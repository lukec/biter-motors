#!/usr/bin/env python3
"""Build a deterministic Factorio archive for the Biter Motors mod."""

from __future__ import annotations

import argparse
import json
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODS = ROOT / "mod"
LEGAL_FILES = ("LICENSE", "ASSET-LICENSE.md", "ATTRIBUTION.md", "CHANGELOG.md")
FIXED_DATE = (1980, 1, 1, 0, 0, 0)
EXCLUDED_NAMES = {".DS_Store", "__pycache__"}
EXCLUDED_SUFFIXES = {".pyc", ".pyo", ".blend1"}


def read_manifest() -> tuple[Path, dict]:
    manifests = sorted(MODS.glob("bitermotors_*/info.json"))
    if len(manifests) != 1:
        raise SystemExit(f"expected exactly one Biter Motors manifest, found {len(manifests)}")
    manifest_path = manifests[0]
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("name") != "bitermotors":
        raise SystemExit("mod manifest name must be bitermotors")
    version = manifest.get("version")
    if not isinstance(version, str) or not version:
        raise SystemExit("mod manifest must contain a non-empty version")
    mod_dir = manifest_path.parent
    expected_dir = f"bitermotors_{version}"
    if mod_dir.name != expected_dir:
        raise SystemExit(f"mod directory {mod_dir.name!r} does not match manifest version {version!r}")
    return mod_dir, manifest


def should_include(path: Path) -> bool:
    return not any(part in EXCLUDED_NAMES for part in path.parts) and path.suffix not in EXCLUDED_SUFFIXES


def archive_entries(mod_dir: Path, package_root: str) -> list[tuple[str, bytes]]:
    entries: list[tuple[str, bytes]] = []
    for path in sorted(mod_dir.rglob("*")):
        if path.is_file() and should_include(path):
            relative = path.relative_to(mod_dir).as_posix()
            entries.append((f"{package_root}/{relative}", path.read_bytes()))
    for name in LEGAL_FILES:
        source = ROOT / name
        if not source.is_file():
            raise SystemExit(f"missing release artifact: {source}")
        entries.append((f"{package_root}/{name}", source.read_bytes()))
    return sorted(entries)


def write_archive(output: Path, entries: list[tuple[str, bytes]]) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, content in entries:
            info = zipfile.ZipInfo(name, date_time=FIXED_DATE)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(info, content)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=ROOT / "dist")
    parser.add_argument("--version", help="require this manifest version")
    args = parser.parse_args()

    mod_dir, manifest = read_manifest()
    version = manifest["version"]
    if args.version and args.version != version:
        raise SystemExit(f"requested version {args.version} does not match manifest version {version}")
    package_root = f"bitermotors_{version}"
    output = args.output_dir / f"{package_root}.zip"
    entries = archive_entries(mod_dir, package_root)
    write_archive(output, entries)

    with zipfile.ZipFile(output) as archive:
        names = archive.namelist()
        if not names or any(not name.startswith(f"{package_root}/") for name in names):
            raise SystemExit("archive root validation failed")
        if f"{package_root}/info.json" not in names:
            raise SystemExit("archive is missing info.json")
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
