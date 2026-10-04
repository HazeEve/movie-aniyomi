--!strict
-- AuraPhone · server
-- Messages between players (filtered by Roblox, as the rules require), saved settings,
-- and "Send Robux": players add their OWN game passes to their phone wallet, and others
-- buy one of those passes to send them Robux (the same way donation games do it).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TextService = game:GetService("TextService")
local TextChatService = game:GetService("TextChatService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local MAX_PASSES = 12
local MAX_MESSAGE = 200
local MESSAGE_COOLDOWN = 0.6
local WALLPAPERS = 8

-- ===== remotes =====
local folder = ReplicatedStorage:FindFirstChild("AuraPhoneRemotes") or Instance.new("Folder")
folder.Name = "AuraPhoneRemotes"
folder.Parent = ReplicatedStorage
local function remote(class: string, name: string): Instance
	local r = folder:FindFirstChild(name)
	if not r then
		r = Instance.new(class)
		r.Name = name
		r.Parent = folder
	end
	return r :: Instance
end
local Fn = remote("RemoteFunction", "Fn") :: RemoteFunction
local Event = remote("RemoteEvent", "Event") :: RemoteEvent

-- ===== saved data =====
local okStore, store = pcall(function()
	return DataStoreService:GetDataStore("AuraPhone_v1")
end)
if not okStore then
	warn("[AuraPhone] Saving is off. In Studio: Game Settings > Security > Enable Studio Access to API Services.")
end

type Data = { passes: { number }, wallpaper: number, received: number, sent: number }
local data: { [Player]: Data } = {}
local dirty: { [Player]: boolean } = {}

local function blank(): Data
	return { passes = {}, wallpaper = 1, received = 0, sent = 0 }
end

local function load(plr: Player)
	local d = blank()
	if okStore then
		for _ = 1, 3 do
			local ok, saved = pcall(function()
				return store:GetAsync("u" .. plr.UserId)
			end)
			if ok then
				if type(saved) == "table" then
					d.passes = if type(saved.passes) == "table" then saved.passes else {}
					d.wallpaper = tonumber(saved.wallpaper) or 1
					d.received = tonumber(saved.received) or 0
					d.sent = tonumber(saved.sent) or 0
				end
				break
			end
			task.wait(1)
		end
	end
	data[plr] = d
end

local function save(plr: Player)
	local d = data[plr]
	if not (okStore and d and dirty[plr]) then
		return
	end
	dirty[plr] = nil
	pcall(function()
		store:SetAsync("u" .. plr.UserId, d)
	end)
end

-- ===== game pass info (cached) =====
type PassInfo = { id: number, name: string, price: number, forSale: boolean, icon: number, creator: number }
local passCache: { [number]: { at: number, info: PassInfo? } } = {}

local function passInfo(id: number): PassInfo?
	local c = passCache[id]
	if c and os.clock() - c.at < 60 then
		return c.info
	end
	local ok, info = pcall(function()
		local mps = MarketplaceService :: any
		if mps.GetProductInfoAsync then
			return mps:GetProductInfoAsync(id, Enum.InfoType.GamePass)
		end
		return MarketplaceService:GetProductInfo(id, Enum.InfoType.GamePass)
	end)
	local out: PassInfo? = nil
	if ok and type(info) == "table" then
		local creator = info.Creator or {}
		out = {
			id = id,
			name = tostring(info.Name or "Game Pass"),
			price = tonumber(info.PriceInRobux) or 0,
			forSale = info.IsForSale == true and (tonumber(info.PriceInRobux) or 0) > 0,
			icon = tonumber(info.IconImageAssetId) or 0,
			creator = tonumber(creator.CreatorTargetId) or tonumber(creator.Id) or 0,
		}
	end
	passCache[id] = { at = os.clock(), info = out }
	return out
end

local function passesOf(plr: Player): { PassInfo }
	local d = data[plr]
	local list = {}
	if not d then
		return list
	end
	for _, id in d.passes do
		local info = passInfo(id)
		if info and info.forSale and info.creator == plr.UserId then
			table.insert(list, info)
		end
	end
	table.sort(list, function(a, b)
		return a.price < b.price
	end)
	return list
end

-- ===== chat permission + filtering =====
local function canChat(a: Player, b: Player): boolean
	if RunService:IsStudio() then
		return true -- Studio test players
	end
	local ok, allowed = pcall(function()
		return TextChatService:CanUsersDirectChatAsync(a.UserId, { b.UserId })
	end)
	if ok and type(allowed) == "table" then
		return table.find(allowed, b.UserId) ~= nil
	end
	local ok2, can = pcall(function()
		return (game:GetService("Chat") :: Chat):CanUsersChatAsync(a.UserId, b.UserId)
	end)
	return ok2 and can == true
end

local function filterFor(text: string, from: Player, to: Player): string?
	local ok, result = pcall(function()
		local f = TextService:FilterStringAsync(text, from.UserId, Enum.TextFilterContext.PrivateChat)
		return f:GetChatForUserAsync(to.UserId)
	end)
	return if ok then result else nil
end

-- ===== requests =====
local lastMessage: { [Player]: number } = {}
local pending: { [Player]: { to: Player, pass: number, price: number } } = {}

local function playerById(id: any): Player?
	if type(id) ~= "number" then
		return nil
	end
	return Players:GetPlayerByUserId(id)
end

local handlers: { [string]: (Player, ...any) -> (any, any) } = {}

function handlers.GetMe(plr)
	local d = data[plr]
	while not d and plr.Parent do
		task.wait(0.1)
		d = data[plr]
	end
	if not d then
		return nil
	end
	return { wallpaper = d.wallpaper, received = d.received, sent = d.sent, passes = passesOf(plr), saving = okStore }
end

function handlers.AddPass(plr, raw)
	local d = data[plr]
	if not d then
		return false, "Phone is still loading."
	end
	local id = tonumber(string.match(tostring(raw or ""), "(%d%d%d+)"))
	if not id then
		return false, "Paste your game pass link or ID."
	end
	if table.find(d.passes, id) then
		return false, "That pass is already in your wallet."
	end
	if #d.passes >= MAX_PASSES then
		return false, "Your wallet is full (" .. MAX_PASSES .. " passes)."
	end
	passCache[id] = nil
	local info = passInfo(id)
	if not info then
		return false, "Couldn't find that game pass. Check the ID."
	end
	if info.creator ~= plr.UserId then
		return false, "That pass isn't yours. Use a pass YOU made."
	end
	if not info.forSale then
		return false, "Put the pass on sale with a price first."
	end
	table.insert(d.passes, id)
	dirty[plr] = true
	task.spawn(save, plr)
	return true, passesOf(plr)
end

function handlers.RemovePass(plr, id)
	local d = data[plr]
	local i = if d and type(id) == "number" then table.find(d.passes, id) else nil
	if d and i then
		table.remove(d.passes, i)
		dirty[plr] = true
		task.spawn(save, plr)
	end
	return passesOf(plr)
end

function handlers.GetPasses(plr, userId)
	local target = playerById(userId)
	if not target or target == plr then
		return {}
	end
	local list = passesOf(target)
	for _, p in list do
		local okOwn, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, plr.UserId, p.id)
		;(p :: any).owned = okOwn and owns or false
	end
	return list
end

function handlers.Gift(plr, userId, passId)
	local target = playerById(userId)
	if target == plr then
		return false, "You can't send Robux to yourself."
	end
	if not target or type(passId) ~= "number" then
		return false, "That player left."
	end
	local d = data[target]
	if not (d and table.find(d.passes, passId)) then
		return false, "That pass isn't in their wallet anymore."
	end
	local info = passInfo(passId)
	if not (info and info.forSale and info.creator == target.UserId) then
		return false, "That pass isn't on sale right now."
	end
	local okOwn, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, plr.UserId, passId)
	if okOwn and owns then
		return false, "You already sent this one. Each pass can only be bought once — pick another amount."
	end
	pending[plr] = { to = target, pass = passId, price = info.price }
	MarketplaceService:PromptGamePassPurchase(plr, passId)
	return true
end

function handlers.Message(plr, userId, text)
	local target = playerById(userId)
	if not target or target == plr or type(text) ~= "string" then
		return false, "They're not in this server."
	end
	local trimmed = string.gsub(text, "^%s+", "")
	text = string.sub(trimmed, 1, MAX_MESSAGE)
	if #text == 0 then
		return false, nil
	end
	local now = os.clock()
	if now - (lastMessage[plr] or 0) < MESSAGE_COOLDOWN then
		return false, "Slow down a little!"
	end
	lastMessage[plr] = now
	if not canChat(plr, target) then
		return false, "You can't message this player (chat settings)."
	end
	local toThem = filterFor(text, plr, target)
	local toMe = filterFor(text, plr, plr)
	if not (toThem and toMe) then
		return false, "Message couldn't be sent. Try again."
	end
	Event:FireClient(target, "Message", plr.UserId, toThem)
	return true, toMe
end

function handlers.Wallpaper(plr, n)
	local d = data[plr]
	if d and type(n) == "number" and n >= 1 and n <= WALLPAPERS and n % 1 == 0 then
		d.wallpaper = n
		dirty[plr] = true
	end
	return true
end

Fn.OnServerInvoke = function(plr: Player, kind: any, ...: any)
	local h = if type(kind) == "string" then handlers[kind] else nil
	if not h then
		return nil
	end
	local ok, a, b = pcall(h, plr, ...)
	if not ok then
		warn("[AuraPhone]", kind, a)
		return false, "Something went wrong. Try again."
	end
	return a, b
end

-- ===== purchases =====
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr: Player, passId: number, bought: boolean)
	local p = pending[plr]
	if not p or p.pass ~= passId then
		return
	end
	pending[plr] = nil
	if not bought then
		return
	end
	local fromData = data[plr]
	if fromData then
		fromData.sent += p.price
		dirty[plr] = true
	end
	local toData = p.to.Parent and data[p.to]
	if toData then
		toData.received += p.price
		dirty[p.to] = true
	end
	Event:FireClient(plr, "Sent", p.to.UserId, p.price)
	if p.to.Parent then
		Event:FireClient(p.to, "Received", plr.UserId, p.price)
	end
	Event:FireAllClients("Shoutout", plr.UserId, p.to.UserId, p.price)
end)

-- ===== join / leave =====
Players.PlayerAdded:Connect(load)
for _, plr in Players:GetPlayers() do
	task.spawn(load, plr)
end
Players.PlayerRemoving:Connect(function(plr)
	save(plr)
	data[plr], dirty[plr], pending[plr], lastMessage[plr] = nil, nil, nil, nil
end)
game:BindToClose(function()
	for _, plr in Players:GetPlayers() do
		task.spawn(save, plr)
	end
	task.wait(2)
end)
task.spawn(function()
	while true do
		task.wait(60)
		for plr in dirty do
			task.spawn(save, plr)
		end
	end
end)
