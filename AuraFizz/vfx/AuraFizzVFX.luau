--!nonstrict
-- AuraFizzVFX v2 (ModuleScript in ReplicatedStorage): clean, shiny anime auras for drinking / eating.
-- Call it from the SERVER when a player drinks (particles and beams replicate to everyone):
--
--   local VFX = require(game.ReplicatedStorage.AuraFizzVFX)
--   VFX.PlayDrink(player, "iced_latte")            -- aura for that drink (its colour + category + tier)
--   VFX.Play(player, "Blaze", Color3.fromRGB(255, 110, 40), { Seconds = 6, Tier = "Luscious" })  -- foods / custom
--   VFX.Stop(player)
--
-- The shine: every texture is white/grey with a glow halo, and everything here uses
-- LightEmission = 1 (additive) + Brightness, so cores blow out white-hot and the colour glows.
-- The spinning rings are Beams (4 curved segments per ring) with the Streak texture scrolling
-- round them. Tip: a Bloom effect in Lighting (Intensity ~1, Threshold ~1.5) makes it glow even more.
--
-- Upload the PNGs from vfx/sheets and paste their ids below. Until then a built-in texture is used.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VFX = {}

-- ===== EDIT ME: asset ids of the uploaded sheets (numbers) =====
VFX.Textures = {
	Flame = 0, Wisp = 0, Sparkle = 0, Bolt = 0, Impact = 0, Bubbles = 0, Puff = 0, Glow = 0,
	Streak = 0, -- AuraFX_Streak.png (beam texture for the rings, not a flipbook)
	Swirl = 0, -- optional: only used by the "SwirlFlat" layer
}
VFX.Seconds = 7 -- how long an aura lasts after drinking
-- ================================================================

-- Which aura each drink category gets (your DrinkRecipes category names).
VFX.CategoryPreset = {
	["Hot Caffeinated Drinks"] = "Blaze",
	["Cold Caffeinated Drinks"] = "Cyclone",
	["Fruit Smoothie Drinks"] = "Bloom",
	["Milkshakes"] = "Bloom",
	["Carbonated Drinks (Cola/Soda)"] = "Fizz",
	["Boba Fruity"] = "Cyclone",
	["Boba Confectionary"] = "Bloom",
	["Juices"] = "Splash",
	["Milk-Based Drinks"] = "Bloom",
	["Mocktails"] = "Cyclone",
	["Sparkling Grape Juices"] = "Fizz",
	["Craft Sodas & Floats"] = "Fizz",
}
-- Higher tiers get extra layers on top of their preset.
VFX.TierExtras = {
	Luscious = { "RingMid" },
	Delectable = { "RingMid", "Bolts" },
	Ambrosial = { "RingMid", "RingHigh", "Bolts", "GoldSparkles" },
}

-- ---------------------------------------------------------------- particle layers
-- where: "Body" (whole HumanoidRootPart box) | "Feet" | "Waist" | "Chest"
-- once: frames play once over each particle's life (else loop)   burst: emitted once at the start
-- tint: "main" | "light" | "gold"
local L = {}
L.Glow = { sheet = "Glow", where = "Waist", rate = 3, life = { 1, 1.2 }, size = { 5, 6, 6 }, bright = 0.6, fps = 12, tint = "main", fadeIn = true }
L.FlameAura = { sheet = "Flame", where = "Body", rate = 22, life = { 0.55, 0.85 }, size = { 1.6, 2.6, 0.2 }, speed = { 3, 6 }, spread = 20, up = 8, bright = 2.2, fps = 24, tint = "main" }
L.Wisps = { sheet = "Wisp", where = "Body", rate = 7, life = { 0.6, 0.8 }, size = { 1.6, 2.4, 2 }, speed = { 4, 7 }, spread = 15, once = true, bright = 2.5, tint = "light" }
L.Sparkles = { sheet = "Sparkle", where = "Body", rate = 8, life = { 0.5, 0.7 }, size = { 0.8, 1.4, 0.4 }, speed = { 1, 3 }, spread = 180, once = true, bright = 3, tint = "light" }
L.GoldSparkles = { sheet = "Sparkle", where = "Body", rate = 9, life = { 0.5, 0.7 }, size = { 1, 1.7, 0.4 }, speed = { 2, 4 }, spread = 180, once = true, bright = 3, tint = "gold" }
L.Bolts = { sheet = "Bolt", where = "Body", rate = 3, life = { 0.35, 0.45 }, size = { 3, 3.6, 3.6 }, once = true, bright = 4, tint = "light" }
L.Bubbles = { sheet = "Bubbles", where = "Body", rate = 4, life = { 1, 1.4 }, size = { 2, 2.6, 2.8 }, speed = { 2, 3 }, spread = 10, bright = 1.8, fps = 14, tint = "light" }
L.Impact = { sheet = "Impact", where = "Chest", burst = 1, life = { 0.45, 0.45 }, size = { 2, 8, 9 }, once = true, bright = 3, tint = "light" }
L.Puffs = { sheet = "Puff", where = "Feet", burst = 5, life = { 0.6, 0.8 }, size = { 1.5, 3.2, 3.6 }, speed = { 3, 5 }, spread = 80, once = true, bright = 1.2, tint = "light" }
L.Splashes = { sheet = "Puff", where = "Waist", rate = 3, life = { 0.5, 0.7 }, size = { 1, 2, 2.2 }, speed = { 2, 4 }, spread = 180, once = true, bright = 1.5, tint = "main" }
L.SwirlFlat = { sheet = "Swirl", where = "Feet", rate = 2, life = { 1.1, 1.3 }, size = { 4.5, 6.5, 7 }, flat = true, spin = { 140, 260 }, bright = 2.5, fps = 20, tint = "light" }
-- ---------------------------------------------------------------- beam rings (spinning brush streaks)
-- r radius, y height (studs from HumanoidRootPart), w width, speed = texture scroll (negative = other way), tilt (radians)
L.RingLow = { ring = true, r = 3.0, y = -2.4, w = 0.9, speed = 0.9, tint = "main", tilt = 0 }
L.RingMid = { ring = true, r = 2.3, y = -0.4, w = 0.7, speed = -1.2, tint = "light", tilt = 0.12 }
L.RingHigh = { ring = true, r = 1.7, y = 1.5, w = 0.55, speed = 1.5, tint = "main", tilt = -0.1 }
VFX.Layers = L

-- The aura structures (recoloured per drink):
VFX.Presets = {
	Cyclone = { "Glow", "RingLow", "RingMid", "RingHigh", "Wisps", "Sparkles", "Impact" }, -- spinning streak rings, no centre orb
	Blaze = { "Glow", "FlameAura", "Wisps", "Sparkles", "RingLow", "Impact" },             -- anime fire aura
	Bloom = { "Glow", "Sparkles", "Wisps", "RingLow", "Puffs", "Impact" },                  -- soft sparkly glow
	Fizz = { "Glow", "Bubbles", "Sparkles", "RingLow", "Impact" },                          -- sodas & sparkling
	Splash = { "Glow", "Splashes", "Sparkles", "RingLow", "Impact" },                       -- juices
}

-- ---------------------------------------------------------------- helpers
local FALLBACK = "rbxasset://textures/particles/sparkles_main.dds"
local Y = { Feet = -2.8, Waist = -0.6, Chest = 1.1, Body = 0 }

local function range(t)
	return NumberRange.new(t[1], t[2] or t[1])
end

local function palette(main)
	local h, s, v = main:ToHSV()
	local vivid = Color3.fromHSV(h, math.clamp(s * 1.2 + 0.15, 0, 1), math.max(v, 0.9))
	if s < 0.12 then -- whites / creams / greys: a bright, slightly warm pearl
		vivid = Color3.fromHSV(0.1, 0.15, 1)
	end
	return {
		main = vivid,
		light = vivid:Lerp(Color3.new(1, 1, 1), 0.35),
		gold = Color3.fromRGB(255, 209, 89),
	}
end

local function characterOf(who)
	if typeof(who) == "Instance" and who:IsA("Player") then
		return who.Character
	end
	return who
end

local function tex(name)
	local id = VFX.Textures[name] or 0
	return if id > 0 then "rbxassetid://" .. id else nil
end

local function emitter(def, parent, pal)
	local e = Instance.new("ParticleEmitter")
	e.Name = "AuraFX"
	local t = tex(def.sheet)
	if t then
		e.Texture = t
		e.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
		e.FlipbookMode = if def.once then Enum.ParticleFlipbookMode.OneShot else Enum.ParticleFlipbookMode.Loop
		if not def.once then
			e.FlipbookFramerate = NumberRange.new(def.fps or 20)
			e.FlipbookStartRandom = true
		end
	else
		e.Texture = FALLBACK
	end
	e.Color = ColorSequence.new(pal[def.tint or "main"])
	e.LightEmission = 1 -- additive: this is the "shiny" part
	e.LightInfluence = 0
	e.Brightness = def.bright or 2
	e.Lifetime = range(def.life)
	local s = def.size
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, s[1]), NumberSequenceKeypoint.new(0.35, s[2]), NumberSequenceKeypoint.new(1, s[3] or s[2]) })
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, if def.fadeIn then 1 else 0),
		NumberSequenceKeypoint.new(if def.fadeIn then 0.3 else 0.05, 0),
		NumberSequenceKeypoint.new(0.8, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Speed = range(def.speed or { 0, 0 })
	e.SpreadAngle = Vector2.new(def.spread or 0, def.spread or 0)
	e.Rotation = NumberRange.new(-15, 15)
	e.RotSpeed = range(def.spin or { 0, 0 })
	e.EmissionDirection = Enum.NormalId.Top
	e.ZOffset = 0.5
	if def.up then
		e.Acceleration = Vector3.new(0, def.up, 0)
	end
	if def.flat then
		e.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		e.Speed = NumberRange.new(0.01)
		e.SpreadAngle = Vector2.new(0, 0)
		e.Rotation = NumberRange.new(-180, 180)
	end
	if def.sheet == "Sparkle" or def.sheet == "Bolt" then
		e.Rotation = NumberRange.new(-180, 180)
	end
	e.Rate = if def.burst then 0 else (def.rate or 5)
	e.Parent = parent
	return e
end

-- A spinning ring: 4 quarter-circle Beams (Bezier handles 0.5523 r) with the Streak texture
-- scrolling round it. TextureLength = one quarter, so the wrapping texture has no seams.
local function beamRing(def, root, pal, list)
	local r = def.r
	local tilt = CFrame.Angles(def.tilt or 0, 0, 0)
	local atts = {}
	for i = 0, 3 do
		local a = i * math.pi / 2
		local pos = tilt * Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local tangent = tilt:VectorToWorldSpace(Vector3.new(-math.sin(a), 0, math.cos(a)))
		local att = Instance.new("Attachment")
		att.Name = "AuraFX_Ring"
		att.Position = Vector3.new(0, def.y, 0) + pos
		att.Axis = tangent
		att.Parent = root
		atts[i] = att
		table.insert(list, att)
	end
	local streak = tex("Streak")
	for i = 0, 3 do
		local b = Instance.new("Beam")
		b.Name = "AuraFX_Ring"
		b.Attachment0 = atts[i]
		b.Attachment1 = atts[(i + 1) % 4]
		b.CurveSize0 = r * 0.5523
		b.CurveSize1 = r * 0.5523
		b.Segments = 14
		b.FaceCamera = true
		b.Width0 = def.w
		b.Width1 = def.w
		b.Color = ColorSequence.new(pal[def.tint or "main"])
		b.LightEmission = 1
		b.LightInfluence = 0
		b.Brightness = 3
		if streak then
			b.Texture = streak
			b.TextureMode = Enum.TextureMode.Stretch
			b.TextureLength = 1
			b.TextureSpeed = def.speed
		else
			b.Transparency = NumberSequence.new(0.55)
			b.Width0, b.Width1 = def.w * 0.25, def.w * 0.25
		end
		b.Parent = root
		table.insert(list, b)
	end
end

-- ---------------------------------------------------------------- API
local active = {} -- [character] = { instances }

function VFX.Stop(who)
	local char = characterOf(who)
	local list = char and active[char]
	if not list then
		return
	end
	active[char] = nil
	for _, inst in list do
		if inst:IsA("ParticleEmitter") then
			inst.Enabled = false
		elseif inst:IsA("Beam") then
			inst.Enabled = false
		end
	end
	task.delay(1.5, function()
		for _, inst in list do
			inst:Destroy()
		end
	end)
end

-- Play a preset (or a list of layer names) in any colour. opts = { Seconds = n, Tier = "Ambrosial" }
function VFX.Play(who, preset, color, opts)
	opts = opts or {}
	local char = characterOf(who)
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	VFX.Stop(char)
	local names = if typeof(preset) == "table" then table.clone(preset) else table.clone(VFX.Presets[preset] or VFX.Presets.Bloom)
	for _, extra in VFX.TierExtras[opts.Tier or ""] or {} do
		if not table.find(names, extra) then
			table.insert(names, extra)
		end
	end
	local pal = palette(color or Color3.fromRGB(245, 154, 192))
	local list, anchors = {}, {}
	for _, name in names do
		local def = L[name]
		if def and def.ring then
			beamRing(def, root, pal, list)
		elseif def then
			local parent = root
			if def.where ~= "Body" then
				if not anchors[def.where] then
					local a = Instance.new("Attachment")
					a.Name = "AuraFX_" .. def.where
					a.Position = Vector3.new(0, Y[def.where] or 0, 0)
					a.Parent = root
					anchors[def.where] = a
					table.insert(list, a)
				end
				parent = anchors[def.where]
			end
			local e = emitter(def, parent, pal)
			table.insert(list, e)
			if def.burst then
				task.defer(function()
					e:Emit(def.burst)
				end)
			end
		end
	end
	local glow = Instance.new("PointLight")
	glow.Name = "AuraFX"
	glow.Color = pal.main
	glow.Range = 12
	glow.Brightness = 2
	glow.Parent = root
	table.insert(list, glow)
	active[char] = list
	task.delay(opts.Seconds or VFX.Seconds, function()
		if active[char] == list then
			VFX.Stop(char)
		end
	end)
	return list
end

-- The drink's aura: colour from DrinkLooks (else the recipe colour), structure from its
-- category, extras from its tier. Reads your ReplicatedStorage.Drinks modules.
local recipes, looks
local function loadDrinks()
	if recipes then
		return
	end
	recipes, looks = {}, {}
	local folder = ReplicatedStorage:FindFirstChild("Drinks")
	local function req(n)
		local m = folder and folder:FindFirstChild(n)
		local ok, res = pcall(function()
			return m and require(m)
		end)
		return if ok then res else nil
	end
	for _, r in req("DrinkRecipes") or {} do
		if r.id then
			recipes[r.id] = r
		end
	end
	looks = req("DrinkLooks") or {}
end

function VFX.DrinkColor(drinkId)
	loadDrinks()
	local look = looks[drinkId]
	if look and look.grad and #look.grad > 0 then
		return Color3.fromHex(look.grad[#look.grad])
	end
	local r = recipes[drinkId]
	return r and r.color or Color3.fromRGB(245, 154, 192)
end

function VFX.PresetFor(drinkId)
	loadDrinks()
	local r = recipes[drinkId]
	return (r and VFX.CategoryPreset[r.category]) or "Bloom", r and r.tier
end

function VFX.PlayDrink(who, drinkId, seconds)
	local preset, tier = VFX.PresetFor(drinkId)
	return VFX.Play(who, preset, VFX.DrinkColor(drinkId), { Seconds = seconds, Tier = tier })
end

return VFX
