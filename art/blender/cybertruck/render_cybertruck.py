import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from vehicle_common import add_shadow, cube, material, parent_parts, render_vehicle, wedge, wheel

STEEL = material("Weathered stainless steel", (0.32, 0.33, 0.31, 1), 0.82, 0.44, 0.04, {
    "dark": (0.09, 0.085, 0.07, 1), "scale": 6.0
})
STEEL_LIT = material("Steel highlight planes", (0.54, 0.53, 0.48, 1), 0.78, 0.39, 0.04, {
    "dark": (0.14, 0.13, 0.1, 1), "scale": 8.0
})
GLASS = material("Armor glass", (0.008, 0.018, 0.024, 1), 0.4, 0.32, 0.04)
RUBBER = material("All terrain tire", (0.006, 0.007, 0.008, 1), 0.02, 0.74)
RIM = material("Black wheel", (0.022, 0.022, 0.02, 1), 0.62, 0.48, 0.01)
LIGHT = material("White light bar", (0.8, 0.82, 0.72, 1), 0.18, 0.25, 0.02)
TAIL = material("Red light bar", (0.7, 0.003, 0.001, 1), 0.15, 0.3, 0.02)
BED = material("Composite truck bed", (0.018, 0.022, 0.025, 1), 0.2, 0.55)
DIRT = material("Heavy road dust", (0.16, 0.11, 0.06, 1), 0.02, 0.94, 0.0)
SHADOW = material("Neutral footprint shadow", (0.012, 0.01, 0.008, 0.4), 0.0, 1.0, 0.0)
SHADOW.surface_render_method = "DITHERED"


def build():
    root = bpy.data.objects.new("Cybertruck", None)
    bpy.context.collection.objects.link(root)
    parts = [
        cube("Armored battery chassis", (0, 0, 0.62), (2.45, 1.02, 0.24), STEEL, 0.035),
        wedge("Wedge nose", 2.58, 0.72, 0.99, 0.7, 0.88, 1.12, STEEL_LIT, 0.96, 0.025),
        wedge("Cabin armor", 0.72, -0.72, 0.96, 0.83, 1.12, 1.82, STEEL, 0.9, 0.02),
        wedge("Angular windshield", 0.76, 0.02, 0.82, 1.08, 1.14, 1.78, GLASS, 0.94, 0.018),
        wedge("Triangular glass roof", 0.02, -0.75, 0.8, 1.08, 1.78, 1.22, GLASS, 0.92, 0.018),
        cube("Open cargo bed", (-1.55, 0, 0.91), (0.8, 0.84, 0.11), BED, 0.02),
        wedge("Left sail panel", -0.65, -2.35, 0.98, 0.72, 1.28, 0.92, STEEL, 0.98, 0.018),
        cube("Front light bar", (2.51, 0, 0.88), (0.055, 0.77, 0.045), LIGHT, 0.012),
        cube("Rear light bar", (-2.39, 0, 0.91), (0.05, 0.79, 0.045), TAIL, 0.012),
        cube("Front skid plate", (2.5, 0, 0.4), (0.13, 0.82, 0.08), RIM, 0.02),
        cube("Rear tow beam", (-2.43, 0, 0.43), (0.11, 0.74, 0.075), RIM, 0.02),
        cube("Hood center break", (1.7, 0, 1.0), (0.72, 0.018, 0.016), RIM, 0.006),
        cube("Left armor seam", (0.0, -1.025, 0.94), (1.5, 0.015, 0.025), RIM, 0.006),
        cube("Right armor seam", (0.0, 1.025, 0.94), (1.5, 0.015, 0.025), RIM, 0.006),
        cube("Bed rib one", (-1.2, 0, 1.04), (0.035, 0.72, 0.025), RIM, 0.006),
        cube("Bed rib two", (-1.6, 0, 1.04), (0.035, 0.72, 0.025), RIM, 0.006),
        cube("Bed rib three", (-2.0, 0, 1.04), (0.035, 0.72, 0.025), RIM, 0.006),
        cube("Left lower-body mud", (-0.25, -1.07, 0.53), (1.65, 0.018, 0.08), DIRT, 0.006),
        cube("Right lower-body mud", (-0.25, 1.07, 0.53), (1.65, 0.018, 0.08), DIRT, 0.006),
    ]
    for x, y, name in [(1.58, -1.03, "front left"), (1.58, 1.03, "front right"), (-1.62, -1.03, "rear left"), (-1.62, 1.03, "rear right")]:
        parts.extend(wheel(name, x, y, 0.57, 0.54, 0.34, RUBBER, RIM, 12))
    add_shadow(parts, SHADOW, (2.85, 1.38), 0.17)
    parent_parts(root, parts)
    return root


render_vehicle(__file__, build, "cybertruck", "cybertruck.blend", 7.2)
