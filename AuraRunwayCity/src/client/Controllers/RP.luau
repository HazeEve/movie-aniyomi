--!nonstrict
-- Roleplay client: driving cars you sit in, jump-to-wake, and world prompts
-- that open UI (catalog mirrors, auction screen).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(script.Parent.Parent.UI)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Config = require(ReplicatedStorage.Shared.Config)

local RP = {}
local player = Players.LocalPlayer

local driveConn
local function stopDriving()
	if driveConn then
		driveConn:Disconnect()
		driveConn = nil
	end
end

local function drive(seat: VehicleSeat)
	stopDriving()
	local car = seat:FindFirstAncestorOfClass("Model")
	local root = car and car.PrimaryPart
	if not root then
		return
	end
	local lv = root:FindFirstChild("Drive")
	local ao = root:FindFirstChild("Upright")
	if not lv or not ao then
		return
	end
	local look = root.CFrame.LookVector
	local yaw = math.atan2(-look.X, -look.Z)
	local speed = 0
	local maxSpeed = car:GetAttribute("MaxSpeed") or Config.RP.CarMaxSpeed
	local wheels = {}
	for _, d in car:GetDescendants() do
		if d.Name == "Wheel" or d.Name == "Hub" then
			table.insert(wheels, d)
		end
	end
	driveConn = RunService.Heartbeat:Connect(function(dt)
		if seat.Occupant == nil or not root.Parent then
			stopDriving()
			return
		end
		local throttle = seat.ThrottleFloat
		local steer = seat.SteerFloat
		local target = throttle > 0 and maxSpeed * throttle or (throttle < 0 and -Config.RP.CarReverseSpeed or 0)
		local accel = (throttle ~= 0) and 28 or 40
		if math.abs(target - speed) < accel * dt then
			speed = target
		else
			speed += math.sign(target - speed) * accel * dt
		end
		local turn = Config.RP.CarTurnRate * math.clamp(math.abs(speed) / 18, 0, 1) * (speed >= 0 and 1 or -1)
		yaw -= steer * turn * dt
		local rot = CFrame.Angles(0, yaw, 0)
		ao.CFrame = rot
		local v = rot.LookVector * speed
		lv.PlaneVelocity = Vector2.new(v.X, v.Z)
	end)
end

function RP.Init(controllers)
	local function hookCharacter(char: Model)
		local hum = char:WaitForChild("Humanoid", 10)
		if not hum then
			return
		end
		hum.Seated:Connect(function(active, seatPart)
			if active and seatPart and seatPart:IsA("VehicleSeat") and seatPart.Name == "DriverSeat" then
				drive(seatPart)
				controllers.Notify.Show("🚗 WASD / thumbstick to drive • Jump to hop out", "info")
			else
				stopDriving()
			end
		end)
		hum.StateChanged:Connect(function(_, new)
			if new == Enum.HumanoidStateType.Jumping and player:GetAttribute("Sleeping") then
				Remotes.Event("RP"):FireServer("Wake")
			end
		end)
	end
	if player.Character then
		task.spawn(hookCharacter, player.Character)
	end
	player.CharacterAdded:Connect(hookCharacter)

	-- jump request while sleeping (humanoid is anchored so it can't enter Jumping)
	UserInputService.JumpRequest:Connect(function()
		if player:GetAttribute("Sleeping") then
			Remotes.Event("RP"):FireServer("Wake")
		end
	end)

	Remotes.Event("RP").OnClientEvent:Connect(function(kind)
		if kind == "OpenCatalog" then
			UI.open("Catalog")
		elseif kind == "OpenAuction" then
			UI.open("Auction")
		end
	end)
end

return RP
