--!nonstrict
-- Player saves (coins, hearts, wins, favourites, outfits, chord presets, shop setup).
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = {}
DataService.Profiles = {} :: { [Player]: any }
DataService.Loaded = Instance.new("BindableEvent")

local store
do
	local ok, s = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = s
	else
		warn("[Data] DataStores unavailable (enable Studio API access to save):", s)
	end
end

local function default()
	return {
		Coins = Config.StartCoins,
		Hearts = 0,
		Wins = 0,
		Shows = 0,
		Favorites = {},
		Outfits = {},
		Presets = {},
		Shop = { Name = "", Items = {} },
		Version = 1,
	}
end

local function reconcile(data)
	local d = default()
	if typeof(data) ~= "table" then
		return d
	end
	for k, v in d do
		if data[k] == nil then
			data[k] = v
		end
	end
	return data
end

local function leaderstats(player: Player, profile)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = profile.Coins
	coins.Parent = ls
	local hearts = Instance.new("IntValue")
	hearts.Name = "Hearts"
	hearts.Value = profile.Hearts
	hearts.Parent = ls
	ls.Parent = player
end

function DataService.Get(player: Player)
	return DataService.Profiles[player]
end

function DataService.WaitFor(player: Player, timeout: number?)
	local t = 0
	while not DataService.Profiles[player] and player.Parent and t < (timeout or 30) do
		t += task.wait(0.2)
	end
	return DataService.Profiles[player]
end

-- Sends the client-visible part of the profile
function DataService.Sync(player: Player)
	local p = DataService.Profiles[player]
	if not p then
		return
	end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.Coins.Value = p.Coins
		ls.Hearts.Value = p.Hearts
	end
	player:SetAttribute("Coins", p.Coins)
	player:SetAttribute("Hearts", p.Hearts)
	Remotes.Event("Data"):FireClient(player, {
		Coins = p.Coins,
		Hearts = p.Hearts,
		Wins = p.Wins,
		Shows = p.Shows,
		Favorites = p.Favorites,
		Outfits = p.Outfits,
		Presets = p.Presets,
		Shop = p.Shop,
	})
end

function DataService.AddCoins(player: Player, amount: number)
	local p = DataService.Profiles[player]
	if not p then
		return false
	end
	p.Coins = math.max(0, math.floor(p.Coins + amount))
	DataService.Sync(player)
	return true
end

function DataService.Spend(player: Player, amount: number): boolean
	local p = DataService.Profiles[player]
	if not p or amount < 0 or p.Coins < amount then
		return false
	end
	p.Coins -= math.floor(amount)
	DataService.Sync(player)
	return true
end

function DataService.AddHearts(player: Player, amount: number)
	local p = DataService.Profiles[player]
	if p then
		p.Hearts += math.floor(amount)
		DataService.Sync(player)
	end
end

local function key(userId: number)
	return "u_" .. userId
end

local function save(player: Player, final: boolean?)
	local p = DataService.Profiles[player]
	if not p or not store or p._noSave then
		return
	end
	local copy = table.clone(p)
	copy._noSave = nil
	local ok, err = pcall(function()
		store:UpdateAsync(key(player.UserId), function()
			return copy
		end)
	end)
	if not ok then
		warn("[Data] save failed for", player.Name, err)
	end
	if final then
		DataService.Profiles[player] = nil
	end
end
DataService.Save = save

local function load(player: Player)
	local data
	local failed = false
	if store then
		for attempt = 1, 3 do
			local ok, res = pcall(function()
				return store:GetAsync(key(player.UserId))
			end)
			if ok then
				data = res
				failed = false
				break
			end
			failed = true
			warn("[Data] load attempt", attempt, "failed:", res)
			task.wait(1.5 * attempt)
		end
	end
	local profile = reconcile(data)
	if failed then
		profile._noSave = true -- never overwrite a save we could not read
	end
	if not player.Parent then
		return
	end
	DataService.Profiles[player] = profile
	leaderstats(player, profile)
	DataService.Sync(player)
	DataService.Loaded:Fire(player, profile)
end

function DataService.Init()
	Players.PlayerAdded:Connect(load)
	for _, pl in Players:GetPlayers() do
		task.spawn(load, pl)
	end
	Players.PlayerRemoving:Connect(function(player)
		save(player, true)
	end)
	game:BindToClose(function()
		if RunService:IsStudio() and not store then
			return
		end
		local threads = {}
		for _, pl in Players:GetPlayers() do
			table.insert(threads, task.spawn(save, pl, true))
		end
		task.wait(3)
	end)
	-- autosave + playtime reward
	task.spawn(function()
		local t = 0
		while true do
			task.wait(Config.PlaytimeRewardEvery)
			t += Config.PlaytimeRewardEvery
			for _, pl in Players:GetPlayers() do
				if DataService.Profiles[pl] then
					DataService.AddCoins(pl, Config.PlaytimeRewardCoins)
				end
			end
			if t >= 120 then
				t = 0
				for _, pl in Players:GetPlayers() do
					task.spawn(save, pl, false)
				end
			end
		end
	end)

	-- client requests (favorites, outfits list, presets)
	Remotes.Func("DataCall").OnServerInvoke = function(player, action, a, b)
		local p = DataService.Profiles[player]
		if not p then
			return false
		end
		if action == "ToggleFavorite" and typeof(a) == "number" then
			local id = math.floor(a)
			local idx = table.find(p.Favorites, id)
			if idx then
				table.remove(p.Favorites, idx)
			elseif #p.Favorites < 300 then
				table.insert(p.Favorites, 1, id)
			end
			DataService.Sync(player)
			return true, idx == nil
		elseif action == "Get" then
			DataService.Sync(player)
			return true
		end
		return false
	end
end

return DataService
