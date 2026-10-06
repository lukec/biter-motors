#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$repo_root/scripts/fixtures/recycling-control.lua"
checker="$repo_root/scripts/check-recycling-prototypes.py"
if [[ ! -f "$fixture" ]]; then
  printf 'Recycling fixture is not ready: %s\n' "$fixture" >&2
  exit 2
fi
if [[ ! -f "$checker" ]]; then
  printf 'Recycling prototype checker is not ready: %s\n' "$checker" >&2
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

tmp="$(mktemp -d /tmp/bitermotors-recycling.XXXXXX)"
mods="$tmp/mods"
helper="$mods/bitermotors_recycling_0.1.1"
save="$tmp/saves/recycling.zip"
checkpoint="$tmp/saves/bitermotors-recycling-reload.zip"
report="$tmp/script-output/bitermotors-recycling.jsonl"
mkdir -p "$helper" "$tmp/saves" "$tmp/script-output"
printf 'Isolated recycling artifacts: %s\n' "$tmp"
bitermotors_stage_mod "$mods"

cat > "$tmp/config.ini" <<EOF_CONFIG
[path]
read-data=$read_data
write-data=$tmp
EOF_CONFIG
cat > "$mods/mod-list.json" <<'EOF_MODS'
{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":true},
{"name":"bitermotors","enabled":true},{"name":"bitermotors_recycling","enabled":true}]}
EOF_MODS
cat > "$helper/info.json" <<'EOF_INFO'
{"name":"bitermotors_recycling","version":"0.1.1","title":"Biter Motors Recycling Fixture","author":"Codex",
"factorio_version":"2.1","dependencies":["base >= 2.1.20","space-age >= 2.1.20","bitermotors >= 0.1.1"]}
EOF_INFO
cp "$fixture" "$helper/control.lua"
python3 - "$read_data/server-settings.example.json" "$tmp/server-settings.json" <<'EOF_SERVER'
import json
import sys
from pathlib import Path

settings = json.loads(Path(sys.argv[1]).read_text())
settings.update(name="Isolated Biter Motors recycling fixture",
                visibility={"public": False, "lan": False},
                require_user_verification=False, auto_pause=False, autosave_interval=0)
Path(sys.argv[2]).write_text(json.dumps(settings))
EOF_SERVER

run_engine() {
  local log="$1"
  shift
  if ! "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" "$@" > "$log" 2>&1; then
    tail -100 "$log" >&2
    return 1
  fi
}
run_engine "$tmp/dump-data.log" --dump-data
bitermotors_check_log "$tmp/dump-data.log" --expect-marker Goodbye
python3 "$checker" "$tmp/script-output/data-raw-dump.json"

run_engine "$tmp/create.log" --create "$save" --map-gen-seed 1062028
bitermotors_check_log "$tmp/create.log" --expect-marker Goodbye

port="$(python3 - <<'EOF_PORT'
import socket
with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
EOF_PORT
)"
mkfifo "$tmp/server.stdin"
exec 3<> "$tmp/server.stdin"
"$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" \
  --start-server "$save" --server-settings "$tmp/server-settings.json" \
  --bind 127.0.0.1 --port "$port" <&3 > "$tmp/server.log" 2>&1 &
server_pid=$!
server_status=0
server_stopped=0
stop_server() {
  if (( server_stopped == 0 )); then
    kill -INT "$server_pid" 2>/dev/null || true
    wait "$server_pid" || server_status=$?
    server_stopped=1
  fi
}
cleanup() {
  stop_server
  exec 3<&- 3>&- 2>/dev/null || true
}
trap cleanup EXIT INT TERM

deadline=$((SECONDS + 60))
checkpoint_and_sentinel=0
while (( SECONDS < deadline )); do
  if [[ -s "$checkpoint" ]] && python3 - "$report" <<'EOF_STATUS'
import json
import sys
from pathlib import Path

try:
    rows = [json.loads(line) for line in Path(sys.argv[1]).read_text().splitlines() if line.strip()]
except (OSError, json.JSONDecodeError):
    raise SystemExit(1)
raise SystemExit(0 if any(row.get("status") == "recycling_passed" for row in rows) else 1)
EOF_STATUS
  then
    checkpoint_and_sentinel=1
    break
  fi
  if ! kill -0 "$server_pid" 2>/dev/null; then
    wait "$server_pid" || server_status=$?
    server_stopped=1
    break
  fi
  sleep 0.2
done
if (( checkpoint_and_sentinel == 0 )); then
  if (( server_stopped == 0 )); then stop_server; fi
  tail -120 "$tmp/server.log" >&2
  printf 'Timed out waiting for recycling_passed and the server-written checkpoint in %s\n' "$tmp" >&2
  exit 1
fi
stop_server
exec 3<&- 3>&-
bitermotors_check_log "$tmp/server.log" --expect-marker Goodbye
if [[ "$server_status" != 0 && "$server_status" != 130 ]]; then
  printf 'Recycling server failed with status %s\n' "$server_status" >&2
  exit 1
fi
test -s "$save" || { printf 'Seeded save is missing: %s\n' "$save" >&2; exit 1; }
test -s "$checkpoint" || { printf 'Server did not create checkpoint: %s\n' "$checkpoint" >&2; exit 1; }
python3 "$repo_root/scripts/validation_support.py" report "$report" \
  --require-status recycling_passed --minimum-tick 1

run_engine "$tmp/reload.log" --benchmark "$checkpoint" --benchmark-ticks 61 --benchmark-runs 1
bitermotors_check_log "$tmp/reload.log" --expect-updates 61 --expect-marker Goodbye
python3 "$repo_root/scripts/validation_support.py" report "$report" \
  --require-status reload_passed --minimum-tick 1

python3 - "$report" "$save" "$checkpoint" <<'EOF_CHECK'
import json
import sys
from pathlib import Path

report, save, checkpoint = map(Path, sys.argv[1:])
assert save.is_file() and save.stat().st_size > 0, f"seeded save missing: {save}"
assert checkpoint.is_file() and checkpoint.stat().st_size > 0, f"checkpoint missing: {checkpoint}"
rows = [json.loads(line) for line in report.read_text().splitlines() if line.strip()]
expected = ["policy_passed", "recycling_passed", "reload_passed"]
assert [row.get("status") for row in rows] == expected, f"expected ordered statuses {expected}, got {rows}"
for row, minimum in zip(rows, (52, 400, 26)):
    assert type(row.get("assertions")) is int and row["assertions"] >= minimum, row
policy, native, reload = rows
assert policy.get("rewritten") == 18 and policy.get("battery_routes") == 2, policy
for key, count in {"normal_rewrites": 18, "rare_rewrites": 1, "recovery_cases": 4,
                   "salvage_cases": 11, "checkpoint_partial_packs": 9}.items():
    assert native.get(key) == count, (key, native)
assert reload.get("checkpoint_partial_packs") == 9, reload
reload = rows[-1]
assert type(reload.get("tick")) is int and type(reload.get("saved_tick")) is int, reload
assert reload["tick"] > reload["saved_tick"], reload
print("Recycling fixture passed:", json.dumps(rows, sort_keys=True))
EOF_CHECK
