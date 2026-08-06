#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
factorio_bin="${FACTORIO_BINARY:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/data}"
save="${1:?usage: $0 SAVE.zip [TICKS]}"
ticks="${2:-600}"
verbose="${BITERMOTORS_BENCHMARK_VERBOSE:-0}"
tmp="$(mktemp -d /tmp/bitermotors-playtest-benchmark.XXXXXX)"
mods="$tmp/mods"

mkdir -p "$mods"
ln -sfn "$repo_root/mod/bitermotors_0.1.1" "$mods/bitermotors_0.1.1"
cat > "$tmp/config.ini" <<EOF
[path]
read-data=$read_data
write-data=$tmp
EOF
cat > "$mods/mod-list.json" <<'EOF'
{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":true},{"name":"bitermotors","enabled":true}]}
EOF

cp "$save" "$tmp/benchmark.zip"
benchmark_args=(
  --config "$tmp/config.ini"
  --mod-directory "$mods"
  --benchmark "$tmp/benchmark.zip"
  --benchmark-ticks "$ticks"
  --benchmark-runs 1
)
if [[ "$verbose" == "1" ]]; then
  benchmark_args+=(--benchmark-verbose all)
fi
if ! "$factorio_bin" "${benchmark_args[@]}" >"$tmp/benchmark.log" 2>&1; then
  tail -120 "$tmp/benchmark.log" >&2
  exit 1
fi
if grep -qE 'non-recoverable error|Error while running event|errored when running' "$tmp/benchmark.log"; then
  tail -120 "$tmp/benchmark.log" >&2
  exit 1
fi

python3 - "$tmp/benchmark.log" "${FACTORIO_BENCHMARK_MAX_MS:-0}" <<'PY'
import re
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text(errors="replace")
threshold = float(sys.argv[2])
matches = [
    tuple(map(float, values))
    for values in re.findall(
        r"avg:\s*([0-9.]+)\s*ms,\s*min:\s*([0-9.]+)\s*ms,\s*max:\s*([0-9.]+)\s*ms",
        text,
    )
]
if not matches:
    print(text[-4000:])
    raise SystemExit("Could not parse benchmark update times")
average, minimum, maximum = matches[-1]
print(
    "Biter Motors benchmark update: "
    f"avg={average:.3f} ms min={minimum:.3f} ms max={maximum:.3f} ms"
)
if threshold > 0 and average > threshold:
    raise SystemExit(f"Biter Motors benchmark exceeds {threshold:g} ms threshold: {average:.3f} ms")
PY

echo "Benchmark log: $tmp/benchmark.log"
