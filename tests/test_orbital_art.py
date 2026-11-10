import hashlib
import runpy
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ART = runpy.run_path(str(ROOT / "scripts/build-bitermotors-art.py"))
GRAPHICS = ROOT / "mod/bitermotors_0.1.1/graphics"


class OrbitalArtTests(unittest.TestCase):
    def test_alpha_dimensions_occupancy_and_distinct_sources(self):
        hashes = set()
        for slug in ART["ORBITAL_ENTITY_SLUGS"]:
            path = GRAPHICS / "entity" / slug / f"{slug}.png"
            hashes.add(hashlib.sha256(path.read_bytes()).hexdigest())
            with Image.open(path) as image:
                self.assertEqual(image.mode, "RGBA")
                self.assertEqual(image.size, (512, 512))
                alpha = image.getchannel("A")
                self.assertEqual(alpha.getpixel((0, 0)), 0)
                self.assertEqual(alpha.getextrema(), (0, 255))
                left, top, right, bottom = ART["alpha_bbox"](image)
                self.assertAlmostEqual((right - left) * 0.2, 96, delta=0.4)
                self.assertGreaterEqual(left, 14)
                self.assertGreater(top, 0)
                self.assertLess(bottom, 512)
            with Image.open(GRAPHICS / "icons" / f"{slug}.png") as icon:
                self.assertEqual(icon.size, (256, 256))
                self.assertEqual(icon.mode, "RGBA")
                self.assertEqual(icon.getpixel((0, 0))[3], 0)
        self.assertEqual(len(hashes), 3)

    def test_orbital_only_builder_reproduces_frozen_assets(self):
        builder = ART["build_orbital_entity_art"]
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            (output / "icons").mkdir()
            with patch.dict(builder.__globals__, MOD_GRAPHICS=output, ICON_DIR=output / "icons"):
                builder()
            files = list(output.rglob("*.png"))
            self.assertEqual(len(files), 6)
            for path in files:
                self.assertEqual(path.read_bytes(), (GRAPHICS / path.relative_to(output)).read_bytes())

    def test_dedicated_picture_and_animation_wiring(self):
        data = (ROOT / "mod/bitermotors_0.1.1/data.lua").read_text()
        self.assertIn('orbital_datacenter_core.graphics_set = generated_entity_animation("orbital-datacenter-core", 0.2)', data)
        self.assertIn('orbital_radiator_panel.picture = generated_entity_picture("orbital-radiator-panel", nil, 0.2)', data)
        self.assertIn('high_density_space_solar_panel.picture = generated_entity_picture("high-density-space-solar-panel", nil, 0.2)', data)


if __name__ == "__main__":
    unittest.main()
