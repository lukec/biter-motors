import hashlib
import importlib.util
import json
import stat
import subprocess
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
PACKAGE_SCRIPT = ROOT / "scripts" / "package-bitermotors.py"
CHECK_SCRIPT = ROOT / "scripts" / "check-bitermotors-release.py"
MOD = ROOT / "mod" / "bitermotors_0.1.1"


def load_package_module():
    spec = importlib.util.spec_from_file_location("package_bitermotors", PACKAGE_SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class ReleaseArtifactTest(unittest.TestCase):
    def build(self, output_dir: Path) -> Path:
        result = subprocess.run(
            ["python3", str(PACKAGE_SCRIPT), "--output-dir", str(output_dir)],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )
        archive = Path(result.stdout.strip())
        self.assertTrue(archive.is_file())
        return archive

    def test_release_documents_exist_and_are_consistent(self):
        license_text = (ROOT / "LICENSE").read_text()
        assets = (ROOT / "ASSET-LICENSE.md").read_text()
        attribution = (ROOT / "ATTRIBUTION.md").read_text()
        changelog = (ROOT / "CHANGELOG.md").read_text()
        self.assertIn("MIT License", license_text)
        self.assertIn("licensed separately under ASSET-LICENSE.md", license_text)
        self.assertIn("complete, unmodified Biter Motors mod package", assets)
        self.assertIn("redistribute", assets)
        self.assertIn("Factorio, Space Age", assets)
        self.assertIn("Electric Vehicles Factorio mod", attribution)
        self.assertIn("inspiration", attribution)
        self.assertIn("## 0.1.1 - Alpha", changelog)
        factorio_changelog = (MOD / "changelog.txt").read_text()
        self.assertEqual(len(factorio_changelog.splitlines()[0]), 99)
        self.assertIn("Version: 0.1.1", factorio_changelog)

    def test_package_has_deterministic_single_root_and_release_metadata(self):
        with tempfile.TemporaryDirectory() as first, tempfile.TemporaryDirectory() as second:
            first_archive = self.build(Path(first))
            second_archive = self.build(Path(second))
            self.assertEqual(
                hashlib.sha256(first_archive.read_bytes()).digest(),
                hashlib.sha256(second_archive.read_bytes()).digest(),
            )
            with zipfile.ZipFile(first_archive) as archive:
                names = archive.namelist()
                self.assertTrue(names)
                self.assertEqual({name.split("/", 1)[0] for name in names}, {"bitermotors_0.1.1"})
                manifest = json.loads(archive.read("bitermotors_0.1.1/info.json"))
                self.assertEqual(manifest["name"], "bitermotors")
                self.assertEqual(manifest["version"], "0.1.1")
                self.assertEqual(manifest["homepage"], "https://github.com/lukec/biter-motors")
                self.assertIn("bitermotors_0.1.1/changelog.txt", names)
                self.assertIn("bitermotors_0.1.1/LICENSE", names)
                self.assertIn("bitermotors_0.1.1/ASSET-LICENSE.md", names)
                self.assertIn("bitermotors_0.1.1/ATTRIBUTION.md", names)
                self.assertIn("bitermotors_0.1.1/CHANGELOG.md", names)
                self.assertIn("bitermotors_0.1.1/MEDIA-PROVENANCE.md", names)
                self.assertIn("bitermotors_0.1.1/PACKAGE-CONTENTS.json", names)
                self.assertTrue(all(info.date_time == (1980, 1, 1, 0, 0, 0) for info in archive.infolist()))

            subprocess.run(
                ["python3", str(CHECK_SCRIPT), str(first_archive), "--source", str(MOD.relative_to(ROOT)),
                 "--require-source-match"],
                cwd=ROOT,
                check=True,
            )

    def test_source_match_rejects_stale_wrong_version_and_duplicate_archives(self):
        spec = importlib.util.spec_from_file_location("check_bitermotors", CHECK_SCRIPT)
        checker = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(checker)
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            source = directory / "bitermotors_1.0.0"
            source.mkdir()
            (source / "info.json").write_text(json.dumps({"version": "1.0.0"}))
            expected = [("bitermotors_1.0.0/control.lua", b"current")]
            with mock.patch.object(checker.runpy, "run_path", return_value={
                "archive_entries": lambda path, root: expected
            }):
                archive_path = directory / "test.zip"
                for entries, message in (
                    ([(expected[0][0], b"stale")], "differs"),
                    ([("bitermotors_0.1.1/control.lua", b"current")], "manifest"),
                    (expected + [("extra.lua", b"extra")], "manifest"),
                ):
                    with self.subTest(message=message):
                        with zipfile.ZipFile(archive_path, "w") as archive:
                            for name, content in entries:
                                archive.writestr(name, content)
                        with self.assertRaisesRegex(SystemExit, message):
                            checker.inspect_source_match(archive_path, source)
                with zipfile.ZipFile(archive_path, "w") as archive:
                    archive.writestr(*expected[0])
                    with self.assertWarns(UserWarning):
                        archive.writestr(*expected[0])
                with self.assertRaisesRegex(SystemExit, "duplicate"):
                    checker.inspect_source_match(archive_path, source)

    def test_package_excludes_development_and_runtime_junk(self):
        package = load_package_module()
        excluded = (
            Path(".DS_Store"),
            Path("graphics/__pycache__/generated.png"),
            Path("control.pyc"),
            Path("control.pyo"),
            Path("art/model.blend1"),
        )
        for path in excluded:
            with self.subTest(path=path):
                self.assertFalse(package.should_include(path))
        self.assertTrue(package.should_include(Path("graphics/entity/sales-office.png")))

    def fixture(self, root, package):
        source = root / "mod/bitermotors_1.0.0"
        source.mkdir(parents=True)
        manifest = json.loads((MOD / "info.json").read_text())
        manifest["version"] = "1.0.0"
        (source / "info.json").write_text(json.dumps(manifest))
        (source / "changelog.txt").write_text("Version: 1.0.0\n")
        (source / "thumbnail.png").write_bytes((MOD / "thumbnail.png").read_bytes())
        for name in package.LEGAL_FILES:
            (root / name).write_text("release notice")
        for name in package.EXTRA_DOCUMENTS.values():
            path = root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("media origins")
        subprocess.run(["git", "init", "-q", str(root)], check=True)
        subprocess.run(["git", "-C", str(root), "add", "."], check=True)
        return source

    def test_only_approved_tracked_regular_files_can_ship(self):
        package = load_package_module()
        for name, tracked, message in (
            ("runtime/new.lua", False, "untracked"),
            (".env", True, "unapproved"),
            ("saves/latest.zip", True, "unapproved"),
            ("server-data/log.txt", True, "unapproved"),
            ("runtime/secret.lua", True, "credential"),
        ):
            with self.subTest(name=name), tempfile.TemporaryDirectory() as temp:
                root = Path(temp)
                source = self.fixture(root, package)
                path = source / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('api_key = "sk-' + 'X' * 40 + '"' if "secret" in name else "private")
                if tracked:
                    subprocess.run(["git", "-C", str(root), "add", "."], check=True)
                with mock.patch.object(package, "ROOT", root):
                    with self.assertRaisesRegex(SystemExit, message):
                        package.archive_entries(source, "bitermotors_1.0.0")

    def test_symlinks_and_missing_tracked_inputs_fail_closed(self):
        package = load_package_module()
        for kind in ("external-file", "external-directory", "missing"):
            with self.subTest(kind=kind), tempfile.TemporaryDirectory() as temp:
                root = Path(temp)
                source = self.fixture(root, package)
                path = source / "control.lua"
                path.write_text("return {}")
                subprocess.run(["git", "-C", str(root), "add", "."], check=True)
                path.unlink()
                if kind != "missing":
                    target = root / "outside"
                    if kind == "external-directory":
                        target.mkdir()
                    else:
                        target.write_text("private")
                    path.symlink_to(target)
                with mock.patch.object(package, "ROOT", root):
                    with self.assertRaisesRegex(SystemExit, "missing tracked|symlink"):
                        package.archive_entries(source, "bitermotors_1.0.0")

    def test_release_version_is_discovered_not_hardcoded(self):
        package = load_package_module()
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = self.fixture(root, package)
            with mock.patch.object(package, "ROOT", root), mock.patch.object(package, "MODS", root / "mod"):
                actual, manifest = package.read_manifest()
                self.assertEqual(actual, source)
                self.assertEqual(manifest["version"], "1.0.0")
                entries = dict(package.archive_entries(source, "bitermotors_1.0.0"))
                archive_path = root / "bitermotors_1.0.0.zip"
                package.write_archive(archive_path, sorted(entries.items()))
                result = subprocess.run(["python3", str(CHECK_SCRIPT), str(archive_path)],
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                inventory = json.loads(entries.pop("bitermotors_1.0.0/PACKAGE-CONTENTS.json"))
                self.assertEqual(inventory, {name.split("/", 1)[1]: hashlib.sha256(data).hexdigest()
                                             for name, data in entries.items()})
                (source / "info.json").write_text('{"name":"bitermotors","version":"../bad"}')
                with self.assertRaisesRegex(SystemExit, "numeric"):
                    package.read_manifest()

    def test_archive_checker_rejects_unsafe_paths_links_and_tampering(self):
        spec = importlib.util.spec_from_file_location("release_checker", CHECK_SCRIPT)
        checker = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(checker)
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            baseline = self.build(root / "baseline")
            for name in ("../escape.lua", "bitermotors_0.1.1/../escape.lua",
                         "bitermotors_0.1.1/.env", "bitermotors_0.1.1/runtime/link.lua",
                         "bitermotors_0.1.1/control.lua"):
                with self.subTest(name=name):
                    modified = root / "modified.zip"
                    with zipfile.ZipFile(baseline) as original, zipfile.ZipFile(modified, "w") as archive:
                        for entry in original.infolist():
                            if entry.filename != name:
                                archive.writestr(entry, original.read(entry))
                        entry = zipfile.ZipInfo(name)
                        if name.endswith("link.lua"):
                            entry.create_system = 3
                            entry.external_attr = (stat.S_IFLNK | 0o777) << 16
                        archive.writestr(entry, "tampered")
                    with self.assertRaisesRegex(SystemExit, "unsafe|unapproved|non-regular|checksums"):
                        checker.inspect_archive(modified)

    def test_audio_rebuild_matches_shipped_samples_without_external_sources(self):
        spec = importlib.util.spec_from_file_location("audio_builder", ROOT / "scripts/build-bitermotors-audio.py")
        builder = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(builder)
        with tempfile.TemporaryDirectory() as temp:
            builder.build(Path(temp))
            for name in ("ev-drivetrain-loop.wav", "ev-reverse-warning.wav"):
                self.assertEqual((Path(temp) / name).read_bytes(), (MOD / "sound" / name).read_bytes())
