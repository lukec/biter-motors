#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kind="${BITERMOTORS_ENDING_CASE:-finale}"
[[ "$kind" == delivery || "$kind" == finale ]] || { printf 'Unknown ending case: %s\n' "$kind" >&2; exit 2; }
fixture="$repo_root/scripts/fixtures/$kind-control.lua"
player_save="${BITERMOTORS_ENDING_PLAYER_SAVE:-}"
epilogue="${BITERMOTORS_VALIDATE_EPILOGUE:-0}"
[[ "$epilogue" == 0 || "$epilogue" == 1 ]] || { printf 'Invalid epilogue mode: %s\n' "$epilogue" >&2; exit 2; }
single_player="${BITERMOTORS_EPILOGUE_SINGLE_PLAYER:-0}"
[[ "$single_player" == 0 || "$single_player" == 1 ]] || { printf 'Invalid single-player mode: %s\n' "$single_player" >&2; exit 2; }
if [[ "$single_player" == 1 && "$epilogue" != 1 ]]; then
  printf 'Single-player epilogue requires validate-bitermotors-epilogue.sh --single-player\n' >&2
  exit 2
fi
late_timeout="${BITERMOTORS_EPILOGUE_LATE_TIMEOUT_SECONDS:-240}"
if [[ ! "$late_timeout" =~ ^[1-9][0-9]{0,2}$ ]] || (( late_timeout > 240 )); then
  printf 'Late-player timeout must be 1-240 seconds\n' >&2
  exit 2
fi
if [[ "$epilogue" == 1 && ! -f "$player_save" ]]; then
  if [[ "$single_player" == 1 ]]; then
    printf '%s\n' 'Set BITERMOTORS_ENDING_PLAYER_SAVE to a fresh native save with one actual offline player (any name). Single-player mode does not qualify native multiplayer isolation or late creation.' >&2
    exit 2
  fi
  printf '%s\n' 'Set BITERMOTORS_ENDING_PLAYER_SAVE to a fresh native save with three offline players, preferably "Epilogue-first", "Epilogue-second", "Epilogue-unwon" (any three names accepted; no "Epilogue-late"). Factorio has no game.create_player API.' >&2
  exit 2
fi
if [[ ! -f "$fixture" ]]; then
  printf 'Finale fixture is not ready: %s\n' "$fixture" >&2
  exit 2
fi

source "$repo_root/scripts/lib/bitermotors-validation.sh"
bitermotors_resolve_source "$repo_root"
factorio_bin="${FACTORIO_BINARY:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-$(dirname "$factorio_bin")/../data}"
if [[ ! -x "$factorio_bin" ]]; then
  printf 'Factorio executable is unavailable: %s\n' "$factorio_bin" >&2
  exit 2
fi

tmp="$(mktemp -d "/tmp/bitermotors-$kind.XXXXXX")"
mods="$tmp/mods"
helper="$mods/bitermotors_${kind}_validation_0.1.1"
save="$tmp/saves/bitermotors-$kind-seed.zip"
report="$tmp/script-output/bitermotors-$kind.jsonl"
mkdir -p "$helper" "$tmp/saves" "$tmp/script-output"
printf 'Isolated %s artifacts: %s\n' "$kind" "$tmp"
bitermotors_stage_mod "$mods"

cat > "$tmp/config.ini" <<EOF_CONFIG
[path]
read-data=$read_data
write-data=$tmp
EOF_CONFIG
cat > "$mods/mod-list.json" <<EOF_MODS
{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":true},
{"name":"bitermotors","enabled":true},{"name":"bitermotors_${kind}_validation","enabled":true}]}
EOF_MODS
cat > "$helper/info.json" <<EOF_INFO
{"name":"bitermotors_${kind}_validation","version":"0.1.1","title":"Biter Motors Native Ending Validation","author":"Codex",
"factorio_version":"2.1","dependencies":["base >= 2.1.20","space-age >= 2.1.20","bitermotors >= 0.1.1"]}
EOF_INFO
cp "$fixture" "$helper/control.lua"
cp "$repo_root/scripts/fixtures/epilogue-validation.lua" "$helper/epilogue-validation.lua"
epilogue_lua=false
if [[ "$epilogue" == 1 ]]; then epilogue_lua=true; fi
printf 'return %s\n' "$epilogue_lua" > "$helper/epilogue-enabled.lua"
single_player_lua=false
if [[ "$single_player" == 1 ]]; then single_player_lua=true; fi
printf 'return %s\n' "$single_player_lua" > "$helper/epilogue-single-player.lua"
if [[ "$kind" == finale ]]; then
  cp "$repo_root/scripts/fixtures/delivery-control.lua" "$helper/native-ending.lua"
fi
python3 - "$read_data/server-settings.example.json" "$tmp/server-settings.json" <<'EOF_SERVER'
import json
import sys
from pathlib import Path

settings = json.loads(Path(sys.argv[1]).read_text())
settings.update(name="Isolated Biter Motors finale fixture",
                visibility={"public": False, "lan": False},
                require_user_verification=False, auto_pause=False, autosave_interval=0)
Path(sys.argv[2]).write_text(json.dumps(settings))
EOF_SERVER

run_engine() {
  local log="$1"
  shift
  local status=0
  "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" "$@" > "$log" 2>&1 || status=$?
  if ! bitermotors_check_log "$log" --expect-marker Goodbye; then
    tail -100 "$log" >&2
    return 1
  fi
  if (( status != 0 )); then
    tail -100 "$log" >&2
    return "$status"
  fi
}

if [[ "$epilogue" == 1 ]]; then
  cp "$player_save" "$save"
else
  run_engine "$tmp/create.log" --create "$save" --map-gen-seed 1062026
fi
test -s "$save" || { printf 'Seeded save is missing: %s\n' "$save" >&2; exit 1; }

port="$(python3 - <<'EOF_PORT'
import socket
with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
EOF_PORT
)"
start_server() {
  local source_save="$1"
  local log="$2"
  rm -f "$tmp/server.stdin"
  mkfifo "$tmp/server.stdin"
  exec 3<> "$tmp/server.stdin"
  "$factorio_bin" --config "$tmp/config.ini" --mod-directory "$mods" \
    --start-server "$source_save" --server-settings "$tmp/server-settings.json" \
    --bind 127.0.0.1 --port "$port" <&3 > "$log" 2>&1 &
  server_pid=$!
  server_status=0
  server_stopped=0
}
stop_server() {
  if (( server_stopped == 0 )); then
    kill -INT "$server_pid" 2>/dev/null || true
    wait "$server_pid" || server_status=$?
    server_stopped=1
  fi
  exec 3<&- 3>&-
}
cleanup() {
  if [[ -n "${server_pid:-}" ]] && (( server_stopped == 0 )); then stop_server; fi
}
trap cleanup EXIT INT TERM

wait_for_phase() {
  local checkpoint="$1"
  local status="$2"
  local log="$3"
  local found=0
  local deadline=$((SECONDS + 240))
  local announced=0
  if [[ "$status" == epilogue_late_checkpoint ]]; then deadline=$((SECONDS + late_timeout)); fi
  for _ in {1..1200}; do
    if (( SECONDS >= deadline )); then break; fi
    if [[ "$status" == epilogue_late_checkpoint && "$announced" == 0 && -s "$tmp/script-output/bitermotors-epilogue-needs-player.json" ]]; then
      printf 'BITERMOTORS_EPILOGUE_AWAITING_LATE_PLAYER host=127.0.0.1 port=%s player="Epilogue-late" marker=%s timeout=%ss\n' \
        "$port" "$tmp/script-output/bitermotors-epilogue-needs-player.json" "$late_timeout"
      announced=1
    fi
    if [[ -s "$checkpoint" ]] && python3 - "$report" "$status" <<'EOF_STATUS'
import json
import sys
from pathlib import Path
try:
    rows = [json.loads(line) for line in Path(sys.argv[1]).read_text().splitlines() if line.strip()]
except (OSError, json.JSONDecodeError):
    raise SystemExit(1)
raise SystemExit(0 if any(row.get("status") == sys.argv[2] for row in rows) else 1)
EOF_STATUS
    then
      found=1
      break
    fi
    if ! kill -0 "$server_pid" 2>/dev/null; then
      wait "$server_pid" || server_status=$?
      server_stopped=1
      break
    fi
    sleep 0.2
  done
  if (( found == 0 )); then
    if (( server_stopped == 0 )); then stop_server; fi
    bitermotors_check_log "$log" --expect-marker Goodbye || true
    tail -120 "$log" >&2
    printf 'Required phase was not reached: %s and %s in %s\n' "$status" "$checkpoint" "$tmp" >&2
    return 1
  fi
  stop_server
  bitermotors_check_log "$log" --expect-marker Goodbye
  if [[ "$server_status" != 0 && "$server_status" != 130 ]]; then
    printf 'Finale server failed with status %s\n' "$server_status" >&2
    return 1
  fi
  test -s "$checkpoint" || { printf 'Server checkpoint is missing: %s\n' "$checkpoint" >&2; return 1; }
  python3 "$repo_root/scripts/validation_support.py" report "$report" \
    --require-status "$status" --minimum-tick 1
}

source_save="$save"
phases=(assembly flight return activation won)
if [[ "$epilogue" == 1 ]]; then
  phases+=(epilogue_thinking epilogue_reply epilogue_acknowledged)
  if [[ "$single_player" == 1 ]]; then phases+=(epilogue_replay); else phases+=(epilogue_late); fi
fi
for phase in "${phases[@]}"; do
  checkpoint="$tmp/saves/bitermotors-$kind-$phase.zip"
  phase_log="$tmp/$phase-server.log"
  start_server "$source_save" "$phase_log"
  wait_for_phase "$checkpoint" "${phase}_checkpoint" "$phase_log"
  source_save="$checkpoint"
done

run_engine "$tmp/reload.log" --benchmark "$source_save" --benchmark-ticks 2461 --benchmark-runs 1
bitermotors_check_log "$tmp/reload.log" --expect-updates 2461 --expect-marker Goodbye
python3 "$repo_root/scripts/validation_support.py" report "$report" \
  --require-status won_reload_passed --minimum-tick 1

python3 - "$report" "$tmp/saves" "$kind" "$epilogue" "$single_player" <<'EOF_CHECK'
import json
import sys
from pathlib import Path

report, save_dir = map(Path, sys.argv[1:3])
kind = sys.argv[3]
full_epilogue = len(sys.argv) > 4 and sys.argv[4] == "1"
single_player = len(sys.argv) > 5 and sys.argv[5] == "1"
assert not single_player or full_epilogue, "Single-player mode cannot be mechanical-only"
epilogue_phases = ("epilogue_thinking", "epilogue_reply", "epilogue_acknowledged",
                   "epilogue_replay" if single_player else "epilogue_late") if full_epilogue else ()
for phase in ("seed", "assembly", "flight", "return", "activation", "won", *epilogue_phases):
    path = save_dir / f"bitermotors-{kind}-{phase}.zip"
    assert path.is_file() and path.stat().st_size > 0, path
rows = [json.loads(line) for line in report.read_text().splitlines() if line.strip()]
statuses = ["payload_passed", "assembly_checkpoint", "assembly_reload_passed", "assembly_passed",
            "flight_checkpoint", "flight_reload_passed", "return_checkpoint", "return_reload_passed", "activation_checkpoint",
            "activation_reload_passed", "won_checkpoint"]
for phase in epilogue_phases:
    statuses.extend((f"{phase}_checkpoint", f"{phase}_reload_passed"))
statuses.append("won_reload_passed")
assert [row.get("status") for row in rows] == statuses, rows
assert all(type(row.get("assertions")) is int and row["assertions"] > 0 for row in rows), rows
assert all(row.get("validation_scope") == "native-model-ending" and row.get("limits") for row in rows), rows
assert all(row.get("payload_quality") == ("rare" if kind == "finale" else "normal") for row in rows), rows
assert all(row.get("single_player") is single_player for row in rows), rows
assert all(row.get("multiplayer_qualified") is False for row in rows), rows
assert all(row.get("native_player_isolation_qualified", False) is False for row in rows[:-1]), rows
if kind == "finale":
    assert all(type(row.get("presentation_native_cases")) is int and row["presentation_native_cases"] > 0 for row in rows), rows
assert all(type(row.get("tick")) is int and row["tick"] > 0 for row in rows), rows
assert all(a["tick"] < b["tick"] for a, b in zip(rows, rows[1:])), rows
by_status = {row["status"]: row for row in rows}
payload = by_status["payload_passed"]
assert payload["datasets_loaded"] == 20_000 and payload["earned_equivalents"] == 1_000_000_000, payload
for phase in ("assembly", "activation"):
    checkpoint = by_status[f"{phase}_checkpoint"]
    assert type(checkpoint.get("progress")) in (int, float) and 0 < checkpoint["progress"] < 1, checkpoint
for phase in ("assembly", "flight", "return", "activation", "won", *epilogue_phases):
    checkpoint = by_status[f"{phase}_checkpoint"]
    reload = by_status[f"{phase}_reload_passed"]
    assert reload["saved_tick"] == checkpoint["tick"] and reload["tick"] > reload["saved_tick"], reload
assembly = by_status["assembly_passed"]
assert assembly["products_after_reload"] > by_status["assembly_checkpoint"]["products"], assembly
assert assembly["native_completion_tick"] > assembly["assembly_reload_tick"], assembly
flight = by_status["flight_checkpoint"]
assert flight["models_in_transit"] == 1 and flight["return_credits"] == 0, flight
assert flight["pod"] == by_status["flight_reload_passed"]["pod"], rows
assert by_status["return_checkpoint"]["models_returned"] == 1, rows
assert by_status["won_checkpoint"]["models_activated"] == 1, rows
reload = by_status["won_reload_passed"]
assert reload["native_activations"] == 1 and reload["freeplay_ticks"] >= 2400, reload
assert abs(reload["activation_measured_watts"] - 8_000_000) < 400_000, reload
assert isinstance(reload["victory"], dict) and reload["victory"], reload
assert reload["victory"] == by_status["won_checkpoint"]["victory"], rows
if not full_epilogue:
    assert all(row.get("epilogue_passed") is False and row.get("epilogue_qualification") == "not-qualified" for row in rows), rows
    assert all(row.get("presentation_scope") == "not-qualified" for row in rows), rows
    assert reload.get("native_player_isolation_qualified", False) is False, reload
    print("Native mechanical ending passed; epilogue NOT QUALIFIED:", json.dumps(rows, sort_keys=True))
    raise SystemExit(0)
assert reload.get("epilogue_passed") is True, reload
if single_player:
    # Earlier 1P captures already denied multiplayer and identify the same narrow
    # native presentation scope below; retain their evidence without recapture.
    assert reload.get("epilogue_qualification") in ("native-offline-single-player-qualified", "single-player-qualified"), reload
    assert reload.get("native_player_isolation_qualified", False) is False, reload
else:
    assert reload.get("epilogue_qualification") == "native-offline-player-isolation-qualified", reload
    assert reload.get("native_player_isolation_qualified") is True, reload
evidence = reload["epilogue_evidence"]
force_cache = evidence["progress_force_cache"]
assert force_cache["same_frame"] is True and force_cache["no_spoilers"] is True, force_cache
assert isinstance(force_cache["primed_stage"], str) and force_cache["primed_stage"] != "Complete", force_cache
assert force_cache["returned_stage"] == force_cache["primed_stage"], force_cache
assert force_cache["won_stage"] == force_cache["restored_won_stage"] == "Complete", force_cache
gui_checks = evidence["progress_gui_checks"]
assert set(gui_checks) == {f"{phase}_{suffix}" for phase in ("assembly", "activation", "won") for suffix in ("checkpoint", "reload")}, gui_checks
for phase, label in (("assembly", "Model assembly"), ("activation", "Ground activation"), ("won", "Complete")):
    for suffix in ("checkpoint", "reload"):
        native_gui = gui_checks[f"{phase}_{suffix}"]
        assert native_gui["stage"] == label and native_gui["detail"], native_gui
        if phase == "won":
            assert native_gui["progress"] == 1 and not native_gui.get("payload"), native_gui
        else:
            assert native_gui["payload"] == "Payload committed" and 0 < native_gui["progress"] < 1, native_gui
            assert "Payload committed" in native_gui["detail"], native_gui
for field in ("replay_preserved_ack", "force_isolated", "repeated_open_idempotent"):
    assert evidence.get(field) is True, evidence
if single_player:
    assert evidence.get("thinking_dismiss_preserved_ack") is True, evidence
    assert not evidence.get("late_created_once") and not evidence.get("late"), evidence
else:
    assert evidence.get("late_created_once") is True, evidence
    assert evidence["late"]["acknowledged"] is True, evidence
for row in rows:
    assert row.get("presentation_scope") == ("native-single-player-gui-public-callbacks" if single_player else "native-offline-gui-public-callbacks"), row
    assert row.get("presentation_limits"), row
won = by_status["won_checkpoint"]["epilogue"]
victory_tick = won["victory_tick"]
assert type(victory_tick) is int and victory_tick > 0, won
for row in rows[10:]:
    epilogue = row["epilogue"]
    assert epilogue["victory_tick"] == victory_tick, row
    if not single_player:
        assert epilogue["outsider"]["phase"] == "locked" and epilogue["outsider"]["eligible"] is False, row
    else:
        assert not epilogue.get("second") and not epilogue.get("outsider"), row
    for player in (("first",) if single_player else ("first", "second")):
        assert epilogue[player]["victory_tick"] == victory_tick and epilogue[player]["eligible"] is True, row
        assert epilogue[player]["force_index"] == won[player]["force_index"], row
for player in (("first",) if single_player else ("first", "second")):
    assert won[player]["phase"] == "pending" and won[player]["acknowledged"] is False, won
    assert won[player]["open"] is False, won
thinking = by_status["epilogue_thinking_checkpoint"]["epilogue"]["first"]
thinking_reload = by_status["epilogue_thinking_reload_passed"]["epilogue"]
assert thinking["phase"] == "thinking" and 0 < thinking["elapsed_ticks"] < 180, thinking
assert thinking["acknowledged"] is False, thinking
assert thinking_reload["first"]["phase"] == "thinking", thinking_reload
assert thinking_reload["first"]["acknowledged"] is False, thinking_reload
assert thinking_reload["first"]["elapsed_ticks"] >= thinking["elapsed_ticks"], thinking_reload
if not single_player:
    assert thinking_reload["second"]["acknowledged"] is True and thinking_reload["second"]["skipped"] is True, thinking_reload
for name in ("epilogue_reply_checkpoint",):
    reply = by_status[name]["epilogue"]["first"]
    assert reply["phase"] == "reply" and reply["elapsed_ticks"] >= 180 and reply["acknowledged"] is False, reply
for name in ("epilogue_acknowledged_checkpoint", "epilogue_acknowledged_reload_passed", "won_reload_passed"):
    epilogue = by_status[name]["epilogue"]
    assert epilogue["first"]["acknowledged"] is True and epilogue["first"]["skipped"] is False, epilogue
    if not single_player:
        assert epilogue["second"]["acknowledged"] is True and epilogue["second"]["skipped"] is True, epilogue
if single_player:
    replay = by_status["epilogue_replay_checkpoint"]["epilogue"]["first"]
    assert replay["phase"] == "thinking" and 0 < replay["elapsed_ticks"] < 180, replay
    assert replay["acknowledged"] is True and replay["replay"] is True, replay
    closed = by_status["epilogue_replay_reload_passed"]["epilogue"]["first"]
    assert closed["phase"] == "acknowledged" and closed["open"] is False, closed
    assert closed["acknowledged"] is True and closed["skipped"] is False, closed
print("Native single-player epilogue passed; multiplayer NOT QUALIFIED:" if single_player else "Native offline player isolation passed; multiplayer NOT QUALIFIED:", json.dumps(rows, sort_keys=True))
EOF_CHECK
