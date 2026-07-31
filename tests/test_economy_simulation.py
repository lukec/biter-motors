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
        self.assertEqual(6_000, current)
        self.assertEqual(3_000, demanding)
        self.assertAlmostEqual(3.4131666667, economy.robotaxi_payback_hours(economy.CURRENT), places=6)

    def test_easier_terrestrial_progression_uses_approved_dollar_costs(self):
        self.assertEqual(
            [
                250,
                300,
                200,
                150,
                600,
                750,
                750,
                1_500,
                5_000,
                15_000,
                30_000,
                0,
                11_050,
            ],
            [stage.incremental_dollars for stage in economy.PROGRESSION],
        )

    def test_customer_replacements_and_bounded_local_growth(self):
        self.assertEqual(4, economy.MARKET.purchases_per_customer)
        self.assertEqual(4_000, economy.replacement_purchase_capacity(1_000))
        self.assertEqual(3_000, economy.organic_prospect_cap(1_000))
        self.assertEqual(15, economy.MARKET.organic_prospect_interval_minutes)
        self.assertEqual("affected settlement only", economy.MARKET.growth_suspension_scope)
        self.assertEqual((64, 128, 192, 256), economy.MARKET.charger_radii)

    def test_customer_capacity_rejects_negative_population(self):
        with self.assertRaises(ValueError):
            economy.replacement_purchase_capacity(-1)
        with self.assertRaises(ValueError):
            economy.organic_prospect_cap(-1)

    def test_report_generation_includes_easier_balance_contract(self):
        report = economy.report()
        for fragment in (
            "| V2 Charging Network | 150 |",
            "| Capital Scaling | 600 |",
            "| Terrestrial AI | 750 |",
            "| Autonomous Logistics | 750 |",
            "| Orbital Compute | 1,500 |",
            "1 Dollar per 2 allocated vehicle-minutes",
            "Each living customer can buy one of each consumer vehicle generation",
            "affected settlement only",
            "64 / 128 / 192 / 256",
            "5,000 consumer-sale Robotaxi gate: unchanged",
        ):
            self.assertIn(fragment, report)

    def test_campaign_counts_rebalanced_controller_and_final_megapacks(self):
        plan = economy.campaign_plan(economy.CURRENT)
        self.assertEqual(65_825, plan.pre_endgame_dollars)
        self.assertEqual(2_200, plan.consumed_megapack_opportunity_dollars)
        self.assertEqual(137_403, plan.direct_dollars)
        self.assertEqual(159_623, plan.economic_burden_dollars)


if __name__ == "__main__":
    unittest.main()
