--!nonstrict
-- Creates (server) or waits for (client) every RemoteEvent / RemoteFunction.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EVENTS = { "Notify", "Data", "AvatarChanged", "Show", "Music", "Auction", "Stall", "RP", "Look" }
local FUNCTIONS = { "Avatar", "GetLook", "AuctionCall", "StallCall", "MusicCall", "DataCall" }

local Remotes = {}
local folder

if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	folder.Name = "Remotes"
	for _, n in EVENTS do
		if not folder:FindFirstChild(n) then
			local r = Instance.new("RemoteEvent")
			r.Name = n
			r.Parent = folder
		end
	end
	for _, n in FUNCTIONS do
		if not folder:FindFirstChild(n) then
			local r = Instance.new("RemoteFunction")
			r.Name = n
			r.Parent = folder
		end
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("Remotes")
end

function Remotes.Event(name: string): RemoteEvent
	return folder:WaitForChild(name) :: RemoteEvent
end

function Remotes.Func(name: string): RemoteFunction
	return folder:WaitForChild(name) :: RemoteFunction
end

return Remotes
