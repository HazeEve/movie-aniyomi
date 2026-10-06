import { chromium } from 'playwright';
const [,, svg, png, size='2048'] = process.argv;
const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' }).catch(() => chromium.launch());
const p = await b.newPage({ viewport: { width: +size, height: +size } });
const fs = await import('fs');
await p.setContent(`<html><body style="margin:0">${fs.readFileSync(svg,'utf8').replace('width="1024" height="1024"', `width="${size}" height="${size}"`)}</body></html>`);
await p.screenshot({ path: png, clip: { x:0, y:0, width:+size, height:+size } });
await b.close();
