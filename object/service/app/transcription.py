from __future__ import annotations

import shutil
import subprocess
import threading
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional, Protocol

from .models import Instrument, NoteEvent, StoredJob, WarningDetail


@dataclass(frozen=True)
class ProcessingResult:
    midi_path: Path
    preview_audio_path: Optional[Path]
    note_events: list[NoteEvent] = field(default_factory=list)
    warnings: list[WarningDetail] = field(default_factory=list)


class AnalysisProcessor(Protocol):
    @property
    def algorithm_version(self) -> str: ...

    def process(self, job: StoredJob, output_dir: Path) -> ProcessingResult: ...


GENERAL_MIDI_PROGRAMS = {
    Instrument.piano: 0,
    Instrument.guitar: 24,
    Instrument.drums: 0,
    Instrument.bass: 32,
    Instrument.strings: 48,
}


class BasicPitchFluidSynthProcessor:
    """Production adapter: Basic Pitch transcription plus FluidSynth rendering."""

    def __init__(self, soundfont_path: Optional[Path]) -> None:
        self.soundfont_path = soundfont_path
        self._model = None
        self._inference_lock = threading.Lock()

    @property
    def algorithm_version(self) -> str:
        return "spotify-basic-pitch-0.4.0"

    def process(self, job: StoredJob, output_dir: Path) -> ProcessingResult:
        try:
            from basic_pitch import ICASSP_2022_MODEL_PATH
            from basic_pitch.inference import Model, predict
        except ImportError as error:
            raise RuntimeError("basic_pitch_not_installed") from error

        with self._inference_lock:
            if self._model is None:
                self._model = Model(ICASSP_2022_MODEL_PATH)

            _, midi_data, raw_note_events = predict(Path(job.raw_vocal_path), self._model)
            program = GENERAL_MIDI_PROGRAMS[job.instrument]
            for midi_instrument in midi_data.instruments:
                midi_instrument.program = program
                midi_instrument.is_drum = job.instrument is Instrument.drums

            midi_path = output_dir / "result.mid"
            midi_data.write(str(midi_path))

        note_events = [
            NoteEvent(
                start_seconds=float(event[0]),
                end_seconds=float(event[1]),
                pitch_midi=int(event[2]),
                amplitude=max(0.0, min(1.0, float(event[3]))),
            )
            for event in raw_note_events
        ]
        warnings: list[WarningDetail] = []
        preview_path: Optional[Path] = None
        if self.soundfont_path is None or not self.soundfont_path.is_file():
            warnings.append(
                WarningDetail(
                    code="soundfont_not_configured",
                    message="MIDI 已生成；尚未配置授权音色库，因此暂不能生成乐器预览音频。",
                )
            )
        elif shutil.which("fluidsynth") is None:
            warnings.append(
                WarningDetail(
                    code="fluidsynth_not_installed",
                    message="MIDI 已生成；当前环境缺少 FluidSynth，因此暂不能生成乐器预览音频。",
                )
            )
        else:
            candidate = output_dir / "preview.wav"
            try:
                subprocess.run(
                    [
                        "fluidsynth",
                        "-ni",
                        str(self.soundfont_path),
                        str(midi_path),
                        "-F",
                        str(candidate),
                        "-r",
                        "44100",
                    ],
                    check=True,
                    capture_output=True,
                    timeout=120,
                )
                preview_path = candidate
            except (subprocess.SubprocessError, OSError):
                candidate.unlink(missing_ok=True)
                warnings.append(
                    WarningDetail(
                        code="preview_render_failed",
                        message="MIDI 已生成，但本次乐器预览音频渲染失败。",
                    )
                )

        return ProcessingResult(
            midi_path=midi_path,
            preview_audio_path=preview_path,
            note_events=note_events,
            warnings=warnings,
        )
