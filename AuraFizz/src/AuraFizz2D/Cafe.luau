--!nonstrict
-- AuraFizz2D · Cafe — the 2D window and the full "make one drink" flow.
--   customer orders ONE drink -> every step of YOUR DrinkRecipes steps in 2D
--   (shelf screens + mini-games) -> Serve -> stars, tip, confetti.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent.Config)
local Paint = require(script.Parent.Paint)
local FX = require(script.Parent.FX)
local UI = require(script.Parent.UI)
local Bridge = require(script.Parent.Bridge)
local Storage = require(script.Parent.Storage)
local MiniGames = require(script.Parent.MiniGames)

local Cafe = {}
local T = Config.Theme
local P = UDim2.fromScale
local rng = Random.new()

local STORAGE_GLYPH = { CupRack = "🥤", Pantry = "🫙", Fridge = "🧊", Freezer = "❄", BarShelf = "🍯" }

-- ================= server link (optional) =================
local remote = ReplicatedStorage:FindFirstChild("AuraFizz2DRemote")
local function call(...)
	remote = remote or ReplicatedStorage:FindFirstChild("AuraFizz2DRemote")
	if not remote then
		return nil
	end
	local ok, res = pcall(remote.InvokeServer, remote, ...)
	return if ok then res else nil
end

-- ================= window =================
local gui, stage, top, left, main
local state = { tips = 0, served = 0, starSum = 0, busy = false }

local function background(parent)
	local z = parent.ZIndex
	for i = 1, 9 do
		local s = rng:NextNumber(0.08, 0.2)
		local b = Paint.blob(parent, Config.Pastels[(i % #Config.Pastels) + 1], { Position = P(rng:NextNumber(0, 1), rng:NextNumber(0.15, 1)),
			Size = P(s, s * 1.78), ZIndex = z, Blotch = false })
		b.BackgroundTransparency = 0.9
	end
	-- café awning: scalloped pastel edge along the top
	local n = 16
	for i = 0, n do
		local c = Config.Pastels[(i % 2 == 0) and 1 or 4]
		Paint.blob(parent, c, { Position = P(i / n, 0.005), Size = P(1 / n * 1.02, 0.07), ZIndex = z + 1, LightRot = 90 })
	end
	local band = Paint.new("Frame", { Position = P(0, 0), Size = P(1, 0.01), ZIndex = z + 1, Parent = parent })
	Paint.shade(band, Config.Pastels[1], 90, true)
end

local function ensureWindow()
	if gui and gui.Parent then
		return
	end
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	gui = Paint.new("ScreenGui", { Name = "AuraFizz2D", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 30,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false, Parent = pg })
	Paint.new("Frame", { Name = "Dim", Size = P(1, 1), BackgroundColor3 = Paint.C("#0f131c"), BackgroundTransparency = 0.35, Parent = gui })
	stage = Paint.new("Frame", { Name = "Stage", AnchorPoint = Vector2.new(0.5, 0.5), Position = P(0.5, 0.5), Size = P(0.96, 0.94),
		BackgroundColor3 = Paint.C(T.Ground), ZIndex = 2, Parent = gui })
	Paint.new("UIAspectRatioConstraint", { AspectRatio = 16 / 9, Parent = stage })
	Paint.round(stage, UDim.new(0, 26))
	stage.ClipsDescendants = true
	background(stage)

	top = Paint.new("Frame", { Name = "Top", BackgroundTransparency = 1, Position = P(0.015, 0.075), Size = P(0.97, 0.085), ZIndex = 10, Parent = stage })
	local logo = UI.chip(top, "AURAFIZZ", T.Accent, { Position = P(0, 0.1), Size = P(0.14, 0.8), TextColor = T.TextDark })
	FX.bob(logo, 0.03, 3)
	Paint.new("Frame", { Name = "Steps", BackgroundTransparency = 1, Position = P(0.16, 0.05), Size = P(0.56, 0.9), ZIndex = 11, Parent = top })
	local tips = UI.chip(top, "🪙 0", T.Gold, { Position = P(0.74, 0.1), Size = P(0.14, 0.8), TextColor = T.TextDark })
	tips.Name = "Tips"
	local close = UI.button(top, "✕", T.Bad, { Position = P(0.965, 0.5), Size = P(0.05, 0.8) })
	Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = close })
	close.Activated:Connect(function()
		Cafe.close()
	end)

	left = UI.card(stage, T.Paper, { Name = "Order", Position = P(0.015, 0.18), Size = P(0.3, 0.8), Radius = 24, ZIndex = 10 })
	main = UI.card(stage, T.Panel, { Name = "Main", Position = P(0.33, 0.18), Size = P(0.655, 0.8), Radius = 24, ZIndex = 10 })
end

local function setTips(v)
	local chip = top and top:FindFirstChild("Tips")
	if chip then
		FX.countUp(chip:FindFirstChild("Text"), state.tips, v, 0.8, "🪙 %d")
		state.tips = v
		FX.bounce(chip, 0.2)
	end
end

local function freshPanel()
	main:ClearAllChildren()
	Paint.round(main, UDim.new(0, 24))
	Paint.shade(main, T.Panel, 60, true)
	local panel = Paint.new("Frame", { Name = "Panel", BackgroundTransparency = 1, Size = P(1, 1), ZIndex = main.ZIndex + 1, Parent = main })
	FX.slideIn(panel)
	return panel
end

-- ================= step tracker =================
local function drawTracker(steps, current)
	local row = top:FindFirstChild("Steps")
	row:ClearAllChildren()
	Paint.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0.008, 0), Parent = row })
	for i, s in steps do
		local col = if i < current then T.Good elseif i == current then T.Gold else T.PanelLight
		local dot = UI.card(row, col, { Size = P(0.06, if i == current then 0.9 else 0.7), Corner = UDim.new(0.5, 0) })
		dot.LayoutOrder = i
		Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height, Parent = dot })
		local glyph
		if i < current then
			glyph = "✓"
		elseif s.kind == "storage" then
			glyph = STORAGE_GLYPH[s.station] or "📦"
		elseif s.kind == "serve" then
			glyph = "🛎"
		else
			local a = Bridge.action(s.action)
			glyph = a and a.glyph or "•"
		end
		Paint.text(dot, glyph, { Color = T.TextDark, Position = P(0.15, 0.15), Size = P(0.7, 0.7), ZIndex = dot.ZIndex + 1 })
		if i == current then
			FX.pop(dot, 0, 0.35)
		end
	end
end

-- ================= order card + live drink preview =================
local order = {}

local function drawPreview(frame, recipe, progress, hasCup)
	frame:ClearAllChildren()
	local holder = Paint.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = P(0.5, 0.5), Size = P(1, 1),
		ZIndex = frame.ZIndex + 1, Parent = frame })
	Paint.square(holder)
	if not hasCup then
		local ghost = Paint.new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.95), Size = P(0.4, 0.62),
			BackgroundColor3 = Paint.C("#3a2f45"), BackgroundTransparency = 0.88, ZIndex = holder.ZIndex + 1, Parent = holder })
		Paint.round(ghost, 0.18)
		Paint.text(ghost, "?", { Color = "#3a2f45", Position = P(0.2, 0.3), Size = P(0.6, 0.4), ZIndex = ghost.ZIndex + 1 }).TextTransparency = 0.6
		return
	end
	local vessel = Paint.cup(holder, recipe.cup, { Behind = T.Paper, NoLid = progress < 1 })
	if progress > 0 then
		local grad, mode = Bridge.liquid(recipe)
		local level = math.clamp(progress, 0, 1) * 0.86
		if mode == "Layers" and #grad > 1 then
			for i, c in grad do
				local h = level / #grad
				Paint.new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 1 - (i - 1) * h), Size = P(1, h + 0.005),
					BackgroundColor3 = c, ZIndex = vessel.ZIndex + 1, Parent = vessel })
			end
		else
			local liquid = Paint.new("Frame", { Name = "Liquid", AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 1), Size = P(1, level),
				BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = vessel.ZIndex + 1, Parent = vessel })
			local keys = {}
			for i, c in grad do
				table.insert(keys, ColorSequenceKeypoint.new(if #grad == 1 then (i - 1) else (i - 1) / (#grad - 1), c))
			end
			if #keys == 1 then
				table.insert(keys, ColorSequenceKeypoint.new(1, grad[1]))
			end
			Paint.new("UIGradient", { Color = ColorSequence.new(keys), Rotation = 270, Parent = liquid })
		end
		local surface = Paint.blob(vessel, Paint.tone(Bridge.drinkColor(recipe)).light, { AnchorPoint = Vector2.new(0.5, 0.5), Position = P(0.5, 1 - level),
			Size = P(1, 0.04), ZIndex = vessel.ZIndex + 2, Blotch = false })
		surface.BackgroundTransparency = 0.35
	end
end

local function drawOrder(recipe, look)
	left:ClearAllChildren()
	Paint.round(left, UDim.new(0, 24))
	Paint.shade(left, T.Paper, 60, true)
	local z = left.ZIndex
	-- customer peeking over the ticket
	local cust, setMood = UI.customer(left, look, { AnchorPoint = Vector2.new(0, 1), Position = P(0.05, 0.24), Size = P(0.3, 0.22), ZIndex = z + 2 })
	FX.pop(cust, 0.05)
	FX.bob(cust, 0.004, 2.2)
	Paint.text(left, look.Name .. " ordered:", { Color = "#8a7a90", Position = P(0.36, 0.05), Size = P(0.6, 0.06), AlignX = Enum.TextXAlignment.Left, ZIndex = z + 2 })
	Paint.text(left, recipe.name, { Color = T.TextDark, Position = P(0.36, 0.11), Size = P(0.6, 0.08), AlignX = Enum.TextXAlignment.Left, ZIndex = z + 2 })
	UI.chip(left, recipe.tier or "", Config.TierColor[recipe.tier] or T.Accent, { Position = P(0.36, 0.195), Size = P(0.32, 0.045), ZIndex = z + 2 })
	-- your picture of the finished drink
	local pic = Paint.new("Frame", { BackgroundTransparency = 1, Position = P(0.05, 0.27), Size = P(0.42, 0.3), ZIndex = z + 1, Parent = left })
	Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = pic })
	Bridge.icon(pic, "drink", recipe.id, { Behind = T.Paper })
	Paint.text(left, "Goal", { Color = "#8a7a90", Position = P(0.05, 0.25), Size = P(0.2, 0.04), AlignX = Enum.TextXAlignment.Left, ZIndex = z + 2 })
	-- the live one you're making
	local prev = Paint.new("Frame", { Name = "Preview", BackgroundTransparency = 1, Position = P(0.53, 0.27), Size = P(0.42, 0.3), ZIndex = z + 1, Parent = left })
	Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = prev })
	Paint.text(left, "Yours", { Color = "#8a7a90", Position = P(0.53, 0.25), Size = P(0.2, 0.04), AlignX = Enum.TextXAlignment.Left, ZIndex = z + 2 })
	-- ingredient list (your recipe text)
	local list = Paint.new("Frame", { BackgroundTransparency = 1, Position = P(0.07, 0.6), Size = P(0.86, 0.38), ZIndex = z + 1, Parent = left })
	Paint.new("UIListLayout", { Padding = UDim.new(0.02, 0), Parent = list })
	for i, txt in recipe.ingredients or {} do
		local row = Paint.new("Frame", { BackgroundTransparency = 1, Size = P(1, 0.15), LayoutOrder = i, ZIndex = z + 1, Parent = list })
		Paint.blob(row, Config.Pastels[(i % #Config.Pastels) + 1], { AnchorPoint = Vector2.new(0, 0.5), Position = P(0, 0.5), Size = P(0.05, 0.4), ZIndex = z + 2, Blotch = false })
		Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = row:FindFirstChild("Blob") })
		Paint.text(row, txt, { Color = T.TextDark, Position = P(0.08, 0.1), Size = P(0.9, 0.8), AlignX = Enum.TextXAlignment.Left, ZIndex = z + 2, MaxSize = 24 })
	end
	order = { recipe = recipe, preview = prev, setMood = setMood, cust = cust, hasCup = false, progress = 0 }
	drawPreview(prev, recipe, 0, false)
end

local function updatePreview(progress, hasCup)
	order.progress = progress
	order.hasCup = hasCup or order.hasCup
	drawPreview(order.preview, order.recipe, progress, order.hasCup)
	FX.bounce(order.preview, 0.08)
end

-- ================= one drink, start to finish =================
-- Returns { Scores = {..}, Total = 0..100, Stars = 0..5 } or nil if closed.
function Cafe.makeDrink(recipe, look, orderId)
	look = look or UI.randomLook(rng)
	drawOrder(recipe, look)
	local steps = Bridge.stepsOf(recipe)
	local scores = {}
	local work = 0
	for _, s in steps do
		if s.kind ~= "serve" then
			work += 1
		end
	end
	local doneWork = 0
	for i, s in steps do
		if not (gui and gui.Enabled) then
			return nil
		end
		drawTracker(steps, i)
		if s.kind == "serve" then
			break
		end
		local panel = freshPanel()
		local score
		if s.kind == "storage" then
			score = Storage.play(panel, s.station, s.items, {
				onPick = function()
					if s.station == "CupRack" then
						updatePreview(order.progress, true)
					end
				end,
			})
		else
			local extra: { [string]: any } = {}
			-- fruit / syrup colours for the scenes come from the recipe's items
			for _, st in recipe.steps do
				local it = Bridge.item(st[2])
				if it and it.color then
					if it.storage == "Fridge" and not extra.fruitColor then
						extra.fruitColor = it.color
						extra.fruitId = st[2]
					elseif it.storage == "BarShelf" and not extra.syrupColor then
						extra.syrupColor = it.color
					end
				end
			end
			score = MiniGames.play(panel, s.action, { label = s.label, color = Bridge.drinkColor(recipe), recipe = recipe, extra = extra })
		end
		if score == nil then
			return nil
		end
		table.insert(scores, score)
		doneWork += 1
		updatePreview(doneWork / work, order.hasCup)
	end
	return Cafe.serve(recipe, scores, orderId)
end

-- ================= serve + results =================
function Cafe.serve(recipe, scores, orderId)
	local panel = freshPanel()
	local z = panel.ZIndex
	updatePreview(1, true)
	local sum = 0
	for _, s in scores do
		sum += s
	end
	local local_total = if #scores > 0 then sum / #scores * 100 else 100
	local result = orderId and call("Finish", orderId, scores)
	local total = result and result.Total or math.floor(local_total + 0.5)
	local stars = result and result.Stars or math.floor(total / 20 * 2 + 0.5) / 2
	local tip = result and result.Tip or math.floor((Config.TierTip[recipe.tier] or 10) * total / 100 + 0.5)

	FX.sound("Serve")
	Paint.text(panel, "🛎  Order up!", { Position = P(0.04, 0.05), Size = P(0.6, 0.09), AlignX = Enum.TextXAlignment.Left, ZIndex = z + 2 })
	-- the drink slides to the customer
	local drinkPic = Paint.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = P(0.2, 0.46), Size = P(0.26, 0.46), ZIndex = z + 2, Parent = panel })
	Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = drinkPic })
	Bridge.icon(drinkPic, "drink", recipe.id, { Behind = T.Panel })
	FX.pop(drinkPic, 0.1)

	-- stars
	local starRow = Paint.new("Frame", { BackgroundTransparency = 1, Position = P(0.4, 0.14), Size = P(0.56, 0.14), ZIndex = z + 2, Parent = panel })
	Paint.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0.02, 0), Parent = starRow })
	for i = 1, 5 do
		local full = stars >= i
		local half = not full and stars >= i - 0.5
		local s = Paint.text(starRow, "★", { Color = if full then T.Gold elseif half then "#f7e3a5" else "#46506b", Size = P(0.18, 1), ZIndex = z + 3 })
		s.LayoutOrder = i
		FX.pop(s, 0.3 + i * 0.15)
		if full then
			task.delay(0.3 + i * 0.15, function()
				FX.sound("Perfect")
			end)
		end
	end

	-- step bars
	local steps = Bridge.stepsOf(recipe)
	local bars = Paint.new("ScrollingFrame", { BackgroundTransparency = 1, Position = P(0.4, 0.31), Size = P(0.56, 0.42), ZIndex = z + 2,
		ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = panel })
	Paint.new("UIListLayout", { Padding = UDim.new(0, 6), Parent = bars })
	local k = 0
	for _, s in steps do
		if s.kind == "serve" then
			continue
		end
		k += 1
		local sc = scores[k] or 0
		local name
		if s.kind == "storage" then
			name = Bridge.station(s.station).name or s.station
		else
			local a = Bridge.action(s.action)
			name = a and a.verb or s.action
		end
		local row = Paint.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 28), LayoutOrder = k, ZIndex = z + 2, Parent = bars })
		Paint.text(row, name, { Color = T.TextSoft, Size = P(0.34, 1), AlignX = Enum.TextXAlignment.Left, ZIndex = z + 3 })
		local g = UI.gauge(row, 0.95, 1, { Position = P(0.36, 0.2), Size = P(0.44, 0.6), Color = (select(2, UI.grade(sc))) })
		g.zone.BackgroundTransparency = 1
		task.delay(0.2 + k * 0.08, function()
			for t = 0, 1, 0.1 do
				g.set(sc * t)
				task.wait(0.02)
			end
			g.set(sc)
		end)
		local word, col = UI.grade(sc)
		Paint.text(row, word, { Color = col, Position = P(0.82, 0), Size = P(0.18, 1), ZIndex = z + 3 })
	end

	-- tip + customer reaction
	local tipChip = UI.chip(panel, "+🪙 0", T.Gold, { AnchorPoint = Vector2.new(0.5, 0.5), Position = P(0.2, 0.78), Size = P(0.26, 0.09) })
	FX.pop(tipChip, 0.6)
	task.delay(0.7, function()
		FX.countUp(tipChip:FindFirstChild("Text"), 0, tip, 0.9, "+🪙 %d")
		FX.sound("Coins")
	end)
	local mood = if stars >= 4 then "happy" elseif stars >= 2.5 then "ok" else "sad"
	task.delay(0.5, function()
		if order.setMood then
			order.setMood(mood)
			FX.wobble(order.cust, if mood == "happy" then 6 else 2, 0.6)
			FX.sound(if mood == "happy" then "Happy" elseif mood == "sad" then "Angry" else "Sip")
		end
	end)
	if stars >= 4.5 then
		FX.confetti(stage, 60)
	end

	state.served += 1
	state.starSum += stars
	setTips(state.tips + tip)
	return { Scores = scores, Total = total, Stars = stars, Tip = tip, Panel = panel }
end

-- ================= screens =================
local function buttonsRow(panel, items)
	for i, it in items do
		local b = UI.button(panel, it[1], it[2], { Position = P(0.5 + (i - (#items + 1) / 2) * 0.3, 0.88), Size = P(0.26, 0.1) })
		b.Activated:Connect(it[3])
	end
end

function Cafe.home()
	ensureWindow()
	left:ClearAllChildren()
	Paint.round(left, UDim.new(0, 24))
	Paint.shade(left, T.Paper, 60, true)
	local lz = left.ZIndex
	Paint.text(left, "Welcome to", { Color = "#8a7a90", Position = P(0.1, 0.1), Size = P(0.8, 0.06), ZIndex = lz + 1 })
	Paint.text(left, "AURAFIZZ", { Color = T.TextDark, Position = P(0.1, 0.16), Size = P(0.8, 0.1), ZIndex = lz + 1 })
	local c = UI.customer(left, UI.randomLook(rng), { Position = P(0.5, 0.78), Size = P(0.5, 0.42), ZIndex = lz + 2, Mood = "happy" })
	FX.bob(c, 0.006, 2)
	Paint.text(left, string.format("Served %d  ·  🪙 %d", state.served, state.tips), { Color = "#8a7a90", Position = P(0.1, 0.86), Size = P(0.8, 0.06), ZIndex = lz + 1 })
	drawTracker({}, 0)

	local panel = freshPanel()
	local z = panel.ZIndex
	Paint.text(panel, "What's next?", { Position = P(0.05, 0.08), Size = P(0.9, 0.1), ZIndex = z + 1 })
	local serve = UI.button(panel, "🛎  Serve customers", T.Accent, { Position = P(0.5, 0.38), Size = P(0.56, 0.14) })
	FX.pop(serve, 0.1)
	local menu = UI.button(panel, "📖  Practice from the menu", "#8ec5f0", { Position = P(0.5, 0.58), Size = P(0.56, 0.14) })
	FX.pop(menu, 0.2)
	serve.Activated:Connect(function()
		task.spawn(Cafe.shift)
	end)
	menu.Activated:Connect(function()
		Cafe.menu()
	end)
end

function Cafe.menu()
	ensureWindow()
	local panel = freshPanel()
	local z = panel.ZIndex
	Paint.text(panel, "📖  Menu", { Position = P(0.04, 0.04), Size = P(0.5, 0.08), AlignX = Enum.TextXAlignment.Left, ZIndex = z + 1 })
	local back = UI.button(panel, "Back", T.PanelLight, { Position = P(0.88, 0.08), Size = P(0.16, 0.08), TextColor = T.Text })
	back.Activated:Connect(Cafe.home)
	local tabs = Paint.new("ScrollingFrame", { BackgroundTransparency = 1, Position = P(0.03, 0.15), Size = P(0.94, 0.08), ZIndex = z + 1,
		ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(), Parent = panel })
	Paint.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), Parent = tabs })
	local grid = Paint.new("ScrollingFrame", { BackgroundTransparency = 1, Position = P(0.03, 0.25), Size = P(0.94, 0.72), ZIndex = z + 1,
		ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = panel })
	local layout = Paint.new("UIGridLayout", { CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	local function fit()
		local cell = math.floor((grid.AbsoluteSize.X - 8) / 5) - 8
		layout.CellSize = UDim2.fromOffset(cell, math.floor(cell * 1.25))
	end
	fit()
	grid:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	local function show(cat)
		for _, ch in grid:GetChildren() do
			if ch:IsA("GuiObject") then
				ch:Destroy()
			end
		end
		for i, r in Bridge.allRecipes() do
			if r.category ~= cat then
				continue
			end
			local cell = Paint.new("TextButton", { Text = "", AutoButtonColor = false, LayoutOrder = i, ZIndex = z + 2, Parent = grid })
			Paint.round(cell, UDim.new(0, 16))
			Paint.shade(cell, T.PanelLight, 60, true)
			local pic = Paint.new("Frame", { BackgroundTransparency = 1, Position = P(0.08, 0.04), Size = P(0.84, 0.66), ZIndex = z + 3, Parent = cell })
			Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = pic })
			Bridge.icon(pic, "drink", r.id, { Behind = T.PanelLight })
			Paint.text(cell, r.name, { Color = T.Text, Position = P(0.05, 0.72), Size = P(0.9, 0.13), ZIndex = z + 3, MaxSize = 18 })
			UI.chip(cell, r.tier or "", Config.TierColor[r.tier] or T.Accent, { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0.86), Size = P(0.7, 0.1) })
			cell.Activated:Connect(function()
				FX.bounce(cell, 0.15)
				task.spawn(function()
					local res = call("NextOrder", "practice", r.id)
					local oid = res and res.OrderId
					local out = Cafe.makeDrink(r, UI.randomLook(rng), oid)
					if out then
						buttonsRow(out.Panel, { { "Menu", "#8ec5f0", Cafe.menu }, { "Home", T.PanelLight, Cafe.home } })
					end
				end)
			end)
		end
	end
	for i, cat in Bridge.categories() do
		local short = cat:gsub(" Drinks", ""):gsub("%s*%(.-%)", "")
		local b = UI.button(tabs, short, Config.Pastels[(i % #Config.Pastels) + 1], { AnchorPoint = Vector2.new(0, 0), Size = UDim2.new(0, 170, 1, -6) })
		b.LayoutOrder = i
		b.Activated:Connect(function()
			show(cat)
		end)
		if i == 1 then
			show(cat)
		end
	end
end

-- A shift of customers: each orders one drink the player can make.
function Cafe.shift()
	if state.busy then
		return
	end
	state.busy = true
	local all = Bridge.allRecipes()
	for n = 1, Config.CustomersPerShift do
		if not (gui and gui.Enabled) then
			break
		end
		local res = call("NextOrder", "customer")
		local recipe = res and Bridge.recipe(res.DrinkId)
		if not recipe then
			-- offline / no server: pick from the free "Tasty" starters first, then anything
			local pool = {}
			for _, r in all do
				if r.tier == "Tasty" then
					table.insert(pool, r)
				end
			end
			if #pool == 0 then
				pool = all
			end
			recipe = pool[rng:NextInteger(1, #pool)]
		end
		if not recipe then
			warn("[AuraFizz2D] no recipes found in ReplicatedStorage.Drinks.DrinkRecipes")
			break
		end
		FX.sound("Order")
		local out = Cafe.makeDrink(recipe, UI.randomLook(rng), res and res.OrderId)
		if not out then
			break
		end
		local nextEvt = Instance.new("BindableEvent")
		local label = if n < Config.CustomersPerShift then "Next customer" else "Finish shift"
		buttonsRow(out.Panel, { { label, T.Accent, function()
			nextEvt:Fire()
		end } })
		nextEvt.Event:Wait()
		nextEvt:Destroy()
	end
	state.busy = false
	if gui and gui.Enabled then
		Cafe.home()
		FX.confetti(stage, 40)
		FX.sound("LevelUp")
	end
end

-- ================= open / close / popups =================
function Cafe.open()
	ensureWindow()
	gui.Enabled = true
	FX.pop(stage, 0, 0.4)
	FX.sound("Open")
	Cafe.home()
end

function Cafe.close()
	if gui then
		gui.Enabled = false
		FX.sound("Close")
		main:ClearAllChildren() -- ends any running mini-game
		state.busy = false
	end
end

function Cafe.isOpen()
	return gui ~= nil and gui.Enabled
end

-- Compact popup used when YOUR 3D stations call the API for a single step.
function Cafe.popup()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local pop = Paint.new("ScreenGui", { Name = "AuraFizz2DPopup", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 31, Parent = pg })
	Paint.new("Frame", { Size = P(1, 1), BackgroundColor3 = Paint.C("#0f131c"), BackgroundTransparency = 0.5, Parent = pop })
	local card = UI.card(pop, T.Panel, { AnchorPoint = Vector2.new(0.5, 0.5), Position = P(0.5, 0.52), Size = P(0.7, 0.72), Radius = 26, ZIndex = 2 })
	Paint.new("UIAspectRatioConstraint", { AspectRatio = 1.6, Parent = card })
	FX.pop(card, 0, 0.35)
	local panel = Paint.new("Frame", { Name = "Panel", BackgroundTransparency = 1, Size = P(1, 1), ZIndex = card.ZIndex + 1, Parent = card })
	local x = UI.button(card, "✕", T.Bad, { Position = P(0.965, 0.06), Size = P(0.06, 0.1) })
	Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = x })
	x.Activated:Connect(function()
		pop:Destroy()
	end)
	return panel, function()
		if pop.Parent then
			pop:Destroy()
		end
	end
end

Cafe.Storage = Storage
Cafe.MiniGames = MiniGames
return Cafe
