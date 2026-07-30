#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
factorio_bin="${FACTORIO_BINARY:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/data}"
tmp="$(mktemp -d /tmp/factoryx-battery-resources.XXXXXX)"
mods="$tmp/mods"
helper="$mods/factoryx_battery_resource_test_0.1.0"
save="$tmp/resources.zip"
report="$tmp/script-output/factoryx-battery-resources.json"

mkdir -p "$mods" "$helper" "$tmp/script-output"
ln -sfn "$repo_root/mod/factoryx_0.1.0" "$mods/factoryx_0.1.0"

cat > "$tmp/config.ini" <<EOF
[path]
read-data=$read_data
write-data=$tmp
EOF
cat > "$mods/mod-list.json" <<'EOF'
{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":true},{"name":"factoryx","enabled":true},{"name":"factoryx_battery_resource_test","enabled":true}]}
EOF
cat > "$helper/info.json" <<'EOF'
{"name":"factoryx_battery_resource_test","version":"0.1.0","title":"FactoryX Battery Resource Test","author":"Codex","factorio_version":"2.1","dependencies":["base >= 2.1.0","space-age >= 2.1.0","factoryx >= 0.1.0"]}
EOF
cat > "$helper/control.lua" <<'EOF'
local function nearest_distance(surface, name, radius)
  local nearest
  local count = 0
  for _, entity in pairs(surface.find_entities_filtered{
    name = name,
    area = {{-radius, -radius}, {radius, radius}}
  }) do
    count = count + 1
    local distance = math.sqrt(entity.position.x ^ 2 + entity.position.y ^ 2)
    if not nearest or distance < nearest then nearest = distance end
  end
  return nearest, count
end

script.on_init(function()
  local surface = game.surfaces.nauvis
  local radius = 1024
  surface.request_to_generate_chunks({0, 0}, math.ceil(radius / 32))
  surface.force_generate_chunk_requests()
  local nickel_distance, nickel_tiles = nearest_distance(surface, "x-nickel-ore", radius)
  local lithium_distance, lithium_wells = nearest_distance(surface, "x-lithium-brine", radius)
  local uranium_distance, uranium_tiles = nearest_distance(surface, "uranium-ore", radius)
  helpers.write_file("factoryx-battery-resources.json", helpers.table_to_json{
    radius = radius,
    nickel_distance = nickel_distance,
    nickel_tiles = nickel_tiles,
    lithium_distance = lithium_distance,
    lithium_wells = lithium_wells,
    uranium_distance = uranium_distance,
    uranium_tiles = uranium_tiles
  }, false)
end)
EOF

"$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" --create "$save" >"$tmp/create.log" 2>&1

if rg -n "Error while running event|non-recoverable error|Failed to load mods" "$tmp/create.log"; then
  echo "Battery resource validation encountered a Factorio error: $tmp/create.log" >&2
  exit 1
fi

python3 - "$report" <<'PY'
import json
from pathlib import Path
import sys

row = json.loads(Path(sys.argv[1]).read_text())
for resource, count_field, distance_field in (
    ("Nickel Ore", "nickel_tiles", "nickel_distance"),
    ("Lithium Brine", "lithium_wells", "lithium_distance"),
    ("Uranium Ore", "uranium_tiles", "uranium_distance"),
):
    if row.get(count_field, 0) <= 0 or row.get(distance_field) is None:
        raise SystemExit(f"{resource} did not generate within {row['radius']} tiles: {row}")
print("FactoryX battery resource generation OK:", json.dumps(row, sort_keys=True))
PY
