#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/scripts/lib/bitermotors-validation.sh"
bitermotors_resolve_source "$repo_root"
factorio_bin="${FACTORIO_BINARY:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-$(dirname "$factorio_bin")/../data}"
tmp="$(mktemp -d /tmp/bitermotors-ai.XXXXXX)"
mods="$tmp/mods"
helper="$mods/bitermotors_ai_validation_0.1.1"
save="$tmp/saves/bitermotors-ai.zip"
report="$tmp/script-output/bitermotors-ai.jsonl"
mkdir -p "$helper" "$tmp/saves" "$tmp/script-output"
bitermotors_stage_mod "$mods"

cat > "$tmp/config.ini" <<EOF_CONFIG
[path]
read-data=$read_data
write-data=$tmp
EOF_CONFIG
cat > "$mods/mod-list.json" <<'EOF_MODS'
{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":true},
{"name":"bitermotors","enabled":true},{"name":"bitermotors_ai_validation","enabled":true}]}
EOF_MODS
cat > "$helper/info.json" <<'EOF_INFO'
{"name":"bitermotors_ai_validation","version":"0.1.1","title":"Biter Motors AI Validation Fixture","author":"Codex",
"factorio_version":"2.1","dependencies":["base >= 2.1.20","space-age >= 2.1.20","bitermotors >= 0.1.1"]}
EOF_INFO
cp "$repo_root/scripts/fixtures/ai-control.lua" "$helper/control.lua"
python3 - "$read_data/server-settings.example.json" "$tmp/server-settings.json" <<'EOF_SERVER'
import json
import sys
from pathlib import Path

settings = json.loads(Path(sys.argv[1]).read_text())
settings.update(name="Isolated Biter Motors AI fixture",
                visibility={"public": False, "lan": False},
                require_user_verification=False, auto_pause=False, autosave_interval=0)
Path(sys.argv[2]).write_text(json.dumps(settings))
EOF_SERVER
printf 'Isolated AI artifacts: %s\n' "$tmp"
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
reload="$tmp/saves/bitermotors-ai-reload.zip"
"$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" \
  --start-server "$save" --server-settings "$tmp/server-settings.json" \
  --bind 127.0.0.1 --port "$port" <&3 > "$tmp/server.log" 2>&1 &
pid=$!
trap 'kill -INT "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true' EXIT
for _ in {1..900}; do
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
  echo "AI fixture server failed with status $server_status" >&2
  exit 1
fi
python3 "$repo_root/scripts/validation_support.py" report "$report" \
  --require-status ai_accounting_passed --minimum-tick 1
test -s "$reload"
run_engine "$tmp/reload.log" --benchmark "$reload" --benchmark-ticks 121 --benchmark-runs 1
bitermotors_check_log "$tmp/reload.log" --expect-updates 121 --expect-marker Goodbye
python3 "$repo_root/scripts/validation_support.py" report "$report" \
  --require-status ai_reload_passed --minimum-tick 1
python3 - "$report" <<'EOF_CHECK'
import json
import sys
from pathlib import Path

rows = [json.loads(line) for line in Path(sys.argv[1]).read_text().splitlines()]
assert [row["status"] for row in rows] == [
    "ai_policy_passed", "ai_accounting_passed", "ai_reload_passed"
], rows
assert all(row["assertions"] > 0 for row in rows), rows
assert rows[1]["tick"] > 0, rows
assert rows[0]["assertions"] >= 43 and rows[1]["assertions"] >= 26 and rows[2]["assertions"] >= 9, rows
assert rows[1]["generated"] == 1_155_126 and rows[1]["native_generated"] == 1_155_120, rows
assert rows[1]["other_force_generated"] == 100_000 and rows[1]["pending_bonus"] == 2, rows
assert rows[1]["native_milestone_unlocked"] is True and rows[1]["platforms"] == 2, rows
assert rows[1]["datasets_extracted_by_inserter"] == 18 and rows[1]["packaging_datasets"] == 1, rows
assert rows[2]["tick"] > rows[2]["saved_tick"], rows
assert rows[2]["generated"] == rows[1]["generated"] + 24, rows
print("AI fixture passed:", json.dumps(rows, sort_keys=True))
EOF_CHECK
