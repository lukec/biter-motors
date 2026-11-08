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
