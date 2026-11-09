import json
import shutil
import subprocess
import unittest
from pathlib import Path

try:
    from lupa.lua52 import LuaRuntime
except ImportError:
    LuaRuntime = None


ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "experiments/bitermotors_thermal_prototype_0.1.0"
POLICY = ADDON / "thermal-policy.lua"
LUA = shutil.which("lua5.2") or shutil.which("lua") or shutil.which("luajit")
RUNNER = ROOT / "scripts/validate-bitermotors-thermal.sh"
FIXTURE = ROOT / "scripts/fixtures/thermal-control.lua"


class OrbitalThermalPrototypeScopeTest(unittest.TestCase):
    def test_policy_is_independent_of_factorio_runtime(self):
        source = POLICY.read_text()
        for dependency in ("game.", "storage.", "script.", "data.", "require("):
            self.assertNotIn(dependency, source)

    def test_addon_is_separate_from_main_mod(self):
        info = json.loads((ADDON / "info.json").read_text())
        self.assertEqual(info["name"], "bitermotors_thermal_prototype")
        for path in (ROOT / "mod/bitermotors_0.1.1").rglob("*.lua"):
            source = path.read_text()
            for marker in ("bitermotors-thermal-", "bitermotors_thermal_prototype",
                           'require("thermal-policy")'):
                self.assertNotIn(marker, source, str(path))

    def test_prototypes_use_finite_native_heat_buffers(self):
        source = (ADDON / "data.lua").read_text()
        for capacity, size in (("500MJ", 3), ("100MJ", 3), ("20MJ", 1)):
            self.assertIn(f'buffer("{capacity}", {size})', source)
        self.assertIn('max_transfer = "5GW"', source)
        self.assertIn("default_temperature = P.floor_c", source)

    def test_no_automatic_shutdown_assignment_in_addon(self):
        # Scope guard, not native proof that a running machine survives overheating.
        for path in ADDON.rglob("*.lua"):
            self.assertNotRegex(path.read_text(), r"\.\s*active\s*=\s*false\b", str(path))

    def test_neutral_heat_never_uses_add_mode(self):
        source = (ADDON / "control.lua").read_text()
        self.assertNotRegex(source, r'''mode\s*=\s*["']add["']''')
        self.assertIn('mode = "at-least", temperature = P.floor_c', source)
        self.assertIn("entity.temperature = P.floor_c", source)

    def test_runtime_display_stays_native_without_custom_gui(self):
        source = (ADDON / "control.lua").read_text()
        self.assertEqual(source.count("entity.custom_status ="), 2)
        for marker in ("player.gui", "on_gui_opened", "on_gui_closed", 'type = "frame"'):
            self.assertNotIn(marker, source)

    def test_zero_idle_drain_is_scoped_to_experimental_core(self):
        source = (ADDON / "data.lua").read_text()
        self.assertIn('core.energy_source.drain = "0W"', source)
        self.assertEqual(source.count(".drain ="), 1)
        self.assertIn('table.deepcopy(data.raw["assembling-machine"]'
                      '["bitermotors-orbital-datacenter-core"])', source)

    def test_native_runner_uses_only_temporary_mod_and_write_paths(self):
        source = RUNNER.read_text()
        self.assertIn('mktemp -d /tmp/bitermotors-thermal.XXXXXX', source)
        self.assertIn('mods="$tmp/mods"', source)
        self.assertIn('bitermotors_stage_mod "$mods"', source)
        self.assertIn('write-data=%s', source)
        self.assertIn('"$read_data" "$tmp" > "$tmp/config.ini"', source)
        engine_calls = [line for line in source.splitlines()
                        if line.lstrip().startswith('"$factorio_bin"')]
        self.assertEqual(len(engine_calls), 2)
        for line in engine_calls:
            self.assertIn('--config "$tmp/config.ini" --mod-directory "$mods"', line)
        for command in ("install-bitermotors", "--install", "sudo ", "rsync "):
            self.assertNotIn(command, source)
        self.assertIn('prototype="$repo_root/experiments/bitermotors_thermal_prototype_0.1.0"', source)
        self.assertIn('ln -s "$prototype" "$mods/bitermotors_thermal_prototype_0.1.0"', source)
        self.assertIn('cp "$repo_root/scripts/fixtures/thermal-control.lua" "$helper/control.lua"', source)
        self.assertNotRegex(source, r'''(?m)^.*(?:>|\b(?:cp|mv|rm)\b).*\s["']?\$repo_root/(?:mod|experiments)/[^\n]*$''')

    def test_native_runner_checks_exact_zip_before_temporary_staging(self):
        source = RUNNER.read_text()
        self.assertIn('if [[ -n "${BITERMOTORS_THERMAL_ARCHIVE:-}" ]]; then', source)
        self.assertIn('python3 - "$BITERMOTORS_THERMAL_ARCHIVE" "$prototype"', source)
        self.assertIn('len(files)!=len(expected)', source)
        self.assertIn('{entry.filename for entry in files}!=set(expected)', source)
        self.assertIn('archive.read(name)!=data', source)
        copy = 'cp "$BITERMOTORS_THERMAL_ARCHIVE" "$mods/bitermotors_thermal_prototype_0.1.0.zip"'
        self.assertIn(copy, source)
        self.assertLess(source.index('archive.read(name)!=data'), source.index(copy))

    def test_native_runner_checks_logs_and_advancing_phase_reports(self):
        source = RUNNER.read_text()
        for contract in (
            'bitermotors_check_log "$log" --expect-marker Goodbye',
            'for phase in hot burned; do',
            'bitermotors_check_log "$tmp/$phase.log" --expect-marker Goodbye',
            'run_engine "$tmp/create.log"',
            'run_engine "$tmp/reload.log"',
            'bitermotors_check_log "$tmp/reload.log" --expect-updates 61 --expect-marker Goodbye',
            '--require-status "${phase}_checkpoint" --minimum-tick 1',
            '--require-status reload_passed --minimum-tick 1',
            'assert all(b["tick"]>a["tick"] for a,b in zip(rows,rows[1:]))',
            'assert all(r["assertions"]>0 for r in rows)',
        ):
            self.assertIn(contract, source)

    def test_native_fixture_reports_physics_without_fabricating_heat_or_progress(self):
        source = FIXTURE.read_text()
        runner = RUNNER.read_text()
        phases = ("setup_passed", "steady_passed", "blocked_output_passed",
                  "brownout_passed", "outage_passed", "repair_started", "repair_passed",
                  "hot_checkpoint", "hot_reload_passed", "burnout_passed",
                  "burned_checkpoint", "reload_passed")
        for phase in phases:
            self.assertIn('"' + phase + '"', runner)
        for marker in ("native heat transport conserves injected, stored and radiated energy",
                       "output-blocked core produces no fictitious heat",
                       "one real native overheat death",
                       "hot native buffer survives separate reload"):
            self.assertIn(marker, source)
        self.assertNotRegex(source, r"\.(?:temperature|crafting_progress|bonus_progress)\s*=(?!=)")
        self.assertNotIn("set_heat_setting", source)
        self.assertIn('storage.bridge.destroy{raise_destroy = true}', source)
        self.assertIn('storage.bridge = make(PIPE, 3.5, 10.5)', source)
        self.assertIn("defines.events.on_entity_died", source)


@unittest.skipUnless(LuaRuntime or LUA, "Pure policy requires Lua or optional lupa.lua52")
class OrbitalThermalPrototypePolicyTest(unittest.TestCase):
    def lua(self, assertions):
        source = "local P = dofile(" + repr(str(POLICY)) + ")\n" + assertions
        if LuaRuntime:
            LuaRuntime().execute(source)
        else:
            result = subprocess.run([LUA, "-"], input=source, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_runtime_registration_sets_neutral_floor_and_explicit_spawn_temperature(self):
        self.lua("""
        package.preload['thermal-policy'] = function() return P end
        local init, built
        script = {
          on_init=function(f) init=f end,
          on_configuration_changed=function() end,
          on_nth_tick=function() end,
          on_event=function(events, f)
            if type(events) == 'table' and events[1] == 'on_built_entity' then built=f end
          end
        }
        defines = {events=setmetatable({}, {__index=function(_, k) return k end})}
        prototypes = {recipe={}}
        remote = {add_interface=function() end}
        storage = {}
        game = {surfaces={}, tick=0}
        """ + "dofile(" + repr(str(ADDON / "control.lua")) + ")\n" + """
        init()
        assert(built)
        local settings = {}
        local function heat_entity(name, unit)
          local entity = {valid=true, name=name, unit_number=unit, temperature=999}
          entity.set_heat_setting = function(setting)
            assert(setting.mode == 'at-least' and setting.temperature == P.floor_c)
            settings[#settings + 1] = setting
          end
          return entity
        end
        local buffer = heat_entity('bitermotors-thermal-buffer', 2)
        local surface = {platform={}, create_entity=function() return buffer end}
        local core = {valid=true, name='bitermotors-thermal-core', unit_number=1,
          surface=surface, position={0,0}, force={}, quality='normal'}
        local radiator = heat_entity('bitermotors-thermal-radiator', 3)
        radiator.surface = surface
        built{entity=core}
        built{entity=radiator}
        assert(#settings == 2)
        assert(buffer.temperature == 15 and radiator.temperature == 15)
        assert(storage.cores[1].buffer == buffer)
        assert(storage.radiators[3].entity == radiator)
        -- Reconciliation must not reset already-registered hot entities.
        buffer.temperature, radiator.temperature = 97, 93
        built{entity=core}
        built{entity=radiator}
        assert(#settings == 2)
        assert(buffer.temperature == 97 and radiator.temperature == 93)
        """)

    def test_radiation_uses_absolute_kelvin_fourth_power(self):
        self.lua("""
        assert(P.core_watts == 250000000)
        local reference_c = P.radiator_reference_c
        local reference = P.radiated_watts(reference_c)
        assert(reference == P.core_watts)
        for _, t in ipairs{15, 40, 80, 97} do
          local expected = ((t + 273.15) / (reference_c + 273.15))^4
          assert(math.abs(P.radiated_watts(t) / reference - expected) < 1e-12)
        end
        assert(P.radiated_watts(97) > P.core_watts)
        """)

    def test_radiation_is_capped_at_300_megawatts(self):
        self.lua("""
        assert(P.radiator_max_watts == 300000000)
        assert(P.radiated_watts(97) < P.radiator_max_watts)
        for _, t in ipairs{120, 130, 500, 1000} do
          assert(P.radiated_watts(t) == 300000000)
        end
        """)

    def test_target_and_exact_state_boundaries(self):
        self.lua("""
        assert(P.target_c == 97 and P.warning_c == 105)
        assert(P.critical_c == 120 and P.burnout_c == 130)
        for _, case in ipairs{{15,'normal'}, {97,'normal'}, {104.999,'normal'},
          {105,'warning'}, {119.999,'warning'}, {120,'critical'},
          {129.999,'critical'}, {130,'burnout'}, {500,'burnout'}} do
          assert(P.state(case[1]) == case[2])
        end
        """)

    def test_finite_heat_capacity_and_cooldown_energy_accounting(self):
        self.lua("""
        assert(P.core_joules_per_c == 500000000)
        assert(P.radiator_joules_per_c == 100000000)
        assert(P.conduit_joules_per_c == 20000000)
        assert(P.interval_ticks == 15)
        for _, t in ipairs{15, 16, 97, 130, 500} do
          for _, seconds in ipairs{0, 0.25, 1, 1000000} do
            local cooled, removed = P.cool(t, seconds)
            local available = (t - 15) * 100000000
            assert(cooled == cooled and removed == removed)
            assert(cooled >= 15 and cooled <= t)
            assert(removed >= 0 and removed <= available)
            assert(removed <= P.radiated_watts(t) * seconds)
            assert(math.abs((t - cooled) * 100000000 - removed) < 1e-4)
          end
        end
        local cooled, removed = P.cool(97, 0.25)
        assert(math.abs(removed - P.radiated_watts(97) * 0.25) < 1e-4)
        assert(cooled < 97)
        """)

    def test_cooldown_exhausts_available_heat_without_crossing_floor(self):
        self.lua("""
        assert(P.floor_c == 15)
        local cooled, removed = P.cool(16, 1000000)
        assert(cooled == 15 and removed == 100000000)
        local again, more = P.cool(cooled, 1000000)
        assert(again == 15 and more == 0)
        local unchanged, zero = P.cool(97, 0)
        assert(unchanged == 97 and zero == 0)
        """)

    def test_work_delta_clamps_to_elapsed_and_never_credits_negative_reset(self):
        self.lua("""
        assert(P.work_delta(10, 10.125, 0.25) == 0.125)
        assert(P.work_delta(10, 1000, 0.25) == 0.25)
        assert(P.work_delta(10, 11, 0) == 0)
        assert(P.work_delta(10, 10, 0.25) == 0)
        -- A recipe-change counter reset is not newly performed work.
        assert(P.work_delta(10, 0, 0.25) == 0)
        assert(P.work_delta(10, 9.9, 0.25) == 0)
        for _, previous in ipairs{0, 1, 1000} do
          for _, current in ipairs{0, 0.125, 2000} do
            local work = P.work_delta(previous, current, 0.25)
            assert(work >= 0 and work <= 0.25)
          end
        end
        """)

    def test_policy_reports_overheat_without_proposing_shutdown(self):
        self.lua("""
        for _, t in ipairs{97, 105, 120, 130} do
          assert(type(P.state(t)) == 'string')
        end
        assert(P.shutdown == nil and P.should_shutdown == nil)
        assert(P.state(129.999) == 'critical')
        assert(P.state(130) == 'burnout')
        """)


if __name__ == "__main__":
    unittest.main()
