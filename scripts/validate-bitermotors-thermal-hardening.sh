#!/usr/bin/env bash
set -euo pipefail

validate_report() {
python3 - "$1" "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" <<'EOF_CHECK'
import json
import math
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
sys.path.insert(0, sys.argv[2])
from validation_support import check_log
for name in ("create", "hot", "burned", "hardening", "benchmark12", "benchmark128"):
    check_log(root / f"{name}.log", marker="Goodbye")
def read(path):
    text = path.read_text()
    assert text.endswith("\n"), f"unterminated report: {path}"
    rows = [json.loads(line) for line in text.splitlines() if line.strip()]
    assert rows and all(type(r) is dict for r in rows), f"missing object reports: {path}"
    return rows
def number(row, key):
    v = row[key]
    assert type(v) in (int, float) and math.isfinite(v), (key, v)
    return v
def exact(row, **values):
    for k, v in values.items():
        assert type(row[k]) is type(v) and row[k] == v, (k, row[k], v)
def positive(row, *keys):
    for k in keys:
        assert number(row, k) > 0, (k, row)
def bounded(row):
    assert type(row["max_visited"]) is int and 0 < row["max_visited"] <= 128, row
def array(row, count):
    exact(row, count=count, supplied_power=count != 1, supplied_watts=0 if count == 1 else count * 400000000)
    assert 95.5 <= number(row, "min_c") <= number(row, "max_c") <= 98.5, row
    positive(row, "min_output", "min_cash", "output", "products", "work_seconds", "heat_joules")
    assert number(row, "min_products") > 10, row
    cores = row["per_core"]
    assert type(cores) is list and len(cores) == count
    assert len({c["unit"] for c in cores}) == count
    for c in cores:
        assert type(c["unit"]) is int and c["unit"] > 0
        positive(c, "products", "output", "work_seconds")
        assert 95.5 <= number(c, "temperature") <= 98.5
    for key in ("products", "output", "work_seconds"):
        assert abs(sum(c[key] for c in cores) - number(row, key)) < 0.001
    assert row["min_products"] == min(c["products"] for c in cores)
    assert row["min_output"] == min(c["output"] for c in cores)
    assert row["min_c"] == min(c["temperature"] for c in cores)
    assert row["max_c"] == max(c["temperature"] for c in cores)

rows = read(root / "script-output/bitermotors-thermal-hardening.jsonl")
names = ["idle_passed", "nominal_passed", "brownout_passed", "outage_passed", "blocked_passed",
         "repair_warning_passed", "repair_passed", "hot_checkpoint", "hot_reload_passed", "critical_passed",
         "burnout_passed", "burned_checkpoint", "burned_reload_passed", "shared4_passed", "shared_loss_passed",
         "shared_repair_passed", "lifecycle_passed", "array12_checkpoint", "array128_checkpoint", "hardening_passed"]
assert [r["status"] for r in rows] == names, "missing, duplicate or unordered phases"
for r in rows:
    exact(r, scope="production-native-thermal-hardening")
    assert type(r["limits"]) is str and "supplied EEI" in r["limits"], r
    assert type(r["tick"]) is int and r["tick"] > 0, r
    assert type(r["assertions"]) is int and r["assertions"] > 0, r
    bounded(r)
for a, b in zip(rows, rows[1:]):
    assert b["tick"] > a["tick"] and b["assertions"] > a["assertions"], "nonadvancing evidence"
r = dict(zip(names, rows))
idle = r["idle_passed"]
exact(idle, solar_wings=5, native_solar_watts=300000000, supplied_power=False)
assert type(idle["players"]) is int and idle["players"] >= 0
assert number(idle["core"], "work_seconds") == 0 and number(idle["core"], "heat_joules") > 0
assert abs(number(idle["core"], "watts") - 250000000 / 30) <= 100000
for name, count in (("nominal_passed", 1), ("repair_passed", 1), ("shared4_passed", 4),
                    ("shared_repair_passed", 4), ("array12_checkpoint", 12), ("array128_checkpoint", 128)):
    array(r[name], count)
for name in ("nominal_passed", "array12_checkpoint", "array128_checkpoint"):
    assert number(r[name], "elapsed_ticks") >= 180000
assert 0.35 < number(r["brownout_passed"], "work_fraction") < 0.55
exact(r["brownout_passed"], native_solar_watts=120000000)
for name in ("outage_passed", "blocked_passed"):
    a, b = r[name]["before"], r[name]["after"]
    assert abs(number(a, "work_seconds") - number(b, "work_seconds")) <= 0.001
    assert number(r[name], "elapsed_ticks") >= 1800
    if name == "outage_passed":
        assert abs(number(a, "heat_joules") - number(b, "heat_joules")) <= 1
    else:
        assert abs(number(b, "watts") - 250000000 / 30) <= 100000
for name, state, threshold in (("repair_warning_passed", "warning", 105), ("critical_passed", "critical", 120)):
    core = r[name]["core"]
    exact(core, state=state, warning_visible=True)
    exact(r[name], custom_status=True)
    alert = r[name]["alerts"]
    exact(alert, players=idle["players"], message_key="bitermotors-thermal.alert-" + state)
    assert type(alert["count"]) is int and alert["count"] >= idle["players"]
    assert threshold <= number(core, "temperature") < (120 if threshold == 105 else 130)
exact(r["repair_passed"]["alerts"], players=idle["players"], count=0, message_key="none")
hot, reload = r["hot_checkpoint"], r["hot_reload_passed"]
exact(reload, separate_process_reload=True, saved_tick=hot["tick"])
for key, tolerance in (("temperature", 0.01), ("heat_joules", 1)):
    assert abs(number(hot["core"], key) - number(reload["before"], key)) <= tolerance
    assert abs(number(reload["before"], key) - number(reload["after"], key)) <= tolerance
assert type(reload["queued_ticks"]) is int and 1 <= reload["queued_ticks"] < 15
assert reload["tick"] == hot["tick"] + reload["queued_ticks"]
assert abs(number(hot, "progress_per_tick") - 1.5 / (10 * 60)) < 1e-12
assert reload["progress_per_tick"] == hot["progress_per_tick"]
assert reload["before"]["progress"] == hot["core"]["progress"]
assert abs(number(reload["after"], "progress") - number(hot["core"], "progress")
           - hot["progress_per_tick"] * reload["queued_ticks"]) < 0.000001
assert 105 <= hot["core"]["temperature"] < 120 and 0.05 < hot["core"]["progress"] < 0.9
burned = r["burnout_passed"]
exact(burned, native_deaths=1, burnouts=1, buffers=0)
assert number(burned, "death_tick") > reload["tick"] > number(burned, "cut_tick")
assert number(burned, "seconds") == (burned["death_tick"] - burned["cut_tick"]) / 60
assert 120 <= burned["seconds"] <= 180
assert burned["cut_tick"] == hot["cut_tick"] and 95.5 <= number(hot, "cut_temperature") <= 98.5
exact(burned["last_burnout"], unit=hot["core"]["unit"], tick=burned["death_tick"])
assert 130 <= number(burned["last_burnout"], "temperature") < 131
reload = r["burned_reload_passed"]
exact(reload, native_deaths=1, burnouts=1, buffers=0, separate_process_reload=True,
      saved_tick=r["burned_checkpoint"]["tick"], output=r["burned_checkpoint"]["output"],
      checkpoint_output=r["burned_checkpoint"]["output"])
loss = r["shared_loss_passed"]
assert number(loss["after"], "min_c") > number(loss["before"], "max_c") + 0.5
assert number(loss["after"], "max_c") < 120 and number(loss, "elapsed_ticks") >= 2400
exact(r["lifecycle_passed"], cloning=True, force_change=True, mining=True, rebuild=True, removal=True,
      surface_delete=True, configuration_rebuild=False)
exact(r["hardening_passed"], native_deaths=1, player_alert_delivery=idle["players"] > 0, configuration_rebuild=False)
for name in ("seed", "hot", "burned", "array12", "array128"):
    p = root / "saves" / f"bitermotors-thermal-hardening-{name}.zip"
    assert p.is_file() and p.stat().st_size > 0, f"missing native save: {p}"
perf = read(root / "script-output/bitermotors-thermal-hardening-benchmark.jsonl")
assert len(perf) == 12, "three real benchmark runs per array, two reports per run"
for index, (a, b) in enumerate(zip(perf[::2], perf[1::2])):
    count = 12 if index < 3 else 128
    exact(a, status="benchmark_start")
    exact(b, status="benchmark_end")
    for p in (a, b):
        bounded(p)
        array(p["state"], count)
        assert type(p["tick"]) is int and p["tick"] > 0
    assert 3540 <= b["tick"] - a["tick"] <= 3600, "benchmark updates without advancing ticks"
    assert abs(b["state"]["max_c"] - a["state"]["max_c"]) < 0.5, "benchmark array not thermally stable"
    for key in ("products", "output", "work_seconds", "heat_joules"):
        assert number(b["state"], key) > number(a["state"], key), "benchmark not physically producing"
    before = {c["unit"]: c for c in a["state"]["per_core"]}
    after = {c["unit"]: c for c in b["state"]["per_core"]}
    assert before.keys() == after.keys(), "benchmark cores changed"
    for unit, c in after.items():
        for key in ("products", "output", "work_seconds"):
            assert number(c, key) > number(before[unit], key), "individual benchmark core stopped"
    checkpoint = r[f"array{count}_checkpoint"]
    assert a["tick"] >= checkpoint["tick"] and abs(a["state"]["min_c"] - checkpoint["min_c"]) < 0.1
timings = {}
for count in (12, 128):
    log = (root / f"benchmark{count}.log").read_text()
    records = re.findall(r"Performed (\d+) updates in ([\d.]+) ms", log)
    assert len(records) == 3 and all(int(ticks) == 3600 for ticks, _ in records), "missing engine timings"
    values = [float(ms) for _, ms in records]
    assert all(math.isfinite(ms) and ms > 0 for ms in values)
    timings[count] = {"runs_ms": values, "mean_ms_per_tick": sum(values) / 10800}
print("Production native thermal hardening passed:", json.dumps({"phases": len(rows), "benchmark": timings,
      "player_alert_delivery": idle["players"] > 0, "configuration_rebuild": False, "artifacts": str(root)}, sort_keys=True))
EOF_CHECK
}
if [[ "${1:-}" == --check-report ]]; then
  [[ $# == 2 ]] || exit 2
  validate_report "$2"
  exit
fi
[[ $# == 0 ]] || { printf 'Usage: %s [--check-report ARTIFACT_ROOT]\n' "$0" >&2; exit 2; }
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/scripts/lib/bitermotors-validation.sh"
bitermotors_resolve_source "$repo_root"
factorio_bin="${FACTORIO_BINARY:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-$(dirname "$factorio_bin")/../data}"
[[ -x "$factorio_bin" ]] || { printf 'Factorio executable unavailable: %s\n' "$factorio_bin" >&2; exit 2; }
# Fail before launching if the production data/runtime integration is not ready.
python3 - "$bitermotors_mod_source" <<'EOF_PREFLIGHT'
import sys
from pathlib import Path
p = Path(sys.argv[1])
data, control = (p / "data.lua").read_text(), (p / "control.lua").read_text()
assert all(s in data for s in ('"bitermotors-orbital-heat-buffer"', '"bitermotors-orbital-heat-pipe"',
                             'orbital_heat_buffer("1200MJ", 3)', 'orbital_heat_buffer("100MJ", 3)'))
assert "thermal_status" in control and (p / "runtime/orbital_thermals.lua").is_file()
print("Production native thermal prototypes and remote integration present")
EOF_PREFLIGHT
resume="${BITERMOTORS_THERMAL_RESUME_DIR:-}"
if [[ -n "$resume" ]]; then
  tmp="$(cd "$resume" && pwd -P)"
  [[ "$tmp" == /private/tmp/bitermotors-thermal-hardening.* || "$tmp" == /tmp/bitermotors-thermal-hardening.* ]] || exit 2
  [[ -s "$tmp/input-manifest.json" && -s "$tmp/saves/bitermotors-thermal-hardening-burned.zip" ]] || exit 2
else
  tmp="$(mktemp -d /tmp/bitermotors-thermal-hardening.XXXXXX)"
fi
mods="$tmp/mods"
helper="$mods/bitermotors_thermal_hardening_validation_0.1.0"
mkdir -p "$helper" "$tmp/saves" "$tmp/script-output"
printf 'Production thermal hardening artifacts: %s\n' "$tmp"
if [[ -z "$resume" ]]; then bitermotors_stage_mod "$mods"; fi
# Freeze source-mode inputs: other agents may fix the shared checkout during a run.
if [[ -L "$mods/bitermotors_${bitermotors_mod_version}" ]]; then
  rm "$mods/bitermotors_${bitermotors_mod_version}"
  cp -R "$bitermotors_mod_source" "$mods/bitermotors_${bitermotors_mod_version}"
fi
cp "$repo_root/scripts/fixtures/thermal-hardening-control.lua" "$helper/control.lua"
python3 - "$mods" "$tmp/input-manifest.json" "$helper/control.lua" "$repo_root/scripts/validate-bitermotors-thermal-hardening.sh" <<'EOF_MANIFEST'
import hashlib
import json
import sys
import zipfile
from pathlib import Path
mods, destination, fixture, runner = map(Path, sys.argv[1:])
archives = list(mods.glob("bitermotors_*.zip"))
if archives:
    with zipfile.ZipFile(archives[0]) as z:
        files = {n: hashlib.sha256(z.read(n)).hexdigest() for n in sorted(z.namelist()) if not n.endswith("/")}
    archive_hash = hashlib.sha256(archives[0].read_bytes()).hexdigest()
else:
    source = next(p for p in mods.glob("bitermotors_*") if p.is_dir() and "validation" not in p.name)
    files = {str(p.relative_to(mods)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(source.rglob("*")) if p.is_file()}
    archive_hash = None
manifest = dict(input_kind="exact-archive" if archives else "frozen-source", archive_sha256=archive_hash,
    source_tree_sha256=hashlib.sha256(json.dumps(files, sort_keys=True).encode()).hexdigest(), files=files,
    fixture_sha256=hashlib.sha256(fixture.read_bytes()).hexdigest(), runner_sha256=hashlib.sha256(runner.read_bytes()).hexdigest())
if destination.exists():
    previous = json.loads(destination.read_text())
    assert previous["source_tree_sha256"] == manifest["source_tree_sha256"], "resume cannot change main-mod inputs"
    manifest["resumed_after_burned_checkpoint"] = True
    manifest["previous_input_manifest"] = previous
destination.write_text(json.dumps(manifest, sort_keys=True, indent=2) + "\n")
print("Frozen thermal inputs:", json.dumps({k: v for k, v in manifest.items() if k not in {"files", "previous_input_manifest"}}, sort_keys=True))
EOF_MANIFEST
python3 - "$tmp" "$read_data" "$helper" <<'EOF_PROFILE'
import json
import sys
from pathlib import Path
t, data, helper = map(Path, sys.argv[1:])
(t / "config.ini").write_text(f"[path]\nread-data={data}\nwrite-data={t}\n")
(helper / "info.json").write_text(json.dumps(dict(name="bitermotors_thermal_hardening_validation", version="0.1.0",
    title="Production native thermal hardening", author="Codex", factorio_version="2.1",
    dependencies=["base >= 2.1.20", "space-age >= 2.1.20", "bitermotors >= 0.1.1"])))
(t / "mods/mod-list.json").write_text(json.dumps({"mods": [{"name": n, "enabled": True} for n in
    ("base", "space-age", "bitermotors", "bitermotors_thermal_hardening_validation")]}))
settings = json.loads((data / "server-settings.example.json").read_text())
settings.update(name="Disposable production thermal hardening", visibility={"public": False, "lan": False},
    require_user_verification=False, auto_pause=False, autosave_interval=0)
(t / "server-settings.json").write_text(json.dumps(settings))
EOF_PROFILE
run_engine() {
  local log="$1" code=0
  shift
  "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" "$@" > "$log" 2>&1 || code=$?
  if ! bitermotors_check_log "$log" --expect-marker Goodbye; then tail -100 "$log" >&2; return 1; fi
  if (( code )); then tail -100 "$log" >&2; return "$code"; fi
}
if [[ -n "$resume" ]]; then
  python3 - "$tmp" <<'EOF_RESUME'
import json
import time
import sys
from pathlib import Path
t = Path(sys.argv[1])
p = t / "script-output/bitermotors-thermal-hardening.jsonl"
text = p.read_text()
rows = [json.loads(line) for line in text.splitlines() if line.strip()]
index = next(i for i, r in enumerate(rows) if r["status"] == "burned_checkpoint")
stamp = str(time.time_ns())
(t / f"report-before-resume-{stamp}.jsonl").write_text(text)
log = t / "hardening.log"
if log.exists():
    (t / f"hardening-before-resume-{stamp}.log").write_bytes(log.read_bytes())
p.write_text("".join(json.dumps(r) + "\n" for r in rows[:index + 1]))
perf = t / "script-output/bitermotors-thermal-hardening-benchmark.jsonl"
if perf.exists():
    (t / f"benchmark-before-resume-{stamp}.jsonl").write_bytes(perf.read_bytes())
    perf.unlink()
EOF_RESUME
elif [[ -n "${BITERMOTORS_THERMAL_PLAYER_SAVE:-}" ]]; then
  [[ -s "$BITERMOTORS_THERMAL_PLAYER_SAVE" ]] || { printf 'Missing real-player seed\n' >&2; exit 2; }
  cp "$BITERMOTORS_THERMAL_PLAYER_SAVE" "$tmp/saves/bitermotors-thermal-hardening-seed.zip"
  printf 'Copied supplied real-player save; no client invoked. Goodbye\n' > "$tmp/create.log"
else
  run_engine "$tmp/create.log" --create "$tmp/saves/bitermotors-thermal-hardening-seed.zip" --map-gen-seed 97130128
fi
port="$(python3 -c 'import socket; s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')"
pid=""
cleanup() {
  local child="${pid:-}"
  pid=""
  if [[ -n "$child" ]]; then kill -INT "$child" 2>/dev/null || true; wait "$child" 2>/dev/null || true; fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
save="$tmp/saves/bitermotors-thermal-hardening-seed.zip"
phases="hot burned hardening"
if [[ -n "$resume" ]]; then save="$tmp/saves/bitermotors-thermal-hardening-burned.zip"; phases="hardening"; fi
for phase in $phases; do
  fifo="$tmp/$phase.stdin"
  rm -f "$fifo"
  mkfifo "$fifo"
  exec 3<> "$fifo"
  run_save="$tmp/saves/run-$phase.zip"
  cp "$save" "$run_save"
  "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" --start-server "$run_save" \
    --server-settings "$tmp/server-settings.json" --bind 127.0.0.1 --port "$port" <&3 > "$tmp/$phase.log" 2>&1 &
  pid=$!
  expected="${phase}_checkpoint"
  if [[ "$phase" == hardening ]]; then expected=hardening_passed; fi
  checkpoint="$tmp/saves/bitermotors-thermal-hardening-$phase.zip"
  if [[ "$phase" == hardening ]]; then checkpoint="$tmp/saves/bitermotors-thermal-hardening-array128.zip"; fi
  deadline=$((SECONDS+${BITERMOTORS_THERMAL_PHASE_TIMEOUT:-600}))
  found=0
  while ((SECONDS < deadline)); do
    if [[ -s "$checkpoint" ]] && python3 "$repo_root/scripts/validation_support.py" report \
      "$tmp/script-output/bitermotors-thermal-hardening.jsonl" --require-status "$expected" --minimum-tick 1 > /dev/null 2>&1; then found=1; break; fi
    if ! kill -0 "$pid" 2>/dev/null; then break; fi
    if [[ -s "$tmp/$phase.log" ]] && ! bitermotors_check_log "$tmp/$phase.log" > /dev/null; then break; fi
    sleep 0.5
  done
  kill -INT "$pid" 2>/dev/null || true
  code=0
  wait "$pid" || code=$?
  pid=""
  exec 3<&- 3>&-
  if ! bitermotors_check_log "$tmp/$phase.log" --expect-marker Goodbye || ((found == 0)) || [[ "$code" != 0 && "$code" != 130 ]]; then
    tail -100 "$tmp/$phase.log" >&2
    printf 'Failed phase %s; retained artifacts: %s\n' "$phase" "$tmp" >&2
    exit 1
  fi
  save="$checkpoint"
done
for count in 12 128; do
  run_engine "$tmp/benchmark$count.log" --benchmark "$tmp/saves/bitermotors-thermal-hardening-array$count.zip" \
    --benchmark-ticks 3600 --benchmark-runs 3
  bitermotors_check_log "$tmp/benchmark$count.log" --expect-marker Goodbye
done
validate_report "$tmp"
