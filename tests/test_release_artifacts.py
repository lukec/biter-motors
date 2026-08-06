import hashlib
import importlib.util
import json
import subprocess
import tempfile
import unittest
import zipfile
from pathlib import Path


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
        self.assertIn("All rights reserved", assets)
        self.assertIn("Factorio, Space Age", assets)
        self.assertIn("Electric Vehicles Factorio mod", attribution)
        self.assertIn("does not vendor, copy, or link against", attribution)
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
                self.assertTrue(all(info.date_time == (1980, 1, 1, 0, 0, 0) for info in archive.infolist()))

            subprocess.run(
                ["python3", str(CHECK_SCRIPT), str(first_archive), "--source", str(MOD)],
                cwd=ROOT,
                check=True,
            )

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
