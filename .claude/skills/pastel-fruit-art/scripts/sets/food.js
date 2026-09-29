// Food set — same painted language applied to bakery, sweets and meals.
// Colours here are free choices (any hex); tone() derives shade/light.
import * as THREE from 'three';
import { paintShape, smoothPath, ellipsePath, boxOf, rng, withAlpha, tone } from '../paint.js';
import { mat, mesh, paintVerts, canvasTex, lathe, slab, sweep, blob, lump, leaf } from '../painted3d.js';

const rect = (x, y, w, h) => { const p = new Path2D(); p.rect(x, y, w, h); return p; };
const polyPath = pts => { const p = new Path2D(); pts.forEach(([x, y], i) => (i ? p.lineTo(x, y) : p.moveTo(x, y))); p.closePath(); return p; };

function donut(icing = '#f59ac0', dough = '#e7a45c') {
  const grp = new THREE.Group();
  const R = 0.62, r = 0.32, g = new THREE.TorusGeometry(R, r, 28, 56);
  paintVerts(g, (x, y, z) => (z > 0.02 + 0.06 * Math.sin(7 * Math.atan2(y, x)) ? icing : dough));
  grp.add(mesh(g, mat(null, { vcol: true, finish: 'smooth' })));
  const cols = ['#ffffff', '#7fd3f2', '#ffe27a', '#a7e08a', '#c9a0f0'], rnd = rng(9);
  const sg = new THREE.CapsuleGeometry(0.018, 0.07, 3, 6);
  for (let i = 0; i < 46; i++) {
    const a = rnd() * Math.PI * 2, b = 0.35 + rnd() * 1.2;
    const s = mesh(sg.clone(), mat(cols[i % cols.length], { finish: 'smooth' }));
    s.position.set((R + r * Math.cos(b)) * Math.cos(a), (R + r * Math.cos(b)) * Math.sin(a), r * Math.sin(b) + 0.01);
    s.rotation.set(rnd() * 3, rnd() * 3, rnd() * 3);
    grp.add(s);
  }
  grp.rotation.x = -Math.PI / 2 + 0.6;
  return grp;
}

function cheese(body = '#f7c84a') {
  const pts = [[0, 0], [1.5, 0], [1.5, 0.12], [0, 0.85]];
  const m = slab(pts, (ctx, S, to) => {
    const out = pts.map(to);
    paintShape(ctx, polyPath(out), body, boxOf(out));
    const rnd = rng(4);
    for (let i = 0; i < 6; i++) {
      const x = 0.15 + rnd() * 1.1, y = 0.08 + rnd() * (0.6 - x * 0.35), rr = (0.05 + rnd() * 0.06) * S / 1.6;
      const [cx, cy] = to([x, y]);
      paintShape(ctx, ellipsePath(cx, cy, rr, rr * 0.85), tone(body).shade, { x: cx - rr, y: cy - rr, w: 2 * rr, h: 2 * rr }, { blotches: 2, light: [0.4, 0.5] });
    }
  }, () => '#f2b53c', { depth: 0.9, bevel: 0.05 });
  m.rotation.set(-0.2, -0.5, 0);
  m.position.set(-0.75, -0.3, 0);
  return m;
}

function pizza() {
  const R = 1.25, pts = [[0, 0]];                                                   // apex down, crust on top
  for (let i = 0; i <= 20; i++) { const a = Math.PI / 2 + 0.42 - (i / 20) * 0.84; pts.push([Math.cos(a) * R, Math.sin(a) * R]); }
  const m = slab(pts, (ctx, S, to) => {
    const full = pts.map(to);
    paintShape(ctx, polyPath(full), '#e9a656', boxOf(full));                       // crust
    const inner = pts.map(([x, y]) => [x * 0.84, y * 0.84 + 0.04]).map(to);
    paintShape(ctx, polyPath(inner), '#f6d77a', boxOf(inner), { blotches: 30 });   // cheese
    const rnd = rng(12);
    for (const t of [0.35, 0.55, 0.72, 0.62]) {
      const a = Math.PI / 2 + (rnd() - 0.5) * 0.45 * t;
      const [cx, cy] = to([Math.cos(a) * R * t, Math.sin(a) * R * t]), rr = S * 0.05;
      paintShape(ctx, ellipsePath(cx, cy, rr, rr), '#d9463f', { x: cx - rr, y: cy - rr, w: 2 * rr, h: 2 * rr }, { blotches: 4 });
    }
  }, (x, y) => (Math.hypot(x, y) > R * 0.88 ? '#d98a3e' : '#f3c864'), { depth: 0.12, bevel: 0.05 });
  m.rotation.x = -0.35;
  m.position.y = -0.6;
  return m;
}

function toast() {
  const pts = [[-0.7, -0.75], [0.7, -0.75], [0.72, 0.35], [0.9, 0.55], [0.7, 0.85], [0.3, 0.92], [0, 0.85], [-0.3, 0.92], [-0.7, 0.85], [-0.9, 0.55], [-0.72, 0.35]];
  const m = slab(pts, (ctx, S, to) => {
    const out = pts.map(to);
    paintShape(ctx, smoothPath(out), '#c98a45', boxOf(out));
    const inner = pts.map(([x, y]) => [x * 0.85, y * 0.85 + 0.02]).map(to);
    paintShape(ctx, smoothPath(inner), '#f4dba6', boxOf(inner), { blotches: 40 });
    const rnd = rng(3); ctx.fillStyle = withAlpha('#d9b477', 0.5);                    // crumb pores
    for (let i = 0; i < 70; i++) { const [x, y] = to([(rnd() - 0.5) * 1.2, (rnd() - 0.4) * 1.3]); ctx.beginPath(); ctx.ellipse(x, y, 3 + rnd() * 4, 2 + rnd() * 3, rnd() * 3, 0, 7); ctx.fill(); }
  }, () => '#c98a45', { depth: 0.22 });
  m.rotation.set(-0.15, 0.3, 0.05);
  return m;
}

function friedEgg() {
  const grp = new THREE.Group(), pts = [];
  for (let i = 0; i < 14; i++) { const a = (i / 14) * Math.PI * 2, r = 0.95 + 0.14 * Math.sin(i * 2.3) + 0.08 * Math.cos(i * 5.1); pts.push([Math.cos(a) * r, Math.sin(a) * r * 0.8]); }
  const white = slab(pts, (ctx, S, to) => { const out = pts.map(to); paintShape(ctx, smoothPath(out), '#fbf6ea', boxOf(out), { blotches: 20 }); }, () => '#f3ead6', { depth: 0.06, bevel: 0.08 });
  white.rotation.x = -Math.PI / 2 + 0.55; grp.add(white);
  const yolk = blob('#f7b52a', 0.4, 0.26, { finish: 'smooth' }); yolk.position.set(0.1, 0.12, 0.05); grp.add(yolk);
  return grp;
}

function cupcake(frost = '#b9a4ec', liner = '#f6a3b4') {
  const grp = new THREE.Group();
  const wrap = lathe([[0, 0], [0.42, 0], [0.5, 0.3], [0.58, 0.62], [0, 0.62]], null, {});
  const g = wrap.geometry;
  paintVerts(g, (x, y, z) => (Math.floor(((Math.atan2(z, x) + Math.PI) / (Math.PI * 2)) * 18) % 2 ? liner : tone(liner).shade));
  wrap.material = mat(null, { vcol: true });
  grp.add(wrap);
  [[0.6, 0.72, 0.2], [0.46, 0.95, 0.17], [0.3, 1.15, 0.14], [0.12, 1.3, 0.11]].forEach(([R, y, r]) => {
    const t = mesh(new THREE.TorusGeometry(R, r, 16, 40), mat(frost, { finish: 'smooth' }));
    t.rotation.x = Math.PI / 2; t.position.y = y; grp.add(t);
  });
  const ch = blob('#d93c3a', 0.15, 0.14, { finish: 'smooth' }); ch.position.y = 1.45; grp.add(ch);
  return grp;
}

function croissant() {
  return sweep(
    [[-0.95, -0.35, 0], [-0.6, 0.2, 0.05], [0, 0.42, 0.1], [0.6, 0.2, 0.05], [0.95, -0.35, 0]],
    t => 0.1 + 0.34 * Math.pow(Math.sin(Math.PI * t), 0.8) * (1 + 0.16 * Math.cos(t * Math.PI * 10)),
    t => (Math.cos(t * Math.PI * 10) < -0.6 ? '#f3c77e' : Math.abs(t - 0.5) > 0.42 ? '#b86a2c' : '#e39a45'),
    { sides: 24, segs: 90 });
}

function nigiri(fish = '#f59a6b') {
  const grp = new THREE.Group();
  const rice = lump('#f7f4ec', 0.06, { finish: 'rough', detail: 4 }); rice.scale.set(0.75, 0.32, 0.42); grp.add(rice);
  const pts = [[-0.8, -0.35], [0.8, -0.35], [0.8, 0.35], [-0.8, 0.35]];
  const top = slab(pts, (ctx, S, to) => {
    const out = pts.map(to); paintShape(ctx, smoothPath(out), fish, boxOf(out));
    ctx.save(); ctx.clip(smoothPath(out)); ctx.strokeStyle = withAlpha('#ffffff', 0.55); ctx.lineWidth = S * 0.018;
    for (let i = -4; i <= 4; i++) { const [x0, y0] = to([i * 0.2 - 0.3, -0.5]), [x1, y1] = to([i * 0.2 + 0.1, 0.5]); ctx.beginPath(); ctx.moveTo(x0, y0); ctx.quadraticCurveTo((x0 + x1) / 2 + 8, (y0 + y1) / 2, x1, y1); ctx.stroke(); }
    ctx.restore();
  }, () => tone(fish).base, { depth: 0.07, bevel: 0.06 });
  const p = top.geometry.attributes.position;                                       // drape over the rice
  for (let i = 0; i < p.count; i++) p.setZ(i, p.getZ(i) - p.getX(i) ** 2 * 0.3);
  top.geometry.computeVertexNormals();
  top.rotation.x = -Math.PI / 2; top.position.y = 0.42; grp.add(top);
  grp.rotation.x = 0.6;
  return grp;
}

function iceCream(scoop = '#8fd6c0') {
  const grp = new THREE.Group();
  const coneG = new THREE.ConeGeometry(0.45, 1.3, 32, 1, true); coneG.rotateX(Math.PI);
  const waffle = canvasTex((ctx, W, H) => {
    paintShape(ctx, rect(0, 0, W, H), '#e3a55a', { x: 0, y: 0, w: W, h: H }, { flat: true, blotches: 30 });
    ctx.strokeStyle = tone('#e3a55a').shade; ctx.lineWidth = 7;
    for (let i = -8; i < 16; i++) { ctx.beginPath(); ctx.moveTo(i * W / 8, 0); ctx.lineTo(i * W / 8 + H, H); ctx.stroke(); ctx.beginPath(); ctx.moveTo(i * W / 8, H); ctx.lineTo(i * W / 8 + H, 0); ctx.stroke(); }
  });
  waffle.wrapS = waffle.wrapT = THREE.RepeatWrapping;
  const cone = mesh(coneG, mat(null, { map: waffle, finish: 'matte', flat: 0 })); cone.position.y = -0.5; grp.add(cone);
  const s = lump(scoop, 0.08, { seed: 3 }); s.scale.set(0.55, 0.5, 0.55); s.position.y = 0.38; grp.add(s);
  const drip = mesh(new THREE.TorusGeometry(0.47, 0.1, 12, 40), mat(scoop)); drip.rotation.x = Math.PI / 2; drip.position.y = 0.17; grp.add(drip);
  const ch = blob('#d93c3a', 0.13, 0.12, { finish: 'smooth' }); ch.position.y = 0.92; grp.add(ch);
  return grp;
}

function macaron(shell) {
  const grp = new THREE.Group();
  for (const y of [0.17, -0.17]) { const s = blob(shell, 0.5, 0.17); s.position.y = y; grp.add(s); }
  const fill = mesh(new THREE.CylinderGeometry(0.43, 0.43, 0.16, 32), mat('#fff3e3')); grp.add(fill);
  grp.rotation.x = 0.35;
  return grp;
}

function mushroom(cap = '#e0533d') {
  const grp = new THREE.Group();
  grp.add(lathe([[0, 0], [0.22, 0], [0.18, 0.4], [0.2, 0.7], [0, 0.7]], '#f5ecd6'));
  const c = lathe([[0, 0.6], [0.5, 0.58], [0.72, 0.68], [0.62, 0.95], [0.3, 1.15], [0, 1.18]], cap, { finish: 'smooth' }); grp.add(c);
  for (const [a, h, s] of [[0.2, 0.95, 0.09], [1.3, 0.8, 0.07], [-0.9, 0.85, 0.08], [0.6, 1.1, 0.06], [2.4, 0.9, 0.08]]) {
    const d = blob('#fff8ee', s, s * 0.5); const r = h > 1 ? 0.3 : 0.58;
    d.position.set(Math.sin(a) * r, h, Math.cos(a) * r); d.lookAt(d.position.x * 3, h + 0.6, d.position.z * 3); d.rotateX(Math.PI / 2); grp.add(d);
  }
  return grp;
}

export function build(place) {
  place(donut(), -8.4, 2.4, 1.4);
  place(donut('#6b4a3a', '#e7a45c'), -5.8, 2.4, 1.2, 0.3);
  place(cheese(), -3.2, 2.3, 1.3);
  place(pizza(), -0.7, 2.5, 1.7);
  place(toast(), 1.9, 2.3, 1.3);
  place(croissant(), 4.6, 2.3, 1.2);
  place(friedEgg(), 7.6, 2.1, 1.3);
  place(cupcake(), -8.5, -1.4, 1.35);
  place(cupcake('#fff1d6', '#8fcfe8'), -6.3, -1.3, 1.15);
  place(iceCream(), -3.9, -0.6, 1.3);
  place(iceCream('#f6a6c1'), -1.9, -0.6, 1.2);
  place(nigiri(), 0.6, -0.8, 1.35);
  place(nigiri('#e8584e'), 3.1, -0.8, 1.2);
  place(mushroom(), 5.6, -1.5, 1.3);
  place(mushroom('#c98a52'), 7.9, -1.4, 1.1);
  ['#a8d8b9', '#f4b6c2', '#c7b3e6', '#ffd97a', '#8ec5f0', '#f5a86b'].forEach((c, i) => place(macaron(c), -7.6 + i * 1.6, -3.8, 1.2));
}
