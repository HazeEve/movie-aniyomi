#!/usr/bin/env python3
"""Preview of the AuraFizzVFX v2 presets, rendered the way Roblox shows them:
additive particles (LightEmission 1) with Brightness, soft bloom, and the spinning
beam rings drawn in 3D (back half behind the player, front half in front).
Settings mirror AuraFizzVFX.luau.   python3 vfx/preview_auras.py -> vfx/preview/auras.gif
"""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.abspath(__file__))
SHEETS = os.path.join(ROOT, "sheets")
W, H, PX = 320, 440, 34
BG = np.array([0.055, 0.07, 0.12], np.float32)
FRAMES, DT = 72, 1 / 30
PITCH = 0.32   # how much we look down on the rings

# ---- particle layers (same numbers as the Roblox module)
LAYERS = {
    "Glow": dict(sheet="Glow", where="Waist", rate=3, life=(1.0, 1.2), size=(5, 6, 6), bright=0.6, tint="main"),
    "FlameAura": dict(sheet="Flame", where="Body", rate=22, life=(0.55, 0.85), size=(1.6, 2.6, 0.2), speed=(3, 6), spread=20, up=8, bright=2.2, tint="main"),
    "Wisps": dict(sheet="Wisp", where="Body", rate=7, life=(0.6, 0.8), size=(1.6, 2.4, 2), speed=(4, 7), spread=15, once=True, bright=2.5, tint="light"),
    "Sparkles": dict(sheet="Sparkle", where="Body", rate=8, life=(0.5, 0.7), size=(0.8, 1.4, 0.4), speed=(1, 3), spread=180, once=True, bright=3, tint="light"),
    "GoldSparkles": dict(sheet="Sparkle", where="Body", rate=9, life=(0.5, 0.7), size=(1.0, 1.7, 0.4), speed=(2, 4), spread=180, once=True, bright=3, tint="gold"),
    "Bolts": dict(sheet="Bolt", where="Body", rate=3, life=(0.35, 0.45), size=(3, 3.6, 3.6), once=True, bright=4, tint="light"),
    "Bubbles": dict(sheet="Bubbles", where="Body", rate=4, life=(1, 1.4), size=(2, 2.6, 2.8), speed=(2, 3), spread=10, bright=1.8, tint="light", fps=14),
    "Impact": dict(sheet="Impact", where="Chest", burst=1, life=(0.45, 0.45), size=(2, 8, 9), once=True, bright=3, tint="light"),
    "Puffs": dict(sheet="Puff", where="Feet", burst=5, life=(0.6, 0.8), size=(1.5, 3.2, 3.6), speed=(3, 5), spread=80, once=True, bright=1.2, tint="light"),
    "Splashes": dict(sheet="Puff", where="Waist", rate=3, life=(0.5, 0.7), size=(1, 2, 2.2), speed=(2, 4), spread=180, once=True, bright=1.5, tint="main"),
}
# ---- beam rings: radius, height, width, texture speed (turns/s), tint, tilt
RINGS = {
    "RingLow": dict(r=3.0, y=-2.4, w=0.9, speed=0.9, tint="main", tilt=0.0),
    "RingMid": dict(r=2.3, y=-0.4, w=0.7, speed=-1.2, tint="light", tilt=0.12),
    "RingHigh": dict(r=1.7, y=1.5, w=0.55, speed=1.5, tint="main", tilt=-0.1),
}
PRESETS = {
    "Cyclone (iced / boba)": (["Glow", "RingLow", "RingMid", "RingHigh", "Wisps", "Sparkles", "Impact"], (40, 150, 255)),
    "Blaze (hot coffee)": (["Glow", "FlameAura", "Wisps", "Sparkles", "RingLow", "Impact"], (255, 110, 40)),
    "Fizz (sodas)": (["Glow", "Bubbles", "Sparkles", "RingLow", "Impact"], (60, 230, 150)),
    "Bloom + Ambrosial": (["Glow", "Sparkles", "Wisps", "RingLow", "RingMid", "Puffs", "Bolts", "GoldSparkles"], (190, 90, 255)),
}
Y = {"Feet": -2.8, "Waist": -0.6, "Chest": 1.1, "Body": 0}


def load():
    fr = {}
    for f in os.listdir(SHEETS):
        if f.endswith(".png") and f != "AuraFX_Streak.png":
            sh = Image.open(os.path.join(SHEETS, f))
            fr[f[7:-4]] = [np.asarray(sh.crop(((i % 4) * 256, (i // 4) * 256, (i % 4 + 1) * 256, (i // 4 + 1) * 256))).astype(np.float32) / 255 for i in range(16)]
    streak = np.asarray(Image.open(os.path.join(SHEETS, "AuraFX_Streak.png"))).astype(np.float32) / 255
    return fr, streak


FRAMES_BY, STREAK = load()


def palette(rgb):
    c = np.array(rgb, np.float32) / 255
    return {"main": c, "light": c + (1 - c) * 0.35, "gold": np.array([1, 0.82, 0.35], np.float32)}


def add_sprite(canvas, arr, cx, cy, w, h, color, bright, fade):
    img = Image.fromarray((arr * 255).astype(np.uint8), "RGBA").resize((max(2, int(w)), max(2, int(h))), Image.BILINEAR)
    a = np.asarray(img).astype(np.float32) / 255
    add = a[..., :3] * color * bright * (a[..., 3:] * fade)
    x0, y0 = int(cx - img.width / 2), int(cy - img.height / 2)
    xs0, ys0 = max(0, x0), max(0, y0)
    xs1, ys1 = min(W, x0 + img.width), min(H, y0 + img.height)
    if xs1 <= xs0 or ys1 <= ys0:
        return
    canvas[ys0:ys1, xs0:xs1] += add[ys0 - y0:ys1 - y0, xs0 - x0:xs1 - x0]


def draw_ring(canvas, ring, pal, t, front, root):
    th = np.linspace(0, 2 * math.pi, 900, endpoint=False)
    sin_t = np.sin(th)
    keep = (sin_t <= 0) if front else (sin_t > 0)          # sin>0 = far side (behind player)
    th, sin_t = th[keep], sin_t[keep]
    r, y = ring["r"], ring["y"]
    u = np.mod(th / (2 * math.pi) * ring.get("tiles", 1) + t * ring["speed"], 1.0)
    col = pal[ring["tint"]] * 2.4
    for vv in np.linspace(0, 1, 18):
        rr = r + (vv - 0.5) * ring["w"]
        sx = root[0] + rr * np.cos(th) * PX
        sy = root[1] - (y + rr * sin_t * PITCH + ring["tilt"] * rr * np.cos(th)) * PX
        tx = (u * (STREAK.shape[1] - 1)).astype(int)
        ty = int(vv * (STREAK.shape[0] - 1))
        s = STREAK[ty, tx]
        val = s[:, :3] * col * s[:, 3:4]
        ix, iy = sx.astype(int), sy.astype(int)
        ok = (ix >= 0) & (ix < W - 1) & (iy >= 0) & (iy < H - 1)
        for dx in (0, 1):
            for dy in (0, 1):
                np.add.at(canvas, (iy[ok] + dy, ix[ok] + dx), val[ok] * 0.5)


def sim(names, rgb, seed=1):
    rnd = random.Random(seed)
    pal = palette(rgb)
    root = (W / 2, H * 0.58)
    parts, acc, out = [], {n: 0.0 for n in names}, []
    for fi in range(FRAMES):
        t = fi * DT
        for n in names:
            d = LAYERS.get(n)
            if not d:
                continue
            count = 0
            if d.get("burst"):
                count = d["burst"] if fi == 0 else 0
            else:
                acc[n] += d["rate"] * DT
                count, acc[n] = int(acc[n]), acc[n] - int(acc[n])
            for _ in range(count):
                pos = np.array([rnd.uniform(-1, 1), rnd.uniform(-1.2, 1.2)]) if d["where"] == "Body" else np.array([0.0, Y[d["where"]]])
                sp = rnd.uniform(*d.get("speed", (0, 0)))
                ang = math.radians(90 + rnd.uniform(-d.get("spread", 0), d.get("spread", 0)))
                parts.append(dict(n=n, pos=pos, vel=np.array([math.cos(ang), math.sin(ang)]) * sp, age=0.0,
                                  life=rnd.uniform(*d["life"]), f0=rnd.randrange(16), flip=rnd.random() < 0.5))
        canvas = np.ones((H, W, 3), np.float32) * BG
        for n in names:
            if n in RINGS:
                draw_ring(canvas, RINGS[n], pal, t, False, root)
        keep = []
        for p in parts:
            d = LAYERS[p["n"]]
            p["age"] += DT
            if p["age"] > p["life"]:
                continue
            keep.append(p)
            p["vel"] = p["vel"] + np.array([0, d.get("up", 0)]) * DT
            p["pos"] = p["pos"] + p["vel"] * DT
            k = p["age"] / p["life"]
            s0, s1, s2 = d["size"]
            size = s0 + (s1 - s0) * k / 0.35 if k < 0.35 else s1 + (s2 - s1) * (k - 0.35) / 0.65
            fr = min(15, int(k * 16)) if d.get("once") else (p["f0"] + int(p["age"] * d.get("fps", 20))) % 16
            arr = FRAMES_BY[d["sheet"]][fr]
            if p["flip"] and d["sheet"] in ("Flame", "Wisp", "Bolt"):
                arr = arr[:, ::-1]
            fade = 1 if k < 0.8 else (1 - k) / 0.2
            add_sprite(canvas, arr, root[0] + p["pos"][0] * PX, root[1] - p["pos"][1] * PX, size * PX, size * PX,
                       pal[d["tint"]], d["bright"], fade)
        parts = keep
        # the player silhouette sits between the back and front halves of the rings
        sil = Image.new("L", (W, H), 0)
        dr = ImageDraw.Draw(sil)
        cx, cy = root
        dr.rounded_rectangle([cx - 0.9 * PX, cy - 1.2 * PX, cx + 0.9 * PX, cy + 2.8 * PX], radius=14, fill=255)
        dr.ellipse([cx - 0.75 * PX, cy - 2.9 * PX, cx + 0.75 * PX, cy - 1.3 * PX], fill=255)
        m = np.asarray(sil).astype(np.float32)[..., None] / 255
        canvas = canvas * (1 - m * 0.85) + np.array([0.05, 0.06, 0.09]) * m * 0.85
        for n in names:
            if n in RINGS:
                draw_ring(canvas, RINGS[n], pal, t, True, root)
        # bloom
        hot = np.clip(canvas - 0.55, 0, None)
        bl = np.asarray(Image.fromarray((np.clip(hot, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(9))).astype(np.float32) / 255
        canvas = canvas + bl * 1.1
        canvas = 1 - np.exp(-canvas * 1.25)          # soft tone-map so whites glow instead of clipping flat
        out.append(Image.fromarray((np.clip(canvas, 0, 1) * 255).astype(np.uint8)))
    return out


def main():
    panels = {name: sim(layers, col, i) for i, (name, (layers, col)) in enumerate(PRESETS.items())}
    gif = []
    for fi in range(FRAMES):
        strip = Image.new("RGB", (W * len(panels), H + 28), tuple(int(c * 255) for c in BG))
        dr = ImageDraw.Draw(strip)
        for k, (name, fr) in enumerate(panels.items()):
            strip.paste(fr[fi], (k * W, 28))
            dr.text((k * W + 10, 8), name, fill=(235, 240, 255))
        gif.append(strip)
    os.makedirs(os.path.join(ROOT, "preview"), exist_ok=True)
    path = os.path.join(ROOT, "preview", "auras.gif")
    gif[0].save(path, save_all=True, append_images=gif[1:], duration=33, loop=0)
    gif[20].save(os.path.join(ROOT, "preview", "auras_still.png"))
    print("wrote", path)


if __name__ == "__main__":
    main()
