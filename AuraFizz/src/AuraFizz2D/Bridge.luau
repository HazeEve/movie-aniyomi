--!nonstrict
-- AuraFizz2D · Bridge — the only file that knows about your game's modules.
--   ReplicatedStorage.Drinks.DrinkRecipes   recipes + steps (storage / appliance / ServeCounter)
--   ReplicatedStorage.Drinks.DrinkCatalog   stations, cups, storage items, actions (mini-games)
--   ReplicatedStorage.Drinks.DrinkLooks     liquid colours per drink
--   ReplicatedStorage.Drinks.DrinkImages    your picture sheets (IMG.Apply)
--   ReplicatedStorage.Drinks.Sounds         your sound ids (S.Ids)
-- If a module is missing, the 2D game still runs with painted fallbacks.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(script.Parent.Config)
local Paint = require(script.Parent.Paint)

local Bridge = {}

local folder = ReplicatedStorage:WaitForChild(Config.DrinksFolder, 15)
if not folder then
	warn("[AuraFizz2D] ReplicatedStorage." .. Config.DrinksFolder .. " not found - the 2D game needs your Drinks modules")
end

local function load(name)
	local m = folder and folder:FindFirstChild(name)
	if not (m and m:IsA("ModuleScript")) then
		return nil
	end
	local ok, res = pcall(require, m)
	if not ok then
		warn("[AuraFizz2D] could not load Drinks." .. name .. ": " .. tostring(res))
		return nil
	end
	return res
end

Bridge.Recipes = load("DrinkRecipes") or {}
Bridge.Catalog = load("DrinkCatalog") or {}
Bridge.Looks = load("DrinkLooks") or {}
Bridge.Images = load("DrinkImages")
Bridge.Sounds = load("Sounds")

local C = Bridge.Catalog
C.Stations = C.Stations or {}
C.Cups = C.Cups or {}
C.Items = C.Items or {}
C.Actions = C.Actions or {}
C.CupOrder = C.CupOrder or {}
C.ItemOrder = C.ItemOrder or {}

local byId = {}
for _, r in Bridge.Recipes do
	if r.id and not r.alcohol then
		byId[r.id] = r
	end
end

-- ---------------- lookups ----------------
function Bridge.recipe(id)
	return byId[id]
end

function Bridge.allRecipes()
	local out = {}
	for _, r in Bridge.Recipes do
		if r.id and not r.alcohol then
			table.insert(out, r)
		end
	end
	return out
end

function Bridge.categories()
	local seen, out = {}, {}
	for _, r in Bridge.allRecipes() do
		if r.category and not seen[r.category] then
			seen[r.category] = true
			table.insert(out, r.category)
		end
	end
	return out
end

function Bridge.station(key)
	return C.Stations[key] or { name = key, kind = "appliance", plate = string.upper(key) }
end

function Bridge.action(id)
	return C.Actions[id]
end

function Bridge.item(id)
	return C.Items[id] or C.Cups[id]
end

function Bridge.itemName(id)
	local it = Bridge.item(id)
	return it and it.name or id
end

-- Everything kept in one storage station, in your ItemOrder (CupRack -> CupOrder).
function Bridge.itemsIn(stationKey)
	if stationKey == "CupRack" then
		return table.clone(C.CupOrder)
	end
	local out = {}
	for _, id in C.ItemOrder do
		local it = C.Items[id]
		if it and it.storage == stationKey and not it.alcohol then
			table.insert(out, id)
		end
	end
	return out
end

-- ---------------- colours ----------------
local function hex(c)
	if typeof(c) == "Color3" then
		return c
	end
	if typeof(c) == "string" then
		return Color3.fromHex(c)
	end
	return nil
end

-- Liquid gradient for a drink, bottom -> top (DrinkLooks.grad, else recipe.color)
function Bridge.liquid(recipe)
	local look = Bridge.Looks[recipe.id]
	local out = {}
	if look and look.grad then
		for _, h in look.grad do
			table.insert(out, hex(h))
		end
	end
	if #out == 0 then
		out = { recipe.color or Color3.fromHex("#d9c9b8") }
	end
	return out, look and look.mode or "Smooth"
end

function Bridge.drinkColor(recipe)
	local g = Bridge.liquid(recipe)
	return g[#g]
end

-- ---------------- sounds ----------------
function Bridge.soundId(name)
	local S = Bridge.Sounds
	local id = S and S.Ids and S.Ids[name]
	if typeof(id) == "number" and id > 0 then
		return "rbxassetid://" .. id
	elseif typeof(id) == "string" and id ~= "" and not id:find("://0$") then
		return id
	end
	return nil
end

-- ---------------- pictures ----------------
local FRUIT_SLICE = { orange = 1, lemon = 1, lime = 1, calamansi = 1, kiwi = 1, watermelon = 1, dragon_fruit = 1,
	papaya = 1, melon = 1, guava = 1, cucumber = 1, passion_fruit = 1, pomegranate = 1 }
local function descFor(kind, id)
	if kind == "cup" or C.Cups[id] then
		return { Shape = "cup", CupStyle = id, Color = "#eef6fb" }
	end
	if kind == "drink" then
		local r = byId[id]
		return { Shape = "cup", CupStyle = r and r.cup or "tall_glass", Color = "#eef6fb" }
	end
	local it = C.Items[id] or {}
	local col = it.color or Color3.fromHex("#d9c9b8")
	local st = it.storage
	local shape = "circle"
	if st == "Pantry" then
		shape = "jar"
	elseif st == "BarShelf" then
		shape = "bottle"
	elseif st == "Freezer" then
		shape = if id == "ice" then "cube" else "scoop"
	elseif st == "Fridge" then
		if FRUIT_SLICE[id] then
			shape = "slice"
		elseif id == "mint" or id == "ginger" then
			shape = "leaf"
		elseif id:find("milk") or id:find("cream") or id:find("yogurt") or id:find("yakurt") or id:find("water")
			or id:find("juice") or id:find("lemonade") or id:find("pudding") or id:find("egg") or id:find("cheese") then
			shape = "carton"
		elseif id:find("berr") or id:find("grape") or id == "cherry" or id == "blackcurrant" or id == "brewing_fruit" then
			shape = "berries"
		else
			shape = "fruit"
		end
	end
	return { Shape = shape, Color = col }
end

-- Puts a picture of `id` inside `parent`: YOUR DrinkImages tile if uploaded,
-- otherwise a painted placeholder in the same pastel style.
-- kind: "drink" | "item" | "cup" | "garnish"
function Bridge.icon(parent, kind, id, opts)
	opts = opts or {}
	local label = Instance.new("ImageLabel")
	label.Name = "Icon"
	label.BackgroundTransparency = 1
	label.ScaleType = Enum.ScaleType.Fit
	label.AnchorPoint = opts.AnchorPoint or Vector2.new(0.5, 0.5)
	label.Position = opts.Position or UDim2.fromScale(0.5, 0.5)
	label.Size = opts.Size or UDim2.fromScale(1, 1)
	label.ZIndex = (parent:IsA("GuiObject") and parent.ZIndex or 1) + 1
	local IMG = Bridge.Images
	local ok = false
	if IMG and IMG.Apply then
		local k = if kind == "item" and C.Cups[id] then "cup" else kind
		ok = pcall(IMG.Apply, label, k, id) and label.Image ~= ""
	end
	if ok then
		label.Parent = parent
		return label
	end
	label.Image = ""
	label.Parent = parent
	Paint.square(label)
	Paint.art(label, descFor(kind, id), { HoleColor = opts.Behind })
	return label
end

-- ---------------- recipe -> 2D steps ----------------
-- Storage steps in a row at the same storage = one shelf visit (as in your game).
-- Every appliance action is its own mini-game (chained at the same station).
function Bridge.stepsOf(recipe)
	local out = {}
	for _, s in recipe.steps or {} do
		local key = s[1]
		local st = Bridge.station(key)
		if key == "ServeCounter" or st.kind == "serve" then
			table.insert(out, { kind = "serve", station = key })
		elseif st.kind == "storage" then
			local last = out[#out]
			if last and last.kind == "storage" and last.station == key then
				table.insert(last.items, s[2])
			else
				table.insert(out, { kind = "storage", station = key, items = { s[2] } })
			end
		else
			table.insert(out, { kind = "action", station = key, action = s[2], label = s[3] })
		end
	end
	if #out == 0 or out[#out].kind ~= "serve" then
		table.insert(out, { kind = "serve", station = "ServeCounter" })
	end
	return out
end

return Bridge
