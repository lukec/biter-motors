#!/usr/bin/env python3
"""Validate the public Biter Motors archive and namespace contract."""

from __future__ import annotations

import argparse
import json
import zipfile
from pathlib import Path


FORBIDDEN_NAMESPACES = ("factoryx", "frontier")
TEXT_SUFFIXES = {".cfg", ".html", ".json", ".lua", ".md", ".sh", ".txt"}
REQUIRED_ARTIFACTS = {"LICENSE", "ASSET-LICENSE.md", "ATTRIBUTION.md", "CHANGELOG.md"}
EXPECTED_HOMEPAGE = "https://github.com/lukec/biter-motors"


def fail(message: str) -> None:
    raise SystemExit(message)


def inspect_archive(archive_path: Path) -> None:
    if not archive_path.is_file():
        fail(f"archive does not exist: {archive_path}")
    with zipfile.ZipFile(archive_path) as archive:
        names = archive.namelist()
        if not names:
            fail("archive is empty")
        roots = {name.split("/", 1)[0] for name in names}
        if len(roots) != 1:
            fail(f"archive must have one root directory, found {sorted(roots)}")
        root = next(iter(roots))
        if not root.startswith("bitermotors_"):
            fail(f"unexpected archive root: {root}")
        info_name = f"{root}/info.json"
        if info_name not in names:
            fail("archive is missing info.json")
        info = json.loads(archive.read(info_name))
        if info.get("name") != "bitermotors":
            fail("archive manifest name is not bitermotors")
        if f"{root}/info.json" != f"bitermotors_{info.get('version')}/info.json":
            fail("archive root does not match info.json version")
        if info.get("factorio_version") != "2.1":
            fail("archive manifest must target Factorio 2.1")
        if info.get("homepage") != EXPECTED_HOMEPAGE:
            fail(f"archive manifest homepage must be {EXPECTED_HOMEPAGE}")
        if "space-age >= 2.1.0" not in info.get("dependencies", []):
            fail("archive manifest must declare Space Age")
        for artifact in REQUIRED_ARTIFACTS:
            if f"{root}/{artifact}" not in names:
                fail(f"archive is missing {artifact}")
        changelog_name = f"{root}/changelog.txt"
        if changelog_name not in names:
            fail("archive is missing Factorio changelog.txt")
        changelog = archive.read(changelog_name).decode("utf-8")
        if f"Version: {info.get('version')}" not in changelog:
            fail("changelog.txt does not describe the manifest version")
        thumbnail_name = f"{root}/thumbnail.png"
        if thumbnail_name not in names:
            fail("archive is missing thumbnail.png")
        thumbnail = archive.read(thumbnail_name)
        if not thumbnail.startswith(b"\x89PNG\r\n\x1a\n") or len(thumbnail) < 24:
            fail("thumbnail.png is not a valid PNG")
        width = int.from_bytes(thumbnail[16:20], "big")
        height = int.from_bytes(thumbnail[20:24], "big")
        if (width, height) != (144, 144):
            fail(f"thumbnail.png must be 144x144, found {width}x{height}")
        for name in names:
            if name.endswith("/"):
                continue
            if Path(name).suffix.lower() not in TEXT_SUFFIXES:
                continue
            text = archive.read(name).decode("utf-8", errors="ignore").lower()
            for forbidden in FORBIDDEN_NAMESPACES:
                if forbidden in text or forbidden in name.lower():
                    fail(f"forbidden retired namespace {forbidden!r} in {name}")
        print(f"release archive OK: {archive_path}")


def inspect_source(source: Path) -> None:
    if not source.is_dir():
        fail(f"source directory does not exist: {source}")
    for path in source.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore").lower()
        for forbidden in FORBIDDEN_NAMESPACES:
            if forbidden in text or forbidden in path.name.lower():
                fail(f"forbidden retired namespace {forbidden!r} in source {path}")
    print(f"source namespace scan OK: {source}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("--source", type=Path)
    args = parser.parse_args()
    inspect_archive(args.archive)
    if args.source:
        inspect_source(args.source)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
