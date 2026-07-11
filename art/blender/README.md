# FactoryX Blender Vehicle Family

The FactoryX vehicle family now has editable Blender studies and deterministic
64-direction renders for:

- Prototype Roadster: red, compact, low two-seat sports car.
- Premium EV: black, long-wheelbase grand tourer.
- Mass-market EV: white, practical liftback.
- Cybertruck: silver, oversized faceted pickup.
- Robotaxi: gold, compact autonomous passenger pod.

`vehicle_common.py` owns the shared camera, lighting, geometry helpers, wheel
construction, transparent rendering, and directional export used by the final
three models. The Roadster and Premium EV predate that extraction but use the
same visual setup.

Each model folder contains its editable `.blend`, render script, transparent
master, and direction/scale QA sheet. Individual directional frames are
reproducible local output and remain ignored until the approved models are
packed into Factorio sprite sheets.
