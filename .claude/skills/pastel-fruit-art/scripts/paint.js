// paint.js — the "digital drawing" layer of the pastel-fruit style.
// Pure Canvas 2D, no dependencies. Used two ways:
//   1. concept-2d.html draws flat illustrations with it (the 2D concept sheet).
//   2. scene-3d.html paints cut-face / skin textures with it for the 3D models.
// Every fill goes through paintShape(): base colour, soft light-to-shade
// gradient, then low-contrast "brush blotches". That combination is what
// makes the style read as hand-painted instead of vector-flat.

export const BG = '#232b3d';

// Palette sampled from the reference sheet. Each material has
// base (mid tone), shade (core shadow), light (lit side).
export const P = {
  apple:      { base: '#dc4a3c', shade: '#a8302f', light: '#f07a5c' },
  appleFlesh: { base: '#f7ecd2', shade: '#ead6a6', light: '#fff8e6' },
  pear:       { base: '#cbd98c', shade: '#98ad5c', light: '#e6efb4' },
  pearFlesh:  { base: '#f5f2d8', shade: '#e3ddb0', light: '#fffdf0' },
  orange:     { base: '#f28b1f', shade: '#d4650f', light: '#f9ab4a' },
  orangeFlesh:{ base: '#f8a534', shade: '#ec8a1c', light: '#fcc464' },
  pith:       { base: '#fde6be', shade: '#f5cf92', light: '#fff4dc' },
  lemon:      { base: '#f6d33f', shade: '#dfaa21', light: '#fbe77a' },
  lemonFlesh: { base: '#fbe487', shade: '#f2cf55', light: '#fff2b8' },
  peach:      { base: '#f49a73', shade: '#e0705c', light: '#fbbf93' },
  peachFlesh: { base: '#f8c898', shade: '#eea878', light: '#fde0bc' },
  pit:        { base: '#b5523d', shade: '#8a3a2c', light: '#cf7358' },
  kiwiSkin:   { base: '#8d6b45', shade: '#6a4f33', light: '#a8845a' },
  kiwiFlesh:  { base: '#a3c64c', shade: '#84a93a', light: '#c4dc74' },
  kiwiCore:   { base: '#eef0c8', shade: '#dbe0a6', light: '#fbfce6' },
  strawberry: { base: '#e2413f', shade: '#b32c36', light: '#f46a5a' },
  berryFlesh: { base: '#f7b6a8', shade: '#ee8e84', light: '#fdd6cc' },
  cherry:     { base: '#d93c3a', shade: '#a92a33', light: '#f06550' },
  blueberry:  { base: '#4f58ba', shade: '#363d8e', light: '#6f79d4' },
  grape:      { base: '#9b3b7a', shade: '#6d2658', light: '#be5c98' },
  banana:     { base: '#f6d24a', shade: '#e0ab2c', light: '#fbe785' },
  bananaFlesh:{ base: '#fbefc6', shade: '#f0dc9c', light: '#fffae6' },
  melonRind:  { base: '#5d9f4b', shade: '#3f7a38', light: '#7fbd62' },
  melonStripe:{ base: '#3a7434', shade: '#2c5a2a', light: '#4d8b44' },
  melonFlesh: { base: '#ea5249', shade: '#d03b3c', light: '#f47a66' },
  melonWhite: { base: '#e7f0c4', shade: '#d3e0a4', light: '#f6fbe4' },
  seed:       { base: '#3a2b27', shade: '#26191a', light: '#5a443c' },
  paleSeed:   { base: '#f6d66c', shade: '#e6b845', light: '#fff0a8' },
  leaf:       { base: '#55a444', shade: '#3b7d33', light: '#7cc25e' },
  stem:       { base: '#7a5a3a', shade: '#5a412a', light: '#9a7650' },
};

// ---------- colour helpers ----------
export function hexToRgb(h) {
  const n = parseInt(h.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}
export function rgbToHex([r, g, b]) {
  return '#' + [r, g, b].map(v => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, '0')).join('');
}
export function mix(a, b, t) {
  const A = hexToRgb(a), B = hexToRgb(b);
  return rgbToHex(A.map((v, i) => v + (B[i] - v) * t));
}
export function withAlpha(hex, a) {
  const [r, g, b] = hexToRgb(hex);
  return `rgba(${r},${g},${b},${a})`;
}

// ---------- any colour -> painted triad ----------
// The style is NOT tied to the palette above. tone() turns any base colour
// into {base, shade, light} using the same rules the reference follows:
// shadows shift cool (toward blue-violet) and a bit more saturated,
// lights shift warm (toward yellow) and a bit less saturated. Never black, never white.
export function hexToHsl(hex) {
  let [r, g, b] = hexToRgb(hex).map(v => v / 255);
  const mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2;
  if (mx === mn) return [0, 0, l];
  const d = mx - mn, s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
  const h = mx === r ? (g - b) / d + (g < b ? 6 : 0) : mx === g ? (b - r) / d + 2 : (r - g) / d + 4;
  return [h * 60, s, l];
}
export function hslToHex([h, s, l]) {
  h = ((h % 360) + 360) % 360; s = Math.max(0, Math.min(1, s)); l = Math.max(0, Math.min(1, l));
  const k = n => (n + h / 30) % 12, a = s * Math.min(l, 1 - l);
  const f = n => l - a * Math.max(-1, Math.min(k(n) - 3, 9 - k(n), 1));
  return rgbToHex([f(0), f(8), f(4)].map(v => v * 255));
}
const towardHue = (h, target, amt) => { const d = ((target - h + 540) % 360) - 180; return h + Math.sign(d) * Math.min(Math.abs(d), amt); };
export function tone(base, o = {}) {
  const { depth = 0.12, lift = 0.1, shift = 1 } = o;
  const [h, s, l] = hexToHsl(base);
  const grey = s < 0.08;
  const shade = hslToHex([grey ? 230 : towardHue(h, 245, 10 * shift), grey ? 0.1 : s * 0.88, Math.max(l * 0.6, l - depth - 0.05 * (1 - l))]); // never crush to black
  const light = hslToHex([grey ? 50 : towardHue(h, 55, 8 * shift), grey ? 0.08 : s, l + Math.min(lift, (0.97 - l) * 0.5)]);
  return { base, shade, light };
}
// Accept a triad or a bare hex anywhere a colour is expected.
export const triad = c => (typeof c === 'string' ? tone(c) : c);

// Deterministic RNG so drawings are stable between runs.
export function rng(seed = 1) {
  let s = seed >>> 0 || 1;
  return () => ((s = (s * 1664525 + 1013904223) >>> 0) / 4294967296);
}

// ---------- the core brush ----------
// Fill `path` (Path2D) with the painted treatment.
// box = {x, y, w, h}: bounds of the shape, used to place the light.
// opts.light = [lx, ly] in -1..1 box space (default top-left, like the reference).
export function paintShape(ctx, path, c, box, opts = {}) {
  c = triad(c);
  const { light = [-0.35, -0.45], blotches = 26, seed = 7, flat = false } = opts;
  const { x, y, w, h } = box;
  const cx = x + w / 2, cy = y + h / 2, R = Math.max(w, h);
  ctx.save();
  ctx.clip(path);
  ctx.fillStyle = c.base;
  ctx.fillRect(x - 2, y - 2, w + 4, h + 4);
  if (!flat) {
    // Soft light -> base -> shade ramp. The wide middle band keeps it matte.
    const lx = cx + light[0] * w * 0.5, ly = cy + light[1] * h * 0.5;
    const g = ctx.createRadialGradient(lx, ly, 0, lx, ly, R * 0.95);
    g.addColorStop(0, withAlpha(c.light, 0.9));
    g.addColorStop(0.3, withAlpha(c.base, 0));
    g.addColorStop(0.52, withAlpha(c.base, 0));
    g.addColorStop(1, withAlpha(c.shade, 0.95));
    ctx.fillStyle = g;
    ctx.fillRect(x - 2, y - 2, w + 4, h + 4);
  }
  // Brush blotches: many large, very transparent dabs of light/shade tone.
  const r = rng(seed);
  for (let i = 0; i < blotches; i++) {
    const bx = x + r() * w, by = y + r() * h, br = R * (0.08 + r() * 0.16);
    const tone = r() < 0.5 ? c.light : c.shade;
    const g = ctx.createRadialGradient(bx, by, 0, bx, by, br);
    g.addColorStop(0, withAlpha(tone, 0.13));
    g.addColorStop(1, withAlpha(tone, 0));
    ctx.fillStyle = g;
    ctx.fillRect(bx - br, by - br, br * 2, br * 2);
  }
  ctx.restore();
}

// ---------- path helpers ----------
export function ellipsePath(cx, cy, rx, ry, rot = 0) {
  const p = new Path2D();
  p.ellipse(cx, cy, rx, ry, rot, 0, Math.PI * 2);
  return p;
}
// Closed smooth path through points (Catmull-Rom -> Bezier).
export function smoothPath(pts, closed = true) {
  const p = new Path2D();
  const n = pts.length;
  const get = i => pts[closed ? (i + n) % n : Math.max(0, Math.min(n - 1, i))];
  p.moveTo(pts[0][0], pts[0][1]);
  for (let i = 0; i < (closed ? n : n - 1); i++) {
    const p0 = get(i - 1), p1 = get(i), p2 = get(i + 1), p3 = get(i + 2);
    p.bezierCurveTo(
      p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6,
      p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6,
      p2[0], p2[1]);
  }
  if (closed) p.closePath();
  return p;
}
export function boxOf(pts) {
  const xs = pts.map(p => p[0]), ys = pts.map(p => p[1]);
  const x = Math.min(...xs), y = Math.min(...ys);
  return { x, y, w: Math.max(...xs) - x, h: Math.max(...ys) - y };
}
// A lathe profile [[r, y], ...] (bottom->top, y up) -> symmetric outline in canvas space.
export function profileOutline(profile, cx, baseY, scale) {
  const right = profile.map(([r, y]) => [cx + r * scale, baseY - y * scale]);
  const left = profile.slice().reverse().map(([r, y]) => [cx - r * scale, baseY - y * scale]);
  return right.concat(left);
}
export function shrink(pts, k) {
  const b = boxOf(pts), cx = b.x + b.w / 2, cy = b.y + b.h / 2;
  return pts.map(([x, y]) => [cx + (x - cx) * k, cy + (y - cy) * k]);
}

// ---------- reusable motifs ----------
// Teardrop seed; angle points the tip.
export function seed(ctx, x, y, len, ang, c = P.seed) {
  const pts = [];
  for (let i = 0; i < 16; i++) {
    const t = (i / 16) * Math.PI * 2;
    const rr = len * 0.5 * (1 - 0.45 * Math.cos(t)) * (0.55 + 0.45 * Math.abs(Math.sin(t / 2)));
    pts.push([Math.cos(t) * rr * 0.62, Math.sin(t) * rr]);
  }
  const rot = pts.map(([px, py]) => [
    x + px * Math.cos(ang) - py * Math.sin(ang),
    y + px * Math.sin(ang) + py * Math.cos(ang)]);
  paintShape(ctx, smoothPath(rot), c, boxOf(rot), { blotches: 3 });
}

export function leafPath(x, y, len, width, ang) {
  const pts = [];
  for (let i = 0; i <= 12; i++) {
    const t = i / 12;
    pts.push([t * len, Math.sin(t * Math.PI) * width * (1 - 0.35 * t)]);
  }
  for (let i = 12; i >= 0; i--) {
    const t = i / 12;
    pts.push([t * len, -Math.sin(t * Math.PI) * width * 0.75 * (1 - 0.35 * t)]);
  }
  return pts.map(([px, py]) => [
    x + px * Math.cos(ang) - py * Math.sin(ang),
    y + px * Math.sin(ang) + py * Math.cos(ang)]);
}
export function leaf(ctx, x, y, len, width, ang) {
  const pts = leafPath(x, y, len, width, ang);
  paintShape(ctx, smoothPath(pts), P.leaf, boxOf(pts), { blotches: 8 });
  // single soft midrib, lighter than the leaf — never a dark line
  ctx.save();
  ctx.strokeStyle = withAlpha(P.leaf.light, 0.55);
  ctx.lineWidth = Math.max(1, width * 0.1);
  ctx.lineCap = 'round';
  ctx.beginPath();
  ctx.moveTo(x, y);
  ctx.lineTo(x + Math.cos(ang) * len * 0.8, y + Math.sin(ang) * len * 0.8);
  ctx.stroke();
  ctx.restore();
}
export function stem(ctx, x0, y0, x1, y1, w, c = P.stem) {
  ctx.save();
  ctx.lineCap = 'round';
  ctx.strokeStyle = c.base;
  ctx.lineWidth = w;
  ctx.beginPath();
  ctx.moveTo(x0, y0);
  ctx.quadraticCurveTo((x0 + x1) / 2 + w, (y0 + y1) / 2, x1, y1);
  ctx.stroke();
  ctx.strokeStyle = withAlpha(c.light, 0.6);
  ctx.lineWidth = w * 0.35;
  ctx.stroke();
  ctx.restore();
}

// ---------- cross-section painters (used for 2D art AND 3D cut-face textures) ----------

// Citrus wheel: rind ring, pith ring, N juicy segments with pale membranes.
export function citrusSlice(ctx, cx, cy, R, skin, flesh, opts = {}) {
  const { segments = 10, seedCount = 0 } = opts;
  paintShape(ctx, ellipsePath(cx, cy, R, R), skin, { x: cx - R, y: cy - R, w: 2 * R, h: 2 * R }, { blotches: 10 });
  const Rp = R * 0.9;
  paintShape(ctx, ellipsePath(cx, cy, Rp, Rp), P.pith, { x: cx - Rp, y: cy - Rp, w: 2 * Rp, h: 2 * Rp }, { flat: true, blotches: 6 });
  const Rs = R * 0.8, gap = R * 0.06;
  for (let i = 0; i < segments; i++) {
    const a0 = (i / segments) * Math.PI * 2, a1 = ((i + 1) / segments) * Math.PI * 2;
    const am = (a0 + a1) / 2;
    const ox = Math.cos(am) * gap, oy = Math.sin(am) * gap;
    const p = new Path2D();
    p.moveTo(cx + ox + Math.cos(am) * R * 0.08, cy + oy + Math.sin(am) * R * 0.08);
    p.arc(cx + ox, cy + oy, Rs, a0 + 0.06, a1 - 0.06);
    p.closePath();
    paintShape(ctx, p, flesh, { x: cx - Rs, y: cy - Rs, w: 2 * Rs, h: 2 * Rs }, { light: [Math.cos(am) * 0.6, Math.sin(am) * 0.6], blotches: 6, seed: i + 3 });
  }
  const r = rng(11);
  for (let i = 0; i < seedCount; i++) {
    const a = (i / seedCount) * Math.PI * 2 + 0.3;
    seed(ctx, cx + Math.cos(a) * R * 0.32, cy + Math.sin(a) * R * 0.32, R * 0.12, a + Math.PI / 2, P.paleSeed);
  }
  // tiny pale centre
  paintShape(ctx, ellipsePath(cx, cy, R * 0.07, R * 0.07), P.pith, { x: cx - R * 0.07, y: cy - R * 0.07, w: R * 0.14, h: R * 0.14 }, { flat: true, blotches: 0 });
}

// Kiwi: brown skin, green flesh, cream core, ring of black seeds.
export function kiwiSlice(ctx, cx, cy, R, ry = R) {
  const box = (rx, rY) => ({ x: cx - rx, y: cy - rY, w: 2 * rx, h: 2 * rY });
  paintShape(ctx, ellipsePath(cx, cy, R, ry), P.kiwiSkin, box(R, ry), { blotches: 8 });
  paintShape(ctx, ellipsePath(cx, cy, R * 0.92, ry * 0.92), P.kiwiFlesh, box(R * 0.92, ry * 0.92), { blotches: 20 });
  // radial light streaks
  ctx.save();
  ctx.strokeStyle = withAlpha(P.kiwiFlesh.light, 0.45);
  ctx.lineWidth = R * 0.025;
  ctx.lineCap = 'round';
  for (let i = 0; i < 28; i++) {
    const a = (i / 28) * Math.PI * 2;
    ctx.beginPath();
    ctx.moveTo(cx + Math.cos(a) * R * 0.38, cy + Math.sin(a) * ry * 0.38);
    ctx.lineTo(cx + Math.cos(a) * R * 0.78, cy + Math.sin(a) * ry * 0.78);
    ctx.stroke();
  }
  ctx.restore();
  paintShape(ctx, ellipsePath(cx, cy, R * 0.3, ry * 0.3), P.kiwiCore, box(R * 0.3, ry * 0.3), { flat: true, blotches: 4 });
  for (let i = 0; i < 22; i++) {
    const a = (i / 22) * Math.PI * 2;
    seed(ctx, cx + Math.cos(a) * R * 0.37, cy + Math.sin(a) * ry * 0.37, R * 0.09, a + Math.PI / 2);
  }
}

// Watermelon wedge face: point at bottom, rind arc on top.
// Returns the outline points so 3D can reuse the exact same shape.
export function melonWedgePoints(cx, apexY, R, spread = 0.52) {
  const pts = [[cx, apexY]];
  for (let i = 0; i <= 24; i++) {
    const a = -Math.PI / 2 - spread + (i / 24) * spread * 2;
    pts.push([cx + Math.cos(a) * R, apexY + Math.sin(a) * R]);
  }
  return pts;
}
export function melonWedge(ctx, cx, apexY, R, spread = 0.52) {
  const layer = (rr, c, flat) => {
    const pts = melonWedgePoints(cx, apexY, rr, spread);
    const p = new Path2D();
    p.moveTo(cx, apexY);
    p.arc(cx, apexY, rr, -Math.PI / 2 - spread, -Math.PI / 2 + spread);
    p.closePath();
    paintShape(ctx, p, c, boxOf(pts), { flat, blotches: 14, light: [0, -0.8] });
  };
  layer(R, P.melonRind);
  layer(R * 0.93, P.melonWhite, true);
  layer(R * 0.87, P.melonFlesh);
  const r = rng(5);
  for (let i = 0; i < 7; i++) {
    const t = 0.35 + r() * 0.4;
    const a = -Math.PI / 2 + (r() - 0.5) * spread * 1.4;
    seed(ctx, cx + Math.cos(a) * R * t, apexY + Math.sin(a) * R * t, R * 0.07, a + Math.PI / 2);
  }
}

// Pome / stone-fruit cut lengthwise: skin rim, flesh, core with seeds or a pit.
export function pomeCut(ctx, outline, skin, flesh, opts = {}) {
  const { core = 'seeds' } = opts;
  paintShape(ctx, smoothPath(outline), skin, boxOf(outline), { blotches: 6 });
  const inner = shrink(outline, 0.92);
  const b = boxOf(inner);
  paintShape(ctx, smoothPath(inner), flesh, b, { blotches: 18, light: [-0.2, -0.3] });
  const cx = b.x + b.w / 2, cy = b.y + b.h * 0.52;
  if (core === 'seeds') {
    const cr = b.w * 0.16;
    paintShape(ctx, ellipsePath(cx, cy, cr, cr * 1.25), { base: flesh.shade, shade: mix(flesh.shade, skin.shade, 0.15), light: flesh.base },
      { x: cx - cr, y: cy - cr * 1.25, w: cr * 2, h: cr * 2.5 }, { blotches: 3 });
    seed(ctx, cx - cr * 0.35, cy, cr * 0.75, Math.PI + 0.25);
    seed(ctx, cx + cr * 0.35, cy, cr * 0.75, Math.PI - 0.25);
  } else if (core === 'pit') {
    const pr = b.w * 0.2;
    paintShape(ctx, ellipsePath(cx, cy, pr, pr * 1.2), P.pit, { x: cx - pr, y: cy - pr * 1.2, w: pr * 2, h: pr * 2.4 }, { blotches: 6 });
  } else if (core === 'berry') {
    // strawberry: pale heart streaks from the calyx
    ctx.save();
    ctx.clip(smoothPath(inner));
    ctx.strokeStyle = withAlpha('#ffffff', 0.35);
    ctx.lineWidth = b.w * 0.06;
    ctx.lineCap = 'round';
    for (const k of [-0.25, 0, 0.25]) {
      ctx.beginPath();
      ctx.moveTo(cx + k * b.w * 0.2, b.y + b.h * 0.08);
      ctx.quadraticCurveTo(cx + k * b.w * 0.6, cy, cx + k * b.w * 0.25, b.y + b.h * 0.85);
      ctx.stroke();
    }
    ctx.restore();
  }
}

// Simple procedural skin textures for 3D wraps (u around, v bottom->top).
export function stripeSkin(ctx, W, H) {
  paintShape(ctx, (() => { const p = new Path2D(); p.rect(0, 0, W, H); return p; })(), P.melonRind, { x: 0, y: 0, w: W, h: H }, { flat: true, blotches: 40 });
  const n = 12;
  for (let i = 0; i < n; i++) {
    const x0 = (i + 0.5) * W / n, pts = [];
    for (let j = 0; j <= 24; j++) {
      const y = (j / 24) * H;
      const taper = Math.sin((j / 24) * Math.PI) * 0.9 + 0.1;
      pts.push([x0 + Math.sin(j * 1.7 + i) * W * 0.012 + W * 0.022 * taper, y]);
    }
    for (let j = 24; j >= 0; j--) {
      const y = (j / 24) * H;
      const taper = Math.sin((j / 24) * Math.PI) * 0.9 + 0.1;
      pts.push([x0 + Math.sin(j * 1.3 + i * 2) * W * 0.012 - W * 0.022 * taper, y]);
    }
    paintShape(ctx, smoothPath(pts), P.melonStripe, boxOf(pts), { flat: true, blotches: 4 });
  }
}
export function speckleSkin(ctx, W, H, c, dot, count, seedN = 3) {
  const p = new Path2D(); p.rect(0, 0, W, H);
  paintShape(ctx, p, c, { x: 0, y: 0, w: W, h: H }, { flat: true, blotches: 30 });
  const r = rng(seedN);
  for (let i = 0; i < count; i++) {
    const x = r() * W, y = r() * H, s = (0.6 + r() * 0.6) * dot;
    ctx.fillStyle = withAlpha(r() < 0.5 ? c.shade : c.light, 0.35);
    ctx.beginPath(); ctx.ellipse(x, y, s, s * 0.7, r() * 3, 0, Math.PI * 2); ctx.fill();
  }
}
