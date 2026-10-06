"""Store one generated batch image, cut every object out, name it, and style-match it.

usage: python3 take.py BATCH_NUMBER IMAGE.png [--no-match]
  BATCH_NUMBER  1..79, from AuraFizz/art/tripo/batches.json (the prompt page order)

Writes:
  AuraFizz/art/sheets/batchNN.png            the untouched sheet
  AuraFizz/art/cut/<group>/<CODE>.png        one transparent PNG per object, style-matched
  /tmp/take_preview.png                      all cut-outs on a dark ground, for checking
"""
import json
import os
import shutil
import subprocess
import sys

import cv2
import numpy as np

here = os.path.dirname(os.path.abspath(__file__))
repo = os.path.abspath(os.path.join(here, "..", "..", "..", ".."))
art = os.path.join(repo, "AuraFizz", "art")

n, src = int(sys.argv[1]), sys.argv[2]
match = "--no-match" not in sys.argv
batch = json.load(open(os.path.join(art, "tripo", "batches.json")))["batches"][n - 1]
codes = batch["codes"]
group = batch["section"].split(". ", 1)[1].split(" ")[0].lower()  # stations, materials, ingredients, liquids
out = os.path.join(art, "cut", group)
os.makedirs(out, exist_ok=True)
os.makedirs(os.path.join(art, "sheets"), exist_ok=True)
sheet = os.path.join(art, "sheets", f"batch{n:02d}.png")
shutil.copy(src, sheet)

r = subprocess.run([sys.executable, os.path.join(here, "cut.py"), sheet, out, *codes], capture_output=True, text=True)
print(r.stdout.strip(), r.stderr.strip()[-400:])
if match:
    for c in codes:
        p = os.path.join(out, c + ".png")
        if os.path.exists(p):
            subprocess.run([sys.executable, os.path.join(here, "style_match.py"), p, p], capture_output=True)

ims = [cv2.imread(os.path.join(out, c + ".png"), cv2.IMREAD_UNCHANGED) for c in codes]
ims = [i for i in ims if i is not None]
if ims:
    H = max(i.shape[0] for i in ims)
    tiles = []
    for im in ims:
        bg = np.full((H, im.shape[1], 3), (60, 40, 35), np.uint8)
        a = im[:, :, 3:] / 255.0
        y = H - im.shape[0]
        bg[y:] = (im[:, :, :3] * a + bg[y:] * (1 - a)).astype(np.uint8)
        tiles.append(bg)
    prev = np.hstack(tiles)
    if prev.shape[1] > 1600:
        prev = cv2.resize(prev, (1600, int(prev.shape[0] * 1600 / prev.shape[1])))
    cv2.imwrite("/tmp/take_preview.png", prev)
print(f"batch {n}: {batch['title']} -> {out}")
