--!nonstrict
-- Always-on HUD: dock buttons, coins & hearts, show banner, hunger/energy,
-- travel menu and the wake-up button.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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
	local dockHolder = UI.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 10),
		Size = UDim2.fromOffset(70, 500),
		Parent = gui,
	})
	UI.autoScale(dockHolder)
	UI.list(dockHolder, Enum.FillDirection.Vertical, 4, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	local buttons = {}
	local function dock(emoji, caption, fn)
		local b = UI.iconButton(dockHolder, emoji, caption)
		b.Activated:Connect(fn)
		buttons[caption] = b
		return b
	end
	dock("👗", "Catalog", function()
		UI.toggle("Catalog")
	end)
	local showBtn = dock("✨", "Join Show", function()
		if player:GetAttribute("InShow") then
			Remotes.Event("Show"):FireServer("Leave")
		else
			Remotes.Event("Show"):FireServer("Join")
		end
	end)
	dock("🎸", "Music", function()
		controllers.Music.Toggle()
	end)
	dock("🔨", "Auction", function()
		UI.toggle("Auction")
	end)
	dock("🗺️", "Travel", function()
		UI.toggle("Travel")
	end)
	local function refreshShowBtn()
		local cap = showBtn.Parent:FindFirstChildOfClass("TextLabel")
		if cap then
			cap.Text = player:GetAttribute("InShow") and "Leave Show" or "Join Show"
		end
		showBtn.Text = player:GetAttribute("InShow") and "💃" or "✨"
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
	local coinsL = pill("🪙")
	local heartsL = pill("💗")
	local function refreshData(d)
		coinsL.Text = "🪙  " .. tostring(d.Coins or 0)
		heartsL.Text = "💗  " .. tostring(d.Hearts or 0)
	end
	State.DataChanged.Event:Connect(refreshData)
	refreshData(State.Data)

	-- ============ Stats (bottom left) ============
	local stats = UI.panel(gui, {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -12),
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
		Intermission = "✨ NEXT SHOW SOON — tap Join Show!",
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

	-- ============ Travel menu ============
	local tgui = UI.screen("AuraTravel", 20)
	local holder, body = UI.window(tgui, "Travel", "Travel", Vector2.new(520, 470))
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

	-- ============ Wake button ============
	local wake = UI.button(gui, "☀️  Wake Up", "gold", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(200, 54),
		TextSize = 22,
		Visible = false,
	})
	UI.autoScale(wake)
	wake.Activated:Connect(function()
		Remotes.Event("RP"):FireServer("Wake")
	end)
	player:GetAttributeChangedSignal("Sleeping"):Connect(function()
		wake.Visible = player:GetAttribute("Sleeping") == true
	end)

	HUD.Buttons = buttons
end

return HUD
