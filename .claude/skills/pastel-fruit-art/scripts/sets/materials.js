// Materials set — the style on non-food things, plus a colour-freedom row
// proving any hex works (each swatch is auto-toned by tone()).
import * as THREE from 'three';
import { paintShape, ellipsePath, rng, withAlpha, tone } from '../paint.js';
import { mat, mesh, paintVerts, canvasTex, lathe, wheel, blob, lump, gem, leaf } from '../painted3d.js';

function log() {
  const rings = (ctx, cx, cy, R) => {
    paintShape(ctx, ellipsePath(cx, cy, R, R), '#6d4a30', { x: cx - R, y: cy - R, w: 2 * R, h: 2 * R });
    const Ri = R * 0.88;
    paintShape(ctx, ellipsePath(cx, cy, Ri, Ri), '#e8c38c', { x: cx - Ri, y: cy - Ri, w: 2 * Ri, h: 2 * Ri }, { blotches: 20 });
    ctx.strokeStyle = withAlpha(tone('#e8c38c').shade, 0.6); ctx.lineWidth = R * 0.025;
    for (let k = 1; k <= 6; k++) { ctx.beginPath(); ctx.ellipse(cx + k * 1.5, cy - k, Ri * k / 7, Ri * k / 7 * 0.96, 0, 0, 7); ctx.stroke(); }
  };
  const m = wheel('#6d4a30', rings, 1.4, { finish: 'rough' });
  m.rotation.set(0.25, 0.7, 0);
  m.scale.setScalar(0.6);
  return m;
}

function potPlant() {
  const grp = new THREE.Group();
  grp.add(lathe([[0, 0], [0.4, 0], [0.5, 0.6], [0.58, 0.62], [0.6, 0.78], [0, 0.78]], '#d9774c'));
  const soil = mesh(new THREE.CircleGeometry(0.52, 32), mat('#5a3d2c', { finish: 'rough' })); soil.rotation.x = -Math.PI / 2; soil.position.y = 0.72; grp.add(soil);
  for (let i = 0; i < 5; i++) { const l = leaf(0.7, 0.24); l.position.y = 0.72; l.rotation.set(0, (i / 5) * Math.PI * 2, 0.9 + (i % 2) * 0.3); grp.add(l); }
  return grp;
}

function mug(glaze = '#7ab8e6') {
  const grp = new THREE.Group();
  const body = lathe([[0, 0], [0.45, 0], [0.5, 0.1], [0.5, 0.95], [0.44, 0.97], [0.42, 0.9], [0, 0.9]], glaze, { finish: 'smooth' }); grp.add(body);
  const h = mesh(new THREE.TorusGeometry(0.26, 0.07, 12, 24, Math.PI * 1.3), mat(glaze, { finish: 'smooth' }));
  h.position.set(0.5, 0.48, 0); h.rotation.z = -Math.PI * 0.65; grp.add(h);
  const tea = mesh(new THREE.CircleGeometry(0.42, 32), mat('#b36a3a', { finish: 'flat' })); tea.rotation.x = -Math.PI / 2; tea.position.y = 0.84; grp.add(tea);
  return grp;
}

function can() {
  const g = new THREE.CylinderGeometry(0.45, 0.45, 1.1, 40, 1);
  const label = canvasTex((ctx, W, H) => {
    const p = new Path2D(); p.rect(0, 0, W, H);
    paintShape(ctx, p, '#e8584e', { x: 0, y: 0, w: W, h: H }, { flat: true });
    ctx.fillStyle = '#fff3e0'; ctx.fillRect(0, H * 0.38, W, H * 0.24);
    for (let i = 0; i < 4; i++) { const cx = (i + 0.5) * W / 4, r = H * 0.09; paintShape(ctx, ellipsePath(cx, H / 2, r, r), '#f5b53a', { x: cx - r, y: H / 2 - r, w: 2 * r, h: 2 * r }, { blotches: 2 }); }
  }, 512, 256);
  const side = mat(null, { map: label, finish: 'matte', flat: 0 });
  const metal = mat('#b9c2cf', { finish: 'hard' });
  const m = new THREE.Mesh(g, [side, metal, metal]);
  const grp = new THREE.Group(); grp.add(m);
  for (const y of [0.56, -0.56]) { const rim = mesh(new THREE.TorusGeometry(0.45, 0.035, 8, 40), metal); rim.rotation.x = Math.PI / 2; rim.position.y = y; grp.add(rim); }
  grp.rotation.x = 0.2;
  return grp;
}

function kettle() {
  const grp = new THREE.Group();
  grp.add(lathe([[0, 0], [0.55, 0], [0.68, 0.3], [0.62, 0.62], [0.35, 0.82], [0.12, 0.86], [0.1, 0.95], [0, 0.97]], '#9aa6b8', { finish: 'hard' }));
  const hd = mesh(new THREE.TorusGeometry(0.4, 0.05, 10, 30, Math.PI), mat('#3c3f4d', { finish: 'smooth' })); hd.position.y = 0.85; grp.add(hd);
  const sp = mesh(new THREE.CylinderGeometry(0.06, 0.12, 0.55, 12), mat('#9aa6b8', { finish: 'hard' })); sp.position.set(0.72, 0.52, 0); sp.rotation.z = -0.9; grp.add(sp);
  return grp;
}

function ball() {
  const g = new THREE.SphereGeometry(0.6, 48, 32);
  const cols = ['#f25f5c', '#ffe066', '#70c1b3', '#fdfdfd'];
  paintVerts(g, (x, y, z) => cols[Math.floor(((Math.atan2(z, x) + Math.PI) / (Math.PI * 2)) * 8) % 4]);
  return mesh(g, mat(null, { vcol: true, finish: 'smooth' }));
}

function cushion(fabric = '#e6a0b4') {
  const grp = new THREE.Group();
  const c = blob(fabric, 0.85, 0.32, { finish: 'fuzzy', sz: 0.85 }); grp.add(c);
  const b = blob(tone(fabric).shade, 0.09, 0.05); b.position.y = 0.3; grp.add(b);
  grp.rotation.x = 0.5;
  return grp;
}

export function build(place) {
  place(lump('#8e97aa', 0.2, { finish: 'rough', faceted: true, detail: 1, seed: 2 }), -8.3, 2.4, 0.95, 0.4);
  place(lump('#b7a58f', 0.14, { finish: 'rough', seed: 5 }), -6.4, 2.2, 0.75);
  place(log(), -4.3, 2.3, 1.4);
  place(potPlant(), -2.0, 1.6, 1.3);
  place(mug(), 0.2, 1.7, 1.35);
  place(mug('#f2c14e'), 2.2, 1.7, 1.15, 0.6);
  place(can(), 4.3, 2.3, 1.3);
  place(kettle(), 6.6, 1.7, 1.25);
  place(gem('#6fd3c8'), 8.7, 2.6, 0.75, 0.3);
  place(ball(), -7.7, -1.0, 1.3, 0.3);
  place(cushion(), -5.0, -1.0, 1.3);
  place(cushion('#8fb8e8'), -2.5, -1.0, 1.1);
  place(gem('#c79af0'), -0.4, -0.4, 0.8);
  place(gem('#f7b55b'), 1.4, -0.4, 0.7, 0.4);
  place(lump('#6ea85e', 0.12, { seed: 7 }), 3.6, -0.9, 0.85);   // shrub
  place(lump('#f4f6fb', 0.1, { seed: 9 }), 6.4, -0.9, 0.9);     // cloud / snowball
  // colour-freedom row: arbitrary hexes, no palette entries, all auto-toned
  const swatches = ['#ff5d8f', '#ff9f1c', '#ffd23f', '#9bde7e', '#2ec4b6', '#3a86ff', '#8338ec', '#5c5470', '#f1faee', '#1d1d1d'];
  swatches.forEach((c, i) => place(blob(c, 0.45, 0.45, { finish: i % 3 === 0 ? 'smooth' : 'matte' }), -8.1 + i * 1.8, -3.7, 1));
}
