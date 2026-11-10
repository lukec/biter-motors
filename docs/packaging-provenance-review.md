# Packaging And Provenance Gate

Completed 2026-11-10 for the 0.1.1 alpha candidate. No identified packaging or
current media-provenance blocker remains. This is not overall release approval
or an independent legal opinion.

## Exact Candidate

- Archive: `bitermotors_0.1.1.zip`.
- SHA-256: `688922a6e283ce04cdea3ba47a55ca5660f286d31d1ee91cca3575560c17f63f`.
- 24,226,929 bytes; 182 regular entries; 25,241,936 uncompressed bytes.
- Local tested copy: `/tmp/bitermotors-provenance-package/bitermotors_0.1.1.zip`.
- Engine: Factorio 2.1.24 build 87808, mac-arm64, Space Age.
- Build environment: Python 3.15.0, zlib 1.2.12. Pillow 13.0.0 was available
  for static image tests, but packaging and audio synthesis do not require it.

The archive is identified by its hash, not merely its alpha version or filename.
Changing a packaged notice, image, sound or source file requires a new hash and
fresh relevant qualification. Prior practical ending/UI reports retain their
own archive identities; they have not been relabeled as this ZIP's observations.

## Blockers Fixed

1. The filesystem-wide short denylist could include local ignored files or
   external symlink content. Packaging now requires Git-tracked inputs in
   approved runtime path families, detects missing tracked files, and rejects
   unexpected files, symlinks and recognized credential patterns. Staged new
   release inputs are permitted; unrelated repository files never enter the ZIP.
2. Independent archive inspection now rejects traversal paths, backslashes,
   duplicate entries, non-regular entries, unexpected paths, missing notices and
   mismatched per-file hashes. Source-match checks compare every payload byte.
   `PACKAGE-CONTENTS.json` covers every other entry; it is not a signature.
3. The asset notice now explicitly permits complete, unmodified mod installation,
   use and redistribution with notices intact. Standalone asset reuse remains
   reserved; MIT code licensing is unchanged.
4. Older image provenance now includes Luke's explicit confirmation that the
   selected artwork and supplied logo were created together for this project
   and are his to distribute. Historical prompts/tool IDs remain incomplete,
   not fabricated. The packaged `MEDIA-PROVENANCE.md` records the evidence.
5. Two undocumented WAVs were replaced with original mathematical synthesis.
   `scripts/build-bitermotors-audio.py` uses no recordings, samples or external
   audio tools; regression tests reproduce the shipped WAV bytes. Existing
   runtime paths/volume settings are retained. No gameplay balance changed.
6. Default fresh-start/resource runners failed under macOS Bash 3.2 `nounset`
   because optional seed arrays were empty. Their argument arrays are now
   always nonempty, tested both with and without explicit seeds.

The bounded media comparison found no exact binary matches against 13,506 local
game media files. This does not detect transformed copies or independently
establish rights. Current permission evidence and the narrower audit limits are
recorded in [media provenance](media-provenance.md).

## Verification

- Full unit/static suite: **525 tests passed**, with the exact candidate's native
  prototype dump supplied (no dump-dependent skips).
- Negative package tests cover untracked inputs, `.env`, saves, server data,
  credential content, symlinked files/directories, missing tracked inputs,
  traversal paths, duplicates and payload tampering.
- Numeric 1.0.0 metadata/source-folder rehearsal passes in a synthetic release
  fixture. The real candidate remains 0.1.1; this is not a native 1.0.0 run.
- Repeated builds, including a clean Git-index export initialized as a separate
  checkout, produced the candidate hash above with the same toolchain.
- Source native smoke passed at `/tmp/bitermotors-validate.PJd2K1`.
- Exact-ZIP native smoke passed at `/tmp/bitermotors-validate.Mm9MLD`: prototype,
  locale/reference, vehicle and recycling checks plus 18,580 benchmark updates.
- Exact-ZIP default Freeplay bootstrap and resource generation passed. Reports:
  `bitermotors-fresh-start.FqOl6l/script-output/bitermotors-fresh-start.jsonl` and
  `bitermotors-battery-resources.7UG7i5/script-output/bitermotors-battery-resources.json`
  in the macOS temporary directory. The latter sampled seed 1963358693 within
  the existing bounded resource-audit window; not a new three-seed campaign.
- Exact-ZIP mechanical ending passed at `/tmp/bitermotors-finale.Rqf4Ak`,
  including 20,000 Dataset input, Model assembly, return, activation, checkpoints
  across separate process reloads, persistent victory and 2,400 freeplay ticks.
  This fixture supplies construction/research/inputs/power and manually transfers
  some inventories. It is not campaign economics, solar/logistics qualification,
  simultaneous multiplayer, or graphical epilogue acceptance.
- Native runners inspect logs as well as process exit codes. All disposable
  runs stopped; the live game/client/save was not restarted or modified.
- Repository credential-pattern scan and whitespace checks passed. Pattern
  checks are bounded, not a claim that all possible secrets can be recognized.

## Remaining Release Gates

Run the four simulated-hour terrestrial and one simulated-hour multi-platform
orbital candidate soaks, then the settlement scale benchmarks and real
multiplayer/force/lifecycle checks. Finish clean single/multiplayer installation
and an outside player's early-game rehearsal. Use the same exact archive for
those gates, or explicitly rebuild and requalify if a fix changes its bytes.
See [the authoritative roadmap](../ROADMAP.md).
