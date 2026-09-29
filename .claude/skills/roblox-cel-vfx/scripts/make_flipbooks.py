#!/usr/bin/env python3
"""
AuraFizz VFX v2: clean, shiny anime VFX textures for Roblox.

How the look works (same trick Roblox VFX artists use):
  * textures are WHITE/GREY: core 1.0, mid 0.62, outer 0.34, plus a soft glow halo
  * in Roblox: LightEmission = 1 (additive) + Brightness 2-4 + Color tint
    -> the core blows out to white-hot, the rim keeps the colour, the halo glows
  * strokes are tapered brush streaks with a white highlight line, drawn at 4x and
    downsampled so edges are crisp but clean

Outputs (vfx/sheets):
  AuraFX_<Name>.png  1024x1024 flipbooks, 4x4 frames of 256px (FlipbookLayout Grid4x4)
     Flame   loop  anime fire tongue with flicks
     Swirl   loop  top-view spinning brush-streak ring (flat rings)
     Wisp    once  energy stroke rising and curling
     Sparkle once  8-point twinkle star with rays
     Bolt    once  lightning strike: grows, flickers, fades
     Impact  once  burst ring + speed spikes (the "gulp" hit)
     Bubbles loop  shiny fizz bubbles rising
     Puff    once  soft cartoon smoke puff
     Glow    loop  soft pulsing orb (put behind everything)
  AuraFX_Streak.png  1024x256 beam texture: tapered brush streaks for the spinning rings

    pip install numpy pillow && python3 vfx/make_flipbooks.py
"""
import math, os
import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ROOT, "sheets")
FR, SS, N = 256, 4, 16
R = FR * SS
OUTER, MID, CORE, HALO = 0.34, 0.62, 1.0, 0.55

ys, xs = np.mgrid[0:R, 0:R].astype(np.float32)
U = (xs + 0.5) / R * 2 - 1
V = 1 - (ys + 0.5) / R * 2


def waves(u, v, t, seed, n=7, fmin=2.0, fmax=7.0, speeds=(1, 2, -1, 3)):
    rng = np.random.default_rng(seed)
    out = np.zeros_like(u)
    tot = 0
    for i in range(n):
        f, a = rng.uniform(fmin, fmax), rng.uniform(0, 2 * math.pi)
        amp = 1.0 / (1 + i * 0.35)
        out += amp * np.sin(f * (math.cos(a) * u + math.sin(a) * v) + speeds[i % len(speeds)] * t + rng.uniform(0, 6.283))
        tot += amp
    return out / tot


def cel(field, c1, c2, c3):
    alpha = (field > c1).astype(np.float32)
    tone = np.where(field > c3, CORE, np.where(field > c2, MID, OUTER)).astype(np.float32)
    return tone, alpha


def seg_dist(px, py, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    h = np.clip(((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy + 1e-9), 0, 1)
    return np.hypot(px - ax - dx * h, py - ay - dy * h)


def add_halo(img, glow=1.0, blur=10):
    """The soft glow halo around every shape: what makes it 'shine' once additive in Roblox."""
    arr = np.asarray(img).astype(np.float32) / 255
    if glow <= 0:
        return img
    halo = np.asarray(Image.fromarray((arr[..., 3] * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(blur))).astype(np.float32) / 255
    halo = np.clip(halo * 1.6, 0, 1) * 0.42 * glow
    a0 = arr[..., 3]
    a_out = a0 + halo * (1 - a0)
    tone_out = (arr[..., 0] * a0 + HALO * halo * (1 - a0)) / np.maximum(a_out, 1e-4)
    out = np.dstack([tone_out, tone_out, tone_out, a_out])
    return Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGBA")


def finish(tone, alpha, glow=1.0, blur=10, size=(FR, FR)):
    tone, alpha = np.nan_to_num(tone), np.nan_to_num(alpha)
    tone = np.where(alpha > 0, tone, OUTER)
    g = (np.clip(tone, 0, 1) * 255).astype(np.uint8)
    a = (np.clip(alpha, 0, 1) * 255).astype(np.uint8)
    img = Image.fromarray(np.dstack([g, g, g, a]), "RGBA").resize(size, Image.LANCZOS)
    return add_halo(img, glow, blur)


def streak_field(r, th, rk, start, L, wk, t_off=0.0):
    """A tapered brush streak along a circle: thick head, long thin tail, white highlight line."""
    s = np.mod(th - start - t_off, 2 * math.pi) / L
    inside = s <= 1
    sc = np.clip(s, 0, 1)
    thick = wk * (np.clip(np.sin(np.pi * sc), 0, None) ** 0.5) * (0.25 + 0.75 * sc ** 1.5)
    val = np.where(inside, 1 - np.abs(r - rk) / (thick + 1e-4), -1)
    hl = np.where(inside & (sc > 0.35), 1 - np.abs(r - rk + thick * 0.25) / (thick * 0.22 + 1e-4), -1)
    return val, hl


# ---------------------------------------------------------------- designs
def flame(i):
    t = i / N * 2 * math.pi
    u, v = U * 1.05, V * 1.05
    base = -0.5
    sway = 0.18 * np.sin(2.2 * v - t) * np.clip(v - base, 0, None) ** 1.2
    rad = np.where(v < base, 0.46, 0.46 * np.clip(1 - (v - base) / 1.45, 0, 1) ** 1.1)
    d = np.where(v < base, np.hypot(u, v - base) / 0.46, np.abs(u - sway) / (rad + 1e-3))
    up = np.clip(v - base + 0.2, 0, 2)
    f = 1 - d + (0.28 + 0.5 * up) * (0.7 * waves(u * 1.4, v * 1.4, t, 11, fmin=3, fmax=7, speeds=(2, 1, 3, -2))
                                     + 0.45 * waves(u * 2.2, v * 2.2, t, 12, n=5, fmin=5, fmax=10, speeds=(3, 2, -3)))
    core = 1 - np.hypot(u * 1.1 - sway * 0.5, (v - base - 0.05) * 0.9) / 0.32 + 0.18 * waves(u, v, t, 5, n=4, fmin=3, fmax=5)
    tone, alpha = cel(f, 0.0, 0.26, 9.0)
    tone = np.where((core > 0) & (alpha > 0), CORE, tone)
    return finish(tone, alpha)


def swirl(i):
    t = i / N * 2 * math.pi
    r, th = np.hypot(U, V), np.arctan2(V, U)
    rng = np.random.default_rng(3)
    f, hl = np.full_like(U, -1.0), np.full_like(U, -1.0)
    for _ in range(8):
        v1, h1 = streak_field(r, th, rng.uniform(0.45, 0.9), rng.uniform(0, 6.283), rng.uniform(1.6, 3.4), rng.uniform(0.03, 0.075), t)
        f, hl = np.maximum(f, v1), np.maximum(hl, h1)
    tone, alpha = cel(f, 0.0, 0.5, 9.0)
    tone = np.where((hl > 0) & (alpha > 0), CORE, tone)
    return finish(tone, alpha, blur=8)


def wisp(i):
    k = i / (N - 1)
    head = -0.9 + 2.1 * min(1, k * 1.4)
    tail = -0.9 + 2.0 * max(0, (k - 0.25) * 1.3)
    cx = 0.28 * np.sin(2.4 * V + 0.6) * (0.4 + 0.6 * (V + 1) / 2)
    along = (V - tail) / max(head - tail, 1e-3)
    inside = (V >= tail) & (V <= head)
    thick = 0.1 * np.sin(np.pi * np.clip(along, 0, 1)) ** 0.7 * (1 - 0.6 * k)
    f = np.where(inside, 1 - np.abs(U - cx) / (thick + 1e-4), -1)
    tone, alpha = cel(f, 0.0, 0.35, 0.7)
    return finish(tone, alpha, blur=8)


def sparkle(i):
    k = i / (N - 1)
    s = math.sin(math.pi * min(1, k * 1.2)) * (1 - 0.25 * k)
    rot = 0.4 * k

    def star(scale, ang, p):
        u = U * math.cos(ang) - V * math.sin(ang)
        v = U * math.sin(ang) + V * math.cos(ang)
        return 1 - ((np.abs(u) ** p + np.abs(v) ** p) ** (1 / p)) / (scale + 1e-3)
    f = np.maximum(star(0.95 * s, rot, 0.42), star(0.5 * s, rot + math.pi / 4, 0.42))   # 8-point twinkle, long rays
    core = 1 - np.hypot(U, V) / (0.14 * s + 1e-3)
    tone, alpha = cel(f, 0.0, 0.25, 0.55)
    tone = np.where(core > 0, CORE, tone)
    return finish(tone, alpha, glow=1.3, blur=14)


def bolt(i):
    rng = np.random.default_rng(7 + (i // 3))          # shape changes every 3 frames (flicker)
    k = i / (N - 1)
    grow = min(1, k * 4)                                  # strikes down in the first frames
    fade = 1 - max(0, (k - 0.6) / 0.4)
    f = np.full_like(U, 10.0)
    fc = np.full_like(U, 10.0)

    def zig(x0, y0, x1, y1, n, jit, width):
        nonlocal f, fc
        pts = [(x0, y0)]
        for j in range(1, n):
            q = j / n
            pts.append((x0 + (x1 - x0) * q + rng.uniform(-jit, jit), y0 + (y1 - y0) * q + rng.uniform(-jit * 0.3, jit * 0.3)))
        pts.append((x1, y1))
        for (ax, ay), (bx, by) in zip(pts, pts[1:]):
            if (0.95 - ay) / 1.9 > grow:
                break
            d = seg_dist(U, V, ax, ay, bx, by)
            f = np.minimum(f, d / (width * fade + 1e-4))
            fc = np.minimum(fc, d / (width * 0.35 * fade + 1e-4))
        return pts

    main = zig(rng.uniform(-0.15, 0.15), 0.95, rng.uniform(-0.2, 0.2), -0.95, 10, 0.3, 0.05)
    for _ in range(3):
        ax, ay = main[rng.integers(2, 7)]
        zig(ax, ay, ax + rng.uniform(-0.7, 0.7), ay - rng.uniform(0.2, 0.6), 4, 0.15, 0.026)
    alpha = (f < 1).astype(np.float32) * (1 if fade > 0.05 else 0)
    tone = np.where(fc < 1, CORE, MID).astype(np.float32)
    return finish(tone, alpha, glow=1.4, blur=12)


def impact(i):
    k = i / (N - 1)
    r, th = np.hypot(U, V), np.arctan2(V, U)
    rad = 0.1 + 0.8 * (1 - (1 - k) ** 2.2)
    thick = 0.13 * (1 - k) ** 1.1 + 0.008
    ring = 1 - np.abs(r - rad) / thick
    inner = 1 - np.abs(r - rad * 0.86) / (thick * 0.35 + 1e-3)
    rng = np.random.default_rng(9)
    spikes = np.full_like(U, -1.0)
    for _ in range(10):                                  # speed spikes shooting outward
        a = rng.uniform(0, 6.283)
        L = rng.uniform(0.18, 0.4) * (1 - k)
        r0 = rad * 0.9 + 0.1 * k
        dth = np.abs(np.angle(np.exp(1j * (th - a))))
        w = 0.05 * (1 - np.clip((r - r0) / (L + 1e-3), 0, 1))
        spikes = np.maximum(spikes, np.where((r > r0) & (r < r0 + L), 1 - dth * r / (w + 1e-4), -1))
    f = np.maximum(ring, spikes)
    tone, alpha = cel(f, 0.0, 0.45, 9.0)
    tone = np.where(((inner > 0) | (spikes > 0.5)) & (alpha > 0), CORE, tone)
    return finish(tone, alpha, glow=1.2, blur=12)


def bubbles(i):
    t = i / N
    rng = np.random.default_rng(31)
    ring = np.full_like(U, -1.0)
    shine = np.full_like(U, -1.0)
    fill = np.zeros_like(U, dtype=bool)
    for b in range(9):
        x = rng.uniform(-0.7, 0.7) + 0.06 * math.sin((t + b) * 2 * math.pi)
        rr = rng.uniform(0.07, 0.16)
        y = -1.2 + np.mod(rng.uniform(0, 1) + t * rng.integers(1, 3), 1.0) * 2.4
        d = np.hypot(U - x, V - y)
        ring = np.maximum(ring, 1 - np.abs(d - rr) / (rr * 0.2))
        shine = np.maximum(shine, 1 - np.hypot(U - x + rr * 0.38, V - y - rr * 0.38) / (rr * 0.22))
        fill |= d < rr
    alpha = np.where(ring > 0, 1.0, np.where(fill, 0.18, 0)).astype(np.float32)
    tone = np.where(ring > 0, MID, OUTER).astype(np.float32)
    tone = np.where(shine > 0, CORE, tone)
    alpha = np.where(shine > 0, 1.0, alpha)
    return finish(tone, alpha, glow=0.8, blur=6)


def puff(i):
    k = i / (N - 1)
    rng = np.random.default_rng(41)
    f = np.full_like(U, -1.0)
    for _ in range(7):
        a = rng.uniform(0, 6.283)
        d = rng.uniform(0.1, 0.4) * (0.6 + 0.8 * k)
        rr = rng.uniform(0.22, 0.34) * (0.5 + 0.7 * math.sin(math.pi * min(1, k * 1.3 + 0.15)))
        f = np.maximum(f, 1 - np.hypot(U - math.cos(a) * d, V - math.sin(a) * d - 0.2 * k) / (rr + 1e-3))
    f = f - np.clip(k - 0.45, 0, 1) * (1.2 + waves(U, V, 0, 51, n=5, fmin=4, fmax=9, speeds=(0,)))
    light = f + 0.35 * (V - U) * 0.5
    alpha = (f > 0).astype(np.float32)
    tone = np.where(light > 0.45, CORE, np.where(light > 0.2, MID, OUTER)).astype(np.float32)
    return finish(tone, alpha, glow=0.6, blur=8)


def glow(i):
    k = 0.85 + 0.15 * math.sin(i / N * 2 * math.pi)
    r = np.hypot(U, V) / k
    a = np.clip(1 - r, 0, 1) ** 2.2
    tone = np.clip(0.6 + 0.4 * (1 - r), 0, 1)
    return finish(tone.astype(np.float32), a.astype(np.float32), glow=0)


DESIGNS = {"Flame": flame, "Swirl": swirl, "Wisp": wisp, "Sparkle": sparkle, "Bolt": bolt,
           "Impact": impact, "Bubbles": bubbles, "Puff": puff, "Glow": glow}


def streak_texture():
    """1024x256 beam texture: tapered brush streaks; wraps horizontally so it tiles round a ring."""
    W, H = 1024 * 2, 256 * 2
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    x, y = xx / W, yy / H
    rng = np.random.default_rng(5)
    f = np.full_like(x, -1.0)
    hl = np.full_like(x, -1.0)
    for _ in range(7):   # few, varied streaks with gaps between = brushy, not a solid ring
        cy, x0, L, w = rng.uniform(0.15, 0.85), rng.uniform(0, 1), rng.uniform(0.12, 0.42), rng.uniform(0.035, 0.12)
        s = np.mod(x - x0, 1.0) / L
        inside = s <= 1
        sc = np.clip(s, 0, 1)
        thick = w * np.clip(np.sin(np.pi * sc), 0, None) ** 0.5 * (0.2 + 0.8 * sc ** 1.4)
        f = np.maximum(f, np.where(inside, 1 - np.abs(y - cy) / (thick + 1e-4), -1))
        hl = np.maximum(hl, np.where(inside & (sc > 0.3), 1 - np.abs(y - cy + thick * 0.2) / (thick * 0.25 + 1e-4), -1))
    alpha = (f > 0).astype(np.float32)
    tone = np.where(hl > 0, CORE, np.where(f > 0.45, MID, OUTER)).astype(np.float32)
    return finish(tone, alpha, glow=1.0, blur=8, size=(1024, 256))


def build():
    os.makedirs(OUT, exist_ok=True)
    for old in os.listdir(OUT):
        os.remove(os.path.join(OUT, old))
    frames_by = {}
    for name, fn in DESIGNS.items():
        sheet = Image.new("RGBA", (FR * 4, FR * 4), (0, 0, 0, 0))
        frames = [fn(i) for i in range(N)]
        for i, fr in enumerate(frames):
            sheet.paste(fr, ((i % 4) * FR, (i // 4) * FR))
        sheet.save(os.path.join(OUT, f"AuraFX_{name}.png"))
        frames_by[name] = frames
        print("sheet", name)
    streak_texture().save(os.path.join(OUT, "AuraFX_Streak.png"))
    print("beam texture Streak")
    return frames_by


if __name__ == "__main__":
    build()
