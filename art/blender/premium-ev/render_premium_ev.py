import math
import os

import bpy
from mathutils import Vector


ROOT = os.path.dirname(os.path.abspath(__file__))
OUTPUT = os.path.join(ROOT, "renders")
os.makedirs(OUTPUT, exist_ok=True)


def material(name, color, metallic=0.0, roughness=0.4):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Coat Weight"].default_value = 0.4
    bsdf.inputs["Coat Roughness"].default_value = 0.15
    return mat


BLACK = material("Obsidian black paint", (0.012, 0.016, 0.021, 1), 0.82, 0.17)
BLACK_LIT = material("Black body highlights", (0.045, 0.065, 0.08, 1), 0.75, 0.2)
GLASS = material("Panoramic smoked glass", (0.008, 0.02, 0.03, 1), 0.5, 0.1)
RUBBER = material("Tire rubber", (0.006, 0.007, 0.008, 1), 0.02, 0.65)
METAL = material("Machined wheel metal", (0.3, 0.34, 0.38, 1), 0.92, 0.15)
TRIM = material("Satin bright trim", (0.5, 0.55, 0.58, 1), 0.82, 0.22)
LIGHT = material("LED headlights", (0.8, 0.92, 1.0, 1), 0.2, 0.1)
TAIL = material("Continuous tail lamps", (1.0, 0.004, 0.002, 1), 0.2, 0.12)
SHADOW = material("Soft footprint shadow", (0.01, 0.012, 0.016, 0.3), 0.0, 1.0)
SHADOW.surface_render_method = "DITHERED"


def bevel(obj, width=0.08, segments=3):
    modifier = obj.modifiers.new("Manufactured edge radius", "BEVEL")
    modifier.width = width
    modifier.segments = segments
    modifier.limit_method = "ANGLE"
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.shade_smooth_by_angle()
    obj.select_set(False)
    return obj


def cube(name, location, scale, mat, radius=0.08):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    return bevel(obj, radius)


def wedge(name, front, rear, width, bottom, front_top, rear_top, mat, taper=0.92):
    vertices = [
        (front, -width, bottom), (front, width, bottom),
        (rear, -width, bottom), (rear, width, bottom),
        (front, -width * taper, front_top), (front, width * taper, front_top),
        (rear, -width * taper, rear_top), (rear, width * taper, rear_top),
    ]
    faces = [(0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4), (2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5)]
    mesh = bpy.data.meshes.new(name + " mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return bevel(obj, 0.075, 3)


def wheel(name, x, y):
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=0.47, depth=0.3, location=(x, y, 0.5), rotation=(math.pi / 2, 0, 0))
    tire = bpy.context.object
    tire.name = name + " tire"
    tire.data.materials.append(RUBBER)
    bevel(tire, 0.035, 2)
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.3, depth=0.31, location=(x, y, 0.5), rotation=(math.pi / 2, 0, 0))
    rim = bpy.context.object
    rim.name = name + " turbine wheel"
    rim.data.materials.append(METAL)
    bevel(rim, 0.018, 2)
    return tire, rim


def build_premium_ev():
    root = bpy.data.objects.new("Premium EV", None)
    bpy.context.collection.objects.link(root)
    parts = [
        cube("Long wheelbase battery floor", (0, 0, 0.5), (2.28, 0.94, 0.16), BLACK, 0.17),
        wedge("Sculpted front body", 2.45, 0.65, 0.92, 0.53, 0.7, 0.91, BLACK_LIT),
        wedge("Fastback rear body", 0.65, -2.38, 0.95, 0.53, 0.91, 0.73, BLACK),
        wedge("Raked windshield", 0.78, 0.12, 0.72, 0.88, 1.06, 1.42, GLASS, 0.9),
        wedge("Panoramic roof", 0.12, -1.18, 0.69, 1.02, 1.42, 1.3, GLASS, 0.92),
        wedge("Fastback rear glass", -1.18, -1.72, 0.67, 0.82, 1.3, 0.92, GLASS, 0.9),
        cube("Front lower intake", (2.37, 0, 0.39), (0.12, 0.73, 0.065), RUBBER, 0.03),
        cube("Left daylight lamp", (2.32, -0.61, 0.7), (0.085, 0.22, 0.045), LIGHT, 0.02),
        cube("Right daylight lamp", (2.32, 0.61, 0.7), (0.085, 0.22, 0.045), LIGHT, 0.02),
        cube("Full width tail lamp", (-2.31, 0, 0.73), (0.055, 0.72, 0.045), TAIL, 0.018),
        cube("Left window trim", (-0.25, -0.73, 1.13), (1.05, 0.025, 0.026), TRIM, 0.012),
        cube("Right window trim", (-0.25, 0.73, 1.13), (1.05, 0.025, 0.026), TRIM, 0.012),
        cube("Flush left door line", (-0.35, -0.935, 0.76), (0.025, 0.018, 0.28), TRIM, 0.008),
        cube("Flush right door line", (-0.35, 0.935, 0.76), (0.025, 0.018, 0.28), TRIM, 0.008),
    ]
    for x, y, label in [(1.5, -0.95, "front left"), (1.5, 0.95, "front right"), (-1.48, -0.95, "rear left"), (-1.48, 0.95, "rear right")]:
        parts.extend(wheel(label, x, y))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, location=(0, 0, 0.16), scale=(2.7, 1.28, 0.025))
    shadow = bpy.context.object
    shadow.name = "Ground contact shadow"
    shadow.data.materials.append(SHADOW)
    parts.append(shadow)
    for part in parts:
        part.parent = root
    return root


def point_camera(camera, target=(0, 0, 0.58)):
    camera.rotation_euler = (Vector(target) - camera.location).to_track_quat("-Z", "Y").to_euler()


def setup_scene():
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.resolution_percentage = 100
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.world.color = (0.03, 0.04, 0.055)
    for location, energy, size, color in [
        ((3, -4.5, 8), 1500, 5.0, (1.0, 0.78, 0.58)),
        ((-4, 3, 5), 1450, 4.0, (0.35, 0.68, 1.0)),
        ((0, 0, 8), 900, 5.0, (0.82, 0.9, 1.0)),
    ]:
        bpy.ops.object.light_add(type="AREA", location=location)
        lamp = bpy.context.object
        lamp.data.energy = energy
        lamp.data.size = size
        lamp.data.color = color
    bpy.ops.object.camera_add(location=(8.4, -10.0, 7.6))
    camera = bpy.context.object
    camera.name = "Factorio orthographic camera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 6.8
    point_camera(camera)
    scene.camera = camera
    return scene


def render(scene, root, path, size):
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def main():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    scene = setup_scene()
    car = build_premium_ev()
    car.rotation_euler.z = math.radians(18)
    render(scene, car, os.path.join(OUTPUT, "premium-ev-master.png"), 768)
    frames = os.path.join(OUTPUT, "directions")
    os.makedirs(frames, exist_ok=True)
    for index in range(64):
        car.rotation_euler.z = 2 * math.pi * index / 64
        render(scene, car, os.path.join(frames, f"premium-ev-{index:02d}.png"), 192)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "premium-ev.blend"))


if __name__ == "__main__":
    main()
