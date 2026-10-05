import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ANALYZER = ROOT / "scripts" / "analyze-bitermotors-soak.py"
HARNESS = ROOT / "scripts" / "soak-bitermotors-save.sh"


class SoakHarnessTest(unittest.TestCase):
    def fixture(self, directory: Path, profile: str = "terrestrial") -> list[str]:
        save = directory / "save.zip"
        archive = directory / "bitermotors_0.1.1.zip"
        benchmark = directory / "benchmark.log"
        timing = directory / "timing.log"
        report = directory / "probe.jsonl"
        output = directory / "summary.json"
        save.write_bytes(b"save")
        archive.write_bytes(b"archive")
        benchmark.write_text("Performed 600 updates\navg: 1.500 ms, min: 0.500 ms, max: 40.000 ms\nGoodbye\n")
        rows = ["tick,timestamp,wholeUpdate", "t0,0,200000000"]
        rows.extend(f"t{tick},{tick},{1_000_000 + tick}" for tick in range(1, 121))
        timing.write_text("Performed 121 updates\navg: 1.000 ms, min: 0.500 ms, max: 200.000 ms\n" + "\n".join(rows) + "\nGoodbye\n")
        snapshots = [
            {
                "tick": 100,
                "platform_count": 2,
                "orbital_core_count": 2,
                "active_orbital_core_count": 2,
                "progress": {"sales_offices": 1, "customer_settlements": 2, "datacenters": 1},
                "endgame": {"orbital": {"generated": 1000}},
            },
            {
                "tick": 699,
                "platform_count": 2,
                "orbital_core_count": 2,
                "active_orbital_core_count": 2,
                "progress": {"sales_offices": 1, "customer_settlements": 2, "datacenters": 1},
                "endgame": {"orbital": {"generated": 2000}},
            },
        ]
        for snapshot, kind in zip(snapshots, ("initial", "final")):
            snapshot.update(kind=kind, profile=profile,
                            errors={method: False for method in ("progress", "endgame", "performance")},
                            performance={})
        snapshots[1:1] = [dict(snapshots[0], tick=tick, kind="periodic") for tick in (200, 400, 600)]
        report.write_text("\n".join(json.dumps(row) for row in snapshots) + "\n")
        timing_report = directory / "timing-probe.jsonl"
        timing_report.write_text("\n".join(json.dumps(dict(snapshots[0], kind=kind, tick=tick))
                                        for kind, tick in (("initial", 100), ("final", 220))) + "\n")
        return [
            "python3", str(ANALYZER), "--profile", profile, "--ticks", "600",
            "--factorio-version", "2.1.20", "--wall-seconds", "12.5",
            "--save", str(save), "--archive", str(archive),
            "--benchmark-log", str(benchmark), "--timing-log", str(timing),
            "--probe-report", str(report), "--output", str(output), "--warmup-ticks", "1",
            "--timing-ticks", "121", "--sample-ticks", "200",
            "--timing-probe-report", str(timing_report),
        ]

    def test_analyzer_accepts_healthy_terrestrial_and_orbital_runs(self):
        for profile in ("terrestrial", "orbital"):
            with self.subTest(profile=profile), tempfile.TemporaryDirectory() as temp:
                directory = Path(temp)
                subprocess.run(self.fixture(directory, profile), cwd=ROOT, check=True, capture_output=True)
                result = json.loads((directory / "summary.json").read_text())
                self.assertEqual("pass", result["status"])
                self.assertEqual(profile, result["profile"])
                self.assertEqual(12.5, result["wall_seconds"])
                self.assertEqual(5, result["probe_snapshots"])
                self.assertEqual(599, result["simulated_ticks"])
                self.assertEqual(600, result["benchmark"]["completed_updates"])
                self.assertEqual(120, result["timing_sample"]["samples"])
                self.assertLess(result["timing_sample"]["p99_ms"], 2)

    def test_analyzer_writes_failure_report_for_runtime_error_and_bad_orbital_fixture(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            command = self.fixture(directory, "orbital")
            (directory / "benchmark.log").write_text(
                "Error while running event bitermotors::on_tick\n"
                "avg: 20.000 ms, min: 0.500 ms, max: 300.000 ms\n"
            )
            snapshots = [
                {"tick": 1, "platform_count": 1, "orbital_core_count": 1,
                 "active_orbital_core_count": 0, "endgame": {"orbital": {"generated": 10}}},
                {"tick": 601, "platform_count": 1, "orbital_core_count": 1,
                 "active_orbital_core_count": 0, "endgame": {"orbital": {"generated": 10}}},
            ]
            (directory / "probe.jsonl").write_text(
                "\n".join(json.dumps(row) for row in snapshots) + "\n"
            )
            completed = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
            self.assertEqual(1, completed.returncode)
            result = json.loads((directory / "summary.json").read_text())
            self.assertEqual("fail", result["status"])
            self.assertTrue(any("runtime error" in failure for failure in result["failures"]))
            self.assertTrue(any("two space platforms" in failure for failure in result["failures"]))
            self.assertTrue(any("did not increase" in failure for failure in result["failures"]))

    def test_shell_harness_documents_release_profiles_and_exact_archive(self):
        text = HARNESS.read_text()
        self.assertIn("--profile terrestrial|orbital", text)
        self.assertIn("package-bitermotors.py", text)
        self.assertIn("check-bitermotors-release.py", text)
        self.assertIn("game.tick_paused = false", text)
        self.assertIn("--benchmark-verbose all", text)
        self.assertIn("bitermotors-soak.jsonl", text)
        self.assertIn("local PERIODIC_PROBE = true", text)
        # nth_tick can fire at tick 0 and before/after on_tick. It must never
        # emit at initial/final; on_tick owns terminal periodic-then-final order.
        self.assertIn("if start and event.tick > start and event.tick < start + RUN_TICKS - 1 then", text)
        self.assertIn('if PERIODIC_PROBE and event.tick % SAMPLE_TICKS == 0 then snapshot("periodic") end\n    snapshot("final")', text)
        self.assertIn('source.replace(old, "local PERIODIC_PROBE = false", 1)', text)
        self.assertIn('bitermotors_resolve_source "$repo_root"', text)
        self.assertIn('--source "$bitermotors_mod_source"', text)
        self.assertNotIn('bitermotors_stage_mod "$mods"', text)
        self.assertIn("--skip-profile-requirements", text)

    def test_orbital_probe_recognizes_all_scale_recipes_and_failure_states(self):
        text = HARNESS.read_text()
        for suffix in ("", "-cluster", "-grid-scale", "-hyperscale"):
            self.assertIn(f'["bitermotors-orbital-ai-token{suffix}"] = true', text)
        self.assertIn('if CORE_RECIPES[core.recipe or ""]', text)
        for flag in ("disabled_by_script", "reset_for_power", "reset_for_cooling"):
            self.assertIn(f'and not core.{flag}', text)

    def test_incomplete_and_malformed_evidence_always_writes_failure_summary(self):
        cases = (
            ("short updates", "benchmark.log", lambda text: text.replace("600 updates", "599 updates"), "completed 599"),
            ("no updates", "benchmark.log", lambda text: text.replace("Performed 600 updates", ""), "update count"),
            ("duplicate summaries", "benchmark.log", lambda text: text + text, "benchmark"),
            ("truncated summary", "benchmark.log", lambda text: "Performed 600 updates\navg: 1.5", "summary"),
            ("zero exit Lua error", "benchmark.log", lambda text: text + "Non-recoverable error\n", "runtime error"),
            ("zero exit generic error", "benchmark.log", lambda text: text + "0.10 Error Other.cpp:10: failed\n", "runtime error"),
            ("incomplete shutdown", "benchmark.log", lambda text: text.replace("Goodbye", ""), "completion marker"),
            ("timing Lua error", "timing.log", lambda text: text + "Error while running event probe::on_tick\n", "runtime error"),
            ("short timing count", "timing.log", lambda text: text.replace("121 updates", "120 updates"), "completed 120"),
            ("short timing data", "timing.log", lambda text: text.replace("t120,120,1000120\n", ""), "requires 121 samples"),
            ("timing gap", "timing.log", lambda text: text.replace("t30,30,1000030\n", ""), "discontinuous"),
            ("timing duplicate", "timing.log", lambda text: text.replace("t30,30,1000030", "t29,30,1000030"), "discontinuous"),
            ("timing malformed", "timing.log", lambda text: text.replace("t30,30,1000030", "t30,30,nope"), "timing samples"),
            ("timing extra", "timing.log", lambda text: text.replace("Goodbye", "t121,121,1000000\nGoodbye"), "requires 121 samples"),
            ("probe truncated", "probe.jsonl", lambda text: text[:-5], "probe evidence"),
            ("probe empty", "probe.jsonl", lambda text: "", "any snapshots"),
            ("probe unterminated", "probe.jsonl", lambda text: text.rstrip(), "unterminated"),
            ("probe NaN", "probe.jsonl", lambda text: text.replace('"tick": 400', '"tick": NaN'), "invalid JSON"),
            ("timing repeated header", "timing.log", lambda text: text + "tick,timestamp,wholeUpdate\n", "timing header"),
            ("probe non-object", "probe.jsonl", lambda text: "[]\n", "must be an object"),
        )
        for label, filename, mutate, diagnostic in cases:
            with self.subTest(case=label), tempfile.TemporaryDirectory() as temp:
                directory = Path(temp)
                command = self.fixture(directory)
                path = directory / filename
                path.write_text(mutate(path.read_text()))
                completed = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
                self.assertEqual(1, completed.returncode, completed.stderr)
                result = json.loads((directory / "summary.json").read_text())
                self.assertEqual("fail", result["status"])
                self.assertTrue(any(diagnostic in failure for failure in result["failures"]), result)

    def test_every_probe_and_global_cadence_are_required_even_without_profile_checks(self):
        def change(rows, index, **fields):
            rows[index].update(fields)
        cases = (
            ("missing final", lambda rows: rows.pop(), "final sentinel"),
            ("paused ticks", lambda rows: change(rows, -1, tick=100), "game tick span"),
            ("off by one", lambda rows: change(rows, -1, tick=700), "game tick span"),
            ("missing scheduled probe", lambda rows: rows.pop(2), "cadence"),
            ("duplicate scheduled probe", lambda rows: rows.insert(2, rows[1]), "cadence"),
            ("relative instead of global cadence", lambda rows: change(rows, 1, tick=300), "cadence"),
            ("intermediate remote failure", lambda rows: change(rows, 2, errors={"progress": "broken"}), "could not read progress"),
            ("missing error evidence", lambda rows: rows[2].pop("errors"), "malformed errors"),
            ("missing error fields", lambda rows: change(rows, 2, errors={}), "malformed errors fields"),
            ("missing status", lambda rows: rows[2].pop("performance"), "missing performance"),
            ("wrong profile", lambda rows: change(rows, 2, profile="orbital"), "incorrect profile"),
            ("invalid tick", lambda rows: change(rows, 2, tick="400"), "invalid game tick"),
            ("missing initial", lambda rows: rows.pop(0), "initial probe"),
        )
        for label, mutate, diagnostic in cases:
            with self.subTest(case=label), tempfile.TemporaryDirectory() as temp:
                directory = Path(temp)
                command = self.fixture(directory) + ["--skip-profile-requirements"]
                path = directory / "probe.jsonl"
                rows = [json.loads(line) for line in path.read_text().splitlines()]
                mutate(rows)
                path.write_text("\n".join(json.dumps(row) for row in rows) + "\n")
                completed = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
                self.assertEqual(1, completed.returncode, completed.stderr)
                result = json.loads((directory / "summary.json").read_text())
                self.assertTrue(any(diagnostic in failure for failure in result["failures"]), result)

    def test_timing_tick_span_and_final_sentinel_are_independent(self):
        for field, value, diagnostic in (("tick", 219, "game tick span"),
                                          ("kind", "periodic", "final sentinel"),
                                          ("errors", {"performance": "failed"}, "could not read performance")):
            with self.subTest(field=field), tempfile.TemporaryDirectory() as temp:
                directory = Path(temp)
                command = self.fixture(directory)
                path = directory / "timing-probe.jsonl"
                rows = [json.loads(line) for line in path.read_text().splitlines()]
                rows[-1][field] = value
                path.write_text("\n".join(json.dumps(row) for row in rows) + "\n")
                completed = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
                self.assertEqual(1, completed.returncode)
                result = json.loads((directory / "summary.json").read_text())
                self.assertTrue(any("timing:" in failure and diagnostic in failure for failure in result["failures"]), result)

    def test_missing_files_and_nonzero_exit_write_failure_summary(self):
        for filename in ("benchmark.log", "timing.log", "probe.jsonl", "timing-probe.jsonl", "archive", "save.zip"):
            with self.subTest(filename=filename), tempfile.TemporaryDirectory() as temp:
                directory = Path(temp)
                command = self.fixture(directory) + ["--benchmark-exit-code", "7"]
                path = directory / ("bitermotors_0.1.1.zip" if filename == "archive" else filename)
                path.unlink()
                completed = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
                self.assertEqual(1, completed.returncode)
                result = json.loads((directory / "summary.json").read_text())
                self.assertEqual("fail", result["status"])
                self.assertTrue(any("status 7" in failure for failure in result["failures"]))

    def test_global_cadence_excludes_initial_and_includes_terminal_boundary(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            command = self.fixture(directory)
            path = directory / "probe.jsonl"
            rows = [json.loads(line) for line in path.read_text().splitlines()]
            # Start itself is a global nth_tick boundary; only the initial probe
            # belongs there. The terminal boundary has both periodic and final.
            rows[0]["tick"] = 0
            for row, tick in zip(rows[1:-1], (200, 400, 600)):
                row["tick"] = tick
            rows[-1]["tick"] = 600
            path.write_text("\n".join(json.dumps(row) for row in rows) + "\n")
            command[command.index("--ticks") + 1] = "601"
            benchmark = directory / "benchmark.log"
            benchmark.write_text(benchmark.read_text().replace("600 updates", "601 updates"))
            completed = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
            self.assertEqual(0, completed.returncode, completed.stderr)

    def test_tick_zero_periodic_is_rejected_and_600_updates_span_599(self):
        for extra_zero_probe in (False, True):
            with self.subTest(extra_zero_probe=extra_zero_probe), tempfile.TemporaryDirectory() as temp:
                directory = Path(temp)
                command = self.fixture(directory)
                path = directory / "probe.jsonl"
                rows = [json.loads(line) for line in path.read_text().splitlines()]
                rows[0]["tick"] = 0
                rows[-1]["tick"] = 599
                rows.pop(-2)  # No periodic tick 600 in a 0..599 window.
                if extra_zero_probe:
                    rows.insert(1, dict(rows[0], kind="periodic"))
                path.write_text("\n".join(json.dumps(row) for row in rows) + "\n")
                completed = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
                self.assertEqual(1 if extra_zero_probe else 0, completed.returncode, completed.stderr)
                result = json.loads((directory / "summary.json").read_text())
                if extra_zero_probe:
                    self.assertTrue(any("cadence" in failure for failure in result["failures"]))
                else:
                    self.assertEqual(599, result["observed_game_tick_span"])

    def test_missing_timing_probe_argument_and_invalid_threshold_fail_closed(self):
        for missing_report in (True, False):
            with self.subTest(missing_report=missing_report), tempfile.TemporaryDirectory() as temp:
                directory = Path(temp)
                command = self.fixture(directory)
                if missing_report:
                    index = command.index("--timing-probe-report")
                    del command[index:index + 2]
                else:
                    command += ["--max-p99-ms", "nan"]
                completed = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
                self.assertEqual(1, completed.returncode)
                result = json.loads((directory / "summary.json").read_text())
                diagnostic = "missing timing probe" if missing_report else "invalid p99 threshold"
                self.assertTrue(any(diagnostic in failure for failure in result["failures"]), result)

    def test_mocked_harness_writes_failure_summary_without_invoking_engine(self):
        for setup_failure in (False, True):
            with self.subTest(setup_failure=setup_failure), tempfile.TemporaryDirectory() as temp:
                directory = Path(temp)
                scripts = directory / "scripts"
                (scripts / "lib").mkdir(parents=True)
                harness = scripts / HARNESS.name
                harness.write_text(HARNESS.read_text())
                (scripts / ANALYZER.name).write_text(ANALYZER.read_text())
                # The common-helper API is stubbed: subset tests do not require
                # that workstream, a licensed engine, or any game operation.
                (scripts / "lib" / "bitermotors-validation.sh").write_text(
                    'bitermotors_resolve_source() { bitermotors_mod_source="$1/mod/bitermotors_9.8.7"; '
                    'bitermotors_mod_version=9.8.7; }\n'
                )
                (scripts / "package-bitermotors.py").write_text(
                    'import pathlib, sys\n'
                    'assert sys.argv[-2:] == ["--version", "9.8.7"]\n'
                    'path = pathlib.Path(sys.argv[2]) / "bitermotors_9.8.7.zip"\n'
                    'path.write_bytes(b"archive")\nprint(path)\n'
                )
                (scripts / "check-bitermotors-release.py").write_text(
                    'import sys\nassert sys.argv[-1].endswith("mod/bitermotors_9.8.7")\n'
                    + ('raise SystemExit(9)\n' if setup_failure else '')
                )
                fake = directory / "fake-factorio"
                fake.write_text(
                    '#!/bin/sh\nif [ "$1" = --version ]; then echo "Version: 2.1.20"; exit 0; fi\n'
                    'echo "Error while running event bitermotors::on_tick"\nexit 0\n'
                )
                fake.chmod(0o755)
                # Keep the harness's isolated scratch runtime inside this test.
                mktemp = directory / "mktemp"
                mktemp.write_text('#!/bin/sh\nexec /usr/bin/mktemp -d "$MOCK_RUNTIME/runtime.XXXXXX"\n')
                mktemp.chmod(0o755)
                save = directory / "save.zip"
                save.write_bytes(b"save")
                output = directory / "output"
                completed = subprocess.run(
                    ["bash", str(harness), "--profile", "terrestrial", "--save", str(save),
                     "--ticks", "600", "--timing-ticks", "121", "--warmup-ticks", "1",
                     "--output-dir", str(output)],
                    env=dict(os.environ, FACTORIO_BINARY=str(fake), MOCK_RUNTIME=str(directory),
                             PATH=str(directory) + os.pathsep + os.environ["PATH"]),
                    capture_output=True, text=True,
                )
                self.assertNotEqual(0, completed.returncode, completed.stdout)
                result = json.loads((output / "summary.json").read_text())
                self.assertEqual("fail", result["status"])
                diagnostic = "aborted" if setup_failure else "runtime error"
                self.assertTrue(any(diagnostic in failure for failure in result["failures"]), result)


if __name__ == "__main__":
    unittest.main()
