from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


@dataclass(frozen=True)
class Settings:
    data_dir: Path
    soundfont_path: Optional[Path]
    max_upload_bytes: int = 50 * 1024 * 1024

    @classmethod
    def from_environment(cls) -> "Settings":
        default_data_dir = Path(__file__).resolve().parents[1] / ".local-data"
        raw_soundfont = os.environ.get("MUSIC_GLOVE_SOUNDFONT")
        return cls(
            data_dir=Path(os.environ.get("MUSIC_GLOVE_DATA_DIR", default_data_dir)),
            soundfont_path=Path(raw_soundfont) if raw_soundfont else None,
            max_upload_bytes=int(
                os.environ.get("MUSIC_GLOVE_MAX_UPLOAD_BYTES", 50 * 1024 * 1024)
            ),
        )
