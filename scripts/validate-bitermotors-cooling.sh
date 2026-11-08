#!/usr/bin/env bash
set -euo pipefail

validate_report() {
python3 - "$@" <<'EOF_CHECK'
import json
import math
import sys
from pathlib import Path

report, seed, save = map(Path, sys.argv[1:])
assert all(path.is_file() and path.stat().st_size > 0 for path in (seed, save)), "missing real saves"
rows = [json.loads(line) for line in report.read_text().splitlines() if line.strip()]
assert all(type(row) is dict for row in rows), rows
assert [row.get("status") for row in rows] == [
    "cooling_policy_passed", "cooling_checkpoint", "orbital_banked_reload_passed",
    "terrestrial_scrap_passed", "cooling_reload_passed"
], rows
policy, checkpoint, recovered, ground, final = rows
for row in rows:
    for key in ("tick", "assertions"):
        assert type(row.get(key)) is int and row[key] > 0, (key, row)
    assert not any("reset" in key for key in row), "obsolete reset evidence is not banked evidence"
assert policy["tick"] < checkpoint["tick"] < recovered["tick"] < ground["tick"] == final["tick"], rows
assert all(left["assertions"] < right["assertions"] for left, right in zip(rows[:3], rows[1:4])), rows
assert final["assertions"] == ground["assertions"], rows

def exact(row, **expected):
    for key, value in expected.items():
        assert type(row.get(key)) is type(value) and row[key] == value, (key, row)

exact(policy, work_policy="banked", platforms=2, zero_vs_one=True,
      capacity_scope="surface+force", before_first_craft_paused=True,
      supplied_power_fixture=True, solar_power_multiplier=0)
exact(checkpoint, work_policy="banked", failure="native_total_power", saved_file=save.name,
      power_limited=True, paused_for_cooling=False, generated=10000, products=0, output=0,
      quality="rare", dollars_supplied=1, dollars_remaining=0, replacement_dollars=0,
      cooling_progress_preserved=True, blocked_output_generated=0, base_products=1, base_output=10000,
      base_events=1)
assert type(checkpoint.get("saved_tick")) is int and checkpoint["saved_tick"] == checkpoint["tick"], checkpoint
for key in ("progress", "full_rate", "half_rate"):
    value = checkpoint.get(key)
    assert type(value) in (int, float) and math.isfinite(value) and value > 0, (key, checkpoint)
assert checkpoint["progress"] < 1, checkpoint
assert checkpoint["half_rate"] < checkpoint["full_rate"] * 0.8, checkpoint
exact(recovered, work_policy="banked", saved_tick=checkpoint["saved_tick"], quality="rare",
      replacement_dollars=0, dollars_supplied=1, dollars_remaining=0, recovered_products=1,
      recovery_output_delta=10000, recovery_ledger_delta=10000, generated=20000, native_events=1)
assert type(recovered.get("progress_after_reload")) in (int, float), recovered
assert recovered["progress_after_reload"] == checkpoint["progress"], rows
assert recovered["generated"] - checkpoint["generated"] == recovered["recovery_ledger_delta"], rows
exact(ground, original_dollars=20, scrapped_dollars=20, failure_generated=0,
      restored_without_inputs_products=0, retry_dollars=20, retry_products=1,
      retry_output=20, retry_generated=20, native_events=1)
exact(final, saved_tick=checkpoint["saved_tick"], work_policy="banked",
      orbital_generated=recovered["generated"], terrestrial_generated=ground["retry_generated"],
      platform_removal=True, separate_process_reload=True)
print("Cooling fixture passed:", json.dumps(rows, sort_keys=True))
EOF_CHECK
}

# Report-only validation never resolves or launches a Factorio executable.
if [[ "${1:-}" == --check-report ]]; then
  [[ $# == 4 ]] || { printf 'Usage: %s --check-report REPORT SEED CHECKPOINT\n' "$0" >&2; exit 2; }
  validate_report "$2" "$3" "$4"
  exit
fi
[[ $# == 0 ]] || { printf 'Unexpected cooling validator arguments\n' >&2; exit 2; }

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$repo_root/scripts/fixtures/cooling-control.lua"
if [[ ! -f "$fixture" ]]; then
  printf 'Cooling fixture is unavailable: %s\n' "$fixture" >&2
  exit 2
fi
source "$repo_root/scripts/lib/bitermotors-validation.sh"
bitermotors_resolve_source "$repo_root"
factorio_bin="${FACTORIO_BINARY:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-$(dirname "$factorio_bin")/../data}"
if [[ ! -x "$factorio_bin" ]]; then
  printf 'Factorio executable is unavailable: %s\n' "$factorio_bin" >&2
  exit 2
fi

tmp="$(mktemp -d /tmp/bitermotors-cooling.XXXXXX)"
mods="$tmp/mods"
helper="$mods/bitermotors_cooling_validation_0.1.1"
save="$tmp/saves/bitermotors-cooling-seed.zip"
checkpoint="$tmp/saves/bitermotors-cooling-failure.zip"
report="$tmp/script-output/bitermotors-cooling.jsonl"
mkdir -p "$helper" "$tmp/saves" "$tmp/script-output"
printf 'Isolated cooling artifacts: %s\n' "$tmp"
bitermotors_stage_mod "$mods"

cat > "$tmp/config.ini" <<EOF_CONFIG
[path]
read-data=$read_data
write-data=$tmp
EOF_CONFIG
cat > "$mods/mod-list.json" <<'EOF_MODS'
{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":true},
{"name":"bitermotors","enabled":true},{"name":"bitermotors_cooling_validation","enabled":true}]}
EOF_MODS
cat > "$helper/info.json" <<'EOF_INFO'
{"name":"bitermotors_cooling_validation","version":"0.1.1","title":"Biter Motors Cooling Validation","author":"Codex",
"factorio_version":"2.1","dependencies":["base >= 2.1.20","space-age >= 2.1.20","bitermotors >= 0.1.1"]}
EOF_INFO
cp "$fixture" "$helper/control.lua"
python3 - "$read_data/server-settings.example.json" "$tmp/server-settings.json" <<'EOF_SERVER'
import json
import sys
from pathlib import Path

settings = json.loads(Path(sys.argv[1]).read_text())
settings.update(name="Isolated Biter Motors cooling fixture",
                visibility={"public": False, "lan": False},
                require_user_verification=False, auto_pause=False, autosave_interval=0)
Path(sys.argv[2]).write_text(json.dumps(settings))
EOF_SERVER

run_engine() {
  local log="$1"
  shift
  local status=0
  "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" "$@" > "$log" 2>&1 || status=$?
  if ! bitermotors_check_log "$log" --expect-marker Goodbye; then tail -100 "$log" >&2; return 1; fi
  if (( status != 0 )); then tail -100 "$log" >&2; return "$status"; fi
}

run_engine "$tmp/create.log" --create "$save" --map-gen-seed 1062026
test -s "$save" || { printf 'Seeded save is missing: %s\n' "$save" >&2; exit 1; }
port="$(python3 - <<'EOF_PORT'
import socket
with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
EOF_PORT
)"
server_pid=""
server_stopped=1
server_status=0
start_server() {
  local source_save="$1" log="$2"
  rm -f "$tmp/server.stdin"
  mkfifo "$tmp/server.stdin"
  exec 3<> "$tmp/server.stdin"
  "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" \
    --start-server "$source_save" --server-settings "$tmp/server-settings.json" \
    --bind 127.0.0.1 --port "$port" <&3 > "$log" 2>&1 &
  server_pid=$!
  server_status=0
  server_stopped=0
  for _ in {1..100}; do
    if rg -q 'Hosting game at' "$log"; then break; fi
    if ! kill -0 "$server_pid" 2>/dev/null; then return 1; fi
    sleep 0.1
  done
  rg -q 'Hosting game at' "$log" || { printf 'Isolated server did not start: %s\n' "$log" >&2; return 1; }
}
stop_server() {
  if (( server_stopped == 0 )); then
    kill -INT "$server_pid" 2>/dev/null || true
    wait "$server_pid" || server_status=$?
    server_stopped=1
  fi
  exec 3<&- 3>&- || true
}
cleanup() { if [[ -n "$server_pid" ]] && (( server_stopped == 0 )); then stop_server; fi; }
trap cleanup EXIT INT TERM

wait_for_phase() {
  local expected="$1" log="$2" found=0
  for _ in {1..1500}; do
    if [[ -s "$checkpoint" ]] && python3 - "$report" "$expected" <<'EOF_STATUS'
import json
import sys
from pathlib import Path
try:
    rows = [json.loads(line) for line in Path(sys.argv[1]).read_text().splitlines() if line.strip()]
except (OSError, json.JSONDecodeError):
    raise SystemExit(1)
raise SystemExit(0 if any(row.get("status") == sys.argv[2] for row in rows) else 1)
EOF_STATUS
    then found=1; break; fi
    if ! kill -0 "$server_pid" 2>/dev/null; then wait "$server_pid" || server_status=$?; server_stopped=1; break; fi
    sleep 0.2
  done
  if (( found == 0 )); then
    if (( server_stopped == 0 )); then stop_server; fi
    tail -120 "$log" >&2
    printf 'Cooling fixture did not reach %s; artifacts: %s\n' "$expected" "$tmp" >&2
    return 1
  fi
  stop_server
  bitermotors_check_log "$log" --expect-marker Goodbye
  if [[ "$server_status" != 0 && "$server_status" != 130 ]]; then
    printf 'Cooling server failed with status %s\n' "$server_status" >&2; return 1
  fi
  test -s "$checkpoint"
  python3 "$repo_root/scripts/validation_support.py" report "$report" --require-status "$expected" --minimum-tick 1
}

start_server "$save" "$tmp/first-server.log"
wait_for_phase cooling_checkpoint "$tmp/first-server.log"
start_server "$checkpoint" "$tmp/reload-server.log"
for _ in {1..1500}; do
  if python3 - "$report" <<'EOF_DONE'
import json
import sys
from pathlib import Path
try:
    rows = [json.loads(line) for line in Path(sys.argv[1]).read_text().splitlines() if line.strip()]
except (OSError, json.JSONDecodeError):
    raise SystemExit(1)
raise SystemExit(0 if any(row.get("status") == "cooling_reload_passed" for row in rows) else 1)
EOF_DONE
  then break; fi
  if ! kill -0 "$server_pid" 2>/dev/null; then break; fi
  sleep 0.2
done
if (( server_stopped == 0 )); then stop_server; fi
bitermotors_check_log "$tmp/reload-server.log" --expect-marker Goodbye
if [[ "$server_status" != 0 && "$server_status" != 130 ]]; then
  printf 'Cooling reload server failed with status %s\n' "$server_status" >&2; exit 1
fi
test -s "$checkpoint"
python3 "$repo_root/scripts/validation_support.py" report "$report" --require-status cooling_reload_passed --minimum-tick 1

validate_report "$report" "$save" "$checkpoint"
