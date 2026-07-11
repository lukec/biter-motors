import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from vehicle_common import add_shadow, cube, material, parent_parts, render_vehicle, wedge, wheel

GOLD = material("Robotaxi gold", (0.72, 0.39, 0.025, 1), 0.72, 0.18)
GOLD_LIT = material("Gold body highlight", (1.0, 0.66, 0.08, 1), 0.62, 0.17)
GLASS = material("Passenger canopy", (0.008, 0.025, 0.038, 1), 0.5, 0.09)
RUBBER = material("Low rolling resistance tire", (0.006, 0.007, 0.008, 1), 0.02, 0.62)
RIM = material("Gold aero wheel", (0.2, 0.13, 0.035, 1), 0.78, 0.2)
LIGHT = material("Autonomy light", (0.75, 0.95, 1.0, 1), 0.2, 0.08)
TAIL = material("Rear service light", (1.0, 0.01, 0.002, 1), 0.2, 0.1)
SHADOW = material("Soft footprint shadow", (0.01, 0.012, 0.016, 0.28), 0.0, 1.0)
SHADOW.surface_render_method = "DITHERED"


def build():
    root = bpy.data.objects.new("Robotaxi", None)
    bpy.context.collection.objects.link(root)
    parts = [
        cube("Compact autonomy floor", (0, 0, 0.49), (1.78, 0.88, 0.16), GOLD, 0.2),
        wedge("Friendly rounded nose", 1.93, 0.58, 0.86, 0.52, 0.76, 1.0, GOLD_LIT),
        wedge("Short tail body", 0.58, -1.88, 0.9, 0.52, 1.0, 0.78, GOLD),
        wedge("Full passenger windshield", 0.72, 0.12, 0.71, 0.93, 1.08, 1.5, GLASS),
        wedge("Single glass canopy", 0.12, -1.12, 0.7, 1.08, 1.5, 1.4, GLASS),
        wedge("Rear passenger glass", -1.12, -1.56, 0.68, 0.85, 1.4, 0.98, GLASS),
        cube("Autonomy sensor brow", (0.56, 0, 1.13), (0.09, 0.62, 0.055), LIGHT, 0.025),
        cube("Front status bar", (1.84, 0, 0.75), (0.06, 0.58, 0.04), LIGHT, 0.018),
        cube("Rear service bar", (-1.82, 0, 0.77), (0.055, 0.64, 0.04), TAIL, 0.018),
        cube("Left sliding door seam", (-0.42, -0.89, 0.78), (0.025, 0.018, 0.3), RIM, 0.008),
        cube("Right sliding door seam", (-0.42, 0.89, 0.78), (0.025, 0.018, 0.3), RIM, 0.008),
    ]
    for x, y, name in [(1.18, -0.89, "front left"), (1.18, 0.89, "front right"), (-1.18, -0.89, "rear left"), (-1.18, 0.89, "rear right")]:
        parts.extend(wheel(name, x, y, 0.49, 0.4, 0.26, RUBBER, RIM, 20))
    add_shadow(parts, SHADOW, (2.2, 1.18))
    parent_parts(root, parts)
    return root


render_vehicle(__file__, build, "robotaxi", "robotaxi.blend", 6.2)
