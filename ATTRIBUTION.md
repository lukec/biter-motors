# Attribution

## Biter Motors

Biter Motors source code is released under the MIT License. Original Biter
Motors artwork and media are covered by `ASSET-LICENSE.md`.
That license expressly permits installation, use, and redistribution of the
complete, unmodified package, while reserving standalone media reuse. It grants
only rights the licensors hold; it does not license third-party game assets.

## Shipped Media Evidence

The packaged `MEDIA-PROVENANCE.md` contains the image-source audit, audio hashes
and history, owner confirmation, and historical metadata limits. Its repository version is
[media provenance](https://github.com/lukec/biter-motors/blob/main/docs/media-provenance.md).
`PACKAGE-CONTENTS.json` in the release archive inventories packaged file hashes;
hashes establish file identity, not permission or authorship.

Two WAVs ship: `sound/ev-drivetrain-loop.wav` and
`sound/ev-reverse-warning.wav`. On 2026-11-10 the older, undocumented WAVs were
replaced with original mathematical oscillator synthesis from
[the reproducible audio builder](https://github.com/lukec/biter-motors/blob/main/scripts/build-bitermotors-audio.py).
The builder uses Python's standard library, with no recordings, samples, or
external audio tools. The current WAVs match that generator; their hashes and
superseded-file evidence are recorded in `MEDIA-PROVENANCE.md`.

On 2026-11-10 Luke Closs explicitly confirmed that the older selected artwork
and `BiterMotors.png` were created together for this project and were his to
distribute. This owner confirmation and the reproducible audio replacement
leave no unresolved current media-clearance blocker identified by this review.
Incomplete historical generation metadata remains documented, not presented as
an outstanding permission requirement or independent legal attestation.

## Electric-vehicle inspiration

The project was inspired in part by the gameplay idea and implementation
direction of the MIT-licensed [Electric Vehicles Factorio mod](https://mods.factorio.com/mod/electric-vehicles).

This attribution records inspiration, not a claim that code or media from
Electric Vehicles is incorporated here. The current shipped WAVs are generated
by the project's oscillator script, not sourced from that mod. The review did
not establish that mod as the source of the superseded WAVs either.

## Factorio and Space Age

Biter Motors is a mod for Factorio and Space Age by Wube Software Ltd. Factorio
and Space Age media referenced through game asset paths or inherited prototypes
are loaded from the user's game installation, not licensed by Biter Motors.
Users must obtain and use the game under Wube's terms. The bounded binary audit
found no exact matches between shipped media and local game media; that is not
a guarantee against transformed copies or unidentified third-party material.

## Development tools

The three compact orbital entity rasters and matching icons were generated
with OpenAI's built-in image-generation tool on 2026-11-10, then normalized
with Pillow, as recorded in the repository's
[orbital art provenance](https://github.com/lukec/biter-motors/blob/main/docs/orbital-art-provenance.md).
The packaged `MEDIA-PROVENANCE.md` provides a self-contained summary; the
repository-only link supplies requests, retained sources, and crop mappings.

The repository uses Python's standard library and Pillow for development-time
art checks, and Blender for scripted vehicle/battery renders. Those tools are
not bundled into the Factorio mod archive and keep their own licenses.
