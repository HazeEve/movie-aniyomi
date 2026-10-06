"""Push a generated asset image toward the Aura Fizz reference look.

usage: python3 style_match.py IN.png OUT.png [--strength 0.6] [--outline 3] [--no-light]

Works on a sheet with a plain light background or on a transparent cut-out PNG.
1. colour: matches the objects' colour distribution (LAB) to the reference's props
2. outlines: recolours dark line-art to the reference's espresso brown and gives every
   object silhouette a solid outline of the reference's weight
3. light: adds the reference's warm top-left lamp light
"""
import argparse
import os

import cv2
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
REF = os.path.join(HERE, "..", "reference", "style_reference.png")
OUTLINE_RGB = (0x38, 0x26, 0x19)  # measured median outline colour of the reference
# regions of the reference that are props (machine, jars, pitcher, bottles, dome) at 1536x864
PROP_BOXES = [(70, 520, 540, 720), (550, 215, 990, 740), (1000, 465, 1480, 720)]


def ref_chroma():
    ref = cv2.imread(REF)
    sy, sx = ref.shape[0] / 864, ref.shape[1] / 1536
    px = [ref[int(y0 * sy):int(y1 * sy), int(x0 * sx):int(x1 * sx)].reshape(-1, 3) for x0, y0, x1, y1 in PROP_BOXES]
    lab = cv2.cvtColor(np.concatenate(px)[None], cv2.COLOR_BGR2LAB)[0].astype(np.float32)
    c = np.sqrt((lab[:, 1] - 128) ** 2 + (lab[:, 2] - 128) ** 2)
    return float(np.median(c[c > 8]))


def ref_stats():
    ref = cv2.imread(REF)
    sy, sx = ref.shape[0] / 864, ref.shape[1] / 1536
    px = [ref[int(y0 * sy):int(y1 * sy), int(x0 * sx):int(x1 * sx)].reshape(-1, 3) for x0, y0, x1, y1 in PROP_BOXES]
    lab = cv2.cvtColor(np.concatenate(px)[None], cv2.COLOR_BGR2LAB)[0].astype(np.float32)
    return lab.mean(0), lab.std(0)


def foreground(bgr, alpha):
    if alpha is not None:
        return alpha > 127
    h, w = bgr.shape[:2]
    border = np.concatenate([bgr[0], bgr[-1], bgr[:, 0], bgr[:, -1]])
    bg = np.median(border, axis=0)
    lab = cv2.cvtColor(bgr, cv2.COLOR_BGR2LAB).astype(np.float32)
    bgl = cv2.cvtColor(bg.reshape(1, 1, 3).astype(np.uint8), cv2.COLOR_BGR2LAB)[0, 0].astype(np.float32)
    near = (np.linalg.norm(lab - bgl, axis=2) < 10).astype(np.uint8) * 255
    ff = near.copy()
    m = np.zeros((h + 2, w + 2), np.uint8)
    for x in range(0, w, 8):
        for y in (0, h - 1):
            if ff[y, x] == 255:
                cv2.floodFill(ff, m, (x, y), 128)
    for y in range(0, h, 8):
        for x in (0, w - 1):
            if ff[y, x] == 255:
                cv2.floodFill(ff, m, (x, y), 128)
    return ff != 128


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--strength", type=float, default=0.6, help="0..1 colour match strength")
    ap.add_argument("--outline", type=float, default=3.0, help="silhouette outline px at 1536 wide")
    ap.add_argument("--no-light", action="store_true")
    a = ap.parse_args()

    raw = cv2.imread(a.src, cv2.IMREAD_UNCHANGED)
    alpha = raw[:, :, 3] if raw.ndim == 3 and raw.shape[2] == 4 else None
    bgr = raw[:, :, :3].copy()
    h, w = bgr.shape[:2]
    fg = foreground(bgr, alpha)

    # 1. colour: keep each material's identity (white stays white, black stays black),
    #    warm the neutrals like the reference lamp light, match the reference's saturation
    lab = cv2.cvtColor(bgr, cv2.COLOR_BGR2LAB).astype(np.float32)
    A, B = lab[..., 1] - 128, lab[..., 2] - 128
    chroma = np.sqrt(A * A + B * B)
    neutral = np.clip(1 - chroma / 14, 0, 1) * fg
    lab[..., 1] += 1.5 * a.strength * neutral
    lab[..., 2] += 6.0 * a.strength * neutral * (0.4 + 0.6 * lab[..., 0] / 255)
    ref_c = ref_chroma()
    src_c = np.median(chroma[fg & (chroma > 8)]) if (fg & (chroma > 8)).any() else ref_c
    k = 1 + (np.clip(ref_c / max(src_c, 1), 0.8, 1.35) - 1) * a.strength
    sel = fg & (chroma > 8)
    lab[..., 1][sel] = 128 + A[sel] * k
    lab[..., 2][sel] = 128 + B[sel] * k
    out = cv2.cvtColor(np.clip(lab, 0, 255).astype(np.uint8), cv2.COLOR_LAB2BGR)

    # 2a. dark line-art -> espresso brown
    g = cv2.cvtColor(out, cv2.COLOR_BGR2GRAY)
    edge = cv2.dilate(cv2.Canny(cv2.GaussianBlur(g, (3, 3), 0), 50, 140), np.ones((2, 2), np.uint8)) > 0
    # thin dark strokes only (not big black surfaces): dark pixel with a lighter neighbourhood
    local = cv2.blur(g, (15, 15))
    lines = fg & edge & (g < 60) & (local.astype(int) - g > 25)
    col = np.array(OUTLINE_RGB[::-1], np.float32)
    out[lines] = (out[lines].astype(np.float32) * 0.4 + col * 0.6).astype(np.uint8)

    # 2b. solid silhouette outline at the reference weight
    px = max(1, int(round(a.outline * w / 1536)))
    m = fg.astype(np.uint8)
    ring = (cv2.dilate(m, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * px + 1, 2 * px + 1))) > 0) & ~fg
    if alpha is None:
        out[ring] = col.astype(np.uint8)
    else:
        out[ring] = col.astype(np.uint8)
        alpha = np.maximum(alpha, (ring * 255).astype(np.uint8))

    # 3. warm lamp light from the upper left on the objects
    if not a.no_light:
        yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
        light = 1.0 - np.clip((xx / w * 0.6 + yy / h), 0, 1.6) / 1.6
        warm = np.array([150, 205, 255], np.float32)  # BGR warm gold
        f = (light * 0.10)[..., None] * fg[..., None]
        out = (out.astype(np.float32) * (1 - f) + warm * f).clip(0, 255).astype(np.uint8)

    if alpha is not None:
        out = np.dstack([out, alpha])
    cv2.imwrite(a.dst, out)
    print("wrote", a.dst)


if __name__ == "__main__":
    main()
