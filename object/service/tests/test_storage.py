from pathlib import Path

from app.models import Instrument
from app.storage import JobStore


def test_raw_vocal_is_moved_to_immutable_asset_location(tmp_path: Path) -> None:
    store = JobStore(tmp_path / "store")
    staged = tmp_path / "upload.wav"
    staged.write_bytes(b"authorized synthetic fixture")

    job, created = store.create_or_get(
        session_id="session-1",
        idempotency_key="idempotency-key-1",
        input_sha256="abc123",
        instrument=Instrument.guitar,
        staged_vocal=staged,
        original_filename="voice.wav",
    )

    assert created is True
    assert not staged.exists()
    assert Path(job.raw_vocal_path).read_bytes() == b"authorized synthetic fixture"
