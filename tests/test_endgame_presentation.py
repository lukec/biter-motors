import shutil
import subprocess
import unittest
from pathlib import Path

try:
    from lupa import LuaRuntime
except ImportError:
    LuaRuntime = None


ROOT = Path(__file__).resolve().parents[1]
MODULE = ROOT / "mod/bitermotors_0.1.1/runtime/endgame_presentation.lua"
LUA = shutil.which("lua") or shutil.which("lua5.4") or shutil.which("luajit")


class EndgamePresentationContractTest(unittest.TestCase):
    def test_inspector_guards_and_layout(self):
        control = (ROOT / "mod/bitermotors_0.1.1/control.lua").read_text()
        inspector = control.split("local function show_manufacturer_info_panel(player, entity)", 1)[1]
        inspector = inspector.split("local function is_customer_settlement_entity", 1)[0]
        self.assertIn('name = "bitermotors_manufacturer_content"', inspector)
        self.assertIn('label.style.single_line = false', control)
        self.assertIn('if not prerequisite.researched then logistic_system_ready = false end', control)
        self.assertIn('panel.style.maximal_height = math.max(160, math.min(780,', inspector)
        self.assertIn('panel.horizontal_scroll_policy = "never"', inspector)
        self.assertIn('elseif compute_recipe then', inspector)
        self.assertNotIn('recipe and recipe.energy or 30', inspector)
        self.assertIn('%.2f-second cycle at current crafting speed', inspector)
        self.assertIn('if agi_training_status(entity.force).unlocked then', inspector)
        committed = inspector.index('elseif final_recipe and (entity.crafting_progress or 0) > 0 then')
        missing = inspector.index('elseif missing_name then')
        self.assertLess(committed, missing)
        self.assertIn('do not reload inputs.', inspector[committed:missing])
        locale = (ROOT / "mod/bitermotors_0.1.1/locale/en/bitermotors.cfg").read_text()
        self.assertIn('bitermotors-orbital-ai-dataset-grid-scale=Grid-scale Training Datasets', locale)

    def test_module_is_bounded_and_independent(self):
        source = MODULE.read_text()
        for dependency in ("game.", "storage.", "script.", "rendering.", "require(",
                           "find_entities", "get_inventory", "pairs(", "ipairs("):
            self.assertNotIn(dependency, source)
        self.assertNotRegex(source, r"(?m)^\s*(?:for|while)\s+")
        self.assertIn("function EndgamePresentation.describe(agi)", source)
        self.assertTrue(source.rstrip().endswith("return EndgamePresentation"))

    def test_native_icons_exist(self):
        data = (ROOT / "mod/bitermotors_0.1.1/data.lua").read_text()
        for name in ("agi-model", "agi-training-dataset", "orbital-datacenter-core",
                     "terrestrial-datacenter"):
            self.assertIn('"item/bitermotors-' + name + '"', MODULE.read_text())
            self.assertIn('"bitermotors-' + name + '"', data)


@unittest.skipUnless(LuaRuntime or LUA, "Pure execution requires Lua or optional lupa; native fixture runs separately")
class EndgamePresentationCasesTest(unittest.TestCase):
    def lua(self, assertions):
        source = "local P = dofile(" + repr(str(MODULE)) + ")\n" + assertions
        if LuaRuntime:
            LuaRuntime().execute(source)
        else:
            result = subprocess.run([LUA, "-"], input=source, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_precedence_and_removed_machines(self):
        self.lua("""
        assert(P.describe{completed=true, return_credits=1}.stage_key == 'complete')
        assert(P.describe{completed=true}.progress == 1)
        assert(P.describe{return_credits=1, models_in_transit=1, assembly_credits=1}.stage_key == 'activation')
        assert(P.describe{return_credits=1}.status == 'No machine')
        assert(P.describe{models_in_transit=1, assembly_credits=1}.status == 'In flight')
        local dispatch = P.describe{assembly_credits=1}
        assert(dispatch.status == 'Awaiting hub dispatch')
        assert(dispatch.detail:find('actual Model', 1, true))
        assert(dispatch.detail:find('platform hub', 1, true))
        assert(dispatch.detail:find('Nauvis Cargo Landing Pad', 1, true))
        local lost = P.describe{unlocked=true, models_assembled=1, models_returned=1}
        assert(lost.stage_key == 'assembly')
        assert(lost.objective:find('Rebuild the lost', 1, true))
        assert(P.describe{models_assembled=1}.stage_key == 'assembly')
        assert(P.describe{models_activated=1}.stage_key ~= 'complete')
        """)

    def test_gui_payload_tooltips_and_narrow_metrics(self):
        self.lua("""
        package.loaded['runtime.endgame_presentation'] = P
        package.loaded['runtime.terminal_epilogue'] = {open_button='terminal'}
        helpers = {table_to_json=function() return 'fixture' end}
        local G = dofile(""" + repr(str(MODULE.with_name("endgame_gui.lua"))) + """)
        local function element(spec)
          local e = {style={}, tags={}, caption=spec and spec.caption}
          e.add = function(child)
            local c = element(child)
            if child.name then e[child.name] = c end
            return c
          end
          e.clear = function() end
          return e
        end
        for _, state in ipairs{'needs_inputs', 'working'} do
          local panel = element()
          local agi = {unlocked=true, models_assembled=0, models_returned=0,
            required_ai_tokens=1000000000, cumulative_ai_tokens=1000000000,
            assembly={state=state, committed=state=='working', progress=0.5,
              datasets=123, racks=1}}
          G.render({force={index=1}, display_scale=1.5,
            display_resolution={width=640,height=480}}, panel, agi)
          local content = panel.bitermotors_progress_content
          local payload = content.bitermotors_ending_payload
          assert(payload.tooltip == P.describe(agi).payload_tooltip)
          assert(payload.style.maximal_width == panel.style.width - 56)
          local row = content.bitermotors_earned_compute
          assert(row.bitermotors_earned_compute_value.style.width > 0)
          assert(content.horizontal_scroll_policy == 'never')
          assert(content.style.maximal_height == 170)
        end
        """)

    def test_inspector_rates_follow_recipe_and_crafting_speed(self):
        control = (ROOT / "mod/bitermotors_0.1.1/control.lua").read_text()
        block = control.split('elseif compute_recipe then', 1)[1]
        block = block.split('      add_station_info_label(panel, status.next_threshold', 1)[0]
        self.lua("""
        local function inspect(seconds, speed, dollars, output, compact)
          local lines = {}
          local panel = {}
          local entity = {crafting_speed=speed,
            get_recipe=function() return {energy=seconds, ingredients={{amount=dollars}}} end}
          local selected_output, datasets = output, compact
          local AiAccounting = {dataset_tokens=50000}
          local function add_station_info_label(_, line) lines[#lines+1] = line end
          if true then
        """ + block + """
          return lines
        end
        local entry = inspect(50, 1.5, 5, 50000, true)
        assert(entry[1]:find('5 Dollars per 33.33-second cycle', 1, true))
        local grid = inspect(10, 1.5, 1, 100000, true)
        assert(grid[1]:find('1 Dollars per 6.67-second cycle', 1, true))
        assert(grid[2]:find('900000/minute', 1, true))
        assert(grid[3]:find('2 Training Datasets/cycle', 1, true))
        local faster = inspect(10, 3, 1, 100000, false)
        assert(faster[1]:find('3.33-second cycle', 1, true))
        assert(#faster == 2)
        """)

    def test_compute_gate_hides_model_and_separates_physical_stock(self):
        self.lua("""
        local v = P.describe{cumulative_ai_tokens=50, required_ai_tokens=100,
          assembly={datasets=20000, racks=1}}
        assert(v.stage_key == 'compute' and v.progress == 0.5)
        assert(v.payload_value == nil)
        for _, field in ipairs{'stage','objective','detail','status','icon'} do
          assert(not v[field]:find('Model', 1, true))
        end
        assert(v.detail:find('Packaging does not earn compute again', 1, true))
        assert(v.detail:find('Hyperscale research is optional', 1, true))
        assert(v.detail:find('Grid-scale Energy', 1, true))
        assert(P.describe{cumulative_ai_tokens=100, required_ai_tokens=100}.status == 'Awaiting research')
        assert(P.describe{cumulative_ai_tokens=100, required_ai_tokens=100}.objective ==
          'Complete Grid-scale Energy research.')
        assert(P.describe{unlocked=true, assembly={datasets=0}}.stage_key == 'assembly')
        local researched = P.describe{grid_scale_researched=true,
          cumulative_ai_tokens=50, required_ai_tokens=100}
        assert(researched.stage_key == 'compute' and researched.progress == 0.5)
        assert(researched.status == 'Earning compute')
        assert(researched.objective:find('Run compute recipes', 1, true))
        assert(not researched.detail:find('Complete Grid-scale', 1, true))
        assert(not researched.objective:find('research', 1, true))
        local gate = P.describe{grid_scale_researched=true,
          cumulative_ai_tokens=100, required_ai_tokens=100}
        assert(gate.status == 'Compute gate met')
        assert(not gate.detail:find('Complete Grid-scale', 1, true))
        """)

    def test_committed_payload_and_banked_power_cooling_states(self):
        self.lua("""
        for _, state in ipairs{'needs_inputs','working','no_power','low_power','cooling','full_output'} do
          local input = {unlocked=true, assembly={state=state, selected=true, progress=0.42,
            datasets=0, racks=0}}
          local v = P.describe(input)
          assert(v.payload_value == 'Payload committed')
          assert(v.progress == 0.42 and v.detail:find('42% banked', 1, true))
          assert(not v.detail:find('Load 20000', 1, true))
          assert(v.color ~= 'bad')
          assert(input.assembly.progress == 0.42 and input.assembly.datasets == 0)
          if state == 'full_output' then assert(v.detail:find('Remove the Model', 1, true)) end
        end
        assert(P.describe{unlocked=true, assembly={committed=true}}.payload_value == 'Payload committed')
        """)

    def test_machine_actions_and_colors(self):
        self.lua("""
        local expected = {no_machine='bad', select_recipe='warning', needs_inputs='warning',
          working='good', no_power='warning', low_power='warning', cooling='warning', full_output='warning'}
        for state, color in pairs(expected) do
          for _, activation in ipairs{false,true} do
            local v = P.describe{unlocked=true, return_credits=activation and 1 or 0,
              assembly={state=state}, activation={state=state}}
            assert(v.color == color, state)
            assert(v.detail ~= '' and v.objective ~= '')
            assert(v.stage_key == (activation and 'activation' or 'assembly'))
          end
        end
        local a = P.describe{unlocked=true, assembly={state='needs_inputs', datasets=123, racks=0}}
        assert(a.payload_value == '123 / 20000 Datasets; 0 / 1 Rack')
        assert(a.detail:find('minimum payload to 1', 1, true))
        assert(a.detail:find('1 minute', 1, true))
        assert(P.describe{return_credits=1}.detail:find('30 seconds at 8 MW', 1, true))
        """)

    def test_result_is_plain_fresh_and_progress_is_clamped(self):
        self.lua("""
        local input = {unlocked=true, assembly={state='working', selected=true, progress=2,
          surface={}, unit_number=1, quality='legendary'}}
        local v = P.describe(input)
        assert(v.progress == 1)
        local allowed = {stage_key=true,stage=true,objective=true,detail=true,icon=true,
          status=true,color=true,progress=true,payload_value=true,payload_tooltip=true}
        for key, value in pairs(v) do
          assert(allowed[key])
          assert(type(value) == 'string' or type(value) == 'number')
        end
        v.status = 'changed'
        assert(P.describe(input).status == 'Working')
        assert(P.describe{required_ai_tokens=0}.progress == 1)
        assert(P.describe{cumulative_ai_tokens=-1}.progress == 0)
        assert(P.describe{cumulative_ai_tokens=0/0}.progress == 0)
        assert(P.describe{cumulative_ai_tokens=math.huge}.progress == 0)
        assert(P.describe().stage_key == 'compute')
        """)


if __name__ == "__main__":
    unittest.main()
