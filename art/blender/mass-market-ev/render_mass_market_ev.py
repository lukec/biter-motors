import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from vehicle_common import add_shadow, cube, material, parent_parts, render_vehicle, wedge, wheel

WHITE = material("Pearl white paint", (0.72, 0.76, 0.78, 1), 0.55, 0.2)
WHITE_LIT = material("Pearl body highlight", (0.95, 0.97, 0.98, 1), 0.42, 0.18)
GLASS = material("Dark panoramic glass", (0.01, 0.028, 0.04, 1), 0.5, 0.11)
RUBBER = material("Tire rubber", (0.006, 0.007, 0.008, 1), 0.02, 0.65)
RIM = material("Aero wheel graphite", (0.12, 0.15, 0.17, 1), 0.8, 0.2)
LIGHT = material("LED headlights", (0.82, 0.94, 1.0, 1), 0.2, 0.1)
TAIL = material("Red tail light", (1.0, 0.004, 0.002, 1), 0.2, 0.12)
SHADOW = material("Soft footprint shadow", (0.01, 0.012, 0.016, 0.28), 0.0, 1.0)
SHADOW.surface_render_method = "DITHERED"


def build():
    root = bpy.data.objects.new("Mass-market EV", None)
    bpy.context.collection.objects.link(root)
    parts = [
        cube("Efficient battery floor", (0, 0, 0.51), (2.05, 0.92, 0.16), WHITE, 0.18),
        wedge("Short practical nose", 2.2, 0.62, 0.9, 0.54, 0.74, 0.94, WHITE_LIT),
        wedge("Liftback body", 0.62, -2.12, 0.94, 0.54, 0.96, 0.78, WHITE),
        wedge("Tall windshield", 0.7, 0.04, 0.72, 0.91, 1.08, 1.48, GLASS),
        wedge("Roomy panoramic roof", 0.04, -1.14, 0.7, 1.06, 1.48, 1.38, GLASS),
        wedge("Liftback glass", -1.14, -1.68, 0.68, 0.83, 1.38, 0.96, GLASS),
        cube("Front lower grille", (2.12, 0, 0.4), (0.1, 0.62, 0.055), RIM, 0.025),
        cube("Left headlamp", (2.08, -0.61, 0.72), (0.075, 0.21, 0.045), LIGHT, 0.02),
        cube("Right headlamp", (2.08, 0.61, 0.72), (0.075, 0.21, 0.045), LIGHT, 0.02),
        cube("Wide tail lamp", (-2.05, 0, 0.75), (0.055, 0.68, 0.045), TAIL, 0.018),
    ]
    for x, y, name in [(1.35, -0.93, "front left"), (1.35, 0.93, "front right"), (-1.35, -0.93, "rear left"), (-1.35, 0.93, "rear right")]:
        parts.extend(wheel(name, x, y, 0.5, 0.43, 0.28, RUBBER, RIM, 20))
    add_shadow(parts, SHADOW, (2.45, 1.22))
    parent_parts(root, parts)
    return root


render_vehicle(__file__, build, "mass-market-ev", "mass-market-ev.blend", 6.45)
