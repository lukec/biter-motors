#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/scripts/lib/bitermotors-validation.sh"
bitermotors_resolve_source "$repo_root"
factorio_bin="${FACTORIO_BINARY:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/data}"
seed_settings=""
if [[ ${BITERMOTORS_SEED+x} ]]; then
  seed_settings="$(python3 "$repo_root/scripts/fresh_world_support.py" "$BITERMOTORS_SEED")"
fi
tmp="$(mktemp -d "${TMPDIR:-/tmp}/bitermotors-battery-resources.XXXXXX")"
seed_args=()
if [[ -n "$seed_settings" ]]; then
  printf '%s\n' "$seed_settings" > "$tmp/map-gen-settings.json"
  seed_args=(--map-gen-settings "$tmp/map-gen-settings.json")
fi
mods="$tmp/mods"
helper="$mods/bitermotors_battery_resource_test_0.1.1"
save="$tmp/resources.zip"
report="$tmp/script-output/bitermotors-battery-resources.json"

mkdir -p "$mods" "$helper" "$tmp/script-output"
bitermotors_stage_mod "$mods"

cat > "$tmp/config.ini" <<EOF
[path]
read-data=$read_data
write-data=$tmp
EOF
cat > "$mods/mod-list.json" <<'EOF'
{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":true},{"name":"bitermotors","enabled":true},{"name":"bitermotors_battery_resource_test","enabled":true}]}
EOF
cat > "$helper/info.json" <<'EOF'
{"name":"bitermotors_battery_resource_test","version":"0.1.1","title":"Biter Motors Battery Resource Test","author":"Codex","factorio_version":"2.1","dependencies":["base >= 2.1.0","space-age >= 2.1.0","bitermotors >= 0.1.0"]}
EOF
cat > "$helper/control.lua" <<'EOF'
local function measure(entities, resource)
  local nearest
  local count = 0
  local amount = 0
  for _, entity in pairs(entities) do
    count = count + 1
    if resource then amount = amount + entity.amount end
    local distance = math.sqrt(entity.position.x ^ 2 + entity.position.y ^ 2)
    if not nearest or distance < nearest then nearest = distance end
  end
  return {nearest = nearest, count = count, total_amount = resource and amount or nil}
end

script.on_init(function()
  local surface = game.surfaces.nauvis
  local radius = 1024
  surface.request_to_generate_chunks({0, 0}, math.ceil(radius / 32))
  surface.force_generate_chunk_requests()
  local area = {{-radius, -radius}, {radius, radius}}
  local resources = {}
  for _, name in ipairs({"iron-ore", "copper-ore", "coal", "stone", "crude-oil", "calcite",
      "bitermotors-nickel-ore", "bitermotors-lithium-brine", "uranium-ore"}) do
    resources[name] = measure(surface.find_entities_filtered{name = name, area = area}, true)
  end
  resources.water = measure(surface.find_tiles_filtered{collision_mask = "water_tile", area = area}, false)
  resources["enemy-spawners"] = measure(surface.find_entities_filtered{
    type = "unit-spawner", force = "enemy", area = area}, false)
  local nickel = resources["bitermotors-nickel-ore"]
  local lithium = resources["bitermotors-lithium-brine"]
  local uranium = resources["uranium-ore"]
  helpers.write_file("bitermotors-battery-resources.json", helpers.table_to_json{
    status = "battery_resources_complete",
    radius = radius,
    seed = surface.map_gen_settings.seed,
    peaceful_mode = surface.peaceful_mode,
    pollution = game.map_settings.pollution.enabled,
    enemy_expansion = game.map_settings.enemy_expansion.enabled,
    enemy_base_frequency = surface.map_gen_settings.autoplace_controls["enemy-base"].frequency,
    resources = resources,
    nickel_distance = nickel.nearest,
    nickel_tiles = nickel.count,
    lithium_distance = lithium.nearest,
    lithium_wells = lithium.count,
    uranium_distance = uranium.nearest,
    uranium_tiles = uranium.count
  }, false)
end)
EOF

"$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" "${seed_args[@]}" --create "$save" >"$tmp/create.log" 2>&1

bitermotors_check_log "$tmp/create.log" --expect-marker Goodbye

PYTHONPATH="$repo_root/scripts${PYTHONPATH:+:$PYTHONPATH}" python3 - "$report" <<'PY'
import json
from pathlib import Path
import sys
import os
from fresh_world_support import check_resources, parse_seed

row = json.loads(Path(sys.argv[1]).read_text())
if row.get("status") != "battery_resources_complete":
    raise SystemExit(f"battery resource report missing completion sentinel: {row}")
check_resources(row, parse_seed(os.environ["BITERMOTORS_SEED"]) if "BITERMOTORS_SEED" in os.environ else None)
for resource, count_field, distance_field in (
    ("Nickel Ore", "nickel_tiles", "nickel_distance"),
    ("Lithium Brine", "lithium_wells", "lithium_distance"),
    ("Uranium Ore", "uranium_tiles", "uranium_distance"),
):
    if row.get(count_field, 0) <= 0 or row.get(distance_field) is None:
        raise SystemExit(f"{resource} did not generate within {row['radius']} tiles: {row}")
print("Biter Motors battery resource generation OK:", json.dumps(row, sort_keys=True))
PY
printf 'Resource report: %s\n' "$report"
