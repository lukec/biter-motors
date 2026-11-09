# Orbital Compute Build Reference

Development reference with endgame spoilers. The [layout index](orbital-layout-preview.html)
shows coordinate schematics, not gameplay screenshots. The blueprints are native
Factorio 2.1.20 exports; no entity coordinates were reconstructed into a blueprint.

## Start Small, Extend The Same Platform

Import the [one-cluster blueprint](../blueprints/orbital-compute-1.txt) on a new,
stationary Nauvis platform, aligning its hub with the existing hub. Later paste
the four-, eight-, and twelve-cluster versions over the same hub. Their original
equipment stays in place. Twelve clusters is a reference layout, not a win gate.

Each cluster has one compute core, one radiator and five orbital solar wings.
At Nauvis's native 300% orbital sunlight, those wings generate 300 MW against
250 MW of rated compute plus its native drain and inserters. There is no orbital
accumulator, supplied power interface, solar multiplier, or cooling bypass.

Keep the input belt filtered to **Dollars only**. Finished Datasets must never
recirculate onto that belt. Input arms use a hand size of one; output arms use
native bulk capacity. No modules or higher-quality equipment are necessary.
Bulk inserters and express belts are ordinary terrestrial technology; the
fixture supplies research and is not a technology-prerequisite qualification.

The foundation includes filled interior voids: native platforms must be connected
and cannot enclose holes. See the [official construction rules](https://wiki.factorio.com/Space_platform#Construction).

## Supply And Return

On Nauvis, put manufactured hardware and Dollars in logistic supply, connect a
powered rocket silo, and enable its automatic platform requests. For a small
bootstrap request, lower the minimum delivery count rather than waiting for a
full rocket of an expensive item. The native test used a minimum of one, allowing
2.1 to combine different items in a rocket. That is a tested setting, not an
instruction to manufacture a rocket for every single Dollar.

The blueprint hub contains finite **test** requests for its construction bill
and operating Dollars. Review those requests before building, and set a sensible
ongoing Dollar buffer. Requests copied from a larger blueprint are cumulative;
they are not a second bill for equipment already built.

For normal play, **keep most Datasets in orbit**: turn off the hub's automatic
trash of unrequested items and do not request all Datasets at the ground pad.
Return a few Datasets for research, unpack them in a terrestrial assembler, and
feed the resulting Tokens to labs. One Dataset contains 50,000 Tokens. Packaging
and unpacking preserve equivalents and earn no additional compute progress.

For the transport rehearsal only, the fixture instead enables hub trash and
requests the entire finite Dataset output at the Nauvis Cargo Landing Pad. It
proves extraction and native delivery, but is deliberately not the cheapest
final-archive operating policy.

## Recipe Ladder

| Research | Compact output | Dollars | Normal core time |
| --- | ---: | ---: | ---: |
| Orbital Compute | 1 Dataset | 5 | 100 s |
| Cluster Training | 1 Dataset | 1 | 20 s |
| Grid-scale Energy | 2 Datasets | 1 | 20 s |
| Hyperscale Training, optional | 4 Datasets | 1 | 20 s |

These are the same cash, time and power per equivalent as the raw Token recipes.
The first compact batch groups five original batches; it does not give a free
efficiency upgrade. Raw Token recipes remain available for smaller requirements.

## Assemble And Return The Model

After the earned-compute gate and Grid-scale research, retain 20,000 Datasets
and ship one Datacenter Rack. Switch one core to Model assembly. Change the hub
input filter and **that core's** input filter to Datasets and the Rack; stop
feeding Dollars to it. Increase that input arm's hand size for the large Dataset
load. Moving 20,000 physical items is not part of the quoted one-minute craft.

Stop the other cores when the archive is sufficient rather than burning surplus
capital. The output belt already accepts the Model. Request that Model at the
Nauvis Cargo Landing Pad, let the native pod deliver it, then activate it in an
existing terrestrial datacenter. The model-return/activation chain has separate
[native ending qualification](endgame-validation.md). This layout slice does
not additionally qualify the large assembly-input transfer described above.

## Evidence Limits

The platform tests supply finite finished ground hardware, research, operating
cash, rocket ingredients and ground power. Platform construction, solar power,
compute, extraction, launches, cargo delivery and checkpoint reloads are native.
They do not prove natural campaign time or resource accessibility. Manufacturing,
shared material demand and finite-market funding are modeled separately in the
[logistics budget](orbital-logistics-budget.md).
