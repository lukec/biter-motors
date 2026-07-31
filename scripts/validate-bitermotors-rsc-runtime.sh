#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
factorio_bin="${FACTORIO_BINARY:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
read_data="${FACTORIO_READ_DATA:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/data}"
source_save="${1:-$HOME/Library/Application Support/factorio/saves/Biter-Motors-Start16.zip}"
tmp="$(mktemp -d /tmp/bitermotors-rsc-runtime.XXXXXX)"
mkdir -p "$tmp/mods" "$tmp/script-output"
ln -sfn "$repo_root/mod/bitermotors_0.1.0" "$tmp/mods/bitermotors_0.1.0"
printf '%s\n' '{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":true},{"name":"bitermotors","enabled":true}]}' > "$tmp/mods/mod-list.json"
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

python3 - <<'PY'
import json
import socket
import struct
import time


class RconClient:
    def __init__(self, host, port, password, timeout=10):
        self.host = host
        self.port = port
        self.password = password
        self.timeout = timeout
        self.socket = None
        self.request_id = 0

    def __enter__(self):
        self.socket = socket.create_connection(
            (self.host, self.port),
            timeout=self.timeout,
        )
        self.socket.settimeout(self.timeout)
        request_id = self._next_request_id()
        self._send(request_id, 3, self.password)
        response_id, _, _ = self._receive()
        if response_id != request_id:
            raise RuntimeError("RCON authentication failed")
        return self

    def __exit__(self, *_):
        if self.socket:
            self.socket.close()

    def _next_request_id(self):
        self.request_id += 1
        return self.request_id

    def _send(self, request_id, packet_type, body):
        encoded = body.encode("utf-8")
        payload = struct.pack("<ii", request_id, packet_type) + encoded + b"\0\0"
        self.socket.sendall(struct.pack("<i", len(payload)) + payload)

    def _receive_exactly(self, size):
        chunks = []
        remaining = size
        while remaining:
            chunk = self.socket.recv(remaining)
            if not chunk:
                raise ConnectionError("RCON connection closed")
            chunks.append(chunk)
            remaining -= len(chunk)
        return b"".join(chunks)

    def _receive(self):
        length = struct.unpack("<i", self._receive_exactly(4))[0]
        payload = self._receive_exactly(length)
        request_id, packet_type = struct.unpack("<ii", payload[:8])
        return request_id, packet_type, payload[8:-2].decode("utf-8")

    def command(self, command):
        request_id = self._next_request_id()
        self._send(request_id, 2, command)
        response_id, _, body = self._receive()
        if response_id != request_id:
            raise RuntimeError(
                f"RCON response id {response_id} did not match {request_id}"
            )
        return body

setup = r'''/sc game.tick_paused=false local s=game.surfaces.nauvis local f=game.forces.player local offices=remote.call("bitermotors","sales_office_status","player") local served=offices[1] and offices[1].settlements[1] local office=s.find_entities_filtered{name="bitermotors-sales-office",force=f}[1] local base=served and served.position or office and office.position or {x=0,y=0} local function make(dx) local p=s.find_non_colliding_position("bitermotors-robotaxi-service-center",{base.x+dx,base.y+20},128,1) local c=s.create_entity{name="bitermotors-robotaxi-service-center",position=p,force=f} script.raise_event(defines.events.script_raised_built,{entity=c}) local inv=c.get_inventory(defines.inventory.chest) inv.insert{name="bitermotors-robotaxi-fleet",count=200} local pole=s.create_entity{name="substation",position={p.x,p.y+6},force=f} local power=s.create_entity{name="electric-energy-interface",position={p.x+3,p.y+6},force=f} power.electric_interface_mode=defines.electric_interface_mode.primary_output power.power_production=30000000 power.output_flow_limit=30000000 return c end local c1=make(0) local c2=make(12) local inv2=c2.get_inventory(defines.inventory.chest) inv2[41].set_stack{name="bitermotors-dollar",count=100000} s.create_entity{name="bitermotors-robotaxi-service-power",position=c1.position,force=f} s.create_entity{name="bitermotors-robotaxi-service-power",position={base.x+300,base.y+300},force=f} storage.bitermotors_rsc_test={c1=c1.unit_number,c2=c2.unit_number,surface=s.index} rcon.print("RSC_SETUP ok")'''
query = r'''/sc local rows=remote.call("bitermotors","robotaxi_service_status","player") local s=game.get_surface(storage.bitermotors_rsc_test.surface) local customers=#s.find_entities_filtered{type="unit",force=game.forces["bitermotors-customers"]} local helper_count=#s.find_entities_filtered{name="bitermotors-robotaxi-service-power",force=game.forces.player} rcon.print("RSC_RESULT "..helpers.table_to_json{rows=rows,customers=customers,helpers=helper_count})'''
destroy = r'''/sc local s=game.get_surface(storage.bitermotors_rsc_test.surface) for _,c in pairs(s.find_entities_filtered{name="bitermotors-robotaxi-service-center",force=game.forces.player}) do if c.unit_number==storage.bitermotors_rsc_test.c2 then c.destroy{raise_destroy=true} end end rcon.print("RSC_DESTROY ok")'''

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
