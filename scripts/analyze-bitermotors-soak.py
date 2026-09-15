#!/usr/bin/env python3
"""Analyze a Biter Motors headless soak and write a machine-readable verdict."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import re
import sys
from pathlib import Path
from typing import Any


RUNTIME_ERROR_PATTERNS = (
    "non-recoverable error",
    "error while running event",
    "errored when running",
    "luaentity api call when luaentity was invalid",
    "received sigsegv",
    "unexpected error occurred",
)


def percentile(values: list[float], fraction: float) -> float:
    if not values:
        raise ValueError("cannot calculate a percentile without samples")
    ordered = sorted(values)
    index = max(0, math.ceil(fraction * len(ordered)) - 1)
    return ordered[index]


def benchmark_summary(text: str) -> dict[str, float]:
    matches = re.findall(
        r"avg:\s*([0-9.]+)\s*ms,\s*min:\s*([0-9.]+)\s*ms,\s*max:\s*([0-9.]+)\s*ms",
        text,
    )
    if not matches:
        raise ValueError("Factorio benchmark summary was not found")
    average, minimum, maximum = map(float, matches[-1])
    return {"average_ms": average, "minimum_ms": minimum, "maximum_ms": maximum}


def whole_update_samples(text: str, warmup_ticks: int) -> list[float]:
    lines = text.splitlines()
    header_index = next(
        (index for index, line in enumerate(lines) if line.startswith("tick,") and "wholeUpdate" in line),
        None,
    )
    if header_index is None:
        raise ValueError("verbose benchmark wholeUpdate data was not found")
    reader = csv.DictReader(lines[header_index:])
    samples: list[float] = []
    for row in reader:
        tick = row.get("tick", "")
        raw = row.get("wholeUpdate", "")
        if not tick.startswith("t") or not raw:
            break
        samples.append(int(raw) / 1_000_000)
    samples = samples[warmup_ticks:]
    if not samples:
        raise ValueError("no warm benchmark samples remain after the warmup window")
    return samples


def read_json_lines(path: Path) -> list[dict[str, Any]]:
    snapshots = []
    for line in path.read_text(errors="replace").splitlines():
        if line.strip():
            snapshots.append(json.loads(line))
    if not snapshots:
        raise ValueError("the soak probe did not emit any snapshots")
    return snapshots


def runtime_errors(*texts: str) -> list[str]:
    found = []
    for text in texts:
        for line in text.splitlines():
            lowered = line.lower()
            if any(pattern in lowered for pattern in RUNTIME_ERROR_PATTERNS):
                found.append(line.strip())
    return found[:20]


def profile_failures(profile: str, initial: dict[str, Any], final: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    if int(final.get("tick") or 0) <= int(initial.get("tick") or 0):
        failures.append("simulation time did not advance between probe snapshots")
    progress = final.get("progress") or {}
    endgame = final.get("endgame") or {}
    if profile == "terrestrial":
        for field, label in (
            ("sales_offices", "Sales Office"),
            ("customer_settlements", "customer settlement"),
            ("datacenters", "Terrestrial Datacenter"),
        ):
            if int(progress.get(field) or 0) < 1:
                failures.append(f"terrestrial profile requires at least one {label}")
    elif profile == "orbital":
        if int(final.get("platform_count") or 0) < 2:
            failures.append("orbital profile requires at least two space platforms")
        if int(final.get("orbital_core_count") or 0) < 2:
            failures.append("orbital profile requires at least two Orbital Datacenter Cores")
        if int(final.get("active_orbital_core_count") or 0) < 2:
            failures.append("orbital profile requires at least two powered, cooled, configured cores")
        initial_tokens = int(((initial.get("endgame") or {}).get("orbital") or {}).get("generated") or 0)
        final_tokens = int((endgame.get("orbital") or {}).get("generated") or 0)
        if final_tokens <= initial_tokens:
            failures.append("orbital AI Token output did not increase during the soak")
    return failures


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", choices=("terrestrial", "orbital"), required=True)
    parser.add_argument("--ticks", type=int, required=True)
    parser.add_argument("--factorio-version", required=True)
    parser.add_argument("--wall-seconds", type=float, required=True)
    parser.add_argument("--save", type=Path, required=True)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--benchmark-log", type=Path, required=True)
    parser.add_argument("--timing-log", type=Path, required=True)
    parser.add_argument("--probe-report", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--warmup-ticks", type=int, default=60)
    parser.add_argument("--max-average-ms", type=float, default=8.0)
    parser.add_argument("--max-p99-ms", type=float, default=16.667)
    parser.add_argument("--max-spike-ms", type=float, default=100.0)
    parser.add_argument("--skip-profile-requirements", action="store_true")
    args = parser.parse_args()

    benchmark_text = args.benchmark_log.read_text(errors="replace")
    timing_text = args.timing_log.read_text(errors="replace")
    snapshots = read_json_lines(args.probe_report)
    timing_samples = whole_update_samples(timing_text, args.warmup_ticks)
    timing = {
        "samples": len(timing_samples),
        "warmup_ticks_excluded": args.warmup_ticks,
        "average_ms": sum(timing_samples) / len(timing_samples),
        "p95_ms": percentile(timing_samples, 0.95),
        "p99_ms": percentile(timing_samples, 0.99),
        "maximum_ms": max(timing_samples),
    }
    benchmark = benchmark_summary(benchmark_text)
    errors = runtime_errors(benchmark_text, timing_text)
    failures = [f"runtime error: {error}" for error in errors]
    for phase, snapshot in (("initial", snapshots[0]), ("final", snapshots[-1])):
        for method, error in (snapshot.get("errors") or {}).items():
            if error:
                failures.append(f"{phase} probe could not read {method}: {error}")
    if benchmark["average_ms"] > args.max_average_ms:
        failures.append(
            f"long-run average {benchmark['average_ms']:.3f} ms exceeds {args.max_average_ms:.3f} ms"
        )
    if timing["p99_ms"] > args.max_p99_ms:
        failures.append(f"warm p99 {timing['p99_ms']:.3f} ms exceeds {args.max_p99_ms:.3f} ms")
    if timing["maximum_ms"] > args.max_spike_ms:
        failures.append(
            f"warm maximum {timing['maximum_ms']:.3f} ms exceeds {args.max_spike_ms:.3f} ms"
        )
    if not args.skip_profile_requirements:
        failures.extend(profile_failures(args.profile, snapshots[0], snapshots[-1]))

    result = {
        "status": "pass" if not failures else "fail",
        "profile": args.profile,
        "factorio_version": args.factorio_version,
        "simulated_ticks": args.ticks,
        "simulated_hours": args.ticks / 216_000,
        "wall_seconds": args.wall_seconds,
        "save": {"path": str(args.save), "sha256": sha256(args.save)},
        "archive": {"path": str(args.archive), "sha256": sha256(args.archive)},
        "thresholds": {
            "max_average_ms": args.max_average_ms,
            "max_p99_ms": args.max_p99_ms,
            "max_spike_ms": args.max_spike_ms,
        },
        "benchmark": benchmark,
        "timing_sample": timing,
        "probe_snapshots": len(snapshots),
        "initial": snapshots[0],
        "final": snapshots[-1],
        "failures": failures,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")

    print(
        f"Biter Motors {args.profile} soak: {result['status'].upper()} "
        f"({result['simulated_hours']:.2f} simulated hours)"
    )
    print(
        f"Long run: avg={benchmark['average_ms']:.3f} ms "
        f"min={benchmark['minimum_ms']:.3f} ms max={benchmark['maximum_ms']:.3f} ms"
    )
    print(
        f"Warm timing sample: avg={timing['average_ms']:.3f} ms "
        f"p95={timing['p95_ms']:.3f} ms p99={timing['p99_ms']:.3f} ms "
        f"max={timing['maximum_ms']:.3f} ms"
    )
    for failure in failures:
        print(f"FAIL: {failure}", file=sys.stderr)
    print(f"Summary: {args.output}")
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
