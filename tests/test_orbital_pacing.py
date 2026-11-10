"""Approved native pacing contract, without running Factorio."""

import unittest

from tests.test_economy_simulation import economy


class OrbitalPacingTests(unittest.TestCase):
    def test_native_compact_and_raw_compute_preserve_time_cash_and_physical_payload(self):
        catalog = economy.EconomyCatalog.load()
        for suffix, tokens, datasets, dollars, seconds in (
            ("", 10000, 1, 5, 50),
            ("-cluster", 50000, 1, 1, 10),
            ("-grid-scale", 100000, 2, 1, 10),
            ("-hyperscale", 200000, 4, 1, 10),
        ):
            with self.subTest(tier=suffix or "entry"):
                raw = economy.P + "orbital-ai-token" + suffix
                compact = economy.P + "orbital-ai-dataset" + suffix
                self.assertEqual(10, catalog.recipe(raw)["energy_required"])
                self.assertAlmostEqual(10 / 1.5, catalog.seconds(raw, economy.CORE))
                self.assertEqual(seconds, catalog.recipe(compact)["energy_required"])
                self.assertEqual(tokens, catalog.output(raw, economy.TOKEN))
                self.assertEqual(datasets, catalog.output(compact, economy.DATASET))
                self.assertEqual(0, catalog.output(raw, economy.DATASET))
                self.assertEqual(0, catalog.output(compact, economy.TOKEN))
                self.assertEqual(1, catalog.ingredient(raw, economy.DOLLAR))
                self.assertEqual(dollars, catalog.ingredient(compact, economy.DOLLAR))
                raw_batches = datasets * 50000 / tokens
                self.assertAlmostEqual(catalog.seconds(raw, economy.CORE) * raw_batches,
                                       catalog.seconds(compact, economy.CORE))
                self.assertEqual(catalog.ingredient(raw, economy.DOLLAR) * raw_batches,
                                 catalog.ingredient(compact, economy.DOLLAR))

    def test_exact_four_research_counts_and_unchanged_per_cycle_dollars(self):
        catalog = economy.EconomyCatalog.load()
        for name, count, dollars in (
            ("orbital-compute", 500, 1),
            ("orbital-cluster-training", 300, 1),
            ("grid-scale-energy", 450, 1),
            ("hyperscale-training", 600, 2),
        ):
            with self.subTest(technology=name):
                unit = catalog.data["technologies"][economy.P + name]["unit"]
                self.assertEqual(count, unit["count"])
                self.assertEqual(60, unit["time"])
                self.assertEqual(dollars, dict(unit["ingredients"])[economy.DOLLAR])


if __name__ == "__main__":
    unittest.main()
