--!nonstrict
-- Client-side cache of the player's profile + worn items.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local State = {}
State.Data = { Coins = 0, Hearts = 0, Favorites = {}, Outfits = {}, Presets = {}, Shop = {} }
State.Worn = {}
State.Snap = nil
State.DataChanged = Instance.new("BindableEvent")
State.WornChanged = Instance.new("BindableEvent")

function State.Init()
	Remotes.Event("Data").OnClientEvent:Connect(function(data)
		State.Data = data
		State.DataChanged:Fire(data)
	end)
	task.spawn(function()
		Remotes.Func("DataCall"):InvokeServer("Get")
	end)
end

function State.SetAvatarReply(res)
	if typeof(res) ~= "table" then
		return
	end
	if res.worn then
		State.Worn = res.worn
	end
	if res.snap then
		State.Snap = res.snap
	end
	State.WornChanged:Fire(State.Worn)
end

function State.IsWorn(id: number): boolean
	for _, w in State.Worn do
		if w.Id == id then
			return true
		end
	end
	return false
end

function State.IsFavorite(id: number): boolean
	return table.find(State.Data.Favorites or {}, id) ~= nil
end

return State
