--!nonstrict
-- AuraFizz2D · Stations — shows YOUR real 3D station models inside the 2D screens
-- (a ViewportFrame "camera shot" of the model), so the art is your own black & gold stations.
-- It finds each station model by name (e.g. a Model called "ToppingStation" or "Topping Station"
-- anywhere in Workspace, or in Config.StationModelsFolder). Set exact models in Config.StationModels
-- if the names differ. A station that isn't found falls back to the drawn scene.
local Players = game:GetService("Players")

local Config = require(script.Parent.Config)

local Stations = {}
local P = UDim2.fromScale

local SKIP = { "Script", "LocalScript", "ModuleScript", "Sound", "ProximityPrompt", "ClickDetector", "BillboardGui",
	"ParticleEmitter", "Beam", "Trail", "Fire", "Smoke", "Sparkles", "Attachment", "Weld", "WeldConstraint", "Motor6D",
	"Humanoid", "AnimationController" }

local function norm(s)
	return string.lower((string.gsub(s, "[^%w]", "")))
end

local function root()
	local ch = Players.LocalPlayer and Players.LocalPlayer.Character
	return ch and ch:FindFirstChild("HumanoidRootPart")
end

local function resolve(path)
	local node = game
	for part in string.gmatch(path, "[^%.]+") do
		if node == game then
			local ok, svc = pcall(game.GetService, game, part)
			node = (ok and svc) or game:FindFirstChild(part)
		else
			node = node:FindFirstChild(part)
		end
		if not node then
			return nil
		end
	end
	return node
end

-- The Model for a station key, or nil.
function Stations.find(stationKey, stationName)
	local fixed = Config.StationModels and Config.StationModels[stationKey]
	if typeof(fixed) == "Instance" then
		return fixed
	elseif type(fixed) == "string" then
		return resolve(fixed)
	end
	local want = { [norm(stationKey)] = true }
	if stationName then
		want[norm(stationName)] = true
	end
	local places = {}
	if Config.StationModelsFolder then
		local f = resolve(Config.StationModelsFolder)
		if f then
			table.insert(places, f)
		end
	end
	table.insert(places, workspace)
	local hrp = root()
	for _, place in places do
		local best, bestD = nil, math.huge
		for _, m in place:GetDescendants() do
			if m:IsA("Model") and want[norm(m.Name)] then
				local d = if hrp then (m:GetPivot().Position - hrp.Position).Magnitude else 0
				if d < bestD then
					best, bestD = m, d
				end
			end
		end
		if best then
			return best
		end
	end
	return nil
end

local function copyOf(model)
	local was = model.Archivable
	model.Archivable = true
	local ok, c = pcall(model.Clone, model)
	model.Archivable = was
	if not ok or not c then
		return nil
	end
	for _, d in c:GetDescendants() do
		for _, cls in SKIP do
			if d:IsA(cls) then
				d:Destroy()
				break
			end
		end
	end
	for _, d in c:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	return c
end

-- Puts a camera shot of the station into `area` (behind everything else in it).
-- Returns the ViewportFrame, or nil when the station model isn't found.
function Stations.view(area, stationKey, stationName)
	if Config.UseStationModels == false then
		return nil
	end
	local model = Stations.find(stationKey, stationName)
	if not model then
		return nil
	end
	local copy = copyOf(model)
	if not copy then
		return nil
	end
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Station3D"
	vp.BackgroundTransparency = 1
	vp.Size = P(1, 1)
	vp.ZIndex = area.ZIndex
	vp.Ambient = Color3.fromRGB(170, 165, 175)
	vp.LightColor = Color3.fromRGB(255, 244, 225)
	vp.LightDirection = Vector3.new(-0.4, -1, -0.6)
	local cam = Instance.new("Camera")
	cam.FieldOfView = 35
	cam.Parent = vp
	vp.CurrentCamera = cam
	copy.Parent = vp

	-- frame it from the side the player stands on (they're at the station in 3D), a little from above
	local cf, size = copy:GetBoundingBox()
	local view = Config.StationView and Config.StationView[stationKey] or {}
	local centre = cf.Position
	local hrp = root()
	local dir
	local orig = model:GetPivot().Position
	if hrp and (hrp.Position - orig).Magnitude < 60 then
		dir = hrp.Position - orig
	else
		dir = model:GetPivot().LookVector
	end
	dir = Vector3.new(dir.X, 0, dir.Z)
	dir = if dir.Magnitude > 0.01 then dir.Unit else Vector3.new(0, 0, -1)
	if view.yaw then
		dir = CFrame.Angles(0, math.rad(view.yaw), 0):VectorToWorldSpace(dir)
	end
	local pitch = math.rad(view.pitch or 14)
	local radius = size.Magnitude / 2
	local dist = radius / math.tan(math.rad(cam.FieldOfView / 2)) * (view.zoom or 1)
	local eye = centre + (dir * math.cos(pitch) + Vector3.new(0, math.sin(pitch), 0)) * dist
	cam.CFrame = CFrame.lookAt(eye, centre)
	vp.Parent = area
	return vp
end

return Stations
