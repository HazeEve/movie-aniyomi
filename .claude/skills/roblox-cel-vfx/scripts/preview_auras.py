#!/usr/bin/env python3
"""Rough 2D preview of the AuraFizzVFX presets using the real flipbook sheets.
Mirrors the layer settings in AuraFizzVFX.luau (side view, 1 stud = 34 px).
    python3 vfx/preview_auras.py   -> vfx/preview/auras.gif
"""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.abspath(__file__))
SHEETS = os.path.join(ROOT, "sheets")
W, H, PX = 300, 420, 34
BG = np.array([35, 43, 61], np.float32) / 255
FRAMES, DT = 60, 1 / 30

LAYERS = {  # sheet, where, rate, life, size(3), speed, spread, once, flat, tint, burst, up, fps
    "FlameAura": dict(sheet="Flame", where="Body", rate=22, life=(0.55, 0.85), size=(1.6, 2.6, 0.2), speed=(3, 6), spread=20, up=8, tint="main"),
    "SwirlLow": dict(sheet="Swirl", where="Feet", rate=2.5, life=(1.1, 1.3), size=(4.5, 6.5, 7), flat=True, tint="light"),
    "SwirlMid": dict(sheet="Swirl", where="Waist", rate=2, life=(1, 1.2), size=(3.5, 5, 5.5), flat=True, tint="main"),
    "SwirlHigh": dict(sheet="Swirl", where="Chest", rate=1.6, life=(0.9, 1.1), size=(2.6, 3.8, 4.2), flat=True, tint="light"),
    "Wisps": dict(sheet="Wisp", where="Body", rate=7, life=(0.6, 0.8), size=(1.6, 2.4, 2), speed=(4, 7), spread=15, once=True, tint="light"),
    "Sparkles": dict(sheet="Sparkle", where="Body", rate=7, life=(0.5, 0.7), size=(0.7, 1.2, 0.4), speed=(1, 3), spread=180, once=True, tint="light"),
    "GoldSparkles": dict(sheet="Sparkle", where="Body", rate=9, life=(0.5, 0.7), size=(0.9, 1.5, 0.4), speed=(2, 4), spread=180, once=True, tint="gold"),
    "Bolts": dict(sheet="Bolt", where="Body", rate=5, life=(0.18, 0.28), size=(2.2, 3.2, 3), tint="light", fps=30),
    "Bubbles": dict(sheet="Bubbles", where="Body", rate=4, life=(1, 1.4), size=(2, 2.6, 2.8), speed=(2, 3), spread=10, tint="light", fps=14),
    "Burst": dict(sheet="Shockwave", where="Feet", burst=1, life=(0.5, 0.5), size=(1, 11, 13), flat=True, once=True, tint="light"),
    "BurstUp": dict(sheet="Shockwave", where="Chest", burst=1, life=(0.4, 0.4), size=(1, 7, 8), once=True, tint="main"),
    "Puffs": dict(sheet="Puff", where="Feet", burst=5, life=(0.6, 0.8), size=(1.5, 3.2, 3.6), speed=(3, 5), spread=80, once=True, tint="light"),
    "Splashes": dict(sheet="Puff", where="Waist", rate=3, life=(0.5, 0.7), size=(1, 2, 2.2), speed=(2, 4), spread=180, once=True, tint="main"),
}
PRESETS = {
    "Blaze (hot coffee)": (["FlameAura", "Wisps", "Sparkles", "Burst", "Puffs"], (255, 120, 60)),
    "Cyclone (iced / boba)": (["SwirlLow", "SwirlMid", "SwirlHigh", "Wisps", "Burst"], (70, 170, 255)),
    "Fizz (sodas)": (["Bubbles", "Sparkles", "SwirlLow", "Burst"], (120, 230, 140)),
    "Bloom + Ambrosial": (["Sparkles", "Wisps", "SwirlLow", "Puffs", "BurstUp", "Bolts", "GoldSparkles", "FlameAura"], (200, 120, 255)),
}
Y = {"Feet": -2.8, "Waist": -0.6, "Chest": 1.1, "Body": 0}

frames = {}
for f in os.listdir(SHEETS):
    if f.endswith(".png"):
        sh = Image.open(os.path.join(SHEETS, f))
        frames[f[7:-4]] = [sh.crop(((i % 4) * 256, (i // 4) * 256, (i % 4 + 1) * 256, (i // 4 + 1) * 256)) for i in range(16)]


def palette(rgb):
    c = np.array(rgb, np.float32) / 255
    return {"main": c, "light": c + (1 - c) * 0.45, "gold": np.array([1, 0.84, 0.4])}


def sim(names, rgb, seed=1):
    rnd = random.Random(seed)
    pal = palette(rgb)
    parts, acc = [], {n: 0.0 for n in names}
    out = []
    root = np.array([W / 2, H * 0.58])
    for fi in range(FRAMES):
        t = fi * DT
        for n in names:
            d = LAYERS[n]
            count = 0
            if d.get("burst") and fi == 0:
                count = d["burst"]
            elif not d.get("burst"):
                acc[n] += d["rate"] * DT
                count, acc[n] = int(acc[n]), acc[n] - int(acc[n])
            for _ in range(count):
                if d["where"] == "Body":
                    pos = np.array([rnd.uniform(-1, 1), rnd.uniform(-1, 1)])
                else:
                    pos = np.array([0.0, Y[d["where"]]])
                sp = rnd.uniform(*d.get("speed", (0, 0)))
                ang = math.radians(90 + rnd.uniform(-d.get("spread", 0), d.get("spread", 0)))
                vel = np.array([math.cos(ang), math.sin(ang)]) * sp
                parts.append(dict(n=n, pos=pos, vel=vel, age=0.0, life=rnd.uniform(*d["life"]), rot=rnd.uniform(0, 360),
                                  f0=rnd.randrange(16)))
        img = np.ones((H, W, 3), np.float32) * BG
        pil = Image.fromarray((img * 255).astype(np.uint8)).convert("RGBA")
        dr = ImageDraw.Draw(pil)
        # simple character silhouette
        cx, cy = root
        dr.rounded_rectangle([cx - 0.9 * PX, cy - 1.2 * PX, cx + 0.9 * PX, cy + 2.8 * PX], radius=14, fill=(20, 24, 36, 255))
        dr.ellipse([cx - 0.75 * PX, cy - 2.9 * PX, cx + 0.75 * PX, cy - 1.3 * PX], fill=(20, 24, 36, 255))
        keep = []
        layer_imgs = []
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
            size = s0 + (s1 - s0) * min(1, k / 0.35) if k < 0.35 else s1 + (s2 - s1) * (k - 0.35) / 0.65
            fr = min(15, int(k * 16)) if d.get("once") else (p["f0"] + int(p["age"] * d.get("fps", 20))) % 16
            spr = frames[d["sheet"]][fr]
            px = max(2, int(size * PX))
            hgt = max(2, int(px * (0.32 if d.get("flat") else 1)))
            spr = spr.resize((px, hgt), Image.LANCZOS)
            if not d.get("flat"):
                spr = spr.rotate(p["rot"] if d["sheet"] in ("Sparkle", "Bolt", "Puff") else 0, expand=False)
            a = np.asarray(spr).astype(np.float32) / 255
            col = pal[d["tint"]]
            rgb_ = np.clip(a[..., :3] * col + a[..., :3] ** 3 * 0.45, 0, 1)
            alpha = a[..., 3] * (1 if k < 0.8 else (1 - k) / 0.2)
            tile = Image.fromarray(np.dstack([rgb_ * 255, alpha * 255]).astype(np.uint8), "RGBA")
            x = int(cx + p["pos"][0] * PX - tile.width / 2)
            y = int(cy - p["pos"][1] * PX - tile.height / 2)
            if x + tile.width <= 0 or y + tile.height <= 0 or x >= W or y >= H:
                continue
            pil.alpha_composite(tile, (max(0, x), max(0, y)), (max(0, -x), max(0, -y)))
        parts = keep
        out.append(pil.convert("RGB"))
    return out


def main():
    panels = {name: sim(layers, col, i) for i, (name, (layers, col)) in enumerate(PRESETS.items())}
    gif = []
    for fi in range(FRAMES):
        strip = Image.new("RGB", (W * len(panels), H + 30), tuple(int(c * 255) for c in BG))
        dr = ImageDraw.Draw(strip)
        for k, (name, fr) in enumerate(panels.items()):
            strip.paste(fr[fi], (k * W, 30))
            dr.text((k * W + 10, 8), name, fill=(240, 240, 240))
        gif.append(strip)
    path = os.path.join(ROOT, "preview", "auras.gif")
    gif[0].save(path, save_all=True, append_images=gif[1:], duration=33, loop=0)
    gif[24].save(os.path.join(ROOT, "preview", "auras_still.png"))
    print("wrote", path)


if __name__ == "__main__":
    main()
