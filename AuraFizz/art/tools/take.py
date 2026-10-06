"""Store a generated sheet and cut it into named transparent PNGs.

usage: python3 take.py SHEET_NAME GENERATED.png
Reads the item codes from jobs.json, saves sheets/<SHEET_NAME>.png, cuts into cut/<group>/,
and writes a dark-background preview to /tmp/take_preview.png for checking.
"""
import json
import os
import shutil
import subprocess
import sys

import cv2
import numpy as np

here = os.path.dirname(os.path.abspath(__file__))
art = os.path.dirname(here)
name, src = sys.argv[1], sys.argv[2]
job = next(j for j in json.load(open(os.path.join(here, "jobs.json"))) if j["name"] == name)
group = name.split("_")[1].lower() if name.startswith("SHEET_") else "bases"
out = os.path.join(art, "cut", group)
os.makedirs(out, exist_ok=True)
os.makedirs(os.path.join(art, "sheets"), exist_ok=True)
sheet = os.path.join(art, "sheets", name + ".png")
shutil.copy(src, sheet)
r = subprocess.run([sys.executable, os.path.join(here, "cut.py"), sheet, out, *job["codes"]], capture_output=True, text=True)
print(r.stdout.strip(), r.stderr.strip()[-400:])

tiles = []
ims = [cv2.imread(os.path.join(out, c + ".png"), cv2.IMREAD_UNCHANGED) for c in job["codes"]]
ims = [i for i in ims if i is not None]
H = max(i.shape[0] for i in ims)
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
