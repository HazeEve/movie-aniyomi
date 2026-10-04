import sys, math, random, os; sys.path.insert(0, '.')
import bpy
from soft import *
HERE = os.getcwd()
sc = setup((1920, 1080))
BLACK = mat('black', '#1e1b1a', 0.32, coat=0.35)
CHAR = mat('char', '#3a3533', 0.4, coat=0.2)
GOLD = mat('gold', '#e3b453', 0.22, 1.0)
STEEL = mat('steel', '#dfe3e8', 0.2, 1.0)
DSTEEL = mat('dsteel', '#9aa1aa', 0.3, 1.0)
WHITE = mat('white', '#fbf7f0', 0.18, coat=0.6)
MARBLE = mat('marble', '#f3e2c6', 0.3, coat=0.4)
CAB = mat('cab', '#1c1918', 0.4, coat=0.2)
GLASS = mat('glass', '#f4fbff', 0.04, trans=1.0)
ACR = mat('acr', '#f2f9ff', 0.06, alpha=0.12, coat=0.8)
SCREEN = mat('screen', '#1f4a70', 0.2, emit=0.6)
CYAN = mat('cyan', '#8fefff', 0.3, emit=3.0)
GFACE = mat('gface', '#fffaf0', 0.3)
RED = mat('red', '#d9473a', 0.4)
BEAN = mat('bean', '#7a3d1c', 0.28, coat=0.6)
BEAN2 = mat('bean2', '#5e2c12', 0.3, coat=0.6)
SUG = mat('sug', '#fffdf8', 0.55, sss=0.2)
CHOC = mat('choc', '#4a2414', 0.3, coat=0.5)
MILK = mat('milk', '#fffdf6', 0.3, sss=0.3)
GROUND = mat('ground', '#c39a74', 0.7)
LEAF = mat('leaf', '#6fae5f', 0.45, sss=0.2)
SOIL = mat('soil', '#4a3022', 0.9)
LATTE = imgmat('latteimg', HERE + '/latte.png', 0.15)
ESPI = imgmat('espimg', HERE + '/espresso.png', 0.12)
# ---- room: wallpaper, counter, cabinet with band ----
bpy.ops.mesh.primitive_plane_add(size=1, location=(0, 1.35, 1.5), rotation=(math.pi/2, 0, 0)); w = bpy.context.object; w.scale = (12, 4, 1)
wm = imgmat('wall', HERE + '/wall.png', 0.8); nt = wm.node_tree; tex = [n for n in nt.nodes if n.type == 'TEX_IMAGE'][0]
mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Scale'].default_value = (9, 3, 1); tc = nt.nodes.new('ShaderNodeTexCoord')
nt.links.new(tc.outputs['UV'], mp.inputs[0]); nt.links.new(mp.outputs[0], tex.inputs[0]); w.data.materials.append(wm)
box('backsplashrail', (12, 0.06, 0.06), (0, 1.3, 0.03), GOLD, bevel=0.01, outline=0)
box('counter', (12, 3.0, 0.1), (0, -0.2, -0.05), MARBLE, bevel=0.02, outline=0)
box('cabinet', (12, 0.1, 1.2), (0, -1.75, -0.65), CAB, bevel=0.01, outline=0)
box('goldedge', (12, 0.04, 0.035), (0, -1.71, -0.02), GOLD, bevel=0.008, outline=0)
bpy.ops.mesh.primitive_plane_add(size=1, location=(0, -1.81, -0.16), rotation=(math.pi/2, 0, 0)); b = bpy.context.object; b.scale = (12, 0.16, 1)
bm = imgmat('band', HERE + '/band.png', 0.5); nt = bm.node_tree; tex = [n for n in nt.nodes if n.type == 'TEX_IMAGE'][0]
mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Scale'].default_value = (14, 1, 1); tc = nt.nodes.new('ShaderNodeTexCoord')
nt.links.new(tc.outputs['UV'], mp.inputs[0]); nt.links.new(mp.outputs[0], tex.inputs[0]); b.data.materials.append(bm)
box('goldline2', (12, 0.03, 0.02), (0, -1.81, -0.25), GOLD, bevel=0.005, outline=0)
# ---- espresso machine (owner's model) ----
Y0 = 0.25
box('body', (1.3, 0.8, 1.0), (0, Y0, 0.5), BLACK, bevel=0.04)
box('topplate', (1.34, 0.84, 0.04), (0, Y0, 1.02), STEEL, bevel=0.012)
box('panel', (1.2, 0.03, 0.36), (0, Y0-0.41, 0.8), CHAR, bevel=0.015)
for z in (0.995, 0.615):
    box('trim', (1.24, 0.012, 0.014), (0, Y0-0.425, z), GOLD, bevel=0.004, outline=0)
box('sidetrim', (0.014, 0.012, 0.92), (0.64, Y0-0.41, 0.5), GOLD, bevel=0.004, outline=0)
box('recess', (1.1, 0.06, 0.48), (0, Y0-0.39, 0.33), mat('rec', '#141211', 0.5), bevel=0.02, outline=0.004)
box('screen', (0.3, 0.02, 0.17), (-0.2, Y0-0.43, 0.84), SCREEN, bevel=0.015, outline=0.004)
box('ui', (0.2, 0.005, 0.014), (-0.2, Y0-0.442, 0.8), CYAN, bevel=0, outline=0)
for x in (-0.25, -0.2, -0.15): cyl('dot', 0.017, 0.006, (x, Y0-0.442, 0.86), CYAN, rot=(math.pi/2, 0, 0), outline=0)
for i in range(4): box('btn', (0.05, 0.03, 0.035), (-0.3+i*0.066, Y0-0.44, 0.71), DSTEEL, bevel=0.012, outline=0.003)
for x, z in ((-0.5, 0.84), (0.5, 0.8)):
    cyl('knob', 0.055, 0.06, (x, Y0-0.45, z), BLACK, rot=(math.pi/2, 0, 0), outline=0.004)
    cyl('knobg', 0.032, 0.07, (x, Y0-0.455, z), GOLD, rot=(math.pi/2, 0, 0), outline=0.003)
cyl('gaugeB', 0.12, 0.05, (0.2, Y0-0.445, 0.81), STEEL, rot=(math.pi/2, 0, 0), outline=0.005)
cyl('gaugeF', 0.1, 0.05, (0.2, Y0-0.45, 0.81), GFACE, rot=(math.pi/2, 0, 0), outline=0.003)
cyl('gaugeG', 0.1, 0.01, (0.2, Y0-0.478, 0.81), GLASS, rot=(math.pi/2, 0, 0), outline=0)
for k in range(9):
    a = math.radians(-120 + k*30)
    box('tick', (0.004, 0.004, 0.022), (0.2+0.082*math.sin(a), Y0-0.477, 0.81+0.082*math.cos(a)), CHAR, bevel=0, outline=0, rot=(0, -a, 0))
box('needle', (0.006, 0.004, 0.08), (0.22, Y0-0.48, 0.84), RED, bevel=0, outline=0, rot=(0, math.radians(-40), 0))
cyl('group', 0.11, 0.08, (-0.08, Y0-0.34, 0.55), STEEL, outline=0.005)
cyl('basket', 0.09, 0.06, (-0.08, Y0-0.34, 0.48), DSTEEL, outline=0.005)
box('pfh', (0.32, 0.055, 0.055), (-0.3, Y0-0.45, 0.47), BLACK, bevel=0.025, rot=(0, math.radians(-15), math.radians(-30)))
cyl('pfring', 0.032, 0.03, (-0.19, Y0-0.41, 0.485), GOLD, rot=(0, math.radians(75), math.radians(-30)), outline=0.003)
for x in (-0.11, -0.05):
    cyl('spout', 0.012, 0.06, (x, Y0-0.34, 0.42), DSTEEL, outline=0.003)
    cyl('stream', 0.007, 0.2, (x, Y0-0.34, 0.29), mat('esp', '#6a3418', 0.2, coat=0.5), outline=0)
cyl('cup', 0.075, 0.12, (-0.08, Y0-0.36, 0.2), WHITE, r2=0.09, outline=0.005)
tor('cuprim', 0.089, 0.007, (-0.08, Y0-0.36, 0.26), GOLD)
c = cyl('crema', 0.083, 0.004, (-0.08, Y0-0.36, 0.262), ESPI, outline=0)
tor('cuphandle', 0.038, 0.012, (0.01, Y0-0.36, 0.2), WHITE, rot=(math.pi/2, 0, 0))
cyl('wand', 0.017, 0.38, (-0.56, Y0-0.43, 0.43), STEEL, rot=(0, math.radians(8), 0), outline=0.004)
sph('wandtip', 0.025, (-0.585, Y0-0.43, 0.25), STEEL)
box('hook', (0.14, 0.03, 0.025), (0.3, Y0-0.42, 0.45), STEEL, bevel=0.01, outline=0.003)
box('tray', (0.92, 0.36, 0.06), (0, Y0-0.48, 0.09), STEEL, bevel=0.015)
for i in range(13): box('slot', (0.014, 0.3, 0.012), (-0.36+i*0.06, Y0-0.48, 0.125), mat('slot', '#5b6068', 0.4, 1.0), bevel=0, outline=0)
box('trayfront', (0.94, 0.02, 0.06), (0, Y0-0.665, 0.09), GOLD, bevel=0.008, outline=0.003)
# rail + cups on top
for x in (-0.6, -0.05): cyl('post', 0.009, 0.12, (x, Y0-0.3, 1.1), STEEL, outline=0.002)
cyl('rail', 0.009, 0.56, (-0.325, Y0-0.3, 1.16), STEEL, rot=(0, math.pi/2, 0), outline=0.002)
for x, y in ((-0.48, 0.05), (-0.3, 0.14), (-0.18, -0.04)):
    cyl('topcup', 0.06, 0.1, (x, Y0+y, 1.09), WHITE, r2=0.072, outline=0.004); tor('tr', 0.071, 0.006, (x, Y0+y, 1.14), GOLD)
    cyl('in', 0.064, 0.005, (x, Y0+y, 1.142), mat('cin', '#efe6d8', 0.3), outline=0)
# grinder jar
cyl('gbase', 0.13, 0.09, (0.38, Y0+0.1, 1.085), BLACK, outline=0.005); tor('gring', 0.132, 0.012, (0.38, Y0+0.1, 1.13), GOLD)
cyl('gjar', 0.12, 0.26, (0.38, Y0+0.1, 1.27), GLASS, r2=0.135, outline=0.005)
cyl('ggr', 0.105, 0.14, (0.38, Y0+0.1, 1.21), GROUND, r2=0.118, outline=0)
sph('glid', 0.14, (0.38, Y0+0.1, 1.4), BLACK, scale=(1, 1, 0.42), outline=0.005); sph('gknob', 0.026, (0.38, Y0+0.1, 1.465), GOLD)
# ---- clear square containers ----
random.seed(5)
def container(cx, cy, kind):
    box('cont', (0.42, 0.36, 0.3), (cx, cy, 0.15), ACR, bevel=0.025, outline=0.004)
    for (sx, sy, dx, dy) in ((0.43, 0.016, 0, -0.18), (0.43, 0.016, 0, 0.18), (0.016, 0.37, -0.21, 0), (0.016, 0.37, 0.21, 0)):
        box('rim', (sx, sy, 0.016), (cx+dx, cy+dy, 0.305), GOLD, bevel=0.004, outline=0)
    n = {'bean': 150, 'sugar': 60, 'choc': 140}[kind]
    for i in range(n):
        x = cx + random.uniform(-0.18, 0.18); y = cy + random.uniform(-0.15, 0.15); z = random.uniform(0.03, 0.27)
        if kind == 'bean':
            o = sph('b', 0.03, (x, y, z), random.choice((BEAN, BEAN2)), scale=(1.35, 1, 0.75), outline=0.003, seg=14, rot=(random.uniform(0,3), random.uniform(0,3), random.uniform(0,3)))
        elif kind == 'sugar':
            o = box('s', (0.05, 0.05, 0.05), (x, y, z), SUG, bevel=0.008, outline=0.002, rot=(random.uniform(-.4,.4), random.uniform(-.4,.4), random.uniform(0,3)))
        else:
            bpy.ops.mesh.primitive_cone_add(radius1=0.028, radius2=0.0, depth=0.04, location=(x, y, z), vertices=16); o = bpy.context.object; finish(o, CHOC, 0, 0.002)
container(-1.6, 0.2, 'bean'); container(-1.05, 0.2, 'sugar'); container(-1.6, -0.62, 'choc')
# milk pitcher
cyl('pitcher', 0.12, 0.26, (-0.95, -0.75, 0.13), STEEL, r2=0.1, outline=0.005)
cyl('milktop', 0.1, 0.005, (-0.95, -0.75, 0.258), MILK, outline=0)
tor('ph', 0.07, 0.016, (-1.09, -0.75, 0.15), STEEL, rot=(math.pi/2, 0, 0))
# syrup bottles
for i, col in enumerate(('#b9672c', '#f0bf63', '#6e3a24')):
    x = 0.98 + i*0.3
    cyl('bot', 0.11, 0.42, (x, 0.35, 0.21), mat(f'syr{i}', col, 0.08, trans=0.6, coat=0.8), outline=0.005)
    cyl('lab', 0.112, 0.14, (x, 0.35, 0.2), mat('label', '#fffaf0', 0.5), outline=0.002)
    cyl('labg', 0.113, 0.02, (x, 0.35, 0.28), GOLD, outline=0)
    cyl('neck', 0.04, 0.08, (x, 0.35, 0.46), BLACK, outline=0.003); cyl('pump', 0.025, 0.12, (x, 0.35, 0.56), GOLD, outline=0.003)
    box('nozzle', (0.14, 0.03, 0.03), (x+0.06, 0.35, 0.62), GOLD, bevel=0.01, outline=0.003)
# gold mugs
for i, (x, y) in enumerate(((2.0, 0.45), (2.28, 0.45), (2.0, 0.15), (2.28, 0.15))):
    cyl('gmug', 0.1, 0.18, (x, y, 0.09), GOLD, outline=0.004); tor('gmh', 0.05, 0.014, (x+0.12, y, 0.09), GOLD, rot=(math.pi/2, 0, 0))
    cyl('gin', 0.09, 0.005, (x, y, 0.178), mat('gin', '#8a6020', 0.4, 1.0), outline=0)
# goal coaster + latte with art
box('coaster', (0.62, 0.48, 0.02), (1.25, -0.78, 0.01), mat('check', '#f3d48a', 0.6), bevel=0.01, outline=0.003)
cyl('saucer', 0.2, 0.02, (1.25, -0.78, 0.03), WHITE, r2=0.16, outline=0.004); tor('sr', 0.15, 0.005, (1.25, -0.78, 0.041), GOLD)
cyl('lmug', 0.12, 0.17, (1.25, -0.78, 0.125), WHITE, r2=0.135, outline=0.005); tor('lr', 0.134, 0.008, (1.25, -0.78, 0.21), GOLD)
o = cyl('art', 0.127, 0.004, (1.25, -0.78, 0.214), LATTE, outline=0); o.rotation_euler = (0, 0, math.radians(90))
tor('lh', 0.06, 0.018, (1.4, -0.78, 0.13), WHITE, rot=(math.pi/2, 0, 0))
# plant
cyl('pot', 0.16, 0.24, (2.15, -0.72, 0.12), BLACK, r2=0.19, outline=0.005); tor('potr', 0.19, 0.012, (2.15, -0.72, 0.24), GOLD); cyl('soil', 0.17, 0.01, (2.15, -0.72, 0.235), SOIL, outline=0)
for k in range(9):
    a = k*40; o = sph('leaf', 0.1, (2.15 + 0.1*math.cos(math.radians(a)), -0.72 + 0.1*math.sin(math.radians(a)), 0.33), LEAF, scale=(0.5, 1.4, 0.25), outline=0.003)
    o.rotation_euler = (math.radians(35)*math.cos(math.radians(a)), math.radians(35), math.radians(a))
# lights + camera
light('SUN', (0, 0, 5), (math.radians(48), math.radians(-18), math.radians(-35)), 4.2, '#ffe6c4')
light('AREA', (2.5, -3.5, 2.5), (math.radians(60), 0, math.radians(35)), 220, '#dfe6ff', size=3)
light('AREA', (-1.5, 2.5, 3.0), (math.radians(-40), 0, math.radians(200)), 160, '#ffd9a8', size=2)
camera((0.25, -0.3, 0.45), 6.0, 36, lens=40)
sc.render.filepath = HERE + '/cozy.png'
bpy.ops.render.render(write_still=True)
