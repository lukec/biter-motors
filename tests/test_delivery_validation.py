import json
import copy
import os
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
                       'phases=(assembly flight return activation won)', '--benchmark-ticks 2461',
                       'bitermotors_check_log "$log" --expect-marker Goodbye'):
            self.assertIn(marker, source)
        self.assertNotIn("killall", source)
        self.assertLess(source.index('if ! bitermotors_check_log "$log"'),
                        source.index('if (( status != 0 ))'))
        for name in ("delivery", "finale", "epilogue"):
            self.assertTrue((ROOT / f"scripts/validate-bitermotors-{name}.sh").stat().st_mode & 0o111)
        result = subprocess.run(["bash", "-n", str(RUNNER)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_missing_native_player_bootstrap_fails_before_launching_engine(self):
        env = dict(os.environ, BITERMOTORS_ENDING_PLAYER_SAVE="/nonexistent/epilogue-player-save.zip",
                   FACTORIO_BINARY="/nonexistent/must-not-launch-factorio")
        wrapper = ROOT / "scripts/validate-bitermotors-epilogue.sh"
        result = subprocess.run(["bash", str(wrapper)], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn("BITERMOTORS_ENDING_PLAYER_SAVE", result.stderr)
        self.assertNotIn("executable is unavailable", result.stderr)

    def test_mechanical_default_needs_no_seed_and_cannot_be_upgraded_by_seed_env(self):
        env = dict(os.environ, BITERMOTORS_VALIDATE_EPILOGUE="0",
                   BITERMOTORS_ENDING_PLAYER_SAVE="/nonexistent/ignored-seed.zip",
                   FACTORIO_BINARY="/nonexistent/factorio")
        result = subprocess.run(["bash", str(RUNNER)], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn("executable is unavailable", result.stderr)
        self.assertNotIn("Set BITERMOTORS_ENDING_PLAYER_SAVE", result.stderr)

    def test_late_join_window_is_explicit_and_wall_time_bounded(self):
        source = RUNNER.read_text()
        for marker in ("BITERMOTORS_EPILOGUE_LATE_TIMEOUT_SECONDS", "SECONDS >= deadline",
                       "BITERMOTORS_EPILOGUE_AWAITING_LATE_PLAYER", '"$port"',
                       "bitermotors-epilogue-needs-player.json"):
            self.assertIn(marker, source)
        fixture = (ROOT / "scripts/fixtures/epilogue-validation.lua").read_text()
        self.assertIn('status = "awaiting_late_player"', fixture)
        self.assertIn('if not f.late or f.late.connected then return end', fixture)

    def test_fixture_player_names_are_lan_safe_and_late_lookup_matches_marker(self):
        fixture = (ROOT / "scripts/fixtures/epilogue-validation.lua").read_text()
        runner = RUNNER.read_text()
        for name in ("Epilogue-first", "Epilogue-second", "Epilogue-unwon", "Epilogue-late"):
            self.assertIn(name, fixture)
            self.assertIn(name, runner)
            self.assertNotIn(name.replace("-", " "), fixture + runner)
        self.assertIn('player_name = "Epilogue-late"', fixture)
        self.assertIn('f.late = game.get_player("Epilogue-late")', fixture)
        self.assertIn('not used[candidate.index] and not named[candidate.name]', fixture)

    def test_single_player_is_explicit_and_requires_a_real_seed(self):
        env = dict(os.environ, BITERMOTORS_ENDING_PLAYER_SAVE="/nonexistent/seed.zip",
                   FACTORIO_BINARY="/nonexistent/must-not-launch-factorio")
        wrapper = ROOT / "scripts/validate-bitermotors-epilogue.sh"
        result = subprocess.run(["bash", str(wrapper), "--single-player"], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn("one actual offline player", result.stderr)
        result = subprocess.run(["bash", str(wrapper), "--full"], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn("three offline players", result.stderr)


class EndingReportContractTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.full_epilogue = True
        self.single_player = False
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
                            activation_measured_watts=8000000, epilogue_passed=True)
        extra = []
        for phase in ("epilogue_thinking", "epilogue_reply", "epilogue_acknowledged", "epilogue_late"):
            for suffix in ("checkpoint", "reload_passed"):
                row = dict(self.rows[0], status=f"{phase}_{suffix}", tick=120 + len(extra) * 10)
                if suffix == "reload_passed":
                    row["saved_tick"] = extra[-1]["tick"]
                extra.append(row)
        self.rows[11:11] = extra
        self.rows[-1]["tick"] = 200
        for row in self.rows:
            row.update(presentation_scope="native-offline-gui-public-callbacks", single_player=False,
                       multiplayer_qualified=False, native_player_isolation_qualified=False,
                       presentation_limits="Mouse/Escape/network acceptance is separate")
            player = dict(phase="pending", acknowledged=False, skipped=False, eligible=True,
                          open=False, elapsed_ticks=0, force_index=1, victory_tick=110)
            row["epilogue"] = dict(first=dict(player), second=dict(player), victory_tick=110,
                                   outsider=dict(phase="locked", eligible=False))
        for row in self.rows[11:]:
            epilogue = row["epilogue"]
            epilogue["first"].update(phase="thinking", elapsed_ticks=60, open=True)
            if row["status"] != "epilogue_thinking_checkpoint":
                epilogue["second"].update(phase="acknowledged", acknowledged=True, skipped=True)
            if row["status"] == "epilogue_reply_checkpoint":
                epilogue["first"].update(phase="reply", elapsed_ticks=180)
            elif row["status"] in ("epilogue_reply_reload_passed", "epilogue_acknowledged_checkpoint",
                                    "epilogue_acknowledged_reload_passed", "epilogue_late_checkpoint",
                                    "epilogue_late_reload_passed", "won_reload_passed"):
                epilogue["first"].update(phase="acknowledged", acknowledged=True, open=False)
        self.rows[-1]["epilogue_evidence"] = dict(replay_preserved_ack=True, force_isolated=True,
                                                 repeated_open_idempotent=True,
                                                 late_created_once=True, late=dict(acknowledged=True))
        self.rows[-1]["epilogue_evidence"]["progress_gui_checks"] = {
            f"{phase}_{suffix}": dict(stage=label, detail="Victory recorded" if phase == "won" else "Payload committed; 42% banked",
                                      progress=1 if phase == "won" else 0.42,
                                      **({} if phase == "won" else dict(payload="Payload committed")))
            for phase, label in (("assembly", "Model assembly"), ("activation", "Ground activation"), ("won", "Complete"))
            for suffix in ("checkpoint", "reload")}
        self.rows[-1]["epilogue_evidence"]["progress_force_cache"] = dict(
            primed_stage="First delivery", returned_stage="First delivery", won_stage="Complete",
            restored_won_stage="Complete", same_frame=True, no_spoilers=True)
        self.rows[-1]["epilogue_qualification"] = "native-offline-player-isolation-qualified"
        self.rows[-1]["native_player_isolation_qualified"] = True
        for phase in ("seed", "assembly", "flight", "return", "activation", "won",
                      "epilogue_thinking", "epilogue_reply", "epilogue_acknowledged", "epilogue_late"):
            (self.directory / f"bitermotors-delivery-{phase}.zip").write_bytes(b"fixture checkpoint")

    def run_check(self):
        report = self.directory / "report.jsonl"
        report.write_text("".join(json.dumps(row) + "\n" for row in self.rows))
        return subprocess.run([sys.executable, "-c", self.checker, str(report), str(self.directory), "delivery",
                               "1" if self.full_epilogue else "0", "1" if self.single_player else "0"],
                              capture_output=True, text=True)

    def test_accepts_complete_report(self):
        result = self.run_check()
        self.assertEqual(result.returncode, 0, result.stderr)

    def mechanical_report(self):
        self.rows = [row for row in self.rows if not row["status"].startswith("epilogue_")]
        self.full_epilogue = False
        for row in self.rows:
            row.update(epilogue_passed=False, epilogue_qualification="not-qualified",
                       presentation_scope="not-qualified", multiplayer_qualified=False,
                       native_player_isolation_qualified=False)
            row.pop("epilogue", None)
            row.pop("epilogue_evidence", None)

    def test_accepts_original_twelve_phase_mechanical_route_without_gui(self):
        self.mechanical_report()
        self.assertEqual(len(self.rows), 12)
        result = self.run_check()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("epilogue NOT QUALIFIED", result.stdout)

    def test_full_epilogue_cannot_silently_accept_mechanical_route(self):
        self.mechanical_report()
        self.full_epilogue = True
        self.assertNotEqual(self.run_check().returncode, 0)

    def test_mechanical_route_cannot_claim_epilogue_qualification(self):
        self.mechanical_report()
        self.rows[-1].update(epilogue_passed=True, epilogue_qualification="qualified")
        self.assertNotEqual(self.run_check().returncode, 0)

    def single_player_report(self):
        self.single_player = True
        for row in self.rows:
            row.update(single_player=True, multiplayer_qualified=False, native_player_isolation_qualified=False,
                       presentation_scope="native-single-player-gui-public-callbacks")
            row["epilogue"].pop("second")
            row["epilogue"].pop("outsider")
            if row["status"].startswith("epilogue_late_"):
                row["status"] = row["status"].replace("epilogue_late_", "epilogue_replay_")
        replay = next(row for row in self.rows if row["status"] == "epilogue_replay_checkpoint")
        replay["epilogue"]["first"].update(phase="thinking", elapsed_ticks=60, replay=True, open=True)
        self.rows[-1]["epilogue_evidence"].pop("late")
        self.rows[-1]["epilogue_evidence"].pop("late_created_once")
        self.rows[-1]["epilogue_evidence"]["thinking_dismiss_preserved_ack"] = True
        self.rows[-1]["epilogue_qualification"] = "native-offline-single-player-qualified"
        (self.directory / "bitermotors-delivery-epilogue_replay.zip").write_bytes(b"native checkpoint")

    def test_accepts_honestly_scoped_single_player_report(self):
        self.single_player_report()
        result = self.run_check()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("multiplayer NOT QUALIFIED", result.stdout)

    def test_single_player_cannot_satisfy_full_multiplayer_qualification(self):
        self.single_player_report()
        self.single_player = False
        self.assertNotEqual(self.run_check().returncode, 0)

    def test_no_fixture_mode_may_claim_broad_multiplayer_qualification(self):
        original = copy.deepcopy(self.rows)
        for mode in ("full", "single", "mechanical"):
            for index in (0, -1):
                with self.subTest(mode=mode, index=index):
                    self.rows = copy.deepcopy(original)
                    self.full_epilogue, self.single_player = True, False
                    if mode == "single":
                        self.single_player_report()
                    elif mode == "mechanical":
                        self.mechanical_report()
                    self.rows[index]["multiplayer_qualified"] = True
                    self.assertNotEqual(self.run_check().returncode, 0)

    def test_full_mode_requires_explicit_narrow_native_isolation_qualification(self):
        self.rows[-1]["native_player_isolation_qualified"] = False
        self.assertNotEqual(self.run_check().returncode, 0)
        self.rows[-1]["native_player_isolation_qualified"] = True
        self.rows[-1]["epilogue_qualification"] = "qualified"
        self.assertNotEqual(self.run_check().returncode, 0)

    def test_preserves_existing_explicitly_non_multiplayer_single_player_captures(self):
        self.single_player_report()
        for row in self.rows:
            row.pop("native_player_isolation_qualified")
        self.rows[-1]["epilogue_qualification"] = "single-player-qualified"
        result = self.run_check()
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_single_player_cannot_claim_multiplayer_or_late_creation(self):
        self.single_player_report()
        self.rows[-1]["multiplayer_qualified"] = True
        self.assertNotEqual(self.run_check().returncode, 0)
        self.rows[-1]["multiplayer_qualified"] = False
        self.rows[-1]["epilogue_evidence"]["late_created_once"] = True
        self.assertNotEqual(self.run_check().returncode, 0)

    def test_single_player_must_preserve_initial_unacknowledged_thinking(self):
        self.single_player_report()
        self.rows[11]["epilogue"]["first"]["acknowledged"] = True
        self.assertNotEqual(self.run_check().returncode, 0)

    def test_requires_native_progress_gui_at_every_checkpoint_and_reload(self):
        self.single_player_report()
        original = copy.deepcopy(self.rows)
        for phase in ("assembly", "activation", "won"):
            for suffix in ("checkpoint", "reload"):
                with self.subTest(phase=phase, suffix=suffix):
                    self.rows = copy.deepcopy(original)
                    del self.rows[-1]["epilogue_evidence"]["progress_gui_checks"][f"{phase}_{suffix}"]
                    self.assertNotEqual(self.run_check().returncode, 0)

    def test_rejects_empty_ingredient_instructions_and_lost_completion_in_native_gui(self):
        self.single_player_report()
        original = copy.deepcopy(self.rows)
        for name, field, value in (("assembly_checkpoint", "payload", "0 / 20000 Datasets"),
                                   ("activation_reload", "detail", "Load the returned AGI Model"),
                                   ("won_reload", "stage", "Model assembly")):
            with self.subTest(name=name, field=field):
                self.rows = copy.deepcopy(original)
                self.rows[-1]["epilogue_evidence"]["progress_gui_checks"][name][field] = value
                self.assertNotEqual(self.run_check().returncode, 0)

    def test_rejects_native_progress_force_cache_spoilers_or_reset_panel(self):
        self.single_player_report()
        original = copy.deepcopy(self.rows)
        for field, value in (("returned_stage", "Complete"), ("primed_stage", "Complete"),
                             ("same_frame", False), ("no_spoilers", False),
                             ("restored_won_stage", "First delivery")):
            with self.subTest(field=field):
                self.rows = copy.deepcopy(original)
                self.rows[-1]["epilogue_evidence"]["progress_force_cache"][field] = value
                self.assertNotEqual(self.run_check().returncode, 0)

    def test_single_player_must_save_real_acknowledged_replay_and_preserve_continue(self):
        self.single_player_report()
        original = copy.deepcopy(self.rows)
        for index, field, value in ((17, "acknowledged", False), (17, "replay", False),
                                    (17, "elapsed_ticks", 180), (18, "skipped", True)):
            with self.subTest(index=index, field=field):
                self.rows = copy.deepcopy(original)
                self.rows[index]["epilogue"]["first"][field] = value
                self.assertNotEqual(self.run_check().returncode, 0)

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
        self.rows[-1]["freeplay_ticks"] = 0
        self.assertNotEqual(self.run_check().returncode, 0)

    def test_rejects_changed_victory_after_reload(self):
        self.rows[-1]["victory"] = {"tick": 120}
        self.assertNotEqual(self.run_check().returncode, 0)

    def test_rejects_replaced_inflight_pod(self):
        self.rows[5]["pod"] = 78
        self.assertNotEqual(self.run_check().returncode, 0)

    def test_rejects_flight_save_after_delivery(self):
        self.rows[4]["return_credits"] = 1
        self.assertNotEqual(self.run_check().returncode, 0)

    def test_rejects_missing_epilogue_checkpoint(self):
        (self.directory / "bitermotors-delivery-epilogue_thinking.zip").unlink()
        self.assertNotEqual(self.run_check().returncode, 0)

    def test_rejects_epilogue_contract_regressions(self):
        original = copy.deepcopy(self.rows)
        cases = [(10, "first", "phase", "reply"),
                 (11, "first", "elapsed_ticks", 180),
                 (12, "first", "elapsed_ticks", 0),
                 (12, "second", "skipped", False),
                 (13, "first", "elapsed_ticks", 179),
                 (13, "first", "acknowledged", True),
                 (15, "first", "acknowledged", False),
                 (16, "first", "victory_tick", 111),
                 (17, "outsider", "eligible", True)]
        for index, player, field, value in cases:
            with self.subTest(index=index, player=player, field=field):
                self.rows = copy.deepcopy(original)
                self.rows[index]["epilogue"][player][field] = value
                self.assertNotEqual(self.run_check().returncode, 0)

    def test_rejects_unproven_replay_force_and_late_creation(self):
        for field in ("replay_preserved_ack", "force_isolated", "late_created_once", "repeated_open_idempotent"):
            with self.subTest(field=field):
                self.rows[-1]["epilogue_evidence"][field] = False
                self.assertNotEqual(self.run_check().returncode, 0)
                self.rows[-1]["epilogue_evidence"][field] = True


if __name__ == "__main__":
    unittest.main()
