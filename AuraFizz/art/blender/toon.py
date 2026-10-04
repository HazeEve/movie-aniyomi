# Aura Fizz toon kit for Blender (EEVEE): cel-shaded materials + inverted-hull outlines
import bpy, math, random
from mathutils import Vector
OUT = (0.16, 0.085, 0.05)   # warm dark-brown outline

def hexc(h):
    h = h.lstrip('#'); c = [int(h[i:i+2], 16)/255 for i in (0, 2, 4)]
    return tuple((x/12.92) if x <= 0.04045 else ((x+0.055)/1.055)**2.4 for x in c)

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_EEVEE'
    sc.render.film_transparent = True
    sc.view_settings.view_transform = 'Standard'
    w = bpy.data.worlds.new('w'); w.use_nodes = True
    w.node_tree.nodes['Background'].inputs[0].default_value = (0.9, 0.85, 0.8, 1); w.node_tree.nodes['Background'].inputs[1].default_value = 0.35
    sc.world = w
    return sc

_mats = {}
def toon(name, hexcol, shade=0.58, light=1.18, gloss=0.0, alpha=1.0, emit=0.0, warm=True):
    key = (name, hexcol, shade, light, gloss, alpha, emit)
    if key in _mats: return _mats[key]
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; N = nt.nodes; L = nt.links; N.clear()
    out = N.new('ShaderNodeOutputMaterial')
    base = hexc(hexcol)
    sh = tuple(min(1, c*shade*(0.92 if i == 0 else 1.0)*(1.06 if i == 2 else 1)) for i, c in enumerate(base))
    li = tuple(min(1, c*light + (0.03 if warm and i == 0 else 0)) for i, c in enumerate(base))
    dif = N.new('ShaderNodeBsdfDiffuse'); s2r = N.new('ShaderNodeShaderToRGB'); L.new(dif.outputs[0], s2r.inputs[0])
    ramp = N.new('ShaderNodeValToRGB'); ramp.color_ramp.interpolation = 'CONSTANT'
    e = ramp.color_ramp.elements; e[0].position = 0.0; e[0].color = (*sh, 1); e[1].position = 0.32; e[1].color = (*base, 1)
    e3 = e.new(0.78); e3.color = (*li, 1)
    L.new(s2r.outputs[0], ramp.inputs[0])
    col = ramp.outputs[0]
    if gloss > 0:
        g = N.new('ShaderNodeBsdfGlossy'); g.inputs['Roughness'].default_value = 0.25
        s3 = N.new('ShaderNodeShaderToRGB'); L.new(g.outputs[0], s3.inputs[0])
        r2 = N.new('ShaderNodeValToRGB'); r2.color_ramp.interpolation = 'CONSTANT'
        r2.color_ramp.elements[0].color = (0, 0, 0, 1); r2.color_ramp.elements[1].position = 0.55; r2.color_ramp.elements[1].color = (gloss, gloss, gloss, 1)
        L.new(s3.outputs[0], r2.inputs[0])
        add = N.new('ShaderNodeMixRGB'); add.blend_type = 'ADD'; add.inputs[0].default_value = 1
        L.new(col, add.inputs[1]); L.new(r2.outputs[0], add.inputs[2]); col = add.outputs[0]
    # soft ambient occlusion in the creases + a warm rim light
    ao = N.new('ShaderNodeAmbientOcclusion'); ao.inputs['Distance'].default_value = 0.15
    aom = N.new('ShaderNodeMapRange'); aom.inputs['To Min'].default_value = 0.72; L.new(ao.outputs['AO'], aom.inputs['Value'])
    mul = N.new('ShaderNodeMixRGB'); mul.blend_type = 'MULTIPLY'; mul.inputs[0].default_value = 1
    L.new(col, mul.inputs[1]); L.new(aom.outputs[0], mul.inputs[2]); col = mul.outputs[0]
    lw = N.new('ShaderNodeLayerWeight'); lw.inputs[0].default_value = 0.18
    rr = N.new('ShaderNodeValToRGB'); rr.color_ramp.interpolation = 'CONSTANT'
    rr.color_ramp.elements[0].color = (0, 0, 0, 1); rr.color_ramp.elements[1].position = 0.6; rr.color_ramp.elements[1].color = (0.10, 0.07, 0.03, 1)
    L.new(lw.outputs['Facing'], rr.inputs[0])
    ad2 = N.new('ShaderNodeMixRGB'); ad2.blend_type = 'ADD'; ad2.inputs[0].default_value = 1
    L.new(col, ad2.inputs[1]); L.new(rr.outputs[0], ad2.inputs[2]); col = ad2.outputs[0]
    em = N.new('ShaderNodeEmission'); L.new(col, em.inputs[0]); em.inputs[1].default_value = 1.0
    sh_out = em.outputs[0]
    if alpha < 1:
        tr = N.new('ShaderNodeBsdfTransparent'); mix = N.new('ShaderNodeMixShader'); mix.inputs[0].default_value = alpha
        L.new(tr.outputs[0], mix.inputs[1]); L.new(sh_out, mix.inputs[2]); sh_out = mix.outputs[0]
        m.surface_render_method = 'BLENDED'
    L.new(sh_out, out.inputs[0])
    _mats[key] = m
    return m

def outline_mat():
    if 'OUTLINE' in bpy.data.materials: return bpy.data.materials['OUTLINE']
    m = bpy.data.materials.new('OUTLINE'); m.use_nodes = True; N = m.node_tree.nodes; N.clear()
    o = N.new('ShaderNodeOutputMaterial'); e = N.new('ShaderNodeEmission'); e.inputs[0].default_value = (*OUT, 1)
    m.node_tree.links.new(e.outputs[0], o.inputs[0]); m.use_backface_culling = True
    return m

def finish(ob, mat, bevel=0.0, outline=0.016, smooth=True, seg=3):
    ob.data.materials.clear(); ob.data.materials.append(mat)
    if bevel > 0:
        b = ob.modifiers.new('bev', 'BEVEL'); b.width = bevel; b.segments = seg; b.limit_method = 'ANGLE'
    if smooth:
        for p in ob.data.polygons: p.use_smooth = True
    if outline > 0:
        ob.data.materials.append(outline_mat())
        s = ob.modifiers.new('ol', 'SOLIDIFY'); s.thickness = outline; s.offset = 1; s.use_flip_normals = True
        s.material_offset = len(ob.data.materials) - 1; s.use_rim = False
    return ob

def box(name, size, loc, mat, bevel=0.02, outline=0.016, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot); ob = bpy.context.object; ob.name = name
    ob.scale = size; bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(ob, mat, bevel, outline, smooth=False)

def cyl(name, r, h, loc, mat, rot=(0, 0, 0), verts=48, bevel=0.0, outline=0.016, r2=None):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=h, location=loc, rotation=rot, vertices=verts)
    else:
        bpy.ops.mesh.primitive_cone_add(radius1=r, radius2=r2, depth=h, location=loc, rotation=rot, vertices=verts)
    ob = bpy.context.object; ob.name = name
    return finish(ob, mat, bevel, outline, smooth=True)

def sphere(name, r, loc, mat, scale=(1, 1, 1), outline=0.008, seg=24):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=seg, ring_count=seg//2); ob = bpy.context.object; ob.name = name
    ob.scale = scale; bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(ob, mat, 0, outline, smooth=True)

def torus(name, R, r, loc, mat, rot=(0, 0, 0), outline=0.006):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, location=loc, rotation=rot, major_segments=48, minor_segments=12)
    ob = bpy.context.object; ob.name = name
    return finish(ob, mat, 0, outline, smooth=True)

def lights_and_camera(sc, target=(0, 0, 0.6), ortho=2.4, elev=12, azim=0, res=(1600, 1600)):
    sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN')); sc.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(52), math.radians(-22), math.radians(-28)); sun.data.energy = 3.2
    cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.type = 'ORTHO'; cam.data.ortho_scale = ortho
    d = 10; el = math.radians(elev); az = math.radians(azim)
    cam.location = (target[0] + d*math.sin(az)*math.cos(el), target[1] - d*math.cos(az)*math.cos(el), target[2] + d*math.sin(el))
    cam.rotation_euler = (math.radians(90) - el, 0, az)
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.eevee.taa_render_samples = 32
