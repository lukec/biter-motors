import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class DeliveryValidationTests(unittest.TestCase):
    def test_native_delivery_cannot_be_replaced_with_inventory_injection(self):
        source = (ROOT / "scripts/fixtures/delivery-control.lua").read_text()
        for marker in ("on_cargo_pod_started_ascending", "on_cargo_pod_delivered_cargo",
                       "space_platform_hub_requester", "trash_not_requested = true",
                       "request(storage.pad, DATASET, 20000)", "both real platforms delivered",
                       "actual native billion-equivalent computation", "native inserters commit entire Dataset payload"):
            self.assertIn(marker, source)
        for forbidden in ("test_set_ai_token_progress", "crafting_progress =", "bonus_progress =",
                          "create_cargo_pod", "force_finish_ascending", "force_finish_descending",
                          "insert{name = DATASET", "remove{name = DATASET", "cargo_pod_destination ="):
            self.assertNotIn(forbidden, source)

    def test_final_technology_and_construction_are_native(self):
        source = (ROOT / "scripts/fixtures/delivery-control.lua").read_text()
        self.assertIn('event.by_script, false', source)
        self.assertIn('force.add_research(RESEARCH)', source)
        self.assertIn('storage.builder.set_recipe(CONTROLLER)', source)
        self.assertIn('storage.builder.products_finished, 1', source)
        self.assertIn('storage.capital.products_finished, 100', source)
        self.assertNotIn('force.technologies[RESEARCH].researched = true', source)
        self.assertIn('full delivered-payload training duration', source)
        self.assertIn('for _, loader in ipairs(storage.final_loaders) do loader.disabled_by_script = true end', source)
        self.assertIn('for _, loader in ipairs(storage.final_loaders) do loader.disabled_by_script = false end', source)
        self.assertIn('constructed controller has an unobstructed footprint', source)
        self.assertIn('sections.add_section()', source)

    def test_runner_has_exact_staging_checkpoint_log_and_duration_guards(self):
        path = ROOT / "scripts/validate-bitermotors-delivery.sh"
        source = path.read_text()
        self.assertTrue(path.stat().st_mode & 0o111)
        self.assertIn('bitermotors_stage_mod "$mods"', source)
        self.assertIn('--bind 127.0.0.1 --port "$port"', source)
        self.assertIn('kill -INT "$pid"', source)
        self.assertNotIn('killall', source)
        self.assertIn('--expect-marker Goodbye', source)
        self.assertIn('--benchmark-ticks 61 --benchmark-runs 1', source)
        self.assertIn('test -s "$reload"', source)
        self.assertIn('71_999 <= training["training_ticks"] <= 72_001', source)
        self.assertIn('reload["victory"] == training["victory"]', source)
        metadata = re.search(r"<<'EOF_INFO'\n(.*?)\nEOF_INFO", source, re.S)
        info = json.loads(metadata.group(1))
        self.assertIn('base >= 2.1.20', info['dependencies'])
        self.assertIn('space-age >= 2.1.20', info['dependencies'])


if __name__ == "__main__":
    unittest.main()
