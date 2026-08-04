# Biter Motors Battery Chemistry Branch

## Status And Direction

Implemented in Biter Motors 0.1.0 and revised after the first Premium EV
playtest. The values below are the initial playtest balance rather than a
proposal; future changes should preserve both the progression and the audited
material-loop constraints.

This is the proposed terrestrial battery branch for the Biter Motors refocus.
It replaces the generic `Battery Pack` supply chain with two real chemistry
families. Removing the old SpaceX products, technologies, and runtime paths is
a separate implementation slice.

The branch distinguishes chemistry from manufacturing:

- High-nickel and LFP are cathode chemistries.
- Cell-scale manufacturing and dry electrodes improve production recipes.
- Structural packs improve vehicle integration; they are not new chemistry.

Tesla uses nickel-rich NCA/NCM cells for higher-energy applications and LFP
for lower-energy applications. Its published long-term plan similarly assigns
LFP to standard-range vehicles and high-nickel chemistry to long-range uses.

References:

- [Tesla 2021 Impact Report](https://www.tesla.com/ns_videos/2021-tesla-impact-report.pdf)
- [Tesla Master Plan Part 3](https://www.tesla.com/ns_videos/Tesla-Master-Plan-Part-3.pdf)
- [Tesla Roadster battery description](https://service.tesla.com/docs/Public/Roadster/Original/1.2.5/battery/descriptionandoperation.html)

## Progression

| Existing gate | Battery change |
| --- | --- |
| Prototype Roadster | Continues using ordinary Batteries, representing purchased commodity cells. |
| EV Production Line + 50 Roadster sales | Unlocks Electric Drivetrains and an expensive Premium EV pilot recipe using 48 conventional Batteries per vehicle. Nickel, lithium, and engineered cells are not available yet. |
| 100 Premium EV pilot | Proves the product and unlocks Biterfactory Modules and Biterfactory construction. |
| Biterfactory V1 | Scales the commodity-cell Premium EV line. Producing 250 Premium EVs makes Advanced Battery Chemistry researchable. |
| Advanced Battery Chemistry | Unlocks nickel and lithium extraction, dirty refining, High-Nickel Cells, High-Energy Battery Packs, cell-scale High-Nickel Manufacturing, and a faster cell-scale Premium EV recipe. |
| Energy Products | Builds on Advanced Battery Chemistry and unlocks LFP chemistry and LFP Battery Packs for Grid Batteries. |
| Capital Scaling / Biterfactory V2 | Unlocks clean refining and dry-electrode recipes with lower acid, waste, power and craft time. |
| First chemistry-specific battery scrap + Recycling | Makes Battery Material Recovery researchable. It does not auto-complete the research. |

After the 50-Roadster market gate, the Progress panel first asks for a
100-Premium-EV pilot using conventional Batteries. That pilot unlocks
Biterfactory construction. The player then scales the same constrained
commodity-cell line to 250 produced Premium EVs. Only after factory scale
exposes the supply bottleneck does the panel ask the player to research
Advanced Battery Chemistry, extract both minerals, refine both precursors,
produce High-Nickel Cells, and switch the Premium EV line to High-Energy
Battery Packs.

When an older Biter Motors save loads this progression, configuration migration
revokes the chemistry recipes that EV Production Line used to unlock. The
recipes remain disabled until Advanced Battery Chemistry is researched, so old
saves follow the same 100-vehicle Biterfactory and 250-vehicle chemistry
transitions as new saves.

Premium EV production milestones use a persistent monotonic lifetime counter,
not Factorio's resettable production-stat window directly. On first observation
or after a statistics reset, Biter Motors reconciles the lower bound from completed
Premium EV sales plus surviving stocked and placed vehicles. It stores the
offset from native statistics so later production continues from the repaired
lifetime total without recurring full-factory scans.

Mass-Market EVs and Bitertaxis use LFP packs. Premium EVs and Megatrucks use
high-energy packs. Megatrucks use a purpose-built steel chassis rather than
embedding completed LFP vehicles.

## Resources And Items

Only two new natural resources are added to Nauvis:

- `Nickel Ore`: solid drill-mined patches.
- `Lithium Brine`: pumpjack fields.

Lithium Brine uses uranium's ordinary 1.25 patches/km2. Nickel is a mainline
manufacturing input, so it uses 2.0 expected patches/km2 at 1.25 base density
instead of uranium-like 1.25 patches/km2 at 2.0 density. Expected total nickel
remains roughly unchanged, but it is distributed across more, smaller deposits
and is less vulnerable to a bad map seed. Both resources begin their
regular-resource fade-in at 240 tiles instead of uranium's 300, without a
guaranteed starting-area patch.

Existing resources supply the rest: coal becomes Battery Graphite, stone
becomes Phosphate, and iron supplies LFP cathodes. Early nickel refining emits
a small Cobalt Concentrate byproduct. Both initial cell routes consume that
cobalt so choosing the Biterfactory recipe cannot jam dirty refining. Later
clean refining and dry-electrode cells remove cobalt from the flow. Both
natural resources must appear in map preview and be generated on new Biter Motors
worlds. No save migration is required.

New logistics items are Nickel Sulfate, Lithium Carbonate, Battery Graphite,
Cobalt Concentrate, Phosphate, High-Nickel Cells, LFP Cells, High-Energy
Battery Packs, LFP Battery Packs, and one damaged-pack item per chemistry.
Acidic Tailings is a fluid. Packs stack to 20; cells and refined powders stack
to 100.

## Implemented Recipes

Quantities are balance targets for the first implementation pass.

| Recipe | Inputs | Outputs | Time |
| --- | --- | --- | ---: |
| Dirty nickel refining | 10 Nickel Ore + 100 Sulfuric Acid | 4 Nickel Sulfate + 1 Cobalt Concentrate + 200 Acidic Tailings | 10 s |
| Lithium extraction | 100 Lithium Brine + 5 Calcite | 4 Lithium Carbonate + 100 Acidic Tailings | 10 s |
| Battery graphite | 5 Coal | 2 Battery Graphite | 5 s |
| Phosphate extraction | 10 Stone + 50 Sulfuric Acid | 4 Phosphate + 100 Acidic Tailings | 8 s |
| Tailings neutralization | 100 Acidic Tailings + 2 Calcite | 2 Stone | 5 s |
| High-nickel cells (Chemical Plant) | 4 Nickel Sulfate + 1 Lithium Carbonate + 2 Battery Graphite + 1 Cobalt Concentrate | 4 High-Nickel Cells | 8 s |
| High-nickel cells (Biterfactory) | 4 Nickel Sulfate + 1 Lithium Carbonate + 2 Battery Graphite + 1 Cobalt Concentrate | 5 High-Nickel Cells | 6 s |
| Commodity-cell Premium EV pilot | 1 Car + 48 Batteries + 2 Electric Drivetrains + 10 Advanced Circuits | 1 Premium EV | 30 s |
| Cell-scale Premium EV | 1 Car + 8 High-Energy Battery Packs + 2 Electric Drivetrains + 10 Advanced Circuits | 1 Premium EV | 20 s |
| LFP cells (Chemical Plant) | 2 Lithium Carbonate + 4 Iron Plates + 2 Phosphate | 4 LFP Cells | 6 s |
| LFP cells (Biterfactory) | 2 Lithium Carbonate + 4 Iron Plates + 2 Phosphate | 5 LFP Cells | 5 s |
| High-Energy Battery Pack | 4 High-Nickel Cells + 4 Steel Plates + 2 Advanced Circuits | 1 pack | 8 s |
| LFP Battery Pack | 4 LFP Cells + 4 Steel Plates + 2 Electronic Circuits | 1 pack | 6 s |

Biterfactory V2's clean recipes are capped at these yields:

- 10 Nickel Ore + 75 Sulfuric Acid -> 5 Nickel Sulfate + 50 Acidic Tailings.
- 100 Lithium Brine + 4 Calcite -> 5 Lithium Carbonate + 25 Acidic Tailings.
- 10 Stone + 40 Sulfuric Acid -> 5 Phosphate + 25 Acidic Tailings.
- Dry high-nickel and LFP recipes produce 6 cells from the same inputs used by
  their 5-cell scale recipes. They reduce craft time but not mineral inputs.

Vehicle and energy-product pack counts after Advanced Battery Chemistry:

- Premium EV cell-scale recipe: 8 High-Energy Battery Packs. The earlier pilot
  recipe remains available as an expensive fallback so existing assemblers and
  saves retain their selected recipe.
- Mass-Market EV: 4 LFP Battery Packs.
- Megatruck: 1 Car + 40 Steel Plates + 8 High-Energy Battery Packs +
  2 Electric Drivetrains.
- Bitertaxi Fleet: inherits 16 LFP packs through its four Mass-Market EVs.
- Grid Battery: 12 LFP Battery Packs + 4 Accumulators + 1 Substation.

Chemistry effects stay attached to vehicle classes, not individual customer
records. Premium and Megatruck customers go roughly 50% longer between
charges. LFP Mass-Market EVs charge somewhat more often but retire at roughly
one-third the high-nickel attrition rate. Bitertaxis inherit the LFP retirement
benefit. The existing drivable-vehicle battery counts continue to provide the
player-visible range differences without another per-vehicle chemistry script.

## Ninety-Percent Battery Recycling

Ninety percent means active cell-material recovery, not recovery of the entire
vehicle bill of materials:

```text
10 Damaged High-Energy Battery Packs -> 36 High-Nickel Cells
10 Damaged LFP Battery Packs         -> 36 LFP Cells
```

Ten original packs contain 40 cells; 36 recovered cells can rebuild nine
packs. The player must still supply fresh steel and electronics for all nine.
Chassis, drivetrains, circuits, quality bonuses, Dollars and science are never
created by battery recovery.

Vehicle retirement produces damaged packs according to the packs embodied in
that vehicle class. The existing Wrecked EV remains chassis salvage. Killing
customer biters does not drop battery scrap; scheduled vehicle retirement,
Bitertaxi attrition, charger-generated end-of-life events, and destruction of a
player-owned EV are the supported sources. This prevents deliberate customer
farming from accelerating the recycling loop.

The two chemistries remain separate through recycling. LFP scrap cannot become
high-nickel cells, and high-nickel scrap cannot become LFP cells.

## Recipe Richness Audit

- The commodity-cell pilot consumes 48 conventional Batteries per Premium EV.
  One hundred vehicles therefore require 4,800 Batteries, making the old
  sulfuric-acid, iron, and copper supply chain a visible scale bottleneck.
- A dirty High-Energy Pack uses one complete early cell batch: 10 Nickel Ore,
  25 Lithium Brine and 5 Coal, plus 4 Steel Plates and 2 Advanced Circuits for
  its enclosure and battery management. Nickel mining/refining and tailings
  treatment remain the dominant chemical cost.
- An LFP pack avoids nickel, cobalt, graphite and red circuits. It still needs
  25 Lithium Brine, iron and phosphate for four cells, plus 4 Steel Plates and
  2 Electronic Circuits for pack hardware. It is cheaper, not free.
- Cell-scale recipes improve cell yield by 25%. Clean refining plus cell-scale
  manufacturing improves cells per ore by about 56% over the dirty process;
  the branch does not reach a 2x material multiplier.
- Battery refining, precursor, tailings-treatment, cell, and pack recipes allow
  productivity because they produce physical intermediates. Pack recipes cap
  total productivity at 10%; combined with 90% cell recovery, that can rebuild
  at most 99% of the original packs and cannot create a positive material loop.
  Recovery recipes remain non-productive. Finished vehicles, Grid Batteries, and
  other final products continue to reject productivity.
- Recycling recovers exactly 90% of cells in ten-pack batches and zero fresh
  electronics, steel or vehicle parts. No probabilistic output can
  round recovery above 90%.
- Tailings treatment is a disposal cost. It does not return acid, nickel or
  lithium, so dirty refining cannot form a positive material loop.
- Tailings neutralization consumes two Calcite per 100 fluid. This keeps dirty
  chemistry materially expensive without making Calcite logistics dominate the
  branch: one early High-Energy Battery Pack requires about 5.75 Calcite in
  total, versus roughly 1.1 after clean refining and dry-electrode production.

## Implementation Slices

1. Add map resources, dirty refining, high-nickel cells and Premium EV packs.
2. Add LFP cells, LFP packs, Grid Battery and mass-market recipe conversion.
3. Add chemistry-specific damaged packs and deterministic 90% recycling.
4. Add clean refining, cell-scale and dry-electrode recipes.
5. Remove the superseded SpaceX branch and rebalance the terrestrial endgame.

Each slice requires prototype-load tests, recipe ownership/category tests, a
raw-material balance fixture, and an engine test proving that ten recycled
packs can rebuild nine packs but never ten.
