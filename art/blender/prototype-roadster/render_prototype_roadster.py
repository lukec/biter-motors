import math
import os
import sys

import bpy
from mathutils import Vector


ROOT = os.path.dirname(os.path.abspath(__file__))
OUTPUT = os.path.join(ROOT, "renders")
os.makedirs(OUTPUT, exist_ok=True)


def material(name, color, metallic=0.0, roughness=0.4, coat=0.18, variation=None):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Coat Weight"].default_value = coat
    bsdf.inputs["Coat Roughness"].default_value = 0.3
    if variation:
        noise = mat.node_tree.nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = variation.get("scale", 7.0)
        noise.inputs["Detail"].default_value = 3.0
        noise.inputs["Roughness"].default_value = 0.72
        ramp = mat.node_tree.nodes.new("ShaderNodeValToRGB")
        ramp.color_ramp.elements[0].position = 0.24
        ramp.color_ramp.elements[0].color = variation["dark"]
        ramp.color_ramp.elements[1].position = 0.78
        ramp.color_ramp.elements[1].color = color
        mat.node_tree.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
        mat.node_tree.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


RED = material("Roadster weathered red", (0.34, 0.012, 0.016, 1), 0.62, 0.43, 0.12, {
    "dark": (0.10, 0.006, 0.008, 1), "scale": 8.0
})
RED_LIGHT = material("Roadster weathered highlight", (0.56, 0.025, 0.022, 1), 0.5, 0.37, 0.16, {
    "dark": (0.16, 0.008, 0.009, 1), "scale": 10.0
})
GLASS = material("Smoked glass", (0.012, 0.022, 0.026, 1), 0.35, 0.3, 0.08)
RUBBER = material("Tire rubber", (0.008, 0.009, 0.01, 1), 0.05, 0.62)
METAL = material("Wheel metal", (0.16, 0.17, 0.17, 1), 0.82, 0.38, 0.04)
DARK_METAL = material("Roadster exposed dark metal", (0.035, 0.032, 0.028, 1), 0.7, 0.52, 0.0)
DIRT = material("Road dust and wear", (0.11, 0.075, 0.045, 1), 0.05, 0.9, 0.0)
LIGHT = material("Headlights", (0.9, 0.68, 0.32, 1), 0.15, 0.25, 0.05)
TAIL = material("Tail lights", (0.72, 0.008, 0.004, 1), 0.18, 0.3, 0.05)
SHADOW = material("Neutral footprint shadow", (0.012, 0.01, 0.008, 0.38), 0.0, 1.0, 0.0)
SHADOW.surface_render_method = "DITHERED"


def bevel_object(obj, amount=0.08, segments=3):
    bevel = obj.modifiers.new("Soft manufactured edges", "BEVEL")
    bevel.width = amount
    bevel.segments = segments
    bevel.limit_method = "ANGLE"
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.shade_smooth_by_angle()
    obj.select_set(False)
    return obj


def cube(name, location, scale, mat, bevel=0.08):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    return bevel_object(obj, bevel)


def wedge(name, x_front, x_back, half_width, z_bottom, z_front, z_back, mat):
    verts = [
        (x_front, -half_width, z_bottom), (x_front, half_width, z_bottom),
        (x_back, -half_width, z_bottom), (x_back, half_width, z_bottom),
        (x_front, -half_width * 0.92, z_front), (x_front, half_width * 0.92, z_front),
        (x_back, -half_width * 0.92, z_back), (x_back, half_width * 0.92, z_back),
    ]
    faces = [
        (0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4), (2, 6, 7, 3),
        (0, 4, 6, 2), (1, 3, 7, 5),
    ]
    mesh = bpy.data.meshes.new(name + " mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return bevel_object(obj, 0.07, 3)


def wheel(name, x, y):
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.43, depth=0.28, location=(x, y, 0.48), rotation=(math.pi / 2, 0, 0))
    tire = bpy.context.object
    tire.name = name + " tire"
    tire.data.materials.append(RUBBER)
    bevel_object(tire, 0.035, 2)
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.25, depth=0.292, location=(x, y, 0.48), rotation=(math.pi / 2, 0, 0))
    rim = bpy.context.object
    rim.name = name + " rim"
    rim.data.materials.append(METAL)
    bevel_object(rim, 0.02, 2)


def build_roadster():
    root = bpy.data.objects.new("Prototype Roadster", None)
    bpy.context.collection.objects.link(root)

    parts = []
    parts.append(cube("Low battery skateboard", (0, 0, 0.47), (1.95, 0.85, 0.14), RED, 0.15))
    parts.append(wedge("Long low hood", 2.1, 0.34, 0.83, 0.52, 0.66, 0.87, RED_LIGHT))
    parts.append(wedge("Rear haunch", 0.34, -2.02, 0.87, 0.51, 0.88, 0.68, RED))
    parts.append(wedge("Integrated glass canopy", 0.48, -1.18, 0.64, 0.84, 1.03, 1.25, GLASS))
    parts.append(wedge("Rear canopy taper", -0.5, -1.35, 0.6, 0.82, 1.23, 0.9, GLASS))
    parts.append(cube("Front splitter", (2.02, 0, 0.39), (0.12, 0.82, 0.07), RUBBER, 0.035))
    parts.append(cube("Rear diffuser", (-1.98, 0, 0.4), (0.12, 0.78, 0.08), RUBBER, 0.035))
    parts.append(cube("Left side sill", (-0.05, -0.87, 0.38), (1.62, 0.055, 0.075), DARK_METAL, 0.025))
    parts.append(cube("Right side sill", (-0.05, 0.87, 0.38), (1.62, 0.055, 0.075), DARK_METAL, 0.025))
    parts.append(cube("Hood center seam", (1.28, 0, 0.88), (0.72, 0.018, 0.014), DARK_METAL, 0.008))
    parts.append(cube("Left hood vent", (1.38, -0.47, 0.83), (0.34, 0.08, 0.025), DARK_METAL, 0.015))
    parts.append(cube("Right hood vent", (1.38, 0.47, 0.83), (0.34, 0.08, 0.025), DARK_METAL, 0.015))
    parts.append(cube("Rear electronics grille", (-1.48, 0, 0.82), (0.34, 0.58, 0.035), DARK_METAL, 0.018))
    parts.append(cube("Front exposed crossmember", (1.75, 0, 0.43), (0.06, 0.66, 0.055), METAL, 0.02))
    parts.append(cube("Rear exposed crossmember", (-1.72, 0, 0.43), (0.06, 0.66, 0.055), METAL, 0.02))
    parts.append(cube("Left lower-body dust", (-0.25, -0.91, 0.48), (1.2, 0.018, 0.055), DIRT, 0.01))
    parts.append(cube("Right lower-body dust", (-0.25, 0.91, 0.48), (1.2, 0.018, 0.055), DIRT, 0.01))
    parts.append(cube("Left headlight", (1.95, -0.57, 0.68), (0.09, 0.2, 0.055), LIGHT, 0.025))
    parts.append(cube("Right headlight", (1.95, 0.57, 0.68), (0.09, 0.2, 0.055), LIGHT, 0.025))
    parts.append(cube("Left tail light", (-1.93, -0.55, 0.68), (0.07, 0.21, 0.05), TAIL, 0.02))
    parts.append(cube("Right tail light", (-1.93, 0.55, 0.68), (0.07, 0.21, 0.05), TAIL, 0.02))
    for x, y, label in [(1.28, -0.86, "front left"), (1.28, 0.86, "front right"), (-1.28, -0.86, "rear left"), (-1.28, 0.86, "rear right")]:
        before = set(bpy.context.scene.objects)
        wheel(label, x, y)
        parts.extend([obj for obj in bpy.context.scene.objects if obj not in before])

    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, location=(0, 0, 0.16), scale=(2.35, 1.18, 0.025))
    shadow = bpy.context.object
    shadow.name = "Ground contact shadow"
    shadow.data.materials.append(SHADOW)
    parts.append(shadow)

    for part in parts:
        part.parent = root
    return root


def point_camera(camera, target=(0, 0, 0.55)):
    direction = Vector(target) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def setup_scene():
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.resolution_percentage = 100
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.world.color = (0.025, 0.021, 0.017)

    bpy.ops.object.light_add(type="AREA", location=(2.5, -4.5, 8))
    key = bpy.context.object
    key.name = "Warm factory key light"
    key.data.energy = 1250
    key.data.shape = "DISK"
    key.data.size = 5.0
    key.data.color = (1.0, 0.82, 0.64)

    bpy.ops.object.light_add(type="AREA", location=(-4, 3, 5))
    fill = bpy.context.object
    fill.name = "Neutral industrial fill"
    fill.data.energy = 280
    fill.data.size = 4.0
    fill.data.color = (0.72, 0.76, 0.78)

    bpy.ops.object.light_add(type="AREA", location=(0, 0, 8))
    top = bpy.context.object
    top.data.energy = 850
    top.data.size = 5

    bpy.ops.object.camera_add(location=(7.8, -9.2, 15.0))
    camera = bpy.context.object
    camera.name = "Factorio orthographic camera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 6.1
    point_camera(camera)
    scene.camera = camera
    return scene, camera


def render(scene, path, size):
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def main():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    scene, camera = setup_scene()
    roadster = build_roadster()

    shadow = bpy.data.objects.get("Ground contact shadow")
    color_parts = [obj for obj in bpy.context.scene.objects if obj != shadow and obj != camera and obj.type != "LIGHT"]

    roadster.rotation_euler.z = math.radians(18)
    render(scene, os.path.join(OUTPUT, "prototype-roadster-master.png"), 768)

    scene.render.resolution_x = 192
    scene.render.resolution_y = 192
    frames = os.path.join(OUTPUT, "directions")
    os.makedirs(frames, exist_ok=True)
    for index in range(64):
        roadster.rotation_euler.z = 2 * math.pi * index / 64
        if shadow:
            shadow.hide_render = True
        scene.render.filepath = os.path.join(frames, f"roadster-{index:02d}.png")
        bpy.ops.render.render(write_still=True)
        for part in color_parts:
            part.hide_render = True
        if shadow:
            shadow.hide_render = False
        scene.render.filepath = os.path.join(frames, f"roadster-shadow-{index:02d}.png")
        bpy.ops.render.render(write_still=True)
        for part in color_parts:
            part.hide_render = False

    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "prototype-roadster.blend"))


if __name__ == "__main__":
    main()
