# Premium EV Blender Study

The black Premium EV is a distinct long-wheelbase four-door fastback built on
the same Factorio orthographic camera and lighting conventions as the Prototype
Roadster.

```sh
/opt/homebrew/bin/blender --background \
  --python art/blender/premium-ev/render_premium_ev.py
```

The script produces a transparent master, 64 directional frames, and an
editable `.blend`. Direction frames remain generated local output until the
vehicle family is approved and packed into Factorio sprite sheets.
