import math
import os

import bpy
from mathutils import Vector


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
        noise.inputs["Scale"].default_value = variation.get("scale", 8.0)
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
    scene.world.color = (0.025, 0.021, 0.017)
    for location, energy, size, color in [
        ((3, -4.5, 8), 1250, 5.0, (1.0, 0.82, 0.64)),
        ((-4, 3, 5), 280, 4.0, (0.72, 0.76, 0.78)),
        ((0, 0, 8), 850, 5.0, (1.0, 0.96, 0.88)),
    ]:
        bpy.ops.object.light_add(type="AREA", location=location)
        lamp = bpy.context.object
        lamp.data.energy = energy
        lamp.data.size = size
        lamp.data.color = color
    bpy.ops.object.camera_add(location=(7.8, -9.2, 15.0))
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
    shadow = bpy.data.objects.get("Ground contact shadow")
    color_parts = [
        obj for obj in scene.objects
        if obj != shadow and obj != scene.camera and obj.type not in {"LIGHT", "EMPTY"}
    ]
    vehicle.rotation_euler.z = math.radians(18)
    scene.render.resolution_x = 768
    scene.render.resolution_y = 768
    scene.render.filepath = os.path.join(output, stem + "-master.png")
    bpy.ops.render.render(write_still=True)
    scene.render.resolution_x = 192
    scene.render.resolution_y = 192
    for index in range(64):
        vehicle.rotation_euler.z = 2 * math.pi * index / 64
        if shadow:
            shadow.hide_render = True
        scene.render.filepath = os.path.join(frames, f"{stem}-{index:02d}.png")
        bpy.ops.render.render(write_still=True)
        for part in color_parts:
            part.hide_render = True
        if shadow:
            shadow.hide_render = False
        scene.render.filepath = os.path.join(frames, f"{stem}-shadow-{index:02d}.png")
        bpy.ops.render.render(write_still=True)
        for part in color_parts:
            part.hide_render = False
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(root_dir, blend_name))
