#!/usr/bin/env python3
"""Checks AuraFizz2D against YOUR drink data without opening Studio.

  python3 tools/check_with_your_data.py path/to/2_Update_v3.lua   (or any file with the MODULES block)

Needs the `luau` CLI (https://github.com/luau-lang/luau/releases) on PATH or in $LUAU.
It loads your DrinkRecipes / DrinkCatalog / DrinkLooks / DrinkImages with the 2D Bridge
and MiniGames modules and reports any recipe step the 2D game can't play.
"""
import os, re, subprocess, sys, tempfile
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HEAD = '\n-- tiny Roblox stand-ins, just enough to load the modules\nlocal function enumStub() return setmetatable({}, {__index=function(t,k) local v=setmetatable({Name=k},{__index=function(_,kk) return k.."."..kk end}); rawset(t,k,v); return v end}) end\nEnum = enumStub()\nlocal C3 = {}\nC3.__index = C3\nColor3 = { new=function(r,g,b) return setmetatable({R=r,G=g,B=b},C3) end,\n  fromRGB=function(r,g,b) return setmetatable({R=r/255,G=g/255,B=b/255},C3) end,\n  fromHex=function(h) h=h:gsub("#",""); return setmetatable({R=tonumber(h:sub(1,2),16)/255,G=tonumber(h:sub(3,4),16)/255,B=tonumber(h:sub(5,6),16)/255},C3) end }\nfunction C3:Lerp(o,t) return Color3.new(self.R+(o.R-self.R)*t,self.G+(o.G-self.G)*t,self.B+(o.B-self.B)*t) end\nfunction C3:ToHex() return string.format("%02x%02x%02x",self.R*255,self.G*255,self.B*255) end\ntypeof = function(v) if getmetatable(v)==C3 then return "Color3" end return type(v) end\nlocal anyStub; anyStub = setmetatable({}, {__index=function() return anyStub end, __call=function() return anyStub end})\nUDim2 = {new=function() return {} end, fromScale=function() return {} end, fromOffset=function() return {} end}\nUDim = {new=function() return {} end}\nVector2 = {new=function(x,y) return {X=x,Y=y} end, zero={X=0,Y=0}}\nRandom = {new=function() return {NextInteger=function(_,a,b) return a end, NextNumber=function(_,a,b) return a or 0 end} end}\nTweenInfo = {new=function() return {} end}\nwarn = function(...) print("WARN", ...) end\ntask = {spawn=function() end, delay=function() end, wait=function() end}\n\n'
TAIL = 'local loaded = {}\nlocal modObjs = {}\nlocal function modObj(name) modObjs[name] = modObjs[name] or {Name=name, IsA=function() return true end, __mod=name}; return modObjs[name] end\nlocal drinksFolder = {FindFirstChild=function(_, n) if SOURCES[n] and (n=="DrinkRecipes" or n=="DrinkCatalog" or n=="DrinkLooks" or n=="DrinkImages") then return modObj(n) end return nil end}\nlocal pkgFolder = setmetatable({}, {__index=function(_, n) return modObj(n) end})\nlocal services = {ReplicatedStorage={WaitForChild=function(_, n) return drinksFolder end}}\ngame = {GetService=function(_, n) return services[n] or anyStub end}\nlocal function myRequire(obj)\n  local n = obj.__mod\n  if loaded[n] ~= nil then return loaded[n] end\n  local fn = assert(loadstring(SOURCES[n], n))\n  setfenv(fn, setmetatable({script={Parent=pkgFolder}, require=myRequire}, {__index=getfenv(0)}))\n  loaded[n] = fn()\n  return loaded[n]\nend\n\nlocal Bridge = myRequire(modObj("Bridge"))\nlocal MiniGames = myRequire(modObj("MiniGames"))\nlocal Config = myRequire(modObj("Config"))\nlocal C = Bridge.Catalog\n\nlocal all = Bridge.allRecipes()\nprint("recipes (all-ages):", #all, " categories:", #Bridge.categories())\nlocal problems, storageVisits, actions, gamesUsed = 0, 0, 0, {}\nfor _, r in all do\n  for _, s in r.steps do\n    local st = C.Stations[s[1]]\n    if not st then print("  unknown station", r.id, s[1]); problems += 1\n    elseif st.kind == "storage" and s[1] ~= "CupRack" and not C.Items[s[2]] then print("  unknown item", r.id, s[2]); problems += 1\n    elseif s[1] == "CupRack" and not C.Cups[s[2]] then print("  unknown cup", r.id, s[2]); problems += 1\n    elseif st.kind == "appliance" then\n      local a = C.Actions[s[2]]\n      if not a then print("  unknown action", r.id, s[2]); problems += 1\n      else\n        local kind = Config.Games[s[2]] or a.game\n        gamesUsed[kind] = (gamesUsed[kind] or 0) + 1\n        if not MiniGames.Games[kind] then print("  no 2D game for", kind); problems += 1 end\n      end\n    end\n  end\n  for _, g in Bridge.stepsOf(r) do\n    if g.kind == "storage" then storageVisits += 1 elseif g.kind == "action" then actions += 1 end\n  end\n  if #r.steps > 0 and r.steps[#r.steps][1] ~= "ServeCounter" then print("  no serve step", r.id) end\nend\nprint("2D steps: shelf visits", storageVisits, " mini-games", actions, " problems", problems)\nlocal names = {}\nfor k, v in gamesUsed do table.insert(names, k.."="..v) end\ntable.sort(names); print("game types used:", table.concat(names, ", "))\nfor _, key in {"CupRack","Pantry","Fridge","Freezer","BarShelf"} do print("  shelf", key, #Bridge.itemsIn(key), "items") end\nlocal ex = Bridge.recipe("cafe_au_lait")\nlocal parts = {}\nfor _, g in Bridge.stepsOf(ex) do\n  if g.kind == "storage" then table.insert(parts, g.station.."("..table.concat(g.items, "+")..")")\n  elseif g.kind == "action" then table.insert(parts, g.action) else table.insert(parts, "SERVE") end\nend\nprint("example Café au Lait:", table.concat(parts, " -> "))\nlocal g = Bridge.liquid(Bridge.recipe("vietnamese_coffee"))\nprint("vietnamese_coffee liquid layers:", #g)\nprint("zone score centre/edge/miss:", MiniGames.zoneScore(0.81,0.72,0.9), MiniGames.zoneScore(0.72,0.72,0.9), MiniGames.zoneScore(0.5,0.72,0.9))\n'

def lit(s):
    return "[==========[\n" + s + "\n]==========]"

def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    text = open(sys.argv[1], encoding="utf-8").read()
    mods = dict(re.findall(r"\n\t(\w+) = \[=\[\n(.*?)\n\]=\]", text, re.S))
    need = ["DrinkRecipes", "DrinkCatalog"]
    if not all(n in mods for n in need):
        print("Could not find DrinkRecipes + DrinkCatalog in", sys.argv[1])
        return 1
    pkg = os.path.join(ROOT, "src", "AuraFizz2D")
    ours = {n: open(os.path.join(pkg, n + ".luau"), encoding="utf-8").read() for n in ["Config", "Paint", "Bridge", "FX", "UI", "MiniGames"]}
    body = HEAD + "local SOURCES = {\n"
    for n, s in list(mods.items()) + list(ours.items()):
        body += '  ["%s"] = %s,\n' % (n, lit(s))
    body += "}\n" + TAIL
    with tempfile.NamedTemporaryFile("w", suffix=".luau", delete=False, encoding="utf-8") as f:
        f.write(body)
    luau = os.environ.get("LUAU", "luau")
    return subprocess.call([luau, f.name])

if __name__ == "__main__":
    sys.exit(main())
