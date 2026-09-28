--!nonstrict
-- Catalog Avatar Creator: search the whole Roblox catalog, try on / take off,
-- buy, favourite, recent, wearing, saved outfits, body tone & scales, undo/redo.
local Players = game:GetService("Players")
local AvatarEditorService = game:GetService("AvatarEditorService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(script.Parent.Parent.UI)
local State = require(script.Parent.Parent.State)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local AvatarTypes = require(ReplicatedStorage.Shared.AvatarTypes)
local P = UI.P

local Catalog = {}
local player = Players.LocalPlayer
local Notify

local A = Enum.AvatarAssetType
local CATEGORIES = {
	{ "For You/All" },
	{ "Accessories", { A.Hat, A.HairAccessory, A.FaceAccessory, A.NeckAccessory, A.ShoulderAccessory, A.FrontAccessory, A.BackAccessory, A.WaistAccessory } },
	{ "Hats", { A.Hat } },
	{ "Hair", { A.HairAccessory } },
	{ "Face", { A.Face, A.FaceAccessory, A.EyebrowAccessory, A.EyelashAccessory } },
	{ "Tops", { A.ShirtAccessory, A.TShirtAccessory, A.SweaterAccessory, A.JacketAccessory, A.Shirt, A.TShirt } },
	{ "Bottoms", { A.PantsAccessory, A.ShortsAccessory, A.DressSkirtAccessory, A.Pants } },
	{ "Dresses", { A.DressSkirtAccessory } },
	{ "Jackets", { A.JacketAccessory, A.SweaterAccessory } },
	{ "Shoes", { A.LeftShoeAccessory, A.RightShoeAccessory } },
	{ "Shoe Sets", nil, { Enum.BundleType.Shoes } },
	{ "Extras", { A.NeckAccessory, A.ShoulderAccessory, A.FrontAccessory, A.BackAccessory, A.WaistAccessory } },
	{ "Classics", { A.Shirt, A.Pants, A.TShirt } },
	{ "Emotes", { A.EmoteAnimation } },
	{ "Heads", nil, { Enum.BundleType.DynamicHead } },
	{ "Bodies", nil, { Enum.BundleType.BodyParts } },
	{ "Animations", nil, { Enum.BundleType.Animations } },
}
local EMOTE_TAB = 14
local SORTS = {
	{ "Relevance", Enum.CatalogSortType.Relevance },
	{ "Best Selling", Enum.CatalogSortType.Bestselling },
	{ "Most Favorited", Enum.CatalogSortType.MostFavorited },
	{ "Newest", Enum.CatalogSortType.RecentlyCreated },
	{ "Price ↑", Enum.CatalogSortType.PriceLowToHigh },
	{ "Price ↓", Enum.CatalogSortType.PriceHighToLow },
}

local infoCache = {}
local function productInfo(id: number, isBundle: boolean?)
	local key = (isBundle and "b" or "a") .. id
	if infoCache[key] then
		return infoCache[key]
	end
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(id, isBundle and Enum.InfoType.Bundle or Enum.InfoType.Asset)
	end)
	if ok and info then
		local entry = {
			Id = id,
			Name = info.Name,
			Price = info.PriceInRobux,
			ForSale = info.IsForSale,
			ItemType = isBundle and "Bundle" or "Asset",
		}
		infoCache[key] = entry
		return entry
	end
	return { Id = id, Name = "Item", ItemType = isBundle and "Bundle" or "Asset" }
end

-- ================= state =================
local catIndex, sortIndex, subTab = 1, 1, "Featured"
local keyword = ""
local pages, loading, token = nil, false, 0
local recent = {}
local undoStack, redoStack = {}, {}
local grid, wearingStrip, previewWorld, previewCam, emptyLabel, bodyPanel
local rotY = math.pi
local selectedCard

local function avatarCall(action, a, b, pushUndo)
	if pushUndo ~= false and State.Snap then
		table.insert(undoStack, State.Snap)
		if #undoStack > 40 then
			table.remove(undoStack, 1)
		end
		redoStack = {}
	end
	local res = Remotes.Func("Avatar"):InvokeServer(action, a, b)
	State.SetAvatarReply(res)
	if res and res.msg and Notify then
		Notify.Show(res.msg, res.ok and "success" or "warn")
	end
	return res
end
Catalog.Call = avatarCall

-- ================= preview =================
local function clearPreview()
	for _, c in previewWorld:GetChildren() do
		c:Destroy()
	end
end

local refreshToken = 0
local function refreshPreview()
	refreshToken += 1
	local my = refreshToken
	task.delay(0.35, function()
		if my ~= refreshToken or not previewWorld then
			return
		end
		local char = player.Character
		if not char then
			return
		end
		char.Archivable = true
		local ok, clone = pcall(function()
			return char:Clone()
		end)
		if not ok or not clone then
			return
		end
		for _, d in clone:GetDescendants() do
			if d:IsA("BaseScript") or d:IsA("Sound") or d:IsA("ProximityPrompt") or d:IsA("BillboardGui") or d:IsA("Tool") then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		local hum = clone:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
		clearPreview()
		clone.Parent = previewWorld
		clone:PivotTo(CFrame.Angles(0, rotY, 0))
		local size = clone:GetExtentsSize()
		local h = math.max(size.Y, 4)
		local dist = (h / 2) / math.tan(math.rad(previewCam.FieldOfView / 2)) * 1.25
		local centre = clone:GetBoundingBox().Position
		previewCam.CFrame = CFrame.lookAt(centre + Vector3.new(0, 0.2, -dist), centre)
	end)
end
Catalog.RefreshPreview = refreshPreview

-- ================= cards =================
local function closeSelected()
	if selectedCard then
		local ov = selectedCard:FindFirstChild("Overlay")
		if ov then
			ov.Visible = false
		end
		selectedCard = nil
	end
end

local function isWornEntry(entry): boolean
	if entry.ItemType == "Bundle" then
		return false
	end
	return State.IsWorn(entry.Id)
end

local function favKey(entry): number
	return entry.ItemType == "Bundle" and -entry.Id or entry.Id
end

local function addRecent(entry)
	for i, r in recent do
		if r.Id == entry.Id and r.ItemType == entry.ItemType then
			table.remove(recent, i)
			break
		end
	end
	table.insert(recent, 1, entry)
	if #recent > 60 then
		table.remove(recent)
	end
end

local function makeCard(entry, order: number)
	local card = UI.card(grid, { Name = "Card", LayoutOrder = order, Size = UDim2.fromOffset(186, 232) })
	card:SetAttribute("Id", entry.Id)
	card:SetAttribute("Bundle", entry.ItemType == "Bundle")
	UI.stroke(card, P.Lavender, 1.5, 0.6)
	local thumb = UI.new("ImageLabel", {
		BackgroundTransparency = 1,
		Image = entry.ItemType == "Bundle" and UI.bundleThumb(entry.Id) or UI.assetThumb(entry.Id),
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.fromOffset(166, 150),
		ScaleType = Enum.ScaleType.Fit,
		Parent = card,
	})
	local nameL = UI.label(card, entry.Name or "…", {
		Position = UDim2.fromOffset(10, 160),
		Size = UDim2.new(1, -20, 0, 38),
		TextColor3 = P.Text,
		TextSize = 15,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	local priceL = UI.label(card, UI.priceText(entry.Price, entry.ForSale), {
		Position = UDim2.fromOffset(10, 200),
		Size = UDim2.new(1, -20, 0, 24),
		TextColor3 = P.Violet,
		TextSize = 17,
		Font = UI.Font.Title,
	})
	if entry.ItemType == "Bundle" then
		local tag = UI.label(card, "BUNDLE", {
			BackgroundColor3 = P.Lavender,
			BackgroundTransparency = 0,
			TextColor3 = P.Plum,
			TextSize = 11,
			Font = UI.Font.Title,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(8, 8),
			Size = UDim2.fromOffset(62, 20),
		})
		UI.round(tag)
	end
	-- lazily fill unknown names/prices
	if not entry.Name or entry.Name == "Item" then
		task.spawn(function()
			local info = productInfo(entry.Id, entry.ItemType == "Bundle")
			entry.Name = info.Name
			entry.Price = info.Price
			entry.ForSale = info.ForSale
			if card.Parent then
				nameL.Text = info.Name or "Item"
				priceL.Text = UI.priceText(info.Price, info.ForSale)
			end
		end)
	end
	local check = UI.new("TextLabel", {
		Name = "Check",
		BackgroundColor3 = P.Success,
		Text = "✓",
		TextColor3 = P.Plum,
		Font = UI.Font.Title,
		TextSize = 18,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.fromOffset(30, 30),
		Visible = isWornEntry(entry),
		Parent = card,
	})
	UI.round(check)
	UI.stroke(check, P.Ivory, 2, 0)

	-- overlay with actions
	local overlay = UI.new("Frame", {
		Name = "Overlay",
		BackgroundColor3 = P.Plum,
		BackgroundTransparency = 0.25,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 5,
		Parent = card,
	})
	UI.corner(overlay, 14)
	local wear = UI.button(overlay, "", "secondary", { Position = UDim2.fromOffset(18, 44), Size = UDim2.new(1, -36, 0, 44), ZIndex = 6 })
	local buy = UI.button(overlay, "Buy", "gold", { Position = UDim2.fromOffset(18, 98), Size = UDim2.new(1, -36, 0, 48), TextSize = 22, ZIndex = 6 })
	local fav = UI.button(overlay, "♡", "dark", { Position = UDim2.fromOffset(18, 156), Size = UDim2.fromOffset(44, 40), TextSize = 22, ZIndex = 6 })
	local copyId = UI.button(overlay, "#ID", "dark", { Position = UDim2.new(1, -106, 0, 156), Size = UDim2.fromOffset(88, 40), TextSize = 14, ZIndex = 6 })
	local function refreshOverlay()
		wear.Text = entry.IsEmote and "▶ Play" or (isWornEntry(entry) and "Take Off" or "Try On")
		UI.style(wear, (not entry.IsEmote and isWornEntry(entry)) and "light" or "secondary")
		fav.Text = State.IsFavorite(favKey(entry)) and "♥" or "♡"
		check.Visible = isWornEntry(entry)
	end
	refreshOverlay()
	card:SetAttribute("Refresh", true)

	local hit = UI.new("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = card })
	hit.Activated:Connect(function()
		if selectedCard == card then
			closeSelected()
			return
		end
		closeSelected()
		selectedCard = card
		refreshOverlay()
		overlay.Visible = true
	end)
	wear.Activated:Connect(function()
		addRecent(entry)
		if entry.IsEmote then
			Catalog.PlayEmote(entry.Id)
		elseif entry.ItemType == "Bundle" then
			avatarCall("ToggleBundle", entry.Id)
		else
			avatarCall("Toggle", entry.Id)
		end
		refreshOverlay()
	end)
	buy.Activated:Connect(function()
		if entry.ItemType == "Bundle" then
			MarketplaceService:PromptBundlePurchase(player, entry.Id)
		else
			MarketplaceService:PromptPurchase(player, entry.Id)
		end
	end)
	fav.Activated:Connect(function()
		Remotes.Func("DataCall"):InvokeServer("ToggleFavorite", favKey(entry))
		task.wait(0.2)
		refreshOverlay()
	end)
	copyId.Activated:Connect(function()
		if Notify then
			Notify.Show(("%s ID: %d"):format(entry.Name or "Item", entry.Id), "info")
		end
	end)
	card:GetAttributeChangedSignal("Refresh"):Connect(refreshOverlay)
	return card
end

local function clearGrid()
	selectedCard = nil
	for _, c in grid:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	grid.CanvasPosition = Vector2.zero
end

local function refreshCards()
	for _, c in grid:GetChildren() do
		if c.Name == "Card" then
			c:SetAttribute("Refresh", not c:GetAttribute("Refresh"))
		end
	end
end

local function toEntry(item)
	return {
		Id = item.Id,
		Name = item.Name,
		Price = item.Price or item.LowestPrice,
		ForSale = item.PriceStatus ~= "Off Sale",
		ItemType = item.ItemType == "Bundle" and "Bundle" or "Asset",
		IsEmote = item.AssetType == "EmoteAnimation" or catIndex == EMOTE_TAB,
	}
end

-- equip a catalog emote on the server, then play it (works for any catalog emote)
local emoteNames = {}
function Catalog.PlayEmote(id: number)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local name = emoteNames[id]
	if not name then
		local res = Remotes.Func("Avatar"):InvokeServer("Emote", id)
		if not res or not res.ok or not res.emote then
			if Notify then
				Notify.Show(res and res.msg or "Couldn't load that emote.", "warn")
			end
			return
		end
		name = res.emote
		emoteNames[id] = name
		task.wait(0.4)
	end
	local ok, played = pcall(function()
		return hum:PlayEmote(name)
	end)
	if (not ok or not played) and emoteNames[id] then
		-- respawned or desc reset: equip again once
		emoteNames[id] = nil
		local res = Remotes.Func("Avatar"):InvokeServer("Emote", id)
		if res and res.ok and res.emote then
			emoteNames[id] = res.emote
			task.wait(0.4)
			pcall(function()
				hum:PlayEmote(res.emote)
			end)
		end
	end
end

-- open the catalog straight on the Emotes tab (runway shortcut)
function Catalog.OpenEmotes()
	Catalog.PendingTab = EMOTE_TAB
	UI.open("Catalog")
end

local function appendPage()
	if not pages then
		return
	end
	local ok, items = pcall(function()
		return pages:GetCurrentPage()
	end)
	if not ok or not items then
		return
	end
	local n = #grid:GetChildren()
	for i, item in items do
		makeCard(toEntry(item), n + i)
	end
end

local function runSearch()
	token += 1
	local my = token
	clearGrid()
	emptyLabel.Visible = false
	pages = nil
	if subTab ~= "Featured" then
		local list = {}
		if subTab == "Wearing" then
			for _, w in State.Worn do
				table.insert(list, { Id = w.Id, ItemType = "Asset" })
			end
		elseif subTab == "Favorites" then
			for _, id in State.Data.Favorites or {} do
				table.insert(list, { Id = math.abs(id), ItemType = id < 0 and "Bundle" or "Asset" })
			end
		elseif subTab == "Recent" then
			list = recent
		end
		for i, e in list do
			makeCard(e, i)
		end
		emptyLabel.Text = ({ Wearing = "You're not wearing any items yet.", Favorites = "Tap ♡ on any item to save it here.", Recent = "Items you try on show up here." })[subTab] or ""
		emptyLabel.Visible = #list == 0
		return
	end
	loading = true
	local cat = CATEGORIES[catIndex]
	local params = CatalogSearchParams.new()
	params.SearchKeyword = keyword
	params.SortType = SORTS[sortIndex][2]
	params.Limit = 60
	params.IncludeOffSale = true -- off-sale items can still be tried on
	if cat[2] then
		params.AssetTypes = cat[2]
	end
	if cat[3] then
		params.BundleTypes = cat[3]
	end
	local ok, res = pcall(function()
		-- SearchCatalogAsync is the current API; fall back for older clients
		local okA, pagesA = pcall(function()
			return (AvatarEditorService :: any):SearchCatalogAsync(params)
		end)
		if okA and pagesA then
			return pagesA
		end
		return AvatarEditorService:SearchCatalog(params)
	end)
	loading = false
	if my ~= token then
		return
	end
	if not ok then
		emptyLabel.Text = "The catalog is busy — try again in a moment."
		emptyLabel.Visible = true
		warn("[Catalog]", res)
		return
	end
	pages = res
	appendPage()
	emptyLabel.Text = "No items found."
	local count = 0
	for _, c in grid:GetChildren() do
		if c.Name == "Card" then
			count += 1
		end
	end
	emptyLabel.Visible = count == 0
end

local function loadMore()
	if loading or not pages or subTab ~= "Featured" then
		return
	end
	if pages.IsFinished then
		return
	end
	loading = true
	local my = token
	local ok = pcall(function()
		pages:AdvanceToNextPageAsync()
	end)
	loading = false
	if ok and my == token then
		appendPage()
	end
end

-- ================= wearing strip =================
local function refreshWearing()
	for _, c in wearingStrip:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	for i, w in State.Worn do
		local cell = UI.card(wearingStrip, { LayoutOrder = i, Size = UDim2.fromOffset(84, 84) })
		UI.new("ImageLabel", { BackgroundTransparency = 1, Image = UI.assetThumb(w.Id), Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4), Parent = cell })
		local ck = UI.new("TextLabel", {
			BackgroundColor3 = P.Success,
			Text = "✓",
			Font = UI.Font.Title,
			TextSize = 14,
			TextColor3 = P.Plum,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -4, 0, 4),
			Size = UDim2.fromOffset(22, 22),
			Parent = cell,
		})
		UI.round(ck)
		local b = UI.new("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), Parent = cell })
		b.Activated:Connect(function()
			avatarCall("Remove", w.Id)
		end)
	end
end

-- ================= body panel =================
local function buildBodyPanel(parent)
	local panel = UI.panel(parent, { Name = "Body", Size = UDim2.new(1, -24, 1, -70), Position = UDim2.fromOffset(12, 58), Visible = false, ZIndex = 20 })
	UI.pad(panel, 14)
	local layout = UI.list(panel, Enum.FillDirection.Vertical, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	UI.label(panel, "Skin Tone", { LayoutOrder = 1, TextColor3 = P.Champagne, Font = UI.Font.Title, ZIndex = 21 })
	local sw = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 84), LayoutOrder = 2, ZIndex = 21, Parent = panel })
	UI.grid(sw, UDim2.fromOffset(36, 36), UDim2.fromOffset(8, 8))
	for i, hex in AvatarTypes.SkinTones do
		local b = UI.new("TextButton", { Text = "", BackgroundColor3 = Color3.fromHex(hex), LayoutOrder = i, ZIndex = 22, Parent = sw })
		UI.round(b)
		UI.stroke(b, P.Ivory, 2, 0.3)
		b.Activated:Connect(function()
			avatarCall("Skin", hex)
		end)
	end
	UI.label(panel, "Body Shape", { LayoutOrder = 3, TextColor3 = P.Champagne, Font = UI.Font.Title, ZIndex = 21 })
	local sliders = {
		{ "HeightScale", "Height" },
		{ "WidthScale", "Width" },
		{ "HeadScale", "Head" },
		{ "BodyTypeScale", "Body Type" },
		{ "ProportionScale", "Proportions" },
	}
	for i, s in sliders do
		local prop, label = s[1], s[2]
		local lim = AvatarTypes.ScaleLimits[prop]
		local row = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 3 + i, ZIndex = 21, Parent = panel })
		UI.label(row, label, { Size = UDim2.fromOffset(100, 34), TextSize = 15, ZIndex = 21 })
		local track = UI.new("Frame", { BackgroundColor3 = P.PlumDeep, Position = UDim2.fromOffset(110, 13), Size = UDim2.new(1, -120, 0, 8), ZIndex = 21, Parent = row })
		UI.round(track)
		local knob = UI.new("TextButton", { Text = "", BackgroundColor3 = P.Blush, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(22, 22), ZIndex = 23, Parent = track })
		UI.round(knob)
		UI.stroke(knob, P.Ivory, 2, 0)
		local function setFromSnap()
			local v = State.Snap and State.Snap.S and State.Snap.S[prop]
			if v then
				knob.Position = UDim2.fromScale((v - lim[1]) / (lim[2] - lim[1]), 0.5)
			end
		end
		setFromSnap()
		State.WornChanged.Event:Connect(setFromSnap)
		local dragging
		local function update(x)
			local a = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			knob.Position = UDim2.fromScale(a, 0.5)
			return lim[1] + (lim[2] - lim[1]) * a
		end
		local lastVal
		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = input
				lastVal = update(input.Position.X)
			end
		end)
		knob.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = input
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input == dragging or input.UserInputType == Enum.UserInputType.MouseMovement) then
				lastVal = update(input.Position.X)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if dragging and (input == dragging or input.UserInputType == Enum.UserInputType.MouseButton1) then
				dragging = nil
				if lastVal then
					avatarCall("Scale", prop, lastVal)
				end
			end
		end)
	end
	local reset = UI.button(panel, "↺  Reset to my avatar", "light", { LayoutOrder = 20, Size = UDim2.new(1, 0, 0, 40), TextSize = 16, ZIndex = 22 })
	reset.Activated:Connect(function()
		avatarCall("Reset")
	end)
	return panel
end

-- ================= outfits tab =================
local function showOutfits()
	token += 1
	clearGrid()
	emptyLabel.Visible = #(State.Data.Outfits or {}) == 0
	emptyLabel.Text = "Save your looks with 💾 Save Outfit below."
	for i, o in State.Data.Outfits or {} do
		local card = UI.card(grid, { LayoutOrder = i, Size = UDim2.fromOffset(186, 232) })
		UI.stroke(card, P.Lavender, 1.5, 0.6)
		UI.label(card, "👗", { TextSize = 64, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 100), Position = UDim2.fromOffset(0, 12) })
		UI.label(card, o.Name, { TextColor3 = P.Text, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(8, 116), Size = UDim2.new(1, -16, 0, 40), TextSize = 16 })
		local wear = UI.button(card, "Wear", "secondary", { Position = UDim2.fromOffset(12, 166), Size = UDim2.new(1, -72, 0, 44) })
		local del = UI.button(card, "🗑", "danger", { Position = UDim2.new(1, -54, 0, 166), Size = UDim2.fromOffset(42, 44) })
		wear.Activated:Connect(function()
			avatarCall("WearOutfit", i)
		end)
		del.Activated:Connect(function()
			avatarCall("DeleteOutfit", i, nil, false)
			task.wait(0.3)
			showOutfits()
		end)
	end
end

function Catalog.Init(controllers)
	Notify = controllers.Notify
	local gui = UI.screen("AuraCatalog", 10)
	local holder = UI.new("Frame", {
		Name = "Catalog",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(1240, 660),
		Parent = gui,
	})
	UI.autoScale(holder, Vector2.new(1240, 660))
	local win = UI.panel(holder, { Name = "Window", Size = UDim2.fromScale(1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 0.02 })

	-- ---------- left: preview ----------
	local prevCard = UI.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(380, 516), Parent = win })
	UI.corner(prevCard, 18)
	UI.gradient(prevCard, { P.Lilac, P.Blush, P.Ivory }, 90)
	local vp = UI.new("ViewportFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Ambient = Color3.fromHex("C9BFD9"),
		LightColor = Color3.fromHex("FFF4EE"),
		LightDirection = Vector3.new(-0.4, -1, -0.6),
		Parent = prevCard,
	})
	previewCam = UI.new("Camera", { FieldOfView = 34, Parent = vp })
	vp.CurrentCamera = previewCam
	previewWorld = UI.new("WorldModel", { Parent = vp })
	-- floor shadow disc
	local floor = UI.new("Frame", { BackgroundColor3 = P.Plum, BackgroundTransparency = 0.85, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 1, -44), Size = UDim2.fromOffset(200, 26), Parent = prevCard })
	UI.round(floor)
	-- rotate by dragging
	local dragInput, lastX
	vp.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
			lastX = input.Position.X
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragInput and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local dx = input.Position.X - lastX
			lastX = input.Position.X
			rotY += dx * 0.012
			local model = previewWorld:FindFirstChildOfClass("Model")
			if model then
				model:PivotTo(CFrame.Angles(0, rotY, 0))
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragInput = nil
		end
	end)
	-- preview toolbar
	local bodyBtn = UI.button(prevCard, "🎨", "dark", { Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(46, 46), TextSize = 22 })
	local undoBtn = UI.button(prevCard, "↶", "dark", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -64, 0, 12), Size = UDim2.fromOffset(46, 46), TextSize = 24 })
	local redoBtn = UI.button(prevCard, "↷", "dark", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(46, 46), TextSize = 24 })
	bodyPanel = buildBodyPanel(prevCard)
	bodyBtn.Activated:Connect(function()
		bodyPanel.Visible = not bodyPanel.Visible
	end)
	undoBtn.Activated:Connect(function()
		local snap = table.remove(undoStack)
		if snap then
			if State.Snap then
				table.insert(redoStack, State.Snap)
			end
			avatarCall("Snapshot", snap, nil, false)
		end
	end)
	redoBtn.Activated:Connect(function()
		local snap = table.remove(redoStack)
		if snap then
			if State.Snap then
				table.insert(undoStack, State.Snap)
			end
			avatarCall("Snapshot", snap, nil, false)
		end
	end)
	UI.label(prevCard, "drag to spin ↔", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.fromOffset(200, 20), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 13, TextColor3 = P.TextSoft })

	-- wearing strip
	local stripCard = UI.new("Frame", { BackgroundColor3 = P.PlumDeep, BackgroundTransparency = 0.3, Position = UDim2.fromOffset(16, 542), Size = UDim2.fromOffset(380, 102), Parent = win })
	UI.corner(stripCard, 16)
	wearingStrip = UI.scroll(stripCard, {
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.new(1, -16, 1, -12),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 4,
	})
	UI.list(wearingStrip, Enum.FillDirection.Horizontal, 8)

	-- ---------- right: search + tabs ----------
	local right = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(412, 16), Size = UDim2.new(1, -428, 1, -32), Parent = win })
	local search = UI.textbox(right, "🔍  Search the catalog…", { Size = UDim2.fromOffset(270, 50), TextSize = 19 })
	local clear = UI.button(search, "✕", "ghost", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 8, 0.5, 0), Size = UDim2.fromOffset(34, 34), TextColor3 = P.TextSoft })
	clear.TextColor3 = P.TextSoft
	local tabsBar = UI.panel(right, { Position = UDim2.fromOffset(282, 0), Size = UDim2.new(1, -346, 0, 50), BackgroundTransparency = 0.2 })
	local tabs = UI.scroll(tabsBar, {
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -16, 1, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 0,
	})
	UI.list(tabs, Enum.FillDirection.Horizontal, 4, nil, Enum.VerticalAlignment.Center)
	local close = UI.button(right, "✕", "dark", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(52, 50), TextSize = 24 })
	UI.stroke(close, P.Champagne, 1.5, 0.4)
	close.Activated:Connect(function()
		UI.close("Catalog")
	end)

	local tabButtons = {}
	local function styleTabs()
		for i, b in tabButtons do
			b.TextColor3 = i == catIndex and P.Champagne or P.TextLight
			b.Font = i == catIndex and UI.Font.Title or UI.Font.Bold
			local u = b:FindFirstChild("Underline")
			if u then
				u.Visible = i == catIndex
			end
		end
	end
	for i, c in CATEGORIES do
		local b = UI.new("TextButton", {
			BackgroundTransparency = 1,
			Text = c[1],
			Font = UI.Font.Bold,
			TextSize = 18,
			TextColor3 = P.TextLight,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 40),
			LayoutOrder = i,
			Parent = tabs,
		})
		UI.pad(b, 0, 10)
		UI.new("Frame", { Name = "Underline", BackgroundColor3 = P.Blush, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.new(1, -8, 0, 3), Visible = false, Parent = b })
		b.Activated:Connect(function()
			catIndex = i
			subTab = "Featured"
			styleTabs()
			Catalog.RefreshSubTabs()
			runSearch()
		end)
		tabButtons[i] = b
	end
	styleTabs()

	-- sub tabs
	local subBar = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 40), Parent = right })
	UI.list(subBar, Enum.FillDirection.Horizontal, 6, nil, Enum.VerticalAlignment.Center)
	local subs = { "Featured", "Wearing", "Favorites", "Recent", "Outfits" }
	local subLabels = { Featured = "Featured/All", Wearing = "Wearing", Favorites = "Favorites", Recent = "Recent", Outfits = "My Outfits" }
	local subButtons = {}
	function Catalog.RefreshSubTabs()
		for name, b in subButtons do
			UI.style(b, name == subTab and "light" or "dark")
		end
	end
	for i, name in subs do
		local b = UI.button(subBar, subLabels[name], "dark", { LayoutOrder = i, Size = UDim2.fromOffset(128, 36), TextSize = 15 })
		b.Activated:Connect(function()
			subTab = name
			Catalog.RefreshSubTabs()
			if name == "Outfits" then
				showOutfits()
			else
				runSearch()
			end
		end)
		subButtons[name] = b
	end
	local sortBtn = UI.button(subBar, "Sort: Relevance", "secondary", { LayoutOrder = 10, Size = UDim2.fromOffset(150, 36), TextSize = 14 })
	sortBtn.Activated:Connect(function()
		sortIndex = sortIndex % #SORTS + 1
		sortBtn.Text = "Sort: " .. SORTS[sortIndex][1]
		subTab = "Featured"
		Catalog.RefreshSubTabs()
		runSearch()
	end)
	Catalog.RefreshSubTabs()

	-- grid
	grid = UI.scroll(right, { Position = UDim2.fromOffset(0, 106), Size = UDim2.new(1, 0, 1, -172) })
	UI.grid(grid, UDim2.fromOffset(186, 232), UDim2.fromOffset(12, 12))
	UI.pad(grid, 4, 4, 4, 4)
	emptyLabel = UI.label(right, "", {
		Position = UDim2.fromOffset(0, 220),
		Size = UDim2.new(1, 0, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = P.Lilac,
		Visible = false,
	})
	grid:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if grid.CanvasPosition.Y + grid.AbsoluteWindowSize.Y > grid.AbsoluteCanvasSize.Y - 300 then
			task.spawn(loadMore)
		end
	end)

	-- bottom bar
	local bottom = UI.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 54), Parent = right })
	local link = UI.textbox(bottom, "Enter Item Link or ID…", { Size = UDim2.fromOffset(330, 50) })
	local tryLink = UI.button(bottom, "Try On", "secondary", { Position = UDim2.fromOffset(340, 3), Size = UDim2.fromOffset(110, 44) })
	local outfitName = UI.textbox(bottom, "Outfit name", { Position = UDim2.fromOffset(470, 0), Size = UDim2.fromOffset(170, 50) })
	local saveBtn = UI.button(bottom, "💾 Save Outfit", "gold", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 3), Size = UDim2.fromOffset(158, 44), TextSize = 16 })
	tryLink.Activated:Connect(function()
		local text = link.Text
		local id = UI.parseId(text)
		if not id then
			Notify.Show("Paste a catalog link or item ID.", "warn")
			return
		end
		local isBundle = text:find("bundles/") ~= nil
		local entry = { Id = id, ItemType = isBundle and "Bundle" or "Asset" }
		addRecent(entry)
		avatarCall(isBundle and "ToggleBundle" or "Toggle", id)
	end)
	saveBtn.Activated:Connect(function()
		avatarCall("SaveOutfit", outfitName.Text, nil, false)
		outfitName.Text = ""
		if subTab == "Outfits" then
			task.wait(0.3)
			showOutfits()
		end
	end)

	-- search box
	local searchToken = 0
	search.FocusLost:Connect(function(enter)
		if enter or search.Text ~= keyword then
			keyword = search.Text
			subTab = "Featured"
			Catalog.RefreshSubTabs()
			runSearch()
		end
	end)
	search:GetPropertyChangedSignal("Text"):Connect(function()
		searchToken += 1
		local my = searchToken
		task.delay(0.8, function()
			if my == searchToken and search.Text ~= keyword then
				keyword = search.Text
				subTab = "Featured"
				Catalog.RefreshSubTabs()
				runSearch()
			end
		end)
	end)
	clear.Activated:Connect(function()
		search.Text = ""
	end)

	State.WornChanged.Event:Connect(function()
		refreshWearing()
		refreshCards()
		refreshPreview()
		if subTab == "Wearing" and UI.isOpen("Catalog") then
			runSearch()
		end
	end)
	player:GetAttributeChangedSignal("OutfitVersion"):Connect(refreshPreview)

	-- ---------- compact (portrait) mode: a side panel so you can watch your character ----------
	local compact = true
	local modeBtn = UI.button(right, "⇔", "secondary", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -58, 0, 0), Size = UDim2.fromOffset(52, 50), TextSize = 22 })
	local function applyMode()
		prevCard.Visible = not compact
		stripCard.Visible = not compact
		sortBtn.Visible = not compact
		outfitName.Visible = not compact
		if compact then
			holder.Size = UDim2.fromOffset(460, 660)
			holder.AnchorPoint = Vector2.new(1, 0.5)
			holder.Position = UDim2.new(1, -10, 0.54, 0)
			right.Position = UDim2.fromOffset(12, 14)
			right.Size = UDim2.new(1, -24, 1, -28)
			search.Size = UDim2.new(1, -116, 0, 50)
			tabsBar.Position = UDim2.fromOffset(0, 56)
			tabsBar.Size = UDim2.new(1, 0, 0, 46)
			subBar.Position = UDim2.fromOffset(0, 108)
			grid.Position = UDim2.fromOffset(0, 152)
			grid.Size = UDim2.new(1, 0, 1, -214)
			for _, b in subButtons do
				b.Size = UDim2.fromOffset(80, 34)
				b.TextSize = 12
			end
			link.Size = UDim2.new(1, -230, 0, 50)
			tryLink.Position = UDim2.new(1, -224, 0, 3)
			tryLink.Size = UDim2.fromOffset(80, 44)
			saveBtn.Size = UDim2.fromOffset(136, 44)
			saveBtn.Text = "💾 Save"
			modeBtn.Text = "⇔"
		else
			holder.Size = UDim2.fromOffset(1240, 660)
			holder.AnchorPoint = Vector2.new(0.5, 0.5)
			holder.Position = UDim2.fromScale(0.5, 0.52)
			right.Position = UDim2.fromOffset(412, 16)
			right.Size = UDim2.new(1, -428, 1, -32)
			search.Size = UDim2.fromOffset(270, 50)
			tabsBar.Position = UDim2.fromOffset(282, 0)
			tabsBar.Size = UDim2.new(1, -404, 0, 50)
			subBar.Position = UDim2.fromOffset(0, 58)
			grid.Position = UDim2.fromOffset(0, 106)
			grid.Size = UDim2.new(1, 0, 1, -172)
			for _, b in subButtons do
				b.Size = UDim2.fromOffset(128, 36)
				b.TextSize = 15
			end
			link.Size = UDim2.fromOffset(330, 50)
			tryLink.Position = UDim2.fromOffset(340, 3)
			tryLink.Size = UDim2.fromOffset(110, 44)
			saveBtn.Size = UDim2.fromOffset(158, 44)
			saveBtn.Text = "💾 Save Outfit"
			modeBtn.Text = "⇔"
		end
	end
	modeBtn.Activated:Connect(function()
		compact = not compact
		applyMode()
		refreshPreview()
	end)
	applyMode()

	local first = true
	UI.registerModal("Catalog", holder, function()
		local res = Remotes.Func("Avatar"):InvokeServer("Get")
		State.SetAvatarReply(res)
		refreshPreview()
		if Catalog.PendingTab then
			catIndex = Catalog.PendingTab
			Catalog.PendingTab = nil
			subTab = "Featured"
			styleTabs()
			Catalog.RefreshSubTabs()
			first = false
			runSearch()
		elseif first then
			first = false
			runSearch()
		end
	end, function()
		bodyPanel.Visible = false
		clearPreview()
	end)
end

return Catalog
