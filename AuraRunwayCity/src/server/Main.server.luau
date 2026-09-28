--!nonstrict
-- Aura Runway City — server bootstrap
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
require(ReplicatedStorage.Shared.Remotes) -- creates remotes first

local World = require(script.Parent.World)
local Services = script.Parent.Services
local Util = require(Services.Util)

-- 1) World (pre-baked in the place file, or built now)
local root = workspace:FindFirstChild(World.RootName)
if not root then
	local t = os.clock()
	root = World.Build(workspace, function()
		task.wait()
	end)
	print(("[Aura] World built in %.1fs (%d parts)"):format(os.clock() - t, root:GetAttribute("PartCount") or 0))
end
Util.World = root

-- 2) Services
local DataService = require(Services.DataService)
local AvatarService = require(Services.AvatarService)
local ShowService = require(Services.ShowService)
local AuctionService = require(Services.AuctionService)
local StallService = require(Services.StallService)
local MusicService = require(Services.MusicService)
local VehicleService = require(Services.VehicleService)
local RPService = require(Services.RPService)

DataService.Init()
AvatarService.Init({ DataService = DataService })
ShowService.Init({ DataService = DataService })
AuctionService.Init({ DataService = DataService, AvatarService = AvatarService, ShowService = ShowService })
StallService.Init({ DataService = DataService, AvatarService = AvatarService })
MusicService.Init({ DataService = DataService })
VehicleService.Init({ Build = require(script.Parent.World.Build), CarModel = require(script.Parent.World.CarModel) })
RPService.Init({ VehicleService = VehicleService })

-- 3) Day / night
if Config.DayNightCycle then
	Lighting.ClockTime = Config.StartClockTime
	task.spawn(function()
		local rate = 24 / (Config.MinutesPerDay * 60)
		while true do
			local dt = task.wait(0.5)
			Lighting.ClockTime = (Lighting.ClockTime + dt * rate) % 24
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid", 10)
		if hum then
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
			hum.NameDisplayDistance = 60
		end
	end)
end)

print("[Aura] Aura Runway City is live ✨")
