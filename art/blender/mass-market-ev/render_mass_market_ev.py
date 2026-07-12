import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from vehicle_common import add_shadow, cube, material, parent_parts, render_vehicle, wedge, wheel

WHITE = material("Road-worn pearl white", (0.62, 0.64, 0.62, 1), 0.42, 0.43, 0.12, {
    "dark": (0.25, 0.24, 0.21, 1), "scale": 10.0
})
WHITE_LIT = material("Pearl body highlight", (0.82, 0.82, 0.77, 1), 0.35, 0.38, 0.14, {
    "dark": (0.34, 0.32, 0.27, 1), "scale": 12.0
})
GLASS = material("Dark panoramic glass", (0.01, 0.025, 0.032, 1), 0.35, 0.3, 0.06)
RUBBER = material("Tire rubber", (0.006, 0.007, 0.008, 1), 0.02, 0.65)
RIM = material("Aero wheel graphite", (0.09, 0.1, 0.1, 1), 0.7, 0.4, 0.02)
DARK_METAL = material("Exposed underbody", (0.025, 0.024, 0.021, 1), 0.6, 0.56, 0.0)
DIRT = material("Road dust", (0.14, 0.105, 0.065, 1), 0.02, 0.92, 0.0)
LIGHT = material("LED headlights", (0.78, 0.82, 0.74, 1), 0.15, 0.25, 0.03)
TAIL = material("Red tail light", (0.7, 0.004, 0.002, 1), 0.15, 0.3, 0.03)
SHADOW = material("Neutral footprint shadow", (0.012, 0.01, 0.008, 0.38), 0.0, 1.0, 0.0)
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
        cube("Left practical side sill", (-0.08, -0.92, 0.39), (1.55, 0.04, 0.065), DARK_METAL, 0.018),
        cube("Right practical side sill", (-0.08, 0.92, 0.39), (1.55, 0.04, 0.065), DARK_METAL, 0.018),
        cube("Hood service seam", (1.48, 0, 0.88), (0.58, 0.015, 0.012), RIM, 0.006),
        cube("Left front door seam", (0.25, -0.925, 0.76), (0.02, 0.014, 0.27), RIM, 0.006),
        cube("Right front door seam", (0.25, 0.925, 0.76), (0.02, 0.014, 0.27), RIM, 0.006),
        cube("Left rear door seam", (-0.78, -0.925, 0.76), (0.02, 0.014, 0.27), RIM, 0.006),
        cube("Right rear door seam", (-0.78, 0.925, 0.76), (0.02, 0.014, 0.27), RIM, 0.006),
        cube("Left rocker dust", (-0.2, -0.96, 0.47), (1.18, 0.014, 0.05), DIRT, 0.006),
        cube("Right rocker dust", (-0.2, 0.96, 0.47), (1.18, 0.014, 0.05), DIRT, 0.006),
    ]
    for x, y, name in [(1.35, -0.93, "front left"), (1.35, 0.93, "front right"), (-1.35, -0.93, "rear left"), (-1.35, 0.93, "rear right")]:
        parts.extend(wheel(name, x, y, 0.5, 0.43, 0.28, RUBBER, RIM, 20))
    add_shadow(parts, SHADOW, (2.45, 1.22))
    parent_parts(root, parts)
    return root


render_vehicle(__file__, build, "mass-market-ev", "mass-market-ev.blend", 6.45)
