import json
import re
import unittest
from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / "mod" / "bitermotors_0.1.1"


class BiterMotorsModTest(unittest.TestCase):
    def test_space_age_freeplay_is_branded_for_biter_motors(self):
        locale = (MOD / "locale/en/freeplay.cfg").read_text()
        self.assertIn("scenario-name-space-age=Freeplay (Biter Motors)", locale)
        self.assertIn("turn biter settlements into customers", locale)
        self.assertIn("train AGI", locale)
        self.assertNotIn("discover other planets", locale)

    def test_internal_power_helpers_have_player_facing_locale_names(self):
        locale = (MOD / "locale/en/bitermotors.cfg").read_text()
        expected = {
            "bitermotors-ev-charging-grid-connection": "EV Charging Station grid connection",
            "bitermotors-ev-charging-power-sink": "EV Charging Station charging stalls",
            "bitermotors-ev-charging-v2-power-sink": "EV Charging Station V2 charging stalls",
            "bitermotors-ev-charging-v3-power-sink": "V3 Rapid Charger charging stalls",
            "bitermotors-ev-charging-v4-power-sink": "V4 Solar Charging Hub charging stalls",
            "bitermotors-bitertaxi-depot-power": "Bitertaxi Depot charging",
            "bitermotors-cybertrain-charging-power": "Cybertrain charging",
        }
        for key, label in expected.items():
            self.assertIn(f"{key}={label}", locale)

        validator = (ROOT / "scripts/validate-bitermotors-mod.sh").read_text()
        self.assertIn("Biter Motors prototype locale coverage OK.", validator)
        self.assertIn("Biter Motors prototypes have missing locale names:", validator)
        self.assertIn('"electric-energy-interface"', validator)
        self.assertIn('"assembling-machine"', validator)

    def test_electric_vehicles_use_ev_audio(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        self.assertIn("__bitermotors__/sound/ev-drivetrain-loop.wav", data)
        self.assertIn('name = "bitermotors-ev-reverse-warning"', data)
        self.assertIn("volume = 0.72", data)
        self.assertIn("volume = 0.58", data)
        self.assertIn("function update_ev_reverse_warnings()", control)
        self.assertIn("defines.riding.acceleration.reversing", control)
        self.assertIn("ELECTRIC_VEHICLE_BATTERIES[vehicle.name]", control)
        self.assertNotIn("ELECTRIC_VEHICLE_NAMES", control)
        self.assertIn("update_ev_reverse_warnings()", control)

    def test_bitermotors_ev_self_driving_is_physical_owned_bounded_and_excludes_roadster(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        runtime = (MOD / "runtime" / "ev_self_driving.lua").read_text()
        locale = (MOD / "locale" / "en" / "bitermotors.cfg").read_text()
        roadmap = (ROOT / "ROADMAP.md").read_text()
        validator = (ROOT / "scripts" / "validate-bitermotors-mod.sh").read_text()

        for name in [
            "bitermotors-premium-ev",
            "bitermotors-mass-market-ev",
            "bitermotors-megatruck",
            "bitermotors-bitertaxi-fleet",
        ]:
            self.assertIn(f'["{name}"] = true', runtime)
        self.assertNotIn('["bitermotors-prototype-roadster"] = true', runtime)
        self.assertIn('name = "bitermotors-ev-self-driving-destination"', data)
        self.assertIn('name = "bitermotors-route-ev"', data)
        self.assertIn('name = "bitermotors-summon-ev"', data)
        self.assertIn('technology_to_unlock = "bitermotors-autonomous-logistics"', data)
        for control_name in ["move-up", "move-down", "move-left", "move-right"]:
            self.assertIn(f'linked_game_control = "{control_name}"', data)

        self.assertIn("vehicle.surface.request_path{", control)
        self.assertIn("bounding_box = vehicle.prototype.collision_box", control)
        self.assertIn("collision_mask = vehicle.prototype.collision_mask", control)
        self.assertIn("entity_to_ignore = vehicle", control)
        self.assertIn("vehicle.riding_state =", control)
        self.assertIn("defines.events.on_script_path_request_finished", control)
        self.assertIn("defines.events.on_player_selected_area", control)
        self.assertIn("EV_SELF_DRIVING_SUMMON_SHORTCUT", control)
        self.assertIn("function nearest_recent_ev_for_player", control)
        self.assertIn("runtime.owner_by_vehicle[unit_number] == player.index", control)
        self.assertIn("function player_is_vehicle_driver", control)
        self.assertIn('cancel_ev_self_driving(unit_number, "no route found"', control)
        self.assertIn("EvSelfDriving.config.max_active", control)
        self.assertIn("EvSelfDriving.config.updates_per_tick", control)
        self.assertIn("safety_check_ticks = 30", runtime)
        self.assertIn("state.next_safety_tick = game.tick + EvSelfDriving.config.safety_check_ticks", control)
        self.assertIn('state.mode == "summon"', control)
        self.assertIn("return vehicle, vehicle, player", control)
        self.assertNotIn("teleport", runtime)

        self.assertIn("bitermotors-route-ev=Route EV", locale)
        self.assertIn("bitermotors-summon-ev=Summon nearest recent EV", locale)
        self.assertIn("Self-driving, and Summon", roadmap)
        self.assertIn('"test_ev_self_driving_start"', validator)
        self.assertIn("self_driving_distance_moved", validator)
        self.assertIn("blocked Biter Motors EV route did not abort cleanly", validator)

    def test_sales_office_panel_explains_market_saturation(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn('label = "EV owners"', control)
        self.assertIn('return "Surplus Sales Office", BITERMOTORS_STATE_COLORS.warning', control)
        self.assertIn('return "Waiting for market growth", BITERMOTORS_STATE_COLORS.neutral', control)
        self.assertIn('label = "Prospects"', control)
        self.assertIn('"%d new + %d returning; %d need charging"', control)
        self.assertIn('"%d new + %d returning"', control)
        self.assertIn('return "Prospects reserved", BITERMOTORS_STATE_COLORS.neutral', control)
        self.assertIn('return "Prospects need charging", BITERMOTORS_STATE_COLORS.bad', control)
        self.assertIn('"Surplus office - %d prospects remain"', control)
        self.assertIn("SALES_OFFICE_LOW_PROSPECT_FRACTION = 0.20", control)
        self.assertIn("Reserved prospects belong to sales already in progress.", control)
        self.assertIn("Overlapping Sales Offices share one prospect pool.", control)
        self.assertNotIn("free prospects", control.lower())
        self.assertNotIn("%d left; %d free", control)
        self.assertIn('label = "Charging"', control)
        self.assertIn('label = "Underserved"', control)
        self.assertIn("BITERMOTORS_STATE_COLORS", control)
        self.assertIn("add_station_info_label(state_row, state_text, state_color)", control)
        sales_panel = control[control.index("if entity.name == SALES_OFFICE_NAME then", control.index("local function show_manufacturer_info_panel")):
                              control.index("  else\n    local config = BITERFACTORY_CONFIGS", control.index("local function show_manufacturer_info_panel"))]
        self.assertIn("add_bitermotors_metric_table", sales_panel)
        self.assertNotIn("Cycle progress", sales_panel)
        self.assertNotIn("Inputs", sales_panel)
        self.assertNotIn("Outputs", sales_panel)
        self.assertNotIn('add_station_info_label(panel, "Recipe: none selected")', control)

    def test_sales_office_showroom_tracks_active_sale_recipe(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        art_script = (ROOT / "scripts/build-bitermotors-art.py").read_text()
        self.assertIn(
            'name = "bitermotors-sales-office-showroom-" .. vehicle.name .. "-frame-" .. frame_index',
            data,
        )
        for vehicle in ["prototype-roadster", "premium-ev", "mass-market-ev", "megatruck"]:
            self.assertIn(f'"{vehicle}"', data)
            showroom_path = MOD / f"graphics/animation/sales-office-showroom-{vehicle}.png"
            self.assertTrue(showroom_path.exists())
            with Image.open(showroom_path) as image:
                self.assertEqual(image.size, (4096, 512))
                first = image.crop((0, 0, 512, 512))
                fifth = image.crop((2048, 0, 2560, 512))
                self.assertIsNotNone(first.getchannel("A").getbbox())
                self.assertIsNotNone(ImageChops.difference(first, fifth).getbbox())
        self.assertIn("SALES_OFFICE_SHOWROOM_SPRITES", control)
        self.assertIn("office.status == defines.entity_status.working", control)
        self.assertIn("math.floor(game.tick / 30) % 8 + 1", control)
        self.assertIn("entry.object.sprite = sprite_prefix .. frame_index", control)
        self.assertIn("target_offset = {0, 0}", control)
        self.assertIn("x_scale = 0.19", control)
        self.assertIn("function update_sales_office_showrooms()", control)
        self.assertIn("destroy_sales_office_showroom_rendering(entity.unit_number)", control)
        self.assertIn("build_sales_office_showroom_animations()", art_script)
        self.assertIn("sales-office-active-empty-chroma.png", art_script)
        self.assertIn("VEHICLE_ICON_NAMES", art_script)
        self.assertIn("if source.stem in VEHICLE_ICON_NAMES", art_script)

    def test_sales_office_beacon_reflects_working_state(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        self.assertIn('"bitermotors-sales-office-status-green-frame-"', control)
        self.assertIn('"bitermotors-sales-office-status-amber-frame-"', control)
        self.assertIn('"bitermotors-sales-office-status-red-frame-"', control)
        self.assertIn('warning_sprite_prefix = "bitermotors-sales-office-status-amber-frame-"', control)
        self.assertIn("defines.entity_status_diode.yellow", control)
        self.assertIn("function update_sales_office_market_alerts()", control)
        self.assertIn("Surplus Sales Office in a saturated market.", control)
        self.assertIn("entry.entity.status == defines.entity_status.working", control)
        self.assertIn('name = "bitermotors-sales-office-status-" .. status.color .. "-frame-" .. frame_index', data)
        self.assertNotIn('working_animation("sales-office-lights"', data)

    def test_sales_office_saturation_only_warns_on_surplus_coverage(self):
        control = (MOD / "control.lua").read_text()
        market_policy = (MOD / "runtime" / "sales_office_market.lua").read_text()
        validator = (ROOT / "scripts" / "validate-bitermotors-mod.sh").read_text()

        self.assertIn('require("runtime.sales_office_market")', control)
        self.assertIn("function SalesOfficeMarket.classify(office_specs)", market_policy)
        self.assertIn("state.market_office_count > 1", market_policy)
        self.assertIn("and not preserves_settlement", market_policy)
        self.assertIn("build_sales_office_market_topology(", control)
        self.assertIn("service.sales_office_market", control)
        self.assertIn("surplus_office = buyer_status.surplus_office == true", control)

        visual = control[
            control.index("local function update_bitermotors_runtime_visuals()"):
            control.index("function charger_stall_visuals()")
        ]
        self.assertIn("and market_state.surplus_office", visual)
        self.assertIn("quiet_mature_market", visual)

        alerts = control[
            control.index("function sales_office_market_alert_message"):
            control.index("function reserve_office_buyers")
        ]
        self.assertIn("state and state.surplus_office", alerts)
        self.assertIn("Deconstruct this office", alerts)
        self.assertIn('test_sales_office_market = function()', control)
        self.assertIn('"unique_edge_retained"', validator)

    def test_sales_office_reconciles_stale_buyer_reservations(self):
        control = (MOD / "control.lua").read_text()
        reconcile = control[
            control.index("function reconcile_office_buyer_reservations()"):
            control.index("function office_has_all_sale_inputs")
        ]
        self.assertIn("population.virtual_reserved = 0", reconcile)
        self.assertIn("storage.bitermotors_buyer_reserved_by_unit = physical_reservations", reconcile)
        self.assertIn("reservations[office_unit_number] = nil", reconcile)
        self.assertIn("rebuild_customer_buyer_queues()", reconcile)
        self.assertIn("SALES_OFFICE_RESERVATION_RECONCILE_TICKS", control)

    def test_ev_progression_is_gated_by_completed_sales(self):
        control = (MOD / "control.lua").read_text()
        data = (MOD / "data.lua").read_text()
        self.assertIn('item = "bitermotors-prototype-roadster",\n    threshold = 50', control)
        self.assertIn('item = "bitermotors-premium-ev",\n    threshold = 250', control)
        self.assertIn('item = "bitermotors-mass-market-ev",\n    threshold = 2000', control)
        self.assertIn('total_consumer_sales = true,\n    threshold = 5000', control)
        self.assertIn('sync_ev_sales_recipe_gates(force, true)', control)
        self.assertIn('not EV_SALES_GATED_RECIPES[effect.recipe]', control)
        prototype_sale = data[data.index('recipe("bitermotors-sell-prototype-roadster"'):data.index('recipe("bitermotors-sell-premium-ev"')]
        self.assertIn('}}, 60,', prototype_sale)

    def test_premium_ev_production_history_survives_statistics_resets(self):
        control = (MOD / "control.lua").read_text()
        runtime = (MOD / "runtime" / "production_history.lua").read_text()
        validator = (ROOT / "scripts" / "validate-bitermotors-mod.sh").read_text()

        self.assertIn('ProductionHistory = require("runtime.production_history")', control)
        self.assertIn("function count_premium_ev_stock(force)", control)
        self.assertIn("function count_premium_evs_produced(force)", control)
        self.assertIn("consumed + count_premium_ev_stock(force)", control)
        self.assertIn("raw < state.last_raw", control)
        self.assertIn("premium_ev_production_history = function", control)
        self.assertIn("state.total - raw", runtime)
        self.assertIn("math.max(state.total, raw + state.offset, floor)", runtime)
        self.assertIn("premium_ev_history_after_reset", validator)

    def test_bitermotors_manifest(self):
        info = json.loads((MOD / "info.json").read_text())
        self.assertEqual(info["name"], "bitermotors")
        self.assertEqual(info["version"], "0.1.1")
        self.assertIn("space-age >= 2.1.0", info["dependencies"])

    def test_legacy_product_names_exist_only_in_the_namespace_migration(self):
        current_sources = "\n".join(
            path.read_text()
            for path in [
                MOD / "data.lua",
                MOD / "data-updates.lua",
                MOD / "data-final-fixes.lua",
                MOD / "control.lua",
                MOD / "locale" / "en" / "bitermotors.cfg",
            ]
        ).lower()
        for retired in [
            "gigafactory",
            "gigacast",
            "robotaxi",
            "megapack",
            "autopilot",
            "supercharger",
        ]:
            self.assertNotIn(retired, current_sources)

        migration = json.loads((MOD / "migrations" / "0.1.1.json").read_text())
        self.assertIn(
            ["bitermotors-gigafactory-building", "bitermotors-biterfactory-building"],
            migration["entity"],
        )
        self.assertIn(
            ["bitermotors-robotaxi-service-center", "bitermotors-bitertaxi-depot"],
            migration["entity"],
        )
        self.assertIn(
            ["bitermotors-grid-megapack", "bitermotors-grid-battery-array"],
            migration["item"],
        )
        runtime_migration = (MOD / "runtime" / "namespace_migration.lua").read_text()
        self.assertIn("function NamespaceMigration.migrate(runtime)", runtime_migration)
        self.assertIn("function NamespaceMigration.audit(runtime)", runtime_migration)
        self.assertIn("NamespaceMigration.migrate(storage)", (MOD / "control.lua").read_text())
        self.assertIn("internal_namespace_status = function", (MOD / "control.lua").read_text())

    def test_bitermotors_mvp_surface(self):
        data = (MOD / "data.lua").read_text()
        for expected in [
            "bitermotors-sales-office",
            "bitermotors-dollar",
            "bitermotors-ev-reservation",
            "bitermotors-biterfactory-module",
            "bitermotors-biterfactory-building",
            "bitermotors-structural-casting",
            "bitermotors-biterfactory-v2",
            "bitermotors-high-density-solar-array",
            "bitermotors-grid-battery",
            "bitermotors-energy-products",
            "bitermotors-ev-charging-station",
            "bitermotors-ev-charging-station-v2",
            "bitermotors-ev-charging-station-v3",
            "bitermotors-ev-charging-station-v4",
            "bitermotors-ai-token",
            "bitermotors-agi-model",
            "bitermotors-agi-training-run",
            "bitermotors-agi-training-dataset",
            "bitermotors-capital-allocation",
            "bitermotors-terrestrial-datacenter",
            "bitermotors-orbital-datacenter-core",
            "bitermotors-planetary-grid-controller",
            "bitermotors-sell-premium-ev",
            "bitermotors-orbital-ai-token",
        ]:
            self.assertIn(expected, data)

    def test_bitermotors_player_facing_name(self):
        info = json.loads((MOD / "info.json").read_text())
        locale = (MOD / "locale/en/bitermotors.cfg").read_text()
        control = (MOD / "control.lua").read_text()
        self.assertEqual(info["name"], "bitermotors")
        self.assertEqual(info["title"], "Biter Motors")
        self.assertIn("bitermotors=Biter Motors", locale)
        self.assertIn("bitermotors-sell-prototype-roadster=Sell hopes and dreams", locale)
        self.assertIn("bitermotors-sell-premium-ev=Sell premium product", locale)
        self.assertIn("bitermotors-premium-ev-program=EV Production Line", locale)
        self.assertIn("bitermotors-advanced-battery-chemistry=Advanced Battery Chemistry", locale)
        self.assertIn("bitermotors-biterfactory-building=Biterfactory", locale)
        self.assertIn("bitermotors-biterfactory-v2=Biterfactory V2", locale)
        self.assertIn("bitermotors-structural-casting=Structural Casting", locale)
        self.assertIn("bitermotors-ev-charging-station-v2=EV Charging Station V2", locale)
        self.assertIn("bitermotors-ev-charging-station-v3=V3 Rapid Charger", locale)
        self.assertIn("bitermotors-ev-charging-station-v4=V4 Solar Charging Hub", locale)
        self.assertIn("bitermotors-energy-products=Energy Products", locale)
        self.assertIn("bitermotors-grid-battery=Grid Battery", locale)
        self.assertIn("bitermotors-high-density-solar-array=High-density Solar Panel", locale)
        self.assertIn("Roughly US$10,000", locale)
        settings = (MOD / "settings.lua").read_text()
        self.assertIn('name = "bitermotors-accelerated-start"', settings)
        self.assertIn("default_value = true", settings)
        self.assertIn("[Biter Motors]", control)

    def test_infinite_continuous_improvement_research(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        locale = (MOD / "locale/en/bitermotors.cfg").read_text()
        roadmap = (ROOT / "ROADMAP.md").read_text()

        for technology in [
            "bitermotors-rapid-charging-power-electronics",
            "bitermotors-long-range-battery",
            "bitermotors-premium-audio-systems",
        ]:
            start = data.index(f'    "{technology}"')
            block = data[start:start + 750]
            self.assertIn('max_level = "infinite"', data[data.index("local function infinite_tech"):data.index("local function infinite_tech") + 500])
            self.assertIn('type = "nothing"', block)
            self.assertNotIn('"military-science-pack"', block)

        referral_start = data.index('    "bitermotors-customer-referral-program"')
        referral_block = data[referral_start:referral_start + 750]
        self.assertIn('max_level = "infinite"', data[data.index("local function infinite_tech"):data.index("local function infinite_tech") + 500])
        self.assertIn('type = "nothing"', referral_block)
        self.assertIn('{"military-science-pack", 1}', referral_block)
        self.assertIn('{"bitermotors-dollar", 1}', referral_block)

        self.assertIn("bitermotors-premium-audio-systems=Biters love Nickelback.", locale)
        for technology, recipe, count_formula in [
            ("bitermotors-high-density-solar-productivity", "bitermotors-high-density-solar-array", "750*1.5^(L-1)"),
            ("bitermotors-grid-battery-productivity", "bitermotors-grid-battery", "750*1.5^(L-1)"),
        ]:
            start = data.index(f'    "{technology}"')
            block = data[start:start + 900]
            self.assertIn(f'recipe = "{recipe}", change = 0.1', block)
            self.assertIn(f'"{count_formula}"', block)
            self.assertIn('{"bitermotors-dollar", 1}', block)
        solar_productivity = data[data.index('    "bitermotors-high-density-solar-productivity"'):data.index('    "bitermotors-grid-battery-productivity"')]
        self.assertIn('recipe = "bitermotors-high-density-solar-array-batch", change = 0.1', solar_productivity)
        self.assertIn("High-density Solar Panel recipe productivity: +10% per level", locale)
        self.assertIn("Grid Battery recipe productivity: +10% per level", locale)
        self.assertNotIn("bitermotors-solar-cell-productivity", data)
        self.assertIn("function station_stall_power_watts", control)
        self.assertIn("sink.power_usage = watts", control)
        self.assertIn("1 + battery_level * 0.05", control)
        self.assertIn("1 - battery_level * 0.08", control)
        self.assertIn("function accelerate_consumer_ev_sales", control)
        self.assertIn("function award_bitertaxi_audio_revenue", control)
        self.assertIn("1 + referral_level * 0.1", control)
        self.assertIn("continuous_improvements = function", control)

        self.assertIn("charging commutes", roadmap)
        self.assertIn("bounded representative", roadmap)

    def test_bitermotors_has_no_legacy_namespace(self):
        legacy_word = "front" + "ier"
        surfaces = [MOD, ROOT / "art" / "bitermotors-review"]
        files = [ROOT / "ROADMAP.md", ROOT / "scripts" / "install-bitermotors-mod.sh", ROOT / "scripts" / "validate-bitermotors-mod.sh"]
        for surface in surfaces:
            files.extend(path for path in surface.rglob("*") if path.is_file())

        for path in files:
            self.assertNotIn(legacy_word, path.name.lower(), path)
            if path.suffix.lower() in {".cfg", ".html", ".json", ".lua", ".md", ".sh"}:
                self.assertNotIn(legacy_word, path.read_text().lower(), path)

    def test_accelerated_start_is_light_optional_and_narrated(self):
        settings = (MOD / "settings.lua").read_text()
        control = (MOD / "control.lua").read_text()
        self.assertIn('setting_type = "startup"', settings)
        self.assertIn("default_value = true", settings)
        for technology in [
            "steam-power",
            "automation-science-pack",
            "steel-axe",
            "automation-2",
            "electric-mining-drill",
            "repair-pack",
            "military",
            "gun-turret",
            "radar",
            "heavy-armor",
            "stone-wall",
            "landfill",
            "circuit-network",
            "logistic-science-pack",
            "advanced-material-processing",
            "advanced-material-processing-2",
            "electric-energy-distribution-2",
            "oil-processing",
            "sulfur-processing",
            "plastics",
            "advanced-circuit",
            "fluid-handling",
            "lamp",
            "construction-robotics",
            "logistic-robotics",
            "modular-armor",
            "solar-panel-equipment",
            "battery-equipment",
            "night-vision-equipment",
            "personal-roboport-equipment",
        ]:
            self.assertIn(f'"{technology}"', control)
        self.assertIn('remote.call("freeplay", "set_ship_items"', control)
        self.assertIn('bitermotors_copy_table(BITERMOTORS_START_SHIP_ITEMS)', control)
        self.assertIn('remote.call("freeplay", "set_debris_items"', control)
        self.assertIn('remote.call("freeplay", "set_custom_intro_message"', control)
        self.assertIn("An advance landing party was supposed to prepare the site", control)
        self.assertIn("the crash destroyed much of its technical archive", control)
        self.assertIn("you possess machines that you cannot yet reproduce", control)
        self.assertIn("Restore red and green science as quickly as possible", control)
        self.assertIn("The Industrial Supply Chain recovers plans for Big Mining Drills", control)
        configure = control[control.index("function configure_bitermotors_new_game"):control.index("function grant_bitermotors_energy_jumpstart")]
        self.assertNotIn("surface.create_entity", configure)
        jumpstart = control[control.index("BITERMOTORS_ENERGY_JUMPSTART_ITEMS"):control.index("local STATION_GRID_CONNECTION_DISTANCE")]
        self.assertIn('["bitermotors-high-density-solar-array"] = 54', jumpstart)
        self.assertIn('["bitermotors-grid-battery"] = 24', jumpstart)
        self.assertIn('["substation"] = 40', jumpstart)
        self.assertIn('["roboport"] = 20', jumpstart)
        self.assertIn('["passive-provider-chest"] = 50', jumpstart)
        self.assertIn('["storage-chest"] = 25', jumpstart)
        self.assertIn('["construction-robot"] = 50', jumpstart)
        self.assertIn('["logistic-robot"] = 100', jumpstart)
        self.assertIn('["modular-armor"] = 1', jumpstart)
        self.assertIn('["personal-roboport-equipment"] = 1', jumpstart)
        self.assertIn('["battery-equipment"] = 2', jumpstart)
        self.assertIn('["solar-panel-equipment"] = 8', jumpstart)
        self.assertIn('["night-vision-equipment"] = 1', jumpstart)
        self.assertIn('["electric-furnace"] = 10', jumpstart)
        self.assertIn('["electric-mining-drill"] = 10', jumpstart)
        self.assertNotIn('["electric-furnace"] = 24', control)
        self.assertIn('["lamp"] = 50', control)
        self.assertIn('BITERMOTORS_ENERGY_JUMPSTART_QUALITY = "legendary"', control)
        self.assertIn('BITERMOTORS_ENERGY_JUMPSTART_NORMAL_QUALITY_ITEMS', jumpstart)
        self.assertIn('BITERMOTORS_ENERGY_JUMPSTART_NORMAL_QUALITY_ITEMS[item_name]', control)
        self.assertIn('and "normal"', control)
        self.assertIn('name = "passive-provider-chest"', control)
        self.assertIn('chest.backer_name = "Captain\'s Chest"', control)
        self.assertNotIn('player.force.add_chart_tag', control)
        self.assertIn('function seed_crash_site_salvage', control)
        self.assertIn('crash-site-spaceship-wreck-', control)
        self.assertIn('function award_small_crash_site_salvage', control)
        self.assertIn('stack = {name = "copper-plate", count = 5', control)
        self.assertIn("grant_bitermotors_energy_jumpstart(player)", control)
        self.assertIn("grant_energy_jumpstart = function(player_index)", control)
        self.assertIn('["bitermotors-high-density-solar-array"] = 54', control)

    def test_megatruck_and_ev_sales_are_balanced_as_profit(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        locale = (MOD / "locale/en/bitermotors.cfg").read_text()
        locale = (MOD / "locale/en/bitermotors.cfg").read_text()
        expected = {
            "bitermotors-prototype-roadster": 30,
            "bitermotors-premium-ev": 30,
            "bitermotors-premium-ev-cell-scale": 20,
            "bitermotors-mass-market-ev": 8,
            "bitermotors-megatruck": 15,
            "bitermotors-bitertaxi-fleet": 20,
        }
        for recipe_name, seconds in expected.items():
            start = data.index(f'recipe("{recipe_name}"')
            block = data[start:start + 700]
            self.assertIn(f'}}, {seconds}', block, recipe_name)
        megatruck = data[data.index('recipe("bitermotors-megatruck"'):data.index('recipe("bitermotors-high-density-solar-array"')]
        self.assertIn('name = "bitermotors-mass-market-ev", amount = 2', megatruck)
        self.assertIn('name = "steel-plate", amount = 20', megatruck)
        self.assertIn('name = "bitermotors-high-energy-battery-pack", amount = 4', megatruck)
        self.assertNotIn("low-density-structure", megatruck)
        self.assertNotIn("processing-unit", megatruck)
        megatruck_sale = data[data.index('recipe("bitermotors-sell-megatruck"'):data.index('recipe("bitermotors-sell-grid-battery"')]
        self.assertIn('name = "bitermotors-dollar", amount = 2', megatruck_sale)
        self.assertIn('name = "bitermotors-ev-reservation", amount = 1', megatruck_sale)
        self.assertIn("}}, 10", megatruck_sale)
        self.assertIn("bitermotors-megatruck=Megatruck", locale)
        self.assertIn("bitermotors-sell-megatruck=Sell Megatruck", locale)
        megatruck_tech = data[data.index('tech("bitermotors-megatruck-engineering"'):data.index('tech("bitermotors-ev-charging-network"')]
        self.assertIn('{"bitermotors-capital-scaling", "tank"}', megatruck_tech)
        self.assertIn('unlock("bitermotors-megatruck")', megatruck_tech)
        self.assertIn('unlock("bitermotors-sell-megatruck")', megatruck_tech)
        capital_tech = data[data.index('tech("bitermotors-capital-scaling"'):data.index('tech("bitermotors-megatruck-engineering"')]
        self.assertNotIn('unlock("bitermotors-megatruck")', capital_tech)
        self.assertIn('technology = "bitermotors-megatruck-engineering"', control)
        self.assertIn('Research Megatruck Engineering.', control)
        self.assertIn("Megatruck", locale)
        self.assertIn("Dollars of profit", locale)

    def test_bitermotors_evs_are_drivable_and_charge_from_powered_stalls(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        locale = (MOD / "locale/en/bitermotors.cfg").read_text()
        self.assertIn("local function copied_electric_vehicle", data)
        self.assertIn('profile.equipment_grid or "medium-equipment-grid"', data)
        self.assertIn('fuel_categories = {"bitermotors-electric-drive"}', data)
        self.assertIn('fuel_value = "1MJ"', data)
        for name in ["bitermotors-prototype-roadster", "bitermotors-premium-ev", "bitermotors-mass-market-ev", "bitermotors-megatruck", "bitermotors-bitertaxi-fleet"]:
            item_start = data.index(f'item("{name}"')
            self.assertIn(f'place_result = "{name}"', data[item_start:item_start + 300])
            self.assertIn(f'"{name}"', control[control.index("ELECTRIC_VEHICLE_BATTERIES ="):control.index("ELECTRIC_DRIVE_FUEL_NAME =")])
        self.assertIn("install_vehicle_batteries", control)
        self.assertIn("entity.grid.take{equipment = existing[index]}", control)
        self.assertIn("install_vehicle_batteries(entity, charge_new_batteries)", control)
        self.assertIn("equipment.energy = equipment.max_energy", control)
        self.assertIn("track_electric_vehicle(entity, true)", control)
        self.assertIn("track_electric_vehicle(entity, false)", control)
        self.assertIn("feed_electric_drive_from_batteries", control)
        self.assertIn("nearby_uncharged_vehicles", control)
        self.assertIn("charge_station_vehicles(station)", control)
        self.assertIn("capacity * 0.03", control)
        self.assertIn("event.buffer.get_item_count(ELECTRIC_DRIVE_FUEL_NAME)", control)
        self.assertIn("if hidden_charge_count > 0 then", control)
        self.assertIn("braking_multiplier = 8.0", data)
        self.assertIn("customer_requested_stalls", control)
        self.assertIn('label = "Commutes"', control)
        self.assertIn('filename = "__bitermotors__/graphics/entity/vehicles/" .. profile.artwork .. ".png"', data)
        self.assertIn("direction_count = 64", data)
        self.assertIn("line_length = 8", data)
        self.assertIn("prototype.turret_animation = nil", data)
        self.assertIn("prototype.light_animation = nil", data)
        self.assertIn('profile.artwork .. "-shadow.png"', data)
        self.assertIn("draw_as_shadow = true", data)
        for artwork in ["prototype-roadster", "premium-ev", "mass-market-ev", "megatruck", "bitertaxi-fleet"]:
            self.assertTrue((MOD / f"graphics/entity/vehicles/{artwork}-shadow.png").exists())
        self.assertIn("bitermotors-electric-drive=Electric drive", locale)
        self.assertIn("bitermotors-electric-drive-charge=Stored battery charge", locale)
        self.assertIn("no manually inserted fuel is required", locale)
        self.assertIn("begins with a full battery", locale)
        for artwork in ["prototype-roadster", "premium-ev", "mass-market-ev", "megatruck", "bitertaxi-fleet"]:
            self.assertIn(f'artwork = "{artwork}"', data)
            sheet = MOD / f"graphics/entity/vehicles/{artwork}.png"
            self.assertTrue(sheet.exists())
            with Image.open(sheet) as image:
                self.assertEqual(image.size, (1536, 1536))
                self.assertEqual(image.mode, "RGBA")
        for fragment in [
            '{consumption = "600kW", weight = 450, max_health = 240',
            '{consumption = "540kW", weight = 750, max_health = 550',
            '{consumption = "240kW", weight = 800, max_health = 500',
            '{consumption = "600kW", weight = 1800, max_health = 1400',
            '{consumption = "270kW", weight = 850, max_health = 650',
            'equipment_grid = "large-equipment-grid"',
            '{type = "impact", decrease = 150, percent = 70}',
        ]:
            self.assertIn(fragment, data)
        for braking in ["8.0", "6.4", "5.5", "4.5", "6.0"]:
            self.assertIn(f"braking_multiplier = {braking}", data)
        self.assertEqual(540 / 1.8, 0.8 * (600 / 1.6))
        vehicle_table = data.index("local electric_vehicles")
        roadster = data[data.index('"bitermotors-prototype-roadster", generated_icon("prototype-roadster")', vehicle_table):
                        data.index('"bitermotors-premium-ev", generated_icon("premium-ev")', vehicle_table)]
        self.assertIn('{type = "impact", percent = -50}', roadster)
        for name, batteries in {
            "bitermotors-prototype-roadster": 1,
            "bitermotors-premium-ev": 2,
            "bitermotors-mass-market-ev": 1,
            "bitermotors-megatruck": 4,
            "bitermotors-bitertaxi-fleet": 2,
        }.items():
            self.assertIn(f'["{name}"] = {batteries}', control)

    def test_empty_customer_settlements_seed_initial_mobile_buyer(self):
        control = (MOD / "control.lua").read_text()

        self.assertIn("function ensure_seed_customer(settlement, market_force)", control)
        self.assertIn('settlement.name == "spitter-spawner" and "small-spitter" or "small-biter"', control)
        self.assertIn('mark_bitermotors_market_dirty(market_force, "settlement-seed-customer")', control)
        self.assertIn("ensure_seed_customer(settlement, force)", control)
        self.assertIn("if population_size > 0 then", control)

    def test_existing_mobile_enemies_convert_across_charger_service_area(self):
        control = (MOD / "control.lua").read_text()

        self.assertIn("function convert_station_area_customers(market_force, service)", control)
        self.assertIn("area_around(station.position, config.customer_radius)", control)
        self.assertIn('if entity.type == "unit"', control)
        self.assertIn("position_has_sales_coverage(entity.surface, entity.position, offices)", control)
        self.assertIn("converted = converted + convert_station_area_customers(force, service)", control)

    def test_sales_follow_covered_home_settlements_not_wandering_unit_positions(self):
        control = (MOD / "control.lua").read_text()

        self.assertIn("local settlement_in_office_coverage = population", control)
        self.assertIn("population.surface_index == office.surface.index", control)
        self.assertIn("within_radius(office, {position = population.position}, SALES_OFFICE_CUSTOMER_RADIUS)", control)
        dequeue = control[control.index("function dequeue_available_buyer"):control.index("function eligible_customer_buyers")]
        self.assertNotIn("within_radius(office, entity", dequeue)
        self.assertIn("function sales_office_buyer_status(office)", control)
        self.assertIn('label = "Prospects"', control)
        self.assertIn("every remaining prospect is reserved by a sale already in progress", control)
        self.assertIn("function rebuild_customer_settlement_population_cache()", control)
        self.assertIn("function ensure_customer_settlement_population_cache()", control)
        self.assertIn("ensure_customer_settlement_population_cache()", control)
        self.assertIn("rebuild_customer_vehicle_aggregates()", control)
        self.assertIn("rebuild_customer_buyer_queues()", control)
        self.assertIn("buyer_queue_self_repairs", control)
        self.assertIn("script.register_on_object_destroyed(entity)", control)
        self.assertIn("defines.events.on_object_destroyed", control)
        self.assertIn("unregister_customer_unit_number(event.useful_id)", control)
        self.assertIn("customer_population_records = population_records", control)
        self.assertIn("repair_customer_populations = function()", control)
        self.assertIn("sales_office_status = function(force_name)", control)
        self.assertIn("sync_sales_offices = function()", control)
        self.assertNotIn("function rehome_customer_buyer", control)
        self.assertNotIn("function dequeue_rehomed_buyer", control)
        self.assertNotIn("dequeue_rehomed_buyer(office, pool.key)", control)
        eligible = control[control.index("function eligible_customer_buyers"):
                           control.index("function sales_office_buyer_status")]
        self.assertIn("dequeue_available_buyer(pool.queue, office, pool.key, sale.item)", eligible)
        self.assertIn("customer_virtual_purchase_capacity(population, sale.item)", eligible)

    def test_ev_drivers_see_charge_zones_and_live_charging_indicator(self):
        control = (MOD / "control.lua").read_text()

        self.assertIn("function refresh_ev_driver_overlays()", control)
        self.assertIn("local vehicle = player.vehicle", control)
        self.assertIn("config.vehicle_charge_radius", control)
        self.assertIn("vehicle_charge_radius = 8", control)
        self.assertEqual(3, control.count("vehicle_charge_radius = 10"))
        self.assertIn("dx * dx + dy * dy <= 256 * 256", control)
        self.assertIn('sprite = "item/bitermotors-electric-drive-charge"', control)
        self.assertIn("state.charge_text = rendering.draw_text", control)
        self.assertIn('state.charge_text.text = string.format("BATTERY %d%%", percent)', control)
        self.assertIn("local stationary = math.abs(vehicle.speed or 0) <= 0.005", control)
        self.assertIn("state.charge_text.visible = charging and stationary", control)
        self.assertIn("storage.bitermotors_vehicle_charge_activity[vehicle.unit_number] = game.tick", control)
        self.assertIn("refresh_ev_driver_overlays()", control)
        self.assertIn("defines.events.on_player_driving_changed_state", control)
        self.assertIn("state.market_generation ~= (bitermotors_market_generation()[vehicle.force.index] or 0)", control)
        self.assertIn("destroy_ev_driver_overlay(event.player_index)", control)

    def test_ev_exit_shows_a_two_second_battery_popup_without_driving_label(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn("EV_BATTERY_POPUP_TICKS = 2 * 60", control)
        self.assertIn("EV_BATTERY_POPUP_FADE_TICKS = 60", control)
        self.assertIn("function show_ev_battery_popup(player, vehicle)", control)
        self.assertIn("function vehicle_total_charge_energy(entity)", control)
        self.assertIn("entity.burner.remaining_burning_fuel", control)
        self.assertIn("inventory.get_item_count(ELECTRIC_DRIVE_FUEL_NAME)", control)
        self.assertIn('text = string.format("BATTERY %d%%", percent)', control)
        self.assertIn("players = {player}", control)
        self.assertIn("local prior_vehicle = prior_state and prior_state.vehicle", control)
        self.assertIn("if vehicle then\n    destroy_ev_battery_popup(player.index)", control)
        self.assertIn("else\n    show_ev_battery_popup(player, prior_vehicle)", control)
        self.assertIn("local alpha = math.min(1, remaining / EV_BATTERY_POPUP_FADE_TICKS)", control)
        self.assertIn("script.on_nth_tick(6, update_ev_battery_popups)", control)

    def test_quality_scales_physical_assets_not_abstract_outputs(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        self.assertIn("station.quality and station.quality.level", control)
        self.assertIn("1 + quality_level * 0.1", control)
        self.assertIn("ELECTRIC_VEHICLE_BATTERIES[entity.name] + math.floor(quality_level / 2)", control)
        for recipe_name in [
            "bitermotors-sell-prototype-roadster",
            "bitermotors-sell-megatruck",
            "bitermotors-terrestrial-ai-token",
            "bitermotors-orbital-ai-token",
            "bitermotors-agi-training-run",
        ]:
            self.assertIn(f'"{recipe_name}"', data[data.index("for _, recipe_name in pairs({", data.index("allow_productivity = false")):])
        self.assertIn("data.raw.recipe[recipe_name].allow_quality = false", data)

    def test_sales_office_uses_distinct_test_art(self):
        data = (MOD / "data.lua").read_text()
        self.assertIn("__bitermotors__/graphics/icons/sales-office.png", data)
        self.assertIn("__bitermotors__/graphics/entity/sales-office/sales-office.png", data)
        self.assertIn("sales_office.graphics_set", data)
        self.assertTrue((MOD / "graphics/icons/sales-office.png").exists())
        self.assertTrue((MOD / "graphics/entity/sales-office/sales-office.png").exists())

    def test_bitermotors_selected_art_is_wired_for_playtest_prototypes(self):
        data = (MOD / "data.lua").read_text()
        for slug in [
            "ev-charging-station",
            "ev-charging-station-v2",
            "ev-charging-station-v3",
            "ev-charging-station-v4",
            "terrestrial-datacenter",
            "orbital-datacenter-core",
            "ev-reservation",
            "biterfactory-module",
            "ai-token",
            "prototype-roadster",
            "premium-ev",
            "mass-market-ev",
            "bitertaxi-fleet",
            "datacenter-rack",
            "structural-casting",
            "agi-model",
            "planetary-grid-controller",
            "bitertaxi-depot",
        ]:
            self.assertIn(f'generated_icon("{slug}")', data)
            icon_path = MOD / f"graphics/icons/{slug}.png"
            self.assertTrue(icon_path.exists())
            with Image.open(icon_path) as image:
                alpha = image.convert("RGBA").getchannel("A")
                self.assertEqual(alpha.getpixel((0, 0)), 0)
                self.assertGreater(alpha.histogram()[0], image.width * image.height * 0.1)
        group_icon = MOD / "graphics/icons/bitermotors-group.png"
        self.assertTrue(group_icon.exists())
        self.assertIn("__bitermotors__/graphics/icons/bitermotors-group.png", data)
        progress_shortcut = data[
            data.index('name = "bitermotors-open-progress"') - 40:
            data.index('name = "bitermotors-toggle-sales-office-coverage"')
        ]
        self.assertNotIn('type = "item-group"', data)
        self.assertNotIn("rocket-silo.png", progress_shortcut)
        self.assertIn("icon_size = 256", progress_shortcut)
        with Image.open(group_icon) as image:
            self.assertEqual(image.size, (256, 256))
            self.assertEqual(image.mode, "RGB")
        with Image.open(MOD / "thumbnail.png") as image:
            self.assertEqual(image.size, (144, 144))
            self.assertEqual(image.mode, "RGB")
        for slug in ["bitertaxi-depot", "planetary-grid-controller"]:
            entity_path = MOD / f"graphics/entity/{slug}/{slug}.png"
            self.assertTrue(entity_path.exists())
            with Image.open(entity_path) as image:
                self.assertEqual(image.size, (512, 512))
                self.assertEqual(image.mode, "RGBA")
                self.assertEqual(image.getpixel((0, 0))[3], 0)
        self.assertIn('generated_entity_picture("ev-charging-station", nil, 0.14)', data)
        self.assertIn('generated_entity_picture("ev-charging-station-v2", nil, 0.26)', data)
        self.assertIn('generated_entity_picture("ev-charging-station-v3", nil, 0.35)', data)
        self.assertIn('generated_entity_picture("ev-charging-station-v4", nil, 0.38)', data)
        self.assertIn("customer_radius_visualisation(64)", data)
        self.assertIn("customer_radius_visualisation(128)", data)
        self.assertIn("radius_visualisation_specification", data)
        self.assertIn("draw_in_cursor = true", data)
        self.assertIn("draw_on_selection = true", data)
        self.assertIn("tint = {r = 0.18, g = 0.48, b = 0.24, a = 0.16}", data)
        self.assertNotIn("tint = {r = 0.25, g = 0.85, b = 1.0, a = 0.35}", data)
        self.assertIn('generated_entity_animation("terrestrial-datacenter", 0.36, {', data)
        self.assertIn('generated_entity_animation("orbital-datacenter-core", 0.36)', data)
        self.assertIn('orbital_radiator_panel_icon = layered_icon64(', data)
        self.assertIn('high_density_space_solar_panel_icon = layered_icon64(', data)
        for slug in [
            "ev-charging-station",
            "ev-charging-station-v2",
            "ev-charging-station-v3",
            "ev-charging-station-v4",
            "terrestrial-datacenter",
            "orbital-datacenter-core",
        ]:
            entity_path = MOD / f"graphics/entity/{slug}/{slug}.png"
            self.assertTrue(entity_path.exists())
            with Image.open(entity_path) as image:
                alpha = image.convert("RGBA").getchannel("A")
                self.assertEqual(alpha.getpixel((0, 0)), 0)
                self.assertGreater(alpha.histogram()[0], image.width * image.height * 0.1)
                if slug.startswith("ev-charging-station"):
                    self.assertEqual(image.size, (512, 512))
                    left, top, right, bottom = alpha.getbbox()
                    self.assertGreaterEqual(right - left, image.width * 0.84)
                    self.assertGreaterEqual(bottom - top, image.height * 0.84)
                    self.assertAlmostEqual((left + right) / 2, image.width / 2, delta=image.width * 0.05)
                    self.assertAlmostEqual((top + bottom) / 2, image.height / 2, delta=image.height * 0.05)
                if slug == "terrestrial-datacenter":
                    self.assertEqual(image.size, (512, 512))
                    left, top, right, bottom = alpha.getbbox()
                    self.assertGreaterEqual(right - left, image.width * 0.84)
                    self.assertGreaterEqual(bottom - top, image.height * 0.96)
                    self.assertAlmostEqual((left + right) / 2, image.width / 2, delta=image.width * 0.03)
                    self.assertAlmostEqual((top + bottom) / 2, image.height / 2, delta=image.height * 0.03)

    def test_bitermotors_free_art_pipeline_is_wired_and_reviewable(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        animation_sizes = {
            "sales-office-status-green.png": (512, 64),
            "sales-office-status-amber.png": (512, 64),
            "sales-office-status-red.png": (512, 64),
            "sales-office-showroom-prototype-roadster.png": (4096, 512),
            "sales-office-showroom-premium-ev.png": (4096, 512),
            "sales-office-showroom-mass-market-ev.png": (4096, 512),
            "sales-office-showroom-megatruck.png": (4096, 512),
            "charger-stall-idle.png": (256, 32),
            "charger-stall-low.png": (256, 32),
            "charger-stall-medium.png": (256, 32),
            "charger-stall-full.png": (256, 32),
            "charger-stall-overload.png": (256, 32),
            "charger-stall-charging.png": (256, 32),
            "biterfactory-v1-activity.png": (4096, 512),
            "biterfactory-v2-activity.png": (4096, 512),
            "biterfactory-loading-lights.png": (4096, 128),
            "datacenter-cooling-fans.png": (1024, 64),
            "bitertaxi-dispatch-lights.png": (1024, 64),
            "grid-charge-stages.png": (1024, 128),
        }
        for filename, expected_size in animation_sizes.items():
            path = MOD / "graphics/animation" / filename
            self.assertTrue(path.exists(), filename)
            with Image.open(path) as image:
                self.assertEqual(image.size, expected_size)
                self.assertEqual(image.mode, "RGBA")
                self.assertGreater(image.getchannel("A").getbbox()[2], 0)

                frame_width = expected_size[0] // 8
                first = image.crop((0, 0, frame_width, expected_size[1]))
                fourth = image.crop((frame_width * 3, 0, frame_width * 4, expected_size[1]))
                if filename not in {"charger-stall-idle.png"}:
                    channels = ImageChops.difference(first, fourth).split()
                    changed = channels[0]
                    for channel in channels[1:]:
                        changed = ImageChops.lighter(changed, channel)
                    changed_pixels = changed.point(lambda value: 255 if value else 0).histogram()[255]
                    self.assertGreater(changed_pixels, 20, filename)

        for technology in [
            "sales-office",
            "ev-charging-network",
            "biterfactory",
            "terrestrial-ai",
            "autonomous-logistics",
            "planetary-energy-grid",
            "achieving-agi",
        ]:
            path = MOD / "graphics/technology" / f"{technology}.png"
            self.assertTrue(path.exists(), technology)
            with Image.open(path) as image:
                self.assertEqual(image.size, (256, 256))

        self.assertIn('"__bitermotors__/graphics/technology/bitermotors-tech-badge.png"', data)
        for clean_subject in [
            "sales-office",
            "ev-charging-station-v2",
            "terrestrial-datacenter",
            "bitertaxi-depot",
            "planetary-grid-controller",
        ]:
            self.assertIn(f'"__bitermotors__/graphics/icons/{clean_subject}.png"', data)

        self.assertIn('working_animation(activity_slug, 512, 512, 0.325', data)
        self.assertIn('working_animation("biterfactory-loading-lights", 512, 128, 0.325', data)
        self.assertIn('tier == 2 and "biterfactory-v2-activity" or "biterfactory-v1-activity"', data)
        self.assertIn('working_animation("datacenter-cooling-fans"', data)
        self.assertIn('working_animation("grid-charge-stages"', data)
        self.assertIn('rendering.draw_sprite{', control)
        self.assertIn("function update_charger_stall_visuals(force_refresh)", control)
        self.assertIn('scale = 0.75', control)
        self.assertIn('scale = 0.78', control)
        self.assertIn('object.sprite = "bitermotors-charger-stall-" .. state .. "-frame-" .. staggered_frame', control)
        self.assertIn('sprite_prefix = "bitermotors-bitertaxi-dispatch-lights-frame-"', control)
        self.assertIn("entry.object.sprite = entry.sprite_prefix .. frame_index", control)
        self.assertIn("update_bitermotors_runtime_visuals()", control)

        qa = ROOT / "art/bitermotors-qa/index.html"
        manifest = json.loads((qa.parent / "art-manifest.json").read_text())
        page = qa.read_text()
        self.assertTrue(qa.exists())
        self.assertEqual(manifest["paid_generation_count"], 3)
        self.assertIn("Biter Motors Artwork QA", page)
        self.assertIn("Directional vehicle production math", page)
        self.assertIn("data-filter=\"animations\"", page)
        self.assertGreaterEqual(page.count('class="asset '), 50)

    def test_charger_stall_visuals_are_bounded_and_explain_utilization(self):
        control = (MOD / "control.lua").read_text()
        data = (MOD / "data.lua").read_text()
        self.assertIn("CHARGER_STALL_VISUAL_LAYOUTS", control)
        self.assertIn("for stall_index = 1, config.stalls do", control)
        self.assertIn("assignment.stall_loads[stall_index]", control)
        self.assertIn("customer_commute_station_counts()", control)
        self.assertIn("local refresh_states = force_refresh == true or game.tick % 120 == 0", control)
        self.assertIn("local state = entry.states[stall_index] or \"idle\"", control)
        for state in ["idle", "low", "medium", "full", "overload", "charging"]:
            self.assertIn(f'{{state = "{state}"', data)
            self.assertIn(f'return "{state}"', control)
        self.assertNotIn('sprite_prefix = "bitermotors-charger-status-lights-frame-"', control)

    def test_sales_office_starts_with_showroom_and_charger(self):
        data = (MOD / "data.lua").read_text()
        sales_tech = data[data.index('tech("bitermotors-sales-office"'):data.index('tech("bitermotors-premium-ev-program"')]
        premium_tech = data[data.index('tech("bitermotors-premium-ev-program"'):data.index('tech("bitermotors-advanced-battery-chemistry"')]
        battery_tech = data[data.index('tech("bitermotors-advanced-battery-chemistry"'):data.index('tech("bitermotors-capital-scaling"')]
        prototype_recipe = data[data.index('recipe("bitermotors-prototype-roadster"'):data.index('recipe("bitermotors-premium-ev"')]
        first_sale_recipe = data[data.index('recipe("bitermotors-sell-prototype-roadster"'):data.index('recipe("bitermotors-sell-premium-ev"')]
        self.assertIn('unlock("bitermotors-sales-office")', sales_tech)
        self.assertIn('{"automobilism", "electric-engine", "chemical-science-pack"}', sales_tech)
        self.assertIn('{"chemical-science-pack", 1}', sales_tech)
        self.assertIn('unlock("bitermotors-ev-charging-station")', sales_tech)
        self.assertIn('unlock("bitermotors-sell-prototype-roadster")', sales_tech)
        self.assertNotIn('unlock("bitermotors-prototype-roadster")', sales_tech)
        self.assertNotIn('unlock("bitermotors-sell-prototype-roadster")', premium_tech)
        self.assertIn('{"bitermotors-dollar", 1}', premium_tech)
        self.assertIn('    250,', premium_tech)
        self.assertNotIn('unlock("bitermotors-biterfactory-module")', premium_tech)
        self.assertNotIn('unlock("bitermotors-biterfactory-building")', premium_tech)
        self.assertNotIn('unlock("bitermotors-dirty-nickel-refining")', premium_tech)
        self.assertNotIn('unlock("bitermotors-lithium-extraction")', premium_tech)
        self.assertIn('unlock("bitermotors-dirty-nickel-refining")', battery_tech)
        self.assertIn("    300,", battery_tech)
        self.assertIn('unlock("bitermotors-lithium-extraction")', battery_tech)
        self.assertIn('unlock("bitermotors-high-nickel-cell")', battery_tech)
        self.assertIn('unlock("bitermotors-high-energy-battery-pack")', battery_tech)
        self.assertIn('unlock("bitermotors-premium-ev-cell-scale")', battery_tech)
        self.assertIn('{enabled = false}', battery_tech)
        self.assertIn('{{type = "item", name = "bitermotors-dollar", amount = 2}}, 60', first_sale_recipe)
        self.assertIn('name = "bitermotors-ev-reservation", amount = 1', first_sale_recipe)
        self.assertIn('"car"', prototype_recipe)
        self.assertIn('"battery"', prototype_recipe)
        self.assertIn('"advanced-circuit"', prototype_recipe)
        self.assertNotIn('"bitermotors-battery-pack"', prototype_recipe)
        self.assertNotIn('"bitermotors-electric-drivetrain"', prototype_recipe)

    def test_premium_ev_loop_is_concrete_and_guided(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        battery_recipe = data[data.index('recipe("bitermotors-high-energy-battery-pack"'):data.index('recipe("bitermotors-clean-nickel-refining"')]
        drivetrain_recipe = data[data.index('recipe("bitermotors-electric-drivetrain"'):data.index('recipe("bitermotors-prototype-roadster"')]
        premium_ev_recipe = data[data.index('recipe("bitermotors-premium-ev"'):data.index('recipe("bitermotors-premium-ev-cell-scale"')]
        cell_scale_premium_ev_recipe = data[data.index('recipe("bitermotors-premium-ev-cell-scale"'):data.index('recipe("bitermotors-mass-market-ev"')]
        premium_sale_recipe = data[data.index('recipe("bitermotors-sell-premium-ev"'):data.index('recipe("bitermotors-sell-mass-market-ev"')]

        self.assertIn('{"advanced-crafting", "bitermotors-vertical-integration"}', battery_recipe)
        self.assertNotIn('"accumulator"', battery_recipe)
        self.assertIn('name = "bitermotors-high-nickel-cell", amount = 4', battery_recipe)
        self.assertIn('name = "steel-plate", amount = 4', battery_recipe)
        self.assertIn('name = "advanced-circuit", amount = 2', battery_recipe)
        cell_scale_recipe = data[
            data.index('recipe("bitermotors-cell-scale-high-nickel"'):
            data.index('recipe("bitermotors-lfp-cell"')
        ]
        self.assertIn('name = "bitermotors-cobalt-concentrate", amount = 1', cell_scale_recipe)
        self.assertIn('{"advanced-crafting"}', drivetrain_recipe)
        self.assertIn('"electric-engine-unit"', drivetrain_recipe)
        self.assertIn('"advanced-circuit"', drivetrain_recipe)
        self.assertIn('"copper-cable"', drivetrain_recipe)
        self.assertNotIn('"iron-gear-wheel"', drivetrain_recipe)
        self.assertNotIn('"steel-plate"', drivetrain_recipe)
        self.assertIn('name = "bitermotors-ev-reservation", amount = 1', premium_sale_recipe)
        self.assertIn('"car"', premium_ev_recipe)
        self.assertIn('name = "battery", amount = 48', premium_ev_recipe)
        self.assertIn('"bitermotors-electric-drivetrain"', premium_ev_recipe)
        self.assertNotIn('"bitermotors-high-energy-battery-pack"', premium_ev_recipe)
        self.assertNotIn('"plastic-bar"', premium_ev_recipe)
        self.assertNotIn('"steel-plate"', premium_ev_recipe)
        self.assertIn('{"advanced-crafting", "bitermotors-vehicle-assembly"}', premium_ev_recipe)
        self.assertIn('"bitermotors-high-energy-battery-pack"', cell_scale_premium_ev_recipe)
        self.assertIn('"bitermotors-electric-drivetrain"', cell_scale_premium_ev_recipe)
        self.assertIn('name = "bitermotors-premium-ev", amount = 1', cell_scale_premium_ev_recipe)
        self.assertIn('{"advanced-crafting", "bitermotors-vehicle-assembly"}', cell_scale_premium_ev_recipe)
        self.assertIn('{{type = "item", name = "bitermotors-dollar", amount = 1}}, 30', premium_sale_recipe)
        self.assertIn('"bitermotors-sell-premium-ev"', control)
        self.assertIn("EV Production Line researched. Premium EV tooling is ready after 50 completed Prototype Roadster sales", control)
        self.assertIn("Energy Products researched. Upgrade conventional solar fields with High-density Solar Panels", control)
        self.assertIn("PREMIUM_PILOT_PRODUCTION_GATE = 100", control)
        self.assertIn("ADVANCED_BATTERY_CHEMISTRY_PRODUCTION_GATE = 250", control)
        self.assertIn("function sync_advanced_battery_chemistry_gate", control)
        self.assertIn("Commodity battery supply has reached its scale limit after %d Premium EVs", control)
        chemistry_gate = control[
            control.index("function sync_advanced_battery_chemistry_gate"):
            control.index("function sync_biterfactory_production_gate")
        ]
        self.assertIn("ADVANCED_BATTERY_CHEMISTRY_RECIPES", chemistry_gate)
        self.assertIn("recipe.enabled = technology.researched", chemistry_gate)
        self.assertIn("function sync_biterfactory_production_gate", control)
        gate = control[
            control.index("function sync_biterfactory_production_gate"):
            control.index("function customer_ev_fleet_size")
        ]
        self.assertIn('count_item_produced(force, PREMIUM_EV_NAME)', gate)
        self.assertIn('researched(force, "bitermotors-premium-ev-program")', gate)
        self.assertNotIn("researched(force, ADVANCED_BATTERY_CHEMISTRY_TECH_NAME)", gate)
        self.assertNotIn('and researched(force, "foundry")', gate)
        self.assertIn('"bitermotors-biterfactory-module", "bitermotors-biterfactory-building"', gate)
        self.assertIn('solar_batch_recipe.enabled = unlocked and researched(force, "bitermotors-energy-products")', gate)
        self.assertNotIn('"bitermotors-cell-scale-high-nickel"', gate)
        self.assertIn("Premium pilot proven: %d Premium EVs produced. Biterfactory construction is now available", control)
        self.assertIn("sync_biterfactory_production_gate(force, true)", control)
        self.assertIn('"Premium pilot production"', control)
        self.assertIn('"Biterfactory scale"', control)
        self.assertIn("snapshot.premium_pilot_production_gate", control)
        self.assertIn("snapshot.advanced_battery_chemistry_production_gate", control)
        self.assertIn("Premium EV sales are working. Build 100 pilot vehicles to unlock the Biterfactory", control)
        self.assertIn("bitermotors_first_premium_ev_sales", control)

    def test_progress_panel_makes_charging_power_and_customer_impact_prominent(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn("requested_customer_stalls", control)
        self.assertIn("powered_customer_stalls", control)
        self.assertIn("charging_power_demand_kw", control)
        self.assertIn("charging_power_served_kw", control)
        self.assertIn('add_progress_section(content, "Grid power", grid_rows)', control)
        self.assertIn('label = "EV grid load"', control)
        self.assertIn('label = "Charging stalls"', control)
        self.assertIn('label = "Powered capacity"', control)
        self.assertIn('"%d EVs; %d spare"', control)
        self.assertIn('label = "EV owners"', control)
        self.assertIn("next_customer_charging_step", control)
        self.assertIn("next_charging_step = next_charging_step", control)
        self.assertIn('label = "Next charger activation"', control)
        self.assertNotIn('label = "Next load step"', control)
        self.assertNotIn('label = "Next grid load"', control)
        self.assertIn('"%d EV sale%s: +%.0f kW"', control)
        self.assertIn('"No spare stalls; add charger"', control)
        self.assertIn('"Research Energy Products for industrial expansion."', control)
        self.assertIn('"Prove a 5 MW solar industrial block."', control)
        self.assertIn('"Research Metallurgical Scaling."', control)
        objective = control[
            control.index("local function current_progress_objective"):
            control.index("function progress_objective_icon")
        ]
        self.assertLess(
            objective.index('elseif not snapshot.energy_products_researched then'),
            objective.index('elseif snapshot.foundry_power_gate and not snapshot.foundry_power_gate.qualified then'),
        )
        self.assertLess(
            objective.index('elseif snapshot.premium_evs_produced < snapshot.premium_pilot_production_gate then'),
            objective.index('elseif snapshot.biterfactories == 0 and snapshot.biterfactories_v2 == 0 then'),
        )
        self.assertLess(
            objective.index('elseif snapshot.biterfactories == 0 and snapshot.biterfactories_v2 == 0 then'),
            objective.index('elseif snapshot.premium_evs_produced < snapshot.advanced_battery_chemistry_production_gate then'),
        )
        self.assertLess(
            objective.index('elseif snapshot.premium_evs_produced < snapshot.advanced_battery_chemistry_production_gate then'),
            objective.index('elseif not snapshot.advanced_battery_chemistry_researched then'),
        )
        self.assertLess(
            objective.index('elseif not snapshot.advanced_battery_chemistry_researched then'),
            objective.index('elseif not snapshot.energy_products_researched then'),
        )

    def test_progress_panel_rows_have_actionable_full_row_tooltips(self):
        control = (MOD / "control.lua").read_text()
        metrics = control[
            control.index("function add_progress_metrics"):
            control.index("function add_progress_section")
        ]
        self.assertIn('local tooltip = (row.tooltip or', metrics)
        self.assertIn('tooltip = tooltip}', metrics)
        self.assertIn('caption = row.label, tooltip = tooltip', metrics)
        self.assertIn('caption = row.value, tooltip = tooltip', metrics)
        self.assertIn('"Red: action is required."', metrics)
        self.assertIn('"Orange: prepare or keep progressing."', metrics)
        self.assertIn('"Green: healthy or complete."', metrics)
        self.assertIn("No action is required while EV grid load and Powered capacity remain green", control)
        self.assertIn("Place another powered charger there before selling more EVs.", control)
        self.assertIn("Follow the red settlement map tags", control)

    def test_tier_two_modules_are_terrestrial_capital_research(self):
        updates = (MOD / "data-updates.lua").read_text()
        module_rewrite = updates[
            updates.index("-- Tier 2 modules are terrestrial Biter Motors capital investments"):
            updates.index("-- Sparse calcite")
        ]

        for technology_name in [
            "speed-module-2",
            "productivity-module-2",
            "efficiency-module-2",
            "quality-module-2",
        ]:
            self.assertIn(f'"{technology_name}"', module_rewrite)
        self.assertIn('prerequisite ~= "space-science-pack"', module_rewrite)
        self.assertIn('prerequisites[#prerequisites + 1] = "bitermotors-sales-office"', module_rewrite)
        self.assertIn('ingredient_name == "space-science-pack"', module_rewrite)
        self.assertIn('{"bitermotors-dollar", ingredient.amount or ingredient[2] or 1}', module_rewrite)
        self.assertIn("mark_bitermotors_technology(technology, technology.icon)", module_rewrite)

    def test_sales_recipes_show_the_product_with_a_coin_badge(self):
        data = (MOD / "data.lua").read_text()
        self.assertIn("local function sale_icon(product_icons)", data)
        self.assertIn('icon = "__base__/graphics/icons/coin.png"', data)
        expected_icons = {
            "bitermotors-sell-prototype-roadster": 'sale_icon(generated_icon("prototype-roadster"))',
            "bitermotors-sell-premium-ev": 'sale_icon(generated_icon("premium-ev"))',
            "bitermotors-sell-mass-market-ev": 'sale_icon(generated_icon("mass-market-ev"))',
            "bitermotors-sell-grid-battery": "sale_icon(grid_battery_icon)",
            "bitermotors-sell-bitertaxi-fleet": 'sale_icon(generated_icon("bitertaxi-fleet"))',
        }
        for recipe_name, expected_icon in expected_icons.items():
            start = data.index(f'recipe("{recipe_name}"')
            block = data[start:start + 650]
            self.assertIn(f"icons = {expected_icon}", block)

    def test_terrestrial_ai_and_bitertaxi_form_a_complete_pre_space_loop(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        locale = (MOD / "locale/en/bitermotors.cfg").read_text()

        terrestrial_tech = data[
            data.index('tech("bitermotors-terrestrial-ai"'):
            data.index('tech("bitermotors-orbital-compute"')
        ]
        autonomous_tech = data[
            data.index('tech("bitermotors-autonomous-logistics"'):
            data.index('tech("bitermotors-planetary-energy-grid"')
        ]
        token_recipe = data[
            data.index('recipe("bitermotors-terrestrial-ai-token"'):
            data.index('recipe("bitermotors-orbital-ai-token"')
        ]
        bitertaxi_recipe = data[
            data.index('recipe("bitermotors-bitertaxi-fleet"'):
            data.index('recipe("bitermotors-bitertaxi-depot"')
        ]
        datacenter_entity = data[
            data.index('local terrestrial_datacenter = copied_assembler('):
            data.index('local orbital_datacenter_core = copied_assembler(')
        ]

        self.assertIn('{"bitermotors-capital-scaling", "bitermotors-energy-products", "processing-unit"}', terrestrial_tech)
        self.assertNotIn("bitermotors-satellite-constellation", terrestrial_tech)
        self.assertNotIn("space-science-pack", terrestrial_tech)
        self.assertIn("    750,", terrestrial_tech)
        for ingredient in [
            "automation-science-pack",
            "logistic-science-pack",
            "chemical-science-pack",
            "production-science-pack",
            "utility-science-pack",
            "bitermotors-dollar",
        ]:
            self.assertIn(ingredient, terrestrial_tech)

        self.assertIn('recipe("bitermotors-terrestrial-ai-token", {"bitermotors-datacenter"}', token_recipe)
        self.assertIn('name = "bitermotors-dollar", amount = 20', token_recipe)
        self.assertIn('name = "bitermotors-ai-token", amount = 20', token_recipe)
        self.assertIn("}}, 30", token_recipe)
        self.assertIn('"8MW"', datacenter_entity)
        self.assertIn('collision_box = {{-2.9, -2.9}, {2.9, 2.9}}', datacenter_entity)
        self.assertIn('selection_box = {{-3, -3}, {3, 3}}', datacenter_entity)
        self.assertIn('generated_entity_animation("terrestrial-datacenter", 0.36, {', datacenter_entity)

        self.assertIn('{"bitermotors-terrestrial-ai", "logistic-robotics", "production-science-pack", "utility-science-pack"}', autonomous_tech)
        for ingredient in [
            "automation-science-pack",
            "logistic-science-pack",
            "chemical-science-pack",
            "production-science-pack",
            "utility-science-pack",
            "bitermotors-ai-token",
            "bitermotors-dollar",
        ]:
            self.assertIn(ingredient, autonomous_tech)
        self.assertNotIn('"logistic-system"', autonomous_tech)
        self.assertNotIn("space-science-pack", autonomous_tech)
        self.assertIn('{"bitermotors-mass-vehicle-assembly"}', bitertaxi_recipe)
        self.assertNotIn('{"advanced-crafting"}', bitertaxi_recipe)
        self.assertIn('"rocket-silo"', data[data.index('tech("bitermotors-orbital-compute"'):])
        self.assertIn('unlock("bitermotors-orbital-datacenter-core")', data)

        self.assertIn('BITERTAXI_SALE_RECIPE = "bitermotors-sell-bitertaxi-fleet"', control)
        self.assertIn("announce_first_bitertaxi_depot", control)
        self.assertNotIn("launch_technology.enabled = true", control)
        self.assertIn("v4_recipe.enabled = true", control)
        self.assertIn("Bitertaxi service is producing recurring profit", control)
        self.assertIn("cargo pods must return them to Nauvis", locale)
        self.assertIn("bitertaxi_sale_complete", control)
        self.assertIn("Operate the Bitertaxi service", control)
        self.assertIn("Cumulative AI Tokens", control)
        self.assertIn("snapshot.ai_tokens_produced < 1000", control)
        self.assertIn("Generate 1,000 AI Tokens", control)
        self.assertIn('power = "8 MW"', control)
        self.assertIn("20 Dollars", locale)
        self.assertIn("Each cycle consumes 20 Dollars, draws 8 MW", locale)
        self.assertIn("stockpile 1,000 Tokens for Autonomous Logistics", locale)

    def test_bitermotors_orbital_compute_is_space_bound(self):
        data = (MOD / "data.lua").read_text()
        orbital_entity = data.index('local orbital_datacenter_core = copied_assembler(')
        orbital_recipe = data.index('recipe("bitermotors-orbital-ai-token"')
        self.assertIn('property = "gravity"', data[orbital_entity:orbital_entity + 800])
        self.assertIn('property = "gravity"', data[orbital_recipe:orbital_recipe + 1200])

    def test_bitermotors_recipes_use_factorio_2_1_categories_field(self):
        data = (MOD / "data.lua").read_text()
        self.assertIn("categories = categories", data)
        self.assertIn("vertically_integrated_intermediates", data)
        self.assertNotIn("category = categories[1]", data)
        self.assertIn("if #ingredients > 4 then", data)
        self.assertIn("has more than four ingredients", data)

    def test_bitermotors_uses_vanilla_crafting_tabs(self):
        data = (MOD / "data.lua").read_text()
        locale = (MOD / "locale/en/bitermotors.cfg").read_text()

        self.assertNotIn('type = "item-group"', data)
        self.assertNotIn("[item-group-name]", locale)
        for subgroup, group in [
            ("bitermotors-infrastructure", "production"),
            ("bitermotors-components", "intermediate-products"),
            ("bitermotors-capital", "intermediate-products"),
        ]:
            start = data.index(f'name = "{subgroup}"')
            block = data[start:start + 220]
            self.assertIn(f'group = "{group}"', block)
            self.assertIn(f"{subgroup}=", locale)

        for name, subgroup in [
            ("bitermotors-prototype-roadster", "transport"),
            ("bitermotors-premium-ev", "transport"),
            ("bitermotors-high-density-solar-array", "energy"),
            ("bitermotors-orbital-datacenter-core", "bitermotors-infrastructure"),
            ("bitermotors-ai-token", "science-pack"),
            ("bitermotors-sales-office", "bitermotors-infrastructure"),
            ("bitermotors-high-energy-battery-pack", "bitermotors-components"),
            ("bitermotors-dollar", "bitermotors-capital"),
            ("bitermotors-ev-reservation", "raw-material"),
            ("bitermotors-wrecked-ev", "bitermotors-components"),
        ]:
            self.assertIn(f'item("{name}"', data)
            item_start = data.index(f'item("{name}"')
            self.assertIn(f'"{subgroup}"', data[item_start:item_start + 300])

        wrecked_ev_start = data.index('item("bitermotors-wrecked-ev"')
        wrecked_ev = data[wrecked_ev_start:wrecked_ev_start + 300]
        self.assertIn('flags = {"always-show"}', wrecked_ev)
        self.assertIn('"z[wrecked-ev]", 1', wrecked_ev)

        for name, subgroup in [
            ("bitermotors-prototype-roadster", "transport"),
            ("bitermotors-high-density-solar-array", "energy"),
            ("bitermotors-orbital-radiator-panel", "energy"),
            ("bitermotors-terrestrial-ai-token", "science-pack"),
            ("bitermotors-sales-office", "bitermotors-infrastructure"),
            ("bitermotors-high-energy-battery-pack", "bitermotors-components"),
            ("bitermotors-sell-prototype-roadster", "bitermotors-capital"),
        ]:
            recipe_start = data.index(f'recipe("{name}"')
            self.assertIn(f'"{subgroup}"', data[recipe_start:recipe_start + 300])

        for legacy_subgroup in [
            "bitermotors-buildings", "bitermotors-mobility", "bitermotors-energy", "bitermotors-space", "bitermotors-compute", "bitermotors-economy"
        ]:
            self.assertNotIn(f'"{legacy_subgroup}"', data)

    def test_bitermotors_repairs_and_reports_progression_integrity(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn("repair_researched_bitermotors_unlocks", control)
        self.assertIn("technology.prototype.effects", control)
        self.assertIn('effect.type == "unlock-recipe"', control)
        self.assertIn("recipe.enabled = true", control)
        self.assertIn("progression_integrity_status", control)
        self.assertIn("progression_integrity = function", control)
        sync_start = control.index("local function sync_force_unlocks")
        self.assertIn(
            "repair_researched_bitermotors_unlocks(force)",
            control[sync_start:sync_start + 250],
        )

    def test_bitermotors_labs_accept_capital_and_late_science(self):
        data = (MOD / "data.lua").read_text()
        for input_name in ["bitermotors-dollar", "bitermotors-ai-token"]:
            self.assertIn(f'add_lab_input("lab", "{input_name}")', data)
            self.assertIn(f'add_lab_input("biolab", "{input_name}")', data)
        self.assertNotIn('add_lab_input("lab", "bitermotors-planetary-grid-segment")', data)
        self.assertNotIn('add_lab_input("biolab", "bitermotors-planetary-grid-segment")', data)

    def test_bitermotors_biterfactory_module_is_an_early_production_cell(self):
        data = (MOD / "data.lua").read_text()
        module_recipe = data.index('recipe("bitermotors-biterfactory-module"')
        module_block = data[module_recipe:module_recipe + 900]
        for expected in [
            '"bitermotors-dollar"',
            '"assembling-machine-2"',
            '"lab"',
            '"refined-concrete"',
        ]:
            self.assertIn(expected, module_block)
        self.assertIn('name = "bitermotors-dollar", amount = 10', module_block)
        self.assertIn('name = "assembling-machine-2", amount = 5', module_block)
        self.assertIn('name = "lab", amount = 5', module_block)
        self.assertIn('name = "refined-concrete", amount = 50', module_block)
        self.assertNotIn('"assembling-machine-3"', module_block)
        self.assertNotIn('"express-transport-belt"', module_block)
        self.assertNotIn('"fast-transport-belt"', module_block)

    def test_biterfactory_v1_is_large_and_builds_premium_evs(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        entity = data[data.index('local biterfactory = copied_assembler('):data.index('local terrestrial_datacenter = copied_assembler(')]
        recipe = data[data.index('recipe("bitermotors-biterfactory-building"'):data.index('recipe("bitermotors-dirty-nickel-refining"')]
        mass_ev = data[data.index('recipe("bitermotors-mass-market-ev"'):data.index('recipe("bitermotors-high-density-solar-array"')]

        self.assertIn('"bitermotors-biterfactory-building"', entity)
        self.assertIn('{"advanced-crafting", "bitermotors-vehicle-assembly", "bitermotors-energy-products", "bitermotors-energy-products-batch", "bitermotors-vertical-integration"}', entity)
        self.assertIn('"20MW"', entity)
        self.assertIn('\n  4\n)', entity)
        self.assertIn('biterfactory.effect_receiver = {base_effect = {productivity = 0.5}}', entity)
        self.assertIn('biterfactory.max_health = 5000', entity)
        self.assertIn('biterfactory.module_slots = 8', entity)
        self.assertIn('"productivity"', entity)
        self.assertIn('collision_box = {{-4.4, -4.4}, {4.4, 4.4}}', entity)
        self.assertIn('selection_box = {{-4.5, -4.5}, {4.5, 4.5}}', entity)
        self.assertIn('biterfactory.graphics_set = biterfactory_animation()', entity)
        self.assertIn('biterfactory.fast_replaceable_group = "bitermotors-biterfactory"', entity)
        self.assertIn('biterfactory.next_upgrade = "bitermotors-biterfactory-v2"', entity)
        self.assertIn('LOGISTIC_SYSTEM_TECH_NAME = "logistic-system"', control)
        self.assertNotIn("unlock_biterfactory_logistics", control)
        self.assertNotIn("Biterfactory logistics online", control)
        self.assertIn("logistic_system.enabled = true", control)
        self.assertNotIn("logistic_system.enabled = unlocked", control)
        self.assertIn("Premium pilot proven: %d Premium EVs produced. Biterfactory construction is now available", control)
        updates = (MOD / "data-updates.lua").read_text()
        logistic_rewrite = updates[
            updates.index('local logistic_system_tech = data.raw.technology["logistic-system"]'):
            updates.index("-- Tier 2 modules are terrestrial Biter Motors capital investments")
        ]
        self.assertIn('prerequisites = {"logistic-robotics", "bitermotors-industrial-supply-chain"}', logistic_rewrite)
        self.assertIn('"automation-science-pack"', logistic_rewrite)
        self.assertIn('"logistic-science-pack"', logistic_rewrite)
        self.assertIn('"chemical-science-pack"', logistic_rewrite)
        self.assertNotIn('"bitermotors-dollar"', logistic_rewrite)
        self.assertNotIn('"space-science-pack"', logistic_rewrite)
        self.assertIn("logistic_system_tech.enabled = true", logistic_rewrite)
        self.assertIn('name = "bitermotors-biterfactory-module", amount = 10', recipe)
        self.assertIn('name = "substation", amount = 2', recipe)
        self.assertIn('{"bitermotors-mass-vehicle-assembly"}', mass_ev)
        self.assertNotIn('{"advanced-crafting"}', mass_ev)
        self.assertTrue((MOD / "graphics/icons/biterfactory.png").exists())
        self.assertTrue((MOD / "graphics/entity/biterfactory/biterfactory.png").exists())
        with Image.open(MOD / "graphics/entity/biterfactory/biterfactory.png") as image:
            self.assertEqual(image.size, (1024, 1024))
            alpha = image.convert("RGBA").getchannel("A")
            self.assertEqual(alpha.getpixel((0, 0)), 0)
            left, top, right, bottom = alpha.getbbox()
            self.assertGreaterEqual(right - left, image.width * 0.84)
            self.assertGreaterEqual(bottom - top, image.height * 0.84)
            self.assertAlmostEqual((left + right) / 2, image.width / 2, delta=image.width * 0.05)
            self.assertAlmostEqual((top + bottom) / 2, image.height / 2, delta=image.height * 0.05)

    def test_biterfactory_v2_is_a_faster_more_efficient_structural_casting_upgrade(self):
        data = (MOD / "data.lua").read_text()
        entity = data[data.index('local biterfactory_v2 = copied_assembler('):data.index('local terrestrial_datacenter = copied_assembler(')]
        structural_casting_recipe = data[data.index('recipe("bitermotors-structural-casting"'):data.index('recipe("bitermotors-biterfactory-v2"')]
        v2_recipe = data[data.index('recipe("bitermotors-biterfactory-v2"'):data.index('recipe("bitermotors-dirty-nickel-refining"')]
        capital_tech = data[data.index('tech("bitermotors-capital-scaling"'):data.index('tech("bitermotors-ev-charging-network"')]

        self.assertIn('{"advanced-crafting", "bitermotors-vehicle-assembly", "bitermotors-mass-vehicle-assembly", "bitermotors-energy-products", "bitermotors-energy-products-batch", "bitermotors-vertical-integration"}', entity)
        self.assertIn('"30MW"', entity)
        self.assertIn('\n  8\n)', entity)
        self.assertIn('base_effect = {productivity = 1.5}', entity)
        self.assertIn('biterfactory_v2.max_health = 7500', entity)
        self.assertIn('biterfactory_v2.module_slots = 8', entity)
        self.assertIn('biterfactory_v2.fast_replaceable_group = "bitermotors-biterfactory"', entity)
        self.assertIn('biterfactory/biterfactory-v2.png', entity)
        self.assertIn('"productivity"', entity)
        self.assertIn('name = "electric-furnace", amount = 20', structural_casting_recipe)
        self.assertIn('name = "steel-plate", amount = 500', structural_casting_recipe)
        self.assertIn('name = "electric-engine-unit", amount = 50', structural_casting_recipe)
        self.assertIn('name = "bitermotors-dollar", amount = 50', structural_casting_recipe)
        self.assertIn('name = "bitermotors-biterfactory-building", amount = 1', v2_recipe)
        self.assertIn('name = "bitermotors-structural-casting", amount = 1', v2_recipe)
        self.assertIn('name = "bitermotors-dollar", amount = 100', v2_recipe)
        self.assertNotIn('"refined-concrete"', v2_recipe)
        self.assertIn('unlock("bitermotors-structural-casting")', capital_tech)
        self.assertIn('unlock("bitermotors-biterfactory-v2")', capital_tech)
        self.assertIn('unlock("bitermotors-mass-market-ev")', capital_tech)
        v2_art = MOD / "graphics/entity/biterfactory/biterfactory-v2.png"
        self.assertTrue(v2_art.exists())
        with Image.open(v2_art) as image:
            self.assertEqual(image.size, (1024, 1024))
            alpha = image.convert("RGBA").getchannel("A")
            self.assertEqual(alpha.getpixel((0, 0)), 0)
            left, top, right, bottom = alpha.getbbox()
            self.assertGreaterEqual(right - left, image.width * 0.84)
            self.assertGreaterEqual(bottom - top, image.height * 0.84)
            self.assertAlmostEqual((left + right) / 2, image.width / 2, delta=image.width * 0.05)
            self.assertAlmostEqual((top + bottom) / 2, image.height / 2, delta=image.height * 0.05)

    def test_biterfactory_vertical_integration_only_productivizes_intermediates(self):
        data = (MOD / "data.lua").read_text()
        locale = (MOD / "locale/en/bitermotors.cfg").read_text()
        control = (MOD / "control.lua").read_text()

        for recipe_name in [
            "copper-cable",
            "electronic-circuit",
            "advanced-circuit",
            "low-density-structure",
            "bitermotors-biterfactory-module",
            "bitermotors-structural-casting",
            "bitermotors-electric-drivetrain",
            "bitermotors-autonomy-computer",
            "bitermotors-datacenter-rack",
        ]:
            self.assertIn(f'"{recipe_name}"', data[data.index("local vertically_integrated_intermediates"):])
        for recipe_name in [
            "bitermotors-premium-ev",
            "bitermotors-mass-market-ev",
            "bitermotors-high-density-solar-array",
            "bitermotors-grid-battery",
            "bitermotors-bitertaxi-fleet",
        ]:
            self.assertIn(f'"{recipe_name}"', data[data.index("for _, recipe_name in pairs({"):])
        self.assertIn('add_recipe_category(recipe_name, "bitermotors-vertical-integration").allow_productivity = true', data)
        self.assertIn("data.raw.recipe[recipe_name].allow_productivity = false", data)
        self.assertIn("bitermotors-vertical-integration=Biterfactory vertical integration", locale)
        self.assertIn("vertically integrated component recipe", control)
        self.assertIn("First Biterfactory V2 online", (MOD / "control.lua").read_text())

    def test_energy_products_are_parallel_placeable_and_biterfactory_built(self):
        data = (MOD / "data.lua").read_text()
        locale = (MOD / "locale/en/bitermotors.cfg").read_text()
        solar_recipe = data[data.index('recipe("bitermotors-high-density-solar-array"'):data.index('recipe("bitermotors-high-density-solar-array-batch"')]
        solar_batch_recipe = data[data.index('recipe("bitermotors-high-density-solar-array-batch"'):data.index('recipe("bitermotors-grid-battery"')]
        grid_battery_recipe = data[data.index('recipe("bitermotors-grid-battery"'):data.index('recipe("bitermotors-autonomy-computer"')]
        energy_tech = data[data.index('tech("bitermotors-energy-products"'):data.index('tech("bitermotors-terrestrial-ai"')]

        self.assertIn('copied_energy_entity(\n  "solar-panel"', data)
        self.assertIn('high_density_solar_array.production = "300kW"', data)
        self.assertIn('high_density_solar_array.collision_box = {{-1.35, -1.35}, {1.35, 1.35}}', data)
        self.assertIn('high_density_solar_array.selection_box = {{-1.5, -1.5}, {1.5, 1.5}}', data)
        self.assertIn('high_density_solar_array.fast_replaceable_group = "solar-panel"', data)
        self.assertIn('data.raw["solar-panel"]["solar-panel"].next_upgrade = "bitermotors-high-density-solar-array"', data)
        self.assertIn('generated_icon("high-density-solar-array")', data)
        self.assertIn('local tandem_solar_array_icon = generated_icon("high-density-solar-array")', data)
        self.assertIn('graphics/entity/high-density-solar-array/high-density-solar-array.png', data)
        self.assertIn('graphics/entity/high-density-solar-array/high-density-solar-array-shadow.png', data)
        control = (MOD / "control.lua").read_text()
        self.assertNotIn("bitermotors-high-density-solar-array-horizontal", data)
        self.assertNotIn("bitermotors-high-density-solar-array-power-source", data)
        self.assertNotIn("replace_solar_array_orientation", control)
        self.assertIn('copied_energy_entity(\n  "accumulator"', data)
        self.assertIn('grid_battery.energy_source.buffer_capacity = "100MJ"', data)
        self.assertIn('grid_battery.energy_source.input_flow_limit = "5MW"', data)
        self.assertIn('grid_battery.energy_source.output_flow_limit = "5MW"', data)
        self.assertIn('generated_icon("grid-battery")', data)
        self.assertIn('local grid_battery_array_icon = generated_icon("grid-battery")', data)
        self.assertIn('graphics/animation/grid-battery-charge.png', data)
        self.assertIn('graphics/animation/grid-battery-discharge.png', data)
        self.assertIn('charge_cooldown = 30', data)
        self.assertIn('discharge_cooldown = 60', data)
        self.assertTrue((MOD / "graphics/icons/high-density-solar-array.png").exists())
        self.assertTrue((MOD / "graphics/icons/grid-battery.png").exists())
        self.assertTrue((MOD / "graphics/entity/high-density-solar-array/high-density-solar-array.png").exists())
        self.assertTrue((MOD / "graphics/entity/high-density-solar-array/high-density-solar-array-shadow.png").exists())
        self.assertTrue((MOD / "graphics/entity/grid-battery/grid-battery.png").exists())
        self.assertTrue((MOD / "graphics/entity/grid-battery/grid-battery-shadow.png").exists())
        self.assertTrue((MOD / "graphics/animation/grid-battery-charge.png").exists())
        self.assertTrue((MOD / "graphics/animation/grid-battery-discharge.png").exists())
        self.assertIn('{"advanced-crafting"}', solar_recipe)
        self.assertIn('name = "solar-panel", amount = 1', solar_recipe)
        self.assertIn('name = "processing-unit", amount = 2', solar_recipe)
        self.assertIn('name = "low-density-structure", amount = 2', solar_recipe)
        self.assertNotIn('name = "bitermotors-dollar"', solar_recipe)
        self.assertIn('{"bitermotors-energy-products-batch"}', solar_batch_recipe)
        self.assertIn('name = "solar-panel", amount = 4', solar_batch_recipe)
        self.assertIn('name = "processing-unit", amount = 6', solar_batch_recipe)
        self.assertIn('name = "low-density-structure", amount = 6', solar_batch_recipe)
        self.assertNotIn('name = "bitermotors-dollar"', solar_batch_recipe)
        self.assertIn('name = "bitermotors-high-density-solar-array", amount = 4', solar_batch_recipe)
        self.assertIn('item("bitermotors-high-density-solar-array", high_density_solar_array_icon, "energy", "bitermotors-a[high-density-solar-array]", 10', data)
        self.assertIn('{"bitermotors-energy-products"}', grid_battery_recipe)
        self.assertIn('name = "bitermotors-lfp-battery-pack", amount = 12', grid_battery_recipe)
        self.assertIn('name = "accumulator", amount = 4', grid_battery_recipe)
        self.assertIn('name = "substation", amount = 1', grid_battery_recipe)
        self.assertIn('{"bitermotors-advanced-battery-chemistry", "electric-energy-accumulators", "solar-energy"}', energy_tech)
        self.assertNotIn('"production-science-pack"', energy_tech)
        self.assertIn("    200,", energy_tech)
        self.assertIn("    30\n  ),", energy_tech)
        self.assertNotIn('"bitermotors-capital-scaling"', energy_tech)
        self.assertNotIn('unlock("bitermotors-biterfactory-building")', energy_tech)
        self.assertIn('unlock("bitermotors-high-density-solar-array")', energy_tech)
        self.assertIn('unlock("bitermotors-grid-battery")', energy_tech)
        self.assertIn('unlock("bitermotors-sell-grid-battery")', energy_tech)
        self.assertIn("bitermotors-grid-battery=Stores 100 MJ", locale)
        self.assertNotIn("bitermotors-grid-storage-unit", data)
        self.assertNotIn("bitermotors-sell-grid-storage", data)

    def test_bitermotors_charging_network_sales_loop(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        self.assertIn('recipe("bitermotors-ev-charging-station"', data)
        self.assertIn('tech("bitermotors-ev-charging-network"', data)
        sales_office_entity = data[data.index('local sales_office = copied_assembler('):data.index('local ev_charging_station = copied_reservation_output_site(')]
        self.assertIn('"bitermotors-sales-office"', sales_office_entity)
        self.assertIn("radius_visualisation_specification", sales_office_entity)
        self.assertIn("customer_radius_visualisation(128)", sales_office_entity)
        charging_entity = data[data.index('local ev_charging_station = copied_reservation_output_site('):data.index('local terrestrial_datacenter = copied_assembler(')]
        self.assertIn('"bitermotors-ev-charging-station"', charging_entity)
        self.assertIn('"bitermotors-ev-charging-station-v2"', charging_entity)
        self.assertIn('"bitermotors-ev-charging-station-v3"', charging_entity)
        self.assertIn('"bitermotors-ev-charging-station-v4"', charging_entity)
        self.assertNotIn("copied_electric_pole", charging_entity)
        self.assertIn("radius_visualisation_specification", charging_entity)
        self.assertIn("customer_radius_visualisation(64)", charging_entity)
        self.assertIn("customer_radius_visualisation(128)", charging_entity)
        self.assertIn("customer_radius_visualisation(192)", charging_entity)
        self.assertIn("customer_radius_visualisation(256)", charging_entity)
        self.assertIn('collision_box = {{-1.9, -1.9}, {1.9, 1.9}}', charging_entity)
        self.assertIn('collision_box = {{-2.4, -2.4}, {2.4, 2.4}}', charging_entity)
        self.assertIn('collision_box = {{-2.9, -2.9}, {2.9, 2.9}}', charging_entity)
        self.assertIn('generated_entity_picture("ev-charging-station-v4", nil, 0.38)', charging_entity)
        self.assertIn('data.raw["logistic-container"]["passive-provider-chest"]', data)
        self.assertIn("prototype.inventory_size = 2", data)
        self.assertIn('prototype.logistic_mode = "passive-provider"', data)
        self.assertIn("prototype.render_not_in_network_icon = false", data)
        self.assertIn("robot_door.animation = generated_entity_picture", charging_entity)
        self.assertIn('prototype.name = "bitermotors-ev-charging-grid-connection"', data)
        self.assertIn('hidden_ev_charging_power_sink("bitermotors-ev-charging-power-sink", 50)', data)
        self.assertIn('hidden_ev_charging_power_sink("bitermotors-ev-charging-v2-power-sink", 150)', data)
        self.assertIn('hidden_ev_charging_power_sink("bitermotors-ev-charging-v3-power-sink", 250)', data)
        self.assertIn('hidden_ev_charging_power_sink("bitermotors-ev-charging-v4-power-sink", 500)', data)
        self.assertIn('type = "electric-energy-interface"', data)
        self.assertIn('local power = tostring(power_kw) .. "kW"', data)
        self.assertIn("input_flow_limit = power", data)
        self.assertIn("energy_usage = power", data)
        self.assertIn('gui_mode = "none"', data)
        self.assertIn('selectable_in_game = false', data)
        self.assertIn('prototype.maximum_wire_distance = 0', data)
        self.assertIn('prototype.auto_connect_up_to_n_wires = 0', data)
        self.assertIn('prototype.rewire_neighbours_when_destroying = false', data)
        self.assertIn('prototype.supply_area_distance = 1', data)
        self.assertIn('pole.prototype.get_supply_area_distance(pole.quality)', control)
        self.assertIn('storage.bitermotors_station_power_model = "native-supply-area-v1"', control)
        self.assertIn('cleanup_legacy_station_grid_connections()', control)
        self.assertNotIn('charger_wire.connect_to(grid_wire, false)', control)
        self.assertNotIn('name = STATION_GRID_CONNECTION_NAME,\n      position = station.position', control)
        self.assertIn('item("bitermotors-ev-charging-station", ev_charging_station_icon, "bitermotors-infrastructure", "b[ev-charging-station]", 5', data)
        self.assertIn('item("bitermotors-ev-charging-station-v2", ev_charging_station_v2_icon, "bitermotors-infrastructure", "c[ev-charging-station-v2]", 5', data)
        self.assertIn('item("bitermotors-ev-charging-station-v3", ev_charging_station_v3_icon, "bitermotors-infrastructure", "d[ev-charging-station-v3]", 5', data)
        self.assertIn('item("bitermotors-ev-charging-station-v4", ev_charging_station_v4_icon, "bitermotors-infrastructure", "e[ev-charging-station-v4]", 5', data)

    def test_terrestrial_industrial_supply_chain(self):
        data = (MOD / "data.lua").read_text()
        updates = (MOD / "data-updates.lua").read_text()
        control = (MOD / "control.lua").read_text()
        locale = (MOD / "locale" / "en" / "bitermotors.cfg").read_text()
        self.assertIn('name = "bitermotors-industrial-supply-chain"', updates)
        self.assertIn('data.raw.technology["advanced-material-processing-2"]', updates)
        self.assertIn('effect.recipe ~= "electric-furnace"', updates)
        self.assertIn('{"electric-mining-drill", 4}', updates)
        self.assertIn('{"engine-unit", 20}', updates)
        self.assertIn('big_drill_tech.prerequisites = {"bitermotors-industrial-supply-chain", "engine"}', updates)
        self.assertIn('tungsten_steel_tech.prerequisites = {"planet-discovery-vulcanus"}', updates)
        self.assertIn('holmium_tech.prerequisites = {"recycling", "planet-discovery-fulgora"}', updates)
        self.assertIn('entities = {"tungsten-ore"}', updates)
        self.assertIn('"electric-mining-drill", "steel-processing"', updates)
        self.assertIn('{"electronic-circuit", 20}', updates)
        self.assertIn('{"electric-furnace", 25}', updates)
        self.assertIn('{"refined-concrete", 200}', updates)
        self.assertIn('foundry_tech.prerequisites = {"bitermotors-industrial-supply-chain", "bitermotors-energy-products", "concrete"}', updates)
        self.assertIn('foundry_tech.unit = science(250, {', updates)
        foundry_technology = updates[
            updates.index("local foundry_tech = data.raw.technology.foundry"):
            updates.index("-- The Foundry's terrestrial ore/casting loop")
        ]
        for ingredient in [
            '"automation-science-pack"',
            '"logistic-science-pack"',
            '"chemical-science-pack"',
            '"bitermotors-dollar"',
        ]:
            self.assertIn(ingredient, foundry_technology)
        self.assertIn("foundry_tech.enabled = false", foundry_technology)
        self.assertNotIn('"molten-iron-from-lava",', updates)
        self.assertNotIn('"casting-low-density-structure",', updates)
        self.assertIn('initialize_patch_set("calcite", false)', updates)
        self.assertIn('entity.settings.calcite = {}', updates)
        self.assertIn('rewrite_recipe("recycler"', updates)
        self.assertIn('unlock("bitermotors-wrecked-ev-recycling")', updates)
        self.assertIn('recycling_tech.enabled = false', updates)
        self.assertIn('rewrite_recipe("teslagun"', updates)
        tesla_ammo = updates[
            updates.index('rewrite_recipe("tesla-ammo"'):
            updates.index("local tesla_tech")
        ]
        self.assertIn('{"bitermotors-high-nickel-cell", 1}', tesla_ammo)
        self.assertNotIn("bitermotors-high-energy-battery-pack", tesla_ammo)
        self.assertIn("energy_required = 5", tesla_ammo)
        self.assertNotIn('holmium-plate', updates)
        self.assertNotIn('superconductor', updates)
        self.assertIn('item("bitermotors-wrecked-ev"', data)
        self.assertIn(
            'item("bitermotors-wrecked-ev", wrecked_ev_icon, "bitermotors-components"',
            data,
        )
        self.assertIn('flags = {"always-show"}', data)
        self.assertIn('recipe("bitermotors-wrecked-ev-recycling"', data)
        self.assertIn('if math.random() < 0.01', control)
        recycling_unlock = control[
            control.index('unlock_vehicle_recycling = function(force)'):
            control.index('generate_station_wrecks = function')
        ]
        self.assertIn('technology.enabled = true', recycling_unlock)
        self.assertNotIn('technology.researched = true', recycling_unlock)
        self.assertNotIn('force.print', recycling_unlock)
        self.assertIn('output.insert{name = WRECKED_EV_NAME, count = removed}', control)
        self.assertIn('bitermotors-industrial-supply-chain=Industrial Supply Chain', locale)
        self.assertIn('foundry=Metallurgical Scaling', locale)
        self.assertIn('a basic melting and casting pair draws 5 MW', locale)
        self.assertIn("FOUNDRY_POWER_GATE = {", control)
        self.assertIn("solar_panels = 25", control)
        self.assertIn("grid_batteries = 5", control)
        self.assertIn("function foundry_power_gate_status(force)", control)
        self.assertIn("count_deployed_energy_product(force, HIGH_DENSITY_SOLAR_ARRAY_NAME)", control)
        self.assertIn("count_deployed_energy_product(force, GRID_BATTERY_NAME)", control)
        self.assertIn("quality = BITERMOTORS_ENERGY_JUMPSTART_QUALITY", control)
        self.assertIn("total - math.min(starter_count, starter_quality_count)", control)
        self.assertIn("technology.enabled = technology.researched or gate.qualified", control)
        self.assertIn('label = "Industrial power qualification"', control)

    def test_bitermotors_technology_icons_share_one_badge(self):
        data = (MOD / "data.lua").read_text()
        updates = (MOD / "data-updates.lua").read_text()
        control = (MOD / "control.lua").read_text()
        badge = MOD / "graphics" / "technology" / "bitermotors-tech-badge.png"
        self.assertTrue(badge.exists())
        with Image.open(badge) as badge_image:
            self.assertEqual(badge_image.size, (64, 64))
        self.assertIn('bitermotors-tech-badge.png', data)
        self.assertIn('bitermotors-tech-badge.png', updates)
        for old_ringed_icon in [
            "sales-office.png",
            "ev-charging-network.png",
            "biterfactory.png",
            "terrestrial-ai.png",
            "autonomous-logistics.png",
            "planetary-energy-grid.png",
        ]:
            self.assertNotIn(f'graphics/technology/{old_ringed_icon}', data)
        for clean_subject in [
            "graphics/icons/sales-office.png",
            "graphics/icons/premium-ev.png",
            "graphics/icons/mass-market-ev.png",
            "graphics/icons/ev-charging-station-v2.png",
            "graphics/icons/grid-battery.png",
            "graphics/icons/bitertaxi-depot.png",
            "graphics/icons/planetary-grid-controller.png",
        ]:
            self.assertIn(clean_subject, data)
        station_recipe = data[data.index('recipe("bitermotors-ev-charging-station"'):data.index('recipe("bitermotors-ev-charging-station-v2"')]
        station_v2_recipe = data[data.index('recipe("bitermotors-ev-charging-station-v2"'):data.index('recipe("bitermotors-ev-charging-station-v3"')]
        station_v3_recipe = data[data.index('recipe("bitermotors-ev-charging-station-v3"'):data.index('recipe("bitermotors-ev-charging-station-v4"')]
        station_v4_recipe = data[data.index('recipe("bitermotors-ev-charging-station-v4"'):data.index('recipe("bitermotors-biterfactory-module"')]
        self.assertNotIn('"bitermotors-dollar"', station_recipe)
        for expected in [
            '"substation"',
            '"accumulator"',
            '"concrete"',
        ]:
            self.assertIn(expected, station_recipe)
        for redundant in [
            '"advanced-circuit"',
            '"copper-cable"',
            '"battery"',
            '"steel-plate"',
        ]:
            self.assertNotIn(redundant, station_recipe)
        for expected in [
            'name = "bitermotors-ev-charging-station", amount = 1',
            'name = "substation", amount = 2',
            'name = "processing-unit", amount = 20',
        ]:
            self.assertIn(expected, station_v2_recipe)
        self.assertNotIn('"bitermotors-dollar"', station_v2_recipe)
        for expected in [
            'name = "bitermotors-ev-charging-station-v2", amount = 1',
            'name = "substation", amount = 4',
            'name = "processing-unit", amount = 40',
            'name = "bitermotors-dollar", amount = 75',
        ]:
            self.assertIn(expected, station_v3_recipe)
        for expected in [
            'name = "bitermotors-ev-charging-station-v3", amount = 1',
            'name = "bitermotors-high-density-solar-array", amount = 4',
            'name = "bitermotors-grid-battery", amount = 4',
            'name = "bitermotors-dollar", amount = 200',
        ]:
            self.assertIn(expected, station_v4_recipe)
        charging_tech = data[data.index('tech("bitermotors-ev-charging-network"'):data.index('tech("bitermotors-energy-products"')]
        self.assertIn('unlock("bitermotors-ev-charging-station-v2")', charging_tech)
        self.assertNotIn('unlock("bitermotors-ev-charging-station")', charging_tech)
        capital_scaling_tech = data[data.index('tech("bitermotors-capital-scaling"'):data.index('tech("bitermotors-ev-charging-network"')]
        autonomous_tech = data[data.index('tech("bitermotors-autonomous-logistics"'):data.index('tech("bitermotors-planetary-energy-grid"')]
        self.assertIn('unlock("bitermotors-ev-charging-station-v3")', capital_scaling_tech)
        self.assertIn('unlock("bitermotors-ev-charging-station-v4")', autonomous_tech)
        self.assertIn('v4_recipe.enabled = researched(force, "bitermotors-autonomous-logistics")', control)
        mass_sale = data[data.index('recipe("bitermotors-sell-mass-market-ev"'):data.index('recipe("bitermotors-sell-grid-battery"')]
        bitertaxi_sale = data[data.index('recipe("bitermotors-sell-bitertaxi-fleet"'):data.index('recipe("bitermotors-terrestrial-ai-token"')]
        self.assertIn('"bitermotors-ev-reservation"', mass_sale)
        self.assertIn('name = "bitermotors-mass-market-ev", amount = 1', mass_sale)
        self.assertIn('name = "bitermotors-ev-reservation", amount = 1', mass_sale)
        self.assertIn('{{type = "item", name = "bitermotors-dollar", amount = 1}}, 5', mass_sale)
        self.assertNotIn('"bitermotors-ev-reservation"', bitertaxi_sale)
        self.assertIn('name = "bitermotors-bitertaxi-fleet", amount = 3', bitertaxi_sale)
        self.assertIn('{{type = "item", name = "bitermotors-dollar", amount = 1}}, 3', bitertaxi_sale)
        bitertaxi_recipe = data[data.index('recipe("bitermotors-bitertaxi-fleet"'):data.index('recipe("bitermotors-bitertaxi-depot"')]
        self.assertIn('name = "bitermotors-dollar", amount = 100', bitertaxi_recipe)

    def test_sales_office_coverage_has_remote_view_toggle(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        locale = (MOD / "locale/en/bitermotors.cfg").read_text()
        shortcut = data[
            data.index('name = "bitermotors-toggle-sales-office-coverage"') - 40:
            data.index('type = "item-subgroup"')
        ]

        self.assertIn('type = "shortcut"', shortcut)
        self.assertIn('action = "lua"', shortcut)
        self.assertIn('toggleable = true', shortcut)
        self.assertIn('technology_to_unlock = "bitermotors-sales-office"', shortcut)
        self.assertIn('__bitermotors__/graphics/icons/sales-office-coverage.png', shortcut)
        self.assertNotIn('__base__/graphics/icons/radar.png', shortcut)
        self.assertIn("bitermotors-toggle-sales-office-coverage=Sales Office Coverage", locale)
        coverage_icon = MOD / "graphics/icons/sales-office-coverage.png"
        self.assertTrue(coverage_icon.exists())
        with Image.open(coverage_icon) as image:
            self.assertEqual(image.size, (256, 256))
            self.assertEqual(image.mode, "RGBA")
        self.assertIn("refresh_sales_office_coverage", control)
        self.assertIn("rendering.draw_circle", control)
        self.assertIn('render_mode = "chart"', control)
        self.assertIn(
            "local radius = grid_battery_market and GRID_BATTERY_SALES_RADIUS or SALES_OFFICE_CUSTOMER_RADIUS",
            control,
        )
        self.assertIn("radius = radius", control)
        self.assertIn("players = {player}", control)
        self.assertIn("set_shortcut_toggled", control)
        self.assertIn("on_lua_shortcut", control)
        self.assertIn("mark_sales_office_coverage_dirty", control)
        self.assertIn("{r = 0.03, g = 0.16, b = 0.18, a = 0.18}", control)
        self.assertIn("{r = 0.18, g = 0.62, b = 0.58, a = 0.72}", control)
        self.assertIn("{r = 0.10, g = 0.20, b = 0.08, a = 0.10}", control)
        self.assertNotIn("color = {r = 0.2, g = 1.0, b = 0.35", control)

    def test_grid_battery_sales_use_social_adoption_and_physical_buyers(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        sale = data[
            data.index('recipe("bitermotors-sell-grid-battery"'):
            data.index('recipe("bitermotors-sell-bitertaxi-fleet"')
        ]

        self.assertIn('name = "bitermotors-grid-battery", amount = 1', sale)
        self.assertIn('name = "bitermotors-dollar", amount = 20', sale)
        self.assertIn("}}, 30,", sale)
        self.assertNotIn("bitermotors-ev-reservation", sale)
        for contract in [
            "GRID_BATTERY_SALES_RADIUS = 384",
            "GRID_BATTERY_INITIAL_ADOPTION_FRACTION = 0.05",
            "GRID_BATTERY_REFERRAL_FRACTION = 0.05",
            "GRID_BATTERY_REFERRAL_WAVE_TICKS = 5 * 60 * 60",
            "GRID_BATTERY_BUYER_MAX_ACTIVE = 32",
            "GRID_BATTERY_BUYER_STARTS_PER_SECOND = 4",
            "function sync_grid_battery_adoption_waves()",
            "function ensure_grid_battery_buyer_icon(",
            "function begin_grid_battery_buyer_trip(",
            "function hold_grid_battery_buyer_at_showroom(",
            "function complete_grid_battery_buyer_arrival(",
            "function send_grid_battery_buyer_home(",
            "function install_grid_battery_at_settlement(",
            "function handle_grid_battery_buyer_command_completed(",
            "function sync_grid_battery_sales_offices()",
            'sprite = "item/" .. GRID_BATTERY_NAME',
            'trip.phase == "waiting_product"',
            "trip.showroom_position",
        ]:
            self.assertIn(contract, control)
        self.assertIn("if trip.buyer_icon and trip.buyer_icon.valid then trip.buyer_icon.destroy() end", control)
        self.assertIn("return hold_grid_battery_buyer_at_showroom(trip, entity)", control)
        self.assertIn(
            "if not handle_grid_battery_buyer_command_completed(event) then",
            control,
        )
        self.assertIn(
            "if not grid_battery_buyer_reservations()[entity.unit_number]",
            control,
        )
        self.assertIn("complete_grid_battery_sale(office)", control)
        self.assertIn("Grid Battery adoption", control)
        self.assertIn("Next referral wave", control)

    def test_bitermotors_progress_interface_is_live_and_actionable(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        locale = (MOD / "locale/en/bitermotors.cfg").read_text()

        progress_shortcut = data[
            data.index('name = "bitermotors-open-progress"') - 40:
            data.index('name = "bitermotors-toggle-sales-office-coverage"')
        ]
        self.assertIn('type = "shortcut"', progress_shortcut)
        self.assertIn('action = "lua"', progress_shortcut)
        self.assertIn('__bitermotors__/graphics/icons/bitermotors-group.png', progress_shortcut)
        self.assertIn("bitermotors-open-progress=Biter Motors Progress", locale)
        self.assertIn('BITERMOTORS_PROGRESS_SHORTCUT = "bitermotors-open-progress"', control)
        self.assertIn('PROGRESS_PANEL_NAME = "bitermotors_progress_panel"', control)
        self.assertIn("progress_snapshot", control)
        self.assertIn("current_progress_objective", control)
        self.assertIn("progress_stages", control)
        self.assertIn("refresh_progress_panel", control)
        self.assertIn("open_progress_panel", control)
        self.assertIn('sprite = "utility/close"', control)
        self.assertIn('commands.add_command("bitermotors-status"', control)
        self.assertIn('commands.add_command("bitermotors-note"', control)
        self.assertIn('helpers.write_file("bitermotors-playtest-notes.jsonl"', control)
        self.assertIn("Playtest note recorded", control)
        self.assertIn("progress_status = function", control)
        self.assertIn("Profit generated", control)
        self.assertIn("format_represented_usd", control)
        self.assertIn("* 10000", control)
        self.assertIn('"%s (%d $)"', control)
        self.assertNotIn('label = "Calcite mined"', control)
        self.assertNotIn('label = "Wrecked EVs"', control)
        self.assertNotIn('label = "Vehicle recycling"', control)
        self.assertIn('label = "Logistic System"', control)
        self.assertIn("statistics.output_counts[item_name]", control)
        self.assertIn('"bitermotors_dollars_produced_value"', control)
        self.assertIn("EV Reservations", control)
        self.assertNotIn('add_progress_section(content, "Infrastructure"', control)
        self.assertNotIn('add_progress_section(content, "Continuous improvement"', control)
        self.assertNotIn('label = "Energy Products"', control)
        self.assertIn("Terrestrial industry", control)
        self.assertIn("progress_health", control)
        self.assertIn("current_progress_measure", control)
        self.assertIn('type = "progressbar"', control)
        self.assertIn("add_progress_metrics", control)
        self.assertIn("BITERMOTORS_STATE_COLORS.good", control)
        self.assertIn("BITERMOTORS_STATE_COLORS.warning", control)
        self.assertIn("BITERMOTORS_STATE_COLORS.bad", control)
        self.assertIn("industrial_supply_chain_researched", control)
        self.assertIn("big_mining_drills = count_entities", control)
        self.assertIn("foundries = count_entities", control)
        self.assertIn("calcite_mined = count_item_produced", control)
        self.assertIn("wrecked_evs_produced = count_item_produced", control)
        self.assertIn('type = "scroll-pane"', control)
        self.assertIn("player.display_resolution.width / display_scale", control)
        self.assertIn("player.display_resolution.height / display_scale", control)
        self.assertIn("content.style.maximal_height = content_height", control)
        self.assertIn("Cumulative AI Tokens", control)
        self.assertIn("if snapshot.planetary_grid_researched then", control)
        self.assertIn("AI Tokens generated", control)
        self.assertIn("if snapshot.terrestrial_ai_researched then", control)
        self.assertIn("if snapshot.autonomous_logistics_researched then", control)
        self.assertIn("if snapshot.mass_market_researched then", control)
        self.assertIn("Wait for the first EV Reservation at the charger", control)
        self.assertIn("Run Sell hopes and dreams", control)
        self.assertIn("Upgrade a Biterfactory to V2", control)

    def test_sales_office_and_biterfactory_panels_report_bottlenecks(self):
        control = (MOD / "control.lua").read_text()

        self.assertIn('ENTITY_INFO_PANEL_NAME = "bitermotors_entity_info_panel"', control)
        self.assertIn("BITERFACTORY_CONFIGS", control)
        self.assertIn('power = "20 MW"', control)
        self.assertIn('power = "30 MW"', control)
        self.assertIn('productivity = "4x crafting speed; 50% built-in productivity"', control)
        self.assertIn('productivity = "2x crafting speed; 150% built-in productivity"', control)
        self.assertIn("show_manufacturer_info_panel", control)
        self.assertIn("is_bitermotors_manufacturer", control)
        self.assertIn("entity_status_text", control)
        self.assertIn("recipe_missing_item", control)
        self.assertIn("add_item_inventory_row", control)
        self.assertIn("add_bitermotors_metric_table", control)
        self.assertIn("Cycle progress", control)
        self.assertIn("Blocked: restore electric power", control)
        self.assertIn("Blocked: remove finished products", control)
        self.assertIn('"Blocked: deliver "', control)
        self.assertIn("announce_first_mass_market_ev_sale", control)
        self.assertIn("RESEARCH_COMPLETION_MESSAGES", control)
        self.assertIn("ENTITY_PLACEMENT_MESSAGES", control)
        self.assertIn("announce_first_entity_placement(entity)", control)

    def test_customer_settlement_inspector_explains_service_and_hostility(self):
        control = (MOD / "control.lua").read_text()

        self.assertIn("assignment_by_settlement_key", control)
        self.assertIn("is_customer_settlement_entity", control)
        self.assertIn("show_customer_settlement_info_panel", control)
        self.assertIn('caption = "Biter Motors Customer Settlement"', control)
        self.assertIn("Sales Office coverage", control)
        self.assertIn("Active vehicles at this settlement", control)
        self.assertIn("Assigned charger", control)
        self.assertIn("settlement slots free", control)
        self.assertIn("Network vehicle capacity", control)
        self.assertIn("outside the %d-tile Sales Office market radius", control)
        self.assertIn("no reachable powered charger has a free settlement stall", control)
        self.assertIn("sold EVs exceed reachable charging capacity", control)
        self.assertIn("remains friendly during its patience period", control)
        self.assertIn("is_customer_settlement_entity(entity)", control)
        self.assertIn("is_customer_settlement_entity(opened)", control)

    def test_vehicle_sales_require_living_mobile_buyers_and_track_ownership(self):
        control = (MOD / "control.lua").read_text()

        self.assertIn("bitermotors_customer_vehicle_owners", control)
        self.assertIn("bitermotors_office_buyer_reservations", control)
        self.assertIn("eligible_customer_buyers", control)
        self.assertIn("reserve_office_buyers", control)
        self.assertIn("office.disabled_by_script = not valid_reservation", control)
        self.assertIn("complete_reserved_vehicle_sale", control)
        self.assertIn("replace_customer_vehicle_entity", control)
        self.assertIn('return "bitermotors-" .. base_name .. "-" .. class_name', control)
        self.assertNotIn('sprite = "item/" .. ownership.vehicle', control)
        self.assertIn('text = "$"', control)
        self.assertIn("unregister_customer_unit(entity)", control)
        self.assertIn("Active customer EVs", control)
        self.assertIn("Roadsters sold", control)
        self.assertIn('label = "Reserved"', control)
        self.assertIn("Waiting for a prospect.", control)

    def test_charger_power_and_customer_patience_are_proportional(self):
        control = (MOD / "control.lua").read_text()

        self.assertIn("sample_station_power_service", control)
        self.assertIn("flow.secondary_demand_usage", control)
        self.assertIn("powered_station_stalls", control)
        self.assertIn("power_state.power_fraction", control)
        self.assertIn("CUSTOMER_SERVICE_GRACE_TICKS = 3 * 60 * 60", control)
        self.assertIn("CUSTOMER_MOOD_CHECK_TICKS = 60 * 60", control)
        self.assertIn("if random() < chance", control)
        self.assertIn("state.angry = false", control)
        self.assertIn("EVs lack powered charging service. Restore grid power.", control)

    def test_biter_motors_reduces_vanilla_enemy_attack_pressure(self):
        control = (MOD / "control.lua").read_text()

        self.assertIn("BITERMOTORS_ENEMY_ATTACK_POLLUTION_COST = 4", control)
        self.assertIn("BITERMOTORS_MAX_GATHERING_ATTACK_GROUPS = 10", control)
        self.assertIn("BITERMOTORS_MAX_ATTACK_GROUP_SIZE = 80", control)
        self.assertIn("BITERMOTORS_MIN_EXPANSION_COOLDOWN_TICKS = 10 * 60 * 60", control)
        self.assertIn("BITERMOTORS_MAX_EXPANSION_COOLDOWN_TICKS = 60 * 60 * 60", control)
        self.assertIn("BITERMOTORS_POLLUTION_EVOLUTION_FACTOR = 3e-7", control)
        self.assertIn("apply_bitermotors_enemy_pressure_settings()", control)
        self.assertIn("relieve_bitermotors_enemy_pressure(max_evolution)", control)
        self.assertIn("command.type ~= defines.command.wander", control)
        self.assertIn('relieve_enemy_pressure = function(max_evolution)', control)
        self.assertIn("enemy_pressure_status = function()", control)

    def test_bitermotors_control_generates_physical_reservations_at_chargers(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn('"bitermotors-ev-charging-station"', control)
        self.assertIn('"bitermotors-sales-office"', control)
        self.assertIn('"bitermotors-ev-reservation"', control)
        self.assertIn('"bitermotors-sell-prototype-roadster"', control)
        self.assertIn("sync_all_force_unlocks", control)
        self.assertIn("FIRST_CUSTOMER_CHARGER_UNLOCK_RECIPES", control)
        self.assertIn("force.get_item_production_statistics(surface)", control)
        self.assertIn("statistics.output_counts[PROTOTYPE_ROADSTER_NAME]", control)
        self.assertIn("unlock_roadster_sales", control)
        unlock = control[control.index("local function unlock_roadster_sales"):control.index("local function announce_first_ev_production_line_hint")]
        self.assertIn("local first_unlock = not milestones[force.name]", unlock)
        self.assertIn("recipe.enabled = true", unlock)
        self.assertIn("if first_unlock then", unlock)
        self.assertNotIn("if milestones[force.name] then\n    return", unlock)
        self.assertIn("First biter customer charging site covered", control)
        self.assertIn("Prototype Roadsters are now available for Sell hopes and dreams", control)
        self.assertIn("First Dollars earned. Next: research EV Production Line", control)
        self.assertIn("unlock EV components, Premium EV pilot production", control)
        self.assertIn("bitermotors_first_ev_production_line_hints", control)
        self.assertIn("PREMIUM_EV_SALE_RECIPE", control)
        self.assertIn("STATION_GRID_CONNECTION_NAME", control)
        for station_name in [
            '"bitermotors-ev-charging-station"',
            '"bitermotors-ev-charging-station-v2"',
            '"bitermotors-ev-charging-station-v3"',
            '"bitermotors-ev-charging-station-v4"',
        ]:
            self.assertIn(station_name, control)
        self.assertIn("STATION_CONFIGS", control)
        self.assertIn("stalls = 4", control)
        self.assertIn("stalls = 8", control)
        self.assertIn("stalls = 12", control)
        self.assertIn("stalls = 20", control)
        self.assertIn("power_per_stall_kw = 50", control)
        self.assertIn("power_per_stall_kw = 150", control)
        self.assertIn("power_per_stall_kw = 250", control)
        self.assertIn("power_per_stall_kw = 500", control)
        self.assertIn("customer_radius = 128", control)
        self.assertIn("customer_radius = 192", control)
        self.assertIn("customer_radius = 256", control)
        self.assertIn('power_sink_name = "bitermotors-ev-charging-v2-power-sink"', control)
        self.assertIn('power_sink_name = "bitermotors-ev-charging-v3-power-sink"', control)
        self.assertIn('power_sink_name = "bitermotors-ev-charging-v4-power-sink"', control)
        self.assertIn('chargers_v3 = count_entities(force, "bitermotors-ev-charging-station-v3")', control)
        self.assertIn('chargers_v4 = count_entities(force, "bitermotors-ev-charging-station-v4")', control)
        self.assertIn("Craft and place a V3 Rapid Charger", control)
        self.assertIn("Craft and place a solar-canopy V4 Solar Charging Hub", control)
        self.assertIn("research Autonomous Logistics to unlock Bitertaxis, V4 fleet charging", control)
        self.assertIn("ensure_station_power_sinks", control)
        self.assertIn("remove_station_power_sink", control)
        self.assertIn("active_station_stalls", control)
        self.assertIn("count_active_customer_stalls", control)
        self.assertIn("nearby_real_power_pole", control)
        self.assertIn("count_powered_stations", control)
        self.assertIn("Connect it within 18 tiles of your electric grid", control)
        self.assertIn("refresh_station_power_state", control)
        self.assertIn("update_station_alerts", control)
        self.assertIn("defines.events.on_robot_built_entity", control)
        self.assertIn("player.add_custom_alert(", control)
        self.assertIn('" is not connected to power."', control)
        self.assertIn('" has power for "', control)
        self.assertIn('" active stalls. Increase grid generation or storage."', control)
        self.assertIn('{type = "item", name = "accumulator"}', control)
        self.assertNotIn("defines.alert_type.no_power", control)
        self.assertNotIn('"flying-text"', control)
        self.assertNotIn("reject_unpowered_station", control)
        self.assertNotIn("reject_existing_unpowered_stations", control)
        self.assertIn('script.on_nth_tick(600', control)
        self.assertIn('commands.add_command("bitermotors-coverage"', control)
        self.assertIn("STATION_INFO_PANEL_NAME", control)
        self.assertIn("show_station_info_panel", control)
        self.assertIn("on_selected_entity_changed", control)
        self.assertIn("sync_charger_hover_overlay", control)
        self.assertIn("release_charger_hover_overlay", control)
        self.assertIn("reset_charger_hover_overlays", control)
        self.assertIn("selected.disabled_by_script = true", control)
        self.assertIn("state.entity.disabled_by_script = false", control)
        self.assertIn("on_gui_opened", control)
        self.assertIn("on_gui_closed", control)
        self.assertIn("player.gui.relative.add", control)
        self.assertIn("player.gui.relative[STATION_INFO_PANEL_NAME]", control)
        self.assertIn("player.gui.relative[ENTITY_INFO_PANEL_NAME]", control)
        self.assertIn("defines.relative_gui_type.assembling_machine_gui", control)
        self.assertIn("defines.relative_gui_type.container_gui", control)
        self.assertIn("defines.relative_gui_position.right", control)
        self.assertIn("opened_bitermotors_entities()[player.index]", control)
        self.assertNotIn("player.gui.left", control)
        self.assertIn('caption = "Biter Motors " .. config.display_name', control)
        self.assertIn('player.gui.screen.add{', control)
        self.assertIn('name = "bitermotors_station_info_close"', control)
        self.assertIn("if is_station(opened) and player.gui.screen[STATION_INFO_PANEL_NAME] then", control)
        station_open = control[control.index("script.on_event(defines.events.on_gui_opened"):
                               control.index("script.on_event(defines.events.on_gui_closed")]
        self.assertIn("player.opened = nil", station_open)
        self.assertNotIn("player.opened = panel", control)
        self.assertIn("local legacy_panel = player.gui.relative[STATION_INFO_PANEL_NAME]", control)
        self.assertIn('label = "Settlements"', control)
        self.assertIn("nearby spawners are still hostile", control)
        self.assertIn("Put a Sales Office within %d tiles", control)
        self.assertIn("Sales Office-converted customer settlements", control)
        self.assertIn('label = "Stalls"', control)
        self.assertIn('label = "Power"', control)
        self.assertIn("This site serves customer EVs and prints EV Reservations for Sales Offices", control)
        station_guidance = control[control.index("local function station_next_step"):
                                   control.index("local function show_station_info_panel")]
        self.assertNotIn("craft Prototype Roadsters", station_guidance)
        self.assertIn("Dollar output is full", control)
        self.assertIn("EV Reservation consumption are paused", control)
        self.assertIn("[Biter Motors] %s online", control)
        self.assertIn("EV Charging Network researched. Craft a separate V2 charger", control)
        self.assertIn("script.on_nth_tick(60", control)
        self.assertIn("PROSPECT_RESERVATION_RETRY_MINUTES = 5", control)
        self.assertIn("RESERVATION_SAMPLES_PER_PRINT = 60", control)
        self.assertIn("bitermotors_reservation_print_progress", control)
        self.assertIn("station_reservation_rate_per_minute", control)
        self.assertIn('label = "Prospects"', control)
        self.assertIn("New and returning prospects file one EV Reservation", control)
        self.assertIn("station_reservation_inventory", control)
        self.assertIn("generate_station_reservations", control)
        self.assertIn("top_up_station_reservations", control)
        self.assertIn("defines.inventory.chest", control)
        self.assertIn("inventory.set_filter(1, RESERVATION_NAME)", control)
        self.assertIn('label = "Reservations"', control)
        self.assertIn('label = "Stored"', control)
        self.assertNotIn("distribute_reservations", control)

    def test_charging_utilization_uses_living_vehicle_owners(self):
        control = (MOD / "control.lua").read_text()
        fleet = control[control.index("function customer_ev_fleet_size"):control.index("local function calculate_station_utilization")]
        utilization = control[control.index("local function calculate_station_utilization"):control.index("local function destroy_customer_marker_key")]

        for item_name in ["bitermotors-prototype-roadster", "bitermotors-premium-ev", "bitermotors-mass-market-ev", "bitermotors-megatruck", "bitermotors-bitertaxi-fleet"]:
            self.assertIn(f'"{item_name}"', control)
        self.assertIn("CUSTOMER_EV_SALE_RECIPES", control)
        self.assertIn("record_customer_ev_sales", control)
        self.assertIn("bitermotors_customer_ev_sales", control)
        self.assertIn('vehicles = 3', control)
        self.assertIn("historical_customer_ev_sales", control)
        self.assertIn('statistics.get_input_count("bitermotors-mass-market-ev")', control)
        self.assertIn("active_customer_vehicle_summary(force).total", fleet)
        self.assertIn("assignment.requested_stalls", utilization)
        self.assertIn("powered_station_stalls", control)
        self.assertIn("allocations_by_force", control)
        self.assertIn("refresh_station_power_state(station, allocations_by_force[force_index])", control)
        self.assertIn("customer_ev_fleet = customer_ev_fleet_size(force)", control)
        self.assertIn("Active customer EVs", control)
        self.assertIn('label = "EV capacity"', control)
        self.assertIn("market.customer_ev_fleet", control)
        self.assertIn("refresh_biter_customer_market", control)

    def test_bitermotors_biter_customer_mode(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn("biter_customer_mode_enabled", control)
        self.assertIn("return true", control)
        self.assertIn("count_covered_biter_settlements", control)
        self.assertIn('"biter-spawner"', control)
        self.assertIn('"spitter-spawner"', control)
        self.assertIn("PROSPECT_RESERVATION_RETRY_MINUTES", control)
        self.assertIn('CUSTOMER_FORCE_NAME = "bitermotors-customers"', control)
        self.assertIn("SALES_OFFICE_CUSTOMER_RADIUS = 128", control)
        self.assertIn("game.create_force(CUSTOMER_FORCE_NAME)", control)
        self.assertIn("sync_customer_settlements", control)
        self.assertIn("rendering.draw_text", control)
        self.assertIn("customer_markers", control)
        self.assertIn("destroy_customer_marker", control)
        self.assertIn('text = "$"', control)
        customer_marker = control[control.index("function draw_settlement_marker"):control.index("local function scan_biter_customer_entities")]
        self.assertNotIn("rendering.draw_circle", customer_marker)
        self.assertIn("if not is_settlement then", customer_marker)
        self.assertNotIn("rendering.draw_sprite", customer_marker)
        self.assertIn('draw_settlement_marker(entity, "market")', customer_marker)
        self.assertIn('draw_settlement_marker(entity, "blocked")', customer_marker)
        self.assertIn('marker_type == "blocked"', customer_marker)
        self.assertNotIn("blink_interval", control)
        self.assertIn("set_cease_fire", control)
        self.assertIn("force.set_cease_fire(enemy, false)", control)
        self.assertIn("force.set_cease_fire(customers, true)", control)
        self.assertIn('remote.add_interface("bitermotors"', control)
        self.assertIn("biter_customer_market", control)
        self.assertIn("covered biter settlements", control)
        self.assertNotIn("bitermotors-biter-customer-mode", control)
        self.assertNotIn("on_runtime_mod_setting_changed", control)

    def test_ai_tokens_are_dense_capital_funded_and_improvable(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        token_line = next(line for line in data.splitlines() if 'item("bitermotors-ai-token"' in line)
        self.assertIn(", 1000000, {weight = 1})", token_line)
        self.assertIn("ai_efficiency_thresholds = {1000, 10000, 100000, 1000000, 10000000, 100000000}", data)
        self.assertIn('+10% AI Tokens per cycle', data)
        self.assertIn('recipe("bitermotors-terrestrial-ai-token"', data)
        self.assertNotIn("bitermotors-orbital-ai-efficiency-", data)
        self.assertIn('ORBITAL_AI_MILESTONES = {', control)
        self.assertIn('threshold = 1000000,\n    technology = "bitermotors-orbital-cluster-training"', control)
        self.assertIn('threshold = 10000000,\n    technology = "bitermotors-grid-scale-energy"', control)
        self.assertIn('threshold = 100000000,\n    technology = "bitermotors-hyperscale-training"', control)
        self.assertIn('["bitermotors-orbital-ai-token-hyperscale"] = 100000', control)
        self.assertIn("terrestrial_datacenter.module_slots = 0", data)
        self.assertIn('terrestrial_datacenter.allowed_effects = {"consumption", "speed", "pollution", "quality"}', data)
        self.assertIn("math.floor(threshold / 10)", data)
        self.assertIn("track_ai_efficiency_progress()", control)
        self.assertIn("ai_efficiency_status", control)
        self.assertIn("function ai_efficiency_track_status", control)
        self.assertIn("function ai_tokens_per_completed_cycle", control)
        self.assertIn("if config.milestones then", control)
        self.assertIn("local bonus_cycles = math.floor(bonus_progress + 0.000001)", control)
        self.assertIn('name = "bitermotors-ai-token"', control)
        self.assertIn("Capital burn: 20 Dollars per 30-second cycle", control)
        self.assertIn("AI output:", control)
        self.assertIn("Terrestrial production tracked:", control)
        self.assertIn("terrestrial ceiling reached", control)
        self.assertIn("terrestrial_ai_tokens_generated", control)

    def test_bitertaxi_depot_economy(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        locale = (MOD / "locale/en/bitermotors.cfg").read_text()

        bitertaxi_item = next(line for line in data.splitlines() if 'item("bitermotors-bitertaxi-fleet"' in line)
        self.assertIn('"transport", "bitermotors-e[bitertaxi-fleet]", 5,', bitertaxi_item)
        self.assertIn('name = "bitermotors-bitertaxi-depot"', data)
        self.assertIn("bitertaxi_depot.inventory_size = 43", data)
        self.assertIn('"bitermotors-bitertaxi-depot-power"', data)
        self.assertIn('"10MW"', data[data.index("local bitertaxi_depot_power ="):data.index("local orbital_datacenter_core =")])
        self.assertIn('recipe("bitermotors-operate-bitertaxi-fleet", {"bitermotors-bitertaxi-depot"}', data)
        self.assertIn('unlock("bitermotors-bitertaxi-depot")', data)
        self.assertIn('unlock("bitermotors-operate-bitertaxi-fleet")', data)
        self.assertIn("BITERTAXI_CUSTOMERS_PER_VEHICLE = 5", control)
        self.assertIn("BITERTAXI_REVENUE_VEHICLE_MINUTES_PER_DOLLAR = 2", control)
        self.assertIn("BITERTAXI_ATTRITION_VEHICLE_HOURS = 60", control)
        self.assertIn("function process_bitertaxi_depots", control)
        self.assertIn("function ensure_bitertaxi_depot_power", control)
        self.assertIn("function bitertaxi_customer_allocations", control)
        self.assertIn('registered_bitermotors_entities("bitertaxi_depots", force)', control)
        self.assertIn("customer_settlement_populations()", control)
        self.assertIn("distance <= BITERTAXI_DEPOT_RADIUS * BITERTAXI_DEPOT_RADIUS", control)
        self.assertIn("available[center.unit_number] = stored > 0", control)
        self.assertIn("result[selected.unit_number] = result[selected.unit_number] + customers", control)
        self.assertIn("game.tick - cached.tick < 300", control)
        self.assertIn("function bitertaxi_dollar_output_blocked", control)
        self.assertIn("slot.count >= slot.prototype.stack_size", control)
        self.assertIn("output_blocked = bitertaxi_dollar_output_blocked(output)", control)
        self.assertIn("not snapshot.output_blocked", control)
        self.assertIn("trips and fleet attrition are paused", control)
        self.assertIn("radius = 0.25", control)
        self.assertIn("active_power_units", control)
        self.assertIn("not active_power_units[power.unit_number]", control)
        self.assertIn("bitertaxi_depot_status = function", control)
        self.assertIn("Premium Audio increases trip revenue", control)
        self.assertIn("legacy_bitertaxi_sale.enabled = false", control)
        self.assertIn("invalidate_bitertaxi_customer_allocations(entity.force)", control)
        self.assertIn("bitermotors-bitertaxi-depot=Bitertaxi Depot", locale)

    def test_easier_campaign_economy_is_consistent_in_runtime_and_prototypes(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        locale = (MOD / "locale/en/bitermotors.cfg").read_text()

        expected_counts = {
            "bitermotors-ev-charging-network": 150,
            "bitermotors-capital-scaling": 600,
            "bitermotors-terrestrial-ai": 750,
            "bitermotors-autonomous-logistics": 750,
            "bitermotors-orbital-compute": 1500,
        }
        technology_offsets = sorted(
            (data.index(f'tech("{name}"'), name, count)
            for name, count in expected_counts.items()
        )
        for index, (start, name, count) in enumerate(technology_offsets):
            end = technology_offsets[index + 1][0] if index + 1 < len(technology_offsets) else len(data)
            self.assertIn(f"    {count},", data[start:end], name)

        self.assertIn("customer_radius = 128", control)
        self.assertIn("customer_radius = 192", control)
        self.assertIn("customer_radius = 256", control)
        self.assertIn("BITERTAXI_REVENUE_VEHICLE_MINUTES_PER_DOLLAR = 2", control)
        self.assertIn("Invests 150 cycles", locale)
        self.assertIn("Invests 600 cycles", locale)

    def test_customers_can_replace_each_consumer_vehicle_generation_once(self):
        control = (MOD / "control.lua").read_text()
        aggregates = (MOD / "runtime" / "customer_aggregates.lua").read_text()

        self.assertIn("CUSTOMER_VEHICLE_REPLACEMENT_ORDER", control)
        for vehicle in [
            "bitermotors-prototype-roadster",
            "bitermotors-premium-ev",
            "bitermotors-mass-market-ev",
            "bitermotors-megatruck",
        ]:
            self.assertIn(f'"{vehicle}"', control)
        self.assertIn("ownership.purchases", control)
        self.assertIn("customer_can_purchase_vehicle(unit_number, sale.item)", control)
        self.assertIn("record_customer_population_purchase(", control)
        self.assertIn("replace_virtual_customer_vehicle(", control)
        self.assertIn("CUSTOMER_REPLACEMENT_WRECK_FRACTION = 0.05", control)
        self.assertIn("CustomerAggregates.replace_virtual", aggregates)
        self.assertIn("ensure_customer_purchase_histories()", control)
        self.assertIn("does not add another charging burden", control)
        self.assertIn("test_virtual_customer_replacement = function()", control)
        self.assertIn("prior_population = home and previous[home.settlement_key]", control)

    def test_battery_chemistry_branch_is_physical_and_productive_where_safe(self):
        data = (MOD / "data.lua").read_text()
        updates = (MOD / "data-updates.lua").read_text()
        self.assertNotIn('item("bitermotors-battery-pack"', data)
        for name in [
            "bitermotors-nickel-ore", "bitermotors-lithium-brine", "bitermotors-acidic-tailings",
            "bitermotors-high-nickel-cell", "bitermotors-lfp-cell", "bitermotors-high-energy-battery-pack",
            "bitermotors-lfp-battery-pack", "bitermotors-damaged-high-energy-battery-pack",
            "bitermotors-damaged-lfp-battery-pack",
        ]:
            self.assertIn(name, data)
        self.assertIn('initialize_patch_set("bitermotors-nickel-ore", false)', updates)
        self.assertIn('initialize_patch_set("bitermotors-lithium-brine", false)', updates)
        self.assertIn('local battery_mineral_fade = "clamp((distance - 240) / 60, 0, 1)"', updates)
        self.assertIn("local function battery_mineral_autoplace", updates)
        nickel_autoplace = updates[
            updates.index('data.raw.resource["bitermotors-nickel-ore"].autoplace'):
            updates.index('resource_autoplace.initialize_patch_set("bitermotors-lithium-brine", false)')
        ]
        lithium_autoplace = updates[
            updates.index('data.raw.resource["bitermotors-lithium-brine"].autoplace'):
            updates.index('nauvis.map_gen_settings.autoplace_controls["bitermotors-nickel-ore"]')
        ]
        self.assertIn("base_density = 1.25", nickel_autoplace)
        self.assertIn("base_spots_per_km2 = 2.0", nickel_autoplace)
        self.assertIn("base_density = 5.0", lithium_autoplace)
        self.assertIn("base_spots_per_km2 = 1.25", lithium_autoplace)
        self.assertIn('frequency = 1.0, size = 1.0, richness = 1.0', updates)
        high_pack = data[
            data.index('recipe("bitermotors-high-energy-battery-pack"'):
            data.index('recipe("bitermotors-lfp-battery-pack"')
        ]
        lfp_pack = data[
            data.index('recipe("bitermotors-lfp-battery-pack"'):
            data.index('recipe("bitermotors-clean-nickel-refining"')
        ]
        self.assertNotIn('"accumulator"', high_pack)
        self.assertIn('name = "bitermotors-high-nickel-cell", amount = 4', high_pack)
        self.assertIn('name = "steel-plate", amount = 4', high_pack)
        self.assertIn('name = "advanced-circuit", amount = 2', high_pack)
        self.assertNotIn('"accumulator"', lfp_pack)
        self.assertIn('name = "bitermotors-lfp-cell", amount = 4', lfp_pack)
        self.assertIn('name = "steel-plate", amount = 4', lfp_pack)
        self.assertIn('name = "electronic-circuit", amount = 2', lfp_pack)
        neutralization = data[
            data.index('recipe("bitermotors-tailings-neutralization"'):
            data.index('recipe("bitermotors-high-nickel-cell"')
        ]
        self.assertIn('name = "bitermotors-acidic-tailings", amount = 100', neutralization)
        self.assertIn('name = "calcite", amount = 2', neutralization)
        self.assertIn('name = "stone", amount = 2', neutralization)
        self.assertIn("}}, 5", neutralization)
        for recipe_name in [
            "bitermotors-dirty-nickel-refining",
            "bitermotors-lithium-extraction",
            "bitermotors-battery-graphite",
            "bitermotors-phosphate-extraction",
            "bitermotors-tailings-neutralization",
            "bitermotors-high-nickel-cell",
            "bitermotors-cell-scale-high-nickel",
            "bitermotors-lfp-cell",
            "bitermotors-cell-scale-lfp",
            "bitermotors-clean-nickel-refining",
            "bitermotors-clean-lithium-extraction",
            "bitermotors-clean-phosphate-extraction",
            "bitermotors-dry-high-nickel-cell",
            "bitermotors-dry-lfp-cell",
        ]:
            start = data.index(f'recipe("{recipe_name}"')
            end = data.index('recipe("', start + len('recipe("'))
            self.assertIn("allow_productivity = true", data[start:end], recipe_name)
        self.assertIn("allow_productivity = true", high_pack)
        self.assertIn("maximum_productivity = 0.1", high_pack)
        self.assertIn("allow_productivity = true", lfp_pack)
        self.assertIn("maximum_productivity = 0.1", lfp_pack)
        premium = data[data.index('recipe("bitermotors-premium-ev-cell-scale"'):data.index('recipe("bitermotors-mass-market-ev"')]
        mass = data[data.index('recipe("bitermotors-mass-market-ev"'):data.index('recipe("bitermotors-megatruck"')]
        grid_battery = data[data.index('recipe("bitermotors-grid-battery"'):data.index('recipe("bitermotors-autonomy-computer"')]
        self.assertIn('name = "bitermotors-high-energy-battery-pack", amount = 8', premium)
        self.assertIn('name = "bitermotors-lfp-battery-pack", amount = 4', mass)
        self.assertIn('name = "bitermotors-lfp-battery-pack", amount = 12', grid_battery)
        high_recovery = data[data.index('recipe("bitermotors-high-energy-battery-recovery"'):data.index('recipe("bitermotors-lfp-battery-recovery"')]
        lfp_recovery = data[data.index('recipe("bitermotors-lfp-battery-recovery"'):data.index('recipe("bitermotors-cybertrain"')]
        self.assertIn('amount = 10', high_recovery)
        self.assertIn('name = "bitermotors-high-nickel-cell", amount = 36', high_recovery)
        self.assertIn('amount = 10', lfp_recovery)
        self.assertIn('name = "bitermotors-lfp-cell", amount = 36', lfp_recovery)
        self.assertIn('allow_productivity = false', high_recovery)
        self.assertIn('allow_productivity = false', lfp_recovery)
        for damaged_pack in [
            "bitermotors-damaged-high-energy-battery-pack",
            "bitermotors-damaged-lfp-battery-pack",
        ]:
            item_start = data.index(f'item("{damaged_pack}"')
            self.assertIn('flags = {"always-show"}', data[item_start:item_start + 350])
        locale = (MOD / "locale" / "en" / "bitermotors.cfg").read_text()
        self.assertIn("bitermotors-high-nickel-cell=High-nickel cells (Chemical Plant)", locale)
        self.assertIn("bitermotors-cell-scale-high-nickel=High-nickel cells (Biterfactory)", locale)
        self.assertIn("bitermotors-lfp-cell=LFP cells (Chemical Plant)", locale)
        self.assertIn("bitermotors-cell-scale-lfp=LFP cells (Biterfactory)", locale)
        self.assertIn("one four-cell batch fills one High-energy Battery Pack", locale)
        self.assertIn("Advanced damaged battery packs are recovered as separate items", locale)
        self.assertIn("process ten packs in a Recycler", locale)
        self.assertIn("same dirty-refining precursors and cobalt", locale)
        self.assertIn("bitermotors-lithium-extraction=Dirty lithium extraction", locale)
        self.assertIn("bitermotors-phosphate-extraction=Dirty phosphate extraction", locale)
        for product_slug in ["nickel-sulfate", "lithium-carbonate", "phosphate"]:
            self.assertIn(
                f'battery_process_recipe_icon("{product_slug}", false)',
                data,
            )
            self.assertIn(
                f'battery_process_recipe_icon("{product_slug}", true)',
                data,
            )
        self.assertIn('icon = "__bitermotors__/graphics/icons/acidic-tailings.png"', data)
        self.assertIn('icon = "__base__/graphics/icons/efficiency-module-3.png"', data)
        icon_helper = data[
            data.index("local function battery_process_recipe_icon"):
            data.index("local function sale_icon")
        ]
        self.assertIn("icon_size = 256,\n      scale = 0.105", icon_helper)
        self.assertNotIn("icons[1].tint", icon_helper)
        self.assertNotIn("tint =", icon_helper)
        self.assertIn("Legacy process: produces 4 Nickel Sulfate", locale)
        self.assertIn("Improved process: produces 5 Nickel Sulfate", locale)
        self.assertIn('battery_process_recipe_icon("high-nickel-cell", true)', data)
        self.assertIn('battery_process_recipe_icon("lfp-cell", true)', data)
        self.assertIn("legacy cell recipes still require cobalt", locale)
        self.assertIn("Pair it with Clean nickel refining", locale)
        item_art_slugs = [
            "nickel-ore", "nickel-sulfate", "lithium-carbonate", "battery-graphite",
            "cobalt-concentrate", "phosphate",
            "high-nickel-cell", "lfp-cell", "high-energy-battery-pack", "lfp-battery-pack",
            "damaged-high-energy-battery-pack", "damaged-lfp-battery-pack",
        ]
        for slug in item_art_slugs:
            path = MOD / "graphics" / "icons" / f"{slug}.png"
            self.assertTrue(path.exists(), path)
            with Image.open(path) as image:
                self.assertEqual(image.size, (256, 256))
            self.assertIn(f'generated_icon("{slug}")', data)
        for slug in ["lithium-brine", "acidic-tailings"]:
            path = MOD / "graphics" / "icons" / f"{slug}.png"
            self.assertTrue(path.exists(), path)
            with Image.open(path) as image:
                self.assertEqual(image.size, (256, 256))

        pack_colors = {}
        for slug in ["high-energy-battery-pack", "lfp-battery-pack"]:
            with Image.open(MOD / "graphics" / "icons" / f"{slug}.png") as image:
                belt_icon = image.convert("RGBA").resize((32, 32), Image.Resampling.LANCZOS)
            visible = [pixel for pixel in belt_icon.get_flattened_data() if pixel[3] > 64]
            bright_colored = [
                pixel for pixel in visible
                if max(pixel[:3]) - min(pixel[:3]) > 20
                and sum(pixel[:3]) / 3 > 125
            ]
            self.assertGreater(len(bright_colored) / len(visible), 0.32, slug)
            pack_colors[slug] = tuple(
                sum(pixel[channel] for pixel in bright_colored) / len(bright_colored)
                for channel in range(3)
            )
        high_energy_color = pack_colors["high-energy-battery-pack"]
        lfp_color = pack_colors["lfp-battery-pack"]
        self.assertGreater(high_energy_color[2] - high_energy_color[0], 25)
        self.assertGreater(lfp_color[0] - lfp_color[2], 25)

        self.assertIn('nickel_ore.icon = "__bitermotors__/graphics/icons/nickel-ore.png"', data)
        self.assertIn('lithium_brine.icon = "__bitermotors__/graphics/icons/lithium-brine.png"', data)
        self.assertIn('acidic_tailings.icon = "__bitermotors__/graphics/icons/acidic-tailings.png"', data)

    def test_premium_pilot_precedes_advanced_battery_onboarding(self):
        control = (MOD / "control.lua").read_text()
        objective = control[control.index("local function current_progress_objective"):control.index("local function progress_stages")]
        for field in [
            "nickel_ore_mined", "lithium_brine_pumped", "acidic_tailings_produced",
            "nickel_sulfate_produced", "lithium_carbonate_produced",
            "high_nickel_cells_produced", "high_energy_battery_packs_produced",
            "lfp_cells_produced", "lfp_battery_packs_produced",
        ]:
            self.assertIn(field, control)
        self.assertLess(objective.index('return "Premium pilot production"'), objective.index('return "Biterfactory scale"'))
        self.assertLess(objective.index('return "Biterfactory scale"'), objective.index('return "Battery breakthrough"'))
        self.assertLess(objective.index('return "Battery breakthrough"'), objective.index('return "Battery minerals"'))
        self.assertLess(objective.index('return "Battery minerals"'), objective.index('return "Battery refining"'))
        self.assertLess(objective.index('return "Battery refining"'), objective.index('return "Battery cells"'))
        self.assertLess(objective.index('return "Battery cells"'), objective.index('return "Battery packs"'))
        self.assertIn("function count_fluid_produced", control)
        self.assertIn("get_fluid_production_statistics", control)

    def test_bitertaxi_safety_improves_automatically_with_completed_rides(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn("BITERTAXI_SAFETY_RIDES_SCALE = 1000", control)
        self.assertIn("BITERTAXI_ROUTINE_WEAR_FLOOR = 0.20", control)
        self.assertIn("function bitertaxi_safety_snapshot", control)
        self.assertIn("math.log(1 + state.completed_rides", control)
        self.assertIn("completed_rides_by_force", control)
        self.assertIn("snapshot.allocated * snapshot.power_factor / 60", control)
        self.assertIn("retirement_multiplier", control)
        self.assertIn("Safety learning:", control)
        self.assertIn("Expected retirement:", control)

    def test_cybertrain_is_extremely_fast_with_bounded_mass_sensitive_regen_and_station_charging(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        locale = (MOD / "locale" / "en" / "bitermotors.cfg").read_text()
        self.assertIn('cybertrain.max_speed = 3.0', data)
        self.assertIn('cybertrain.max_power = "6MW"', data)
        self.assertIn('fuel_acceleration_multiplier = 2.0', data)
        self.assertIn('fuel_top_speed_multiplier = 1.5', data)
        self.assertIn('cybertrain.braking_force = 40', data)
        self.assertIn('fuel_categories = {"bitermotors-cybertrain-drive"}', data)
        self.assertIn('cybertrain_charging_power.energy_source.input_flow_limit = "50MW"', data)
        self.assertIn('recipe("bitermotors-cybertrain"', data)
        self.assertIn('recipe("bitermotors-cybertrain-charging-stop"', data)
        self.assertIn('tech(\n    "bitermotors-cybertrain-logistics"', data)
        self.assertIn("CYBERTRAIN_PROCESS_BUDGET = 32", control)
        self.assertIn("local budget = math.min(#order, CYBERTRAIN_PROCESS_BUDGET)", control)
        self.assertIn("train.weight / math.max(1, #semis)", control)
        self.assertIn("CYBERTRAIN_REGEN_EFFICIENCY", control)
        self.assertIn("CYBERTRAIN_RESERVE_THRESHOLD = 10000000", control)
        self.assertIn("CYBERTRAIN_RESERVE_SPEED = 0.08", control)
        self.assertIn("battery.energy <= CYBERTRAIN_RESERVE_THRESHOLD", control)
        self.assertIn("set_cybertrain_drive_permission(entity, true)", control)
        self.assertIn("reserve_mode = battery.reserve_mode == true", control)
        self.assertIn('if not script.active_mods["bitermotors_smoke"] then return false end', control)
        self.assertIn('"test_cybertrain_reserve"', (ROOT / "scripts" / "validate-bitermotors-mod.sh").read_text())
        self.assertIn("stop.get_stopped_train()", control)
        self.assertIn("power.power_usage = CYBERTRAIN_CHARGING_POWER", control)
        self.assertIn("script.on_nth_tick(6, process_cybertrain_runtime)", control)
        self.assertIn("cybertrain_status = function", control)
        self.assertIn("vehicle.name == CYBERTRAIN_NAME", control)
        self.assertIn("bitermotors-cybertrain=Cybertrain", locale)
        self.assertIn("bitermotors-cybertrain-logistics=Cybertrain Freight", locale)
        self.assertIn('generated_icon("cybertrain")', data)
        self.assertIn('generated_icon("cybertrain-charging-stop")', data)
        self.assertIn('graphics/entity/cybertrain/cybertrain.png', data)
        self.assertIn('graphics/entity/cybertrain/cybertrain-shadow.png', data)
        self.assertIn('direction_count = 64', data)
        for filename in ["cybertrain.png", "cybertrain-shadow.png"]:
            path = MOD / "graphics" / "entity" / "cybertrain" / filename
            self.assertTrue(path.exists(), path)
            with Image.open(path) as image:
                self.assertEqual(image.size, (2048, 2048))
        self.assertIn("local function cybertrain_stop_direction(frame)", data)
        self.assertIn('graphics/entity/cybertrain-charging-stop/charging-stop.png', data)
        self.assertIn('graphics/entity/cybertrain-charging-stop/charging-stop-shadow.png', data)
        self.assertIn("north = cybertrain_stop_direction(0)", data)
        self.assertIn("west = cybertrain_stop_direction(3)", data)
        for filename in ["charging-stop.png", "charging-stop-shadow.png"]:
            path = MOD / "graphics" / "entity" / "cybertrain-charging-stop" / filename
            self.assertTrue(path.exists(), path)
            with Image.open(path) as image:
                self.assertEqual(image.size, (1024, 256))
        self.assertIn("emergency reserve speed of roughly 17 km/h", locale)

    def test_minimal_orbital_ai_endgame_replaces_launch_business_roadmap(self):
        roadmap = (ROOT / "ROADMAP.md").read_text()
        section = roadmap[
            roadmap.index("### Orbital AI Infrastructure"):
            roadmap.index("### AGI Victory")
        ]
        normalized = " ".join(section.replace("`", "").split())
        self.assertIn("uses vanilla rockets, cargo pods, and space platforms", " ".join(roadmap.split()))
        self.assertIn("Orbital Datacenter Core", normalized)
        self.assertIn("Radiator Panel", normalized)
        self.assertIn("High-density Space Solar Panel", normalized)
        self.assertIn("250 MW", normalized)
        self.assertIn("10,000 physical AI Tokens", normalized)
        self.assertIn("Space does not beam energy to the planet", normalized)

    def test_customer_population_virtualizes_beyond_visible_limits(self):
        control = (MOD / "control.lua").read_text()
        aggregates = (MOD / "runtime" / "customer_aggregates.lua").read_text()
        self.assertIn("CUSTOMER_VISIBLE_GLOBAL_LIMIT = 2000", control)
        self.assertIn("CUSTOMER_VISIBLE_PER_SETTLEMENT_LIMIT = 128", control)
        self.assertIn("population.virtual_unowned", control)
        self.assertIn("population.virtual_reserved", control)
        self.assertIn("population.virtual_by_vehicle", control)
        self.assertIn("CustomerAggregates.add_virtual", aggregates)
        self.assertIn("visible_customer_limit = CUSTOMER_VISIBLE_GLOBAL_LIMIT", control)

    def test_hyperscaler_and_ai_hater_roadmap_is_concrete(self):
        roadmap = (ROOT / "ROADMAP.md").read_text()
        self.assertIn("Hyperscale terrestrial datacenters", roadmap)
        self.assertIn("settlement opposition", roadmap)
        self.assertIn("Post-Alpha Candidates", roadmap)

    def test_agi_victory_roadmap_replaces_legacy_ending(self):
        roadmap = (ROOT / "ROADMAP.md").read_text()
        self.assertIn("### AGI Victory", roadmap)
        self.assertIn("1,000,000,000 cumulative AI Tokens", roadmap)
        self.assertIn("20,000 AGI Training Datasets", roadmap)
        self.assertIn("100 Capital Allocations", roadmap)
        self.assertIn("Sustain the controller's 10 GW draw for 60 minutes", roadmap)
        self.assertIn("physical AGI Model triggers victory", roadmap)
        self.assertNotIn("Kardashev", roadmap)

    def test_customer_reconciliation_is_not_per_second(self):
        control = (MOD / "control.lua").read_text()
        once_per_second = control[
            control.index("script.on_nth_tick(60, function()"):
            control.index("script.on_nth_tick(600, function()")
        ]
        self.assertNotIn("sync_customer_settlements()", once_per_second)
        recurring = control[
            control.index("script.on_nth_tick(600, function()"):
            control.index('remote.add_interface("bitermotors"')
        ]
        self.assertNotIn("sync_customer_settlements()", recurring)
        self.assertIn("sync_customer_service_states()", recurring)
        self.assertNotIn("MOBILE_CUSTOMERS_PER_SETTLEMENT", control)
        self.assertNotIn("entity.active = force.name ~= CUSTOMER_FORCE_NAME", control)
        self.assertNotIn("trim_customer_mobile_population", control)
        self.assertIn("entity.active = true", control)
        self.assertIn("CUSTOMER_UNIT_COLOR", control)
        self.assertIn("CUSTOMER_VEHICLE_CLASS_BY_ITEM", control)
        self.assertIn("process_customer_vehicle_variant_migration(50)", control)

    def test_market_snapshots_reject_destroyed_settlements(self):
        control = (MOD / "control.lua").read_text()
        validator = (ROOT / "scripts" / "validate-bitermotors-mod.sh").read_text()

        cache_start = control.index("function market_service_references_valid")
        cache_end = control.index("local function next_customer_charging_step", cache_start)
        cache = control[cache_start:cache_end]
        self.assertIn("if not settlement or not settlement.valid then return false end", cache)
        self.assertIn("if not assignment.station or not assignment.station.valid then return false end", cache)
        self.assertIn("market_service_references_valid(cached.service)", cache)
        self.assertIn("invalid_market_snapshot_rebuilds", cache)
        self.assertIn('mark_bitermotors_market_dirty(force, "invalid-market-snapshot")', cache)

        buyer_start = control.index("function sales_office_buyer_status")
        buyer_end = control.index("function classify_sales_office_market", buyer_start)
        buyer = control[buyer_start:buyer_end]
        self.assertIn("if settlement and settlement.valid then", buyer)
        self.assertIn('mark_bitermotors_market_dirty(office.force, "invalid-market-settlement")', buyer)

        removal_start = control.index("for _, event_name in pairs({")
        removal_end = control.index("script.on_nth_tick(1, function()", removal_start)
        removal = control[removal_start:removal_end]
        self.assertIn("removed_customer_settlement", removal)
        self.assertIn('mark_bitermotors_market_dirty(force, "settlement-removed")', removal)
        self.assertIn("if player_market_force(force) then", removal)

        self.assertIn('status = "invalid_market_snapshot"', validator)
        self.assertIn("invalid_snapshot_rebuilds", validator)
        self.assertIn("if settlement then settlement.destroy() end", validator)

    def test_vehicle_owner_classes_use_baked_prototypes(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        for class_name in ["roadster", "premium", "mass-market", "bitertaxi"]:
            self.assertIn(f'{class_name} = {{' if class_name != "mass-market" else '["mass-market"] = {', data)
        self.assertIn("0.90, g = 0.02, b = 0.01", data)
        self.assertIn("0.015, g = 0.015, b = 0.015", data)
        self.assertIn("0.82, g = 0.82, b = 0.82", data)
        self.assertIn("0.85, g = 0.52, b = 0.03", data)
        self.assertIn('prototype.name = "bitermotors-" .. base_name .. "-" .. class_name', data)
        self.assertIn("animation_mask_tint(prototype.run_animation, class)", data)
        self.assertIn("CUSTOMER_UNIT_BASE_BY_NAME[variant_name] = base_name", control)

    def test_unowned_customers_use_baked_prospect_prototypes(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        self.assertIn('label = "EV prospect (friendly)"', data)
        self.assertIn('prototype.name = "bitermotors-" .. base_name .. "-" .. class_name', data)
        self.assertIn('and {"", class.label, " - ", base.localised_name', data)
        self.assertIn('local prospect_name = "bitermotors-" .. base_name .. "-prospect"', control)
        self.assertIn("function replace_customer_prospect_entity(entity)", control)
        self.assertIn("queue.units[index] = replacement.unit_number", control)
        self.assertIn("replace_customer_prospect_entity(entity)", control)
        self.assertIn("enqueue_customer_variant_migration(entity.unit_number)", control)

    def test_sales_continue_past_charging_capacity_with_visible_consequences(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn("assigned_capacity_by_settlement_key", control)
        self.assertIn("requested_capacity_by_settlement_key", control)
        self.assertIn("powered_capacity_by_settlement_key", control)
        allocator = (MOD / "runtime" / "charger_allocator.lua").read_text()
        self.assertIn("function ChargerAllocator.allocate", allocator)
        self.assertIn("assignment.customer_requested_stalls", allocator)
        self.assertIn("demand_phase", allocator)
        self.assertIn('test_charger_allocator = function()', control)
        buyer_start = control.index("function eligible_customer_buyers")
        buyer_end = control.index("function sales_office_buyer_status", buyer_start)
        buyer_selection = control[buyer_start:buyer_end]
        self.assertIn("for key in pairs(service.served_keys)", buyer_selection)
        self.assertIn("left.load / left.capacity", buyer_selection)
        self.assertIn("if not candidate.exhausted", buyer_selection)
        self.assertNotIn("load < capacity", buyer_selection)
        self.assertIn("vehicle_count - powered_capacity", control)
        self.assertIn("Underserved vehicles: %d", control)
        self.assertIn('return "Customers hostile", BITERMOTORS_STATE_COLORS.bad', control)

    def test_worms_remain_hostile_inside_customer_coverage(self):
        control = (MOD / "control.lua").read_text()
        customer_entities = control[
            control.index("local BITER_CUSTOMER_ENTITY_NAMES"):
            control.index("local HOSTILE_WORM_ENTITY_NAMES")
        ]
        hostile_worms = control[
            control.index("local HOSTILE_WORM_ENTITY_NAMES"):
            control.index("local STATION_INFO_PANEL_NAME")
        ]

        for worm_name in [
            "small-worm-turret",
            "medium-worm-turret",
            "big-worm-turret",
            "behemoth-worm-turret",
        ]:
            self.assertNotIn(f'"{worm_name}"', customer_entities)
            self.assertIn(f'"{worm_name}"', hostile_worms)
        self.assertIn("is_hostile_worm_entity(entity)", control)
        self.assertIn("destroy_customer_marker(entity)", control)
        self.assertIn("reverted_hostile_worms", control)
        self.assertIn('entity.type == "unit" and force.name == CUSTOMER_FORCE_NAME', control)
        self.assertIn("give_customer_wander_command(entity)", control)
        self.assertIn("type = defines.command.wander", control)
        self.assertIn("distraction = defines.distraction.none", control)
        self.assertIn("CUSTOMER_WANDER_RADIUS = 8", control)
        self.assertIn("release_enemy_mobile_unit(entity)", control)
        self.assertIn("distraction = defines.distraction.by_enemy", control)
        self.assertIn("area_around(settlement.position, CUSTOMER_MOBILE_SERVICE_RADIUS)", control)
        self.assertIn("within_radius(settlement, entity, CUSTOMER_MOBILE_SERVICE_RADIUS)", control)
        self.assertIn("force.set_friend(customers, true)", control)
        self.assertIn("customers.set_friend(force, true)", control)

    def test_customer_growth_requires_service_and_keeps_worms_hostile(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn("CUSTOMER_GROWTH_STALL_MINUTES = 4", control)
        self.assertIn("customer_service_for_force", control)
        self.assertIn("accessible_stall_capacity", control)
        for capacity in [12, 20, 32, 50]:
            self.assertIn(f"evs_per_stall = {capacity}", control)
        self.assertNotIn("CUSTOMER_EVS_PER_STALL", control)
        self.assertIn("config.stalls * config.evs_per_stall", control)
        self.assertIn("service.average_evs_per_stall", control)
        self.assertIn("CUSTOMER_SERVICE_GRACE_TICKS = 3 * 60 * 60", control)
        self.assertIn("CUSTOMER_MOOD_BASE_ANGER_CHANCE = 0.05", control)
        self.assertIn("CUSTOMER_MOOD_MAX_ANGER_CHANCE = 0.25", control)
        self.assertIn("settlement_friendly_after_service_check", control)
        self.assertIn("active_stalls * config.evs_per_stall", control)
        self.assertIn("stranded_evs", control)
        self.assertIn("angry_keys", control)
        self.assertIn("process_customer_growth(force)", control)
        self.assertIn("assignment.powered_stalls or 0", control)
        self.assertIn("spare_stalls > 0", control)
        self.assertNotIn("service.stranded_evs == 0", control)
        self.assertIn("(assignment.powered_stalls or 0) >= (assignment.requested_stalls or 0)", control)
        self.assertIn("CUSTOMER_ORGANIC_GROWTH_INTERVAL_TICKS = 15 * 60 * 60", control)
        self.assertIn("CUSTOMER_ORGANIC_GROWTH_CAP_MULTIPLIER = 3", control)
        self.assertIn("grow_customer_settlement(station, state)", control)
        self.assertIn("local service = customer_service_for_force(force)", control)
        self.assertIn("assignment and assignment.requested_stalls or 0", control)
        growth = control[
            control.index("local function grow_customer_settlement"):
            control.index("local function process_customer_growth")
        ]
        self.assertIn("force = customer_force()", growth)
        self.assertIn("force = game.forces.enemy", growth)
        self.assertIn("hostile_worm_name", growth)
        self.assertIn("hostile_worm_chance", control)
        self.assertIn("return 0.25", control)
        self.assertIn("return 0.50", control)
        self.assertIn("return 0.75", control)
        self.assertIn("game.create_random_generator()", control)
        self.assertIn("local random = customer_growth_random()", growth)
        self.assertIn("random() < hostile_worm_chance(evolution)", growth)
        self.assertNotIn("Customer settlement expanded", growth)
        self.assertIn("remains friendly during its patience period", control)
        self.assertIn('summary, summary_color = string.format("%d stalls available."', control)

    def test_bitermotors_victory_is_agi_training_run(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        self.assertIn('"bitermotors-planetary-grid-controller"', data)
        self.assertIn('"bitermotors-agi-model"', data)
        self.assertIn('recipe("bitermotors-agi-training-run"', data)
        self.assertIn('tech("bitermotors-planetary-energy-grid"', data)
        self.assertIn('unlock("bitermotors-planetary-grid-controller")', data)
        self.assertNotIn('bitermotors-kardashev-type-1', data)
        self.assertNotIn('bitermotors-planetary-grid-charge', data)
        controller = data[data.index('"bitermotors-planetary-grid-controller"'):data.index('planetary_grid_controller.energy_source')]
        self.assertIn('"10GW"', controller)
        charge_recipe = data[data.index('recipe("bitermotors-agi-training-run"'):data.index('add_lab_input("lab", "bitermotors-dollar")')]
        for expected in ['name = "bitermotors-agi-training-dataset", amount = 20000', 'name = "bitermotors-capital-allocation", amount = 100', 'name = "bitermotors-grid-battery-array", amount = 100', 'name = "processing-unit", amount = 10000', 'name = "bitermotors-agi-model", amount = 1', '3600']:
            self.assertIn(expected, charge_recipe)
        self.assertIn('name = "bitermotors-ai-token", amount = 50000', data)
        capital_recipe = data[
            data.index('recipe("bitermotors-package-capital-allocation"'):
            data.index('recipe("bitermotors-agi-training-run"')
        ]
        self.assertIn('name = "bitermotors-dollar", amount = 500', capital_recipe)
        for embodied_input in [
            '"bitermotors-planetary-grid-segment"',
            '"space-science-pack"',
        ]:
            self.assertNotIn(embodied_input, charge_recipe)
        self.assertNotIn('"bitermotors-planetary-grid-segment"', data)
        self.assertNotIn("bitermotors-k1-knowledge", data)
        self.assertIn('AGI_TOKEN_GATE = 1000000000', control)
        self.assertIn('controller_has_agi_model(controller)', control)
        self.assertIn('sync_agi_training_unlock(force, true)', control)
        self.assertIn('statistics.set_output_count(', control)
        self.assertIn('"Cumulative AI Tokens"', control)
        self.assertIn('game.set_game_state', control)

    def test_late_grid_energy_upgrades_and_orbital_milestones(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()

        solar = data[data.index("local high_density_solar_array ="):data.index("local grid_battery =")]
        self.assertIn('high_density_solar_array.production = "300kW"', solar)
        self.assertIn('high_density_solar_array.next_upgrade = "bitermotors-tandem-solar-array"', solar)
        self.assertIn('tandem_solar_array.production = "3MW"', solar)

        storage = data[data.index("local grid_battery ="):data.index("local terrestrial_datacenter =")]
        self.assertIn('grid_battery.energy_source.buffer_capacity = "100MJ"', storage)
        self.assertIn('grid_battery.next_upgrade = "bitermotors-grid-battery-array"', storage)
        self.assertIn('grid_battery_array.energy_source.buffer_capacity = "1GJ"', storage)
        self.assertIn('grid_battery_array.energy_source.input_flow_limit = "50MW"', storage)
        self.assertIn('grid_battery_array.energy_source.output_flow_limit = "50MW"', storage)

        for recipe_name, output in [
            ("bitermotors-orbital-ai-token", 10000),
            ("bitermotors-orbital-ai-token-cluster", 25000),
            ("bitermotors-orbital-ai-token-grid-scale", 50000),
        ]:
            start = data.index(f'recipe("{recipe_name}"')
            end = data.find('\n  recipe("', start + 1)
            block = data[start:end]
            self.assertIn('name = "bitermotors-dollar", amount = 1', block)
            self.assertIn(f'name = "bitermotors-ai-token", amount = {output}', block)
        hyperscale_start = data.index('recipe("bitermotors-orbital-ai-token-hyperscale"')
        hyperscale_end = data.find('\n  recipe("', hyperscale_start + 1)
        hyperscale = data[hyperscale_start:hyperscale_end]
        self.assertEqual(
            2,
            hyperscale.count('name = "bitermotors-ai-token", amount = 50000'),
        )

        self.assertIn('technology = "bitermotors-orbital-cluster-training"', control)
        self.assertIn("local unlocked = track.generated >= milestone.threshold", control)
        self.assertIn("technology.enabled = unlocked", control)
        self.assertIn('unlock("bitermotors-tandem-solar-array")', data)
        self.assertIn('unlock("bitermotors-grid-battery-array")', data)

    def test_bitermotors_compute_runs_reset_when_underpowered(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn('["bitermotors-terrestrial-datacenter"] = true', control)
        self.assertIn('[ORBITAL_DATACENTER_CORE_NAME] = true', control)
        self.assertIn('["bitermotors-planetary-grid-controller"] = AGI_TRAINING_RECIPE_NAME', control)
        self.assertIn('status == defines.entity_status.low_power', control)
        self.assertIn('status == defines.entity_status.no_power', control)
        self.assertIn('entity.energy < entity.electric_buffer_size * 0.1', control)
        self.assertIn('entity.crafting_progress = 0', control)
        self.assertIn('entity.disabled_by_script = true', control)
        self.assertIn('entity.energy >= entity.electric_buffer_size * 0.9', control)
        self.assertIn('entity.disabled_by_script = false', control)
        one_tick = control[control.index("script.on_nth_tick(1"):control.index("script.on_nth_tick(6")]
        self.assertIn("reset_underpowered_compute_progress()", one_tick)
        self.assertIn("process_ev_self_drivings()", one_tick)
        self.assertIn('while processed < 32', control)
        self.assertIn('track_bitermotors_compute_machine(entity)', control)
        self.assertIn('rebuild_bitermotors_compute_machines()', control)

    def test_customer_ev_owners_physically_commute_to_chargers(self):
        control = (MOD / "control.lua").read_text()
        roadmap = (ROOT / "ROADMAP.md").read_text()
        for fragment in [
            "CUSTOMER_COMMUTE_MAX_ACTIVE = 512",
            "CUSTOMER_COMMUTE_STARTS_PER_SECOND = 8",
            "CUSTOMER_COMMUTE_SCHEDULER_BATCH = 256",
            "CUSTOMER_COMMUTE_CHARGE_SECONDS = 30",
            "CUSTOMER_COMMUTE_PATH_TIMEOUT_TICKS = 2 * 60 * 60",
            "function select_customer_commute_station",
            "function process_customer_charging_commutes",
            "defines.command.go_to_location",
            "defines.events.on_ai_command_completed",
            "handle_customer_commute_command_completed",
            "CUSTOMER_COMMUTE_RETRY_BASE_TICKS * (2 ^ (attempts - 1))",
            "fraction * (1 + rapid_charging * 0.1)",
            "customer_commute_interval_ticks",
            "customer_commute_totals",
            'label = "Charging commutes"',
            "snapshot.customer_commutes_completed > 0",
            "customer_charging_commutes = function",
            "customer_commute_timing_wheel",
            "customer_active_commutes",
            "function send_customer_home_after_charging",
            'state.phase = "returning_home"',
            "state.return_destination = destination",
        ]:
            self.assertIn(fragment, control)
        home_return = control[control.index("function send_customer_home_after_charging"):
                              control.index("function complete_customer_charging_commute")]
        self.assertIn("customer_home_settlements()[entity.unit_number]", home_return)
        self.assertIn("customer_settlement_populations()[home.settlement_key]", home_return)
        self.assertIn("population and population.surface_index", home_return)
        self.assertIn("population and population.position", home_return)
        self.assertIn("local surface = entity and entity.surface", home_return)
        self.assertIn("surface_index and surface_index ~= surface.index", home_return)
        self.assertNotIn("game.surfaces[home.surface_index]", home_return)
        self.assertNotIn("game.get_surface(home.surface_index)", home_return)
        self.assertNotIn("game.get_surface(surface_index)", home_return)
        self.assertIn("local radius = 8 +", home_return)
        self.assertIn("defines.command.go_to_location", home_return)
        self.assertIn("surface.find_non_colliding_position", home_return)
        completion = control[control.index("function complete_customer_charging_commute"):
                             control.index("function process_customer_charging_commutes")]
        self.assertIn("send_customer_home_after_charging(entity, state)", completion)
        self.assertNotIn("customer_active_commutes()[entity.unit_number] = true", home_return)
        self.assertIn("charging commutes", roadmap)

    def test_customer_scale_paths_are_cached_queued_and_event_driven(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn("function bitermotors_entity_registries", control)
        self.assertIn("function rebuild_bitermotors_entity_registries", control)
        self.assertIn("function bitermotors_market_cache", control)
        self.assertIn("local CUSTOMER_MARKET_CACHE_TICKS = 3600", control)
        self.assertIn("function refresh_customer_service_power_capacity", control)
        self.assertIn("refresh_customer_service_power_capacity(force, services_by_force[force_index])", control)
        self.assertIn("script.on_event(defines.events.on_biter_base_built", control)
        self.assertIn('mark_bitermotors_market_dirty(force, "settlement-built")', control)
        virtualized = control[
            control.index("if not benchmark and (customer_visible_count()"):
            control.index("customer_unit_registry()[entity.unit_number] = entity")
        ]
        self.assertNotIn('mark_bitermotors_market_dirty(market_force, "customer-virtualized")', virtualized)
        self.assertIn("BUYER_QUEUE_SELF_REPAIR_TICKS = 10 * 60", control)
        self.assertIn("storage.bitermotors_last_buyer_queue_self_repair_tick = game.tick", control)
        self.assertIn("game.tick - cached.tick < CUSTOMER_MARKET_CACHE_TICKS", control)
        self.assertIn("market_snapshot_cache_hits", control)
        self.assertIn("market_snapshot_builds", control)
        self.assertIn("function customer_buyer_queues", control)
        self.assertIn("function dequeue_available_buyer", control)
        self.assertIn("defines.events.on_entity_spawned", control)
        self.assertIn("event.spawner", control)
        self.assertIn("if not market_force_name then return end", control)
        self.assertIn('registered_bitermotors_entities("sales_offices")', control)
        self.assertIn('registered_bitermotors_entities("stations", force, surface)', control)
        self.assertIn('registered_bitermotors_entities("ai_machines", force)', control)
        self.assertIn("performance_status = function", control)
        self.assertIn('require("runtime.timing_wheel")', control)
        self.assertIn('require("runtime.performance_state")', control)
        self.assertIn("reconcile_bitermotors_entity_registry_step", control)
        self.assertIn("BITERMOTORS_REGISTRY_RECONCILIATION_CHUNKS_PER_STEP = 2", control)
        self.assertIn("rebuild_bitermotors_registry_reconciliation_chunks", control)
        self.assertIn("register_bitermotors_reconciliation_chunk(event.surface, event.position)", control)
        self.assertIn('mark_bitermotors_market_dirty(entity.force, "infrastructure-built")', control)
        reconciliation_start = control.index("function reconcile_bitermotors_entity_registry_step")
        reconciliation_end = control.index("function bitermotors_market_cache", reconciliation_start)
        reconciliation = control[reconciliation_start:reconciliation_end]
        self.assertIn("area = area", reconciliation)
        self.assertNotIn("name = config.names", reconciliation)
        half_second = control[
            control.index("script.on_nth_tick(30, function()"):
            control.index("script.on_nth_tick(60, function()")
        ]
        self.assertIn("reconcile_bitermotors_entity_registry_step()", half_second)
        ten_seconds = control[
            control.index("script.on_nth_tick(600, function()"):
            control.index('remote.add_interface("bitermotors"', control.index("script.on_nth_tick(600, function()"))
        ]
        self.assertNotIn("reconcile_bitermotors_entity_registry_step()", ten_seconds)
        buyer_start = control.index("function eligible_customer_buyers")
        buyer_end = control.index("function reserve_office_buyers", buyer_start)
        self.assertNotIn("pairs(customer_unit_registry())", control[buyer_start:buyer_end])
        commute_start = control.index("function process_customer_charging_commutes")
        commute_end = control.index("function handle_customer_commute_command_completed", commute_start)
        self.assertNotIn("pairs(customer_vehicle_owners())", control[commute_start:commute_end])
        ai_start = control.index("function track_ai_efficiency_progress")
        ai_end = control.index("function bitermotors_accelerated_start_enabled", ai_start)
        self.assertNotIn("find_entities_filtered", control[ai_start:ai_end])
        once_per_second = control[
            control.index("script.on_nth_tick(60, function()"):
            control.index("script.on_nth_tick(UiRefresh.interval_ticks")
        ]
        self.assertEqual(once_per_second.count("calculate_station_utilization(station.force)"), 1)
        self.assertIn("if player_market_force(force) then", once_per_second)
        self.assertIn("sync_sales_office_buyers()", once_per_second)
        self.assertNotIn("active_station_stalls(station)", once_per_second)
        self.assertIn("allocations_by_force[force_index]", once_per_second)
        self.assertIn("services_by_force[force_index]", once_per_second)
        self.assertIn("cached.tick == game.tick", control)

    def test_charger_changes_refresh_market_capacity_immediately(self):
        control = (MOD / "control.lua").read_text()
        built_start = control.index("defines.events.on_built_entity")
        built_end = control.index("defines.events.on_player_mined_entity", built_start)
        built = control[built_start:built_end]
        self.assertLess(built.index("track_bitermotors_entity(entity)"), built.index("handle_station_built(entity, event)"))
        self.assertLess(built.index('mark_bitermotors_market_dirty(entity.force, "infrastructure-built")'),
                        built.index("handle_station_built(entity, event)"))
        self.assertIn("refresh_bitermotors_infrastructure_change(entity)", built)
        refresh_start = control.index("function refresh_bitermotors_infrastructure_change")
        refresh_end = control.index("local function sync_biter_customer_diplomacy", refresh_start)
        refresh = control[refresh_start:refresh_end]
        self.assertNotIn("sync_customer_settlements()", refresh)
        self.assertIn("sync_sales_office_buyers()", refresh)
        self.assertIn("update_charger_stall_visuals(true)", refresh)
        self.assertIn("refresh_progress_panel(player)", refresh)
        removed = control[built_end:control.index("script.on_nth_tick(1", built_end)]
        self.assertIn("refresh_bitermotors_infrastructure_change(entity)", removed)
        self.assertIn('mark_bitermotors_market_dirty(entity.force, "infrastructure-removed")', removed)
        self.assertNotIn('mark_bitermotors_market_dirty(entity.force, "entity-removed")', removed)

    def test_bitermotors_scale_benchmark_and_runtime_modules_exist(self):
        timing_wheel = (MOD / "runtime/timing_wheel.lua").read_text()
        performance_state = (MOD / "runtime/performance_state.lua").read_text()
        customer_aggregates = (MOD / "runtime/customer_aggregates.lua").read_text()
        buyer_queues = (MOD / "runtime/buyer_queues.lua").read_text()
        bitertaxi_depot = (MOD / "runtime/bitertaxi_depot.lua").read_text()
        power_queue = (MOD / "runtime/power_queue.lua").read_text()
        ui_refresh = (MOD / "runtime/ui_refresh.lua").read_text()
        sales_office_market = (MOD / "runtime/sales_office_market.lua").read_text()
        benchmark = (ROOT / "scripts/benchmark-bitermotors-scale.sh").read_text()
        self.assertIn("function TimingWheel.schedule", timing_wheel)
        self.assertIn("function TimingWheel.pop_due", timing_wheel)
        self.assertIn("math.ceil(due_tick / 60)", timing_wheel)
        self.assertIn("function PerformanceState.invalidate", performance_state)
        self.assertIn("state.invalidations[reason]", performance_state)
        self.assertIn("function CustomerAggregates.rebuild", customer_aggregates)
        self.assertIn('require("runtime.customer_aggregates")', (MOD / "control.lua").read_text())
        self.assertIn("function BuyerQueues.pop_valid", buyer_queues)
        self.assertIn('require("runtime.buyer_queues")', (MOD / "control.lua").read_text())
        self.assertIn("function BitertaxiDepot.metrics", bitertaxi_depot)
        self.assertIn("function PowerQueue.next", power_queue)
        self.assertIn("interval_ticks = 300", ui_refresh)
        self.assertIn("progress_interval_ticks = 1800", ui_refresh)
        self.assertIn("function UiRefresh.should_refresh_progress", ui_refresh)
        self.assertIn("function SalesOfficeMarket.classify", sales_office_market)
        self.assertIn('require("runtime.bitertaxi_depot")', (MOD / "control.lua").read_text())
        self.assertIn('require("runtime.power_queue")', (MOD / "control.lua").read_text())
        self.assertIn('require("runtime.ui_refresh")', (MOD / "control.lua").read_text())
        self.assertIn('require("runtime.sales_office_market")', (MOD / "control.lua").read_text())
        self.assertIn("bitermotors_progress_panel_signatures", (MOD / "control.lua").read_text())
        self.assertIn("BITERMOTORS_BENCHMARK_UNITS:-20000", benchmark)
        self.assertIn("BITERMOTORS_BENCHMARK_CAPS", benchmark)
        self.assertIn("0 128 256 512", benchmark)
        self.assertIn("completed_commands", benchmark)
        self.assertIn("performance_test_seed_owner", benchmark)

    def test_bitermotors_avoids_capex_language(self):
        combined = "\n".join(
            [
                (MOD / "data.lua").read_text(),
                (MOD / "control.lua").read_text(),
                (MOD / "locale/en/bitermotors.cfg").read_text(),
                (MOD / "README.md").read_text(),
            ]
        ).lower()
        self.assertNotIn("capex", combined)
        self.assertNotIn("k1", combined)

    def test_charger_placement_prefers_power_overlay(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn("on_player_cursor_stack_changed", control)
        self.assertIn('["show-electric-network"] = enabled', control)
        self.assertIn('["show-logistic-network"] = false', control)
        self.assertIn("MapViewSettings is write-only", control)
        self.assertNotIn("local settings = player.map_view_settings", control)
        self.assertIn("function set_charger_placement_overlay(player, enabled)", control)
        self.assertIn("if not player or not player.valid or not player.connected then", control)
        self.assertIn("local ok, error_message = pcall(function()", control)
        self.assertIn("Charger placement overlay unavailable for player", control)
        self.assertIn("defines.events.on_player_left_game", control)
        self.assertIn("defines.events.on_player_removed", control)

        reads = re.findall(r"(?:local\s+\w+\s*=|return)\s*player\.map_view_settings", control)
        self.assertEqual([], reads, "LuaPlayer.map_view_settings is write-only")

    def test_friendly_customer_attack_commands_are_interrupted(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn("defines.events.on_entity_damaged", control)
        self.assertIn("attacker.force.name == CUSTOMER_FORCE_NAME", control)
        self.assertIn("give_customer_wander_command(attacker, true)", control)

    def test_player_driven_ev_impacts_trigger_bounded_customer_road_rage(self):
        control = (MOD / "control.lua").read_text()
        roadmap = (ROOT / "ROADMAP.md").read_text()

        self.assertIn('ROAD_RAGE_FORCE_NAME = "bitermotors-road-rage"', control)
        self.assertIn("event.damage_type.name ~= \"impact\"", control)
        self.assertIn("player.vehicle == vehicle", control)
        self.assertIn("ELECTRIC_VEHICLE_BATTERIES[vehicle.name]", control)
        self.assertIn("duration_ticks = 45 * 60", control)
        self.assertIn("nearby_duration_ticks = 30 * 60", control)
        self.assertIn("response_radius = 12", control)
        self.assertIn("nearby_limit = 2", control)
        self.assertIn("megatruck_duration_ticks = 60 * 60", control)
        self.assertIn("megatruck_response_radius = 15", control)
        self.assertIn("megatruck_nearby_limit = 5", control)
        self.assertIn("max_active = 256", control)
        self.assertIn('local megatruck = vehicle.name == "bitermotors-megatruck"', control)
        self.assertIn("if first_anger then", control)
        self.assertIn("math.min(limit, #candidates)", control)
        self.assertIn('label = "Road rage"', control)
        self.assertIn("road rage", roadmap)

    def test_customer_road_rage_pauses_commutes_and_expires_on_timing_wheel(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn("function customer_road_rage_timing_wheel()", control)
        self.assertIn("TimingWheel.schedule(customer_road_rage_timing_wheel()", control)
        self.assertIn("TimingWheel.pop_due(\n    customer_road_rage_timing_wheel()", control)
        self.assertIn('commute.phase = "road_rage"', control)
        self.assertIn("TimingWheel.cancel(customer_commute_timing_wheel(), unit_number)", control)
        self.assertIn("entity.force = road_rage_force()", control)
        self.assertIn("type = defines.command.attack", control)
        self.assertIn("target = target", control)
        self.assertIn("entity.force = customer_force()", control)
        self.assertIn("clear_customer_road_rage_status(entity)", control)
        self.assertIn("process_customer_road_rage()", control)
        self.assertIn("TimingWheel.cancel(customer_road_rage_timing_wheel(), unit_number)", control)
        self.assertIn("enqueue_customer_variant_migration(unit_number)", control)
        self.assertIn("if customer_road_rage_states()[unit_number] then", control)
        self.assertIn('test_customer_road_rage = function', control)
        self.assertIn('script.active_mods["bitermotors_smoke"]', control)

    def test_road_rage_force_is_hostile_only_to_player_market_forces(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn("force.name ~= ROAD_RAGE_FORCE_NAME", control)
        self.assertIn("force.set_cease_fire(road_rage, false)", control)
        self.assertIn("road_rage.set_cease_fire(force, false)", control)
        self.assertIn("customers.set_cease_fire(road_rage, true)", control)
        self.assertIn("road_rage.set_cease_fire(customers, true)", control)
        self.assertIn("road_rage.set_cease_fire(enemy, true)", control)

    def test_registered_customers_follow_home_service_not_wander_position(self):
        control = (MOD / "control.lua").read_text()
        sync = control[control.index("function sync_customer_settlements()"):
                       control.index("local function customer_growth_states()")]
        self.assertIn("local served_home_keys = {}", sync)
        self.assertIn("served_home_keys[key] = true", sync)
        self.assertIn("for unit_number, entity in pairs(customer_unit_registry()) do", sync)
        self.assertIn("served_home_keys[home.settlement_key]", sync)
        self.assertNotIn("if entity.unit_number and customer_vehicle_owners()[entity.unit_number] then", sync)

    def test_customer_service_alerts_are_entity_local_and_quiet(self):
        control = (MOD / "control.lua").read_text()
        validator = (ROOT / "scripts" / "validate-bitermotors-mod.sh").read_text()
        self.assertIn("update_customer_settlement_alerts(force, service)", control)
        self.assertIn("if vehicle_count > powered_capacity then", control)
        self.assertIn('power_missing > 0 and "mixed" or "capacity"', control)
        self.assertIn("Place or upgrade an EV charger near this settlement.", control)
        self.assertIn("EVs lack powered charging service. Restore grid power.", control)
        self.assertIn("Add or upgrade a charger and restore grid power.", control)
        self.assertIn('{type = "item", name = "bitermotors-ev-charging-station"}', control)
        self.assertIn('{type = "item", name = "accumulator"}', control)
        self.assertIn('{type = "virtual", name = "signal-red"}', control)
        self.assertIn("player.add_custom_alert(", control)
        self.assertIn("player.remove_alert{entity = settlement", control)
        self.assertIn("function update_customer_settlement_map_tags(force, disrupted)", control)
        self.assertIn("force.add_chart_tag(disruption.settlement.surface", control)
        self.assertIn("EVs underserved - add charger", control)
        self.assertIn("EVs underserved - restore power", control)
        self.assertIn("EVs underserved - charger + power", control)
        self.assertIn("if tag and tag.valid then tag.destroy() end", control)
        alert_logic = control[
            control.index("function update_customer_settlement_alerts(force, service)"):
            control.index("function ensure_seed_customer")
        ]
        self.assertNotIn("mood.was_customer", alert_logic)
        self.assertIn("underserved_chart_tags", validator)
        self.assertIn("restored charging capacity did not clear global-map tags", validator)
        self.assertIn("Custom alerts expire. Refresh persistent disruptions", control)
        self.assertNotIn("[Biter Motors] Charging disruption:", control)
        self.assertNotIn("[Biter Motors] Customer charging access restored.", control)
        self.assertNotIn("[Biter Motors] Customer settlement expanded", control)

    def test_blocked_market_spawners_get_red_dollar_markers(self):
        control = (MOD / "control.lua").read_text()
        sync = control[control.index("function sync_customer_settlements()"):
                       control.index("local function customer_growth_states()")]
        self.assertIn("local blocked_settlements = {}", sync)
        self.assertIn("blocked_settlements[key] = settlement", sync)
        self.assertIn("draw_blocked_settlement_marker(settlement)", sync)
        self.assertIn("draw_blocked_settlement_marker(settlement)", control[control.index("function sync_customer_service_states()"):
                                                                           control.index("local function customer_growth_states()")])

    def test_cached_charger_assignments_tolerate_destroyed_settlements(self):
        control = (MOD / "control.lua").read_text()
        waiting = control[
            control.index("function waiting_market_buyers_at_station"):
            control.index("function station_reservation_rate_per_minute")
        ]
        self.assertIn("if not is_station(station) then return 0 end", waiting)
        self.assertIn("if settlement and settlement.valid then", waiting)
        self.assertIn('mark_bitermotors_market_dirty(station.force, "invalid-assigned-settlement")', waiting)
        self.assertIn("service.assignment_by_settlement_key[key] == station", waiting)
        self.assertIn("customer_population_available_purchase_accounts(", waiting)
        self.assertIn("or not service.prospects_by_settlement_key then", control)
        self.assertNotIn("customer_unit_registry()", waiting)
        self.assertIn("local key = settlement and settlement.valid and", control)
        self.assertIn("if not station or not station.valid then", control)

    def test_bitermotors_stack_sizes_match_physical_scale(self):
        data = (MOD / "data.lua").read_text()
        for name in [
            "bitermotors-prototype-roadster",
            "bitermotors-premium-ev",
            "bitermotors-mass-market-ev",
            "bitermotors-megatruck",
            "bitermotors-biterfactory-module",
            "bitermotors-wrecked-ev",
        ]:
            item_line = next(line for line in data.splitlines() if f'item("{name}"' in line)
            self.assertIn(", 1", item_line, name)
        bitertaxi_line = next(line for line in data.splitlines() if 'item("bitermotors-bitertaxi-fleet"' in line)
        self.assertIn(", 5,", bitertaxi_line)
        for name in [
            "bitermotors-biterfactory-building",
            "bitermotors-biterfactory-v2",
            "bitermotors-terrestrial-datacenter",
            "bitermotors-orbital-datacenter-core",
            "bitermotors-planetary-grid-controller",
        ]:
            item_line = next(line for line in data.splitlines() if f'item("{name}"' in line)
            self.assertIn(", 1, {", item_line, name)
        for name in [
            "bitermotors-ev-charging-station",
            "bitermotors-ev-charging-station-v2",
            "bitermotors-ev-charging-station-v3",
            "bitermotors-ev-charging-station-v4",
        ]:
            item_line = next(line for line in data.splitlines() if f'item("{name}"' in line)
            self.assertIn(", 5, {", item_line, name)

    def test_bitermotors_is_nauvis_and_nauvis_orbit_only(self):
        data = (MOD / "data.lua").read_text()
        updates = (MOD / "data-updates.lua").read_text()
        final_fixes = (MOD / "data-final-fixes.lua").read_text()

        for location in [
            "vulcanus", "fulgora", "gleba", "aquilo",
            "solar-system-edge", "shattered-planet",
        ]:
            self.assertIn(f'"{location}"', final_fixes)
        for technology in [
            "space-platform-thruster",
            "planet-discovery-vulcanus",
            "planet-discovery-fulgora",
            "planet-discovery-gleba",
            "planet-discovery-aquilo",
            "metallurgic-science-pack",
            "electromagnetic-science-pack",
            "agricultural-science-pack",
            "cryogenic-science-pack",
        ]:
            self.assertIn(f'["{technology}"] = true', final_fixes)
        self.assertIn("location.hidden = true", final_fixes)
        self.assertIn("technology.hidden = true", final_fixes)
        self.assertIn('{"space-age", "spoilables"}', final_fixes)

        orbital = data[data.index('tech("bitermotors-orbital-compute"'):
                       data.index('tech("bitermotors-autonomous-logistics"')]
        self.assertIn('"space-platform"', orbital)
        self.assertIn('"space-science-pack"', orbital)
        self.assertNotIn('"electromagnetic-science-pack"', orbital)
        self.assertNotIn('"bitermotors-satellite-constellation"', orbital)

        planetary = data[data.index('tech("bitermotors-planetary-energy-grid"'):
                         data.index('local battery_material_recovery')]
        self.assertIn('"nuclear-power"', planetary)
        for science_pack in [
            "metallurgic-science-pack",
            "electromagnetic-science-pack",
            "agricultural-science-pack",
            "cryogenic-science-pack",
        ]:
            self.assertNotIn(f'"{science_pack}"', planetary)

        self.assertIn('local module_3 = module_family .. "-module-3"', updates)
        self.assertIn('{"bitermotors-dollar", 10}', updates)
        self.assertIn('epic_quality.prerequisites = {"quality-module-3", "bitermotors-terrestrial-ai"}', updates)
        self.assertIn('legendary_quality.prerequisites = {"epic-quality", "bitermotors-orbital-compute"}', updates)
        for retained in [
            "personal-roboport-mk2-equipment",
            "energy-shield-mk2-equipment",
            "cliff-explosives",
            "coal-liquefaction",
            "artillery",
        ]:
            self.assertIn(f'["{retained}"] = true', final_fixes)
        self.assertIn('rewrite_recipe("artillery-shell"', updates)
        self.assertIn('artillery.prerequisites = {"military-4", "tank", "concrete", "radar"}', updates)


if __name__ == "__main__":
    unittest.main()
