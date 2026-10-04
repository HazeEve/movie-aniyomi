#!/usr/bin/env python3
"""Builds AuraPhone_Install.lua (paste into the Studio Command Bar).   python3 tools/build_installer.py"""
import os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EQ = "=" * 8
def lit(s):
    assert ("]" + EQ + "]") not in s
    return "[" + EQ + "[\n" + s + "]" + EQ + "]"
server = open(os.path.join(ROOT, "src", "PhoneServer.server.luau"), encoding="utf-8").read()
client = open(os.path.join(ROOT, "src", "PhoneClient.client.luau"), encoding="utf-8").read()
out = f'''--!nocheck
-- AuraPhone installer. Paste ALL of this into the Roblox Studio Command Bar (View > Command Bar) and press Enter.
-- It adds:  ServerScriptService.AuraPhoneServer  and  StarterPlayer.StarterPlayerScripts.AuraPhoneClient
-- Old copies are moved to ServerStorage.AuraPhoneOld. Safe to run again. Ctrl+Z undoes it.
local CHS = game:GetService("ChangeHistoryService")
CHS:SetWaypoint("AuraPhone install (before)")
local SS = game:GetService("ServerStorage")
local old = SS:FindFirstChild("AuraPhoneOld") or Instance.new("Folder")
old.Name = "AuraPhoneOld"
old.Parent = SS
local function put(class, name, parent, source)
	local was = parent:FindFirstChild(name)
	if was then was.Name = name .. "_old_" .. os.time(); was.Parent = old end
	local s = Instance.new(class)
	s.Name = name
	s.Source = source
	s.Parent = parent
end
put("Script", "AuraPhoneServer", game:GetService("ServerScriptService"), {lit(server)})
put("LocalScript", "AuraPhoneClient", game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"), {lit(client)})
CHS:SetWaypoint("AuraPhone install")
print("AuraPhone installed! Now: Game Settings > Security > Enable Studio Access to API Services, then File > Publish to Roblox.")
'''
open(os.path.join(ROOT, "AuraPhone_Install.lua"), "w", encoding="utf-8").write(out)
print("wrote AuraPhone_Install.lua", out.count("\n"), "lines")
