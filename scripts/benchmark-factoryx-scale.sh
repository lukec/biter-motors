#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
factorio_bin="${FACTORIO_BINARY:-/Users/lukec/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-/Users/lukec/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/data}"
unit_count="${FACTORYX_BENCHMARK_UNITS:-20000}"
benchmark_ticks="${FACTORYX_BENCHMARK_TICKS:-3600}"
results="${FACTORYX_BENCHMARK_RESULTS:-/tmp/factoryx-20k-results.csv}"
register_owners="${FACTORYX_BENCHMARK_REGISTER_OWNERS:-1}"
read -r -a caps <<<"${FACTORYX_BENCHMARK_CAPS:-0 128 256 512}"

printf 'units,registered_owners,moving_cap,ticks,avg_ms,min_ms,max_ms,movers,moved_units,completed_commands,queued_commutes,active_commutes,market_builds,robotaxi_builds\n' >"$results"

for cap in "${caps[@]}"; do
  tmp="$(mktemp -d "/tmp/factoryx-scale-${cap}.XXXXXX")"
  mods="$tmp/mods"
  bench="$mods/factoryx_perf_benchmark_0.1.0"
  save="$tmp/saves/factoryx-scale.zip"
  report="$tmp/script-output/factoryx-scale.jsonl"
  mkdir -p "$mods" "$bench" "$tmp/saves" "$tmp/script-output"
  ln -sfn "$repo_root/mod/factoryx_0.1.0" "$mods/factoryx_0.1.0"

  cat >"$tmp/config.ini" <<EOF_CONFIG
[path]
read-data=$read_data
write-data=$tmp
EOF_CONFIG

  cat >"$mods/mod-list.json" <<'EOF_MOD_LIST'
{
  "mods": [
    {"name": "base", "enabled": true},
    {"name": "space-age", "enabled": true},
    {"name": "factoryx", "enabled": true},
    {"name": "factoryx_perf_benchmark", "enabled": true}
  ]
}
EOF_MOD_LIST

  cat >"$bench/info.json" <<'EOF_INFO'
{
  "name": "factoryx_perf_benchmark",
  "version": "0.1.0",
  "title": "FactoryX Performance Benchmark",
  "author": "Codex",
  "factorio_version": "2.1",
  "dependencies": ["base >= 2.1.0", "space-age >= 2.1.0", "factoryx >= 0.1.0"]
}
EOF_INFO

  report_tick=$((benchmark_ticks - 60))
  cat >"$bench/control.lua" <<EOF_LUA
local UNIT_COUNT = $unit_count
local REGISTER_OWNERS = $register_owners == 1
local MOVING_CAP = $cap
local REPORT_TICK = $report_tick
local REPORT = "factoryx-scale.jsonl"

local function command_mover(entity, direction)
  if not entity or not entity.valid or not entity.commandable then return end
  entity.commandable.set_command{
    type = defines.command.go_to_location,
    destination = {x = entity.position.x + direction * 24, y = entity.position.y},
    distraction = defines.distraction.none,
    radius = 1
  }
end

script.on_init(function()
  local surface = game.surfaces.nauvis or game.surfaces[1]
  local customers = game.forces["factoryx-customers"]
  local player_force = game.forces.player
  surface.request_to_generate_chunks({1200, 100}, 24)
  surface.force_generate_chunk_requests()
  local spawner = surface.create_entity{name = "biter-spawner", position = {1200, -20}, force = customers}
  storage.movers = {}
  storage.directions = {}
  storage.initial_positions = {}
  storage.completed_commands = 0
  local created = 0
  for index = 1, UNIT_COUNT do
    local column = (index - 1) % 200
    local row = math.floor((index - 1) / 200)
    local entity = surface.create_entity{
      name = "small-biter",
      position = {1000 + column * 2, row * 2},
      force = customers
    }
    if entity then
      created = created + 1
      entity.commandable.set_command{
        type = defines.command.wander,
        distraction = defines.distraction.none,
        radius = 0.1,
        ticks_to_wait = REPORT_TICK + 600
      }
      if REGISTER_OWNERS then
        remote.call(
          "factoryx",
          "performance_test_seed_owner",
          entity,
          spawner,
          player_force.name,
          "x-mass-market-ev",
          REPORT_TICK + 3600
        )
      end
      if created <= MOVING_CAP then
        storage.movers[entity.unit_number] = entity
        storage.directions[entity.unit_number] = created % 2 == 0 and 1 or -1
        storage.initial_positions[entity.unit_number] = {x = entity.position.x, y = entity.position.y}
        command_mover(entity, storage.directions[entity.unit_number])
      end
    end
  end
  storage.created = created
end)

script.on_event(defines.events.on_ai_command_completed, function(event)
  local entity = storage.movers[event.unit_number]
  if not entity or not entity.valid then return end
  storage.directions[event.unit_number] = -(storage.directions[event.unit_number] or 1)
  storage.completed_commands = storage.completed_commands + 1
  command_mover(entity, storage.directions[event.unit_number])
end)

script.on_nth_tick(REPORT_TICK, function()
  if game.tick < REPORT_TICK then return end
  local movers = 0
  local moved_units = 0
  for unit_number, entity in pairs(storage.movers) do
    if entity and entity.valid then
      movers = movers + 1
      local initial = storage.initial_positions[unit_number]
      local dx = initial and entity.position.x - initial.x or 0
      local dy = initial and entity.position.y - initial.y or 0
      if dx * dx + dy * dy > 1 then moved_units = moved_units + 1 end
    end
  end
  helpers.write_file(REPORT, helpers.table_to_json{
    tick = game.tick,
    created = storage.created,
    moving_cap = MOVING_CAP,
    registered_owners = REGISTER_OWNERS,
    movers = movers,
    moved_units = moved_units,
    completed_commands = storage.completed_commands,
    performance = remote.call("factoryx", "performance_status", "player")
  } .. "\n", true)
end)
EOF_LUA

  create_log="/tmp/factoryx-scale-${cap}-create.log"
  benchmark_log="/tmp/factoryx-scale-${cap}-benchmark.log"
  "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" --create "$save" >"$create_log" 2>&1
  if grep -qE 'non-recoverable error|Error while running event' "$create_log"; then
    tail -120 "$create_log" >&2
    exit 1
  fi
  rm -f "$report"
  "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" \
    --benchmark "$save" --benchmark-ticks "$benchmark_ticks" --benchmark-runs 1 >"$benchmark_log" 2>&1
  if grep -qE 'non-recoverable error|Error while running event' "$benchmark_log"; then
    tail -120 "$benchmark_log" >&2
    exit 1
  fi

  python3 - "$benchmark_log" "$report" "$results" "$unit_count" "$cap" "$benchmark_ticks" <<'PY'
import json
import re
import sys
from pathlib import Path

log = Path(sys.argv[1]).read_text()
report = json.loads(Path(sys.argv[2]).read_text().splitlines()[-1])
match = re.search(r"avg: ([0-9.]+) ms, min: ([0-9.]+) ms, max: ([0-9.]+) ms", log)
if not match:
    raise SystemExit("benchmark timing was not found")
performance = report["performance"]
counters = performance.get("counters", {})
row = [
    sys.argv[4], str(report.get("registered_owners", False)).lower(), sys.argv[5], sys.argv[6], *match.groups(),
    report.get("movers", 0),
    report.get("moved_units", 0),
    report.get("completed_commands", 0),
    performance.get("queued_commutes", 0),
    performance.get("active_commutes", 0),
    counters.get("market_snapshot_builds", 0),
    counters.get("robotaxi_allocation_builds", 0),
]
with Path(sys.argv[3]).open("a") as handle:
    handle.write(",".join(map(str, row)) + "\n")
PY
  rm -rf "$tmp"
done

cat "$results"
