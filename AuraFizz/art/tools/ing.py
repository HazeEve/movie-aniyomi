import random, math
OUT = "#4a2410"  # warm dark outline
def defs():
    return f'''
<radialGradient id="beanG" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#d08a50"/><stop offset=".45" stop-color="#9a5228"/><stop offset="1" stop-color="#5e2c12"/></radialGradient>
<radialGradient id="beanG2" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#c47c44"/><stop offset=".5" stop-color="#874420"/><stop offset="1" stop-color="#52250f"/></radialGradient>
<radialGradient id="beanG3" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#dc9a5e"/><stop offset=".5" stop-color="#a65e30"/><stop offset="1" stop-color="#683416"/></radialGradient>
<g id="bean"><ellipse rx="21" ry="15" fill="url(#beanG)" stroke="{OUT}" stroke-width="3.5"/><path d="M-16 3 C-6 -9 6 11 16 -3" stroke="{OUT}" stroke-width="4" fill="none" stroke-linecap="round"/><path d="M-13 7 C-4 -3 6 13 14 3" stroke="#d99a62" stroke-width="1.6" fill="none" opacity=".7"/><ellipse cx="-9" cy="-7" rx="6" ry="2.6" fill="#fff" opacity=".75" transform="rotate(-18 -9 -7)"/></g>
<g id="bean2"><ellipse rx="21" ry="15" fill="url(#beanG2)" stroke="{OUT}" stroke-width="3.5"/><path d="M-16 3 C-6 -9 6 11 16 -3" stroke="{OUT}" stroke-width="4" fill="none" stroke-linecap="round"/><ellipse cx="-9" cy="-7" rx="5" ry="2.2" fill="#fff" opacity=".65" transform="rotate(-18 -9 -7)"/></g>
<g id="bean3"><ellipse rx="21" ry="15" fill="url(#beanG3)" stroke="{OUT}" stroke-width="3.5"/><path d="M-16 3 C-6 -9 6 11 16 -3" stroke="{OUT}" stroke-width="4" fill="none" stroke-linecap="round"/><path d="M-13 7 C-4 -3 6 13 14 3" stroke="#e6ac78" stroke-width="1.6" fill="none" opacity=".7"/><ellipse cx="-9" cy="-7" rx="6" ry="2.6" fill="#fff" opacity=".8" transform="rotate(-18 -9 -7)"/></g>
<linearGradient id="trayG" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#fffaf0"/><stop offset="1" stop-color="#efdcbc"/></linearGradient>
<linearGradient id="goldR" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#fff0b8"/><stop offset=".45" stop-color="#e8bb52"/><stop offset="1" stop-color="#b07a22"/></linearGradient>
<radialGradient id="strawG" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#ff8a8a"/><stop offset=".5" stop-color="#ec3f4a"/><stop offset="1" stop-color="#b3202f"/></radialGradient>
<g id="straw"><path d="M0 26 C-24 10 -24 -14 -12 -18 C-4 -21 4 -21 12 -18 C24 -14 24 10 0 26z" fill="url(#strawG)" stroke="{OUT}" stroke-width="3.5" stroke-linejoin="round"/>
 <g fill="#ffe7a0"><ellipse cx="-8" cy="-6" rx="1.6" ry="2.4"/><ellipse cx="4" cy="-8" rx="1.6" ry="2.4"/><ellipse cx="10" cy="2" rx="1.6" ry="2.4"/><ellipse cx="-2" cy="4" rx="1.6" ry="2.4"/><ellipse cx="-11" cy="6" rx="1.6" ry="2.4"/><ellipse cx="4" cy="14" rx="1.6" ry="2.4"/></g>
 <path d="M-14 -18 l6 -8 l6 6 l2 -10 l4 10 l6 -6 l4 8z" fill="#5fae4e" stroke="{OUT}" stroke-width="3" stroke-linejoin="round"/>
 <ellipse cx="-10" cy="-8" rx="4" ry="6" fill="#fff" opacity=".55" transform="rotate(20 -10 -8)"/></g>
<g id="mint"><path d="M0 22 C-22 8 -20 -14 0 -24 C20 -14 22 8 0 22z" fill="#7fd08a" stroke="{OUT}" stroke-width="3.5"/><path d="M0 20 V-20 M0 -4 l-10 -8 M0 6 l11 -8 M0 12 l-9 -6" stroke="#3f8a4a" stroke-width="2.5" fill="none" stroke-linecap="round"/><ellipse cx="-8" cy="-6" rx="3" ry="6" fill="#d8ffd8" opacity=".6"/></g>
<g id="lemon"><circle r="24" fill="#ffe46a" stroke="{OUT}" stroke-width="3.5"/><circle r="18" fill="#fff7c2"/>
 <g fill="#ffd93d" stroke="#f2c230" stroke-width="1">{''.join(f'<path d="M0 0 L{16*math.cos(a):.1f} {16*math.sin(a):.1f} A16 16 0 0 1 {16*math.cos(a+0.9):.1f} {16*math.sin(a+0.9):.1f}z" transform="rotate(3)"/>' for a in [i*2*math.pi/7 for i in range(7)])}</g>
 <circle r="3" fill="#fff7c2"/><ellipse cx="-10" cy="-12" rx="5" ry="2.4" fill="#fff" opacity=".7" transform="rotate(-30 -10 -12)"/></g>
<radialGradient id="bobaG" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#7a4a3a"/><stop offset=".5" stop-color="#3a1e18"/><stop offset="1" stop-color="#1a0a08"/></radialGradient>
<g id="boba"><circle r="13" fill="url(#bobaG)" stroke="#1a0a08" stroke-width="2.5"/><ellipse cx="-4" cy="-5" rx="4.5" ry="2.6" fill="#fff" opacity=".8" transform="rotate(-25 -4 -5)"/></g>
<linearGradient id="iceG" x1="0" x2="1" y1="0" y2="1"><stop offset="0" stop-color="#f4fdff"/><stop offset=".6" stop-color="#bfe9fb"/><stop offset="1" stop-color="#8fd0ef"/></linearGradient>
<g id="ice"><rect x="-20" y="-20" width="40" height="40" rx="9" fill="url(#iceG)" stroke="#4a8fb8" stroke-width="3"/><path d="M-12 -12 h16" stroke="#fff" stroke-width="4" stroke-linecap="round"/><path d="M-12 -12 v12" stroke="#fff" stroke-width="4" stroke-linecap="round" opacity=".8"/><rect x="-6" y="-4" width="18" height="16" rx="5" fill="#fff" opacity=".25"/></g>
<g id="sugar"><path d="M-17 -10 l17 -8 l17 8 v18 l-17 9 l-17 -9z" fill="#fffdf8" stroke="#a89a86" stroke-width="3" stroke-linejoin="round"/><path d="M-17 -10 l17 8 l17 -8 M0 -2 v19" stroke="#a89a86" stroke-width="2.5" fill="none"/><path d="M0 -2 l17 -8 v18 l-17 9z" fill="#e6ebf5"/><circle cx="-6" cy="4" r="1.3" fill="#d9d3c6"/><circle cx="-11" cy="-1" r="1.3" fill="#d9d3c6"/></g>
<radialGradient id="blueG" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#8aa2ff"/><stop offset=".5" stop-color="#4a5ad0"/><stop offset="1" stop-color="#2a2f8a"/></radialGradient>
<g id="blueb"><circle r="12" fill="url(#blueG)" stroke="#1e1f5e" stroke-width="2.5"/><path d="M-4 -9 l4 3 l4 -3" stroke="#1e1f5e" stroke-width="2" fill="none"/><ellipse cx="-5" cy="-3" rx="3" ry="1.8" fill="#fff" opacity=".7"/></g>
<radialGradient id="chocG" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#8a5236"/><stop offset="1" stop-color="#3e1e10"/></radialGradient>
<g id="chip"><path d="M0 -14 C4 -6 14 2 12 8 C10 13 -10 13 -12 8 C-14 2 -4 -6 0 -14z" fill="url(#chocG)" stroke="{OUT}" stroke-width="2.5"/><ellipse cx="-3" cy="-1" rx="2.5" ry="4" fill="#c58a62" opacity=".7"/></g>
<g id="dollop"><path d="M-38 18 C-44 4 -30 -4 -20 -2 C-22 -16 -6 -22 2 -14 C8 -26 30 -20 26 -4 C40 -4 44 12 34 20z" fill="#fffdf6" stroke="#b49a78" stroke-width="3.5" stroke-linejoin="round"/><path d="M-26 8 q10 -8 20 0 M2 -4 q8 -8 16 0 M8 10 q10 -6 20 2" stroke="#e8dcc6" stroke-width="3" fill="none" stroke-linecap="round"/><ellipse cx="-14" cy="-4" rx="6" ry="3" fill="#fff"/></g>
<linearGradient id="creamG" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#f1e6d2"/></linearGradient>
<g id="swirl">
 <path d="M-50 12 C-56 -8 -32 -18 0 -18 C32 -18 56 -8 50 12 C44 26 -44 26 -50 12z" fill="url(#creamG)" stroke="#b49a78" stroke-width="3.5"/>
 <path d="M-38 -10 C-42 -26 -24 -34 0 -34 C24 -34 42 -26 38 -10 C30 0 -30 0 -38 -10z" fill="url(#creamG)" stroke="#b49a78" stroke-width="3.5"/>
 <path d="M-26 -30 C-28 -44 -14 -50 0 -50 C14 -50 28 -44 26 -30 C20 -22 -20 -22 -26 -30z" fill="url(#creamG)" stroke="#b49a78" stroke-width="3.5"/>
 <path d="M-10 -48 C-12 -62 4 -70 10 -60 C14 -54 8 -48 2 -48z" fill="url(#creamG)" stroke="#b49a78" stroke-width="3.5"/>
 <path d="M-34 8 q16 -10 30 0 M6 6 q14 -10 30 -2 M-24 -14 q12 -8 22 0 M4 -16 q12 -8 22 0 M-12 -36 q10 -6 20 0" stroke="#e3d4ba" stroke-width="3" fill="none" stroke-linecap="round"/>
 <ellipse cx="-18" cy="-2" rx="9" ry="4" fill="#fff"/><ellipse cx="-10" cy="-40" rx="6" ry="3" fill="#fff"/>
</g>
<radialGradient id="cherryG" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#ff7a8a"/><stop offset=".5" stop-color="#d81e3c"/><stop offset="1" stop-color="#8a0e22"/></radialGradient>
<g id="cherry"><path d="M2 -10 q4 -18 18 -22" stroke="#4a7a2a" stroke-width="3" fill="none" stroke-linecap="round"/><circle cx="0" cy="2" r="13" fill="url(#cherryG)" stroke="{OUT}" stroke-width="3"/><ellipse cx="-5" cy="-3" rx="4" ry="2.4" fill="#fff" opacity=".8" transform="rotate(-25 -5 -3)"/></g>
'''
def heap(item, cx, cy, w, h, n, seed, scale=1.0, variants=None, clip=None):
    r = random.Random(seed)
    pts = []
    for i in range(n):
        x = cx + r.uniform(-w/2, w/2); y = cy + r.uniform(-h/2, h/2)
        pts.append((y, x))
    pts.sort()
    out = []
    for y, x in pts:
        it = r.choice(variants) if variants else item
        out.append(f'<use href="#{it}" transform="translate({x:.1f},{y:.1f}) rotate({r.uniform(0,360):.0f}) scale({scale*r.uniform(.9,1.08):.2f})"/>')
    g = ''.join(out)
    return f'<g clip-path="url(#{clip})">{g}</g>' if clip else g
def tray(x, y, w, h, content, label, idn):
    return f'''<g transform="translate({x},{y})" filter="url(#shadow)">
 <clipPath id="c{idn}"><rect x="10" y="10" width="{w-20}" height="{h-20}" rx="12"/></clipPath>
 <rect width="{w}" height="{h}" rx="20" fill="url(#trayG)" stroke="{OUT}" stroke-width="4"/>
 <rect x="10" y="10" width="{w-20}" height="{h-20}" rx="12" fill="#e9d6b4"/>
 <g clip-path="url(#c{idn})">{content}</g>
 <rect x="10" y="10" width="{w-20}" height="{h-20}" rx="12" fill="none" stroke="#c9a77a" stroke-width="2"/>
 <rect x="-4" y="-6" width="{w+8}" height="14" rx="7" fill="url(#goldR)" stroke="{OUT}" stroke-width="3"/>
 <rect x="{w/2-58}" y="{h-6}" width="116" height="26" rx="13" fill="#1d1a1f" stroke="url(#goldR)" stroke-width="3"/>
 <text x="{w/2}" y="{h+12}" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="11" fill="#f2d27a">{label}</text></g>'''

def pack(variants, w, h, d, seed, scale=1.0, rot=360, jitter=.25, ox=10, oy=10, rows_extra=1):
    """dense, neat pile filling the tray; drawn back (top) to front (bottom)"""
    r = random.Random(seed)
    out = []
    y = oy - d*0.3
    row = 0
    while y < oy + h + d*0.3:
        x = ox - d*0.2 + (d/2 if row % 2 else 0)
        while x < ox + w + d*0.3:
            jx, jy = r.uniform(-jitter, jitter)*d, r.uniform(-jitter, jitter)*d
            a = r.uniform(-rot/2, rot/2)
            it = r.choice(variants)
            out.append(f'<use href="#{it}" transform="translate({x+jx:.1f},{y+jy:.1f}) rotate({a:.0f}) scale({scale*r.uniform(.92,1.06):.2f})"/>')
            x += d
        y += d*0.82; row += 1
    return ''.join(out)

_cid = [0]
def container(x, y, w, h, variants, d, seed, scale=1.0, rot=360, jitter=.25, label=None, top=34, fill=.97, base="#e9d6b4", scoop=False):
    """clear square acrylic topping container (gelato-pan style), 3/4 view"""
    _cid[0] += 1; k = _cid[0]
    fy = y + top + h*(1-fill)            # contents level on the front face
    inset = 10
    topPoly = f"{x+inset},{y} {x+w-inset},{y} {x+w},{y+top} {x},{y+top}"
    s = f'<g filter="url(#shadow)">'
    s += f'<clipPath id="cf{k}"><rect x="{x}" y="{fy}" width="{w}" height="{y+top+h-fy}" rx="8"/></clipPath>'
    s += f'<clipPath id="ct{k}"><polygon points="{topPoly}"/></clipPath>'
    # back wall + top opening
    s += f'<polygon points="{topPoly}" fill="{base}" stroke="#4a2410" stroke-width="3"/>'
    s += f'<g clip-path="url(#ct{k})"><g transform="translate(0,{y}) scale(1,.55) translate(0,{-y})">{pack(variants, w, top/.55+10, d, seed+500, scale, rot=rot, jitter=jitter, ox=x, oy=y-6)}</g>'
    s += f'<polygon points="{topPoly}" fill="#000" opacity=".08"/></g>'
    # front face with contents
    s += f'<rect x="{x}" y="{y+top}" width="{w}" height="{h}" rx="8" fill="#eef8ff" fill-opacity=".35"/>'
    s += f'<g clip-path="url(#cf{k})"><rect x="{x}" y="{fy}" width="{w}" height="{h}" fill="{base}"/>{pack(variants, w, y+top+h-fy, d, seed, scale, rot=rot, jitter=jitter, ox=x, oy=fy)}</g>'
    s += f'<rect x="{x}" y="{y+top}" width="{w}" height="{h}" rx="8" fill="url(#acryl)" stroke="#4a2410" stroke-width="4"/>'
    s += f'<path d="M{x+10} {y+top+10} v{h-24}" stroke="#fff" stroke-width="6" stroke-linecap="round" opacity=".75"/>'
    s += f'<path d="M{x+22} {y+top+10} v{h*0.4:.0f}" stroke="#fff" stroke-width="3" stroke-linecap="round" opacity=".55"/>'
    # rim
    s += f'<polygon points="{topPoly}" fill="none" stroke="#4a2410" stroke-width="4" stroke-linejoin="round"/>'
    s += f'<path d="M{x} {y+top} h{w}" stroke="#fff" stroke-width="3" opacity=".8"/>'
    if scoop:
        s += f'<g transform="translate({x+w*0.68},{y+top-6}) rotate(-35)"><rect x="-4" y="-56" width="8" height="50" rx="4" fill="url(#chromeI)" stroke="#4a2410" stroke-width="2.5"/><ellipse cx="0" cy="0" rx="14" ry="9" fill="url(#chromeI)" stroke="#4a2410" stroke-width="2.5"/></g>'
    if label:
        s += f'<rect x="{x+w/2-50}" y="{y+top+h-14}" width="100" height="24" rx="12" fill="#1d1a1f" stroke="url(#goldR)" stroke-width="3"/><text x="{x+w/2}" y="{y+top+h+3}" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="10.5" fill="#f2d27a">{label}</text>'
    return s + '</g>'

EXTRA_DEFS = '''<linearGradient id="acryl" x1="0" x2="1"><stop offset="0" stop-color="#fff" stop-opacity=".35"/><stop offset=".25" stop-color="#fff" stop-opacity=".06"/><stop offset=".8" stop-color="#dff2ff" stop-opacity=".08"/><stop offset="1" stop-color="#cfe8f7" stop-opacity=".3"/></linearGradient>
<linearGradient id="chromeI" x1="0" x2="1"><stop offset="0" stop-color="#8a929e"/><stop offset=".35" stop-color="#f4f7fb"/><stop offset="1" stop-color="#8a929e"/></linearGradient>
<linearGradient id="alu" x1="0" x2="1"><stop offset="0" stop-color="#7f8894"/><stop offset=".2" stop-color="#f6f8fb"/><stop offset=".45" stop-color="#c3cad3"/><stop offset=".75" stop-color="#eef1f5"/><stop offset="1" stop-color="#7a828e"/></linearGradient>
<g id="whipper">
 <rect x="-36" y="-240" width="72" height="236" rx="16" fill="url(#alu)" stroke="#4a2410" stroke-width="4"/>
 <path d="M-36 -20 h72" stroke="#4a2410" stroke-width="2" opacity=".4"/>
 <path d="M-22 -226 v200" stroke="#fff" stroke-width="8" stroke-linecap="round" opacity=".85"/>
 <rect x="-30" y="-150" width="60" height="44" rx="6" fill="#1d1a1f" stroke="#4a2410" stroke-width="3"/>
 <text x="0" y="-131" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="10" fill="#f2d27a">WHIPPED</text>
 <text x="0" y="-117" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="10" fill="#f2d27a">CREAM</text>
 <path d="M-40 -244 h80 v-18 a10 10 0 0 0 -10 -10 h-60 a10 10 0 0 0 -10 10z" fill="#2b2026" stroke="#4a2410" stroke-width="4"/>
 <path d="M-40 -252 h80" stroke="url(#goldR)" stroke-width="5"/>
 <path d="M-8 -272 v-20 h16 v20" fill="url(#alu)" stroke="#4a2410" stroke-width="3"/>
 <path d="M-10 -292 l4 -24 h12 l4 24z" fill="url(#alu)" stroke="#4a2410" stroke-width="3" stroke-linejoin="round"/>
 <path d="M-4 -312 v12 M0 -314 v14 M4 -312 v12" stroke="#4a2410" stroke-width="1.5"/>
 <path d="M14 -274 q34 -6 46 -34 l-8 -6 q-12 22 -40 26z" fill="#2b2026" stroke="#4a2410" stroke-width="3" stroke-linejoin="round"/>
 <rect x="-52" y="-262" width="14" height="30" rx="5" fill="url(#goldR)" stroke="#4a2410" stroke-width="3"/>
</g>'''
