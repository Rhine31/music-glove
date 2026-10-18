from __future__ import annotations

import hashlib
import importlib.util
import re
import shutil
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Annotated, Optional

from fastapi import BackgroundTasks, FastAPI, File, Form, Header, HTTPException, Request, UploadFile
from fastapi.responses import FileResponse

from .models import AnalysisJobResponse, ErrorDetail, HealthResponse, Instrument, JobStatus, StoredJob
from .settings import Settings
from .storage import IdempotencyConflict, JobNotFound, JobStore
from .transcription import AnalysisProcessor, BasicPitchFluidSynthProcessor


def create_app(
    *,
    settings: Optional[Settings] = None,
    processor: Optional[AnalysisProcessor] = None,
) -> FastAPI:
    active_settings = settings or Settings.from_environment()
    store = JobStore(active_settings.data_dir)
    active_processor = processor or BasicPitchFluidSynthProcessor(
        active_settings.soundfont_path
    )

    app = FastAPI(
        title="Music Glove Analysis API",
        version="1.0.0",
        description="Turns an immutable humming asset into editable MIDI and a gesture-selected instrument preview.",
    )

    def response_for(job: StoredJob, request: Request) -> AnalysisJobResponse:
        origin = str(request.base_url).rstrip("/")
        base = f"{origin}/v1/analysis/jobs/{job.job_id}/assets"
        return AnalysisJobResponse(
            job_id=job.job_id,
            session_id=job.session_id,
            status=job.status,
            instrument=job.instrument,
            created_at=job.created_at,
            updated_at=job.updated_at,
            raw_vocal_asset_id=job.raw_vocal_asset_id,
            algorithm_version=job.algorithm_version,
            midi_url=f"{base}/midi" if job.midi_path else None,
            preview_audio_url=f"{base}/preview" if job.preview_audio_path else None,
            note_events=job.note_events,
            warnings=job.warnings,
            error=job.error,
        )

    def process_job(job_id: str) -> None:
        job = store.get(job_id)
        job.status = JobStatus.processing
        job.updated_at = datetime.now(timezone.utc)
        store.save(job)
        try:
            output_dir = active_settings.data_dir / "assets" / job.job_id
            result = active_processor.process(job, output_dir)
            if not result.note_events:
                result.midi_path.unlink(missing_ok=True)
                if result.preview_audio_path is not None:
                    result.preview_audio_path.unlink(missing_ok=True)
                job.status = JobStatus.failed
                job.error = ErrorDetail(
                    code="no_melody_detected",
                    message="没有识别到清晰旋律，请换一段更清晰的哼唱音频。",
                    retryable=False,
                )
                job.algorithm_version = active_processor.algorithm_version
                job.updated_at = datetime.now(timezone.utc)
                store.save(job)
                return
            job.midi_path = str(result.midi_path)
            job.preview_audio_path = (
                str(result.preview_audio_path) if result.preview_audio_path else None
            )
            job.note_events = result.note_events
            job.warnings = result.warnings
            job.algorithm_version = active_processor.algorithm_version
            job.status = JobStatus.completed
            job.error = None
        except Exception as error:  # Adapter errors are mapped without leaking content.
            raw_code = str(error)
            code = (
                raw_code
                if re.fullmatch(r"[a-z][a-z0-9_]{0,63}", raw_code)
                else "analysis_failed"
            )
            job.status = JobStatus.failed
            job.error = ErrorDetail(code=code, message="分析服务未能完成任务。", retryable=True)
        job.updated_at = datetime.now(timezone.utc)
        store.save(job)

    @app.get("/health", response_model=HealthResponse)
    def health() -> HealthResponse:
        soundfont_ready = (
            active_settings.soundfont_path is not None
            and active_settings.soundfont_path.is_file()
        )
        return HealthResponse(
            status="ok",
            transcription_available=importlib.util.find_spec("basic_pitch") is not None,
            renderer_available=shutil.which("fluidsynth") is not None and soundfont_ready,
        )

    @app.post(
        "/v1/analysis/jobs",
        response_model=AnalysisJobResponse,
        status_code=202,
    )
    async def create_job(
        request: Request,
        background_tasks: BackgroundTasks,
        vocal: Annotated[UploadFile, File(description="Original immutable humming audio")],
        session_id: Annotated[str, Form(min_length=8, max_length=128)],
        instrument: Annotated[Instrument, Form()],
        idempotency_key: Annotated[str, Header(alias="X-Idempotency-Key", min_length=16, max_length=200)],
    ) -> AnalysisJobResponse:
        digest = hashlib.sha256()
        received = 0
        temporary = tempfile.NamedTemporaryFile(
            prefix="music-glove-upload-", delete=False, dir=active_settings.data_dir
        )
        staged_path = Path(temporary.name)
        try:
            while chunk := await vocal.read(1024 * 1024):
                received += len(chunk)
                if received > active_settings.max_upload_bytes:
                    raise HTTPException(status_code=413, detail="vocal_too_large")
                digest.update(chunk)
                temporary.write(chunk)
            temporary.flush()
            temporary.close()
            if received == 0:
                raise HTTPException(status_code=422, detail="empty_vocal")

            try:
                job, created = store.create_or_get(
                    session_id=session_id,
                    idempotency_key=idempotency_key,
                    input_sha256=digest.hexdigest(),
                    instrument=instrument,
                    staged_vocal=staged_path,
                    original_filename=vocal.filename,
                )
            except IdempotencyConflict as error:
                raise HTTPException(status_code=409, detail="idempotency_conflict") from error

            should_process = created
            if not created and job.error is not None and job.error.retryable:
                should_process = store.mark_for_retry(job.job_id)
                job = store.get(job.job_id)
            if should_process:
                background_tasks.add_task(process_job, job.job_id)
            return response_for(job, request)
        finally:
            temporary.close()
            staged_path.unlink(missing_ok=True)
            await vocal.close()

    @app.get("/v1/analysis/jobs/{job_id}", response_model=AnalysisJobResponse)
    def get_job(job_id: str, request: Request) -> AnalysisJobResponse:
        try:
            return response_for(store.get(job_id), request)
        except JobNotFound as error:
            raise HTTPException(status_code=404, detail="job_not_found") from error

    @app.get("/v1/analysis/jobs/{job_id}/assets/{asset_kind}")
    def get_asset(job_id: str, asset_kind: str) -> FileResponse:
        try:
            job = store.get(job_id)
        except JobNotFound as error:
            raise HTTPException(status_code=404, detail="job_not_found") from error

        if asset_kind == "midi" and job.midi_path:
            return FileResponse(job.midi_path, media_type="audio/midi", filename="music-glove.mid")
        if asset_kind == "preview" and job.preview_audio_path:
            return FileResponse(job.preview_audio_path, media_type="audio/wav", filename="music-glove-preview.wav")
        raise HTTPException(status_code=404, detail="asset_not_ready")

    return app


app = create_app()
