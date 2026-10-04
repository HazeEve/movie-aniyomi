from ing import *
v2=open('../v2.svg').read()
head=v2[:v2.index('<!-- ================= COUNTER')]
counter=v2[v2.index('<!-- ================= COUNTER'):v2.index('<!-- ================= GRINDER')]
hud=v2[v2.index('<!-- ================= HUD'):]
head=head.replace('<defs>','<defs>'+defs()+EXTRA_DEFS+'''
<linearGradient id="macc" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#7a4424"/><stop offset=".3" stop-color="#a86a3e"/><stop offset=".55" stop-color="#e2c7a4"/><stop offset="1" stop-color="#f6ecdc"/></linearGradient>
<linearGradient id="caramelS" x1="0" x2="1"><stop offset="0" stop-color="#9a5420"/><stop offset=".5" stop-color="#e8a450"/><stop offset="1" stop-color="#a85e24"/></linearGradient>
<pattern id="stripe" width="16" height="16" patternUnits="userSpaceOnUse" patternTransform="rotate(35)"><rect width="16" height="16" fill="#f2c230"/><rect width="8" height="16" fill="#2b2026"/></pattern>''',1)
syr=[("#ef5f72","STRAWB."),("#f0bf63","VANILLA"),("#b9672c","CARAMEL"),("#6e3a24","CHOCO"),("#8cc56a","MATCHA"),("#b08ad8","TARO"),("#ffb347","MANGO")]
rail='<g filter="url(#shadow)"><rect x="330" y="436" width="760" height="20" rx="6" fill="#16121a" stroke="#4a2a18" stroke-width="3"/><rect x="330" y="436" width="760" height="5" fill="url(#goldH)"/>'
for i,(c,l) in enumerate(syr):
    rail+=f'<g style="--syrup:{c}" transform="translate({380+i*108},436) scale(.92)"><use href="#bottle"/><text x="0" y="-22" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="10" fill="#7a4a1e">{l}</text></g>'
rail+='</g>'
# topping bin: black & gold well with a row of clear square containers
bin_='<g filter="url(#shadow)"><rect x="318" y="560" width="804" height="190" rx="16" fill="#16121a" stroke="#4a2a18" stroke-width="4"/><rect x="318" y="560" width="804" height="7" fill="url(#goldH)"/><rect x="318" y="744" width="804" height="6" fill="url(#goldH)"/></g>'
tl=[("Boba",["boba"],18,.8,360,.25),("Strawberry",["straw"],30,.72,40,.12),("Blueberry",["blueb"],18,.8,360,.25),("Mint",["mint"],26,.72,90,.15),("Lemon",["lemon"],30,.7,30,.1),("Choco Chip",["chip"],20,.8,40,.25),("Cherry",["cherry"],26,.8,30,.12)]
for i,(lab,v,d,sc,rot,j) in enumerate(tl):
    bin_+=container(334+i*112,584,100,118,v,d,60+i,sc,rot=rot,jitter=j,label=lab,top=24,scoop=(i in (0,3,5))).replace('width="100" height="24" rx="12"','width="92" height="22" rx="11"').replace('font-size="10.5"','font-size="9.5"')
left='<g filter="url(#shadow)" transform="translate(150,600)"><use href="#whipper"/></g>'
left+='''<g filter="url(#shadow)" transform="translate(262,600)">
 <path d="M-14 -150 l-8 -60 M-4 -150 l2 -66 M8 -150 l10 -58 M18 -150 l20 -50" stroke="#4a2a18" stroke-width="11" stroke-linecap="round"/>
 <path d="M-14 -150 l-8 -60" stroke="url(#stripe)" stroke-width="6" stroke-linecap="round"/><path d="M-4 -150 l2 -66" stroke="#e8414f" stroke-width="6" stroke-linecap="round"/><path d="M8 -150 l10 -58" stroke="url(#stripe)" stroke-width="6" stroke-linecap="round"/><path d="M18 -150 l20 -50" stroke="#8a6ad8" stroke-width="6" stroke-linecap="round"/>
 <path d="M-36 -160 h72 l-6 150 a10 10 0 0 1 -10 10 h-40 a10 10 0 0 1 -10 -10z" fill="url(#glassG)" stroke="#4a2a18" stroke-width="4"/>
 <path d="M-24 -146 v130" stroke="#fff" stroke-width="7" stroke-linecap="round" opacity=".85"/>
 <rect x="-40" y="-168" width="80" height="14" rx="7" fill="url(#gold)" stroke="#4a2a18" stroke-width="3"/></g>'''
# drink in the Aura Fizz look: tall glass, layered latte, ice, caramel lines inside, small contained cream dome, striped straw
G='M-70 -300 h140 l-12 286 a14 14 0 0 1 -14 12 h-88 a14 14 0 0 1 -14 -12z'
drink=f'''<g transform="translate(1360,770)">
 <ellipse cx="0" cy="6" rx="150" ry="30" fill="#2a1006" opacity=".25" filter="url(#softShadow)"/>
 <rect x="-150" y="-26" width="300" height="62" rx="22" fill="url(#check)" stroke="#b07a22" stroke-width="4"/>
 <ellipse cx="0" cy="4" rx="104" ry="22" fill="#fffdf8" stroke="#e6d6b8" stroke-width="3" stroke-dasharray="4 5"/>
 <!-- straw behind the cream -->
 <path d="M18 -300 l40 -150" stroke="#4a2a18" stroke-width="22" stroke-linecap="round"/><path d="M18 -300 l40 -150" stroke="url(#stripe)" stroke-width="14" stroke-linecap="round"/>
 <clipPath id="gin"><path d="{G}"/></clipPath>
 <g clip-path="url(#gin)">
  <rect x="-72" y="-262" width="144" height="264" fill="url(#macc)"/>
  <g opacity=".6">{pack(["ice"],130,90,52,91,1.0,rot=50,jitter=.12,ox=-66,oy=-260)}</g>
  <path d="M-62 -270 q14 50 -2 100 q12 30 -2 70" stroke="url(#caramelS)" stroke-width="7" fill="none" stroke-linecap="round"/>
  <path d="M-26 -268 q10 40 -2 80" stroke="url(#caramelS)" stroke-width="6" fill="none" stroke-linecap="round"/>
  <path d="M58 -270 q-12 46 2 96 q-12 34 0 70" stroke="url(#caramelS)" stroke-width="7" fill="none" stroke-linecap="round"/>
  <path d="M24 -266 q-8 36 2 70" stroke="url(#caramelS)" stroke-width="6" fill="none" stroke-linecap="round"/>
 </g>
 <path d="{G}" fill="url(#glassG)" opacity=".55"/>
 <path d="{G}" fill="none" stroke="#4a2a18" stroke-width="5" stroke-linejoin="round"/>
 <path d="M-56 -286 l10 262" stroke="#fff" stroke-width="10" stroke-linecap="round" opacity=".7"/>
 <path d="M46 -280 l-5 170" stroke="#fff" stroke-width="5" stroke-linecap="round" opacity=".4"/>
 <!-- whipped cream dome sitting in the rim (not overflowing) -->
 <path d="M-66 -298 C-66 -330 -36 -346 0 -346 C36 -346 66 -330 66 -298z" fill="#fffdf6" stroke="#b49a78" stroke-width="4"/>
 <path d="M-44 -306 q14 -14 30 -2 M-4 -312 q16 -14 32 0 M22 -302 q12 -10 26 0" stroke="#e3d4ba" stroke-width="3" fill="none" stroke-linecap="round"/>
 <ellipse cx="-24" cy="-326" rx="14" ry="5" fill="#fff"/>
 <path d="M-52 -304 q14 -18 28 -4 q14 -20 28 -4 q14 -18 28 -2" stroke="url(#caramelS)" stroke-width="6" fill="none" stroke-linecap="round"/>
 <path d="M-72 -300 h144" stroke="url(#goldH)" stroke-width="8" stroke-linecap="round"/>
</g>'''
# player action: whipper nozzle topping the drink? show caramel squeeze bottle drizzling into dome
hand='''<g transform="translate(1235,330) rotate(-35)" filter="url(#shadow)">
 <path d="M-26 -70 h52 v120 a16 16 0 0 1 -16 16 h-20 a16 16 0 0 1 -16 -16z" fill="#e09a4a" stroke="#4a2a18" stroke-width="4"/>
 <path d="M-14 -56 v96" stroke="#fff" stroke-width="7" stroke-linecap="round" opacity=".7"/>
 <rect x="-20" y="-20" width="40" height="34" rx="8" fill="#fffaf0" stroke="#4a2a18" stroke-width="3"/><text x="0" y="2" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="8" fill="#7a4a1e">CARAMEL</text>
 <path d="M-14 66 h28 l-6 24 h-16z" fill="url(#gold)" stroke="#4a2a18" stroke-width="3"/><path d="M-3 90 h6 v18 h-6z" fill="#2b2026" stroke="#4a2a18" stroke-width="2.5"/></g>
<path d="M1306 410 q10 26 18 48" stroke="url(#caramelS)" stroke-width="5" fill="none" stroke-linecap="round"/>'''
goal='''<g filter="url(#shadow)" transform="translate(1470,250)">
 <rect x="-80" y="-70" width="160" height="150" rx="20" fill="#fffaf0" stroke="#4a2a18" stroke-width="4"/>
 <rect x="-38" y="-86" width="76" height="24" rx="12" fill="#1d1a1f" stroke="url(#goldH)" stroke-width="3"/><text y="-69" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="12" fill="#f2d27a" letter-spacing="2">GOAL</text>
 <g transform="translate(0,72) scale(.3)"><path d="M18 -300 l40 -150" stroke="url(#stripe)" stroke-width="18" stroke-linecap="round"/><path d="M-70 -300 h140 l-12 286 a14 14 0 0 1 -14 12 h-88 a14 14 0 0 1 -14 -12z" fill="url(#macc)" stroke="#4a2a18" stroke-width="10"/><path d="M-66 -298 C-66 -330 -36 -346 0 -346 C36 -346 66 -330 66 -298z" fill="#fffdf6" stroke="#b49a78" stroke-width="8"/><path d="M-52 -304 q14 -18 28 -4 q14 -20 28 -4 q14 -18 28 -2" stroke="url(#caramelS)" stroke-width="10" fill="none"/></g>
</g>'''
hud=hud.replace('Hold to pull the shot, let go in the gold ✨','Drag toppings in · draw the caramel drizzle ✨')
hud=hud.replace('<g transform="translate(610,700)" filter="url(#shadow)">','<g transform="translate(610,830)" filter="url(#shadow)">')
hud=hud.replace('<rect x="84" y="3" width="74" height="26" fill="url(#gold)"/>','').replace('fill="url(#espresso)"/>\n  <rect x="-223" y="5"','fill="url(#goldH)"/>\n  <rect x="-223" y="5"')
hud=hud.replace('Caramel Macchiato','Iced Caramel Macchiato').replace('font-size="25" fill="#3a2414">','font-size="20" fill="#3a2414">').replace('>Pull the shot<','>Add toppings<').replace('Grind the beans','Pull the shot').replace('Steam milk, caramel','Serve')
open('../topping2.svg','w').write(head+counter+rail+left+bin_+drink+hand+goal+hud)
