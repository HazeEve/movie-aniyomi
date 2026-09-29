"""
blender_painted.py — the pastel painted style for Blender (4.x / 5.x).

Same idea as painted3d.js: an UNLIT emission material whose colour comes from
a 3-tone ramp driven by (normal . light_dir), broken up by noise ("brush"),
with a soft darker silhouette. Fully matte: no specular highlights.
No real lights needed, so it renders the same in Cycles, EEVEE and viewport.

Use inside Blender:   blender --background --python blender_painted.py -- --out render.png
Or as a module:       from blender_painted import painted_material, lathe, ...
Headless with pip bpy: python blender_painted.py --out render.png

Any hex colour works: tone() derives shade/light the same way paint.js does.
"""
import bpy, bmesh, math, colorsys, sys, argparse
from mathutils import Vector

LIGHT_DIR = Vector((-0.55, -0.75, 0.85)).normalized()   # Blender is Z-up; -Y is toward the camera
BG = "#232b3d"

# Fully MATTE, like the reference: no specular highlights, ever.
# Smooth/hard materials read through low noise and a crisper ramp instead.
FINISH = {  # noise, ramp edge (start, end), flat
    "matte":  (0.16, (0.18, 0.62), 0.0),   # fruit, clay, paper, wood
    "fuzzy":  (0.32, (0.10, 0.70), 0.0),   # peach, kiwi, fabric
    "rough":  (0.45, (0.20, 0.60), 0.0),   # stone, bread, bark
    "smooth": (0.07, (0.20, 0.60), 0.0),   # icing, candy, glaze, plastic
    "hard":   (0.05, (0.36, 0.54), 0.0),   # metal, glass, gems
    "flat":   (0.05, (0.18, 0.62), 0.75),  # cut faces / decals
}

# ---------------- colour ----------------
def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))

def rgb_hex(c):
    return "#" + "".join(f"{max(0, min(255, round(v * 255))):02x}" for v in c)

def _toward(h, target, amt):
    d = ((target - h + 540) % 360) - 180
    return h + math.copysign(min(abs(d), amt), d)

def tone(base, depth=0.12, lift=0.10):
    """Any hex -> (base, shade, light). Shadows go cooler, lights go warmer."""
    r, g, b = hex_rgb(base)
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    h *= 360
    grey = s < 0.08
    sh = colorsys.hls_to_rgb(((230 if grey else _toward(h, 245, 10)) % 360) / 360,
                             max(l * 0.6, l - depth - 0.05 * (1 - l)), 0.1 if grey else s * 0.88)
    li = colorsys.hls_to_rgb(((50 if grey else _toward(h, 55, 8)) % 360) / 360,
                             l + min(lift, (0.97 - l) * 0.5), 0.08 if grey else s)
    return base, rgb_hex(sh), rgb_hex(li)

def srgb_to_linear(c):
    return tuple(v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in c)

def lin(hexstr):
    return (*srgb_to_linear(hex_rgb(hexstr)), 1.0)

# ---------------- material ----------------
def painted_material(name, color, finish="matte", image=None):
    """color: hex or (base, shade, light). image: optional bpy image (cut faces / labels)."""
    base, shade, light = tone(color) if isinstance(color, str) else color
    noise_amt, (e0, e1), flat = FINISH[finish if not image else "flat"]
    m = bpy.data.materials.new(name)
    if not m.node_tree: m.use_nodes = True
    nt = m.node_tree; N = nt.nodes; L = nt.links
    N.clear()
    def node(t, x, y, **kw):
        n = N.new(t); n.location = (x, y)
        for k, v in kw.items(): setattr(n, k, v)
        return n
    def math_node(op, x, y, a=None, b=None):
        n = node("ShaderNodeMath", x, y, operation=op)
        if a is not None: n.inputs[0].default_value = a
        if b is not None: n.inputs[1].default_value = b
        return n

    geo = node("ShaderNodeNewGeometry", -1400, 0)
    ldir = node("ShaderNodeCombineXYZ", -1400, -250)
    ldir.inputs[0].default_value, ldir.inputs[1].default_value, ldir.inputs[2].default_value = LIGHT_DIR
    ndl = node("ShaderNodeVectorMath", -1200, 0, operation="DOT_PRODUCT")
    L.new(geo.outputs["Normal"], ndl.inputs[0]); L.new(ldir.outputs[0], ndl.inputs[1])
    half = math_node("MULTIPLY_ADD", -1000, 0, None, 0.5); half.inputs[2].default_value = 0.5
    L.new(ndl.outputs["Value"], half.inputs[0])

    # brush noise in object space
    tc = node("ShaderNodeTexCoord", -1400, -500)
    nz = node("ShaderNodeTexNoise", -1200, -500)
    nz.inputs["Scale"].default_value = 5.0; nz.inputs["Detail"].default_value = 3.0
    L.new(tc.outputs["Object"], nz.inputs["Vector"])
    nzc = math_node("SUBTRACT", -1000, -500, None, 0.5); L.new(nz.outputs["Fac"], nzc.inputs[0])
    nzs = math_node("MULTIPLY", -850, -500, None, noise_amt); L.new(nzc.outputs[0], nzs.inputs[0])
    t = math_node("ADD", -800, 0); L.new(half.outputs[0], t.inputs[0]); L.new(nzs.outputs[0], t.inputs[1])
    tflat = node("ShaderNodeMix", -650, 0, data_type="FLOAT")
    tflat.inputs["Factor"].default_value = flat
    L.new(t.outputs[0], tflat.inputs["A"]); tflat.inputs["B"].default_value = 0.62

    # base / shade / light: flat colours, or derived from the image
    if image:
        img = node("ShaderNodeTexImage", -1000, 400, image=image)
        L.new(tc.outputs["UV"], img.inputs["Vector"])
        c_base = img.outputs["Color"]
        mshade = node("ShaderNodeMix", -800, 500, data_type="RGBA", blend_type="MULTIPLY")
        mshade.inputs["Factor"].default_value = 1.0
        L.new(c_base, mshade.inputs[6]); mshade.inputs[7].default_value = lin("#d6ccdc")
        mlight = node("ShaderNodeMix", -800, 300, data_type="RGBA")
        mlight.inputs["Factor"].default_value = 0.1
        L.new(c_base, mlight.inputs[6]); mlight.inputs[7].default_value = (1, 1, 1, 1)
        c_shade, c_light = mshade.outputs[2], mlight.outputs[2]
    else:
        rb = node("ShaderNodeRGB", -800, 500); rb.outputs[0].default_value = lin(base)
        rs = node("ShaderNodeRGB", -800, 700); rs.outputs[0].default_value = lin(shade)
        rl = node("ShaderNodeRGB", -800, 300); rl.outputs[0].default_value = lin(light)
        c_base, c_shade, c_light = rb.outputs[0], rs.outputs[0], rl.outputs[0]

    # shade -> base (smoothstep e0..e1), then -> light (0.7..0.98)*0.75
    s1 = node("ShaderNodeMapRange", -450, 150, interpolation_type="SMOOTHSTEP")
    s1.inputs["From Min"].default_value, s1.inputs["From Max"].default_value = e0, e1
    L.new(tflat.outputs[0], s1.inputs["Value"])
    mix1 = node("ShaderNodeMix", -250, 250, data_type="RGBA")
    L.new(s1.outputs[0], mix1.inputs["Factor"]); L.new(c_shade, mix1.inputs[6]); L.new(c_base, mix1.inputs[7])
    s2 = node("ShaderNodeMapRange", -450, -100, interpolation_type="SMOOTHSTEP")
    s2.inputs["From Min"].default_value, s2.inputs["From Max"].default_value = 0.7, 0.98
    s2.inputs["To Max"].default_value = 0.75
    L.new(tflat.outputs[0], s2.inputs["Value"])
    mix2 = node("ShaderNodeMix", -50, 200, data_type="RGBA")
    L.new(s2.outputs[0], mix2.inputs["Factor"]); L.new(mix1.outputs[2], mix2.inputs[6]); L.new(c_light, mix2.inputs[7])

    # soft darker silhouette (never an outline)
    lw = node("ShaderNodeLayerWeight", -250, -300); lw.inputs["Blend"].default_value = 0.25
    fres = math_node("MULTIPLY", -50, -300, None, 0.3 * (1 - flat)); L.new(lw.outputs["Facing"], fres.inputs[0])
    fres_p = math_node("POWER", 50, -300, None, 1.6); L.new(fres.outputs[0], fres_p.inputs[0])
    mix3 = node("ShaderNodeMix", 150, 200, data_type="RGBA")
    L.new(fres_p.outputs[0], mix3.inputs["Factor"]); L.new(mix2.outputs[2], mix3.inputs[6]); L.new(c_shade, mix3.inputs[7])
    out_col = mix3.outputs[2]

    em = node("ShaderNodeEmission", 550, 200); L.new(out_col, em.inputs["Color"])
    out = node("ShaderNodeOutputMaterial", 750, 200); L.new(em.outputs[0], out.inputs["Surface"])
    return m

# ---------------- geometry helpers ----------------
def _link(obj):
    bpy.context.scene.collection.objects.link(obj)
    return obj

def lathe(name, profile, color, finish="matte", segments=48, angle=2 * math.pi):
    """profile: [(radius, height), ...] bottom->top (same format as profiles.js)."""
    # Catmull-Rom smooth the profile
    pts = [Vector((r, 0, y)) for r, y in profile]
    sm = []
    for i in range(len(pts) - 1):
        p0, p1, p2, p3 = pts[max(i - 1, 0)], pts[i], pts[i + 1], pts[min(i + 2, len(pts) - 1)]
        for k in range(6):
            t = k / 6
            sm.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3))
    sm.append(pts[-1])
    bm = bmesh.new()
    verts = [bm.verts.new((max(0, v.x), 0, v.z)) for v in sm]
    edges = [bm.edges.new((verts[i], verts[i + 1])) for i in range(len(verts) - 1)]
    bmesh.ops.spin(bm, geom=verts + edges, axis=(0, 0, 1), cent=(0, 0, 0), steps=segments, angle=angle)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = True
    obj = _link(bpy.data.objects.new(name, me))
    obj.data.materials.append(painted_material(name, color, finish))
    return obj

def blob(name, color, scale=(1, 1, 1), finish="matte", loc=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=32, location=loc)
    o = bpy.context.active_object; o.name = name; o.scale = scale
    bpy.ops.object.shade_smooth()
    o.data.materials.append(painted_material(name, color, finish))
    return o

def torus(name, color, R=0.62, r=0.32, finish="matte", loc=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, major_segments=56, minor_segments=28, location=loc)
    o = bpy.context.active_object; o.name = name
    bpy.ops.object.shade_smooth()
    o.data.materials.append(painted_material(name, color, finish))
    return o

def gem(name, color, loc=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=1, radius2=0.7, depth=0.45, location=loc)
    top = bpy.context.active_object
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=1, radius2=0, depth=1.1, location=(loc[0], loc[1], loc[2] - 0.78), rotation=(math.pi, 0, 0))
    tip = bpy.context.active_object
    mat = painted_material(name, color, "hard")
    for o in (top, tip): o.data.materials.append(mat)
    bpy.ops.object.select_all(action="DESELECT")
    tip.select_set(True); top.select_set(True); bpy.context.view_layer.objects.active = top
    bpy.ops.object.join()                      # one object so it scales as a unit
    top.name = name
    return top

# ---------------- stage ----------------
def stage(bg=BG, res=(1440, 810)):
    sc = bpy.context.scene
    for o in list(sc.objects): bpy.data.objects.remove(o, do_unlink=True)
    sc.render.engine = "CYCLES"                 # emission-only: fast & identical to EEVEE
    sc.cycles.samples = 16; sc.cycles.use_denoising = False; sc.cycles.device = "CPU"
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.view_settings.view_transform = "Standard"  # keep palette hex = pixel hex
    sc.view_settings.look = "None"
    w = bpy.data.worlds.new("bg")
    if hasattr(w, "use_nodes") and not w.node_tree: w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = lin(bg)
    sc.world = w
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    cam.data.lens = 50
    cam.location = (0, -30, 3.6); cam.rotation_euler = (math.radians(83), 0, 0)
    _link(cam); sc.camera = cam
    return sc

APPLE = [(0, 0.1), (0.22, 0.01), (0.46, 0.08), (0.6, 0.28), (0.66, 0.52), (0.62, 0.76), (0.46, 0.93), (0.24, 0.92), (0.08, 0.84), (0, 0.82)]
PEAR = [(0, 0.02), (0.28, 0.0), (0.5, 0.14), (0.56, 0.36), (0.46, 0.62), (0.32, 0.82), (0.26, 1.0), (0.17, 1.15), (0.05, 1.19), (0, 1.18)]
POT = [(0, 0), (0.4, 0), (0.5, 0.6), (0.58, 0.62), (0.6, 0.78), (0, 0.78)]
MUG = [(0, 0), (0.45, 0), (0.5, 0.1), (0.5, 0.95), (0.44, 0.97), (0.42, 0.9), (0, 0.9)]

def demo():
    """A small mixed lineup: fruit, food, objects, arbitrary colours."""
    stage()
    s = 1.3
    items = [
        lathe("apple", APPLE, "#dc4a3c", "smooth"),
        lathe("pear", PEAR, "#cbd98c"),
        blob("orange", "#f28b1f", (0.8, 0.8, 0.74)),
        torus("donut", "#f59ac0", finish="smooth"),
        lathe("pot", POT, "#d9774c"),
        lathe("mug", MUG, "#7ab8e6", "smooth"),
        blob("rock", "#8e97aa", (0.8, 0.7, 0.6), "rough"),
        blob("berry", "#4f58ba", (0.5, 0.5, 0.45)),
    ]
    for i, o in enumerate(items):
        o.location = (-8.4 + i * 2.1, 0, 0.3)
        o.scale = tuple(v * s for v in o.scale)
    items[3].rotation_euler = (math.radians(55), 0, 0)
    g = gem("gem", "#6fd3c8", loc=(8.4, 0, 1.3)); g.scale = (0.7, 0.7, 0.7)
    # colour-freedom row
    for i, c in enumerate(["#ff5d8f", "#ff9f1c", "#ffd23f", "#9bde7e", "#2ec4b6", "#3a86ff", "#8338ec", "#1d1d1d"]):
        blob(f"sw{i}", c, (0.45, 0.45, 0.45), "smooth" if i % 3 == 0 else "matte", loc=(-7.35 + i * 2.1, 0, -2.3))

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser(); ap.add_argument("--out", default="painted_demo.png")
    a = ap.parse_args(argv)
    demo()
    bpy.context.scene.render.filepath = a.out
    bpy.ops.render.render(write_still=True)
    print("wrote", a.out)
