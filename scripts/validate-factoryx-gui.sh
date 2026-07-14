#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
factorio_bin="${FACTORIO_BINARY:-/Users/lukec/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-/Users/lukec/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/data}"
source_save="${1:-${FACTORIO_GUI_TEST_SAVE:-}}"

if [[ -z "$source_save" || ! -f "$source_save" ]]; then
  echo "Usage: $0 /path/to/factoryx-save.zip" >&2
  exit 2
fi

tmp="$(mktemp -d /tmp/factoryx-gui-validate.XXXXXX)"
mods="$tmp/mods"
helper="$mods/factoryx_gui_smoke_0.1.0"
save="$tmp/gui-smoke.zip"
report="$tmp/script-output/factoryx-gui-smoke.jsonl"

cleanup() {
  local status=$?
  if (( status != 0 )) && [[ -f "$tmp/factoryx-gui-benchmark.log" ]]; then
    tail -80 "$tmp/factoryx-gui-benchmark.log" >&2
  fi
  rm -rf "$tmp"
  return "$status"
}
trap cleanup EXIT

mkdir -p "$mods" "$helper" "$tmp/script-output"
cp "$source_save" "$save"
ln -s "$repo_root/mod/factoryx_0.1.0" "$mods/factoryx_0.1.0"

cat > "$tmp/config.ini" <<EOF_CONFIG
[path]
read-data=$read_data
write-data=$tmp
EOF_CONFIG

cat > "$mods/mod-list.json" <<'EOF_MOD_LIST'
{
  "mods": [
    {"name": "base", "enabled": true},
    {"name": "space-age", "enabled": true},
    {"name": "factoryx", "enabled": true},
    {"name": "factoryx_gui_smoke", "enabled": true}
  ]
}
EOF_MOD_LIST

cat > "$helper/info.json" <<'EOF_INFO'
{
  "name": "factoryx_gui_smoke",
  "version": "0.1.0",
  "title": "FactoryX GUI Smoke Test",
  "author": "Codex",
  "factorio_version": "2.1",
  "dependencies": ["base >= 2.1.0", "space-age >= 2.1.0", "factoryx >= 0.1.0"]
}
EOF_INFO

cat > "$helper/control.lua" <<'EOF_LUA'
local REPORT = "factoryx-gui-smoke.jsonl"

local function write_report(payload)
  helpers.write_file(REPORT, helpers.table_to_json(payload) .. "\n", true)
end

local function first_entity(player, name)
  for _, surface in pairs(game.surfaces) do
    local entities = surface.find_entities_filtered{name = name, force = player.force}
    if entities[1] then
      return entities[1]
    end
  end
  return nil
end

local function dollar_diagnostics(player)
  local total = 0
  local surfaces = {}
  for _, surface in pairs(game.surfaces) do
    local statistics = player.force.get_item_production_statistics(surface)
    local count = statistics.get_output_count("x-dollar") or 0
    total = total + count
    surfaces[surface.name] = {
      method = count,
      output_counts = statistics.output_counts["x-dollar"] or 0
    }
  end
  local offices = {}
  for _, surface in pairs(game.surfaces) do
    for _, office in pairs(surface.find_entities_filtered{name = "x-sales-office", force = player.force}) do
      local recipe = office.get_recipe()
      offices[#offices + 1] = {
        surface = surface.name,
        recipe = recipe and recipe.name,
        products_finished = office.products_finished
      }
    end
  end
  return {total = total, surfaces = surfaces, offices = offices}
end

local function find_named(element, name)
  if not element or not element.valid then
    return nil
  end
  if element.name == name then
    return element
  end
  for _, child in pairs(element.children or {}) do
    local found = find_named(child, name)
    if found then
      return found
    end
  end
  return nil
end

local function has_caption(element, caption)
  if not element or not element.valid then return false end
  if element.caption == caption then return true end
  for _, child in pairs(element.children or {}) do
    if has_caption(child, caption) then return true end
  end
  return false
end

script.on_event(defines.events.on_tick, function()
  if storage.complete then
    return
  end
  if game.tick_paused then
    game.tick_paused = false
  end

  local player = game.get_player(1)
  if not player then
    write_report{status = "failed", reason = "save has no player 1"}
    storage.complete = true
    return
  end

  remote.call("factoryx", "grant_energy_jumpstart", player.index)
  local jumpstart_solar = 0
  local jumpstart_megapacks = 0
  local jumpstart_substations = 0
  local jumpstart_roboports = 0
  local jumpstart_construction_robots = 0
  local jumpstart_logistic_robots = 0
  for _, chest in pairs(player.surface.find_entities_filtered{
    name = "passive-provider-chest",
    force = player.force,
    position = player.position,
    radius = 64
  }) do
    local inventory = chest.get_inventory(defines.inventory.chest)
    if inventory then
      jumpstart_solar = jumpstart_solar + inventory.get_item_count{name = "x-high-density-solar-array", quality = "legendary"}
      jumpstart_megapacks = jumpstart_megapacks + inventory.get_item_count{name = "x-megapack", quality = "legendary"}
      jumpstart_substations = jumpstart_substations + inventory.get_item_count{name = "substation", quality = "legendary"}
      jumpstart_roboports = jumpstart_roboports + inventory.get_item_count{name = "roboport", quality = "legendary"}
      jumpstart_construction_robots = jumpstart_construction_robots + inventory.get_item_count{name = "construction-robot", quality = "legendary"}
      jumpstart_logistic_robots = jumpstart_logistic_robots + inventory.get_item_count{name = "logistic-robot", quality = "legendary"}
    end
  end

  local progress_ok, progress_result = pcall(function()
    return remote.call("factoryx", "open_progress", player.index)
  end)
  local progress_status = remote.call("factoryx", "progress_status", player.force.name)
  local market_status = remote.call("factoryx", "refresh_biter_customer_market", player.force.name)
  local integrity_ok, integrity_result = pcall(function()
    return remote.call("factoryx", "progression_integrity", player.force.name)
  end)
  local office = first_entity(player, "x-sales-office")
  local office_open_ok, office_open_error = pcall(function()
    if office then
      player.opened = office
      remote.call("factoryx", "open_entity_info", player.index, office)
    end
  end)
  local sales_office_panel_created = player.gui.relative.factoryx_entity_info_panel ~= nil
  local progress_panel = player.gui.screen.factoryx_progress_panel
  local progress_has_business = has_caption(progress_panel, "Business")
  local progress_has_current_premium = has_caption(progress_panel, "Premium EVs")
  local progress_has_future_robotaxi = has_caption(progress_panel, "Robotaxi Service Centers")
  local progress_has_future_agi = has_caption(progress_panel, "AGI training")
  local dollars_label = find_named(progress_panel, "factoryx_dollars_produced_value")
  local dollars_caption = dollars_label and dollars_label.caption
  local solar_productivity_label = find_named(progress_panel, "factoryx_solar_productivity_level_value")
  local megapack_productivity_label = find_named(progress_panel, "factoryx_megapack_productivity_level_value")
  local solar_productivity_caption = solar_productivity_label and solar_productivity_label.caption
  local megapack_productivity_caption = megapack_productivity_label and megapack_productivity_label.caption
  local gigafactory
  local datacenter
  local gigafactory_v2
  local charger
  local charger_panel_created = false
  local datacenter_recipe_selected = false
  local robotaxi_recipe_selected = false
  local datacenter_panel_created = false
  local gigafactory_v2_panel_created = false
  local charger_shared_build_event_ok = false
  local charger_shared_build_event_error
  local custom_power_alert_ok = false
  if office then
    local surface = office.surface
    custom_power_alert_ok = pcall(function()
      player.add_custom_alert(
        office,
        {type = "item", name = "x-sales-office"},
        "FactoryX alert API smoke test",
        true
      )
      player.remove_alert{entity = office, type = defines.alert_type.custom}
    end)
    local station_position = surface.find_non_colliding_position(
      "x-ev-charging-station",
      {office.position.x + 128, office.position.y + 128},
      128,
      1
    )
    if station_position then
      charger = surface.create_entity{
        name = "x-ev-charging-station",
        position = station_position,
        force = player.force
      }
      if charger then
        charger_shared_build_event_ok, charger_shared_build_event_error = pcall(function()
          script.raise_event(defines.events.script_raised_built, {entity = charger})
        end)
        player.opened = charger
        remote.call("factoryx", "open_entity_info", player.index, charger)
        charger_panel_created = player.gui.screen.factoryx_station_info_panel ~= nil
      end
    end
    local position = surface.find_non_colliding_position(
      "x-gigafactory-building",
      {office.position.x + 24, office.position.y},
      128,
      1
    )
    if position then
      gigafactory = surface.create_entity{
        name = "x-gigafactory-building",
        position = position,
        force = player.force
      }
      if gigafactory then
        player.opened = gigafactory
        remote.call("factoryx", "open_entity_info", player.index, gigafactory)
      end
    end
    for _, technology_name in pairs({"x-terrestrial-ai", "x-autonomous-logistics"}) do
      local technology = player.force.technologies[technology_name]
      if technology then
        technology.researched = true
      end
    end
    remote.call("factoryx", "progression_integrity", player.force.name)
    local datacenter_position = surface.find_non_colliding_position(
      "x-terrestrial-datacenter",
      {office.position.x + 40, office.position.y},
      128,
      1
    )
    if datacenter_position then
      datacenter = surface.create_entity{
        name = "x-terrestrial-datacenter",
        position = datacenter_position,
        force = player.force
      }
      if datacenter then
        datacenter.set_recipe("x-terrestrial-ai-token")
        datacenter_recipe_selected = datacenter.get_recipe()
          and datacenter.get_recipe().name == "x-terrestrial-ai-token"
        player.opened = datacenter
        remote.call("factoryx", "open_entity_info", player.index, datacenter)
        datacenter_panel_created = player.gui.relative.factoryx_entity_info_panel ~= nil
      end
    end
    local gigafactory_v2_position = surface.find_non_colliding_position(
      "x-gigafactory-v2",
      {office.position.x + 56, office.position.y},
      128,
      1
    )
    if gigafactory_v2_position then
      gigafactory_v2 = surface.create_entity{
        name = "x-gigafactory-v2",
        position = gigafactory_v2_position,
        force = player.force
      }
      if gigafactory_v2 then
        gigafactory_v2.set_recipe("x-robotaxi-fleet")
        robotaxi_recipe_selected = gigafactory_v2.get_recipe()
          and gigafactory_v2.get_recipe().name == "x-robotaxi-fleet"
        player.opened = gigafactory_v2
        remote.call("factoryx", "open_entity_info", player.index, gigafactory_v2)
        gigafactory_v2_panel_created = player.gui.relative.factoryx_entity_info_panel ~= nil
      end
    end
  end

  write_report{
    status = "checked",
    progress_call_ok = progress_ok,
    jumpstart_solar = jumpstart_solar,
    jumpstart_megapacks = jumpstart_megapacks,
    jumpstart_substations = jumpstart_substations,
    jumpstart_roboports = jumpstart_roboports,
    jumpstart_construction_robots = jumpstart_construction_robots,
    jumpstart_logistic_robots = jumpstart_logistic_robots,
    progress_result = progress_result,
    progress_panel_created = player.gui.screen.factoryx_progress_panel ~= nil,
    progress_has_business = progress_has_business,
    progress_has_current_premium = progress_has_current_premium,
    progress_has_future_robotaxi = progress_has_future_robotaxi,
    progress_has_future_agi = progress_has_future_agi,
    progress_status = progress_status,
    progress_dollars = progress_status and progress_status.snapshot.dollars_produced,
    progress_dollars_caption = dollars_caption,
    solar_productivity_caption = solar_productivity_caption,
    megapack_productivity_caption = megapack_productivity_caption,
    market_status = market_status,
    progression_integrity_call_ok = integrity_ok,
    progression_integrity = integrity_result,
    logistic_system_researched = player.force.technologies["logistic-system"]
      and player.force.technologies["logistic-system"].researched,
    dollar_diagnostics = dollar_diagnostics(player),
    sales_office_found = office ~= nil,
    sales_office_open_ok = office_open_ok,
    sales_office_open_error = office_open_ok and nil or tostring(office_open_error),
    sales_office_panel_created = sales_office_panel_created,
    charger_created = charger ~= nil,
    charger_panel_created = charger_panel_created,
    gigafactory_created = gigafactory ~= nil,
    gigafactory_panel_created = player.gui.relative.factoryx_entity_info_panel ~= nil,
    datacenter_created = datacenter ~= nil,
    datacenter_recipe_selected = datacenter_recipe_selected,
    datacenter_panel_created = datacenter_panel_created,
    gigafactory_v2_created = gigafactory_v2 ~= nil,
    robotaxi_recipe_selected = robotaxi_recipe_selected,
    gigafactory_v2_panel_created = gigafactory_v2_panel_created,
    custom_power_alert_ok = custom_power_alert_ok,
    charger_shared_build_event_ok = charger_shared_build_event_ok,
    charger_shared_build_event_error = charger_shared_build_event_ok
      and nil or tostring(charger_shared_build_event_error),
    prototype_roadster_enabled = player.force.recipes["x-prototype-roadster"].enabled
  }
  storage.complete = true
end)
EOF_LUA

rm -f "$report"
"$factorio_bin" \
  --config "$tmp/config.ini" \
  --mod-directory "$mods" \
  --benchmark "$save" \
  --benchmark-ticks 2 \
  --benchmark-runs 1 \
  >"$tmp/factoryx-gui-benchmark.log" 2>&1

python3 - "$report" <<'PY'
import json
import sys
from pathlib import Path

report = Path(sys.argv[1])
records = [json.loads(line) for line in report.read_text().splitlines() if line.strip()]
checked = next((record for record in records if record.get("status") == "checked"), None)
if checked is None:
    raise SystemExit(f"GUI smoke report missing checked record: {records}")
for field in (
    "progress_call_ok",
    "progress_result",
    "progress_panel_created",
    "progress_has_business",
    "progress_has_current_premium",
    "progression_integrity_call_ok",
    "logistic_system_researched",
    "sales_office_found",
    "sales_office_open_ok",
    "sales_office_panel_created",
    "charger_created",
    "charger_panel_created",
    "gigafactory_created",
    "gigafactory_panel_created",
    "datacenter_created",
    "datacenter_recipe_selected",
    "datacenter_panel_created",
    "gigafactory_v2_created",
    "robotaxi_recipe_selected",
    "gigafactory_v2_panel_created",
    "custom_power_alert_ok",
    "charger_shared_build_event_ok",
    "prototype_roadster_enabled",
):
    if not checked.get(field):
        raise SystemExit(f"FactoryX GUI check failed at {field}: {checked}")
for field in ("progress_has_future_robotaxi", "progress_has_future_agi"):
    if checked.get(field):
        raise SystemExit(f"FactoryX progress panel revealed future content at {field}: {checked}")
integrity = checked.get("progression_integrity", {})
if not integrity.get("ok") or integrity.get("disabled_recipes"):
    raise SystemExit(f"FactoryX progressed-save integrity check failed: {checked}")
diagnostics_total = checked.get("dollar_diagnostics", {}).get("total")
if checked.get("progress_dollars") != diagnostics_total:
    raise SystemExit(f"FactoryX progress snapshot Dollar count mismatch: {checked}")
represented_profit = f"${diagnostics_total * 10000:,} ({diagnostics_total} $)"
if checked.get("progress_dollars_caption") != represented_profit:
    raise SystemExit(f"FactoryX progress panel Dollar caption mismatch: {checked}")
if checked.get("solar_productivity_caption") not in (None, "Level 0"):
    raise SystemExit(f"FactoryX progress panel solar productivity caption mismatch: {checked}")
if checked.get("megapack_productivity_caption") not in (None, "Level 0"):
    raise SystemExit(f"FactoryX progress panel Megapack productivity caption mismatch: {checked}")
print("FactoryX GUI smoke report OK:", json.dumps(checked, sort_keys=True))
PY
