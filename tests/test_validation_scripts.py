"""Static contract checks for validator wiring; these do not exercise Factorio."""

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"
ISOLATED_VALIDATORS = (
    "validate-bitermotors-mod.sh",
    "validate-bitermotors-fresh-start.sh",
    "validate-bitermotors-gui.sh",
    "validate-bitermotors-battery-resources.sh",
    "validate-bitermotors-bitertaxi-runtime.sh",
    "benchmark-bitermotors-scale.sh",
    "benchmark-bitermotors-playtest-save.sh",
)


class ValidationScriptContracts(unittest.TestCase):
    def read_script(self, name):
        return (SCRIPTS / name).read_text()

    def test_install_uses_resolved_version_without_archive_staging(self):
        script = self.read_script("install-bitermotors-mod.sh")
        self.assertIn('source "$repo_root/scripts/lib/bitermotors-validation.sh"', script)
        self.assertIn("bitermotors_resolve_source \"$repo_root\"", script)
        self.assertIn('"$mods_dir/bitermotors_$bitermotors_mod_version"', script)
        self.assertIn('ln -sfn "$source_dir" "$target_dir"', script)
        self.assertNotIn("bitermotors_stage_mod", script)
        self.assertNotRegex(script, r"bitermotors_0\.1\.1")

    def test_isolated_validators_use_shared_versioned_staging_and_log_gate(self):
        for name in ISOLATED_VALIDATORS:
            with self.subTest(script=name):
                script = self.read_script(name)
                self.assertIn('source "$repo_root/scripts/lib/bitermotors-validation.sh"', script)
                self.assertIn('bitermotors_resolve_source "$repo_root"', script)
                self.assertIn("bitermotors_stage_mod", script)
                self.assertIn("bitermotors_check_log", script)
                self.assertNotRegex(script, r"mod/bitermotors_0\.1\.1")

    def test_helper_folder_versions_match_declared_versions(self):
        for name, helper in (
            ("validate-bitermotors-fresh-start.sh", "bitermotors_fresh_start_test"),
            ("validate-bitermotors-gui.sh", "bitermotors_gui_smoke"),
            ("validate-bitermotors-battery-resources.sh", "bitermotors_battery_resource_test"),
        ):
            with self.subTest(script=name):
                script = self.read_script(name)
                folder = re.search(rf'helper="\$mods/{helper}_([^"/]+)"', script)
                manifest = re.search(r'"version"\s*:\s*"([^"]+)"', script)
                self.assertIsNotNone(folder)
                self.assertIsNotNone(manifest)
                self.assertEqual(folder.group(1), manifest.group(1))

    def test_gui_requires_final_completion_report(self):
        script = self.read_script("validate-bitermotors-gui.sh")
        self.assertIn("complete = true", script)
        self.assertIn('records[-1] is not checked or checked.get("complete") is not True', script)
        self.assertIn('"$tmp/bitermotors-gui-benchmark.log" --expect-updates 2', script)
        self.assertIn('report "$report" --require-status checked', script)

    def test_fresh_start_requires_report_and_rejects_failure_sentinel(self):
        script = self.read_script("validate-bitermotors-fresh-start.sh")
        self.assertIn('if not records:', script)
        self.assertIn('row.get("status") == "failed"', script)
        self.assertIn('--require-status fresh_start_complete', script)

    def test_battery_generation_requires_completion_sentinel(self):
        script = self.read_script("validate-bitermotors-battery-resources.sh")
        self.assertIn('status = "battery_resources_complete"', script)
        self.assertIn('row.get("status") != "battery_resources_complete"', script)

    def test_runtime_asserts_terminal_rcon_sentinel(self):
        script = self.read_script("validate-bitermotors-bitertaxi-runtime.sh")
        self.assertIn('"RSC_DESTROY"', script)
        self.assertIn('bitermotors_check_log "$tmp/server.log"', script)

    def test_scale_benchmark_checks_terminal_tick_and_complete_log(self):
        script = self.read_script("benchmark-bitermotors-scale.sh")
        self.assertIn('report_tick=$((benchmark_ticks - 1))', script)
        self.assertIn('status = "benchmark_complete"', script)
        self.assertIn('--require-status benchmark_complete --minimum-tick "$report_tick"', script)
        self.assertIn('--expect-updates "$benchmark_ticks" --expect-marker Goodbye', script)

    def test_archive_staging_rejects_stale_or_mismatched_package(self):
        script = (SCRIPTS / "lib" / "bitermotors-validation.sh").read_text()
        self.assertIn('--require-source-match', script)


if __name__ == "__main__":
    unittest.main()
