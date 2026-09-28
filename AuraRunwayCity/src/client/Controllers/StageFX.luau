--!nonstrict
-- Animates the stage: sweeping beams (that chase the current model during the
-- show), twinkling LED stars, glowing sun and titles.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local StageFX = {}

local function tagged(tag: string)
	local set = {}
	for _, i in CollectionService:GetTagged(tag) do
		set[i] = true
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(i)
		set[i] = true
	end)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(i)
		set[i] = nil
	end)
	return set
end

function StageFX.Init()
	local beams = tagged("StageBeam")
	local gradients = tagged("LEDGradient")
	local starSets = tagged("LEDStars")
	local suns = tagged("LEDSun")
	local titles = tagged("LEDTitle")
	local state = ReplicatedStorage:WaitForChild("ShowState")
	local t = 0
	local twinkleT = 0
	local pink, lav, cyan = Color3.fromHex("FF8BCB"), Color3.fromHex("A88CFF"), Color3.fromHex("86DBFF")
	RunService.Heartbeat:Connect(function(dt)
		t += dt
		local cam = workspace.CurrentCamera
		if not cam or (cam.CFrame.Position - Vector3.new(0, 10, -30)).Magnitude > 450 then
			return
		end
		local phase = state:GetAttribute("Phase")
		local modelId = state:GetAttribute("ModelId") or 0
		local modelPos
		if phase == "Runway" and modelId ~= 0 then
			local mp = Players:GetPlayerByUserId(modelId)
			local root = mp and mp.Character and mp.Character:FindFirstChild("HumanoidRootPart")
			modelPos = root and root.Position
		end
		local speed = phase == "Runway" and 1.6 or 0.6
		for beam in beams do
			local a1 = beam.Attachment1
			local targets = a1 and a1.Parent
			if a1 and targets and targets:IsA("BasePart") then
				local home = beam:GetAttribute("Home") or Vector3.new(0, 5, 0)
				local i = beam:GetAttribute("Index") or 1
				local goal
				if modelPos and i % 2 == 0 then
					goal = modelPos + Vector3.new(math.sin(t * 3 + i) * 1.5, -2.5, math.cos(t * 3 + i) * 1.5)
				else
					goal = home + Vector3.new(math.sin(t * speed + i * 1.7) * 14, 0, math.cos(t * speed * 0.8 + i) * 22)
				end
				local rel = goal - targets.Position
				a1.Position = a1.Position:Lerp(rel, math.min(dt * 4, 1))
				if phase == "Runway" then
					local k = (math.sin(t * 2 + i) + 1) / 2
					beam.Color = ColorSequence.new(i % 3 == 0 and cyan:Lerp(pink, k) or lav:Lerp(pink, k))
				end
			end
		end
		for g in gradients do
			g.Offset = Vector2.new(0, math.sin(t * 0.25) * 0.08)
		end
		for s in suns do
			local k = 1 + math.sin(t * 1.4) * 0.03
			s.GroupTransparency = 0.05 + (math.sin(t * 0.9) + 1) * 0.04
			s.Rotation = 0
			local sc = s:FindFirstChild("Pulse")
			if not sc then
				sc = Instance.new("UIScale")
				sc.Name = "Pulse"
				sc.Parent = s
			end
			sc.Scale = k
		end
		twinkleT += dt
		if twinkleT > 0.12 then
			twinkleT = 0
			for set in starSets do
				local kids = set:GetChildren()
				if #kids > 0 then
					for _ = 1, 3 do
						local s = kids[math.random(1, #kids)]
						if s:IsA("Frame") then
							s.BackgroundTransparency = math.random() * 0.8
						end
					end
				end
			end
			for title in titles do
				local st = title:FindFirstChildOfClass("UIStroke")
				if st then
					st.Color = pink:Lerp(lav, (math.sin(t) + 1) / 2)
				end
			end
		end
	end)
end

return StageFX
