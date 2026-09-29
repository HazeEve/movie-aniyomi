--!nonstrict
-- AuraFizz2D · MiniGames — 2D versions of YOUR DrinkCatalog.Actions mini-games.
-- Each action names a game type + params; this file plays it and returns a score 0..1.
--   Tap     { count, label }                            tap N times before time runs out
--   Swipe   { count, alternate, vertical, label }       swipe N times (alternating = back & forth)
--   Hold    { fillTime, zoneMin, zoneMax, label }       hold, let go in the gold zone
--   Circle  { turns, label }                            drag in circles N turns
--   Cook    { duration, zoneMin, zoneMax, gauge, maxTemp, label }  it rises by itself, stop in the gold zone
--   Timing  { count, zone, speed, label }               stop the moving marker in the gold zone N times
-- Plus Cooking-Mama-style extras (see Config.GameOverrides):
--   Trace   { count }            drag the knife along dotted cut lines
--   Mash    { count }            alternate left/right fast
--   Sequence{ count }            follow the arrow pattern
--   Catch   { count }            move the cup to catch falling toppings
--   Steady  { fillTime, zoneMin, zoneMax }  keep the marker in a drifting zone
--   Drag    { count }            drag garnish pieces onto marked spots
-- Every station gets its own painted scene (coffee machine, stove, blender, juicer, ...).
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(script.Parent.Config)
local Paint = require(script.Parent.Paint)
local FX = require(script.Parent.FX)
local UI = require(script.Parent.UI)
local Bridge = require(script.Parent.Bridge)

local MiniGames = {}
local T = Config.Theme
local P = UDim2.fromScale
local rng = Random.new()

-- ================= scoring =================
local function zoneScore(p, a, b)
	if p >= a and p <= b then
		local c, h = (a + b) / 2, math.max((b - a) / 2, 1e-3)
		return 1 - (math.abs(p - c) / h) * 0.12
	end
	local d = if p < a then a - p else p - b
	return math.clamp(1 - d * 4.5, 0, 0.85)
end
MiniGames.zoneScore = zoneScore

-- finished within `par` seconds = 1, then eases down to 0.6 at the time limit
local function speedScore(elapsed, par, limit)
	if elapsed <= par then
		return 1
	end
	return math.clamp(1 - 0.4 * (elapsed - par) / math.max(limit - par, 0.1), 0.6, 1)
end

-- ================= station scenes =================
local VESSEL = {
	glass = { "#e3f1f8", 0.45 },
	steel = { "#aeb6c6", 0 },
	ceramic = { "#f6e9dc", 0 },
	wood = { "#b87a4a", 0 },
}
local SCENES = {
	CoffeeMachine = { vessel = { 0.5, 0.86, 0.22, 0.2, "ceramic", 0.3 }, fx = { stream = true, steam = true } },
	Stove = { vessel = { 0.5, 0.66, 0.5, 0.3, "steel", 0.18 }, fx = { flame = true, steam = true, bubbles = true } },
	Blender = { vessel = { 0.5, 0.74, 0.36, 0.5, "glass", 0.2 }, fx = { swirl = true } },
	Juicer = { vessel = { 0.5, 0.88, 0.26, 0.28, "glass", 0.18 }, fx = { stream = true } },
	CuttingBoard = { vessel = nil, fx = { chop = true } },
	TeaBobaStation = { vessel = { 0.5, 0.8, 0.46, 0.36, "glass", 0.3 }, fx = { steam = true, bubbles = true } },
	MixingStation = { vessel = { 0.5, 0.82, 0.26, 0.56, "steel", 0.25 }, fx = { swirl = true } },
	SodaFountain = { vessel = { 0.5, 0.88, 0.3, 0.4, "glass", 0.16 }, fx = { stream = true, bubbles = true } },
	ToppingStation = { vessel = { 0.46, 0.88, 0.32, 0.44, "glass", 0.18 }, fx = { drip = true } },
	CupSealer = { vessel = { 0.5, 0.9, 0.3, 0.44, "glass", 0.14 }, fx = { seal = true } },
	BrewBarrel = { vessel = { 0.5, 0.84, 0.5, 0.56, "wood", 0.3 }, fx = { bubbles = true } },
}

-- Builds the painted scene for a station; returns a rig with set(p), tick(dt), kick().
local function scene(area, stationKey, color, extra)
	local cfg = SCENES[stationKey] or { vessel = { 0.5, 0.84, 0.36, 0.44, "glass", 0.2 }, fx = { swirl = true } }
	local z = area.ZIndex
	local r = { p = 0, flow = 0, spin = 0, fx = cfg.fx }
	Paint.shadow(area, { Position = P(0.5, 0.93), Size = P(0.8, 0.06), ZIndex = z })

	-- station furniture behind the vessel
	if stationKey == "CoffeeMachine" then
		Paint.blob(area, "#8c93a6", { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0.1), Size = P(0.72, 0.46), Corner = 0.14, ZIndex = z + 1 })
		Paint.blob(area, "#8c93a6", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.92), Size = P(0.72, 0.06), Corner = 0.4, ZIndex = z + 1 })
		Paint.blob(area, "#3b4763", { Position = P(0.5, 0.56), Size = P(0.16, 0.07), Corner = 0.3, ZIndex = z + 2 })
		Paint.blob(area, "#f59ac0", { Position = P(0.7, 0.2), Size = P(0.07, 0.07), ZIndex = z + 2, Blotch = false })
		Paint.blob(area, "#8ed5b4", { Position = P(0.6, 0.2), Size = P(0.07, 0.07), ZIndex = z + 2, Blotch = false })
		Paint.blob(area, "#1b2131", { Position = P(0.36, 0.26), Size = P(0.2, 0.12), Corner = 0.25, ZIndex = z + 2, Blotch = false })
		r.spout = 0.6
	elseif stationKey == "Stove" then
		Paint.blob(area, "#3b4763", { Position = P(0.5, 0.86), Size = P(0.84, 0.14), Corner = 0.3, ZIndex = z + 1 })
		Paint.blob(area, "#1b2131", { Position = P(0.5, 0.8), Size = P(0.56, 0.08), ZIndex = z + 2, Blotch = false })
		r.flames = {}
		for i, x in { 0.38, 0.5, 0.62 } do
			local f = Paint.blob(area, if i == 2 then "#f7c95b" else "#f5a86b", { AnchorPoint = Vector2.new(0.5, 1), Position = P(x, 0.8), Size = P(0.08, 0.1), ZIndex = z + 3, Blotch = false })
			table.insert(r.flames, f)
		end
		Paint.blob(area, "#aeb6c6", { Position = P(0.82, 0.54), Size = P(0.22, 0.05), Corner = 0.4, ZIndex = z + 3 }) -- pot handle
	elseif stationKey == "Blender" then
		Paint.blob(area, "#3b4763", { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0.74), Size = P(0.46, 0.18), Corner = 0.25, ZIndex = z + 1 })
		Paint.blob(area, "#f59ac0", { Position = P(0.5, 0.83), Size = P(0.08, 0.08), ZIndex = z + 2, Blotch = false })
		Paint.blob(area, "#3b4763", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.25), Size = P(0.4, 0.06), Corner = 0.4, ZIndex = z + 4 })
	elseif stationKey == "Juicer" then
		r.press = Paint.blob(area, "#aeb6c6", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.36), Size = P(0.4, 0.16), Corner = 0.45, ZIndex = z + 4 })
		local fruit = Paint.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = P(0.5, 0.46), Size = P(0.28, 0.28), ZIndex = z + 3, Parent = area })
		Paint.art(fruit, { Shape = "slice", Color = extra.fruitColor or "#f6d33f" })
		r.fruit = fruit
		Paint.blob(area, "#aeb6c6", { Position = P(0.5, 0.58), Size = P(0.44, 0.08), Corner = 0.4, ZIndex = z + 2 })
		r.spout = 0.6
	elseif stationKey == "CuttingBoard" then
		Paint.blob(area, T.Wood, { Position = P(0.5, 0.72), Size = P(0.86, 0.34), Corner = 0.3, ZIndex = z + 1 })
		local whole = Paint.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = P(0.5, 0.64), Size = P(0.36, 0.36), ZIndex = z + 3, Parent = area })
		Paint.art(whole, { Shape = extra.fruitShape or "fruit", Color = extra.fruitColor or "#dc4a3c" })
		r.whole = whole
		r.knife = Paint.blob(area, "#dfe4ee", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.72, 0.5), Size = P(0.06, 0.34), Corner = 0.45, Rotation = 18, ZIndex = z + 5 })
		r.pieces = {}
	elseif stationKey == "TeaBobaStation" then
		Paint.blob(area, "#3b4763", { Position = P(0.5, 0.88), Size = P(0.7, 0.08), Corner = 0.4, ZIndex = z + 1 })
		Paint.blob(area, "#aeb6c6", { Position = P(0.5, 0.6), Size = P(0.52, 0.05), Corner = 0.4, ZIndex = z + 4 })
	elseif stationKey == "MixingStation" then
		Paint.blob(area, "#dfe4ee", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.28), Size = P(0.2, 0.08), Corner = 0.4, ZIndex = z + 4 })
		Paint.blob(area, T.Wood, { Position = P(0.5, 0.9), Size = P(0.7, 0.06), Corner = 0.4, ZIndex = z + 1 })
	elseif stationKey == "SodaFountain" then
		Paint.blob(area, "#8ec5f0", { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0.06), Size = P(0.62, 0.32), Corner = 0.2, ZIndex = z + 1 })
		for i, c in { "#f59ac0", "#f7c95b", "#8ed5b4" } do
			Paint.blob(area, c, { Position = P(0.34 + (i - 1) * 0.16, 0.2), Size = P(0.1, 0.1), ZIndex = z + 2, Blotch = false })
		end
		Paint.blob(area, "#3b4763", { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0.36), Size = P(0.08, 0.08), Corner = 0.3, ZIndex = z + 2 })
		Paint.blob(area, "#3b4763", { Position = P(0.5, 0.9), Size = P(0.6, 0.05), Corner = 0.4, ZIndex = z + 1 })
		r.spout = 0.44
	elseif stationKey == "ToppingStation" then
		Paint.blob(area, extra.syrupColor or "#d08a3a", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.8, 0.88), Size = P(0.18, 0.4), Corner = 0.3, ZIndex = z + 1 })
		Paint.blob(area, "#3b4763", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.8, 0.5), Size = P(0.05, 0.12), Corner = 0.3, ZIndex = z + 1 })
		r.pump = Paint.blob(area, "#3b4763", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.74, 0.39), Size = P(0.16, 0.04), Corner = 0.4, ZIndex = z + 2 })
	elseif stationKey == "CupSealer" then
		Paint.blob(area, "#c7b3e6", { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0.08), Size = P(0.6, 0.22), Corner = 0.2, ZIndex = z + 1 })
		for _, x in { 0.24, 0.76 } do
			Paint.blob(area, "#c7b3e6", { AnchorPoint = Vector2.new(0.5, 0), Position = P(x, 0.2), Size = P(0.1, 0.72), Corner = 0.3, ZIndex = z + 1 })
		end
		r.press = Paint.blob(area, "#8c93a6", { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0.28), Size = P(0.34, 0.08), Corner = 0.3, ZIndex = z + 3 })
	elseif stationKey == "BrewBarrel" then
		for _, y in { 0.4, 0.72 } do
			Paint.blob(area, "#6a4a36", { Position = P(0.5, y), Size = P(0.54, 0.04), Corner = 0.4, ZIndex = z + 5 })
		end
	end

	-- the vessel (clipped so liquid sits inside it)
	local v = cfg.vessel
	if v then
		local mat = VESSEL[v[5]]
		local vessel = Paint.new("CanvasGroup", { Name = "Vessel", AnchorPoint = Vector2.new(0.5, 1), Position = P(v[1], v[2]), Size = P(v[3], v[4]),
			BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = mat[2], ZIndex = z + 3, Parent = area })
		Paint.round(vessel, v[6])
		Paint.shade(vessel, mat[1], 30)
		local see = v[5] == "glass" or v[5] == "ceramic"
		local liquid = Paint.new("Frame", { Name = "Liquid", AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 1), Size = P(1, 0.05),
			ZIndex = vessel.ZIndex + 1, Parent = vessel, Visible = true })
		Paint.shade(liquid, color, 0)
		if not see then
			-- steel pot / shaker / barrel: you see the contents from above, deepening as you work
			liquid.Visible = false
			r.surface = Paint.blob(area, color, { Position = P(v[1], v[2] - v[4] + 0.015), Size = P(v[3] * 0.86, 0.05),
				ZIndex = z + 4, Blotch = false, LightRot = 90 })
			r.surface.BackgroundTransparency = 1
		end
		r.vessel, r.liquid, r.vtop = vessel, liquid, v[2] - v[4]
		-- swirl blobs for blending / stirring
		if cfg.fx.swirl then
			r.swirl = {}
			for i = 1, 3 do
				local b = Paint.blob(vessel, Paint.tone(color).light, { Size = P(0.34, 0.12), ZIndex = vessel.ZIndex + 3, Blotch = false })
				b.BackgroundTransparency = 0.4
				r.swirl[i] = b
			end
		end
		if stationKey == "CupSealer" then
			r.film = Paint.blob(area, "#f4fafd", { Position = P(v[1], r.vtop), Size = P(v[3] * 1.06, 0.035), ZIndex = z + 6, Blotch = false })
			r.film.BackgroundTransparency = 1
		end
	end
	if cfg.fx.stream and r.spout then
		r.stream = Paint.new("Frame", { Name = "Stream", AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, r.spout), Size = P(0.03, 0),
			ZIndex = z + 2, Parent = area })
		Paint.round(r.stream, 0.5)
		Paint.shade(r.stream, color, 0)
	end
	r.bubbles, r.steam = {}, {}

	function r.set(p)
		r.p = p
		if r.surface then
			r.surface.BackgroundTransparency = 1 - math.clamp(0.15 + p, 0, 1) * 0.9
		end
		if r.liquid then
			r.liquid.Size = P(1, math.clamp(0.05 + 0.85 * math.min(p, 1), 0, 1))
		end
		if r.flames then
			for i, f in r.flames do
				local s = 0.06 + 0.08 * math.min(p, 1.2) + (i == 2 and 0.03 or 0)
				f.Size = P(0.08, s)
			end
		end
		if r.press and stationKey == "Juicer" then
			r.press.Position = P(0.5, 0.36 + 0.08 * math.min(p, 1))
			r.fruit.Size = P(0.28, 0.28 * (1 - 0.35 * math.min(p, 1)))
		end
		if r.press and stationKey == "CupSealer" then
			r.press.Position = P(0.5, 0.28 + 0.14 * math.min(p, 1))
		end
		if r.film then
			r.film.BackgroundTransparency = if p >= 0.7 then 0.1 else 1
		end
	end

	function r.kick(n)
		if r.vessel then
			FX.wobble(r.vessel, 5, 0.25)
		end
		if r.knife then
			FX.tween(r.knife, 0.08, { Position = P(0.56, 0.62), Rotation = 0 }).Completed:Connect(function()
				FX.tween(r.knife, 0.14, { Position = P(0.72, 0.5), Rotation = 18 })
			end)
			-- chop the fruit into more and more pieces
			if r.whole and n then
				local pieces = math.clamp(n + 1, 2, 8)
				for _, pc in r.pieces do
					pc:Destroy()
				end
				r.pieces = {}
				r.whole.Visible = false
				for i = 1, pieces do
					local x = 0.5 + (i - (pieces + 1) / 2) * (0.4 / pieces)
					local pc = Paint.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = P(x, 0.66),
						Size = P(0.34 / pieces + 0.04, 0.2), ZIndex = z + 3, Parent = area })
					Paint.art(pc, { Shape = "slice", Color = extra.fruitColor or "#dc4a3c" })
					table.insert(r.pieces, pc)
				end
			end
		end
		if r.pump then
			FX.tween(r.pump, 0.08, { Position = P(0.74, 0.43) }).Completed:Connect(function()
				FX.tween(r.pump, 0.15, { Position = P(0.74, 0.39) })
			end)
		end
	end

	local t = 0
	function r.tick(dt)
		t += dt
		local p = math.min(r.p, 1.2)
		if r.stream then
			local on = r.flow > 0
			local target = if r.vessel then (r.vtop + 0.02) - r.spout else 0.3
			r.stream.Size = P(0.03, if on then math.max(0, target) else 0)
		end
		if r.swirl then
			local speed = 2 + r.flow * 10 + r.spin
			for i, b in r.swirl do
				local a = t * speed + i * 2.1
				b.Position = P(0.5 + math.cos(a) * 0.28, 1 - math.min(p, 1) * 0.5 + math.sin(a) * 0.08)
				b.Rotation = math.deg(a) % 360
			end
		end
		-- bubbles / steam spawn with intensity
		if (cfg.fx.bubbles and p > 0.25) and r.vessel and rng:NextNumber() < dt * (2 + p * 10) then
			local b = Paint.blob(r.vessel, "#ffffff", { Position = P(rng:NextNumber(0.15, 0.85), 0.95), Size = P(0.06, 0.06 * r.vessel.AbsoluteSize.X / math.max(r.vessel.AbsoluteSize.Y, 1)), ZIndex = r.vessel.ZIndex + 4, Blotch = false })
			b.BackgroundTransparency = 0.45
			FX.tween(b, 1.1, { Position = P(b.Position.X.Scale, 1 - math.min(p, 1) * 0.85), BackgroundTransparency = 1 })
			task.delay(1.15, function()
				b:Destroy()
			end)
		end
		if cfg.fx.steam and p > 0.5 and rng:NextNumber() < dt * (1 + p * 4) then
			local y = if r.vtop then r.vtop else 0.4
			local s = Paint.blob(area, "#ffffff", { Position = P(0.5 + rng:NextNumber(-0.12, 0.12), y), Size = P(0.1, 0.1), ZIndex = z + 7, Blotch = false })
			s.BackgroundTransparency = 0.55
			FX.tween(s, 1.4, { Position = s.Position - P(0, 0.25), Size = P(0.18, 0.18), BackgroundTransparency = 1 })
			task.delay(1.45, function()
				s:Destroy()
			end)
		end
		if cfg.fx.drip and r.flow > 0 and rng:NextNumber() < dt * 8 and r.vessel then
			local d = Paint.blob(area, extra.syrupColor or color, { Position = P(0.46 + rng:NextNumber(-0.1, 0.1), (r.vtop or 0.5) - 0.12), Size = P(0.04, 0.05), ZIndex = z + 7, Blotch = false })
			FX.tween(d, 0.35, { Position = P(d.Position.X.Scale, (r.vtop or 0.5) + 0.04) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.36, function()
				d:Destroy()
			end)
		end
	end
	return r
end
MiniGames.scene = scene

-- ================= shared layout =================
-- panel: the station area. Returns layout pieces.
local function layout(panel, action, stepLabel)
	panel:ClearAllChildren()
	local z = panel.ZIndex
	local title = Paint.text(panel, (action.glyph and (action.glyph .. "  ") or "") .. (action.verb or "Go"), {
		Position = P(0.04, 0.05), Size = P(0.6, 0.09), AlignX = Enum.TextXAlignment.Left, ZIndex = z + 2 })
	local sub = Paint.text(panel, stepLabel or action.hint or "", { Color = T.TextSoft, Position = P(0.04, 0.14), Size = P(0.62, 0.055),
		AlignX = Enum.TextXAlignment.Left, ZIndex = z + 2 })
	local art = Paint.new("Frame", { Name = "Art", BackgroundTransparency = 1, Position = P(0.02, 0.22), Size = P(0.56, 0.74), ZIndex = z + 1, Parent = panel })
	Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = art })
	local ctrl = Paint.new("Frame", { Name = "Controls", BackgroundTransparency = 1, Position = P(0.6, 0.2), Size = P(0.38, 0.76), ZIndex = z + 1, Parent = panel })
	local hint = Paint.text(ctrl, action.hint or "", { Color = T.TextSoft, Position = P(0, 0.86), Size = P(1, 0.08), ZIndex = z + 2 })
	return { title = title, sub = sub, art = art, ctrl = ctrl, hint = hint }
end

local function finishFx(panel, score)
	local word, col = UI.grade(score, true)
	FX.floatText(panel, word, col, P(0.3, 0.42), P(0.5, 0.16))
	if score >= 0.95 then
		FX.sparkle(panel, P(0.3, 0.5), nil, 12)
		FX.sound("Perfect")
	elseif score >= 0.6 then
		FX.sparkle(panel, P(0.3, 0.5), T.Gold, 6)
		FX.sound("Good")
	else
		FX.sound("Oops")
	end
end

-- Runs fn(api) and waits for api.finish(score). Cleans every connection.
local function run(panel, fn)
	local done = Instance.new("BindableEvent")
	local conns, result, finished = {}, nil, false
	local api = {}
	function api.on(sig, cb)
		local c = sig:Connect(cb)
		table.insert(conns, c)
		return c
	end
	function api.finish(score)
		if finished then
			return
		end
		finished = true
		result = math.clamp(score, 0, 1)
		for _, c in conns do
			c:Disconnect()
		end
		finishFx(panel, result)
		task.delay(1.0, function()
			done:Fire()
		end)
	end
	function api.alive()
		return not finished and panel.Parent ~= nil
	end
	api.on(panel.AncestryChanged, function()
		if not panel:IsDescendantOf(game) and not finished then
			finished = true -- window closed mid-game: stop everything
			for _, c in conns do
				c:Disconnect()
			end
			done:Fire()
		end
	end)
	task.spawn(fn, api)
	done.Event:Wait()
	done:Destroy()
	return result
end

-- ================= game types =================
local Games = {}

function Games.Tap(panel, action, ctx)
	local prm = action.params or {}
	local count = prm.count or 5
	local L = layout(panel, action, ctx.label)
	local rig = scene(L.art, action.station, ctx.color, ctx.extra)
	local limit = (count * 0.75 + 3) * Config.TimeLimitScale
	return run(panel, function(api)
		local timer = UI.timer(panel, limit, { Position = P(0.04, 0.215), Size = P(0.92, 0.02) })
		local pips = UI.pips(L.ctrl, count, { Position = P(0.5, 0.1), Size = P(1, 0.09) })
		local btn = UI.button(L.ctrl, prm.label or "TAP", T.Accent, { Position = P(0.5, 0.48), Size = P(0.9, 0.3) })
		local n = 0
		api.on(btn.Activated, function()
			n += 1
			pips.set(n)
			rig.set(n / count)
			rig.kick(n)
			FX.sound("Pick")
			FX.sparkle(L.art, P(0.5, 0.55), nil, 3)
			if n >= count then
				timer.stop()
				api.finish(speedScore(timer.elapsed(), count * 0.45, limit))
			end
		end)
		api.on(RunService.Heartbeat, function(dt)
			rig.tick(dt)
			if timer.remaining() <= 0 then
				api.finish(0.7 * n / count)
			end
		end)
	end)
end

function Games.Swipe(panel, action, ctx)
	local prm = action.params or {}
	local count, vertical, alternate = prm.count or 4, prm.vertical == true, prm.alternate == true
	local L = layout(panel, action, ctx.label)
	local rig = scene(L.art, action.station, ctx.color, ctx.extra)
	local limit = (count * 0.9 + 3.5) * Config.TimeLimitScale
	return run(panel, function(api)
		local timer = UI.timer(panel, limit, { Position = P(0.04, 0.215), Size = P(0.92, 0.02) })
		local pips = UI.pips(L.ctrl, count, { Position = P(0.5, 0.06), Size = P(1, 0.08) })
		local pad = UI.card(L.ctrl, T.PanelLight, { Position = P(0.05, 0.14), Size = P(0.9, 0.62), Radius = 26 })
		local arrow = Paint.text(pad, "", { Color = T.Gold, Position = P(0.2, 0.25), Size = P(0.6, 0.5), ZIndex = pad.ZIndex + 2 })
		Paint.text(pad, prm.label or "SWIPE", { Color = T.TextSoft, Position = P(0.1, 0.8), Size = P(0.8, 0.12), ZIndex = pad.ZIndex + 2 })
		local dir = 1 -- +1 = right/down, -1 = left/up
		local function showArrow()
			if vertical then
				arrow.Text = if dir > 0 then "⬇" else "⬆"
			else
				arrow.Text = if dir > 0 then "➡" else "⬅"
			end
		end
		showArrow()
		local n, start, armed = 0, nil, true
		api.on(pad.InputBegan, function(input)
			if UI.isPress(input) then
				start = UI.pointer(input)
			end
		end)
		api.on(UserInputService.InputChanged, function(input)
			if not start or not armed then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local pos = UI.pointer(input)
			local d = if vertical then pos.Y - start.Y else pos.X - start.X
			local need = (if vertical then pad.AbsoluteSize.Y else pad.AbsoluteSize.X) * 0.35
			if d * dir >= need then
				n += 1
				pips.set(n)
				rig.set(n / count)
				rig.kick(n)
				FX.sound(if action.station == "MixingStation" then "Fizz" else "Pick")
				if rig.vessel then
					local base = rig.vessel.Position
					FX.tween(rig.vessel, 0.08, { Position = base + P(0, if vertical then 0.04 * dir else 0) })
					task.delay(0.09, function()
						if rig.vessel.Parent then
							FX.tween(rig.vessel, 0.1, { Position = base })
						end
					end)
				end
				start = pos
				if alternate then
					dir = -dir
				else
					armed = false -- lift and swipe again
				end
				showArrow()
				if n >= count then
					timer.stop()
					api.finish(speedScore(timer.elapsed(), count * 0.55, limit))
				end
			end
		end)
		api.on(UserInputService.InputEnded, function(input)
			if UI.isPress(input) then
				start, armed = nil, true
			end
		end)
		api.on(RunService.Heartbeat, function(dt)
			rig.tick(dt)
			if timer.remaining() <= 0 then
				api.finish(0.7 * n / count)
			end
		end)
	end)
end

function Games.Hold(panel, action, ctx)
	local prm = action.params or {}
	local fillTime, a, b = prm.fillTime or 2, prm.zoneMin or 0.72, prm.zoneMax or 0.9
	local L = layout(panel, action, ctx.label)
	local rig = scene(L.art, action.station, ctx.color, ctx.extra)
	return run(panel, function(api)
		local gauge = UI.gauge(L.ctrl, a, b, { Vertical = true, Position = P(0.08, 0.02), Size = P(0.22, 0.8), Color = ctx.color })
		local btn = UI.button(L.ctrl, prm.label or "HOLD", T.Accent, { Position = P(0.66, 0.44), Size = P(0.62, 0.3) })
		local holding, p = false, 0
		local sfx = if action.station == "SodaFountain" then "Fizz" else "Pour"
		api.on(btn.InputBegan, function(input)
			if UI.isPress(input) and api.alive() then
				holding = true
				rig.flow = 1
				FX.sound(sfx)
			end
		end)
		local function release()
			if holding then
				holding = false
				rig.flow = 0
				api.finish(zoneScore(p, a, b))
			end
		end
		api.on(btn.InputEnded, function(input)
			if UI.isPress(input) then
				release()
			end
		end)
		api.on(UserInputService.InputEnded, function(input)
			if UI.isPress(input) then
				release()
			end
		end)
		api.on(RunService.Heartbeat, function(dt)
			if holding then
				p += dt / fillTime
				if p >= 1.15 then -- spilled!
					holding = false
					rig.flow = 0
					FX.wobble(L.art, 6, 0.4)
					api.finish(0.15)
				end
			end
			gauge.set(p)
			rig.set(p)
			rig.tick(dt)
		end)
	end)
end

function Games.Circle(panel, action, ctx)
	local prm = action.params or {}
	local turns = prm.turns or 2
	local L = layout(panel, action, ctx.label)
	local rig = scene(L.art, action.station, ctx.color, ctx.extra)
	local limit = (turns * 3.2 + 3) * Config.TimeLimitScale
	return run(panel, function(api)
		local timer = UI.timer(panel, limit, { Position = P(0.04, 0.215), Size = P(0.92, 0.02) })
		local ring = UI.card(L.ctrl, T.PanelLight, { AnchorPoint = Vector2.new(0.5, 0.5), Position = P(0.5, 0.42), Size = P(0.9, 0.9), Corner = UDim.new(0.5, 0) })
		Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = ring })
		local inner = UI.card(ring, T.Panel, { AnchorPoint = Vector2.new(0.5, 0.5), Position = P(0.5, 0.5), Size = P(0.56, 0.56), Corner = UDim.new(0.5, 0) })
		local pct = Paint.text(inner, "0%", { Color = T.Gold, Position = P(0.15, 0.3), Size = P(0.7, 0.4), ZIndex = inner.ZIndex + 1 })
		Paint.text(ring, prm.label or "STIR", { Color = T.TextSoft, AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 1.02), Size = P(1, 0.12) })
		local knob = Paint.blob(ring, T.Accent, { Position = P(0.5, 0.1), Size = P(0.2, 0.2), ZIndex = ring.ZIndex + 3 })
		local dragging, lastA, total = false, nil, 0
		local goal = turns * math.pi * 2
		local function angleAt(pos)
			local c = ring.AbsolutePosition + ring.AbsoluteSize / 2
			return math.atan2(pos.Y - c.Y, pos.X - c.X)
		end
		api.on(ring.InputBegan, function(input)
			if UI.isPress(input) then
				dragging = true
				lastA = angleAt(UI.pointer(input))
			end
		end)
		api.on(UserInputService.InputEnded, function(input)
			if UI.isPress(input) then
				dragging = false
			end
		end)
		api.on(UserInputService.InputChanged, function(input)
			if not dragging then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local ang = angleAt(UI.pointer(input))
			local d = ang - lastA
			if d > math.pi then
				d -= math.pi * 2
			elseif d < -math.pi then
				d += math.pi * 2
			end
			lastA = ang
			total += d
			knob.Position = P(0.5 + math.cos(ang) * 0.4, 0.5 + math.sin(ang) * 0.4)
			local prog = math.clamp(math.abs(total) / goal, 0, 1)
			pct.Text = string.format("%d%%", math.floor(prog * 100))
			rig.spin = math.abs(d) * 60
			rig.set(prog)
			if prog >= 1 then
				timer.stop()
				api.finish(speedScore(timer.elapsed(), turns * 1.6, limit))
			end
		end)
		api.on(RunService.Heartbeat, function(dt)
			rig.spin *= 0.9
			rig.tick(dt)
			if timer.remaining() <= 0 then
				api.finish(0.7 * math.clamp(math.abs(total) / goal, 0, 1))
			end
		end)
	end)
end

function Games.Cook(panel, action, ctx)
	local prm = action.params or {}
	local duration, a, b = prm.duration or 4, prm.zoneMin or 0.72, prm.zoneMax or 0.9
	local L = layout(panel, action, ctx.label)
	local rig = scene(L.art, action.station, ctx.color, ctx.extra)
	return run(panel, function(api)
		local gauge = UI.gauge(L.ctrl, a, math.min(b, 1), { Position = P(0.05, 0.12), Size = P(0.9, 0.1), Color = T.Warn })
		Paint.text(L.ctrl, prm.gauge or "Progress", { Color = T.TextSoft, Position = P(0.05, 0.02), Size = P(0.5, 0.08), AlignX = Enum.TextXAlignment.Left })
		local readout = Paint.text(L.ctrl, "", { Color = T.Gold, Position = P(0.5, 0.02), Size = P(0.45, 0.08), AlignX = Enum.TextXAlignment.Right })
		local btn = UI.button(L.ctrl, prm.label or "STOP", T.Accent, { Position = P(0.5, 0.52), Size = P(0.9, 0.28) })
		local p = 0
		rig.flow = 1
		api.on(btn.Activated, function()
			rig.flow = 0
			api.finish(zoneScore(p, a, b))
		end)
		api.on(RunService.Heartbeat, function(dt)
			p += dt / duration
			gauge.set(p)
			rig.set(p)
			rig.tick(dt)
			if prm.maxTemp then
				readout.Text = string.format("%d°C", math.floor(math.min(p, 1.2) * prm.maxTemp))
			else
				readout.Text = string.format("%d%%", math.floor(math.min(p, 1.2) * 100))
			end
			if p >= math.max(b, 1) + 0.25 then -- left too long: burnt / over-steeped
				rig.flow = 0
				api.finish(0.2)
			end
		end)
	end)
end

function Games.Timing(panel, action, ctx)
	local prm = action.params or {}
	local count, width, speed = prm.count or 2, prm.zone or 0.2, prm.speed or 0.9
	local L = layout(panel, action, ctx.label)
	local rig = scene(L.art, action.station, ctx.color, ctx.extra)
	return run(panel, function(api)
		local pips = UI.pips(L.ctrl, count, { Position = P(0.5, 0.06), Size = P(1, 0.08) })
		local center = rng:NextNumber(width / 2 + 0.05, 1 - width / 2 - 0.05)
		local gauge = UI.gauge(L.ctrl, center - width / 2, center + width / 2, { Position = P(0.05, 0.18), Size = P(0.9, 0.1), Color = T.Steel })
		local marker = Paint.blob(gauge.frame, T.Text, { Position = P(0, 0.5), Size = P(0.03, 1.3), Corner = 0.4, ZIndex = gauge.frame.ZIndex + 4, Blotch = false })
		local btn = UI.button(L.ctrl, prm.label or "NOW!", T.Accent, { Position = P(0.5, 0.56), Size = P(0.9, 0.28) })
		local t, n, sum = 0, 0, 0
		local pos = 0
		api.on(btn.Activated, function()
			n += 1
			local s = zoneScore(pos, center - width / 2, center + width / 2)
			sum += s
			pips.set(n)
			rig.set(n / count)
			rig.kick(n)
			FX.sound(if s > 0.8 then "Pick" else "Wrong")
			if n >= count then
				api.finish(sum / count)
			else
				center = rng:NextNumber(width / 2 + 0.05, 1 - width / 2 - 0.05)
				gauge.setZone(center - width / 2, center + width / 2)
			end
		end)
		api.on(RunService.Heartbeat, function(dt)
			t += dt * speed
			pos = 1 - math.abs((t % 2) - 1) -- ping-pong 0..1
			marker.Position = P(pos, 0.5)
			rig.tick(dt)
		end)
	end)
end

-- ================= Cooking-Mama-style extras =================
-- pointer -> 0..1 coordinates inside a frame
local function inFrame(frame, pos)
	local rel = pos - frame.AbsolutePosition
	return Vector2.new(rel.X / math.max(frame.AbsoluteSize.X, 1), rel.Y / math.max(frame.AbsoluteSize.Y, 1))
end
local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

-- Trace: drag the knife along each dotted cut line.
function Games.Trace(panel, action, ctx)
	local prm = action.params or {}
	local lines = math.clamp(prm.count or 3, 2, 4)
	local L = layout(panel, action, ctx.label)
	local rig = scene(L.art, "CuttingBoard", ctx.color, ctx.extra)
	local limit = (lines * 2.4 + 3) * Config.TimeLimitScale
	return run(panel, function(api)
		local timer = UI.timer(panel, limit, { Position = P(0.04, 0.215), Size = P(0.92, 0.02) })
		local pips = UI.pips(L.ctrl, lines, { Position = P(0.5, 0.1), Size = P(1, 0.09) })
		Paint.text(L.ctrl, prm.label or "CUT!", { Color = T.Gold, Position = P(0, 0.3), Size = P(1, 0.14) })
		Paint.text(L.ctrl, "Start at the gold dot and drag along the line", { Color = T.TextSoft, Position = P(0, 0.46), Size = P(1, 0.07) })
		local dots, a, b = {}, nil, nil
		local cur, accSum = 1, 0
		local dragging, progress, devSum, samples = false, 0, 0, 0
		local function drawLine(i)
			for _, d in dots do
				d:Destroy()
			end
			dots = {}
			local x = 0.5 + (i - (lines + 1) / 2) * (0.3 / lines)
			local tilt = (rng:NextNumber() - 0.5) * 0.08
			a, b = Vector2.new(x - tilt, 0.44), Vector2.new(x + tilt, 0.86)
			for k = 0, 12 do
				local q = a:Lerp(b, k / 12)
				local big = k == 0
				local d = Paint.blob(L.art, if big then T.Gold else "#ffffff", { Position = P(q.X, q.Y), Size = P(if big then 0.05 else 0.022, if big then 0.05 else 0.022),
					ZIndex = L.art.ZIndex + 8, Blotch = false })
				d.BackgroundTransparency = if big then 0 else 0.3
				table.insert(dots, d)
			end
			FX.pop(dots[1], 0, 0.3)
		end
		drawLine(1)
		api.on(L.art.InputBegan, function(input)
			if UI.isPress(input) then
				local q = inFrame(L.art, UI.pointer(input))
				if (q - a).Magnitude < 0.09 then
					dragging, progress, devSum, samples = true, 0, 0, 0
				end
			end
		end)
		api.on(UserInputService.InputEnded, function(input)
			if UI.isPress(input) then
				dragging = false
			end
		end)
		api.on(UserInputService.InputChanged, function(input)
			if not (dragging and isMove(input)) then
				return
			end
			local q = inFrame(L.art, UI.pointer(input))
			local ab = b - a
			local t = math.clamp((q - a):Dot(ab) / ab:Dot(ab), 0, 1)
			local dev = (q - (a + ab * t)).Magnitude
			progress = math.max(progress, t)
			devSum += dev
			samples += 1
			if rig.knife then
				rig.knife.Position = P(q.X, q.Y)
				rig.knife.Rotation = 0
			end
			for k, d in dots do
				if (k - 1) / 12 <= progress then
					d.BackgroundColor3 = Paint.C(T.Good)
				end
			end
			if dev > 0.12 then -- slipped off the line: start this cut again
				dragging = false
				FX.sound("Wrong")
				FX.wobble(L.art, 4, 0.3)
				for _, d in dots do
					d.BackgroundColor3 = Color3.new(1, 1, 1)
				end
				return
			end
			if progress >= 0.95 then
				dragging = false
				accSum += math.clamp(1 - (devSum / math.max(samples, 1)) / 0.06 * 0.5, 0, 1)
				pips.set(cur)
				rig.kick(cur)
				FX.sound("Pick")
				FX.sparkle(L.art, P(b.X, b.Y), nil, 4)
				cur += 1
				if cur > lines then
					for _, d in dots do
						d:Destroy()
					end
					timer.stop()
					api.finish(accSum / lines * speedScore(timer.elapsed(), lines * 1.4, limit))
				else
					drawLine(cur)
				end
			end
		end)
		api.on(RunService.Heartbeat, function(dt)
			rig.tick(dt)
			if timer.remaining() <= 0 then
				api.finish(0.7 * (cur - 1) / lines)
			end
		end)
	end)
end

-- Mash: alternate left / right as fast as you can.
function Games.Mash(panel, action, ctx)
	local prm = action.params or {}
	local target = math.clamp((prm.count or 4) * 3, 8, 24)
	local L = layout(panel, action, ctx.label)
	local rig = scene(L.art, action.station, ctx.color, ctx.extra)
	local limit = (target * 0.3 + 3) * Config.TimeLimitScale
	return run(panel, function(api)
		local timer = UI.timer(panel, limit, { Position = P(0.04, 0.215), Size = P(0.92, 0.02) })
		local bar = UI.gauge(L.ctrl, 0.97, 1, { Position = P(0.05, 0.06), Size = P(0.9, 0.08), Color = T.Good })
		bar.zone.BackgroundTransparency = 1
		Paint.text(L.ctrl, prm.label or "MASH!", { Color = T.Gold, Position = P(0, 0.17), Size = P(1, 0.12) })
		local left = UI.button(L.ctrl, "◀", "#8ec5f0", { Position = P(0.26, 0.52), Size = P(0.44, 0.3) })
		local right = UI.button(L.ctrl, "▶", "#f59ac0", { Position = P(0.74, 0.52), Size = P(0.44, 0.3) })
		Paint.text(L.ctrl, "Left, right, left, right!", { Color = T.TextSoft, Position = P(0, 0.72), Size = P(1, 0.07) })
		local n, last = 0, nil
		local function press(side)
			if not api.alive() then
				return
			end
			if last == side then
				FX.wobble(if side == "L" then left else right, 8, 0.2)
				return
			end
			last = side
			n += 1
			bar.set(n / target)
			rig.set(n / target)
			if n % 3 == 0 then
				rig.kick(n // 3)
				FX.sound("Pick")
			end
			if n >= target then
				timer.stop()
				api.finish(speedScore(timer.elapsed(), target * 0.17, limit))
			end
		end
		api.on(left.Activated, function()
			press("L")
		end)
		api.on(right.Activated, function()
			press("R")
		end)
		api.on(UserInputService.InputBegan, function(input, gp)
			if gp then
				return
			end
			if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.A then
				press("L")
			elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.D then
				press("R")
			end
		end)
		api.on(RunService.Heartbeat, function(dt)
			rig.tick(dt)
			if timer.remaining() <= 0 then
				api.finish(0.7 * n / target)
			end
		end)
	end)
end

-- Sequence: follow the arrow pattern.
local ARROWS = {
	Up = { "⬆", Vector2.new(0, -1), { Enum.KeyCode.Up, Enum.KeyCode.W } },
	Down = { "⬇", Vector2.new(0, 1), { Enum.KeyCode.Down, Enum.KeyCode.S } },
	Left = { "⬅", Vector2.new(-1, 0), { Enum.KeyCode.Left, Enum.KeyCode.A } },
	Right = { "➡", Vector2.new(1, 0), { Enum.KeyCode.Right, Enum.KeyCode.D } },
}
local ARROW_NAMES = { "Up", "Down", "Left", "Right" }
function Games.Sequence(panel, action, ctx)
	local prm = action.params or {}
	local len = math.clamp(math.floor((prm.count or 6) / 1.4), 3, 6)
	local L = layout(panel, action, ctx.label)
	local rig = scene(L.art, action.station, ctx.color, ctx.extra)
	local limit = (len * 1.2 + 4) * Config.TimeLimitScale
	return run(panel, function(api)
		local timer = UI.timer(panel, limit, { Position = P(0.04, 0.215), Size = P(0.92, 0.02) })
		local seq = {}
		for i = 1, len do
			local nm
			repeat
				nm = ARROW_NAMES[rng:NextInteger(1, 4)]
			until nm ~= seq[i - 1]
			seq[i] = nm
		end
		local row = Paint.new("Frame", { BackgroundTransparency = 1, Position = P(0, 0.02), Size = P(1, 0.14), ZIndex = L.ctrl.ZIndex + 1, Parent = L.ctrl })
		Paint.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0.02, 0), Parent = row })
		local chips = {}
		for i, nm in seq do
			local c = UI.card(row, if i == 1 then T.Gold else T.PanelLight, { Size = P(0.9 / len - 0.02, 1), Corner = UDim.new(0.3, 0) })
			c.LayoutOrder = i
			Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height, Parent = c })
			Paint.text(c, ARROWS[nm][1], { Color = T.TextDark, Position = P(0.15, 0.15), Size = P(0.7, 0.7), ZIndex = c.ZIndex + 1 })
			chips[i] = c
			FX.pop(c, i * 0.06)
		end
		local pad = Paint.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = P(0.5, 0.5), Size = P(0.8, 0.5),
			ZIndex = L.ctrl.ZIndex + 1, Parent = L.ctrl })
		Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = pad })
		local i, mistakes = 1, 0
		local function press(nm)
			if not api.alive() then
				return
			end
			if seq[i] == nm then
				Paint.shade(chips[i], T.Good, 60, true)
				FX.bounce(chips[i], 0.3)
				FX.sound("Fizz")
				local d = ARROWS[nm][2]
				if rig.vessel then
					local base = rig.vessel.Position
					FX.tween(rig.vessel, 0.08, { Position = base + P(d.X * 0.05, d.Y * 0.05) })
					task.delay(0.1, function()
						if rig.vessel.Parent then
							FX.tween(rig.vessel, 0.12, { Position = base }, Enum.EasingStyle.Back)
						end
					end)
				end
				rig.set(i / len)
				i += 1
				if i > len then
					timer.stop()
					api.finish(len / (len + mistakes * 0.7) * speedScore(timer.elapsed(), len * 0.7, limit))
				else
					Paint.shade(chips[i], T.Gold, 60, true)
				end
			else
				mistakes += 1
				FX.sound("Wrong")
				FX.wobble(chips[i], 10, 0.3)
			end
		end
		for nm, def in ARROWS do
			local d = def[2]
			local btn = UI.button(pad, def[1], "#8ec5f0", { Position = P(0.5 + d.X * 0.34, 0.5 + d.Y * 0.34), Size = P(0.32, 0.32) })
			api.on(btn.Activated, function()
				press(nm)
			end)
		end
		api.on(UserInputService.InputBegan, function(input, gp)
			if gp then
				return
			end
			for nm, def in ARROWS do
				if table.find(def[3], input.KeyCode) then
					press(nm)
				end
			end
		end)
		api.on(RunService.Heartbeat, function(dt)
			rig.tick(dt)
			if timer.remaining() <= 0 then
				api.finish(0.7 * (i - 1) / len)
			end
		end)
	end)
end

-- Catch: slide the cup under the falling toppings, dodge the grey duds.
function Games.Catch(panel, action, ctx)
	local prm = action.params or {}
	local need = math.clamp((prm.count or 3) * 2, 4, 10)
	local L = layout(panel, action, ctx.label)
	local limit = (need * 1.3 + 4) * Config.TimeLimitScale
	local good = ctx.extra.syrupColor or ctx.extra.fruitColor or Paint.tone(ctx.color).light
	return run(panel, function(api)
		local timer = UI.timer(panel, limit, { Position = P(0.04, 0.215), Size = P(0.92, 0.02) })
		local field = L.art
		field.ClipsDescendants = true
		local cupHolder = Paint.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.98), Size = P(0.3, 0.3),
			ZIndex = field.ZIndex + 2, Parent = field })
		Paint.cup(cupHolder, ctx.recipe and ctx.recipe.cup or "tall_glass", { Behind = T.Panel, NoLid = true })
		local count = Paint.text(L.ctrl, "0 / " .. need, { Color = T.Gold, Position = P(0, 0.08), Size = P(1, 0.16) })
		Paint.text(L.ctrl, prm.label or "CATCH!", { Color = T.Text, Position = P(0, 0.28), Size = P(1, 0.1) })
		Paint.text(L.ctrl, "Move the cup with your mouse / finger\nor ← → keys. Dodge the grey bits!", { Color = T.TextSoft, Position = P(0, 0.42), Size = P(1, 0.14) })
		local cupX, caught, bad, missed = 0.5, 0, 0, 0
		local drops, spawnT, keyDir = {}, 0, 0
		api.on(UserInputService.InputChanged, function(input)
			if isMove(input) then
				local q = inFrame(field, UI.pointer(input))
				if q.Y > -0.2 and q.Y < 1.2 then
					cupX = math.clamp(q.X, 0.12, 0.88)
				end
			end
		end)
		api.on(UserInputService.InputBegan, function(input, gp)
			if gp then
				return
			end
			if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.A then
				keyDir = -1
			elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.D then
				keyDir = 1
			end
		end)
		api.on(UserInputService.InputEnded, function(input)
			if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.D then
				keyDir = 0
			end
		end)
		api.on(RunService.Heartbeat, function(dt)
			cupX = math.clamp(cupX + keyDir * dt * 1.2, 0.12, 0.88)
			cupHolder.Position = P(cupX, 0.98)
			spawnT -= dt
			if spawnT <= 0 then
				spawnT = rng:NextNumber(0.45, 0.8)
				local isBad = rng:NextNumber() < 0.22
				local d = Paint.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = P(rng:NextNumber(0.1, 0.9), -0.05),
					Size = P(0.09, 0.09), ZIndex = field.ZIndex + 3, Parent = field })
				Paint.art(d, { Shape = if isBad then "circle" else "star", Color = if isBad then "#6b6f7a" else good })
				table.insert(drops, { f = d, bad = isBad, v = rng:NextNumber(0.35, 0.55) })
			end
			for k = #drops, 1, -1 do
				local o = drops[k]
				local pos = o.f.Position
				local y = pos.Y.Scale + o.v * dt
				o.f.Position = P(pos.X.Scale, y)
				o.f.Rotation += dt * 90
				if y >= 0.74 and y <= 0.8 and math.abs(pos.X.Scale - cupX) < 0.13 then
					if o.bad then
						bad += 1
						FX.sound("Wrong")
						FX.wobble(cupHolder, 8, 0.3)
					else
						caught += 1
						count.Text = caught .. " / " .. need
						FX.sound("Pick")
						FX.bounce(cupHolder, 0.15)
						FX.sparkle(field, P(cupX, 0.72), good, 3)
					end
					o.f:Destroy()
					table.remove(drops, k)
				elseif y > 1.05 then
					if not o.bad then
						missed += 1
					end
					o.f:Destroy()
					table.remove(drops, k)
				end
			end
			if caught >= need then
				timer.stop()
				api.finish(math.clamp(1 - bad * 0.15 - missed * 0.04, 0.3, 1))
			elseif timer.remaining() <= 0 then
				api.finish(0.7 * caught / need)
			end
		end)
	end)
end

-- Steady: hold to lift the marker, let go to drop; stay inside the drifting gold zone.
function Games.Steady(panel, action, ctx)
	local prm = action.params or {}
	local goal = (prm.fillTime or 1.6) * 1.8
	local half = math.max(((prm.zoneMax or 0.9) - (prm.zoneMin or 0.72)) / 2 + 0.05, 0.08)
	local L = layout(panel, action, ctx.label)
	local rig = scene(L.art, action.station, ctx.color, ctx.extra)
	local limit = (goal * 3 + 3) * Config.TimeLimitScale
	return run(panel, function(api)
		local timer = UI.timer(panel, limit, { Position = P(0.04, 0.215), Size = P(0.92, 0.02) })
		local gauge = UI.gauge(L.ctrl, 0.4, 0.6, { Vertical = true, Position = P(0.08, 0.02), Size = P(0.2, 0.8), Color = T.Steel })
		local marker = Paint.blob(gauge.frame, T.Text, { Position = P(0.5, 0.5), Size = P(1.2, 0.035), Corner = 0.4, ZIndex = gauge.frame.ZIndex + 4, Blotch = false })
		local prog = UI.gauge(L.ctrl, 0.97, 1, { Position = P(0.36, 0.06), Size = P(0.6, 0.07), Color = T.Good })
		prog.zone.BackgroundTransparency = 1
		local btn = UI.button(L.ctrl, prm.label or "HOLD", T.Accent, { Position = P(0.66, 0.46), Size = P(0.62, 0.3) })
		Paint.text(L.ctrl, "Hold = up · let go = down", { Color = T.TextSoft, Position = P(0.34, 0.68), Size = P(0.64, 0.07) })
		local holding, m, vel, t, inside, outside = false, 0.3, 0, 0, 0, 0
		api.on(btn.InputBegan, function(input)
			if UI.isPress(input) then
				holding = true
			end
		end)
		api.on(UserInputService.InputEnded, function(input)
			if UI.isPress(input) then
				holding = false
			end
		end)
		api.on(RunService.Heartbeat, function(dt)
			t += dt
			local c = 0.5 + 0.28 * math.sin(t * 1.2) + 0.08 * math.sin(t * 2.9)
			gauge.setZone(math.clamp(c - half, 0, 1), math.clamp(c + half, 0, 1))
			vel += (if holding then 2.2 else -1.8) * dt
			vel = math.clamp(vel, -0.9, 0.9)
			m = math.clamp(m + vel * dt, 0, 1)
			if m <= 0 or m >= 1 then
				vel = 0
			end
			marker.Position = P(0.5, 1 - m)
			local ok = math.abs(m - c) <= half
			if ok then
				inside += dt
				rig.flow = 1
			else
				outside += dt
				rig.flow = 0
			end
			marker.BackgroundColor3 = if ok then Paint.C(T.Good) else Paint.C(T.Text)
			prog.set(inside / goal)
			rig.set(inside / goal)
			rig.tick(dt)
			if inside >= goal then
				rig.flow = 0
				timer.stop()
				api.finish(math.clamp(1 - outside / (goal * 1.5), 0.3, 1))
			elseif timer.remaining() <= 0 then
				api.finish(0.7 * inside / goal)
			end
		end)
	end)
end

-- Drag: drag each garnish piece onto a marked spot on the drink.
function Games.Drag(panel, action, ctx)
	local prm = action.params or {}
	local n = math.clamp(prm.count or 3, 2, 5)
	local L = layout(panel, action, ctx.label)
	local rig = scene(L.art, action.station, ctx.color, ctx.extra)
	local limit = (n * 2.2 + 4) * Config.TimeLimitScale
	local pieceColor = ctx.extra.fruitColor or "#55a444"
	return run(panel, function(api)
		local timer = UI.timer(panel, limit, { Position = P(0.04, 0.215), Size = P(0.92, 0.02) })
		Paint.text(L.ctrl, prm.label or "DECORATE", { Color = T.Gold, Position = P(0, 0.04), Size = P(1, 0.12) })
		Paint.text(L.ctrl, "Drag each piece onto a dotted spot", { Color = T.TextSoft, Position = P(0, 0.17), Size = P(1, 0.07) })
		local tray = UI.card(L.ctrl, T.PanelLight, { Position = P(0.05, 0.3), Size = P(0.9, 0.44), Radius = 20 })
		-- target spots across the top of the drink
		local topY = (rig.vtop or 0.5) - 0.02
		local spots = {}
		for i = 1, n do
			local x = 0.5 + (i - (n + 1) / 2) * (0.34 / n)
			local ring = Paint.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = P(x, topY), Size = P(0.09, 0.09),
				BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.65, ZIndex = L.art.ZIndex + 9, Parent = L.art })
			Paint.round(ring, 0.5)
			spots[i] = { pos = Vector2.new(x, topY), ring = ring, used = false }
			FX.pop(ring, i * 0.08)
		end
		local placed, accSum = 0, 0
		local dragging, grabOffset = nil, Vector2.zero
		local homes = {}
		for i = 1, n do
			local col = (i - 1) % 3
			local rowi = math.floor((i - 1) / 3)
			local piece = Paint.new("TextButton", { Text = "", BackgroundTransparency = 1, AutoButtonColor = false, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = P(0.2 + col * 0.3, 0.3 + rowi * 0.42), Size = P(0.26, 0.36), ZIndex = tray.ZIndex + 3, Parent = tray })
			Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = piece })
			Paint.art(piece, { Shape = if ctx.extra.fruitColor then "slice" else "leaf", Color = pieceColor })
			homes[piece] = piece.Position
			api.on(piece.InputBegan, function(input)
				if UI.isPress(input) and not piece:GetAttribute("Placed") then
					dragging = piece
					-- lift the piece to the panel so it can travel over the drink
					local abs = piece.AbsolutePosition + piece.AbsoluteSize / 2
					local size = piece.AbsoluteSize
					piece.Parent = panel
					piece.ZIndex = panel.ZIndex + 30
					piece.Size = UDim2.fromOffset(size.X, size.Y)
					piece.Position = UDim2.fromOffset(abs.X - panel.AbsolutePosition.X, abs.Y - panel.AbsolutePosition.Y)
					grabOffset = abs - UI.pointer(input)
					FX.bounce(piece, 0.2)
				end
			end)
		end
		api.on(UserInputService.InputChanged, function(input)
			if dragging and isMove(input) then
				local p = UI.pointer(input) + grabOffset - panel.AbsolutePosition
				dragging.Position = UDim2.fromOffset(p.X, p.Y)
			end
		end)
		api.on(UserInputService.InputEnded, function(input)
			if not (dragging and UI.isPress(input)) then
				return
			end
			local piece = dragging
			dragging = nil
			local q = inFrame(L.art, piece.AbsolutePosition + piece.AbsoluteSize / 2)
			local best, bestD = nil, math.huge
			for _, s in spots do
				if not s.used then
					local d = (q - s.pos).Magnitude
					if d < bestD then
						best, bestD = s, d
					end
				end
			end
			if best and bestD < 0.1 then
				best.used = true
				best.ring.Visible = false
				piece:SetAttribute("Placed", true)
				piece.Parent = L.art
				piece.ZIndex = L.art.ZIndex + 10
				piece.Size = P(0.11, 0.11)
				piece.Position = P(best.pos.X, best.pos.Y)
				FX.bounce(piece, 0.3)
				FX.sound("Pick")
				FX.sparkle(L.art, P(best.pos.X, best.pos.Y), T.Gold, 4)
				accSum += math.clamp(1 - bestD / 0.1 * 0.3, 0, 1)
				placed += 1
				if placed >= n then
					timer.stop()
					api.finish(accSum / n * speedScore(timer.elapsed(), n * 1.3, limit))
				end
			else
				piece.Parent = tray
				piece.ZIndex = tray.ZIndex + 3
				piece.Size = P(0.26, 0.36)
				piece.Position = homes[piece]
				FX.sound("Wrong")
			end
		end)
		api.on(RunService.Heartbeat, function(dt)
			rig.tick(dt)
			if timer.remaining() <= 0 then
				api.finish(0.7 * placed / n)
			end
		end)
	end)
end

-- ================= public =================
-- Plays one of your DrinkCatalog actions in `panel`. Yields; returns score 0..1
-- (nil if the panel was closed). ctx = { label = step text, color = drink Color3, recipe = recipe }
function MiniGames.play(panel, actionId, ctx)
	ctx = ctx or {}
	local action = Bridge.action(actionId)
	if not action then
		warn("[AuraFizz2D] unknown action " .. tostring(actionId) .. " - skipped")
		return 1
	end
	ctx.color = ctx.color or Color3.fromHex("#d9c9b8")
	ctx.extra = ctx.extra or {}
	local kind = (Config.GameOverrides and Config.GameOverrides[actionId]) or action.game
	local playFn = Games[kind] or Games[action.game] or Games.Tap
	return playFn(panel, action, ctx)
end

MiniGames.Games = Games
return MiniGames
