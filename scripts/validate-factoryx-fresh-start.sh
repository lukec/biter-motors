#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
factorio_bin="${FACTORIO_BINARY:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/data}"
tmp="$(mktemp -d /tmp/factoryx-fresh-start.XXXXXX)"
mods="$tmp/mods"
helper="$mods/factoryx_fresh_start_test_0.1.0"
save="$tmp/fresh.zip"
report="$tmp/script-output/factoryx-fresh-start.jsonl"

mkdir -p "$mods" "$helper" "$tmp/script-output"
ln -sfn "$repo_root/mod/factoryx_0.1.0" "$mods/factoryx_0.1.0"

cat > "$tmp/config.ini" <<EOF
[path]
read-data=$read_data
write-data=$tmp
EOF
cat > "$mods/mod-list.json" <<'EOF'
{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":true},{"name":"factoryx","enabled":true},{"name":"factoryx_fresh_start_test","enabled":true}]}
EOF
cat > "$helper/info.json" <<'EOF'
{"name":"factoryx_fresh_start_test","version":"0.1.0","title":"FactoryX Fresh Start Test","author":"Codex","factorio_version":"2.1","dependencies":["base >= 2.1.0","space-age >= 2.1.0","factoryx >= 0.1.0"]}
EOF
cat > "$helper/control.lua" <<'EOF'
script.on_init(function()
  local force = game.forces.player
  local ship = remote.call("freeplay", "get_ship_items")
  local debris = remote.call("freeplay", "get_debris_items")
  local intro = remote.call("freeplay", "get_custom_intro_message")
  local technologies = {}
  for _, name in pairs({
    "steam-power", "automation-science-pack", "automation", "logistics", "electronics",
    "steel-processing", "steel-axe", "electric-mining-drill", "repair-pack", "military", "gun-turret", "radar",
    "heavy-armor", "stone-wall", "landfill", "circuit-network", "automation-2",
    "logistic-science-pack", "electric-energy-distribution-2", "advanced-material-processing",
    "advanced-material-processing-2", "oil-processing", "sulfur-processing", "plastics",
    "advanced-circuit", "fluid-handling", "lamp", "construction-robotics", "logistic-robotics",
    "modular-armor", "solar-panel-equipment", "battery-equipment",
    "night-vision-equipment", "personal-roboport-equipment"
  }) do
    technologies[name] = force.technologies[name] and force.technologies[name].researched or false
  end
  helpers.write_file("factoryx-fresh-start.jsonl", helpers.table_to_json{
    active_mods = script.active_mods,
    accelerated_start = settings.startup["x-accelerated-start"].value,
    ship = ship,
    debris = debris,
    intro = intro,
    technologies = technologies,
    pollution = game.map_settings.pollution.enabled,
    enemy_expansion = game.map_settings.enemy_expansion.enabled,
    sales_office_researched = force.technologies["x-sales-office"].researched,
    prototype_roadster_enabled = force.recipes["x-prototype-roadster"].enabled
  } .. "\n", true)
end)
EOF

"$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" --create "$save" >"$tmp/create.log" 2>&1

python3 - "$report" <<'PY'
import json
from pathlib import Path
import sys

path = Path(sys.argv[1])
row = json.loads(path.read_text().splitlines()[-1])
required_mods = {"base", "space-age", "quality", "factoryx"}
if not required_mods.issubset(row["active_mods"]):
    raise SystemExit(f"required mods missing: {row}")
if not row["accelerated_start"] or not row["pollution"] or not row["enemy_expansion"]:
    raise SystemExit(f"fresh map settings mismatch: {row}")
if not all(row["technologies"].values()):
    raise SystemExit(f"bootstrap technologies missing: {row}")
for name, count in {"steel-plate": 100, "electronic-circuit": 100, "iron-gear-wheel": 100, "assembling-machine-1": 4, "lab": 4, "lamp": 50}.items():
    if row["ship"].get(name) != count:
        raise SystemExit(f"ship inventory mismatch for {name}: {row}")
for name in ("iron-plate", "copper-plate", "transport-belt", "medium-electric-pole"):
    if row["debris"].get(name, 0) <= 0:
        raise SystemExit(f"debris inventory missing {name}: {row}")
for name in ("boiler", "steam-engine", "offshore-pump"):
    if row["debris"].get(name, 0) != 0:
        raise SystemExit(f"burner-era power item should not be in debris: {name}: {row}")
if "FACTORYX" not in str(row["intro"]) or "Recover the scattered cargo" not in str(row["intro"]):
    raise SystemExit(f"intro mismatch: {row}")
if row["sales_office_researched"] or row["prototype_roadster_enabled"]:
    raise SystemExit(f"FactoryX progression started unlocked: {row}")
print("FactoryX fresh Freeplay bootstrap OK")
PY
