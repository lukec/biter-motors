import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class FinaleValidationTests(unittest.TestCase):
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


if __name__ == "__main__":
    unittest.main()
