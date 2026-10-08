#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/scripts/lib/bitermotors-validation.sh"

uplift_check_report() {
  python3 - "$1" <<'EOF_CHECK'
import json
import sys
from pathlib import Path

CORE = "bitermotors-orbital-datacenter-core"
SOLAR = "bitermotors-high-density-space-solar-panel"
RADIATOR = "bitermotors-orbital-radiator-panel"
DOLLAR = "bitermotors-dollar"
TOKEN = "bitermotors-ai-token"
MANIFEST = {"space-platform-starter-pack": 1, "space-platform-foundation": 100,
            CORE: 1, SOLAR: 5, RADIATOR: 1, "transport-belt": 12,
            "inserter": 4, DOLLAR: 100}
WEIGHTS = {CORE: 100_000, SOLAR: 25_000, RADIATOR: 100_000, DOLLAR: 10,
           "bitermotors-agi-model": 1000, TOKEN: 1,
           "bitermotors-agi-training-dataset": 1000}
CARGO_WEIGHTS = {**WEIGHTS, "space-platform-starter-pack": 1_000_000,
                 "space-platform-foundation": 20_000, "transport-belt": 10_000, "inserter": 20_000}
SCIENCE = {name: 1 for name in ("automation-science-pack", "logistic-science-pack",
           "chemical-science-pack", "production-science-pack", "utility-science-pack", DOLLAR, TOKEN)}
STATUSES = ["uplift_setup_passed", "uplift_manufacture_passed", "uplift_delivery_passed",
            "uplift_return_passed", "uplift_reload_passed"]

def require(condition, message):
    if not condition:
        raise ValueError(message)

def integer(value, minimum=0):
    return type(value) is int and value >= minimum

def exact_counts(value, expected, label):
    require(isinstance(value, dict) and value == expected and
            all(integer(count) for count in value.values()), label)

def validate_rows(rows):
    require(isinstance(rows, list) and len(rows) == len(STATUSES), "incomplete/extra milestones")
    require(all(isinstance(row, dict) for row in rows), "non-object milestone")
    require([row.get("status") for row in rows] == STATUSES, "failed/duplicate/out-of-order milestones")
    previous_tick, previous_assertions = -1, -1
    for row in rows:
        require(integer(row.get("tick")) and row["tick"] > previous_tick, "time did not advance")
        require(integer(row.get("assertions"), 1) and row["assertions"] > previous_assertions,
                "missing or nonadvancing assertions")
        previous_tick, previous_assertions = row["tick"], row["assertions"]
    setup, manufacture, delivery, returned, reload = rows
    exact_counts(setup.get("weights"), WEIGHTS, "runtime masses")
    exact_counts(setup.get("science"), SCIENCE, "entry science must exclude white")
    exact_counts(setup.get("manifest"), MANIFEST, "first-cluster manifest")
    require(setup.get("inserter_stack_size_bonus") == 2, "disclosed native ordinary inserter capacity prerequisite")
    require(setup.get("footprints") == {name: [3, 3] for name in (CORE, SOLAR, RADIATOR)}, "compact footprints")
    manufactured = {name: count for name, count in MANIFEST.items() if name != DOLLAR}
    exact_counts(manufacture.get("manufactured"), manufactured, "native manufactured hardware")
    require(integer(manufacture.get("science_consumed")) and manufacture["science_consumed"] == 1500,
            "native research consumption")
    require(all(integer(manufacture.get(key), 1) for key in
                ("starter_tick", "platform_research_tick", "researched_tick")), "missing native research ticks")
    require(setup["tick"] < manufacture["starter_tick"] <= manufacture["platform_research_tick"] <
            manufacture["researched_tick"] < manufacture["tick"], "starter must unlock native platform before entry")
    built = {name: MANIFEST[name] for name in (CORE, SOLAR, RADIATOR, "transport-belt", "inserter")}
    for row in (delivery, returned, reload):
        require(row.get("requests") == {name: {"count": count + (10 if name == "space-platform-foundation" else 0),
                    "minimum_delivery_count": 50 if name == "space-platform-foundation" else count} for name, count in MANIFEST.items()
                    if name != "space-platform-starter-pack"}, "explicit practical native request minima")
        require(row.get("foundation_remaining") == 10, "native foundation inventory conservation")
        require(row.get("gravity") == 0 and row.get("solar_coefficient") == 300 and
                row.get("core_watts") == 250_000_000 and row.get("wing_nominal_watts") == 20_000_000,
                "native gravity and 60MW Nauvis-orbit wings / 250MW core")
        exact_counts(row.get("manufactured"), manufactured, "manufacturing conservation")
        exact_counts(row.get("shipped"), MANIFEST, "launched cargo conservation")
        exact_counts(row.get("delivered"), MANIFEST, "delivered cargo conservation")
        exact_counts(row.get("built"), built, "native ghost building evidence")
        require(integer(row.get("built_tiles")) and row["built_tiles"] == 100, "100 added foundation")
        require(integer(row.get("rockets")) and row["rockets"] == 9, "nine actual launches")
        require(integer(row.get("rocket_parts")) and row["rocket_parts"] == 450, "native rocket-part consumption")
        exact_counts(row.get("rocket_consumed"), {"processing-unit": 450,
                     "low-density-structure": 450, "rocket-fuel": 450}, "actual native rocket ingredients")
        require(row.get("starter_tick") == manufacture["starter_tick"], "real starter delivery")
        shipments = row.get("shipments")
        require(isinstance(shipments, list) and len(shipments) == 9, "missing actual shipment ledger")
        cargo_total = {}
        for shipment in shipments:
            require(isinstance(shipment, dict), "shipment must be an object")
            cargo = shipment.get("cargo")
            require(isinstance(cargo, dict) and len(cargo) == 1, "separate-item partial native launch")
            name, count = next(iter(cargo.items()))
            require(name in MANIFEST and integer(count, 1) and
                    count == (50 if name == "space-platform-foundation" else MANIFEST[name]), "shipment cargo")
            require(shipment.get("origin") == "nauvis-silo" and shipment.get("launched_by_rocket") is True,
                    "cargo did not originate in a real ground rocket")
            require(integer(shipment.get("tick"), 1) and integer(shipment.get("delivered_tick"), 1) and
                    setup["tick"] < shipment["tick"] <= shipment["delivered_tick"] <= delivery["tick"], "shipment timing")
            require(integer(shipment.get("mass"), 1) and shipment["mass"] <= 1_000_000, "rocket capacity")
            require(shipment["mass"] == CARGO_WEIGHTS[name] * count, "cargo mass conservation")
            if name == "space-platform-starter-pack":
                require(shipment["mass"] == 1_000_000 and shipment["delivered_tick"] == row["starter_tick"],
                        "real full-mass starter deployment")
            require(integer(shipment.get("capacity"), 1) and shipment["capacity"] == 10 and
                    integer(shipment.get("slots"), 1) and shipment["slots"] <= shipment["capacity"], "rocket inventory slots")
            cargo_total[name] = cargo_total.get(name, 0) + count
        exact_counts(cargo_total, MANIFEST, "per-pod cargo conservation")
    require(delivery["shipments"] == returned["shipments"] == reload["shipments"], "shipment ledger changed")
    require(delivery.get("produced") == delivery.get("returned") == delivery.get("return_pods") == 0,
            "operation must follow complete uplift")
    require(integer(returned.get("operation_tick"), 1) and returned["operation_tick"] == delivery["tick"],
            "operation start")
    for row in (returned, reload):
        require(integer(row.get("core_completions")) and row["core_completions"] == 1 and
                integer(row.get("earned_equivalents")) and row["earned_equivalents"] == 10_000,
                "actual earned orbital compute / reload ledger")
        require(integer(row.get("dollars_remaining")) and row["dollars_remaining"] == 99,
                "uplifted Dollar conservation / reload stock")
        require(row.get("produced") == row.get("returned") == 10_000 and integer(row.get("return_pods"), 1),
                "native produced/output/delivered Token conservation")
        require(row.get("physical_tokens") == 10_000, "actual landing-pad output stock")
    require(reload.get("saved_tick") == returned["tick"] < reload["tick"], "separate-process reload time")
    require(reload["return_pods"] == returned["return_pods"], "return ledger changed on reload")
    return rows

if __name__ == "__main__":
    try:
        text = Path(sys.argv[1]).read_text()
        require(text.endswith("\n"), "unterminated report")
        rows = validate_rows([json.loads(line) for line in text.splitlines() if line.strip()])
    except (OSError, ValueError, TypeError, KeyError) as error:
        raise SystemExit(f"Uplift validation failed: {error}")
    print("Native uplift fixture passed:", json.dumps(rows, sort_keys=True))
EOF_CHECK
}

# Evidence-only mode never starts Factorio; also used by the sidecar tests.
if [[ "${1:-}" == --check-report ]]; then
  [[ "$#" == 2 ]] || { printf 'Usage: %s --check-report REPORT\n' "$0" >&2; exit 2; }
  uplift_check_report "$2"
  exit
fi
[[ "$#" == 0 ]] || { printf 'Usage: %s [--check-report REPORT]\n' "$0" >&2; exit 2; }
bitermotors_resolve_source "$repo_root"
factorio_bin="${FACTORIO_BINARY:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-$(dirname "$factorio_bin")/../data}"
[[ -x "$factorio_bin" ]] || { printf 'Factorio executable unavailable: %s\n' "$factorio_bin" >&2; exit 2; }
tmp="$(mktemp -d /tmp/bitermotors-uplift.XXXXXX)"
mods="$tmp/mods"
helper="$mods/bitermotors_uplift_validation_0.1.1"
save="$tmp/saves/bitermotors-uplift.zip"
reload="$tmp/saves/bitermotors-uplift-reload.zip"
report="$tmp/script-output/bitermotors-uplift.jsonl"
mkdir -p "$helper" "$tmp/saves" "$tmp/script-output"
printf 'Isolated uplift artifacts (retained): %s\n' "$tmp"
bitermotors_stage_mod "$mods"
cat > "$tmp/config.ini" <<EOF_CONFIG
[path]
read-data=$read_data
write-data=$tmp
EOF_CONFIG
cat > "$mods/mod-list.json" <<'EOF_MODS'
{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":true},
{"name":"bitermotors","enabled":true},{"name":"bitermotors_uplift_validation","enabled":true}]}
EOF_MODS
cat > "$helper/info.json" <<'EOF_INFO'
{"name":"bitermotors_uplift_validation","version":"0.1.1","title":"Biter Motors Native Uplift Validation","author":"Codex",
"factorio_version":"2.1","dependencies":["base >= 2.1.20","space-age >= 2.1.20","bitermotors >= 0.1.1"]}
EOF_INFO
cp "$repo_root/scripts/fixtures/uplift-control.lua" "$helper/control.lua"
python3 - "$read_data/server-settings.example.json" "$tmp/server-settings.json" <<'EOF_SERVER'
import json
import sys
from pathlib import Path
settings = json.loads(Path(sys.argv[1]).read_text())
settings.update(name="Isolated Biter Motors native uplift fixture",
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
run_engine "$tmp/create.log" --create "$save" --map-gen-seed 1082026
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
cleanup() { kill -INT "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; }
trap cleanup EXIT
completed=0
deadline=$((SECONDS + 600))
for (( attempt=0; attempt<3000 && SECONDS<deadline; attempt++ )); do
  if [[ -s "$reload" ]]; then completed=1; break; fi
  if ! kill -0 "$pid" 2>/dev/null; then break; fi
  # Fail promptly even when Factorio logs a runtime error but stays alive/exits zero.
  if [[ -s "$tmp/server.log" ]] && ! bitermotors_check_log "$tmp/server.log"; then break; fi
  sleep 0.2
done
kill -INT "$pid" 2>/dev/null || true
server_status=0
wait "$pid" || server_status=$?
trap - EXIT
exec 3<&- 3>&-
bitermotors_check_log "$tmp/server.log" --expect-marker Goodbye
if [[ "$server_status" != 0 && "$server_status" != 130 ]]; then
  tail -100 "$tmp/server.log" >&2
  printf 'Uplift fixture server failed: %s\n' "$server_status" >&2; exit 1
fi
if [[ "$completed" != 1 ]]; then
  tail -100 "$tmp/server.log" >&2
  printf 'Uplift timeout/incomplete checkpoint; retained artifacts: %s\n' "$tmp" >&2; exit 1
fi
python3 "$repo_root/scripts/validation_support.py" report "$report" \
  --require-status uplift_return_passed --minimum-tick 1
test -s "$reload"
run_engine "$tmp/reload.log" --benchmark "$reload" --benchmark-ticks 61 --benchmark-runs 1
bitermotors_check_log "$tmp/reload.log" --expect-updates 61 --expect-marker Goodbye
python3 "$repo_root/scripts/validation_support.py" report "$report" \
  --require-status uplift_reload_passed --minimum-tick 1
uplift_check_report "$report"
