--!nonstrict
-- Catalog avatar editor backend: try on / take off any catalog item or bundle,
-- body colours & scales, undo snapshots, saved outfits, copy someone's look.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local AssetService = game:GetService("AssetService")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AvatarTypes = require(ReplicatedStorage.Shared.AvatarTypes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local AvatarService = {}
local DataService -- injected

local infoCache = {}
local bundleCache = {}
local lastSnap = {} :: { [Player]: any }
local busy = {} :: { [Player]: boolean }
local originals = {}
local rate = {}

local MAX_RIGID = 14

function AvatarService.GetInfo(assetId: number)
	if typeof(assetId) ~= "number" or assetId <= 0 or assetId ~= assetId then
		return nil
	end
	assetId = math.floor(assetId)
	local c = infoCache[assetId]
	if c ~= nil then
		return c or nil
	end
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Asset)
	end)
	if ok and info then
		infoCache[assetId] = info
		return info
	end
	return nil
end

function AvatarService.GetBundle(bundleId: number)
	if bundleCache[bundleId] ~= nil then
		return bundleCache[bundleId] or nil
	end
	local ok, details = pcall(function()
		return AssetService:GetBundleDetailsAsync(bundleId)
	end)
	bundleCache[bundleId] = ok and details or false
	return ok and details or nil
end

local function humanoidOf(player: Player): Humanoid?
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function currentDesc(player: Player): HumanoidDescription?
	local hum = humanoidOf(player)
	if not hum then
		return nil
	end
	local ok, desc = pcall(function()
		return hum:GetAppliedDescription()
	end)
	return ok and desc or nil
end
AvatarService.CurrentDesc = currentDesc

-- ---------- snapshots (plain tables that can be saved / sent) ----------
local COLOR_PROPS = { "HeadColor", "TorsoColor", "LeftArmColor", "RightArmColor", "LeftLegColor", "RightLegColor" }
local SCALE_PROPS = { "HeightScale", "WidthScale", "DepthScale", "HeadScale", "BodyTypeScale", "ProportionScale" }

function AvatarService.Serialize(desc: HumanoidDescription)
	local snap = { A = {}, P = {}, S = {}, C = {} }
	for _, a in desc:GetAccessories(true) do
		table.insert(snap.A, { a.AssetId, a.AccessoryType.Name, a.IsLayered and true or false, a.Order })
	end
	for _, prop in AvatarTypes.SingleProps do
		local v = desc[prop]
		if typeof(v) == "number" and v ~= 0 then
			snap.P[prop] = v
		end
	end
	for _, prop in SCALE_PROPS do
		local v = desc[prop]
		if typeof(v) == "number" then
			snap.S[prop] = v
		end
	end
	for _, prop in COLOR_PROPS do
		local c = desc[prop]
		if typeof(c) == "Color3" then
			snap.C[prop] = c:ToHex()
		end
	end
	return snap
end

function AvatarService.Deserialize(snap): HumanoidDescription?
	if typeof(snap) ~= "table" then
		return nil
	end
	local desc = Instance.new("HumanoidDescription")
	local accs = {}
	if typeof(snap.A) == "table" then
		for i, a in snap.A do
			if i > 40 then
				break
			end
			if typeof(a) == "table" and typeof(a[1]) == "number" and typeof(a[2]) == "string" then
				local ok, accType = pcall(function()
					return (Enum.AccessoryType :: any)[a[2]]
				end)
				if ok and accType then
					table.insert(accs, {
						AssetId = math.floor(a[1]),
						AccessoryType = accType,
						IsLayered = a[3] == true,
						Order = (a[3] == true and typeof(a[4]) == "number") and math.clamp(math.floor(a[4]), 0, 20) or nil,
					})
				end
			end
		end
	end
	pcall(function()
		desc:SetAccessories(accs, true)
	end)
	if typeof(snap.P) == "table" then
		for _, prop in AvatarTypes.SingleProps do
			local v = snap.P[prop]
			if typeof(v) == "number" and v > 0 then
				desc[prop] = math.floor(v)
			end
		end
	end
	if typeof(snap.S) == "table" then
		for _, prop in SCALE_PROPS do
			local v = snap.S[prop]
			local lim = AvatarTypes.ScaleLimits[prop]
			if typeof(v) == "number" and lim then
				desc[prop] = math.clamp(v, lim[1], lim[2])
			end
		end
	end
	if typeof(snap.C) == "table" then
		for _, prop in COLOR_PROPS do
			local v = snap.C[prop]
			if typeof(v) == "string" and #v == 6 then
				local ok, c = pcall(Color3.fromHex, v)
				if ok then
					desc[prop] = c
				end
			end
		end
	end
	return desc
end

-- Worn list for the UI
function AvatarService.WornList(desc: HumanoidDescription?)
	local list = {}
	if not desc then
		return list
	end
	for _, a in desc:GetAccessories(true) do
		table.insert(list, { Id = a.AssetId, Type = a.AccessoryType.Name, Slot = "acc" })
	end
	for _, prop in AvatarTypes.SingleProps do
		local v = desc[prop]
		if typeof(v) == "number" and v ~= 0 then
			table.insert(list, { Id = v, Type = AvatarTypes.PropTypeName[prop] or prop, Slot = "prop", Prop = prop })
		end
	end
	return list
end

local function apply(player: Player, desc: HumanoidDescription): boolean
	local hum = humanoidOf(player)
	if not hum then
		return false
	end
	local waited = 0
	while busy[player] and waited < 8 do
		waited += task.wait(0.1)
	end
	busy[player] = true
	local ok, err = pcall(function()
		hum:ApplyDescription(desc)
	end)
	busy[player] = nil
	if not ok then
		warn("[Avatar] ApplyDescription failed:", err)
		return false
	end
	lastSnap[player] = AvatarService.Serialize(desc)
	player:SetAttribute("OutfitVersion", (player:GetAttribute("OutfitVersion") or 0) + 1)
	return true
end
AvatarService.Apply = apply

local function accSpec(assetId: number, t)
	return {
		AssetId = assetId,
		AccessoryType = (Enum.AccessoryType :: any)[t.Acc],
		IsLayered = t.Layered == true,
		Order = t.Layered and t.Order or nil,
	}
end

-- Adds an asset to a description (replacing same-slot items). Returns false if not wearable.
function AvatarService.AddToDesc(desc: HumanoidDescription, assetId: number, forceOn: boolean?): (boolean, string?)
	local info = AvatarService.GetInfo(assetId)
	if not info then
		return false, "Couldn't load that item."
	end
	local t = AvatarTypes.ById[info.AssetTypeId]
	if not t then
		return false, "That item type can't be worn here."
	end
	if t.Kind == "acc" then
		local accs = desc:GetAccessories(true)
		local foundIdx
		local rigid = 0
		for i, a in accs do
			if a.AssetId == assetId then
				foundIdx = i
			end
			if not a.IsLayered then
				rigid += 1
			end
		end
		if foundIdx then
			if forceOn then
				return true
			end
			table.remove(accs, foundIdx)
		else
			if t.Layered then
				for i = #accs, 1, -1 do
					if accs[i].AccessoryType.Name == t.Acc then
						table.remove(accs, i)
					end
				end
			elseif rigid >= MAX_RIGID then
				return false, "Too many accessories! Take something off first."
			end
			table.insert(accs, accSpec(assetId, t))
		end
		desc:SetAccessories(accs, true)
	else
		if desc[t.Prop] == assetId and not forceOn then
			desc[t.Prop] = 0
		else
			desc[t.Prop] = assetId
		end
	end
	return true
end

function AvatarService.IsWearing(desc: HumanoidDescription, assetId: number): boolean
	for _, a in desc:GetAccessories(true) do
		if a.AssetId == assetId then
			return true
		end
	end
	for _, prop in AvatarTypes.SingleProps do
		if desc[prop] == assetId then
			return true
		end
	end
	return false
end

local function bundleAssets(details)
	local ids, outfitId = {}, nil
	for _, item in details.Items or {} do
		if item.Type == "Asset" then
			table.insert(ids, item.Id)
		elseif item.Type == "UserOutfit" then
			outfitId = item.Id
		end
	end
	return ids, outfitId
end

function AvatarService.ToggleBundle(player: Player, bundleId: number)
	local details = AvatarService.GetBundle(bundleId)
	if not details then
		return false, "Couldn't load that bundle."
	end
	local desc = currentDesc(player)
	if not desc then
		return false, "Character not ready."
	end
	local ids, outfitId = bundleAssets(details)
	local allWorn = #ids > 0
	for _, id in ids do
		if not AvatarService.IsWearing(desc, id) then
			allWorn = false
			break
		end
	end
	if allWorn then
		-- take the bundle off
		local accs = desc:GetAccessories(true)
		for i = #accs, 1, -1 do
			if table.find(ids, accs[i].AssetId) then
				table.remove(accs, i)
			end
		end
		desc:SetAccessories(accs, true)
		for _, prop in AvatarTypes.SingleProps do
			if table.find(ids, desc[prop]) then
				desc[prop] = 0
			end
		end
	else
		local src
		if outfitId then
			local ok, od = pcall(function()
				return Players:GetHumanoidDescriptionFromOutfitId(outfitId)
			end)
			if ok then
				src = od
			end
		end
		if src then
			for _, prop in AvatarTypes.SingleProps do
				local v = src[prop]
				if typeof(v) == "number" and v ~= 0 then
					desc[prop] = v
				end
			end
			local accs = desc:GetAccessories(true)
			for _, a in src:GetAccessories(true) do
				local dup = false
				for _, b in accs do
					if b.AssetId == a.AssetId then
						dup = true
					end
				end
				if not dup then
					if a.IsLayered then
						for i = #accs, 1, -1 do
							if accs[i].AccessoryType == a.AccessoryType then
								table.remove(accs, i)
							end
						end
					end
					table.insert(accs, a)
				end
			end
			desc:SetAccessories(accs, true)
		else
			for _, id in ids do
				AvatarService.AddToDesc(desc, id, true)
			end
		end
	end
	return apply(player, desc)
end

function AvatarService.Original(player: Player): HumanoidDescription?
	if originals[player.UserId] then
		return originals[player.UserId]:Clone()
	end
	local ok, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(math.max(player.UserId, 1))
	end)
	if ok and desc then
		originals[player.UserId] = desc
		return desc:Clone()
	end
	return nil
end

-- Builds a mannequin description from a list of asset ids (for stalls)
function AvatarService.DescriptionFromIds(ids: { number }): HumanoidDescription
	local desc = Instance.new("HumanoidDescription")
	local ivory = Color3.fromHex("F3EDE6")
	for _, prop in COLOR_PROPS do
		desc[prop] = ivory
	end
	for _, id in ids do
		pcall(AvatarService.AddToDesc, desc, id, true)
	end
	return desc
end

local function filterForUser(text: string, userId: number): string?
	local ok, res = pcall(function()
		local f = TextService:FilterStringAsync(text, userId, Enum.TextFilterContext.PrivateChat)
		return f:GetNonChatStringForUserAsync(userId)
	end)
	return ok and res or nil
end

local function reply(player: Player, ok: boolean, msg: string?)
	local desc = currentDesc(player)
	return { ok = ok, msg = msg, worn = AvatarService.WornList(desc), snap = desc and AvatarService.Serialize(desc) or nil }
end

function AvatarService.Handle(player: Player, action: string, a, b)
	-- rate limit
	local now = os.clock()
	local r = rate[player]
	if not r or now - r.t > 1 then
		rate[player] = { t = now, n = 0 }
		r = rate[player]
	end
	r.n += 1
	if r.n > 10 then
		return reply(player, false, "Slow down a little!")
	end

	if action == "Get" then
		return reply(player, true)
	elseif action == "Toggle" then
		local id = tonumber(a)
		if not id then
			return reply(player, false, "Invalid item.")
		end
		local desc = currentDesc(player)
		if not desc then
			return reply(player, false, "Character not ready.")
		end
		local ok, msg = AvatarService.AddToDesc(desc, math.floor(id), b == true)
		if ok then
			ok = apply(player, desc)
		end
		return reply(player, ok, msg)
	elseif action == "ToggleBundle" then
		local id = tonumber(a)
		if not id then
			return reply(player, false, "Invalid bundle.")
		end
		local ok, msg = AvatarService.ToggleBundle(player, math.floor(id))
		return reply(player, ok, msg)
	elseif action == "Remove" then
		local desc = currentDesc(player)
		local id = tonumber(a)
		if desc and id and AvatarService.IsWearing(desc, id) then
			AvatarService.AddToDesc(desc, id, false)
			apply(player, desc)
		end
		return reply(player, true)
	elseif action == "Snapshot" then
		local desc = AvatarService.Deserialize(a)
		if not desc then
			return reply(player, false, "Invalid outfit.")
		end
		return reply(player, apply(player, desc))
	elseif action == "Reset" then
		local desc = AvatarService.Original(player)
		if desc then
			apply(player, desc)
		end
		return reply(player, desc ~= nil)
	elseif action == "Skin" then
		local desc = currentDesc(player)
		if desc and typeof(a) == "string" and #a == 6 then
			local ok, c = pcall(Color3.fromHex, a)
			if ok then
				for _, prop in COLOR_PROPS do
					desc[prop] = c
				end
				apply(player, desc)
			end
		end
		return reply(player, true)
	elseif action == "Scale" then
		local desc = currentDesc(player)
		local lim = AvatarTypes.ScaleLimits[a]
		if desc and lim and typeof(b) == "number" then
			desc[a] = math.clamp(b, lim[1], lim[2])
			apply(player, desc)
		end
		return reply(player, true)
	elseif action == "CopyLook" then
		local target = Players:GetPlayerByUserId(tonumber(a) or 0)
		local desc = target and currentDesc(target)
		if not desc then
			return reply(player, false, "That player isn't available.")
		end
		return reply(player, apply(player, desc))
	elseif action == "SaveOutfit" then
		local profile = DataService.Get(player)
		local desc = currentDesc(player)
		if not profile or not desc then
			return reply(player, false, "Not ready.")
		end
		if #profile.Outfits >= 24 then
			return reply(player, false, "Outfit slots full (24). Delete one first.")
		end
		local name = typeof(a) == "string" and a:sub(1, 30) or ""
		if name:match("^%s*$") then
			name = "Outfit " .. (#profile.Outfits + 1)
		end
		name = filterForUser(name, player.UserId) or ("Outfit " .. (#profile.Outfits + 1))
		table.insert(profile.Outfits, { Name = name, Snap = AvatarService.Serialize(desc) })
		DataService.Sync(player)
		return reply(player, true, "Outfit saved!")
	elseif action == "WearOutfit" then
		local profile = DataService.Get(player)
		local o = profile and profile.Outfits[tonumber(a) or 0]
		if not o then
			return reply(player, false, "Outfit not found.")
		end
		local desc = AvatarService.Deserialize(o.Snap)
		return reply(player, desc ~= nil and apply(player, desc))
	elseif action == "DeleteOutfit" then
		local profile = DataService.Get(player)
		local i = tonumber(a) or 0
		if profile and profile.Outfits[i] then
			table.remove(profile.Outfits, i)
			DataService.Sync(player)
		end
		return reply(player, true)
	end
	return reply(player, false, "Unknown action.")
end

function AvatarService.Init(deps)
	DataService = deps.DataService
	Remotes.Func("Avatar").OnServerInvoke = function(player, action, a, b)
		local ok, res = pcall(AvatarService.Handle, player, action, a, b)
		if not ok then
			warn("[Avatar]", res)
			return { ok = false, msg = "Something went wrong.", worn = {} }
		end
		return res
	end

	-- someone's look (for "shop the look")
	Remotes.Func("GetLook").OnServerInvoke = function(_player, userId)
		local target = Players:GetPlayerByUserId(tonumber(userId) or 0)
		if not target then
			return nil
		end
		local desc = currentDesc(target)
		return {
			UserId = target.UserId,
			Name = target.Name,
			DisplayName = target.DisplayName,
			Items = AvatarService.WornList(desc),
		}
	end

	local function onCharacter(player: Player, char: Model)
		local snap = lastSnap[player]
		if not snap then
			return
		end
		local hum = char:WaitForChild("Humanoid", 10)
		if not hum then
			return
		end
		task.wait(0.6)
		if player.Character == char then
			local desc = AvatarService.Deserialize(snap)
			if desc then
				apply(player, desc)
			end
		end
	end
	local function hook(player: Player)
		player.CharacterAdded:Connect(function(char)
			onCharacter(player, char)
		end)
	end
	Players.PlayerAdded:Connect(hook)
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		lastSnap[p] = nil
		busy[p] = nil
		rate[p] = nil
	end)
end

return AvatarService
