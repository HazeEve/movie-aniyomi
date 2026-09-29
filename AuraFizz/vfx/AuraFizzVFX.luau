--!nonstrict
-- AuraFizzVFX (ModuleScript in ReplicatedStorage) — cel-style anime auras for drinking / eating.
-- Call it from the SERVER when a player drinks (particles replicate to everyone):
--
--   local VFX = require(game.ReplicatedStorage.AuraFizzVFX)
--   VFX.PlayDrink(player, "iced_latte")            -- aura for that drink (its colour + category + tier)
--   VFX.Play(player, "Blaze", Color3.fromRGB(255, 120, 60), { Seconds = 6, Tier = 3 })  -- any food / custom
--   VFX.Stop(player)
--
-- 8 grayscale flipbook sheets (vfx/sheets/AuraFX_*.png, 4x4 frames) are recoloured per drink
-- with ParticleEmitter.Color, so every drink gets its own colours from only 8 uploads.
-- Upload the PNGs, paste the ids below. Until then a built-in Roblox texture is used.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local VFX = {}

-- ===== EDIT ME: asset ids of the uploaded sheets (numbers) =====
VFX.Textures = {
	Flame = 0, Swirl = 0, Wisp = 0, Sparkle = 0, Bolt = 0, Shockwave = 0, Bubbles = 0, Puff = 0,
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
-- Tier extras: Delectable adds lightning; Ambrosial adds lightning + gold sparkles + flames.
VFX.TierExtras = {
	Delectable = { "Bolts" },
	Ambrosial = { "Bolts", "GoldSparkles", "FlameAura" },
}

-- ---------------------------------------------------------------- layers
-- where: "Body" (emits from the whole HumanoidRootPart box), "Feet", "Waist", "Chest"
-- once: frames play once over each particle's life (else loop)   burst: emitted once at the start
-- tint: "main" | "light" | "dark" | "gold"
local L = {}
L.FlameAura = { sheet = "Flame", where = "Body", rate = 22, life = { 0.55, 0.85 }, size = { 1.6, 2.6, 0.2 },
	speed = { 3, 6 }, spread = 20, up = 8, light = 0.6, bright = 2, z = 0.5, fps = 24, tint = "main" }
L.SwirlLow = { sheet = "Swirl", where = "Feet", rate = 2.5, life = { 1.1, 1.3 }, size = { 4.5, 6.5, 7 }, flat = true,
	spin = { 140, 260 }, light = 0.8, bright = 2.5, fps = 20, tint = "light" }
L.SwirlMid = { sheet = "Swirl", where = "Waist", rate = 2, life = { 1, 1.2 }, size = { 3.5, 5, 5.5 }, flat = true,
	spin = { -260, -140 }, light = 0.8, bright = 2.5, fps = 20, tint = "main" }
L.SwirlHigh = { sheet = "Swirl", where = "Chest", rate = 1.6, life = { 0.9, 1.1 }, size = { 2.6, 3.8, 4.2 }, flat = true,
	spin = { 160, 300 }, light = 0.8, bright = 2.5, fps = 20, tint = "light" }
L.Wisps = { sheet = "Wisp", where = "Body", rate = 7, life = { 0.6, 0.8 }, size = { 1.6, 2.4, 2 }, speed = { 4, 7 },
	spread = 15, light = 0.7, bright = 2, once = true, tint = "light" }
L.Sparkles = { sheet = "Sparkle", where = "Body", rate = 7, life = { 0.5, 0.7 }, size = { 0.7, 1.2, 0.4 }, speed = { 1, 3 },
	spread = 180, light = 1, bright = 3, once = true, tint = "light" }
L.GoldSparkles = { sheet = "Sparkle", where = "Body", rate = 9, life = { 0.5, 0.7 }, size = { 0.9, 1.5, 0.4 }, speed = { 2, 4 },
	spread = 180, light = 1, bright = 3, once = true, tint = "gold" }
L.Bolts = { sheet = "Bolt", where = "Body", rate = 5, life = { 0.18, 0.28 }, size = { 2.2, 3.2, 3 }, speed = { 0, 0 },
	light = 1, bright = 4, fps = 30, tint = "light" }
L.Bubbles = { sheet = "Bubbles", where = "Body", rate = 4, life = { 1, 1.4 }, size = { 2, 2.6, 2.8 }, speed = { 2, 3 },
	spread = 10, light = 0.5, bright = 1.5, fps = 14, tint = "light" }
L.Burst = { sheet = "Shockwave", where = "Feet", burst = 1, life = { 0.5, 0.5 }, size = { 1, 11, 13 }, flat = true,
	light = 1, bright = 3, once = true, tint = "light" }
L.BurstUp = { sheet = "Shockwave", where = "Chest", burst = 1, life = { 0.4, 0.4 }, size = { 1, 7, 8 },
	light = 1, bright = 3, once = true, tint = "main" }
L.Puffs = { sheet = "Puff", where = "Feet", burst = 5, life = { 0.6, 0.8 }, size = { 1.5, 3.2, 3.6 }, speed = { 3, 5 },
	spread = 80, light = 0.2, bright = 1, once = true, tint = "light" }
L.Splashes = { sheet = "Puff", where = "Waist", rate = 3, life = { 0.5, 0.7 }, size = { 1, 2, 2.2 }, speed = { 2, 4 },
	spread = 180, light = 0.4, bright = 1.5, once = true, tint = "main" }
VFX.Layers = L

-- The aura structures (recoloured per drink):
VFX.Presets = {
	Blaze = { "FlameAura", "Wisps", "Sparkles", "Burst", "Puffs" },            -- hot coffee: cel fire aura
	Cyclone = { "SwirlLow", "SwirlMid", "SwirlHigh", "Wisps", "Burst" },       -- spinning brush rings, no centre orb
	Bloom = { "Sparkles", "Wisps", "SwirlLow", "Puffs", "BurstUp" },          -- soft sparkly glow
	Fizz = { "Bubbles", "Sparkles", "SwirlLow", "Burst" },                     -- sodas & sparkling
	Splash = { "Splashes", "Sparkles", "Wisps", "Burst" },                     -- juices
	Storm = { "Bolts", "SwirlMid", "Wisps", "Sparkles", "Burst" },             -- extra for energy / specials
}

-- ---------------------------------------------------------------- helpers
local FALLBACK = "rbxasset://textures/particles/sparkles_main.dds"

local function range(t)
	return NumberRange.new(t[1], t[2] or t[1])
end

local function sizeSeq(s)
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, s[1]),
		NumberSequenceKeypoint.new(0.35, s[2]),
		NumberSequenceKeypoint.new(1, s[3] or s[2]),
	})
end

local function palette(main)
	local h, s, v = main:ToHSV()
	local vivid = Color3.fromHSV(h, math.clamp(s * 1.15 + 0.1, 0, 1), math.max(v, 0.85))
	if s < 0.12 then -- whites / creams / greys: keep them bright and a little warm
		vivid = Color3.fromHSV(0.1, 0.12, 0.97)
	end
	return {
		main = vivid,
		light = vivid:Lerp(Color3.new(1, 1, 1), 0.45),
		dark = vivid:Lerp(Color3.new(0, 0, 0), 0.3),
		gold = Color3.fromRGB(255, 214, 102),
	}
end

local function characterOf(who)
	if typeof(who) == "Instance" and who:IsA("Player") then
		return who.Character
	end
	return who
end

local function anchor(root, where)
	local y = ({ Feet = -2.8, Waist = -0.6, Chest = 1.1, Body = 0 })[where] or 0
	local a = Instance.new("Attachment")
	a.Name = "AuraFX_" .. where
	a.Position = Vector3.new(0, y, 0)
	a.Parent = root
	return a
end

local function emitter(def, parent, pal)
	local e = Instance.new("ParticleEmitter")
	e.Name = "AuraFX"
	local id = VFX.Textures[def.sheet] or 0
	if id > 0 then
		e.Texture = "rbxassetid://" .. id
		e.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
		e.FlipbookMode = if def.once then Enum.ParticleFlipbookMode.OneShot else Enum.ParticleFlipbookMode.Loop
		if not def.once then
			e.FlipbookFramerate = NumberRange.new(def.fps or 20)
			e.FlipbookStartRandom = true
		end
	else
		e.Texture = FALLBACK
	end
	local c = pal[def.tint or "main"]
	e.Color = ColorSequence.new(c, pal.light)
	e.LightEmission = def.light or 0.6
	e.LightInfluence = 0
	e.Brightness = def.bright or 1.5
	e.Lifetime = range(def.life)
	e.Size = sizeSeq(def.size)
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.8, 0), NumberSequenceKeypoint.new(1, 1) })
	e.Speed = range(def.speed or { 0, 0 })
	e.SpreadAngle = Vector2.new(def.spread or 0, def.spread or 0)
	e.Rotation = NumberRange.new(-180, 180)
	e.RotSpeed = range(def.spin or { -30, 30 })
	e.ZOffset = def.z or 0
	e.EmissionDirection = Enum.NormalId.Top
	if def.up then
		e.Acceleration = Vector3.new(0, def.up, 0)
	end
	if def.flat then
		-- lies flat around the player like the tornado rings (Speed tiny so it has a direction)
		e.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		e.Speed = NumberRange.new(0.01)
		e.SpreadAngle = Vector2.new(0, 0)
	end
	e.Rate = def.burst and 0 or (def.rate or 5)
	e.Parent = parent
	return e
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
		end
	end
	task.delay(1.5, function()
		for _, inst in list do
			inst:Destroy()
		end
	end)
end

-- Play a preset (or a list of layer names) in any colour. opts = { Seconds, Tier }
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
	local list = {}
	local anchors = {}
	for _, name in names do
		local def = L[name]
		if def then
			local parent = root
			if def.where ~= "Body" then
				anchors[def.where] = anchors[def.where] or anchor(root, def.where)
				parent = anchors[def.where]
				table.insert(list, parent)
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
	-- a soft light in the aura colour
	local glow = Instance.new("PointLight")
	glow.Color = pal.main
	glow.Range = 10
	glow.Brightness = 1.5
	glow.Parent = root
	table.insert(list, glow)
	active[char] = list
	local seconds = opts.Seconds or VFX.Seconds
	task.delay(seconds, function()
		if active[char] == list then
			VFX.Stop(char)
		end
	end)
	Debris:AddItem(glow, seconds + 2)
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
		return ok and res or nil
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
