# Aura Fizz "soft illustrated 3D" kit: stylized PBR + thin warm outlines, soft light, AO
import bpy, math, random
from toon import hexc, outline_mat, OUT
_m = {}
def mat(name, hexcol, rough=0.45, metal=0.0, alpha=1.0, trans=0.0, emit=0.0, coat=0.0, sss=0.0):
    k = (name, hexcol, rough, metal, alpha, trans, emit)
    if k in _m: return _m[k]
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*hexc(hexcol), 1)
    b.inputs['Roughness'].default_value = rough; b.inputs['Metallic'].default_value = metal
    if trans: b.inputs['Transmission Weight'].default_value = trans; b.inputs['IOR'].default_value = 1.2
    if coat: b.inputs['Coat Weight'].default_value = coat; b.inputs['Coat Roughness'].default_value = 0.08
    if sss: b.inputs['Subsurface Weight'].default_value = sss
    if emit: b.inputs['Emission Color'].default_value = (*hexc(hexcol), 1); b.inputs['Emission Strength'].default_value = emit
    if alpha < 1:
        b.inputs['Alpha'].default_value = alpha
    if alpha < 1 or trans:
        m.surface_render_method = 'BLENDED' if alpha < 1 else 'DITHERED'
        try: m.use_raytrace_refraction = True
        except Exception: pass
    _m[k] = m
    return m

def finish(ob, m, bevel=0.0, outline=0.009, smooth=True, seg=3):
    ob.data.materials.clear(); ob.data.materials.append(m)
    if bevel > 0:
        bv = ob.modifiers.new('bev', 'BEVEL'); bv.width = bevel; bv.segments = seg; bv.limit_method = 'ANGLE'
    if smooth:
        for p in ob.data.polygons: p.use_smooth = True
        try: ob.data.set_sharp_from_angle(angle=math.radians(40))
        except Exception: pass
    if outline > 0:
        ob.data.materials.append(outline_mat())
        s = ob.modifiers.new('ol', 'SOLIDIFY'); s.thickness = outline; s.offset = 1; s.use_flip_normals = True
        s.material_offset = len(ob.data.materials) - 1; s.use_rim = False
    return ob
def _ap(): bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
def box(n, size, loc, m, bevel=0.02, outline=0.009, rot=(0,0,0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot); o = bpy.context.object; o.name = n; o.scale = size; _ap()
    return finish(o, m, bevel, outline, smooth=bevel > 0)
def cyl(n, r, h, loc, m, rot=(0,0,0), r2=None, outline=0.009, verts=64, bevel=0.0):
    if r2 is None: bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=h, location=loc, rotation=rot, vertices=verts)
    else: bpy.ops.mesh.primitive_cone_add(radius1=r, radius2=r2, depth=h, location=loc, rotation=rot, vertices=verts)
    o = bpy.context.object; o.name = n; return finish(o, m, bevel, outline)
def sph(n, r, loc, m, scale=(1,1,1), outline=0.004, seg=24, rot=(0,0,0)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=seg, ring_count=seg//2, rotation=rot); o = bpy.context.object; o.name = n; o.scale = scale; _ap()
    return finish(o, m, 0, outline)
def tor(n, R, r, loc, m, rot=(0,0,0), outline=0.003):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, location=loc, rotation=rot, major_segments=64, minor_segments=14); o = bpy.context.object; o.name = n
    return finish(o, m, 0, outline)
def imgmat(name, path, rough=0.4):
    m = bpy.data.materials.new(name); m.use_nodes = True; N = m.node_tree.nodes
    t = N.new('ShaderNodeTexImage'); t.image = bpy.data.images.load(path)
    m.node_tree.links.new(t.outputs[0], N['Principled BSDF'].inputs['Base Color']); N['Principled BSDF'].inputs['Roughness'].default_value = rough
    return m
def setup(res=(1920, 1080)):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene; sc.render.engine = 'BLENDER_EEVEE'
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.view_settings.view_transform = 'Standard'; sc.view_settings.look = 'Medium High Contrast'
    e = sc.eevee; e.taa_render_samples = 48
    for a, v in (('use_raytracing', True), ('use_shadows', True), ('fast_gi_distance', 0.6), ('use_fast_gi', True)):
        try: setattr(e, a, v)
        except Exception: pass
    w = bpy.data.worlds.new('w'); w.use_nodes = True; bg = w.node_tree.nodes['Background']
    bg.inputs[0].default_value = (*hexc('#f6d7b0'), 1); bg.inputs[1].default_value = 0.45; sc.world = w
    return sc
def light(kind, loc, rot, energy, color='#fff1dc', size=2.0):
    L = bpy.data.lights.new(kind, kind); L.energy = energy; L.color = hexc(color)
    if kind == 'AREA': L.size = size
    if kind == 'SUN': L.angle = math.radians(8)
    o = bpy.data.objects.new(kind, L); bpy.context.scene.collection.objects.link(o); o.location = loc; o.rotation_euler = rot
    return o
def camera(target, dist, elev, lens=70, az=0):
    sc = bpy.context.scene; c = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(c); sc.camera = c
    c.data.lens = lens; el = math.radians(elev); a = math.radians(az)
    c.location = (target[0] + dist*math.sin(a)*math.cos(el), target[1] - dist*math.cos(a)*math.cos(el), target[2] + dist*math.sin(el))
    c.rotation_euler = (math.radians(90) - el, 0, a)
    c.data.dof.use_dof = False
    return c
