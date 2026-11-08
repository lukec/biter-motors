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


def model_test_catalog():
    """Synthetic unit-test data only, never a native capture or generated report."""
    data = copy.deepcopy(economy.EconomyCatalog.load().data)
    if "agi_assembly_recipe" in data["runtime"]:
        return economy.EconomyCatalog(data)
    data["recipes"][economy.ASSEMBLE] = {
        "ingredients": [{"name": economy.DATASET, "amount": 20000},
                        {"name": economy.P + "datacenter-rack", "amount": 1}],
        "results": [{"name": economy.MODEL, "amount": 1}], "energy_required": 90,
        "allow_productivity": False, "allow_quality": False}
    data["recipes"][economy.ACTIVATE] = {
        "ingredients": [{"name": economy.MODEL, "amount": 1}],
        "results": [{"name": economy.MODEL, "amount": 1}], "energy_required": 30,
        "allow_productivity": False, "allow_quality": False}
    data["runtime"].update({
        "agi_assembly_recipe": economy.ASSEMBLE, "agi_activation_recipe": economy.ACTIVATE,
        "agi_assembly_seconds": 60, "agi_activation_seconds": 30,
        "agi_activation_power_watts": 8000000})
    data["runtime"]["compute_progress_policy"]["activation"] = "banked"
    # Explicit hypothetical mass for unit arithmetic, not a native weight claim.
    data["launch"]["item_weights_grams"][economy.P + "datacenter-rack"] = 100000
    return economy.EconomyCatalog(data)


class EconomySimulationTests(unittest.TestCase):
    def setUp(self):
        self.catalog = model_test_catalog()

    def altered(self):
        return economy.EconomyCatalog(copy.deepcopy(self.catalog.data))

    def test_capture_provenance_is_distinct_from_current_source_freshness(self):
        native = economy.EconomyCatalog.load()
        self.assertEqual(bool(native.freshness_errors()), native.data["source_sha256"] != catalog_module.source_fingerprint())
        self.assertEqual(self.catalog.data["capture"]["source_sha256"], self.catalog.data["source_sha256"])
        self.assertEqual("2.1.20", self.catalog.data["factorio_version"])
        self.assertFalse(any(name.startswith("bitermotors-smoke-") for name in self.catalog.data["recipes"]))

    def test_native_catalog_requires_new_contract_before_reporting(self):
        native = economy.EconomyCatalog.load()
        if "agi_assembly_recipe" not in native.runtime:
            with self.assertRaisesRegex(ValueError, "fresh native capture required"):
                native.model_ending()
        else:
            ending = native.model_ending()
            self.assertEqual(60, ending["assembly_seconds"])
            self.assertEqual(30, ending["activation_seconds"])
            self.assertEqual(8000000, ending["activation_watts"])

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
        catalog.runtime["agi_assembly_seconds"] /= 2
        changed = economy.campaign_plan(catalog)
        self.assertEqual(20, plan["bands"][0]["normal_cycle_seconds"])
        self.assertAlmostEqual(plan["orbital_one_core_hours"] / 2, changed["orbital_one_core_hours"])
        self.assertEqual(plan["orbital_operating_dollars"], changed["orbital_operating_dollars"])
        self.assertEqual(plan["orbital_generated_equivalents"], changed["orbital_generated_equivalents"])

    def test_physical_payload_accounts_for_tokens_spent_by_labs(self):
        plan = economy.campaign_plan(self.catalog)
        self.assertEqual([100, 180, 9901], [band["batches"] for band in plan["bands"]])
        self.assertEqual(2500, plan["orbital_research_tokens"])
        self.assertEqual(199, plan["early_datasets_packaged"])
        self.assertEqual(20001, plan["physical_datasets"] + plan["early_datasets_packaged"])
        self.assertGreaterEqual(plan["orbital_generated_equivalents"], self.catalog.runtime["agi_token_gate"])

    def test_compute_output_changes_required_batch_count(self):
        catalog = self.altered()
        catalog.data["recipes"][economy.ORBITAL_RECIPES[-2]]["results"][0]["amount"] *= 2
        changed = economy.campaign_plan(catalog)
        original = economy.campaign_plan(self.catalog)
        self.assertLess(changed["orbital_operating_dollars"], original["orbital_operating_dollars"])
        self.assertGreaterEqual(changed["physical_datasets"] + changed["early_datasets_packaged"], 20000)

    def test_native_model_timing_and_no_legacy_grid_double_count(self):
        plan = economy.campaign_plan(self.catalog)
        self.assertEqual(60, plan["model_ending"]["assembly_seconds"])
        self.assertEqual(30, plan["model_ending"]["activation_seconds"])
        self.assertEqual(8e6, plan["model_ending"]["activation_watts"])
        self.assertNotIn("final_capital_dollars", plan)
        self.assertNotIn("grid_battery_arrays", plan)
        expected = sum(count * self.catalog.item_dollars(item) for item, count in (
            (economy.P + "biterfactory-v2", 1), (economy.TERRESTRIAL, 1),
            (economy.P + "datacenter-rack", 1), (economy.CORE, 8),
            (economy.P + "high-density-space-solar-panel", plan["space_panels"]),
            (economy.P + "orbital-radiator-panel", plan["radiators"])))
        self.assertEqual(expected, plan["construction_dollars"])
        self.assertEqual(plan["direct_dollars"], sum(plan[key] for key in (
            "research_dollars", "construction_dollars", "terrestrial_operating_dollars",
            "orbital_operating_dollars", "ordinary_ai_retry_dollars")))
        self.assertNotIn("bitermotors-hyperscale-training", economy.REQUIRED_TECHNOLOGIES)
        self.assertNotIn("bitermotors-planetary-energy-grid", economy.REQUIRED_TECHNOLOGIES)
        self.assertEqual(0, plan["research_science"]["space-science-pack"])
        self.assertGreater(economy.campaign_plan(self.catalog, hyperscale=True)["research_dollars"],
                           plan["research_dollars"])

    def test_native_contract_is_required_and_timing_is_cross_checked(self):
        catalog = self.altered()
        del catalog.runtime["agi_assembly_recipe"]
        with self.assertRaisesRegex(ValueError, "fresh native capture required"):
            economy.campaign_plan(catalog)
        catalog = self.altered()
        catalog.runtime["agi_assembly_seconds"] = 90
        with self.assertRaisesRegex(ValueError, "disagrees"):
            economy.campaign_plan(catalog)

    def test_extra_final_fee_and_white_research_fail_closed(self):
        catalog = self.altered()
        catalog.recipe(economy.ASSEMBLE)["ingredients"].append({"name": economy.DOLLAR, "amount": 1})
        with self.assertRaisesRegex(ValueError, "fee or payload"):
            economy.campaign_plan(catalog)
        catalog = self.altered()
        catalog.data["technologies"]["bitermotors-grid-scale-energy"]["unit"]["ingredients"].append(
            ["space-science-pack", 1])
        with self.assertRaisesRegex(ValueError, "white science"):
            economy.campaign_plan(catalog)

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
        self.assertLessEqual(case["grid_batteries_sold_in_window"], 1000)
        self.assertFalse(case["taxi_gate_ready_from_required_generations"])
        self.assertIsNotNone(case["funding_window_hours"])
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
        self.assertEqual(260, retry["ordinary_ai_retry_dollars"])
        self.assertEqual(260, retry["terrestrial_ai_retry_dollars"])
        self.assertEqual(0, retry["orbital_ai_retry_dollars"])
        self.assertNotIn("final_capital_dollars", retry)
        self.assertEqual(base["direct_dollars"] + retry["ordinary_ai_retry_dollars"], retry["direct_dollars"])

    def test_progress_policy_must_match_native_capture(self):
        catalog = self.altered()
        self.assertEqual({"terrestrial": "scrap", "orbital": "banked", "activation": "banked"},
                         catalog.runtime["compute_progress_policy"])
        catalog.runtime["compute_progress_policy"]["orbital"] = "reset"
        with self.assertRaisesRegex(ValueError, "unsupported native compute-progress policy"):
            economy.campaign_plan(catalog)

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

    def test_report_discloses_limits_without_legacy_charge(self):
        report = economy.report(self.catalog)
        for claim in ("Not a total campaign-time forecast", "active", "Finite battery adoption",
                      "Phase 4 remains open", "No balance values are changed"):
            self.assertIn(claim.lower(), report.lower())
        self.assertNotIn("10 GW", report)
        self.assertNotIn("20 uninterrupted", report)

    def test_report_names_cash_sinks_and_distinguishes_starting_scopes(self):
        report = economy.report(self.catalog)
        for text in ("Default cash budget skips Hyperscale", "terrestrial EV/energy research",
                     "not a full crash-landing budget", "orbital study starts later",
                     "different scopes, not competing totals", "Direct cash total (no Hyperscale)",
                     "automation (red)", "logistic (green)", "chemical (blue)",
                     "production (purple)", "utility (yellow)", "no space (white)"):
            self.assertIn(text, report)
        for key in ("research_dollars", "construction_dollars", "direct_dollars"):
            self.assertNotIn(key, report)

    def test_generated_report_matches_fresh_native_catalog(self):
        native = economy.EconomyCatalog.load()
        self.assertEqual([], native.freshness_errors())
        self.assertEqual(economy.report(native), (ROOT / "docs/economy-balance.md").read_text())


if __name__ == "__main__":
    unittest.main()
