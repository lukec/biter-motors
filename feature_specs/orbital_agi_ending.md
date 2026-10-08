# Orbital AGI Ending

Design date: 2026-10-07. Updated: 2026-10-08.
Status: **orbital-entry slice implemented; replacement finale pending**.
Source now has compact hardware, explicit cargo weights, one-radiator cooling
and research without white science. The old 10 GW terrestrial finale and
orbital run-scrapping policy remain until slice 2. No player save, installed mod
or live process was changed. See [entry validation](../docs/orbital-entry-validation.md).

## Campaign Contract

The player rebuilds industry, sells products to biter customers, and finances
terrestrial AI. Its expensive operating costs motivate moving compute into
Nauvis orbit. Space is a final application of the existing business, battery,
electronics and solar supply chains, not another company or planetary campaign.

1. One ground datacenter can fund and produce the early AI research inputs.
   Additional datacenters are optional throughput, not a mandatory one/two/four
   escalating-price toll. Hyperscaler buildings remain outside this v1 slice.
2. Terrestrial AI and the native Rocket Silo lead directly to Orbital AI
   Infrastructure. Remove conventional white science and its prerequisite from
   the required compute path, including its efficiency tiers. Keep the native
   silo, starter pack, platform construction and cargo mechanics.
3. The first stationary platform contains one compact compute cluster with
   solar wings and a radiator. It physically returns Tokens for research.
4. Expand toward approximately twelve normal-quality clusters, on one to three
   platforms. This is a balancing reference, not a required entity count.
   Quality, modules, larger installations or slower cheaper routes remain valid.
5. One billion physical computed Token equivalents are assembled into an AGI
   Model in orbit. Return the actual Model to Nauvis and activate it in the
   existing terrestrial datacenter, now also serving as a terminal.
6. Native ground activation latches victory. A short epilogue follows; continued
   free play remains available. No new terrestrial grid megaproject follows it.

The Token/Dataset fiction compresses AI work into Factorio items. A Dataset is
50,000 existing Token equivalents, not another currency or a claim that a billion
real inference tokens scientifically guarantees AGI. The compact satellite art
represents a cluster of rack-scale satellites, not a literal 250 MW single rack.

## Proposed Working Values

The hardware table is implemented in source. Later research yields, Model
completion and pause/resume below remain **modeled recommendations**. The full
[cost study](../docs/orbital-ending-cost-study.md) distinguishes native captures,
proposal overrides, material frontiers and unmeasured play time.

| Hardware | Normal footprint | Operation | Proposed manufacturing recipe |
| --- | --- | --- | --- |
| Orbital Compute Cluster | 3x3 | 250 MW, current 1.5 crafting speed | 8 Datacenter Racks + 40 LDS + 12 LFP Battery Packs |
| Space Solar Wing | 3x3 | 20 MW nominal; 60 MW in Nauvis orbit | 2 HD Panels + 10 blue circuits + 5 LDS + 2 High-energy Packs |
| Orbital Radiator | 3x3 | Cools one 250 MW cluster | Keep current recipe: 20 heat pipes + 100 copper plates + 10 electric engines + 10 LDS |

Five wings and one radiator per normal cluster provide 300 MW generation for
250 MW compute and a 5:1 solar/radiator footprint ratio. This is inspired by the
earlier rack-satellite area discussion, not a flight-qualified thermal model.
Reduce the solar-wing recipe along with its output: five new panels must not
cost five of the much larger old 50 MW nominal units. The compute recipe removes
redundant blue circuits already contained in its racks.

Solar generation stays continuous in Nauvis orbit. A platform can nevertheless
be overloaded; its entire electric network must support the working machines.
Cooling capacity is local to that platform and force, with bounded allocation.
Do not add coolant mining, radiators that need consumable fluids, communication
currencies, engines, travel, other planets or combat fleets to this v1 path.

### Transport Weights

Capture **LuaItemPrototype.weight**, not only optional `data.raw` weight fields.
The 2026-10-07 capture found a 1,208,326-g core, over the normal 1,000,000-g
rocket limit, 250,025-g Dollars and a 2,147,483,647-g ground-built Model.
The 2026-10-08 entry slice replaces these defaults with explicit portable
weights. Manufacturing a core in orbit is no longer an uplift workaround.

Implemented weights, checked against the refreshed native catalog:

| Item | Explicit weight | Normal upward rocket capacity by mass |
| --- | ---: | ---: |
| Compute Cluster | 100 kg | 10 |
| Space Solar Wing | 25 kg | 40 |
| Radiator | 100 kg | 10 |
| Dollar | 10 g | 100,000 |
| AGI Model | 1 kg | 1,000 by mass; inventory also limits it |

Keep existing AI Tokens at 1 g and Datasets at 1 kg. Respect rocket inventory
slots as well as mass, native sendability, item quality and platform requests.
Configure practical minimum launch quantities: a first-cluster request must not
wait for ten clusters or forty panels. Avoid special scripted cargo delivery.

### Research And Throughput

The first two research costs remain 750 Dollars for Autonomy and 1,500 for
Orbital Infrastructure. They consume 2,250 physical terrestrial Tokens, costing
2,260 operating Dollars and 56.5 active minutes at normal base efficiency.
Do not require Bitertaxi sales or fleet construction to unlock orbit; recurring
service is one effective financing strategy, not the only route.

| Milestone | Research cycles | Dollars/cycle | Total Dollars | Unlocked normal batch |
| --- | ---: | ---: | ---: | ---: |
| Initial orbit | Existing 1,500 | 1 | 1,500 | 10,000 Tokens / 20s |
| 1M orbital equivalents | 1,000 | 2 | 2,000 | 50,000 Tokens / 20s |
| 10M orbital equivalents | 1,500 | 2 | 3,000 | 100,000 equivalents / 20s |
| 100M orbital equivalents | 2,000 | 3 | 6,000 | 200,000 equivalents / 20s |

Keep appropriate red/green/blue/purple/yellow science and AI inputs. Remove
white science, rather than adding another alternative space-science recipe.
Grid/Hyperscale Dataset variants must match their Token variants: two/four
50,000-equivalent Datasets per batch. Each batch still consumes one Dollar.
Higher tiers are efficiency choices. Hyperscale is not a permission to win:
the billion-equivalent milestone can unlock the final recipe without it.

Packaging does not generate new earned compute. Preserve native completion
accounting by force, recipe and quality. Research-consumed Tokens cannot also be
loaded as final training payload. Earlier work and physically stored items stay
useful after tier upgrades; there is no second billion-equivalent bill.

## Completion And Failure Rules

Remove the Planetary Grid Controller, its required research, Capital Allocation
item/recipe and 50,000-Dollar finale charge from the campaign. Tandem Solar and
Grid Battery Arrays may remain useful terrestrial upgrades without mandatory
final placement or consumption counts.

The proposed orbital final recipe consumes 20,000 Datasets and one Datacenter
Rack and produces one portable AGI Model. Approximately one normal minute is
enough for the final native craft; this is compilation/assembly of work already
performed, not another long training countdown. Disable final productivity and
quality rerolls. Do not add a new capital fee or specialized final building.

An existing terrestrial datacenter accepts a ground-only activation recipe
using the delivered Model. Approximately 30 normal seconds at its ordinary
power draw is sufficient. The Model can remain displayed or be returned as its
output. Producing the orbital Model is not victory until ground activation.

Orbital low power slows/pauses normal native crafting. Insufficient cooling
disables/pause-holds the affected cluster. Neither cancels its committed inputs,
resets progress or loses previous completed work. Removing/deleting the machine
still has normal Factorio consequences. Keep the terrestrial ordinary-run
scrapping behavior; this change removes the special finale contract and the
orbital scrapping policy, not every power consequence in the game.

Win qualification requires an earned-compute gate, genuine native orbital Model
completion and genuine native Nauvis activation. Merely possessing/injecting a
Model, transferring stock or modifying item statistics must not win. Handle
immediate output extraction, machine removal, force separation, quality, pause,
save/reload and multiplayer without per-tick whole-world scans or inventory polls.
The ordinary final craft may benefit from quality speed; no special
quality-independent countdown or 90%-buffer requirement remains.

## Epilogue

After persistent victory is recorded, show a short native terminal panel:

```text
You: Okay, can you now solve world peace?

[A blinking cursor for a few seconds.]

Computer: I don't want to.
```

Do not explain the punchline or revoke victory. It is deterministic and offline:
no actual AI service, API credential or paid inference is needed. Make it
skippable/replayable, track per-player acknowledgement, and preserve that state
through reload/join. Do not force multiplayer simulation to pause for each viewer.
Keep the ending out of the public README's marketing copy.

## Cost And Pacing Findings

- Ideal remaining AI/research cash is 21,191 Dollars versus 132,326 under the
  old ending's comparable post-terrestrial window. Prior terrestrial factories,
  research and optional fleet capital are not funded again for free.
- The first cluster uses nine automatic separate-item launches with partial
  minimum requests, including starter, foundation, belts/inserters and cash.
- Twelve clusters fit a paper 1,300-tile single-platform envelope. Batched
  uplifts need 35 rockets; a 1/4/8/12 staged ramp needs 49 before extra top-ups.
  The staged bill contains 4,490 blue circuits, 2,450 rocket fuel and substantial
  steel/copper. The physical recipe and blueprint work must still be tested.
- At 60 effective science sets/minute and 2,000 starting Dollars, partially
  utilized taxi cases finish the ideal-input cash/compute model in about 5.7 h,
  paying for fleets after Autonomy unlocks. More income mostly builds a larger
  cash buffer; it cannot eliminate compute/science work.
- A finite 1,000-battery market can finish in about 10.3 h by skipping
  Hyperscale. With no remaining income, 2,000 Dollars alone cannot finish.
  These closed cases exclude new population/nest growth and new EV generations.
- Hardware alone needs about 3.7/1.2/0.6 h at 20/60/120 spare blue circuits/min.
  Science adds 4,500 more blue circuits. Do not allocate the same production to
  both loads or describe elapsed modeled time as active player time.

The 4-6-hour playable chapter is still a target, not achieved evidence. The
current model is already near that ceiling without build/cargo delays. Prove a
compact first-cluster blueprint and representative manufacturing throughput
before freezing yields or promising the final campaign duration.

## Consecutive Implementation Slices

1. **Reachable orbital entry and uplift:** explicit masses, compact prototypes,
   recipes, cooling ratio, white-science removal, practical starter instructions
   and a native silo-to-platform first-cluster fixture. No direct construction
   or inventory seeding on the platform may stand in for successful uplift.
   **Completed 2026-10-08 on source and the exact ZIP.** Implementation and focused validation are recorded in
   [orbital-entry validation](../docs/orbital-entry-validation.md); this does
   not qualify the pending finale or an entire player campaign.
2. **Banked compute and final Model:** tier values, native earned accounting,
   power/cooling pause-and-resume, physical archive consumption, orbital Model
   output, real cargo-pod return and ground activation. Remove the obsolete
   controller/capital/uninterrupted-run runtime and player guidance.
3. **Ending interface and artwork:** progressive Token/Dataset/Model status,
   concise actionable blockers, native terminal epilogue, satellite-shaped
   core/solar/radiator art and readable filterable icons. No new HUD clutter.
4. **Requalification:** test all relevant qualities, partial loads, real rocket
   ingredients, science consumption, supply interruption/recovery, full output,
   machine removal, persistence and two-force/multiplayer behavior on source and
   the exact ZIP. Run the frozen candidate's native soaks and RC rehearsal.

Update the native catalog after gameplay implementation; do not reuse today's
source hashes or mark old 10 GW validation as proof of the new ending. Resume
the final fresh playthrough only after these changes and release qualification.
