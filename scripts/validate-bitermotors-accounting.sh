#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/scripts/lib/bitermotors-validation.sh"
bitermotors_resolve_source "$repo_root"
factorio_bin="${FACTORIO_BINARY:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-$(dirname "$factorio_bin")/../data}"
tmp="$(mktemp -d /tmp/bitermotors-accounting.XXXXXX)"
mods="$tmp/mods"
helper="$mods/bitermotors_accounting_0.1.1"
save="$tmp/saves/accounting.zip"
report="$tmp/script-output/bitermotors-accounting.jsonl"
mkdir -p "$helper" "$tmp/saves" "$tmp/script-output"
bitermotors_stage_mod "$mods"

cat > "$tmp/config.ini" <<EOF_CONFIG
[path]
read-data=$read_data
write-data=$tmp
EOF_CONFIG
cat > "$mods/mod-list.json" <<'EOF_MODS'
{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":true},
{"name":"bitermotors","enabled":true},{"name":"bitermotors_accounting","enabled":true}]}
EOF_MODS
cat > "$helper/info.json" <<'EOF_INFO'
{"name":"bitermotors_accounting","version":"0.1.1","title":"Biter Motors Accounting Fixture","author":"Codex",
"factorio_version":"2.1","dependencies":["base >= 2.1.20","space-age >= 2.1.20","bitermotors >= 0.1.1"]}
EOF_INFO
# Test-only recipes accelerate native manufacture/sales, not campaign balance.
cat > "$helper/data-final-fixes.lua" <<'EOF_DATA'
data:extend({{
  type = "recipe", name = "bitermotors-accounting-premium", enabled = true,
  energy_required = 0.25, allow_productivity = false,
  ingredients = {{type = "item", name = "copper-plate", amount = 1}},
  results = {{type = "item", name = "bitermotors-premium-ev", amount = 1}}
}})
data.raw.recipe["bitermotors-sell-prototype-roadster"].energy_required = 0.5
EOF_DATA
cp "$repo_root/scripts/fixtures/accounting-control.lua" "$helper/control.lua"
python3 - "$read_data/server-settings.example.json" "$tmp/server-settings.json" <<'EOF_SERVER'
import json
import sys
from pathlib import Path

settings = json.loads(Path(sys.argv[1]).read_text())
settings.update(name="Isolated Biter Motors accounting fixture",
                visibility={"public": False, "lan": False},
                require_user_verification=False, auto_pause=False, autosave_interval=0)
Path(sys.argv[2]).write_text(json.dumps(settings))
EOF_SERVER
printf 'Isolated accounting artifacts: %s\n' "$tmp"
run_engine() {
  local log="$1"
  shift
  if ! "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" "$@" > "$log" 2>&1; then
    tail -80 "$log" >&2
    return 1
  fi
}
run_engine "$tmp/create.log" --create "$save" --map-gen-seed 1062026
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
reload="$tmp/saves/bitermotors-accounting-reload.zip"
"$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" \
  --start-server "$save" --server-settings "$tmp/server-settings.json" \
  --bind 127.0.0.1 --port "$port" <&3 > "$tmp/server.log" 2>&1 &
pid=$!
trap 'kill -INT "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true' EXIT
for _ in {1..300}; do
  if [[ -s "$reload" ]] || ! kill -0 "$pid" 2>/dev/null; then break; fi
  sleep 0.2
done
kill -INT "$pid" 2>/dev/null || true
server_status=0
wait "$pid" || server_status=$?
trap - EXIT
exec 3<&- 3>&-
bitermotors_check_log "$tmp/server.log" --expect-marker Goodbye
if [[ "$server_status" != 0 && "$server_status" != 130 ]]; then
  echo "Accounting server failed with status $server_status" >&2
  exit 1
fi
python3 "$repo_root/scripts/validation_support.py" report "$report" \
  --require-status accounting_passed --minimum-tick 1
test -s "$reload"
run_engine "$tmp/reload.log" --benchmark "$reload" --benchmark-ticks 61 --benchmark-runs 1
bitermotors_check_log "$tmp/reload.log" --expect-updates 61 --expect-marker Goodbye
python3 "$repo_root/scripts/validation_support.py" report "$report" \
  --require-status reload_passed --minimum-tick 1
python3 - "$report" <<'EOF_CHECK'
import json
import sys
from pathlib import Path

rows = [json.loads(line) for line in Path(sys.argv[1]).read_text().splitlines()]
assert [row["status"] for row in rows] == [
    "lua_fixtures_passed", "accounting_passed", "reload_passed"
], rows
assert rows[0]["assertions"] >= 39, rows
assert rows[1]["assertions"] >= 26, rows
assert rows[1]["manufactured"] == 259 and rows[1]["sold"] == 50 and rows[1]["profit"] == 100, rows
assert rows[1]["dollar_production"] == 113 and rows[1]["other_dollar_inflow"] == 13, rows
assert rows[-1]["assertions"] >= 3, rows
assert rows[-1]["tick"] > rows[-1]["saved_tick"], rows
print("Accounting fixture passed:", json.dumps(rows, sort_keys=True))
EOF_CHECK
