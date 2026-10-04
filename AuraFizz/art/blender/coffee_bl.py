import sys, math, random; sys.path.insert(0, '.')
from toon import *
sc = reset()
BLACK = toon('black', '#25221f', shade=0.55, light=1.45, gloss=0.3)
PANEL = toon('panel', '#3e3a37', shade=0.6, light=1.3, gloss=0.25)
STEEL = toon('steel', '#c9ced6', shade=0.62, light=1.12, gloss=0.6)
DARKSTEEL = toon('dsteel', '#8d939d', shade=0.6, light=1.2, gloss=0.5)
GOLD = toon('gold', '#d6a043', shade=0.62, light=1.22, gloss=0.6)
WHITE = toon('white', '#fbf6ee', shade=0.8, light=1.04, gloss=0.35)
SCREEN = toon('screen', '#14324f', shade=0.9, light=1.1)
CYAN = toon('cyan', '#7fe6ff', shade=1, light=1)
GLASS = toon('glass', '#e8f4fb', shade=0.85, light=1.05, gloss=0.8, alpha=0.32)
COFFEEGROUND = toon('grounds', '#c39a74', shade=0.7, light=1.12)
ESP = toon('esp', '#6a3a1e', shade=0.7, light=1.2)
MARBLE = toon('marble', '#f6ecdb', shade=0.82, light=1.04, gloss=0.2)
CAB = toon('cab', '#201d1b', shade=0.6, light=1.35, gloss=0.2)
GAUGEF = toon('gface', '#fffaf0', shade=0.9, light=1.0)
RED = toon('red', '#d9473a', shade=0.8, light=1.1)

# ---- counter (cream marble, gold edge, black & gold cabinet) ----
box('marble', (6.4, 1.2, 0.08), (0, 0.1, -0.04), MARBLE, bevel=0.015)
box('goldedge', (6.42, 0.02, 0.025), (0, -0.505, -0.075), GOLD, bevel=0.005, outline=0.004)
box('cab', (6.3, 1.1, 0.8), (0, 0.15, -0.5), CAB, bevel=0.01)
for x in (-2.2, -1.1, 0, 1.1, 2.2):
    for (sx, sz, dx, dz) in ((0.98, 0.012, 0, 0.3), (0.98, 0.012, 0, -0.3), (0.012, 0.6, -0.49, 0), (0.012, 0.6, 0.49, 0)):
        box('trim', (sx, 0.01, sz), (x+dx, -0.405, -0.5+dz), GOLD, bevel=0, outline=0)
    box('handle', (0.16, 0.02, 0.02), (x, -0.41, -0.2), GOLD, bevel=0.005, outline=0.004)

# ---- machine body ----
Y0 = -0.05
box('body', (1.3, 0.8, 1.0), (0, Y0+0.1, 0.55), BLACK, bevel=0.03)
box('frontpanel', (1.24, 0.03, 0.36), (0, Y0-0.31, 0.86), PANEL, bevel=0.012)
box('toptrim', (1.26, 0.012, 0.012), (0, Y0-0.33, 1.045), GOLD, bevel=0, outline=0.003)
box('midtrim', (1.26, 0.012, 0.012), (0, Y0-0.33, 0.675), GOLD, bevel=0, outline=0.003)
box('sidetrim', (0.012, 0.012, 0.95), (0.645, Y0-0.3, 0.55), GOLD, bevel=0, outline=0)
box('topplate', (1.32, 0.82, 0.04), (0, Y0+0.1, 1.07), STEEL, bevel=0.01)
box('recess', (1.12, 0.05, 0.5), (0, Y0-0.29, 0.38), toon('rec', '#1b1917', shade=0.7, light=1.2), bevel=0.02, outline=0.006)
# display + buttons + knobs + gauge
box('screen', (0.3, 0.02, 0.17), (-0.2, Y0-0.33, 0.9), SCREEN, bevel=0.012, outline=0.006)
box('ui1', (0.2, 0.005, 0.012), (-0.2, Y0-0.343, 0.86), CYAN, bevel=0, outline=0)
for i, x in enumerate((-0.25, -0.2, -0.15)):
    cyl('dot', 0.018, 0.006, (x, Y0-0.343, 0.92), CYAN, rot=(math.pi/2, 0, 0), outline=0)
for i in range(4):
    box('btn', (0.05, 0.03, 0.035), (-0.3+i*0.066, Y0-0.335, 0.77), DARKSTEEL, bevel=0.01, outline=0.005)
cyl('knobL', 0.055, 0.06, (-0.5, Y0-0.35, 0.9), BLACK, rot=(math.pi/2, 0, 0), outline=0.006)
cyl('knobLg', 0.03, 0.065, (-0.5, Y0-0.355, 0.9), GOLD, rot=(math.pi/2, 0, 0), outline=0.004)
cyl('knobR', 0.055, 0.06, (0.5, Y0-0.35, 0.85), BLACK, rot=(math.pi/2, 0, 0), outline=0.006)
cyl('knobRg', 0.035, 0.07, (0.5, Y0-0.36, 0.85), GOLD, rot=(math.pi/2, 0, 0), outline=0.004)
cyl('gaugeB', 0.12, 0.05, (0.2, Y0-0.345, 0.87), STEEL, rot=(math.pi/2, 0, 0), outline=0.008)
cyl('gaugeF', 0.1, 0.05, (0.2, Y0-0.35, 0.87), GAUGEF, rot=(math.pi/2, 0, 0), outline=0.004)
for k in range(9):
    a = math.radians(-120 + k*30)
    box('tick', (0.004, 0.004, 0.022), (0.2+0.082*math.sin(a), Y0-0.377, 0.87+0.082*math.cos(a)), PANEL, bevel=0, outline=0, rot=(0, -a, 0))
box('needle', (0.006, 0.004, 0.08), (0.2+0.02, Y0-0.38, 0.87+0.03), RED, bevel=0, outline=0, rot=(0, math.radians(-40), 0))
cyl('hub', 0.012, 0.01, (0.2, Y0-0.382, 0.87), PANEL, rot=(math.pi/2, 0, 0), outline=0)
# group head + portafilter + cup
cyl('group', 0.11, 0.08, (-0.08, Y0-0.24, 0.6), STEEL, outline=0.008)
cyl('basket', 0.09, 0.06, (-0.08, Y0-0.24, 0.53), DARKSTEEL, outline=0.008)
box('pfh', (0.3, 0.05, 0.05), (-0.3, Y0-0.33, 0.52), BLACK, bevel=0.022, rot=(0, math.radians(-18), math.radians(-28)))
cyl('pfring', 0.03, 0.03, (-0.2, Y0-0.3, 0.535), GOLD, rot=(0, math.radians(72), math.radians(-28)), outline=0.004)
cyl('spout1', 0.012, 0.06, (-0.11, Y0-0.24, 0.47), DARKSTEEL, outline=0.004)
cyl('spout2', 0.012, 0.06, (-0.05, Y0-0.24, 0.47), DARKSTEEL, outline=0.004)
cyl('cup', 0.075, 0.12, (-0.08, Y0-0.26, 0.24), WHITE, r2=0.09, verts=48, outline=0.007)
torus('cupgold', 0.09, 0.008, (-0.08, Y0-0.26, 0.302), GOLD, outline=0.002)
cyl('crema', 0.083, 0.01, (-0.08, Y0-0.26, 0.295), toon('crema', '#b9773f', shade=0.8, light=1.15), outline=0)
torus('handle', 0.04, 0.012, (0.0, Y0-0.26, 0.24), WHITE, rot=(math.pi/2, 0, 0))
for x in (-0.11, -0.05):
    cyl('stream', 0.006, 0.14, (x, Y0-0.24, 0.37), ESP, outline=0)
# steam wand (left) + hot water hook (right)
cyl('wand', 0.016, 0.38, (-0.56, Y0-0.33, 0.48), STEEL, rot=(0, math.radians(8), 0), outline=0.005)
sphere('wandtip', 0.024, (-0.585, Y0-0.33, 0.3), STEEL, outline=0.004)
box('hook', (0.14, 0.03, 0.025), (0.3, Y0-0.32, 0.5), STEEL, bevel=0.01, outline=0.004)
# drip tray grill
box('tray', (0.9, 0.34, 0.06), (0, Y0-0.4, 0.13), STEEL, bevel=0.012)
for i in range(13):
    box('slot', (0.012, 0.28, 0.01), (-0.36+i*0.06, Y0-0.4, 0.165), DARKSTEEL, bevel=0, outline=0)
box('trayfront', (0.92, 0.02, 0.06), (0, Y0-0.575, 0.13), GOLD, bevel=0.006, outline=0.004)
box('base', (1.3, 0.8, 0.08), (0, Y0+0.1, 0.06), BLACK, bevel=0.01)
# cup rail + cups on top (left)
for x in (-0.6, -0.05):
    cyl('post', 0.008, 0.12, (x, Y0-0.22, 1.15), STEEL, outline=0.003)
cyl('rail', 0.008, 0.56, (-0.325, Y0-0.22, 1.21), STEEL, rot=(0, math.pi/2, 0), outline=0.003)
for i, (x, y) in enumerate(((-0.48, 0.05), (-0.3, 0.12), (-0.2, -0.02))):
    cyl('topcup', 0.06, 0.1, (x, Y0+y, 1.14), WHITE, r2=0.072, outline=0.006)
    torus('topcuprim', 0.072, 0.008, (x, Y0+y, 1.19), GOLD, outline=0.002)
    cyl('topcupin', 0.066, 0.004, (x, Y0+y, 1.186), WHITE, outline=0)
# grinder jar (right top)
cyl('gbase', 0.13, 0.09, (0.38, Y0+0.12, 1.135), BLACK, outline=0.008)
cyl('gring', 0.135, 0.02, (0.38, Y0+0.12, 1.18), GOLD, outline=0.004)
cyl('gjar', 0.12, 0.26, (0.38, Y0+0.12, 1.32), GLASS, r2=0.135, outline=0.008)
cyl('ggrounds', 0.11, 0.14, (0.38, Y0+0.12, 1.26), COFFEEGROUND, r2=0.12, outline=0)
sphere('glid', 0.14, (0.38, Y0+0.12, 1.45), BLACK, scale=(1, 1, 0.42), outline=0.008)
sphere('gknob', 0.025, (0.38, Y0+0.12, 1.515), GOLD, outline=0.004)
# milk pitcher (left on counter)
cyl('pitcher', 0.09, 0.2, (-0.95, -0.3, 0.1), STEEL, r2=0.075, outline=0.008)
torus('phandle', 0.055, 0.014, (-1.05, -0.3, 0.12), STEEL, rot=(math.pi/2, 0, 0))

# ---- props: clear square containers (beans, sugar), stacked mugs ----
BEAN = toon('bean', '#8a4a24', shade=0.6, light=1.25, gloss=0.5)
SUG = toon('sugar', '#fffdf8', shade=0.85, light=1.02)
ACR = toon('acryl', '#eef8ff', shade=0.9, light=1.05, gloss=0.9, alpha=0.22)
random.seed(3)
def container(cx, kind):
    box('cont', (0.36, 0.3, 0.3), (cx, -0.25, 0.15), ACR, bevel=0.02, outline=0.008)
    for (sx,sy,dx,dy) in ((0.37,0.014,0,-0.15),(0.37,0.014,0,0.15),(0.014,0.31,-0.18,0),(0.014,0.31,0.18,0)):
        box('lidrim', (sx, sy, 0.014), (cx+dx, -0.25+dy, 0.305), GOLD, bevel=0.003, outline=0.003)
    for i in range(70 if kind == 'bean' else 40):
        x = cx + random.uniform(-0.15, 0.15); y = -0.25 + random.uniform(-0.12, 0.12); z = random.uniform(0.03, 0.26)
        if kind == 'bean':
            o = sphere('b', 0.028, (x, y, z), BEAN, scale=(1.35, 1, 0.8), outline=0.004, seg=12)
            o.rotation_euler = (random.uniform(0, 3), random.uniform(0, 3), random.uniform(0, 3))
        else:
            o = box('s', (0.045, 0.045, 0.045), (x, y, z), SUG, bevel=0.006, outline=0.003)
            o.rotation_euler = (random.uniform(-.3, .3), random.uniform(-.3, .3), random.uniform(0, 3))
container(1.05, 'bean'); container(1.5, 'sugar')
for k in range(3):
    cyl('stackmug', 0.1, 0.13, (1.95, -0.2, 0.065+k*0.11), WHITE, r2=0.115, outline=0.006)
    torus('stackrim', 0.115, 0.008, (1.95, -0.2, 0.13+k*0.11), GOLD, outline=0.002)

lights_and_camera(sc, target=(0.45, 0, 0.62), ortho=3.7, elev=13, res=(1920, 1080))
sc.render.filepath = '/tmp/claude-0/-home-user-movie-aniyomi/fbea6901-f4ba-5bfb-a75b-f3adccde22ba/scratchpad/bl/coffee_bl.png'
bpy.ops.render.render(write_still=True)
