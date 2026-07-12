# Prototype Roadster Blender Study

This is the first FactoryX vehicle-model pipeline test. It produces a
transparent 768 px master and 64 deterministic directional renders from one
Blender scene.

The production pass uses a high overhead orthographic camera, weathered paint,
warm industrial lighting, added panel and underbody detail, and separate
shadow-only frames. The packing script softens and offsets those shadow frames
into `prototype-roadster-shadow.png` for Factorio's shadow render layer.

Run:

```sh
/opt/homebrew/bin/blender --background \
  --python art/blender/prototype-roadster/render_prototype_roadster.py
```

Review:

- `renders/prototype-roadster-master.png`: transparent high-resolution master.
- `renders/prototype-roadster-direction-qa.png`: eight directions plus UI-scale
  previews.
- `prototype-roadster.blend`: editable source model, materials, lights, and
  orthographic camera.

The individual directional frames are generated locally and ignored. The
deterministic packing step builds the body sheet, shadow sheet, and final icon.
