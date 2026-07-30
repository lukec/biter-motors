import importlib.util
import sys
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = REPO_ROOT / "scripts/simulate_bitermotors_economy.py"
SPEC = importlib.util.spec_from_file_location("economy_simulation", SCRIPT)
economy = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
sys.modules[SPEC.name] = economy
SPEC.loader.exec_module(economy)


class EconomySimulationTests(unittest.TestCase):
    def test_modeled_values_match_mod_source(self):
        self.assertEqual([], economy.validate_source_snapshot())

    def test_current_ai_efficiency_has_a_finite_optimum(self):
        plan = economy.optimal_ai_plan(economy.CURRENT)
        self.assertEqual(4, plan.efficiency_level)
        self.assertGreater(plan.total_dollars, 7_000_000)
        self.assertLess(plan.total_dollars, 7_500_000)

    def test_candidate_ai_cost_is_below_one_hundred_thousand(self):
        plan = economy.optimal_ai_plan(economy.RELEASE_CANDIDATE)
        self.assertEqual(2, plan.efficiency_level)
        self.assertGreater(plan.total_dollars, 80_000)
        self.assertLess(plan.total_dollars, 90_000)

    def test_current_solar_only_endgame_requires_millions_of_panels(self):
        plan = economy.power_plan(economy.CURRENT)
        self.assertEqual(4_761_905, plan.panels)
        self.assertEqual(1_000_001, plan.megapacks)

    def test_release_candidate_remains_a_large_power_build(self):
        plan = economy.power_plan(economy.RELEASE_CANDIDATE)
        self.assertEqual(47_620, plan.panels)
        self.assertEqual(10_001, plan.megapacks)
        self.assertAlmostEqual(34_014.29, plan.panel_recipe_dollars, places=2)
        self.assertAlmostEqual(6_093.75, plan.solar_research_dollars, places=2)

    def test_robotaxi_candidate_improves_revenue_twenty_fold(self):
        current = economy.robotaxi_revenue_per_hour(economy.CURRENT, 1)
        candidate = economy.robotaxi_revenue_per_hour(economy.RELEASE_CANDIDATE, 1)
        self.assertEqual(120, current)
        self.assertEqual(2_400, candidate)

    def test_campaign_counts_controller_and_final_megapacks(self):
        plan = economy.campaign_plan(economy.RELEASE_CANDIDATE)
        self.assertEqual(22_850, plan.pre_endgame_dollars)
        self.assertEqual(22_000, plan.consumed_megapack_opportunity_dollars)


if __name__ == "__main__":
    unittest.main()
