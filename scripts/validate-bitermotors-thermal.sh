#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/scripts/lib/bitermotors-validation.sh"
bitermotors_resolve_source "$repo_root"
factorio_bin="${FACTORIO_BINARY:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-$(dirname "$factorio_bin")/../data}"
tmp="$(mktemp -d /tmp/bitermotors-thermal.XXXXXX)"
mods="$tmp/mods"
helper="$mods/bitermotors_thermal_validation_0.1.0"
mkdir -p "$helper" "$tmp/saves" "$tmp/script-output"
printf 'Isolated thermal prototype: %s\n' "$tmp"
bitermotors_stage_mod "$mods"
prototype="$repo_root/experiments/bitermotors_thermal_prototype_0.1.0"
if [[ -n "${BITERMOTORS_THERMAL_ARCHIVE:-}" ]]; then
  python3 - "$BITERMOTORS_THERMAL_ARCHIVE" "$prototype" <<'PY'
import sys, zipfile
from pathlib import Path
source=Path(sys.argv[2])
expected={source.name+"/"+p.relative_to(source).as_posix():p.read_bytes() for p in source.rglob("*") if p.is_file()}
with zipfile.ZipFile(sys.argv[1]) as archive:
    files=[entry for entry in archive.infolist() if not entry.is_dir()]
    if len(files)!=len(expected) or {entry.filename for entry in files}!=set(expected):
        raise SystemExit("Prototype archive contents differ from source")
    if any(archive.read(name)!=data for name,data in expected.items()):
        raise SystemExit("Prototype archive bytes differ from source")
print("Prototype ZIP matches current experimental source")
PY
  cp "$BITERMOTORS_THERMAL_ARCHIVE" "$mods/bitermotors_thermal_prototype_0.1.0.zip"
else
  ln -s "$prototype" "$mods/bitermotors_thermal_prototype_0.1.0"
fi
cp "$repo_root/scripts/fixtures/thermal-control.lua" "$helper/control.lua"
python3 - "$helper/info.json" "$mods/mod-list.json" "$tmp/server-settings.json" "$read_data/server-settings.example.json" <<'PY'
import json, sys
from pathlib import Path
Path(sys.argv[1]).write_text(json.dumps(dict(name="bitermotors_thermal_validation", version="0.1.0", title="Thermal prototype native validation", author="Codex", factorio_version="2.1", dependencies=["base >= 2.1.20", "space-age >= 2.1.20", "bitermotors_thermal_prototype >= 0.1.0"])))
Path(sys.argv[2]).write_text(json.dumps({"mods":[{"name":n,"enabled":True} for n in ["base","space-age","bitermotors","bitermotors_thermal_prototype","bitermotors_thermal_validation"]]}))
settings=json.loads(Path(sys.argv[4]).read_text())
settings.update(name="Isolated orbital thermal prototype",visibility={"public":False,"lan":False}, require_user_verification=False,auto_pause=False,autosave_interval=0)
Path(sys.argv[3]).write_text(json.dumps(settings))
PY
printf '[path]\nread-data=%s\nwrite-data=%s\n' "$read_data" "$tmp" > "$tmp/config.ini"
run_engine() {
  local log="$1" code=0
  shift
  "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" "$@" > "$log" 2>&1 || code=$?
  if ! bitermotors_check_log "$log" --expect-marker Goodbye; then tail -80 "$log" >&2; return 1; fi
  if (( code )); then tail -80 "$log" >&2; return "$code"; fi
}
run_engine "$tmp/create.log" --create "$tmp/saves/seed.zip" --map-gen-seed 97130
port="$(python3 -c 'import socket; s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')"
pid=""
cleanup() { if [[ -n "$pid" ]]; then kill -INT "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; fi; }
trap cleanup EXIT
save="$tmp/saves/seed.zip"
for phase in hot burned; do
  fifo="$tmp/$phase.stdin"
  mkfifo "$fifo"
  exec 3<> "$fifo"
  "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" --start-server "$save" \
    --server-settings "$tmp/server-settings.json" --bind 127.0.0.1 --port "$port" <&3 > "$tmp/$phase.log" 2>&1 &
  pid=$!
  checkpoint="$tmp/saves/bitermotors-thermal-$phase.zip"
  deadline=$((SECONDS+180))
  while [[ ! -s "$checkpoint" ]] && ((SECONDS < deadline)); do
    if ! kill -0 "$pid" 2>/dev/null; then break; fi
    if [[ -s "$tmp/$phase.log" ]] && ! bitermotors_check_log "$tmp/$phase.log"; then break; fi
    sleep 0.2
  done
  kill -INT "$pid" 2>/dev/null || true
  code=0
  wait "$pid" || code=$?
  pid=""
  exec 3<&- 3>&-
  if ! bitermotors_check_log "$tmp/$phase.log" --expect-marker Goodbye; then tail -80 "$tmp/$phase.log" >&2; exit 1; fi
  if [[ "$code" != 0 && "$code" != 130 ]] || [[ ! -s "$checkpoint" ]]; then tail -80 "$tmp/$phase.log" >&2; exit 1; fi
  python3 "$repo_root/scripts/validation_support.py" report "$tmp/script-output/bitermotors-thermal.jsonl" --require-status "${phase}_checkpoint" --minimum-tick 1
  save="$checkpoint"
done
run_engine "$tmp/reload.log" --benchmark "$save" --benchmark-ticks 61 --benchmark-runs 1
bitermotors_check_log "$tmp/reload.log" --expect-updates 61 --expect-marker Goodbye
python3 "$repo_root/scripts/validation_support.py" report "$tmp/script-output/bitermotors-thermal.jsonl" --require-status reload_passed --minimum-tick 1
python3 - "$tmp/script-output/bitermotors-thermal.jsonl" <<'PY'
import json, sys
from pathlib import Path
rows=[json.loads(line) for line in Path(sys.argv[1]).read_text().splitlines()]
assert [r["status"] for r in rows]==["setup_passed","steady_passed","blocked_output_passed","brownout_passed","outage_passed","repair_started","repair_passed","hot_checkpoint","hot_reload_passed","burnout_passed","burned_checkpoint","reload_passed"]
assert all(b["tick"]>a["tick"] for a,b in zip(rows,rows[1:]))
assert all(r["assertions"]>0 for r in rows)
burned=next(r for r in rows if r["status"]=="burnout_passed")
print("Thermal prototype native validation passed:", json.dumps({"steady_c":rows[1]["thermal"]["cores"][0]["temperature"],"burnout_c":burned["thermal"]["burnout_events"][0]["temperature"],"hot_buffer_seconds":burned["seconds_from_hot_checkpoint"],"native_deaths":rows[-1]["native_deaths"]}))
PY
