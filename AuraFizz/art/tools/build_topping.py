from ing import *
v2=open('../v2.svg').read()
head=v2[:v2.index('<!-- ================= COUNTER')]
counter=v2[v2.index('<!-- ================= COUNTER'):v2.index('<!-- ================= GRINDER')]
hud=v2[v2.index('<!-- ================= HUD'):]
head=head.replace('<defs>','<defs>'+defs()+'''
<linearGradient id="latte" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#e9c79c"/><stop offset=".55" stop-color="#c88d5a"/><stop offset="1" stop-color="#8a5230"/></linearGradient>
<linearGradient id="caramelS" x1="0" x2="1"><stop offset="0" stop-color="#9a5420"/><stop offset=".5" stop-color="#e09a4a"/><stop offset="1" stop-color="#a85e24"/></linearGradient>''',1)
syr=[("#ef5f72","STRAWB."),("#f0bf63","VANILLA"),("#b9672c","CARAMEL"),("#6e3a24","CHOCO"),("#8cc56a","MATCHA"),("#b08ad8","TARO"),("#ffb347","MANGO")]
rail='<g filter="url(#shadow)"><rect x="330" y="436" width="760" height="20" rx="6" fill="#16121a" stroke="#4a2a18" stroke-width="3"/><rect x="330" y="436" width="760" height="5" fill="url(#goldH)"/>'
for i,(c,l) in enumerate(syr):
    x=380+i*108
    rail+=f'<g style="--syrup:{c}" transform="translate({x},436) scale(.92)"><use href="#bottle"/><text x="0" y="-22" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="10" fill="#7a4a1e">{l}</text></g>'
rail+='</g>'
# black tray rack with ingredient trays (two rows)
rack='<g filter="url(#shadow)"><rect x="330" y="560" width="780" height="40" rx="10" fill="#16121a"/><rect x="330" y="560" width="780" height="5" fill="url(#goldH)"/></g>'
tl=[("Boba",["boba"],22,1.0,360,.25),("Strawberries",["straw"],40,.9,40,.12),("Blueberries",["blueb"],22,.95,360,.25),("Mint",["mint"],34,.9,90,.15),("Lemon",["lemon"],40,.9,30,.1),("Choco Chips",["chip"],24,.95,40,.25),("Cream",["swirl"],70,1.0,12,.06),("Cherries",["cherry"],32,.95,30,.12)]
for i,(lab,v,d,sc,rot,j) in enumerate(tl):
    x=340+i*96
    rack+=tray(x,604,88,104,pack(v,68,84,d,40+i,sc,rot=rot,jitter=j),lab,200+i).replace('font-size="11"','font-size="9"').replace(f'width="116"','width="84"').replace(f'x="{88/2-58}"',f'x="{88/2-42}"')
# left: whipped cream siphon + straw jar
left='''<g filter="url(#shadow)" transform="translate(150,600)">
 <rect x="-34" y="-250" width="68" height="236" rx="30" fill="url(#chrome)" stroke="#4a2a18" stroke-width="4"/>
 <rect x="-34" y="-120" width="68" height="18" fill="url(#goldH)"/>
 <path d="M-20 -232 v200" stroke="#fff" stroke-width="8" stroke-linecap="round" opacity=".8"/>
 <rect x="-26" y="-284" width="52" height="38" rx="10" fill="#2b2026" stroke="#4a2a18" stroke-width="4"/>
 <path d="M10 -284 l26 -20 l8 10 l-22 18z" fill="url(#gold)" stroke="#4a2a18" stroke-width="3"/>
 <path d="M-8 -284 v-26 h16 v26" fill="url(#chrome)" stroke="#4a2a18" stroke-width="3"/>
 <path d="M-4 -310 l4 -12 l4 12" fill="url(#gold)" stroke="#4a2a18" stroke-width="2.5"/>
</g>
<g filter="url(#shadow)" transform="translate(250,600)">
 <path d="M-14 -150 l-8 -60 M-4 -150 l2 -66 M8 -150 l10 -58 M18 -150 l20 -50" stroke="#4a2a18" stroke-width="11" stroke-linecap="round"/>
 <path d="M-14 -150 l-8 -60" stroke="#f59ac0" stroke-width="6" stroke-linecap="round"/><path d="M-4 -150 l2 -66" stroke="#8ed5b4" stroke-width="6" stroke-linecap="round"/><path d="M8 -150 l10 -58" stroke="#f2d27a" stroke-width="6" stroke-linecap="round"/><path d="M18 -150 l20 -50" stroke="#9ad6ff" stroke-width="6" stroke-linecap="round"/>
 <path d="M-36 -160 h72 l-6 150 a10 10 0 0 1 -10 10 h-40 a10 10 0 0 1 -10 -10z" fill="url(#glassG)" stroke="#4a2a18" stroke-width="4"/>
 <path d="M-24 -146 v130" stroke="#fff" stroke-width="7" stroke-linecap="round" opacity=".85"/>
 <rect x="-40" y="-168" width="80" height="14" rx="7" fill="url(#gold)" stroke="#4a2a18" stroke-width="3"/>
</g>'''
# the drink being decorated (big, right) on gingham coaster
cx,cy=1360,760
drink=f'''<g filter="url(#shadow)" transform="translate({cx},{cy})">
 <rect x="-150" y="-30" width="300" height="70" rx="22" fill="url(#check)" stroke="#b07a22" stroke-width="4"/>
 <ellipse cx="0" cy="4" rx="110" ry="24" fill="#fffdf8" stroke="#e6d6b8" stroke-width="3" stroke-dasharray="4 5"/>
 <clipPath id="glassIn"><path d="M-78 -330 h156 l-14 318 a14 14 0 0 1 -14 12 h-100 a14 14 0 0 1 -14 -12z"/></clipPath>
 <path d="M-78 -330 h156 l-14 318 a14 14 0 0 1 -14 12 h-100 a14 14 0 0 1 -14 -12z" fill="#fff" fill-opacity=".25"/>
 <g clip-path="url(#glassIn)">
  <rect x="-80" y="-270" width="160" height="272" fill="url(#latte)"/>
  <path d="M-80 -270 q40 14 80 0 t80 0 v10 h-160z" fill="#f3dfc2"/>
  {pack(["boba"],150,46,24,77,1.05,ox=-75,oy=-38)}
  <g opacity=".55">{pack(["ice"],140,120,60,78,1.1,rot=50,jitter=.15,ox=-70,oy=-250)}</g>
  <path d="M-70 -300 q12 60 -4 120 q16 40 0 90" stroke="url(#caramelS)" stroke-width="10" fill="none" stroke-linecap="round" opacity=".9"/>
  <path d="M68 -300 q-14 50 2 110 q-14 50 0 80" stroke="url(#caramelS)" stroke-width="9" fill="none" stroke-linecap="round" opacity=".9"/>
 </g>
 <path d="M-78 -330 h156 l-14 318 a14 14 0 0 1 -14 12 h-100 a14 14 0 0 1 -14 -12z" fill="none" stroke="#4a2a18" stroke-width="5" stroke-linejoin="round"/>
 <path d="M-62 -316 l10 290" stroke="#fff" stroke-width="10" stroke-linecap="round" opacity=".75"/>
 <path d="M50 -310 l-6 200" stroke="#fff" stroke-width="5" stroke-linecap="round" opacity=".45"/>
 <path d="M-82 -330 h164" stroke="url(#goldH)" stroke-width="8" stroke-linecap="round"/>
 <!-- straw -->
 <path d="M30 -320 l46 -150" stroke="#4a2a18" stroke-width="20" stroke-linecap="round"/><path d="M30 -320 l46 -150" stroke="#f59ac0" stroke-width="12" stroke-linecap="round"/><path d="M34 -332 l42 -136" stroke="#fff" stroke-width="3" stroke-dasharray="10 12" opacity=".9"/>
 <!-- whipped cream crown + drizzle + toppings -->
 <g transform="translate(-4,-338) scale(1.9)"><use href="#swirl"/></g>
 <path d="M-70 -350 q20 -26 40 -4 q16 -30 38 -6 q18 -28 40 -2" stroke="url(#caramelS)" stroke-width="7" fill="none" stroke-linecap="round"/>
 <path d="M-40 -400 q16 -18 32 -2 q14 -20 30 -2" stroke="url(#caramelS)" stroke-width="6" fill="none" stroke-linecap="round"/>
 <g transform="translate(-50,-380) rotate(-15) scale(.9)"><use href="#straw"/></g>
 <g transform="translate(48,-372) rotate(10) scale(.9)"><use href="#mint"/></g>
 <g transform="translate(6,-448) scale(1)"><use href="#cherry"/></g>
 <g transform="translate(-14,-412) rotate(30) scale(.8)"><use href="#chip"/></g><g transform="translate(24,-410) rotate(-20) scale(.8)"><use href="#chip"/></g>
</g>'''
# squeeze bottle drawing the drizzle + a strawberry being dragged
hand=f'''<g transform="translate(1180,300) rotate(-38)" filter="url(#shadow)">
 <path d="M-26 -70 h52 v120 a16 16 0 0 1 -16 16 h-20 a16 16 0 0 1 -16 -16z" fill="#e09a4a" stroke="#4a2a18" stroke-width="4"/>
 <path d="M-26 -70 h52 v120 a16 16 0 0 1 -16 16 h-20 a16 16 0 0 1 -16 -16z" fill="url(#glassG)" opacity=".7"/>
 <path d="M-14 -56 v96" stroke="#fff" stroke-width="7" stroke-linecap="round" opacity=".7"/>
 <rect x="-20" y="-20" width="40" height="34" rx="8" fill="#fffaf0" stroke="#4a2a18" stroke-width="3"/><text x="0" y="2" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="8" fill="#7a4a1e">CARAMEL</text>
 <path d="M-14 66 h28 l-6 24 h-16z" fill="url(#gold)" stroke="#4a2a18" stroke-width="3"/><path d="M-3 90 h6 v18 h-6z" fill="#2b2026" stroke="#4a2a18" stroke-width="2.5"/>
</g>
<path d="M1252 382 q20 30 30 60" stroke="url(#caramelS)" stroke-width="6" fill="none" stroke-linecap="round" stroke-dasharray="2 0"/>
<g transform="translate(1180,520) rotate(-12) scale(1.25)" filter="url(#shadow)"><use href="#straw"/></g>
<path d="M1050 650 q60 -110 120 -126" stroke="#fff" stroke-width="4" fill="none" stroke-dasharray="3 12" stroke-linecap="round" opacity=".9"/>
<g transform="translate(1166,532)"><circle r="30" fill="none" stroke="#fff" stroke-width="4" opacity=".7"/></g>'''
goal='''<g filter="url(#shadow)" transform="translate(1470,250)">
 <rect x="-80" y="-70" width="160" height="150" rx="20" fill="#fffaf0" stroke="#4a2a18" stroke-width="4"/>
 <rect x="-38" y="-86" width="76" height="24" rx="12" fill="#1d1a1f" stroke="url(#goldH)" stroke-width="3"/><text y="-69" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="700" font-size="12" fill="#f2d27a" letter-spacing="2">GOAL</text>
 <g transform="translate(0,78) scale(.27)"><path d="M-78 -330 h156 l-14 318 a14 14 0 0 1 -14 12 h-100 a14 14 0 0 1 -14 -12z" fill="url(#latte)" stroke="#4a2a18" stroke-width="10"/><g transform="translate(-4,-338) scale(1.9)"><use href="#swirl"/></g><path d="M-70 -350 q20 -26 40 -4 q16 -30 38 -6 q18 -28 40 -2" stroke="url(#caramelS)" stroke-width="12" fill="none"/><g transform="translate(6,-448) scale(1.6)"><use href="#cherry"/></g><g transform="translate(-50,-380) scale(1.4)"><use href="#straw"/></g></g>
</g>'''
hud=hud.replace('Hold to pull the shot, let go in the gold ✨','Drag toppings on · draw the caramel drizzle ✨')
hud=hud.replace('<g transform="translate(610,700)" filter="url(#shadow)">','<g transform="translate(610,800)" filter="url(#shadow)">')
hud=hud.replace('<rect x="84" y="3" width="74" height="26" fill="url(#gold)"/>','').replace('fill="url(#espresso)"/>\n  <rect x="-223" y="5"','fill="url(#goldH)"/>\n  <rect x="-223" y="5"')
hud=hud.replace('Caramel Macchiato','Caramel Cloud Latte').replace('>Pull the shot<','>Add toppings<').replace('Grind the beans','Pull the shot')
hud=hud.replace('Steam milk, caramel','Serve')
svg=head+counter+rail+left+rack+drink+hand+goal+hud
open('../topping.svg','w').write(svg)
