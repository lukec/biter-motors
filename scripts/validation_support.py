"""Shared source discovery and fail-closed checks for isolated engine runs."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


ERROR_PATTERNS = (
    r"non-recoverable error",
    r"error while (?:running|loading)",
    r"errored when running",
    r"luaentity api call when luaentity was invalid",
    r"received sigsegv",
    r"unexpected error occurred",
    r"(?:^|\s)error(?:\s|:)",
)


def discover_source(root: Path) -> tuple[Path, str]:
    manifests = sorted((root / "mod").glob("bitermotors_*/info.json"))
    if len(manifests) != 1:
        raise ValueError(f"expected one Biter Motors manifest, found {len(manifests)}")
    manifest = manifests[0]
    info = json.loads(manifest.read_text())
    if not isinstance(info, dict):
        raise ValueError("Biter Motors manifest must be an object")
    version = info.get("version", "")
    if (info.get("name") != "bitermotors" or not isinstance(version, str)
            or not re.fullmatch(r"\d+\.\d+\.\d+", version)):
        raise ValueError("invalid Biter Motors manifest name/version")
    source = manifest.parent.resolve()
    if source.name != f"bitermotors_{version}":
        raise ValueError("source folder and manifest version do not match")
    if any(character in str(source) for character in "\t\n\r"):
        raise ValueError("source path cannot contain tabs or newlines")
    return source, version


def check_log(path: Path, expected_updates: int | None = None,
              marker: str | None = None) -> None:
    text = path.read_text(errors="replace")
    if not text.strip():
        raise ValueError(f"empty engine log: {path}")
    for line in text.splitlines():
        if any(re.search(pattern, line, re.IGNORECASE) for pattern in ERROR_PATTERNS):
            raise ValueError(f"engine error in {path}: {line.strip()}")
    if marker is not None and marker not in text:
        raise ValueError(f"engine log missing completion marker {marker!r}: {path}")
    if expected_updates is not None:
        counts = re.findall(r"Performed\s+(\d+)\s+updates\b", text)
        if counts != [str(expected_updates)]:
            raise ValueError(
                f"expected {expected_updates} completed updates, found {counts}: {path}"
            )


def check_report(path: Path, required_status: str, minimum_tick: int) -> None:
    text = path.read_text()
    if text and not text.endswith("\n"):
        raise ValueError(f"unterminated engine report: {path}")
    rows = [json.loads(line) for line in text.splitlines() if line.strip()]
    if not rows or any(not isinstance(row, dict) for row in rows):
        raise ValueError(f"empty or invalid engine report: {path}")
    for row in rows:
        if row.get("status") in {"failed", "error"}:
            raise ValueError(f"engine report failure: {row}")
    sentinels = [row for row in rows if row.get("status") == required_status]
    if (len(sentinels) != 1 or type(sentinels[0].get("tick")) is not int
            or rows[-1] is not sentinels[0]):
        raise ValueError(f"expected one {required_status!r} completion sentinel: {path}")
    if sentinels[0]["tick"] < minimum_tick:
        raise ValueError(f"engine report ended before tick {minimum_tick}: {path}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    source = commands.add_parser("source")
    source.add_argument("--repo", type=Path, required=True)
    log = commands.add_parser("log")
    log.add_argument("path", type=Path)
    log.add_argument("--expect-updates", type=int)
    log.add_argument("--expect-marker")
    report = commands.add_parser("report")
    report.add_argument("path", type=Path)
    report.add_argument("--require-status", required=True)
    report.add_argument("--minimum-tick", type=int, default=0)
    args = parser.parse_args()
    try:
        if args.command == "source":
            path, version = discover_source(args.repo)
            print(f"{path}\t{version}")
        elif args.command == "log":
            check_log(args.path, args.expect_updates, args.expect_marker)
        else:
            check_report(args.path, args.require_status, args.minimum_tick)
    except (OSError, ValueError, TypeError) as error:
        parser.exit(1, f"Validation failed: {error}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
