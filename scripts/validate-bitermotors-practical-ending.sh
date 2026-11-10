#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
checker="$repo_root/scripts/check_practical_ending.py"
if [[ "${1:-}" == --check-report ]]; then
  [[ $# == 2 ]] || exit 2
  exec python3 "$checker" "$2"
fi
config=""
probe=""
while (( $# )); do
  case "$1" in
    --config) config="$2"; shift 2 ;;
    --probe-ticks) probe="$2"; shift 2 ;;
    *) printf 'Usage: %s [--config JSON] [--probe-ticks N] | --check-report JSONL\n' "$0" >&2; exit 2 ;;
  esac
done
[[ -z "$probe" || "$probe" =~ ^[1-9][0-9]{0,7}$ ]] || { printf 'Invalid probe ticks\n' >&2; exit 2; }
source "$repo_root/scripts/lib/bitermotors-validation.sh"
bitermotors_resolve_source "$repo_root"
factorio_bin="${FACTORIO_BINARY:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-$(dirname "$factorio_bin")/../data}"
[[ -x "$factorio_bin" ]] || { printf 'Factorio executable unavailable: %s\n' "$factorio_bin" >&2; exit 2; }
tmp="$(mktemp -d /tmp/bitermotors-practical.XXXXXX)"
mods="$tmp/mods"
helper="$mods/bitermotors_practical_validation_0.1.1"
report="$tmp/script-output/bitermotors-practical-ending.jsonl"
seed="$tmp/saves/seed.zip"
mkdir -p "$helper" "$tmp/saves" "$tmp/script-output"
printf 'Isolated practical-ending artifacts (retained): %s\n' "$tmp"
bitermotors_stage_mod "$mods"
prepare=(python3 "$checker" --prepare "$helper" --source "$bitermotors_mod_source")
if [[ -n "$config" ]]; then prepare+=(--config "$config"); fi
"${prepare[@]}"
expected_sha="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["source_sha256"])' "$helper/practical-config.json")"
cp "$repo_root/scripts/fixtures/practical-ending-control.lua" "$helper/control.lua"
cp "$repo_root/scripts/fixtures/orbital-layout.lua" "$helper/orbital-layout.lua"
cat > "$tmp/config.ini" <<EOF_CONFIG
[path]
read-data=$read_data
write-data=$tmp
EOF_CONFIG
cat > "$mods/mod-list.json" <<'EOF_MODS'
{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":true},
{"name":"bitermotors","enabled":true},{"name":"bitermotors_practical_validation","enabled":true}]}
EOF_MODS
cat > "$helper/info.json" <<'EOF_INFO'
{"name":"bitermotors_practical_validation","version":"0.1.1","title":"Biter Motors Practical Ending Harness","author":"Codex",
"factorio_version":"2.1","dependencies":["base >= 2.1.20","space-age >= 2.1.20","bitermotors >= 0.1.1"]}
EOF_INFO
python3 - "$read_data/server-settings.example.json" "$tmp/server-settings.json" <<'EOF_SETTINGS'
import json, sys
from pathlib import Path
settings = json.loads(Path(sys.argv[1]).read_text())
settings.update(name="Isolated practical ending", visibility={"public": False, "lan": False},
                require_user_verification=False, auto_pause=False, autosave_interval=0)
Path(sys.argv[2]).write_text(json.dumps(settings))
EOF_SETTINGS
run_engine() {
  local log="$1" status=0
  shift
  "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" "$@" > "$log" 2>&1 || status=$?
  if ! bitermotors_check_log "$log" --expect-marker Goodbye; then tail -100 "$log" >&2; return 1; fi
  if (( status != 0 )); then tail -100 "$log" >&2; return "$status"; fi
}
run_engine "$tmp/create.log" --create "$seed" --map-gen-seed 1092026
if [[ -n "$probe" ]]; then
  run_engine "$tmp/probe.log" --benchmark "$seed" --benchmark-ticks "$probe" --benchmark-runs 1
  bitermotors_check_log "$tmp/probe.log" --expect-updates "$probe" --expect-marker Goodbye
  # A probe is diagnostic only. It never prints a full-route success claim.
  python3 - "$tmp/script-output/bitermotors-practical-progress.jsonl" "$probe" <<'EOF_PROBE'
import json, sys
from pathlib import Path
rows = [json.loads(line) for line in Path(sys.argv[1]).read_text().splitlines()]
assert rows and rows[-1]["tick"] >= (int(sys.argv[2]) // 3600) * 3600 > 0, "probe time did not advance"
assert rows[-1]["paused"] is False and rows[-1]["game_finished"] is False, "paused/finished probe"
EOF_PROBE
  printf 'Probe only; full route and reloads NOT QUALIFIED. Progress: %s\n' "$tmp/script-output/bitermotors-practical-progress.jsonl"
  exit
fi
port="$(python3 - <<'EOF_PORT'
import socket
with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
EOF_PORT
)"
server_pid=""
cleanup() {
  if [[ -n "$server_pid" ]]; then kill -INT "$server_pid" 2>/dev/null || true; wait "$server_pid" 2>/dev/null || true; fi
}
trap cleanup EXIT INT TERM
source_save="$seed"
for phase in loading victory; do
  checkpoint="$tmp/saves/bitermotors-practical-$phase.zip"
  log="$tmp/$phase-server.log"
  mkfifo "$tmp/$phase.stdin"
  exec 3<> "$tmp/$phase.stdin"
  "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" --start-server "$source_save" \
    --server-settings "$tmp/server-settings.json" --bind 127.0.0.1 --port "$port" <&3 > "$log" 2>&1 &
  server_pid=$!
  deadline=$((SECONDS + ${BITERMOTORS_PRACTICAL_TIMEOUT_SECONDS:-1800}))
  while [[ ! -s "$checkpoint" ]] && (( SECONDS < deadline )); do
    kill -0 "$server_pid" 2>/dev/null || break
    if [[ -s "$log" ]] && ! bitermotors_check_log "$log"; then break; fi
    sleep 0.5
  done
  kill -INT "$server_pid" 2>/dev/null || true
  status=0
  wait "$server_pid" || status=$?
  server_pid=""
  exec 3<&- 3>&-
  if ! bitermotors_check_log "$log" --expect-marker Goodbye; then tail -100 "$log" >&2; exit 1; fi
  [[ "$status" == 0 || "$status" == 130 ]] || { tail -100 "$log" >&2; exit 1; }
  [[ -s "$checkpoint" ]] || { tail -50 "$log" >&2; printf 'Checkpoint not reached: %s\n' "$phase" >&2; exit 1; }
  python3 "$repo_root/scripts/validation_support.py" report "$report" --require-status "${phase}_checkpoint" --minimum-tick 1
  source_save="$checkpoint"
done
run_engine "$tmp/reload.log" --benchmark "$source_save" --benchmark-ticks 2491 --benchmark-runs 1
bitermotors_check_log "$tmp/reload.log" --expect-updates 2491 --expect-marker Goodbye
python3 "$checker" "$report" --expected-source-sha256 "$expected_sha"
