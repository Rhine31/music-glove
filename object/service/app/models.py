from __future__ import annotations

from datetime import datetime, timezone
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class Instrument(str, Enum):
    piano = "piano"
    guitar = "guitar"
    drums = "drums"
    bass = "bass"
    strings = "strings"


class JobStatus(str, Enum):
    queued = "queued"
    processing = "processing"
    completed = "completed"
    failed = "failed"


class ErrorDetail(BaseModel):
    code: str
    message: str
    retryable: bool = False


class WarningDetail(BaseModel):
    code: str
    message: str


class NoteEvent(BaseModel):
    start_seconds: float = Field(ge=0)
    end_seconds: float = Field(gt=0)
    pitch_midi: int = Field(ge=0, le=127)
    amplitude: float = Field(ge=0, le=1)


class StoredJob(BaseModel):
    job_id: str
    session_id: str
    idempotency_hash: str
    input_sha256: str
    instrument: Instrument
    status: JobStatus = JobStatus.queued
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    raw_vocal_asset_id: str
    raw_vocal_path: str
    midi_path: Optional[str] = None
    preview_audio_path: Optional[str] = None
    algorithm_version: Optional[str] = None
    note_events: list[NoteEvent] = Field(default_factory=list)
    warnings: list[WarningDetail] = Field(default_factory=list)
    error: Optional[ErrorDetail] = None


class AnalysisJobResponse(BaseModel):
    job_id: str
    session_id: str
    status: JobStatus
    instrument: Instrument
    created_at: datetime
    updated_at: datetime
    raw_vocal_asset_id: str
    algorithm_version: Optional[str] = None
    midi_url: Optional[str] = None
    preview_audio_url: Optional[str] = None
    note_events: list[NoteEvent] = Field(default_factory=list)
    warnings: list[WarningDetail] = Field(default_factory=list)
    error: Optional[ErrorDetail] = None


class HealthResponse(BaseModel):
    status: str
    transcription_available: bool
    renderer_available: bool
