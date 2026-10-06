#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$repo_root/scripts/fixtures/customer-control.lua"
if [[ ! -f "$fixture" ]]; then
  printf 'Customer fixture is not ready: %s\n' "$fixture" >&2
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

tmp="$(mktemp -d /tmp/bitermotors-customers.XXXXXX)"
mods="$tmp/mods"
helper="$mods/bitermotors_customers_0.1.1"
save="$tmp/saves/customers.zip"
checkpoint="$tmp/saves/bitermotors-customers-reload.zip"
report="$tmp/script-output/bitermotors-customers.jsonl"
mkdir -p "$helper" "$tmp/saves" "$tmp/script-output"
printf 'Isolated customer artifacts: %s\n' "$tmp"
bitermotors_stage_mod "$mods"

cat > "$tmp/config.ini" <<EOF_CONFIG
[path]
read-data=$read_data
write-data=$tmp
EOF_CONFIG
cat > "$mods/mod-list.json" <<'EOF_MODS'
{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":true},
{"name":"bitermotors","enabled":true},{"name":"bitermotors_customers","enabled":true}]}
EOF_MODS
write_helper_info() {
  local version="$1"
  cat > "$helper/info.json" <<EOF_INFO
{"name":"bitermotors_customers","version":"$version","title":"Biter Motors Customer Fixture","author":"Codex",
"factorio_version":"2.1","dependencies":["base >= 2.1.20","space-age >= 2.1.20","bitermotors >= 0.1.1"]}
EOF_INFO
}
write_helper_info 0.1.1
cat > "$helper/data-final-fixes.lua" <<'EOF_DATA'
-- Fixture-only: prevent uncontrolled vanilla spawns from changing population counts.
data.raw["unit-spawner"]["biter-spawner"].spawning_cooldown = {3600000, 3600000}
data.raw["unit-spawner"]["spitter-spawner"].spawning_cooldown = {3600000, 3600000}

for _, name in ipairs({
  "bitermotors-sell-prototype-roadster",
  "bitermotors-sell-premium-ev",
  "bitermotors-sell-mass-market-ev",
  "bitermotors-sell-megatruck"
}) do
  local recipe = data.raw.recipe[name]
  if recipe then recipe.energy_required = 0.5 end
end
EOF_DATA
cp "$fixture" "$helper/control.lua"
python3 - "$read_data/server-settings.example.json" "$tmp/server-settings.json" <<'EOF_SERVER'
import json
import sys
from pathlib import Path

settings = json.loads(Path(sys.argv[1]).read_text())
settings.update(name="Isolated Biter Motors customer fixture",
                visibility={"public": False, "lan": False},
                require_user_verification=False, auto_pause=False, autosave_interval=0)
Path(sys.argv[2]).write_text(json.dumps(settings))
EOF_SERVER

run_engine() {
  local log="$1"
  shift
  if ! "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" "$@" > "$log" 2>&1; then
    tail -80 "$log" >&2
    return 1
  fi
}
run_engine "$tmp/create.log" --create "$save" --map-gen-seed 1062027
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
trap 'stop_server; exec 3<&- 3>&-' EXIT INT TERM

deadline=$((SECONDS + 60))
checkpoint_and_sentinel=0
while (( SECONDS < deadline )); do
  if [[ -s "$checkpoint" ]] && python3 - "$report" <<'EOF_STATUS'
import json
import sys
from pathlib import Path
path = Path(sys.argv[1])
try:
    rows = [json.loads(line) for line in path.read_text().splitlines() if line.strip()]
except (OSError, json.JSONDecodeError):
    raise SystemExit(1)
raise SystemExit(0 if any(row.get("status") == "customers_passed" for row in rows) else 1)
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
  tail -100 "$tmp/server.log" >&2
  printf 'Timed out waiting for customers_passed and the server-written checkpoint in %s\n' "$tmp" >&2
  exit 1
fi
stop_server
exec 3<&- 3>&-
bitermotors_check_log "$tmp/server.log" --expect-marker Goodbye
if [[ "$server_status" != 0 && "$server_status" != 130 ]]; then
  printf 'Customer server failed with status %s\n' "$server_status" >&2
  exit 1
fi
test -s "$checkpoint" || { printf 'Server did not create checkpoint: %s\n' "$checkpoint" >&2; exit 1; }
python3 "$repo_root/scripts/validation_support.py" report "$report" \
  --require-status customers_passed --minimum-tick 1

run_engine "$tmp/reload.log" --benchmark "$checkpoint" --benchmark-ticks 61 --benchmark-runs 1
bitermotors_check_log "$tmp/reload.log" --expect-updates 61 --expect-marker Goodbye
python3 "$repo_root/scripts/validation_support.py" report "$report" \
  --require-status reload_passed --minimum-tick 1

write_helper_info 0.1.2
mv "$helper" "$mods/bitermotors_customers_0.1.2"
helper="$mods/bitermotors_customers_0.1.2"
run_engine "$tmp/configuration.log" --benchmark "$checkpoint" --benchmark-ticks 61 --benchmark-runs 1
bitermotors_check_log "$tmp/configuration.log" --expect-updates 61 --expect-marker Goodbye
python3 "$repo_root/scripts/validation_support.py" report "$report" \
  --require-status configuration_passed --minimum-tick 1
python3 - "$report" <<'EOF_CHECK'
import json
import sys
from pathlib import Path

rows = [json.loads(line) for line in Path(sys.argv[1]).read_text().splitlines() if line.strip()]
expected = ["lua_fixtures_passed", "customers_passed", "reload_passed", "configuration_passed"]
statuses = [row.get("status") for row in rows]
assert statuses == expected, f"expected ordered statuses {expected}, got {statuses}"
for row, minimum in zip(rows, (63, 134, 9, 12)):
    assert type(row.get("assertions")) is int and row["assertions"] >= minimum, row
for row in rows[2:]:
    assert type(row.get("tick")) is int, row
    assert type(row.get("saved_tick")) is int, row
    assert row["tick"] > row["saved_tick"], row
print("Customer lifecycle fixture passed:", json.dumps(rows, sort_keys=True))
EOF_CHECK
