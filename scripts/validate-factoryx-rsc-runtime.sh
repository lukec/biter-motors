#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
factorio_bin="${FACTORIO_BINARY:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/data}"
source_save="${1:-$HOME/Library/Application Support/factorio/saves/FactoryX-Start16.zip}"
tmp="$(mktemp -d /tmp/factoryx-rsc-runtime.XXXXXX)"
mkdir -p "$tmp/mods" "$tmp/script-output"
ln -sfn "$repo_root/mod/factoryx_0.1.0" "$tmp/mods/factoryx_0.1.0"
printf '%s\n' '{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":true},{"name":"factoryx","enabled":true}]}' > "$tmp/mods/mod-list.json"
printf '[path]\nread-data=%s\nwrite-data=%s\n' "$read_data" "$tmp" > "$tmp/config.ini"
cp "$read_data/server-settings.example.json" "$tmp/server-settings.json"
sed -i '' -e 's/"public": true/"public": false/' -e 's/"lan": true/"lan": false/' -e 's/"auto_pause": true/"auto_pause": false/' "$tmp/server-settings.json"
cp "$source_save" "$tmp/save.zip"

"$factorio_bin" --config "$tmp/config.ini" --mod-directory "$tmp/mods" \
  --start-server "$tmp/save.zip" --port 34206 --rcon-port 27026 --rcon-password test \
  --server-settings "$tmp/server-settings.json" \
  >"$tmp/server.log" 2>&1 &
pid=$!
trap 'kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true' EXIT
for _ in {1..80}; do nc -z 127.0.0.1 27026 && break; sleep 0.25; done

PYTHONPATH="$repo_root/bridge" python3 - <<'PY'
import json, time
from factorio_rcon import RconClient

setup = r'''/sc game.tick_paused=false local s=game.surfaces.nauvis local f=game.forces.player local office=s.find_entities_filtered{name="x-sales-office",force=f}[1] local base=office and office.position or {x=0,y=0} local function make(dx) local p=s.find_non_colliding_position("x-robotaxi-service-center",{base.x+dx,base.y+40},128,1) local c=s.create_entity{name="x-robotaxi-service-center",position=p,force=f} script.raise_event(defines.events.script_raised_built,{entity=c}) local inv=c.get_inventory(defines.inventory.chest) inv.insert{name="x-robotaxi-fleet",count=200} local pole=s.create_entity{name="substation",position={p.x,p.y+6},force=f} local power=s.create_entity{name="electric-energy-interface",position={p.x+3,p.y+6},force=f} power.electric_interface_mode=defines.electric_interface_mode.primary_output power.power_production=30000000 power.output_flow_limit=30000000 return c end local c1=make(0) local c2=make(12) local inv2=c2.get_inventory(defines.inventory.chest) inv2[41].set_stack{name="x-dollar",count=100000} s.create_entity{name="x-robotaxi-service-power",position=c1.position,force=f} s.create_entity{name="x-robotaxi-service-power",position={base.x+300,base.y+300},force=f} storage.factoryx_rsc_test={c1=c1.unit_number,c2=c2.unit_number,surface=s.index} rcon.print("RSC_SETUP ok")'''
query = r'''/sc local rows=remote.call("factoryx","robotaxi_service_status","player") local s=game.get_surface(storage.factoryx_rsc_test.surface) local customers=#s.find_entities_filtered{type="unit",force=game.forces["factoryx-customers"]} local helper_count=#s.find_entities_filtered{name="x-robotaxi-service-power",force=game.forces.player} rcon.print("RSC_RESULT "..helpers.table_to_json{rows=rows,customers=customers,helpers=helper_count})'''
destroy = r'''/sc local s=game.get_surface(storage.factoryx_rsc_test.surface) for _,c in pairs(s.find_entities_filtered{name="x-robotaxi-service-center",force=game.forces.player}) do if c.unit_number==storage.factoryx_rsc_test.c2 then c.destroy{raise_destroy=true} end end rcon.print("RSC_DESTROY ok")'''

with RconClient("127.0.0.1", 27026, "test", timeout=10) as client:
    output = client.command(setup)
    if "RSC_SETUP" not in output:
        output = client.command(setup)
    if "RSC_SETUP" not in output:
        raise SystemExit(output)
    time.sleep(3)
    result_output = client.command(query)
    line = next(line for line in result_output.splitlines() if line.startswith("RSC_RESULT "))
    result = json.loads(line.removeprefix("RSC_RESULT "))
    rows = result["rows"]
    assert len(rows) == 2, result
    assert sum(row["customers"] for row in rows) <= result["customers"], result
    assert sum(row["customers"] for row in rows) > 0, result
    assert any(row["output_blocked"] for row in rows), result
    assert result["helpers"] == 2, result
    client.command(destroy)
    time.sleep(2)
    result_output = client.command(query)
    line = next(line for line in result_output.splitlines() if line.startswith("RSC_RESULT "))
    after = json.loads(line.removeprefix("RSC_RESULT "))
    assert len(after["rows"]) == 1, after
    assert after["helpers"] == 1, after
    print("Biter Motors RSC runtime gate OK:", json.dumps({"before": result, "after": after}, sort_keys=True))
PY
