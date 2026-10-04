local M = MOCK
local function svc(name, props) local s = M.make(name, props); s.Name = name; return s end
local fakeCalls = {}
local remotesFolder = svc("Folder"); remotesFolder.Name = "AuraPhoneRemotes"
local Fn = svc("RemoteFunction"); Fn.Name = "Fn"; Fn.Parent = remotesFolder
local Event = svc("RemoteEvent"); Event.Name = "Event"; Event.Parent = remotesFolder
local passes = { { id = 111, name = "Small tip", price = 5, forSale = true, icon = 0, creator = 2 }, { id = 222, name = "Big tip", price = 50, forSale = true, icon = 9, creator = 2, owned = true } }
Fn.InvokeServer = function(_, kind, ...)
	table.insert(fakeCalls, kind)
	task.wait(0.1)
	if kind == "GetMe" then return { wallpaper = 3, received = 120, sent = 10, passes = { passes[1] }, saving = true } end
	if kind == "GetPasses" then return passes end
	if kind == "Message" then local _, t = ...; return true, (string.gsub(t, "bad", "###")) end
	if kind == "AddPass" then return true, passes end
	if kind == "RemovePass" then return {} end
	if kind == "Gift" then return false, "test error" end
	return true
end
local rs = svc("ReplicatedStorage"); remotesFolder.Parent = rs
local playerGui = svc("PlayerGui"); playerGui.Name = "PlayerGui"
local me = svc("Player", { UserId = 1, Name = "aura_maker", DisplayName = "Aura" }); playerGui.Parent = me
local other = svc("Player", { UserId = 2, Name = "fizzfan", DisplayName = "Fizz" })
local list = { me, other }
local Players = svc("Players", { LocalPlayer = me })
Players.GetPlayers = function() return table.clone(list) end
Players.GetPlayerByUserId = function(_, id) for _, p in list do if p.UserId == id then return p end end return nil end
Players.GetUserThumbnailAsync = function(_, id) task.wait(0.2); return "rbxthumb://" .. id end
local TweenService = svc("TweenService")
TweenService.Create = function(_, obj, info, props)
	local tw = M.make("Tween")
	tw.Play = function() for k, v in props do obj[k] = v end task.delay(info[1] or 0, function() tw.Completed:Fire(Enum.PlaybackState.Completed) end) end
	tw.Cancel = function() end
	return tw
end
local UIS = svc("UserInputService")
UIS.GetFocusedTextBox = function() return nil end
local Sound = svc("SoundService"); Sound.PlayLocalSound = function() end
local services = { Players = Players, ReplicatedStorage = rs, TweenService = TweenService, UserInputService = UIS, SoundService = Sound }
game = { GetService = function(_, n) return assert(services[n], n) end }
local cam = svc("Camera"); cam.ViewportSize = Vector2.new(1366, 768)
workspace = { CurrentCamera = cam }

CLIENT()
M.run(1)

local gui = playerGui:FindFirstChild("AuraPhone")
assert(gui, "no gui")
local function find(pred) for _, o in M.all do if not rawget(o, "__props").__destroyed and pred(o) then return o end end end
local function labelBtn(txt) local l = find(function(o) return o.__class == "TextLabel" and o.Text == txt and o.Parent.__class == "TextButton" end); assert(l, "no label " .. txt); return l.Parent end
local function tap(b) assert(b, "nil button"); b.Activated:Fire(); M.run(0.6); local e = M.errors(); if #e > 0 then print("ERR", e[1]); error("stop") end end
local phone = gui:FindFirstChild("Phone")
local screen = phone:FindFirstChild("Screen")
local pages = screen:FindFirstChild("Pages")
local function visiblePages() local v = {} for _, p in pages:GetChildren() do if p.Visible then table.insert(v, p.Name) end end table.sort(v) return table.concat(v, ",") end

tap(gui:FindFirstChild("PhoneButton"))
print("opened; phone visible", phone.Visible, "pages:", visiblePages())
local lock = pages:FindFirstChild("lock")
local lockBtn; for _, c in lock:GetChildren() do if c.__class == "TextButton" then lockBtn = c end end
tap(lockBtn)
print("after unlock:", visiblePages())
local grid = find(function(o) return o.__class == "Frame" and o:FindFirstChild("messages") and o:FindFirstChild("messages").__class == "TextButton" end)
for _, id in { "messages", "contacts", "send", "wallet", "settings" } do
	tap(grid:FindFirstChild(id))
	print("open", id, "->", visiblePages())
	tap(screen:FindFirstChild("HomeBar"))
end
-- incoming message while on home
Event.OnClientEvent:Fire("Message", 2, "hi there!")
M.run(4)
-- open chat from contacts
tap(grid:FindFirstChild("contacts"))
local msgBtn = find(function(o) return o.__class == "TextLabel" and o.Text == "💬" and o.Parent.Parent and o.Parent.Parent.Parent and o.Parent.Parent.Parent.Name == "ScrollingFrame" end)
tap(msgBtn.Parent)
print("chat:", visiblePages())
local box = find(function(o) return o.__class == "TextBox" and o.PlaceholderText == "Message" end)
box.Text = "hello bad word"
box.FocusLost:Fire(true)
M.run(1)
local bubbles = 0
for _, o in M.all do if o.__class == "TextLabel" and (o.Text == "hello ### word" or o.Text == "hi there!") and not o.__props.__destroyed then bubbles += 1 end end
print("bubbles with filtered text:", bubbles)
-- send robux from chat header
tap(find(function(o) return o.__class == "TextLabel" and o.Text == "💸" and o.Parent.__class == "TextButton" and o.Parent.Parent.Parent and o.Parent.Parent.Parent.Name == "chat" end).Parent)
M.run(1)
print("sendTo:", visiblePages(), "price buttons:", find(function(o) return o.__class == "TextLabel" and o.Text == "R$ 5" end) ~= nil, find(function(o) return o.__class == "TextLabel" and o.Text == "Sent ✓" end) ~= nil)
tap(labelBtn("R$ 5"))
M.run(4)
-- back twice
tap(find(function(o) return o.__class == "TextButton" and o.Parent and o.Parent.Name == "Header" and o.Parent.Parent and o.Parent.Parent.Name == "sendTo" end))
print("after back:", visiblePages())
-- wallet add
tap(screen:FindFirstChild("HomeBar"))
tap(grid:FindFirstChild("wallet"))
local addBox = find(function(o) return o.__class == "TextBox" and o.PlaceholderText == "Paste pass link or ID" end)
addBox.Text = "https://www.roblox.com/game-pass/123456/Tip"
tap(labelBtn("Add"))
M.run(4)
print("wallet passes:", find(function(o) return o.__class == "TextLabel" and o.Text == "MY PASSES (2)" end) ~= nil)
tap(labelBtn("✕"))
M.run(1)
-- money events
Event.OnClientEvent:Fire("Received", 2, 25)
Event.OnClientEvent:Fire("Sent", 2, 5)
Event.OnClientEvent:Fire("Shoutout", 2, 3, 10)
M.run(8)
print("received widget:", find(function(o) return o.__class == "TextLabel" and o.Text == "R$ 145" end) ~= nil)
-- settings wallpaper
tap(screen:FindFirstChild("HomeBar"))
tap(grid:FindFirstChild("settings"))
local wp = find(function(o) return o.__class == "TextButton" and o.LayoutOrder == 6 and o.Parent and o.Parent.__class == "Frame" and o.Parent.Parent and o.Parent.Parent.__class == "Frame" end)
tap(wp)
-- close with P, then message arrives -> toast + badge
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.P }, false)
M.run(1)
print("closed; phone visible", phone.Visible)
Event.OnClientEvent:Fire("Message", 2, "you there?")
M.run(1)
print("badge visible:", gui.PhoneButton:GetChildren()[4] and true, find(function(o) return o.__class == "TextLabel" and o.Text == "you there?" end) ~= nil)
-- player leaves while phone open
tap(gui:FindFirstChild("PhoneButton"))
table.remove(list, 2)
Players.PlayerRemoving:Fire(other)
M.run(10)
print("server calls:", table.concat(fakeCalls, ","))
local errs = M.errors()
print("RUNTIME ERRORS:", #errs)
for _, e in errs do print(e) end
