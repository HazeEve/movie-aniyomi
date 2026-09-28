--!nonstrict
-- Runway voting (1–5 hearts), theme announcement and results podium UI.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local UI = require(script.Parent.Parent.UI)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Config = require(ReplicatedStorage.Shared.Config)
local P = UI.P

local Show = {}
local player = Players.LocalPlayer

function Show.Init(controllers)
	local gui = UI.screen("AuraShow", 8)
	local state = ReplicatedStorage:WaitForChild("ShowState")

	-- ============ vote panel ============
	local vote = UI.panel(gui, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.fromOffset(560, 150),
		Visible = false,
	})
	UI.autoScale(vote)
	local head = UI.new("ImageLabel", { BackgroundColor3 = P.Lilac, Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(64, 64), Parent = vote })
	UI.round(head)
	UI.stroke(head, P.Champagne, 2, 0.2)
	local nowL = UI.label(vote, "NOW WALKING", { Position = UDim2.fromOffset(92, 14), Size = UDim2.fromOffset(300, 18), TextSize = 13, TextColor3 = P.Blush })
	local nameL = UI.label(vote, "", { Position = UDim2.fromOffset(92, 32), Size = UDim2.fromOffset(300, 30), TextSize = 24, Font = UI.Font.Title, TextColor3 = P.Champagne, TextTruncate = Enum.TextTruncate.AtEnd })
	local themeL = UI.label(vote, "", { Position = UDim2.fromOffset(92, 60), Size = UDim2.fromOffset(300, 20), TextSize = 14, TextColor3 = P.Lilac })
	local shop = UI.button(vote, "🛍  Shop the Look", "gold", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 18), Size = UDim2.fromOffset(170, 44), TextSize = 16 })
	local heartsRow = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 90), Size = UDim2.new(1, -32, 0, 48), Parent = vote })
	UI.list(heartsRow, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	local hearts = {}
	local myVote = 0
	local function paint()
		for i, h in hearts do
			local on = i <= myVote
			h.Text = on and "💗" or "🤍"
			h.TextColor3 = on and P.Heart or P.Ivory
		end
	end
	for i = 1, 5 do
		local h = UI.button(heartsRow, "🤍", "ghost", { Size = UDim2.fromOffset(62, 48), TextSize = 40, LayoutOrder = i, Font = UI.Font.Title })
		h.Activated:Connect(function()
			myVote = i
			paint()
			Remotes.Event("Show"):FireServer("Vote", i)
			local sc = h:FindFirstChildOfClass("UIScale")
			if sc then
				sc.Scale = 1.35
				UI.tween(sc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
			end
		end)
		hearts[i] = h
	end
	local timerBar = UI.new("Frame", { BackgroundColor3 = P.Blush, Position = UDim2.new(0, 16, 1, -6), Size = UDim2.new(1, -32, 0, 3), Parent = vote })
	UI.round(timerBar)

	-- model-only panel
	local modelPanel = UI.panel(gui, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.fromOffset(620, 160),
		Visible = false,
	})
	UI.autoScale(modelPanel)
	UI.label(modelPanel, "✨ YOU'RE ON THE RUNWAY ✨", { Position = UDim2.fromOffset(18, 12), Size = UDim2.new(1, -36, 0, 30), TextSize = 22, Font = UI.Font.Title, TextColor3 = P.Champagne, TextXAlignment = Enum.TextXAlignment.Center })
	UI.label(modelPanel, "Walk to the glowing circle, strike a pose, then walk back!", { Position = UDim2.fromOffset(18, 42), Size = UDim2.new(1, -36, 0, 20), TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = P.Lilac })
	-- runway poses (Roblox's built-in emotes work in every game)
	local poses = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 68), Size = UDim2.new(1, -28, 0, 40), Parent = modelPanel })
	UI.list(poses, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	local POSES = { { "👋", "wave" }, { "👉", "point" }, { "🙌", "cheer" }, { "😂", "laugh" }, { "💃 1", "dance" }, { "💃 2", "dance2" }, { "💃 3", "dance3" } }
	for i, pz in POSES do
		local b = UI.button(poses, pz[1], "light", { LayoutOrder = i, Size = UDim2.fromOffset(72, 38), TextSize = 18 })
		b.Activated:Connect(function()
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then
				pcall(function()
					hum:PlayEmote(pz[2])
				end)
			end
		end)
	end
	local auc = UI.button(modelPanel, "🔨 Auction a Limited", "secondary", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(0.5, -6, 0, 116), Size = UDim2.fromOffset(200, 32), TextSize = 14 })
	auc.Activated:Connect(function()
		UI.open("Auction")
	end)
	-- shortcut: every catalog emote as a runway pose
	local emo = UI.button(modelPanel, "✨ Catalog Emotes", "gold", { AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0.5, 6, 0, 116), Size = UDim2.fromOffset(200, 32), TextSize = 14 })
	emo.Activated:Connect(function()
		controllers.Catalog.OpenEmotes()
	end)

	shop.Activated:Connect(function()
		local id = state:GetAttribute("ModelId")
		if id and id ~= 0 then
			controllers.Look.Open(id)
		end
	end)

	local lastModel = 0
	local function refresh()
		local phase = state:GetAttribute("Phase")
		local modelId = state:GetAttribute("ModelId") or 0
		local runway = phase == "Runway" and modelId ~= 0
		vote.Visible = runway and modelId ~= player.UserId
		modelPanel.Visible = runway and modelId == player.UserId
		if modelId ~= lastModel then
			lastModel = modelId
			myVote = 0
			paint()
			if modelId ~= 0 then
				head.Image = UI.headshot(modelId)
				nameL.Text = state:GetAttribute("ModelName") or ""
				themeL.Text = "Theme: " .. (state:GetAttribute("Theme") or "")
				nowL.Text = ("NOW WALKING  •  %d / %d"):format(state:GetAttribute("ModelIndex") or 0, state:GetAttribute("ModelCount") or 0)
			end
		end
	end
	for _, a in { "Phase", "ModelId", "ModelName" } do
		state:GetAttributeChangedSignal(a):Connect(refresh)
	end
	refresh()
	-- if the instrument panel is open, lift the voting panels to the top
	local function placePanels()
		local top = controllers.Music and controllers.Music.IsPlaying and controllers.Music.IsPlaying()
		local anchor = top and Vector2.new(0.5, 0) or Vector2.new(0.5, 1)
		local pos = top and UDim2.new(0.5, 0, 0, 74) or UDim2.new(0.5, 0, 1, -16)
		for _, f in { vote, modelPanel } do
			if f.AnchorPoint ~= anchor then
				f.AnchorPoint = anchor
				f.Position = pos
			end
		end
	end
	RunService.Heartbeat:Connect(function()
		placePanels()
		if vote.Visible then
			local left = (state:GetAttribute("EndsAt") or 0) - workspace:GetServerTimeNow()
			timerBar.Size = UDim2.new(math.clamp(left / Config.Show.RunwayTimePerModel, 0, 1), -32, 0, 3)
		end
	end)

	-- ============ theme splash ============
	local splash = UI.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38), Size = UDim2.fromOffset(900, 170), Visible = false, Parent = gui })
	UI.autoScale(splash)
	local splashTop = UI.label(splash, "THIS ROUND'S THEME", { Size = UDim2.new(1, 0, 0, 34), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 26, TextColor3 = P.Blush, Font = UI.Font.Title, TextStrokeTransparency = 0.5, TextStrokeColor3 = P.PlumDeep })
	local splashText = UI.label(splash, "", { Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 110), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 72, TextColor3 = P.Champagne, Font = UI.Font.Luxe, TextStrokeTransparency = 0.3, TextStrokeColor3 = P.PlumDeep })
	local splashScale = UI.new("UIScale", { Parent = splashText })
	local function showSplash(top: string, text: string)
		splashTop.Text = top
		splashText.Text = text
		splash.Visible = true
		splashScale.Scale = 0.4
		UI.tween(splashScale, 0.6, { Scale = 1 }, Enum.EasingStyle.Back)
		task.delay(4, function()
			splash.Visible = false
		end)
	end

	-- ============ results ============
	local results = UI.panel(gui, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(760, 430), Visible = false })
	UI.autoScale(results, Vector2.new(760, 430))
	UI.label(results, "🏆  RESULTS", { Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, 44), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 38, Font = UI.Font.Luxe, TextColor3 = P.Champagne })
	local resTheme = UI.label(results, "", { Position = UDim2.fromOffset(0, 60), Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 16, TextColor3 = P.Lilac })
	local podium = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 96), Size = UDim2.new(1, -40, 0, 250), Parent = results })
	local others = UI.label(results, "", { Position = UDim2.fromOffset(24, 352), Size = UDim2.new(1, -48, 0, 60), TextSize = 15, TextColor3 = P.Lilac, TextXAlignment = Enum.TextXAlignment.Center })
	local closeRes = UI.button(results, "X", "light", { Font = UI.Font.Title, TextSize = 22, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(40, 40) })
	closeRes.Activated:Connect(function()
		results.Visible = false
	end)

	local function heartString(score: number): string
		local full = math.floor(score + 0.5)
		return string.rep("💗", full) .. string.rep("🤍", 5 - full)
	end

	local function showResults(list, theme)
		for _, c in podium:GetChildren() do
			c:Destroy()
		end
		resTheme.Text = theme and ("Theme: " .. theme) or ""
		local slots = { { 2, 0, 190, P.Pearl }, { 1, 240, 230, P.Gold }, { 3, 480, 170, P.RoseGold } }
		for _, s in slots do
			local place, x, h, col = s[1], s[2], s[3], s[4]
			local r = list[place]
			local card = UI.card(podium, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, x, 1, 0), Size = UDim2.fromOffset(220, h) })
			UI.stroke(card, col, 3, 0)
			UI.label(card, ({ "🥇", "🥈", "🥉" })[place], { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 6), TextSize = 34, TextXAlignment = Enum.TextXAlignment.Center })
			if r then
				local img = UI.new("ImageLabel", { BackgroundColor3 = P.Lilac, Image = UI.headshot(r.UserId), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 46), Size = UDim2.fromOffset(72, 72), Parent = card })
				UI.round(img)
				UI.label(card, r.DisplayName, { Position = UDim2.fromOffset(8, 122), Size = UDim2.new(1, -16, 0, 24), TextColor3 = P.Text, TextXAlignment = Enum.TextXAlignment.Center, Font = UI.Font.Title, TextTruncate = Enum.TextTruncate.AtEnd })
				UI.label(card, heartString(r.Score) .. ("  %.1f"):format(r.Score), { Position = UDim2.fromOffset(8, 148), Size = UDim2.new(1, -16, 0, 22), TextColor3 = P.Heart, TextXAlignment = Enum.TextXAlignment.Center, TextSize = 18 })
				if h > 180 then
					UI.label(card, ("%d votes  •  +%d ✨"):format(r.Votes, r.Coins or 0), { Position = UDim2.fromOffset(8, 174), Size = UDim2.new(1, -16, 0, 20), TextColor3 = P.TextSoft, TextXAlignment = Enum.TextXAlignment.Center, TextSize = 14 })
				end
			else
				UI.label(card, "—", { Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 40), TextColor3 = P.TextSoft, TextXAlignment = Enum.TextXAlignment.Center, TextSize = 30 })
			end
		end
		local rest = {}
		for i = 4, #list do
			table.insert(rest, ("%d. %s %.1f♥"):format(i, list[i].DisplayName, list[i].Score))
		end
		others.Text = table.concat(rest, "   ")
		results.Visible = true
		results.BackgroundTransparency = 1
		UI.tween(results, 0.4, { BackgroundTransparency = 0.04 })
		task.delay(Config.Show.ResultsTime, function()
			results.Visible = false
		end)
		for i, r in list do
			if r.UserId == player.UserId then
				controllers.Notify.Show(("You placed #%d with %.1f hearts! +%d ✨ Sparkles"):format(i, r.Score, r.Coins or 0), "success")
			end
		end
	end

	Remotes.Event("Show").OnClientEvent:Connect(function(kind, a, b)
		if kind == "Theme" then
			showSplash("THIS ROUND'S THEME", a)
			if player:GetAttribute("InShow") then
				controllers.Notify.Show("Open 👗 Catalog and style your look before the timer ends!", "info")
			end
		elseif kind == "Model" then
			if a == player.UserId then
				showSplash("IT'S YOUR TURN", "Strike a pose! 💃")
			end
		elseif kind == "Results" then
			showResults(a, b)
		end
	end)
end

return Show
