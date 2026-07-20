import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from vehicle_common import add_shadow, cube, material, parent_parts, wedge, wheel


ROOT = os.path.dirname(os.path.abspath(__file__))
RENDERS = os.path.join(ROOT, "renders")
ICON_RENDERS = os.path.join(RENDERS, "icons")
TRAIN_RENDERS = os.path.join(RENDERS, "directions")
STOP_RENDERS = os.path.join(RENDERS, "stop-directions")


TEAL = material("High nickel teal", (0.08, 0.42, 0.36, 1), 0.48, 0.36)
TEAL_LIGHT = material("High nickel highlight", (0.28, 0.78, 0.65, 1), 0.35, 0.3)
ORANGE = material("LFP orange", (0.72, 0.25, 0.055, 1), 0.34, 0.43)
ORANGE_LIGHT = material("LFP highlight", (0.96, 0.56, 0.12, 1), 0.24, 0.34)
SILVER = material("Cybertrain alloy", (0.34, 0.38, 0.4, 1), 0.74, 0.34, variation={
    "dark": (0.09, 0.11, 0.12, 1), "scale": 8.0
})
DARK = material("Dark machinery", (0.025, 0.032, 0.035, 1), 0.42, 0.6)
BLACK = material("Graphite", (0.025, 0.028, 0.03, 1), 0.18, 0.7)
WHITE = material("Lithium carbonate", (0.72, 0.77, 0.75, 1), 0.05, 0.82)
BLUE = material("Cobalt concentrate", (0.04, 0.17, 0.52, 1), 0.18, 0.6)
TAN = material("Phosphate", (0.52, 0.37, 0.13, 1), 0.05, 0.78)
ORE = material("Nickel ore", (0.12, 0.38, 0.3, 1), 0.32, 0.78, variation={
    "dark": (0.035, 0.07, 0.055, 1), "scale": 4.0
})
CRYSTAL = material("Nickel sulfate", (0.12, 0.72, 0.53, 1), 0.12, 0.42)
BRINE = material("Lithium brine", (0.16, 0.68, 0.78, 1), 0.18, 0.22)
TAILINGS = material("Acidic tailings", (0.42, 0.5, 0.06, 1), 0.08, 0.34)
COPPER = material("Copper busbar", (0.64, 0.24, 0.055, 1), 0.72, 0.32)
YELLOW = material("High voltage marking", (0.95, 0.62, 0.05, 1), 0.14, 0.36)
GLASS = material("Dark cab glass", (0.006, 0.03, 0.045, 1), 0.45, 0.25)
CYAN = material("Electric light", (0.08, 0.86, 1.0, 1), 0.2, 0.18)
RED = material("Tail light", (0.82, 0.015, 0.005, 1), 0.12, 0.25)
RUBBER = material("Rail wheel", (0.008, 0.009, 0.01, 1), 0.45, 0.68)
RUST = material("Damage and scorch", (0.22, 0.055, 0.018, 1), 0.28, 0.82)
SHADOW = material("Neutral footprint shadow", (0.01, 0.01, 0.008, 0.42), 0, 1)
SHADOW.surface_render_method = "DITHERED"


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def setup_camera(ortho_scale=5.8):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.resolution_percentage = 100
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.world.color = (0.02, 0.018, 0.014)
    for location, energy, size, color in [
        ((4, -5, 9), 1150, 5.0, (1.0, 0.78, 0.58)),
        ((-4, 3, 6), 390, 4.0, (0.58, 0.74, 0.82)),
        ((0, 0, 9), 700, 4.0, (1.0, 0.96, 0.86)),
    ]:
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.object
        light.data.energy = energy
        light.data.size = size
        light.data.color = color
    bpy.ops.object.camera_add(location=(7.8, -9.2, 15.0))
    camera = bpy.context.object
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = ortho_scale
    camera.rotation_euler = (Vector((0, 0, 0.5)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera
    return scene


def cylinder(name, location, radius, depth, mat, rotation=(0, 0, 0), vertices=32):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return obj


def chunks(mat, count=7, spread=1.2, z=0.45, seed=0):
    parts = []
    for i in range(count):
        angle = (i * 2.399 + seed) % math.tau
        radius = spread * (0.28 + 0.62 * ((i * 37) % 11) / 10)
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=1,
            radius=0.44 + 0.12 * ((i * 5) % 3),
            location=(math.cos(angle) * radius, math.sin(angle) * radius, z + 0.14 * (i % 3)),
        )
        obj = bpy.context.object
        obj.rotation_euler = (i * 0.31, i * 0.19, angle)
        obj.scale = (1.0, 0.72 + 0.08 * (i % 2), 0.68)
        obj.data.materials.append(mat)
        parts.append(obj)
    return parts


def tray(name, mat):
    parts = [cube(name + " tray", (0, 0, 0.16), (1.5, 1.13, 0.14), DARK, 0.08)]
    parts += chunks(mat, 8, 1.15, 0.48, 0.7)
    return parts


def fluid_drum(name, fluid_mat):
    parts = [
        cylinder(name + " drum", (0, 0, 0.83), 1.05, 1.55, DARK),
        cylinder(name + " fill", (0, 0, 1.62), 0.82, 0.08, fluid_mat),
        cube(name + " stripe", (0, -1.02, 0.88), (0.72, 0.055, 0.19), fluid_mat, 0.04),
    ]
    for z in (0.3, 1.35):
        parts.append(cylinder(name + " ring", (0, 0, z), 1.09, 0.09, SILVER))
    return parts


def cells(name, body, accent):
    parts = []
    for x in (-0.7, 0, 0.7):
        for y in (-0.42, 0.42):
            parts.append(cylinder(name + " cell", (x, y, 0.86), 0.29, 1.5, body))
            parts.append(cylinder(name + " cap", (x, y, 1.63), 0.22, 0.08, accent))
    parts.append(cube(name + " busbar", (0, 0, 1.72), (1.03, 0.63, 0.055), COPPER, 0.035))
    return parts


def pack(name, body, accent, damaged=False):
    tilt = (0.06, -0.12, -0.08) if damaged else (0, 0, 0)
    root = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(root)
    parts = [
        cube(name + " enclosure", (0, 0, 0.5), (1.65, 1.14, 0.34), body, 0.12),
        cube(name + " top plate", (0, 0, 0.88), (1.48, 0.97, 0.06), DARK, 0.05),
    ]
    for x in (-1.08, -0.36, 0.36, 1.08):
        parts.append(cube(name + " cell seam", (x, 0, 0.96), (0.035, 0.82, 0.035), accent, 0.01))
    parts.extend([
        cube(name + " positive busbar", (0.65, -0.98, 0.97), (0.44, 0.07, 0.045), COPPER, 0.02),
        cube(name + " negative busbar", (-0.65, -0.98, 0.97), (0.44, 0.07, 0.045), SILVER, 0.02),
        cube(name + " warning", (0, 0.99, 0.62), (0.32, 0.035, 0.16), YELLOW, 0.025),
    ])
    if damaged:
        parts.extend([
            wedge(name + " crushed corner", 1.72, 0.62, 1.1, 0.18, 0.82, 0.32, RUST, 0.72, 0.03),
            cube(name + " scorch", (-0.85, -1.02, 0.74), (0.48, 0.045, 0.23), RUST, 0.025),
        ])
    parent_parts(root, parts)
    root.rotation_euler = tilt
    return root


def build_charging_stop(include_shadow=False):
    root = bpy.data.objects.new("Cybertrain charging stop", None)
    bpy.context.collection.objects.link(root)
    parts = [
        cube("Stop foundation", (0, 0, 0.12), (1.45, 1.08, 0.12), DARK, 0.06),
        cube("Track approach plate", (0, -1.18, 0.14), (1.34, 0.34, 0.08), SILVER, 0.035),
        cube("Transformer cabinet", (-0.88, 0.55, 0.94), (0.42, 0.42, 0.82), SILVER, 0.08),
        cube("Power cabinet", (0.04, 0.67, 0.72), (0.38, 0.3, 0.6), TEAL, 0.07),
        cube("Transformer screen", (-0.88, 0.12, 1.08), (0.24, 0.035, 0.26), CYAN, 0.025),
        cube("Power screen", (0.04, 0.36, 0.8), (0.21, 0.03, 0.16), CYAN, 0.02),
        cube("Gantry left", (-1.12, -0.56, 1.25), (0.13, 0.13, 1.1), SILVER, 0.035),
        cube("Gantry right", (1.12, -0.56, 1.25), (0.13, 0.13, 1.1), SILVER, 0.035),
        cube("Gantry beam", (0, -0.56, 2.28), (1.25, 0.14, 0.14), SILVER, 0.035),
        cube("Overhead charge rail", (0, -0.56, 2.04), (0.8, 0.09, 0.075), CYAN, 0.02),
        cube("Left cable trunk", (-1.12, 0.08, 1.1), (0.055, 0.46, 0.055), COPPER, 0.015),
        cube("Right cable trunk", (1.12, 0.08, 1.1), (0.055, 0.46, 0.055), COPPER, 0.015),
        cube("Safety stripe", (0, -1.48, 0.23), (1.26, 0.035, 0.06), YELLOW, 0.01),
    ]
    for x in (-0.72, 0, 0.72):
        parts.append(cube("Charge indicator", (x, -0.72, 2.29), (0.19, 0.035, 0.045), CYAN, 0.012))
    if include_shadow:
        add_shadow(parts, SHADOW, (1.65, 1.55), 0.1)
    parent_parts(root, parts)
    return root


def charging_stop_icon():
    return [build_charging_stop(False)]


def build_icon(slug):
    if slug == "nickel-ore": return chunks(ORE, 9, 1.25, 0.42, 0.2)
    if slug == "nickel-sulfate": return tray(slug, CRYSTAL)
    if slug == "lithium-carbonate": return tray(slug, WHITE)
    if slug == "battery-graphite": return tray(slug, BLACK)
    if slug == "cobalt-concentrate": return tray(slug, BLUE)
    if slug == "phosphate": return chunks(TAN, 8, 1.2, 0.42, 1.2)
    if slug == "lithium-brine": return fluid_drum(slug, BRINE)
    if slug == "acidic-tailings": return fluid_drum(slug, TAILINGS)
    if slug == "high-nickel-cell": return cells(slug, TEAL, TEAL_LIGHT)
    if slug == "lfp-cell": return cells(slug, ORANGE, ORANGE_LIGHT)
    if slug == "high-energy-battery-pack": return [pack(slug, TEAL, TEAL_LIGHT)]
    if slug == "lfp-battery-pack": return [pack(slug, ORANGE, ORANGE_LIGHT)]
    if slug == "damaged-high-energy-battery-pack": return [pack(slug, TEAL, TEAL_LIGHT, True)]
    if slug == "damaged-lfp-battery-pack": return [pack(slug, ORANGE, ORANGE_LIGHT, True)]
    if slug == "electric-semi-drive-charge": return cells(slug, SILVER, CYAN)
    if slug == "semi-charging-stop": return charging_stop_icon()
    raise ValueError(slug)


def render_icons():
    os.makedirs(ICON_RENDERS, exist_ok=True)
    slugs = [
        "nickel-ore", "nickel-sulfate", "lithium-carbonate", "battery-graphite",
        "cobalt-concentrate", "phosphate", "lithium-brine", "acidic-tailings",
        "high-nickel-cell", "lfp-cell", "high-energy-battery-pack", "lfp-battery-pack",
        "damaged-high-energy-battery-pack", "damaged-lfp-battery-pack",
        "electric-semi-drive-charge", "semi-charging-stop",
    ]
    for slug in slugs:
        clear_scene()
        scene = setup_camera(5.5)
        build_icon(slug)
        scene.render.resolution_x = 512
        scene.render.resolution_y = 512
        scene.render.filepath = os.path.join(ICON_RENDERS, slug + ".png")
        bpy.ops.render.render(write_still=True)


def build_cybertrain():
    root = bpy.data.objects.new("Cybertrain", None)
    bpy.context.collection.objects.link(root)
    parts = [
        cube("Long battery chassis", (0, 0, 0.68), (3.05, 0.82, 0.28), DARK, 0.06),
        wedge("Aerodynamic nose", 3.18, 1.36, 0.8, 0.63, 0.82, 1.62, SILVER, 0.62, 0.045),
        wedge("Cabin", 1.38, 0.18, 0.79, 0.78, 1.6, 1.95, SILVER, 0.9, 0.05),
        wedge("Windshield", 1.47, 0.68, 0.68, 1.28, 1.55, 1.78, GLASS, 0.86, 0.025),
        cube("Battery spine", (-1.25, 0, 1.22), (1.42, 0.73, 0.56), SILVER, 0.1),
        wedge("Rear taper", -0.15, -3.03, 0.78, 0.67, 1.78, 1.08, SILVER, 0.9, 0.05),
        cube("Side battery panel left", (-1.12, -0.79, 1.1), (1.15, 0.035, 0.35), TEAL, 0.025),
        cube("Side battery panel right", (-1.12, 0.79, 1.1), (1.15, 0.035, 0.35), TEAL, 0.025),
        cube("Front light bar", (3.1, 0, 0.95), (0.05, 0.57, 0.06), CYAN, 0.015),
        cube("Rear light bar", (-3.02, 0, 0.92), (0.05, 0.57, 0.06), RED, 0.015),
        cube("Roof charge rail", (-0.3, 0, 1.88), (0.72, 0.22, 0.06), CYAN, 0.02),
        cube("Lower warning stripe left", (0, -0.83, 0.69), (2.58, 0.025, 0.06), YELLOW, 0.01),
        cube("Lower warning stripe right", (0, 0.83, 0.69), (2.58, 0.025, 0.06), YELLOW, 0.01),
    ]
    for x in (-1.78, 1.58):
        for y in (-0.82, 0.82):
            parts.extend(wheel("Rail wheel", x, y, 0.45, 0.42, 0.22, RUBBER, SILVER, 12))
    add_shadow(parts, SHADOW, (3.3, 1.15), 0.14)
    parent_parts(root, parts)
    return root


def render_cybertrain():
    os.makedirs(TRAIN_RENDERS, exist_ok=True)
    clear_scene()
    scene = setup_camera(8.2)
    train = build_cybertrain()
    shadow = bpy.data.objects.get("Ground contact shadow")
    color_parts = [obj for obj in scene.objects if obj != shadow and obj != scene.camera and obj.type not in {"LIGHT", "EMPTY"}]
    scene.render.resolution_x = 768
    scene.render.resolution_y = 768
    train.rotation_euler.z = math.radians(18)
    scene.render.filepath = os.path.join(RENDERS, "cybertrain-master.png")
    bpy.ops.render.render(write_still=True)
    scene.render.resolution_x = 256
    scene.render.resolution_y = 256
    for index in range(64):
        train.rotation_euler.z = math.tau * index / 64
        shadow.hide_render = True
        scene.render.filepath = os.path.join(TRAIN_RENDERS, f"cybertrain-{index:02d}.png")
        bpy.ops.render.render(write_still=True)
        for part in color_parts: part.hide_render = True
        shadow.hide_render = False
        scene.render.filepath = os.path.join(TRAIN_RENDERS, f"cybertrain-shadow-{index:02d}.png")
        bpy.ops.render.render(write_still=True)
        for part in color_parts: part.hide_render = False
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "battery-cybertrain.blend"))


def render_charging_stop():
    os.makedirs(STOP_RENDERS, exist_ok=True)
    clear_scene()
    scene = setup_camera(6.6)
    stop = build_charging_stop(True)
    shadow = bpy.data.objects.get("Ground contact shadow")
    color_parts = [obj for obj in scene.objects if obj != shadow and obj != scene.camera and obj.type not in {"LIGHT", "EMPTY"}]
    stop.rotation_euler.z = math.radians(18)
    scene.render.resolution_x = 768
    scene.render.resolution_y = 768
    scene.render.filepath = os.path.join(RENDERS, "charging-stop-master.png")
    bpy.ops.render.render(write_still=True)
    scene.render.resolution_x = 256
    scene.render.resolution_y = 256
    for index in range(4):
        stop.rotation_euler.z = math.tau * index / 4
        shadow.hide_render = True
        scene.render.filepath = os.path.join(STOP_RENDERS, f"charging-stop-{index}.png")
        bpy.ops.render.render(write_still=True)
        for part in color_parts: part.hide_render = True
        shadow.hide_render = False
        scene.render.filepath = os.path.join(STOP_RENDERS, f"charging-stop-shadow-{index}.png")
        bpy.ops.render.render(write_still=True)
        for part in color_parts: part.hide_render = False
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "battery-cybertrain.blend"))


render_icons()
render_cybertrain()
render_charging_stop()
