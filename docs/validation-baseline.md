# Current Engine Validation Baseline

Date: **2026-10-05**. Release-plan **Phase 1 complete**; the mod remains alpha.
Engine: **Factorio 2.1.20, build 87512, mac-arm64, Space Age**.
Mod: **Biter Motors 0.1.1**. Both engine dependencies require **2.1.20**.

All engine checks used isolated temporary user/mod directories. The installed
mod-list and links were not rewritten; no server/client was restarted and no
player save was changed. The existing client development symlink points at this
checkout, so its next load will use the source updates automatically. The only
gameplay prototype change is the schema correction for four hidden drive-charge
items; campaign accounting and endgame contracts are still Phase 2/3 work.

## Verified Evidence

| Check | Result | Evidence boundary |
| --- | --- | --- |
| Python suite | 147 tests pass | Static contracts, simulator/artifact checks, and validator failure fixtures; not a complete campaign. |
| Source engine smoke | Pass, without a shim | Final prototype dump, new-world create/save/reload, and existing native smoke assertions. |
| Exact-archive engine smoke | Pass, without a shim | Same engine checks using the ZIP below, with byte-for-byte current package/source matching. |
| Fresh-start validator | Source and exact archive pass | Headless bootstrap research, map settings, and configured recovery cargo; not a player opening/mining every wreck. |
| Battery resource validator | Source and exact archive pass | Nickel, lithium, and uranium generate within 1,024 tiles in the tested worlds; not five-seed balance qualification. |
| Native soak harness checks | 600 and 601 requested updates pass | Observed spans 599 and 600 ticks; complete cadence and independent 120/121-update timing runs. The second case includes a terminal periodic-probe boundary. |
| Scale harness check | Pass with 128 registered owners | 0/16 moving-unit caps, 120 updates, and a final-tick sentinel; all 16 commanded movers moved. Not a 20k stress result. |
| Ad-hoc saved-world timing | 120 updates complete | Only timing/log sanity; this tool intentionally does not qualify game-time duration. |
| GUI validator | Rejects unsuitable input | The CLI-created fixture has no player 1. No GUI or in-game visual acceptance pass is claimed. |
| Bitertaxi runtime validator | Wiring/syntax checked only | Needs an appropriate isolated customer/player fixture before its engine pass is claimed. |

The broad smoke requests **18,580 updates** and reaches its verified victory
and completion sentinel at **game tick 18,540**. Winning stops subsequent game
time even though Factorio reports the requested updates. This is a logical
smoke pass, **not** 18,580 ticks of advancing simulation or proof of the full
final training run. It injects milestones and an AGI Model; it does not earn,
deliver, and train the real final payload.

The soak checks instead require the whole observed game-time span. Both runs
must have unique initial/final sentinels, normal engine completion, all requested
updates, complete timing rows, and every expected probe/error field. Negative
fixtures cover zero-exit Lua errors, paused/short game time, missing or duplicate
sentinels/probes, intermediate remote failures, malformed/truncated reports,
incomplete timing data, and failed processes. Stale same-version, wrong-version,
extra-file, and duplicate-entry archives are rejected when matching a checkout.

## Exact Tested Archive

Archive: `bitermotors_0.1.1.zip`

SHA-256:

```text
b3eda623be4bd71f023d9b300d33c046bff4455ce38fab56c60801c638d3891a
```

Local evidence, deliberately excluded from Git:

- Archive: `/tmp/bitermotors-phase1-release/bitermotors_0.1.1.zip`
- Final archive validator log: `/tmp/bitermotors-phase1-final-archive-validation.log`
- Final native soak artifacts: `/tmp/bitermotors-phase1-final-soak/`
- Scale CSV: `/tmp/bitermotors-phase1-scale.csv`

These temporary artifacts may expire. Rebuild and revalidate after any package
change; a version number alone does not identify the tested bytes.

## Reproduce

From the repository root:

```bash
python3 -m unittest discover tests
scripts/validate-bitermotors-mod.sh
python3 scripts/package-bitermotors.py --output-dir /tmp/bitermotors-phase1-release
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-phase1-release/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-mod.sh
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-phase1-release/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-fresh-start.sh
BITERMOTORS_MOD_ARCHIVE=/tmp/bitermotors-phase1-release/bitermotors_0.1.1.zip \
  scripts/validate-bitermotors-battery-resources.sh
```

The main validator prints its isolated directory; its created smoke save can
be used for a **harness-only** check:

```bash
scripts/soak-bitermotors-save.sh \
  --profile terrestrial --save /path/to/isolated/saves/bitermotors-smoke.zip \
  --ticks 601 --timing-ticks 121 --sample-ticks 100 --warmup-ticks 10 \
  --output-dir /tmp/bitermotors-phase1-final-soak
```

## Still Required

Proceed with Phase 2's authoritative production/sales/profit accounting and
behavioral customer/recycling fixtures. Phase 3 must prove the real orbital
delivery and full-duration victory contract. Player-bearing GUI/landing checks,
large-world stress, four-hour terrestrial and one-hour orbital soaks, and
multiplayer/persistence qualification remain outstanding. Do not start the
final acceptance playthrough until Phases 1-6 of the
[v1 plan](v1-readiness-review.md) pass.
