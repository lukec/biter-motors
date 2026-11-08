import json
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / "scripts/validate-bitermotors-finale.sh"
FIXTURE = ROOT / "scripts/fixtures/delivery-control.lua"


class DeliveryValidationTests(unittest.TestCase):
    def test_route_uses_native_payload_and_cargo_not_progress_injection(self):
        source = FIXTURE.read_text()
        for marker in ("on_cargo_pod_started_ascending", "on_cargo_pod_delivered_cargo",
                       "cargo_pod_origin", "space_platform_hub_requester", "trash_not_requested = true",
                       "actual full 20k input loading assertion", "native inserter physically extracted Model",
                       "one billion native earned equivalents", "19999 Datasets cannot assemble",
                       "new physical Model produced after assembly reload",
                       "new native activation event after activation reload",
                       "orbital outage banks progress", "one native assembly"):
            self.assertIn(marker, source)
        for forbidden in ("test_set_ai_token_progress", "crafting_progress =", "bonus_progress =",
                          "create_cargo_pod", "force_finish_ascending", "force_finish_descending",
                          "cargo_pod_destination =", "storage.bitermotors_"):
            self.assertNotIn(forbidden, source)
        self.assertEqual(40 * 125 * 4 * 50000, 1_000_000_000)

    def test_runner_is_isolated_bounded_and_inspects_even_successful_logs(self):
        source = RUNNER.read_text()
        wrapper = (ROOT / "scripts/validate-bitermotors-delivery.sh").read_text()
        self.assertIn("BITERMOTORS_ENDING_CASE=delivery exec bash", wrapper)
        for marker in ('bitermotors_stage_mod "$mods"', '--bind 127.0.0.1 --port "$port"',
                       'kill -INT "$server_pid"', 'for _ in {1..1200}', '--minimum-tick 1',
                       'for phase in assembly flight return activation won', '--benchmark-ticks 2461',
                       'bitermotors_check_log "$log" --expect-marker Goodbye'):
            self.assertIn(marker, source)
        self.assertNotIn("killall", source)
        self.assertLess(source.index('if ! bitermotors_check_log "$log"'),
                        source.index('if (( status != 0 ))'))
        for name in ("delivery", "finale"):
            self.assertTrue((ROOT / f"scripts/validate-bitermotors-{name}.sh").stat().st_mode & 0o111)
        result = subprocess.run(["bash", "-n", str(RUNNER)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)


class EndingReportContractTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.checker = re.search(r"<<'EOF_CHECK'\n(.*?)\nEOF_CHECK", RUNNER.read_text(), re.S).group(1)
        statuses = ["payload_passed", "assembly_checkpoint", "assembly_reload_passed", "assembly_passed",
                    "flight_checkpoint", "flight_reload_passed", "return_checkpoint", "return_reload_passed", "activation_checkpoint",
                    "activation_reload_passed", "won_checkpoint", "won_reload_passed"]
        self.rows = [{"status": status, "tick": 10 * (i + 1), "assertions": i + 1,
                      "validation_scope": "native-model-ending", "limits": "supplied construction",
                      "payload_quality": "normal"} for i, status in enumerate(statuses)]
        self.rows[0].update(datasets_loaded=20000, earned_equivalents=1000000000)
        self.rows[1].update(progress=0.4, products=125)
        self.rows[3].update(products_after_reload=126, assembly_reload_tick=30, native_completion_tick=35)
        self.rows[4].update(models_in_transit=1, return_credits=0, pod=77)
        self.rows[5].update(pod=77)
        self.rows[6].update(models_returned=1)
        self.rows[8].update(progress=0.4, products=0)
        self.rows[10].update(models_activated=1, victory={"tick": 110})
        for checkpoint, reload in ((1, 2), (4, 5), (6, 7), (8, 9), (10, 11)):
            self.rows[reload]["saved_tick"] = self.rows[checkpoint]["tick"]
        self.rows[11].update(victory={"tick": 110}, native_activations=1, freeplay_ticks=2400,
                            activation_measured_watts=8000000)
        for phase in ("seed", "assembly", "flight", "return", "activation", "won"):
            (self.directory / f"bitermotors-delivery-{phase}.zip").write_bytes(b"fixture checkpoint")

    def run_check(self):
        report = self.directory / "report.jsonl"
        report.write_text("".join(json.dumps(row) + "\n" for row in self.rows))
        return subprocess.run([sys.executable, "-c", self.checker, str(report), str(self.directory), "delivery"],
                              capture_output=True, text=True)

    def test_accepts_complete_report(self):
        result = self.run_check()
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_rejects_tick_zero(self):
        self.rows[0]["tick"] = 0
        self.assertNotEqual(self.run_check().returncode, 0)

    def test_rejects_old_products_after_reload(self):
        self.rows[3]["products_after_reload"] = 125
        self.assertNotEqual(self.run_check().returncode, 0)

    def test_rejects_old_native_event_after_reload(self):
        self.rows[3]["native_completion_tick"] = 29
        self.assertNotEqual(self.run_check().returncode, 0)

    def test_rejects_partial_payload(self):
        self.rows[0]["datasets_loaded"] = 19999
        self.assertNotEqual(self.run_check().returncode, 0)

    def test_rejects_missing_or_duplicate_phase(self):
        self.rows.insert(3, dict(self.rows[2]))
        self.assertNotEqual(self.run_check().returncode, 0)

    def test_rejects_missing_native_checkpoint(self):
        (self.directory / "bitermotors-delivery-return.zip").unlink()
        self.assertNotEqual(self.run_check().returncode, 0)

    def test_rejects_paused_freeplay(self):
        self.rows[11]["freeplay_ticks"] = 0
        self.assertNotEqual(self.run_check().returncode, 0)

    def test_rejects_changed_victory_after_reload(self):
        self.rows[11]["victory"] = {"tick": 120}
        self.assertNotEqual(self.run_check().returncode, 0)

    def test_rejects_replaced_inflight_pod(self):
        self.rows[5]["pod"] = 78
        self.assertNotEqual(self.run_check().returncode, 0)

    def test_rejects_flight_save_after_delivery(self):
        self.rows[4]["return_credits"] = 1
        self.assertNotEqual(self.run_check().returncode, 0)


if __name__ == "__main__":
    unittest.main()
