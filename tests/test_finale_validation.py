import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class FinaleValidationTests(unittest.TestCase):
    def test_epilogue_uses_native_players_gui_and_guarded_presentation_only(self):
        source = (ROOT / "scripts/fixtures/epilogue-validation.lua").read_text()
        for marker in ('game.get_player', 'player.gui.screen.bitermotors_epilogue',
                       'player.opened', '"open_epilogue"', '"dismiss_epilogue"',
                       '"epilogue_status"', 's.elapsed_ticks < 180', 's.elapsed_ticks >= 180',
                       'f.first.force = f.unwon_force', 'f.first.force = game.forces.player',
                       'frame(f.first).destroy()', '"thinking reload cannot acknowledge"',
                       '"repeated thinking open preserves same native frame"',
                       '"repeated thinking open preserves elapsed ticks"',
                       '"repeated thinking open preserves acknowledgement"',
                       '"repeated open cannot queue a delayed close"',
                       '"replay never resets acknowledgement"', '"native late player creation queues epilogue"'):
            self.assertIn(marker, source)
        for forbidden in ('script.raise_event', 'storage.bitermotors_', 'game.speed =',
                          'game.tick_paused =', 'trigger_victory', 'test_set_ai_token_progress'):
            self.assertNotIn(forbidden, source)
        runner = (ROOT / "scripts/validate-bitermotors-finale.sh").read_text()
        self.assertIn('"$helper/epilogue-validation.lua"', runner)
        self.assertIn('epilogue_thinking epilogue_reply epilogue_acknowledged', runner)
        self.assertIn('bitermotors_stage_mod "$mods"', runner)
        self.assertIn('BITERMOTORS_ENDING_PLAYER_SAVE', runner)
        self.assertIn('"$player_save" "$save"', runner)

    def test_progress_gui_is_instantiated_through_public_api_on_native_route(self):
        helper = (ROOT / "scripts/fixtures/epilogue-validation.lua").read_text()
        route = (ROOT / "scripts/fixtures/delivery-control.lua").read_text()
        for marker in ('call("open_progress", f.first)', 'bitermotors_progress_panel',
                       '"bitermotors_progress_content"', '"bitermotors_ending_stage"',
                       '"bitermotors_ending_payload"', '"bitermotors_ending_progress"',
                       '"native GUI does not show empty ingredients as missing"',
                       '"completed Progress survives original machine removal"'):
            self.assertIn(marker, helper)
        self.assertIn('epilogue.progress(phase, phase .. "_checkpoint")', route)
        self.assertIn('epilogue.progress(phase, phase .. "_reload")', route)
        self.assertIn('epilogue.progress("won", "won_reload")', route)
        self.assertIn('epilogue.progress_force_cache()', route)

    def test_native_force_cache_probe_preserves_panel_and_never_clears_spoilers_before_assertion(self):
        helper = (ROOT / "scripts/fixtures/epilogue-validation.lua").read_text()
        probe = helper.split('function api.progress_force_cache()', 1)[1].split('function api.progress(', 1)[0]
        code = "\n".join(line for line in probe.splitlines() if not line.lstrip().startswith("--"))
        self.assertNotIn('call("open_epilogue"', code)
        self.assertNotIn('locked(', code)
        self.assertNotIn('.clear()', code)
        self.assertEqual(code.count('panel.destroy()'), 1)
        self.assertLess(code.index('local restored = complete(panel)'), code.index('panel.destroy()'))
        self.assertIn('equal(returned, primed', code)
        self.assertIn('"bitermotors_epilogue_open"', code)
        self.assertIn('"bitermotors_epilogue_reply"', code)

    def test_return_uses_native_landing_station_then_actual_delivery_without_sweeps(self):
        control = (ROOT / "mod/bitermotors_0.1.1/control.lua").read_text()
        landing = control.split("function record_agi_model_landing(event)", 1)[1].split(
            "function record_agi_model_return", 1)[0]
        handler = control.split("function record_agi_model_return(event)", 1)[1].split(
            "function clear_office_buyer_reservation", 1)[0]
        code = "\n".join(line for line in handler.splitlines() if not line.lstrip().startswith("--"))
        self.assertNotIn("cargo_pod_destination", code)
        for forbidden in ("cargo_bay_connection_owner", "find_entities", "AgiCompletion.deliver", "trigger_victory"):
            self.assertNotIn(forbidden, landing)
        for forbidden in ("cargo_bay_connection_owner", "find_entities", "find_entity"):
            self.assertNotIn(forbidden, code)
        for guard in ('destination.type == defines.cargo_destination.station and destination.station',
                      'pad and pad.valid', 'pad.type == "cargo-landing-pad"',
                      'pad.force == pod.force', 'pad.surface == game.surfaces.nauvis',
                      'pod.surface == pad.surface', 'transit.landing_pad = pad'):
            self.assertIn(guard, landing)
        for guard in ('local pad = transit.landing_pad', 'event.spawned_container',
                      'not pad or not pad.valid', 'pad.type ~= "cargo-landing-pad"',
                      'pad.force ~= pod.force', 'pad.surface ~= game.surfaces.nauvis',
                      'pod.surface ~= pad.surface', 'AgiCompletion.deliver(state, pod.unit_number, pad.force.index)'):
            self.assertIn(guard, code)
        self.assertIn('script.on_event(defines.events.on_cargo_pod_finished_descending, record_agi_model_landing)', control)
        self.assertIn('script.on_event(defines.events.on_cargo_pod_delivered_cargo, record_agi_model_return)', control)

    def test_finale_reuses_native_route_with_rare_payload_and_adversaries(self):
        source = (ROOT / "scripts/fixtures/delivery-control.lua").read_text()
        wrapper = (ROOT / "scripts/fixtures/finale-control.lua").read_text()
        runner = (ROOT / "scripts/validate-bitermotors-finale.sh").read_text()
        self.assertIn('require("native-ending").run{adversarial = true}', wrapper)
        self.assertIn('"$helper/native-ending.lua"', runner)
        self.assertIn('options.adversarial and "rare" or "normal"', source)
        for marker in ("injected Model negative ran a real native activation", "raw statistics cannot earn compute",
                       "wrong-force negative ran a real native activation", "wrong surface cannot earn activation credit",
                       "wrong-quality negative completed anew after return reload",
                       "blocked output and injected Model cannot mint assembly credit",
                       "machine removal does not erase earned assembly credit",
                       "genuine output reran native activation without a new credit",
                       "activation outage retains exact progress",
                       "activation reload retains committed original Model",
                       "unpowered activation checkpoint retains exact native progress",
                       "native activation low/no_power observed through checkpoint",
                       "native full_output observed beyond full 60-second craft",
                       "grid-scale research and earned billion suffice without Hyper"):
            self.assertIn(marker, source)

    def test_private_pure_ledger_exercises_conservation_and_replay_boundaries(self):
        source = (ROOT / "scripts/fixtures/delivery-control.lua").read_text()
        self.assertIn('require("__bitermotors__/runtime/agi_completion")', source)
        for marker in ("no cross-force departure", "no cross-platform departure", "no cross-quality departure",
                       "excess cargo reserves only native credit", "replayed departure cannot mint",
                       "replayed delivery cannot mint", "lost-pod cleanup forfeits reservation",
                       "lost credit cannot be reused", "wrong-quality activation rejected",
                       "cross-force delivery forfeits instead of transferring", "JSON conserves in-transit quality",
                       "native reload conserves in-transit quality", "reload cannot reuse consumed activation"):
            self.assertIn(marker, source)
        self.assertIn('helpers.json_to_table(helpers.table_to_json(ledger))', source)
        self.assertIn('storage.pure_ledger = ledger', source)
        self.assertNotIn('storage.bitermotors_', source)
        self.assertIn('require("__bitermotors__/runtime/endgame_presentation")', source)
        for marker in ("presentation victory precedence", "physical stock is not earned compute",
                       "presentation empty inputs are committed", "presentation leaves input snapshot unchanged",
                       "presentation actual pod transit", "presentation lost Model recovery",
                       "presentation rejects NaN progress", "presentation_native_cases = assertions - before"):
            self.assertIn(marker, source)


if __name__ == "__main__":
    unittest.main()
