"""Production thermal data/locale contracts, not native physics qualification."""

import configparser
from pathlib import Path
import re
import shutil
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / "mod/bitermotors_0.1.1"
DATA = (MOD / "data.lua").read_text()
LOCALE = configparser.ConfigParser(interpolation=None)
LOCALE.read(MOD / "locale/en/bitermotors.cfg")


def block(start, end):
    return DATA[DATA.index(start):DATA.index(end, DATA.index(start))]


def recipe(name):
    match = re.search(r'  recipe\("' + re.escape(name) + r'".*?\n  \)', DATA, re.S)
    if not match:
        raise AssertionError(f"Missing recipe {name}")
    return match.group()


class OrbitalThermalDataTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('lua'), 'Lua interpreter unavailable')
    def test_evaluated_prototypes_preserve_native_art_and_exact_heat_topology(self):
        source = '''
        local function copy(value)
          if type(value) ~= "table" then return value end
          local result = {}
          for k, v in pairs(value) do result[k] = copy(v) end
          return result
        end
        table.deepcopy = copy
        defines = {direction = {north = 0, east = 4, south = 8, west = 12}}
        data = {raw = {
          ["heat-interface"] = {["heat-interface"] = {type = "heat-interface", hidden = true}},
          ["solar-panel"] = {["solar-panel"] = {
            max_health = 200, picture = {layers = {{filename = "native-panel"}, {filename = "native-shadow"}}}
          }},
          ["heat-pipe"] = {["heat-pipe"] = {
            type = "heat-pipe", connection_sprites = {native = true}, heat_glow_sprites = {native = true}
          }}
        }}
        local orbital_radiator_panel_icon = {}
        local function generated_entity_picture(slug, _, scale)
          return {filename = "graphics/entity/" .. slug .. "/" .. slug .. ".png", scale = scale}
        end
        '''
        source += block('local function copied_energy_entity(', 'local function copied_electric_vehicle(')
        source += block('local function orbital_heat_buffer(', 'local high_density_space_solar_panel =')
        source += '''
        for _, spec in ipairs{
          {orbital_core_heat_buffer, "1200MJ", 1},
          {orbital_radiator_panel, "100MJ", 1},
          {orbital_heat_pipe, "20MJ", 0}
        } do
          local entity, capacity, offset = spec[1], spec[2], spec[3]
          local heat = entity.heat_buffer
          assert(heat.specific_heat == capacity and heat.max_transfer == "5GW")
          assert(heat.default_temperature == 15 and heat.min_working_temperature == 15)
          assert(heat.max_temperature == 500 and heat.min_temperature_gradient == 0.01)
          assert(#heat.connections == 4)
          local positions = {{0, -offset}, {offset, 0}, {0, offset}, {-offset, 0}}
          for index, port in ipairs(heat.connections) do
            assert(port.position[1] == positions[index][1] and port.position[2] == positions[index][2])
            assert(port.direction == (index - 1) * 4)
          end
        end
        assert(orbital_core_heat_buffer.type == "heat-interface" and orbital_core_heat_buffer.hidden)
        assert(not orbital_core_heat_buffer.minable)
        assert(orbital_radiator_panel.type == "heat-interface" and not orbital_radiator_panel.hidden)
        assert(orbital_radiator_panel.picture.filename == "graphics/entity/orbital-radiator-panel/orbital-radiator-panel.png")
        assert(orbital_radiator_panel.picture.scale == 0.2)
        assert(orbital_radiator_panel.picture ~= data.raw["solar-panel"]["solar-panel"].picture)
        assert(orbital_radiator_panel.gui_mode == "none" and not orbital_radiator_panel.production)
        assert(orbital_heat_pipe.type == "heat-pipe")
        assert(orbital_heat_pipe.connection_sprites.native and orbital_heat_pipe.heat_glow_sprites.native)
        assert(orbital_heat_pipe.heat_buffer.minimum_glow_temperature == 90)
        '''
        result = subprocess.run([shutil.which('lua'), '-'], input=source,
                                text=True, capture_output=True)
        self.assertEqual(0, result.returncode, result.stderr)

    def test_production_core_power_size_and_idle_drain_are_unchanged(self):
        core = block("local orbital_datacenter_core =", "local function orbital_heat_buffer(")
        self.assertIn('"bitermotors-orbital-datacenter-core"', core)
        self.assertIn('"250MW",\n  1.5\n)', core)
        self.assertIn('collision_box = {{-1.4, -1.4}, {1.4, 1.4}}', core)
        self.assertIn('selection_box = {{-1.5, -1.5}, {1.5, 1.5}}', core)
        self.assertNotIn('.drain =', core)

    def test_native_heat_buffers_have_shared_floor_transfer_and_edge_ports(self):
        heat = block("local function orbital_heat_buffer(", "local orbital_core_heat_buffer =")
        for field in ('max_temperature = 500', 'default_temperature = 15',
                      'min_working_temperature = 15', 'max_transfer = "5GW"',
                      'min_temperature_gradient = 0.01', 'specific_heat = capacity',
                      'local offset = (size - 1) / 2'):
            self.assertIn(field, heat)
        self.assertEqual(4, heat.count('direction = defines.direction.'))
        for position, direction in (('0, -offset', 'north'), ('offset, 0', 'east'),
                                    ('0, offset', 'south'), ('-offset, 0', 'west')):
            self.assertIn('{position = {' + position + '}, direction = defines.direction.' + direction + '}', heat)
        for capacity, size in ((1200, 3), (100, 3), (20, 1)):
            self.assertIn(f'orbital_heat_buffer("{capacity}MJ", {size})', DATA)

    def test_core_buffer_is_hidden_noncolliding_and_not_player_buildable(self):
        buffer = block("local orbital_core_heat_buffer =", "local orbital_radiator_panel =")
        for field in ('type = "heat-interface"', 'name = "bitermotors-orbital-heat-buffer"',
                      'hidden = true', '"not-selectable-in-game"',
                      '"not-blueprintable"', '"not-deconstructable"',
                      'collision_mask = {layers = {}}', 'gui_mode = "none"'):
            self.assertIn(field, buffer)
        self.assertNotIn('minable', buffer)
        self.assertIn('\n  orbital_core_heat_buffer,', DATA)

    def test_radiator_is_native_heat_interface_with_existing_real_entity_art(self):
        radiator = block("local orbital_radiator_panel =", "local orbital_heat_pipe =")
        self.assertIn('copied_energy_entity(\n  "heat-interface",\n  "heat-interface",', radiator)
        self.assertIn('"bitermotors-orbital-radiator-panel"', radiator)
        self.assertIn('hidden = false', radiator)
        self.assertIn('gui_mode = "none"', radiator)
        self.assertIn('collision_box = {{-1.4, -1.4}, {1.4, 1.4}}', radiator)
        self.assertIn('selection_box = {{-1.5, -1.5}, {1.5, 1.5}}', radiator)
        self.assertIn('picture = generated_entity_picture("orbital-radiator-panel", nil, 0.2)', radiator)
        self.assertNotIn('graphics/icons/', radiator)
        self.assertNotIn('.production =', radiator)
        self.assertIn('property = "gravity"', radiator)

    def test_pipe_clones_native_art_and_has_safe_replacement_and_glow(self):
        pipe = block("local orbital_heat_pipe =", "local high_density_space_solar_panel =")
        self.assertIn('table.deepcopy(data.raw["heat-pipe"]["heat-pipe"])', pipe)
        self.assertIn('name = "bitermotors-orbital-heat-pipe"', pipe)
        self.assertIn('result = orbital_heat_pipe.name', pipe)
        self.assertIn('fast_replaceable_group = orbital_heat_pipe.name', pipe)
        self.assertIn('next_upgrade = nil', pipe)
        self.assertIn('minimum_glow_temperature = 90', pipe)
        self.assertNotRegex(pipe, r'\.(?:picture|connection_sprites|heat_glow_sprites)\s*=')
        self.assertIn('\n  orbital_heat_pipe,', DATA)

    def test_pipe_item_recipe_and_unlock_do_not_need_nuclear(self):
        item = block('  item("bitermotors-orbital-heat-pipe"',
                     '  item("bitermotors-high-density-space-solar-panel"')
        for field in ('50, {', 'weight = 1000', 'flags = {"always-show"}',
                      'place_result = "bitermotors-orbital-heat-pipe"'):
            self.assertIn(field, item)
        pipe = recipe('bitermotors-orbital-heat-pipe')
        self.assertEqual([('copper-plate', '20'), ('steel-plate', '10'),
                          ('bitermotors-orbital-heat-pipe', '1')],
                         re.findall(r'name = "([^"]+)", amount = (\d+)', pipe))
        self.assertNotIn('enabled = true', pipe)
        self.assertIn('allow_productivity = false', pipe)
        tech = block('  tech("bitermotors-orbital-compute"',
                     '  tech("bitermotors-orbital-cluster-training"')
        self.assertIn('unlock("bitermotors-orbital-heat-pipe")', tech)
        radiator = recipe('bitermotors-orbital-radiator-panel')
        self.assertIn('name = "bitermotors-orbital-heat-pipe", amount = 20', radiator)
        self.assertNotIn('name = "heat-pipe"', radiator)

    def test_locale_covers_names_physical_cooling_thresholds_and_finite_buffer(self):
        for section in ('entity-name', 'item-name', 'recipe-name'):
            self.assertEqual('Orbital Heat Pipe', LOCALE[section]['bitermotors-orbital-heat-pipe'])
        core = LOCALE['entity-description']['bitermotors-orbital-datacenter-core']
        for text in ('Physically', '97 C', '105 C', '120 C', '130 C', '2-3 minutes', 'finite'):
            self.assertIn(text, core)
        radiator = LOCALE['entity-description']['bitermotors-orbital-radiator-panel']
        self.assertIn('sharing a platform alone does not cool', radiator)
        self.assertNotIn('one Radiator provides cooling capacity', radiator)
        # Ensure adding the runtime section did not capture following technology keys.
        self.assertIn('bitermotors-orbital-cluster-training', LOCALE['technology-description'])

    def test_runtime_locale_argument_contract(self):
        expected = {'normal': 1, 'warning': 1, 'critical': 1, 'radiator': 2,
                    'alert-warning': 2, 'alert-critical': 2, 'burnt-out': 0}
        self.assertEqual(set(expected), set(LOCALE['bitermotors-thermal']))
        for key, count in expected.items():
            with self.subTest(key=key):
                self.assertEqual([str(i) for i in range(1, count + 1)],
                                 re.findall(r'__(\d+)__', LOCALE['bitermotors-thermal'][key]))


if __name__ == '__main__':
    unittest.main()
