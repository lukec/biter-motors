import json
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
        benchmark.write_text("Performed 600 updates\navg: 1.500 ms, min: 0.500 ms, max: 40.000 ms\n")
        rows = ["tick,timestamp,wholeUpdate", "t0,0,200000000"]
        rows.extend(f"t{tick},{tick},{1_000_000 + tick}" for tick in range(1, 121))
        timing.write_text("\n".join(rows) + "\n")
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
                "tick": 700,
                "platform_count": 2,
                "orbital_core_count": 2,
                "active_orbital_core_count": 2,
                "progress": {"sales_offices": 1, "customer_settlements": 2, "datacenters": 1},
                "endgame": {"orbital": {"generated": 2000}},
            },
        ]
        report.write_text("\n".join(json.dumps(row) for row in snapshots) + "\n")
        return [
            "python3", str(ANALYZER), "--profile", profile, "--ticks", "600",
            "--factorio-version", "2.1.14", "--wall-seconds", "12.5",
            "--save", str(save), "--archive", str(archive),
            "--benchmark-log", str(benchmark), "--timing-log", str(timing),
            "--probe-report", str(report), "--output", str(output), "--warmup-ticks", "1",
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
                self.assertEqual(2, result["probe_snapshots"])
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
        self.assertIn("--skip-profile-requirements", text)


if __name__ == "__main__":
    unittest.main()
