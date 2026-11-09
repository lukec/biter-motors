import copy
import json
import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / "scripts/validate-bitermotors-cooling.sh"
FIXTURE = ROOT / "scripts/fixtures/cooling-control.lua"


def valid_rows():
    return [
        dict(status="cooling_policy_passed", tick=240, assertions=30, work_policy="banked",
             platforms=2, zero_vs_one=True, capacity_scope="physical-heat-networks", before_first_craft_paused=False,
             supplied_power_fixture=True, solar_power_multiplier=0),
        dict(status="cooling_checkpoint", tick=4000, assertions=100, saved_tick=4000,
             saved_file="bitermotors-cooling-failure.zip", failure="native_total_power",
             work_policy="banked", power_limited=True, paused_for_cooling=False, progress=0.4,
             full_rate=0.0005, half_rate=0.00024, generated=10000, products=0, output=0,
             quality="rare", dollars_supplied=1, dollars_remaining=0, replacement_dollars=0,
             cooling_progress_preserved=True, blocked_output_generated=0,
             base_products=1, base_output=10000, base_events=1),
        dict(status="orbital_banked_reload_passed", tick=8000, assertions=120, saved_tick=4000,
             work_policy="banked", progress_after_reload=0.4, quality="rare", replacement_dollars=0,
             dollars_supplied=1, dollars_remaining=0, recovered_products=1,
             recovery_output_delta=10000, recovery_ledger_delta=10000, generated=20000, native_events=1),
        dict(status="terrestrial_scrap_passed", tick=15000, assertions=150,
             original_dollars=20, scrapped_dollars=20, failure_generated=0,
             restored_without_inputs_products=0, retry_dollars=20, retry_products=1,
             retry_output=20, retry_generated=20, native_events=1),
        dict(status="cooling_reload_passed", tick=15000, assertions=150, saved_tick=4000,
             work_policy="banked", orbital_generated=20000, terrestrial_generated=20,
             platform_removal=True, separate_process_reload=True),
    ]


class CoolingValidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.runner = RUNNER.read_text()
        cls.fixture = FIXTURE.read_text()

    def validate(self, rows=None, *, raw=None, seed=b"seed", checkpoint=b"checkpoint"):
        with tempfile.TemporaryDirectory(prefix="cooling-report-test-") as directory:
            directory = Path(directory)
            report = directory / "report.jsonl"
            report.write_text(raw if raw is not None else "\n".join(map(json.dumps, rows)))
            saves = [directory / "seed.zip", directory / "bitermotors-cooling-failure.zip"]
            for path, content in zip(saves, (seed, checkpoint)):
                if content is not None:
                    path.write_bytes(content)
            return subprocess.run(
                ["bash", str(RUNNER), "--check-report", str(report), *map(str, saves)],
                env={**os.environ, "FACTORIO_BINARY": "/must-not-launch-factorio"},
                text=True, capture_output=True, timeout=10,
            )

    def test_valid_banked_report_without_engine(self):
        result = self.validate(valid_rows())
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Cooling fixture passed:", result.stdout)

    def test_every_required_field_is_fail_closed(self):
        for index, row in enumerate(valid_rows()):
            for key in row:
                with self.subTest(row=index, missing=key):
                    rows = valid_rows()
                    del rows[index][key]
                    self.assertNotEqual(self.validate(rows).returncode, 0)

    def test_new_contract_and_conservation_reject_corruption(self):
        corruptions = {
            0: dict(work_policy="reset", zero_vs_one=1, before_first_craft_paused=True),
            1: dict(power_limited="true", paused_for_cooling=True, progress=0,
                    replacement_dollars=1, dollars_remaining=1, generated=0, products=1,
                    full_rate=float("inf"), half_rate=0.0005, base_output=0,
                    base_events=0, blocked_output_generated=10000, saved_tick=3999),
            2: dict(progress_after_reload=0.1, replacement_dollars=1, recovered_products=2,
                    recovery_output_delta=0, recovery_ledger_delta=20000, generated=10000,
                    quality="normal", native_events=2),
            3: dict(scrapped_dollars=0, failure_generated=20, restored_without_inputs_products=1,
                    retry_dollars=0, retry_output=0, retry_generated=40, native_events=2),
            4: dict(orbital_generated=10000, terrestrial_generated=0, separate_process_reload=False),
        }
        for index, changes in corruptions.items():
            for key, value in changes.items():
                with self.subTest(row=index, key=key, value=value):
                    rows = valid_rows()
                    rows[index][key] = value
                    self.assertNotEqual(self.validate(rows).returncode, 0)

    def test_old_reset_evidence_cannot_be_relabeled(self):
        for key in ("reset_for_power", "reset_for_cooling", "half_power_reset_and_recovery",
                    "cooling_failure_reset", "total_power_failure_reset"):
            rows = valid_rows()
            rows[2][key] = True
            with self.subTest(key=key):
                self.assertNotEqual(self.validate(rows).returncode, 0)

    def test_reports_require_order_advancing_ticks_and_real_files(self):
        rows = valid_rows()
        variants = [rows[:-1], rows + [copy.deepcopy(rows[-1])], rows[::-1]]
        for index, key, value in ((2, "tick", 4000), (0, "tick", 0), (1, "tick", True),
                                  (2, "assertions", 30), (4, "tick", 15001)):
            changed = copy.deepcopy(rows)
            changed[index][key] = value
            variants.append(changed)
        for changed in variants:
            self.assertNotEqual(self.validate(changed).returncode, 0)
        for raw in ("", "{", "[]", "null", "42", '{"status":"cooling_reload_passed"}'):
            self.assertNotEqual(self.validate(raw=raw).returncode, 0)
        for content in (None, b""):
            self.assertNotEqual(self.validate(rows, seed=content).returncode, 0)
            self.assertNotEqual(self.validate(rows, checkpoint=content).returncode, 0)

    def test_runner_uses_isolated_real_server_checkpoint_and_reload(self):
        for marker in (
            'source "$repo_root/scripts/lib/bitermotors-validation.sh"',
            "bitermotors_stage_mod", "bitermotors_check_log", "--expect-marker Goodbye",
            '--bind 127.0.0.1 --port "$port"', 'kill -INT "$server_pid"',
            'start_server "$save" "$tmp/first-server.log"',
            'start_server "$checkpoint" "$tmp/reload-server.log"',
            'wait_for_phase cooling_checkpoint', 'test -s "$checkpoint"',
            '"$report" --require-status "$expected" --minimum-tick 1',
            'validate_report "$report" "$save" "$checkpoint"',
            "for _ in {1..1500}", "trap cleanup EXIT INT TERM",
        ):
            self.assertIn(marker, self.runner)
        self.assertNotIn("killall", self.runner)
        self.assertNotIn("--benchmark", self.runner)
        metadata = re.search(r"<<'EOF_INFO'\n(.*?)\nEOF_INFO", self.runner, re.S)
        self.assertEqual(json.loads(metadata.group(1))["dependencies"], [
            "base >= 2.1.20", "space-age >= 2.1.20", "bitermotors >= 0.1.1"])

    def test_fixture_requires_native_banked_and_terrestrial_evidence(self):
        for marker in (
            "missing cooling does not script-pause a cold core", "physical cooling replaces quota allocation",
            "cooling loss generates heat, not a script hold", "disconnected cooling allows positive native progress",
            "blocked_output", "full_output", "power is not a script hold",
            "half-power gives slower positive native progress without cancellation",
            "full outage holds identical positive progress", "same positive progress survives separate-process reload",
            "no duplicate completion without replacement Dollar", "new rare physical batch after reload",
            "terrestrial low-power still cancels batch", "terrestrial failure ledger0",
            "restored terrestrial power cannot finish scrapped batch", "new terrestrial retry succeeds once",
            'game.server_save("bitermotors-cooling-failure")', "on_crafted_event",
            "value.surface.solar_power_multiplier = 0",
            "event.entity.unit_number", "event.bonus", 'work_policy, "banked"',
            'type(row.power_limited), "boolean"', 'type(row.paused_for_cooling), "boolean"',
        ):
            self.assertIn(marker, self.fixture)
        self.assertEqual(self.fixture.count("script.on_event(defines.events.on_tick"), 1)
        self.assertIn('storage.stage == "power_checkpoint"', self.fixture)
        self.assertIn('script.on_load', self.fixture)
        self.assertNotRegex(self.fixture, r"(?:crafting_progress|bonus_progress|\.active)\s*=")
        self.assertNotRegex(self.fixture, r"\.generated\s*=")
        self.assertNotIn("AiAccounting.record", self.fixture)
        self.assertNotIn("energy_required", self.fixture)
        self.assertNotIn("game.write_file", self.fixture)

    def test_shell_syntax_and_executable(self):
        self.assertTrue(RUNNER.stat().st_mode & 0o111)
        result = subprocess.run(["bash", "-n", str(RUNNER)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
