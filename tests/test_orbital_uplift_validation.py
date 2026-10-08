import copy
import importlib.util
import json
import re
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / "scripts/validate-bitermotors-uplift.sh"
FIXTURE = ROOT / "scripts/fixtures/uplift-control.lua"
CHECKER_SOURCE = re.search(r"<<'EOF_CHECK'\n(.*?)\nEOF_CHECK", RUNNER.read_text(), re.S).group(1)
CHECKER = {"__name__": "uplift_test_checker"}
exec(compile(CHECKER_SOURCE, str(RUNNER), "exec"), CHECKER)
SPEC = importlib.util.spec_from_file_location("uplift_validation_support", ROOT / "scripts/validation_support.py")
SUPPORT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SUPPORT)


def complete_evidence():
    manifest = CHECKER["MANIFEST"].copy()
    manufactured = {name: count for name, count in manifest.items() if name != CHECKER["DOLLAR"]}
    setup = {"status": "uplift_setup_passed", "tick": 0, "assertions": 50,
             "weights": CHECKER["WEIGHTS"].copy(), "science": CHECKER["SCIENCE"].copy(),
             "footprints": {name: [3, 3] for name in (CHECKER["CORE"], CHECKER["SOLAR"], CHECKER["RADIATOR"])},
             "manifest": manifest.copy(), "inserter_stack_size_bonus": 2}
    manufacture = {"status": "uplift_manufacture_passed", "tick": 6000, "assertions": 100,
                   "starter_tick": 1000, "platform_research_tick": 1000,
                   "researched_tick": 5000, "science_consumed": 1500, "manufactured": manufactured.copy()}
    shipments = []
    for i, (name, count) in enumerate(manifest.items()):
        if name == "space-platform-foundation":
            count = 50
        shipments.append({"cargo": {name: count}, "mass": CHECKER["CARGO_WEIGHTS"][name] * count,
                          "slots": 1, "capacity": 10, "tick": 500 + i * 1000, "delivered_tick": 1000 + i * 1000,
                          "origin": "nauvis-silo", "launched_by_rocket": True})
    shipments[0]["mass"] = 1_000_000
    second_foundation = copy.deepcopy(shipments[1])
    second_foundation.update(tick=8500, delivered_tick=9000, mass=1_000_000)
    shipments[1]["mass"] = 1_000_000
    shipments.append(second_foundation)
    delivery = {"status": "uplift_delivery_passed", "tick": 10000, "assertions": 200,
                "starter_tick": 1000, "shipped": manifest.copy(), "delivered": manifest.copy(),
                "manufactured": manufactured.copy(), "shipments": shipments,
                "built": {name: manifest[name] for name in (CHECKER["CORE"], CHECKER["SOLAR"],
                          CHECKER["RADIATOR"], "transport-belt", "inserter")},
                "built_tiles": 100, "rockets": 9, "rocket_parts": 450,
                "gravity": 0, "solar_coefficient": 300, "core_watts": 250_000_000,
                "wing_nominal_watts": 20_000_000,
                "requests": {name: {"count": count + (10 if name == "space-platform-foundation" else 0),
                    "minimum_delivery_count": 50 if name == "space-platform-foundation" else count} for name, count in manifest.items()
                    if name != "space-platform-starter-pack"},
                "foundation_remaining": 10, "physical_tokens": 0,
                "rocket_consumed": {"processing-unit": 450, "low-density-structure": 450, "rocket-fuel": 450},
                "produced": 0, "returned": 0, "return_pods": 0}
    returned = copy.deepcopy(delivery)
    returned.update(status="uplift_return_passed", tick=14000, assertions=250, operation_tick=10000,
                    produced=10000, returned=10000, return_pods=2, core_completions=1,
                    earned_equivalents=10000, dollars_remaining=99, physical_tokens=10000)
    reload = copy.deepcopy(returned)
    reload.update(status="uplift_reload_passed", tick=14060, assertions=260, saved_tick=14000)
    return [setup, manufacture, delivery, returned, reload]


class OrbitalUpliftValidationTests(unittest.TestCase):
    def validate(self, rows):
        return CHECKER["validate_rows"](rows)

    def test_complete_native_evidence_passes(self):
        self.validate(complete_evidence())

    def test_native_starter_can_deliver_on_the_ascending_event_tick(self):
        rows = complete_evidence()
        for row in rows[2:]:
            row["shipments"][0]["tick"] = row["shipments"][0]["delivered_tick"]
        self.validate(rows)

    def test_pod_capacity_rejects_eleven_slots_despite_twenty_slot_rocket(self):
        rows = complete_evidence()
        for row in rows[2:]:
            row["shipments"][2]["slots"] = 11
        with self.assertRaises(ValueError):
            self.validate(rows)
        for row in rows[2:]:
            row["shipments"][2]["capacity"] = 20
        with self.assertRaises(ValueError):
            self.validate(rows)

    def test_missing_duplicate_out_of_order_or_failed_milestone_rejected(self):
        rows = complete_evidence()
        for mutant in (rows[:-1], rows + [rows[-1]], rows[:2] + rows[3:],
                       [rows[1], rows[0]] + rows[2:], []):
            with self.subTest(rows=mutant), self.assertRaises(ValueError):
                self.validate(mutant)
        for status in ("failed", "error", "uplift_setup_passed"):
            mutant = complete_evidence()
            mutant[-1]["status"] = status
            with self.subTest(status=status), self.assertRaises(ValueError):
                self.validate(mutant)

    def test_zero_ticks_boolean_counters_and_missing_assertions_rejected(self):
        for index, key, value in ((1, "tick", 0), (4, "tick", 14000), (2, "assertions", 0),
                                  (2, "assertions", True), (2, "tick", True)):
            mutant = complete_evidence()
            mutant[index][key] = value
            with self.subTest(key=key, value=value), self.assertRaises(ValueError):
                self.validate(mutant)

    def test_transport_hardware_research_and_return_contracts_rejected(self):
        mutations = [
            (0, "weights", {**CHECKER["WEIGHTS"], CHECKER["CORE"]: 1_208_326}),
            (0, "weights", {**CHECKER["WEIGHTS"], CHECKER["DOLLAR"]: 250_025}),
            (0, "science", {**CHECKER["SCIENCE"], "space-science-pack": 1}),
            (0, "footprints", {}), (1, "science_consumed", 0),
            (0, "inserter_stack_size_bonus", 3),
            (1, "platform_research_tick", 0), (1, "researched_tick", 900),
            (2, "built_tiles", 99), (2, "rockets", 0), (2, "rocket_parts", 0),
            (2, "gravity", 10), (2, "solar_coefficient", 100), (2, "core_watts", 1),
            (2, "wing_nominal_watts", 50_000_000),
            (2, "requests", {}), (2, "foundation_remaining", 0),
            (2, "rocket_consumed", {}), (2, "shipped", {}), (2, "delivered", {}),
            (2, "built", {}), (2, "manufactured", {}),
            (2, "produced", 10000), (3, "produced", 0), (3, "returned", 9999),
            (3, "return_pods", 0), (3, "earned_equivalents", 0),
            (3, "dollars_remaining", 100), (3, "core_completions", 0),
            (3, "operation_tick", 0), (4, "saved_tick", 0), (4, "returned", 0),
            (3, "physical_tokens", 0), (4, "physical_tokens", 9999),
            (4, "earned_equivalents", 0), (4, "core_completions", 0), (4, "dollars_remaining", 100),
        ]
        for index, key, value in mutations:
            mutant = complete_evidence()
            mutant[index][key] = value
            with self.subTest(index=index, key=key), self.assertRaises(ValueError):
                self.validate(mutant)

    def test_forged_missing_overweight_or_incomplete_shipments_rejected(self):
        mutations = [("origin", "platform"), ("launched_by_rocket", False),
                     ("launched_by_rocket", 1), ("mass", 1_000_001), ("mass", 0),
                     ("slots", 0), ("slots", 21), ("capacity", 0), ("tick", 0), ("delivered_tick", 0),
                     ("cargo", {}), ("cargo", {CHECKER["CORE"]: 10}),
                     ("cargo", {CHECKER["CORE"]: 1, CHECKER["DOLLAR"]: 100})]
        for key, value in mutations:
            mutant = complete_evidence()
            for row in mutant[2:]:
                row["shipments"][2][key] = value
            with self.subTest(key=key, value=value), self.assertRaises(ValueError):
                self.validate(mutant)
        mutant = complete_evidence()
        for row in mutant[2:]:
            row["shipments"].pop()
        with self.assertRaises(ValueError):
            self.validate(mutant)

    def test_report_only_cli_never_needs_factorio_and_rejects_truncation(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "report.jsonl"
            text = "".join(json.dumps(row) + "\n" for row in complete_evidence())
            for payload, success in ((text, True), (text.rstrip(), False), ("", False),
                                     ('{"status":"error"}\n', False), ("not-json\n", False)):
                path.write_text(payload)
                result = subprocess.run([str(RUNNER), "--check-report", str(path)],
                                        capture_output=True, text=True, timeout=10)
                with self.subTest(payload=payload[:40]):
                    self.assertEqual(result.returncode == 0, success, result.stderr)

    def test_zero_exit_runtime_error_logs_are_rejected_even_with_goodbye(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "engine.log"
            for message in ("Error while running event bitermotors_uplift_validation::on_nth_tick(60)",
                            "The mod caused a non-recoverable error.", "LuaEntity API call when LuaEntity was invalid"):
                path.write_text(f"{message}\nPerformed 61 updates\nGoodbye\n")
                with self.subTest(message=message), self.assertRaises(ValueError):
                    SUPPORT.check_log(path, 61, "Goodbye")
            path.write_text("Performed 61 updates\nGoodbye\n")
            SUPPORT.check_log(path, 61, "Goodbye")
            path.write_text("Goodbye\n")
            with self.assertRaises(ValueError):
                SUPPORT.check_log(path, 61, "Goodbye")

    def test_fixture_does_not_seed_platform_hardware_or_fake_cargo(self):
        source = FIXTURE.read_text()
        for forbidden in ("apply_starter_pack(", "create_cargo_pod", "force_finish_ascending",
                          "force_finish_descending", "cargo_pod_destination =",
                          "crafting_progress =", "bonus_progress =", "test_set_ai_token_progress",
                          "default_request_amount", "rocket_launch_amount", "surface.set_property"):
            self.assertNotIn(forbidden, source)
        self.assertNotRegex(source, r"\.[ \t]*rocket_parts\s*=(?!=)")
        self.assertNotRegex(source, r"\.[ \t]*active\s*=(?!=)")
        self.assertEqual(source.count(".set_tiles("), 1)
        self.assertIn('game.surfaces.nauvis.create_entity', source)
        self.assertIn('name = "entity-ghost", inner_name = name', source)
        self.assertIn('name = "tile-ghost", inner_name = "space-platform-foundation"', source)
        for marker in ("on_cargo_pod_finished_ascending", "on_cargo_pod_delivered_cargo",
                       "on_cargo_pod_started_ascending", "on_space_platform_built_entity",
                       "on_space_platform_built_tile", "on_rocket_launched", "minimum_delivery_count = minimum",
                       "sections", "on_crafted_event", "trash_not_requested = true",
                       'game.server_save("bitermotors-uplift-reload")', "remaining_dollars()"):
            self.assertIn(marker, source)
        self.assertIn('technology.name ~= "space-platform"', source)
        self.assertIn('"native create-space-platform trigger"', source)
        self.assertIn('"native lab entry research"', source)
        self.assertIn('storage.core.disabled_by_script = true', source)
        self.assertIn('entity.inserter_stack_size_override = 1', source)
        self.assertIn('storage.core.is_crafting()', source)
        self.assertIn('loaded = false', source)
        self.assertIn('"live earned ledger survives reload"', source)
        self.assertIn('"live core completions survive reload"', source)

    def test_runner_is_isolated_bounded_checkpointed_and_checks_all_logs(self):
        source = RUNNER.read_text()
        self.assertTrue(RUNNER.stat().st_mode & 0o111)
        for marker in ('bitermotors_stage_mod "$mods"', 'mktemp -d /tmp/bitermotors-uplift.',
                       '--bind 127.0.0.1 --port "$port"', 'attempt<3000', 'kill -INT "$pid"',
                       'bitermotors_check_log "$tmp/server.log" --expect-marker Goodbye',
                       'bitermotors_check_log "$tmp/reload.log" --expect-updates 61',
                       'bitermotors_check_log "$log" --expect-marker Goodbye',
                       '--require-status uplift_return_passed', '--require-status uplift_reload_passed',
                       '--benchmark-ticks 61 --benchmark-runs 1', 'test -s "$reload"', 'trap cleanup EXIT'):
            self.assertIn(marker, source)
        for forbidden in ("killall", "tmux", "--rcon", "--load-game"):
            self.assertNotIn(forbidden, source)
        info = json.loads(re.search(r"<<'EOF_INFO'\n(.*?)\nEOF_INFO", source, re.S).group(1))
        self.assertIn("base >= 2.1.20", info["dependencies"])
        self.assertIn("space-age >= 2.1.20", info["dependencies"])


if __name__ == "__main__":
    unittest.main()
