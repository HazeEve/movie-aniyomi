import json, html
d = json.load(open('batches.json'))
B = d['batches']
secs = []
for b in B:
    if not secs or secs[-1][0] != b['section']:
        secs.append([b['section'], []])
    secs[-1][1].append(b)
total_items = sum(len(b['codes']) for b in B)
nav = "".join(f'<a href="#s{i+1}"><span class="n">{len(s[1])}</span>{html.escape(s[0].split(". ",1)[1])}</a>' for i, s in enumerate(secs))
body = []
k = 0
for i, (name, bs) in enumerate(secs):
    body.append(f'<section id="s{i+1}"><h2><span class="step">Step {i+1}</span>{html.escape(name.split(". ",1)[1])}</h2>')
    for b in bs:
        k += 1
        chips = "".join(f'<code>{html.escape(c)}</code>' for c in b['codes'])
        body.append(f'''<article class="batch" id="b{k}" data-id="b{k}">
<header><label class="done"><input type="checkbox" id="chk{k}" aria-label="Mark batch {k} done"><span class="num">{k:02d}</span></label>
<h3>{html.escape(b['title'])}</h3><span class="count">{len(b['codes'])} objects</span>
<button class="copy" type="button" data-k="{k}">Copy prompt</button></header>
<pre id="p{k}">{html.escape(b['prompt'])}</pre>
<details><summary>Object codes, in order</summary><div class="chips">{chips}</div></details>
</article>''')
    body.append('</section>')
page = f'''<title>Aura Fizz Tripo Batches</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,600;12..96,800&family=Atkinson+Hyperlegible:wght@400;700&family=JetBrains+Mono:wght@400;600&display=swap">
<style>
/* Layout: one reading column of numbered batch cards; sticky step bar on top. Espresso black + brass gold, like the stations. */
:root {{
  --bg:#f6f2ea; --panel:#fffdf8; --ink:#231b16; --muted:#6e6157; --line:#e3d9cb;
  --gold:#a8792a; --gold-soft:#f1e3c4; --prompt:#2a211b; --prompt-ink:#f3e9d8; --ok:#3d7a4a;
  --display:"Bricolage Grotesque", "Segoe UI", system-ui, sans-serif;
  --body:"Atkinson Hyperlegible", "Segoe UI", system-ui, sans-serif;
  --mono:"JetBrains Mono", ui-monospace, Menlo, Consolas, monospace;
}}
@media (prefers-color-scheme: dark) {{ :root:not([data-theme="light"]) {{
  --bg:#16110e; --panel:#1f1814; --ink:#f1e8dc; --muted:#a8998b; --line:#3a2f27;
  --gold:#d9a94e; --gold-soft:#3a2d18; --prompt:#0f0b09; --prompt-ink:#efe3cf; --ok:#6fbf7e; color-scheme:dark }} }}
:root[data-theme="dark"] {{ --bg:#16110e; --panel:#1f1814; --ink:#f1e8dc; --muted:#a8998b; --line:#3a2f27;
  --gold:#d9a94e; --gold-soft:#3a2d18; --prompt:#0f0b09; --prompt-ink:#efe3cf; --ok:#6fbf7e; color-scheme:dark }}
body {{ background:var(--bg); color:var(--ink); font:16px/1.55 var(--body); padding-inline:16px; padding-block:0 64px }}
.wrap {{ max-width:880px; margin:0 auto }}
.top {{ padding-block:40px 20px; display:grid; gap:14px }}
h1 {{ font:800 clamp(30px,6vw,46px)/1.05 var(--display); letter-spacing:-.02em; margin:0; text-wrap:balance }}
h1 em {{ font-style:normal; color:var(--gold) }}
.lead {{ margin:0; max-width:62ch; color:var(--muted) }}
.how {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(190px,1fr)); gap:10px; margin:6px 0 0; padding:0; list-style:none }}
.how li {{ background:var(--panel); border:1px solid var(--line); border-radius:10px; padding:12px 14px; font-size:14px }}
.how b {{ display:block; font:700 12px/1 var(--body); letter-spacing:.08em; text-transform:uppercase; color:var(--gold); margin-bottom:6px }}
.bar {{ position:sticky; top:env(safe-area-inset-top,0px); z-index:5; background:var(--bg); border-bottom:1px solid var(--line);
  display:flex; gap:8px; overflow-x:auto; padding-block:10px; margin-inline:-16px; padding-inline:16px; scrollbar-width:thin }}
.bar a {{ flex:none; display:flex; gap:7px; align-items:center; text-decoration:none; color:var(--ink); font-size:14px;
  background:var(--panel); border:1px solid var(--line); border-radius:999px; padding:6px 12px 6px 6px }}
.bar a:hover, .bar a:focus-visible {{ border-color:var(--gold) }}
.bar .n {{ background:var(--gold-soft); color:var(--gold); font:600 12px/1 var(--mono); border-radius:999px; padding:5px 7px }}
.progress {{ font:600 13px/1 var(--mono); color:var(--muted); font-variant-numeric:tabular-nums }}
section {{ padding-top:28px; scroll-margin-top:60px }}
h2 {{ font:700 24px/1.2 var(--display); margin:0 0 14px; display:flex; flex-direction:column; gap:4px; text-wrap:balance }}
.step {{ font:600 12px/1 var(--body); letter-spacing:.1em; text-transform:uppercase; color:var(--gold) }}
.batch {{ background:var(--panel); border:1px solid var(--line); border-radius:12px; padding:14px; margin-bottom:12px; scroll-margin-top:64px; display:grid; gap:10px }}
.batch.is-done {{ opacity:.55 }}
.batch header {{ display:flex; align-items:center; gap:12px; flex-wrap:wrap }}
.done {{ display:flex; align-items:center; gap:8px; cursor:pointer }}
.done input {{ width:18px; height:18px; accent-color:var(--ok) }}
.num {{ font:600 13px/1 var(--mono); color:var(--muted); font-variant-numeric:tabular-nums }}
h3 {{ font:700 17px/1.25 var(--display); margin:0; flex:1 1 200px; min-width:0 }}
.count {{ font-size:13px; color:var(--muted) }}
.copy {{ font:700 14px/1 var(--body); background:var(--ink); color:var(--bg); border:0; border-radius:8px; padding:10px 14px; cursor:pointer }}
.copy:hover {{ background:var(--gold) }}
.copy:focus-visible, .done input:focus-visible, summary:focus-visible {{ outline:2px solid var(--gold); outline-offset:2px }}
.copy.ok {{ background:var(--ok); color:#fff }}
pre {{ margin:0; background:var(--prompt); color:var(--prompt-ink); border-radius:8px; padding:12px 14px; font:13px/1.6 var(--mono);
  white-space:pre-wrap; word-break:break-word; max-height:9.6em; overflow:auto }}
details summary {{ cursor:pointer; color:var(--muted); font-size:14px }}
.chips {{ display:flex; flex-wrap:wrap; gap:6px; padding-top:8px }}
.chips code {{ font:12px/1 var(--mono); background:var(--gold-soft); color:var(--ink); border-radius:6px; padding:5px 7px }}
@media (prefers-reduced-motion: reduce) {{ html {{ scroll-behavior:auto }} }}
html {{ scroll-behavior:smooth }}
</style>
<div class="wrap">
<div class="top">
<h1>Aura Fizz <em>Tripo</em> batches</h1>
<p class="lead">{len(B)} images cover all {total_items} objects. Every prompt already includes the art style, so you only copy and paste. Go top to bottom: stations, materials, ingredients, cut pieces, then liquids.</p>
<ul class="how">
<li><b>1 · Copy</b>Press <em>Copy prompt</em> on the next batch.</li>
<li><b>2 · Generate</b>Paste into Tripo, set size to 16:9, attach coffee_front_final.png if Tripo allows a reference.</li>
<li><b>3 · Send</b>Send me the image. I cut out every object and name it with the batch's codes.</li>
<li><b>4 · Tick</b>Tick the box so you know where you stopped. <span class="progress" id="prog"></span></li>
</ul>
</div>
<nav class="bar" aria-label="Steps">{nav}</nav>
{''.join(body)}
</div>
<script>
const KEY='aurafizz-tripo-done';
let done={{}};
try {{ done=JSON.parse(localStorage.getItem(KEY)||'{{}}')||{{}} }} catch(e) {{}}
const boxes=[...document.querySelectorAll('.batch input[type=checkbox]')];
function paint(){{
  let n=0;
  boxes.forEach(b=>{{const a=b.closest('.batch');const on=!!done[a.dataset.id];b.checked=on;a.classList.toggle('is-done',on);if(on)n++;}});
  document.getElementById('prog').textContent=n+' / '+boxes.length+' done';
}}
boxes.forEach(b=>b.addEventListener('change',()=>{{const id=b.closest('.batch').dataset.id;if(b.checked)done[id]=1;else delete done[id];
  try{{localStorage.setItem(KEY,JSON.stringify(done))}}catch(e){{}} paint();}}));
paint();
document.addEventListener('click',async e=>{{
  const btn=e.target.closest('.copy'); if(!btn) return;
  const pre=document.getElementById('p'+btn.dataset.k);
  try {{ await navigator.clipboard.writeText(pre.textContent); btn.textContent='Copied'; btn.classList.add('ok'); }}
  catch(err) {{ const r=document.createRange(); r.selectNodeContents(pre); const s=getSelection(); s.removeAllRanges(); s.addRange(r); btn.textContent='Selected, press Ctrl+C'; }}
  setTimeout(()=>{{btn.textContent='Copy prompt';btn.classList.remove('ok')}},1800);
}});
</script>
'''
open('tripo_batches.html', 'w').write(page)
print(len(page))
