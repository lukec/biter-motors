#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/scripts/lib/bitermotors-validation.sh"
bitermotors_resolve_source "$repo_root"
factorio_bin="${FACTORIO_BINARY:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-$(dirname "$factorio_bin")/../data}"
[[ -x "$factorio_bin" ]] || { printf 'Factorio executable unavailable: %s\n' "$factorio_bin" >&2; exit 2; }
tmp="$(mktemp -d /tmp/bitermotors-delivery.XXXXXX)"
mods="$tmp/mods"
helper="$mods/bitermotors_delivery_validation_0.1.1"
save="$tmp/saves/bitermotors-delivery.zip"
reload="$tmp/saves/bitermotors-delivery-reload.zip"
report="$tmp/script-output/bitermotors-delivery.jsonl"
mkdir -p "$helper" "$tmp/saves" "$tmp/script-output"
printf 'Isolated delivery artifacts: %s\n' "$tmp"
bitermotors_stage_mod "$mods"
cat > "$tmp/config.ini" <<EOF_CONFIG
[path]
read-data=$read_data
write-data=$tmp
EOF_CONFIG
cat > "$mods/mod-list.json" <<'EOF_MODS'
{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":true},
{"name":"bitermotors","enabled":true},{"name":"bitermotors_delivery_validation","enabled":true}]}
EOF_MODS
cat > "$helper/info.json" <<'EOF_INFO'
{"name":"bitermotors_delivery_validation","version":"0.1.1","title":"Biter Motors Delivery Validation","author":"Codex",
"factorio_version":"2.1","dependencies":["base >= 2.1.20","space-age >= 2.1.20","bitermotors >= 0.1.1"]}
EOF_INFO
cp "$repo_root/scripts/fixtures/delivery-control.lua" "$helper/control.lua"
python3 - "$read_data/server-settings.example.json" "$tmp/server-settings.json" <<'EOF_SERVER'
import json
import sys
from pathlib import Path
settings = json.loads(Path(sys.argv[1]).read_text())
settings.update(name="Isolated Biter Motors delivery fixture",
                visibility={"public": False, "lan": False},
                require_user_verification=False, auto_pause=False, autosave_interval=0)
Path(sys.argv[2]).write_text(json.dumps(settings))
EOF_SERVER

run_engine() {
  local log="$1" status=0
  shift
  "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" "$@" > "$log" 2>&1 || status=$?
  if ! bitermotors_check_log "$log" --expect-marker Goodbye; then tail -100 "$log" >&2; return 1; fi
  if (( status != 0 )); then tail -100 "$log" >&2; return "$status"; fi
}
run_engine "$tmp/create.log" --create "$save" --map-gen-seed 1062026
test -s "$save"
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
pid=$!
trap 'kill -INT "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true' EXIT
for _ in {1..1500}; do
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
  printf 'Delivery fixture server failed: %s\n' "$server_status" >&2
  exit 1
fi
python3 "$repo_root/scripts/validation_support.py" report "$report" \
  --require-status delivery_training_passed --minimum-tick 1
test -s "$reload"
run_engine "$tmp/reload.log" --benchmark "$reload" --benchmark-ticks 61 --benchmark-runs 1
bitermotors_check_log "$tmp/reload.log" --expect-updates 61 --expect-marker Goodbye
python3 "$repo_root/scripts/validation_support.py" report "$report" \
  --require-status delivery_reload_passed --minimum-tick 1
python3 - "$report" <<'EOF_CHECK'
import json
import sys
from pathlib import Path
rows = [json.loads(line) for line in Path(sys.argv[1]).read_text().splitlines() if line.strip()]
assert [row.get("status") for row in rows] == [
    "delivery_setup_passed", "delivery_compute_passed", "delivery_payload_passed",
    "delivery_training_passed", "delivery_reload_passed"
], rows
assert all(type(row.get("assertions")) is int and row["assertions"] > 0 for row in rows), rows
setup, compute, payload, training, reload = rows
assert setup["tick"] < compute["tick"] < payload["tick"] < training["tick"] < reload["tick"], rows
assert compute["datasets"] == 20_032 and compute["tokens"] == 10_000, compute
assert compute["earned_equivalents"] == training["earned_equivalents"] == 1_001_610_000, rows
assert payload["delivered"] >= 20_000 and training["delivered"] >= 20_000, rows
assert training["launched_pods"] >= 20 and training["researched_tick"] > compute["tick"], rows
assert 71_999 <= training["training_ticks"] <= 72_001, training
assert reload["tick"] > reload["saved_tick"], reload
assert reload["victory"] == training["victory"], rows
print("Delivery fixture passed:", json.dumps(rows, sort_keys=True))
EOF_CHECK
