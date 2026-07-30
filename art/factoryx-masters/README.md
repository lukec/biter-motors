# Biter Motors Generated Masters

These three production masters were generated with the built-in image-generation
tool, extracted from flat chroma-key backgrounds, and retained here at source
resolution. The mod consumes derived 512 px entity sprites and 256 px icons.

## Sales Office

- Final: `final/sales-office.png`
- Reference: the previous selected Sales Office sprite.
- Prompt: re-render the same compact automated EV showroom and sales kiosk with
  its orange awning, display window, cash conveyor, terminal, pipes, and roof
  equipment. Use a centered orthographic three-quarter Factorio-like camera,
  align the square slab to both tile axes, make a 3x3 footprint inferable, fill
  88-94% of the canvas, light from upper-left, and use a flat magenta chroma
  background. No floor, cast shadow, text, people, vehicles, or diagonal base.

## Terrestrial Datacenter

- Final: `final/terrestrial-datacenter.png`
- Reference: the previous selected Terrestrial Datacenter sprite.
- Prompt: re-render the terrestrial AI datacenter with dense server halls, blue
  status lighting, rooftop cooling, transformers, conduits, intake and exhaust
  equipment, and a concrete foundation. Use a centered orthographic
  three-quarter Factorio-like camera, align a broad 6x6 foundation to both tile
  axes, fill 88-94% of the canvas, light from upper-left, and use a flat green
  chroma background. Avoid a narrow tower, diagonal base, city backdrop, people,
  vehicles, cast shadow, text, and excessive neon.

## AGI Model

- Final: `final/agi-model.png`
- References: the current AI Token and Planetary Grid Controller.
- Prompt: create one physical manufactured AGI Model artifact: a dense
  black-and-silver computation core containing a contained gold neural lattice,
  seated in a rugged transport frame with visible data buses and cooling. Use a
  centered three-quarter orthographic Factorio-like item camera, strong silhouette
  at 64 px, upper-left key light, restrained cyan indicators, and a flat green
  chroma background. Avoid text, brains, faces, robots, coins, holograms, floating
  orbs, cast shadows, and excessive bloom.

## Deterministic Derivatives

Run:

```bash
scripts/build-factoryx-art.py
scripts/build-factoryx-art-qa.py
```

The first command derives normalized icons from immutable files in
`art/factoryx-icon-sources/`, technology illustrations, and small animation
overlays without image generation. The second rebuilds the static QA index at
`art/factoryx-qa/index.html`. Both builders are deterministic and idempotent.
