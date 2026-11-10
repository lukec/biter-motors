# Fresh-world seed audit

Native audit completed 2026-11-09 on Factorio 2.1.24 (build 87808, mac-arm64, Steam Space Age). All six existing-script invocations passed; no blockers.

## Scope and provenance

- Disposable new worlds only, each script/seed in a separate directory under `/tmp/bitermotors-seed-audit-20261109/<seed>/<fresh|resources>/`.
- No original world touched. No live client/server operations. No production mod changes.
- Preserves the existing resource fixture bounds: origin-centered square from (-1024,-1024) to (1024,1024), a 2048-tile side, **not** a 1024-tile side or a radial circle. Native area-query boundary semantics apply.
- This is generation/bootstrap evidence, not a human route, accessibility, mining, throughput, combat-survival, or full-campaign qualification. No human-route claim.
- Source: `mod/bitermotors_0.1.1`, version 0.1.1; checkout `e42f0aca6aa863159ff64b68e854bd183bd03a82`.
- Source SHA-256: `29b4442ed589220df330ec3af48b37ad983753e0be1ef691d25b6041514d15de` (174 files; sorted relative POSIX path + NUL + file bytes + NUL).
- Engine binary SHA-256: `991c1182742f60cde97be2a412106670f73ba483fd1715a95e687b73c8b5250d`.
- [Machine-readable results](fresh-world-seeds.json) retain active-mod versions, source/engine identity, exact local artifact directories, and report/log/save SHA-256 values. Distances below are rounded to 0.001 tile; report hashes identify the full-precision originals. Temporary artifacts are not committed and may later be removed.

## Results

Each cell is **nearest / count / total amount**. Distance is Euclidean from (0,0); resource count means native resource entities, water count means water-collision tiles, and spawner count means enemy-force unit spawners. Amount is the sum of native `entity.amount` (not extracted oil yield or obtainable product). Water and spawners have no resource amount, represented as null in JSON.

| Observation | 1092026 | 424242 | 8675309 |
| --- | ---: | ---: | ---: |
| iron-ore | 40.626 / 10367 / 48465646 | 56.925 / 15312 / 73422130 | 40.651 / 9203 / 40519990 |
| copper-ore | 43.134 / 7671 / 35918007 | 29.707 / 9064 / 33417619 | 28.504 / 8384 / 38054687 |
| coal | 39.655 / 5996 / 28102726 | 28.504 / 10927 / 67112265 | 76.515 / 8571 / 47745489 |
| stone | 36.090 / 5489 / 28460062 | 42.030 / 5801 / 24279439 | 70.289 / 5483 / 25046320 |
| crude-oil | 262.154 / 65 / 32043565 | 540.447 / 27 / 13881947 | 251.182 / 70 / 32162894 |
| calcite | 35.756 / 1207 / 12307031 | 56.943 / 1181 / 10969106 | 59.435 / 325 / 1664408 |
| bitermotors-nickel-ore | 347.509 / 1858 / 7261416 | 384.472 / 1906 / 9981136 | 256.040 / 2148 / 11211665 |
| bitermotors-lithium-brine | 603.417 / 42 / 21278065 | 410.537 / 62 / 31467581 | 451.339 / 88 / 39459448 |
| uranium-ore | 425.749 / 2184 / 9779984 | 611.811 / 4061 / 18199787 | 339.288 / 2541 / 13681609 |
| water | 47.424 / 1371511 / n/a | 43.829 / 723738 / n/a | 48.083 / 689018 / n/a |
| enemy-spawners | 193.733 / 624 / n/a | 213.632 / 537 / n/a | 176.835 / 550 / n/a |

Fresh-start bootstrap: **PASS / PASS / PASS**. Expanded resource fixture: **PASS / PASS / PASS**. Legacy nickel/lithium/uranium fields and assertions remain checked.

All three resource reports show `peaceful_mode=false`, `enemy_base_frequency=1`, `enemy_expansion=true`, and `pollution=true`. The fixture only generates/scans the real mod world; it neither fabricates deposits nor disables enemies. The observed spawners confirm actual generation alongside resources, not just enabled settings. This does not test subsequent combat behavior.

## Reproduction and checks

`BITERMOTORS_SEED` accepts decimal uint32 values 0 through 4294967295 (leading zeros allowed); an explicitly empty, signed, whitespace-padded, fractional, nondecimal, or out-of-range value fails before engine launch. When unset, the existing random-seed behavior remains. `TMPDIR` chooses the parent of a new unique disposable directory. Only the seed is supplied in map-gen settings; production autoplace defaults remain intact.

Run each script for each of 1092026, 424242, and 8675309, with separately created TMPDIR parents:

```sh
BITERMOTORS_SEED=1092026 TMPDIR=/tmp/my-audit/1092026/fresh scripts/validate-bitermotors-fresh-start.sh
BITERMOTORS_SEED=1092026 TMPDIR=/tmp/my-audit/1092026/resources scripts/validate-bitermotors-battery-resources.sh
```

Verification: 7 focused tests in `tests/test_fresh_world_seeds.py`, 11 existing validator-contract tests, shell syntax checks, and `git diff --check` passed. Resource validation rejects missing evidence, absent resources/spawners, invalid distances/counts/amounts, seed mismatch, disabled enemy settings, and inconsistent legacy fields. Both scripts retain shared source staging and engine-log error gates.

The complementary [dependency audit](progression-dependency-audit.md) checks
research and manufacturing reachability; neither check replaces the final
non-sandbox acceptance campaign.
