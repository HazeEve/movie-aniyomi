local M = MOCK
local function svc(name, props) local s = M.make(name, props); s.Name = name; return s end
local rs = svc("ReplicatedStorage")
local a = svc("Player", { UserId = 1, Name = "a", DisplayName = "A", Parent = true })
local b = svc("Player", { UserId = 2, Name = "b", DisplayName = "B", Parent = true })
local list = { a, b }
local Players = svc("Players")
Players.GetPlayers = function() return table.clone(list) end
Players.GetPlayerByUserId = function(_, id) for _, p in list do if p.UserId == id then return p end end return nil end
local owned = {}
local MPS = svc("MarketplaceService")
local passDb = { [5001] = { Name = "Tip 5", PriceInRobux = 5, IsForSale = true, IconImageAssetId = 0, Creator = { CreatorTargetId = 2, Id = 2 } },
	[5002] = { Name = "Not mine", PriceInRobux = 10, IsForSale = true, Creator = { CreatorTargetId = 99 } },
	[5003] = { Name = "Off sale", PriceInRobux = 10, IsForSale = false, Creator = { CreatorTargetId = 2 } } }
MPS.GetProductInfoAsync = function(_, id) task.wait(0.05); return assert(passDb[id], "HTTP 404") end
MPS.UserOwnsGamePassAsync = function(_, uid, id) return owned[uid .. ":" .. id] == true end
MPS.PromptGamePassPurchase = function(_, plr, id)
	task.delay(1, function() owned[plr.UserId .. ":" .. id] = true; MPS.PromptGamePassPurchaseFinished:Fire(plr, id, true) end)
end
local TS = svc("TextService")
TS.FilterStringAsync = function(_, t) return { GetChatForUserAsync = function(_, uid) return (string.gsub(t, "bad", "###")) end } end
local TCS = svc("TextChatService")
TCS.CanUsersDirectChatAsync = function(_, from, ids) return ids end
local saved = {}
local DSS = svc("DataStoreService")
DSS.GetDataStore = function() return { GetAsync = function(_, k) return saved[k] end, SetAsync = function(_, k, v) saved[k] = table.clone(v) end } end
local Run = svc("RunService"); Run.IsStudio = function() return false end
local services = { Players = Players, ReplicatedStorage = rs, MarketplaceService = MPS, TextService = TS, TextChatService = TCS, DataStoreService = DSS, RunService = Run }
local fired = {}
game = { GetService = function(_, n) return assert(services[n], n) end, BindToClose = function() end }
SERVER()
M.run(1)
local folder = rs:FindFirstChild("AuraPhoneRemotes")
local Fn, Ev = folder.Fn, folder.Event
Ev.FireClient = function(_, plr, ...) table.insert(fired, plr.Name .. ":" .. table.concat({ ... }, "|")) end
Ev.FireAllClients = function(_, ...) table.insert(fired, "ALL:" .. table.concat({ ... }, "|")) end
local function inv(plr, ...)
	local co = coroutine.create(function(...) return Fn.OnServerInvoke(plr, ...) end)
	local res
	task.spawn(function(...) res = table.pack(Fn.OnServerInvoke(plr, ...)) end, ...)
	M.run(2)
	return table.unpack(res, 1, res.n)
end
for _, p in list do Players.PlayerAdded:Fire(p) end
M.run(1)
print("GetMe", inv(a, "GetMe").wallpaper)
print("AddPass not mine:", inv(b, "AddPass", "5002"))
print("AddPass off sale:", inv(b, "AddPass", "5003"))
print("AddPass garbage:", inv(b, "AddPass", "hello"))
local ok, l = inv(b, "AddPass", "https://www.roblox.com/game-pass/5001/Tip-5")
print("AddPass link:", ok, l and #l)
print("AddPass dup:", inv(b, "AddPass", "5001"))
local ps = inv(a, "GetPasses", 2)
print("A sees B passes:", #ps, ps[1].price, ps[1].owned)
print("Gift self:", inv(b, "Gift", 2, 5001))
print("Gift:", inv(a, "Gift", 2, 5001))
M.run(3)
print("fired:", table.concat(fired, " / "))
print("Gift again:", inv(a, "Gift", 2, 5001))
print("Message:", inv(a, "Message", 2, "  hi bad guy"))
print("Message spam:", inv(a, "Message", 2, "again"))
M.run(1)
print("Message to self:", inv(a, "Message", 1, "x"))
print("Message wrong types:", inv(a, "Message", "2", {}))
print("Unknown:", inv(a, "Nope"))
print("Wallpaper bad:", inv(a, "Wallpaper", 99), "good:", inv(a, "Wallpaper", 4))
Players.PlayerRemoving:Fire(a)
Players.PlayerRemoving:Fire(b)
M.run(1)
print("saved a:", saved.u1 and saved.u1.sent, saved.u1 and saved.u1.wallpaper, "saved b:", saved.u2 and saved.u2.received, saved.u2 and #saved.u2.passes)
print("RUNTIME ERRORS:", #M.errors())
for _, e in M.errors() do print(e) end
