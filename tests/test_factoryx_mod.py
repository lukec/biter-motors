import json
import re
import unittest
from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / "mod" / "factoryx_0.1.0"


class FactoryXModTest(unittest.TestCase):
    def test_electric_vehicles_use_ev_audio(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        self.assertIn("__factoryx__/sound/ev-drivetrain-loop.wav", data)
        self.assertIn('name = "x-ev-reverse-warning"', data)
        self.assertIn("volume = 0.72", data)
        self.assertIn("volume = 0.58", data)
        self.assertIn("function update_ev_reverse_warnings()", control)
        self.assertIn("defines.riding.acceleration.reversing", control)
        self.assertIn("ELECTRIC_VEHICLE_BATTERIES[vehicle.name]", control)
        self.assertNotIn("ELECTRIC_VEHICLE_NAMES", control)
        self.assertIn("update_ev_reverse_warnings()", control)

    def test_sales_office_panel_explains_market_saturation(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn('label = "EV owners"', control)
        self.assertIn('return "Market saturated", FACTORYX_STATE_COLORS.warning', control)
        self.assertIn('label = "Charging"', control)
        self.assertIn('label = "Underserved"', control)
        self.assertIn("FACTORYX_STATE_COLORS", control)
        self.assertIn("add_station_info_label(state_row, state_text, state_color)", control)
        sales_panel = control[control.index("if entity.name == SALES_OFFICE_NAME then", control.index("local function show_manufacturer_info_panel")):
                              control.index("  else\n    local config = GIGAFACTORY_CONFIGS", control.index("local function show_manufacturer_info_panel"))]
        self.assertIn("add_factoryx_metric_table", sales_panel)
        self.assertNotIn("Cycle progress", sales_panel)
        self.assertNotIn("Inputs", sales_panel)
        self.assertNotIn("Outputs", sales_panel)
        self.assertNotIn('add_station_info_label(panel, "Recipe: none selected")', control)

    def test_sales_office_showroom_tracks_active_sale_recipe(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        art_script = (ROOT / "scripts/build-factoryx-art.py").read_text()
        self.assertIn('name = "x-sales-office-showroom-" .. vehicle_name', data)
        for vehicle in ["prototype-roadster", "premium-ev", "mass-market-ev", "cybertruck"]:
            self.assertIn(f'"{vehicle}"', data)
            showroom_path = MOD / f"graphics/entity/sales-office/showroom/{vehicle}.png"
            self.assertTrue(showroom_path.exists())
            with Image.open(showroom_path) as image:
                self.assertEqual(image.size, (256, 128))
        self.assertIn("SALES_OFFICE_SHOWROOM_SPRITES", control)
        self.assertIn("office.status == defines.entity_status.working", control)
        self.assertIn("function update_sales_office_showrooms()", control)
        self.assertIn("destroy_sales_office_showroom_rendering(entity.unit_number)", control)
        self.assertIn("build_sales_office_showroom_vehicles()", art_script)

    def test_sales_office_beacon_reflects_working_state(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        self.assertIn('"x-sales-office-status-green-frame-"', control)
        self.assertIn('"x-sales-office-status-red-frame-"', control)
        self.assertIn("entry.entity.status == defines.entity_status.working", control)
        self.assertIn('name = "x-sales-office-status-" .. status.color .. "-frame-" .. frame_index', data)
        self.assertNotIn('working_animation("sales-office-lights"', data)

    def test_ev_progression_is_gated_by_completed_sales(self):
        control = (MOD / "control.lua").read_text()
        data = (MOD / "data.lua").read_text()
        self.assertIn('item = "x-prototype-roadster",\n    threshold = 50', control)
        self.assertIn('item = "x-premium-ev",\n    threshold = 250', control)
        self.assertIn('item = "x-mass-market-ev",\n    threshold = 2000', control)
        self.assertIn('total_consumer_sales = true,\n    threshold = 5000', control)
        self.assertIn('sync_ev_sales_recipe_gates(force, true)', control)
        self.assertIn('not EV_SALES_GATED_RECIPES[effect.recipe]', control)
        prototype_sale = data[data.index('recipe("x-sell-prototype-roadster"'):data.index('recipe("x-sell-premium-ev"')]
        self.assertIn('}}, 60,', prototype_sale)

    def test_factoryx_manifest(self):
        info = json.loads((MOD / "info.json").read_text())
        self.assertEqual(info["name"], "factoryx")
        self.assertEqual(info["version"], "0.1.0")
        self.assertIn("space-age >= 2.1.0", info["dependencies"])

    def test_factoryx_mvp_surface(self):
        data = (MOD / "data.lua").read_text()
        for expected in [
            "x-sales-office",
            "x-dollar",
            "x-ev-reservation",
            "x-gigafactory-module",
            "x-gigafactory-building",
            "x-gigacast",
            "x-gigafactory-v2",
            "x-high-density-solar-array",
            "x-megapack",
            "x-energy-products",
            "x-ev-charging-station",
            "x-ev-charging-station-v2",
            "x-ev-charging-station-v3",
            "x-ev-charging-station-v4",
            "x-ai-token",
            "x-planetary-grid-segment",
            "x-agi-model",
            "x-agi-training-run",
            "x-agi-training-dataset",
            "x-capital-allocation",
            "x-terrestrial-datacenter",
            "x-orbital-compute-array",
            "x-planetary-grid-controller",
            "x-sell-premium-ev",
            "x-orbital-ai-token",
        ]:
            self.assertIn(expected, data)

    def test_factoryx_player_facing_name(self):
        locale = (MOD / "locale/en/factoryx.cfg").read_text()
        control = (MOD / "control.lua").read_text()
        self.assertIn("factoryx=FactoryX", locale)
        self.assertIn("x-sell-prototype-roadster=Sell hopes and dreams", locale)
        self.assertIn("x-sell-premium-ev=Sell premium product", locale)
        self.assertIn("x-premium-ev-program=EV Production Line", locale)
        self.assertIn("x-gigafactory-building=Gigafactory", locale)
        self.assertIn("x-gigafactory-v2=Gigafactory V2", locale)
        self.assertIn("x-gigacast=Gigacast", locale)
        self.assertIn("x-ev-charging-station-v2=EV Charging Station V2", locale)
        self.assertIn("x-ev-charging-station-v3=V3 Supercharger", locale)
        self.assertIn("x-ev-charging-station-v4=V4 Supercharger", locale)
        self.assertIn("x-energy-products=Energy Products", locale)
        self.assertIn("x-megapack=Megapack", locale)
        self.assertIn("x-high-density-solar-array=High-density Solar Panel", locale)
        self.assertIn("Roughly US$10,000", locale)
        settings = (MOD / "settings.lua").read_text()
        self.assertIn('name = "x-accelerated-start"', settings)
        self.assertIn("default_value = true", settings)
        self.assertIn("[FactoryX]", control)

    def test_infinite_continuous_improvement_research(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        locale = (MOD / "locale/en/factoryx.cfg").read_text()
        roadmap = (ROOT / "factoryX.md").read_text()

        for technology in [
            "x-supercharging-power-electronics",
            "x-long-range-battery",
            "x-premium-audio-systems",
        ]:
            start = data.index(f'    "{technology}"')
            block = data[start:start + 750]
            self.assertIn('max_level = "infinite"', data[data.index("local function infinite_tech"):data.index("local function infinite_tech") + 500])
            self.assertIn('type = "nothing"', block)
            self.assertNotIn('"military-science-pack"', block)

        referral_start = data.index('    "x-customer-referral-program"')
        referral_block = data[referral_start:referral_start + 750]
        self.assertIn('max_level = "infinite"', data[data.index("local function infinite_tech"):data.index("local function infinite_tech") + 500])
        self.assertIn('type = "nothing"', referral_block)
        self.assertIn('{"military-science-pack", 1}', referral_block)
        self.assertIn('{"x-dollar", 1}', referral_block)

        self.assertIn("x-premium-audio-systems=Biters love Nickelback.", locale)
        for technology, recipe, count_formula in [
            ("x-high-density-solar-productivity", "x-high-density-solar-array", "750*1.5^(L-1)"),
            ("x-megapack-productivity", "x-megapack", "750*1.5^(L-1)"),
        ]:
            start = data.index(f'    "{technology}"')
            block = data[start:start + 900]
            self.assertIn(f'recipe = "{recipe}", change = 0.1', block)
            self.assertIn(f'"{count_formula}"', block)
            self.assertIn('{"x-dollar", 1}', block)
        solar_productivity = data[data.index('    "x-high-density-solar-productivity"'):data.index('    "x-megapack-productivity"')]
        self.assertIn('recipe = "x-high-density-solar-array-batch", change = 0.1', solar_productivity)
        self.assertIn("High-density Solar Panel recipe productivity: +10% per level", locale)
        self.assertIn("Megapack recipe productivity: +10% per level", locale)
        self.assertNotIn("x-solar-cell-productivity", data)
        self.assertIn("function station_stall_power_watts", control)
        self.assertIn("sink.power_usage = watts", control)
        self.assertIn("1 + battery_level * 0.05", control)
        self.assertIn("1 - battery_level * 0.08", control)
        self.assertIn("function accelerate_consumer_ev_sales", control)
        self.assertIn("function award_robotaxi_audio_revenue", control)
        self.assertIn("1 + referral_level * 0.1", control)
        self.assertIn("continuous_improvements = function", control)

        self.assertIn("choose the nearest charger", roadmap)
        self.assertIn("resumes local wandering", roadmap)
        self.assertIn("Charging duration scales inversely with available power", roadmap)
        self.assertIn("12,000 customer units", roadmap)

    def test_factoryx_has_no_legacy_namespace(self):
        legacy_word = "front" + "ier"
        surfaces = [MOD, ROOT / "art" / "factoryx-review"]
        files = [ROOT / "factoryX.md", ROOT / "scripts" / "install-factoryx-mod.sh", ROOT / "scripts" / "validate-factoryx-mod.sh"]
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
        self.assertIn('factoryx_copy_table(FACTORYX_START_SHIP_ITEMS)', control)
        self.assertIn('remote.call("freeplay", "set_debris_items"', control)
        self.assertIn('remote.call("freeplay", "set_custom_intro_message"', control)
        self.assertIn("An advance landing party was supposed to prepare the site", control)
        self.assertIn("the crash destroyed much of its technical archive", control)
        self.assertIn("you possess machines that you cannot yet reproduce", control)
        self.assertIn("Restore red and green science as quickly as possible", control)
        self.assertIn("The Industrial Supply Chain recovers plans for Big Mining Drills", control)
        configure = control[control.index("function configure_factoryx_new_game"):control.index("function grant_factoryx_energy_jumpstart")]
        self.assertNotIn("surface.create_entity", configure)
        jumpstart = control[control.index("FACTORYX_ENERGY_JUMPSTART_ITEMS"):control.index("local STATION_GRID_CONNECTION_DISTANCE")]
        self.assertIn('["x-high-density-solar-array"] = 54', jumpstart)
        self.assertIn('["x-megapack"] = 24', jumpstart)
        self.assertIn('["substation"] = 40', jumpstart)
        self.assertIn('["roboport"] = 20', jumpstart)
        self.assertIn('["passive-provider-chest"] = 50', jumpstart)
        self.assertIn('["storage-chest"] = 50', jumpstart)
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
        self.assertIn('FACTORYX_ENERGY_JUMPSTART_QUALITY = "legendary"', control)
        self.assertIn('name = "passive-provider-chest"', control)
        self.assertIn('chest.backer_name = "Captain\'s Chest"', control)
        self.assertNotIn('player.force.add_chart_tag', control)
        self.assertIn('function seed_crash_site_salvage', control)
        self.assertIn('crash-site-spaceship-wreck-', control)
        self.assertIn('function award_small_crash_site_salvage', control)
        self.assertIn('stack = {name = "copper-plate", count = 5', control)
        self.assertIn("grant_factoryx_energy_jumpstart(player)", control)
        self.assertIn("grant_energy_jumpstart = function(player_index)", control)
        self.assertIn('["x-high-density-solar-array"] = 54', control)

    def test_cybertruck_and_ev_sales_are_balanced_as_profit(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        locale = (MOD / "locale/en/factoryx.cfg").read_text()
        locale = (MOD / "locale/en/factoryx.cfg").read_text()
        expected = {
            "x-prototype-roadster": 30,
            "x-premium-ev": 20,
            "x-mass-market-ev": 8,
            "x-cybertruck": 15,
            "x-robotaxi-fleet": 20,
        }
        for recipe_name, seconds in expected.items():
            start = data.index(f'recipe("{recipe_name}"')
            block = data[start:start + 700]
            self.assertIn(f'}}, {seconds}', block, recipe_name)
        cybertruck = data[data.index('recipe("x-cybertruck"'):data.index('recipe("x-high-density-solar-array"')]
        self.assertIn('name = "x-mass-market-ev", amount = 2', cybertruck)
        self.assertIn('name = "steel-plate", amount = 20', cybertruck)
        self.assertIn('name = "x-high-energy-battery-pack", amount = 4', cybertruck)
        self.assertNotIn("low-density-structure", cybertruck)
        self.assertNotIn("processing-unit", cybertruck)
        cybertruck_sale = data[data.index('recipe("x-sell-cybertruck"'):data.index('recipe("x-sell-megapack"')]
        self.assertIn('name = "x-dollar", amount = 2', cybertruck_sale)
        self.assertIn('name = "x-ev-reservation", amount = 1', cybertruck_sale)
        self.assertIn("}}, 10", cybertruck_sale)
        self.assertIn("x-cybertruck=Megatruck", locale)
        self.assertIn("x-sell-cybertruck=Sell Megatruck", locale)
        megatruck_tech = data[data.index('tech("x-megatruck-engineering"'):data.index('tech("x-ev-charging-network"')]
        self.assertIn('{"x-capital-scaling", "tank"}', megatruck_tech)
        self.assertIn('unlock("x-cybertruck")', megatruck_tech)
        self.assertIn('unlock("x-sell-cybertruck")', megatruck_tech)
        capital_tech = data[data.index('tech("x-capital-scaling"'):data.index('tech("x-megatruck-engineering"')]
        self.assertNotIn('unlock("x-cybertruck")', capital_tech)
        self.assertIn('technology = "x-megatruck-engineering"', control)
        self.assertIn('Research Megatruck Engineering.', control)
        self.assertNotIn("Cybertruck", locale)
        self.assertIn("Dollars of profit", locale)

    def test_factoryx_evs_are_drivable_and_charge_from_powered_stalls(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        locale = (MOD / "locale/en/factoryx.cfg").read_text()
        self.assertIn("local function copied_electric_vehicle", data)
        self.assertIn('profile.equipment_grid or "medium-equipment-grid"', data)
        self.assertIn('fuel_categories = {"x-electric-drive"}', data)
        self.assertIn('fuel_value = "1MJ"', data)
        for name in ["x-prototype-roadster", "x-premium-ev", "x-mass-market-ev", "x-cybertruck", "x-robotaxi-fleet"]:
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
        self.assertIn('filename = "__factoryx__/graphics/entity/vehicles/" .. profile.artwork .. ".png"', data)
        self.assertIn("direction_count = 64", data)
        self.assertIn("line_length = 8", data)
        self.assertIn("prototype.turret_animation = nil", data)
        self.assertIn("prototype.light_animation = nil", data)
        self.assertIn('profile.artwork .. "-shadow.png"', data)
        self.assertIn("draw_as_shadow = true", data)
        for artwork in ["prototype-roadster", "premium-ev", "mass-market-ev", "cybertruck", "robotaxi-fleet"]:
            self.assertTrue((MOD / f"graphics/entity/vehicles/{artwork}-shadow.png").exists())
        self.assertIn("x-electric-drive=Electric drive", locale)
        self.assertIn("x-electric-drive-charge=Stored battery charge", locale)
        self.assertIn("no manually inserted fuel is required", locale)
        self.assertIn("begins with a full battery", locale)
        for artwork in ["prototype-roadster", "premium-ev", "mass-market-ev", "cybertruck", "robotaxi-fleet"]:
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
        roadster = data[data.index('"x-prototype-roadster", generated_icon("prototype-roadster")', vehicle_table):
                        data.index('"x-premium-ev", generated_icon("premium-ev")', vehicle_table)]
        self.assertIn('{type = "impact", percent = -50}', roadster)
        for name, batteries in {
            "x-prototype-roadster": 1,
            "x-premium-ev": 2,
            "x-mass-market-ev": 1,
            "x-cybertruck": 4,
            "x-robotaxi-fleet": 2,
        }.items():
            self.assertIn(f'["{name}"] = {batteries}', control)

    def test_empty_customer_settlements_seed_initial_mobile_buyer(self):
        control = (MOD / "control.lua").read_text()

        self.assertIn("function ensure_seed_customer(settlement, market_force)", control)
        self.assertIn('settlement.name == "spitter-spawner" and "small-spitter" or "small-biter"', control)
        self.assertIn('mark_factoryx_market_dirty(market_force, "settlement-seed-customer")', control)
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
        self.assertIn('label = "Buyers"', control)
        self.assertIn("Waiting for an unassigned buyer from a powered settlement", control)
        self.assertIn("function rebuild_customer_settlement_population_cache()", control)
        self.assertIn("function ensure_customer_settlement_population_cache()", control)
        self.assertIn("ensure_customer_settlement_population_cache()", control)
        self.assertIn("rebuild_customer_vehicle_aggregates()", control)
        self.assertIn("rebuild_customer_buyer_queues()", control)
        self.assertIn("customer_population_records = population_records", control)
        self.assertIn("repair_customer_populations = function()", control)
        self.assertIn("sales_office_status = function(force_name)", control)
        self.assertIn("sync_sales_offices = function()", control)
        self.assertNotIn("function rehome_customer_buyer", control)
        self.assertNotIn("function dequeue_rehomed_buyer", control)
        self.assertNotIn("dequeue_rehomed_buyer(office, pool.key)", control)
        eligible = control[control.index("function eligible_customer_buyers"):
                           control.index("function sales_office_buyer_status")]
        self.assertIn("dequeue_available_buyer(pool.queue, office, pool.key)", eligible)
        self.assertIn("population.virtual_unowned", eligible)

    def test_ev_drivers_see_charge_zones_and_live_charging_indicator(self):
        control = (MOD / "control.lua").read_text()

        self.assertIn("function refresh_ev_driver_overlays()", control)
        self.assertIn("local vehicle = player.vehicle", control)
        self.assertIn("config.vehicle_charge_radius", control)
        self.assertIn("vehicle_charge_radius = 8", control)
        self.assertEqual(3, control.count("vehicle_charge_radius = 10"))
        self.assertIn("dx * dx + dy * dy <= 256 * 256", control)
        self.assertIn('sprite = "item/x-electric-drive-charge"', control)
        self.assertIn('string.format("CHARGING %d%%", percent)', control)
        self.assertIn("storage.factoryx_vehicle_charge_activity[vehicle.unit_number] = game.tick", control)
        self.assertIn("refresh_ev_driver_overlays()", control)
        self.assertIn("defines.events.on_player_driving_changed_state", control)
        self.assertIn("state.market_generation ~= (factoryx_market_generation()[vehicle.force.index] or 0)", control)
        self.assertIn("destroy_ev_driver_overlay(event.player_index)", control)

    def test_ev_enter_and_exit_show_a_two_second_battery_popup(self):
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
        self.assertIn("is_electric_vehicle(vehicle) or vehicle.name == ELECTRIC_SEMI_NAME", control)
        self.assertIn("local alpha = math.min(1, remaining / EV_BATTERY_POPUP_FADE_TICKS)", control)
        self.assertIn("script.on_nth_tick(6, update_ev_battery_popups)", control)

    def test_quality_scales_physical_assets_not_abstract_outputs(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        self.assertIn("station.quality and station.quality.level", control)
        self.assertIn("1 + quality_level * 0.1", control)
        self.assertIn("ELECTRIC_VEHICLE_BATTERIES[entity.name] + math.floor(quality_level / 2)", control)
        for recipe_name in [
            "x-sell-prototype-roadster",
            "x-sell-cybertruck",
            "x-terrestrial-ai-token",
            "x-orbital-ai-token",
            "x-agi-training-run",
        ]:
            self.assertIn(f'"{recipe_name}"', data[data.index("for _, recipe_name in pairs({", data.index("allow_productivity = false")):])
        self.assertIn("data.raw.recipe[recipe_name].allow_quality = false", data)

    def test_sales_office_uses_distinct_test_art(self):
        data = (MOD / "data.lua").read_text()
        self.assertIn("__factoryx__/graphics/icons/sales-office.png", data)
        self.assertIn("__factoryx__/graphics/entity/sales-office/sales-office.png", data)
        self.assertIn("sales_office.graphics_set", data)
        self.assertTrue((MOD / "graphics/icons/sales-office.png").exists())
        self.assertTrue((MOD / "graphics/entity/sales-office/sales-office.png").exists())

    def test_factoryx_selected_art_is_wired_for_playtest_prototypes(self):
        data = (MOD / "data.lua").read_text()
        for slug in [
            "ev-charging-station",
            "ev-charging-station-v2",
            "ev-charging-station-v3",
            "ev-charging-station-v4",
            "terrestrial-datacenter",
            "orbital-compute-array",
            "ev-reservation",
            "gigafactory-module",
            "ai-token",
            "prototype-roadster",
            "premium-ev",
            "mass-market-ev",
            "robotaxi-fleet",
            "small-launch-service",
            "reusable-booster",
            "reusable-launch-service",
            "satellite-bus",
            "ground-station-network",
            "datacenter-rack",
            "gigacast",
            "planetary-grid-segment",
            "agi-model",
            "planetary-grid-controller",
            "robotaxi-service-center",
        ]:
            self.assertIn(f'generated_icon("{slug}")', data)
            icon_path = MOD / f"graphics/icons/{slug}.png"
            self.assertTrue(icon_path.exists())
            with Image.open(icon_path) as image:
                alpha = image.convert("RGBA").getchannel("A")
                self.assertEqual(alpha.getpixel((0, 0)), 0)
                self.assertGreater(alpha.histogram()[0], image.width * image.height * 0.1)
        group_icon = MOD / "graphics/icons/factoryx-group.png"
        self.assertTrue(group_icon.exists())
        self.assertIn("__factoryx__/graphics/icons/factoryx-group.png", data)
        progress_shortcut = data[
            data.index('name = "x-open-factoryx-progress"') - 40:
            data.index('name = "x-toggle-sales-office-coverage"')
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
        for slug in ["robotaxi-service-center", "planetary-grid-controller"]:
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
        self.assertIn('generated_entity_animation("orbital-compute-array")', data)
        for slug in [
            "ev-charging-station",
            "ev-charging-station-v2",
            "ev-charging-station-v3",
            "ev-charging-station-v4",
            "terrestrial-datacenter",
            "orbital-compute-array",
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

    def test_factoryx_free_art_pipeline_is_wired_and_reviewable(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        animation_sizes = {
            "sales-office-status-green.png": (512, 64),
            "sales-office-status-red.png": (512, 64),
            "charger-stall-idle.png": (256, 32),
            "charger-stall-low.png": (256, 32),
            "charger-stall-medium.png": (256, 32),
            "charger-stall-full.png": (256, 32),
            "charger-stall-overload.png": (256, 32),
            "charger-stall-charging.png": (256, 32),
            "gigafactory-v1-activity.png": (4096, 512),
            "gigafactory-v2-activity.png": (4096, 512),
            "gigafactory-loading-lights.png": (4096, 128),
            "datacenter-cooling-fans.png": (1024, 64),
            "robotaxi-dispatch-lights.png": (1024, 64),
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
            "gigafactory",
            "terrestrial-ai",
            "autonomous-logistics",
            "planetary-energy-grid",
            "achieving-agi",
        ]:
            path = MOD / "graphics/technology" / f"{technology}.png"
            self.assertTrue(path.exists(), technology)
            with Image.open(path) as image:
                self.assertEqual(image.size, (256, 256))

        self.assertIn('"__factoryx__/graphics/technology/factoryx-tech-badge.png"', data)
        for clean_subject in [
            "sales-office",
            "ev-charging-station-v2",
            "terrestrial-datacenter",
            "robotaxi-service-center",
            "planetary-grid-controller",
        ]:
            self.assertIn(f'"__factoryx__/graphics/icons/{clean_subject}.png"', data)

        self.assertIn('working_animation(activity_slug, 512, 512, 0.325', data)
        self.assertIn('working_animation("gigafactory-loading-lights", 512, 128, 0.325', data)
        self.assertIn('tier == 2 and "gigafactory-v2-activity" or "gigafactory-v1-activity"', data)
        self.assertIn('working_animation("datacenter-cooling-fans"', data)
        self.assertIn('working_animation("grid-charge-stages"', data)
        self.assertIn('rendering.draw_sprite{', control)
        self.assertIn("function update_charger_stall_visuals(force_refresh)", control)
        self.assertIn('scale = 0.75', control)
        self.assertIn('scale = 0.78', control)
        self.assertIn('object.sprite = "x-charger-stall-" .. state .. "-frame-" .. staggered_frame', control)
        self.assertIn('sprite_prefix = "x-robotaxi-dispatch-lights-frame-"', control)
        self.assertIn("entry.object.sprite = entry.sprite_prefix .. frame_index", control)
        self.assertIn("update_factoryx_runtime_visuals()", control)

        qa = ROOT / "art/factoryx-qa/index.html"
        manifest = json.loads((qa.parent / "art-manifest.json").read_text())
        page = qa.read_text()
        self.assertTrue(qa.exists())
        self.assertEqual(manifest["paid_generation_count"], 3)
        self.assertIn("FactoryX Artwork QA", page)
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
        self.assertNotIn('sprite_prefix = "x-charger-status-lights-frame-"', control)

    def test_sales_office_starts_with_showroom_and_charger(self):
        data = (MOD / "data.lua").read_text()
        sales_tech = data[data.index('tech("x-sales-office"'):data.index('tech("x-premium-ev-program"')]
        premium_tech = data[data.index('tech("x-premium-ev-program"'):data.index('tech("x-capital-scaling"')]
        prototype_recipe = data[data.index('recipe("x-prototype-roadster"'):data.index('recipe("x-premium-ev"')]
        first_sale_recipe = data[data.index('recipe("x-sell-prototype-roadster"'):data.index('recipe("x-sell-premium-ev"')]
        self.assertIn('unlock("x-sales-office")', sales_tech)
        self.assertIn('{"automobilism", "electric-engine", "chemical-science-pack"}', sales_tech)
        self.assertIn('{"chemical-science-pack", 1}', sales_tech)
        self.assertIn('unlock("x-ev-charging-station")', sales_tech)
        self.assertIn('unlock("x-sell-prototype-roadster")', sales_tech)
        self.assertNotIn('unlock("x-prototype-roadster")', sales_tech)
        self.assertNotIn('unlock("x-sell-prototype-roadster")', premium_tech)
        self.assertIn('{"x-dollar", 1}', premium_tech)
        self.assertIn('    250,', premium_tech)
        self.assertNotIn('unlock("x-gigafactory-module")', premium_tech)
        self.assertNotIn('unlock("x-gigafactory-building")', premium_tech)
        self.assertIn('{{type = "item", name = "x-dollar", amount = 2}}, 60', first_sale_recipe)
        self.assertIn('name = "x-ev-reservation", amount = 1', first_sale_recipe)
        self.assertIn('"car"', prototype_recipe)
        self.assertIn('"battery"', prototype_recipe)
        self.assertIn('"advanced-circuit"', prototype_recipe)
        self.assertNotIn('"x-battery-pack"', prototype_recipe)
        self.assertNotIn('"x-electric-drivetrain"', prototype_recipe)

    def test_premium_ev_loop_is_concrete_and_guided(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        battery_recipe = data[data.index('recipe("x-high-energy-battery-pack"'):data.index('recipe("x-clean-nickel-refining"')]
        drivetrain_recipe = data[data.index('recipe("x-electric-drivetrain"'):data.index('recipe("x-prototype-roadster"')]
        premium_ev_recipe = data[data.index('recipe("x-premium-ev"'):data.index('recipe("x-mass-market-ev"')]
        premium_sale_recipe = data[data.index('recipe("x-sell-premium-ev"'):data.index('recipe("x-sell-mass-market-ev"')]

        self.assertIn('{"advanced-crafting", "x-vertical-integration"}', battery_recipe)
        self.assertIn('"accumulator"', battery_recipe)
        self.assertIn('"x-high-nickel-cell"', battery_recipe)
        self.assertIn('"advanced-circuit"', battery_recipe)
        self.assertNotIn('"steel-plate"', battery_recipe)
        self.assertIn('{"advanced-crafting"}', drivetrain_recipe)
        self.assertIn('"electric-engine-unit"', drivetrain_recipe)
        self.assertIn('"advanced-circuit"', drivetrain_recipe)
        self.assertIn('"copper-cable"', drivetrain_recipe)
        self.assertNotIn('"iron-gear-wheel"', drivetrain_recipe)
        self.assertNotIn('"steel-plate"', drivetrain_recipe)
        self.assertIn('name = "x-ev-reservation", amount = 1', premium_sale_recipe)
        self.assertIn('"car"', premium_ev_recipe)
        self.assertIn('"x-high-energy-battery-pack"', premium_ev_recipe)
        self.assertIn('"x-electric-drivetrain"', premium_ev_recipe)
        self.assertNotIn('"plastic-bar"', premium_ev_recipe)
        self.assertNotIn('"steel-plate"', premium_ev_recipe)
        self.assertIn('{"advanced-crafting", "x-vehicle-assembly"}', premium_ev_recipe)
        self.assertIn('{{type = "item", name = "x-dollar", amount = 1}}, 30', premium_sale_recipe)
        self.assertIn('"x-sell-premium-ev"', control)
        self.assertIn("EV Production Line researched. Premium EV tooling is ready, but production requires 50 completed Prototype Roadster sales", control)
        self.assertIn("Energy Products researched. Upgrade conventional solar fields with High-density Solar Panels", control)
        self.assertIn("GIGAFACTORY_PRODUCTION_GATE = 100", control)
        self.assertIn("function sync_gigafactory_production_gate", control)
        gate = control[
            control.index("function sync_gigafactory_production_gate"):
            control.index("function customer_ev_fleet_size")
        ]
        self.assertIn('count_item_produced(force, PREMIUM_EV_NAME)', gate)
        self.assertIn('and researched(force, "x-energy-products")', gate)
        self.assertIn('"x-gigafactory-module", "x-gigafactory-building", HIGH_DENSITY_SOLAR_BATCH_RECIPE,', control)
        self.assertIn('"x-cell-scale-high-nickel"', gate)
        self.assertIn("Industrial scale unlocked: %d Premium EVs produced and Energy Products researched", control)
        self.assertIn("sync_gigafactory_production_gate(force, true)", control)
        self.assertIn('"Premium pilot production"', control)
        self.assertIn("snapshot.gigafactory_production_gate", control)
        self.assertIn("Premium EV sales are working. Next: build EV Charging Network, then research Mass-market EV Production", control)
        self.assertIn("factoryx_first_premium_ev_sales", control)

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
        self.assertIn('label = "Next load step"', control)
        self.assertIn('"%d EV sale%s -> +%.0f kW"', control)
        self.assertIn("next_customer_charging_step", control)
        self.assertIn("next_charging_step = next_charging_step", control)
        self.assertIn('label = "Next grid load"', control)
        self.assertIn('"No spare stalls; add charger"', control)
        self.assertIn('"Research Energy Products before factory scale."', control)
        objective = control[
            control.index("local function current_progress_objective"):
            control.index("function progress_objective_icon")
        ]
        self.assertLess(
            objective.index('elseif not snapshot.energy_products_researched then'),
            objective.index('elseif snapshot.gigafactories == 0 and snapshot.gigafactories_v2 == 0 then'),
        )

    def test_tier_two_modules_are_terrestrial_capital_research(self):
        updates = (MOD / "data-updates.lua").read_text()
        module_rewrite = updates[
            updates.index("-- Tier 2 modules are terrestrial FactoryX capital investments"):
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
        self.assertIn('prerequisites[#prerequisites + 1] = "x-sales-office"', module_rewrite)
        self.assertIn('ingredient_name == "space-science-pack"', module_rewrite)
        self.assertIn('{"x-dollar", ingredient.amount or ingredient[2] or 1}', module_rewrite)
        self.assertIn("mark_factoryx_technology(technology, technology.icon)", module_rewrite)

    def test_sales_recipes_show_the_product_with_a_coin_badge(self):
        data = (MOD / "data.lua").read_text()
        self.assertIn("local function sale_icon(product_icons)", data)
        self.assertIn('icon = "__base__/graphics/icons/coin.png"', data)
        expected_icons = {
            "x-sell-prototype-roadster": 'sale_icon(generated_icon("prototype-roadster"))',
            "x-sell-premium-ev": 'sale_icon(generated_icon("premium-ev"))',
            "x-sell-mass-market-ev": 'sale_icon(generated_icon("mass-market-ev"))',
            "x-sell-megapack": "sale_icon(megapack_icon)",
            "x-sell-small-launch": 'sale_icon(generated_icon("small-launch-service"))',
            "x-sell-reusable-launch": 'sale_icon(generated_icon("reusable-launch-service"))',
            "x-sell-robotaxi-fleet": 'sale_icon(generated_icon("robotaxi-fleet"))',
        }
        for recipe_name, expected_icon in expected_icons.items():
            start = data.index(f'recipe("{recipe_name}"')
            block = data[start:start + 650]
            self.assertIn(f"icons = {expected_icon}", block)

    def test_terrestrial_ai_and_robotaxi_form_a_complete_pre_space_loop(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        locale = (MOD / "locale/en/factoryx.cfg").read_text()

        terrestrial_tech = data[
            data.index('tech("x-terrestrial-ai"'):
            data.index('tech("x-orbital-compute"')
        ]
        autonomous_tech = data[
            data.index('tech("x-autonomous-logistics"'):
            data.index('tech("x-planetary-energy-grid"')
        ]
        small_launch_tech = data[
            data.index('tech("x-small-orbital-launch"'):
            data.index('tech("x-reusable-launch"')
        ]
        token_recipe = data[
            data.index('recipe("x-terrestrial-ai-token"'):
            data.index('recipe("x-orbital-ai-token"')
        ]
        robotaxi_recipe = data[
            data.index('recipe("x-robotaxi-fleet"'):
            data.index('recipe("x-robotaxi-service-center"')
        ]
        datacenter_entity = data[
            data.index('local terrestrial_datacenter = copied_assembler('):
            data.index('local orbital_compute_array = copied_assembler(')
        ]

        self.assertIn('{"x-capital-scaling", "x-energy-products", "processing-unit"}', terrestrial_tech)
        self.assertNotIn("x-satellite-constellation", terrestrial_tech)
        self.assertNotIn("space-science-pack", terrestrial_tech)
        self.assertIn("    1000,", terrestrial_tech)
        for ingredient in [
            "automation-science-pack",
            "logistic-science-pack",
            "chemical-science-pack",
            "production-science-pack",
            "utility-science-pack",
            "x-dollar",
        ]:
            self.assertIn(ingredient, terrestrial_tech)

        self.assertIn('recipe("x-terrestrial-ai-token", {"x-datacenter"}', token_recipe)
        self.assertIn('name = "x-dollar", amount = 20', token_recipe)
        self.assertIn('name = "x-ai-token", amount = 20', token_recipe)
        self.assertIn("}}, 30", token_recipe)
        self.assertIn('"8MW"', datacenter_entity)
        self.assertIn('collision_box = {{-2.9, -2.9}, {2.9, 2.9}}', datacenter_entity)
        self.assertIn('selection_box = {{-3, -3}, {3, 3}}', datacenter_entity)
        self.assertIn('generated_entity_animation("terrestrial-datacenter", 0.36, {', datacenter_entity)

        self.assertIn('{"x-terrestrial-ai", "logistic-robotics", "production-science-pack", "utility-science-pack"}', autonomous_tech)
        for ingredient in [
            "automation-science-pack",
            "logistic-science-pack",
            "chemical-science-pack",
            "production-science-pack",
            "utility-science-pack",
            "x-ai-token",
            "x-dollar",
        ]:
            self.assertIn(ingredient, autonomous_tech)
        self.assertNotIn('"logistic-system"', autonomous_tech)
        self.assertNotIn("space-science-pack", autonomous_tech)
        self.assertIn('{"x-mass-vehicle-assembly"}', robotaxi_recipe)
        self.assertNotIn('{"advanced-crafting"}', robotaxi_recipe)
        self.assertIn('{"rocket-silo", "x-autonomous-logistics"}', small_launch_tech)
        self.assertIn('data.raw.technology["x-small-orbital-launch"].enabled = false', data)

        self.assertIn('ROBOTAXI_SALE_RECIPE = "x-sell-robotaxi-fleet"', control)
        self.assertIn("announce_first_robotaxi_service", control)
        self.assertNotIn("launch_technology.enabled = true", control)
        self.assertIn("v4_recipe.enabled = true", control)
        self.assertIn("Robotaxi service is producing recurring profit", control)
        self.assertIn("launch vanilla cargo rockets", control)
        self.assertIn("robotaxi_sale_complete", control)
        self.assertIn("Operate the Robotaxi service", control)
        self.assertIn("Cumulative AI Tokens", control)
        self.assertIn("snapshot.ai_tokens_produced < 1000", control)
        self.assertIn("Generate 1,000 AI Tokens", control)
        self.assertIn('power = "8 MW"', control)
        self.assertIn("20 Dollars", locale)
        self.assertIn("Each cycle consumes 20 Dollars, draws 8 MW", locale)
        self.assertIn("stockpile 1,000 Tokens for Autonomous Logistics", locale)

    def test_factoryx_orbital_compute_is_space_bound(self):
        data = (MOD / "data.lua").read_text()
        orbital_entity = data.index('local orbital_compute_array = copied_assembler(')
        orbital_recipe = data.index('recipe("x-orbital-ai-token"')
        self.assertIn('property = "gravity"', data[orbital_entity:orbital_entity + 800])
        self.assertIn('property = "gravity"', data[orbital_recipe:orbital_recipe + 1200])

    def test_factoryx_recipes_use_factorio_2_1_categories_field(self):
        data = (MOD / "data.lua").read_text()
        self.assertIn("categories = categories", data)
        self.assertIn("vertically_integrated_intermediates", data)
        self.assertNotIn("category = categories[1]", data)
        self.assertIn("if #ingredients > 4 then", data)
        self.assertIn("has more than four ingredients", data)

    def test_factoryx_uses_vanilla_crafting_tabs(self):
        data = (MOD / "data.lua").read_text()
        locale = (MOD / "locale/en/factoryx.cfg").read_text()

        self.assertNotIn('type = "item-group"', data)
        self.assertNotIn("[item-group-name]", locale)
        for subgroup, group in [
            ("x-factoryx-infrastructure", "production"),
            ("x-factoryx-components", "intermediate-products"),
            ("x-factoryx-capital", "intermediate-products"),
        ]:
            start = data.index(f'name = "{subgroup}"')
            block = data[start:start + 220]
            self.assertIn(f'group = "{group}"', block)
            self.assertIn(f"{subgroup}=", locale)

        for name, subgroup in [
            ("x-prototype-roadster", "transport"),
            ("x-premium-ev", "transport"),
            ("x-high-density-solar-array", "energy"),
            ("x-reusable-booster", "space-related"),
            ("x-ai-token", "science-pack"),
            ("x-sales-office", "x-factoryx-infrastructure"),
            ("x-high-energy-battery-pack", "x-factoryx-components"),
            ("x-dollar", "x-factoryx-capital"),
            ("x-ev-reservation", "raw-material"),
        ]:
            self.assertIn(f'item("{name}"', data)
            item_start = data.index(f'item("{name}"')
            self.assertIn(f'"{subgroup}"', data[item_start:item_start + 300])

        for name, subgroup in [
            ("x-prototype-roadster", "transport"),
            ("x-high-density-solar-array", "energy"),
            ("x-reusable-booster", "space-related"),
            ("x-terrestrial-ai-token", "science-pack"),
            ("x-sales-office", "x-factoryx-infrastructure"),
            ("x-high-energy-battery-pack", "x-factoryx-components"),
            ("x-sell-prototype-roadster", "x-factoryx-capital"),
        ]:
            recipe_start = data.index(f'recipe("{name}"')
            self.assertIn(f'"{subgroup}"', data[recipe_start:recipe_start + 300])

        for legacy_subgroup in [
            "x-buildings", "x-mobility", "x-energy", "x-space", "x-compute", "x-economy"
        ]:
            self.assertNotIn(f'"{legacy_subgroup}"', data)

    def test_factoryx_repairs_and_reports_progression_integrity(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn("repair_researched_factoryx_unlocks", control)
        self.assertIn("technology.prototype.effects", control)
        self.assertIn('effect.type == "unlock-recipe"', control)
        self.assertIn("recipe.enabled = true", control)
        self.assertIn("progression_integrity_status", control)
        self.assertIn("progression_integrity = function", control)
        sync_start = control.index("local function sync_force_unlocks")
        self.assertIn(
            "repair_researched_factoryx_unlocks(force)",
            control[sync_start:sync_start + 250],
        )

    def test_factoryx_labs_accept_capital_and_late_science(self):
        data = (MOD / "data.lua").read_text()
        for input_name in ["x-dollar", "x-ai-token"]:
            self.assertIn(f'add_lab_input("lab", "{input_name}")', data)
            self.assertIn(f'add_lab_input("biolab", "{input_name}")', data)
        self.assertNotIn('add_lab_input("lab", "x-planetary-grid-segment")', data)
        self.assertNotIn('add_lab_input("biolab", "x-planetary-grid-segment")', data)

    def test_factoryx_gigafactory_module_is_an_early_production_cell(self):
        data = (MOD / "data.lua").read_text()
        module_recipe = data.index('recipe("x-gigafactory-module"')
        module_block = data[module_recipe:module_recipe + 900]
        for expected in [
            '"x-dollar"',
            '"assembling-machine-2"',
            '"lab"',
            '"refined-concrete"',
        ]:
            self.assertIn(expected, module_block)
        self.assertIn('name = "x-dollar", amount = 10', module_block)
        self.assertIn('name = "assembling-machine-2", amount = 5', module_block)
        self.assertIn('name = "lab", amount = 5', module_block)
        self.assertIn('name = "refined-concrete", amount = 50', module_block)
        self.assertNotIn('"assembling-machine-3"', module_block)
        self.assertNotIn('"express-transport-belt"', module_block)
        self.assertNotIn('"fast-transport-belt"', module_block)

    def test_gigafactory_v1_is_large_and_builds_premium_evs(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        entity = data[data.index('local gigafactory = copied_assembler('):data.index('local terrestrial_datacenter = copied_assembler(')]
        recipe = data[data.index('recipe("x-gigafactory-building"'):data.index('recipe("x-dirty-nickel-refining"')]
        mass_ev = data[data.index('recipe("x-mass-market-ev"'):data.index('recipe("x-high-density-solar-array"')]

        self.assertIn('"x-gigafactory-building"', entity)
        self.assertIn('{"advanced-crafting", "x-vehicle-assembly", "x-energy-products", "x-energy-products-batch", "x-vertical-integration"}', entity)
        self.assertIn('"20MW"', entity)
        self.assertIn('\n  4\n)', entity)
        self.assertIn('gigafactory.effect_receiver = {base_effect = {productivity = 0.5}}', entity)
        self.assertIn('gigafactory.max_health = 5000', entity)
        self.assertIn('gigafactory.module_slots = 8', entity)
        self.assertIn('"productivity"', entity)
        self.assertIn('collision_box = {{-4.4, -4.4}, {4.4, 4.4}}', entity)
        self.assertIn('selection_box = {{-4.5, -4.5}, {4.5, 4.5}}', entity)
        self.assertIn('gigafactory.graphics_set = gigafactory_animation()', entity)
        self.assertIn('gigafactory.fast_replaceable_group = "x-gigafactory"', entity)
        self.assertIn('gigafactory.next_upgrade = "x-gigafactory-v2"', entity)
        self.assertIn('LOGISTIC_SYSTEM_TECH_NAME = "logistic-system"', control)
        self.assertNotIn("unlock_gigafactory_logistics", control)
        self.assertNotIn("Gigafactory logistics online", control)
        self.assertIn("logistic_system.enabled = unlocked", control)
        self.assertIn("Gigafactory construction, High-density Solar Panel mass production, and Logistic System research are now available", control)
        updates = (MOD / "data-updates.lua").read_text()
        logistic_rewrite = updates[
            updates.index('local logistic_system_tech = data.raw.technology["logistic-system"]'):
            updates.index("-- Tier 2 modules are terrestrial FactoryX capital investments")
        ]
        self.assertIn('prerequisites = {"logistic-robotics", "x-energy-products"}', logistic_rewrite)
        self.assertIn('"automation-science-pack"', logistic_rewrite)
        self.assertIn('"logistic-science-pack"', logistic_rewrite)
        self.assertIn('"chemical-science-pack"', logistic_rewrite)
        self.assertIn('"x-dollar"', logistic_rewrite)
        self.assertNotIn('"space-science-pack"', logistic_rewrite)
        self.assertIn("logistic_system_tech.enabled = false", logistic_rewrite)
        self.assertIn('name = "x-gigafactory-module", amount = 10', recipe)
        self.assertIn('name = "substation", amount = 2', recipe)
        self.assertIn('{"x-mass-vehicle-assembly"}', mass_ev)
        self.assertNotIn('{"advanced-crafting"}', mass_ev)
        self.assertTrue((MOD / "graphics/icons/gigafactory.png").exists())
        self.assertTrue((MOD / "graphics/entity/gigafactory/gigafactory.png").exists())
        with Image.open(MOD / "graphics/entity/gigafactory/gigafactory.png") as image:
            self.assertEqual(image.size, (1024, 1024))
            alpha = image.convert("RGBA").getchannel("A")
            self.assertEqual(alpha.getpixel((0, 0)), 0)
            left, top, right, bottom = alpha.getbbox()
            self.assertGreaterEqual(right - left, image.width * 0.84)
            self.assertGreaterEqual(bottom - top, image.height * 0.84)
            self.assertAlmostEqual((left + right) / 2, image.width / 2, delta=image.width * 0.05)
            self.assertAlmostEqual((top + bottom) / 2, image.height / 2, delta=image.height * 0.05)

    def test_gigafactory_v2_is_a_faster_more_efficient_gigacasting_upgrade(self):
        data = (MOD / "data.lua").read_text()
        entity = data[data.index('local gigafactory_v2 = copied_assembler('):data.index('local terrestrial_datacenter = copied_assembler(')]
        gigacast_recipe = data[data.index('recipe("x-gigacast"'):data.index('recipe("x-gigafactory-v2"')]
        v2_recipe = data[data.index('recipe("x-gigafactory-v2"'):data.index('recipe("x-dirty-nickel-refining"')]
        capital_tech = data[data.index('tech("x-capital-scaling"'):data.index('tech("x-ev-charging-network"')]

        self.assertIn('{"advanced-crafting", "x-vehicle-assembly", "x-mass-vehicle-assembly", "x-energy-products", "x-energy-products-batch", "x-vertical-integration"}', entity)
        self.assertIn('"30MW"', entity)
        self.assertIn('\n  8\n)', entity)
        self.assertIn('base_effect = {productivity = 1.5}', entity)
        self.assertIn('gigafactory_v2.max_health = 7500', entity)
        self.assertIn('gigafactory_v2.module_slots = 8', entity)
        self.assertIn('gigafactory_v2.fast_replaceable_group = "x-gigafactory"', entity)
        self.assertIn('gigafactory/gigafactory-v2.png', entity)
        self.assertIn('"productivity"', entity)
        self.assertIn('name = "electric-furnace", amount = 20', gigacast_recipe)
        self.assertIn('name = "steel-plate", amount = 500', gigacast_recipe)
        self.assertIn('name = "electric-engine-unit", amount = 50', gigacast_recipe)
        self.assertIn('name = "x-dollar", amount = 50', gigacast_recipe)
        self.assertIn('name = "x-gigafactory-building", amount = 1', v2_recipe)
        self.assertIn('name = "x-gigacast", amount = 1', v2_recipe)
        self.assertIn('name = "x-dollar", amount = 100', v2_recipe)
        self.assertNotIn('"refined-concrete"', v2_recipe)
        self.assertIn('unlock("x-gigacast")', capital_tech)
        self.assertIn('unlock("x-gigafactory-v2")', capital_tech)
        self.assertIn('unlock("x-mass-market-ev")', capital_tech)
        v2_art = MOD / "graphics/entity/gigafactory/gigafactory-v2.png"
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

    def test_gigafactory_vertical_integration_only_productivizes_intermediates(self):
        data = (MOD / "data.lua").read_text()
        locale = (MOD / "locale/en/factoryx.cfg").read_text()
        control = (MOD / "control.lua").read_text()

        for recipe_name in [
            "copper-cable",
            "electronic-circuit",
            "advanced-circuit",
            "low-density-structure",
            "x-gigafactory-module",
            "x-gigacast",
            "x-electric-drivetrain",
            "x-autonomy-computer",
            "x-datacenter-rack",
            "x-reusable-booster",
            "x-satellite-bus",
            "x-ground-station-network",
        ]:
            self.assertIn(f'"{recipe_name}"', data[data.index("local vertically_integrated_intermediates"):])
        for recipe_name in [
            "x-premium-ev",
            "x-mass-market-ev",
            "x-high-density-solar-array",
            "x-megapack",
            "x-robotaxi-fleet",
        ]:
            self.assertIn(f'"{recipe_name}"', data[data.index("for _, recipe_name in pairs({"):])
        self.assertIn('add_recipe_category(recipe_name, "x-vertical-integration").allow_productivity = true', data)
        self.assertIn("data.raw.recipe[recipe_name].allow_productivity = false", data)
        self.assertIn("x-vertical-integration=Gigafactory vertical integration", locale)
        self.assertIn("vertically integrated component recipe", control)
        self.assertIn("First Gigafactory V2 online", (MOD / "control.lua").read_text())

    def test_energy_products_are_parallel_placeable_and_gigafactory_built(self):
        data = (MOD / "data.lua").read_text()
        locale = (MOD / "locale/en/factoryx.cfg").read_text()
        solar_recipe = data[data.index('recipe("x-high-density-solar-array"'):data.index('recipe("x-high-density-solar-array-batch"')]
        solar_batch_recipe = data[data.index('recipe("x-high-density-solar-array-batch"'):data.index('recipe("x-megapack"')]
        megapack_recipe = data[data.index('recipe("x-megapack"'):data.index('recipe("x-autonomy-computer"')]
        energy_tech = data[data.index('tech("x-energy-products"'):data.index('tech("x-small-orbital-launch"')]

        self.assertIn('copied_energy_entity(\n  "solar-panel"', data)
        self.assertIn('high_density_solar_array.production = "300kW"', data)
        self.assertIn('high_density_solar_array.collision_box = {{-1.35, -1.35}, {1.35, 1.35}}', data)
        self.assertIn('high_density_solar_array.selection_box = {{-1.5, -1.5}, {1.5, 1.5}}', data)
        self.assertIn('high_density_solar_array.fast_replaceable_group = "solar-panel"', data)
        self.assertIn('data.raw["solar-panel"]["solar-panel"].next_upgrade = "x-high-density-solar-array"', data)
        self.assertIn("tiled_high_density_solar_sprite", data)
        self.assertIn("pairs({-0.75, 0.75})", data)
        self.assertIn("layer.scale = (layer.scale or 1) * 0.5", data)
        control = (MOD / "control.lua").read_text()
        self.assertNotIn("x-high-density-solar-array-horizontal", data)
        self.assertNotIn("x-high-density-solar-array-power-source", data)
        self.assertNotIn("replace_solar_array_orientation", control)
        self.assertIn('copied_energy_entity(\n  "accumulator"', data)
        self.assertIn('megapack.energy_source.buffer_capacity = "100MJ"', data)
        self.assertIn('megapack.energy_source.input_flow_limit = "5MW"', data)
        self.assertIn('megapack.energy_source.output_flow_limit = "5MW"', data)
        self.assertIn('generated_icon("megapack")', data)
        self.assertIn('generated_entity_picture("megapack", nil, 0.14)', data)
        self.assertTrue((MOD / "graphics/icons/megapack.png").exists())
        self.assertTrue((MOD / "graphics/entity/megapack/megapack.png").exists())
        self.assertIn('{"advanced-crafting"}', solar_recipe)
        self.assertIn('name = "solar-panel", amount = 1', solar_recipe)
        self.assertIn('name = "processing-unit", amount = 2', solar_recipe)
        self.assertIn('name = "low-density-structure", amount = 2', solar_recipe)
        self.assertIn('name = "x-dollar", amount = 1', solar_recipe)
        self.assertIn('{"x-energy-products-batch"}', solar_batch_recipe)
        self.assertIn('name = "solar-panel", amount = 4', solar_batch_recipe)
        self.assertIn('name = "processing-unit", amount = 6', solar_batch_recipe)
        self.assertIn('name = "low-density-structure", amount = 6', solar_batch_recipe)
        self.assertIn('name = "x-dollar", amount = 3', solar_batch_recipe)
        self.assertIn('name = "x-high-density-solar-array", amount = 4', solar_batch_recipe)
        self.assertIn('item("x-high-density-solar-array", high_density_solar_array_icon, "energy", "x-a[high-density-solar-array]", 10', data)
        self.assertIn('{"x-energy-products"}', megapack_recipe)
        self.assertIn('name = "x-lfp-battery-pack", amount = 12', megapack_recipe)
        self.assertIn('name = "accumulator", amount = 4', megapack_recipe)
        self.assertIn('name = "substation", amount = 1', megapack_recipe)
        self.assertIn('{"x-premium-ev-program", "electric-energy-accumulators", "solar-energy"}', energy_tech)
        self.assertNotIn('"production-science-pack"', energy_tech)
        self.assertIn("    250,", energy_tech)
        self.assertIn("    30\n  ),", energy_tech)
        self.assertNotIn('"x-capital-scaling"', energy_tech)
        self.assertNotIn('unlock("x-gigafactory-building")', energy_tech)
        self.assertIn('unlock("x-high-density-solar-array")', energy_tech)
        self.assertIn('unlock("x-megapack")', energy_tech)
        self.assertIn('unlock("x-sell-megapack")', energy_tech)
        self.assertIn("x-megapack=Stores 100 MJ", locale)
        self.assertNotIn("x-grid-storage-unit", data)
        self.assertNotIn("x-sell-grid-storage", data)

    def test_factoryx_charging_network_sales_loop(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        self.assertIn('recipe("x-ev-charging-station"', data)
        self.assertIn('tech("x-ev-charging-network"', data)
        sales_office_entity = data[data.index('local sales_office = copied_assembler('):data.index('local ev_charging_station = copied_reservation_output_site(')]
        self.assertIn('"x-sales-office"', sales_office_entity)
        self.assertIn("radius_visualisation_specification", sales_office_entity)
        self.assertIn("customer_radius_visualisation(128)", sales_office_entity)
        charging_entity = data[data.index('local ev_charging_station = copied_reservation_output_site('):data.index('local terrestrial_datacenter = copied_assembler(')]
        self.assertIn('"x-ev-charging-station"', charging_entity)
        self.assertIn('"x-ev-charging-station-v2"', charging_entity)
        self.assertIn('"x-ev-charging-station-v3"', charging_entity)
        self.assertIn('"x-ev-charging-station-v4"', charging_entity)
        self.assertNotIn("copied_electric_pole", charging_entity)
        self.assertIn("radius_visualisation_specification", charging_entity)
        self.assertIn("customer_radius_visualisation(64)", charging_entity)
        self.assertIn("customer_radius_visualisation(96)", charging_entity)
        self.assertIn("customer_radius_visualisation(128)", charging_entity)
        self.assertIn("customer_radius_visualisation(160)", charging_entity)
        self.assertIn('collision_box = {{-1.9, -1.9}, {1.9, 1.9}}', charging_entity)
        self.assertIn('collision_box = {{-2.4, -2.4}, {2.4, 2.4}}', charging_entity)
        self.assertIn('collision_box = {{-2.9, -2.9}, {2.9, 2.9}}', charging_entity)
        self.assertIn('generated_entity_picture("ev-charging-station-v4", nil, 0.38)', charging_entity)
        self.assertIn('data.raw["logistic-container"]["passive-provider-chest"]', data)
        self.assertIn("prototype.inventory_size = 2", data)
        self.assertIn('prototype.logistic_mode = "passive-provider"', data)
        self.assertIn("prototype.render_not_in_network_icon = false", data)
        self.assertIn("robot_door.animation = generated_entity_picture", charging_entity)
        self.assertIn('prototype.name = "x-ev-charging-grid-connection"', data)
        self.assertIn('hidden_ev_charging_power_sink("x-ev-charging-power-sink", 50)', data)
        self.assertIn('hidden_ev_charging_power_sink("x-ev-charging-v2-power-sink", 150)', data)
        self.assertIn('hidden_ev_charging_power_sink("x-ev-charging-v3-power-sink", 250)', data)
        self.assertIn('hidden_ev_charging_power_sink("x-ev-charging-v4-power-sink", 500)', data)
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
        self.assertIn('storage.factoryx_station_power_model = "native-supply-area-v1"', control)
        self.assertIn('cleanup_legacy_station_grid_connections()', control)
        self.assertNotIn('charger_wire.connect_to(grid_wire, false)', control)
        self.assertNotIn('name = STATION_GRID_CONNECTION_NAME,\n      position = station.position', control)
        self.assertIn('item("x-ev-charging-station", ev_charging_station_icon, "x-factoryx-infrastructure", "b[ev-charging-station]", 5', data)
        self.assertIn('item("x-ev-charging-station-v2", ev_charging_station_v2_icon, "x-factoryx-infrastructure", "c[ev-charging-station-v2]", 5', data)
        self.assertIn('item("x-ev-charging-station-v3", ev_charging_station_v3_icon, "x-factoryx-infrastructure", "d[ev-charging-station-v3]", 5', data)
        self.assertIn('item("x-ev-charging-station-v4", ev_charging_station_v4_icon, "x-factoryx-infrastructure", "e[ev-charging-station-v4]", 5', data)

    def test_terrestrial_industrial_supply_chain(self):
        data = (MOD / "data.lua").read_text()
        updates = (MOD / "data-updates.lua").read_text()
        control = (MOD / "control.lua").read_text()
        locale = (MOD / "locale" / "en" / "factoryx.cfg").read_text()
        self.assertIn('name = "x-industrial-supply-chain"', updates)
        self.assertIn('data.raw.technology["advanced-material-processing-2"]', updates)
        self.assertIn('effect.recipe ~= "electric-furnace"', updates)
        self.assertIn('{"electric-mining-drill", 4}', updates)
        self.assertIn('{"engine-unit", 20}', updates)
        self.assertIn('big_drill_tech.prerequisites = {"x-industrial-supply-chain", "engine"}', updates)
        self.assertIn('tungsten_steel_tech.prerequisites = {"planet-discovery-vulcanus"}', updates)
        self.assertIn('holmium_tech.prerequisites = {"recycling", "planet-discovery-fulgora"}', updates)
        self.assertIn('entities = {"tungsten-ore"}', updates)
        self.assertIn('"electric-mining-drill", "steel-processing"', updates)
        self.assertIn('{"electronic-circuit", 20}', updates)
        self.assertIn('{"electric-furnace", 25}', updates)
        self.assertIn('{"refined-concrete", 200}', updates)
        self.assertNotIn('"molten-iron-from-lava",', updates)
        self.assertNotIn('"casting-low-density-structure",', updates)
        self.assertIn('initialize_patch_set("calcite", false)', updates)
        self.assertIn('entity.settings.calcite = {}', updates)
        self.assertIn('rewrite_recipe("recycler"', updates)
        self.assertIn('unlock("x-wrecked-ev-recycling")', updates)
        self.assertIn('recycling_tech.enabled = false', updates)
        self.assertIn('rewrite_recipe("teslagun"', updates)
        self.assertNotIn('holmium-plate', updates)
        self.assertNotIn('superconductor', updates)
        self.assertIn('item("x-wrecked-ev"', data)
        self.assertIn('item("x-wrecked-ev", wrecked_ev_icon, "transport"', data)
        self.assertIn('recipe("x-wrecked-ev-recycling"', data)
        self.assertIn('if math.random() < 0.01', control)
        recycling_unlock = control[
            control.index('unlock_vehicle_recycling = function(force)'):
            control.index('generate_station_wrecks = function')
        ]
        self.assertIn('technology.enabled = true', recycling_unlock)
        self.assertNotIn('technology.researched = true', recycling_unlock)
        self.assertNotIn('force.print', recycling_unlock)
        self.assertIn('output.insert{name = WRECKED_EV_NAME, count = removed}', control)
        self.assertIn('x-industrial-supply-chain=Industrial Supply Chain', locale)

    def test_factoryx_technology_icons_share_one_badge(self):
        data = (MOD / "data.lua").read_text()
        updates = (MOD / "data-updates.lua").read_text()
        control = (MOD / "control.lua").read_text()
        badge = MOD / "graphics" / "technology" / "factoryx-tech-badge.png"
        self.assertTrue(badge.exists())
        with Image.open(badge) as badge_image:
            self.assertEqual(badge_image.size, (64, 64))
        self.assertIn('factoryx-tech-badge.png', data)
        self.assertIn('factoryx-tech-badge.png', updates)
        for old_ringed_icon in [
            "sales-office.png",
            "ev-charging-network.png",
            "gigafactory.png",
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
            "graphics/icons/megapack.png",
            "graphics/icons/robotaxi-service-center.png",
            "graphics/icons/planetary-grid-controller.png",
        ]:
            self.assertIn(clean_subject, data)
        station_recipe = data[data.index('recipe("x-ev-charging-station"'):data.index('recipe("x-ev-charging-station-v2"')]
        station_v2_recipe = data[data.index('recipe("x-ev-charging-station-v2"'):data.index('recipe("x-ev-charging-station-v3"')]
        station_v3_recipe = data[data.index('recipe("x-ev-charging-station-v3"'):data.index('recipe("x-ev-charging-station-v4"')]
        station_v4_recipe = data[data.index('recipe("x-ev-charging-station-v4"'):data.index('recipe("x-gigafactory-module"')]
        self.assertNotIn('"x-dollar"', station_recipe)
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
            'name = "x-ev-charging-station", amount = 1',
            'name = "substation", amount = 2',
            'name = "processing-unit", amount = 20',
            'name = "x-dollar", amount = 20',
        ]:
            self.assertIn(expected, station_v2_recipe)
        for expected in [
            'name = "x-ev-charging-station-v2", amount = 1',
            'name = "substation", amount = 4',
            'name = "processing-unit", amount = 40',
            'name = "x-dollar", amount = 75',
        ]:
            self.assertIn(expected, station_v3_recipe)
        for expected in [
            'name = "x-ev-charging-station-v3", amount = 1',
            'name = "x-high-density-solar-array", amount = 4',
            'name = "x-megapack", amount = 4',
            'name = "x-dollar", amount = 200',
        ]:
            self.assertIn(expected, station_v4_recipe)
        charging_tech = data[data.index('tech("x-ev-charging-network"'):data.index('tech("x-energy-products"')]
        self.assertIn('unlock("x-ev-charging-station-v2")', charging_tech)
        self.assertNotIn('unlock("x-ev-charging-station")', charging_tech)
        capital_scaling_tech = data[data.index('tech("x-capital-scaling"'):data.index('tech("x-ev-charging-network"')]
        autonomous_tech = data[data.index('tech("x-autonomous-logistics"'):data.index('tech("x-planetary-energy-grid"')]
        self.assertIn('unlock("x-ev-charging-station-v3")', capital_scaling_tech)
        self.assertIn('unlock("x-ev-charging-station-v4")', autonomous_tech)
        self.assertIn('v4_recipe.enabled = researched(force, "x-autonomous-logistics")', control)
        mass_sale = data[data.index('recipe("x-sell-mass-market-ev"'):data.index('recipe("x-sell-megapack"')]
        robotaxi_sale = data[data.index('recipe("x-sell-robotaxi-fleet"'):data.index('recipe("x-terrestrial-ai-token"')]
        self.assertIn('"x-ev-reservation"', mass_sale)
        self.assertIn('name = "x-mass-market-ev", amount = 1', mass_sale)
        self.assertIn('name = "x-ev-reservation", amount = 1', mass_sale)
        self.assertIn('{{type = "item", name = "x-dollar", amount = 1}}, 5', mass_sale)
        self.assertNotIn('"x-ev-reservation"', robotaxi_sale)
        self.assertIn('name = "x-robotaxi-fleet", amount = 3', robotaxi_sale)
        self.assertIn('{{type = "item", name = "x-dollar", amount = 1}}, 3', robotaxi_sale)
        robotaxi_recipe = data[data.index('recipe("x-robotaxi-fleet"'):data.index('recipe("x-small-launch-service"')]
        self.assertIn('name = "x-dollar", amount = 100', robotaxi_recipe)

    def test_sales_office_coverage_has_remote_view_toggle(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        locale = (MOD / "locale/en/factoryx.cfg").read_text()
        shortcut = data[
            data.index('name = "x-toggle-sales-office-coverage"') - 40:
            data.index('type = "item-subgroup"')
        ]

        self.assertIn('type = "shortcut"', shortcut)
        self.assertIn('action = "lua"', shortcut)
        self.assertIn('toggleable = true', shortcut)
        self.assertIn('technology_to_unlock = "x-sales-office"', shortcut)
        self.assertIn('__factoryx__/graphics/icons/sales-office-coverage.png', shortcut)
        self.assertNotIn('__base__/graphics/icons/radar.png', shortcut)
        self.assertIn("x-toggle-sales-office-coverage=Sales Office Coverage", locale)
        coverage_icon = MOD / "graphics/icons/sales-office-coverage.png"
        self.assertTrue(coverage_icon.exists())
        with Image.open(coverage_icon) as image:
            self.assertEqual(image.size, (256, 256))
            self.assertEqual(image.mode, "RGBA")
        self.assertIn("refresh_sales_office_coverage", control)
        self.assertIn("rendering.draw_circle", control)
        self.assertIn('render_mode = "chart"', control)
        self.assertIn("radius = SALES_OFFICE_CUSTOMER_RADIUS", control)
        self.assertIn("players = {player}", control)
        self.assertIn("set_shortcut_toggled", control)
        self.assertIn("on_lua_shortcut", control)
        self.assertIn("mark_sales_office_coverage_dirty", control)
        self.assertIn("color = {r = 0.03, g = 0.16, b = 0.18, a = 0.18}", control)
        self.assertIn("color = {r = 0.18, g = 0.62, b = 0.58, a = 0.72}", control)
        self.assertNotIn("color = {r = 0.2, g = 1.0, b = 0.35", control)

    def test_factoryx_progress_interface_is_live_and_actionable(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        locale = (MOD / "locale/en/factoryx.cfg").read_text()

        progress_shortcut = data[
            data.index('name = "x-open-factoryx-progress"') - 40:
            data.index('name = "x-toggle-sales-office-coverage"')
        ]
        self.assertIn('type = "shortcut"', progress_shortcut)
        self.assertIn('action = "lua"', progress_shortcut)
        self.assertIn('__factoryx__/graphics/icons/factoryx-group.png', progress_shortcut)
        self.assertIn("x-open-factoryx-progress=FactoryX Progress", locale)
        self.assertIn('FACTORYX_PROGRESS_SHORTCUT = "x-open-factoryx-progress"', control)
        self.assertIn('PROGRESS_PANEL_NAME = "factoryx_progress_panel"', control)
        self.assertIn("progress_snapshot", control)
        self.assertIn("current_progress_objective", control)
        self.assertIn("progress_stages", control)
        self.assertIn("refresh_progress_panel", control)
        self.assertIn("open_progress_panel", control)
        self.assertIn('sprite = "utility/close"', control)
        self.assertIn('commands.add_command("factoryx-status"', control)
        self.assertIn('commands.add_command("factoryx-note"', control)
        self.assertIn('helpers.write_file("factoryx-playtest-notes.jsonl"', control)
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
        self.assertIn('"factoryx_dollars_produced_value"', control)
        self.assertIn("EV Reservations", control)
        self.assertNotIn('add_progress_section(content, "Infrastructure"', control)
        self.assertNotIn('add_progress_section(content, "Continuous improvement"', control)
        self.assertNotIn('label = "Energy Products"', control)
        self.assertIn("Terrestrial industry", control)
        self.assertIn("progress_health", control)
        self.assertIn("current_progress_measure", control)
        self.assertIn('type = "progressbar"', control)
        self.assertIn("add_progress_metrics", control)
        self.assertIn("FACTORYX_STATE_COLORS.good", control)
        self.assertIn("FACTORYX_STATE_COLORS.warning", control)
        self.assertIn("FACTORYX_STATE_COLORS.bad", control)
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
        self.assertIn("Upgrade a Gigafactory to V2", control)

    def test_sales_office_and_gigafactory_panels_report_bottlenecks(self):
        control = (MOD / "control.lua").read_text()

        self.assertIn('ENTITY_INFO_PANEL_NAME = "factoryx_entity_info_panel"', control)
        self.assertIn("GIGAFACTORY_CONFIGS", control)
        self.assertIn('power = "20 MW"', control)
        self.assertIn('power = "30 MW"', control)
        self.assertIn('productivity = "4x crafting speed; 50% built-in productivity"', control)
        self.assertIn('productivity = "2x crafting speed; 150% built-in productivity"', control)
        self.assertIn("show_manufacturer_info_panel", control)
        self.assertIn("is_factoryx_manufacturer", control)
        self.assertIn("entity_status_text", control)
        self.assertIn("recipe_missing_item", control)
        self.assertIn("add_item_inventory_row", control)
        self.assertIn("add_factoryx_metric_table", control)
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
        self.assertIn('caption = "FactoryX Customer Settlement"', control)
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

        self.assertIn("factoryx_customer_vehicle_owners", control)
        self.assertIn("factoryx_office_buyer_reservations", control)
        self.assertIn("eligible_customer_buyers", control)
        self.assertIn("reserve_office_buyers", control)
        self.assertIn("office.disabled_by_script = not valid_reservation", control)
        self.assertIn("complete_reserved_vehicle_sale", control)
        self.assertIn("replace_customer_vehicle_entity", control)
        self.assertIn('return "x-" .. base_name .. "-" .. class_name', control)
        self.assertNotIn('sprite = "item/" .. ownership.vehicle', control)
        self.assertIn('text = "$"', control)
        self.assertIn("unregister_customer_unit(entity)", control)
        self.assertIn("Active customer EVs", control)
        self.assertIn("Roadsters sold", control)
        self.assertIn('label = "Reserved"', control)
        self.assertIn("no eligible mobile customer", control)

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

    def test_factoryx_control_generates_physical_reservations_at_chargers(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn('"x-ev-charging-station"', control)
        self.assertIn('"x-sales-office"', control)
        self.assertIn('"x-ev-reservation"', control)
        self.assertIn('"x-sell-prototype-roadster"', control)
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
        self.assertIn("factoryx_first_ev_production_line_hints", control)
        self.assertIn("PREMIUM_EV_SALE_RECIPE", control)
        self.assertIn("STATION_GRID_CONNECTION_NAME", control)
        for station_name in [
            '"x-ev-charging-station"',
            '"x-ev-charging-station-v2"',
            '"x-ev-charging-station-v3"',
            '"x-ev-charging-station-v4"',
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
        self.assertIn("customer_radius = 96", control)
        self.assertIn("customer_radius = 128", control)
        self.assertIn("customer_radius = 160", control)
        self.assertIn('power_sink_name = "x-ev-charging-v2-power-sink"', control)
        self.assertIn('power_sink_name = "x-ev-charging-v3-power-sink"', control)
        self.assertIn('power_sink_name = "x-ev-charging-v4-power-sink"', control)
        self.assertIn('chargers_v3 = count_entities(force, "x-ev-charging-station-v3")', control)
        self.assertIn('chargers_v4 = count_entities(force, "x-ev-charging-station-v4")', control)
        self.assertIn("Craft and place a V3 Supercharger", control)
        self.assertIn("Craft and place a solar-canopy V4 Supercharger", control)
        self.assertIn("research Autonomous Logistics to unlock Robotaxis, V4 fleet charging", control)
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
        self.assertIn('commands.add_command("factoryx-coverage"', control)
        self.assertIn("STATION_INFO_PANEL_NAME", control)
        self.assertIn("show_station_info_panel", control)
        self.assertNotIn("on_selected_entity_changed", control)
        self.assertIn("on_gui_opened", control)
        self.assertIn("on_gui_closed", control)
        self.assertIn("player.gui.relative.add", control)
        self.assertIn("player.gui.relative[STATION_INFO_PANEL_NAME]", control)
        self.assertIn("player.gui.relative[ENTITY_INFO_PANEL_NAME]", control)
        self.assertIn("defines.relative_gui_type.assembling_machine_gui", control)
        self.assertIn("defines.relative_gui_type.container_gui", control)
        self.assertIn("defines.relative_gui_position.right", control)
        self.assertIn("opened_factoryx_entities()[player.index]", control)
        self.assertNotIn("player.gui.left", control)
        self.assertIn('caption = "FactoryX " .. config.display_name', control)
        self.assertIn('player.gui.screen.add{', control)
        self.assertIn('name = "factoryx_station_info_close"', control)
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
        self.assertIn("[FactoryX] %s online", control)
        self.assertIn("EV Charging Network researched. Craft a separate V2 charger", control)
        self.assertIn("script.on_nth_tick(60", control)
        self.assertIn("RESERVATIONS_PER_ACTIVE_STALL_PER_MINUTE = 1", control)
        self.assertIn("RESERVATION_SAMPLES_PER_PRINT = 60", control)
        self.assertIn("factoryx_reservation_print_progress", control)
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

        for item_name in ["x-prototype-roadster", "x-premium-ev", "x-mass-market-ev", "x-cybertruck", "x-robotaxi-fleet"]:
            self.assertIn(f'"{item_name}"', control)
        self.assertIn("CUSTOMER_EV_SALE_RECIPES", control)
        self.assertIn("record_customer_ev_sales", control)
        self.assertIn("factoryx_customer_ev_sales", control)
        self.assertIn('vehicles = 3', control)
        self.assertIn("historical_customer_ev_sales", control)
        self.assertIn('statistics.get_input_count("x-mass-market-ev")', control)
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

    def test_factoryx_biter_customer_mode(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn("biter_customer_mode_enabled", control)
        self.assertIn("return true", control)
        self.assertIn("count_covered_biter_settlements", control)
        self.assertIn('"biter-spawner"', control)
        self.assertIn('"spitter-spawner"', control)
        self.assertIn("RESERVATIONS_PER_ACTIVE_STALL_PER_MINUTE", control)
        self.assertIn('CUSTOMER_FORCE_NAME = "factoryx-customers"', control)
        self.assertIn("SALES_OFFICE_CUSTOMER_RADIUS = 128", control)
        self.assertIn("game.create_force(CUSTOMER_FORCE_NAME)", control)
        self.assertIn("sync_customer_settlements", control)
        self.assertIn("rendering.draw_text", control)
        self.assertIn("customer_markers", control)
        self.assertIn("destroy_customer_marker", control)
        self.assertIn('text = "$"', control)
        customer_marker = control[control.index("local function draw_customer_marker"):control.index("local function scan_biter_customer_entities")]
        self.assertNotIn("rendering.draw_circle", customer_marker)
        self.assertIn("if not is_settlement then", customer_marker)
        self.assertNotIn("rendering.draw_sprite", customer_marker)
        self.assertNotIn("blink_interval", control)
        self.assertIn("set_cease_fire", control)
        self.assertIn("force.set_cease_fire(enemy, false)", control)
        self.assertIn("force.set_cease_fire(customers, true)", control)
        self.assertIn('remote.add_interface("factoryx"', control)
        self.assertIn("biter_customer_market", control)
        self.assertIn("covered biter settlements", control)
        self.assertNotIn("x-biter-customer-mode", control)
        self.assertNotIn("on_runtime_mod_setting_changed", control)

    def test_ai_tokens_are_dense_capital_funded_and_improvable(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        token_line = next(line for line in data.splitlines() if 'item("x-ai-token"' in line)
        self.assertIn(", 1000000, {weight = 1})", token_line)
        self.assertIn("ai_efficiency_thresholds = {1000, 10000, 100000, 1000000, 10000000, 100000000}", data)
        self.assertIn('+10% AI Tokens per cycle', data)
        self.assertIn('recipe = "x-terrestrial-ai-token"', data)
        self.assertIn('recipe = "x-orbital-ai-token"', data)
        self.assertIn("terrestrial_datacenter.module_slots = 0", data)
        self.assertIn('terrestrial_datacenter.allowed_effects = {"consumption", "speed", "pollution", "quality"}', data)
        self.assertIn("math.floor(threshold / 10)", data)
        self.assertIn("track_ai_efficiency_progress()", control)
        self.assertIn("ai_efficiency_status", control)
        self.assertIn("function ai_efficiency_track_status", control)
        self.assertIn("tokens_per_cycle = config.tokens_per_cycle * (1 + level * 0.1)", control)
        self.assertIn("local bonus_cycles = math.floor(bonus_progress + 0.000001)", control)
        self.assertIn('name = "x-ai-token"', control)
        self.assertIn("Capital burn: 20 Dollars per 30-second cycle", control)
        self.assertIn("AI output:", control)
        self.assertIn("Terrestrial production tracked:", control)
        self.assertIn("terrestrial ceiling reached", control)
        self.assertIn("terrestrial_ai_tokens_generated", control)

    def test_robotaxi_service_center_economy(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        locale = (MOD / "locale/en/factoryx.cfg").read_text()

        robotaxi_item = next(line for line in data.splitlines() if 'item("x-robotaxi-fleet"' in line)
        self.assertIn('"transport", "x-e[robotaxi-fleet]", 5,', robotaxi_item)
        self.assertIn('name = "x-robotaxi-service-center"', data)
        self.assertIn("robotaxi_service_center.inventory_size = 43", data)
        self.assertIn('"x-robotaxi-service-power"', data)
        self.assertIn('"10MW"', data[data.index("local robotaxi_service_power ="):data.index("local orbital_compute_array =")])
        self.assertIn('recipe("x-operate-robotaxis", {"x-robotaxi-service"}', data)
        self.assertIn('unlock("x-robotaxi-service-center")', data)
        self.assertIn('unlock("x-operate-robotaxis")', data)
        self.assertIn("ROBOTAXI_CUSTOMERS_PER_VEHICLE = 5", control)
        self.assertIn("ROBOTAXI_REVENUE_VEHICLE_MINUTES_PER_DOLLAR = 100", control)
        self.assertIn("ROBOTAXI_ATTRITION_VEHICLE_HOURS = 60", control)
        self.assertIn("function process_robotaxi_service_centers", control)
        self.assertIn("function ensure_robotaxi_service_power", control)
        self.assertIn("function robotaxi_customer_allocations", control)
        self.assertIn('registered_factoryx_entities("robotaxi_centers", force)', control)
        self.assertIn("customer_settlement_populations()", control)
        self.assertIn("distance <= ROBOTAXI_SERVICE_RADIUS * ROBOTAXI_SERVICE_RADIUS", control)
        self.assertIn("available[center.unit_number] = stored > 0", control)
        self.assertIn("result[selected.unit_number] = result[selected.unit_number] + customers", control)
        self.assertIn("game.tick - cached.tick < 300", control)
        self.assertIn("function robotaxi_dollar_output_blocked", control)
        self.assertIn("slot.count >= slot.prototype.stack_size", control)
        self.assertIn("output_blocked = robotaxi_dollar_output_blocked(output)", control)
        self.assertIn("not snapshot.output_blocked", control)
        self.assertIn("trips and fleet attrition are paused", control)
        self.assertIn("radius = 0.25", control)
        self.assertIn("active_power_units", control)
        self.assertIn("not active_power_units[power.unit_number]", control)
        self.assertIn("robotaxi_service_status = function", control)
        self.assertIn("Premium Audio increases trip revenue", control)
        self.assertIn("legacy_robotaxi_sale.enabled = false", control)
        self.assertIn("x-robotaxi-service-center=Robotaxi Service Center", locale)

    def test_battery_chemistry_branch_is_physical_and_not_productive(self):
        data = (MOD / "data.lua").read_text()
        updates = (MOD / "data-updates.lua").read_text()
        self.assertNotIn('item("x-battery-pack"', data)
        for name in [
            "x-nickel-ore", "x-lithium-brine", "x-acidic-tailings",
            "x-high-nickel-cell", "x-lfp-cell", "x-high-energy-battery-pack",
            "x-lfp-battery-pack", "x-damaged-high-energy-battery-pack",
            "x-damaged-lfp-battery-pack",
        ]:
            self.assertIn(name, data)
        self.assertIn('initialize_patch_set("x-nickel-ore", false)', updates)
        self.assertIn('initialize_patch_set("x-lithium-brine", false)', updates)
        self.assertIn('local battery_mineral_fade = "clamp((distance - 240) / 60, 0, 1)"', updates)
        self.assertIn("local function battery_mineral_autoplace", updates)
        self.assertEqual(updates.count("base_spots_per_km2 = 1.25"), 2)
        self.assertIn('frequency = 1.0, size = 1.0, richness = 1.0', updates)
        premium = data[data.index('recipe("x-premium-ev"'):data.index('recipe("x-mass-market-ev"')]
        mass = data[data.index('recipe("x-mass-market-ev"'):data.index('recipe("x-cybertruck"')]
        megapack = data[data.index('recipe("x-megapack"'):data.index('recipe("x-autonomy-computer"')]
        self.assertIn('name = "x-high-energy-battery-pack", amount = 8', premium)
        self.assertIn('name = "x-lfp-battery-pack", amount = 4', mass)
        self.assertIn('name = "x-lfp-battery-pack", amount = 12', megapack)
        high_recovery = data[data.index('recipe("x-high-energy-battery-recovery"'):data.index('recipe("x-lfp-battery-recovery"')]
        lfp_recovery = data[data.index('recipe("x-lfp-battery-recovery"'):data.index('recipe("x-electric-semi"')]
        self.assertIn('amount = 10', high_recovery)
        self.assertIn('name = "x-high-nickel-cell", amount = 72', high_recovery)
        self.assertIn('amount = 10', lfp_recovery)
        self.assertIn('name = "x-lfp-cell", amount = 72', lfp_recovery)
        self.assertIn('allow_productivity = false', high_recovery)
        self.assertIn('allow_productivity = false', lfp_recovery)
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
        self.assertIn('nickel_ore.icon = "__factoryx__/graphics/icons/nickel-ore.png"', data)
        self.assertIn('lithium_brine.icon = "__factoryx__/graphics/icons/lithium-brine.png"', data)
        self.assertIn('acidic_tailings.icon = "__factoryx__/graphics/icons/acidic-tailings.png"', data)

    def test_battery_onboarding_precedes_premium_pilot(self):
        control = (MOD / "control.lua").read_text()
        objective = control[control.index("local function current_progress_objective"):control.index("local function progress_stages")]
        for field in [
            "nickel_ore_mined", "lithium_brine_pumped", "acidic_tailings_produced",
            "nickel_sulfate_produced", "lithium_carbonate_produced",
            "high_nickel_cells_produced", "high_energy_battery_packs_produced",
            "lfp_cells_produced", "lfp_battery_packs_produced",
        ]:
            self.assertIn(field, control)
        self.assertLess(objective.index('return "Battery minerals"'), objective.index('return "Premium pilot production"'))
        self.assertLess(objective.index('return "Battery refining"'), objective.index('return "Premium pilot production"'))
        self.assertLess(objective.index('return "Battery cells"'), objective.index('return "Premium pilot production"'))
        self.assertLess(objective.index('return "Battery packs"'), objective.index('return "Premium pilot production"'))
        self.assertIn("function count_fluid_produced", control)
        self.assertIn("get_fluid_production_statistics", control)

    def test_robotaxi_safety_improves_automatically_with_completed_rides(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn("ROBOTAXI_SAFETY_RIDES_SCALE = 1000", control)
        self.assertIn("ROBOTAXI_ROUTINE_WEAR_FLOOR = 0.20", control)
        self.assertIn("function robotaxi_safety_snapshot", control)
        self.assertIn("math.log(1 + state.completed_rides", control)
        self.assertIn("completed_rides_by_force", control)
        self.assertIn("snapshot.allocated * snapshot.power_factor / 60", control)
        self.assertIn("retirement_multiplier", control)
        self.assertIn("Safety learning:", control)
        self.assertIn("Expected retirement:", control)

    def test_cybertrain_is_extremely_fast_with_bounded_mass_sensitive_regen_and_station_charging(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        locale = (MOD / "locale" / "en" / "factoryx.cfg").read_text()
        self.assertIn('electric_semi.max_speed = 3.0', data)
        self.assertIn('electric_semi.max_power = "6MW"', data)
        self.assertIn('fuel_acceleration_multiplier = 2.0', data)
        self.assertIn('fuel_top_speed_multiplier = 1.5', data)
        self.assertIn('electric_semi.braking_force = 40', data)
        self.assertIn('fuel_categories = {"x-electric-semi-drive"}', data)
        self.assertIn('semi_charging_power.energy_source.input_flow_limit = "50MW"', data)
        self.assertIn('recipe("x-electric-semi"', data)
        self.assertIn('recipe("x-semi-charging-stop"', data)
        self.assertIn('tech(\n    "x-electric-semi-logistics"', data)
        self.assertIn("SEMI_PROCESS_BUDGET = 32", control)
        self.assertIn("local budget = math.min(#order, SEMI_PROCESS_BUDGET)", control)
        self.assertIn("train.weight / math.max(1, #semis)", control)
        self.assertIn("SEMI_REGEN_EFFICIENCY", control)
        self.assertIn("SEMI_RESERVE_THRESHOLD = 10000000", control)
        self.assertIn("SEMI_RESERVE_SPEED = 0.08", control)
        self.assertIn("battery.energy <= SEMI_RESERVE_THRESHOLD", control)
        self.assertIn("set_semi_drive_permission(entity, true)", control)
        self.assertIn("reserve_mode = battery.reserve_mode == true", control)
        self.assertIn('if not script.active_mods["factoryx_smoke"] then return false end', control)
        self.assertIn('"test_electric_semi_reserve"', (ROOT / "scripts" / "validate-factoryx-mod.sh").read_text())
        self.assertIn("stop.get_stopped_train()", control)
        self.assertIn("power.power_usage = SEMI_CHARGING_POWER", control)
        self.assertIn("script.on_nth_tick(6, process_electric_semi_runtime)", control)
        self.assertIn("electric_semi_status = function", control)
        self.assertIn("vehicle.name == ELECTRIC_SEMI_NAME", control)
        self.assertIn("x-electric-semi=Cybertrain", locale)
        self.assertIn("x-electric-semi-logistics=Cybertrain Freight", locale)
        self.assertIn('generated_icon("electric-semi")', data)
        self.assertIn('generated_icon("semi-charging-stop")', data)
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
        roadmap = (ROOT / "factoryX.md").read_text()
        section = roadmap[
            roadmap.index("#### Minimal Orbital AI Endgame"):
            roadmap.index("## Design Principles")
        ]
        normalized = " ".join(section.replace("`", "").split())
        self.assertIn("Keep the vanilla Rocket Silo", normalized)
        self.assertIn("Orbital Datacenter Core", normalized)
        self.assertIn("Radiator Panel", normalized)
        self.assertIn("High-density Space Solar Panel", normalized)
        self.assertIn("at least 750 million came from orbital compute", normalized)
        self.assertIn("roughly 1 TW for 60 connected gameplay minutes", normalized)
        self.assertIn("Space does not beam power to the planet", normalized)

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
        roadmap = (ROOT / "factoryX.md").read_text()
        self.assertIn("Phase 2.8: Terrestrial AI Hyperscaler And AI Haters", roadmap)
        self.assertIn("100 GW continuously", roadmap)
        self.assertIn("10 million in-game Dollar items", roadmap)
        self.assertIn("1, 2, 3, 4, 8, 16, 32", roadmap)
        self.assertIn("| 0 | Hyperscaler Prototype I | 1,000,000 | US$10B |", roadmap)
        self.assertIn("| 3 | Hyperscaler I | 10,000,000 | US$100B |", roadmap)
        self.assertIn("| 4-7 | Hyperscaler II | 20,000,000 | US$200B |", roadmap)
        self.assertIn("factoryx-ai-haters", roadmap)
        self.assertIn("sample at most 32 eligible", roadmap)
        self.assertIn("12,000-unit", roadmap)

    def test_agi_victory_roadmap_replaces_legacy_ending(self):
        roadmap = (ROOT / "factoryX.md").read_text()
        playtest_spec = (ROOT / "feature_specs/factoryx_fresh_playtest.md").read_text()
        self.assertIn("Phase 6: Achieving AGI Victory", roadmap)
        self.assertIn("one billion cumulative AI Tokens", roadmap)
        self.assertIn("100 million physical AI Tokens", roadmap)
        self.assertIn("10 million Dollars", roadmap)
        self.assertIn("roughly 1 TW continuously for 60 connected gameplay", roadmap)
        self.assertIn("Completion creates an `AGI Model`", roadmap)
        self.assertNotIn("Kardashev", roadmap)
        self.assertIn("one billion cumulative AI Tokens", playtest_spec)

    def test_customer_reconciliation_is_not_per_second(self):
        control = (MOD / "control.lua").read_text()
        once_per_second = control[
            control.index("script.on_nth_tick(60, function()"):
            control.index("script.on_nth_tick(600, function()")
        ]
        self.assertNotIn("sync_customer_settlements()", once_per_second)
        recurring = control[
            control.index("script.on_nth_tick(600, function()"):
            control.index('remote.add_interface("factoryx"')
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

    def test_vehicle_owner_classes_use_baked_prototypes(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        for class_name in ["roadster", "premium", "mass-market", "robotaxi"]:
            self.assertIn(f'{class_name} = {{' if class_name != "mass-market" else '["mass-market"] = {', data)
        self.assertIn("0.90, g = 0.02, b = 0.01", data)
        self.assertIn("0.015, g = 0.015, b = 0.015", data)
        self.assertIn("0.82, g = 0.82, b = 0.82", data)
        self.assertIn("0.85, g = 0.52, b = 0.03", data)
        self.assertIn('prototype.name = "x-" .. base_name .. "-" .. class_name', data)
        self.assertIn("animation_mask_tint(prototype.run_animation, class)", data)
        self.assertIn("CUSTOMER_UNIT_BASE_BY_NAME[variant_name] = base_name", control)

    def test_unowned_customers_use_baked_prospect_prototypes(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        self.assertIn('label = "EV prospect (friendly)"', data)
        self.assertIn('prototype.name = "x-" .. base_name .. "-" .. class_name', data)
        self.assertIn('and {"", class.label, " - ", base.localised_name', data)
        self.assertIn('local prospect_name = "x-" .. base_name .. "-prospect"', control)
        self.assertIn("function replace_customer_prospect_entity(entity)", control)
        self.assertIn("queue.units[index] = replacement.unit_number", control)
        self.assertIn("replace_customer_prospect_entity(entity)", control)
        self.assertIn("enqueue_customer_variant_migration(entity.unit_number)", control)

    def test_sales_continue_past_charging_capacity_with_visible_consequences(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn("assigned_capacity_by_settlement_key", control)
        self.assertIn("requested_capacity_by_settlement_key", control)
        self.assertIn("powered_capacity_by_settlement_key", control)
        self.assertIn("left_capacity < right_capacity", control)
        buyer_start = control.index("function eligible_customer_buyers")
        buyer_end = control.index("function sales_office_buyer_status", buyer_start)
        buyer_selection = control[buyer_start:buyer_end]
        self.assertIn("for key in pairs(service.served_keys)", buyer_selection)
        self.assertIn("left.load / left.capacity", buyer_selection)
        self.assertIn("if not candidate.exhausted", buyer_selection)
        self.assertNotIn("load < capacity", buyer_selection)
        self.assertIn("vehicle_count - powered_capacity", control)
        self.assertIn("Underserved vehicles: %d", control)
        self.assertIn('return "Customers hostile", FACTORYX_STATE_COLORS.bad', control)

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
        self.assertIn("CUSTOMER_GROWTH_STALL_MINUTES = 5", control)
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
        self.assertIn("service.stranded_evs == 0", control)
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

    def test_factoryx_victory_is_agi_training_run(self):
        data = (MOD / "data.lua").read_text()
        control = (MOD / "control.lua").read_text()
        self.assertIn('"x-planetary-grid-controller"', data)
        self.assertIn('"x-planetary-grid-segment"', data)
        self.assertIn('"x-agi-model"', data)
        self.assertIn('recipe("x-planetary-grid-segment"', data)
        self.assertIn('recipe("x-agi-training-run"', data)
        self.assertIn('tech("x-planetary-energy-grid"', data)
        self.assertIn('unlock("x-planetary-grid-controller")', data)
        self.assertIn('unlock("x-planetary-grid-segment")', data)
        self.assertNotIn('x-kardashev-type-1', data)
        self.assertNotIn('x-planetary-grid-charge', data)
        controller = data[data.index('"x-planetary-grid-controller"'):data.index('planetary_grid_controller.energy_source')]
        self.assertIn('"1TW"', controller)
        charge_recipe = data[data.index('recipe("x-agi-training-run"'):data.index('add_lab_input("lab", "x-dollar")')]
        for expected in ['name = "x-agi-training-dataset", amount = 10000', 'name = "x-capital-allocation", amount = 1000', 'name = "x-planetary-grid-segment", amount = 10000', 'name = "x-megapack", amount = 1000', 'name = "x-agi-model", amount = 1', '3600']:
            self.assertIn(expected, charge_recipe)
        self.assertIn('name = "x-ai-token", amount = 10000', data)
        self.assertIn('name = "x-dollar", amount = 10000', data)
        for embodied_input in [
            '"x-satellite-bus"',
            '"x-ground-station-network"',
            '"space-science-pack"',
        ]:
            self.assertNotIn(embodied_input, charge_recipe)
        segment_recipe = data[data.index('recipe("x-planetary-grid-segment"'):data.index('recipe("x-agi-training-run"')]
        self.assertIn('"x-satellite-bus"', segment_recipe)
        self.assertIn('"x-ground-station-network"', segment_recipe)
        self.assertNotIn("x-k1-knowledge", data)
        self.assertIn('AGI_TOKEN_GATE = 1000000000', control)
        self.assertIn('controller_has_agi_model(controller)', control)
        self.assertIn('sync_agi_training_unlock(force, true)', control)
        self.assertIn('statistics.set_output_count(', control)
        self.assertIn('"Cumulative AI Tokens"', control)
        self.assertIn('game.set_game_state', control)

    def test_factoryx_compute_runs_reset_when_underpowered(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn('["x-terrestrial-datacenter"] = true', control)
        self.assertIn('["x-orbital-compute-array"] = true', control)
        self.assertIn('["x-planetary-grid-controller"] = AGI_TRAINING_RECIPE_NAME', control)
        self.assertIn('status == defines.entity_status.low_power', control)
        self.assertIn('status == defines.entity_status.no_power', control)
        self.assertIn('entity.energy < entity.electric_buffer_size * 0.1', control)
        self.assertIn('entity.crafting_progress = 0', control)
        self.assertIn('entity.disabled_by_script = true', control)
        self.assertIn('entity.energy >= entity.electric_buffer_size * 0.9', control)
        self.assertIn('entity.disabled_by_script = false', control)
        self.assertIn('script.on_nth_tick(1, reset_underpowered_compute_progress)', control)
        self.assertIn('while processed < 32', control)
        self.assertIn('track_factoryx_compute_machine(entity)', control)
        self.assertIn('rebuild_factoryx_compute_machines()', control)

    def test_customer_ev_owners_physically_commute_to_chargers(self):
        control = (MOD / "control.lua").read_text()
        roadmap = (ROOT / "factoryX.md").read_text()
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
            "fraction * (1 + supercharging * 0.1)",
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
        self.assertIn("Implemented V1", roadmap[roadmap.index("### Phase 2.6"):])

    def test_customer_scale_paths_are_cached_queued_and_event_driven(self):
        control = (MOD / "control.lua").read_text()
        self.assertIn("function factoryx_entity_registries", control)
        self.assertIn("function rebuild_factoryx_entity_registries", control)
        self.assertIn("function factoryx_market_cache", control)
        self.assertIn("local CUSTOMER_MARKET_CACHE_TICKS = 120", control)
        self.assertIn("game.tick - cached.tick < CUSTOMER_MARKET_CACHE_TICKS", control)
        self.assertIn("market_snapshot_cache_hits", control)
        self.assertIn("market_snapshot_builds", control)
        self.assertIn("function customer_buyer_queues", control)
        self.assertIn("function dequeue_available_buyer", control)
        self.assertIn("defines.events.on_entity_spawned", control)
        self.assertIn("event.spawner", control)
        self.assertIn("if not market_force_name then return end", control)
        self.assertIn('registered_factoryx_entities("sales_offices")', control)
        self.assertIn('registered_factoryx_entities("stations", force, surface)', control)
        self.assertIn('registered_factoryx_entities("ai_machines", force)', control)
        self.assertIn("performance_status = function", control)
        self.assertIn('require("runtime.timing_wheel")', control)
        self.assertIn('require("runtime.performance_state")', control)
        self.assertIn("reconcile_factoryx_entity_registry_step", control)
        self.assertIn('mark_factoryx_market_dirty(entity.force, "infrastructure-built")', control)
        buyer_start = control.index("function eligible_customer_buyers")
        buyer_end = control.index("function reserve_office_buyers", buyer_start)
        self.assertNotIn("pairs(customer_unit_registry())", control[buyer_start:buyer_end])
        commute_start = control.index("function process_customer_charging_commutes")
        commute_end = control.index("function handle_customer_commute_command_completed", commute_start)
        self.assertNotIn("pairs(customer_vehicle_owners())", control[commute_start:commute_end])
        ai_start = control.index("function track_ai_efficiency_progress")
        ai_end = control.index("function factoryx_accelerated_start_enabled", ai_start)
        self.assertNotIn("find_entities_filtered", control[ai_start:ai_end])
        once_per_second = control[
            control.index("script.on_nth_tick(60, function()"):
            control.index("script.on_nth_tick(UiRefresh.interval_ticks")
        ]
        self.assertEqual(once_per_second.count("calculate_station_utilization(station.force)"), 1)
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
        self.assertLess(built.index("track_factoryx_entity(entity)"), built.index("handle_station_built(entity, event)"))
        self.assertLess(built.index('mark_factoryx_market_dirty(entity.force, "infrastructure-built")'),
                        built.index("handle_station_built(entity, event)"))
        self.assertIn("refresh_factoryx_infrastructure_change(entity)", built)
        refresh_start = control.index("function refresh_factoryx_infrastructure_change")
        refresh_end = control.index("local function sync_biter_customer_diplomacy", refresh_start)
        refresh = control[refresh_start:refresh_end]
        self.assertIn("sync_customer_settlements()", refresh)
        self.assertIn("sync_sales_office_buyers()", refresh)
        self.assertIn("update_charger_stall_visuals(true)", refresh)
        self.assertIn("refresh_progress_panel(player)", refresh)
        removed = control[built_end:control.index("script.on_nth_tick(1", built_end)]
        self.assertIn("refresh_factoryx_infrastructure_change(entity)", removed)

    def test_factoryx_scale_benchmark_and_runtime_modules_exist(self):
        timing_wheel = (MOD / "runtime/timing_wheel.lua").read_text()
        performance_state = (MOD / "runtime/performance_state.lua").read_text()
        customer_aggregates = (MOD / "runtime/customer_aggregates.lua").read_text()
        buyer_queues = (MOD / "runtime/buyer_queues.lua").read_text()
        robotaxi_service = (MOD / "runtime/robotaxi_service.lua").read_text()
        power_queue = (MOD / "runtime/power_queue.lua").read_text()
        ui_refresh = (MOD / "runtime/ui_refresh.lua").read_text()
        benchmark = (ROOT / "scripts/benchmark-factoryx-scale.sh").read_text()
        self.assertIn("function TimingWheel.schedule", timing_wheel)
        self.assertIn("function TimingWheel.pop_due", timing_wheel)
        self.assertIn("math.ceil(due_tick / 60)", timing_wheel)
        self.assertIn("function PerformanceState.invalidate", performance_state)
        self.assertIn("state.invalidations[reason]", performance_state)
        self.assertIn("function CustomerAggregates.rebuild", customer_aggregates)
        self.assertIn('require("runtime.customer_aggregates")', (MOD / "control.lua").read_text())
        self.assertIn("function BuyerQueues.pop_valid", buyer_queues)
        self.assertIn('require("runtime.buyer_queues")', (MOD / "control.lua").read_text())
        self.assertIn("function RobotaxiService.metrics", robotaxi_service)
        self.assertIn("function PowerQueue.next", power_queue)
        self.assertIn("interval_ticks = 300", ui_refresh)
        self.assertIn("progress_interval_ticks = 1800", ui_refresh)
        self.assertIn("function UiRefresh.should_refresh_progress", ui_refresh)
        self.assertIn('require("runtime.robotaxi_service")', (MOD / "control.lua").read_text())
        self.assertIn('require("runtime.power_queue")', (MOD / "control.lua").read_text())
        self.assertIn('require("runtime.ui_refresh")', (MOD / "control.lua").read_text())
        self.assertIn("factoryx_progress_panel_signatures", (MOD / "control.lua").read_text())
        self.assertIn("FACTORYX_BENCHMARK_UNITS:-20000", benchmark)
        self.assertIn("FACTORYX_BENCHMARK_CAPS", benchmark)
        self.assertIn("0 128 256 512", benchmark)
        self.assertIn("completed_commands", benchmark)
        self.assertIn("performance_test_seed_owner", benchmark)

    def test_factoryx_avoids_capex_language(self):
        combined = "\n".join(
            [
                (MOD / "data.lua").read_text(),
                (MOD / "control.lua").read_text(),
                (MOD / "locale/en/factoryx.cfg").read_text(),
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
        self.assertIn("update_customer_settlement_alerts(force, service)", control)
        self.assertIn('kind = assigned_capacity < vehicle_count and "capacity" or "power"', control)
        self.assertIn("Place or upgrade an EV charger near this settlement.", control)
        self.assertIn("EVs lack powered charging service. Restore grid power.", control)
        self.assertIn('{type = "item", name = "x-ev-charging-station"}', control)
        self.assertIn('{type = "item", name = "accumulator"}', control)
        self.assertIn("player.add_custom_alert(", control)
        self.assertIn("player.remove_alert{entity = settlement", control)
        self.assertIn("Custom alerts expire. Refresh persistent disruptions", control)
        self.assertNotIn("[FactoryX] Charging disruption:", control)
        self.assertNotIn("[FactoryX] Customer charging access restored.", control)
        self.assertNotIn("[FactoryX] Customer settlement expanded", control)

    def test_cached_charger_assignments_tolerate_destroyed_settlements(self):
        control = (MOD / "control.lua").read_text()
        waiting = control[
            control.index("function waiting_market_buyers_at_station"):
            control.index("function station_reservation_demand")
        ]
        self.assertIn("if not is_station(station) then return 0 end", waiting)
        self.assertIn("if settlement and settlement.valid then", waiting)
        self.assertIn('mark_factoryx_market_dirty(station.force, "invalid-assigned-settlement")', waiting)
        self.assertIn("local key = settlement and settlement.valid and", control)
        self.assertIn("if not station or not station.valid then", control)

    def test_factoryx_stack_sizes_match_physical_scale(self):
        data = (MOD / "data.lua").read_text()
        for name in [
            "x-prototype-roadster",
            "x-premium-ev",
            "x-mass-market-ev",
            "x-cybertruck",
            "x-gigafactory-module",
            "x-wrecked-ev",
        ]:
            item_line = next(line for line in data.splitlines() if f'item("{name}"' in line)
            self.assertIn(", 1", item_line, name)
        robotaxi_line = next(line for line in data.splitlines() if 'item("x-robotaxi-fleet"' in line)
        self.assertIn(", 5,", robotaxi_line)
        for name in [
            "x-gigafactory-building",
            "x-gigafactory-v2",
            "x-terrestrial-datacenter",
            "x-orbital-compute-array",
            "x-planetary-grid-controller",
        ]:
            item_line = next(line for line in data.splitlines() if f'item("{name}"' in line)
            self.assertIn(", 1, {", item_line, name)
        for name in [
            "x-ev-charging-station",
            "x-ev-charging-station-v2",
            "x-ev-charging-station-v3",
            "x-ev-charging-station-v4",
        ]:
            item_line = next(line for line in data.splitlines() if f'item("{name}"' in line)
            self.assertIn(", 5, {", item_line, name)

    def test_factoryx_is_nauvis_and_nauvis_orbit_only(self):
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

        orbital = data[data.index('tech("x-orbital-compute"'):
                       data.index('tech("x-autonomous-logistics"')]
        self.assertIn('"space-platform"', orbital)
        self.assertIn('"space-science-pack"', orbital)
        self.assertNotIn('"electromagnetic-science-pack"', orbital)
        self.assertNotIn('"x-satellite-constellation"', orbital)

        planetary = data[data.index('tech("x-planetary-energy-grid"'):
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
        self.assertIn('{"x-dollar", 10}', updates)
        self.assertIn('epic_quality.prerequisites = {"quality-module-3", "x-terrestrial-ai"}', updates)
        self.assertIn('legendary_quality.prerequisites = {"epic-quality", "x-orbital-compute"}', updates)
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
