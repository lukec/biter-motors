import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import model_orbital_logistics as model
from bitermotors_economy_catalog import EconomyCatalog


def layout_fixture():
    """Synthetic counts for arithmetic tests, not an accepted platform design."""
    return {"schema": 1, "stages": [
        {"cores": count, "payload": {
            "space-platform-starter-pack": 1, "space-platform-foundation": count * 100,
            model.CORE: count, model.SOLAR: count * 5, model.RADIATOR: count,
            "transport-belt": count * 12, "inserter": count * 4}}
        for count in (1, 4, 8, 12)]}


def checker_layout_fixture():
    from tests.test_orbital_platform_validation import complete_evidence
    return {"schema": 1, "stages": [
        {"cores": cores, "payload": {item: count for item, count in complete_evidence(cores)[1]["manifest"].items()
                                      if item != model.DOLLAR}} for cores in (1, 4, 8, 12)]}


class OrbitalLogisticsTests(unittest.TestCase):
    def setUp(self):
        self.catalog = EconomyCatalog.load()
        self.layouts = layout_fixture()

    def measurement_fixture(self):
        recipe = model.chapter_work(self.catalog)["bands"][0]["recipe"]
        ticks = max(3600, int(self.catalog.seconds(recipe, model.CORE) * 120))
        return {"schema": 1, "source_sha256": self.catalog.data["source_sha256"],
                "layouts_sha256": model.fingerprint(self.layouts),
                "runs": [{"cores": 1, "recipe": recipe, "elapsed_ticks": ticks,
                          "completed_batches": 2}],
                "transit": {"uplift_seconds_per_rocket": 30, "model_return_seconds": 10}}

    def test_missing_inputs_are_explicit_and_do_not_invent_measurements(self):
        result = model.analyze(self.catalog)
        self.assertIn("unqualified", result["qualification"])
        self.assertEqual([], result["native_observations"]["runs"])
        for row in result["scenarios"]:
            self.assertIsNone(row["hardware"])
            self.assertIn("unqualified", row["transit"]["status"])
            self.assertTrue(all(band["observed_rate_projection_seconds"] is None
                                for band in row["compute"]))

    def test_pure_inputs_and_reproducible_output(self):
        before = copy.deepcopy((self.catalog.data, self.layouts))
        first = model.analyze(self.catalog, self.layouts)
        self.assertEqual(first, model.analyze(self.catalog, self.layouts))
        self.assertEqual(before, (self.catalog.data, self.layouts))

    def test_stages_ship_only_added_hardware_and_round_each_stage(self):
        work = model.chapter_work(self.catalog)
        result = model.staged_hardware(self.catalog, model.validate_layouts(self.layouts), work)
        self.assertEqual(12, sum(row["payload"].get(model.CORE, 0) for row in result["stages"]))
        self.assertEqual(1, sum(row["payload"].get("space-platform-starter-pack", 0)
                                for row in result["stages"]))
        self.assertEqual(1, result["stages"][-1]["payload"][model.P + "datacenter-rack"])
        self.assertEqual(work["orbital_dollars"], sum(row["payload"].get(model.DOLLAR, 0)
                                                    for row in result["stages"]))
        self.assertEqual(50, result["rockets"])
        self.assertEqual(2500, result["manufacturing_roots"]["processing-unit"])
        self.assertEqual(7500, result["silo_assembly_seconds_lower_bound"])
        self.assertFalse(result["return_requires_rocket"])

    def test_joint_bill_and_frontier_share_one_blue_circuit_allocation(self):
        result = model.analyze(self.catalog, self.layouts, frontier_rates={"processing-unit": 60})
        row = result["scenarios"][0]
        expected = model.supply_bill(self.catalog, row["joint_manufacturing_roots"])
        self.assertEqual(expected, row["joint_material_bill"])
        blue = next(item for item in row["frontier"]["rows"] if item["item"] == "processing-unit")
        self.assertEqual(expected["supplies"]["processing-unit"] / 60, blue["minutes_lower_bound"])
        self.assertEqual(1, sum(item["item"] == "processing-unit" for item in row["frontier"]["rows"]))
        self.assertTrue(row["frontier"]["unrated_items"])
        self.assertGreater(blue["units"], row["hardware"]["manufacturing_roots"]["processing-unit"])

    def test_cash_does_not_charge_fleet_capital_twice(self):
        row = model.analyze(self.catalog, self.layouts)["scenarios"][0]
        cash = row["cash"]
        self.assertEqual(cash["research_and_compute"] + row["joint_material_bill"]["supplies"].get(model.DOLLAR, 0),
                         cash["total_before_recurring_wear"])
        self.assertEqual(3560, cash["recurring_net_dollars_per_hour"])
        self.assertEqual(10000, cash["finite_sales_revenue_ceiling"])

    def test_non_taxi_market_is_finite_and_hyperscale_is_optional(self):
        row = model.analyze(self.catalog, self.layouts)["scenarios"][1]
        self.assertFalse(row["work"]["hyperscale"])
        self.assertEqual(4, len(row["work"]["bands"]))
        self.assertEqual(0, row["cash"]["recurring_net_dollars_per_hour"])
        self.assertEqual(20000, row["cash"]["finite_sales_revenue_ceiling"])
        self.assertIsNone(row["cash"]["steady_service_hours_lower_bound"])
        self.assertNotIn(model.P + "hyperscale-training", [r["technology"] for r in row["work"]["research"]])

    def test_measurements_bind_source_layout_and_recipe(self):
        measurements = self.measurement_fixture()
        result = model.analyze(self.catalog, self.layouts, measurements)
        row = result["scenarios"][0]
        self.assertAlmostEqual(row["compute"][0]["batches"] * measurements["runs"][0]["elapsed_ticks"] / 120,
                         row["compute"][0]["observed_rate_projection_seconds"])
        self.assertIsNone(row["compute"][1]["observed_rate_projection_seconds"])
        self.assertEqual(row["hardware"]["rockets"] * 30, row["transit"]["serialized_uplift_seconds"])
        self.assertIn("not actual player time", result["qualification"])
        for key in ("source_sha256", "layouts_sha256"):
            wrong = copy.deepcopy(measurements)
            wrong[key] = "wrong"
            with self.assertRaisesRegex(ValueError, "do not match"):
                model.analyze(self.catalog, self.layouts, wrong)

    def test_zero_observed_throughput_does_not_fall_back_to_ideal(self):
        measurements = self.measurement_fixture()
        measurements["runs"][0]["completed_batches"] = 0
        result = model.analyze(self.catalog, self.layouts, measurements)
        self.assertIsNone(result["scenarios"][0]["compute"][0]["observed_rate_projection_seconds"])

    def test_bad_measurements_fail_closed(self):
        for field, value in (("elapsed_ticks", 0), ("completed_batches", -1),
                             ("completed_batches", 100000), ("elapsed_ticks", float("nan")),
                             ("cores", 2), ("recipe", "invented")):
            measurements = self.measurement_fixture()
            measurements["runs"][0][field] = value
            with self.subTest(field=field, value=value), self.assertRaises(ValueError):
                model.analyze(self.catalog, self.layouts, measurements)
        measurements = self.measurement_fixture()
        measurements["runs"] *= 2
        with self.assertRaisesRegex(ValueError, "duplicate"):
            model.analyze(self.catalog, self.layouts, measurements)

    def test_malformed_layouts_and_rates_fail_closed(self):
        for item, count in ((model.CORE, 99), (model.DOLLAR, 1), ("inserter", -1),
                            ("inserter", float("inf")), ("inserter", True)):
            manifest = copy.deepcopy(self.layouts)
            manifest["stages"][0]["payload"][item] = count
            with self.subTest(item=item, count=count), self.assertRaises(ValueError):
                model.validate_layouts(manifest)
        manifest = copy.deepcopy(self.layouts)
        manifest["stages"][1]["payload"]["inserter"] = 0
        with self.assertRaisesRegex(ValueError, "cannot remove"):
            model.validate_layouts(manifest)
        for rate in (0, -1, float("nan")):
            with self.assertRaises(ValueError):
                model.manufacturing_frontier({"supplies": {"processing-unit": 1}}, {"processing-unit": rate})

    def test_unknown_or_unlaunchable_cargo_is_not_ignored(self):
        catalog = EconomyCatalog(copy.deepcopy(self.catalog.data))
        catalog.data["launch"]["item_weights_grams"][model.CORE] = 2000000
        with self.assertRaisesRegex(ValueError, "unlaunchable"):
            model.analyze(catalog, self.layouts)

    def test_cli_measurements_and_stale_catalog_rejection(self):
        with tempfile.TemporaryDirectory() as directory:
            layouts = Path(directory) / "layouts.json"
            measurements = Path(directory) / "measurements.json"
            layouts.write_text(json.dumps(self.layouts))
            measurements.write_text(json.dumps(self.measurement_fixture()))
            command = [sys.executable, str(ROOT / "scripts/model_orbital_logistics.py"),
                       "--layouts", str(layouts), "--measurements", str(measurements), "--json"]
            result = subprocess.run(command, capture_output=True, text=True)
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertEqual(1, json.loads(result.stdout)["schema"])
            stale = copy.deepcopy(self.catalog.data)
            stale["source_sha256"] = "stale"
            path = Path(directory) / "catalog.json"
            path.write_text(json.dumps(stale))
            result = subprocess.run(command + ["--catalog", str(path)], capture_output=True, text=True)
            self.assertNotEqual(0, result.returncode)
            self.assertIn("catalog is stale", result.stderr)

    def fixture_report(self, *, raw=False):
        """Synthetic fixture-shaped report; not engine evidence."""
        payload = dict(self.layouts["stages"][0]["payload"])
        payload[model.DOLLAR] = 60
        recipe = (model.campaign_plan(self.catalog)["bands"][0]["recipe"] if raw else
                  model.chapter_work(self.catalog)["bands"][0]["recipe"])
        ticks = max(3600, int(self.catalog.seconds(recipe, model.CORE) * 120))
        output = model.DATASET if self.catalog.output(recipe, model.DATASET) else model.TOKEN
        batch_output = self.catalog.output(recipe, output)
        produced = 2 * batch_output
        returned = batch_output if raw else produced
        row = {"status": "measured_passed", "scope": "native-platform-logistics",
               "cores": 1, "recipe": recipe, "manifest": payload,
               "tick": 1000 + ticks, "operation_tick": 1000, "measured_ticks": ticks,
               "completions": 2, "batch_output": batch_output, "produced": produced,
               "returned": returned, "physical_returned": returned,
               "output_item": output, "batch_dollars": self.catalog.ingredient(recipe, model.DOLLAR),
               "cycle_ticks": self.catalog.seconds(recipe, model.CORE) * 60,
               "rockets": 10, "rocket_parts": 500, "raw_baseline": raw,
               "shipments": [{"tick": 10, "delivered_tick": 10, "cargo": {model.CORE: 1}}],
               "limits": "Synthetic only; technologies and ground inputs supplied."}
        return [row, {"status": "reload_passed", "tick": row["tick"] + 60}]

    def test_fixture_normalization_preserves_evidence_and_zero_delay(self):
        rows = self.fixture_report()
        normalized = model.normalize_fixture_rows(rows, self.layouts, evidence="synthetic")
        self.assertIsNone(normalized["source_sha256"])
        self.assertEqual([0], normalized["uplift_observations"][0]["delivery_seconds"])
        self.assertIsNone(normalized["transit"])
        self.assertEqual(rows[0], normalized["fixture_rows"][0])
        result = model.analyze(self.catalog, self.layouts, normalized)
        self.assertIn("unqualified source provenance", result["native_observations"]["status"])
        self.assertIsNone(result["scenarios"][0]["compute"][0]["observed_rate_projection_seconds"])

    def test_fixture_source_hash_is_preserved_matched_and_never_inferred(self):
        rows = self.fixture_report()
        rows[0]["source_sha256"] = self.catalog.data["source_sha256"]
        normalized = model.normalize_fixture_rows(rows, self.layouts, evidence="synthetic")
        self.assertEqual(rows[0]["source_sha256"], normalized["source_sha256"])
        result = model.analyze(self.catalog, self.layouts, normalized)
        self.assertTrue(result["native_observations"]["source_bound"])
        self.assertIsNotNone(result["scenarios"][0]["compute"][0]["observed_rate_projection_seconds"])
        self.assertIn("unqualified for campaign pacing", result["qualification"])
        rows[0]["source_sha256"] = "not-the-native-capture"
        normalized = model.normalize_fixture_rows(rows, self.layouts, evidence="synthetic")
        with self.assertRaisesRegex(ValueError, "do not match native catalog source"):
            model.analyze(self.catalog, self.layouts, normalized)

    def test_inconsistent_source_provenance_across_rows_and_files_rejected(self):
        rows = self.fixture_report()
        rows[0]["source_sha256"] = "source-a"
        rows[1]["source_sha256"] = "source-b"
        with self.assertRaisesRegex(ValueError, "inconsistent source provenance"):
            model.normalize_fixture_rows(rows, self.layouts, evidence="synthetic")
        with tempfile.TemporaryDirectory() as directory:
            from tests.test_orbital_platform_validation import complete_evidence
            paths = []
            for index, source in enumerate(("a" * 64, "b" * 64)):
                rows = complete_evidence()
                for row in rows:
                    row["source_sha256"] = source
                path = Path(directory) / f"source-{index}.jsonl"
                path.write_text("".join(json.dumps(row) + "\n" for row in rows))
                paths.append(path)
            with self.assertRaisesRegex(ValueError, "inconsistent source provenance"):
                model.load_measurements(paths, checker_layout_fixture())

    def test_mixed_fixture_loads_do_not_replace_staged_single_item_projection(self):
        rows = self.fixture_report()
        rows[0]["shipments"] = [{"tick": 10, "delivered_tick": 70,
                                 "cargo": {model.CORE: 1, model.SOLAR: 2}}]
        normalized = model.normalize_fixture_rows(rows, self.layouts, evidence="synthetic mixed flight")
        result = model.analyze(self.catalog, self.layouts, normalized)
        comparison = result["native_observations"]["launch_comparisons"][0]
        self.assertEqual(10, comparison["native_fixture_rockets"])
        self.assertEqual(model.shipments(self.catalog, rows[0]["manifest"])["rockets"],
                         comparison["single_item_same_manifest_projection"])
        self.assertEqual(50, result["scenarios"][0]["hardware"]["rockets"])
        self.assertEqual([1], result["native_observations"]["uplift_observations"][0]["delivery_seconds"])
        self.assertEqual(rows[0]["shipments"], result["native_observations"]["fixture_rows"][0]["shipments"])
        self.assertIn("not native mixed-load counts", model.report(result))
        self.assertIn("not a measured campaign ramp", model.report(result))

    def test_native_catalog_variant_is_observed_without_recipe_relabeling(self):
        catalog = EconomyCatalog(copy.deepcopy(self.catalog.data))
        measured = self.measurement_fixture()
        variant = model.P + "orbital-ai-token-compact"
        original = measured["runs"][0]["recipe"]
        catalog.data["recipes"][variant] = copy.deepcopy(catalog.data["recipes"][original])
        measured["runs"][0]["recipe"] = variant
        result = model.analyze(catalog, self.layouts, measured)
        self.assertEqual(variant, result["native_observations"]["runs"][0]["recipe"])
        self.assertTrue(all(band["observed_rate_projection_seconds"] is None
                            for band in result["scenarios"][0]["compute"]))

    def test_fixture_batch_contract_cross_checked_against_catalog(self):
        rows = self.fixture_report()
        rows[0]["source_sha256"] = self.catalog.data["source_sha256"]
        normalized = model.normalize_fixture_rows(rows, self.layouts, evidence="synthetic")
        self.assertTrue(model.analyze(self.catalog, self.layouts, normalized)["native_observations"]["source_bound"])
        for field, value in (("batch_output", 999), ("batch_dollars", 99), ("cycle_ticks", 1)):
            altered = copy.deepcopy(normalized)
            altered["fixture_rows"][0][field] = value
            with self.subTest(field=field), self.assertRaisesRegex(ValueError, "batch contract"):
                model.analyze(self.catalog, self.layouts, altered)

    def test_invalid_native_windows_and_raw_flags_rejected(self):
        for first, last in ((999, 2000), (2000, 1000000), (3000, 2000)):
            rows = self.fixture_report()
            rows[0].update(first_completion_tick=first, last_completion_tick=last)
            with self.assertRaisesRegex(ValueError, "outside operation window"):
                model.normalize_fixture_rows(rows, self.layouts, evidence="synthetic")
        rows = self.fixture_report()
        rows[0]["raw_baseline"] = "false"
        with self.assertRaisesRegex(ValueError, "boolean"):
            model.normalize_fixture_rows(rows, self.layouts, evidence="synthetic")

    def test_raw_transport_deficit_never_becomes_practical_projection(self):
        normalized = model.normalize_fixture_rows(self.fixture_report(raw=True), self.layouts,
                                                  evidence="synthetic raw baseline")
        result = model.analyze(self.catalog, self.layouts, normalized)
        self.assertTrue(result["native_observations"]["runs"][0]["raw_baseline"])
        self.assertTrue(all(row["observed_rate_projection_seconds"] is None
                            for row in result["scenarios"][0]["compute"]))

    def test_fixture_manifest_time_and_conservation_mismatches_rejected(self):
        for key, value in (("measured_ticks", 1), ("produced", 1), ("physical_returned", 0)):
            rows = self.fixture_report()
            rows[0][key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                model.normalize_fixture_rows(rows, self.layouts, evidence="synthetic")
        rows = self.fixture_report()
        rows[0]["manifest"]["inserter"] += 1
        with self.assertRaisesRegex(ValueError, "manifest does not match"):
            model.normalize_fixture_rows(rows, self.layouts, evidence="synthetic")

    def test_native_jsonl_uses_shared_completion_and_truncation_checks(self):
        from tests.test_orbital_platform_validation import complete_evidence
        manifest = checker_layout_fixture()
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "report.jsonl"
            content = "\n".join(json.dumps(row) for row in complete_evidence())
            path.write_text(content + "\n")
            result = model.load_measurements([path], manifest)
            self.assertEqual(1, len(result["runs"]))
            path.write_text(content)
            with self.assertRaisesRegex(ValueError, "unterminated"):
                model.load_measurements([path], manifest)
            path.write_text(json.dumps(self.fixture_report()[0]) + "\n")
            with self.assertRaisesRegex(ValueError, "completion sentinel"):
                model.load_measurements([path], manifest)

    def test_compact_bands_preserve_raw_equivalent_work_cash_and_time(self):
        catalog = model.EconomyCatalog(copy.deepcopy(self.catalog.data))
        # Explicit synthetic fallback permits this regression to run before capture refresh.
        for name, output, cost, recipe_seconds in (
                (model.P + "orbital-ai-dataset", 1, 5, 50),
                (model.P + "orbital-ai-dataset-cluster", 1, 1, 10)):
            catalog.data["recipes"].setdefault(name, {
                "categories": ["bitermotors-orbital-compute"], "energy_required": recipe_seconds,
                "ingredients": [{"name": model.DOLLAR, "amount": cost}],
                "results": [{"name": model.DATASET, "amount": output}]})
        before = copy.deepcopy(catalog.data)
        for hyperscale in (True, False):
            work = model.chapter_work(catalog, hyperscale=hyperscale)
            native = model.campaign_plan(catalog, cores=12, hyperscale=hyperscale)
            self.assertEqual([model.P + "orbital-ai-dataset", model.P + "orbital-ai-dataset-cluster"],
                             [band["recipe"] for band in work["bands"][:2]])
            self.assertEqual([20, 180], [band["batches"] for band in work["bands"][:2]])
            for seconds, band in zip((50 / 1.5, 10 / 1.5), work["bands"][:2]):
                self.assertAlmostEqual(seconds, band["normal_cycle_seconds"])
            self.assertEqual(sum(band["dollars"] for band in native["bands"]), work["orbital_dollars"])
            for original, compact in zip(native["bands"][:2], work["bands"][:2]):
                self.assertEqual(original["dollars"], compact["dollars"])
                self.assertAlmostEqual(original["one_core_hours"], compact["one_core_hours"])
            self.assertTrue(all(band.get("compact_rounding_equivalents", 0) == 0 for band in work["bands"]))
        self.assertEqual(before, catalog.data)

    def test_compact_samples_match_normal_scale_cases_without_cross_recipe_credit(self):
        work = model.chapter_work(self.catalog)
        measurements = self.measurement_fixture()
        measurements["runs"] = [{"cores": cores, "recipe": band["recipe"],
                                  "elapsed_ticks": int(band["normal_cycle_seconds"] * 60 * 60),
                                  "completed_batches": 60 * cores}
                                 for cores, band in zip((1, 4, 8, 12), work["bands"])]
        result = model.analyze(self.catalog, self.layouts, measurements)
        for band in result["scenarios"][0]["compute"]:
            self.assertAlmostEqual(band["ideal_seconds"], band["observed_rate_projection_seconds"])
        self.assertEqual(12, result["scenarios"][1]["compute"][-1]["cores"])
        self.assertIn("grid-scale", result["scenarios"][1]["compute"][-1]["recipe"])
        self.assertIsNone(result["scenarios"][1]["compute"][-1]["observed_rate_projection_seconds"])

    def test_no_hyperscale_grid_split_preserves_compute_cash_and_work(self):
        native = model.campaign_plan(self.catalog, cores=12, hyperscale=False)
        work = model.chapter_work(self.catalog, hyperscale=False)
        self.assertEqual([1, 4, 8, 12], [band["cores"] for band in work["bands"]])
        self.assertEqual(native["bands"][-1]["batches"], sum(band["batches"] for band in work["bands"][-2:]))
        self.assertEqual(native["bands"][-1]["dollars"], sum(band["dollars"] for band in work["bands"][-2:]))
        self.assertAlmostEqual(native["bands"][-1]["one_core_hours"], sum(band["one_core_hours"] for band in work["bands"][-2:]))
        self.assertEqual(100000000, work["bands"][-2]["target"])
        self.assertEqual(work["bands"][-2]["recipe"], work["bands"][-1]["recipe"])

    def test_explicit_frontier_profile_covers_joint_bill_and_scales_parallel_bound(self):
        rates = json.loads((ROOT / "docs/orbital-frontier-example.json").read_text())
        result = model.analyze(self.catalog, self.layouts, frontier_rates=rates)
        for scenario in result["scenarios"]:
            expected = set(scenario["joint_material_bill"]["supplies"]) - {model.DOLLAR}
            self.assertFalse(expected - rates.keys())
            sensitivity = scenario["frontier_sensitivity"]
            self.assertEqual([0.5, 1, 2], [row["rate_multiplier"] for row in sensitivity])
            self.assertTrue(all(row["all_frontier_rates_supplied"] for row in sensitivity))
            self.assertAlmostEqual(sensitivity[1]["minutes_lower_bound"] * 2, sensitivity[0]["minutes_lower_bound"])
            self.assertAlmostEqual(sensitivity[1]["minutes_lower_bound"] / 2, sensitivity[2]["minutes_lower_bound"])

    def test_summary_uses_measured_not_reload_window_and_excludes_runtime_snapshots(self):
        from tests.test_orbital_platform_validation import complete_evidence
        rows = complete_evidence(4)
        summary = model.measured_summary({"status": "synthetic", "fixture_rows": [rows[5]]})
        case = summary["cases"][0]
        self.assertEqual(rows[5]["measured_ticks"], case["measured_ticks"])
        self.assertNotEqual(rows[-1]["measured_ticks"], case["measured_ticks"])
        self.assertEqual(0, case["finite_allocation_imbalance_floor_seconds"])
        self.assertGreater(case["return_drain_after_last_completion_seconds"], 0)
        self.assertNotIn("shipments", case)
        result = model.analyze(self.catalog, self.layouts)
        self.assertNotIn("fixture_rows", model.report_data(result)["native_observations"])

    def test_repeated_canonical_layout_exports_reuse_preview_reader(self):
        with tempfile.TemporaryDirectory() as directory:
            paths = []
            for stage in self.layouts["stages"]:
                manifest = dict(stage["payload"])
                del manifest["space-platform-starter-pack"]
                manifest[model.DOLLAR] = 60 * stage["cores"]
                layout = {"cores": stage["cores"], "manifest": manifest,
                          "entities": [{"name": model.CORE, "position": {"x": 0, "y": 0},
                                        "direction": 0}],
                          "tiles": [{"name": "space-platform-foundation", "position": {"x": 0, "y": 0}}]}
                path = Path(directory) / f"layout-{stage['cores']}.json"
                path.write_text(json.dumps(layout))
                paths.append(path)
            result = model.load_layouts(list(reversed(paths)))
            self.assertEqual([1, 4, 8, 12], [row["cores"] for row in result["stages"]])
            self.assertTrue(all(model.DOLLAR not in row["payload"] for row in result["stages"]))
            self.assertTrue(all(row["payload"]["space-platform-starter-pack"] == 1 for row in result["stages"]))
            self.assertTrue(all("geometry_sha256" in row for row in result["stages"]))


if __name__ == "__main__":
    unittest.main()
