# Experimental Orbital Thermals

Private opt-in laboratory add-on, not part of the Biter Motors release archive.
Do not enable it in a campaign you want to preserve. The ordinary mod and its
current radiator-count rule are unchanged.

## Native Validation

From the repository root, run `scripts/validate-bitermotors-thermal.sh`.
It creates a disposable profile under `/tmp`, with its own mod directory, saves,
network port and reports. It neither installs mods nor restarts a running client.
The validation helper automatically removes conduits and destroys equipment;
its saves are test fixtures, not player demo saves.

## Disposable Sandbox

Enable only Space Age, Biter Motors and this add-on in a separate experimental
mod directory, without `bitermotors_thermal_validation`. Start a disposable
sandbox/editor world. Three enabled conversion recipes provide an experimental
core, radiator and conduit from their existing counterparts.

Connect a core's side port to a radiator with conduits, power it, select an
orbital compute recipe and supply Dollars. A nominal core with three conduits
and one radiator settles near 97 C. Native machine status shows temperature;
the radiator's status shows heat rejection. Art is reused and temporary.

Removing a conduit while computing raises temperature. Warnings start at
105 C; 120 C is critical; at 130 C the core is destroyed, not shut down.
Repairing the connection before burnout lets the same machine recover.
Disconnecting electricity stops active compute heat but does not erase stored
heat. There is no instant cooling or temperature reset on save/reload.

This prototype isolates 250 MW active compute with zero idle drain. Production's
existing idle drain is unchanged and needs integration before adopting this
system. Temperature calibration is layout-dependent; conduits have real native
capacity and gradients. Beacons, arbitrary recipe changes, quality variants,
large arrays and graphical presentation are not release-qualified here.

See `docs/orbital-thermal-prototype.md` in the repository for measured results
and limitations. Loading a hot experimental fixture is deliberately dangerous.
