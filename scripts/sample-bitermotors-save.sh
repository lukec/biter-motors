#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/scripts/lib/bitermotors-validation.sh"
bitermotors_resolve_source "$repo_root"
save="${1:?usage: sample-bitermotors-save.sh SAVE.zip [TICKS]}"
ticks="${2:-36001}"
[[ -f "$save" && "$ticks" =~ ^[0-9]+$ ]] && (( ticks > 1 )) || exit 2
factorio_bin="${FACTORIO_BINARY:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-$(dirname "$factorio_bin")/../data}"
tmp="$(mktemp -d /tmp/bitermotors-save-sample.XXXXXX)"
mods="$tmp/mods"
helper="$mods/bitermotors_save_sample_0.1.0"
mkdir -p "$helper" "$tmp/script-output" "$tmp/saves"
printf 'Isolated save sample: %s\n' "$tmp"
bitermotors_stage_mod "$mods"
if [[ -L "$mods/bitermotors_$bitermotors_mod_version" ]]; then
  rm "$mods/bitermotors_$bitermotors_mod_version"
  cp -R "$bitermotors_mod_source" "$mods/bitermotors_$bitermotors_mod_version"
fi
cp "$save" "$tmp/saves/sample.zip"
cp "$repo_root/scripts/fixtures/save-sample-control.lua" "$helper/control.lua"
printf 'return {ticks=%s}\n' "$ticks" > "$helper/sample-config.lua"
python3 - "$save" "$tmp" "$read_data" "$helper" <<'PY'
import hashlib, json, sys
from pathlib import Path
source, root, data, helper = map(Path, sys.argv[1:])
(root / "config.ini").write_text(f"[path]\nread-data={data}\nwrite-data={root}\n")
(helper / "info.json").write_text(json.dumps(dict(name="bitermotors_save_sample",version="0.1.0",title="Isolated save sampler",author="Codex",factorio_version="2.1",dependencies=["base >= 2.1.20","space-age >= 2.1.20","bitermotors >= 0.1.1"])))
(root / "mods/mod-list.json").write_text(json.dumps({"mods":[{"name":n,"enabled":True} for n in ["base","space-age","bitermotors","bitermotors_save_sample"]]}))
(root / "source.json").write_text(json.dumps(dict(name=source.name,sha256=hashlib.sha256(source.read_bytes()).hexdigest(),bytes=source.stat().st_size),indent=2)+"\n")
PY
code=0
"$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" --benchmark "$tmp/saves/sample.zip" \
  --benchmark-ticks "$ticks" --benchmark-runs 1 > "$tmp/engine.log" 2>&1 || code=$?
if ! bitermotors_check_log "$tmp/engine.log" --expect-updates "$ticks" --expect-marker Goodbye || (( code )); then
  tail -90 "$tmp/engine.log" >&2
  exit 1
fi
python3 - "$tmp" "$save" "$ticks" <<'PY'
import hashlib, json, sys
from pathlib import Path
root, source, ticks = Path(sys.argv[1]), Path(sys.argv[2]), int(sys.argv[3])
manifest=json.loads((root / "source.json").read_text())
assert hashlib.sha256(source.read_bytes()).hexdigest()==manifest["sha256"], "Original save changed during sample"
rows=[json.loads(line) for line in (root / "script-output/bitermotors-save-sample.jsonl").read_text().splitlines()]
assert [r["kind"] for r in rows]==["initial","final"], "Incomplete save observations"
assert rows[-1]["tick"]-rows[0]["tick"]==ticks-1, "Requested updates did not advance time"
print("Saved production sample:",root / "script-output/bitermotors-save-sample.jsonl")
print("Original save unchanged:",manifest["sha256"])
PY
