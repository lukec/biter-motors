# Battery Chemistry And Cybertrain Art

`render_battery_cybertrain.py` creates the teal high-nickel and orange LFP icon
families, material and fluid icons, damaged battery packs, the Cybertrain
charging-stop icon and four-direction placed structure, and a deterministic
64-direction Cybertrain model.

Rebuild the source renders and packed game assets with:

```sh
blender --background --python art/blender/battery-cybertrain/render_battery_cybertrain.py
python3 scripts/build-bitermotors-battery-art.py
python3 scripts/build-bitermotors-art-qa.py
```

Directional frames are reproducible and ignored. The editable `.blend`, icon
masters, Cybertrain master, packed sprites, and game-ready icons are tracked.
