from ing import *
items = [
 ("Coffee Beans", ["bean","bean2","bean3"],30,.95,360,.25),
 ("Sugar Cubes", ["sugar"],32,.95,20,.12),
 ("Ice", ["ice"],40,.95,40,.12),
 ("Strawberries", ["straw"],40,.95,40,.12),
 ("Mint", ["mint"],34,.95,90,.15),
 ("Lemon", ["lemon"],40,.95,30,.1),
 ("Boba Pearls", ["boba"],22,1.0,360,.25),
 ("Blueberries", ["blueb"],22,1.0,360,.25),
 ("Choco Chips", ["chip"],24,1.0,40,.25),
 ("Cherries", ["cherry"],32,1.0,30,.12),
]
cells=[]
for i,(lab,v,d,sc,rot,j) in enumerate(items):
    x=40+(i%5)*300; y=50+(i//5)*300
    cells.append(container(x,y,200,170,v,d,i*7+1,sc,rot=rot,jitter=j,label=lab,scoop=(i%3==0)))
cells.append(f'<g transform="translate(1520,600)"><use href="#whipper"/></g>')
svg=f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1600 650" width="1600" height="650"><defs>{defs()}{EXTRA_DEFS}<filter id="shadow" x="-30%" y="-30%" width="160%" height="170%"><feDropShadow dx="0" dy="8" stdDeviation="7" flood-color="#2a1006" flood-opacity=".35"/></filter></defs>
<rect width="1600" height="650" fill="#f4e6cc"/>{''.join(cells)}</svg>'''
open('sheet2.svg','w').write(svg)
