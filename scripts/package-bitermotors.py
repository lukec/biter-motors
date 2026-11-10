#!/usr/bin/env python3
"""Build a deterministic Factorio archive for the Biter Motors mod."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODS = ROOT / "mod"
LEGAL_FILES = ("LICENSE", "ASSET-LICENSE.md", "ATTRIBUTION.md", "CHANGELOG.md")
EXTRA_DOCUMENTS = {"MEDIA-PROVENANCE.md": "docs/media-provenance.md"}
INTEGRITY_FILE = "PACKAGE-CONTENTS.json"
FIXED_DATE = (1980, 1, 1, 0, 0, 0)
EXCLUDED_NAMES = {".DS_Store", "__pycache__"}
EXCLUDED_SUFFIXES = {".pyc", ".pyo", ".blend1"}
APPROVED_PATHS = re.compile(
    r"(?:info\.json|README\.md|changelog\.txt|thumbnail\.png|"
    r"(?:control|data|data-updates|data-final-fixes|settings)\.lua|"
    r"(?:runtime|prototypes)/[a-z0-9_-]+\.lua|"
    r"migrations/[0-9]+\.[0-9]+\.[0-9]+\.json|"
    r"locale/[a-zA-Z0-9_-]+/[a-z0-9_-]+\.cfg|"
    r"graphics/(?:[a-z0-9_-]+/)*[a-z0-9_-]+\.png|"
    r"sound/[a-z0-9_-]+\.wav)"
)
SECRET_PATTERNS = (
    rb"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----",
    rb"\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,})\b",
    rb"\bsk-(?:proj-)?[A-Za-z0-9_-]{32,}\b",
    rb"(?i)(?:rcon[-_ ]password|api[-_ ]key|access[-_ ]token)\s*[=:]\s*[\"'](?!<|\$)[^\"'\r\n]{8,}[\"']",
)


def validate_content(name: str, content: bytes) -> None:
    if any(re.search(pattern, content) for pattern in SECRET_PATTERNS):
        raise SystemExit(f"possible credential in release input: {name}")


def tracked_paths() -> set[str]:
    result = subprocess.run(
        ["git", "-C", str(ROOT), "ls-files", "-z"],
        check=True, capture_output=True,
    )
    return set(result.stdout.decode("utf-8").split("\0")) - {""}


def approved_bytes(path: Path, tracked: set[str]) -> bytes:
    relative = path.relative_to(ROOT)
    if any((ROOT / part).is_symlink() for part in (relative, *relative.parents)):
        raise SystemExit(f"symlink release input: {relative}")
    if relative.as_posix() not in tracked:
        raise SystemExit(f"untracked release input: {relative}")
    if not path.is_file():
        raise SystemExit(f"missing regular release input: {relative}")
    content = path.read_bytes()
    validate_content(str(relative), content)
    return content


def read_manifest() -> tuple[Path, dict]:
    manifests = sorted(MODS.glob("bitermotors_*/info.json"))
    if len(manifests) != 1:
        raise SystemExit(f"expected exactly one Biter Motors manifest, found {len(manifests)}")
    manifest_path = manifests[0]
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("name") != "bitermotors":
        raise SystemExit("mod manifest name must be bitermotors")
    version = manifest.get("version")
    if not isinstance(version, str) or not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version):
        raise SystemExit("mod manifest must contain a numeric three-part version")
    mod_dir = manifest_path.parent
    expected_dir = f"bitermotors_{version}"
    if mod_dir.name != expected_dir:
        raise SystemExit(f"mod directory {mod_dir.name!r} does not match manifest version {version!r}")
    return mod_dir, manifest


def should_include(path: Path) -> bool:
    return not any(part in EXCLUDED_NAMES for part in path.parts) and path.suffix not in EXCLUDED_SUFFIXES


def archive_entries(mod_dir: Path, package_root: str) -> list[tuple[str, bytes]]:
    mod_dir = mod_dir.absolute()
    tracked = tracked_paths()
    entries: list[tuple[str, bytes]] = []
    # Inspect directories too: rglob does not descend into symlink directories.
    for path in sorted(mod_dir.rglob("*")):
        if path.is_symlink():
            raise SystemExit(f"symlink release input: {path.relative_to(ROOT)}")
        if path.is_dir():
            continue
        relative = path.relative_to(mod_dir).as_posix()
        if not APPROVED_PATHS.fullmatch(relative) or not should_include(path):
            raise SystemExit(f"unapproved release path: {relative}")
        entries.append((f"{package_root}/{relative}", approved_bytes(path, tracked)))
    prefix = mod_dir.relative_to(ROOT).as_posix() + "/"
    present = {name for name, _ in entries}
    for name in tracked:
        if name.startswith(prefix) and f"{package_root}/{name[len(prefix):]}" not in present:
            raise SystemExit(f"missing tracked release input: {name}")
    for name in LEGAL_FILES:
        source = ROOT / name
        entries.append((f"{package_root}/{name}", approved_bytes(source, tracked)))
    for name, source in EXTRA_DOCUMENTS.items():
        entries.append((f"{package_root}/{name}", approved_bytes(ROOT / source, tracked)))
    inventory = {name.split("/", 1)[1]: hashlib.sha256(content).hexdigest()
                 for name, content in sorted(entries)}
    entries.append((f"{package_root}/{INTEGRITY_FILE}",
                    (json.dumps(inventory, indent=2, sort_keys=True) + "\n").encode()))
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
