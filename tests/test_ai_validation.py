import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / "scripts/validate-bitermotors-ai.sh"
MOD = ROOT / "mod/bitermotors_0.1.1"


class AiValidationRunnerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.script = RUNNER.read_text()

    def test_isolated_fixture_and_exact_dependencies(self):
        self.assertIn('helper="$mods/bitermotors_ai_validation_0.1.1"', self.script)
        info = re.search(r"cat > \"\$helper/info\.json\" <<'EOF_INFO'\n(.*?)\nEOF_INFO", self.script, re.S)
        self.assertIsNotNone(info)
        metadata = json.loads(info.group(1))
        self.assertEqual(metadata["name"], "bitermotors_ai_validation")
        self.assertEqual(metadata["version"], "0.1.1")
        self.assertEqual(metadata["dependencies"], [
            "base >= 2.1.20", "space-age >= 2.1.20", "bitermotors >= 0.1.1"
        ])
        self.assertIn('cp "$repo_root/scripts/fixtures/ai-control.lua" "$helper/control.lua"', self.script)

    def test_reports_ordered_policy_accounting_reload_rows_and_bounds(self):
        self.assertIn('"ai_policy_passed", "ai_accounting_passed", "ai_reload_passed"', self.script)
        self.assertIn('all(row["assertions"] > 0 for row in rows)', self.script)
        self.assertIn('rows[1]["tick"] > 0', self.script)
        self.assertIn('rows[2]["tick"] > rows[2]["saved_tick"]', self.script)
        self.assertIn('--require-status ai_accounting_passed --minimum-tick 1', self.script)
        self.assertIn('--require-status ai_reload_passed --minimum-tick 1', self.script)
        self.assertIn('--benchmark-ticks 121 --benchmark-runs 1', self.script)
        self.assertRegex(self.script, r'for _ in \{1\.\.900\}')

    def test_native_runner_checks_logs_and_does_not_override_recipes(self):
        self.assertIn('bitermotors_check_log "$tmp/create.log" --expect-marker Goodbye', self.script)
        self.assertIn('bitermotors_check_log "$tmp/server.log" --expect-marker Goodbye', self.script)
        self.assertIn('bitermotors_check_log "$tmp/reload.log" --expect-updates 121 --expect-marker Goodbye', self.script)
        self.assertIn('trap \'kill -INT "$pid"', self.script)
        self.assertNotIn("data-final-fixes.lua", self.script)
        self.assertNotIn("energy_required", self.script)
        self.assertNotIn("ingredients", self.script)
        self.assertIn('--bind 127.0.0.1 --port "$port"', self.script)
        self.assertIn('BITERMOTORS_MOD_ARCHIVE', (ROOT / "scripts/lib/bitermotors-validation.sh").read_text())

    def test_compute_accounting_uses_native_recipe_events_not_current_recipe_samples(self):
        control = (MOD / "control.lua").read_text()
        data = (MOD / "data.lua").read_text()
        ledger = (MOD / "runtime/ai_accounting.lua").read_text()
        self.assertIn('require("runtime.ai_accounting")', control)
        self.assertIn('data.raw.recipe[recipe_name].raise_on_crafted = true', data)
        self.assertIn('prototypes.recipe[recipe_name].on_crafted_event, record_ai_compute_completion', control)
        event = control[control.index("function record_ai_compute_completion"):
                        control.index("function track_ai_efficiency_progress")]
        self.assertIn('event.recipe', event)
        self.assertIn('event.product_quality', event)
        self.assertIn('event.bonus', event)
        self.assertNotIn('get_recipe()', event)
        self.assertNotIn('safe_products_finished', event)
        cumulative = control[control.index("function cumulative_ai_tokens_generated"):
                             control.index("function update_ai_efficiency_unlocks")]
        self.assertNotIn('count_item_produced_raw', cumulative)
        self.assertNotIn('package-agi-training-dataset', ledger)

    def test_pending_bonus_is_quality_preserving_bounded_and_accounted_only_on_delivery(self):
        control = (MOD / "control.lua").read_text()
        ledger = (MOD / "runtime/ai_accounting.lua").read_text()
        tracker = control[control.index("function track_ai_efficiency_progress"):
                          control.index("function bitermotors_accelerated_start_enabled")]
        self.assertIn('math.min(32, #queue.units)', tracker)
        self.assertNotIn('registered_bitermotors_entities', tracker)
        self.assertNotIn('find_entities_filtered', tracker)
        self.assertIn('quality = quality, count = count', control)
        self.assertIn('track.pending_bonus_total = track.pending_bonus_total - discarded', ledger)
        self.assertIn('track.generated = track.generated + delivered', ledger)
        self.assertIn('discard_ai_machine_bonus(unit_number)', control)
        self.assertIn('old_bonus.force_index ~= force.index', control)

    def test_native_fixture_covers_conservation_and_real_boundaries(self):
        fixture = (ROOT / "scripts/fixtures/ai-control.lua").read_text()
        for marker in (
            "full output does not complete computation", "rare bonus retains quality",
            "statistics alone do not earn computation", "native productivity event exercised",
            "packaging does not earn another compute event", "native reload does not replay completions",
            "pending bonus survives native save/reload", "genuine native Dataset computation unlocks orbital milestone",
            'row.machine.set_recipe("bitermotors-orbital-ai-token")',
            'row.machine.destroy{raise_destroy', '"fast-inserter"',
            'game.server_save("bitermotors-ai-reload")',
        ):
            self.assertIn(marker, fixture)
        self.assertNotIn('test_set_ai_token_progress', fixture)
        self.assertNotIn('crafting_progress =', fixture)

    def test_dump_validator_covers_payload_and_filterability(self):
        validator = (ROOT / "scripts/validate-bitermotors-mod.sh").read_text()
        self.assertIn('Compressed AI payload and packaging prototypes OK.', validator)
        self.assertIn('recipe.get("raise_on_crafted") is not True', validator)
        self.assertIn('dataset["stack_size"] != 1000 or dataset["weight"] != 1000', validator)
        self.assertIn('Packaging must be ordinary, non-multiplying industry', validator)

    def test_broad_smoke_samples_profit_after_scripted_income_tick(self):
        validator = (ROOT / "scripts/validate-bitermotors-mod.sh").read_text()
        self.assertIn('script.on_nth_tick(3781, function()', validator)
        self.assertIn('if game.tick < 3781 then', validator)
        self.assertIn('sales_snapshot.get("dollars_produced") != expected_dollars', validator)
        self.assertNotIn('script.on_nth_tick(3780, function()', validator)


if __name__ == "__main__":
    unittest.main()
