// Headless renderer: serves this folder, opens a page, waits for window.__done,
// saves a PNG. Works in Claude Code cloud sessions (Playwright + Chromium preinstalled).
//
//   node render.mjs concept-2d.html out/concept.png
//   node render.mjs scene-3d.html   out/scene.png
//
// three.js is loaded from jsdelivr by the page. If the browser can't reach the
// CDN, set THREE_MODULE=/path/to/three.module.js (e.g. from `npm i three`) and
// requests for it are answered from disk.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
import { execSync } from 'node:child_process';
let chromium;
try { ({ chromium } = require('playwright')); }
catch { ({ chromium } = require(path.join(execSync('npm root -g').toString().trim(), 'playwright'))); }

const here = path.dirname(fileURLToPath(import.meta.url));
const [page = 'scene-3d.html', out = 'out/render.png', w = '1440', h = '810'] = process.argv.slice(2);
const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.png': 'image/png' };

const server = http.createServer((req, res) => {
  const p = path.join(here, decodeURIComponent(req.url.split('?')[0]));
  if (!p.startsWith(here) || !fs.existsSync(p)) { res.writeHead(404); return res.end(); }
  res.writeHead(200, { 'content-type': types[path.extname(p)] || 'application/octet-stream' });
  fs.createReadStream(p).pipe(res);
}).listen(0);
const port = server.address().port;

const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
const tab = await browser.newPage({ viewport: { width: +w, height: +h }, deviceScaleFactor: 1 });
if (process.env.THREE_MODULE) {
  await tab.route(/three@.*\/build\/three\.module\.js/, r =>
    r.fulfill({ contentType: 'text/javascript', body: fs.readFileSync(process.env.THREE_MODULE) }));
}
tab.on('console', m => m.type() === 'error' && console.error('[page]', m.text()));
tab.on('pageerror', e => console.error('[page]', e.message));
await tab.goto(`http://localhost:${port}/${page}`);
await tab.waitForFunction(() => window.__done === true, null, { timeout: 60000 });
fs.mkdirSync(path.dirname(path.resolve(out)), { recursive: true });
await tab.screenshot({ path: out });
console.log('wrote', out);
await browser.close();
server.close();
