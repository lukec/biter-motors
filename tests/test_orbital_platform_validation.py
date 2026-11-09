"""Adversarial synthetic reports; these tests do not qualify native gameplay."""

import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import check_orbital_platform as checker


def complete_evidence(cores=1, *, raw=False, batch_dollars=5, cycle_ticks=6000):
    manifest = {checker.STARTER: 1, checker.FOUNDATION: 10, checker.CORE: cores,
                checker.SOLAR: cores * 5, checker.RADIATOR: cores,
                "bulk-inserter": cores * 2 + 2, checker.DOLLAR: cores * 60 * batch_dollars}
    hardware = {key: count for key, count in manifest.items()
                if key not in (checker.STARTER, checker.FOUNDATION, checker.DOLLAR)}
    layout = {"cores": cores, "entities": [{"name": item} for item, count in hardware.items()
                                           for _ in range(count)],
              "tiles": [{} for _ in range(10)], "manifest": dict(hardware)}
    output = checker.TOKEN if raw else checker.DATASET
    batch_output = 10000 if raw else 1
    built_tick = 1000
    mid_elapsed = 18000 if raw else cycle_ticks * 30
    measured_elapsed = 36000 if raw else cycle_ticks * 60 + 60
    ticks = (0, 700, built_tick, built_tick + mid_elapsed, built_tick + mid_elapsed + 60,
             built_tick + measured_elapsed, built_tick + measured_elapsed, built_tick + measured_elapsed + 60)
    rows = []
    for index, (status, tick) in enumerate(zip(checker.STATUSES, ticks)):
        row = {"status": status, "tick": tick, "assertions": [10, 20, 30, 40, 45, 50, 50, 55][index],
               "cores": cores, "recipe": checker.P + ("orbital-ai-token" if raw else "orbital-ai-dataset"),
               "source_sha256": "a" * 64, "scope": "native-platform-logistics",
               "limits": "Synthetic report only; finite stock, technologies and ground power supplied."}
        if index < 2:
            row["layout"] = copy.deepcopy(layout)
            if index == 0:
                row.update(technologies_supplied=True, bulk_capacity_bonus=0)
            if index == 1:
                row.update(manifest=dict(manifest), starter_tick=500)
                row["layout"]["manifest"] = {key: count for key, count in manifest.items() if key != checker.STARTER}
            rows.append(row)
            continue
        batches = 0 if index == 2 else (15 if raw else 30) if index < 5 else (20 if raw else 60)
        products = {str(unit + 1): batches for unit in range(cores)} if batches else {}
        produced = batches * cores * batch_output
        returned = (10000 if batches else 0) if raw else produced
        row.update(output_item=output, batch_output=batch_output, batch_dollars=batch_dollars,
                   cycle_ticks=cycle_ticks, target_batches=cores * 60,
                   core_rated_watts=250000000, wing_nominal_watts=20000000,
                   operation_tick=built_tick, measured_ticks=tick - built_tick,
                   completions=batches * cores, produced=produced, returned=returned,
                   physical_returned=returned, earned_equivalents=produced * (1 if raw else 50000),
                   manifest=dict(manifest), shipped=dict(manifest), delivered=dict(manifest),
                   built=dict(hardware), built_tiles=10, foundation_added=10,
                   solar_multiplier=1, solar_coefficient=300, low_power_samples=0, no_cooling_samples=0,
                   core_products=products, return_pods=1 if returned else 0,
                   rockets=2, rocket_parts=100,
                   rocket_supplied={"processing-unit": 150}, rocket_input_remaining={"processing-unit": 50},
                   shipments=[{"cargo": {checker.STARTER: 1}, "mass": 1000000, "slots": 1,
                               "tick": 500, "delivered_tick": 500},
                              {"cargo": {key: count for key, count in manifest.items() if key != checker.STARTER},
                               "mass": 900000, "slots": 8, "tick": 600, "delivered_tick": 700}])
        if batches:
            row.update(first_completion_tick=built_tick + cycle_ticks,
                       last_completion_tick=min(tick, built_tick + batches * cycle_ticks))
        if raw and index == 5:
            row["raw_baseline"] = True
        if index == 7:
            row["saved_tick"] = ticks[6]
        rows.append(row)
    return rows


class OrbitalPlatformValidationTests(unittest.TestCase):
    def test_all_native_scale_cases_and_raw_baseline(self):
        for cores in (1, 4, 8, 12):
            with self.subTest(cores=cores):
                result = checker.check_rows(complete_evidence(cores), "a" * 64)
                self.assertEqual(cores * 60, result["completions"])
                self.assertIn("not a natural campaign", result["qualification"])
        self.assertTrue(checker.check_rows(complete_evidence(raw=True, batch_dollars=1,
                                                          cycle_ticks=1200))["raw_baseline"])

    def test_changed_reported_recipe_economics_are_not_hardcoded(self):
        checker.check_rows(complete_evidence(4, batch_dollars=3, cycle_ticks=7320))

    def test_supplied_technology_and_buffers_are_disclosed(self):
        rows = complete_evidence()
        for row in rows[2:]:
            row["rocket_parts"] = 200
        result = checker.check_rows(rows)
        self.assertTrue(result["technologies_supplied"])
        self.assertEqual(100, result["minimum_launched_rocket_parts"])
        self.assertEqual(100, result["fixture_prebuilt_buffer_parts"])
        rows[0]["technologies_supplied"] = False
        with self.assertRaisesRegex(ValueError, "supplied technology"):
            checker.check_rows(rows)

    def test_catalog_recomputes_mixed_cargo_mass_and_stack_slots(self):
        rows = complete_evidence()
        manifest = rows[1]["manifest"]
        weights = {item: 1 for item in manifest}
        weights[checker.STARTER] = 1000000
        catalog = {"source_sha256": "a" * 64,
                   "launch": {"item_weights_grams": weights, "capacity_grams": 1000000,
                              "inventory_slots": 10, "parts_per_rocket": 50},
                   "items": {item: {"stack_size": 100000} for item in manifest}}
        for row in rows[2:]:
            for shipment in row["shipments"]:
                shipment["mass"] = sum(weights[item] * count for item, count in shipment["cargo"].items())
                shipment["slots"] = len(shipment["cargo"])
        self.assertTrue(checker.check_rows(rows, catalog=catalog)["cargo_mass_slots_recomputed"])
        for field in ("mass", "slots"):
            altered = copy.deepcopy(rows)
            altered[-1]["shipments"][1][field] += 1
            with self.subTest(field=field), self.assertRaisesRegex(ValueError, "native catalog"):
                checker.check_rows(altered, catalog=catalog)
        catalog["source_sha256"] = "b" * 64
        with self.assertRaisesRegex(ValueError, "differs from native catalog"):
            checker.check_rows(rows, catalog=catalog)

    def test_complete_dataset_target_and_raw_deficit_are_not_optional(self):
        rows = complete_evidence()
        for row in rows[5:]:
            row.update(completions=59, produced=59, returned=59, physical_returned=59,
                       core_products={"1": 59}, earned_equivalents=59 * 50000)
        with self.assertRaisesRegex(ValueError, "finite target/return incomplete"):
            checker.check_rows(rows)
        rows = complete_evidence(raw=True, batch_dollars=1, cycle_ticks=1200)
        for row in rows[5:]:
            row["returned"] = row["physical_returned"] = row["produced"]
        with self.assertRaisesRegex(ValueError, "no transport deficit"):
            checker.check_rows(rows)

    def test_same_tick_measurement_and_checkpoint_equal_assertions_are_valid(self):
        rows = complete_evidence()
        self.assertEqual(rows[5]["tick"], rows[6]["tick"])
        self.assertEqual(rows[5]["assertions"], rows[6]["assertions"])
        checker.check_rows(rows)

    def test_status_order_missing_duplicate_failure_and_nonobjects(self):
        rows = complete_evidence()
        for mutated in ([], rows[:-1], rows + [rows[-1]], rows[:3] + rows[4:],
                        [rows[1], rows[0]] + rows[2:], [None] * 8, {}, None):
            with self.subTest(mutated=type(mutated)), self.assertRaises(ValueError):
                checker.check_rows(mutated)

    def test_invalid_numbers_and_missing_required_fields(self):
        for field, value in (("tick", True), ("assertions", False), ("tick", float("nan")),
                             ("returned", -1), ("produced", 1.5), ("measured_ticks", float("inf"))):
            rows = complete_evidence()
            rows[-1][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                checker.check_rows(rows)
        for field in ("source_sha256", "solar_multiplier", "shipments", "core_products", "physical_returned"):
            rows = complete_evidence()
            del rows[-1][field]
            with self.subTest(field=field), self.assertRaises(ValueError):
                checker.check_rows(rows)

    def test_source_hash_optional_expectation_and_case_identity(self):
        checker.check_rows(complete_evidence())
        with self.assertRaisesRegex(ValueError, "unexpected source"):
            checker.check_rows(complete_evidence(), "b" * 64)
        for field, value in (("source_sha256", "b" * 64), ("cores", 4), ("recipe", "other"),
                             ("scope", "other"), ("limits", "")):
            rows = complete_evidence()
            rows[5][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                checker.check_rows(rows)

    def test_nonadvancing_build_measure_and_reloads_rejected(self):
        for index, preceding in ((2, 1), (3, 2), (4, 3), (5, 4), (7, 6)):
            rows = complete_evidence()
            rows[index]["tick"] = rows[preceding]["tick"]
            with self.subTest(index=index), self.assertRaises(ValueError):
                checker.check_rows(rows)
        rows = complete_evidence()
        rows[-1]["assertions"] = 1
        with self.assertRaises(ValueError):
            checker.check_rows(rows)

    def test_manifest_shipping_built_and_foundation_conservation(self):
        for field in ("shipped", "delivered", "manifest", "built"):
            rows = complete_evidence()
            rows[-1][field][checker.CORE] += 1
            with self.subTest(field=field), self.assertRaises(ValueError):
                checker.check_rows(rows)
        for field in ("foundation_added", "built_tiles"):
            rows = complete_evidence()
            rows[-1][field] += 1
            with self.subTest(field=field), self.assertRaises(ValueError):
                checker.check_rows(rows)

    def test_mass_slots_cargo_and_delivery_event_order(self):
        for field, value in (("mass", 1000001), ("mass", 0), ("slots", 11), ("slots", True),
                             ("tick", 800), ("delivered_tick", 1001), ("cargo", {})):
            rows = complete_evidence()
            rows[-1]["shipments"][1][field] = value
            with self.subTest(field=field, value=value), self.assertRaises(ValueError):
                checker.check_rows(rows)
        rows = complete_evidence()
        rows[-1]["shipments"][1]["cargo"][checker.CORE] += 1
        with self.assertRaisesRegex(ValueError, "conserve manifest"):
            checker.check_rows(rows)

    def test_rocket_accounting_and_remaining_stock(self):
        for field, value in (("rockets", 3), ("rocket_parts", 99),
                             ("rocket_input_remaining", {"processing-unit": 151})):
            rows = complete_evidence()
            rows[-1][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                checker.check_rows(rows)
        rows = complete_evidence()
        for row in rows[2:]:
            row["rocket_parts"] = 200  # Additional buffered output is not another observed launch.
        checker.check_rows(rows)

    def test_actual_solar_and_radiators_not_just_powered_completion(self):
        for field, value in (("solar_multiplier", 2), ("solar_coefficient", 400),
                             ("low_power_samples", 1), ("no_cooling_samples", 1)):
            rows = complete_evidence()
            rows[-1][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                checker.check_rows(rows)
        rows = complete_evidence()
        for row in rows[2:]:
            row["wing_nominal_watts"] = 1
        with self.assertRaisesRegex(ValueError, "insufficient orbital solar"):
            checker.check_rows(rows)

    def test_batches_earned_pad_and_all_cores_participate(self):
        for field, value in (("produced", 59), ("physical_returned", 59), ("earned_equivalents", 0),
                             ("completions", 61), ("core_products", {})):
            rows = complete_evidence()
            rows[-1][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                checker.check_rows(rows)
        rows = complete_evidence(4)
        for row in rows[3:]:
            total = row["completions"]
            row["core_products"] = {"1": total}
        with self.assertRaisesRegex(ValueError, "not all cores"):
            checker.check_rows(rows)

    def test_reload_persistence_and_post_reload_new_output(self):
        rows = complete_evidence()
        rows[-1]["saved_tick"] -= 1
        with self.assertRaisesRegex(ValueError, "saved_tick"):
            checker.check_rows(rows)
        rows = complete_evidence()
        rows[4]["core_products"] = {"other": 30}
        with self.assertRaises(ValueError):
            checker.check_rows(rows)

    def test_raw_requires_real_600_second_backlog(self):
        for field, value in (("raw_baseline", "true"), ("returned", 200000),
                             ("measured_ticks", 35999)):
            rows = complete_evidence(raw=True, batch_dollars=1, cycle_ticks=1200)
            rows[5][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                checker.check_rows(rows)
        rows = complete_evidence(raw=True, batch_dollars=1, cycle_ticks=1200)
        rows[5].pop("raw_baseline")
        with self.assertRaisesRegex(ValueError, "physical Datasets"):
            checker.check_rows(rows)

    def test_cli_without_engine_and_truncated_jsonl(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "report.jsonl"
            text = "".join(json.dumps(row) + "\n" for row in complete_evidence())
            path.write_text(text)
            command = [sys.executable, str(ROOT / "scripts/check_orbital_platform.py"), str(path),
                       "--expected-source-sha256", "a" * 64]
            result = subprocess.run(command, capture_output=True, text=True)
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertEqual(60, json.loads(result.stdout)["completions"])
            path.write_text(text.rstrip("\n"))
            result = subprocess.run(command, capture_output=True, text=True)
            self.assertNotEqual(0, result.returncode)
            self.assertIn("unterminated", result.stderr)


if __name__ == "__main__":
    unittest.main()
