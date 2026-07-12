import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from vehicle_common import add_shadow, cube, material, parent_parts, render_vehicle, wedge, wheel

GOLD = material("Working robotaxi gold", (0.52, 0.28, 0.018, 1), 0.58, 0.43, 0.12, {
    "dark": (0.16, 0.075, 0.008, 1), "scale": 9.0
})
GOLD_LIT = material("Gold body highlight", (0.75, 0.43, 0.045, 1), 0.5, 0.38, 0.14, {
    "dark": (0.22, 0.1, 0.009, 1), "scale": 11.0
})
GLASS = material("Passenger canopy", (0.008, 0.022, 0.03, 1), 0.38, 0.3, 0.05)
RUBBER = material("Low rolling resistance tire", (0.006, 0.007, 0.008, 1), 0.02, 0.62)
RIM = material("Gold aero wheel", (0.16, 0.11, 0.035, 1), 0.65, 0.42, 0.02)
DARK_METAL = material("Fleet underbody", (0.025, 0.023, 0.018, 1), 0.58, 0.56, 0.0)
DIRT = material("Fleet road wear", (0.13, 0.085, 0.04, 1), 0.02, 0.92, 0.0)
LIGHT = material("Autonomy light", (0.66, 0.8, 0.76, 1), 0.15, 0.24, 0.03)
TAIL = material("Rear service light", (0.7, 0.008, 0.002, 1), 0.15, 0.3, 0.03)
SHADOW = material("Neutral footprint shadow", (0.012, 0.01, 0.008, 0.38), 0.0, 1.0, 0.0)
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
        cube("Left fleet side sill", (-0.05, -0.9, 0.38), (1.35, 0.04, 0.06), DARK_METAL, 0.016),
        cube("Right fleet side sill", (-0.05, 0.9, 0.38), (1.35, 0.04, 0.06), DARK_METAL, 0.016),
        cube("Front sensor access seam", (1.45, 0, 0.9), (0.34, 0.014, 0.012), RIM, 0.006),
        cube("Roof lidar puck", (0.02, 0, 1.53), (0.14, 0.14, 0.045), DARK_METAL, 0.035),
        cube("Left fleet number plate", (-1.65, -0.5, 0.73), (0.035, 0.14, 0.06), LIGHT, 0.008),
        cube("Right fleet number plate", (-1.65, 0.5, 0.73), (0.035, 0.14, 0.06), LIGHT, 0.008),
        cube("Left rocker dust", (-0.18, -0.94, 0.46), (1.0, 0.014, 0.05), DIRT, 0.006),
        cube("Right rocker dust", (-0.18, 0.94, 0.46), (1.0, 0.014, 0.05), DIRT, 0.006),
    ]
    for x, y, name in [(1.18, -0.89, "front left"), (1.18, 0.89, "front right"), (-1.18, -0.89, "rear left"), (-1.18, 0.89, "rear right")]:
        parts.extend(wheel(name, x, y, 0.49, 0.4, 0.26, RUBBER, RIM, 20))
    add_shadow(parts, SHADOW, (2.2, 1.18))
    parent_parts(root, parts)
    return root


render_vehicle(__file__, build, "robotaxi", "robotaxi.blend", 6.2)
