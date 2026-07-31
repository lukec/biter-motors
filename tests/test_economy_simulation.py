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

    def test_orbital_ai_uses_the_four_cumulative_token_bands(self):
        plan = economy.optimal_ai_plan(economy.CURRENT)
        self.assertEqual(3, plan.milestone_level)
        self.assertEqual((100, 360, 1_800, 9_000), plan.dollars_by_band)
        self.assertEqual(11_260, plan.operating_dollars)
        self.assertEqual(61_260, plan.total_dollars)
        self.assertAlmostEqual(93.833333, plan.one_core_hours, places=5)

    def test_orbital_milestones_match_approved_capital_costs(self):
        self.assertEqual(
            ((1_000_000, 10_000, 1, 5_000),
             (10_000_000, 25_000, 1, 15_000),
             (100_000_000, 50_000, 1, 30_000),
             (1_000_000_000, 100_000, 1, 0)),
            economy.ORBITAL_AI_MILESTONES,
        )
        self.assertEqual(50_000, economy.FINAL_CAPITAL_ALLOCATIONS * economy.CAPITAL_ALLOCATION_DOLLARS)

    def test_approved_power_assets_hit_ten_gigawatts(self):
        plan = economy.power_plan(economy.CURRENT)
        self.assertEqual(10_000_000_000, plan.watts)
        self.assertEqual(4_762, plan.tandem_arrays)
        self.assertEqual(1_001, plan.grid_megapacks)
        self.assertEqual(3_000_000, economy.TANDEM_SOLAR_PEAK_WATTS)
        self.assertEqual(1_000_000_000, economy.GRID_MEGAPACK_CAPACITY_JOULES)

    def test_higher_power_sensitivity_scales_assets(self):
        plan = economy.power_plan(economy.RELEASE_CANDIDATE)
        self.assertEqual(5_715, plan.tandem_arrays)
        self.assertEqual(1_201, plan.grid_megapacks)
        self.assertEqual(5_715, plan.tandem_recipe_dollars)
        self.assertEqual(6_005, plan.grid_megapack_recipe_dollars)
        self.assertAlmostEqual(6_093.75, plan.solar_research_dollars, places=2)

    def test_robotaxi_revenue_uses_recurring_vehicle_minutes(self):
        current = economy.robotaxi_revenue_per_hour(economy.CURRENT, 1)
        demanding = economy.robotaxi_revenue_per_hour(economy.DEMANDING_RELEASE, 1)
        self.assertEqual(2_400, current)
        self.assertEqual(1_200, demanding)

    def test_campaign_counts_rebalanced_controller_and_final_megapacks(self):
        plan = economy.campaign_plan(economy.CURRENT)
        self.assertEqual(70_375, plan.pre_endgame_dollars)
        self.assertEqual(2_200, plan.consumed_megapack_opportunity_dollars)
        self.assertEqual(141_953, plan.direct_dollars)
        self.assertEqual(164_173, plan.economic_burden_dollars)


if __name__ == "__main__":
    unittest.main()
