--!nonstrict
-- Drivable cars (arcade physics: LinearVelocity + AlignOrientation on a
-- rounded root). The driver's client steers; the server hands it ownership.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Palette = require(ReplicatedStorage.Shared.Palette)
local Util = require(script.Parent.Util)

local VehicleService = {}
local B, CarModel
local carsFolder
local owned = {} :: { [Player]: Model }
local parked = {} :: { [BasePart]: Model }

local function setupPhysics(model: Model, root: BasePart, seat: VehicleSeat)
	model:AddTag("Car")
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			if d ~= root then
				d.Massless = true
				local w = Instance.new("WeldConstraint")
				w.Part0 = root
				w.Part1 = d
				w.Parent = d
			end
		end
	end
	root.CustomPhysicalProperties = PhysicalProperties.new(3, 0, 0, 100, 1)
	root.CanCollide = true
	local att = Instance.new("Attachment")
	att.Name = "Drive"
	att.Parent = root
	local lv = Instance.new("LinearVelocity")
	lv.Name = "Drive"
	lv.Attachment0 = att
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.PrimaryTangentAxis = Vector3.new(1, 0, 0)
	lv.SecondaryTangentAxis = Vector3.new(0, 0, 1)
	lv.PlaneVelocity = Vector2.zero
	lv.MaxForce = 60000
	lv.Parent = root
	local ao = Instance.new("AlignOrientation")
	ao.Name = "Upright"
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.MaxTorque = 1e7
	ao.Responsiveness = 35
	ao.CFrame = root.CFrame.Rotation
	ao.Parent = root
	for _, d in model:GetDescendants() do
		if d.Name == "Headlight" and d:IsA("BasePart") then
			local l = Instance.new("SpotLight")
			l.Face = Enum.NormalId.Right
			l.Range = 38
			l.Angle = 55
			l.Brightness = 1.4
			l.Color = Color3.fromHex("FFF1DE")
			l.Shadows = false
			l.Parent = d
		end
	end
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local hum = seat.Occupant
		if hum then
			local pl = Players:GetPlayerFromCharacter(hum.Parent)
			if pl then
				pcall(function()
					root:SetNetworkOwner(pl)
				end)
				model:SetAttribute("Driver", pl.UserId)
			end
		else
			model:SetAttribute("Driver", 0)
			pcall(function()
				root:SetNetworkOwner(nil)
			end)
			lv.PlaneVelocity = Vector2.zero
			model:SetAttribute("IdleSince", os.clock())
		end
	end)
	model:SetAttribute("MaxSpeed", Config.RP.CarMaxSpeed)
	model:SetAttribute("IdleSince", os.clock())
end

local function build(style: string, color: Color3, cf: CFrame): Model
	local model, root, seat = CarModel.build(B, Palette, carsFolder, cf, style, color)
	setupPhysics(model, root, seat)
	return model
end

local function spotFree(spot: BasePart): boolean
	for _, car in carsFolder:GetChildren() do
		if car.PrimaryPart and (car.PrimaryPart.Position - spot.Position).Magnitude < 8 then
			return false
		end
	end
	return true
end

function VehicleService.Despawn(player: Player)
	local car = owned[player]
	if car then
		car:Destroy()
		owned[player] = nil
	end
end

function VehicleService.Spawn(player: Player, style: string?, color)
	style = (style == "Cabrio" or style == "Coupe" or style == "SUV") and style or "Cabrio"
	if typeof(color) ~= "Color3" then
		color = Palette.CarColors[math.random(1, #Palette.CarColors)]
	end
	VehicleService.Despawn(player)
	local chosen
	for _, spot in CollectionService:GetTagged("CarSpot") do
		if spotFree(spot) then
			chosen = spot
			break
		end
	end
	if not chosen then
		Util.Notify(player, "All parking spots are full — try again soon!", "warn")
		return
	end
	local cf = CFrame.new(chosen.Position.X, 0.6, chosen.Position.Z) * chosen.CFrame.Rotation
	local car = build(style, color, cf)
	car.Name = player.Name .. "'s " .. style
	car:SetAttribute("Owner", player.UserId)
	owned[player] = car
	Util.Notify(player, "Your " .. style .. " is waiting in the Aura Motors lot 🚗 (hop in the driver seat)", "success")
end

local function spawnParked(spot: BasePart)
	local r = Random.new(spot.Name:len() * 13 + math.floor(spot.Position.X))
	local styles = CarModel.Styles
	local cf = CFrame.new(spot.Position.X, 0.55, spot.Position.Z) * spot.CFrame.Rotation
	local car = build(styles[r:NextInteger(1, #styles)], Palette.CarColors[r:NextInteger(1, #Palette.CarColors)], cf)
	car.Name = "ParkedCar"
	parked[spot] = car
end

function VehicleService.Init(deps)
	B = deps.Build
	CarModel = deps.CarModel
	carsFolder = Instance.new("Folder")
	carsFolder.Name = "Cars"
	carsFolder.Parent = workspace
	for _, spot in CollectionService:GetTagged("ParkedCarSpot") do
		spawnParked(spot)
	end
	Players.PlayerRemoving:Connect(VehicleService.Despawn)
	-- cleanup: fallen cars, abandoned parked cars go home
	task.spawn(function()
		while true do
			task.wait(20)
			for _, car in carsFolder:GetChildren() do
				local root = car.PrimaryPart
				if not root or root.Position.Y < -40 then
					car:Destroy()
				end
			end
			for spot, car in parked do
				local root = car.Parent and car.PrimaryPart
				local idle = (car:GetAttribute("Driver") or 0) == 0 and os.clock() - (car:GetAttribute("IdleSince") or 0) > 180
				if not root then
					spawnParked(spot)
				elseif idle and (root.Position - spot.Position).Magnitude > 12 then
					car:Destroy()
					spawnParked(spot)
				end
			end
		end
	end)
end

return VehicleService
