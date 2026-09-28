--!nonstrict
-- Mall stalls: players rent a stall with coins, name their shop, and list their
-- own UGC / clothing. Items appear on display frames + a mannequin wearing them.
-- Anyone can buy (real Roblox purchase prompt) or try items on.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TextService = game:GetService("TextService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Palette = require(ReplicatedStorage.Shared.Palette)
local AvatarTypes = require(ReplicatedStorage.Shared.AvatarTypes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Util = require(script.Parent.Util)

local StallService = {}
local DataService, AvatarService

local stalls = {} :: { [string]: any }
local creatorStore
pcall(function()
	creatorStore = DataStoreService:GetDataStore(Config.DataStoreName .. "_Creator")
end)

StallService.Themes = {
	Lavender = Palette.Lavender,
	Blush = Palette.Blush,
	Rose = Palette.Rose,
	Sage = Palette.Sage,
	Champagne = Palette.Champagne,
	Powder = Palette.Powder,
	Mint = Palette.Mint,
	Plum = Palette.Dusk,
}

local function creatorId(): number
	if Config.CreatorUserId and Config.CreatorUserId ~= 0 then
		return Config.CreatorUserId
	end
	if game.CreatorType == Enum.CreatorType.User then
		return game.CreatorId
	end
	return -1
end
StallService.CreatorId = creatorId

local function ownsStall(player: Player)
	for _, s in stalls do
		if s.OwnerId == player.UserId and not s.IsCreator then
			return s
		end
	end
	return nil
end

local function canManage(player: Player, s): boolean
	if s.IsCreator then
		if player.UserId == creatorId() or RunService:IsStudio() then
			return true
		end
		if game.CreatorType == Enum.CreatorType.Group then
			local ok, rank = pcall(function()
				local okA, r = pcall(function()
					return (player :: any):GetRankInGroupAsync(game.CreatorId)
				end)
				if okA then
					return r
				end
				return player:GetRankInGroup(game.CreatorId)
			end)
			return ok and rank >= 254
		end
		return false
	end
	return s.OwnerId == player.UserId
end

local function itemInfo(id: number)
	local info = AvatarService.GetInfo(id)
	if not info then
		return { Id = id, Name = "Item", Price = 0, Type = "" }
	end
	local t = AvatarTypes.ById[info.AssetTypeId]
	return {
		Id = id,
		Name = info.Name or "Item",
		Price = info.PriceInRobux or 0,
		ForSale = info.IsForSale == true,
		Type = t and t.Name or "",
		Creator = info.Creator and info.Creator.Name or "",
	}
end

local function setTheme(s, themeName: string?)
	local col = StallService.Themes[themeName or ""] or (s.IsCreator and Palette.Gold or Palette.Lavender)
	s.Theme = themeName
	for _, d in s.Model:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name == "Awning" or d.Name == "ThemeStripe" then
				d.Color = col
			elseif d.Name == "ThemePad" then
				d.Color = col:Lerp(Palette.Ivory, 0.55)
			end
		end
	end
end

local function buildMannequins(s)
	s.MannequinToken = (s.MannequinToken or 0) + 1
	local token = s.MannequinToken
	task.delay(0.4, function()
		if s.MannequinToken ~= token then
			return
		end
		for _, m in s.Mannequins do
			m:Destroy()
		end
		s.Mannequins = {}
		if #s.Items == 0 then
			return
		end
		local spots = {}
		for _, d in s.Model:GetChildren() do
			if d.Name:match("^MannequinSpot") then
				table.insert(spots, d)
			end
		end
		table.sort(spots, function(a, b)
			return a.Name < b.Name
		end)
		local groups = {}
		for i, id in s.Items do
			local g = ((i - 1) % #spots) + 1
			groups[g] = groups[g] or {}
			table.insert(groups[g], id)
		end
		for i, spot in spots do
			local ids = groups[i]
			if ids then
				local ok, model = pcall(function()
					local desc = AvatarService.DescriptionFromIds(ids)
					return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
				end)
				if ok and model and s.MannequinToken == token then
					model.Name = "Mannequin"
					local hum = model:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
						hum.PlatformStand = true
					end
					local root = model:FindFirstChild("HumanoidRootPart")
					if root then
						root.Anchored = true
						local pr = Instance.new("ProximityPrompt")
						pr.ActionText = "Try This Look"
						pr.ObjectText = "Mannequin"
						pr.MaxActivationDistance = 8
						pr.RequiresLineOfSight = false
						pr.KeyboardKeyCode = Enum.KeyCode.R
						pr.Parent = root
						pr.Triggered:Connect(function(player)
							local desc = AvatarService.CurrentDesc(player)
							if desc then
								for _, id in ids do
									AvatarService.AddToDesc(desc, id, true)
								end
								AvatarService.Apply(player, desc)
								Util.Notify(player, "Trying on the mannequin's look ✨", "success")
							end
						end)
					end
					model:PivotTo(spot.CFrame)
					model.Parent = s.Model
					table.insert(s.Mannequins, model)
				end
			end
		end
	end)
end

local function refresh(s)
	local m = s.Model
	local vacant = not s.IsCreator and s.OwnerId == 0
	-- sign
	for _, d in m:GetDescendants() do
		if d.Name == "ShopName" and d:IsA("TextLabel") then
			d.Text = vacant and "For Rent" or s.Name
		end
	end
	-- counter prompt
	local prompt = s.Prompt
	if prompt then
		prompt.ActionText = vacant and "Rent Stall" or "Shop"
		prompt.ObjectText = vacant and ("✨ %d Sparkles / %d min"):format(Config.Stalls.RentCost, Config.Stalls.RentMinutes) or s.Name
	end
	-- slots
	local slots = m:FindFirstChild("Slots")
	if slots then
		for _, slot in slots:GetChildren() do
			local idx = slot:GetAttribute("Index")
			local id = s.Items[idx]
			local gui = slot:FindFirstChildOfClass("SurfaceGui")
			local bg = gui and gui:FindFirstChild("Bg")
			local pr = slot:FindFirstChild("BuyPrompt")
			if id then
				local info = itemInfo(id)
				slot:SetAttribute("AssetId", id)
				if bg then
					bg.Thumb.Image = ("rbxthumb://type=Asset&id=%d&w=150&h=150"):format(id)
					bg.Label.Text = ("%s\n%s"):format(info.Name, info.ForSale and (info.Price > 0 and ("R$ " .. info.Price) or "Free") or "Off Sale")
				end
				if pr then
					pr.Enabled = true
					pr.ObjectText = info.Name
					pr.ActionText = "Buy"
				end
			else
				slot:SetAttribute("AssetId", nil)
				if bg then
					bg.Thumb.Image = ""
					bg.Label.Text = vacant and "" or "EMPTY"
				end
				if pr then
					pr.Enabled = false
				end
			end
		end
	end
	m:SetAttribute("OwnerId", s.OwnerId)
	m:SetAttribute("OwnerName", s.OwnerName)
	m:SetAttribute("ShopName", s.Name)
	m:SetAttribute("ExpiresAt", s.ExpiresAt)
	buildMannequins(s)
end

local function vacate(s, reason: string?)
	local owner = Players:GetPlayerByUserId(s.OwnerId)
	s.OwnerId = 0
	s.OwnerName = ""
	s.Name = ""
	s.Items = {}
	s.ExpiresAt = 0
	setTheme(s, nil)
	refresh(s)
	if owner and reason then
		Util.Notify(owner, reason, "info")
	end
end

local function saveCreator(s)
	if not creatorStore then
		return
	end
	task.spawn(function()
		pcall(function()
			creatorStore:SetAsync("CreatorStall", { Name = s.Name, Items = s.Items, Theme = s.Theme })
		end)
	end)
end

local function persistShop(player: Player, s)
	if s.IsCreator then
		saveCreator(s)
		return
	end
	local p = DataService.Get(player)
	if p then
		p.Shop = { Name = s.Name, Items = table.clone(s.Items), Theme = s.Theme }
	end
end

local function filterBroadcast(text: string, userId: number): string?
	local ok, res = pcall(function()
		local f = TextService:FilterStringAsync(text, userId, Enum.TextFilterContext.PublicChat)
		return f:GetNonChatStringForBroadcastAsync()
	end)
	return ok and res or nil
end

local function validateItem(player: Player, id: number)
	local info = AvatarService.GetInfo(id)
	if not info then
		return false, "Couldn't find that item."
	end
	if not AvatarTypes.ById[info.AssetTypeId] then
		return false, "Only wearable items (clothes, accessories, UGC) can be listed."
	end
	if not info.IsForSale and not info.IsPublicDomain then
		return false, "That item isn't on sale."
	end
	if Config.Stalls.RequireCreator then
		local c = info.Creator or {}
		local cid = c.CreatorTargetId or c.Id
		if c.CreatorType == "User" or c.CreatorType == Enum.CreatorType.User then
			if cid ~= player.UserId then
				return false, "You can only list items you created."
			end
		else
			local ok, inGroup = pcall(function()
				local okA, r = pcall(function()
					return (player :: any):IsInGroupAsync(cid)
				end)
				if okA then
					return r
				end
				return player:IsInGroup(cid)
			end)
			if not ok or not inGroup then
				return false, "You can only list items you (or your group) created."
			end
		end
	end
	return true
end

local function payload(player: Player, s)
	local items = {}
	for _, id in s.Items do
		table.insert(items, itemInfo(id))
	end
	return {
		Id = s.Id,
		IsCreator = s.IsCreator,
		OwnerId = s.OwnerId,
		OwnerName = s.OwnerName,
		Name = s.Name,
		Items = items,
		ExpiresAt = s.ExpiresAt,
		RentCost = Config.Stalls.RentCost,
		RentMinutes = Config.Stalls.RentMinutes,
		MaxItems = s.IsCreator and Config.Stalls.CreatorMaxItems or Config.Stalls.MaxItems,
		CanManage = canManage(player, s),
		Vacant = not s.IsCreator and s.OwnerId == 0,
		Theme = s.Theme,
		Themes = (function()
			local t = {}
			for k, c in StallService.Themes do
				table.insert(t, { k, c:ToHex() })
			end
			table.sort(t, function(a, b)
				return a[1] < b[1]
			end)
			return t
		end)(),
	}
end

local function handle(player: Player, action: string, stallId, a)
	local s = stalls[stallId]
	if not s then
		return false, "Stall not found."
	end
	if action == "Get" then
		return true, payload(player, s)
	elseif action == "Rent" then
		if s.IsCreator or s.OwnerId ~= 0 then
			return false, "This stall is taken."
		end
		if ownsStall(player) then
			return false, "You already rent a stall."
		end
		if not DataService.Spend(player, Config.Stalls.RentCost) then
			return false, ("You need %d ✨ Sparkles."):format(Config.Stalls.RentCost)
		end
		local p = DataService.Get(player)
		s.OwnerId = player.UserId
		s.OwnerName = player.DisplayName
		s.Name = (p and p.Shop and p.Shop.Name ~= "" and p.Shop.Name) or (player.DisplayName .. "'s Shop")
		s.Items = {}
		if p and p.Shop and typeof(p.Shop.Items) == "table" then
			for i, id in p.Shop.Items do
				if i <= Config.Stalls.MaxItems and typeof(id) == "number" then
					table.insert(s.Items, id)
				end
			end
		end
		s.ExpiresAt = Util.Now() + Config.Stalls.RentMinutes * 60
		setTheme(s, p and p.Shop and p.Shop.Theme)
		refresh(s)
		Util.Notify(player, "Stall rented! Add your items and name your shop 🛍", "success")
		return true, payload(player, s)
	elseif action == "Extend" then
		if s.IsCreator or s.OwnerId ~= player.UserId then
			return false, "Not your stall."
		end
		if s.ExpiresAt - Util.Now() > 150 * 60 then
			return false, "You can extend up to 3 hours ahead."
		end
		if not DataService.Spend(player, Config.Stalls.RentCost) then
			return false, "Not enough ✨ Sparkles."
		end
		s.ExpiresAt += Config.Stalls.RentMinutes * 60
		refresh(s)
		return true, payload(player, s)
	end
	if not canManage(player, s) then
		return false, "Only the shop owner can do that."
	end
	if action == "Leave" then
		if s.IsCreator then
			return false, "The creator stall is permanent."
		end
		vacate(s, "You closed your stall.")
		return true, payload(player, s)
	elseif action == "Rename" then
		if typeof(a) ~= "string" then
			return false, "Invalid name."
		end
		local name = a:gsub("^%s+", ""):gsub("%s+$", ""):sub(1, 28)
		if #name < 2 then
			return false, "Name is too short."
		end
		local filtered = filterBroadcast(name, player.UserId)
		if not filtered then
			return false, "Couldn't check that name, try again."
		end
		s.Name = filtered
		persistShop(player, s)
		refresh(s)
		return true, payload(player, s)
	elseif action == "AddItem" then
		local id = tonumber(a)
		if not id then
			return false, "Paste an item link or ID."
		end
		id = math.floor(id)
		local max = s.IsCreator and Config.Stalls.CreatorMaxItems or Config.Stalls.MaxItems
		if #s.Items >= max then
			return false, ("Your stall holds %d items."):format(max)
		end
		if table.find(s.Items, id) then
			return false, "Already listed."
		end
		local ok, msg = validateItem(player, id)
		if not ok then
			return false, msg
		end
		table.insert(s.Items, id)
		persistShop(player, s)
		refresh(s)
		return true, payload(player, s)
	elseif action == "RemoveItem" then
		local i = table.find(s.Items, tonumber(a) or -1)
		if i then
			table.remove(s.Items, i)
			persistShop(player, s)
			refresh(s)
		end
		return true, payload(player, s)
	elseif action == "Theme" then
		if typeof(a) == "string" and StallService.Themes[a] then
			setTheme(s, a)
			persistShop(player, s)
		end
		return true, payload(player, s)
	end
	return false, "Unknown action."
end

function StallService.Init(deps)
	DataService = deps.DataService
	AvatarService = deps.AvatarService
	local world = Util.World
	local folder = world and world:FindFirstChild("Mall") and world.Mall:FindFirstChild("Stalls")
	if not folder then
		warn("[Stalls] no stalls found in world")
		return
	end
	for _, model in folder:GetChildren() do
		local id = model:GetAttribute("StallId")
		if id then
			local s = {
				Id = id,
				Model = model,
				IsCreator = model:GetAttribute("IsCreator") == true,
				OwnerId = 0,
				OwnerName = "",
				Name = "",
				Items = {},
				ExpiresAt = 0,
				Mannequins = {},
			}
			stalls[id] = s
			local prompt
			for _, d in model:GetDescendants() do
				if d:IsA("ProximityPrompt") and d.Name == "StallPrompt" then
					prompt = d
				end
			end
			s.Prompt = prompt
			if prompt then
				prompt.Triggered:Connect(function(player)
					Remotes.Event("Stall"):FireClient(player, "Open", id)
				end)
			end
			local slots = model:FindFirstChild("Slots")
			if slots then
				for _, slot in slots:GetChildren() do
					local pr = slot:FindFirstChild("BuyPrompt")
					if pr then
						pr.Triggered:Connect(function(player)
							local assetId = slot:GetAttribute("AssetId")
							if assetId then
								MarketplaceService:PromptPurchase(player, assetId)
							end
						end)
					end
				end
			end
			if s.IsCreator then
				s.OwnerId = creatorId()
				s.Name = Config.CreatorStallName
				s.Items = table.clone(Config.CreatorStallItems)
				task.spawn(function()
					local owner = s.OwnerId
					pcall(function()
						local name = Players:GetNameFromUserIdAsync(owner)
						s.OwnerName = name
					end)
					local ok, saved = pcall(function()
						return creatorStore and creatorStore:GetAsync("CreatorStall")
					end)
					if ok and typeof(saved) == "table" then
						if typeof(saved.Name) == "string" and saved.Name ~= "" then
							s.Name = saved.Name
						end
						if typeof(saved.Items) == "table" then
							s.Items = saved.Items
						end
						setTheme(s, saved.Theme)
					end
					refresh(s)
				end)
			else
				refresh(s)
			end
		end
	end

	Remotes.Func("StallCall").OnServerInvoke = function(player, action, stallId, a)
		local ok, r1, r2 = pcall(handle, player, action, stallId, a)
		if not ok then
			warn("[Stalls]", r1)
			return false, "Something went wrong."
		end
		return r1, r2
	end

	Players.PlayerRemoving:Connect(function(p)
		local s = ownsStall(p)
		if s then
			vacate(s, nil)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(10)
			local now = Util.Now()
			for _, s in stalls do
				if not s.IsCreator and s.OwnerId ~= 0 and now > s.ExpiresAt then
					vacate(s, "Your stall rental ended. Rent again anytime!")
				end
			end
		end
	end)
end

return StallService
