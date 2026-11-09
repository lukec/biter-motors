import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from bitermotors_economy_catalog import EconomyCatalog, CATALOG, DATASET, TOKEN, DOLLAR


class CompactOrbitalPayloadTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = EconomyCatalog(json.loads(CATALOG.read_text()))

    def test_compact_tiers_preserve_cash_time_and_physical_equivalents(self):
        for suffix, expected_dollars in (("", 5), ("-cluster", 1),
                                         ("-grid-scale", 1), ("-hyperscale", 1)):
            raw = "bitermotors-orbital-ai-token" + suffix
            compact = "bitermotors-orbital-ai-dataset" + suffix
            raw_yield = self.catalog.output(raw, TOKEN)
            compact_yield = self.catalog.output(compact, DATASET) * 50000
            ratio = compact_yield / raw_yield
            self.assertEqual(expected_dollars, self.catalog.ingredient(compact, DOLLAR))
            self.assertEqual(ratio * self.catalog.ingredient(raw, DOLLAR), expected_dollars)
            self.assertEqual(ratio * self.catalog.recipe(raw)["energy_required"],
                             self.catalog.recipe(compact)["energy_required"])
            self.assertTrue(self.catalog.recipe(compact)["raise_on_crafted"])
            self.assertFalse(self.catalog.recipe(compact)["allow_quality"])

    def test_each_tier_unlocks_its_own_compact_recipe(self):
        for technology, suffix in (("orbital-compute", ""), ("orbital-cluster-training", "-cluster"),
                                   ("grid-scale-energy", "-grid-scale"),
                                   ("hyperscale-training", "-hyperscale")):
            effects = self.catalog.data["technologies"]["bitermotors-" + technology]["effects"]
            self.assertIn({"type": "unlock-recipe", "recipe": "bitermotors-orbital-ai-dataset" + suffix}, effects)

    def test_unpacking_is_lossless_not_a_quality_or_productivity_loop(self):
        name = "bitermotors-unpack-agi-training-dataset"
        self.assertEqual(1, self.catalog.ingredient(name, DATASET))
        self.assertEqual(50000, self.catalog.output(name, TOKEN))
        recipe = self.catalog.recipe(name)
        self.assertFalse(recipe["allow_productivity"])
        self.assertFalse(recipe["allow_quality"])
        ledger = (ROOT / "mod/bitermotors_0.1.1/runtime/ai_accounting.lua").read_text()
        self.assertNotIn(name, ledger)
        entry = self.catalog.data["technologies"]["bitermotors-orbital-compute"]["effects"]
        self.assertIn({"type": "unlock-recipe", "recipe": name}, entry)

    def test_native_fixture_checks_unpacking_without_earning_more_compute(self):
        fixture = (ROOT / "scripts/fixtures/ai-control.lua").read_text()
        self.assertIn("native Dataset unpacking conserves physical equivalents", fixture)
        self.assertIn("unpacking is not computation", fixture)
        self.assertIn("unpacking completes exactly once", fixture)

    def test_guidance_points_to_transportable_output_and_banked_work(self):
        control = (ROOT / "mod/bitermotors_0.1.1/control.lua").read_text()
        self.assertIn("Compute the first Orbital Training Dataset.", control)
        self.assertIn("Keep the input belt filtered to Dollars only.", control)
        self.assertNotIn("insufficient cooling resets the active AI Token batch", control)


if __name__ == "__main__":
    unittest.main()
