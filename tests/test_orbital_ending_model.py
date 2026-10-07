import copy
import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from dataclasses import replace
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/model_orbital_ending.py"
sys.path.insert(0, str(ROOT / "scripts"))
SPEC = importlib.util.spec_from_file_location("orbital_ending_model", SCRIPT)
model = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = model
SPEC.loader.exec_module(model)


class OrbitalEndingTests(unittest.TestCase):
    def setUp(self):
        self.catalog = model.EconomyCatalog.load()
        self.proposal = model.Proposal()

    def test_real_engine_weights_expose_hardware_uplift_gap(self):
        result = model.shipments(self.catalog, {model.CORE: 1, model.DOLLAR: 100})
        self.assertEqual([model.CORE], result["blocked_items"])
        self.assertIsNone(result["rockets"])
        self.assertEqual(3, result["capacity_per_rocket"][model.DOLLAR])
        self.assertEqual(1208326, self.catalog.data["launch"]["item_weights_grams"][model.CORE])

    def test_proposed_mass_is_explicit_and_does_not_change_native_catalog(self):
        before = copy.deepcopy(self.catalog.data)
        candidate = model.proposed_catalog(self.catalog, self.proposal)
        self.assertEqual(before, self.catalog.data)
        result = model.shipments(candidate, {model.CORE: 12, model.DOLLAR: 5681})
        self.assertFalse(result["blocked_items"])
        self.assertEqual(3, result["rockets"])
        self.assertEqual(100000, result["capacity_per_rocket"][model.DOLLAR])

    def test_native_capture_includes_vanilla_manufacturing_and_inventory_limits(self):
        self.assertIn("rocket-silo", self.catalog.data["manufacturing_recipes"])
        self.assertIn("utility-science-pack", self.catalog.data["manufacturing_recipes"])
        self.assertEqual(20, self.catalog.data["launch"]["inventory_slots"])
        self.assertEqual(50, self.catalog.data["launch"]["parts_per_rocket"])
        self.assertIn("space-platform-starter-pack", self.catalog.data["items"])

    def test_shipments_round_per_item_and_obey_both_constraints(self):
        candidate = model.proposed_catalog(self.catalog, self.proposal)
        # Identical aggregate mass is not a license to mix automated cargo types.
        one = model.shipments(candidate, {model.CORE: 1, model.RADIATOR: 1})
        self.assertEqual(2, one["rockets"])
        candidate.data["launch"]["item_weights_grams"][model.CORE] = 1
        limited = model.shipments(candidate, {model.CORE: 21})
        self.assertEqual(20, limited["capacity_per_rocket"][model.CORE])
        self.assertEqual(2, limited["rockets"])

    def test_first_and_full_layout_preserve_starter_foundation_distinction(self):
        first = model.hardware_plan(self.catalog, self.proposal, cores=1, operating_dollars=100)
        full = model.hardware_plan(self.catalog, self.proposal, operating_dollars=5681)
        self.assertEqual((9, 35), (first["rockets"], full["rockets"]))
        self.assertEqual(1200, full["payload"]["space-platform-foundation"])
        self.assertEqual(1300, full["placed_foundation_tiles"])
        candidate = model.proposed_catalog(self.catalog, self.proposal)
        bill = model.supply_bill(candidate, full["manufacturing_roots"])
        self.assertEqual(1260, bill["recipe_batches"]["space-platform-foundation"])
        self.assertEqual(1750, full["launch_ingredients"]["rocket-fuel"])
        self.assertEqual(87.5, full["assembly_only_silo_minutes"])
        self.assertNotIn(model.P + "datacenter-rack", first["manufacturing_roots"])
        final = model.hardware_plan(self.catalog, self.proposal, include_final_model=True)
        self.assertEqual(1, final["manufacturing_roots"][model.P + "datacenter-rack"])

    def test_each_platform_has_its_own_starter_and_payload_rounding(self):
        one = model.hardware_plan(self.catalog, self.proposal, platforms=1, operating_dollars=5681)
        three = model.hardware_plan(self.catalog, self.proposal, platforms=3, operating_dollars=5681)
        self.assertEqual(45, three["rockets"])
        self.assertEqual([4, 4, 4], [row["cores"] for row in three["per_platform"]])
        self.assertEqual(3, three["payload"]["space-platform-starter-pack"])
        self.assertEqual(5681, three["payload"][model.DOLLAR])
        self.assertGreater(three["rockets"], one["rockets"])

    def test_staged_automation_costs_more_than_fully_batched_payloads(self):
        budget = model.compute_budget(self.catalog, self.proposal)
        staged = model.staged_uplifts(self.catalog, self.proposal, budget)
        self.assertEqual(49, staged["rockets"])
        self.assertEqual(14, staged["extra_launches_above_batched"])
        self.assertEqual(12, sum(row["payload"][model.CORE] for row in staged["stages"]))

    def test_proposed_power_ratio_accounts_for_nauvis_multiplier(self):
        plan = model.hardware_plan(self.catalog, self.proposal)
        self.assertEqual(3e9, plan["compute_watts"])
        self.assertEqual(3.6e9, plan["solar_watts"])
        with self.assertRaisesRegex(ValueError, "solar cannot"):
            model.hardware_plan(self.catalog, replace(self.proposal, solar_peak_watts=10_000_000))

    def test_budget_counts_physical_archive_and_science_only_once(self):
        budget = model.compute_budget(self.catalog, self.proposal)
        self.assertEqual(2260, budget["terrestrial_dollars"])
        self.assertEqual(13250, budget["research_dollars"])
        self.assertEqual(5681, budget["orbital_dollars"])
        self.assertEqual(4500, budget["orbital_research_tokens"])
        self.assertGreaterEqual(budget["generated_equivalents"] - budget["orbital_research_tokens"], 1e9)
        self.assertNotIn("space-science-pack", budget["research_science"])

    def test_native_core_speed_changes_time_not_required_work(self):
        before = model.compute_budget(self.catalog, self.proposal)
        altered = model.EconomyCatalog(copy.deepcopy(self.catalog.data))
        altered.data["entities"][model.CORE]["crafting_speed"] *= 2
        after = model.compute_budget(altered, self.proposal)
        self.assertEqual(before["orbital_dollars"], after["orbital_dollars"])
        self.assertAlmostEqual(before["core_hours"] / 2, after["core_hours"])

    def test_complete_manufacturing_routes_include_launches_science_and_chemistry(self):
        result = model.analysis(self.catalog)
        hardware = result["hardware_supplies"]
        full = result["hardware_and_science_supplies"]
        self.assertEqual(4490, hardware["supplies"]["processing-unit"])
        self.assertEqual(8990, full["supplies"]["processing-unit"])
        self.assertNotIn(model.DOLLAR, hardware["supplies"])
        self.assertGreater(full["supplies"]["copper-plate"], hardware["supplies"]["copper-plate"])
        self.assertGreater(hardware["surplus"][model.P + "acidic-tailings"], 0)

    def test_multi_output_recipe_runs_once_for_joint_demand(self):
        altered = model.EconomyCatalog(copy.deepcopy(self.catalog.data))
        a, b, recipe = model.P + "co-a", model.P + "co-b", model.P + "co-process"
        altered.data["baseline_recipe_routes"].update({a: recipe, b: recipe})
        altered.data["recipes"][recipe] = {
            "ingredients": [{"name": "stone", "amount": 10}],
            "results": [{"name": a, "amount": 4}, {"name": b, "amount": 1}]}
        bill = model.supply_bill(altered, {a: 4, b: 1})
        self.assertEqual(1, bill["recipe_batches"][recipe])
        self.assertEqual({"stone": 10}, bill["supplies"])

    def test_missing_cyclic_stochastic_and_negative_materials_fail_closed(self):
        with self.assertRaisesRegex(ValueError, "missing material route"):
            model.supply_bill(self.catalog, {"invented-input": 1})
        with self.assertRaisesRegex(ValueError, "invalid manufacturing"):
            model.supply_bill(self.catalog, {"steel-plate": -1})
        altered = model.EconomyCatalog(copy.deepcopy(self.catalog.data))
        item = model.P + "lfp-battery-pack"
        altered.data["recipes"][item]["ingredients"] = [{"name": item, "amount": 1}]
        with self.assertRaisesRegex(ValueError, "cyclic"):
            model.supply_bill(altered, {item: 1})
        altered = model.EconomyCatalog(copy.deepcopy(self.catalog.data))
        altered.data["recipes"][item]["results"][0]["probability"] = 0.5
        with self.assertRaisesRegex(ValueError, "stochastic"):
            model.supply_bill(altered, {item: 1})

    def test_recurring_business_funds_real_fleet_and_conserves_cash(self):
        case = model.simulate(self.catalog, self.proposal, model.BUSINESSES[1])
        self.assertIsNotNone(case["model_hours"])
        self.assertLess(case["model_hours"], 6)
        self.assertEqual(120, case["active_fleet"])
        self.assertEqual(2600, case["spent"]["fleet_capital"])
        self.assertEqual(3560, case["net_taxi_dollars_per_hour"])
        self.assertAlmostEqual(0, case["cash_conservation_error"], places=7)
        self.assertGreaterEqual(case["archive_equivalents"], 1e9)
        started = next(row["minute"] for row in case["events"] if row["technology"] == "fleet-started")
        autonomy = case["events"][0]["minute"]
        self.assertGreater(started, autonomy)

    def test_remaining_battery_sales_are_finite(self):
        case = model.simulate(self.catalog, self.proposal, model.BUSINESSES[1])
        self.assertLessEqual(case["batteries_sold"], 500)
        self.assertLessEqual(case["income"]["battery_sales"], 10000)
        case = model.simulate(self.catalog, self.proposal, model.BUSINESSES[3])
        self.assertIsNone(case["model_hours"])
        self.assertEqual(2000, case["cash_spent"])
        self.assertEqual(0, case["active_fleet"])

    def test_larger_business_does_not_duplicate_overlapping_customers(self):
        with self.assertRaisesRegex(ValueError, "unique customers"):
            model.simulate(self.catalog, self.proposal, replace(model.BUSINESSES[2], allocated_fleet=1000))
        case = model.simulate(self.catalog, self.proposal, model.BUSINESSES[2])
        self.assertEqual(300, case["active_fleet"])
        self.assertEqual(6400, case["spent"]["fleet_capital"])
        self.assertEqual(8900, case["net_taxi_dollars_per_hour"])

    def test_taxis_cannot_earn_before_confirmed_sales_gate(self):
        case = model.simulate(self.catalog, self.proposal,
                              replace(model.BUSINESSES[1], taxi_sales_gate_met=False))
        self.assertEqual(0, case["active_fleet"])
        self.assertNotIn("taxi_service", case["income"])

    def test_skipping_optional_hyperscale_can_still_finish(self):
        case = model.simulate(self.catalog, self.proposal, model.BUSINESSES[0])
        self.assertIsNotNone(case["model_hours"])
        self.assertGreater(case["model_hours"], 6)
        self.assertNotIn(model.RESEARCH[-1], [row["technology"] for row in case["events"]])
        self.assertGreaterEqual(case["archive_equivalents"], 1e9)

    def test_invalid_model_parameters_fail_early(self):
        for proposal in (replace(self.proposal, phase_cores=(1, 4)),
                         replace(self.proposal, token_yields=(10000, 0, 100000, 200000)),
                         replace(self.proposal, dollar_weight_grams=0)):
            with self.assertRaises(ValueError):
                proposal.validate()
        for cores, platforms in ((0, 1), (1, 2), (1.5, 1)):
            with self.assertRaises(ValueError):
                model.hardware_plan(self.catalog, self.proposal, cores=cores, platforms=platforms)
        with self.assertRaises(ValueError):
            model.simulate(self.catalog, self.proposal, model.BUSINESSES[1], horizon_minutes=0)

    def test_cli_rejects_stale_native_source(self):
        data = copy.deepcopy(self.catalog.data)
        data["source_sha256"] = "stale"
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "catalog.json"
            path.write_text(json.dumps(data))
            result = subprocess.run([sys.executable, str(SCRIPT), "--catalog", str(path)],
                                    capture_output=True, text=True)
        self.assertNotEqual(0, result.returncode)
        self.assertIn("catalog is stale", result.stderr)
        self.assertEqual("", result.stdout)

    def test_report_matches_versioned_study_and_discloses_bounds(self):
        result = model.analysis(self.catalog)
        self.assertEqual(model.report(result), (ROOT / "docs/orbital-ending-cost-study.md").read_text())
        for message in ("Proposed balance, not implemented", "not a campaign-time prediction",
                        "hyperscale", "unmeasured", "not a tested platform blueprint", "silo-to-platform"):
            self.assertIn(message.lower(), model.report(result).lower())


if __name__ == "__main__":
    unittest.main()
