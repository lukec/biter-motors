#!/usr/bin/env python3
"""Synthesize original EV sounds without recordings, samples or external tools."""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RATE = 22050


def samples(kind: str) -> bytes:
    duration = 2.0 if kind == "drivetrain" else 0.72
    frames = bytearray()
    for index in range(round(RATE * duration)):
        t = index / RATE
        if kind == "drivetrain":
            # Integer cycles over two seconds keep the loop boundary continuous.
            carrier = (0.58 * math.sin(math.tau * 180 * t)
                       + 0.25 * math.sin(math.tau * 540 * t)
                       + 0.12 * math.sin(math.tau * 1080 * t)
                       + 0.05 * math.sin(math.tau * 2160 * t))
            value = 0.32 * carrier * (0.92 + 0.08 * math.cos(math.tau * 3 * t))
        elif kind == "reverse":
            # Two soft warning pulses, with cosine attack/release to avoid clicks.
            phase = t % 0.36
            envelope = math.sin(math.pi * phase / 0.24) ** 2 if phase < 0.24 else 0
            value = 0.38 * envelope * (0.65 * math.sin(math.tau * 660 * t)
                                       + 0.35 * math.sin(math.tau * 990 * t))
        else:
            raise ValueError(f"unknown sound: {kind}")
        frames.extend(struct.pack("<h", round(value * 32767)))
    return bytes(frames)


def build(output: Path) -> None:
    output.mkdir(parents=True, exist_ok=True)
    for kind, name in (("drivetrain", "ev-drivetrain-loop.wav"),
                       ("reverse", "ev-reverse-warning.wav")):
        with wave.open(str(output / name), "wb") as audio:
            audio.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
            audio.writeframes(samples(kind))


if __name__ == "__main__":
    # Source discovery follows info.json rather than embedding an alpha version.
    from validation_support import discover_source
    source, _ = discover_source(ROOT)
    build(source / "sound")
