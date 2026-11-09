"""Pure policy and mocked lifecycle tests; native heat conduction is tested separately."""
from pathlib import Path
import shutil
import subprocess
import unittest

try:
    from lupa.lua52 import LuaRuntime
except ImportError:
    LuaRuntime = None
LUA = shutil.which("lua5.2") or shutil.which("lua")

ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / "mod/bitermotors_0.1.1"

PRELUDE = r'''
storage = {}
local next_unit, next_registration = 1, 1
local alert_count, clear_count, scans, deaths = 0, 0, 0, 0
defines = {alert_type={custom=1}, entity_status_diode={green=1,yellow=2,red=3}}
script = {register_on_object_destroyed=function(entity)
  local result=next_registration; next_registration=next_registration+1; return result
end}
local player = {valid=true}
player.add_custom_alert=function(entity, icon, message, on_map)
  assert(entity.valid and on_map and icon.name == P.radiator)
  alert_count=alert_count+1
end
player.remove_alert=function(filter)
  assert(filter.entity and filter.type == 1); clear_count=clear_count+1
end
local force = {index=1, players={player}}
rendering = {draw_sprite=function(spec)
  assert(spec.target.entity.valid and spec.forces[1] == spec.target.entity.force)
  local visual={valid=true}; visual.destroy=function() visual.valid=false end; return visual
end}
local surface = {name='orbit', platform={valid=true}, entities={}}
local recipe = {name='compute',energy=30}
prototypes = {recipe={compute=recipe, model={name='model',energy=90}}}
local function make(name, x, y)
  local e={valid=true,name=name,unit_number=next_unit,surface=surface,
    position={x=x or 0,y=y or 0},force=force,quality={name='normal'},
    crafting_progress=0,crafting_speed=1.5,energy=100,electric_buffer_size=100,
    consumption_bonus=0,temperature=15,products_finished=0,recipe=recipe}
  next_unit=next_unit+1
  e.get_recipe=function() return e.recipe end
  e.is_crafting=function() return e.crafting_progress > 0 end
  e.set_heat_setting=function(setting)
    assert(setting.mode=='at-least' and setting.temperature==15)
  end
  e.destroy=function() e.valid=false end
  e.die=function() e.valid=false; deaths=deaths+1 end
  surface.entities[#surface.entities+1]=e
  return e
end
surface.create_entity=function(spec) return make(spec.name,spec.position.x,spec.position.y) end
surface.find_entities_filtered=function(filter)
  scans=scans+1
  local out={}
  for _,e in ipairs(surface.entities) do
    local match=e.name==filter.name
    if type(filter.name)=='table' then
      for _,name in ipairs(filter.name) do match=match or e.name==name end
    end
    if e.valid and match then out[#out+1]=e end
  end
  return out
end
game = {tick=0, players={player}, surfaces={surface}}
local function tick(n) game.tick=game.tick+(n or 15); M.update() end
local function entry(e) return storage.bitermotors_orbital_thermals.cores[e.unit_number] end
'''


@unittest.skipUnless(LuaRuntime or LUA, "Requires Lua or optional lupa.lua52")
class OrbitalThermalTests(unittest.TestCase):
    def lua(self, body):
        source = "package.path=" + repr(str(MOD / "?.lua")) + "..';'..package.path\n"
        source += "P=require('runtime.orbital_thermal_policy'); M=require('runtime.orbital_thermals')\n"
        source += PRELUDE + body
        if LuaRuntime:
            LuaRuntime().execute(source)
        else:
            result = subprocess.run([LUA, "-"], input=source, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_normal_disconnection_buffer_is_two_to_three_minutes(self):
        self.lua('''
        local seconds=(P.burnout_c-P.target_c)*P.core_joules_per_c/(P.core_watts+P.idle_watts)
        assert(seconds>=120 and seconds<=180)
        assert(P.state(104.999)=='normal' and P.state(105)=='warning')
        assert(P.state(120)=='critical' and P.state(130)=='burnout')
        ''')

    def test_radiation_is_finite_kelvin_based_and_conservative(self):
        self.lua('''
        for _,temperature in ipairs{15,20,97,130,500} do
          for _,elapsed in ipairs{0,0.25,1,10,100000} do
            local t,j=P.cool(temperature,elapsed)
            assert(t>=15 and t<=temperature and j>=0)
            assert(j<=P.radiator_max_watts*elapsed)
            assert(math.abs((temperature-t)*P.radiator_joules_per_c-j)<0.001)
          end
        end
        assert(P.radiated_watts(130)==P.radiator_max_watts)
        local a=P.radiator_reference_c
        assert(math.abs(P.radiated_watts(a)-P.core_watts)<1)
        ''')

    def test_work_counts_completion_recipe_not_bonus_output(self):
        self.lua('''
        local core=make(P.core); M.register(core)
        core.crafting_progress=0.0125; tick()
        local work=entry(core).work_seconds
        assert(math.abs(work-0.25)<1e-8)
        core.crafting_progress=0
        M.completed{entity=core,recipe='compute',bonus=false}
        tick()
        assert(entry(core).work_seconds==work+0.25)
        local completed=entry(core).completed_energy
        M.completed{entity=core,recipe='compute',bonus=true}
        assert(entry(core).completed_energy==completed)
        ''')

    def test_idle_and_blocked_work_only_produce_idle_heat(self):
        self.lua('''
        local core=make(P.core); M.register(core); tick()
        assert(entry(core).work_seconds==0)
        assert(math.abs(entry(core).last_watts-P.idle_watts)<1)
        core.energy=0; tick()
        assert(entry(core).last_watts==0)
        ''')

    def test_native_speed_and_consumption_bonuses_are_accounted(self):
        self.lua('''
        assert(P.work_seconds(10,11.5,6,0.25)==0.25)
        assert(P.work_seconds(10,1000,6,0.25)==0.25)
        assert(P.work_seconds(10,0,6,0.25)==0)
        assert(P.heat_joules(1,1,1,1)==P.core_watts*2+P.idle_watts)
        assert(P.heat_joules(1,1,-10,0)==P.core_watts*0.2)
        local core=make(P.core); core.crafting_speed=6; core.consumption_bonus=1
        M.register(core); core.crafting_progress=0.05; tick()
        assert(math.abs(entry(core).work_seconds-0.25)<1e-8)
        assert(math.abs(entry(core).last_watts-(P.core_watts*2+P.idle_watts))<1)
        ''')

    def test_repeated_registration_and_rebuild_preserve_hot_buffer_and_progress(self):
        self.lua('''
        local core=make(P.core); M.register(core)
        local e=entry(core); e.buffer.temperature=110; core.crafting_progress=0.4
        M.register(core); M.rebuild()
        assert(entry(core)==e and e.buffer.temperature==110 and core.crafting_progress==0.4)
        local orphan=make(P.buffer); M.rebuild(); assert(not orphan.valid)
        ''')

    def test_alerts_are_map_visible_refresh_without_console_and_clear_on_recovery(self):
        self.lua('''
        local core=make(P.core); M.register(core); local e=entry(core)
        e.buffer.temperature=106; tick()
        assert(e.alert_state=='warning' and e.visual.valid and alert_count==1)
        tick(); assert(alert_count==1)
        e.buffer.temperature=121; tick()
        assert(e.alert_state=='critical' and alert_count==2)
        e.buffer.temperature=97; tick()
        assert(not e.alert_state and not e.visual and clear_count>0)
        ''')

    def test_force_switch_moves_buffer_and_warning_ownership(self):
        self.lua('''
        local core=make(P.core); M.register(core); local e=entry(core)
        e.buffer.temperature=106; tick()
        core.force={index=2,players={}}
        tick()
        assert(e.buffer.force==core.force and e.alert_force==2 and alert_count==1)
        assert(#M.status(force).cores==0 and #M.status(core.force).cores==1)
        ''')

    def test_removal_death_and_hidden_component_registration_cleanup(self):
        self.lua('''
        local core=make(P.core); M.register(core); local e=entry(core)
        local buffer=e.buffer; local registration=e.registration
        core.valid=false
        M.destroyed{registration_number=registration}
        assert(not buffer.valid and not entry(core))
        tick(); assert(#M.status().cores==0)
        local other=make(P.core); M.register(other)
        entry(other).buffer.temperature=131; tick()
        assert(not other.valid and deaths==1 and M.status().burnouts==1)
        tick(); assert(deaths==1)
        ''')

    def test_lost_hidden_buffer_cannot_cool_reset(self):
        self.lua('''
        local core=make(P.core); M.register(core); local e=entry(core)
        e.buffer.temperature=125; tick()
        e.buffer.valid=false
        M.destroyed{registration_number=e.buffer_registration}
        tick(); assert(core.valid and entry(core).buffer.temperature>=125)
        ''')

    def test_clone_preserves_temperature_not_source_ownership_or_heat_counters(self):
        self.lua('''
        local core=make(P.core); M.register(core); entry(core).buffer.temperature=110
        local clone=make(P.core,10,0)
        M.cloned{source=core,destination=clone}
        assert(entry(clone).buffer.temperature==110)
        assert(entry(clone).buffer~=entry(core).buffer and entry(clone).heat_joules==0)
        local extra=make(P.buffer); M.cloned{source=entry(core).buffer,destination=extra}
        assert(not extra.valid and entry(clone).buffer.valid)
        ''')

    def test_relocation_preserves_temperature_without_orphan(self):
        self.lua('''
        local core=make(P.core); M.register(core); local old=entry(core).buffer
        old.temperature=110; core.position={x=20,y=20}; tick()
        assert(not old.valid)
        assert(entry(core).buffer.position.x==20 and entry(core).buffer.temperature>=110)
        ''')

    def test_update_budget_no_world_scans_and_deleted_entities_are_trickled_out(self):
        self.lua('''
        local cores={}
        for i=1,257 do
          cores[i]=make(P.core,i*4); M.register(cores[i])
          M.register(make(P.radiator,i*4,10))
        end
        for i=1,10 do tick() end
        assert(scans==0 and M.status().max_visited==128)
        for _,core in ipairs(cores) do assert(entry(core).last_tick>=90) end
        for _,e in ipairs(surface.entities) do e.valid=false end
        for i=1,12 do tick() end
        assert(#M.status().cores==0 and #M.status().radiators==0)
        assert(#storage.bitermotors_orbital_thermals.core_queue.units==0)
        ''')

    def test_runtime_never_disables_or_resets_crafting(self):
        source = (MOD / "runtime/orbital_thermals.lua").read_text()
        self.assertNotRegex(source, r"\.(?:crafting_progress|disabled_by_script)\s*=")
        self.assertNotIn('mode = "add"', source)
        update = source[source.index("function M.update()") : source.index("function M.core_status")]
        self.assertNotIn("game.surfaces", update)


if __name__ == "__main__":
    unittest.main()
