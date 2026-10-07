# Economy And Guidance Validation

Date: **2026-10-06**. **Phase 4 first slice implemented; design freeze remains open.**
Engine: **Factorio 2.1.20, build 87512, mac-arm64, Steam, Space Age**.
Mod: **Biter Motors 0.1.1**, fresh-world alpha contract.

No prices, research ingredients, power output, compute yields, or unlock gates
are rebalanced in this slice. No player save, installed link, live server, or
desktop client was modified or restarted. Existing development links naturally
load changed source at the next load; they were not rewritten.

## Implemented

- `runtime/progress_guidance.lua` multiplies native technology ingredient
  amounts by actual research-unit counts. Progress uses those costs, including
  AI Token research, and a normal orbital core's actual 1.5 crafting speed.
  Its 30-second recipe runs in 20 seconds before further effects.
- Optional Foundry, Megatruck, charger/solar placement, and Bitertaxi work no longer
  appear as mandatory orbital blockers or incomplete Autonomy-stage criteria.
  Their real research/production gates are unchanged. Foundry is described as
  a non-starter deployment milestone, not a functioning-grid qualification.
  Solar/storage products remain recommended power options, not mandatory placed
  entities if the existing grid sustains compute. Final recipes still require
  their physical Grid Battery Array ingredients.
- `runtime/business_income.lua` records native Sales Office recipe completions
  and actually delivered scripted service/audio income per force. Progress
  displays that profit; positive Dollar production remains a separate statistic.
  Recycling, supplied inventory, and arbitrary statistics injection do not
  create business profit. No old private-alpha profit ledger is reconstructed.
- The economy simulator reads `economy-prototypes.json`, captured from final
  engine prototypes and the read-only `economy_contract` runtime interface.
  Capture hashes cover the raw dump, runtime JSON, and unchanged Lua/manifest
  source. Export rejects changed/stale inputs instead of attaching today's
  source hash to an unverified dump. Model execution rejects stale source.
- The model counts research compute, consumed versus deployed storage, the
  extra payload batch required after labs spend Tokens, ordinary AI retry cash,
  and finite EV/battery adoption. It caps taxi revenue by unique customers and
  the actual 200-vehicle runtime depot limit, not its 43 inventory slots.
- The [static artwork index](../art/bitermotors-qa/index.html) now includes 27
  critical records, all five EVs, both compute/power tiers, depot, rail hardware,
  eSpider, Dataset, and Model. It records actual PNG/frame dimensions and stable
  review IDs, rejects missing files, and bounds large animation previews.
  Inherited/tier reuse and identical orbital cooling/solar art remain labeled.

## Verification

| Check | Result | Evidence boundary |
| --- | --- | --- |
| Python suite | 219 tests pass | Static contracts, model mutations, capture failures, artifact/index checks; not a campaign. |
| Native broad smoke | Source and exact ZIP pass | Includes genuine Grid Battery/fleet sales and delivered scripted depot income; generic production and business profit agree when all earnings are business income. |
| Native accounting | Source and exact ZIP pass | 51 executable policy/guidance, 35 native-world, 5 separate-process reload assertions. 50 actual Roadster sales earn 100 profit Dollars; 13 additional positive-flow Dollars remain other production. |
| Native recycling | Source and exact ZIP pass | 52 policy, 482 native-world, 27 reload assertions. Real recycling recovers 39 Dollars; business profit stays zero. |
| Normal research/throughput | Native snapshot passes | Autonomy costs 750 Dollars; Orbital research costs 1,500 Tokens; normal orbital cycle is 20 seconds. The multiplier case is an executable helper policy test, not a campaign with altered difficulty settings. |
| Economy sensitivities | 19 tests pass | Mutated prototype costs/speeds/output/power change results; stale capture, cycles, invalid workloads, finite adoption, overlapping depots, and retry costs fail or reconcile correctly. |
| Artwork index | 27 records, supporting inventories | Deterministic generation and file/frame checks. No native scale, day/night, sound, item-picker, or GUI fit acceptance is claimed. |

The broad smoke now checks grace/recovery on the fixture's owned settlements,
not every distant unrelated nest. A first run failed because an unowned remote
settlement had older independent anger; both affected owned settlements remained
friendly. Unrelated anger is not hidden from runtime reporting. The focused
charging fixture remains the authority for deliberate grace-to-anger transitions.

## Balance Findings And Limits

See the reproducible [economy report](economy-balance.md), not a total-campaign
forecast. Normal quality, no modules, zero research productivity, and zero
capital-recovery credit are conservative assumptions. Intrinsic Biterfactory
productivity can reduce construction costs; exploration, chemistry/science
throughput, building, combat, rockets, and cargo congestion are unmeasured.

- Direct cash: **134,836 Dollars**, including **2,260** for pre-orbital research
  compute and **50,000** in final Capital Allocations. Forgone battery sales are
  an opportunity cost, not another cash bill or guaranteed realizable profit.
- Solar-only 10 GW finale: **4,762 Tandem Arrays**, **1,001 deployed Grid Battery
  Arrays**, and **110 additional consumed arrays**. Panel recipes have no Dollars.
- Closed 5/10/20-settlement markets with 200 living customers each have finite
  EV-plus-battery ceilings of **24k/48k/96k Dollars** before taxi service.
  Native population/nest growth and optional Megatruck sales are excluded.
- Two/four fully allocated depots provide roughly **11.9k/23.7k net Dollars/h**,
  after conservative initial fleet wear; cash payback is approximately **43 min**.
  These are mature, financed-network sensitivities, not natural startup timings.
- The finale's capital alone takes **4.2 h** of two-depot income. The final
  compute band takes about **6.25 h with 8 normal cores**, **3.13 h with 16**.
  Test targeted capital sizing and practical compute expansion against the
  proposed 2-3-hour major-step cadence before freezing values.

**Still open:** intended pacing/budgets; actual material/build/logistics workload;
R15 distinct radiator/space-solar placed art and other minimum-matrix readability;
all-item locked filterability and descriptions; supported-scale native UI review;
spoiler-light frozen campaign contract; Phases 5-8 qualification/publication.
The final acceptance playthrough must still wait for Phases 4-6.

## Exact Tested Archive

`bitermotors_0.1.1.zip`, SHA-256:

```text
30bf8a0496b480227ec503914e0f6c0e81fe3d37f24df49ef4d43a30d0a85bb9
```

Temporary evidence, excluded from Git and subject to expiry:

- Package: `/tmp/bitermotors-phase4-release/bitermotors_0.1.1.zip`
- Source broad/capture: `/tmp/bitermotors-validate.AQ2GQa/`
- Source accounting: `/tmp/bitermotors-accounting.snW93P/`
- Source recycling: `/tmp/bitermotors-recycling.dqOhGN/`
- Exact-ZIP broad: `/tmp/bitermotors-validate.51gGmK/`
- Exact-ZIP accounting: `/tmp/bitermotors-accounting.1TwMH3/`
- Exact-ZIP recycling: `/tmp/bitermotors-recycling.5gCwuo/`

## Reproduce

```bash
python3 -m unittest discover tests
scripts/validate-bitermotors-mod.sh
scripts/validate-bitermotors-accounting.sh
scripts/validate-bitermotors-recycling.sh
python3 scripts/package-bitermotors.py --output-dir /tmp/bitermotors-phase4-release
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-phase4-release/bitermotors_0.1.1.zip scripts/validate-bitermotors-mod.sh
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-phase4-release/bitermotors_0.1.1.zip scripts/validate-bitermotors-accounting.sh
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-phase4-release/bitermotors_0.1.1.zip scripts/validate-bitermotors-recycling.sh
```

The economy report documents capture/export/model regeneration. Its compact
catalog, unlike ephemeral saves/logs, is deliberately versioned input data.
