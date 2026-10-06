import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / "scripts/validate-bitermotors-finale.sh"
MOD = ROOT / "mod/bitermotors_0.1.1"


class FinaleValidationRunnerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.script = RUNNER.read_text()

    def test_native_fixture_staging_and_exact_dependencies(self):
        self.assertIn('helper="$mods/bitermotors_finale_validation_0.1.1"', self.script)
        self.assertIn('--map-gen-seed 1062026', self.script)
        metadata = re.search(r"cat > \"\$helper/info\.json\" <<'EOF_INFO'\n(.*?)\nEOF_INFO", self.script, re.S)
        self.assertIsNotNone(metadata)
        info = json.loads(metadata.group(1))
        self.assertEqual(info["name"], "bitermotors_finale_validation")
        self.assertEqual(info["version"], "0.1.1")
        self.assertEqual(info["dependencies"], [
            "base >= 2.1.20", "space-age >= 2.1.20", "bitermotors >= 0.1.1"
        ])
        self.assertIn('cp "$fixture" "$helper/control.lua"', self.script)

    def test_checkpoint_training_and_reload_are_ordered_and_bounded(self):
        self.assertIn('bitermotors-finale-midrun.zip', self.script)
        self.assertIn('bitermotors-finale-completed.zip', self.script)
        self.assertRegex(self.script, r'for _ in \{1\.\.1200\}')
        self.assertIn('sleep 0.2', self.script)
        self.assertIn('--benchmark-ticks 61 --benchmark-runs 1', self.script)
        self.assertIn('start_server "$save"', self.script)
        self.assertIn('wait_for_phase "$midrun" finale_checkpoint', self.script)
        self.assertIn('start_server "$midrun"', self.script)
        self.assertIn('wait_for_phase "$completed" finale_training_passed', self.script)
        self.assertIn('finale_policy_passed", "finale_checkpoint", "finale_training_passed", "finale_reload_passed', self.script)

    def test_runner_checks_logs_own_pid_and_finale_report_contract(self):
        self.assertIn('--bind 127.0.0.1 --port "$port"', self.script)
        self.assertIn('kill -INT "$server_pid"', self.script)
        self.assertNotIn('killall', self.script)
        self.assertIn('autosave_interval=0', self.script)
        self.assertIn('bitermotors_check_log "$log" --expect-marker Goodbye', self.script)
        self.assertIn('0 < checkpoint["progress"] < 1', self.script)
        self.assertIn('training.get("training_seconds") == 1200', self.script)
        self.assertIn('training.get("required_power_watts") == 10_000_000_000', self.script)
        self.assertIn('len(cases) >= 8', self.script)
        self.assertIn('71999 <= case.get("duration_ticks", 0) <= 72001', self.script)
        self.assertIn('case.get("total_joules", 0) - 12_000_000_000_000', self.script)
        self.assertIn('reload["tick"] > reload["saved_tick"]', self.script)
        self.assertIn('reload.get("victory") == victory', self.script)
        self.assertNotIn('data-final-fixes.lua', self.script)
        self.assertNotIn('energy_required', self.script)
        self.assertNotIn('ingredients', self.script)

    def test_script_is_executable_and_fixture_is_required_before_engine_run(self):
        self.assertTrue(RUNNER.stat().st_mode & 0o111)
        self.assertLess(self.script.index('if [[ ! -f "$fixture" ]]'), self.script.index('run_engine "$tmp/create.log"'))

    def test_final_controller_rejects_quality_and_effect_bypasses(self):
        data = (MOD / "data.lua").read_text()
        controller = data[data.index("local planetary_grid_controller = copied_assembler("):
                          data.index("local espider_legs")]
        self.assertIn('planetary_grid_controller.allowed_effects = {}', controller)
        self.assertIn('planetary_grid_controller.energy_source.drain = "0W"', controller)
        self.assertIn('planetary_grid_controller.crafting_speed_quality_multiplier[quality_name] = 1', controller)
        for field in ("uses_module_effects", "uses_beacon_effects", "uses_surface_effects", "uses_local_effects"):
            self.assertIn(f'{field} = false', controller)

    def test_victory_is_native_earned_completion_not_output_presence(self):
        control = (MOD / "control.lua").read_text()
        handler = control[control.index('function record_agi_training_completion(event)'):
                          control.index('function clear_office_buyer_reservation')]
        for marker in ('event.recipe ~= AGI_TRAINING_RECIPE_NAME', 'event.bonus',
                       'controller.name ~= GRID_CONTROLLER_NAME',
                       'cumulative_ai_tokens_generated(controller.force) < AGI_TOKEN_GATE',
                       'bitermotors_compute_power_failures()[controller.unit_number]', 'event.product_quality'):
            self.assertIn(marker, handler)
        self.assertNotIn('agi_training_power_failed(controller)', handler)
        self.assertNotIn('get_item_count', handler)
        self.assertNotIn('controller_has_agi_model', control)
        self.assertNotIn('finish_completed_agi_training', control)
        self.assertIn('prototypes.recipe[AGI_TRAINING_RECIPE_NAME].on_crafted_event', control)
        self.assertIn('source = "native-training-completion"', control)

    def test_final_power_monitor_is_independent_bounded_and_retryable(self):
        control = (MOD / "control.lua").read_text()
        monitor = control[control.index('function reset_underpowered_compute_progress()'):
                          control.index('function sync_agi_training_unlock')]
        self.assertIn('reset_compute_queue_progress(agi_training_power_queue())', monitor)
        self.assertIn('reset_compute_queue_progress(bitermotors_compute_queue())', monitor)
        self.assertIn('local budget = math.min(32, #queue.units)', control)
        self.assertIn('AGI_MINIMUM_BUFFER_FRACTION = 0.9', control)
        self.assertIn('AGI_RESET_PROGRESS = 1e-12', control)
        self.assertIn('entity.name == GRID_CONTROLLER_NAME and AGI_RESET_PROGRESS or 0', control)
        self.assertIn('retry_tick = entity.name == GRID_CONTROLLER_NAME and game.tick + 60', control)
        self.assertIn('agi-power-reset', control)

    def test_fixture_earns_gate_and_rehearses_complete_native_runs(self):
        fixture = (ROOT / "scripts/fixtures/finale-control.lua").read_text()
        for marker in ('native midrun progress survives reload', 'same-event immediate extraction',
                       'rare removal', 'half-power supply scraps training',
                       'total loss retains effectively zero progress', 'recovered run used retained inputs',
                       'physical final payload has genuinely been computed',
                       'beacon actually boosts witness', 'beacon actually reduces witness power',
                       'native victory sets game finished', 'victory survives native reload'):
            self.assertIn(marker, fixture)
        self.assertIn('failed-power hold survives reload', fixture)
        self.assertIn('failed-state committed inputs survive reload', fixture)
        self.assertIn('native batch actually restarts', fixture)
        self.assertIn('retry needs no replacement payload', fixture)
        self.assertNotIn('test_set_ai_token_progress', fixture)
        self.assertNotIn('crafting_progress =', fixture)
        self.assertNotIn('bonus_progress =', fixture)


if __name__ == "__main__":
    unittest.main()
