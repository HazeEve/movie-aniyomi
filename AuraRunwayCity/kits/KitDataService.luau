--!nonstrict
-- Music Kit: tiny save system for chord presets (DataStore).
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = {}
local profiles = {}
local store
pcall(function()
	store = DataStoreService:GetDataStore("AuraMusicKit_v1")
end)

function DataService.Get(player)
	return profiles[player]
end

function DataService.Sync(player)
	local p = profiles[player]
	if p then
		Remotes.Event("Data"):FireClient(player, { Coins = 0, Hearts = 0, Favorites = {}, Outfits = {}, Presets = p.Presets, Shop = {} })
	end
end

local function load(player)
	local data
	if store then
		pcall(function()
			data = store:GetAsync("u" .. player.UserId)
		end)
	end
	profiles[player] = { Presets = (typeof(data) == "table" and data.Presets) or {} }
	DataService.Sync(player)
end

local function save(player)
	local p = profiles[player]
	if p and store then
		pcall(function()
			store:SetAsync("u" .. player.UserId, { Presets = p.Presets })
		end)
	end
end

function DataService.Init()
	Remotes.Func("DataCall").OnServerInvoke = function(player, action)
		if action == "Get" then
			DataService.Sync(player)
		end
		return true
	end
	Players.PlayerAdded:Connect(load)
	for _, p in Players:GetPlayers() do
		task.spawn(load, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		save(p)
		profiles[p] = nil
	end)
	game:BindToClose(function()
		for _, p in Players:GetPlayers() do
			save(p)
		end
	end)
end

return DataService
