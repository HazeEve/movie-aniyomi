// Fruit set — recreates the reference sheet.
import * as THREE from 'three';
import { P, citrusSlice, kiwiSlice, melonWedge, melonWedgePoints, stripeSkin, speckleSkin } from '../paint.js';
import { PROFILES } from '../profiles.js';
import { mat, mesh, ensureColor, canvasTex, smoothProfile, lathe, latheHalf, pomeCap, domeHalf, wheel,
         slab, sweep, blob, stem, leaf, withStemLeaf } from '../painted3d.js';

function melonSlice() {
  const R = 1, spread = 0.52;
  const pts = melonWedgePoints(0, 0, R, spread).map(([x, y]) => [x, -y]);
  const m = slab(pts, (ctx, S, to) => {
    const [ax, ay] = to([0, 0]), [rx] = to([R, 0]);
    melonWedge(ctx, ax, ay, rx - ax, spread);
  }, (x, y) => (Math.hypot(x, y) > R * 0.93 ? P.melonRind.base : P.melonFlesh.base));
  m.rotation.x = -0.25;
  return m;
}

function strawberry() {
  const grp = new THREE.Group();
  grp.add(lathe(PROFILES.strawberry, P.strawberry, { finish: 'smooth' }));
  const sp = smoothProfile(PROFILES.strawberry, 60);
  const seedG = ensureColor(new THREE.SphereGeometry(0.028, 8, 6)), seedM = mat(P.paleSeed, { noise: 0 });
  for (let row = 1; row < 7; row++) {
    const p = sp[Math.floor((0.1 + row * 0.12) * sp.length)], count = Math.max(4, Math.round(p.x * 22));
    for (let i = 0; i < count; i++) {
      const a = (i + (row % 2) * 0.5) / count * Math.PI * 2, s = new THREE.Mesh(seedG, seedM);
      s.position.set(Math.sin(a) * p.x * 1.01, p.y, Math.cos(a) * p.x * 1.01);
      s.scale.set(0.8, 1.3, 0.5); s.lookAt(s.position.x * 3, p.y, s.position.z * 3);
      grp.add(s);
    }
  }
  for (let i = 0; i < 6; i++) { const lf = leaf(0.3, 0.1); lf.position.set(0, 1.02, 0); lf.rotation.set(0, (i / 6) * Math.PI * 2, -0.35); grp.add(lf); }
  const st = stem(0.18, 0.03, 0.03, P.leaf); st.position.y = 1.02; grp.add(st);
  return grp;
}

function cherries() {
  const grp = new THREE.Group(), top = new THREE.Vector3(0.05, 1.5, 0);
  for (const [x, z] of [[-0.42, 0.1], [0.45, -0.05]]) {
    const b = blob(P.cherry, 0.4, 0.37, { finish: 'smooth' }); b.position.set(x, 0, z); grp.add(b);
    const curve = new THREE.QuadraticBezierCurve3(new THREE.Vector3(x, 0.32, z), new THREE.Vector3(x * 0.6, 1.0, z), top);
    grp.add(mesh(new THREE.TubeGeometry(curve, 16, 0.03, 8, false), mat(P.leaf)));
  }
  const lf = leaf(0.5, 0.18); lf.position.copy(top); lf.rotation.set(0.2, 0, 0.5); grp.add(lf);
  return grp;
}

function blueberries() {
  const grp = new THREE.Group();
  for (const [x, y, z, s] of [[-0.35, 0, 0.1, 0.34], [0.35, -0.02, 0.05, 0.32], [0, 0.3, -0.15, 0.31]]) {
    const b = blob(P.blueberry, s, s * 0.9); b.position.set(x, y, z); grp.add(b);
    const crown = mesh(new THREE.TorusGeometry(s * 0.22, s * 0.07, 8, 16), mat(P.blueberry.shade));
    crown.position.set(x - s * 0.1, y + s * 0.83, z + s * 0.35); crown.rotation.x = -Math.PI / 2 + 0.6; grp.add(crown);
  }
  return grp;
}

function grapes() {
  const grp = new THREE.Group(), g = ensureColor(new THREE.SphereGeometry(0.2, 24, 16));
  [4, 4, 3, 2, 1].forEach((n, r) => {
    for (let i = 0; i < n; i++) for (const z of [0, -0.18]) {
      const m = new THREE.Mesh(g, mat(P.grape, { finish: 'smooth' }));
      m.position.set((i - (n - 1) / 2) * 0.36 + (z ? 0.18 : 0), -r * 0.3, z); grp.add(m);
    }
  });
  const st = stem(0.3, 0.035); st.position.set(0, 0.12, -0.08); grp.add(st);
  const lf = leaf(0.5, 0.2); lf.position.set(0.05, 0.38, -0.08); lf.rotation.set(0.2, -0.2, 0.3); grp.add(lf);
  return grp;
}

const banana = () => sweep(
  [[-1.1, 0.55, 0], [-0.6, -0.05, 0.05], [0.1, -0.3, 0.1], [0.8, -0.05, 0.05], [1.2, 0.45, 0]],
  t => 0.26 * Math.pow(Math.sin(Math.PI * Math.min(1, 0.06 + t * 0.94)), 0.55) + 0.03,
  t => (t < 0.05 || t > 0.97 ? P.stem.base : P.banana.base),
  { lobes: 5 });

export function build(place) {
  const melonTex = canvasTex((ctx, w, h) => stripeSkin(ctx, w, h), 512, 256);
  const kiwiTex = canvasTex((ctx, w, h) => speckleSkin(ctx, w, h, P.kiwiSkin, 3, 900), 256);
  const citrus = (skin, flesh, o) => (c, x, y, r) => citrusSlice(c, x, y, r, skin, flesh, o);
  // row 1
  place(withStemLeaf(lathe(PROFILES.apple, P.apple, { finish: 'smooth' }), 0.84), -9.0, 2.3, 1.3, 0.3);
  place(latheHalf(PROFILES.apple, P.apple, pomeCap(P.apple, P.appleFlesh, 'seeds')), -7.1, 2.3, 1.3);
  place(withStemLeaf(lathe(PROFILES.pear, P.pear), 1.15), -5.3, 2.2, 1.2, 0.2);
  place(latheHalf(PROFILES.pear, P.pear, pomeCap(P.pear, P.pearFlesh, 'seeds')), -3.7, 2.2, 1.2);
  place(latheHalf(PROFILES.peach, P.peach, pomeCap(P.peach, P.peachFlesh, 'pit'), { finish: 'fuzzy' }), -1.8, 2.3, 1.3);
  place(blob(null, 1.05, 0.9, { map: melonTex, finish: 'matte' }), 0.6, 2.9, 1.0, 0.4);
  place(melonSlice(), 2.7, 2.6, 1.45);
  place(strawberry(), 4.6, 2.3, 1.25, 0.3);
  place(latheHalf(PROFILES.strawberry, P.strawberry, pomeCap(P.strawberry, P.berryFlesh, 'berry')), 6.3, 2.3, 1.25);
  place(banana(), 8.3, 2.8, 0.75, -0.2);
  // row 2
  place(withStemLeaf(blob(P.orange, 0.8, 0.74), 0.72), -8.8, -0.4, 1.0);
  place(domeHalf(P.orange, citrus(P.orange, P.orangeFlesh)), -6.8, -0.5, 0.78);
  place(wheel(P.orange, citrus(P.orange, P.orangeFlesh)), -5.0, -0.5, 0.75);
  { const l = lathe(PROFILES.lemon, P.lemon); l.rotation.z = Math.PI / 2; l.position.x = 0.6; place(l, -2.8, -0.6, 1.25, 0.2); }
  place(wheel(P.lemon, citrus(P.lemon, P.lemonFlesh, { segments: 9, seedCount: 3 })), -0.8, -0.5, 0.68);
  place(cherries(), 1.5, -1.0, 0.9);
  place(blueberries(), 3.6, -0.7, 1.1);
  place(grapes(), 6.0, -0.1, 1.2);
  // row 3
  place(blob(null, 0.85, 0.72, { map: kiwiTex, finish: 'fuzzy' }), -8.7, -3.3, 1.0, 0.5);
  place(domeHalf(P.kiwiSkin, (c, x, y, r) => kiwiSlice(c, x, y, r), 0.85, { finish: 'fuzzy' }), -6.7, -3.3, 0.85);
  place(wheel(P.kiwiSkin, (c, x, y, r) => kiwiSlice(c, x, y, r), 0.14), -4.8, -3.3, 0.78);
  place(withStemLeaf(lathe(PROFILES.peach, P.peach, { finish: 'fuzzy' }), 0.97, { len: 0.12 }), -2.8, -3.9, 1.2, 0.3);
  place(withStemLeaf(blob(P.lemon, 0.62, 0.58), 0.56), -0.8, -3.3, 1.0);
}
