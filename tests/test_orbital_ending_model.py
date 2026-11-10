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


from tests.test_economy_simulation import model_test_catalog


class OrbitalEndingTests(unittest.TestCase):
    def setUp(self):
        self.catalog = model_test_catalog()
        self.proposal = model.ModelPlan()

    def test_real_engine_weights_keep_critical_cargo_launchable(self):
        result = model.shipments(self.catalog, {model.CORE: 1, model.DOLLAR: 100})
        self.assertEqual([], result["blocked_items"])
        self.assertEqual(2, result["rockets"])
        self.assertEqual(100000, result["capacity_per_rocket"][model.DOLLAR])
        self.assertEqual(100000, self.catalog.data["launch"]["item_weights_grams"][model.CORE])
        for item in (model.CORE, model.RADIATOR, model.SOLAR, model.MODEL):
            self.assertLessEqual(self.catalog.data["launch"]["item_weights_grams"][item],
                                 self.catalog.data["launch"]["capacity_grams"])

    def test_oversized_cargo_still_fails_closed(self):
        altered = model.EconomyCatalog(copy.deepcopy(self.catalog.data))
        altered.data["launch"]["item_weights_grams"][model.CORE] = 1208326
        result = model.shipments(altered, {model.CORE: 1})
        self.assertEqual([model.CORE], result["blocked_items"])
        self.assertIsNone(result["rockets"])

    def test_entry_prototypes_match_modeled_hardware_without_white_science(self):
        candidate = model.EconomyCatalog(copy.deepcopy(self.catalog.data))
        for item in (model.CORE, model.SOLAR, model.RADIATOR):
            self.assertEqual([[-1.5, -1.5], [1.5, 1.5]],
                             self.catalog.data["entities"][item]["selection_box"])
        self.assertEqual("250MW", self.catalog.data["entities"][model.CORE]["energy_usage"])
        self.assertEqual("20MW", self.catalog.data["entities"][model.SOLAR]["production"])
        for item in (model.CORE, model.SOLAR):
            self.assertEqual(candidate.data["recipes"][item]["ingredients"],
                             self.catalog.data["recipes"][item]["ingredients"])
        for technology in model.RESEARCH[1:]:
            native = self.catalog.data["technologies"][technology]
            self.assertNotIn("space-science-pack", native.get("prerequisites", []))
            self.assertNotIn("space-science-pack", dict(native["unit"]["ingredients"]))

    def test_native_scale_tiers_match_approved_efficiency_and_research(self):
        for technology, dollars in zip(model.RESEARCH[2:], (300, 450, 1200)):
            self.assertEqual(dollars, self.catalog.research(technology))
        for recipe, tokens in zip(model.ORBITAL_RECIPES, (10000, 50000, 100000, 200000)):
            equivalents = self.catalog.output(recipe, model.TOKEN) + 50000 * self.catalog.output(recipe, model.DATASET)
            self.assertEqual(tokens, equivalents)
            self.assertEqual(1, self.catalog.ingredient(recipe, model.DOLLAR))
            self.assertAlmostEqual(10 / 1.5, self.catalog.seconds(recipe, model.CORE))

    def test_whole_cycles_accepts_fractional_seconds_without_rounding_down_throughput(self):
        self.assertEqual(9, model.whole_cycles_per_minute(10 / 1.5))
        self.assertEqual(3, model.whole_cycles_per_minute(20))
        for seconds in (7, 0, -1, float("nan"), float("inf")):
            with self.subTest(seconds=seconds), self.assertRaises(ValueError):
                model.whole_cycles_per_minute(seconds)

    def test_native_mass_is_explicit_and_does_not_change_native_catalog(self):
        before = copy.deepcopy(self.catalog.data)
        candidate = model.EconomyCatalog(copy.deepcopy(self.catalog.data))
        self.assertEqual(before, self.catalog.data)
        result = model.shipments(candidate, {model.CORE: 12, model.DOLLAR: 5681})
        self.assertFalse(result["blocked_items"])
        self.assertEqual(3, result["rockets"])
        self.assertEqual(100000, result["capacity_per_rocket"][model.DOLLAR])

    def test_native_capture_includes_vanilla_manufacturing_and_inventory_limits(self):
        self.assertIn("rocket-silo", self.catalog.data["manufacturing_recipes"])
        self.assertIn("utility-science-pack", self.catalog.data["manufacturing_recipes"])
        self.assertEqual(10, self.catalog.data["launch"]["inventory_slots"])
        self.assertEqual(20, self.catalog.data["launch"]["rocket_inventory_slots"])
        self.assertEqual(10, self.catalog.data["launch"]["cargo_inventory_slots"])
        self.assertEqual(50, self.catalog.data["launch"]["parts_per_rocket"])
        self.assertIn("space-platform-starter-pack", self.catalog.data["items"])
        self.assertEqual(10, sum(row["amount"] for row in self.catalog.data["launch"]["starter_initial_items"]
                                 if row["name"] == "space-platform-foundation"))

    def test_shipments_round_per_item_and_obey_both_constraints(self):
        candidate = model.EconomyCatalog(copy.deepcopy(self.catalog.data))
        # Identical aggregate mass is not a license to mix automated cargo types.
        one = model.shipments(candidate, {model.CORE: 1, model.RADIATOR: 1})
        self.assertEqual(2, one["rockets"])
        candidate.data["launch"]["item_weights_grams"][model.CORE] = 1
        limited = model.shipments(candidate, {model.CORE: 21})
        self.assertEqual(10, limited["capacity_per_rocket"][model.CORE])
        self.assertEqual(3, limited["rockets"])

    def test_first_and_full_layout_preserve_starter_foundation_distinction(self):
        first = model.hardware_plan(self.catalog, self.proposal, cores=1, operating_dollars=100)
        full = model.hardware_plan(self.catalog, self.proposal, operating_dollars=5681)
        self.assertEqual((10, 36), (first["rockets"], full["rockets"]))
        self.assertEqual(24, full["payload"][model.HEAT_PIPE])
        self.assertEqual(1200, full["payload"]["space-platform-foundation"])
        self.assertEqual(1300, full["placed_foundation_tiles"])
        candidate = model.EconomyCatalog(copy.deepcopy(self.catalog.data))
        bill = model.supply_bill(candidate, full["manufacturing_roots"])
        self.assertEqual(1260, bill["recipe_batches"]["space-platform-foundation"])
        self.assertEqual(1800, full["launch_ingredients"]["rocket-fuel"])
        self.assertEqual(90, full["assembly_only_silo_minutes"])
        self.assertNotIn(model.P + "datacenter-rack", first["manufacturing_roots"])
        final = model.hardware_plan(self.catalog, self.proposal, include_final_model=True)
        self.assertEqual(1, final["manufacturing_roots"][model.P + "datacenter-rack"])

    def test_each_platform_has_its_own_starter_and_payload_rounding(self):
        one = model.hardware_plan(self.catalog, self.proposal, platforms=1, operating_dollars=5681)
        three = model.hardware_plan(self.catalog, self.proposal, platforms=3, operating_dollars=5681)
        self.assertEqual(48, three["rockets"])
        self.assertEqual([4, 4, 4], [row["cores"] for row in three["per_platform"]])
        self.assertEqual(3, three["payload"]["space-platform-starter-pack"])
        self.assertEqual(5681, three["payload"][model.DOLLAR])
        self.assertGreater(three["rockets"], one["rockets"])

    def test_staged_automation_costs_more_than_fully_batched_payloads(self):
        budget = model.compute_budget(self.catalog, self.proposal)
        staged = model.staged_uplifts(self.catalog, self.proposal, budget)
        self.assertEqual(54, staged["rockets"])
        self.assertEqual(17, staged["extra_launches_above_batched"])
        self.assertEqual(12, sum(row["payload"][model.CORE] for row in staged["stages"]))

    def test_native_power_ratio_accounts_for_nauvis_multiplier(self):
        plan = model.hardware_plan(self.catalog, self.proposal)
        self.assertEqual(3e9, plan["compute_watts"])
        self.assertEqual(3.6e9, plan["solar_watts"])
        with self.assertRaisesRegex(ValueError, "solar cannot"):
            altered = model.EconomyCatalog(copy.deepcopy(self.catalog.data))
            altered.data["entities"][model.SOLAR]["production"] = "10MW"
            model.hardware_plan(altered, self.proposal)

    def test_budget_counts_physical_archive_and_science_only_once(self):
        budget = model.compute_budget(self.catalog, self.proposal)
        self.assertEqual(1260, budget["terrestrial_dollars"])
        self.assertEqual(3200, budget["research_dollars"])
        self.assertEqual(5681, budget["orbital_dollars"])
        self.assertEqual(1350, budget["orbital_research_tokens"])
        self.assertGreaterEqual(budget["generated_equivalents"] - budget["orbital_research_tokens"], 1e9)
        self.assertNotIn("space-science-pack", budget["research_science"])

    def test_native_core_speed_changes_time_not_required_work(self):
        before = model.compute_budget(self.catalog, self.proposal)
        altered = model.EconomyCatalog(copy.deepcopy(self.catalog.data))
        altered.data["entities"][model.CORE]["crafting_speed"] *= 2
        altered.runtime["agi_assembly_seconds"] /= 2
        after = model.compute_budget(altered, self.proposal)
        self.assertEqual(before["orbital_dollars"], after["orbital_dollars"])
        self.assertAlmostEqual(before["core_hours"] / 2, after["core_hours"])

    def test_complete_manufacturing_routes_include_launches_science_and_chemistry(self):
        result = model.analysis(self.catalog)
        hardware = result["hardware_supplies"]
        full = result["hardware_and_science_supplies"]
        self.assertEqual(4740, hardware["supplies"]["processing-unit"])
        self.assertEqual(6474, full["supplies"]["processing-unit"])
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

    def test_opening_stock_is_credited_before_expansion_without_double_spending(self):
        item = model.P + "datacenter-rack"
        bill = model.supply_bill(self.catalog, {item: 2, "processing-unit": 10},
                                 opening_stock={item: 1, "processing-unit": 15})
        self.assertEqual(1, bill["recipe_batches"][item])
        self.assertEqual(5, bill["supplies"]["processing-unit"])
        self.assertEqual({item: 1, "processing-unit": 15}, bill["stock_credited"])
        self.assertNotIn(item, bill["supplies"])
        for value in (-1, float("nan"), float("inf"), True):
            with self.assertRaisesRegex(ValueError, "invalid opening stock"):
                model.supply_bill(self.catalog, {item: 1}, opening_stock={item: value})

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
        self.assertGreater(case["model_hours"], 0)
        self.assertLess(case["model_hours"], 6)
        self.assertNotIn(model.RESEARCH[-1], [row["technology"] for row in case["events"]])
        self.assertGreaterEqual(case["archive_equivalents"], 1e9)
        self.assertIn(model.RESEARCH[-2], [row["technology"] for row in case["events"]])
        for tiers in (0, 1):
            with self.assertRaisesRegex(ValueError, "Grid-scale research is required"):
                model.simulate(self.catalog, self.proposal, replace(model.BUSINESSES[0], research_tiers=tiers))

    def test_invalid_model_parameters_fail_early(self):
        for proposal in (replace(self.proposal, phase_cores=(1, 4)),
                         replace(self.proposal, phase_cores=(1, 0, 8, 12)),
                         replace(self.proposal, tiles_per_core=0)):
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

    def test_report_discloses_native_evidence_bounds(self):
        result = model.analysis(self.catalog)
        for message in ("native Model ending", "not a campaign-time prediction",
                        "hyperscale", "unmeasured", "not a tested platform blueprint", "silo-to-platform"):
            self.assertIn(message.lower(), model.report(result).lower())
        self.assertNotIn("proposal", model.report(result).lower())
        self.assertNotIn("10 GW", model.report(result))

    def test_generated_report_matches_fresh_native_catalog(self):
        native = model.EconomyCatalog.load()
        self.assertEqual([], native.freshness_errors())
        self.assertEqual(model.report(model.analysis(native)),
                         (ROOT / "docs/orbital-ending-cost-study.md").read_text())

    def test_report_distinguishes_hyperscale_and_later_start(self):
        report = model.report(model.analysis(self.catalog))
        for text in ("with optional Hyperscale", "after earlier terrestrial EV research",
                     "includes pre-orbit", "economy report starts earlier", "no space (white)"):
            self.assertIn(text, report)

    def test_native_hardware_not_overridden_and_legacy_grid_not_charged(self):
        before = copy.deepcopy(self.catalog.data)
        result = model.analysis(self.catalog)
        self.assertEqual(before, self.catalog.data)
        roots = result["layouts"][0]["manufacturing_roots"]
        self.assertNotIn(model.P + "planetary-grid-controller", roots)
        self.assertNotIn(model.P + "grid-battery-array", roots)
        self.assertNotIn(model.P + "capital-allocation", roots)
        altered = model.EconomyCatalog(copy.deepcopy(self.catalog.data))
        altered.recipe(model.CORE)["ingredients"].append({"name": "processing-unit", "amount": 7})
        changed = model.analysis(altered)
        self.assertEqual(12 * 7, changed["hardware_supplies"]["supplies"]["processing-unit"]
                         - result["hardware_supplies"]["supplies"]["processing-unit"])

    def test_final_native_seconds_used_in_completion(self):
        before = model.simulate(self.catalog, self.proposal, model.BUSINESSES[1])
        altered = model.EconomyCatalog(copy.deepcopy(self.catalog.data))
        altered.recipe(model.ASSEMBLE)["energy_required"] *= 2
        altered.runtime["agi_assembly_seconds"] *= 2
        after = model.simulate(altered, self.proposal, model.BUSINESSES[1])
        self.assertAlmostEqual(1/60, after["model_hours"] - before["model_hours"])


if __name__ == "__main__":
    unittest.main()
