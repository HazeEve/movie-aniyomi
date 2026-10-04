# Aura Fizz painted-style FX flipbooks rendered in Blender (cel shading + warm outlines)
import sys, os, math, random; sys.path.insert(0, '.')
import bpy
from toon import *
OUTDIR = os.getcwd() + '/frames'
FR = 16
def scene():
    import toon as _T; _T._mats.clear()
    sc = reset(); sc.render.resolution_x = sc.render.resolution_y = 256
    sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN')); sc.collection.objects.link(sun); sun.rotation_euler = (math.radians(40), math.radians(-25), 0); sun.data.energy = 3
    cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.type = 'ORTHO'; cam.data.ortho_scale = 2.0; cam.location = (0, -10, 0); cam.rotation_euler = (math.radians(90), 0, 0)
    sc.eevee.taa_render_samples = 16
    return sc
def render(sc, name, f):
    os.makedirs(OUTDIR, exist_ok=True); sc.render.filepath = f'{OUTDIR}/{name}_{f:02d}.png'; bpy.ops.render.render(write_still=True)

def stream(name, col, light=1.15, width=0.07, splash=True, crema=None):
    for f in range(FR):
        sc = scene(); t = f / FR
        m = toon(name, col, shade=0.62, light=light, gloss=0.5)
        # wobbly stream: chain of overlapping tapered segments
        pts = 28
        for i in range(pts):
            y = 0.95 - i * (1.75 / pts)
            wob = 0.025 * math.sin(i * 0.8 + t * 2 * math.pi * 2) + 0.012 * math.sin(i * 2.1 - t * 2 * math.pi * 3)
            r = width * (0.75 + 0.25 * math.sin(i * 0.5 + t * 6.28)) * (1.0 if i > 2 else 0.85)
            o = sphere('s', r, (wob, 0, y), m, scale=(1, 1, 1.9), outline=0.012, seg=16)
        if crema:
            cm = toon(name + 'hl', crema, shade=0.9, light=1.0)
            for i in range(0, pts, 3):
                y = 0.9 - i * (1.75 / pts); wob = 0.025 * math.sin(i * 0.8 + t * 12.56)
                sphere('h', width * 0.25, (wob - width * 0.35, -0.05, y), cm, scale=(1, 1, 2.5), outline=0, seg=8)
        if splash:
            rnd = random.Random(f)
            for k in range(7):
                a = rnd.uniform(0.2, 2.94); sp = rnd.uniform(0.15, 0.4) * (0.5 + t % 0.25 * 2)
                sphere('d', rnd.uniform(0.02, 0.04), (math.cos(a) * sp, 0, -0.85 + abs(math.sin(a)) * sp * 0.6), m, outline=0.01, seg=10)
            sphere('pool', 0.28, (0, 0, -0.92), m, scale=(1.4, 1, 0.22), outline=0.012)
        render(sc, name, f)

def steam(name):
    for f in range(FR):
        sc = scene(); t = f / FR
        for k in range(5):
            ph = (t + k / 5) % 1.0
            y = -0.9 + ph * 1.8; x = 0.18 * math.sin(ph * 6 + k)
            a = math.sin(ph * math.pi)   # fade in/out
            m = toon(f'steam{k}_{f}', '#ffffff', shade=0.92, light=1.0, alpha=0.75 * a)
            sphere('p', 0.12 + 0.22 * ph, (x, 0, y), m, scale=(1.2, 1, 0.9), outline=0, seg=20)
        render(sc, name, f)

def bubbles(name, col='#fff7e6'):
    rnd = random.Random(7); B = [(rnd.uniform(-0.8, 0.8), rnd.uniform(0, 1), rnd.uniform(0.03, 0.09), rnd.uniform(0.6, 1.4)) for _ in range(22)]
    for f in range(FR):
        sc = scene(); t = f / FR
        m = toon('bub', col, shade=0.85, light=1.05, gloss=0.9, alpha=0.55)
        hl = toon('bubhl', '#ffffff', shade=1, light=1)
        for (x, p, r, sp) in B:
            ph = (p + t * sp) % 1.0; y = -0.95 + ph * 1.9; xx = x + 0.04 * math.sin(ph * 12)
            sphere('b', r, (xx, 0, y), m, outline=0.008, seg=16)
            sphere('h', r * 0.3, (xx - r * 0.35, -r, y + r * 0.35), hl, outline=0, seg=8)
        render(sc, name, f)

if __name__ == '__main__':
    which = sys.argv[-1]
    if which == 'espresso': stream('espresso', '#6a3418', crema='#d79a5e')
    if which == 'milk': stream('milk', '#fffaf0', light=1.02, width=0.085)
    if which == 'caramel': stream('caramel', '#c87a34', width=0.05, crema='#f2c27a')
    if which == 'soda': stream('soda', '#f2a73a', width=0.08, crema='#ffe0a0')
    if which == 'steam': steam('steam')
    if which == 'bubbles': bubbles('bubbles')
