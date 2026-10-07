import copy
import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/simulate_bitermotors_economy.py"
SPEC = importlib.util.spec_from_file_location("economy_simulation", SCRIPT)
economy = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = economy
SPEC.loader.exec_module(economy)
import bitermotors_economy_catalog as catalog_module


class EconomySimulationTests(unittest.TestCase):
    def setUp(self):
        self.catalog = economy.EconomyCatalog.load()

    def altered(self):
        return economy.EconomyCatalog(copy.deepcopy(self.catalog.data))

    def test_native_snapshot_matches_current_mod_source(self):
        self.assertEqual([], economy.validate_source_snapshot())
        self.assertEqual(self.catalog.data["capture"]["source_sha256"], self.catalog.data["source_sha256"])
        self.assertEqual("2.1.20", self.catalog.data["factorio_version"])
        self.assertFalse(any(name.startswith("bitermotors-smoke-") for name in self.catalog.data["recipes"]))

    def test_stale_source_is_rejected_not_refreshed_by_model(self):
        catalog = self.altered()
        catalog.data["source_sha256"] = "old-source"
        self.assertEqual(1, len(catalog.freshness_errors()))
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "catalog.json"
            path.write_text(json.dumps(catalog.data))
            result = subprocess.run([sys.executable, str(SCRIPT), "--catalog", str(path), "--check-source"],
                                    capture_output=True, text=True)
        self.assertNotEqual(0, result.returncode)
        self.assertIn("catalog is stale", result.stderr)
        self.assertEqual("", result.stdout)

    def test_capture_hashes_reject_modified_artifacts_and_source(self):
        with tempfile.TemporaryDirectory() as directory:
            dump, runtime = Path(directory) / "dump.json", Path(directory) / "runtime.json"
            dump.write_text("{}")
            runtime.write_text("{}")
            manifest = catalog_module.capture_manifest(dump, runtime, catalog_module.source_fingerprint())
            catalog_module.verify_capture(dump, runtime, manifest)
            runtime.write_text('{"different": true}')
            with self.assertRaisesRegex(ValueError, "hashes do not match"):
                catalog_module.verify_capture(dump, runtime, manifest)
            with self.assertRaisesRegex(ValueError, "source changed"):
                catalog_module.capture_manifest(dump, runtime, "stale-source")

    def test_research_totals_multiply_final_native_ingredient_amounts(self):
        catalog = self.altered()
        unit = catalog.data["technologies"]["bitermotors-orbital-compute"]["unit"]
        unit["count"] = 100
        unit["ingredients"] = [[economy.DOLLAR, 3], [economy.TOKEN, 2]]
        self.assertEqual(300, catalog.research("bitermotors-orbital-compute"))
        self.assertEqual(200, catalog.research("bitermotors-orbital-compute", economy.TOKEN))

    def test_pre_orbital_research_compute_is_not_free(self):
        plan = economy.campaign_plan(self.catalog)
        tokens = sum(self.catalog.research(name, economy.TOKEN) for name in (
            "bitermotors-autonomous-logistics", "bitermotors-orbital-compute"))
        self.assertEqual(2250, tokens)
        self.assertEqual(tokens, plan["terrestrial_research_tokens"])
        self.assertEqual(113, plan["terrestrial_batches"])
        self.assertEqual(2260, plan["terrestrial_operating_dollars"])
        self.assertEqual(56.5, plan["terrestrial_active_minutes"])
        catalog = self.altered()
        catalog.data["technologies"]["bitermotors-orbital-compute"]["unit"]["count"] += 100
        changed = economy.campaign_plan(catalog)
        self.assertEqual(100, changed["terrestrial_research_tokens"] - tokens)
        self.assertEqual(100, changed["terrestrial_operating_dollars"] - plan["terrestrial_operating_dollars"])

    def test_recipe_speed_changes_time_not_cash_or_earned_output(self):
        plan = economy.campaign_plan(self.catalog)
        catalog = self.altered()
        catalog.data["entities"][economy.CORE]["crafting_speed"] *= 2
        changed = economy.campaign_plan(catalog)
        self.assertEqual(20, plan["bands"][0]["normal_cycle_seconds"])
        self.assertAlmostEqual(plan["orbital_one_core_hours"] / 2, changed["orbital_one_core_hours"])
        self.assertEqual(plan["orbital_operating_dollars"], changed["orbital_operating_dollars"])
        self.assertEqual(plan["orbital_generated_equivalents"], changed["orbital_generated_equivalents"])

    def test_physical_payload_accounts_for_tokens_spent_by_labs(self):
        plan = economy.campaign_plan(self.catalog)
        self.assertEqual([100, 360, 1800, 9001], [band["batches"] for band in plan["bands"]])
        self.assertEqual(8000, plan["orbital_research_tokens"])
        self.assertEqual(199, plan["early_datasets_packaged"])
        self.assertEqual(20001, plan["physical_datasets"] + plan["early_datasets_packaged"])
        self.assertGreaterEqual(plan["orbital_generated_equivalents"], self.catalog.runtime["agi_token_gate"])

    def test_compute_output_changes_required_batch_count(self):
        catalog = self.altered()
        catalog.data["recipes"][economy.ORBITAL_RECIPES[-1]]["results"][0]["amount"] *= 2
        changed = economy.campaign_plan(catalog)
        original = economy.campaign_plan(self.catalog)
        self.assertLess(changed["orbital_operating_dollars"], original["orbital_operating_dollars"])
        self.assertGreaterEqual(changed["physical_datasets"] + changed["early_datasets_packaged"], 20000)

    def test_grid_and_consumed_storage_are_not_counted_twice(self):
        plan = economy.campaign_plan(self.catalog)
        self.assertEqual(4762, plan["tandem_arrays"])
        self.assertEqual(1001, plan["grid_battery_arrays"])
        self.assertEqual(110, plan["consumed_grid_battery_arrays"])
        self.assertEqual(1111, plan["power_material_bill"]["grid_battery_arrays_including_consumed"])
        self.assertEqual(20, plan["final_training_minutes"])
        self.assertEqual(12e12, plan["normal_final_run_energy_joules"])

    def test_power_changes_scale_physical_assets(self):
        catalog = self.altered()
        catalog.data["entities"][economy.CONTROLLER]["energy_usage"] = "20GW"
        changed = economy.campaign_plan(catalog)
        self.assertEqual(9524, changed["tandem_arrays"])
        self.assertEqual(2001, changed["grid_battery_arrays"])
        self.assertEqual(24e12, changed["normal_final_run_energy_joules"])

    def test_recursive_construction_cash_and_optional_branches(self):
        self.assertEqual(250, self.catalog.item_dollars("bitermotors-biterfactory-v2"))
        self.assertEqual(10, self.catalog.item_dollars(economy.TERRESTRIAL))
        self.assertEqual(5, self.catalog.item_dollars(economy.ARRAY))
        self.assertEqual(0, self.catalog.item_dollars(economy.TANDEM))
        plan = economy.campaign_plan(self.catalog)
        self.assertEqual(54500, plan["research_dollars"])
        self.assertEqual(134836, plan["direct_dollars"])
        self.assertNotIn("foundry", economy.REQUIRED_TECHNOLOGIES)
        self.assertNotIn("bitermotors-megatruck-engineering", economy.REQUIRED_TECHNOLOGIES)
        self.assertEqual(22220, plan["grid_battery_opportunity_dollars"])
        self.assertEqual(plan["direct_dollars"], sum(plan[key] for key in (
            "research_dollars", "construction_dollars", "terrestrial_operating_dollars",
            "orbital_operating_dollars", "final_capital_dollars", "ordinary_ai_retry_dollars")))

    def test_missing_or_cyclic_construction_routes_fail_closed(self):
        catalog = self.altered()
        del catalog.data["recipes"][economy.ARRAY]
        with self.assertRaises(KeyError):
            catalog.item_dollars(economy.ARRAY)
        catalog = self.altered()
        catalog.recipe(economy.ARRAY)["ingredients"] = [{"name": economy.ARRAY, "amount": 1}]
        with self.assertRaisesRegex(ValueError, "cyclic"):
            catalog.item_dollars(economy.ARRAY)

    def test_five_settlement_market_has_a_finite_ceiling(self):
        case = economy.finite_market(self.catalog, economy.SCENARIOS[0])
        self.assertEqual(3000, case["consumer_purchase_capacity"])
        self.assertEqual(24000, case["finite_profit_ceiling_without_taxis"])
        self.assertEqual(1000, case["grid_batteries_sold_in_window"])
        self.assertFalse(case["taxi_gate_ready_from_required_generations"])
        self.assertIsNone(case["funding_window_hours"])
        self.assertEqual(667, case["new_customers_needed_for_taxi_gate"])
        self.assertEqual(33.35, case["organic_only_taxi_gate_wait_hours"])

    def test_overlapping_depots_cannot_duplicate_customer_revenue(self):
        minimal = economy.Scenario("shared", 10, 200, 10, 2, 8)
        excess = economy.Scenario("overlap", 10, 200, 10, 20, 8)
        first = economy.finite_market(self.catalog, minimal)
        second = economy.finite_market(self.catalog, excess)
        self.assertEqual(400, first["fleet_size"])
        self.assertEqual(first["net_taxi_dollars_per_hour"], second["net_taxi_dollars_per_hour"])
        self.assertEqual(first["depot_capex"], second["depot_capex"])
        self.assertLess(first["full_fleet_cash_payback_hours"], 1)

    def test_taxi_fleet_cap_comes_from_runtime_not_chest_output_slots(self):
        catalog = self.altered()
        catalog.runtime["bitertaxi_max_fleet"] = 100
        case = economy.finite_market(catalog, economy.SCENARIOS[1])
        self.assertEqual(200, case["fleet_size"])
        self.assertEqual(43, catalog.data["entities"][economy.DEPOT]["inventory_size"])

    def test_battery_adoption_is_finite_and_rate_limited(self):
        case = economy.finite_market(self.catalog, economy.SCENARIOS[0], horizon_hours=1)
        self.assertLess(case["grid_batteries_sold_in_window"], case["grid_battery_sale_ceiling"])
        self.assertGreater(case["grid_batteries_sold_in_window"], 0)
        catalog = self.altered()
        catalog.runtime["grid_battery_initial_adoption"] = 0
        no_seed = economy.finite_market(catalog, economy.SCENARIOS[0], horizon_hours=1)
        self.assertEqual(0, no_seed["grid_batteries_sold_in_window"])

    def test_failed_compute_adds_ordinary_cost_not_final_capital(self):
        base = economy.campaign_plan(self.catalog)
        retry = economy.campaign_plan(self.catalog, failed_fraction=0.1)
        self.assertEqual(1512, retry["ordinary_ai_retry_dollars"])
        self.assertEqual(base["final_capital_dollars"], retry["final_capital_dollars"])
        self.assertEqual(base["direct_dollars"] + retry["ordinary_ai_retry_dollars"], retry["direct_dollars"])

    def test_invalid_workloads_are_rejected(self):
        for failure in (-0.1, 1, 1.1):
            with self.subTest(failure=failure), self.assertRaises(ValueError):
                economy.retry_batches(10, failure)
        with self.assertRaises(ValueError):
            economy.campaign_plan(self.catalog, cores=0)
        with self.assertRaises(ValueError):
            economy.finite_market(self.catalog, economy.Scenario("empty", 0, 200, 1, 1, 1))
        with self.assertRaises(ValueError):
            economy.finite_market(self.catalog, economy.Scenario("negative", 1, 200, 1, -1, 1))

    def test_report_matches_generated_document_and_discloses_limits(self):
        report = economy.report(self.catalog)
        self.assertEqual(report + "\n" if not report.endswith("\n") else report,
                         (ROOT / "docs/economy-balance.md").read_text())
        for claim in ("Not a total campaign-time forecast", "active", "finite battery adoption",
                      "not another cash bill", "Phase 4 remains open", "No balance values are changed"):
            self.assertIn(claim, report)


if __name__ == "__main__":
    unittest.main()
