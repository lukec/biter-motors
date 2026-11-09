#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/scripts/lib/bitermotors-validation.sh"
bitermotors_resolve_source "$repo_root"
source_sha="$(python3 "$repo_root/scripts/bitermotors_economy_catalog.py" --source-sha)"
factorio_bin="${FACTORIO_BINARY:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-$(dirname "$factorio_bin")/../data}"
cores="${BITERMOTORS_PLATFORM_CORES:-1}"
recipe="${BITERMOTORS_PLATFORM_RECIPE:-bitermotors-orbital-ai-dataset-hyperscale}"
raw="${BITERMOTORS_PLATFORM_RAW:-false}"
batches=60
if [[ "$recipe" == bitermotors-orbital-ai-dataset ]]; then batches=12; fi
[[ "$cores" =~ ^(1|4|8|12)$ && "$raw" =~ ^(true|false)$ ]] || { printf 'Invalid platform case\n' >&2; exit 2; }
[[ "$recipe" =~ ^bitermotors-orbital-ai-(token|dataset)(-(cluster|grid-scale|hyperscale))?$ ]] || exit 2
[[ -x "$factorio_bin" ]] || { printf 'Factorio executable unavailable\n' >&2; exit 2; }
tmp="$(mktemp -d /tmp/bitermotors-platform.XXXXXX)"
mods="$tmp/mods"
helper="$mods/bitermotors_platform_validation_0.1.1"
mkdir -p "$helper" "$tmp/saves" "$tmp/script-output"
printf 'Isolated platform artifacts: %s\n' "$tmp"
bitermotors_stage_mod "$mods"
cp "$repo_root/scripts/fixtures/platform-control.lua" "$helper/control.lua"
cp "$repo_root/scripts/fixtures/orbital-layout.lua" "$helper/orbital-layout.lua"
printf 'return {cores=%s,recipe="%s",batches=%s,raw=%s,source_sha256="%s"}\n' "$cores" "$recipe" "$batches" "$raw" "$source_sha" > "$helper/platform-config.lua"
cat > "$helper/info.json" <<'EOF_INFO'
{"name":"bitermotors_platform_validation","version":"0.1.1","title":"Native practical orbital platform","author":"Codex","factorio_version":"2.1","dependencies":["base >= 2.1.20","space-age >= 2.1.20","bitermotors >= 0.1.1"]}
EOF_INFO
cat > "$mods/mod-list.json" <<'EOF_MODS'
{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":true},{"name":"bitermotors","enabled":true},{"name":"bitermotors_platform_validation","enabled":true}]}
EOF_MODS
cat > "$tmp/config.ini" <<EOF_CONFIG
[path]
read-data=$read_data
write-data=$tmp
EOF_CONFIG
python3 - "$read_data/server-settings.example.json" "$tmp/server-settings.json" <<'EOF_SERVER'
import json, sys
from pathlib import Path
settings=json.loads(Path(sys.argv[1]).read_text())
settings.update(name="Isolated practical orbital platform",visibility={"public":False,"lan":False},require_user_verification=False,auto_pause=False,autosave_interval=0)
Path(sys.argv[2]).write_text(json.dumps(settings))
EOF_SERVER
run_engine() {
  local log="$1" status=0
  shift
  "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" "$@" > "$log" 2>&1 || status=$?
  if ! bitermotors_check_log "$log" --expect-marker Goodbye; then tail -90 "$log" >&2; return 1; fi
  if (( status != 0 )); then tail -90 "$log" >&2; return "$status"; fi
}
seed="$tmp/saves/seed.zip"
report="$tmp/script-output/bitermotors-platform.jsonl"
run_engine "$tmp/create.log" --create "$seed" --map-gen-seed 1082026
port="$(python3 - <<'EOF_PORT'
import socket
with socket.socket(socket.AF_INET,socket.SOCK_DGRAM) as s:
    s.bind(('127.0.0.1',0)); print(s.getsockname()[1])
EOF_PORT
)"
pid=""
cleanup() {
  if [[ -n "$pid" ]]; then kill -INT "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; fi
}
trap cleanup EXIT
source_save="$seed"
for phase in mid complete; do
  checkpoint="$tmp/saves/bitermotors-platform-$phase.zip"
  fifo="$tmp/$phase.stdin"
  mkfifo "$fifo"
  exec 3<> "$fifo"
  "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" --start-server "$source_save" \
    --server-settings "$tmp/server-settings.json" --bind 127.0.0.1 --port "$port" <&3 > "$tmp/$phase.log" 2>&1 &
  pid=$!
  deadline=$((SECONDS+360))
  while [[ ! -s "$checkpoint" ]] && (( SECONDS < deadline )); do
    if ! kill -0 "$pid" 2>/dev/null; then break; fi
    if [[ -s "$tmp/$phase.log" ]] && ! bitermotors_check_log "$tmp/$phase.log"; then break; fi
    sleep 0.2
  done
  kill -INT "$pid" 2>/dev/null || true
  status=0
  wait "$pid" || status=$?
  pid=""
  exec 3<&- 3>&-
  if ! bitermotors_check_log "$tmp/$phase.log" --expect-marker Goodbye; then tail -90 "$tmp/$phase.log" >&2; exit 1; fi
  if [[ "$status" != 0 && "$status" != 130 ]] || [[ ! -s "$checkpoint" ]]; then
    tail -90 "$tmp/$phase.log" >&2; printf 'Missing %s checkpoint in %s\n' "$phase" "$tmp" >&2; exit 1
  fi
  python3 "$repo_root/scripts/validation_support.py" report "$report" --require-status "${phase}_checkpoint" --minimum-tick 1
  source_save="$checkpoint"
done
run_engine "$tmp/reload.log" --benchmark "$source_save" --benchmark-ticks 61 --benchmark-runs 1
bitermotors_check_log "$tmp/reload.log" --expect-updates 61 --expect-marker Goodbye
python3 "$repo_root/scripts/validation_support.py" report "$report" --require-status reload_passed --minimum-tick 1
python3 "$repo_root/scripts/check_orbital_platform.py" "$report" \
  --expected-source-sha256 "$source_sha" --catalog "$repo_root/docs/economy-prototypes.json"
