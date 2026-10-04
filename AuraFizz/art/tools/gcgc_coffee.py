from ing import *
O = "#5a3420"   # outline
def P(*pts): return " ".join(f"{x},{y}" for x, y in pts)
D = f'''
<linearGradient id="gold" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#f7dc8e"/><stop offset=".55" stop-color="#e2b252"/><stop offset="1" stop-color="#c08a2e"/></linearGradient>
<linearGradient id="steelT" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#eef1f4"/><stop offset="1" stop-color="#cfd5dc"/></linearGradient>
<linearGradient id="steelF" x1="0" x2="1"><stop offset="0" stop-color="#b9c0c8"/><stop offset=".3" stop-color="#f3f5f7"/><stop offset=".6" stop-color="#cdd3da"/><stop offset="1" stop-color="#a9b0b9"/></linearGradient>
<linearGradient id="blackF" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#3a3532"/><stop offset="1" stop-color="#2a2624"/></linearGradient>
<linearGradient id="milk" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#fffdf7"/><stop offset="1" stop-color="#f3e9d8"/></linearGradient>
<radialGradient id="latteT" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#e7c08e"/><stop offset=".8" stop-color="#b9773f"/><stop offset="1" stop-color="#8a4f26"/></radialGradient>
<radialGradient id="espT" cx=".45" cy=".45" r=".55"><stop offset="0" stop-color="#c88a52"/><stop offset=".6" stop-color="#8a4a22"/><stop offset="1" stop-color="#5a2e14"/></radialGradient>
<pattern id="wall" width="56" height="56" patternUnits="userSpaceOnUse"><rect width="56" height="56" fill="#f6ead2"/><path d="M28 6 l6 22 -6 22 -6 -22z" fill="#efdcbb"/><circle cx="0" cy="0" r="3" fill="#e8cf9f"/><circle cx="56" cy="56" r="3" fill="#e8cf9f"/><circle cx="0" cy="56" r="3" fill="#e8cf9f"/><circle cx="56" cy="0" r="3" fill="#e8cf9f"/></pattern>
<pattern id="stripeB" width="44" height="20" patternUnits="userSpaceOnUse" patternTransform="skewX(-30)"><rect width="44" height="20" fill="#fbf3e2"/><rect width="14" height="20" fill="#1f1c1f"/><rect x="22" width="14" height="20" fill="#d6a043"/></pattern>
<pattern id="marbleP" width="400" height="300" patternUnits="userSpaceOnUse"><rect width="400" height="300" fill="#fbf4e6"/><path d="M-20 60 q80 -30 160 10 t180 -10 t120 20 M40 200 q60 -20 120 6 t140 -8" stroke="#ead9bc" stroke-width="3" fill="none"/><path d="M120 120 q30 10 60 -4 M260 250 q40 -16 90 0" stroke="#efe2c8" stroke-width="2" fill="none"/></pattern>
<filter id="sh" x="-20%" y="-20%" width="140%" height="150%"><feDropShadow dx="0" dy="6" stdDeviation="5" flood-color="#7a4a24" flood-opacity=".28"/></filter>
<filter id="shS" x="-20%" y="-20%" width="140%" height="150%"><feDropShadow dx="0" dy="3" stdDeviation="2.5" flood-color="#7a4a24" flood-opacity=".3"/></filter>
<g id="spark"><path d="M0 -10 C1 -3 3 -1 10 0 C3 1 1 3 0 10 C-1 3 -3 1 -10 0 C-3 -1 -1 -3 0 -10z" fill="#fff"/></g>
'''
def stroke(w=3.5): return f'stroke="{O}" stroke-width="{w}" stroke-linejoin="round" stroke-linecap="round"'
# --- top-down mug: ellipse rim with drink, handle, gold rim, saucer ---
def mug(x, y, r, drink="latte", saucer=True, art=True, s=1.0):
    g = f'<g transform="translate({x},{y}) scale({s})" filter="url(#shS)">'
    if saucer:
        g += f'<ellipse cx="0" cy="{r*0.35}" rx="{r*1.55}" ry="{r*1.05}" fill="#fffaf0" {stroke()}/><ellipse cx="0" cy="{r*0.35}" rx="{r*1.25}" ry="{r*0.82}" fill="none" stroke="url(#gold)" stroke-width="3"/>'
    g += f'<path d="M{r*0.85} {-r*0.05} c{r*0.75} {-r*0.25} {r*0.85} {r*0.75} {r*0.05} {r*0.75}" fill="none" stroke="{O}" stroke-width="{r*0.36:.1f}" stroke-linecap="round"/><path d="M{r*0.85} {-r*0.05} c{r*0.75} {-r*0.25} {r*0.85} {r*0.75} {r*0.05} {r*0.75}" fill="none" stroke="#fffaf0" stroke-width="{r*0.2:.1f}" stroke-linecap="round"/>'
    g += f'<path d="M{-r} 0 v{r*0.55} a{r} {r*0.7} 0 0 0 {2*r} 0 v{-r*0.55}" fill="url(#milk)" {stroke()}/>'
    g += f'<ellipse cx="0" cy="0" rx="{r}" ry="{r*0.7}" fill="#fffaf0" {stroke()}/>'
    g += f'<ellipse cx="0" cy="0" rx="{r}" ry="{r*0.7}" fill="none" stroke="url(#gold)" stroke-width="4"/>'
    fill = "url(#latteT)" if drink == "latte" else ("url(#espT)" if drink == "esp" else "#fffaf0")
    if drink:
        g += f'<ellipse cx="0" cy="{r*0.04}" rx="{r*0.84}" ry="{r*0.58}" fill="{fill}" stroke="#7a4a24" stroke-width="1.5"/>'
    if drink == "latte" and art:   # rosetta heart latte art
        g += f'<path d="M0 {r*0.42} C{-r*0.55} {r*0.05} {-r*0.5} {-r*0.4} {-r*0.18} {-r*0.36} C{-r*0.05} {-r*0.34} 0 {-r*0.25} 0 {-r*0.18} C0 {-r*0.25} {r*0.05} {-r*0.34} {r*0.18} {-r*0.36} C{r*0.5} {-r*0.4} {r*0.55} {r*0.05} 0 {r*0.42}z" fill="#fff6e6"/>'
        g += f'<path d="M0 {-r*0.1} C{-r*0.25} {r*0.05} {-r*0.18} {r*0.25} 0 {r*0.3} C{r*0.18} {r*0.25} {r*0.25} {r*0.05} 0 {-r*0.1}z" fill="#d9a46c"/><path d="M0 {r*0.42} v{-r*0.62}" stroke="#d9a46c" stroke-width="2"/>'
    g += f'<path d="M{-r*0.7} {-r*0.4} q{r*0.3} {-r*0.22} {r*0.7} {-r*0.26}" stroke="#fff" stroke-width="3" fill="none" stroke-linecap="round" opacity=".9"/>'
    return g + '</g>'
# --- box in oblique top-down view: front rect + top face ---
def obox(x, y, w, h, depth, front, top, side=None, r=10, sw=4):
    t = depth
    g = f'<path d="M{x} {y} l{t*0.18} {-t} h{w-t*0.36} l{t*0.18} {t}z" fill="{top}" {stroke(sw)}/>'
    g += f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{front}" {stroke(sw)}/>'
    return g

def scene():
    s = []
    W, H = 1600, 900
    # wall + top rack (cropped like GCGC)
    s.append(f'<rect width="{W}" height="{H}" fill="url(#wall)"/>')
    s.append(f'<rect y="0" width="{W}" height="58" fill="#2a2624"/><rect y="52" width="{W}" height="8" fill="url(#gold)"/>')
    for i, x in enumerate(range(90, 1600, 150)):
        s.append(f'<g transform="translate({x},34)" filter="url(#shS)"><path d="M-30 0 h60 l-6 56 a10 10 0 0 1 -10 9 h-28 a10 10 0 0 1 -10 -9z" fill="{"#fffaf0" if i%2 else "#e8f4fb"}" fill-opacity="{1 if i%2 else .7}" {stroke(3)}/><path d="M-30 0 h60" stroke="url(#gold)" stroke-width="5"/><path d="M-20 10 l3 40" stroke="#fff" stroke-width="4" stroke-linecap="round"/></g>')
    # counter (big cream marble surface seen from above) + airmail-style band
    s.append(f'<rect x="0" y="250" width="{W}" height="580" fill="url(#marbleP)"/><path d="M0 250 h{W}" stroke="{O}" stroke-width="4"/><rect y="252" width="{W}" height="8" fill="#fffdf6"/>')
    s.append(f'<rect x="0" y="826" width="{W}" height="74" fill="#1f1c1f"/><rect x="0" y="826" width="{W}" height="22" fill="url(#stripeB)"/><path d="M0 826 h{W} M0 848 h{W}" stroke="{O}" stroke-width="3"/>')
    s.append(f'<rect x="0" y="854" width="{W}" height="4" fill="url(#gold)"/>')
    # soft shadow under machine
    s.append('<ellipse cx="800" cy="745" rx="330" ry="34" fill="#7a4a24" opacity=".18"/>')
    # ===== ESPRESSO MACHINE (Aura Fizz model: black body, steel top, gauge, display, grinder jar) =====
    mx, my, mw, mh = 520, 300, 560, 440
    m = f'<g filter="url(#sh)">'
    m += obox(mx, my, mw, mh, 110, "url(#blackF)", "url(#steelT)", r=18, sw=4.5)
    m += f'<path d="M{mx+20} {my-104} h{mw-40}" stroke="#fff" stroke-width="5" stroke-linecap="round" opacity=".8"/>'
    # gold trims
    m += f'<rect x="{mx+12}" y="{my+12}" width="{mw-24}" height="5" rx="2" fill="url(#gold)"/><rect x="{mx+12}" y="{my+172}" width="{mw-24}" height="5" rx="2" fill="url(#gold)"/>'
    m += f'<rect x="{mx+mw-16}" y="{my+20}" width="5" height="{mh-40}" rx="2" fill="url(#gold)"/>'
    # control panel (charcoal)
    m += f'<rect x="{mx+26}" y="{my+26}" width="{mw-52}" height="138" rx="12" fill="#45403c" {stroke(3)}/>'
    m += f'<path d="M{mx+34} {my+36} h{mw-70}" stroke="#6a645e" stroke-width="3" stroke-linecap="round"/>'
    # display
    m += f'<rect x="{mx+120}" y="{my+46}" width="150" height="86" rx="10" fill="#1d2f45" {stroke(3)}/><rect x="{mx+128}" y="{my+54}" width="134" height="70" rx="6" fill="#26405c"/>'
    m += f'<text x="{mx+195}" y="{my+78}" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="11" fill="#8fe9ff" letter-spacing="2">AURA FIZZ</text>'
    m += ''.join(f'<circle cx="{mx+165+i*30}" cy="{my+98}" r="8" fill="{c}"/>' for i, c in enumerate(["#8fe9ff", "#8fe9ff", "#3a6a8c"]))
    m += f'<rect x="{mx+140}" y="{my+112}" width="110" height="5" rx="2.5" fill="#8fe9ff"/>'
    m += ''.join(f'<rect x="{mx+122+i*38}" y="{my+140}" width="30" height="14" rx="5" fill="url(#steelT)" {stroke(2.5)}/>' for i in range(4))
    # knobs
    for kx in (mx+70, mx+mw-70):
        m += f'<circle cx="{kx}" cy="{my+95}" r="24" fill="#2a2624" {stroke(3)}/><circle cx="{kx}" cy="{my+95}" r="14" fill="url(#gold)" stroke="{O}" stroke-width="2.5"/><circle cx="{kx-4}" cy="{my+90}" r="4" fill="#fff6d0"/>'
    # gauge
    gx, gy = mx+385, my+95
    m += f'<circle cx="{gx}" cy="{gy}" r="58" fill="url(#steelF)" {stroke(3.5)}/><circle cx="{gx}" cy="{gy}" r="46" fill="#fffaf0" {stroke(2.5)}/>'
    for k in range(9):
        import math
        a = math.radians(-120 + k*30); m += f'<path d="M{gx+36*math.sin(a):.1f} {gy-36*math.cos(a):.1f} L{gx+42*math.sin(a):.1f} {gy-42*math.cos(a):.1f}" stroke="{O}" stroke-width="2.5" stroke-linecap="round"/>'
    m += f'<path d="M{gx} {gy} L{gx+20} {gy-26}" stroke="#d94a3a" stroke-width="4" stroke-linecap="round"/><circle cx="{gx}" cy="{gy}" r="5" fill="{O}"/><path d="M{gx-30} {gy-20} q10 -16 26 -18" stroke="#fff" stroke-width="4" fill="none" stroke-linecap="round"/>'
    # recess (brew area)
    m += f'<rect x="{mx+40}" y="{my+196}" width="{mw-80}" height="210" rx="14" fill="#1d1a18" {stroke(3)}/>'
    m += f'<path d="M{mx+52} {my+206} h{mw-110}" stroke="#3a3532" stroke-width="3" stroke-linecap="round"/>'
    # group head + portafilter (black handle, gold ring)
    hx = mx+250
    m += f'<rect x="{hx-50}" y="{my+200}" width="100" height="34" rx="10" fill="url(#steelF)" {stroke(3)}/><path d="M{hx-40} {my+234} h80 l-8 18 h-64z" fill="#2a2624" {stroke(3)}/>'
    m += f'<path d="M{hx-34} {my+240} l-120 34 a14 14 0 0 0 8 26 l122 -34z" fill="#2a2624" {stroke(3)}/><circle cx="{hx-62}" cy="{my+262}" r="9" fill="url(#gold)" stroke="{O}" stroke-width="2.5"/>'
    m += f'<path d="M{hx-16} {my+252} q-2 40 2 76" stroke="#7a3f1e" stroke-width="7" stroke-linecap="round" fill="none"/><path d="M{hx+14} {my+252} q2 40 -2 76" stroke="#7a3f1e" stroke-width="6" stroke-linecap="round" fill="none"/>'
    # hot water hook (right)
    m += f'<path d="M{mx+420} {my+226} h46 v20" fill="none" stroke="{O}" stroke-width="12" stroke-linecap="round"/><path d="M{mx+420} {my+226} h46 v20" fill="none" stroke="url(#steelF)" stroke-width="6" stroke-linecap="round"/>'
    # steam wand (left)
    m += f'<path d="M{mx+60} {my+200} l-14 150" stroke="{O}" stroke-width="16" stroke-linecap="round"/><path d="M{mx+60} {my+200} l-14 150" stroke="url(#steelF)" stroke-width="9" stroke-linecap="round"/>'
    # drip tray (seen from above: grill)
    m += obox(mx+80, my+392, mw-160, 30, 40, "url(#steelF)", "url(#steelT)", r=8, sw=3.5)
    m += ''.join(f'<path d="M{mx+100+i*24} {my+356} v30" stroke="#9aa2ac" stroke-width="5" stroke-linecap="round"/>' for i in range(16))
    m += f'<rect x="{mx+80}" y="{my+414}" width="{mw-160}" height="6" rx="3" fill="url(#gold)"/>'
    m += '</g>'
    s.append(m)
    # cup under the portafilter: latte with art (top-down)
    s.append(mug(hx, my+372, 46, "esp", saucer=False, art=False))
    # top of machine: cup rail with cups seen from above + grinder jar (right)
    s.append(f'<path d="M{mx+40} {my-34} h230 M{mx+40} {my-34} v-26 M{mx+270} {my-34} v-26 M{mx+40} {my-60} h230" stroke="{O}" stroke-width="8" stroke-linecap="round" fill="none"/><path d="M{mx+40} {my-34} h230 M{mx+40} {my-60} h230" stroke="url(#steelF)" stroke-width="4" stroke-linecap="round" fill="none"/>')
    for i, cx in enumerate((mx+80, mx+150, mx+220)):
        s.append(mug(cx, my-58, 26, None, saucer=False, art=False))
    jx, jy = mx+430, my-40
    s.append(f'<g filter="url(#sh)"><rect x="{jx-58}" y="{jy-18}" width="116" height="40" rx="12" fill="#2a2624" {stroke(3.5)}/><rect x="{jx-58}" y="{jy-22}" width="116" height="9" rx="4" fill="url(#gold)" stroke="{O}" stroke-width="2.5"/>'
             f'<path d="M{jx-50} {jy-24} l-6 -120 h112 l-6 120z" fill="#e8f4fb" fill-opacity=".55" {stroke(3.5)}/><path d="M{jx-48} {jy-28} l-4 -70 h104 l-4 70z" fill="#c9a07a"/><path d="M{jx-52} {jy-98} q52 -12 104 0" stroke="#b08860" stroke-width="3" fill="none"/>'
             f'<path d="M{jx-40} {jy-130} l4 98" stroke="#fff" stroke-width="7" stroke-linecap="round" opacity=".85"/>'
             f'<path d="M{jx-62} {jy-144} q62 -60 124 0z" fill="#2a2624" {stroke(3.5)}/><ellipse cx="{jx}" cy="{jy-144}" rx="62" ry="8" fill="#2a2624" {stroke(3)}/><circle cx="{jx}" cy="{jy-176}" r="9" fill="url(#gold)" stroke="{O}" stroke-width="2.5"/><path d="M{jx-34} {jy-160} q14 -14 30 -16" stroke="#6a645e" stroke-width="4" fill="none" stroke-linecap="round"/></g>')
    # ===== LEFT: clear square containers (top-down open), milk pitcher =====
    def topcont(x, y, w, h, variants, d, sc, rot, jit, label):
        k = abs(hash(label)) % 10000
        g = f'<g filter="url(#sh)"><clipPath id="tc{k}"><rect x="{x+10}" y="{y+10}" width="{w-20}" height="{h-20}" rx="8"/></clipPath>'
        g += f'<rect x="{x}" y="{y}" width="{w}" height="{h+26}" rx="14" fill="#eef8ff" fill-opacity=".55" {stroke(4)}/>'
        g += f'<rect x="{x+10}" y="{y+10}" width="{w-20}" height="{h-20}" rx="8" fill="#e9d6b4"/><g clip-path="url(#tc{k})">{pack(variants, w-20, h-20, d, k, sc, rot=rot, jitter=jit, ox=x+10, oy=y+10)}</g>'
        g += f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="none" stroke="#fff" stroke-width="3" opacity=".7"/><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="none" {stroke(4)}/>'
        g += f'<path d="M{x+8} {y+h+6} h{w-16}" stroke="#fff" stroke-width="4" opacity=".7" stroke-linecap="round"/>'
        g += f'<rect x="{x+w/2-46}" y="{y+h+12}" width="92" height="22" rx="11" fill="#1f1c1f" stroke="url(#gold)" stroke-width="2.5"/><text x="{x+w/2}" y="{y+h+27}" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="10" fill="#f2d27a">{label}</text></g>'
        return g
    s.append(topcont(70, 330, 170, 150, ["bean", "bean2", "bean3"], 30, .9, 360, .25, "Coffee Beans"))
    s.append(topcont(270, 330, 170, 150, ["sugar"], 30, .85, 25, .12, "Sugar Cubes"))
    s.append(topcont(70, 560, 170, 150, ["chip"], 22, .9, 40, .25, "Choco Chips"))
    # milk pitcher (top-down: milk surface visible)
    px, py = 340, 640
    s.append(f'<g filter="url(#sh)"><path d="M{px-56} {py} v70 a56 22 0 0 0 112 0 v-70" fill="url(#steelF)" {stroke()}/><path d="M{px+50} {py-6} l34 -14 l-10 26z" fill="url(#steelT)" {stroke(3)}/>'
             f'<path d="M{px-56} {py+20} c-40 0 -40 50 0 50" fill="none" stroke="{O}" stroke-width="14" stroke-linecap="round"/><path d="M{px-56} {py+20} c-40 0 -40 50 0 50" fill="none" stroke="url(#steelF)" stroke-width="7" stroke-linecap="round"/>'
             f'<ellipse cx="{px}" cy="{py}" rx="56" ry="22" fill="url(#steelT)" {stroke()}/><ellipse cx="{px}" cy="{py+2}" rx="46" ry="16" fill="#fffdf7"/><ellipse cx="{px-14}" cy="{py-2}" rx="14" ry="4" fill="#fff"/><path d="M{px-46} {py+30} v40" stroke="#fff" stroke-width="7" stroke-linecap="round" opacity=".8"/></g>')
    # ===== RIGHT: syrup bottles (top-down-ish), gold mug rack, plant, goal coaster =====
    for i, (c, lab) in enumerate((("#b9672c", "CARAMEL"), ("#f0bf63", "VANILLA"), ("#6e3a24", "MOCHA"))):
        bx, by = 1150+i*92, 470
        s.append(f'<g filter="url(#sh)" transform="translate({bx},{by})"><path d="M-34 -110 h68 v120 a14 14 0 0 1 -14 14 h-40 a14 14 0 0 1 -14 -14z" fill="{c}" {stroke()}/>'
                 f'<path d="M-34 -110 q34 -26 68 0" fill="{c}" {stroke(3.5)}/><path d="M-24 -96 v96" stroke="#fff" stroke-width="7" stroke-linecap="round" opacity=".5"/>'
                 f'<rect x="-26" y="-74" width="52" height="44" rx="9" fill="#fffaf0" {stroke(3)}/><rect x="-26" y="-74" width="52" height="8" rx="4" fill="url(#gold)"/><text x="0" y="-44" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="9" fill="#7a4a1e">{lab}</text>'
                 f'<rect x="-10" y="-150" width="20" height="30" rx="4" fill="#2a2624" {stroke(3)}/><path d="M-6 -160 h36 v10 h-36z" fill="url(#gold)" {stroke(3)}/><rect x="-14" y="-124" width="28" height="14" rx="4" fill="url(#gold)" {stroke(2.5)}/>'
                 f'<g transform="translate(22,-110)"><circle r="6" cy="-8" fill="#fff"/><circle r="6" cx="8" cy="-2" fill="#fff"/><circle r="6" cx="5" cy="7" fill="#fff"/><circle r="6" cx="-5" cy="7" fill="#fff"/><circle r="6" cx="-8" cy="-2" fill="#fff"/><circle r="4" fill="#f2c14e"/></g></g>')
    # gold mug stack (like GCGC's gold cups) in a wire rack
    s.append(f'<g filter="url(#sh)"><rect x="1430" y="290" width="150" height="220" rx="12" fill="none" stroke="{O}" stroke-width="8"/><rect x="1430" y="290" width="150" height="220" rx="12" fill="none" stroke="url(#gold)" stroke-width="4"/>'
             + ''.join(f'<g transform="translate({1468+(i%2)*74},{338+(i//2)*84})"><path d="M-28 -30 h56 v52 a10 10 0 0 1 -10 10 h-36 a10 10 0 0 1 -10 -10z" fill="url(#gold)" {stroke(3)}/><ellipse cy="-30" rx="28" ry="8" fill="#b07a22" {stroke(3)}/><path d="M28 -18 c14 0 14 26 0 26" fill="none" stroke="{O}" stroke-width="8"/><path d="M28 -18 c14 0 14 26 0 26" fill="none" stroke="url(#gold)" stroke-width="4"/><path d="M-18 -18 v34" stroke="#fff6d0" stroke-width="5" stroke-linecap="round"/></g>' for i in range(4)) + '</g>')
    # small plant
    s.append(f'<g filter="url(#sh)" transform="translate(1500,640)"><path d="M-36 -20 h72 l-8 60 h-56z" fill="#2a2624" {stroke()}/><rect x="-38" y="-24" width="76" height="10" rx="5" fill="url(#gold)" {stroke(2.5)}/>'
             + ''.join(f'<use href="#leaf" transform="translate(0,-22) rotate({a}) scale(1.3)"/>' for a in (-150, -120, -90, -60, -30, -105, -75)) + '</g>')
    # goal coaster (gingham) with target drink top-down
    s.append(f'<g filter="url(#sh)"><rect x="1120" y="560" width="230" height="170" rx="20" fill="url(#check)" {stroke(4)}/><ellipse cx="1235" cy="645" rx="86" ry="62" fill="#fffdf8" stroke="#e6d6b8" stroke-width="3" stroke-dasharray="4 5"/>'
             f'<rect x="1195" y="548" width="80" height="26" rx="13" fill="#1f1c1f" stroke="url(#gold)" stroke-width="3"/><text x="1235" y="566" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="12" fill="#f2d27a" letter-spacing="2">GOAL</text></g>')
    s.append(mug(1228, 646, 44, "latte", saucer=True, art=True, s=.9))
    # sparkles + steam
    s.append('<g opacity=".9"><use href="#spark" transform="translate(1290,610) scale(1.2)"/><use href="#spark" transform="translate(712,640) scale(.9)"/><use href="#spark" transform="translate(470,560) scale(.7)"/></g>')
    s.append(f'<g fill="none" stroke="#fff" stroke-linecap="round" opacity=".7"><path d="M{hx-10} {my+340} q-14 -20 0 -40 q14 -20 0 -40" stroke-width="6" opacity=".55"/></g>')
    # HUD
    s.append(f'''<g filter="url(#sh)" transform="translate(24,84)"><rect width="250" height="178" rx="18" fill="#fffaf0" {stroke(4)}/><rect x="8" y="8" width="234" height="162" rx="13" fill="none" stroke="#e8c46a" stroke-width="2" stroke-dasharray="5 5"/>
     <text x="20" y="34" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="12" fill="#b08030" letter-spacing="3">NOW MAKING</text>
     <text x="20" y="62" font-family="Georgia, serif" font-weight="700" font-size="20" fill="#3a2414">Caramel Macchiato</text>
     <g font-family="DejaVu Sans, sans-serif" font-size="13" font-weight="700"><circle cx="30" cy="92" r="9" fill="#8ed5b4"/><text x="46" y="97" fill="#a8977f">Grind the beans</text><circle cx="30" cy="120" r="9" fill="#f2b84a" stroke="#fff" stroke-width="2"/><text x="46" y="125" fill="#3a2414">Pull the shot</text><circle cx="30" cy="148" r="9" fill="#eadfcb"/><text x="46" y="153" fill="#7a6a55">Steam milk · Caramel</text></g></g>''')
    s.append(f'''<g filter="url(#sh)" transform="translate(1340,84)"><rect width="236" height="50" rx="25" fill="#1f1c1f" stroke="url(#gold)" stroke-width="4"/><circle cx="27" cy="25" r="17" fill="url(#gold)" stroke="{O}" stroke-width="2.5"/><text x="27" y="31" text-anchor="middle" font-family="Georgia" font-weight="700" font-size="15" fill="#7a4a1e">A</text><text x="56" y="33" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="20" fill="#f7e3a5">757</text><rect x="116" y="11" width="106" height="28" rx="14" fill="#8ed5b4"/><text x="169" y="31" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="14" fill="#1f4a38">+35 tip</text></g>''')
    s.append(f'''<g filter="url(#sh)" transform="translate(800,790)"><rect x="-230" y="-28" width="460" height="56" rx="28" fill="#fffaf0" {stroke(4)}/><text x="-206" y="6" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="15" fill="#3a2414">Hold to pull</text><rect x="-90" y="-10" width="300" height="20" rx="10" fill="#efe3cf" {stroke(2.5)}/><rect x="110" y="-8" width="50" height="16" fill="url(#gold)"/><rect x="-88" y="-8" width="170" height="16" rx="8" fill="#8a4a22"/><circle cx="82" cy="0" r="13" fill="#fffaf0" {stroke(3)}/></g>''')
    return "".join(s)
svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1600 900" width="1600" height="900"><defs>{defs()}{EXTRA_DEFS}{D}<g id="leaf"><path d="M0 0 c10 -14 30 -14 38 0 c-10 12 -28 12 -38 0z" fill="#7cbf74" stroke="#2f5a2c" stroke-width="2.5"/><path d="M4 0 h30" stroke="#2f5a2c" stroke-width="1.6"/></g><pattern id="check" width="20" height="20" patternUnits="userSpaceOnUse"><rect width="20" height="20" fill="#fbf1dc"/><rect width="10" height="20" fill="#e8c46a" opacity=".45"/><rect width="20" height="10" fill="#e8c46a" opacity=".45"/></pattern></defs>{scene()}</svg>'
open('../gcgc_coffee.svg', 'w').write(svg)
