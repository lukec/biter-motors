import copy
import json
import os
import unittest

from scripts.check_progression import ROOT, audit, bm, bootstrap


def fixture():
    return {
        "character": {"character": {"type": "character", "crafting_categories": ["crafting"]}},
        "item": {"assembler": {"place_result": "assembler"}, "lab": {"place_result": "lab"}},
        "assembling-machine": {"assembler": {"type": "assembling-machine", "crafting_categories": ["special"]}},
        "lab": {"lab": {"type": "lab", "inputs": ["science"]}},
        "recipe": {
            "science": {"ingredients": [{"name": "ore"}], "results": [{"name": "science"}]},
            "product": {"enabled": False, "categories": ["special"], "ingredients": [{"name": "ore"}], "results": [{"name": "product"}]},
        },
        "technology": {"project": {"unit": {"ingredients": [["science", 1]]}, "effects": [{"type": "unlock-recipe", "recipe": "product"}]}},
    }


class FixedPointTests(unittest.TestCase):
    def run_fixture(self, raw, stock=("ore", "assembler", "lab")):
        return audit(raw, start_items=stock, runtime=False)

    def test_science_machine_chain(self):
        result = self.run_fixture(fixture())
        self.assertIn("product", result["reachable_recipes"])
        self.assertIn("project", result["reachable_technologies"])

    def test_circular_science(self):
        raw = fixture()
        raw["recipe"]["science"]["enabled"] = False
        raw["technology"]["project"]["effects"].append({"type": "unlock-recipe", "recipe": "science"})
        result = self.run_fixture(raw)
        self.assertNotIn("project", result["reachable_technologies"])
        self.assertNotIn("product", result["reachable_recipes"])

    def test_missing_machine(self):
        result = self.run_fixture(fixture(), ("ore", "lab"))
        self.assertNotIn("product", result["reachable_recipes"])

    def test_orbital_machine_requires_a_reachable_platform(self):
        raw = fixture()
        raw["surface-property"] = {"gravity": {"default_value": 10}}
        raw["assembling-machine"]["assembler"]["surface_conditions"] = [{"property": "gravity", "max": 0}]
        self.assertNotIn("product", self.run_fixture(raw)["reachable_recipes"])
        result = audit(raw, start_techs=("space-platform",), start_items=("ore", "assembler", "lab"), runtime=False)
        self.assertNotIn("product", result["reachable_recipes"])
        raw["technology"]["space-platform"] = {"enabled": False}
        result = audit(raw, start_techs=("space-platform",), start_items=("ore", "assembler", "lab"), runtime=False)
        self.assertIn("product", result["reachable_recipes"])

    def test_missing_input(self):
        raw = fixture()
        raw["recipe"]["product"]["ingredients"].append({"name": "unobtainium"})
        self.assertNotIn("product", self.run_fixture(raw)["reachable_recipes"])

    def test_lab_must_accept_all_science(self):
        raw = fixture()
        raw["lab"]["lab"]["inputs"] = []
        self.assertNotIn("project", self.run_fixture(raw)["reachable_technologies"])

    def test_smoke_helper_cannot_supply_input(self):
        raw = fixture()
        raw["recipe"]["bitermotors-smoke-cheat"] = {"results": [{"name": "ore"}]}
        self.assertNotIn("science", self.run_fixture(raw, ("lab", "assembler"))["reachable_recipes"])


@unittest.skipUnless(os.environ.get("BITERMOTORS_PROTOTYPE_DUMP"), "set BITERMOTORS_PROTOTYPE_DUMP for full native dump tests")
class NativeDumpTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with open(os.environ["BITERMOTORS_PROTOTYPE_DUMP"]) as stream:
            cls.raw = json.load(stream)
        cls.techs, cls.stock = bootstrap((ROOT / "mod/bitermotors_0.1.1/control.lua").read_text())

    def check(self, raw):
        return audit(raw, self.techs, self.stock)

    def test_mandatory_activation_path(self):
        result = self.check(self.raw)
        self.assertTrue(result["ok"], result["missing"])
        self.assertIn("model-returned", result["manual_runtime_gates"])
        for science in ("automation", "logistic", "chemical", "production", "utility"):
            self.assertIn(science + "-science-pack", result["reachable_items"])

    def test_removed_planet_ingredient_blocks_activation(self):
        raw = copy.deepcopy(self.raw)
        raw["recipe"][bm("orbital-datacenter-core")]["ingredients"].append({"name": "tungsten-plate", "type": "item", "amount": 1})
        result = self.check(raw)
        self.assertFalse(result["ok"])
        self.assertIn(bm("activate-agi-model"), result["missing"])

    def test_missing_native_machine_blocks_activation(self):
        raw = copy.deepcopy(self.raw)
        del raw["assembling-machine"][bm("terrestrial-datacenter")]
        self.assertFalse(self.check(raw)["ok"])

    def test_native_circular_science_blocks_activation(self):
        raw = copy.deepcopy(self.raw)
        raw["recipe"]["chemical-science-pack"]["ingredients"].append({"name": bm("agi-model"), "type": "item", "amount": 1})
        result = self.check(raw)
        self.assertFalse(result["ok"])
        self.assertIn(bm("activate-agi-model"), result["missing"])


if __name__ == "__main__":
    unittest.main()
