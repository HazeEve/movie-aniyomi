// Render an SVG or HTML file to PNG with the pre-installed Chromium, supersampled for smooth edges.
// usage: node render.mjs IN.svg|IN.html OUT.png [width=1024] [height=width] [scale=2]
// Needs the playwright package (npm i playwright; never run "playwright install" here).
import { chromium } from 'playwright';
import fs from 'fs';
const [,, src, out, W = '1024', H = W, S = '2'] = process.argv;
const w = +W, h = +H, s = +S;
const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' }).catch(() => chromium.launch());
const p = await b.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: s });
let body = fs.readFileSync(src, 'utf8');
if (src.endsWith('.svg')) body = `<html><body style="margin:0;background:transparent">${body.replace(/<svg([^>]*?)\swidth="[^"]*"\s+height="[^"]*"/, `<svg$1 width="${w}" height="${h}"`)}</body></html>`;
await p.setContent(body, { waitUntil: 'networkidle' });
await p.screenshot({ path: out, clip: { x: 0, y: 0, width: w, height: h }, omitBackground: true });
await b.close();
console.log('wrote', out, `${w * s}x${h * s}`);
