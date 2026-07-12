import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from vehicle_common import add_shadow, cube, material, parent_parts, render_vehicle, wedge, wheel


BLACK = material("Weathered obsidian paint", (0.012, 0.016, 0.021, 1), 0.7, 0.42, 0.12, {
    "dark": (0.002, 0.003, 0.004, 1), "scale": 9.0
})
BLACK_LIT = material("Weathered black highlights", (0.055, 0.064, 0.068, 1), 0.62, 0.37, 0.14, {
    "dark": (0.008, 0.011, 0.014, 1), "scale": 11.0
})
GLASS = material("Panoramic smoked glass", (0.008, 0.018, 0.024, 1), 0.35, 0.3, 0.06)
RUBBER = material("Tire rubber", (0.006, 0.007, 0.008, 1), 0.02, 0.68, 0.0)
METAL = material("Machined wheel metal", (0.22, 0.24, 0.24, 1), 0.82, 0.36, 0.03)
TRIM = material("Satin trim", (0.36, 0.38, 0.37, 1), 0.72, 0.42, 0.02)
DARK_METAL = material("Exposed underbody", (0.025, 0.024, 0.021, 1), 0.62, 0.55, 0.0)
DIRT = material("Road wear", (0.09, 0.065, 0.042, 1), 0.02, 0.92, 0.0)
LIGHT = material("LED headlights", (0.78, 0.8, 0.7, 1), 0.12, 0.26, 0.03)
TAIL = material("Continuous tail lamps", (0.68, 0.004, 0.002, 1), 0.15, 0.3, 0.03)
SHADOW = material("Neutral footprint shadow", (0.012, 0.01, 0.008, 0.38), 0.0, 1.0, 0.0)
SHADOW.surface_render_method = "DITHERED"


def build():
    root = bpy.data.objects.new("Premium EV", None)
    bpy.context.collection.objects.link(root)
    parts = [
        cube("Long wheelbase battery floor", (0, 0, 0.5), (2.28, 0.94, 0.16), BLACK, 0.17),
        wedge("Sculpted front body", 2.45, 0.65, 0.92, 0.53, 0.7, 0.91, BLACK_LIT),
        wedge("Fastback rear body", 0.65, -2.38, 0.95, 0.53, 0.91, 0.73, BLACK),
        wedge("Raked windshield", 0.78, 0.12, 0.72, 0.88, 1.06, 1.42, GLASS, 0.9),
        wedge("Panoramic roof", 0.12, -1.18, 0.69, 1.02, 1.42, 1.3, GLASS, 0.92),
        wedge("Fastback rear glass", -1.18, -1.72, 0.67, 0.82, 1.3, 0.92, GLASS, 0.9),
        cube("Front lower intake", (2.37, 0, 0.39), (0.12, 0.73, 0.065), DARK_METAL, 0.03),
        cube("Left daylight lamp", (2.32, -0.61, 0.7), (0.085, 0.22, 0.045), LIGHT, 0.02),
        cube("Right daylight lamp", (2.32, 0.61, 0.7), (0.085, 0.22, 0.045), LIGHT, 0.02),
        cube("Full width tail lamp", (-2.31, 0, 0.73), (0.055, 0.72, 0.045), TAIL, 0.018),
        cube("Left window trim", (-0.25, -0.73, 1.13), (1.05, 0.025, 0.026), TRIM, 0.012),
        cube("Right window trim", (-0.25, 0.73, 1.13), (1.05, 0.025, 0.026), TRIM, 0.012),
        cube("Left side sill", (-0.12, -0.94, 0.39), (1.72, 0.04, 0.07), DARK_METAL, 0.018),
        cube("Right side sill", (-0.12, 0.94, 0.39), (1.72, 0.04, 0.07), DARK_METAL, 0.018),
        cube("Hood center seam", (1.56, 0, 0.86), (0.68, 0.016, 0.012), TRIM, 0.006),
        cube("Left door seam", (-0.35, -0.945, 0.76), (0.025, 0.014, 0.28), TRIM, 0.006),
        cube("Right door seam", (-0.35, 0.945, 0.76), (0.025, 0.014, 0.28), TRIM, 0.006),
        cube("Rear powertrain grille", (-1.82, 0, 0.78), (0.24, 0.55, 0.025), DARK_METAL, 0.01),
        cube("Left rocker dust", (-0.3, -0.98, 0.47), (1.3, 0.014, 0.05), DIRT, 0.006),
        cube("Right rocker dust", (-0.3, 0.98, 0.47), (1.3, 0.014, 0.05), DIRT, 0.006),
    ]
    for x, y, name in [(1.5, -0.95, "front left"), (1.5, 0.95, "front right"), (-1.48, -0.95, "rear left"), (-1.48, 0.95, "rear right")]:
        parts.extend(wheel(name, x, y, 0.5, 0.47, 0.3, RUBBER, METAL, 16))
    add_shadow(parts, SHADOW, (2.7, 1.28))
    parent_parts(root, parts)
    return root


render_vehicle(__file__, build, "premium-ev", "premium-ev.blend", 6.8)
