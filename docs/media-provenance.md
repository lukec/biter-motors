# Biter Motors Media Provenance

## Scope And Evidence Limits

Read-only media audit on 2026-11-10 of the working source for version 0.1.1:
137 PNG files (including the thumbnail) and two WAV files under the mod directory.
This includes unused or historical images still packaged, not only assets
currently referenced by prototypes. This documentation audit did not modify
media; the release owner subsequently replaced both WAVs on the same date, as
recorded below.

The packager includes this document as `MEDIA-PROVENANCE.md` beside
`ATTRIBUTION.md`, `ASSET-LICENSE.md`, and `LICENSE`. The archive's generated
`PACKAGE-CONTENTS.json` records per-file SHA-256 hashes. Those hashes identify
bytes, not authors, sources, or permission. Repository links below are optional
supporting evidence; the findings and permission limits are stated here so a
package recipient does not need repository-only files to read them.

## Audio: Reproducible Replacement

Both shipped files are uncompressed mono PCM, 16-bit, 22,050 Hz:

| Packaged path | Bytes | Duration | SHA-256 |
| --- | --- | --- | --- |
| `sound/ev-drivetrain-loop.wav` | 88,244 | 2.00 s | `abcd2d99111e1dc2fac84acca01c3fe62be93862400a5443c7ef073ffbeb61db` |
| `sound/ev-reverse-warning.wav` | 31,796 | 0.72 s | `01e665277145ec779641e559a72e37ab82391a0e0b4454c08cc2146a720580d8` |

On 2026-11-10 the release owner replaced both older WAVs using the original
[audio synthesis script](https://github.com/lukec/biter-motors/blob/main/scripts/build-bitermotors-audio.py).
It uses only Python's standard-library `math`, `struct`, and `wave` for audio
creation: no recordings, samples, or external audio tools. The drivetrain
combines 180/540/1080/2160 Hz sine oscillators with amplitude modulation; the
reverse warning combines 660/990 Hz oscillators with two soft pulse envelopes.
Both current PCM payloads were checked against the script's generated samples.
Each file has a 44-byte WAV header, with no inherited `LIST` metadata.

The script is the reproducible source for the current audio, resolving the
earlier source/permission gap without relying on the undocumented older files.

### Superseded Audio Evidence

The following concerns the replaced files only, not current shipped bytes:

- [Commit 6459c14](https://github.com/lukec/biter-motors/commit/6459c14ac3fce9664627f6f4a490e2aa2901f4ca),
  dated 2026-07-12, introduces both binary files, vehicle sound wiring, reverse
  warning playback, and wiring tests. It does not include an audio generator,
  source recording, attribution, or permission record.
- Before replacement, following file history through namespace moves and
  comparing the original blobs confirmed both older WAVs were byte-identical
  to that introduction.
- Each older RIFF file contained `fmt `, `LIST`, and `data` chunks. Its `LIST/INFO/ISFT`
  field says `Lavf62.3.100`; there is no author, source URL, or license field.
  Encoding-software metadata does not distinguish synthesis from converted
  recordings and does not establish rights.
- The initial review of repository scripts, docs and audio-related history
  found no reproducible synthesis recipe, original recording, named supplier,
  or third-party license for the older files. Wiring tests demonstrated wiring, not
  origin or permission. A short loop or warning tone is not proof of synthesis.

The superseded drivetrain was 88,278 bytes, SHA-256
`1c2f6f4b3368b6400b74b84605d4c348fe329233b2415e30ec0b8a314f76b957`;
the superseded warning was 31,830 bytes, SHA-256
`860543c2dac8f801d69a9c6d4dcba86b42054a001baf5fe0cb155340f010f0d0`.
Their origins remain historically undocumented; no third-party copying was
established. They are no longer shipped and are not covered by the current
audio's synthesis claim. This historical gap is not a current clearance blocker.

## Image Sources And Derivatives

The available evidence varies by family; retained source pixels and deterministic
processing are not, by themselves, proof of original authorship.

**Owner confirmation, 2026-11-10:** Luke Closs explicitly confirmed that the
older selected artwork and `BiterMotors.png` were created together for this
project and were his to distribute. This is the project's ownership/distribution
evidence for those sources and their derivatives, not an inference from file
names or an independent legal attestation. Missing older prompts, tool/version
IDs and intermediate source records remain historical metadata gaps, not
unresolved current permission requirements.

| Shipped family | Available project evidence | Limits |
| --- | --- | --- |
| Five road-vehicle body/shadow sheets, vehicle icons and showroom derivatives | Editable Blender models, geometry/render scripts, retained masters and packing scripts. | Scripted geometry and render pipeline are inspectable; this review records project evidence, not independent legal attestation. |
| Cybertrain, charging stop and battery/material icons | Battery/Cybertrain Blender scene builder, retained models/renders, and battery-art packer. | Clean-process icons are a separate raster-source family, not evidence of Blender generation. |
| Sales Office, terrestrial datacenter, AGI Model | Retained final masters; masters README records built-in image generation, reference choices and chroma-key extraction. | Some references were earlier selected project sprites; their complete earlier generation/source chain is not recorded there. |
| Orbital datacenter core, radiator and space solar, matching icons | Detailed generation record dated 2026-11-10, three retained transparent masters, deterministic crop/resize code. | Record reports no reference images and no exposed model/version ID. It is a project generation record, not a legal copyrightability determination. |
| High-density terrestrial solar and grid battery | Retained transparent raster sources, deterministic normalization/shadow code, and owner confirmation for older selected project art. | Source-specific historical generation metadata is incomplete; owner confirmation supplies distribution evidence. |
| Remaining building sprites, component/product icons, clean-process and upgraded icons | Retained selected concepts, icon sources and later raster masters; normalization/composition scripts, introduction commits and owner confirmation for older selected project art. | Per-source generation requests and reference chains are incomplete. Do not infer a specific generation method or model for every raster. |
| Technology images, status/activity overlays, showroom animation | Pillow construction/composition code drawing indicators and combining project rasters. | Source-family historical metadata limits carry through to derivatives; owner confirmation covers the older selected project artwork. |
| Thumbnail and group branding | Commit `b3d2fff` records derivation from `BiterMotors.png`, then held in Downloads; Luke confirmed project creation and distribution rights on 2026-11-10. | The full-resolution source was not retained in that commit. This retention gap is distinct from the now-recorded owner confirmation. |

Repository evidence (not required at runtime):

- [Blender family sources and README](https://github.com/lukec/biter-motors/tree/main/art/blender)
  and [vehicle packer](https://github.com/lukec/biter-motors/blob/main/scripts/build-bitermotors-vehicle-sprites.py).
- [Battery art packer](https://github.com/lukec/biter-motors/blob/main/scripts/build-bitermotors-battery-art.py)
  and [general art builder](https://github.com/lukec/biter-motors/blob/main/scripts/build-bitermotors-art.py).
- [Retained masters and generation notes](https://github.com/lukec/biter-motors/tree/main/art/bitermotors-masters)
  and [icon sources](https://github.com/lukec/biter-motors/tree/main/art/bitermotors-icon-sources).
- [Orbital generation/crop record](https://github.com/lukec/biter-motors/blob/main/docs/orbital-art-provenance.md):
  three 1254x1254 RGBA generated sources cropped by alpha, resized to 480 visible
  pixels wide on 512x512 transparent entity canvases; matching 256x256 icons.
- [Brand introduction](https://github.com/lukec/biter-motors/commit/b3d2fff21a86c1ced2a9298c41db969a12ec2adb),
  [retained master/icon pipeline](https://github.com/lukec/biter-motors/commit/93b64371bdf171208ad4419b4df0cd6e922c8f3f),
  [clean-process icons](https://github.com/lukec/biter-motors/commit/5f7331ad5f14021d5813ee608ba2e01253aa54f8),
  and [replacement icon sources](https://github.com/lukec/biter-motors/commit/f2fb3bfddee22e94187039d7a3dc7388371170e0).

## Wube And Other Third-Party Media

The Lua references game-installed media using `__base__` and `__space-age__`
paths and inherits media via copied game prototypes, including
the eSpider's tinted Spidertron body. These runtime references are distinct from
shipping those image/audio binaries. Biter Motors does not grant rights to
Factorio or Space Age assets or trademarks.

Before the audio replacement, the 139 shipped media files were compared by byte
length and SHA-256 against all 13,506 PNG/JPEG/WAV/OGG media files found in the
local Steam Factorio data tree. There were **zero exact binary matches**.
The inspected art builders read project raster/render sources; no direct copy
from a Wube media path was identified in those builders.

This does not detect resized, recolored, re-encoded, composited or otherwise
transformed copies. It does not compare against other game versions, every
third-party mod, online libraries, or unavailable original sources. Historical
art QA pages can be stale and are not proof of current runtime wiring or origin.

**No confirmed Wube or third-party binary-copying blocker was found in this
bounded audit.** With the documented audio replacement and owner confirmation,
no unresolved current media-clearance blocker is identified. Incomplete historic
generation metadata remains distinct from current distribution evidence. Do not
equate absence of a binary match with a warranty of non-infringement. No external
rights are granted by attribution.

## Permission Boundary

`ASSET-LICENSE.md` permits installation/use and redistribution of the complete,
unmodified Biter Motors package, with its notices intact, to the extent the
licensors hold the rights. Standalone asset reuse remains reserved. `LICENSE`
covers source code/documentation separately under MIT. Project policy for
AI-generated output is not a legal determination of copyrightability. Current
project clearance rests on the recorded owner confirmation and reproducible
sources, not an independent legal attestation or complete historical metadata.
