from __future__ import annotations

import hashlib
import json
import os
import re
import tempfile
import threading
import uuid
from datetime import datetime, timezone
from pathlib import Path

from .models import Instrument, JobStatus, StoredJob


class IdempotencyConflict(Exception):
    """The same idempotency key was reused for different content."""


class JobNotFound(Exception):
    """No stored job exists for the supplied identifier."""


class JobStore:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.jobs_dir = root / "jobs"
        self.assets_dir = root / "assets"
        self.keys_dir = root / "idempotency"
        for directory in (self.jobs_dir, self.assets_dir, self.keys_dir):
            directory.mkdir(parents=True, exist_ok=True)
        self._lock = threading.RLock()

    @staticmethod
    def hash_key(key: str) -> str:
        return hashlib.sha256(key.encode("utf-8")).hexdigest()

    @staticmethod
    def safe_extension(filename: str | None) -> str:
        suffix = Path(filename or "vocal.bin").suffix.lower()
        return suffix if re.fullmatch(r"\.[a-z0-9]{1,8}", suffix) else ".bin"

    def create_or_get(
        self,
        *,
        session_id: str,
        idempotency_key: str,
        input_sha256: str,
        instrument: Instrument,
        staged_vocal: Path,
        original_filename: str | None,
    ) -> tuple[StoredJob, bool]:
        idempotency_hash = self.hash_key(idempotency_key)
        key_path = self.keys_dir / f"{idempotency_hash}.json"

        with self._lock:
            if key_path.exists():
                mapped = json.loads(key_path.read_text(encoding="utf-8"))
                existing = self.get(mapped["job_id"])
                if (
                    existing.session_id != session_id
                    or existing.input_sha256 != input_sha256
                    or existing.instrument != instrument
                ):
                    raise IdempotencyConflict
                return existing, False

            job_id = str(uuid.uuid4())
            asset_dir = self.assets_dir / job_id
            asset_dir.mkdir(parents=True, exist_ok=False)
            raw_path = asset_dir / f"raw-vocal{self.safe_extension(original_filename)}"
            os.replace(staged_vocal, raw_path)
            raw_path.chmod(0o600)

            job = StoredJob(
                job_id=job_id,
                session_id=session_id,
                idempotency_hash=idempotency_hash,
                input_sha256=input_sha256,
                instrument=instrument,
                raw_vocal_asset_id=f"raw-vocal:{input_sha256}",
                raw_vocal_path=str(raw_path),
            )
            self.save(job)
            self._atomic_json(key_path, {"job_id": job_id})
            return job, True

    def get(self, job_id: str) -> StoredJob:
        try:
            canonical_job_id = str(uuid.UUID(job_id))
        except ValueError as error:
            raise JobNotFound(job_id) from error
        path = self.jobs_dir / f"{canonical_job_id}.json"
        if not path.exists():
            raise JobNotFound(job_id)
        return StoredJob.model_validate_json(path.read_text(encoding="utf-8"))

    def save(self, job: StoredJob) -> None:
        with self._lock:
            self._atomic_text(
                self.jobs_dir / f"{job.job_id}.json",
                job.model_dump_json(indent=2),
            )

    def mark_for_retry(self, job_id: str) -> bool:
        """Atomically re-queue one retryable failed job without changing its identity."""
        with self._lock:
            job = self.get(job_id)
            if job.status is not JobStatus.failed or job.error is None or not job.error.retryable:
                return False
            job.status = JobStatus.queued
            job.error = None
            job.updated_at = datetime.now(timezone.utc)
            self.save(job)
            return True

    @staticmethod
    def _atomic_json(path: Path, value: object) -> None:
        JobStore._atomic_text(path, json.dumps(value, indent=2, sort_keys=True))

    @staticmethod
    def _atomic_text(path: Path, value: str) -> None:
        fd, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as handle:
                handle.write(value)
                handle.flush()
                os.fsync(handle.fileno())
            os.replace(temporary_name, path)
        finally:
            if os.path.exists(temporary_name):
                os.unlink(temporary_name)
