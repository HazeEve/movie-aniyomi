from ing import *
W=170
items = [
 ("Coffee Beans", lambda: pack(["bean","bean2","bean3"],W,W,34,1,1.0)),
 ("Sugar Cubes", lambda: pack(["sugar"],W,W,36,2,1.05,rot=20,jitter=.12)),
 ("Ice", lambda: pack(["ice"],W,W,42,3,1.0,rot=40,jitter=.12)),
 ("Strawberries", lambda: pack(["straw"],W,W,44,4,1.0,rot=40,jitter=.12)),
 ("Mint", lambda: pack(["mint"],W,W,38,5,1.0,rot=90,jitter=.15)),
 ("Lemon", lambda: pack(["lemon"],W,W,44,6,1.0,rot=30,jitter=.1)),
 ("Boba Pearls", lambda: pack(["boba"],W,W,24,7,1.0)),
 ("Blueberries", lambda: pack(["blueb"],W,W,24,8,1.0)),
 ("Choco Chips", lambda: pack(["chip"],W,W,26,9,1.0,rot=40)),
 ("Whipped Cream", lambda: pack(["swirl"],170,170,84,10,1.15,rot=12,jitter=.06)),
 ("Cherries", lambda: pack(["cherry"],W,W,36,11,1.0,rot=30,jitter=.12)),
]
cells = []
for i,(lab,f) in enumerate(items):
    x = 40 + (i%6)*255; y = 60 + (i//6)*300
    cells.append(tray(x,y,190,190,f(),lab,i))
svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1600 660" width="1600" height="660">
<defs>{defs()}<filter id="shadow" x="-30%" y="-30%" width="160%" height="170%"><feDropShadow dx="0" dy="8" stdDeviation="7" flood-color="#2a1006" flood-opacity=".35"/></filter></defs>
<rect width="1600" height="660" fill="#f4e6cc"/>{''.join(cells)}</svg>'''
open('sheet.svg','w').write(svg)
