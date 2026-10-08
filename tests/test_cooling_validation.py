import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / "scripts/validate-bitermotors-cooling.sh"
FIXTURE = ROOT / "scripts/fixtures/cooling-control.lua"


class CoolingValidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.runner = RUNNER.read_text()
        cls.fixture = FIXTURE.read_text()

    def test_runner_uses_shared_staging_exact_archive_and_loopback_server(self):
        self.assertIn('source "$repo_root/scripts/lib/bitermotors-validation.sh"', self.runner)
        self.assertIn("bitermotors_stage_mod", self.runner)
        self.assertIn("bitermotors_check_log", self.runner)
        self.assertIn('"$repo_root/scripts/fixtures/cooling-control.lua"', self.runner)
        self.assertIn('"$repo_root/scripts/validation_support.py"', self.runner)
        self.assertIn('--bind 127.0.0.1 --port "$port"', self.runner)
        self.assertIn('kill -INT "$server_pid"', self.runner)
        self.assertNotIn("killall", self.runner)
        self.assertIn("BITERMOTORS_MOD_ARCHIVE", (ROOT / "scripts/lib/bitermotors-validation.sh").read_text())
        info = re.search(r"cat > \"\$helper/info\.json\" <<'EOF_INFO'\n(.*?)\nEOF_INFO", self.runner, re.S)
        self.assertIsNotNone(info)
        metadata = json.loads(info.group(1))
        self.assertEqual(metadata["dependencies"], [
            "base >= 2.1.20", "space-age >= 2.1.20", "bitermotors >= 0.1.1"
        ])

    def test_fixture_checks_native_scoped_capacity_failures_and_recovery(self):
        for marker in (
            'cooling allocation is grouped by surface and force',
            'new core is registered for cooling demand',
            'removed core leaves cooling demand',
            'cooled core removal promotes the next core',
            'uncooled core does not borrow cooling from the other platform',
            'deleted platform removes its cooling demand',
            'equal(cooling(force).cooled_cores, 1',
            'oldest unit-number core wins deterministic capacity',
            'undercooling interrupted genuine active progress',
            'undercooling scraps active progress to exact zero',
            'blocked output does not complete a native craft',
            'storage.second.set_recipe(nil)',
            'input(storage.second).clear()',
            '125 MW supply scraps active progress',
            'held total-power failure survives save and reload',
            'restored power and reserved Dollars restart native compute',
            'recovered native completion adds physical orbital Tokens',
            'recovery earns exactly one new native batch',
            'storage.saved_first_products + 1',
            'half-power cannot finish native training',
        ):
            self.assertIn(marker, self.fixture)
        self.assertEqual(self.fixture.count('script.on_nth_tick(30'), 1)
        self.assertNotIn('research_queue_enabled', self.fixture)
        self.assertNotRegex(self.fixture, r'\.active\s*=')
        self.assertIn('tostring(radiator.surface.index) .. ":" .. tostring(radiator.force.index)',
                      (ROOT / "mod/bitermotors_0.1.1/control.lua").read_text())

    def test_fixture_does_not_inject_progress_or_modify_recipes(self):
        self.assertNotRegex(self.fixture, r"crafting_progress\s*=")
        self.assertNotRegex(self.fixture, r"bonus_progress\s*=")
        self.assertNotIn("energy_required", self.fixture)
        self.assertNotIn("game.write_file", self.fixture)
        self.assertIn('machine.set_recipe(RECIPE)', self.fixture)

    def test_runner_requires_ordered_reports_real_files_and_advancing_reload_ticks(self):
        self.assertIn('path.is_file() and path.stat().st_size > 0', self.runner)
        self.assertIn('reload.get("tick", 0) > checkpoint["saved_tick"]', self.runner)
        self.assertIn('reload.get("recovery_ledger_delta") == reload.get("recovery_output_delta") == 10000', self.runner)
        self.assertNotIn('cooling_half_power_defect', self.runner)
        self.assertIn('"$report" --require-status "$expected" --minimum-tick 1', self.runner)

    def test_runner_is_executable(self):
        self.assertTrue(RUNNER.stat().st_mode & 0o111)


if __name__ == "__main__":
    unittest.main()
