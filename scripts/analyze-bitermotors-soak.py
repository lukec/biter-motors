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
    "error while loading",
    "error util.cpp",
    "error mainloop.cpp",
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
    if len(matches) != 1:
        raise ValueError("expected exactly one Factorio benchmark summary")
    average, minimum, maximum = map(float, matches[-1])
    updates = re.findall(r"Performed\s+(\d+)\s+updates\b", text)
    if len(updates) != 1:
        raise ValueError("expected exactly one completed benchmark update count")
    if not all(math.isfinite(value) for value in (average, minimum, maximum)) or not 0 <= minimum <= average <= maximum:
        raise ValueError("invalid benchmark timing summary")
    return {"average_ms": average, "minimum_ms": minimum, "maximum_ms": maximum,
            "completed_updates": int(updates[0])}


def whole_update_samples(text: str, warmup_ticks: int, requested_ticks: int) -> list[float]:
    lines = text.splitlines()
    if sum(line.startswith("tick,") and "wholeUpdate" in line for line in lines) != 1:
        raise ValueError("expected exactly one verbose timing header")
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
        if not tick.startswith("t"):
            break
        if tick != f"t{len(samples)}" or not raw or None in row:
            raise ValueError("malformed or discontinuous verbose timing sample")
        value = int(raw)
        if value < 0:
            raise ValueError("negative wholeUpdate sample")
        samples.append(value / 1_000_000)
    if len(samples) != requested_ticks:
        raise ValueError(f"timing window requires {requested_ticks} samples, observed {len(samples)}")
    samples = samples[warmup_ticks:]
    if not samples:
        raise ValueError("no warm benchmark samples remain after the warmup window")
    return samples


def read_json_lines(path: Path) -> list[dict[str, Any]]:
    snapshots = []
    text = path.read_text(errors="strict")
    if text and not text.endswith("\n"):
        raise ValueError("unterminated probe report")
    def invalid_constant(value: str) -> None:
        raise ValueError(f"invalid JSON constant {value}")

    def finite_float(value: str) -> float:
        number = float(value)
        if not math.isfinite(number):
            raise ValueError(f"non-finite JSON number {value}")
        return number

    for line in text.splitlines():
        if line.strip():
            snapshot = json.loads(line, parse_constant=invalid_constant, parse_float=finite_float)
            if not isinstance(snapshot, dict):
                raise ValueError("probe snapshot must be an object")
            snapshots.append(snapshot)
    if not snapshots:
        raise ValueError("the soak probe did not emit any snapshots")
    return snapshots


def probe_failures(snapshots: list[dict[str, Any]], profile: str,
                   ticks: int, sample_ticks: int | None) -> list[str]:
    failures = []
    for index, snapshot in enumerate(snapshots):
        if snapshot.get("profile") != profile:
            failures.append(f"snapshot {index} has incorrect profile")
        if type(snapshot.get("tick")) is not int or snapshot["tick"] < 0:
            raise ValueError(f"snapshot {index} has invalid game tick")
        if snapshot.get("kind") not in ("initial", "periodic", "final"):
            failures.append(f"snapshot {index} has invalid kind")
        errors = snapshot.get("errors")
        if not isinstance(errors, dict):
            raise ValueError(f"snapshot {index} has missing or malformed errors")
        if set(errors) != {"progress", "endgame", "performance"}:
            failures.append(f"snapshot {index} has missing or malformed errors fields")
        for method, error in errors.items():
            if error is not False:
                failures.append(f"snapshot {index} probe could not read {method}: {error}")
        for method in ("progress", "endgame", "performance"):
            if not isinstance(snapshot.get(method), dict):
                failures.append(f"snapshot {index} missing {method} status")
    initial, final = snapshots[0], snapshots[-1]
    if initial.get("kind") != "initial" or sum(s.get("kind") == "initial" for s in snapshots) != 1:
        failures.append("missing or duplicate initial probe")
    if final.get("kind") != "final" or sum(s.get("kind") == "final" for s in snapshots) != 1:
        failures.append("missing or duplicate final sentinel")
    # Initial is captured on the first native update; N updates span N-1 ticks.
    start, end = initial["tick"], initial["tick"] + ticks - 1
    if final["tick"] != end:
        failures.append(f"game tick span requires {ticks - 1}, observed {final['tick'] - start}")
    expected = list(range((start // sample_ticks + 1) * sample_ticks, end + 1, sample_ticks)) if sample_ticks else []
    actual = [s["tick"] for s in snapshots if s.get("kind") == "periodic"]
    if actual != expected:
        failures.append(f"incomplete scheduled probe cadence: expected {len(expected)}, observed {len(actual)}")
    if any(a["tick"] > b["tick"] for a, b in zip(snapshots, snapshots[1:])):
        failures.append("probe game ticks are out of order")
    return failures


def runtime_errors(*texts: str) -> list[str]:
    found = []
    for text in texts:
        for line in text.splitlines():
            lowered = line.lower()
            if any(pattern in lowered for pattern in RUNTIME_ERROR_PATTERNS) or re.search(r"(?:^|\s)error(?:\s|:)", lowered):
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
    parser.add_argument("--timing-probe-report", type=Path)
    parser.add_argument("--timing-ticks", type=int, default=3600)
    parser.add_argument("--sample-ticks", type=int, default=3600)
    parser.add_argument("--benchmark-exit-code", type=int, default=0)
    parser.add_argument("--timing-exit-code", type=int, default=0)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--warmup-ticks", type=int, default=60)
    parser.add_argument("--max-average-ms", type=float, default=8.0)
    parser.add_argument("--max-p99-ms", type=float, default=16.667)
    parser.add_argument("--max-spike-ms", type=float, default=100.0)
    parser.add_argument("--skip-profile-requirements", action="store_true")
    args = parser.parse_args()

    failures = []
    benchmark_text = timing_text = ""
    for label, path in (("benchmark", args.benchmark_log), ("timing", args.timing_log)):
        try:
            value = path.read_text(errors="strict")
            if label == "benchmark":
                benchmark_text = value
            else:
                timing_text = value
            if "Goodbye" not in value:
                failures.append(f"{label} log missing engine completion marker Goodbye")
        except (OSError, UnicodeError) as error:
            failures.append(f"{label} log: {error}")
    failures.extend(f"runtime error: {error}" for error in runtime_errors(benchmark_text, timing_text))
    for label, code in (("benchmark", args.benchmark_exit_code), ("timing", args.timing_exit_code)):
        if code:
            failures.append(f"{label} process exited with status {code}")
    if args.ticks < 2 or args.timing_ticks <= args.warmup_ticks or args.warmup_ticks < 0 or args.sample_ticks <= 0:
        failures.append("invalid requested tick windows or probe interval")
    if args.timing_ticks < 2:
        failures.append("timing window requires at least two updates")
    for label, value in (("wall seconds", args.wall_seconds), ("average threshold", args.max_average_ms),
                         ("p99 threshold", args.max_p99_ms), ("spike threshold", args.max_spike_ms)):
        if not math.isfinite(value) or value < 0:
            failures.append(f"invalid {label}")
    benchmark = {}
    timing_benchmark = {}
    for label, text, requested in (("benchmark", benchmark_text, args.ticks),
                                   ("timing", timing_text, args.timing_ticks)):
        try:
            measured = benchmark_summary(text)
            measured["requested_updates"] = requested
            if label == "benchmark":
                benchmark = measured
            else:
                timing_benchmark = measured
            if measured["completed_updates"] != requested:
                failures.append(f"{label} requested {requested} updates, completed {measured['completed_updates']}")
        except (ValueError, OverflowError) as error:
            failures.append(f"{label}: {error}")
    snapshots = []
    timing_snapshots = []
    for label, path, requested, interval in (("soak", args.probe_report, args.ticks, args.sample_ticks),
                                            ("timing", args.timing_probe_report, args.timing_ticks, None)):
        try:
            if path is None:
                raise ValueError("missing timing probe report")
            observed = read_json_lines(path)
            if label == "soak":
                snapshots = observed
            else:
                timing_snapshots = observed
            if requested >= 2 and (interval is None or interval > 0):
                failures.extend(f"{label}: {failure}" for failure in
                                probe_failures(observed, args.profile, requested, interval))
        except (OSError, ValueError, TypeError, UnicodeError) as error:
            failures.append(f"{label} probe evidence: {error}")
    timing = {"requested_updates": args.timing_ticks}
    try:
        timing_samples = whole_update_samples(timing_text, args.warmup_ticks, args.timing_ticks)
        timing.update({
            "samples": len(timing_samples),
            "warmup_ticks_excluded": args.warmup_ticks,
            "average_ms": sum(timing_samples) / len(timing_samples),
            "p95_ms": percentile(timing_samples, 0.95),
            "p99_ms": percentile(timing_samples, 0.99),
            "maximum_ms": max(timing_samples),
        })
    except (ValueError, TypeError, OverflowError, ZeroDivisionError) as error:
        failures.append(f"timing samples: {error}")
    if benchmark.get("average_ms", 0) > args.max_average_ms:
        failures.append(
            f"long-run average {benchmark['average_ms']:.3f} ms exceeds {args.max_average_ms:.3f} ms"
        )
    if timing.get("p99_ms", 0) > args.max_p99_ms:
        failures.append(f"warm p99 {timing['p99_ms']:.3f} ms exceeds {args.max_p99_ms:.3f} ms")
    if timing.get("maximum_ms", 0) > args.max_spike_ms:
        failures.append(
            f"warm maximum {timing['maximum_ms']:.3f} ms exceeds {args.max_spike_ms:.3f} ms"
        )
    if not args.skip_profile_requirements and snapshots:
        try:
            failures.extend(profile_failures(args.profile, snapshots[0], snapshots[-1]))
        except (ValueError, TypeError, AttributeError, OverflowError) as error:
            failures.append(f"malformed profile evidence: {error}")

    artifacts = {}
    for label, path in (("save", args.save), ("archive", args.archive)):
        artifacts[label] = {"path": str(path), "sha256": None}
        try:
            artifacts[label]["sha256"] = sha256(path)
        except OSError as error:
            failures.append(f"{label}: {error}")
    span = None
    if snapshots and all(type(s.get("tick")) is int for s in (snapshots[0], snapshots[-1])):
        span = snapshots[-1]["tick"] - snapshots[0]["tick"]
    timing_span = None
    if timing_snapshots and all(type(s.get("tick")) is int for s in (timing_snapshots[0], timing_snapshots[-1])):
        timing_span = timing_snapshots[-1]["tick"] - timing_snapshots[0]["tick"]
    timing["requested_game_tick_span"] = args.timing_ticks - 1
    timing["observed_game_tick_span"] = timing_span

    result = {
        "status": "pass" if not failures else "fail",
        "profile": args.profile,
        "factorio_version": args.factorio_version,
        "requested_updates": args.ticks,
        "requested_game_tick_span": args.ticks - 1,
        "observed_game_tick_span": span,
        "simulated_ticks": span,
        "simulated_hours": span / 216_000 if span is not None else None,
        "wall_seconds": args.wall_seconds if math.isfinite(args.wall_seconds) else None,
        "save": artifacts["save"],
        "archive": artifacts["archive"],
        "thresholds": {
            "max_average_ms": args.max_average_ms if math.isfinite(args.max_average_ms) else None,
            "max_p99_ms": args.max_p99_ms if math.isfinite(args.max_p99_ms) else None,
            "max_spike_ms": args.max_spike_ms if math.isfinite(args.max_spike_ms) else None,
        },
        "benchmark": benchmark,
        "timing_sample": timing,
        "timing_benchmark": timing_benchmark,
        "timing_initial": timing_snapshots[0] if timing_snapshots else None,
        "timing_final": timing_snapshots[-1] if timing_snapshots else None,
        "probe_snapshots": len(snapshots),
        "initial": snapshots[0] if snapshots else None,
        "final": snapshots[-1] if snapshots else None,
        "failures": failures,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")

    print(
        f"Biter Motors {args.profile} soak: {result['status'].upper()} "
        f"(observed game tick span: {span})"
    )
    if benchmark:
        print(
            f"Long run: avg={benchmark['average_ms']:.3f} ms "
            f"min={benchmark['minimum_ms']:.3f} ms max={benchmark['maximum_ms']:.3f} ms"
        )
    if "average_ms" in timing:
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
