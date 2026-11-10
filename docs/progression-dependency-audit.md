# Mandatory Progression Dependency Audit

2026-11-09. Static, qualitative dependency evidence; **not runtime proof**.
Production Lua/prototypes are unchanged by this audit.

## Reproduce

```sh
python3 scripts/check_progression.py /path/to/data-raw-dump.json
BITERMOTORS_PROTOTYPE_DUMP=/path/to/data-raw-dump.json python3 -m unittest tests.test_progression_audit
```

Input used: full native `data-raw-dump.json` from
`/tmp/bitermotors-validate.FQQEhT/script-output/`, SHA-256
`f874322ec1c36876f85cbeddb797cf728b54df9e9f10cad1426b406c06922d4c`.
Do not substitute the smaller economy catalog: vanilla recipes, technology,
labs, resource categories and crafting machines are required.

Result: mandatory path through physical Model assembly, return and activation
is reachable in 18 fixed-point passes. Closure: 257 items/fluids, 278 recipes,
214 technologies, 23 crafting/mining/lab machines. No mandatory dependency
blocker found under the assumptions below. Optional unreached technologies do
not fail this check; this is not a requirement to finish the entire tech tree.

## Algorithm And Boundary

Read the literal bootstrap technology, ship, debris and energy-jumpstart tables
from `control.lua`; nonexistent historical technology aliases are ignored.
Initial stock means available, not renewable or unlimited. Use only resource
entities listed in native Nauvis map generation (including calcite, nickel and
mod Lithium Brine), not all resources from all Space Age planets. Mining needs
a reachable compatible drill/pumpjack and any required mining fluid. Water
requires an offshore pump. No alien-planet mineral or asteroid stock is seeded.

Iterate resource extraction, machine placement, manual runtime edges, research
and recipes to a monotone fixed point with an explicit finite iteration bound.
Research needs prerequisites, every science ingredient, and a reachable lab
accepting all of them. Recipes need all inputs, an enabled/unlocked route and a
reachable machine with overlapping native `categories`/`crafting_categories`;
fluid recipes cannot be hand-crafted. Check surface conditions against Nauvis
and Nauvis orbit only; orbital surface conditions become available only after
the platform trigger is reachable. Exclude all `bitermotors-smoke*` helper recipes.

The required targets cover sales, pilot and cell-scale Premiums, Biterfactory,
Mass-market, terrestrial compute, orbital Dataset tiers through Grid-scale,
cooling/solar hardware, assembly and activation, plus transitive prerequisites
of Grid-scale, autonomous logistics and space-platform. The solver may observe
other reachable recipes/technologies but does not require optional branches.

## Explicit Manual Runtime Rules

These edges are **manually transcribed from source**, not inferred from the
prototype JSON or demonstrated by this Python execution:

| Gate | Source / dependency modeled |
| --- | --- |
| Bootstrap | `BITERMOTORS_START_*`, `BITERMOTORS_ENERGY_JUMPSTART_ITEMS`, accelerated Freeplay start |
| First Roadster | `first_prototype_sale_unlocked`, charging/customer service and `sync_force_unlocks`: Sales Office research, buildable office and V1 charger; assume powered coverage of operational customer settlements |
| Reservations | Customer prospect/office reservation-printing logic: assume prospects and sufficient active office capacity once service hardware is available |
| Premium | `EV_SALES_GATES`, `sync_ev_sales_recipe_gates`: 50 completed Roadster sales plus Premium research |
| Biterfactory | `sync_biterfactory_production_gate`: Premium research plus **100 manufactured** Premiums |
| Advanced chemistry | `sync_advanced_battery_chemistry_gate`: **250 manufactured**, not sold, Premiums; then normal research/science |
| Mass-market | `EV_SALES_GATES`: Capital Scaling plus **250 sold** Premiums |
| Orbital tiers | `ORBITAL_AI_MILESTONES`: 1M / 10M / 100M native earned equivalents enable Cluster / Grid-scale / Hyperscale research |
| Model | `sync_agi_training_unlock`: 1B cumulative earned equivalents plus Grid-scale research; assembly needs physical Datasets and Rack |
| Return/activation | `AgiCompletion`, native completion/cargo callbacks: genuine orbital assembly, return through hub to Nauvis landing pad, native ground datacenter activation |
| Space-platform | Native `create-space-platform` research trigger: reachable silo, rocket parts and starter pack; not assumed researched at bootstrap |

Counts are repeatability assumptions: a reachable native recipe can eventually
complete 50/100/250 times or generate the earned threshold. The audit records
these as `manual_runtime_gates`; it does not inject runtime counters. Higher
orbital tiers are proven after the previous Dataset route; Hyperscale remains
optional. A landing-pad item plus assembly is the explicit abstract return edge,
not proof that a real rocket/hub/pod moved the Model.

## Evidence And Limits

Native three-seed bootstrap/resource checks and full-mod and
accounting checks already passed. Those are separate evidence, not rerun or
claimed as results of this script. See the fresh-world audit and existing native
ending/accounting validators for engine qualification.

This does not simulate quantities, finite initial-stock exhaustion, resource
patch distances, mining throughput, energy, heat, pollution/combat, settlement
population growth, prospect eligibility, office scheduling, cargo weights,
rocket/pod slots, actual surface transfer or native completion provenance.
Craft/build triggers use qualitative availability; unknown triggers remain
blocked. Surface filtering is existential and does not track item location or
machine/recipe co-location. Machine fluid-box presence is checked, not individual
filters, ports or capacities. Initial quality is collapsed. Native callbacks and
manual-rule/source drift still require engine tests and review. No claim of a
complete fresh human campaign or general Factorio simulator is made.

Regression tests reject circular science, missing inputs, missing machines,
incompatible lab science and smoke-helper supply. Full-dump mutation tests also
reintroduce a tungsten ingredient on the orbital core and verify activation is
blocked, remove the terrestrial datacenter, and create a Model/science cycle.

Verification: all 10 audit tests passed with the full native dump, including
negative mutations; the existing 112 `tests.test_bitermotors_mod` tests passed.
`git diff --check` passed. Native engine validators were not rerun for these
Python/documentation-only additions.
