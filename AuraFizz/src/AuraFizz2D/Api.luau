--!nonstrict
-- AuraFizz2D · Api — call this from YOUR client scripts (e.g. when a 3D station's
-- ProximityPrompt is used). Client-only (it builds GUI for the local player).
--
--   local Fizz2D = require(game.ReplicatedStorage.AuraFizz2D.Api)
--   Fizz2D.OpenCafe()                                  -- full 2D café: customers, menu
--   local r = Fizz2D.MakeDrink("iced_latte")           -- whole recipe in 2D -> { Total, Stars, Tip, Scores }
--   local s = Fizz2D.PlayAction("pull_shot")           -- one mini-game popup -> 0..1
--   local s = Fizz2D.PickFromStorage("Pantry", { "coffee_beans", "sugar" }) -- shelf popup -> 0..1
--   local s = Fizz2D.PlayStep("americano", 5)          -- step #5 of that recipe (storage or action)
--
-- Server scripts can open the same things with the RemoteEvent the server script creates:
--   ReplicatedStorage.AuraFizz2DOpen:FireClient(player, "Action", "pull_shot")
local Bridge = require(script.Parent.Bridge)
local Cafe = require(script.Parent.Cafe)
local MiniGames = require(script.Parent.MiniGames)
local Storage = require(script.Parent.Storage)

local Api = {}

function Api.OpenCafe()
	Cafe.open()
end

function Api.Close()
	Cafe.close()
end

function Api.IsOpen()
	return Cafe.isOpen()
end

-- Makes one drink start to finish in the big 2D window. Yields until served (or closed).
function Api.MakeDrink(drinkId, look)
	local recipe = Bridge.recipe(drinkId)
	if not recipe then
		warn("[AuraFizz2D] unknown drink " .. tostring(drinkId))
		return nil
	end
	if not Cafe.isOpen() then
		Cafe.open()
	end
	return Cafe.makeDrink(recipe, look)
end

local function extrasFor(recipe)
	local extra: { [string]: any } = {}
	for _, st in recipe and recipe.steps or {} do
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
	return extra
end

-- One mini-game in a popup. opts = { drinkId = "...", label = "Pull the espresso shot" }
function Api.PlayAction(actionId, opts)
	opts = opts or {}
	local recipe = opts.drinkId and Bridge.recipe(opts.drinkId)
	local panel, close = Cafe.popup()
	local score = MiniGames.play(panel, actionId, {
		label = opts.label,
		recipe = recipe,
		color = opts.color or (recipe and Bridge.drinkColor(recipe)),
		extra = extrasFor(recipe),
	})
	close()
	return score
end

-- One shelf visit in a popup. itemIds = what the player must take.
function Api.PickFromStorage(stationKey, itemIds, opts)
	opts = opts or {}
	local panel, close = Cafe.popup()
	local score = Storage.play(panel, stationKey, itemIds or {}, opts)
	close()
	return score
end

-- Plays raw step #index of a recipe (DrinkRecipes steps), for station-by-station games.
function Api.PlayStep(drinkId, index)
	local recipe = Bridge.recipe(drinkId)
	local step = recipe and recipe.steps and recipe.steps[index]
	if not step then
		return nil
	end
	local st = Bridge.station(step[1])
	if st.kind == "storage" then
		return Api.PickFromStorage(step[1], { step[2] })
	elseif st.kind == "serve" then
		return 1
	end
	return Api.PlayAction(step[2], { drinkId = drinkId, label = step[3] })
end

-- The 2D steps of a recipe (storage visits grouped), if you want to drive them yourself.
function Api.StepsOf(drinkId)
	local recipe = Bridge.recipe(drinkId)
	return recipe and Bridge.stepsOf(recipe) or {}
end

Api.Bridge = Bridge
return Api
