# Recycling And Salvage Validation

Date: **2026-10-06**. Release plan **Phase 2 recycling/salvage slice complete**:
R08/R11 addressed; Phase 2 and the final playthrough gate remain open.
Engine: **Factorio 2.1.20, build 87512, mac-arm64, Steam, Space Age**.
Mod: **Biter Motors 0.1.1**, fresh-world alpha contract.

This is historical slice evidence, not the current package hash. The later
[economy/guidance evidence](economy-guidance-validation.md) separates the
recovered 39 Dollars from business profit (zero) and corrects the accounting
regression's historical 113-Dollars profit label to 100 genuine profit Dollars.

## Changes

- Track all 18 rewritten vanilla recipes in `prototypes/recipe_recycling.lua`.
  After final fixes, use the installed upstream Recycler generator to rebuild
  their reverse recipes from the real forward ingredients. Remove stale aliases
  and old unlocks; keep exactly one unlock per reverse recipe. Do not mutate the
  upstream generator's captured unlock table by replacing that table.
- Correct furnace/drill/Foundry/recycler, Tesla weapons/ammo, Stack Inserter,
  all four tier-3 modules, personal Roboport MK2, Battery MK3, cliff explosives,
  and artillery reverses. No Tungsten, Holmium, Supercapacitors, eggs, or other
  removed-planet products remain in these rewritten inverses.
- Keep vanilla 25% expected recovery and normal quality behavior, without reverse
  productivity. Integer outputs are exact; fractional extras are native random
  rolls, not a promise that four crafts yield exactly one extra item. See the
  official [item-product definition](https://lua-api.factorio.com/latest/types/ItemProductPrototype.html#extra_count_fraction).
- Disable automatic self-recycling on both damaged-pack items. Partial batches
  wait; ten damaged high-energy/LFP packs return exactly 36 matching cells in
  the existing 20-second recipe, without productivity or extra pack hardware.
- Both Premium recipes share one vehicle item. Neither destruction path guesses
  chemistry from current research: both return only generic body scrap. Roadster
  and eSpider salvage are similarly conservative. Mass-market returns four LFP
  packs; Megatruck/Cybertrain each return eight high-energy packs; Bitertaxi
  destruction/actual depot retirement returns sixteen LFP packs.
- Actual player-vehicle destruction produces one body wreck plus known packs,
  preserving quality. Statistics record actual dropped quantities. Depot pack
  output now also records positive production flow, but its natural retirement
  duration is not qualified by this short fixture.
- Remove advanced-pack generation from anonymous charger incidents; lifetime
  sales do not identify the wrecked vehicle. Their old occasional generic body
  wrecks remain tied to paperwork printing, not to a specific owner retirement.
  Customer replacements/deaths do not fabricate advanced packs either.
- Mining returns the reusable vehicle without additional body/pack salvage.
  Clear hidden drive charge before native player/robot mining as well as from
  their event buffers. A real construction bot had carried five hidden charge
  items into storage before this fix; the native regression now requires zero.

## Verified Evidence

| Check | Result | Evidence boundary |
| --- | --- | --- |
| Python suite | 167 tests pass | Existing suite plus negative prototype and runner-wiring contracts; not a full campaign. |
| Source/exact-ZIP final prototypes | 176 checks each | All 18 approved forward/inverse pairs, 25% expected output, unique unlocks, no reverse productivity, quality policy, both 90% routes, no damaged-pack fallback. |
| Source/exact-ZIP native fixture | 52 policy + 480 world assertions | 18 normal reverse recipes, one rare reverse, four battery recovery cases, and eleven salvage/mining cases. No balance/prototype overrides. |
| Incremental feeding | Pass | Both chemistries first run an ordinary automatic recipe, then preserve each partial batch 1-9 before the tenth produces exactly 36 cells. |
| Rare quality | Pass | Rare drill recycling keeps rare ingredients; both rare damaged-pack routes produce exactly 36 rare cells. No quality modules installed. |
| Shared Premium provenance | Pass | Actually craft one Premium from each unmodified recipe and consume their real ingredients; each placed/destroyed result produces one generic wreck and zero advanced packs. |
| Known vehicle destruction | Pass | Native Mass-market, rare Megatruck, Bitertaxi, eSpider, and rare Cybertrain deaths reconcile physical body/pack outputs with statistics. Not a full manufacturing chain for all classes. |
| Collision/mining | Pass | One low-health moving Roadster hits a wall; native entity mining, script removal, and real bot deconstruction do not duplicate salvage. This is not a collision-balance sign-off or a connected-player mining test. |
| Real persistence | Pass | Server saves at tick 3,480; separate engine reload checks at 3,510 retain nine unconsumed packs and completed case state. |
| Source/exact-ZIP accounting regression | Pass | 39 policy + 26 native + 3 reload assertions; manufacturing 259, genuine Roadster sales 50, profit 113, preserved through reload. |
| Source/exact-ZIP customer regression | Pass | 63 policy + 134 world + 9 reload + 12 configuration-change assertions; mixed history and virtual-only persistence remain intact. |
| Source/exact-ZIP broad smoke | Pass | Existing native smoke plus the new final-recycling checker; not an earned orbital ending. |

Fixture seed: **1062028**. Temporary cleared terrain, power, research, and item
inputs are setup. Premium recipe availability is explicitly enabled during its
manufacturing/salvage tests; genuine progression gates are independently covered
by accounting/customer fixtures. Actual recipe ingredients, durations, machine
speeds, output quantities, and recycling rules are unchanged. `game.speed = 100`
accelerates wall-clock simulation, not recipes. No completion counts, recovered
items, or earned statistics are injected to make this fixture pass.

The runner checks ordered reports, explicit completed case counts, minimum
assertions, all engine logs, a real server-written checkpoint, and advancing
reload ticks. It stages the current source or a source-matching ZIP, binds a
temporary loopback server, and stops only its own PID. **No live server, desktop
client, installed symlink, or player save was modified or restarted.**

## Exact Tested Archive

Archive: `bitermotors_0.1.1.zip`. SHA-256:

```text
1e6340778d24a0a9e78d7e0abccb97b8a860963c458826b444949316cf648d55
```

Temporary evidence is excluded from Git and may expire:

- Package: `/tmp/bitermotors-phase2-recycling-release/bitermotors_0.1.1.zip`
- Source recycling: `/tmp/bitermotors-recycling.dYBdgs/`
- Exact-ZIP recycling: `/tmp/bitermotors-recycling.gQr1XJ/`
- Source accounting: `/tmp/bitermotors-accounting.yQpbAO/`
- Exact-ZIP accounting: `/tmp/bitermotors-accounting.PODIKu/`
- Source customer lifecycle: `/tmp/bitermotors-customers.v9hu2r/`
- Exact-ZIP customer lifecycle: `/tmp/bitermotors-customers.CmkjJ5/`
- Source broad smoke: `/tmp/bitermotors-validate.jGCkSd/`
- Exact-ZIP broad smoke: `/tmp/bitermotors-validate.1nOuFd/`

Rebuild after packaged code/changelog changes; version 0.1.1 alone does not
identify tested bytes. The roadmap and validation reports are not packaged.

## Reproduce

From the repository root with a licensed Factorio 2.1.20 installation:

```bash
python3 -m unittest discover tests
scripts/validate-bitermotors-recycling.sh
scripts/validate-bitermotors-accounting.sh
scripts/validate-bitermotors-customers.sh
scripts/validate-bitermotors-mod.sh
python3 scripts/package-bitermotors.py --output-dir /tmp/bitermotors-recycling-release
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-recycling-release/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-recycling.sh
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-recycling-release/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-accounting.sh
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-recycling-release/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-customers.sh
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-recycling-release/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-mod.sh
```

`FACTORIO_BINARY` and `FACTORIO_READ_DATA` override the default macOS Steam paths.
The prototype checker can also inspect an existing final engine dump directly.

## Remaining Gates

**R09/R10** were subsequently fixed and qualified in the
[charging/service slice](charging-validation.md), completing Phase 2. Its report
identifies the newer archive and reruns of this recycling regression. Phase 3 owns physical
orbital delivery and full final training. Later qualification must cover natural
taxi attrition, larger worlds, connected players, and long-running service.

Also track recovered capital separately from business profit in **R12**. This
fixture recovers **39 Dollars** from tier-3 modules, with zero customer sales;
the Progress panel reports those same 39 as profit. Sale gates remain closed,
but that label must be made economically honest before the design freeze.
