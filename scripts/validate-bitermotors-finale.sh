#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kind="${BITERMOTORS_ENDING_CASE:-finale}"
[[ "$kind" == delivery || "$kind" == finale ]] || { printf 'Unknown ending case: %s\n' "$kind" >&2; exit 2; }
fixture="$repo_root/scripts/fixtures/$kind-control.lua"
if [[ ! -f "$fixture" ]]; then
  printf 'Finale fixture is not ready: %s\n' "$fixture" >&2
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

tmp="$(mktemp -d "/tmp/bitermotors-$kind.XXXXXX")"
mods="$tmp/mods"
helper="$mods/bitermotors_${kind}_validation_0.1.1"
save="$tmp/saves/bitermotors-$kind-seed.zip"
report="$tmp/script-output/bitermotors-$kind.jsonl"
mkdir -p "$helper" "$tmp/saves" "$tmp/script-output"
printf 'Isolated %s artifacts: %s\n' "$kind" "$tmp"
bitermotors_stage_mod "$mods"

cat > "$tmp/config.ini" <<EOF_CONFIG
[path]
read-data=$read_data
write-data=$tmp
EOF_CONFIG
cat > "$mods/mod-list.json" <<EOF_MODS
{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":true},
{"name":"bitermotors","enabled":true},{"name":"bitermotors_${kind}_validation","enabled":true}]}
EOF_MODS
cat > "$helper/info.json" <<EOF_INFO
{"name":"bitermotors_${kind}_validation","version":"0.1.1","title":"Biter Motors Native Ending Validation","author":"Codex",
"factorio_version":"2.1","dependencies":["base >= 2.1.20","space-age >= 2.1.20","bitermotors >= 0.1.1"]}
EOF_INFO
cp "$fixture" "$helper/control.lua"
if [[ "$kind" == finale ]]; then
  cp "$repo_root/scripts/fixtures/delivery-control.lua" "$helper/native-ending.lua"
fi
python3 - "$read_data/server-settings.example.json" "$tmp/server-settings.json" <<'EOF_SERVER'
import json
import sys
from pathlib import Path

settings = json.loads(Path(sys.argv[1]).read_text())
settings.update(name="Isolated Biter Motors finale fixture",
                visibility={"public": False, "lan": False},
                require_user_verification=False, auto_pause=False, autosave_interval=0)
Path(sys.argv[2]).write_text(json.dumps(settings))
EOF_SERVER

run_engine() {
  local log="$1"
  shift
  local status=0
  "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" "$@" > "$log" 2>&1 || status=$?
  if ! bitermotors_check_log "$log" --expect-marker Goodbye; then
    tail -100 "$log" >&2
    return 1
  fi
  if (( status != 0 )); then
    tail -100 "$log" >&2
    return "$status"
  fi
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
start_server() {
  local source_save="$1"
  local log="$2"
  rm -f "$tmp/server.stdin"
  mkfifo "$tmp/server.stdin"
  exec 3<> "$tmp/server.stdin"
  "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" \
    --start-server "$source_save" --server-settings "$tmp/server-settings.json" \
    --bind 127.0.0.1 --port "$port" <&3 > "$log" 2>&1 &
  server_pid=$!
  server_status=0
  server_stopped=0
}
stop_server() {
  if (( server_stopped == 0 )); then
    kill -INT "$server_pid" 2>/dev/null || true
    wait "$server_pid" || server_status=$?
    server_stopped=1
  fi
  exec 3<&- 3>&-
}
cleanup() {
  if [[ -n "${server_pid:-}" ]] && (( server_stopped == 0 )); then stop_server; fi
}
trap cleanup EXIT INT TERM

wait_for_phase() {
  local checkpoint="$1"
  local status="$2"
  local log="$3"
  local found=0
  for _ in {1..1200}; do
    if [[ -s "$checkpoint" ]] && python3 - "$report" "$status" <<'EOF_STATUS'
import json
import sys
from pathlib import Path
try:
    rows = [json.loads(line) for line in Path(sys.argv[1]).read_text().splitlines() if line.strip()]
except (OSError, json.JSONDecodeError):
    raise SystemExit(1)
raise SystemExit(0 if any(row.get("status") == sys.argv[2] for row in rows) else 1)
EOF_STATUS
    then
      found=1
      break
    fi
    if ! kill -0 "$server_pid" 2>/dev/null; then
      wait "$server_pid" || server_status=$?
      server_stopped=1
      break
    fi
    sleep 0.2
  done
  if (( found == 0 )); then
    if (( server_stopped == 0 )); then stop_server; fi
    bitermotors_check_log "$log" --expect-marker Goodbye || true
    tail -120 "$log" >&2
    printf 'Required phase was not reached: %s and %s in %s\n' "$status" "$checkpoint" "$tmp" >&2
    return 1
  fi
  stop_server
  bitermotors_check_log "$log" --expect-marker Goodbye
  if [[ "$server_status" != 0 && "$server_status" != 130 ]]; then
    printf 'Finale server failed with status %s\n' "$server_status" >&2
    return 1
  fi
  test -s "$checkpoint" || { printf 'Server checkpoint is missing: %s\n' "$checkpoint" >&2; return 1; }
  python3 "$repo_root/scripts/validation_support.py" report "$report" \
    --require-status "$status" --minimum-tick 1
}

source_save="$save"
for phase in assembly flight return activation won; do
  checkpoint="$tmp/saves/bitermotors-$kind-$phase.zip"
  phase_log="$tmp/$phase-server.log"
  start_server "$source_save" "$phase_log"
  wait_for_phase "$checkpoint" "${phase}_checkpoint" "$phase_log"
  source_save="$checkpoint"
done

run_engine "$tmp/reload.log" --benchmark "$source_save" --benchmark-ticks 2461 --benchmark-runs 1
bitermotors_check_log "$tmp/reload.log" --expect-updates 2461 --expect-marker Goodbye
python3 "$repo_root/scripts/validation_support.py" report "$report" \
  --require-status won_reload_passed --minimum-tick 1

python3 - "$report" "$tmp/saves" "$kind" <<'EOF_CHECK'
import json
import sys
from pathlib import Path

report, save_dir = map(Path, sys.argv[1:3])
kind = sys.argv[3]
for phase in ("seed", "assembly", "flight", "return", "activation", "won"):
    path = save_dir / f"bitermotors-{kind}-{phase}.zip"
    assert path.is_file() and path.stat().st_size > 0, path
rows = [json.loads(line) for line in report.read_text().splitlines() if line.strip()]
statuses = ["payload_passed", "assembly_checkpoint", "assembly_reload_passed", "assembly_passed",
            "flight_checkpoint", "flight_reload_passed", "return_checkpoint", "return_reload_passed", "activation_checkpoint",
            "activation_reload_passed", "won_checkpoint", "won_reload_passed"]
assert [row.get("status") for row in rows] == statuses, rows
assert all(type(row.get("assertions")) is int and row["assertions"] > 0 for row in rows), rows
assert all(row.get("validation_scope") == "native-model-ending" and row.get("limits") for row in rows), rows
assert all(row.get("payload_quality") == ("rare" if kind == "finale" else "normal") for row in rows), rows
assert all(type(row.get("tick")) is int and row["tick"] > 0 for row in rows), rows
assert all(a["tick"] < b["tick"] for a, b in zip(rows, rows[1:])), rows
by_status = {row["status"]: row for row in rows}
payload = by_status["payload_passed"]
assert payload["datasets_loaded"] == 20_000 and payload["earned_equivalents"] == 1_000_000_000, payload
for phase in ("assembly", "activation"):
    checkpoint = by_status[f"{phase}_checkpoint"]
    assert type(checkpoint.get("progress")) in (int, float) and 0 < checkpoint["progress"] < 1, checkpoint
for phase in ("assembly", "flight", "return", "activation", "won"):
    checkpoint = by_status[f"{phase}_checkpoint"]
    reload = by_status[f"{phase}_reload_passed"]
    assert reload["saved_tick"] == checkpoint["tick"] and reload["tick"] > reload["saved_tick"], reload
assembly = by_status["assembly_passed"]
assert assembly["products_after_reload"] > by_status["assembly_checkpoint"]["products"], assembly
assert assembly["native_completion_tick"] > assembly["assembly_reload_tick"], assembly
flight = by_status["flight_checkpoint"]
assert flight["models_in_transit"] == 1 and flight["return_credits"] == 0, flight
assert flight["pod"] == by_status["flight_reload_passed"]["pod"], rows
assert by_status["return_checkpoint"]["models_returned"] == 1, rows
assert by_status["won_checkpoint"]["models_activated"] == 1, rows
reload = by_status["won_reload_passed"]
assert reload["native_activations"] == 1 and reload["freeplay_ticks"] >= 2400, reload
assert abs(reload["activation_measured_watts"] - 8_000_000) < 400_000, reload
assert isinstance(reload["victory"], dict) and reload["victory"], reload
assert reload["victory"] == by_status["won_checkpoint"]["victory"], rows
print("Native ending fixture passed:", json.dumps(rows, sort_keys=True))
EOF_CHECK
