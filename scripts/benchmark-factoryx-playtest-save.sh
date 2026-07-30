#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
factorio_bin="${FACTORIO_BINARY:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/data}"
save="${1:?usage: $0 SAVE.zip [TICKS]}"
ticks="${2:-600}"
tmp="$(mktemp -d /tmp/factoryx-playtest-benchmark.XXXXXX)"
mods="$tmp/mods"

mkdir -p "$mods"
ln -sfn "$repo_root/mod/factoryx_0.1.0" "$mods/factoryx_0.1.0"
cat > "$tmp/config.ini" <<EOF
[path]
read-data=$read_data
write-data=$tmp
EOF
cat > "$mods/mod-list.json" <<'EOF'
{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":true},{"name":"factoryx","enabled":true}]}
EOF

cp "$save" "$tmp/benchmark.zip"
"$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" \
  --benchmark "$tmp/benchmark.zip" --benchmark-ticks "$ticks" --benchmark-runs 1 \
  --benchmark-verbose all >"$tmp/benchmark.log" 2>&1

python3 - "$tmp/benchmark.log" "${FACTORIO_BENCHMARK_MAX_MS:-0}" <<'PY'
import re
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text(errors="replace")
threshold = float(sys.argv[2])
matches = [float(value) for value in re.findall(r"avg:\s*([0-9.]+)\s*ms", text)]
if not matches:
    print(text[-4000:])
    raise SystemExit("Could not parse benchmark average update time")
average = matches[-1]
print(f"Biter Motors benchmark average update: {average:.3f} ms")
if threshold > 0 and average > threshold:
    raise SystemExit(f"Biter Motors benchmark exceeds {threshold:g} ms threshold: {average:.3f} ms")
PY
