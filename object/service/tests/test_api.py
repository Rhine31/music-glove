from __future__ import annotations

from pathlib import Path

from fastapi.testclient import TestClient

from app.main import create_app
from app.models import NoteEvent, StoredJob, WarningDetail
from app.settings import Settings
from app.transcription import ProcessingResult


class FixtureProcessor:
    algorithm_version = "test-fixture-1"

    def process(self, job: StoredJob, output_dir: Path) -> ProcessingResult:
        midi = output_dir / "result.mid"
        preview = output_dir / "preview.wav"
        midi.write_bytes(b"MThd\x00\x00\x00\x06")
        preview.write_bytes(b"RIFFfixture")
        return ProcessingResult(
            midi_path=midi,
            preview_audio_path=preview,
            note_events=[
                NoteEvent(
                    start_seconds=0,
                    end_seconds=0.5,
                    pitch_midi=69,
                    amplitude=0.8,
                )
            ],
        )


class MidiOnlyProcessor:
    algorithm_version = "test-midi-only-1"

    def process(self, job: StoredJob, output_dir: Path) -> ProcessingResult:
        midi = output_dir / "result.mid"
        midi.write_bytes(b"MThd\x00\x00\x00\x06")
        return ProcessingResult(
            midi_path=midi,
            preview_audio_path=None,
            note_events=[
                NoteEvent(
                    start_seconds=0,
                    end_seconds=0.5,
                    pitch_midi=69,
                    amplitude=0.8,
                )
            ],
            warnings=[
                WarningDetail(
                    code="soundfont_not_configured",
                    message="MIDI 已生成；预览音频不可用。",
                )
            ],
        )


class FlakyProcessor:
    algorithm_version = "test-flaky-1"

    def __init__(self) -> None:
        self.attempts = 0

    def process(self, job: StoredJob, output_dir: Path) -> ProcessingResult:
        self.attempts += 1
        if self.attempts == 1:
            raise RuntimeError("temporary_analysis_failure")
        midi = output_dir / "result.mid"
        midi.write_bytes(b"MThd\x00\x00\x00\x06")
        return ProcessingResult(
            midi_path=midi,
            preview_audio_path=None,
            note_events=[
                NoteEvent(
                    start_seconds=0,
                    end_seconds=0.5,
                    pitch_midi=69,
                    amplitude=0.8,
                )
            ],
        )


class EmptyMelodyProcessor:
    algorithm_version = "test-empty-1"

    def process(self, job: StoredJob, output_dir: Path) -> ProcessingResult:
        midi = output_dir / "result.mid"
        midi.write_bytes(b"MThd\x00\x00\x00\x06")
        return ProcessingResult(midi_path=midi, preview_audio_path=None)


class LeakyFailureProcessor:
    algorithm_version = "test-leaky-1"

    def process(self, job: StoredJob, output_dir: Path) -> ProcessingResult:
        raise RuntimeError(f"failed while reading {job.raw_vocal_path}")


def make_client(tmp_path: Path) -> TestClient:
    settings = Settings(data_dir=tmp_path, soundfont_path=None, max_upload_bytes=1024)
    return TestClient(create_app(settings=settings, processor=FixtureProcessor()))


def submit(client: TestClient, *, key: str, content: bytes = b"synthetic-audio"):
    return client.post(
        "/v1/analysis/jobs",
        headers={"X-Idempotency-Key": key},
        data={"session_id": "session-0001", "instrument": "piano"},
        files={"vocal": ("vocal.wav", content, "audio/wav")},
    )


def test_job_completes_and_exposes_derived_assets(tmp_path: Path) -> None:
    client = make_client(tmp_path)
    created = submit(client, key="stable-key-00000001")

    assert created.status_code == 202
    job = created.json()
    assert job["raw_vocal_asset_id"].startswith("raw-vocal:")

    snapshot = client.get(f"/v1/analysis/jobs/{job['job_id']}")
    assert snapshot.status_code == 200
    assert snapshot.json()["status"] == "completed"
    assert snapshot.json()["note_events"][0]["pitch_midi"] == 69
    assert snapshot.json()["midi_url"].startswith("http://testserver/")
    assert client.get(snapshot.json()["midi_url"]).content.startswith(b"MThd")
    assert client.get(snapshot.json()["preview_audio_url"]).content.startswith(b"RIFF")


def test_missing_renderer_keeps_editable_midi_result(tmp_path: Path) -> None:
    settings = Settings(data_dir=tmp_path, soundfont_path=None, max_upload_bytes=1024)
    client = TestClient(create_app(settings=settings, processor=MidiOnlyProcessor()))

    created = submit(client, key="stable-key-00000005")
    snapshot = client.get(f"/v1/analysis/jobs/{created.json()['job_id']}").json()

    assert snapshot["status"] == "completed"
    assert snapshot["midi_url"] is not None
    assert snapshot["preview_audio_url"] is None
    assert snapshot["warnings"][0]["code"] == "soundfont_not_configured"


def test_retry_reuses_failed_job_and_runs_processor_again(tmp_path: Path) -> None:
    settings = Settings(data_dir=tmp_path, soundfont_path=None, max_upload_bytes=1024)
    processor = FlakyProcessor()
    client = TestClient(create_app(settings=settings, processor=processor))

    first = submit(client, key="stable-key-00000006")
    failed = client.get(f"/v1/analysis/jobs/{first.json()['job_id']}").json()
    retried = submit(client, key="stable-key-00000006")
    completed = client.get(f"/v1/analysis/jobs/{retried.json()['job_id']}").json()

    assert failed["status"] == "failed"
    assert retried.json()["job_id"] == first.json()["job_id"]
    assert completed["status"] == "completed"
    assert processor.attempts == 2


def test_empty_melody_is_non_retryable_validation_failure(tmp_path: Path) -> None:
    settings = Settings(data_dir=tmp_path, soundfont_path=None, max_upload_bytes=1024)
    client = TestClient(create_app(settings=settings, processor=EmptyMelodyProcessor()))

    created = submit(client, key="stable-key-00000007")
    snapshot = client.get(f"/v1/analysis/jobs/{created.json()['job_id']}").json()

    assert snapshot["status"] == "failed"
    assert snapshot["midi_url"] is None
    assert snapshot["error"] == {
        "code": "no_melody_detected",
        "message": "没有识别到清晰旋律，请换一段更清晰的哼唱音频。",
        "retryable": False,
    }


def test_adapter_exception_does_not_expose_internal_path(tmp_path: Path) -> None:
    settings = Settings(data_dir=tmp_path, soundfont_path=None, max_upload_bytes=1024)
    client = TestClient(create_app(settings=settings, processor=LeakyFailureProcessor()))

    created = submit(client, key="stable-key-00000008")
    snapshot = client.get(f"/v1/analysis/jobs/{created.json()['job_id']}").json()

    assert snapshot["status"] == "failed"
    assert snapshot["error"]["code"] == "analysis_failed"
    assert str(tmp_path) not in str(snapshot)


def test_replayed_request_is_idempotent(tmp_path: Path) -> None:
    client = make_client(tmp_path)
    first = submit(client, key="stable-key-00000002")
    second = submit(client, key="stable-key-00000002")

    assert second.status_code == 202
    assert first.json()["job_id"] == second.json()["job_id"]


def test_reused_key_with_different_audio_is_rejected(tmp_path: Path) -> None:
    client = make_client(tmp_path)
    submit(client, key="stable-key-00000003")
    conflict = submit(client, key="stable-key-00000003", content=b"different")

    assert conflict.status_code == 409
    assert conflict.json()["detail"] == "idempotency_conflict"


def test_upload_limit_protects_storage(tmp_path: Path) -> None:
    client = make_client(tmp_path)
    response = submit(client, key="stable-key-00000004", content=b"x" * 1025)

    assert response.status_code == 413


def test_invalid_job_identifier_cannot_escape_storage(tmp_path: Path) -> None:
    client = make_client(tmp_path)
    response = client.get("/v1/analysis/jobs/not-a-uuid")

    assert response.status_code == 404
