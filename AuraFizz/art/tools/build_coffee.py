from ing import *
s=open('../v2.svg').read()
s=s.replace('<defs>','<defs>'+defs(),1)
s=s.replace('<path d="M-58 -270 h116 l-25 90 h-66z" fill="url(#beans)"/>',
 '<clipPath id="hop"><path d="M-62 -282 h124 l-29 104 h-66z"/></clipPath><rect x="-62" y="-282" width="124" height="104" fill="#3e1c0c" clip-path="url(#hop)"/><g clip-path="url(#hop)">'+pack(["bean","bean2","bean3"],124,110,30,21,.85,ox=-62,oy=-284)+'</g>')
s=s.replace('<rect x="116" y="-50" width="50" height="46" rx="10" fill="url(#beans)"/>',
 '<clipPath id="jar"><rect x="116" y="-50" width="50" height="46" rx="10"/></clipPath><g clip-path="url(#jar)"><rect x="116" y="-50" width="50" height="46" fill="#3e1c0c"/>'+pack(["bean","bean2"],50,46,20,22,.55,ox=116,oy=-50)+'</g>')
trays = tray(28,622,140,140,pack(["bean","bean2","bean3"],120,120,30,23,.9),"Coffee Beans",90) + tray(190,622,140,140,pack(["sugar"],120,120,30,24,.85,rot=20,jitter=.12),"Sugar",91)
s=s.replace('<!-- coasters: goal + yours','<!-- ingredient trays -->'+trays+'\n<!-- coasters: goal + yours')
open('../v3.svg','w').write(s)
