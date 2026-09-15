#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
factorio_bin="${FACTORIO_BINARY:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/data}"
profile=""
save=""
hours=""
ticks=""
timing_ticks=3600
sample_ticks=3600
warmup_ticks=60
max_average_ms=8
max_p99_ms=16.667
max_spike_ms=100
output_dir=""
skip_profile_requirements=0

usage() {
  cat <<'EOF'
Usage: scripts/soak-bitermotors-save.sh --profile terrestrial|orbital --save SAVE.zip [options]

Options:
  --hours N                    Simulated hours; defaults to 4 terrestrial or 1 orbital.
  --ticks N                    Exact simulated ticks, overriding --hours.
  --timing-ticks N             Bounded verbose timing sample; default 3600.
  --sample-ticks N             Probe snapshot interval; default 3600.
  --warmup-ticks N             Timing samples discarded after load; default 60.
  --max-average-ms N           Long-run average threshold; default 8.
  --max-p99-ms N               Warm timing p99 threshold; default 16.667.
  --max-spike-ms N             Warm timing maximum threshold; default 100.
  --output-dir DIR             Durable results directory; defaults under /tmp.
  --skip-profile-requirements  Measure a save without enforcing profile fixtures.

The harness packages the current checkout, validates that exact archive, loads a
copy of the supplied save in an isolated Factorio user directory, and never
modifies the original save.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) profile="${2:?missing profile}"; shift 2 ;;
    --save) save="${2:?missing save}"; shift 2 ;;
    --hours) hours="${2:?missing hours}"; shift 2 ;;
    --ticks) ticks="${2:?missing ticks}"; shift 2 ;;
    --timing-ticks) timing_ticks="${2:?missing timing ticks}"; shift 2 ;;
    --sample-ticks) sample_ticks="${2:?missing sample ticks}"; shift 2 ;;
    --warmup-ticks) warmup_ticks="${2:?missing warmup ticks}"; shift 2 ;;
    --max-average-ms) max_average_ms="${2:?missing average threshold}"; shift 2 ;;
    --max-p99-ms) max_p99_ms="${2:?missing p99 threshold}"; shift 2 ;;
    --max-spike-ms) max_spike_ms="${2:?missing spike threshold}"; shift 2 ;;
    --output-dir) output_dir="${2:?missing output directory}"; shift 2 ;;
    --skip-profile-requirements) skip_profile_requirements=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ "$profile" == "terrestrial" || "$profile" == "orbital" ]] || {
  echo "--profile must be terrestrial or orbital" >&2
  exit 2
}
[[ -n "$save" && -f "$save" ]] || { echo "--save must name an existing save" >&2; exit 2; }
[[ -x "$factorio_bin" ]] || { echo "Factorio binary is not executable: $factorio_bin" >&2; exit 2; }

if [[ -z "$ticks" ]]; then
  if [[ -z "$hours" ]]; then
    [[ "$profile" == "terrestrial" ]] && hours=4 || hours=1
  fi
  ticks="$(python3 - "$hours" <<'PY'
from decimal import Decimal
import sys
ticks = Decimal(sys.argv[1]) * 60 * 60 * 60
if ticks != ticks.to_integral_value() or ticks <= 0:
    raise SystemExit("--hours must produce a positive whole number of ticks")
print(int(ticks))
PY
)"
fi

for numeric in "$ticks" "$timing_ticks" "$sample_ticks" "$warmup_ticks"; do
  [[ "$numeric" =~ ^[0-9]+$ ]] || { echo "tick values must be non-negative integers" >&2; exit 2; }
done
(( ticks > 0 && timing_ticks > warmup_ticks && sample_ticks > 0 )) || {
  echo "ticks must be positive and timing ticks must exceed warmup ticks" >&2
  exit 2
}

tmp="$(mktemp -d /tmp/bitermotors-soak.XXXXXX)"
if [[ -z "$output_dir" ]]; then
  output_dir="$(mktemp -d /tmp/bitermotors-soak-results.XXXXXX)"
fi
mkdir -p "$output_dir" "$tmp/mods" "$tmp/saves" "$tmp/script-output" "$tmp/release"
mods="$tmp/mods"
probe="$mods/bitermotors_soak_probe_0.1.1"
mkdir -p "$probe"

archive="$(python3 "$repo_root/scripts/package-bitermotors.py" --output-dir "$tmp/release")"
python3 "$repo_root/scripts/check-bitermotors-release.py" \
  "$archive" --source "$repo_root/mod/bitermotors_0.1.1"
cp "$archive" "$mods/"
cp "$save" "$tmp/saves/soak.zip"

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
    {"name": "bitermotors", "enabled": true},
    {"name": "bitermotors_soak_probe", "enabled": true}
  ]
}
EOF_MOD_LIST

cat > "$probe/info.json" <<'EOF_INFO'
{
  "name": "bitermotors_soak_probe",
  "version": "0.1.1",
  "title": "Biter Motors Soak Probe",
  "author": "Biter Motors",
  "factorio_version": "2.1",
  "dependencies": ["base >= 2.1.0", "space-age >= 2.1.0", "bitermotors >= 0.1.1"]
}
EOF_INFO

cat > "$probe/control.lua" <<EOF_LUA
local PROFILE = "$profile"
local SAMPLE_TICKS = $sample_ticks
local PERIODIC_PROBE = true
local REPORT = "bitermotors-soak.jsonl"
local CORE = "bitermotors-orbital-datacenter-core"

local function call_status(method)
  if not remote.interfaces.bitermotors or not remote.interfaces.bitermotors[method] then
    return nil, "missing bitermotors." .. method
  end
  local ok, value = pcall(remote.call, "bitermotors", method, "player")
  if not ok then return nil, tostring(value) end
  return value, nil
end

local function snapshot(kind)
  local progress, progress_error = call_status("progress_status")
  local ending, endgame_error = call_status("endgame_status")
  local performance, performance_error = call_status("performance_status")
  local platform_count = 0
  local core_count = 0
  for _, surface in pairs(game.surfaces) do
    local ok, platform = pcall(function() return surface.platform end)
    if ok and platform then platform_count = platform_count + 1 end
    core_count = core_count + #surface.find_entities_filtered{name = CORE, force = "player"}
  end
  local active_cores = 0
  for _, core in pairs(ending and ending.cores or {}) do
    if core.recipe == "bitermotors-orbital-ai-token"
      and core.cooled
      and (core.power_fraction or 0) > 0 then
      active_cores = active_cores + 1
    end
  end
  helpers.write_file(REPORT, helpers.table_to_json{
    kind = kind,
    profile = PROFILE,
    tick = game.tick,
    platform_count = platform_count,
    orbital_core_count = core_count,
    active_orbital_core_count = active_cores,
    progress = progress and progress.snapshot or nil,
    endgame = ending,
    performance = performance,
    errors = {
      progress = progress_error,
      endgame = endgame_error,
      performance = performance_error
    }
  } .. "\n", true)
end

local function initialize()
  game.tick_paused = false
  storage.bitermotors_soak_started = game.tick
  snapshot("initial")
end

script.on_init(initialize)
script.on_configuration_changed(initialize)
if PERIODIC_PROBE then
  script.on_nth_tick(SAMPLE_TICKS, function()
    snapshot("periodic")
  end)
end
EOF_LUA

benchmark_log="$output_dir/benchmark.log"
timing_log="$output_dir/timing-sample.log"
probe_report="$tmp/script-output/bitermotors-soak.jsonl"
summary="$output_dir/summary.json"

benchmark_args=(
  --config "$tmp/config.ini"
  --mod-directory "$mods"
  --benchmark "$tmp/saves/soak.zip"
  --benchmark-runs 1
)

started_at="$(date +%s)"
echo "Running $profile soak for $ticks ticks..."
"$factorio_bin" "${benchmark_args[@]}" --benchmark-ticks "$ticks" >"$benchmark_log" 2>&1
[[ -s "$probe_report" ]] || { tail -120 "$benchmark_log" >&2; echo "Soak probe produced no report" >&2; exit 1; }
cp "$probe_report" "$output_dir/probe.jsonl"

echo "Running bounded timing sample for $timing_ticks ticks..."
python3 - "$probe/control.lua" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text()
old = "local PERIODIC_PROBE = true"
if old not in source:
    raise SystemExit("soak probe periodic flag was not found")
path.write_text(source.replace(old, "local PERIODIC_PROBE = false", 1))
PY
"$factorio_bin" "${benchmark_args[@]}" --benchmark-ticks "$timing_ticks" \
  --benchmark-verbose all >"$timing_log" 2>&1

factorio_version="$("$factorio_bin" --version | sed -n 's/^Version: \([^ ]*\).*/\1/p' | head -1)"
wall_seconds="$(( $(date +%s) - started_at ))"
analyzer_args=(
  --profile "$profile"
  --ticks "$ticks"
  --factorio-version "$factorio_version"
  --wall-seconds "$wall_seconds"
  --save "$save"
  --archive "$archive"
  --benchmark-log "$benchmark_log"
  --timing-log "$timing_log"
  --probe-report "$output_dir/probe.jsonl"
  --output "$summary"
  --warmup-ticks "$warmup_ticks"
  --max-average-ms "$max_average_ms"
  --max-p99-ms "$max_p99_ms"
  --max-spike-ms "$max_spike_ms"
)
if [[ "$skip_profile_requirements" == 1 ]]; then
  analyzer_args+=(--skip-profile-requirements)
fi
python3 "$repo_root/scripts/analyze-bitermotors-soak.py" "${analyzer_args[@]}"
echo "Artifacts: $output_dir"
echo "Isolated runtime: $tmp"
