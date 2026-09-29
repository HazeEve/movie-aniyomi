#!/usr/bin/env python3
"""
AuraFizz VFX flipbooks: cel-shaded anime-style sprite sheets for Roblox ParticleEmitters.

Every sheet is 1024x1024 = 4x4 frames of 256px (ParticleEmitter.FlipbookLayout = Grid4x4).
Sheets are GRAYSCALE on purpose: white-hot core, light mid tone, darker outer tone,
hard cel edges. Roblox tints them with ParticleEmitter.Color, so ONE sheet serves
every drink colour (the recolouring happens in AuraFizzVFX, no extra uploads).

    pip install numpy pillow
    python3 vfx/make_flipbooks.py          -> vfx/sheets/*.png + vfx/preview/*

Sheets (loop = plays forever, once = plays over each particle's lifetime):
  Flame      loop   stylized fire tongue with detached flicks (cel fire)
  Swirl      loop   top-view ring of brush streaks spinning (flat tornado rings, no centre orb)
  Wisp       once   energy stroke that rises, curls and thins out
  Sparkle    once   4-point star that pops open, twinkles, and shrinks
  Bolt       loop   crackling lightning bolts, new shape every frame
  Shockwave  once   ring that bursts outward and breaks apart (the "gulp" burst)
  Bubbles    loop   fizzy bubbles rising with highlights
  Puff       once   cartoon smoke puff that swells and breaks up
"""
import math, os
import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ROOT, "sheets")
PREV = os.path.join(ROOT, "preview")
FR = 256          # frame size in the sheet
SS = 2            # supersampling
N = 16            # frames (4x4)
R = FR * SS

# tones (grey values the tint multiplies): outer, mid, core
OUTER, MID, CORE = 0.50, 0.76, 1.0

ys, xs = np.mgrid[0:R, 0:R]
U = (xs + 0.5) / R * 2 - 1           # -1..1 left->right
V = 1 - (ys + 0.5) / R * 2           # -1..1 bottom->top


def waves(u, v, t, seed, n=7, fmin=2.0, fmax=7.0, speeds=(1, 2, -1, 3)):
    """Loopable noise: sum of sines whose time speeds are integers (period 2*pi)."""
    rng = np.random.default_rng(seed)
    out = np.zeros_like(u)
    tot = 0
    for i in range(n):
        f = rng.uniform(fmin, fmax)
        a = rng.uniform(0, 2 * math.pi)
        w = speeds[i % len(speeds)]
        amp = 1.0 / (1 + i * 0.35)
        out += amp * np.sin(f * (math.cos(a) * u + math.sin(a) * v) + w * t + rng.uniform(0, 6.283))
        tot += amp
    return out / tot


def cel(field, c1, c2, c3):
    """Hard-edged 3-tone quantize -> (tone, alpha)."""
    alpha = (field > c1).astype(np.float32)
    tone = np.where(field > c3, CORE, np.where(field > c2, MID, OUTER)).astype(np.float32)
    return tone, alpha


def seg_dist(px, py, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    L2 = dx * dx + dy * dy + 1e-9
    h = np.clip(((px - ax) * dx + (py - ay) * dy) / L2, 0, 1)
    return np.hypot(px - ax - dx * h, py - ay - dy * h), h


def to_frame(tone, alpha):
    """Supersampled float arrays -> 256px RGBA frame (no dark fringes)."""
    tone = np.where(alpha > 0, tone, OUTER)   # transparent pixels keep a mid grey so edges don't darken
    g = (np.clip(tone, 0, 1) * 255).astype(np.uint8)
    a = (np.clip(alpha, 0, 1) * 255).astype(np.uint8)
    img = Image.fromarray(np.dstack([g, g, g, a]), "RGBA")
    return img.resize((FR, FR), Image.LANCZOS)


# ---------------------------------------------------------------- designs
def flame(i):
    t = i / N * 2 * math.pi
    u, v = U * 1.05, V * 1.05
    base = -0.5
    sway = 0.18 * np.sin(2.2 * v - t) * np.clip(v - base, 0, None) ** 1.2
    rad = np.where(v < base, 0.46, 0.46 * np.clip(1 - (v - base) / 1.45, 0, 1) ** 1.1)
    d = np.where(v < base, np.hypot(u, v - base) / 0.46, np.abs(u - sway) / (rad + 1e-3))
    f = 1 - d
    up = np.clip(v - base + 0.2, 0, 2)
    n1 = waves(u * 1.4, v * 1.4, t, 11, fmin=3, fmax=7, speeds=(2, 1, 3, -2))
    n2 = waves(u * 2.2, v * 2.2, t, 12, n=5, fmin=5, fmax=10, speeds=(3, 2, -3))
    f = f + (0.28 + 0.5 * up) * (0.7 * n1 + 0.45 * n2)                        # breakup -> detached flicks up top
    core = 1 - np.hypot(u * 1.1 - sway * 0.5, (v - base - 0.05) * 0.9) / 0.3 + 0.18 * waves(u, v, t, 5, n=4, fmin=3, fmax=5)
    tone, alpha = cel(f, 0.0, 0.3, 9.0)
    tone = np.where((core > 0) & (alpha > 0), CORE, tone)
    return tone, alpha


def swirl(i):
    t = i / N * 2 * math.pi
    r = np.hypot(U, V)
    th = np.arctan2(V, U)
    rng = np.random.default_rng(3)
    f = np.full_like(U, -1.0)
    hi = np.zeros_like(U)
    for k in range(7):
        rk = rng.uniform(0.5, 0.88)
        wk = rng.uniform(0.035, 0.08)
        start = rng.uniform(0, 2 * math.pi)
        L = rng.uniform(1.4, 2.8)
        s = np.mod(th - start - t, 2 * math.pi) / L                       # 0..1 along the streak (head at s=1)
        inside = s <= 1
        thick = wk * np.sin(np.pi * np.clip(s, 0, 1)) ** 0.6 * (0.4 + 0.6 * np.clip(s, 0, 1))
        val = np.where(inside, 1 - np.abs(r - rk) / (thick + 1e-4), -1)
        f = np.maximum(f, val)
        hi = np.maximum(hi, np.where(inside & (s > 0.55), 1 - np.abs(r - rk) / (thick * 0.35 + 1e-4), 0))
    tone, alpha = cel(f, 0.0, 0.45, 2.0)
    tone = np.where(hi > 0.2, CORE, tone)
    return tone, alpha


def wisp(i):
    k = i / (N - 1)                                   # 0 -> 1 over the particle's life
    head = -0.9 + 2.1 * min(1, k * 1.4)
    tail = -0.9 + 2.0 * max(0, (k - 0.25) * 1.3)
    cx = 0.28 * np.sin(2.4 * V + 0.6) * (0.4 + 0.6 * (V + 1) / 2)
    along = (V - tail) / max(head - tail, 1e-3)
    inside = (V >= tail) & (V <= head)
    thick = 0.11 * np.sin(np.pi * np.clip(along, 0, 1)) ** 0.7 * (1 - 0.6 * k)
    f = np.where(inside, 1 - np.abs(U - cx) / (thick + 1e-4), -1)
    tone, alpha = cel(f, 0.0, 0.4, 0.72)
    return tone, alpha


def sparkle(i):
    k = i / (N - 1)
    s = math.sin(math.pi * min(1, k * 1.25)) * (1 - 0.3 * k)          # pop open, then shrink
    rot = 0.35 * k
    u = U * math.cos(rot) - V * math.sin(rot)
    v = U * math.sin(rot) + V * math.cos(rot)
    p = 0.55
    star = 1 - ((np.abs(u) ** p + np.abs(v) ** p) ** (1 / p)) / (0.95 * s + 1e-3)
    dots = np.full_like(U, -1.0)
    rng = np.random.default_rng(7)
    for _ in range(4):
        a = rng.uniform(0, 6.283)
        d = 0.35 + 0.5 * k
        dx, dy = math.cos(a) * d, math.sin(a) * d
        dots = np.maximum(dots, 1 - np.hypot(U - dx, V - dy) / (0.06 * (1 - k) + 1e-3))
    f = np.maximum(star, dots)
    tone, alpha = cel(f, 0.0, 0.35, 0.62)
    return tone, alpha


def bolt(i):
    rng = np.random.default_rng(100 + i)
    f = np.full_like(U, 10.0)
    fc = np.full_like(U, 10.0)

    def zig(x0, y0, x1, y1, n, jit, width):
        nonlocal f, fc
        pts = [(x0, y0)]
        for j in range(1, n):
            q = j / n
            pts.append((x0 + (x1 - x0) * q + rng.uniform(-jit, jit), y0 + (y1 - y0) * q + rng.uniform(-jit * 0.4, jit * 0.4)))
        pts.append((x1, y1))
        for (ax, ay), (bx, by) in zip(pts, pts[1:]):
            d, _ = seg_dist(U, V, ax, ay, bx, by)
            f = np.minimum(f, d / width)
            fc = np.minimum(fc, d / (width * 0.4))
        return pts

    main = zig(rng.uniform(-0.3, 0.3), -0.95, rng.uniform(-0.3, 0.3), 0.95, 9, 0.28, 0.05)
    for _ in range(rng.integers(2, 4)):
        ax, ay = main[rng.integers(2, len(main) - 2)]
        zig(ax, ay, ax + rng.uniform(-0.7, 0.7), ay + rng.uniform(-0.1, 0.5), 4, 0.15, 0.028)
    alpha = (f < 1).astype(np.float32)
    tone = np.where(fc < 1, CORE, MID).astype(np.float32)
    if i % 5 == 4:   # occasional flicker frame
        alpha *= 0.0
    return tone, alpha


def shockwave(i):
    k = i / (N - 1)
    r = np.hypot(U, V)
    th = np.arctan2(V, U)
    rad = 0.12 + 0.82 * (1 - (1 - k) ** 2)
    thick = 0.16 * (1 - k) ** 1.2 + 0.01
    f = 1 - np.abs(r - rad) / thick
    brk = waves(np.cos(th) * 2, np.sin(th) * 2, k * 6.283, 21, n=5, fmin=3, fmax=9, speeds=(0,))
    f = f - np.clip(k * 1.2 - 0.2, 0, 1) * (0.6 + 0.8 * brk)                  # breaks apart as it grows
    inner = 1 - np.abs(r - rad * 0.8) / (thick * 0.4)
    tone, alpha = cel(f, 0.0, 0.45, 0.8)
    tone = np.where((inner > 0.3) & (alpha > 0), CORE, tone)
    return tone, alpha


def bubbles(i):
    t = i / N
    rng = np.random.default_rng(31)
    ring = np.full_like(U, -1.0)
    shine = np.full_like(U, -1.0)
    for b in range(9):
        x = rng.uniform(-0.7, 0.7)
        rr = rng.uniform(0.07, 0.16)
        y = -1.2 + np.mod(rng.uniform(0, 1) + t * rng.integers(1, 3), 1.0) * 2.4
        x += 0.06 * math.sin((t + b) * 2 * math.pi)
        d = np.hypot(U - x, V - y)
        ring = np.maximum(ring, 1 - np.abs(d - rr) / (rr * 0.28))
        shine = np.maximum(shine, 1 - np.hypot(U - x + rr * 0.35, V - y - rr * 0.35) / (rr * 0.25))
        ring = np.maximum(ring, np.where(d < rr, 0.05, -1))               # faint fill inside
    alpha = np.where(ring > 0, np.where(ring > 0.06, 1.0, 0.25), 0).astype(np.float32)
    tone = np.where(ring > 0.06, MID, OUTER).astype(np.float32)
    tone = np.where(shine > 0, CORE, tone)
    alpha = np.where(shine > 0, 1.0, alpha)
    return tone, alpha


def puff(i):
    k = i / (N - 1)
    rng = np.random.default_rng(41)
    f = np.full_like(U, -1.0)
    for _ in range(7):
        a = rng.uniform(0, 6.283)
        d = rng.uniform(0.1, 0.4) * (0.6 + 0.8 * k)
        rr = rng.uniform(0.22, 0.34) * (0.5 + 0.7 * math.sin(math.pi * min(1, k * 1.3 + 0.15)))
        f = np.maximum(f, 1 - np.hypot(U - math.cos(a) * d, V - math.sin(a) * d - 0.2 * k) / (rr + 1e-3))
    erode = waves(U, V, 0, 51, n=5, fmin=4, fmax=9, speeds=(0,))
    f = f - np.clip(k - 0.45, 0, 1) * (1.2 + erode)
    light = f + 0.35 * (V - U) * 0.5                                        # top-left light, like the painted style
    tone, alpha = cel(f, 0.0, 2.0, 3.0)
    tone = np.where(light > 0.45, CORE, np.where(light > 0.2, MID, OUTER))
    return tone.astype(np.float32), alpha


DESIGNS = {"Flame": flame, "Swirl": swirl, "Wisp": wisp, "Sparkle": sparkle,
           "Bolt": bolt, "Shockwave": shockwave, "Bubbles": bubbles, "Puff": puff}


def build():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREV, exist_ok=True)
    frames_by = {}
    for name, fn in DESIGNS.items():
        sheet = Image.new("RGBA", (FR * 4, FR * 4), (0, 0, 0, 0))
        frames = []
        for i in range(N):
            fr = to_frame(*fn(i))
            frames.append(fr)
            sheet.paste(fr, ((i % 4) * FR, (i // 4) * FR))
        sheet.save(os.path.join(OUT, f"AuraFX_{name}.png"))
        frames_by[name] = frames
        print("sheet", name)
    return frames_by


def tint(frame, rgb, bg):
    """What Roblox shows: texture x Color, with a bit of LightEmission-style glow."""
    a = np.asarray(frame).astype(np.float32) / 255
    col = a[..., :3] * np.array(rgb, np.float32) / 255
    col = col + (a[..., :3] ** 3) * 0.35                    # hot core blows toward white (Brightness/LightEmission)
    out = bg * (1 - a[..., 3:]) + np.clip(col, 0, 1) * a[..., 3:]
    return out


def previews(frames_by):
    """Contact sheet: every design in 3 drink colours + an animated GIF of each."""
    colors = [(255, 120, 60), (80, 200, 255), (200, 120, 255)]
    bgc = np.array([35, 43, 61], np.float32) / 255
    cell = 160
    names = list(frames_by)
    W, H = cell * len(colors) * 1 + 40, cell * len(names)
    grid = np.ones((len(names) * cell, len(colors) * cell, 3), np.float32) * bgc
    for r, name in enumerate(names):
        fr = frames_by[name][5].resize((cell, cell), Image.LANCZOS)
        for c, col in enumerate(colors):
            bg = np.ones((cell, cell, 3), np.float32) * bgc
            grid[r * cell:(r + 1) * cell, c * cell:(c + 1) * cell] = tint(fr, col, bg)
    Image.fromarray((grid * 255).astype(np.uint8)).save(os.path.join(PREV, "contact_sheet.png"))
    # animated strip of all designs
    gif = []
    for i in range(N):
        strip = np.ones((cell, cell * len(names), 3), np.float32) * bgc
        for k, name in enumerate(names):
            fr = frames_by[name][i].resize((cell, cell), Image.LANCZOS)
            col = colors[k % len(colors)]
            strip[:, k * cell:(k + 1) * cell] = tint(fr, col, strip[:, k * cell:(k + 1) * cell])
        gif.append(Image.fromarray((strip * 255).astype(np.uint8)))
    gif[0].save(os.path.join(PREV, "all_designs.gif"), save_all=True, append_images=gif[1:], duration=70, loop=0)
    print("previews written")


if __name__ == "__main__":
    previews(build())
