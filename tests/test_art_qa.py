import hashlib
import importlib.util
import json
import subprocess
import sys
import unittest
from pathlib import Path
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
GENERATOR = ROOT / "scripts/build-bitermotors-art-qa.py"
SPEC = importlib.util.spec_from_file_location("bitermotors_art_qa", GENERATOR)
ART_QA = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = ART_QA
SPEC.loader.exec_module(ART_QA)


class ArtQaTests(unittest.TestCase):
    def records(self):
        return ART_QA.critical_asset_records()

    def test_critical_inventory_covers_readiness_matrix(self):
        records = self.records()
        ids = {record["prototype_id"] for record in records}
        expected = {
            "bitermotors-sales-office",
            "bitermotors-ev-charging-station",
            "bitermotors-ev-charging-station-v2",
            "bitermotors-ev-charging-station-v3",
            "bitermotors-ev-charging-station-v4",
            "bitermotors-biterfactory-building",
            "bitermotors-biterfactory-v2",
            "bitermotors-bitertaxi-depot",
            "bitermotors-high-density-solar-array",
            "bitermotors-tandem-solar-array",
            "bitermotors-grid-battery",
            "bitermotors-grid-battery-array",
            "bitermotors-terrestrial-datacenter",
            "bitermotors-orbital-datacenter-core",
            "bitermotors-orbital-radiator-panel",
            "bitermotors-high-density-space-solar-panel",
            "bitermotors-planetary-grid-controller",
            "bitermotors-prototype-roadster",
            "bitermotors-premium-ev",
            "bitermotors-mass-market-ev",
            "bitermotors-megatruck",
            "bitermotors-bitertaxi-fleet",
            "bitermotors-cybertrain",
            "bitermotors-cybertrain-charging-stop",
            "bitermotors-espider",
            "bitermotors-agi-training-dataset",
            "bitermotors-agi-model",
        }
        self.assertTrue(expected <= ids)
        self.assertEqual(len(ids), len(records))
        self.assertEqual(len([r for r in records if r["kind"] == "vehicle"]), 5)
        self.assertEqual(len({r["review_id"] for r in records}), len(records))

    def test_referenced_files_and_png_dimensions_match_metadata(self):
        for record in self.records():
            for key in ("source_path", "icon_path"):
                ref = record[key]
                if not ref or ref.startswith("base:") or ref == "base-art":
                    continue
                path = (ART_QA.OUTPUT_DIR / ref).resolve()
                self.assertTrue(path.is_file(), f"{record['prototype_id']} {key}: {path}")
                dims = ART_QA.png_size(path)
                expected_key = "source_dimensions" if key == "source_path" else "icon_dimensions"
                if expected_key in record:
                    self.assertEqual(record[expected_key], list(dims), record["prototype_id"])
            if record.get("source_dimensions") and record["kind"] == "entity":
                width, height = record["source_dimensions"]
                self.assertEqual(record["preview_dimensions"],
                                 [round(width * record["scale"]), round(height * record["scale"])])

    def test_orbital_identical_reuse_is_explicit_and_pending(self):
        records = {r["prototype_id"]: r for r in self.records()}
        radiator = records["bitermotors-orbital-radiator-panel"]
        solar = records["bitermotors-high-density-space-solar-panel"]
        self.assertEqual(radiator["source_path"], "base-art")
        self.assertEqual(solar["source_path"], "base-art")
        self.assertEqual(radiator["status"], "inherited-placeholder")
        self.assertEqual(solar["status"], "inherited-placeholder")

    def test_orbital_entry_preview_matches_current_compact_footprints(self):
        records = {r["prototype_id"]: r for r in self.records()}
        for name in ("orbital-datacenter-core", "orbital-radiator-panel", "high-density-space-solar-panel"):
            self.assertEqual([3, 3], records[f"bitermotors-{name}"]["footprint_tiles"])
        self.assertEqual(0.18, records["bitermotors-orbital-datacenter-core"]["scale"])

    def test_animation_sheet_dimensions_are_real_and_guarded(self):
        for name, filename, frame_width, frame_height, _ in ART_QA.ANIMATIONS:
            path = ART_QA.GRAPHICS / "animation" / filename
            width, height = ART_QA.png_size(path)
            self.assertEqual((width, height), (frame_width * 8, frame_height), name)

    def test_generation_is_deterministic(self):
        subprocess.run([sys.executable, str(GENERATOR)], check=True, cwd=ROOT, capture_output=True)
        outputs = [ART_QA.OUTPUT_DIR / "index.html", ART_QA.OUTPUT_DIR / "art-manifest.json"]
        before = [hashlib.sha256(path.read_bytes()).hexdigest() for path in outputs]
        subprocess.run([sys.executable, str(GENERATOR)], check=True, cwd=ROOT, capture_output=True)
        after = [hashlib.sha256(path.read_bytes()).hexdigest() for path in outputs]
        self.assertEqual(before, after)
        manifest = json.loads(outputs[1].read_text())
        self.assertEqual(len(manifest["critical_assets"]), len(self.records()))
        self.assertEqual(len(manifest["animation_assets"]), len(ART_QA.ANIMATIONS))

    def test_missing_required_asset_raises_guard(self):
        with patch.object(ART_QA, "GRAPHICS", ROOT / "missing-graphics"):
            with self.assertRaises((FileNotFoundError, ValueError)):
                ART_QA.critical_asset_records()

    def test_inventory_only_items_do_not_claim_spidertron_entity_art(self):
        records = {r["prototype_id"]: r for r in self.records()}
        for item in ("bitermotors-agi-training-dataset", "bitermotors-agi-model"):
            self.assertIsNone(records[item]["source_path"])
        self.assertEqual("base-art", records["bitermotors-espider"]["source_path"])

    def test_large_animation_previews_fit_without_cropping(self):
        html = ART_QA.animation_cards()
        self.assertIn("--preview-scale:0.3125", html)
        self.assertIn('data-id="animation:biterfactory-v1-activity"', html)


if __name__ == "__main__":
    unittest.main()
