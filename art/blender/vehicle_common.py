import math
import os

import bpy
from mathutils import Vector


def material(name, color, metallic=0.0, roughness=0.4, coat=0.35):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Coat Weight"].default_value = coat
    bsdf.inputs["Coat Roughness"].default_value = 0.16
    return mat


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


def wedge(name, front, rear, width, bottom, front_top, rear_top, mat, taper=0.92, radius=0.075):
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
    return bevel(obj, radius, 3 if radius > 0.03 else 1)


def wheel(name, x, y, z, radius, width, tire_mat, rim_mat, rim_sides=16):
    parts = []
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=radius, depth=width, location=(x, y, z), rotation=(math.pi / 2, 0, 0))
    tire = bpy.context.object
    tire.name = name + " tire"
    tire.data.materials.append(tire_mat)
    parts.append(bevel(tire, 0.035, 2))
    bpy.ops.mesh.primitive_cylinder_add(vertices=rim_sides, radius=radius * 0.64, depth=width + 0.012, location=(x, y, z), rotation=(math.pi / 2, 0, 0))
    rim = bpy.context.object
    rim.name = name + " wheel"
    rim.data.materials.append(rim_mat)
    parts.append(bevel(rim, 0.018, 2))
    return parts


def add_shadow(parts, mat, scale, z=0.16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, location=(0, 0, z), scale=(scale[0], scale[1], 0.025))
    shadow = bpy.context.object
    shadow.name = "Ground contact shadow"
    shadow.data.materials.append(mat)
    parts.append(shadow)


def parent_parts(root, parts):
    for part in parts:
        part.parent = root


def setup_scene(ortho_scale=6.8):
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
    camera.data.ortho_scale = ortho_scale
    camera.rotation_euler = (Vector((0, 0, 0.58)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera
    return scene


def render_vehicle(script_file, build, stem, blend_name, ortho_scale=6.8):
    root_dir = os.path.dirname(os.path.abspath(script_file))
    output = os.path.join(root_dir, "renders")
    frames = os.path.join(output, "directions")
    os.makedirs(frames, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    scene = setup_scene(ortho_scale)
    vehicle = build()
    vehicle.rotation_euler.z = math.radians(18)
    scene.render.resolution_x = 768
    scene.render.resolution_y = 768
    scene.render.filepath = os.path.join(output, stem + "-master.png")
    bpy.ops.render.render(write_still=True)
    scene.render.resolution_x = 192
    scene.render.resolution_y = 192
    for index in range(64):
        vehicle.rotation_euler.z = 2 * math.pi * index / 64
        scene.render.filepath = os.path.join(frames, f"{stem}-{index:02d}.png")
        bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(root_dir, blend_name))
