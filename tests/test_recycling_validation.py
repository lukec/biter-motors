"""Negative fixtures for final-prototype policy; native behavior is tested in Factorio."""

import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("recycling_checker", ROOT / "scripts/check-recycling-prototypes.py")
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)


def valid_dump():
    data = {"recipe": {}, "item": {}, "technology": {"recycling": {"effects": []}}}
    for name, ingredients in checker.APPROVED.items():
        data["recipe"][name] = {
            "ingredients": [{"name": item, "amount": count} for item, count in ingredients.items()],
            "results": [{"name": name, "amount": 1}],
        }
        data["recipe"][name + "-recycling"] = {
            "ingredients": [{"name": name, "amount": 1}],
            "results": [{"name": item, "amount": count // 4, "extra_count_fraction": count % 4 / 4}
                        for item, count in ingredients.items()],
            "categories": ["recycling"], "hidden": True, "allow_productivity": False,
        }
        data["technology"]["recycling"]["effects"].append({"type": "unlock-recipe", "recipe": name + "-recycling"})
    for chemistry, cell in checker.RECOVERY.items():
        damaged = f"bitermotors-damaged-{chemistry}-battery-pack"
        data["item"][damaged] = {"auto_recycle": False, "flags": ["always-show"]}
        data["recipe"][f"bitermotors-{chemistry}-battery-recovery"] = {
            "ingredients": [{"name": damaged, "amount": 10}],
            "results": [{"name": cell, "amount": 36}],
            "categories": ["recycling"], "auto_recycle": False, "allow_productivity": False,
        }
    data["recipe"]["bitermotors-wrecked-ev-recycling"] = {
        "results": [{"name": item} for item in ("steel-plate", "electronic-circuit", "battery")],
        "allow_productivity": False,
    }
    return data


class RecyclingValidationTest(unittest.TestCase):
    def test_checks_all_eighteen_rewrites_and_both_recovery_routes(self):
        self.assertEqual(checker.validate(valid_dump()), {"rewritten": 18, "battery_routes": 2, "assertions": 176})

    def test_rejects_stale_reverse_materials_and_changed_forward_recipes(self):
        for name in checker.APPROVED:
            with self.subTest(name=name):
                data = valid_dump()
                data["recipe"][name + "-recycling"]["results"][0]["name"] = "tungsten-carbide"
                with self.assertRaisesRegex(ValueError, "outputs"):
                    checker.validate(data)
        data = valid_dump()
        data["recipe"]["big-mining-drill"]["ingredients"][0]["amount"] = 8
        with self.assertRaisesRegex(ValueError, "forward ingredients"):
            checker.validate(data)

    def test_rejects_duplicate_unlocks_and_productivity(self):
        data = valid_dump()
        data["technology"]["recycling"]["effects"].append(data["technology"]["recycling"]["effects"][0])
        with self.assertRaisesRegex(ValueError, "duplicate unlock"):
            checker.validate(data)
        data = valid_dump()
        data["recipe"]["foundry-recycling"]["allow_productivity"] = True
        with self.assertRaisesRegex(ValueError, "non-productive"):
            checker.validate(data)

    def test_rejects_fluid_random_or_inflated_reverse_outputs(self):
        for field, value in (("type", "fluid"), ("independent_probability", 0.5),
                             ("amount", 500), ("extra_count_fraction", 0.8), ("amount_min", 1)):
            data = valid_dump()
            data["recipe"]["electric-furnace-recycling"]["results"][0][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                checker.validate(data)

    def test_rejects_recovery_fallback_bad_batch_yield_or_quality(self):
        for chemistry in checker.RECOVERY:
            damaged = f"bitermotors-damaged-{chemistry}-battery-pack"
            name = f"bitermotors-{chemistry}-battery-recovery"
            for defect in ("fallback", "batch", "yield", "productivity", "quality", "filterable"):
                data = valid_dump()
                if defect == "fallback":
                    data["recipe"][damaged + "-recycling"] = {}
                elif defect == "batch":
                    data["recipe"][name]["ingredients"][0]["amount"] = 1
                elif defect == "yield":
                    data["recipe"][name]["results"][0]["amount"] = 40
                elif defect == "productivity":
                    data["recipe"][name]["allow_productivity"] = True
                elif defect == "quality":
                    data["recipe"][name]["allow_quality"] = False
                else:
                    data["item"][damaged]["flags"] = []
                with self.subTest(chemistry=chemistry, defect=defect), self.assertRaises(ValueError):
                    checker.validate(data)

    def test_rejects_advanced_cells_in_generic_wrecks(self):
        data = valid_dump()
        data["recipe"]["bitermotors-wrecked-ev-recycling"]["results"].append({"name": "bitermotors-high-nickel-cell"})
        with self.assertRaisesRegex(ValueError, "generic wrecks"):
            checker.validate(data)

    def test_runtime_salvage_does_not_guess_chemistry_or_run_on_mining(self):
        control = (ROOT / "mod/bitermotors_0.1.1/control.lua").read_text()
        mapping = control[control.index("PLAYER_VEHICLE_BATTERY_SCRAP ="):control.index("PREMIUM_PILOT_PRODUCTION_GATE =")]
        self.assertNotIn("[PREMIUM_EV_NAME]", mapping)
        self.assertNotIn("insert_battery_retirement_scrap", control)
        anonymous_wrecks = control[control.index("generate_station_wrecks = function"):
                                  control.index("local function reservation_print_progress")]
        self.assertNotIn("DAMAGED_HIGH_ENERGY_PACK_NAME", anonymous_wrecks)
        self.assertNotIn("DAMAGED_LFP_PACK_NAME", anonymous_wrecks)
        self.assertNotIn("sold_customer_evs", anonymous_wrecks)
        self.assertIn("if event_name == defines.events.on_entity_died then spill_player_vehicle_salvage(entity) end", control)
        self.assertIn("stack = {name = item_name, count = count, quality = quality}", control)
        self.assertIn("statistics.on_flow({name = item_name, quality = quality}, spilled)", control)
        self.assertIn("statistics.on_flow(DAMAGED_LFP_PACK_NAME, damaged_packs)", control)
        self.assertIn("defines.events.on_robot_pre_mined", control)
        self.assertIn("defines.events.on_pre_player_mined_item", control)
        self.assertIn("remove_internal_drive_charge(entity.burner.inventory)", control)

    def test_runner_uses_actual_dump_and_separate_server_written_checkpoint(self):
        runner = (ROOT / "scripts/validate-bitermotors-recycling.sh").read_text()
        fixture = (ROOT / "scripts/fixtures/recycling-control.lua").read_text()
        self.assertIn('--dump-data', runner)
        self.assertIn('python3 "$checker" "$tmp/script-output/data-raw-dump.json"', runner)
        self.assertIn('--benchmark "$checkpoint" --benchmark-ticks 61', runner)
        self.assertIn('reload["tick"] > reload["saved_tick"]', runner)
        self.assertIn('game.server_save("bitermotors-recycling-reload")', fixture)
        self.assertNotIn('data.lua', runner)


if __name__ == "__main__":
    unittest.main()
