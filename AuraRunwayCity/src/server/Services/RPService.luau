--!nonstrict
-- Roleplay: hunger/energy, eat & drink, pick up items, sleep in beds,
-- travel menu, and routing of world prompts (catalog mirrors, auction screen).
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Util = require(script.Parent.Util)
local ToolFactory = require(script.Parent.ToolFactory)

local RPService = {}
local sleeping = {} :: { [Player]: any }
local bedUser = {} :: { [BasePart]: Player }
local lastTravel = {}

local function clampStat(player: Player, name: string, delta: number)
	local v = (player:GetAttribute(name) or 100) + delta
	player:SetAttribute(name, math.clamp(v, 0, 100))
end

-- ============ Tools ============
local function countTools(player: Player): number
	local n = 0
	local bp = player:FindFirstChildOfClass("Backpack")
	for _, c in (bp and bp:GetChildren() or {}) do
		if c:IsA("Tool") then
			n += 1
		end
	end
	if player.Character then
		for _, c in player.Character:GetChildren() do
			if c:IsA("Tool") then
				n += 1
			end
		end
	end
	return n
end

local function hasItem(player: Player, item: string): boolean
	local bp = player:FindFirstChildOfClass("Backpack")
	for _, holder in { bp, player.Character } do
		if holder then
			for _, c in holder:GetChildren() do
				if c:IsA("Tool") and c:GetAttribute("Item") == item then
					return true
				end
			end
		end
	end
	return false
end

local function puff(part: BasePart, text: string)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(120, 40)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.GothamBold
	t.TextColor3 = Color3.fromHex("FBF7F2")
	t.TextStrokeTransparency = 0.5
	t.Parent = bb
	bb.Parent = part
	task.delay(1.2, function()
		bb:Destroy()
	end)
end

local function sparkle(part: BasePart, color: Color3)
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 0
	pe.Speed = NumberRange.new(2, 5)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Lifetime = NumberRange.new(0.6, 1)
	pe.Size = NumberSequence.new(0.35, 0)
	pe.Color = ColorSequence.new(color)
	pe.LightEmission = 0.6
	pe.Parent = part
	pe:Emit(24)
	task.delay(1.5, function()
		pe:Destroy()
	end)
end

local function setupTool(tool: Tool, item: string)
	local bites = 3
	local busy = false
	tool.Activated:Connect(function()
		if busy then
			return
		end
		busy = true
		local char = tool.Parent
		local player = char and Players:GetPlayerFromCharacter(char)
		local head = char and char:FindFirstChild("Head")
		if ToolFactory.Food[item] and player then
			local grip = tool.Grip
			tool.Grip = grip * CFrame.new(0, -0.6, 0.9) * CFrame.Angles(math.rad(-60), 0, 0)
			task.wait(0.45)
			tool.Grip = grip
			bites -= 1
			clampStat(player, "Hunger", ToolFactory.Drinks[item] and 12 or 18)
			if head then
				puff(head, ToolFactory.Drinks[item] and "sip~ 🥤" or "yum! 😋")
			end
			if bites <= 0 then
				tool:Destroy()
			end
		elseif player and head then
			if item == "Perfume" then
				sparkle(head, Color3.fromHex("FFC6E0"))
				puff(head, "✨ spritz ✨")
			elseif item == "Phone" then
				puff(head, "📸 selfie!")
				sparkle(head, Color3.new(1, 1, 1))
			elseif item == "Bouquet" or item == "Tulips" or item == "Sunflower" or item == "Lilies" then
				sparkle(head, Color3.fromHex("FFB3C8"))
				puff(head, "💐")
			elseif item == "Balloon" or item == "HeartBalloon" then
				puff(head, "🎈")
			else
				puff(head, "💖")
			end
			task.wait(0.4)
		end
		busy = false
	end)
end

local function give(player: Player, item: string)
	if countTools(player) >= 8 then
		Util.Notify(player, "Your hands are full! Drop something first (Backspace).", "warn")
		return
	end
	if hasItem(player, item) then
		Util.Notify(player, "You already have one!", "info")
		return
	end
	local tool = ToolFactory.Make(item)
	if not tool then
		return
	end
	setupTool(tool, item)
	local bp = player:FindFirstChildOfClass("Backpack")
	tool.Parent = bp
	-- auto-equip
	local hum = Util.Humanoid(player)
	if hum then
		hum:EquipTool(tool)
	end
end

-- ============ Sleep ============
local function wake(player: Player)
	local s = sleeping[player]
	if not s then
		return
	end
	sleeping[player] = nil
	bedUser[s.Bed] = nil
	player:SetAttribute("Sleeping", nil)
	if s.Zzz then
		s.Zzz:Destroy()
	end
	local char = player.Character
	local root = Util.Root(player)
	local hum = Util.Humanoid(player)
	if root then
		root.Anchored = false
	end
	if hum then
		hum.PlatformStand = false
	end
	if char and s.Bed.Parent then
		char:PivotTo(s.Bed.CFrame * CFrame.new(-5.5, 3, 0))
	end
end
RPService.Wake = wake

local function sleep(player: Player, bed: BasePart)
	if sleeping[player] then
		wake(player)
		return
	end
	if bedUser[bed] and bedUser[bed].Parent then
		Util.Notify(player, "Someone is sleeping here 💤", "info")
		return
	end
	local model = bed.Parent
	local spot = model and model:FindFirstChild("SleepSpot")
	local char = player.Character
	local root = Util.Root(player)
	local hum = Util.Humanoid(player)
	if not (spot and char and root and hum) then
		return
	end
	if hum.SeatPart then
		hum.Sit = false
		task.wait()
	end
	hum.PlatformStand = true
	char:PivotTo(spot.CFrame)
	root.Anchored = true
	local head = char:FindFirstChild("Head")
	local zzz
	if head then
		zzz = Instance.new("BillboardGui")
		zzz.Size = UDim2.fromOffset(80, 50)
		zzz.StudsOffset = Vector3.new(0, 2, 0)
		zzz.LightInfluence = 0
		zzz.Name = "Zzz"
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Text = "Z z z"
		t.TextScaled = true
		t.Font = Enum.Font.FredokaOne
		t.TextColor3 = Color3.fromHex("DCD0F3")
		t.TextStrokeTransparency = 0.6
		t.Parent = zzz
		zzz.Parent = head
	end
	sleeping[player] = { Bed = bed, Zzz = zzz }
	bedUser[bed] = player
	player:SetAttribute("Sleeping", true)
end

function RPService.Init(deps)
	local VehicleService = deps.VehicleService
	Util.BeforeTeleport = function(player)
		wake(player)
	end

	local function hookPrompt(tag: string, fn)
		local function connect(inst)
			local prompt = inst:IsA("ProximityPrompt") and inst or inst:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				prompt.Triggered:Connect(function(player)
					fn(player, inst)
				end)
			end
		end
		for _, inst in CollectionService:GetTagged(tag) do
			connect(inst)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(connect)
	end

	hookPrompt("Giver", function(player, pad)
		local item = pad:GetAttribute("Item")
		if item then
			give(player, item)
		end
	end)
	hookPrompt("Bed", function(player, bed)
		sleep(player, bed)
	end)
	hookPrompt("OpenCatalog", function(player)
		Remotes.Event("RP"):FireClient(player, "OpenCatalog")
	end)
	hookPrompt("AuctionPrompt", function(player)
		Remotes.Event("RP"):FireClient(player, "OpenAuction")
	end)
	hookPrompt("CarSpawner", function(player, kiosk)
		VehicleService.Spawn(player, kiosk:GetAttribute("Style"), kiosk:GetAttribute("Color"))
	end)

	-- publish travel destinations (clients may not have far points streamed in)
	local travelList = Instance.new("Folder")
	travelList.Name = "TravelList"
	for _, point in CollectionService:GetTagged("TravelPoint") do
		local v = Instance.new("IntValue")
		v.Name = point.Name
		v.Value = point:GetAttribute("Order") or 99
		v.Parent = travelList
	end
	travelList.Parent = ReplicatedStorage

	Remotes.Event("RP").OnServerEvent:Connect(function(player, action, a)
		if action == "Wake" then
			wake(player)
		elseif action == "Travel" then
			if typeof(a) ~= "string" then
				return
			end
			local now = os.clock()
			if lastTravel[player] and now - lastTravel[player] < 3 then
				return
			end
			for _, point in CollectionService:GetTagged("TravelPoint") do
				if point.Name == a then
					lastTravel[player] = now
					Util.Teleport(player, point.CFrame)
					return
				end
			end
		elseif action == "Despawn" then
			VehicleService.Despawn(player)
		end
	end)

	local function setup(player: Player)
		player:SetAttribute("Hunger", 100)
		player:SetAttribute("Energy", 100)
		player.CharacterAdded:Connect(function()
			if sleeping[player] then
				local s = sleeping[player]
				sleeping[player] = nil
				bedUser[s.Bed] = nil
				player:SetAttribute("Sleeping", nil)
			end
		end)
	end
	Players.PlayerAdded:Connect(setup)
	for _, p in Players:GetPlayers() do
		setup(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		local s = sleeping[p]
		if s then
			bedUser[s.Bed] = nil
			sleeping[p] = nil
		end
		lastTravel[p] = nil
	end)

	-- stat loop
	task.spawn(function()
		local tHunger, tEnergy = 0, 0
		while true do
			task.wait(1)
			tHunger += 1
			tEnergy += 1
			for _, p in Players:GetPlayers() do
				if sleeping[p] then
					clampStat(p, "Energy", Config.RP.SleepEnergyPerSecond)
				end
			end
			if tHunger >= Config.RP.HungerDrainEvery then
				tHunger = 0
				for _, p in Players:GetPlayers() do
					clampStat(p, "Hunger", -1)
					if p:GetAttribute("Hunger") == 20 then
						Util.Notify(p, "You're getting hungry — grab a treat at Blush Café 🍩", "info")
					end
				end
			end
			if tEnergy >= Config.RP.EnergyDrainEvery then
				tEnergy = 0
				for _, p in Players:GetPlayers() do
					if not sleeping[p] then
						clampStat(p, "Energy", -1)
						if p:GetAttribute("Energy") == 20 then
							Util.Notify(p, "Feeling sleepy… take a nap at the Grand Hotel or your home 💤", "info")
						end
					end
				end
			end
		end
	end)
end

return RPService
