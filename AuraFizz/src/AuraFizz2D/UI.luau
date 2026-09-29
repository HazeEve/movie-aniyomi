--!nonstrict
-- AuraFizz2D · UI kit — painted buttons, cards, gauges, timers, customers.
local UserInputService = game:GetService("UserInputService")
local Config = require(script.Parent.Config)
local Paint = require(script.Parent.Paint)
local FX = require(script.Parent.FX)

local UI = {}
local T = Config.Theme
local P = UDim2.fromScale

-- Rounded painted card (panels, order ticket, shelves).
function UI.card(parent, color, props)
	props = props or {}
	local f = Paint.new("Frame", {
		Name = props.Name or "Card",
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
		Position = props.Position or P(0, 0),
		Size = props.Size or P(1, 1),
		ZIndex = props.ZIndex or (parent.ZIndex + 1),
		BackgroundTransparency = props.Transparency or 0,
		ClipsDescendants = props.Clip or false,
		Parent = parent,
	})
	Paint.round(f, props.Corner or UDim.new(0, props.Radius or 18))
	Paint.shade(f, color or T.Panel, props.LightRot or 60, props.Flat ~= false)
	return f
end

-- Chunky pill button with press bounce + click sound. Returns the TextButton.
-- Built as layers (children always draw above their parent in Roblox):
-- transparent button > darker "lip" > painted face > label.
function UI.button(parent, text, color, props)
	props = props or {}
	local col = color or T.Accent
	local b = Paint.new("TextButton", {
		Name = props.Name or "Button",
		AutoButtonColor = false,
		Text = "",
		BackgroundTransparency = 1,
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = props.Position or P(0.5, 0.5),
		Size = props.Size or P(0.3, 0.12),
		ZIndex = props.ZIndex or (parent.ZIndex + 2),
		Parent = parent,
	})
	local lip = Paint.new("Frame", { Name = "Lip", AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0.1), Size = P(1, 0.92),
		BackgroundColor3 = Paint.tone(col).shade, ZIndex = b.ZIndex, Parent = b })
	Paint.round(lip, UDim.new(0.5, 0))
	local face = Paint.new("Frame", { Name = "Face", AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0), Size = P(1, 0.92),
		ZIndex = b.ZIndex + 1, Parent = b })
	Paint.round(face, UDim.new(0.5, 0))
	Paint.shade(face, col, 90)
	Paint.text(b, text, { Color = props.TextColor or T.TextDark, Position = P(0.08, 0.1), Size = P(0.84, 0.7), ZIndex = b.ZIndex + 2 })
	b.MouseButton1Down:Connect(function()
		FX.bounce(b, 0.1)
		face.Position = P(0.5, 0.06)
	end)
	b.MouseButton1Up:Connect(function()
		face.Position = P(0.5, 0)
	end)
	b.MouseLeave:Connect(function()
		face.Position = P(0.5, 0)
	end)
	b.Activated:Connect(function()
		FX.sound("Click")
	end)
	return b
end

function UI.setButtonText(b, text)
	local l = b:FindFirstChild("Text")
	if l then
		l.Text = text
	end
end

-- Small rounded label chip (tier badges, station plates).
function UI.chip(parent, text, color, props)
	props = props or {}
	local c = UI.card(parent, color, { Position = props.Position, Size = props.Size or P(0.3, 0.08), AnchorPoint = props.AnchorPoint,
		Corner = UDim.new(0.5, 0), ZIndex = props.ZIndex })
	Paint.text(c, text, { Color = props.TextColor or T.TextDark, Position = P(0.08, 0.12), Size = P(0.84, 0.76), ZIndex = c.ZIndex + 1 })
	return c
end

-- Gauge with a gold zone. vertical = true fills bottom->top.
function UI.gauge(parent, zoneMin, zoneMax, props)
	props = props or {}
	local vertical = props.Vertical
	local g = UI.card(parent, "#1b2131", { Position = props.Position, Size = props.Size, AnchorPoint = props.AnchorPoint,
		Corner = UDim.new(0.5, 0), ZIndex = props.ZIndex, Clip = true })
	local z = g.ZIndex
	local zone = Paint.new("Frame", {
		Name = "Zone", BackgroundColor3 = Paint.C(T.Gold), BackgroundTransparency = 0.15, ZIndex = z + 1, Parent = g,
		AnchorPoint = if vertical then Vector2.new(0, 1) else Vector2.new(0, 0),
		Position = if vertical then P(0, 1 - zoneMin) else P(zoneMin, 0),
		Size = if vertical then P(1, zoneMax - zoneMin) else P(zoneMax - zoneMin, 1),
	})
	local fill = Paint.new("Frame", {
		Name = "Fill", ZIndex = z + 2, Parent = g, BackgroundTransparency = 0.05,
		AnchorPoint = if vertical then Vector2.new(0, 1) else Vector2.new(0, 0),
		Position = if vertical then P(0, 1) else P(0, 0),
		Size = if vertical then P(1, 0) else P(0, 1),
	})
	Paint.round(fill, UDim.new(0.5, 0))
	Paint.shade(fill, props.Color or T.Accent, if vertical then 0 else 90)
	local api = { frame = g, zone = zone }
	function api.set(p)
		p = math.clamp(p, 0, 1.2)
		local shown = math.min(p, 1)
		fill.Size = if vertical then P(1, shown) else P(shown, 1)
		local over = p > zoneMax + 0.02
		fill.BackgroundColor3 = if over then Paint.C(T.Bad) else Color3.new(1, 1, 1)
	end
	function api.setZone(a, b)
		zone.Position = if vertical then P(0, 1 - a) else P(a, 0)
		zone.Size = if vertical then P(1, b - a) else P(b - a, 1)
	end
	return api
end

-- Countdown bar across the top of a panel. Returns remaining() and stop().
function UI.timer(parent, seconds, props)
	props = props or {}
	local bar = UI.card(parent, "#1b2131", { Position = props.Position or P(0.05, 0.02), Size = props.Size or P(0.9, 0.025),
		Corner = UDim.new(0.5, 0), ZIndex = props.ZIndex, Clip = true })
	local fill = Paint.new("Frame", { Size = P(1, 1), ZIndex = bar.ZIndex + 1, Parent = bar })
	Paint.round(fill, UDim.new(0.5, 0))
	Paint.shade(fill, T.Good, 90)
	local t0, stopped = os.clock(), false
	local api = {}
	function api.remaining()
		return math.max(0, seconds - (os.clock() - t0))
	end
	function api.elapsed()
		return os.clock() - t0
	end
	function api.stop()
		stopped = true
	end
	task.spawn(function()
		while bar.Parent and not stopped do
			local k = api.remaining() / seconds
			fill.Size = P(k, 1)
			if k < 0.3 then
				Paint.shade(fill, T.Bad, 90)
			elseif k < 0.6 then
				Paint.shade(fill, T.Warn, 90)
			end
			task.wait(1 / 30)
		end
	end)
	return api
end

-- Row of progress pips.
function UI.pips(parent, count, props)
	props = props or {}
	local row = Paint.new("Frame", { BackgroundTransparency = 1, AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = props.Position or P(0.5, 0.5), Size = props.Size or P(0.6, 0.05), ZIndex = props.ZIndex or parent.ZIndex + 1, Parent = parent })
	Paint.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0.02, 0), Parent = row })
	local dots = {}
	local w = math.min(0.9 / count, 0.12)
	for i = 1, count do
		local d = Paint.new("Frame", { Size = P(w, 1), BackgroundColor3 = Paint.C("#1b2131"), ZIndex = row.ZIndex, LayoutOrder = i, Parent = row })
		Paint.round(d, 0.5)
		Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height, Parent = d })
		dots[i] = d
	end
	local api = {}
	function api.set(n)
		for i, d in dots do
			if i <= n and not d:GetAttribute("On") then
				d:SetAttribute("On", true)
				Paint.shade(d, props.Color or T.Gold, 45)
				FX.bounce(d, 0.4)
			end
		end
	end
	return api
end

-- Screen-space pointer position (mouse or touch), matching AbsolutePosition in
-- ScreenGuis with IgnoreGuiInset = true.
function UI.pointer(input)
	if input and input.UserInputType == Enum.UserInputType.Touch then
		return Vector2.new(input.Position.X, input.Position.Y) + game:GetService("GuiService"):GetGuiInset()
	end
	return UserInputService:GetMouseLocation()
end

function UI.isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

-- Makes `source` draggable: press to pick up a copy (it lifts, grows, tilts with the
-- movement and follows the finger), release to drop. onDrop(screenPos, held) returns
-- true to keep it (you animate/destroy `held`), false to float it back home.
-- `on` is api.on from a mini-game (so connections are cleaned up). Tap = drop at start.
function UI.draggable(panel, source, on, onDrop)
	local drag
	on(source.InputBegan, function(input)
		if drag or not UI.isPress(input) then
			return
		end
		local held = source:Clone()
		for _, d in held:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex += 60
			end
			if d:IsA("UIGridLayout") or d:IsA("UIListLayout") then
				d:Destroy()
			end
		end
		held.ZIndex += 60
		held.AnchorPoint = Vector2.new(0.5, 0.5)
		held.Size = UDim2.fromOffset(source.AbsoluteSize.X, source.AbsoluteSize.Y)
		local p0 = UI.pointer(input) - panel.AbsolutePosition
		held.Position = UDim2.fromOffset(p0.X, p0.Y)
		held.Parent = panel
		FX.tween(held, 0.12, { Size = UDim2.fromOffset(source.AbsoluteSize.X * 1.15, source.AbsoluteSize.Y * 1.15), Rotation = -8 }, Enum.EasingStyle.Back)
		FX.sound("Pick")
		drag = { held = held, start = UI.pointer(input), last = UI.pointer(input) }
	end)
	on(UserInputService.InputChanged, function(input)
		if not drag then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local pos = UI.pointer(input)
		local rel = pos - panel.AbsolutePosition
		drag.held.Position = UDim2.fromOffset(rel.X, rel.Y)
		drag.held.Rotation = math.clamp((pos.X - drag.last.X) * 1.2, -22, 22)
		drag.last = pos
	end)
	on(UserInputService.InputEnded, function(input)
		if not (drag and UI.isPress(input)) then
			return
		end
		local d = drag
		drag = nil
		local pos = UI.pointer(input)
		local tapped = (pos - d.start).Magnitude < 10
		if onDrop(if tapped then nil else pos, d.held) then
			return
		end
		local home = source.AbsolutePosition + source.AbsoluteSize / 2 - panel.AbsolutePosition
		FX.tween(d.held, 0.3, { Position = UDim2.fromOffset(home.X, home.Y), Rotation = 0,
			Size = UDim2.fromOffset(source.AbsoluteSize.X, source.AbsoluteSize.Y) }, Enum.EasingStyle.Back)
		task.delay(0.31, function()
			d.held:Destroy()
		end)
	end)
end

function UI.inside(frame, pos)
	local a, sz = frame.AbsolutePosition, frame.AbsoluteSize
	return pos.X >= a.X and pos.X <= a.X + sz.X and pos.Y >= a.Y and pos.Y <= a.Y + sz.Y
end

-- Cute painted customer. mood: "happy" | "ok" | "sad"
function UI.customer(parent, look, props)
	props = props or {}
	local root = Paint.new("Frame", { Name = "Customer", BackgroundTransparency = 1, AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 1),
		Position = props.Position or P(0.5, 1), Size = props.Size or P(0.3, 0.6), ZIndex = props.ZIndex or parent.ZIndex + 1, Parent = parent })
	Paint.new("UIAspectRatioConstraint", { AspectRatio = 0.72, Parent = root })
	local z = root.ZIndex
	Paint.blob(root, look.Shirt, { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 1), Size = P(0.86, 0.46), Corner = 0.42, ZIndex = z })
	Paint.blob(root, look.Hair, { Position = P(0.5, 0.3), Size = P(0.8, 0.58), ZIndex = z + 1 })
	local head = Paint.blob(root, look.Skin, { Position = P(0.5, 0.36), Size = P(0.7, 0.5), ZIndex = z + 2 })
	Paint.blob(root, look.Hair, { Position = P(0.5, 0.16), Size = P(0.66, 0.2), Corner = 0.5, ZIndex = z + 3, Blotch = false })
	local face = Paint.new("Frame", { Name = "Face", BackgroundTransparency = 1, Size = P(1, 1), ZIndex = z + 4, Parent = head })
	root:SetAttribute("Mood", "ok")
	local function draw(mood)
		face:ClearAllChildren()
		local fz = face.ZIndex
		for _, x in { 0.33, 0.67 } do
			local eye = Paint.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = P(x, 0.48),
				Size = if mood == "happy" then P(0.12, 0.05) else P(0.09, 0.12), BackgroundColor3 = Paint.C("#3a2f45"), ZIndex = fz, Parent = face })
			Paint.round(eye, 0.5)
			local blush = Paint.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = P(x + (x < 0.5 and -0.08 or 0.08), 0.64),
				Size = P(0.16, 0.08), BackgroundColor3 = Paint.C("#f59ab4"), BackgroundTransparency = 0.45, ZIndex = fz, Parent = face })
			Paint.round(blush, 0.5)
		end
		local mouth = Paint.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = P(0.5, 0.74), ZIndex = fz, Parent = face,
			BackgroundColor3 = Paint.C(if mood == "happy" then "#c9404d" else "#3a2f45"),
			Size = if mood == "happy" then P(0.2, 0.14) elseif mood == "sad" then P(0.14, 0.04) else P(0.12, 0.04) })
		Paint.round(mouth, if mood == "happy" then 0.5 else 0.5)
		if mood == "sad" then
			mouth.Rotation = 8
		end
		root:SetAttribute("Mood", mood)
	end
	draw(props.Mood or "ok")
	return root, draw
end

function UI.randomLook(rng)
	rng = rng or Random.new()
	return {
		Shirt = Config.Pastels[rng:NextInteger(1, #Config.Pastels)],
		Skin = Config.SkinTones[rng:NextInteger(1, #Config.SkinTones)],
		Hair = Config.HairColors[rng:NextInteger(1, #Config.HairColors)],
		Name = Config.CustomerNames[rng:NextInteger(1, #Config.CustomerNames)],
	}
end

-- Grade words for a 0..1 score (Cooking Mama style). fun = true picks a random fun line.
local gradeRng = Random.new()
function UI.grade(score, fun)
	local s = score * 100
	local key, col
	if s >= 95 then
		key, col = "Perfect", T.Good
	elseif s >= 80 then
		key, col = "Great", "#8ec5f0"
	elseif s >= 60 then
		key, col = "Good", T.Warn
	elseif s >= 35 then
		key, col = "Okay", "#f5a86b"
	else
		key, col = "Oops", T.Bad
	end
	local lines = Config.GradeLines and Config.GradeLines[key]
	if fun and lines and #lines > 0 then
		return lines[gradeRng:NextInteger(1, #lines)], col
	end
	return (lines and lines[1]) or key, col
end

return UI
