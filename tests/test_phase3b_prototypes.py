"""Source contracts for the Model prototypes; native integration is separate."""

import configparser
import json
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / "mod/bitermotors_0.1.1"
DATA = (MOD / "data.lua").read_text()
FINAL = (MOD / "data-final-fixes.lua").read_text()
LOCALE = configparser.ConfigParser(interpolation=None, strict=False)
LOCALE.read(MOD / "locale/en/bitermotors.cfg")


def recipe_source(name):
    match = re.search(r'  recipe\("' + re.escape(name) + r'".*?\n  \)', DATA, re.S)
    if not match:
        raise AssertionError(f"Missing recipe {name}")
    return match.group()


class Phase3BPrototypeTests(unittest.TestCase):
    def test_native_recipe_safety_and_runtime_owned_unlocks(self):
        helper = DATA[DATA.index("local function recipe("):DATA.index("local function unlock(")]
        self.assertIn("enabled = false", helper)
        for name in ("bitermotors-assemble-agi-model", "bitermotors-activate-agi-model"):
            with self.subTest(recipe=name):
                block = recipe_source(name)
                for field in ("allow_productivity = false", "allow_quality = false",
                              "auto_recycle = false", "raise_on_crafted = true"):
                    self.assertIn(field, block)
                self.assertNotIn("enabled = true", block)
                self.assertNotIn(f'unlock("{name}")', DATA)

    def test_assembly_payload_category_and_normal_duration(self):
        block = recipe_source("bitermotors-assemble-agi-model")
        self.assertIn('{"bitermotors-orbital-compute"}', block)
        self.assertEqual([
            ("bitermotors-agi-training-dataset", "20000"),
            ("bitermotors-datacenter-rack", "1"),
            ("bitermotors-agi-model", "1"),
        ], re.findall(r'name = "([^"]+)", amount = (\d+)', block))
        self.assertIn('amount = 1}}, 90,', block)
        self.assertIn('property = "gravity", min = 0, max = 0', block)
        machine = DATA[DATA.index("local orbital_datacenter_core ="):DATA.index("local orbital_radiator_panel =")]
        self.assertIn('"250MW",\n  1.5\n)', machine)
        self.assertEqual(60, 90 / 1.5)

    def test_activation_returns_model_at_actual_terra_speed(self):
        block = recipe_source("bitermotors-activate-agi-model")
        self.assertIn('{"bitermotors-datacenter"}', block)
        self.assertEqual([("bitermotors-agi-model", "1")] * 2,
                         re.findall(r'name = "([^"]+)", amount = (\d+)', block))
        self.assertIn('amount = 1}}, 30,', block)
        machine = DATA[DATA.index("local terrestrial_datacenter ="):DATA.index("local bitertaxi_depot =")]
        self.assertIn('"8MW",\n  1\n)', machine)
        self.assertEqual(30, 30 / 1)

    def test_activation_conditions_derive_native_nauvis_properties(self):
        self.assertIn("data.raw.planet.nauvis.surface_properties or {}", FINAL)
        self.assertIn('ipairs({"gravity", "pressure", "magnetic-field"})', FINAL)
        self.assertIn('data.raw["surface-property"][property].default_value', FINAL)
        self.assertIn("{property = property, min = value, max = value}", FINAL)
        self.assertIn('data.raw.recipe["bitermotors-activate-agi-model"].surface_conditions = activation_conditions', FINAL)

    def test_model_remains_portable_and_filterable(self):
        block = DATA[DATA.index('  item("bitermotors-agi-model"'):]
        block = block[:block.index("\n  }),")]
        self.assertIn('"i[agi-model]", 1,', block)
        self.assertIn('flags = {"always-show"}, weight = 1000, auto_recycle = false', block)

    def test_legacy_finale_removed_from_prototypes_and_player_guidance(self):
        paths = [MOD / name for name in ("data.lua", "data-updates.lua", "data-final-fixes.lua",
                                        "locale/en/bitermotors.cfg", "README.md", "info.json")]
        for path in paths:
            with self.subTest(path=path.name):
                content = path.read_text().lower()
                for retired in ("capital-allocation", "capital allocation", "planetary-grid",
                                "planetary-energy-grid", "agi-training-run", "10 gw",
                                "10-gigawatt", "20 uninterrupted minutes", "20-minute"):
                    self.assertNotIn(retired, content)

    def test_recipe_discovery_explains_gate_return_and_optional_hyperscale(self):
        for name in ("bitermotors-assemble-agi-model", "bitermotors-activate-agi-model"):
            self.assertTrue(LOCALE["recipe-name"][name])
            self.assertIn("cargo pod", LOCALE["recipe-description"][name])
        assembly = LOCALE["recipe-description"]["bitermotors-assemble-agi-model"]
        self.assertIn("one billion earned AI Token equivalents", assembly)
        self.assertIn("Grid-scale Energy researched", assembly)
        self.assertIn("Native terrestrial and orbital compute both count; packaging does not", assembly)
        self.assertIn("Hyperscale is optional", assembly)
        self.assertNotIn("Producing it wins", LOCALE["item-description"]["bitermotors-agi-model"])
        self.assertIn("ground activation", json.loads((MOD / "info.json").read_text())["description"])


if __name__ == "__main__":
    unittest.main()
