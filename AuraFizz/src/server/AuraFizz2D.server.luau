--!nonstrict
-- AuraFizz2D server (ServerScriptService). Optional but recommended:
--   * picks the customer's drink (only drinks the player can make, via Hooks.CanMake)
--   * times each order and pays the tip (via Hooks.Reward -> your own coins)
--   * creates ReplicatedStorage.AuraFizz2DOpen so server scripts can open 2D steps:
--       ReplicatedStorage.AuraFizz2DOpen:FireClient(player, "Action", "pull_shot")
--       ReplicatedStorage.AuraFizz2DOpen:FireClient(player, "Storage", "Pantry", { "coffee_beans" })
--       ReplicatedStorage.AuraFizz2DOpen:FireClient(player, "Drink", "iced_latte")
--     The score comes back through Hooks.OnStepResult.
-- Mini-game skill happens on the client, so the server clamps scores and rejects
-- orders finished faster than a human could play them.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Pkg = ReplicatedStorage:WaitForChild("AuraFizz2D")
local Config = require(Pkg:WaitForChild("Config"))
local Bridge = require(Pkg:WaitForChild("Bridge"))

-- ================= HOOKS: connect to your game =================
local Hooks = {}
-- Can this player be asked for this drink? (e.g. check the drinks they unlocked in your shop)
function Hooks.CanMake(player, recipe)
	return true
end
-- Pay the tip with your own economy. Default: adds to leaderstats.Coins if your game has it.
function Hooks.Reward(player, recipe, tip, result)
	local ls = player:FindFirstChild("leaderstats")
	local coins = ls and ls:FindFirstChild("Coins")
	if coins and (coins:IsA("IntValue") or coins:IsA("NumberValue")) then
		coins.Value += tip
	end
end
-- A single 2D step opened from the server finished (score 0..1).
function Hooks.OnStepResult(player, what, id, score) end
-- ===============================================================

local remote = Instance.new("RemoteFunction")
remote.Name = "AuraFizz2DRemote"
remote.Parent = ReplicatedStorage
local open = Instance.new("RemoteEvent")
open.Name = "AuraFizz2DOpen"
open.Parent = ReplicatedStorage

local orders = {} -- [player] = { id, recipe, started, work }
local last = {}
local rng = Random.new()

local Actions = {}

function Actions.NextOrder(player, mode, drinkId)
	local recipe
	if mode == "practice" and typeof(drinkId) == "string" then
		recipe = Bridge.recipe(drinkId)
		if recipe and not Hooks.CanMake(player, recipe) then
			recipe = nil
		end
	else
		local pool = {}
		for _, r in Bridge.allRecipes() do
			if Hooks.CanMake(player, r) then
				table.insert(pool, r)
			end
		end
		recipe = pool[rng:NextInteger(1, math.max(#pool, 1))]
	end
	if not recipe then
		return nil
	end
	local work = 0
	for _, s in Bridge.stepsOf(recipe) do
		if s.kind ~= "serve" then
			work += 1
		end
	end
	local id = HttpService:GenerateGUID(false)
	orders[player] = { id = id, recipe = recipe, started = os.clock(), work = work }
	return { OrderId = id, DrinkId = recipe.id }
end

function Actions.Finish(player, orderId, scores)
	local o = orders[player]
	if not (o and o.id == orderId) or typeof(scores) ~= "table" then
		return nil
	end
	orders[player] = nil
	local secs = os.clock() - o.started
	local sum, n = 0, 0
	for i = 1, o.work do
		local v = scores[i]
		if typeof(v) == "number" and v == v then
			sum += math.clamp(v, 0, 1)
		end
		n += 1
	end
	local total = if n > 0 then sum / n * 100 else 0
	if secs < o.work * 0.8 then -- faster than humanly possible
		total *= 0.25
	end
	total = math.floor(total + 0.5)
	local stars = math.floor(total / 20 * 2 + 0.5) / 2
	local tip = math.floor((Config.TierTip[o.recipe.tier] or 10) * total / 100 + 0.5)
	if stars >= 5 then
		tip += math.floor((Config.TierTip[o.recipe.tier] or 10) * 0.5)
	end
	local result = { Total = total, Stars = stars, Tip = tip, DrinkId = o.recipe.id }
	pcall(Hooks.Reward, player, o.recipe, tip, result)
	return result
end

function Actions.StepResult(player, what, id, score)
	if typeof(score) == "number" and score == score then
		pcall(Hooks.OnStepResult, player, what, id, math.clamp(score, 0, 1))
	end
	return true
end

remote.OnServerInvoke = function(player, action, ...)
	local fn = Actions[action]
	if not fn then
		return nil
	end
	local now = os.clock()
	if last[player] and now - last[player] < 0.25 then
		return nil
	end
	last[player] = now
	return fn(player, ...)
end

Players.PlayerRemoving:Connect(function(p)
	orders[p] = nil
	last[p] = nil
end)
