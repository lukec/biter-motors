# Biter Motors Blender Vehicle Family

The Biter Motors vehicle family now has editable Blender studies and deterministic
64-direction renders for:

- Prototype Roadster: red, compact, low two-seat sports car.
- Premium EV: black, long-wheelbase grand tourer.
- Mass-market EV: white, practical liftback.
- Megatruck: silver, oversized faceted pickup.
- Bitertaxi: gold, compact autonomous passenger pod.

`vehicle_common.py` owns the shared high-overhead camera, warm industrial
lighting, geometry helpers, wheel construction, transparent rendering, and
separate body/shadow directional exports. The independently scripted Roadster
implements the same production conventions.

Each model folder contains its editable `.blend`, render script, transparent
master, and direction/scale QA sheet. Individual directional frames are
reproducible local output and remain ignored; the packing step builds separate
Factorio body and shadow sprite sheets.
