// painted3d.js — the 3D half of the style, subject-agnostic.
// A painted unlit shader + "finishes" + generic shape builders.
// Colours: pass ANY hex string (auto-toned via tone()) or a {base,shade,light} triad.
import * as THREE from 'three';
import { triad, profileOutline, pomeCut } from './paint.js';

THREE.ColorManagement.enabled = false;           // raw sRGB in = raw sRGB out
export const LIGHT_DIR = new THREE.Vector3(-0.55, 0.85, 0.75).normalize();

// Finishes: how a surface reacts, independent of its colour. The style is
// fully MATTE — no specular highlights anywhere, even on "shiny" things.
// Smooth/hard materials read through low brush noise and a crisper ramp instead.
//   noise = brush-blotch strength   edge = ramp start/end (narrower = harder terminator)
export const FINISH = {
  matte:  { noise: 0.16, edge: [0.18, 0.62] },   // most fruit, clay, paper, wood
  fuzzy:  { noise: 0.32, edge: [0.10, 0.70] },   // peach, kiwi, fabric, felt
  rough:  { noise: 0.45, edge: [0.20, 0.60] },   // stone, bread crumb, bark
  smooth: { noise: 0.07, edge: [0.20, 0.60] },   // icing, candy, glaze, plastic, apple skin
  hard:   { noise: 0.05, edge: [0.36, 0.54] },   // metal, glass, gems
  flat:   { noise: 0.05, edge: [0.18, 0.62], flat: 0.75 }, // cut faces / painted decals
};

const vert = /* glsl */`
  varying vec3 vN; varying vec3 vP; varying vec2 vUv; varying vec3 vV; varying vec3 vCol;
  attribute vec3 color;
  void main() {
    vUv = uv; vP = position; vCol = color;
    vN = normalize(mat3(modelMatrix) * normal);
    vec4 wp = modelMatrix * vec4(position, 1.0);
    vV = normalize(cameraPosition - wp.xyz);
    gl_Position = projectionMatrix * viewMatrix * wp;
  }`;
const frag = /* glsl */`
  uniform vec3 uBase, uShade, uLight, uLightDir;
  uniform sampler2D uMap; uniform float uUseMap, uUseVCol, uNoise, uSeed, uFlat;
  uniform vec2 uEdge;
  varying vec3 vN; varying vec3 vP; varying vec2 vUv; varying vec3 vV; varying vec3 vCol;
  float h(vec3 p){ p = fract(p*0.3183099 + 0.1); p *= 17.0; return fract(p.x*p.y*p.z*(p.x+p.y+p.z)); }
  float n3(vec3 x){ vec3 i=floor(x), f=fract(x); f=f*f*(3.0-2.0*f);
    return mix(mix(mix(h(i),h(i+vec3(1,0,0)),f.x),mix(h(i+vec3(0,1,0)),h(i+vec3(1,1,0)),f.x),f.y),
               mix(mix(h(i+vec3(0,0,1)),h(i+vec3(1,0,1)),f.x),mix(h(i+vec3(0,1,1)),h(i+vec3(1,1,1)),f.x),f.y),f.z); }
  void main() {
    vec3 base = uBase, shade = uShade, light = uLight;
    if (uUseMap > 0.5) { vec3 t = texture2D(uMap, vUv).rgb; base = t; shade = t*vec3(0.84,0.8,0.86); light = mix(t, vec3(1.0), 0.1); }
    if (uUseVCol > 0.5) { base = vCol; shade = vCol*vec3(0.78,0.74,0.82); light = mix(vCol, vec3(1.0), 0.18); }
    vec3 n = normalize(vN); if (!gl_FrontFacing) n = -n;
    vec3 v = normalize(vV);
    float ndl = dot(n, uLightDir) * 0.5 + 0.5;
    float brush = n3(vP*5.0 + uSeed)*0.65 + n3(vP*13.0 + uSeed)*0.35;
    ndl += (brush - 0.5) * uNoise;
    ndl = mix(ndl, 0.62, uFlat);
    vec3 c = mix(shade, base, smoothstep(uEdge.x, uEdge.y, ndl));
    c = mix(c, light, smoothstep(0.7, 0.98, ndl) * 0.75);
    float fres = pow(1.0 - max(dot(n, v), 0.0), 3.0);
    c = mix(c, shade, fres * 0.3 * (1.0 - uFlat));        // soft darker silhouette, no outline
    gl_FragColor = vec4(c, 1.0);
  }`;

// mat('#hex' | triad | null, { finish, map, vcol, side, noise, flat })
export function mat(color, o = {}) {
  const f = { ...FINISH[o.finish ?? (o.map ? 'flat' : 'matte')] };
  const c = color ? triad(color) : { base: '#ffffff', shade: '#cccccc', light: '#ffffff' };
  return new THREE.ShaderMaterial({
    vertexShader: vert, fragmentShader: frag, side: o.side ?? THREE.FrontSide,
    uniforms: {
      uBase: { value: new THREE.Color(c.base) }, uShade: { value: new THREE.Color(c.shade) },
      uLight: { value: new THREE.Color(c.light) }, uLightDir: { value: LIGHT_DIR },
      uMap: { value: o.map ?? null }, uUseMap: { value: o.map ? 1 : 0 },
      uUseVCol: { value: o.vcol ? 1 : 0 },
      uNoise: { value: o.noise ?? f.noise },
      uEdge: { value: new THREE.Vector2(...f.edge) }, uFlat: { value: o.flat ?? f.flat ?? 0 },
      uSeed: { value: Math.random() * 50 },
    },
  });
}

export function ensureColor(g, hex = '#ffffff') {
  if (!g.attributes.color) {
    const c = new THREE.Color(hex), n = g.attributes.position.count, a = new Float32Array(n * 3);
    for (let i = 0; i < n; i++) a.set([c.r, c.g, c.b], i * 3);
    g.setAttribute('color', new THREE.BufferAttribute(a, 3));
  }
  if (!g.attributes.uv) g.setAttribute('uv', new THREE.BufferAttribute(new Float32Array(g.attributes.position.count * 2), 2));
  return g;
}
export const mesh = (g, m) => new THREE.Mesh(ensureColor(g), m);

// Per-vertex colouring: fn(x, y, z, i) -> hex. Use with mat(null, {vcol:true}).
export function paintVerts(g, fn) {
  const p = g.attributes.position, a = new Float32Array(p.count * 3), c = new THREE.Color();
  for (let i = 0; i < p.count; i++) { c.set(fn(p.getX(i), p.getY(i), p.getZ(i), i)); a.set([c.r, c.g, c.b], i * 3); }
  g.setAttribute('color', new THREE.BufferAttribute(a, 3));
  return g;
}

// Textures are drawn with paint.js — the 2D step feeds the 3D step.
export function canvasTex(draw, w = 512, h = w) {
  const cv = document.createElement('canvas'); cv.width = w; cv.height = h;
  draw(cv.getContext('2d'), w, h);
  const t = new THREE.CanvasTexture(cv); t.anisotropy = 4;
  return t;
}

// ---------------- generic shape builders ----------------
export const smoothProfile = (pts, n = 48) =>
  new THREE.SplineCurve(pts.map(([r, y]) => new THREE.Vector2(r, y))).getPoints(n)
    .map(v => new THREE.Vector2(Math.max(0, v.x), v.y));

// Anything round-ish: fruit, pots, cupcakes, bottles, mushrooms caps, vases.
export function lathe(profile, color, o = {}) {
  return mesh(new THREE.LatheGeometry(smoothProfile(profile), 48), mat(color, o));
}

// Lengthwise half of a lathe with a painted cut face.
// drawCap(ctx, outlinePts) paints the cross-section; default = pome cut.
export function latheHalf(profile, skin, drawCap, o = {}) {
  const sp = smoothProfile(profile);
  const grp = new THREE.Group();
  grp.add(mesh(new THREE.LatheGeometry(sp, 48, 0, Math.PI), mat(skin, o)));
  const ys = sp.map(v => v.y), ymin = Math.min(...ys), ymax = Math.max(...ys);
  const R = Math.max(...sp.map(v => v.x));
  const cap = new THREE.ShapeGeometry(new THREE.Shape([...sp.map(v => new THREE.Vector2(v.x, v.y)),
    ...sp.slice().reverse().map(v => new THREE.Vector2(-v.x, v.y))]), 24);
  const uv = cap.attributes.uv, pos = cap.attributes.position;
  const span = Math.max(2 * R, ymax - ymin) * 1.02, pad = (span - (ymax - ymin)) / 2;
  for (let i = 0; i < uv.count; i++) uv.setXY(i, (pos.getX(i) + span / 2) / span, (pos.getY(i) - ymin + pad) / span);
  const tex = canvasTex((ctx, S) => {
    const scale = S / span, baseY = S - (pad - ymin) * scale;
    drawCap(ctx, profileOutline(sp.filter((_, i) => i % 2 === 0).map(v => [v.x, v.y]), S / 2, baseY, scale));
  });
  cap.rotateY(-Math.PI / 2);
  grp.add(mesh(cap, mat(null, { map: tex })));
  grp.rotation.y = Math.PI / 2;
  return grp;
}
export const pomeCap = (skin, flesh, core) => (ctx, out) => pomeCut(ctx, out, triad(skin), triad(flesh), { core });

// Cross-cut dome (citrus half, kiwi half, cake dome, egg half).
export function domeHalf(skin, drawCap, sy = 1, o = {}) {
  const grp = new THREE.Group();
  grp.add(mesh(new THREE.SphereGeometry(1, 48, 24, 0, Math.PI * 2, 0, Math.PI / 2), mat(skin, { side: THREE.DoubleSide, ...o })));
  const cap = new THREE.CircleGeometry(1, 64);
  cap.rotateX(Math.PI / 2);
  grp.add(mesh(cap, mat(null, { map: canvasTex((ctx, w) => drawCap(ctx, w / 2, w / 2, w / 2 - 1)) })));
  grp.scale.set(1, sy, 1);
  grp.rotation.x = -Math.PI / 2 - 0.35;
  return grp;
}

// Disc with painted faces (fruit wheels, cookies, coins, log ends, plates).
export function wheel(side, drawCap, thick = 0.16, o = {}) {
  const g = new THREE.CylinderGeometry(1, 1, thick, 64, 1);
  const face = mat(null, { map: canvasTex((ctx, w) => drawCap(ctx, w / 2, w / 2, w / 2 - 1)), flat: 0.6 });
  const m = new THREE.Mesh(ensureColor(g), [mat(side, o), face, face]);
  m.rotation.x = Math.PI / 2 - 0.25;
  return m;
}

// Extruded flat shape with a painted face and vertex-coloured sides.
// pts: [[x,y],...] in shape space. drawFace(ctx, S, toCanvas) paints the face;
// sideColor(x, y) -> hex colours the walls (e.g. rind vs flesh, crust vs crumb).
export function slab(pts, drawFace, sideColor, o = {}) {
  const { depth = 0.24, bevel = 0.04 } = o;
  const g = new THREE.ExtrudeGeometry(new THREE.Shape(pts.map(([x, y]) => new THREE.Vector2(x, y))),
    { depth, bevelEnabled: true, bevelThickness: bevel, bevelSize: bevel * 0.85, bevelSegments: 3, curveSegments: 24 });
  g.translate(0, 0, -depth / 2);
  const xs = pts.map(p => p[0]), ys = pts.map(p => p[1]);
  const x0 = Math.min(...xs) - bevel, y0 = Math.min(...ys) - bevel;
  const span = Math.max(Math.max(...xs) - x0, Math.max(...ys) - y0) + bevel;
  const uv = g.attributes.uv, pos = g.attributes.position;
  for (let i = 0; i < pos.count; i++) uv.setXY(i, (pos.getX(i) - x0) / span, (pos.getY(i) - y0) / span);
  paintVerts(g, (x, y) => sideColor(x, y));
  const toCanvas = S => ([x, y]) => [(x - x0) / span * S, S - (y - y0) / span * S];
  const tex = canvasTex((ctx, S) => drawFace(ctx, S, toCanvas(S)));
  return new THREE.Mesh(g, [mat(null, { map: tex }), mat(null, { vcol: true, finish: o.finish })]);
}

// Sweep a (optionally lobed) circle along a curve: bananas, sausages, handles, churros.
// radius(t) -> r ; color(t, angle) -> hex
export function sweep(points, radius, color, o = {}) {
  const { segs = 60, sides = 20, lobes = 0, lobeAmt = 0.07 } = o;
  const curve = new THREE.CatmullRomCurve3(points.map(p => new THREE.Vector3(...p)));
  const frames = curve.computeFrenetFrames(segs, false);
  const pos = [], col = [], idx = [], c = new THREE.Color();
  for (let i = 0; i <= segs; i++) {
    const t = i / segs, P = curve.getPointAt(t), r = radius(t), N = frames.normals[i], B = frames.binormals[i];
    for (let j = 0; j < sides; j++) {
      const a = (j / sides) * Math.PI * 2, rr = r * (1 + (lobes ? lobeAmt * Math.cos(lobes * a) : 0));
      pos.push(P.x + (N.x * Math.cos(a) + B.x * Math.sin(a)) * rr, P.y + (N.y * Math.cos(a) + B.y * Math.sin(a)) * rr, P.z + (N.z * Math.cos(a) + B.z * Math.sin(a)) * rr);
      c.set(color(t, a)); col.push(c.r, c.g, c.b);
    }
  }
  for (let i = 0; i < segs; i++) for (let j = 0; j < sides; j++) {
    const a = i * sides + j, b = i * sides + (j + 1) % sides;
    idx.push(a, a + sides, b, b, a + sides, b + sides);
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute('color', new THREE.Float32BufferAttribute(col, 3));
  g.setIndex(idx); g.computeVertexNormals();
  return mesh(g, mat(null, { vcol: true, side: THREE.DoubleSide, finish: o.finish }));
}

export function blob(color, sx = 1, sy = 1, o = {}) {
  const m = mesh(new THREE.SphereGeometry(1, 48, 32), mat(color, o));
  m.scale.set(sx, sy, o.sz ?? sx);
  return m;
}

// Lumpy organic form (rocks, potatoes, bread rolls, clouds): displaced icosphere.
export function lump(color, amt = 0.18, o = {}) {
  const g = new THREE.IcosahedronGeometry(1, o.detail ?? 3);
  const p = g.attributes.position, s = o.seed ?? 1;
  for (let i = 0; i < p.count; i++) {
    const v = new THREE.Vector3(p.getX(i), p.getY(i), p.getZ(i));
    const d = 1 + amt * (Math.sin(v.x * 2.1 + s) * Math.sin(v.y * 1.7 + s * 2) + 0.5 * Math.sin(v.z * 3.3 + s * 3));
    v.multiplyScalar(d); p.setXYZ(i, v.x, v.y, v.z);
  }
  g.computeVertexNormals();
  if (o.faceted) { const f = g.toNonIndexed(); f.computeVertexNormals(); return mesh(f, mat(color, o)); }
  return mesh(g, mat(color, o));
}

// Faceted gem / crystal.
export function gem(color, o = {}) {
  const g = new THREE.CylinderGeometry(0.7, 1, 0.45, 8, 1).toNonIndexed();
  const tip = new THREE.ConeGeometry(1, 1.1, 8, 1).toNonIndexed();
  tip.rotateX(Math.PI); tip.translate(0, -0.78, 0);
  const grp = new THREE.Group();
  for (const geo of [g, tip]) { geo.computeVertexNormals(); grp.add(mesh(geo, mat(color, { finish: 'hard', ...o }))); }
  return grp;
}

export function stem(len = 0.28, r = 0.035, bend = 0.08, color = '#7a5a3a') {
  const curve = new THREE.QuadraticBezierCurve3(new THREE.Vector3(0, 0, 0), new THREE.Vector3(bend, len * 0.6, 0), new THREE.Vector3(bend * 1.6, len, 0));
  return mesh(new THREE.TubeGeometry(curve, 12, r, 8, false), mat(color));
}
export function leaf(len = 0.45, w = 0.18, color = '#55a444') {
  const s = new THREE.Shape();
  s.moveTo(0, 0);
  s.bezierCurveTo(len * 0.25, w, len * 0.75, w * 0.9, len, 0);
  s.bezierCurveTo(len * 0.7, -w * 0.7, len * 0.25, -w * 0.8, 0, 0);
  const g = new THREE.ShapeGeometry(s, 16), p = g.attributes.position;
  for (let i = 0; i < p.count; i++) p.setZ(i, -Math.abs(p.getY(i)) * 0.6 + Math.sin((p.getX(i) / len) * Math.PI) * 0.06);
  g.computeVertexNormals();
  return mesh(g, mat(color, { side: THREE.DoubleSide }));
}
export function withStemLeaf(body, top, o = {}) {
  const grp = new THREE.Group(); grp.add(body);
  const st = stem(o.len, o.r); st.position.set(0, top - 0.05, 0); grp.add(st);
  if (o.leaf !== false) { const lf = leaf(); lf.position.set(0.1, top + (o.len ?? 0.28) * 0.75, 0.02); lf.rotation.set(0.3, -0.4, 0.35); grp.add(lf); }
  return grp;
}

// ---------------- stage ----------------
export function stage({ bg = '#232b3d', fov = 22, dist = 30 } = {}) {
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(bg);
  const camera = new THREE.PerspectiveCamera(fov, innerWidth / innerHeight, 0.1, 200);
  camera.position.set(0, dist * 0.12, dist); camera.lookAt(0, 0, 0);
  const renderer = new THREE.WebGLRenderer({ antialias: true, preserveDrawingBuffer: true });
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
  renderer.setSize(innerWidth, innerHeight);
  document.body.appendChild(renderer.domElement);
  const items = [];
  const place = (obj, x, y, s = 1, ry = 0) => {
    const h = new THREE.Group(); h.add(obj);
    h.position.set(x, y, 0); h.scale.setScalar(s); h.rotation.y = ry;
    scene.add(h); items.push(h); return h;
  };
  const run = (animate = true) => {
    const base = items.map(i => i.rotation.y);
    const frame = t => {
      if (animate) items.forEach((it, k) => { it.rotation.y = base[k] + Math.sin(t / 1400 + k) * 0.25; });
      renderer.render(scene, camera);
      if (animate) requestAnimationFrame(frame);
    };
    frame(0);
    requestAnimationFrame(() => { window.__done = true; });
    addEventListener('resize', () => {
      camera.aspect = innerWidth / innerHeight; camera.updateProjectionMatrix();
      renderer.setSize(innerWidth, innerHeight);
    });
  };
  return { THREE, scene, camera, renderer, place, run };
}
