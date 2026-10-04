from ing import *
import math
L = "#7a5238"         # thin warm outline
def st(w=2.6): return f'stroke="{L}" stroke-width="{w}" stroke-linejoin="round" stroke-linecap="round"'
def hl(d, w=4, op=.85): return f'<path d="{d}" stroke="#fff" stroke-width="{w}" stroke-linecap="round" fill="none" opacity="{op}"/>'
PEACH, PEACHS = "#f7d3bd", "#ecb99c"
CREAM, CREAMS = "#fff6e6", "#f2e0c4"
MINT, MINTS = "#cfeee2", "#a9dccb"
PINK, PINKS = "#f9c9cf", "#eeaab4"
GOLD, GOLDS = "#f0cf86", "#d9ac5c"
WOOD, WOODS = "#c98e62", "#a96f47"
def star(x, y, r, fill="#fff3c4", s=2.0):
    p = []
    for i in range(10):
        a = math.radians(-90 + i*36); rr = r if i % 2 == 0 else r*0.45
        p.append(f"{x+rr*math.cos(a):.1f},{y+rr*math.sin(a):.1f}")
    return f'<polygon points="{" ".join(p)}" fill="{fill}" {st(s)}/>'
def bubbles(x, y, w, h, n, seed, col="#ffffff"):
    r = random.Random(seed); o = ''
    for _ in range(n):
        bx, by, br = x + r.uniform(0, w), y + r.uniform(0, h), r.uniform(3, 9)
        o += f'<circle cx="{bx:.1f}" cy="{by:.1f}" r="{br:.1f}" fill="{col}" fill-opacity=".55" stroke="{L}" stroke-width="1.2" stroke-opacity=".5"/><circle cx="{bx-br*.35:.1f}" cy="{by-br*.35:.1f}" r="{br*.25:.1f}" fill="#fff"/>'
    return o
def mugTop(x, y, r, body=CREAM, rim=GOLD, drink="latte", art=True, saucer=True):
    g = f'<g transform="translate({x},{y})">'
    if saucer:
        g += f'<ellipse cx="0" cy="{r*0.42}" rx="{r*1.6}" ry="{r*1.05}" fill="{CREAM}" {st()}/><ellipse cx="0" cy="{r*0.42}" rx="{r*1.32}" ry="{r*0.84}" fill="none" stroke="{CREAMS}" stroke-width="3"/>'
        g += ''.join(f'<circle cx="{r*1.45*math.cos(a):.1f}" cy="{r*0.42 + r*0.95*math.sin(a):.1f}" r="2.4" fill="{GOLDS}"/>' for a in [i*math.pi/8 for i in range(16)])
    g += f'<path d="M{r*0.82} {r*0.05} c{r*0.8} {-r*0.2} {r*0.9} {r*0.8} 0 {r*0.75}" fill="none" stroke="{L}" stroke-width="{r*0.34:.1f}" stroke-linecap="round"/><path d="M{r*0.82} {r*0.05} c{r*0.8} {-r*0.2} {r*0.9} {r*0.8} 0 {r*0.75}" fill="none" stroke="{body}" stroke-width="{r*0.2:.1f}" stroke-linecap="round"/>'
    g += f'<path d="M{-r} 0 v{r*0.55} a{r} {r*0.72} 0 0 0 {2*r} 0 v{-r*0.55}" fill="{body}" {st()}/><path d="M{-r*0.98} {r*0.5} a{r} {r*0.72} 0 0 0 {r*0.6} {r*0.62}" fill="none" stroke="#000" stroke-opacity=".06" stroke-width="{r*0.3:.1f}"/>'
    g += f'<ellipse cx="0" cy="0" rx="{r}" ry="{r*0.72}" fill="{rim}" {st()}/>'
    if drink:
        g += f'<ellipse cx="0" cy="{r*0.03}" rx="{r*0.86}" ry="{r*0.6}" fill="#c78c5a" {st(1.8)}/><ellipse cx="0" cy="{r*0.06}" rx="{r*0.74}" ry="{r*0.5}" fill="#d9a674"/>'
        if art:
            g += f'<path d="M0 {r*0.44} C{-r*0.6} {r*0.06} {-r*0.52} {-r*0.42} {-r*0.18} {-r*0.38} C{-r*0.05} {-r*0.36} 0 {-r*0.27} 0 {-r*0.2} C0 {-r*0.27} {r*0.05} {-r*0.36} {r*0.18} {-r*0.38} C{r*0.52} {-r*0.42} {r*0.6} {r*0.06} 0 {r*0.44}z" fill="#fff8ec"/>'
            g += f'<path d="M0 {-r*0.08} C{-r*0.26} {r*0.06} {-r*0.18} {r*0.27} 0 {r*0.31} C{r*0.18} {r*0.27} {r*0.26} {r*0.06} 0 {-r*0.08}z" fill="#e2b483"/><path d="M0 {r*0.42} v{-r*0.62}" stroke="#e2b483" stroke-width="2.4"/>'
    else:
        g += f'<ellipse cx="0" cy="{r*0.03}" rx="{r*0.84}" ry="{r*0.58}" fill="{CREAMS}"/>'
    g += hl(f"M{-r*0.62} {-r*0.42} q{r*0.32} {-r*0.2} {r*0.66} {-r*0.24}", 3.2)
    return g + '</g>'
S = []
W, H = 1600, 900
# ---------- background: cream with soft arcs ----------
S.append(f'<rect width="{W}" height="{H}" fill="#fcf2e1"/>')
arcs = ''
for cx, cy in ((180, 120), (1420, 160), (980, 40)):
    for k, col in enumerate(("#f7e4c6", "#f9ead2", "#f7e4c6", "#f9ead2")):
        arcs += f'<circle cx="{cx}" cy="{cy}" r="{220-k*42}" fill="none" stroke="{col}" stroke-width="20"/>'
S.append(f'<g opacity=".9">{arcs}</g>')
# counter top + pastel stripe band
S.append(f'<rect y="760" width="{W}" height="140" fill="{CREAM}"/><path d="M0 760 h{W}" stroke="{L}" stroke-width="2.6"/>')
band = ''.join(f'<path d="M{x} 828 l18 -22 h22 l-18 22z" fill="{c}"/>' for x, c in zip(range(-40, 1640, 40), ["#f6b6a8", "#fcf2e1", "#9fd3c4", "#fcf2e1"]*60))
S.append(f'<rect y="806" width="{W}" height="22" fill="#fcf2e1"/>{band}<path d="M0 806 h{W} M0 828 h{W}" stroke="{L}" stroke-width="2.2"/><rect y="828" width="{W}" height="72" fill="#d9a77e"/><path d="M0 846 h{W}" stroke="{WOODS}" stroke-width="2"/>')
# ---------- the AURA FIZZ machine (cute themed: fizzy glass boiler + star dials) ----------
mx, mw = 520, 560
M = ''
# glass fizz boiler dome on top
M += f'<rect x="{mx+170}" y="10" width="220" height="38" rx="12" fill="{GOLD}" {st()}/><path d="M{mx+176} 22 h208" stroke="{GOLDS}" stroke-width="3"/>'
M += f'<path d="M{mx+180} 48 c-6 -120 206 -120 200 0z" fill="{MINT}" fill-opacity=".85" {st()}/>'
M += f'<g clip-path="url(#dome)">{bubbles(mx+186, -50, 190, 98, 18, 3)}</g>'
M += hl(f"M{mx+208} 30 c0 -40 28 -62 56 -66", 6, .9)
M += f'<rect x="{mx+268}" y="-62" width="24" height="18" rx="5" fill="{GOLD}" {st(2.2)}/>' + star(mx+280, -70, 16, "#fff3c4", 2.2)
# main body (rounded vintage)
M += f'<path d="M{mx} 120 q0 -60 60 -66 h{mw-120} q60 6 60 66 v430 q0 24 -24 24 h{-(mw-48)} q-24 0 -24 -24z" fill="{PEACH}" {st(3)}/>'
M += f'<path d="M{mx+mw-50} 80 q40 10 40 50 v410 q0 20 -20 22 h-30z" fill="{PEACHS}" opacity=".9"/>'
M += hl(f"M{mx+26} 130 v380", 6, .55) + hl(f"M{mx+70} 70 h300", 5, .6)
# scallop trim + bubbles decoration band
M += ''.join(f'<path d="M{mx+20+i*40} 150 a20 14 0 0 0 40 0" fill="{CREAM}" {st(2)}/>' for i in range(13))
M += f'<path d="M{mx+20} 150 h{mw-40}" stroke="{GOLDS}" stroke-width="4"/>'
# top cups (pastel) on the warmer
for i, (c, cs) in enumerate(((MINT, MINTS), (PINK, PINKS), (CREAM, CREAMS))):
    x = mx+60+i*58
    M += f'<path d="M{x-22} 56 h44 l-4 -30 h-36z" fill="{c}" {st(2.2)}/><ellipse cx="{x}" cy="26" rx="18" ry="5" fill="{cs}" {st(2)}/>'
for i in range(2):
    x = mx+400+i*58
    M += f'<path d="M{x-20} 56 h40 l-3 -36 h-34z" fill="#eaf7f7" fill-opacity=".8" {st(2.2)}/>' + hl(f"M{x-12} 50 l2 -24", 3)
# control panel: cream plate with two star dials + Aura Fizz badge
M += f'<rect x="{mx+40}" y="176" width="{mw-80}" height="150" rx="26" fill="{CREAM}" {st()}/>'
for gx, col in ((mx+130, MINT), (mx+mw-130, PINK)):
    M += f'<circle cx="{gx}" cy="251" r="54" fill="{GOLD}" {st()}/><circle cx="{gx}" cy="251" r="43" fill="#fffdf6" {st(2)}/>'
    M += ''.join(f'<circle cx="{gx+34*math.sin(math.radians(a)):.1f}" cy="{251-34*math.cos(math.radians(a)):.1f}" r="2.6" fill="{L}"/>' for a in range(-120, 121, 40))
    M += f'<path d="M{gx} 251 L{gx+18} 229" stroke="#e98a8a" stroke-width="4" stroke-linecap="round"/>' + star(gx, 251, 9, col, 1.8)
    M += hl(f"M{gx-28} 229 q10 -14 26 -16", 3.5)
M += f'<circle cx="{mx+mw/2}" cy="251" r="50" fill="{PINK}" {st()}/><circle cx="{mx+mw/2}" cy="251" r="40" fill="#fff8f0" {st(2)}/>'
M += f'<text x="{mx+mw/2}" y="246" text-anchor="middle" font-family="Georgia, serif" font-style="italic" font-weight="700" font-size="17" fill="{L}">Aura</text><text x="{mx+mw/2}" y="266" text-anchor="middle" font-family="Georgia, serif" font-style="italic" font-weight="700" font-size="17" fill="{L}">Fizz</text>'
M += star(mx+mw/2+32, 216, 9, "#fff3c4", 1.8) + star(mx+mw/2-36, 290, 6, "#fff3c4", 1.6)
# brew area
M += f'<rect x="{mx+44}" y="346" width="{mw-88}" height="196" rx="22" fill="#f3c7ad" {st()}/><rect x="{mx+56}" y="356" width="{mw-112}" height="20" rx="10" fill="#e9b394"/>'
# two group heads with wooden handles
for gx, flip in ((mx+190, -1), (mx+370, 1)):
    M += f'<rect x="{gx-46}" y="364" width="92" height="30" rx="10" fill="{GOLD}" {st()}/><path d="M{gx-36} 394 h72 l-8 18 h-56z" fill="#efe7da" {st()}/>'
    M += f'<path d="M{gx+flip*30} 402 l{flip*96} 20 a12 12 0 0 1 {-flip*4} 22 l{-flip*96} -18z" fill="{WOOD}" {st()}/>' + hl(f"M{gx+flip*44} 408 l{flip*64} 13", 2.5, .6)
# espresso drip from left group
M += f'<path d="M{mx+178} 414 q-2 40 2 74" stroke="#9a5a30" stroke-width="6" stroke-linecap="round" fill="none"/><path d="M{mx+202} 414 q2 40 -2 74" stroke="#9a5a30" stroke-width="5" stroke-linecap="round" fill="none"/>'
# drip tray (gold grill)
M += f'<rect x="{mx+64}" y="520" width="{mw-128}" height="40" rx="12" fill="{GOLD}" {st()}/>' + ''.join(f'<path d="M{mx+86+i*26} 528 v24" stroke="{GOLDS}" stroke-width="5" stroke-linecap="round"/>' for i in range(16))
# little feet
M += f'<rect x="{mx+40}" y="574" width="60" height="22" rx="8" fill="{WOOD}" {st()}/><rect x="{mx+mw-100}" y="574" width="60" height="22" rx="8" fill="{WOOD}" {st()}/>'
S.append(f'<g transform="translate(0,72)"><g filter="url(#soft)">{M}</g>')
# big latte cup under the left group, sitting on the tray (focus of the screen)
esp = mugTop(mx+190, 560, 66, CREAM, GOLD, "latte", art=False, saucer=False).replace('#d9a674', '#a8683a').replace('#c78c5a', '#7a4424')
S.append(f'<g filter="url(#soft)">{esp}</g>')
S.append(f'<g fill="none" stroke="#fff" stroke-linecap="round" opacity=".75"><path d="M{mx+176} 486 q-14 -18 0 -36" stroke-width="5"/><path d="M{mx+206} 480 q12 -16 0 -32" stroke-width="4"/></g></g>')
# ---------- left: cute grinder (glass hopper of beans, mint body, star dial, wooden base) ----------
gx = 300
G = f'<path d="M{gx-80} 150 h160 l-38 150 h-84z" fill="#eaf7f7" fill-opacity=".7" {st(3)}/>'
G += f'<clipPath id="hop"><path d="M{gx-74} 178 h148 l-31 118 h-86z"/></clipPath><g clip-path="url(#hop)"><rect x="{gx-80}" y="170" width="160" height="140" fill="#6a3418"/>{pack(["bean","bean2","bean3"], 160, 140, 26, 9, .75, ox=gx-80, oy=170)}</g>'
G += f'<path d="M{gx-80} 150 h160 l-38 150 h-84z" fill="none" {st(3)}/>' + hl(f"M{gx-62} 166 l26 120", 6, .7)
G += f'<rect x="{gx-90}" y="132" width="180" height="24" rx="10" fill="{PINK}" {st()}/><circle cx="{gx}" cy="124" r="12" fill="{GOLD}" {st(2.2)}/>'
G += f'<path d="M{gx-62} 300 h124 v210 q0 18 -18 18 h-88 q-18 0 -18 -18z" fill="{MINT}" {st(3)}/><path d="M{gx+40} 304 h22 v206 q0 18 -18 18 h-4z" fill="{MINTS}"/>' + hl(f"M{gx-48} 312 v180", 5, .6)
G += f'<circle cx="{gx}" cy="372" r="34" fill="{GOLD}" {st()}/><circle cx="{gx}" cy="372" r="24" fill="{CREAM}" {st(2)}/>' + star(gx, 372, 13, PINK, 2)
G += f'<rect x="{gx-26}" y="430" width="52" height="34" rx="8" fill="{CREAMS}" {st()}/><path d="M{gx-30} 470 h60 l-6 30 h-48z" fill="#efe7da" {st()}/><ellipse cx="{gx}" cy="470" rx="30" ry="6" fill="#7a4424"/>'
G += f'<rect x="{gx-86}" y="526" width="172" height="34" rx="12" fill="{WOOD}" {st()}/><path d="M{gx-74} 538 h148" stroke="{WOODS}" stroke-width="3"/>'
S.append(f'<g filter="url(#soft)">{G}</g>')
# ---------- right: pastel mug stack + milk jug + syrup bottle ----------
R = ''
cols = ((PINK, PINKS), (MINT, MINTS), (CREAM, CREAMS), (PEACH, PEACHS), (PINK, PINKS), (MINT, MINTS))
idx = 0
for row, (y, n) in enumerate(((420, 3), (352, 2), (284, 1))):
    for k in range(n):
        c, cs = cols[idx]; idx += 1
        x = 1335 - (n-1)*42 + k*84
        R += f'<path d="M{x-36} {y} h72 l-6 60 q0 10 -10 10 h-40 q-10 0 -10 -10z" fill="{c}" {st()}/><ellipse cx="{x}" cy="{y}" rx="36" ry="9" fill="{cs}" {st(2.2)}/>' + hl(f"M{x-24} {y+12} l3 40", 4, .7)
R += f'<rect x="1210" y="490" width="250" height="22" rx="10" fill="{WOOD}" {st()}/>'
# milk jug (cream with gold band and a heart)
jx = 1330
R += f'<path d="M{jx-70} 560 h140 l-10 150 q0 22 -22 22 h-76 q-22 0 -22 -22z" fill="{CREAM}" {st(3)}/><path d="M{jx+70} 560 l30 -16 v26z" fill="{CREAM}" {st(2.6)}/>'
R += f'<path d="M{jx+56} 590 c46 0 46 80 0 80" fill="none" stroke="{L}" stroke-width="16" stroke-linecap="round"/><path d="M{jx+56} 590 c46 0 46 80 0 80" fill="none" stroke="{CREAM}" stroke-width="9" stroke-linecap="round"/>'
R += f'<ellipse cx="{jx}" cy="560" rx="70" ry="14" fill="#fffdf8" {st()}/><rect x="{jx-64}" y="610" width="122" height="14" fill="{GOLD}"/><path d="M{jx-64} 610 h122 M{jx-63} 624 h120" stroke="{L}" stroke-width="2"/>'
R += f'<path d="M{jx-6} 660 c-12 -14 -30 -2 -16 12 l16 14 l16 -14 c14 -14 -4 -26 -16 -12z" fill="{PINK}" {st(2)}/>' + hl(f"M{jx-54} 580 v120", 6, .6)
# syrup bottle with pump (pink caramel)
bx = 1500
R += f'<rect x="{bx-6}" y="520" width="44" height="12" rx="4" fill="{GOLD}" {st(2.2)}/><rect x="{bx-8}" y="530" width="16" height="34" rx="4" fill="{CREAMS}" {st(2.2)}/>'
R += f'<path d="M{bx-40} 600 q0 -36 40 -36 q40 0 40 36 v120 q0 14 -14 14 h-52 q-14 0 -14 -14z" fill="#e9a676" {st(3)}/><rect x="{bx-32}" y="626" width="64" height="52" rx="12" fill="{CREAM}" {st(2.2)}/>'
R += f'<text x="{bx}" y="657" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="11" fill="{L}">Caramel</text>' + hl(f"M{bx-26} 604 v100", 5, .55) + star(bx+20, 640, 7, "#fff3c4", 1.6)
S.append(f'<g filter="url(#soft)">{R}</g>')
# sparkles
for x, y, r in ((470, 210, 12), (1160, 120, 10), (690, 610, 9), (1220, 600, 8), (140, 640, 10)):
    S.append(f'<path d="M{x} {y-r} C{x+r*.15} {y-r*.3} {x+r*.3} {y-r*.15} {x+r} {y} C{x+r*.3} {y+r*.15} {x+r*.15} {y+r*.3} {x} {y+r} C{x-r*.15} {y+r*.3} {x-r*.3} {y+r*.15} {x-r} {y} C{x-r*.3} {y-r*.15} {x-r*.15} {y-r*.3} {x} {y-r}z" fill="#fff" stroke="{GOLDS}" stroke-width="1.5"/>')
# ---------- light HUD ----------
S.append(f'<g filter="url(#soft)"><rect x="28" y="24" width="230" height="74" rx="20" fill="{CREAM}" {st(2.4)}/><text x="48" y="54" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="12" fill="#c08a5a" letter-spacing="2">NOW MAKING</text><text x="48" y="80" font-family="Georgia, serif" font-weight="700" font-size="19" fill="{L}">Caramel Latte</text></g>')
S.append(f'<g filter="url(#soft)"><rect x="1370" y="24" width="200" height="50" rx="25" fill="{CREAM}" {st(2.4)}/>{star(1400, 49, 14, GOLD, 2)}<text x="1424" y="57" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="20" fill="{L}">757</text><rect x="1478" y="34" width="80" height="30" rx="15" fill="{MINT}" {st(2)}/><text x="1518" y="54" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="13" fill="{L}">+35</text></g>')
S.append(f'<g filter="url(#soft)"><rect x="560" y="780" width="480" height="58" rx="29" fill="{CREAM}" {st(2.4)}/><text x="590" y="816" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="16" fill="{L}">Hold to pull</text><rect x="710" y="800" width="300" height="18" rx="9" fill="#f2e0c4" {st(2)}/><rect x="900" y="802" width="50" height="14" fill="{GOLD}"/><rect x="712" y="802" width="170" height="14" rx="7" fill="#c78c5a"/><circle cx="882" cy="809" r="12" fill="{PINK}" {st(2.2)}/></g>')
svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}"><defs>{defs()}
<clipPath id="dome"><path d="M{mx+180} 48 c-6 -120 206 -120 200 0z"/></clipPath>
<filter id="soft" x="-10%" y="-10%" width="120%" height="125%"><feDropShadow dx="0" dy="5" stdDeviation="3" flood-color="#b9855a" flood-opacity=".25"/></filter></defs>{"".join(S)}</svg>'''
open('../pastel_coffee.svg', 'w').write(svg)
