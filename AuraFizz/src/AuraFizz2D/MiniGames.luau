--!nonstrict
-- AuraFizz2D · MiniGames — 12 2D mini-games for YOUR DrinkCatalog actions.
-- Config.Games says which game each action plays; any action not listed uses its
-- catalog type (Hold -> Fill, Cook -> Cook, Timing -> Blend, Tap -> Mash, Swipe -> Peel, Circle -> Stir).
--
--  Papa's-style (build it right)                    Cooking-Mama-style (skill & rhythm)
--   Fill      pour into the cup, stop on the line    Trace   knife along dotted cut lines
--   Blend     hold, let go on Chunky/Regular/Smooth  Peel    swipe strips off (back & forth if alternate)
--   Cook      timer dial, stop in the gold wedge     Mash    alternate left/right fast
--   Stack     add the layers in the ticket's order   Stir    drag in circles N turns
--   Toppings  drag toppings evenly onto the drink    Shake   follow the arrow pattern
--   Drizzle   trace sauce over the dotted swirl      Catch   catch falling drops in the cup
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
	steel = { T.Appliance, 0 },
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
	-- your stations' matte black counter with a gold edge
	Paint.blob(area, T.Appliance, { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0.9), Size = P(1.02, 0.12), Corner = 0.08, ZIndex = z, Blotch = false })
	Paint.blob(area, T.Trim, { Position = P(0.5, 0.9), Size = P(1.02, 0.012), Corner = 0.4, ZIndex = z + 1, Blotch = false })
	Paint.shadow(area, { Position = P(0.5, 0.9), Size = P(0.8, 0.04), ZIndex = z + 1 })

	-- station furniture behind the vessel
	if stationKey == "CoffeeMachine" then
		Paint.blob(area, T.Appliance, { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0.1), Size = P(0.72, 0.46), Corner = 0.14, ZIndex = z + 1 })
		Paint.blob(area, T.Trim, { Position = P(0.5, 0.47), Size = P(0.72, 0.025), Corner = 0.4, ZIndex = z + 2, Blotch = false })
		Paint.blob(area, T.Appliance, { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.92), Size = P(0.72, 0.06), Corner = 0.4, ZIndex = z + 1 })
		Paint.blob(area, "#2e2833", { Position = P(0.5, 0.56), Size = P(0.16, 0.07), Corner = 0.3, ZIndex = z + 2 })
		Paint.blob(area, "#f59ac0", { Position = P(0.7, 0.2), Size = P(0.07, 0.07), ZIndex = z + 2, Blotch = false })
		Paint.blob(area, "#8ed5b4", { Position = P(0.6, 0.2), Size = P(0.07, 0.07), ZIndex = z + 2, Blotch = false })
		Paint.blob(area, "#1b2131", { Position = P(0.36, 0.26), Size = P(0.2, 0.12), Corner = 0.25, ZIndex = z + 2, Blotch = false })
		r.spout = 0.6
	elseif stationKey == "Stove" then
		Paint.blob(area, "#2e2833", { Position = P(0.5, 0.86), Size = P(0.84, 0.14), Corner = 0.3, ZIndex = z + 1 })
		Paint.blob(area, "#1b2131", { Position = P(0.5, 0.8), Size = P(0.56, 0.08), ZIndex = z + 2, Blotch = false })
		r.flames = {}
		for i, x in { 0.38, 0.5, 0.62 } do
			local f = Paint.blob(area, if i == 2 then "#f7c95b" else "#f5a86b", { AnchorPoint = Vector2.new(0.5, 1), Position = P(x, 0.8), Size = P(0.08, 0.1), ZIndex = z + 3, Blotch = false })
			table.insert(r.flames, f)
		end
		Paint.blob(area, T.Trim, { Position = P(0.82, 0.54), Size = P(0.22, 0.05), Corner = 0.4, ZIndex = z + 3 }) -- pot handle
	elseif stationKey == "Blender" then
		Paint.blob(area, "#2e2833", { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0.74), Size = P(0.46, 0.18), Corner = 0.25, ZIndex = z + 1 })
		Paint.blob(area, "#f59ac0", { Position = P(0.5, 0.83), Size = P(0.08, 0.08), ZIndex = z + 2, Blotch = false })
		Paint.blob(area, "#2e2833", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.25), Size = P(0.4, 0.06), Corner = 0.4, ZIndex = z + 4 })
	elseif stationKey == "Juicer" then
		r.press = Paint.blob(area, T.Trim, { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.36), Size = P(0.4, 0.16), Corner = 0.45, ZIndex = z + 4 })
		local fruit = Paint.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = P(0.5, 0.46), Size = P(0.28, 0.28), ZIndex = z + 3, Parent = area })
		Paint.art(fruit, { Shape = "slice", Color = extra.fruitColor or "#f6d33f" })
		r.fruit = fruit
		Paint.blob(area, T.Trim, { Position = P(0.5, 0.58), Size = P(0.44, 0.08), Corner = 0.4, ZIndex = z + 2 })
		r.spout = 0.6
	elseif stationKey == "CuttingBoard" then
		Paint.blob(area, T.Wood, { Position = P(0.5, 0.72), Size = P(0.86, 0.34), Corner = 0.3, ZIndex = z + 1 })
		local whole = Paint.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = P(0.5, 0.64), Size = P(0.36, 0.36), ZIndex = z + 3, Parent = area })
		Paint.art(whole, { Shape = extra.fruitShape or "fruit", Color = extra.fruitColor or "#dc4a3c" })
		r.whole = whole
		r.knife = Paint.blob(area, "#efdca6", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.72, 0.5), Size = P(0.06, 0.34), Corner = 0.45, Rotation = 18, ZIndex = z + 5 })
		r.pieces = {}
	elseif stationKey == "TeaBobaStation" then
		-- gold nameplate + black shelf of black/gold canisters, like your Tea & Boba station
		local sign = Paint.blob(area, "#15121a", { Position = P(0.5, 0.07), Size = P(0.5, 0.08), Corner = 0.15, ZIndex = z + 1, Blotch = false })
		Paint.text(sign, "TEA & BOBA", { Color = T.Trim, Position = P(0.05, 0.12), Size = P(0.9, 0.76), ZIndex = z + 2 })
		Paint.blob(area, "#15121a", { Position = P(0.5, 0.31), Size = P(0.9, 0.022), Corner = 0.3, ZIndex = z + 1, Blotch = false })
		for i = 0, 4 do
			local x = 0.18 + i * 0.16
			Paint.blob(area, "#1b1820", { AnchorPoint = Vector2.new(0.5, 1), Position = P(x, 0.3), Size = P(0.1, 0.13), Corner = 0.2, ZIndex = z + 1 })
			Paint.blob(area, T.Trim, { AnchorPoint = Vector2.new(0.5, 1), Position = P(x, 0.2), Size = P(0.1, 0.02), Corner = 0.3, ZIndex = z + 2, Blotch = false })
		end
		Paint.blob(area, T.Trim, { Position = P(0.5, 0.6), Size = P(0.52, 0.05), Corner = 0.4, ZIndex = z + 4 })
	elseif stationKey == "MixingStation" then
		Paint.blob(area, "#efdca6", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.28), Size = P(0.2, 0.08), Corner = 0.4, ZIndex = z + 4 })
		Paint.blob(area, T.Wood, { Position = P(0.5, 0.9), Size = P(0.7, 0.06), Corner = 0.4, ZIndex = z + 1 })
	elseif stationKey == "SodaFountain" then
		Paint.blob(area, T.Appliance, { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0.06), Size = P(0.62, 0.32), Corner = 0.2, ZIndex = z + 1 })
		Paint.blob(area, T.Trim, { Position = P(0.5, 0.33), Size = P(0.62, 0.022), Corner = 0.4, ZIndex = z + 2, Blotch = false })
		for i, c in { "#f59ac0", "#f7c95b", "#8ed5b4" } do
			Paint.blob(area, c, { Position = P(0.34 + (i - 1) * 0.16, 0.2), Size = P(0.1, 0.1), ZIndex = z + 2, Blotch = false })
		end
		Paint.blob(area, "#2e2833", { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0.36), Size = P(0.08, 0.08), Corner = 0.3, ZIndex = z + 2 })
		Paint.blob(area, "#2e2833", { Position = P(0.5, 0.9), Size = P(0.6, 0.05), Corner = 0.4, ZIndex = z + 1 })
		r.spout = 0.44
	elseif stationKey == "ToppingStation" then
		-- black rail of pump bottles with gold pump heads + clear acrylic topping bins, like your topping station
		local syrups = { "#f59ac0", "#f7e3a5", "#a8d8b9", "#c7b3e6", "#f5a86b", "#8ec5f0", "#e2413f" }
		Paint.blob(area, "#15121a", { Position = P(0.5, 0.25), Size = P(0.96, 0.02), Corner = 0.3, ZIndex = z + 1, Blotch = false })
		for i, c in syrups do
			local x = 0.08 + (i - 1) * 0.14
			Paint.blob(area, c, { AnchorPoint = Vector2.new(0.5, 1), Position = P(x, 0.24), Size = P(0.07, 0.14), Corner = 0.3, ZIndex = z + 1 })
			Paint.blob(area, T.Trim, { AnchorPoint = Vector2.new(0.5, 1), Position = P(x, 0.1), Size = P(0.018, 0.05), Corner = 0.3, ZIndex = z + 2, Blotch = false })
		end
		local bins = { "#f7e3a5", "#f59ac0", "#c7b3e6", "#a8d8b9" }
		for i, c in bins do
			local bx = 0.07 + (i - 1) * 0.07
			local bin = Paint.blob(area, "#e3f1f8", { AnchorPoint = Vector2.new(0.5, 1), Position = P(bx, 0.89), Size = P(0.065, 0.09), Corner = 0.15, ZIndex = z + 1, Blotch = false })
			bin.BackgroundTransparency = 0.55
			for k = 1, 4 do
				Paint.blob(bin, c, { Position = P(0.2 + (k % 2) * 0.5, 0.55 + math.floor(k / 3) * 0.25), Size = P(0.3, 0.2), ZIndex = bin.ZIndex + 1, Blotch = false })
			end
		end
		-- the pump you press for this drink's syrup
		Paint.blob(area, extra.syrupColor or "#d08a3a", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.8, 0.89), Size = P(0.14, 0.34), Corner = 0.3, ZIndex = z + 1 })
		Paint.blob(area, T.Trim, { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.8, 0.56), Size = P(0.04, 0.1), Corner = 0.3, ZIndex = z + 1 })
		r.pump = Paint.blob(area, T.Trim, { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.74, 0.46), Size = P(0.16, 0.035), Corner = 0.4, ZIndex = z + 2 })
	elseif stationKey == "CupSealer" then
		Paint.blob(area, T.Appliance, { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0.08), Size = P(0.6, 0.22), Corner = 0.2, ZIndex = z + 1 })
		for _, x in { 0.24, 0.76 } do
			Paint.blob(area, T.Appliance, { AnchorPoint = Vector2.new(0.5, 0), Position = P(x, 0.2), Size = P(0.1, 0.72), Corner = 0.3, ZIndex = z + 1 })
		end
		r.press = Paint.blob(area, T.Appliance, { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0.28), Size = P(0.34, 0.08), Corner = 0.3, ZIndex = z + 3 })
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
			FX.tween(r.pump, 0.08, { Position = P(0.74, 0.5) }).Completed:Connect(function()
				FX.tween(r.pump, 0.15, { Position = P(0.74, 0.46) })
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

-- pointer -> 0..1 coordinates inside a frame
local function inFrame(frame, pos)
	local rel = pos - frame.AbsolutePosition
	return Vector2.new(rel.X / math.max(frame.AbsoluteSize.X, 1), rel.Y / math.max(frame.AbsoluteSize.Y, 1))
end
local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

-- ================================================================
-- PAPA'S-STYLE GAMES
-- ================================================================

-- a cup of the recipe drawn in the art area; returns vessel + info (holder scale == art scale)
local function recipeCup(art, ctx, opts)
	local holder = Paint.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 1), Size = P(0.9, 0.9),
		ZIndex = art.ZIndex + 2, Parent = art })
	local vessel, info = Paint.cup(holder, ctx.recipe and ctx.recipe.cup or "tall_glass", { Behind = T.Panel, NoLid = true })
	-- convert holder-scale y to art-scale y
	info.toArt = function(y)
		return 0.1 + y * 0.9
	end
	info.holder = holder
	return vessel, info
end

local function liquidIn(vessel, color)
	local liquid = Paint.new("Frame", { Name = "Liquid", AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 1), Size = P(1, 0),
		ZIndex = vessel.ZIndex + 1, Parent = vessel })
	Paint.shade(liquid, color, 0)
	local surface = Paint.blob(vessel, Paint.tone(color).light, { AnchorPoint = Vector2.new(0.5, 0.5), Position = P(0.5, 1), Size = P(1, 0.035),
		ZIndex = vessel.ZIndex + 2, Blotch = false })
	surface.BackgroundTransparency = 0.3
	return function(level)
		level = math.clamp(level, 0, 1)
		liquid.Size = P(1, level)
		surface.Position = P(0.5, 1 - level)
		surface.Visible = level > 0.01
	end
end

-- Fill: hold to pour into the actual cup and let go on the dashed line.
function Games.Fill(panel, action, ctx)
	local prm = action.params or {}
	local fillTime, a, b = prm.fillTime or 2, prm.zoneMin or 0.75, prm.zoneMax or 0.9
	local L = layout(panel, action, ctx.label)
	local vessel, info = recipeCup(L.art, ctx)
	local setLevel = liquidIn(vessel, ctx.color)
	-- gold band + dashed line where it should stop
	local band = Paint.new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 1 - a), Size = P(1, b - a),
		BackgroundColor3 = Paint.C(T.Gold), BackgroundTransparency = 0.72, ZIndex = vessel.ZIndex + 3, Parent = vessel })
	for k = 0, 5 do
		local dash = Paint.new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = P(k / 6 + 0.02, 1 - (a + b) / 2), Size = P(0.1, 0.012),
			BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = vessel.ZIndex + 4, Parent = vessel })
		Paint.round(dash, 0.5)
	end
	-- the spout above the cup
	local spoutColor = if action.station == "SodaFountain" then "#8ec5f0" elseif action.station == "CoffeeMachine" then "#8c93a6" else "#c7b3e6"
	Paint.blob(L.art, spoutColor, { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0), Size = P(0.5, 0.12), Corner = 0.3, ZIndex = L.art.ZIndex + 3 })
	Paint.blob(L.art, "#3b4763", { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0.11), Size = P(0.08, 0.06), Corner = 0.3, ZIndex = L.art.ZIndex + 3 })
	local stream = Paint.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0.16), Size = P(0.035, 0), ZIndex = L.art.ZIndex + 1, Parent = L.art })
	Paint.round(stream, 0.5)
	Paint.shade(stream, ctx.color, 0)
	local st = info.style
	return run(panel, function(api)
		local btn = UI.button(L.ctrl, prm.label or "HOLD TO POUR", T.Accent, { Position = P(0.5, 0.4), Size = P(0.9, 0.3) })
		Paint.text(L.ctrl, "Let go on the dashed line", { Color = T.TextSoft, Position = P(0, 0.62), Size = P(1, 0.08) })
		local holding, p = false, 0
		local sfx = if action.station == "SodaFountain" then "Fizz" else "Pour"
		api.on(btn.InputBegan, function(input)
			if UI.isPress(input) and api.alive() then
				holding = true
				FX.sound(sfx)
			end
		end)
		local function release()
			if holding then
				holding = false
				stream.Size = P(0.035, 0)
				api.finish(zoneScore(p, a, b))
			end
		end
		api.on(UserInputService.InputEnded, function(input)
			if UI.isPress(input) then
				release()
			end
		end)
		api.on(RunService.Heartbeat, function(dt)
			if holding then
				p += dt / fillTime
				if p >= 1.1 then -- overflow!
					holding = false
					stream.Size = P(0.035, 0)
					for _ = 1, 6 do
						local d = Paint.blob(L.art, ctx.color, { Position = P(0.5 + rng:NextNumber(-0.2, 0.2), info.toArt(info.top)), Size = P(0.04, 0.04), ZIndex = L.art.ZIndex + 9, Blotch = false })
						FX.tween(d, 0.6, { Position = P(d.Position.X.Scale + rng:NextNumber(-0.1, 0.1), 0.98), BackgroundTransparency = 1 })
					end
					FX.floatText(panel, "Spilled!", T.Bad, P(0.3, 0.3), P(0.4, 0.1))
					api.finish(0.15)
					return
				end
			end
			setLevel(p)
			band.BackgroundTransparency = if p >= a and p <= b then 0.45 else 0.72
			local surfaceY = info.toArt(info.bottom - math.min(p, 1) * st.h)
			stream.Size = if holding then P(0.035, math.max(0, surfaceY - 0.16)) else P(0.035, 0)
		end)
	end)
end

-- Blend: hold to blend; the arrow climbs Chunky -> Regular -> Smooth; let go in the target.
local BLEND_BANDS = { { "Chunky", 0, 0.42 }, { "Regular", 0.42, 0.7 }, { "Smooth", 0.7, 1 } }
function Games.Blend(panel, action, ctx)
	local prm = action.params or {}
	local a, b, fillTime, rounds
	if prm.zoneMin then
		a, b, fillTime, rounds = prm.zoneMin, prm.zoneMax or 0.9, prm.fillTime or 2, 1
	else -- timing-style params (count, zone, speed)
		local w = prm.zone or 0.2
		a, b, fillTime, rounds = 0.75 - w / 2, 0.75 + w / 2, 1.4 / (prm.speed or 0.9), math.clamp(prm.count or 1, 1, 3)
	end
	local target = "Regular"
	for _, band in BLEND_BANDS do
		local c = (a + b) / 2
		if c >= band[2] and c < band[3] + 1e-6 then
			target = band[1]
		end
	end
	local L = layout(panel, action, ctx.label)
	local rig = scene(L.art, action.station, ctx.color, ctx.extra)
	-- chunks in the jar that melt away as you blend
	local chunks = {}
	if rig.vessel then
		for i = 1, 7 do
			local c = Paint.blob(rig.vessel, ctx.extra.fruitColor or Paint.tone(ctx.color).shade, { Position = P(0.15 + (i % 4) * 0.23, 0.55 + (i % 3) * 0.14),
				Size = P(0.16, 0.1), Corner = 0.3, Rotation = i * 25, ZIndex = rig.vessel.ZIndex + 3 })
			chunks[i] = c
		end
	end
	return run(panel, function(api)
		Paint.text(L.ctrl, "Make it " .. string.upper(target), { Color = T.Gold, Position = P(0.34, 0.02), Size = P(0.64, 0.09) })
		local meter = UI.card(L.ctrl, "#1b2131", { Position = P(0.04, 0.02), Size = P(0.24, 0.82), Corner = UDim.new(0.3, 0), Clip = true })
		for _, band in BLEND_BANDS do
			local isT = band[1] == target
			local f = Paint.new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = P(0, 1 - band[2]), Size = P(1, band[3] - band[2]),
				BackgroundColor3 = Paint.C(if isT then T.Gold elseif band[1] == "Chunky" then "#8c93a6" elseif band[1] == "Regular" then "#8ec5f0" else "#c7b3e6"),
				BackgroundTransparency = if isT then 0.1 else 0.6, ZIndex = meter.ZIndex + 1, Parent = meter })
			Paint.text(f, band[1], { Color = T.TextDark, Rotation = 0, Position = P(0.05, 0.35), Size = P(0.9, 0.3), ZIndex = f.ZIndex + 1, MaxSize = 16 })
		end
		local arrow = Paint.blob(meter, T.Text, { Position = P(0.5, 1), Size = P(1.1, 0.03), Corner = 0.4, ZIndex = meter.ZIndex + 4, Blotch = false })
		local pips = UI.pips(L.ctrl, rounds, { Position = P(0.66, 0.16), Size = P(0.6, 0.06) })
		local btn = UI.button(L.ctrl, prm.label or "HOLD TO BLEND", T.Accent, { Position = P(0.66, 0.46), Size = P(0.62, 0.28) })
		local holding, p, round, sum = false, 0, 1, 0
		api.on(btn.InputBegan, function(input)
			if UI.isPress(input) and api.alive() then
				holding = true
				rig.flow = 1
				FX.sound("Pour")
			end
		end)
		local function score(s)
			sum += s
			pips.set(round)
			if round >= rounds then
				api.finish(sum / rounds)
			else
				round += 1
				p = 0
				FX.floatText(panel, (UI.grade(s, true)), select(2, UI.grade(s)), P(0.3, 0.4), P(0.4, 0.1))
			end
		end
		api.on(UserInputService.InputEnded, function(input)
			if UI.isPress(input) and holding then
				holding = false
				rig.flow = 0
				score(zoneScore(p, a, b))
			end
		end)
		api.on(RunService.Heartbeat, function(dt)
			if holding then
				p += dt / fillTime
				if p >= 1.08 then
					holding = false
					rig.flow = 0
					FX.floatText(panel, "Over-blended!", T.Bad, P(0.3, 0.3), P(0.4, 0.1))
					score(0.3)
				end
			end
			arrow.Position = P(0.5, 1 - math.clamp(p, 0, 1))
			rig.spin = if holding then 6 else 0
			rig.set(0.5 + p * 0.4)
			for i, c in chunks do
				local k = math.clamp(1 - p * 1.2 + (i % 3) * 0.05, 0, 1)
				c.Size = P(0.16 * k, 0.1 * k)
				c.Rotation += if holding then dt * 400 else 0
			end
			rig.tick(dt)
		end)
	end)
end

-- Cook: a kitchen timer dial; stop it while the hand is in the gold wedge.
function Games.Cook(panel, action, ctx)
	local prm = action.params or {}
	local duration = prm.duration or (prm.fillTime and prm.fillTime * 2.2) or 4
	local a, b = prm.zoneMin or 0.72, prm.zoneMax or 0.9
	local L = layout(panel, action, ctx.label)
	local rig = scene(L.art, action.station, ctx.color, ctx.extra)
	return run(panel, function(api)
		local dial = UI.card(L.ctrl, "#fbf3e2", { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0), Size = P(0.78, 0.78), Corner = UDim.new(0.5, 0) })
		Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = dial })
		local dz = dial.ZIndex
		for k = 0, 35 do -- tick dots, gold inside the target wedge
			local p = k / 36
			local ang = p * math.pi * 2 - math.pi / 2
			local inZone = p >= a and p <= math.min(b, 1)
			local dot = Paint.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = P(0.5 + math.cos(ang) * 0.42, 0.5 + math.sin(ang) * 0.42),
				Size = if inZone then P(0.075, 0.075) else P(0.04, 0.04), BackgroundColor3 = Paint.C(if inZone then T.Gold else "#c9bfb0"), ZIndex = dz + 1, Parent = dial })
			Paint.round(dot, 0.5)
		end
		local handPivot = Paint.new("Frame", { BackgroundTransparency = 1, Size = P(1, 1), ZIndex = dz + 2, Parent = dial })
		local hand = Paint.new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.5), Size = P(0.035, 0.36),
			BackgroundColor3 = Paint.C("#3a2f45"), ZIndex = dz + 3, Parent = handPivot })
		Paint.round(hand, 0.5)
		Paint.blob(dial, T.Accent, { Size = P(0.12, 0.12), ZIndex = dz + 4, Blotch = false })
		local readout = Paint.text(dial, "", { Color = T.TextDark, Position = P(0.25, 0.6), Size = P(0.5, 0.14), ZIndex = dz + 5 })
		Paint.text(dial, prm.gauge or "Timer", { Color = "#8a7a90", Position = P(0.25, 0.26), Size = P(0.5, 0.09), ZIndex = dz + 5 })
		local btn = UI.button(L.ctrl, prm.label or "STOP", T.Accent, { Position = P(0.5, 0.88), Size = P(0.8, 0.16) })
		local p, dinged = 0, false
		rig.flow = 1
		api.on(btn.Activated, function()
			rig.flow = 0
			api.finish(zoneScore(p, a, b))
		end)
		-- the food visibly cooks: raw (pale) -> done (its colour) -> overdone (dark, smoking)
		local raw = ctx.color:Lerp(Color3.new(1, 1, 1), 0.45)
		local burnt = ctx.color:Lerp(Color3.fromHex("#3a2418"), 0.75)
		local tint, frameN = nil, 0
		api.on(RunService.Heartbeat, function(dt)
			p += dt / duration
			handPivot.Rotation = math.min(p, 1.3) * 360
			rig.set(p)
			rig.tick(dt)
			frameN += 1
			local target = rig.liquid and rig.liquid.Visible and rig.liquid or rig.surface
			if target and frameN % 5 == 0 then
				local c = if p <= b then raw:Lerp(ctx.color, math.clamp(p / math.max(b, 0.01), 0, 1)) else ctx.color:Lerp(burnt, math.clamp((p - b) / 0.3, 0, 1))
				if c ~= tint then
					tint = c
					Paint.shade(target, c, 0)
				end
			end
			-- sizzle: the pot/cup jitters a little while it's in the gold zone
			if rig.vessel and p >= a and p <= b then
				rig.vessel.Rotation = math.sin(os.clock() * 60) * 1.2
			elseif rig.vessel then
				rig.vessel.Rotation = 0
			end
			-- overcooking: grey smoke billows up
			if p > b and rng:NextNumber() < dt * 10 then
				local sm = Paint.blob(L.art, "#6b6470", { Position = P(0.5 + rng:NextNumber(-0.15, 0.15), (rig.vtop or 0.5)), Size = P(0.1, 0.1), ZIndex = L.art.ZIndex + 12, Blotch = false })
				sm.BackgroundTransparency = 0.3
				FX.tween(sm, 1.2, { Position = sm.Position - P(0, 0.3), Size = P(0.22, 0.22), BackgroundTransparency = 1 })
				task.delay(1.25, function()
					sm:Destroy()
				end)
			end
			if not dinged and p >= a then
				dinged = true
				FX.sound("Order")
				FX.bounce(dial, 0.06)
			end
			readout.Text = if prm.maxTemp then string.format("%d°C", math.floor(math.min(p, 1.2) * prm.maxTemp)) else string.format("%d%%", math.floor(math.min(p, 1.2) * 100))
			if p >= math.max(b, 1) + 0.25 then
				rig.flow = 0
				FX.floatText(panel, "Too long!", T.Bad, P(0.3, 0.3), P(0.4, 0.1))
				api.finish(0.2)
			end
		end)
	end)
end

-- Stack: add the layers in the exact order on the ticket.
function Games.Stack(panel, action, ctx)
	local L = layout(panel, action, ctx.label)
	local vessel = recipeCup(L.art, ctx)
	-- layers = the recipe's ingredients in step order (up to 4); decoys from the same shelves
	local layers, seen, shelves = {}, {}, {}
	for _, st in ctx.recipe and ctx.recipe.steps or {} do
		local it = Bridge.item(st[2])
		if it and it.storage and st[1] ~= "CupRack" and not seen[st[2]] and #layers < 4 then
			seen[st[2]] = true
			table.insert(layers, st[2])
			shelves[it.storage] = true
		end
	end
	local usePictures = #layers >= 2
	if not usePictures then
		layers = {}
		local grad = if ctx.recipe then Bridge.liquid(ctx.recipe) else { ctx.color }
		for i = 1, math.max(#grad, 3) do
			table.insert(layers, grad[((i - 1) % #grad) + 1])
		end
	end
	local options = table.clone(layers)
	if usePictures then
		local pool = {}
		for shelf in shelves do
			for _, id in Bridge.itemsIn(shelf) do
				if not seen[id] then
					table.insert(pool, id)
				end
			end
		end
		for _ = 1, math.min(2, #pool) do
			table.insert(options, table.remove(pool, rng:NextInteger(1, #pool)))
		end
	end
	for i = #options, 2, -1 do
		local j = rng:NextInteger(1, i)
		options[i], options[j] = options[j], options[i]
	end
	local n = #layers
	local limit = (n * 2 + 4) * Config.TimeLimitScale
	local function colorOf(v)
		if usePictures then
			local it = Bridge.item(v)
			return it and it.color or ctx.color
		end
		return v
	end
	return run(panel, function(api)
		local timer = UI.timer(panel, limit, { Position = P(0.04, 0.215), Size = P(0.92, 0.02) })
		-- the ticket: order of layers, bottom first
		local ticket = UI.card(L.ctrl, T.Paper, { Position = P(0.02, 0), Size = P(0.96, 0.2), Radius = 12 })
		Paint.text(ticket, "Order (bottom → top)", { Color = "#8a7a90", Position = P(0.04, 0.02), Size = P(0.9, 0.28), AlignX = Enum.TextXAlignment.Left, ZIndex = ticket.ZIndex + 1 })
		local steps = {}
		for i, v in layers do
			local c = UI.card(ticket, colorOf(v), { Position = P(0.04 + (i - 1) * (0.92 / n), 0.36), Size = P(0.92 / n - 0.02, 0.56), Corner = UDim.new(0.3, 0) })
			Paint.text(c, tostring(i), { Color = T.TextDark, Position = P(0.05, 0.1), Size = P(0.3, 0.8), ZIndex = c.ZIndex + 1 })
			if usePictures then
				local ic = Paint.new("Frame", { BackgroundTransparency = 1, Position = P(0.36, 0.05), Size = P(0.6, 0.9), ZIndex = c.ZIndex + 1, Parent = c })
				Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = ic })
				Bridge.icon(ic, "item", v, { Behind = T.Paper })
			end
			steps[i] = c
		end
		local grid = Paint.new("Frame", { BackgroundTransparency = 1, Position = P(0, 0.25), Size = P(1, 0.58), ZIndex = L.ctrl.ZIndex + 1, Parent = L.ctrl })
		Paint.new("UIGridLayout", { CellSize = P(0.31, 0.46), CellPadding = P(0.02, 0.04), Parent = grid })
		local nextI, mistakes = 1, 0
		local layerH = 0.86 / n
		for _, v in options do
			local b = Paint.new("TextButton", { Text = "", AutoButtonColor = false, ZIndex = grid.ZIndex + 1, Parent = grid })
			Paint.round(b, UDim.new(0, 14))
			Paint.shade(b, T.PanelLight, 60, true)
			local ic = Paint.new("Frame", { BackgroundTransparency = 1, Position = P(0.15, 0.04), Size = P(0.7, 0.64), ZIndex = b.ZIndex + 1, Parent = b })
			Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = ic })
			if usePictures then
				Bridge.icon(ic, "item", v, { Behind = T.PanelLight })
				Paint.text(b, Bridge.itemName(v), { Color = T.TextSoft, Position = P(0.04, 0.7), Size = P(0.92, 0.26), ZIndex = b.ZIndex + 1, MaxSize = 16 })
			else
				Paint.blob(ic, v, { Size = P(0.9, 0.9) })
			end
			-- drag each ingredient into the cup (a tap also drops it in)
			UI.draggable(panel, b, api.on, function(pos, held)
				if not api.alive() then
					held:Destroy()
					return true
				end
				if pos and not UI.inside(L.art, pos) then
					return false -- dropped outside the cup: floats back
				end
				if layers[nextI] ~= v then
					mistakes += 1
					FX.sound("Wrong")
					FX.wobble(held, 16, 0.3)
					FX.floatText(panel, "Wrong order!", T.Bad, P(0.3, 0.3), P(0.4, 0.08))
					return false
				end
				-- it tips into the cup, then a new layer rises with a little splash
				local top = vessel.AbsolutePosition + Vector2.new(vessel.AbsoluteSize.X / 2, 0) - panel.AbsolutePosition
				FX.tween(held, 0.25, { Position = UDim2.fromOffset(top.X, top.Y), Rotation = 60, Size = UDim2.fromOffset(20, 20) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				local idx = nextI
				task.delay(0.26, function()
					held:Destroy()
					if not vessel.Parent then
						return
					end
					local band = Paint.new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 1 - (idx - 1) * layerH), Size = P(1, 0),
						ZIndex = vessel.ZIndex + 1, Parent = vessel })
					Paint.shade(band, colorOf(v), 0)
					FX.tween(band, 0.35, { Size = P(1, layerH + 0.004) }, Enum.EasingStyle.Back)
					for _ = 1, 4 do
						local drop = Paint.blob(vessel, colorOf(v), { Position = P(0.5 + rng:NextNumber(-0.25, 0.25), 1 - idx * layerH), Size = P(0.08, 0.06), ZIndex = vessel.ZIndex + 3, Blotch = false })
						FX.tween(drop, 0.35, { Position = drop.Position - P(0, 0.08), BackgroundTransparency = 1 })
					end
					FX.sound("Pour")
				end)
				Paint.shade(steps[nextI], T.Good, 60, true)
				FX.bounce(steps[nextI], 0.3)
				nextI += 1
				if nextI > n then
					timer.stop()
					task.delay(0.6, function()
						api.finish(n / (n + mistakes * 0.6) * speedScore(timer.elapsed(), n * 1.3, limit))
					end)
				end
				return true
			end)
		end
		api.on(RunService.Heartbeat, function()
			if timer.remaining() <= 0 then
				api.finish(0.7 * (nextI - 1) / n)
			end
		end)
	end)
end

-- Toppings: drag each topping onto a marked spot on the drink (even placement scores best).
function Games.Toppings(panel, action, ctx)
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
			if ctx.extra.fruitId then
				Bridge.icon(piece, "item", ctx.extra.fruitId, { Behind = T.PanelLight })
			else
				Paint.art(piece, { Shape = if ctx.extra.fruitColor then "slice" else "leaf", Color = pieceColor })
			end
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


-- Drizzle: looking down into the cup, hold and drag the sauce over the dotted swirl.
function Games.Drizzle(panel, action, ctx)
	local prm = action.params or {}
	local L = layout(panel, action, ctx.label)
	local sauce = ctx.extra.syrupColor or Paint.tone(ctx.color).shade
	local limit = 12 * Config.TimeLimitScale
	-- top view: rim, drink surface, swirl of target dots
	local rim = Paint.blob(L.art, "#e3f1f8", { Size = P(0.9, 0.9), ZIndex = L.art.ZIndex + 1, Blotch = false })
	rim.BackgroundTransparency = 0.2
	Paint.blob(L.art, ctx.color, { Size = P(0.8, 0.8), ZIndex = L.art.ZIndex + 2 }) -- the drink, seen from above
	local targets = {}
	local N = 28
	for i = 1, N do
		local t = i / N
		local ang = t * math.pi * 4.2
		local r = 0.05 + t * 0.29
		local pos = Vector2.new(0.5 + math.cos(ang) * r, 0.5 + math.sin(ang) * r)
		local d = Paint.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = P(pos.X, pos.Y), Size = P(0.022, 0.022),
			BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.25, ZIndex = L.art.ZIndex + 4, Parent = L.art })
		Paint.round(d, 0.5)
		targets[i] = { pos = pos, dot = d, hit = false }
	end
	return run(panel, function(api)
		local timer = UI.timer(panel, limit, { Position = P(0.04, 0.215), Size = P(0.92, 0.02) })
		local bar = UI.gauge(L.ctrl, 0.9, 1, { Position = P(0.05, 0.08), Size = P(0.9, 0.08), Color = T.Good })
		Paint.text(L.ctrl, prm.label or "DRIZZLE", { Color = T.Gold, Position = P(0, 0.22), Size = P(1, 0.12) })
		Paint.text(L.ctrl, "Hold and trace the dotted swirl", { Color = T.TextSoft, Position = P(0, 0.36), Size = P(1, 0.07) })
		local done = UI.button(L.ctrl, "DONE", T.PanelLight, { Position = P(0.5, 0.6), Size = P(0.6, 0.16), TextColor = T.Text })
		local drawing, lastQ, samples, mess, hits = false, nil, 0, 0, 0
		local function result()
			local cover = hits / N
			return math.clamp(cover - (mess / math.max(samples, 1)) * 0.5, 0, 1)
		end
		api.on(done.Activated, function()
			api.finish(result())
		end)
		api.on(L.art.InputBegan, function(input)
			if UI.isPress(input) then
				drawing = true
				lastQ = nil
			end
		end)
		api.on(UserInputService.InputEnded, function(input)
			if UI.isPress(input) then
				drawing = false
			end
		end)
		api.on(UserInputService.InputChanged, function(input)
			if not (drawing and isMove(input)) then
				return
			end
			local q = inFrame(L.art, UI.pointer(input))
			if lastQ and (q - lastQ).Magnitude < 0.012 then
				return
			end
			lastQ = q
			samples += 1
			local blob = Paint.blob(L.art, sauce, { Position = P(q.X, q.Y), Size = P(0.035, 0.035), ZIndex = L.art.ZIndex + 5, Blotch = false })
			local near = false
			for _, t in targets do
				local d = (q - t.pos).Magnitude
				if d < 0.09 then
					near = true
				end
				if not t.hit and d < 0.045 then
					t.hit = true
					hits += 1
					t.dot.Visible = false
				end
			end
			if not near then
				mess += 1
				blob.BackgroundTransparency = 0.35
			end
			bar.set(hits / N)
			if hits / N >= 0.92 then
				timer.stop()
				api.finish(result())
			end
		end)
		api.on(RunService.Heartbeat, function()
			if timer.remaining() <= 0 then
				api.finish(result() * 0.85)
			end
		end)
	end)
end

-- ================================================================
-- COOKING-MAMA-STYLE GAMES
-- ================================================================

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

function Games.Peel(panel, action, ctx)
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
				-- a peel strip flies off the fruit
				local strip = Paint.blob(L.art, ctx.extra.fruitColor or ctx.color, { Position = P(0.5, 0.6), Size = P(0.05, 0.16),
					Rotation = rng:NextNumber(-40, 40), ZIndex = L.art.ZIndex + 12 })
				FX.tween(strip, 0.6, { Position = P(0.5 + (if vertical then 0 else dir * 0.35), 0.6 - 0.25), Rotation = strip.Rotation + dir * 120,
					BackgroundTransparency = 1 })
				task.delay(0.62, function()
					strip:Destroy()
				end)
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

function Games.Stir(panel, action, ctx)
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


-- Shake: follow the arrow pattern.
local ARROWS = {
	Up = { "⬆", Vector2.new(0, -1), { Enum.KeyCode.Up, Enum.KeyCode.W } },
	Down = { "⬇", Vector2.new(0, 1), { Enum.KeyCode.Down, Enum.KeyCode.S } },
	Left = { "⬅", Vector2.new(-1, 0), { Enum.KeyCode.Left, Enum.KeyCode.A } },
	Right = { "➡", Vector2.new(1, 0), { Enum.KeyCode.Right, Enum.KeyCode.D } },
}
local ARROW_NAMES = { "Up", "Down", "Left", "Right" }
function Games.Shake(panel, action, ctx)
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


-- Your DrinkCatalog game types (and older names) map onto the 12 games.
Games.Hold = Games.Fill
Games.Timing = Games.Blend
Games.Tap = Games.Mash
Games.Swipe = Games.Peel
Games.Circle = Games.Stir
Games.Sequence = Games.Shake
Games.Drag = Games.Toppings
Games.Steady = Games.Fill

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
	local kind = (Config.Games and Config.Games[actionId]) or action.game
	local playFn = Games[kind] or Games[action.game] or Games.Mash
	return playFn(panel, action, ctx)
end

MiniGames.Games = Games
return MiniGames
