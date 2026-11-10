# Orbital Compute Build Reference

Development reference with endgame spoilers. The [layout index](orbital-layout-preview.html)
shows coordinate schematics, not gameplay screenshots. The blueprints are native
Factorio 2.1.24 exports, rebuilt for physical cooling; no entity coordinates
were reconstructed into a blueprint. The current 1/4/8/12 native rehearsals used
the Hyperscale compact recipe to qualify each layout. The separate
[full normal-logistics rehearsal](endgame-pacing.md) qualifies the research ladder,
staged construction and 20,000-Dataset Model input. It is not a natural campaign.
Earlier quota-era measurements remain historical evidence.

## Start Small, Extend The Same Platform

Import the [one-cluster blueprint](../blueprints/orbital-compute-1.txt) on a new,
stationary Nauvis platform, aligning its hub with the existing hub. Later paste
the four-, eight-, and twelve-cluster versions over the same hub. Their original
equipment stays in place. Twelve clusters is a reference layout, not a win gate.

Each cluster has one compute core, one radiator and five orbital solar wings.
The current layouts also include a short physical Orbital Heat Pipe connection.
Heat only flows through connected ports; a radiator elsewhere provides no quota.
Aim near 97 C. Warnings begin at 105 C and escalate at 120 C; at 130 C the core
and its committed batch are destroyed. From normal full-load operation, a cut
heat path gives roughly 2-3 minutes to repair it or stop power. A sound network
needs no periodic maintenance. The [thermal report](orbital-thermal-hardening.md)
separates current physical-cooling evidence from the earlier quota-based tests.
At Nauvis's native 300% orbital sunlight, those wings generate 300 MW against
250 MW of rated compute plus its native drain and inserters. There is no orbital
accumulator, supplied power interface, solar multiplier, or cooling bypass.

Keep the input belt filtered to **Dollars only**. Finished Datasets must never
recirculate onto that belt during compute. Input arms use a hand size of one; output arms use
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

Do not maintain an exact-target refill after every coin. The full rehearsal
used stable lower/upper windows of 50-200 Dollars initially, 125-500 at Cluster,
then 250-1,000 at Grid/Hyperscale, with minimum deliveries 100/250/500/500.
Keep the ground research budget on Nauvis. Construct the next cluster stage
while its scale research runs; do not wait to build all twelve before starting
the first core. The native starter also supplies ten loose foundations besides
its 100 placed tiles; the build/launch checks account for those explicitly.

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
| Orbital Compute | 1 Dataset | 5 | 33.33 s |
| Cluster Training | 1 Dataset | 1 | 6.67 s |
| Grid-scale Energy | 2 Datasets | 1 | 6.67 s |
| Hyperscale Training, optional | 4 Datasets | 1 | 6.67 s |

These are the same cash, time and power per equivalent as the raw Token recipes.
The first compact batch groups five original batches; it does not give a free
efficiency upgrade. Raw Token recipes remain available for smaller requirements.

## Assemble And Return The Model

After the earned-compute gate and Grid-scale research, retain 20,000 Datasets
and ship one Datacenter Rack. Stop Dollar imports and input, let committed
compute finish, and drain the operating belt back into the hub. Switch one
existing core to Model assembly. Feed Datasets and the Rack through full-hand
bulk inserters, not the one-Dollar operating hand. Moving 20,000 physical items
is not part of the quoted one-minute craft.

The native-exported [Model assembly overlay](../blueprints/orbital-model-assembly.txt)
adds a second hub feeder, a second first-core input, and a far-end return loop.
Apply it only when ready for assembly; it selects that first core's Model recipe
and changes its feed filters. Its input bus is now payload-only, not a compute
Dollar bus. Allow Datasets, the Rack and residual Dollars through the return
loop and hub intake: items missed while an arm turns must not become stranded
at the far end. The full native transfer took about **21 minutes**, not an hour
and not an instant inventory move. The [coordinate reference](orbital-assembly-layout.png)
shows the additional I/O without inventing in-game coordinates.

Stop the other cores when the archive is sufficient rather than burning surplus
capital. The output belt already accepts the Model. Request that Model at the
Nauvis Cargo Landing Pad, let the native pod deliver it, then activate it in an
existing terrestrial datacenter. The model-return/activation chain has separate
[native ending qualification](endgame-validation.md). The
[practical pacing rehearsal](endgame-pacing.md) additionally qualifies the whole
large input transfer, separate-process mid-load reload and continued freeplay.

## Evidence Limits

The platform tests supply finite finished ground hardware, research, operating
cash, rocket ingredients and ground power. Platform construction, solar power,
compute, extraction, launches, cargo delivery and checkpoint reloads are native.
They do not prove natural campaign time or resource accessibility. Manufacturing,
shared material demand and finite-market funding are modeled separately in the
[logistics budget](orbital-logistics-budget.md).
