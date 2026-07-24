# FactoryX MVP

FactoryX is a fictionalized industrial ambition content mod for Factorio 2.1 +
Space Age. This is a clean-break namespace: the mod id is `factoryx`, custom
prototype ids use the `x-` prefix, and no compatibility aliases are retained.
FactoryX is a Nauvis-and-Nauvis-orbit game: the other Space Age planets and
their research branches are deliberately hidden.

With `FactoryX accelerated start` enabled, the first player also finds a red
wreckage chest containing 54 legendary High-density Solar Arrays, 24 legendary
Megapacks, 40 legendary Substations, 20 legendary Roboports, and limited
legendary construction and logistic robots. Nothing is prebuilt. The recovered
cache enables a solar-first opening and a finite logistics network, while the
missing technical archive leaves FactoryX replacements locked behind their
normal research progression.

The MVP loop is intentionally physical:

1. Research Sales Office to unlock the Sales Office, EV Charging Station, and
   `Sell hopes and dreams`.
2. Place a powered EV Charging Station near biter customer settlements.
3. The first covered biter customer charging site unlocks Prototype Roadsters.
4. Craft Prototype Roadsters.
5. Wait for the first active charger stall to print an EV Reservation, then
   belt or bot that paperwork to the Sales Office.
6. Feed one Roadster plus one EV Reservation into `Sell hopes and dreams`, then
   belt Dollars out.
7. Spend first Dollars on EV Production Line research.
8. Sell 50 Prototype Roadsters to prove the premium market.
9. Locate Nickel Ore and Lithium Brine outside the starting area, refine Nickel
   Sulfate and Lithium Carbonate, manage Acidic Tailings, and establish
   High-energy Battery Pack production.
10. Build 100 pilot Premium EVs in ordinary advanced assemblers.
11. Complete the pilot run and research Energy Products to unlock Gigafactory
   Modules and Gigafactory construction together.
12. Convert Dollars plus factory hardware into ten modules, then combine them
    with two Substations to build a 9x9 Gigafactory.
    Placing the first Gigafactory automatically researches Logistic System, so
    requester, buffer, and active-provider chests can feed the large factory.
13. Move Premium EV production into the Gigafactory and use `Sell premium product`.
14. Manufacture 300 kW High-density Solar Arrays and 100 MJ Megapacks in either
    Gigafactory tier.
15. Research EV Charging Network, craft V2 chargers using V1 chargers as recipe
    ingredients, and place the new eight-stall sites. More active stalls increase
    physical EV Reservation output.
16. Research Mass-market EV Production, build a Gigacast, and craft a 9x9,
    30 MW Gigafactory V2 that can fast-replace V1.
17. Use Gigafactory V2's 2x speed and built-in 150% productivity to scale
    Premium or Mass-market EV output efficiently.
18. Research Terrestrial AI and build an 8 MW Terrestrial Datacenter from
    Datacenter Racks and heavy grid infrastructure.
19. Feed 20 Dollars into an 8 MW datacenter to produce 20 AI Tokens every 30 seconds.
20. Spend 1,000 AI Tokens, 1,000 Dollars, and cumulative red-through-yellow science on Autonomous
    Logistics.
21. Use the unlocked toolbar controls to Navigate or Summon Premium,
    Mass-market, Megatruck, and Robotaxi EVs. The Prototype Roadster has no
    Autopilot.
22. Build Robotaxi Fleets in Gigafactory V2 and sell them without EV
    Reservations.
23. Launch vanilla cargo rockets and establish a stationary platform over
    Nauvis. There are no other planetary destinations in FactoryX.

Custom production art now includes footprint-aligned Sales Office and
Terrestrial Datacenter masters, normalized 256 px icon sources, dedicated
technology illustrations, and restrained working visuals for sales, charging,
Gigafactory presses, datacenter cooling, Robotaxi dispatch, and grid charging.
Runtime charger and Service Center lights use one render object per building;
no animation rendering is attached to individual customer units.
24. Research Orbital Compute, build its infrastructure on space platforms, and return
    AI Tokens to the planet.
25. Build a Planetary Energy Grid Controller.
26. Produce Planetary Grid Segments from AI tokens, Megapacks, Satellite
    Buses, and Ground Station Networks.
27. Generate one billion cumulative AI Tokens to unlock AGI Training Run.
28. Package 100 million AI Tokens into 10,000 Training Datasets and 10 million
    Dollars into 1,000 Capital Allocations, then add 10,000 Grid Segments and
    1,000 Megapacks.
29. Sustain the controller's 1 TW draw through a 60-minute training run. Its
    AGI Model output triggers victory and remains in the machine.

## Current Scope

- One economic machine: Sales Office.
- Four demand-infrastructure tiers: 4-stall V1, 8-stall V2, 12-stall V3
  Supercharger, and 20-stall solar-canopy V4 Supercharger.
- Two large vehicle machines: the 9x9, 20 MW Gigafactory and its fast-replaceable
  30 MW V2 upgrade with 2x speed and 150% built-in productivity.
- Physical EV Autopilot controls unlocked by Autonomous Logistics: Navigate an
  occupied EV to a map destination or Summon the nearest available vehicle
  among the player's eight most recently driven EVs. Roadsters are excluded.
- Two placeable energy products: the 300 kW High-density Solar Array and the
  100 MJ, 5 MW Megapack.
- The High-density Solar Array is a native 4x4 solar-panel entity with four
  vanilla panel sprites scaled to 2x2 and tiled edge-to-edge. It keeps
  vanilla solar placement and electric-grid behavior while producing up to
  300 kW on the normal day/night curve.
- Three late machines: Terrestrial Datacenter, Orbital Compute Array, Planetary Energy Grid Controller.
- One science-like late output, AI Token, plus physical Planetary Grid Segments.
- Tangible scale items: Dollar, EV Reservation, Gigafactory Module, and Gigacast.
  One Dollar represents roughly US$10,000 of investable capital in current-dollar terms.
- FactoryX uses vanilla crafting tabs instead of adding a separate tab. EVs sit
  in Logistics/Transport, Energy Products in Production/Energy, launch hardware
  in Production/Space, AI Tokens with science packs, and physical grid outputs
  with FactoryX components. Three named rows
  hold FactoryX infrastructure, components, and capital/contracts.
- A custom steel `X`/gear emblem identifies the FactoryX Progress shortcut; the
  EV Reservation uses a minimal two-sheet approved-paperwork icon that stays
  readable on belts and in small inventory slots. Reservations use the vanilla
  Intermediate Products `raw-material` subgroup so filter selectors expose them
  alongside ordinary physical intermediate items.
- Biters are enemies by default. Biter settlements with both Sales Office and
  powered charger coverage become peaceful customers. Custom hostile enemies,
  market events, and dynamic launch tracking are not implemented yet.

The runtime script handles the first-customer charger milestone, the EV charging
loop, and the MVP victory trigger. FactoryX creates a `factoryx-customers` force.
Enemy spawners inside 128 tiles of a Sales Office become eligible customers and
convert when a reachable powered charging stall serves them; nearby mobile
biters and spitters follow the served settlement. Player forces are friends with
customer biters, while normal enemies outside Sales Office range remain hostile. Worms never convert:
they remain hostile fixed defenses even inside customer territory. Customer
spawners and unsold mobile biters/spitters get a solid `$` marker. Each completed
vehicle sale requires a living mobile buyer, assigns that buyer the vehicle, and
replaces `$` with the vehicle item icon. Sales pause without enough buyers, and
buyer selection favors the least-loaded covered settlements. Owner death removes
the vehicle from the active fleet while preserving lifetime sales statistics.
FactoryX does not cap or cull customer populations. Friendly non-owners use an
engine-native green tint and hostile units retain their normal appearance.
Owners become explicit baked unit prototypes across all eight biter/spitter
forms: Roadster red, Premium black, Mass-market white, and Robotaxi gold. Future
Megatruck variants are reserved as silver. Existing owners migrate gradually;
per-owner Lua car-icon render objects are no longer used.
Customer mobile units have old hostile commands cleared when they convert, so
an attack order issued by the enemy force cannot survive customer conversion.
If a customer unit nevertheless damages player infrastructure, its command is
immediately reset to non-combat wandering.
Charging Stations can be placed anywhere, but they are inactive until they are within 18
tiles of a friendly electric grid pole. Holding or selecting a Sales Office shows
its 128-tile customer conversion radius; holding or selecting a charging
station shows its tier-specific stall demand radius. The mod creates a hidden grid
connection pole at powered stations so the power grid can wire to the site
without making the station itself open the power-network GUI. Unpowered
stations stay in place, remove any hidden grid tap, and show Factorio's native
flashing no-power alert. Logistic-network coverage is optional and never gates
charging, power draw, or paperwork production. Holding a charger item shows
electric coverage, hides logistics coverage, and restores the previous overlay
settings afterward. Selecting a station also opens a small FactoryX info
panel with grid status, customer settlements in charger range, nearby hostile
spawners that are not customers yet, active stalls, power draw, reservation rate,
active EV Sales Offices, and the next step. The first powered station that
covers biter customers unlocks Prototype Roadsters for the first
Sales Office recipe, `Sell hopes and dreams`. A v1 charger has 4 stalls; each
covered biter customer settlement creates one potential stall and each active
stall draws 50 kW. Successive generations serve 12, 20, 32, and 50 EVs per
stall, giving total site capacities of 48, 160, 384, and 1,000 EVs. V2 has 8
stalls, 96-tile range, and draws 150 kW per active stall, up to 1.2 MW. V3 has
12 stalls, 128-tile range, and draws 250 kW per active stall, up to 3 MW. V4
has 20 stalls, 160-tile range, and draws 500 kW per active stall, up to 10 MW.
Each active stall prints one EV Reservation per minute into the
charger's one-slot output inventory. Inserters can always extract it; logistic
bots can also collect it when a network happens to cover the charger. Chargers
outside logistic coverage do not show the no-network warning. Prototype, Premium, and Mass-market EV
sales each consume one reservation. Robotaxi fleets do not: their constraint is
the substantial capital required to create the fleet.

Customer friendliness requires Sales Office coverage and reachable powered
charging capacity. Each settlement with living owners requests one stall.
Delivered grid power proportionally determines how many requested stalls work.
Low power, charger removal, and overload strand only affected settlements. They
remain friendly for three minutes, then have gradually rising 5%-25% periodic
chances to become hostile. Restored powered service makes them friendly
immediately. Affected settlements show a flashing entity alert until service
returns; disruption, recovery, and routine settlement growth stay out of chat.
Cars do not permanently occupy stalls. Active stalls
accumulate adoption; five active stall-minutes can grow one new customer spawner
when the charger has a spare stall. Every grown settlement has a 25%, 50%, or
75% chance of an evolution-scaled worm as evolution rises; any worm remains on
the hostile enemy force. Growth is bounded
by the local charger's stall count, and the station panel reports mood, stranded
EVs, spare settlement capacity, and progress toward the next settlement.
Reservations are never teleported into Sales Offices. Before the first sale, a
reachable unsold buyer provides a one-reservation-per-minute bootstrap signal.
Afterward, only living assigned owners create occupied stalls, charging draw,
and stall-rate reservations. Unsold inventory does not count. One billion
cumulative AI Tokens unlocks a 1 TW, 60-minute AGI Training Run in the
Planetary Energy Grid Controller. Its AGI Model output marks the game won.

The Sales Office technology also unlocks a `Sales Office Coverage` shortcut.
It toggles dark teal, translucent 128-tile coverage circles in map and Remote View for
the current player's force. These overlays use chart-only rendering and do not
appear over normal gameplay.

The always-available `FactoryX Progress` shortcut opens a movable status window.
It derives one concrete next objective from live technologies, infrastructure,
customer settlements, sold EVs, charger utilization, physical paperwork,
sales milestones, Energy Products, datacenters, and victory state. It also shows
Dollar production, market throughput, infrastructure counts, and completed
progression stages. `/factoryx-status` opens or refreshes the same window for a
player and prints the current objective when called through RCON.

Autonomous Logistics adds `Navigate EV` and `Summon nearest recent EV` to the
toolbar. Navigate is available only while driving a Premium EV, Mass-market EV,
Megatruck, or Robotaxi. Select one tile in map or Remote View; the vehicle
physically follows an asynchronous path and the seated player can cancel with
any steering, acceleration, or braking input. Summon chooses the nearest
unoccupied, same-surface vehicle among the player's eight most recently driven
eligible EVs and parks about six tiles away. It requires at least 10% battery,
cancels at 3%, and aborts on no route, nearby hostiles, occupancy, disconnect,
or a surface change. The controller is capped at 32 active vehicles and never
scans the inactive EV fleet.

Selecting or opening a Sales Office adds a FactoryX diagnostics panel with its
customer count, selected contract, cycle progress, exact input and output
inventory counts, machine state, and first concrete bottleneck. Both Gigafactory
tiers expose the same recipe diagnostics plus rated power demand and V2's
speed and built-in productivity. Selecting a biter or spitter spawner opens a
Customer Settlement Inspector with market coverage, charger assignment, active
and free stalls, network capacity, and the exact reason it is hostile. Research completions, first important placements, and
first Prototype, Premium, and Mass-market sales print concise next actions.

`Sell hopes and dreams` is intentionally slow: one Prototype Roadster plus one
EV Reservation takes 60 seconds to return 2 Dollars of profit. The first completed sale prints the next step:
research EV Production Line. That technology costs Dollars plus red, green, and
blue science for 250 cycles, then unlocks high-nickel refining, High-energy Battery Packs, electric drivetrains,
Premium EVs, and `Sell premium product`. The first 100 Premium EVs are built in
ordinary advanced assemblers; completing that pilot run and researching Energy
Products unlocks Gigafactory Modules and construction together. Each production module consumes
10 Dollars, 5 Assembling Machine 2s, 5 Labs, and 50 Refined Concrete. Ten
modules plus two Substations build the Gigafactory. Premium EV
sales consume one EV Reservation, take 30 seconds, and return 1 Dollar. Mass-market EV Production unlocks the Gigacast and
Gigafactory V2. A Gigacast consumes Electric Furnaces, Steel, Electric Engines,
and Dollars; Gigafactory V2 consumes the original Gigafactory, one Gigacast,
and Dollars. V2 draws 30 MW, runs twice as fast, has 150% built-in productivity,
and can be placed directly over V1. Both tiers include advanced crafting, so a
Gigafactory can manufacture Gigafactory items as well as its vertically
integrated supply chain.
Both Gigafactory tiers have eight module slots. Productivity modules are
restricted to intermediate products; finished vehicles, fleets, Solar Arrays,
and Megapacks reject them. A curated vertical-integration category lets either
tier manufacture circuits, Low Density Structures, and FactoryX component
subassemblies without turning the building into an unrestricted assembler.
Only V2 can assemble Mass-market EVs. A Mass-market EV sale consumes one EV and
one EV Reservation, produces 1 Dollar of profit, and takes 5 seconds. The first
completed premium product sale prints the next scale target: EV Charging Network
and mass-market EVs.

Every Sales Office recipe uses a product-first icon with a small gold coin badge,
so the recipe chooser shows what is being sold rather than seven identical
Dollar icons.

Energy Products follows EV Production Line and unlocks High-density Solar
Arrays, Megapacks, and Megapack sales. Both Gigafactory tiers
can build the energy products. The solar recipe consumes four Solar Panels, Processing Units, Low
Density Structures, and Dollars. Megapacks consume LFP Battery Packs, Accumulators,
and a Substation; they can be placed on the grid or sold through `Sell Megapack`.
The first placed Gigafactory automatically researches base-game Logistic System.
This deliberately bypasses Space Age's later space-science gate because the
large terrestrial factory is the point where requester-chest logistics becomes
part of the FactoryX production loop.

Existing playtest saves also get the milestone on config sync if Factorio's
production statistics show that a Prototype Roadster was already consumed.
The EV Charging Station recipe uses a Substation, Accumulators, and Concrete.
The Substation already includes the power electronics, heavy conductors, and
steel enclosure, so those raw ingredients are not repeated. FactoryX recipes
generally use two to four distinct subsystem inputs and rely on quantities,
power, craft time, and throughput for difficulty.

Terrestrial AI is intentionally completed before the launch branch. It requires
Mass-market EV Production, Energy Products, and Processing Units, but no space
science or satellite technology. Its large 6x6 datacenter consumes 20 Dollars,
draws 8 MW, and produces 20 AI Tokens per 30-second cycle. AI Tokens stack to
1,000,000. Separate terrestrial and orbital efficiency tracks unlock at 1K,
10K, 100K, 1M, 10M, and 100M generated Tokens; each researched level costs
Dollars plus science and adds 10% output without raising cycle inputs. Autonomous
Logistics consumes 1,000 AI Tokens, 1,000 Dollars, and cumulative
red-through-yellow science. It requires terrestrial Logistic Robotics rather
than Space Age's space-gated Logistic System technology. Robotaxi
Fleets consume four Mass-market EVs, four Autonomy Computers, and 100 Dollars;
they can only be assembled in Gigafactory V2. Selling three Robotaxi items takes
3 seconds, returns 1 Dollar of profit, and consumes no EV Reservation, for
sustained throughput of one Robotaxi per second.
The first completed fleet sale enables the V4 Supercharger and Small Orbital
Launch; both remain unavailable before that terrestrial milestone.

## Validation

Current validation state, 2026-07-10:

- Factorio 2.1.9 with Space Age enabled loads the mod with `--dump-data` from
  an isolated temp config and mod directory.
- `python3 -m unittest tests.test_factoryx_mod` passes: 50 tests.
- A disposable benchmark smoke save ran 3780 updates with a temporary helper mod
  and verified zero utilization before EV sales, force-wide sold-fleet-capped
  mixed V1/V2 utilization, native per-stall power sinks,
  Gigafactory Premium and Mass-market EV selection, one-minute physical EV
  Reservation generation in the charger output,
  the one-billion-token AGI unlock, and AGI Model victory.
- The benchmark also sells three Robotaxi items without an EV Reservation,
  verifies the 1-Dollar profit output, and verifies that the sale enables Small
  Orbital Launch.
- `scripts/validate-factoryx-gui.sh <save.zip>` loads a disposable copy of an
  existing player save and verifies that the progress, Sales Office, and
  Gigafactory GUI panels are created and the runtime-unlocked Prototype
  Roadster recipe is restored. It also runs the progression-integrity repair and
  verifies that no researched FactoryX recipe remains disabled. The rendered
  Dollars value must match the save's lifetime Dollar output statistic.

Use an isolated mod directory for engine checks so normal saves and the live mod
list are not touched.

From the repo root, run the full isolated check with:

```sh
scripts/validate-factoryx-mod.sh
```
