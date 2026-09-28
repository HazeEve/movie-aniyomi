--!nonstrict
-- Always-on HUD: dock buttons, coins & hearts, show banner, hunger/energy,
-- travel menu and the wake-up button.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local UI = require(script.Parent.Parent.UI)
local State = require(script.Parent.Parent.State)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Config = require(ReplicatedStorage.Shared.Config)
local P = UI.P

local HUD = {}
local player = Players.LocalPlayer

local function statBar(parent, icon: string, color: Color3, order: number)
	local row = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(200, 26), LayoutOrder = order, Parent = parent })
	UI.label(row, icon, { Size = UDim2.fromOffset(26, 26), TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center })
	local track = UI.new("Frame", { BackgroundColor3 = P.PlumDeep, BackgroundTransparency = 0.2, Position = UDim2.fromOffset(32, 7), Size = UDim2.new(1, -32, 0, 12), Parent = row })
	UI.round(track)
	UI.stroke(track, P.Champagne, 1, 0.6)
	local fill = UI.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1), Parent = track })
	UI.round(fill)
	UI.gradient(fill, { color, color:Lerp(P.Ivory, 0.35) }, 0)
	return fill
end

function HUD.Init(controllers)
	local gui = UI.screen("AuraHUD", 5)

	-- ============ Dock (left) ============
	-- phones/tablets: dock on the right (the thumbstick lives bottom-left)
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	-- phones: a compact row under the coin counters (clear of thumbstick + jump)
	-- big, readable labelled buttons on the left (icon + word, light on dark)
	local W, H = touch and 150 or 176, touch and 42 or 48
	local dockHolder = UI.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0),
		Position = touch and UDim2.new(0, 10, 0, 96) or UDim2.new(0, 12, 0.2, 0),
		Size = UDim2.fromOffset(W, (H + 8) * 7),
		Parent = gui,
	})
	UI.autoScale(dockHolder, Vector2.new(W, (H + 8) * 7 + 120))
	UI.list(dockHolder, Enum.FillDirection.Vertical, 8)
	local buttons = {}
	local function dock(label, style, fn)
		local b = UI.button(dockHolder, label, style, {
			Size = UDim2.fromOffset(W, H),
			TextSize = touch and 16 or 18,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		UI.pad(b, 0, 14)
		UI.stroke(b, P.Plum, 2, 0.1)
		b.Activated:Connect(fn)
		buttons[label] = b
		return b
	end
	dock("👗  Catalog", "light", function()
		UI.toggle("Catalog")
	end)
	dock("💃  Emotes", "light", function()
		controllers.Catalog.OpenEmotes()
	end)
	local showBtn = dock("✨  Join Runway", "gold", function()
		if player:GetAttribute("InShow") then
			Remotes.Event("Show"):FireServer("Leave")
		else
			Remotes.Event("Show"):FireServer("Join")
		end
	end)
	dock("🎸  Music", "light", function()
		controllers.Music.Toggle()
	end)
	dock("🔨  Auction", "light", function()
		UI.toggle("Auction")
	end)
	dock("🛒  Store", "gold", function()
		UI.toggle("Store")
	end)
	dock("🗺️  Teleport", "secondary", function()
		UI.toggle("Travel")
	end)
	local function refreshShowBtn()
		local inShow = player:GetAttribute("InShow")
		showBtn.Text = inShow and "🚪  Leave Runway" or "✨  Join Runway"
		UI.style(showBtn, inShow and "danger" or "gold")
	end
	player:GetAttributeChangedSignal("InShow"):Connect(refreshShowBtn)
	refreshShowBtn()

	-- ============ Currency (top right) ============
	local cur = UI.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.fromOffset(300, 46),
		Parent = gui,
	})
	UI.autoScale(cur)
	UI.list(cur, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Right)
	local function pill(icon)
		local f = UI.panel(cur, { Size = UDim2.fromOffset(130, 42), AutomaticSize = Enum.AutomaticSize.X })
		UI.pad(f, 0, 14, 0, 10)
		local l = UI.label(f, icon .. "  0", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, TextSize = 20, Font = UI.Font.Title })
		return l
	end
	local coinsL = pill("✨")
	local heartsL = pill("💗")
	-- tap the Sparkles counter to open the Store
	local coinHit = UI.new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = coinsL.Parent })
	coinHit.Activated:Connect(function()
		UI.open("Store")
	end)
	local function refreshData(d)
		coinsL.Text = "✨  " .. tostring(d.Coins or 0) .. "  ＋"
		heartsL.Text = "💗  " .. tostring(d.Hearts or 0)
	end
	State.DataChanged.Event:Connect(refreshData)
	refreshData(State.Data)

	-- ============ Stats (bottom left) ============
	-- desktop: bottom-left; phones: top-left (the thumbstick is bottom-left)
	local stats = UI.panel(gui, {
		AnchorPoint = touch and Vector2.new(0, 0) or Vector2.new(0, 1),
		Position = touch and UDim2.new(0, 12, 0, 8) or UDim2.new(0, 12, 1, -12),
		Size = UDim2.fromOffset(230, 76),
	})
	UI.autoScale(stats)
	UI.pad(stats, 10, 14)
	UI.list(stats, Enum.FillDirection.Vertical, 6)
	local hungerFill = statBar(stats, "🍔", P.RoseGold, 1)
	local energyFill = statBar(stats, "⚡", P.Lavender, 2)
	local function refreshStats()
		UI.tween(hungerFill, 0.4, { Size = UDim2.fromScale(math.clamp((player:GetAttribute("Hunger") or 100) / 100, 0.02, 1), 1) })
		UI.tween(energyFill, 0.4, { Size = UDim2.fromScale(math.clamp((player:GetAttribute("Energy") or 100) / 100, 0.02, 1), 1) })
	end
	player:GetAttributeChangedSignal("Hunger"):Connect(refreshStats)
	player:GetAttributeChangedSignal("Energy"):Connect(refreshStats)
	refreshStats()

	-- ============ Show banner (top centre) ============
	local banner = UI.panel(gui, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(460, 58),
	})
	UI.autoScale(banner)
	local phaseL = UI.label(banner, "", {
		Position = UDim2.fromOffset(18, 6),
		Size = UDim2.new(1, -150, 0, 22),
		TextSize = 15,
		TextColor3 = P.Blush,
		Font = UI.Font.Bold,
	})
	local themeL = UI.label(banner, "", {
		Position = UDim2.fromOffset(18, 26),
		Size = UDim2.new(1, -150, 0, 26),
		TextSize = 20,
		Font = UI.Font.Title,
		TextColor3 = P.Champagne,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local timerL = UI.label(banner, "0:00", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(120, 36),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 28,
		Font = UI.Font.Title,
	})
	local show = ReplicatedStorage:WaitForChild("ShowState")
	local PHASE_TEXT = {
		Intermission = "✨ NEXT SHOW SOON — tap JOIN RUNWAY!",
		Dressing = "👗 DRESS UP FOR THE THEME",
		Runway = "💃 RUNWAY — vote with hearts!",
		Results = "🏆 RESULTS",
	}
	local function refreshBanner()
		local phase = show:GetAttribute("Phase")
		phaseL.Text = PHASE_TEXT[phase] or ""
		local theme = show:GetAttribute("Theme") or ""
		if phase == "Runway" then
			themeL.Text = ("%s  •  %s (%d/%d)"):format(theme, show:GetAttribute("ModelName") or "", show:GetAttribute("ModelIndex") or 0, show:GetAttribute("ModelCount") or 0)
		elseif theme ~= "" then
			themeL.Text = "Theme: " .. theme
		else
			themeL.Text = Config.GameName .. "  •  " .. Config.Tagline
		end
	end
	for _, a in { "Phase", "Theme", "ModelIndex", "ModelName" } do
		show:GetAttributeChangedSignal(a):Connect(refreshBanner)
	end
	refreshBanner()
	RunService.Heartbeat:Connect(function()
		local left = (show:GetAttribute("EndsAt") or 0) - workspace:GetServerTimeNow()
		timerL.Text = UI.fmtTime(left)
	end)

	-- ============ Theme card (big, under the banner) ============
	local MarketplaceService = game:GetService("MarketplaceService")
	local card = UI.panel(gui, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 72),
		Size = UDim2.fromOffset(460, 150),
		Visible = false,
	})
	UI.autoScale(card)
	UI.label(card, "THIS ROUND'S THEME", { Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 18), TextSize = 13, TextColor3 = P.Blush, TextXAlignment = Enum.TextXAlignment.Center })
	local bigTheme = UI.label(card, "", {
		Position = UDim2.fromOffset(12, 26),
		Size = UDim2.new(1, -24, 0, 44),
		TextSize = 32,
		Font = UI.Font.Luxe,
		TextColor3 = P.Champagne,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextScaled = true,
	})
	local hint = UI.label(card, "Style your whole look to match the theme — then walk the runway!", { Position = UDim2.fromOffset(12, 70), Size = UDim2.new(1, -24, 0, 18), TextSize = 13, TextColor3 = P.Lilac, Font = UI.Font.Medium, TextXAlignment = Enum.TextXAlignment.Center })
	local row = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 96), Size = UDim2.new(1, -20, 0, 44), Parent = card })
	UI.list(row, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	local joinBig = UI.button(row, "✨ JOIN RUNWAY", "gold", { LayoutOrder = 1, Size = UDim2.fromOffset(150, 42), TextSize = 16 })
	local changeBtn = UI.button(row, "🔄 Change Theme", "secondary", { LayoutOrder = 2, Size = UDim2.fromOffset(136, 42), TextSize = 14 })
	local timeBtn = UI.button(row, "⏰ +2 Min", "light", { LayoutOrder = 3, Size = UDim2.fromOffset(136, 42), TextSize = 14 })
	joinBig.Activated:Connect(function()
		Remotes.Event("Show"):FireServer("Join")
	end)
	changeBtn.Activated:Connect(function()
		if (Config.Products.ChangeTheme or 0) == 0 then
			controllers.Notify.Show("Owner: set Config.Products.ChangeTheme to your developer product id.", "warn")
			return
		end
		MarketplaceService:PromptProductPurchase(player, Config.Products.ChangeTheme)
	end)
	timeBtn.Activated:Connect(function()
		if (Config.Products.ExtraTime or 0) == 0 then
			controllers.Notify.Show("Owner: set Config.Products.ExtraTime to your developer product id.", "warn")
			return
		end
		MarketplaceService:PromptProductPurchase(player, Config.Products.ExtraTime)
	end)
	local function refreshCard()
		local phase = show:GetAttribute("Phase")
		local theme = show:GetAttribute("Theme") or ""
		local inShow = player:GetAttribute("InShow") == true
		card.Visible = phase == "Dressing" or phase == "Intermission"
		joinBig.Visible = not inShow
		if phase == "Dressing" and theme ~= "" then
			bigTheme.Text = theme
			hint.Text = show:GetAttribute("ExtraTime") and "⏰ Extra Time is on: 10 minutes to get ready!" or "Style your whole look to match the theme, then walk the runway!"
		else
			bigTheme.Text = "Next show starting soon"
			hint.Text = inShow and "You're in! The theme is revealed when dressing starts." or "Tap JOIN RUNWAY to compete for hearts 💗"
		end
	end
	for _, a in { "Phase", "Theme", "ExtraTime" } do
		show:GetAttributeChangedSignal(a):Connect(refreshCard)
	end
	player:GetAttributeChangedSignal("InShow"):Connect(refreshCard)
	refreshCard()

	-- ============ Travel menu ============
	local tgui = UI.screen("AuraTravel", 20)
	local holder, body = UI.window(tgui, "Travel", "🗺️ Teleport", Vector2.new(520, 470))
	local list = UI.scroll(body, { Size = UDim2.fromScale(1, 1) })
	UI.grid(list, UDim2.fromOffset(228, 60), UDim2.fromOffset(12, 12))
	local function rebuild()
		for _, c in list:GetChildren() do
			if c:IsA("GuiButton") then
				c:Destroy()
			end
		end
		local folder = ReplicatedStorage:WaitForChild("TravelList", 10)
		local points = folder and folder:GetChildren() or {}
		table.sort(points, function(a, b)
			return a.Value < b.Value
		end)
		local icons = { ["Runway Stage"] = "💃", ["Aura Mall"] = "🛍️", ["Blush Café"] = "☕", ["Grand Hotel"] = "🏨", ["Boutiques"] = "👜", ["Salon & Florist"] = "💐", ["Fountain Park"] = "⛲", ["Aura Motors"] = "🚗", ["Residences"] = "🏡" }
		for i, pt in points do
			local b = UI.button(list, (icons[pt.Name] or "📍") .. "  " .. pt.Name, i % 2 == 0 and "secondary" or "light", { LayoutOrder = i, TextSize = 17 })
			b.Activated:Connect(function()
				Remotes.Event("RP"):FireServer("Travel", pt.Name)
				UI.close("Travel")
			end)
		end
	end
	UI.registerModal("Travel", holder, rebuild)

	-- ============ Store (Sparkles + game passes) ============
	local sgui = UI.screen("AuraStore", 20)
	local sholder, sbody = UI.window(sgui, "Store", "🛒 Sparkle Store", Vector2.new(560, 560))
	local slist = UI.scroll(sbody, { Size = UDim2.fromScale(1, 1) })
	UI.list(slist, Enum.FillDirection.Vertical, 10)
	local function storeRow(order, icon, title, sub, price, style, fn)
		local r = UI.card(slist, { LayoutOrder = order, Size = UDim2.new(1, -16, 0, 74) })
		UI.label(r, icon, { Position = UDim2.fromOffset(10, 0), Size = UDim2.fromOffset(52, 74), TextSize = 34, TextXAlignment = Enum.TextXAlignment.Center })
		UI.label(r, title, { Position = UDim2.fromOffset(68, 10), Size = UDim2.new(1, -210, 0, 26), TextSize = 19, Font = UI.Font.Title, TextColor3 = P.Text })
		UI.label(r, sub, { Position = UDim2.fromOffset(68, 38), Size = UDim2.new(1, -210, 0, 26), TextSize = 13, TextColor3 = P.TextSoft, Font = UI.Font.Medium, TextWrapped = true })
		local b = UI.button(r, price, style, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(124, 46), TextSize = 17 })
		b.Activated:Connect(fn)
	end
	local function header(order, text)
		UI.label(slist, text, { LayoutOrder = order, Size = UDim2.new(1, -16, 0, 30), TextSize = 18, Font = UI.Font.Title, TextColor3 = P.Blush })
	end
	local function ownerWarn(what)
		controllers.Notify.Show("Owner: set " .. what .. " in Config to your product/pass id.", "warn")
	end
	header(1, "✨ SPARKLES — use for auction bids & stall rent")
	for i, b in Config.SparkleBundles do
		storeRow(1 + i, "✨", b.Name, ("%d Sparkles"):format(b.Amount), "R$ " .. b.Robux, "gold", function()
			if b.ProductId == 0 then
				return ownerWarn("SparkleBundles[" .. i .. "].ProductId")
			end
			MarketplaceService:PromptProductPurchase(player, b.ProductId)
		end)
	end
	header(80, "🛍️ BOOSTS (buy any time)")
	storeRow(82, "⏰", "2 Min Additional Dress Time", "+2 minutes: next dressing round lasts 10 minutes.", "Buy", "light", function()
		if (Config.Products.ExtraTime or 0) == 0 then
			return ownerWarn("Products.ExtraTime")
		end
		MarketplaceService:PromptProductPurchase(player, Config.Products.ExtraTime)
	end)
	storeRow(81, "🔄", "Change Theme", "Re-roll the runway theme (buy any time).", "Buy", "secondary", function()
		if (Config.Products.ChangeTheme or 0) == 0 then
			return ownerWarn("Products.ChangeTheme")
		end
		MarketplaceService:PromptProductPurchase(player, Config.Products.ChangeTheme)
	end)
	UI.label(slist, "🤝 Won a limited at the auction? The seller sends it to you with Roblox Trade (Profile ▸ ••• ▸ Trade Items).", { LayoutOrder = 99, Size = UDim2.new(1, -16, 0, 44), TextSize = 13, TextWrapped = true, TextColor3 = P.Lilac, Font = UI.Font.Medium })
	UI.registerModal("Store", sholder)

	-- ============ Wake button ============
	local wakeHolder = UI.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(200, 54),
		Visible = false,
		Parent = gui,
	})
	UI.autoScale(wakeHolder)
	local wake = UI.button(wakeHolder, "☀️  Wake Up", "gold", {
		Size = UDim2.fromScale(1, 1),
		TextSize = 22,
	})
	wake.Activated:Connect(function()
		Remotes.Event("RP"):FireServer("Wake")
	end)
	player:GetAttributeChangedSignal("Sleeping"):Connect(function()
		wakeHolder.Visible = player:GetAttribute("Sleeping") == true
	end)

	HUD.Buttons = buttons
end

return HUD
