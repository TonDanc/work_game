"""Builds the Lab 6 character in Blender and exports it for Godot.

Run:  blender --background --python build_character.py
Output: student.blend and student.glb next to this script.

The armature uses Mixamo bone names (mixamorig:Hips, ...) in a T-pose so that
Godot can retarget it with "Mixamo BoneMap.tres" from Godot4-OpenAnimationLibraries
and play MeleeLib / ShooterLib animations on it.
"""
import math
import os

import bmesh
import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
P = "mixamorig:"

# ---------------------------------------------------------------- scene reset
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


# ---------------------------------------------------------------- materials
def material(name, color, image=None, rough=0.8):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Roughness"].default_value = rough
    if image:
        tex = m.node_tree.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(image)
        m.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    return m


def srgb(r, g, b):
    # Blender colours are linear; convert from 0-255 sRGB
    f = lambda c: (c / 255) ** 2.2
    return (f(r), f(g), f(b))


MATS = {
    "Face": material("Face", srgb(241, 194, 160), os.path.join(HERE, "face.png")),
    "Skin": material("Skin", srgb(241, 194, 160)),
    "Shirt": material("Shirt", srgb(245, 245, 245)),
    "Pants": material("Pants", srgb(30, 32, 40)),
    "Shoe": material("Shoe", srgb(20, 20, 22), rough=0.4),
    "Hair": material("Hair", srgb(40, 28, 22)),
    "Belt": material("Belt", srgb(90, 60, 30)),
    "Badge": material("Badge", srgb(40, 90, 200)),
}

# ---------------------------------------------------------------- armature (T-pose, facing -Y)
BONES = [
    # name, head, tail, parent
    ("Hips", (0, 0, 0.95), (0, 0, 1.05), None),
    ("Spine", (0, 0, 1.05), (0, 0, 1.17), "Hips"),
    ("Spine1", (0, 0, 1.17), (0, 0, 1.30), "Spine"),
    ("Spine2", (0, 0, 1.30), (0, 0, 1.46), "Spine1"),
    ("Neck", (0, 0, 1.46), (0, 0, 1.56), "Spine2"),
    ("Head", (0, 0, 1.56), (0, 0, 1.80), "Neck"),
    ("HeadTop_End", (0, 0, 1.80), (0, 0, 1.86), "Head"),
]
for side, sx in (("Left", 1), ("Right", -1)):
    BONES += [
        (f"{side}Shoulder", (0.05 * sx, 0, 1.42), (0.17 * sx, 0, 1.42), "Spine2"),
        (f"{side}Arm", (0.17 * sx, 0, 1.42), (0.45 * sx, 0, 1.42), f"{side}Shoulder"),
        (f"{side}ForeArm", (0.45 * sx, 0, 1.42), (0.70 * sx, 0, 1.42), f"{side}Arm"),
        (f"{side}Hand", (0.70 * sx, 0, 1.42), (0.80 * sx, 0, 1.42), f"{side}ForeArm"),
        (f"{side}UpLeg", (0.10 * sx, 0, 0.92), (0.10 * sx, 0, 0.50), "Hips"),
        (f"{side}Leg", (0.10 * sx, 0, 0.50), (0.10 * sx, 0, 0.09), f"{side}UpLeg"),
        (f"{side}Foot", (0.10 * sx, 0, 0.09), (0.10 * sx, -0.11, 0.02), f"{side}Leg"),
        (f"{side}ToeBase", (0.10 * sx, -0.11, 0.02), (0.10 * sx, -0.19, 0.02), f"{side}Foot"),
        (f"{side}Toe_End", (0.10 * sx, -0.19, 0.02), (0.10 * sx, -0.23, 0.02), f"{side}ToeBase"),
    ]

arm_data = bpy.data.armatures.new("Armature")
rig = bpy.data.objects.new("Armature", arm_data)
scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
for name, head, tail, parent in BONES:
    b = arm_data.edit_bones.new(P + name)
    b.head, b.tail = Vector(head), Vector(tail)
    if parent:
        b.parent = arm_data.edit_bones[P + parent]
        b.use_connect = (Vector(head) - arm_data.edit_bones[P + parent].tail).length < 1e-4
bpy.ops.object.mode_set(mode="OBJECT")

# ---------------------------------------------------------------- body parts
parts = []


def finish(obj, bone, mat, smooth=False):
    """Rigidly bind a part to one bone and give it a material."""
    obj.data.materials.append(MATS[mat])
    vg = obj.vertex_groups.new(name=P + bone)
    vg.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    for poly in obj.data.polygons:
        poly.use_smooth = smooth
    parts.append(obj)
    return obj


def cyl(a, b, r, bone, mat, verts=10, ry=None):
    """Cylinder from point a to point b (optionally elliptical: ry)."""
    a, b = Vector(a), Vector(b)
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=(b - a).length)
    o = bpy.context.object
    if ry:
        o.scale.y = ry / r
        bpy.ops.object.transform_apply(scale=True)
    o.rotation_mode = "QUATERNION"
    o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(b - a)
    o.location = (a + b) / 2
    return finish(o, bone, mat, smooth=True)


def sphere(c, r, bone, mat, scale=(1, 1, 1), seg=16, ring=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=ring, radius=r, location=c)
    o = bpy.context.object
    o.scale = scale
    return finish(o, bone, mat, smooth=True)


def box(c, size, bone, mat, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=c)
    o = bpy.context.object
    o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    if bevel:
        mod = o.modifiers.new("Bevel", "BEVEL")
        mod.width, mod.segments = bevel, 2
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(o, bone, mat)


# Head with spherical UVs so face.png wraps around the front
HEAD_C = Vector((0, 0, 1.66))
bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=16, radius=0.13, location=HEAD_C)
head = bpy.context.object
head.scale = (1, 1, 1.12)
bpy.ops.object.transform_apply(scale=True, location=False)
bm = bmesh.new()
bm.from_mesh(head.data)
uv = bm.loops.layers.uv.verify()
for f in bm.faces:
    us = []
    for loop in f.loops:
        p = loop.vert.co
        u = 0.5 + math.atan2(p.x, -p.y) / (2 * math.pi)
        v = 0.5 + math.asin(max(-1, min(1, p.z / p.length))) / math.pi
        us.append([u, v])
    # Fix the seam at the back of the head
    if max(x[0] for x in us) - min(x[0] for x in us) > 0.5:
        for x in us:
            if x[0] < 0.5:
                x[0] += 1
    for loop, x in zip(f.loops, us):
        loop[uv].uv = x
bm.to_mesh(head.data)
bm.free()
finish(head, "Head", "Face", smooth=True)

# Hair: a cap over the head with the face area cut away
bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=16, radius=0.142, location=HEAD_C + Vector((0, 0.008, 0.02)))
hair = bpy.context.object
hair.scale = (1, 1, 1.1)
bpy.ops.object.transform_apply(scale=True, location=False)
bm = bmesh.new()
bm.from_mesh(hair.data)
cut = [v for v in bm.verts if (v.co.y < -0.035 and v.co.z < 0.045) or v.co.z < -0.04]
bmesh.ops.delete(bm, geom=cut, context="VERTS")
bm.to_mesh(hair.data)
bm.free()
mod = hair.modifiers.new("Solid", "SOLIDIFY")
mod.thickness = 0.015
bpy.context.view_layer.objects.active = hair
bpy.ops.object.modifier_apply(modifier=mod.name)
finish(hair, "Head", "Hair", smooth=True)

# Neck & torso (university uniform: white shirt, black trousers)
cyl((0, 0, 1.44), (0, 0, 1.57), 0.05, "Neck", "Skin")
cyl((0, 0, 1.28), (0, 0, 1.47), 0.19, "Spine2", "Shirt", ry=0.12)
cyl((0, 0, 1.13), (0, 0, 1.30), 0.17, "Spine1", "Shirt", ry=0.11)
cyl((0, 0, 1.00), (0, 0, 1.15), 0.16, "Spine", "Shirt", ry=0.105)
cyl((0, 0, 0.97), (0, 0, 1.02), 0.165, "Hips", "Belt", ry=0.11)
cyl((0, 0, 0.84), (0, 0, 0.98), 0.165, "Hips", "Pants", ry=0.11)
box((-0.08, -0.12, 1.36), (0.07, 0.01, 0.04), "Spine2", "Badge")  # name badge on the chest
for i, z in enumerate((1.40, 1.31, 1.22, 1.13, 1.05)):
    sphere((0, -0.118 + (0.01 if z < 1.2 else 0), z), 0.008, "Spine2" if z > 1.28 else ("Spine1" if z > 1.13 else "Spine"), "Pants", seg=6, ring=4)

for side, sx in (("Left", 1), ("Right", -1)):
    sphere((0.17 * sx, 0, 1.42), 0.075, "Spine2", "Shirt")
    cyl((0.17 * sx, 0, 1.42), (0.33 * sx, 0, 1.42), 0.065, f"{side}Arm", "Shirt")
    cyl((0.32 * sx, 0, 1.42), (0.46 * sx, 0, 1.42), 0.045, f"{side}Arm", "Skin")
    sphere((0.45 * sx, 0, 1.42), 0.046, f"{side}ForeArm", "Skin")
    cyl((0.45 * sx, 0, 1.42), (0.70 * sx, 0, 1.42), 0.04, f"{side}ForeArm", "Skin")
    box((0.75 * sx, 0, 1.42), (0.10, 0.035, 0.08), f"{side}Hand", "Skin", bevel=0.012)
    box((0.72 * sx, -0.04, 1.42), (0.04, 0.03, 0.025), f"{side}Hand", "Skin", bevel=0.006)  # thumb
    cyl((0.10 * sx, 0, 0.93), (0.10 * sx, 0, 0.49), 0.075, f"{side}UpLeg", "Pants")
    sphere((0.10 * sx, 0, 0.50), 0.066, f"{side}Leg", "Pants")
    cyl((0.10 * sx, 0, 0.50), (0.10 * sx, 0, 0.08), 0.062, f"{side}Leg", "Pants")
    box((0.10 * sx, -0.02, 0.05), (0.10, 0.16, 0.09), f"{side}Foot", "Shoe", bevel=0.02)
    box((0.10 * sx, -0.14, 0.035), (0.10, 0.10, 0.07), f"{side}ToeBase", "Shoe", bevel=0.02)

# Join everything into one skinned mesh
bpy.ops.object.select_all(action="DESELECT")
for o in parts:
    o.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.join()
body = bpy.context.object
body.name = "StudentBody"
body.data.name = "StudentBody"
body.parent = rig
mod = body.modifiers.new("Armature", "ARMATURE")
mod.object = rig

# ---------------------------------------------------------------- one T-pose animation (needed for Godot's AnimationPlayer)
rig.animation_data_create()
action = bpy.data.actions.new("TPose")
rig.animation_data.action = action
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="POSE")
for pb in rig.pose.bones:
    pb.rotation_mode = "QUATERNION"
    for f in (1, 10):
        pb.keyframe_insert("rotation_quaternion", frame=f)
        pb.keyframe_insert("location", frame=f)
bpy.ops.object.mode_set(mode="OBJECT")
scene.frame_start, scene.frame_end = 1, 10

# ---------------------------------------------------------------- save & export
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "student.blend"))
bpy.ops.export_scene.gltf(
    filepath=os.path.join(HERE, "student.glb"),
    export_format="GLB",
    export_animations=True,
    export_yup=True,
    export_apply=False,
)
print("EXPORT OK", len(body.data.vertices), "verts")
