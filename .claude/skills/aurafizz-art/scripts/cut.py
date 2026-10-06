"""Cut every object out of an asset sheet (plain cream background) into its own transparent PNG.

usage: python3 cut.py SHEET.png OUT_DIR NAME1 NAME2 ...
Names are matched to objects in reading order (top row left to right, then the next row).
The background is removed by flood-filling from the border, so light areas *inside* an
outline (clear glass, white cups) stay opaque.
"""
import sys
import cv2
import numpy as np

src, out, names = sys.argv[1], sys.argv[2], sys.argv[3:]
img = cv2.imread(src, cv2.IMREAD_COLOR)
h, w = img.shape[:2]

# background colour = median of the border pixels
border = np.concatenate([img[0], img[-1], img[:, 0], img[:, -1]])
bg = np.median(border, axis=0)
lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB).astype(np.float32)
bg_lab = cv2.cvtColor(bg.reshape(1, 1, 3).astype(np.uint8), cv2.COLOR_BGR2LAB).astype(np.float32)[0, 0]
dist = np.linalg.norm(lab - bg_lab, axis=2)
near = (dist < 10).astype(np.uint8)

# flood from the border through background-coloured pixels only
ff = near.copy() * 255
mask = np.zeros((h + 2, w + 2), np.uint8)
for x in range(0, w, 8):
    for y in (0, h - 1):
        if ff[y, x] == 255:
            cv2.floodFill(ff, mask, (x, y), 128)
for y in range(0, h, 8):
    for x in (0, w - 1):
        if ff[y, x] == 255:
            cv2.floodFill(ff, mask, (x, y), 128)
fg = (ff != 128).astype(np.uint8) * 255
# holes enclosed by an object (inside a mug handle, between stems) that are the exact
# background colour are background too; white porcelain and clear glass differ enough to stay
hole = ((dist < 4) & (fg > 0)).astype(np.uint8)
hn, hl, hs, _ = cv2.connectedComponentsWithStats(hole)
for i in range(1, hn):
    if hs[i, cv2.CC_STAT_AREA] > 150:
        fg[hl == i] = 0
fg = cv2.morphologyEx(fg, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
# keep the components' outlines but drop the light anti-aliasing rim (halo)
fg = cv2.erode(fg, np.ones((3, 3), np.uint8))

alpha = cv2.GaussianBlur(fg.astype(np.float32) / 255, (3, 3), 0)

n, lbl, stats, cent = cv2.connectedComponentsWithStats(fg)
objs = [i for i in range(1, n) if stats[i, cv2.CC_STAT_AREA] > (h * w) * 0.002]
# reading order: group into rows by centre y
objs.sort(key=lambda i: cent[i][1])
rows, row = [], []
for i in objs:
    if row and cent[i][1] - cent[row[0]][1] > h * 0.15:
        rows.append(row)
        row = []
    row.append(i)
if row:
    rows.append(row)
order = [i for r in rows for i in sorted(r, key=lambda i: cent[i][0])]

if len(order) != len(names):
    print(f"WARNING: found {len(order)} objects, expected {len(names)}")
pad = 12
for name, i in zip(names, order):
    x, y, bw, bh = stats[i, :4]
    x0, y0 = max(x - pad, 0), max(y - pad, 0)
    x1, y1 = min(x + bw + pad, w), min(y + bh + pad, h)
    own = cv2.dilate((lbl[y0:y1, x0:x1] == i).astype(np.uint8), np.ones((5, 5))) > 0
    a = alpha[y0:y1, x0:x1] * own
    rgba = np.dstack([img[y0:y1, x0:x1], (a * 255).astype(np.uint8)])
    cv2.imwrite(f"{out}/{name}.png", rgba)
    print(name, bw, "x", bh)
