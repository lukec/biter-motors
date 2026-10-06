#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$repo_root/scripts/fixtures/finale-control.lua"
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

tmp="$(mktemp -d /tmp/bitermotors-finale.XXXXXX)"
mods="$tmp/mods"
helper="$mods/bitermotors_finale_validation_0.1.1"
save="$tmp/saves/bitermotors-finale-seed.zip"
midrun="$tmp/saves/bitermotors-finale-midrun.zip"
completed="$tmp/saves/bitermotors-finale-completed.zip"
report="$tmp/script-output/bitermotors-finale.jsonl"
mkdir -p "$helper" "$tmp/saves" "$tmp/script-output"
printf 'Isolated finale artifacts: %s\n' "$tmp"
bitermotors_stage_mod "$mods"

cat > "$tmp/config.ini" <<EOF_CONFIG
[path]
read-data=$read_data
write-data=$tmp
EOF_CONFIG
cat > "$mods/mod-list.json" <<'EOF_MODS'
{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":true},
{"name":"bitermotors","enabled":true},{"name":"bitermotors_finale_validation","enabled":true}]}
EOF_MODS
cat > "$helper/info.json" <<'EOF_INFO'
{"name":"bitermotors_finale_validation","version":"0.1.1","title":"Biter Motors Finale Validation","author":"Codex",
"factorio_version":"2.1","dependencies":["base >= 2.1.20","space-age >= 2.1.20","bitermotors >= 0.1.1"]}
EOF_INFO
cp "$fixture" "$helper/control.lua"
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

start_server "$save" "$tmp/midrun-server.log"
wait_for_phase "$midrun" finale_checkpoint "$tmp/midrun-server.log"
start_server "$midrun" "$tmp/completed-server.log"
wait_for_phase "$completed" finale_training_passed "$tmp/completed-server.log"

run_engine "$tmp/reload.log" --benchmark "$completed" --benchmark-ticks 61 --benchmark-runs 1
bitermotors_check_log "$tmp/reload.log" --expect-updates 61 --expect-marker Goodbye
python3 "$repo_root/scripts/validation_support.py" report "$report" \
  --require-status finale_reload_passed --minimum-tick 1

python3 - "$report" "$save" "$midrun" "$completed" <<'EOF_CHECK'
import json
import sys
from pathlib import Path

report, *saves = map(Path, sys.argv[1:])
assert all(path.is_file() and path.stat().st_size > 0 for path in saves), saves
rows = [json.loads(line) for line in report.read_text().splitlines() if line.strip()]
statuses = ["finale_policy_passed", "finale_checkpoint", "finale_training_passed", "finale_reload_passed"]
assert [row.get("status") for row in rows] == statuses, rows
assert all(type(row.get("assertions")) is int and row["assertions"] > 0 for row in rows), rows
policy, checkpoint, training, reload = rows
assert all(type(row.get("tick")) is int and row["tick"] > 0 for row in rows), rows
assert type(checkpoint.get("progress")) in (int, float) and 0 < checkpoint["progress"] < 1, checkpoint
assert training.get("training_seconds") == 1200, training
assert training.get("required_power_watts") == 10_000_000_000, training
cases = training.get("completion_cases")
assert isinstance(cases, list) and len(cases) >= 8, training
assert all(isinstance(case, dict) and 71999 <= case.get("duration_ticks", 0) <= 72001 for case in cases), cases
assert all(abs(case.get("total_joules", 0) - 12_000_000_000_000) <= 10_000_000_000 / 60 * 2 for case in cases), cases
assert type(reload.get("saved_tick")) is int and reload["tick"] > reload["saved_tick"], reload
victory = training.get("victory")
assert isinstance(victory, dict) and victory, training
assert reload.get("victory") == victory, reload
assert sum(row.get("status") == "finale_training_passed" for row in rows) == 1, rows
print("Finale fixture passed:", json.dumps(rows, sort_keys=True))
EOF_CHECK
