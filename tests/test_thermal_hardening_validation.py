"""Fail-closed native production thermal evidence checks; no engine required."""
import copy
import json
import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / "scripts/validate-bitermotors-thermal-hardening.sh"
FIXTURE = ROOT / "scripts/fixtures/thermal-hardening-control.lua"
NAMES = ["idle_passed", "nominal_passed", "brownout_passed", "outage_passed", "blocked_passed",
         "repair_warning_passed", "repair_passed", "hot_checkpoint", "hot_reload_passed", "critical_passed",
         "burnout_passed", "burned_checkpoint", "burned_reload_passed", "shared4_passed", "shared_loss_passed",
         "shared_repair_passed", "lifecycle_passed", "array12_checkpoint", "array128_checkpoint", "hardening_passed"]


def array(count):
    return dict(count=count, supplied_power=count != 1, supplied_watts=0 if count == 1 else count * 400000000,
                min_c=97, max_c=97.2, min_products=450, min_output=1800, min_cash=1550,
                products=count * 450, output=count * 1800, work_seconds=count * 3000,
                heat_joules=count * 775000000000, elapsed_ticks=180000,
                per_core=[dict(unit=i + 1, products=450, output=1800, work_seconds=3000,
                               temperature=97 if i == 0 else 97.2) for i in range(count)])


def valid_rows():
    rows = [dict(status=name, tick=(i + 1) * 200000, assertions=(i + 1) * 100,
                 scope="production-native-thermal-hardening", limits="Single native solar; shared arrays supplied EEI",
                 max_visited=128) for i, name in enumerate(NAMES)]
    r = dict(zip(NAMES, rows))
    idle = dict(work_seconds=0, heat_joules=83333333, watts=250000000 / 30)
    r["idle_passed"].update(core=idle, solar_wings=5, native_solar_watts=300000000, supplied_power=False, players=0)
    for name, count in (("nominal_passed", 1), ("repair_passed", 1), ("shared4_passed", 4),
                        ("shared_repair_passed", 4), ("array12_checkpoint", 12), ("array128_checkpoint", 128)):
        r[name].update(array(count))
        if count == 1:
            r[name]["max_c"] = 97
    r["brownout_passed"].update(work_fraction=0.45, native_solar_watts=120000000)
    for name in ("outage_passed", "blocked_passed"):
        r[name].update(before=copy.deepcopy(idle), after=copy.deepcopy(idle), elapsed_ticks=1800)
    warning = dict(unit=6, state="warning", warning_visible=True, temperature=108, progress=0.4, heat_joules=1e12)
    r["repair_warning_passed"].update(core=copy.deepcopy(warning), custom_status=True,
        alerts=dict(players=0, count=0, message_key="bitermotors-thermal.alert-warning"))
    r["critical_passed"].update(core={**warning, "temperature": 120.2, "state": "critical"}, custom_status=True,
        alerts=dict(players=0, count=0, message_key="bitermotors-thermal.alert-critical"))
    r["repair_passed"]["alerts"] = dict(players=0, count=0, message_key="none")
    cut = r["hot_checkpoint"]["tick"] - 3600
    r["hot_checkpoint"].update(core=copy.deepcopy(warning), cut_tick=cut, cut_temperature=97, progress_per_tick=1.5 / 600)
    r["hot_reload_passed"].update(saved_tick=r["hot_checkpoint"]["tick"], before=copy.deepcopy(warning),
                                    after={**warning, "progress": warning["progress"] + 1.5 / 600},
                                    progress_per_tick=1.5 / 600, queued_ticks=1, separate_process_reload=True)
    # Use real-tick relationships for the short disconnection sequence.
    r["hot_reload_passed"]["tick"] = r["hot_checkpoint"]["tick"] + 1
    r["critical_passed"]["tick"] = cut + 6600
    death = cut + 9000
    r["burnout_passed"].update(tick=death + 60, native_deaths=1, burnouts=1, buffers=0,
                                 cut_tick=cut, death_tick=death, seconds=150,
                                 last_burnout=dict(unit=6, tick=death, temperature=130.05))
    r["burned_checkpoint"].update(output=100)
    r["burned_reload_passed"].update(saved_tick=r["burned_checkpoint"]["tick"], native_deaths=1, burnouts=1,
                                       buffers=0, separate_process_reload=True, output=100, checkpoint_output=100)
    r["shared_loss_passed"].update(before=array(4), after={**array(4), "min_c": 100, "max_c": 101}, elapsed_ticks=2400)
    r["lifecycle_passed"].update(cloning=True, force_change=True, mining=True, rebuild=True, removal=True,
                                   surface_delete=True, configuration_rebuild=False)
    r["hardening_passed"].update(native_deaths=1, player_alert_delivery=False, configuration_rebuild=False)
    return rows


def valid_perf(rows):
    reports = []
    r = {row["status"]: row for row in rows}
    for count in (12, 128):
        for _ in range(3):
            tick = r[f"array{count}_checkpoint"]["tick"] + 1
            state = array(count)
            reports.append(dict(status="benchmark_start", tick=tick, state=state, max_visited=128))
            after = {**state, "products": state["products"] + count * 9, "output": state["output"] + count * 36,
                     "min_products": 459, "min_output": 1836,
                     "per_core": [{**c, "products": c["products"] + 9, "output": c["output"] + 36,
                                   "work_seconds": c["work_seconds"] + 60} for c in state["per_core"]],
                     "work_seconds": state["work_seconds"] + count * 60, "heat_joules": state["heat_joules"] + count * 1e10}
            reports.append(dict(status="benchmark_end", tick=tick + 3599, state=after, max_visited=128))
    return reports


class ThermalHardeningValidationTests(unittest.TestCase):
    def validate(self, rows=None, perf=None, *, raw=None, log=None, missing_save=None):
        rows = valid_rows() if rows is None else rows
        perf = valid_perf(rows) if perf is None else perf
        with tempfile.TemporaryDirectory(prefix="thermal-hardening-check-") as directory:
            d = Path(directory)
            (d / "script-output").mkdir()
            (d / "saves").mkdir()
            (d / "script-output/bitermotors-thermal-hardening.jsonl").write_text(
                raw if raw is not None else "".join(json.dumps(row) + "\n" for row in rows))
            (d / "script-output/bitermotors-thermal-hardening-benchmark.jsonl").write_text(
                "".join(json.dumps(row) + "\n" for row in perf))
            for name in ("seed", "hot", "burned", "array12", "array128"):
                if name != missing_save:
                    (d / "saves" / f"bitermotors-thermal-hardening-{name}.zip").write_bytes(b"native-save-placeholder")
            for name in ("create", "hot", "burned", "hardening", "benchmark12", "benchmark128"):
                text = "Goodbye\n"
                if name.startswith("benchmark"):
                    text = "Performed 3600 updates in 1200.5 ms\n" * 3 + text
                if log and name == log[0]:
                    text = log[1]
                (d / f"{name}.log").write_text(text)
            return subprocess.run(["bash", str(RUNNER), "--check-report", str(d)], text=True,
                                  capture_output=True, timeout=10,
                                  env={**os.environ, "FACTORIO_BINARY": "/must-not-launch"})

    def test_accepts_complete_report_without_engine(self):
        result = self.validate()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Production native thermal hardening passed:", result.stdout)

    def test_real_player_alert_qualification_is_conditional_and_fail_closed(self):
        rows = valid_rows()
        by_name = {r["status"]: r for r in rows}
        by_name["idle_passed"]["players"] = 1
        for name in ("repair_warning_passed", "critical_passed", "repair_passed"):
            by_name[name]["alerts"]["players"] = 1
            by_name[name]["alerts"]["count"] = 0 if name == "repair_passed" else 1
        by_name["hardening_passed"]["player_alert_delivery"] = True
        result = self.validate(rows)
        self.assertEqual(result.returncode, 0, result.stderr)
        for name, key, value in (("repair_warning_passed", "count", 0), ("critical_passed", "message_key", "wrong"),
                                  ("repair_passed", "count", 1)):
            broken = copy.deepcopy(rows)
            next(r for r in broken if r["status"] == name)["alerts"][key] = value
            self.assertNotEqual(self.validate(broken).returncode, 0)

    def test_queued_save_progress_must_match_actual_native_ticks(self):
        rows = valid_rows()
        reload = next(r for r in rows if r["status"] == "hot_reload_passed")
        reload["tick"] += 1
        reload["queued_ticks"] = 2
        reload["after"]["progress"] += reload["progress_per_tick"]
        result = self.validate(rows)
        self.assertEqual(result.returncode, 0, result.stderr)
        for bad in (0, 15, True):
            reload["queued_ticks"] = bad
            self.assertNotEqual(self.validate(rows).returncode, 0)

    def test_rejects_missing_duplicate_reordered_and_nonadvancing_phases(self):
        rows = valid_rows()
        for changed in (rows[:-1], rows + [rows[-1]], rows[::-1]):
            self.assertNotEqual(self.validate(changed, valid_perf(rows)).returncode, 0)
        for index, key, value in ((0, "tick", 0), (0, "tick", True), (1, "tick", rows[0]["tick"]),
                                  (2, "assertions", rows[1]["assertions"]), (1, "max_visited", 129),
                                  (1, "max_visited", True), (1, "scope", "isolated-thermal-prototype")):
            changed = copy.deepcopy(rows)
            changed[index][key] = value
            with self.subTest(index=index, key=key):
                self.assertNotEqual(self.validate(changed).returncode, 0)

    def test_every_phase_requires_common_evidence(self):
        for index in range(len(NAMES)):
            for key in ("status", "tick", "assertions", "scope", "limits", "max_visited"):
                changed = valid_rows()
                del changed[index][key]
                with self.subTest(index=index, key=key):
                    self.assertNotEqual(self.validate(changed, valid_perf(valid_rows())).returncode, 0)

    def test_rejects_physics_reload_death_and_lifecycle_lies(self):
        corruptions = {
            "idle_passed": dict(supplied_power=True, solar_wings=4),
            "nominal_passed": dict(min_c=94, min_output=0, min_products=0, min_cash=0, elapsed_ticks=600),
            "brownout_passed": dict(work_fraction=1),
            "repair_passed": dict(max_c=105),
            "hot_reload_passed": dict(separate_process_reload=False, saved_tick=0),
            "burnout_passed": dict(seconds=1, native_deaths=0, buffers=1, burnouts=2, cut_tick=0),
            "burned_reload_passed": dict(output=101, buffers=1, checkpoint_output=0),
            "shared4_passed": dict(supplied_power=False, count=3),
            "array12_checkpoint": dict(min_output=0, supplied_watts=0),
            "array128_checkpoint": dict(min_products=0, min_c=float("nan"), max_c=float("inf")),
            "lifecycle_passed": dict(cloning=False, force_change=False, mining=False, rebuild=False,
                                      removal=False, surface_delete=False, configuration_rebuild=True),
            "hardening_passed": dict(player_alert_delivery=True),
        }
        for name, fields in corruptions.items():
            for key, value in fields.items():
                rows = valid_rows()
                next(r for r in rows if r["status"] == name)[key] = value
                with self.subTest(name=name, key=key):
                    self.assertNotEqual(self.validate(rows).returncode, 0)
        for name, path, value in (
            ("outage_passed", ("after", "heat_joules"), 999),
            ("blocked_passed", ("after", "work_seconds"), 1),
            ("blocked_passed", ("after", "watts"), 250000000),
            ("hot_reload_passed", ("after", "progress"), 0),
            ("hot_reload_passed", ("after", "temperature"), 15),
            ("critical_passed", ("core", "warning_visible"), False),
            ("repair_warning_passed", ("core", "state"), "normal"),
            ("burnout_passed", ("last_burnout", "temperature"), 129),
            ("shared_loss_passed", ("after", "min_c"), 97),
        ):
            rows = valid_rows()
            next(r for r in rows if r["status"] == name)[path[0]][path[1]] = value
            with self.subTest(name=name, path=path):
                self.assertNotEqual(self.validate(rows).returncode, 0)

    def test_benchmark_counts_alone_never_prove_time_or_production(self):
        for key, value in (("tick", 0), ("max_visited", 129), ("status", "benchmark_start")):
            perf = valid_perf(valid_rows())
            perf[1][key] = value
            self.assertNotEqual(self.validate(perf=perf).returncode, 0)
        for key in ("products", "output", "work_seconds", "heat_joules"):
            perf = valid_perf(valid_rows())
            perf[1]["state"][key] = perf[0]["state"][key]
            self.assertNotEqual(self.validate(perf=perf).returncode, 0)
        for key, value in (("min_output", 0), ("count", 12), ("supplied_power", False), ("max_c", 110)):
            perf = valid_perf(valid_rows())
            perf[-1]["state"][key] = value
            self.assertNotEqual(self.validate(perf=perf).returncode, 0)
        perf = valid_perf(valid_rows())
        perf[1]["tick"] = perf[0]["tick"]
        self.assertNotEqual(self.validate(perf=perf).returncode, 0)
        for changed in (perf[:-1], perf[::-1], perf + [perf[-1]]):
            self.assertNotEqual(self.validate(perf=changed).returncode, 0)

    def test_aggregate_growth_cannot_hide_one_stopped_benchmark_core(self):
        for key in ("products", "output", "work_seconds"):
            perf = valid_perf(valid_rows())
            start, end = perf[-2]["state"], perf[-1]["state"]
            gain = end["per_core"][0][key] - start["per_core"][0][key]
            end["per_core"][0][key] -= gain
            end["per_core"][1][key] += gain
            end["min_products"] = min(c["products"] for c in end["per_core"])
            end["min_output"] = min(c["output"] for c in end["per_core"])
            with self.subTest(key=key):
                result = self.validate(perf=perf)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("individual benchmark core stopped", result.stderr)

    def test_missing_saves_malformed_reports_and_fatal_exit_zero_logs(self):
        for name in ("seed", "hot", "burned", "array12", "array128"):
            self.assertNotEqual(self.validate(missing_save=name).returncode, 0)
        for raw in ("", "{", "[]\n", "null\n", "42\n"):
            self.assertNotEqual(self.validate(raw=raw).returncode, 0)
        for name in ("create", "hot", "burned", "hardening", "benchmark12", "benchmark128"):
            self.assertNotEqual(self.validate(log=(name, "non-recoverable error\nGoodbye\n")).returncode, 0)
        for text in ("Goodbye\n", "Performed 0 updates in 1200 ms\n" * 3 + "Goodbye\n",
                     "Performed 3600 updates in 0 ms\n" * 3 + "Goodbye\n"):
            self.assertNotEqual(self.validate(log=("benchmark128", text)).returncode, 0)

    def test_fixture_is_native_and_runner_is_isolated(self):
        fixture, runner = FIXTURE.read_text(), RUNNER.read_text()
        summary = fixture.split("local function summary(a)", 1)[1].split("local function stable(a)", 1)[0]
        self.assertEqual(summary.count("status()"), 1)
        self.assertNotIn("core_row(", summary)
        self.assertNotRegex(fixture, r"\.(?:temperature|crafting_progress)\s*=")
        self.assertNotIn("game.create_player", fixture)
        self.assertNotIn("script.raise_event", fixture)
        self.assertNotIn("__bitermotors_thermal_prototype__", fixture + runner)
        for marker in ("thermal_status", "on_entity_died", "warning_visible", "custom_status", "last_burnout",
                       "raise_destroyed = true", ".clone{", ".force = other", "game.server_save", "on_load",
                       "products > benchmark_start.state.products", "output > benchmark_start.state.output"):
            self.assertIn(marker, fixture)
        for marker in ('source "$repo_root/scripts/lib/bitermotors-validation.sh"', "bitermotors_stage_mod",
                       "bitermotors_check_log", "--expect-marker Goodbye", "--benchmark-ticks 3600 --benchmark-runs 3",
                       "--bind 127.0.0.1", "mktemp -d /tmp/bitermotors-thermal-hardening.XXXXXX",
                       "BITERMOTORS_THERMAL_PHASE_TIMEOUT:-600", "trap cleanup EXIT",
                       "trap 'exit 130' INT", "trap 'exit 143' TERM",
                       'cp "$save" "$run_save"', '--start-server "$run_save"',
                       "BITERMOTORS_THERMAL_RESUME_DIR", "previous_input_manifest"):
            self.assertIn(marker, runner)
        self.assertIn("a.platform.destroy(1)", fixture)
        self.assertIn('storage.lifecycle ~= 6 and storage.shared.platform.surface or nil', fixture)
        self.assertNotIn("killall", runner)
        self.assertTrue(RUNNER.stat().st_mode & 0o111)
        self.assertEqual(subprocess.run(["bash", "-n", str(RUNNER)], capture_output=True).returncode, 0)


if __name__ == "__main__":
    unittest.main()
