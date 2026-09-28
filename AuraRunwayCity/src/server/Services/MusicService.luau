--!nonstrict
-- Instruments: equip a 3D instrument, relay chord/pad events to everyone,
-- save chord presets, and find fallback samples if none are configured.
local Players = game:GetService("Players")
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Chords = require(ReplicatedStorage.Shared.Chords)
local Instruments = require(ReplicatedStorage.Shared.Instruments)
local Palette = require(ReplicatedStorage.Shared.Palette)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Util = require(script.Parent.Util)

local MusicService = {}
local DataService

local samplesFolder = Instance.new("Configuration")
samplesFolder.Name = "InstrumentSamples"
samplesFolder.Parent = ReplicatedStorage

local rate = {}
local props = {} :: { [Player]: Instance }

-- ---------- visual instruments ----------
local function weldAll(model: Model, root: BasePart)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.Massless = true
			d.CastShadow = false
			if d ~= root then
				local w = Instance.new("WeldConstraint")
				w.Part0 = root
				w.Part1 = d
				w.Parent = d
			end
		end
	end
end

local function p(parent, size, cf, color, material, shape)
	local part = Instance.new("Part")
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	if shape then
		part.Shape = shape
	end
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

-- Guitar-shaped body built at origin; neck along +X
local function guitarModel(kind: string): (Model, BasePart)
	local m = Instance.new("Model")
	m.Name = kind
	local wood = kind == "Electric" and Palette.Rose or Color3.fromHex("D9A46C")
	local root = p(m, Vector3.new(0.35, 2.3, 2.3), CFrame.new(0, 0, 0) * CFrame.Angles(0, math.pi / 2, 0), wood, Enum.Material.SmoothPlastic, CYL)
	root.Name = "Body"
	p(m, Vector3.new(0.35, 1.8, 1.8), CFrame.new(1.25, 0, 0) * CFrame.Angles(0, math.pi / 2, 0), wood, nil, CYL)
	if kind == "Electric" then
		p(m, Vector3.new(0.9, 0.08, 0.4), CFrame.new(0.2, 0, -0.2), Palette.Ivory)
		p(m, Vector3.new(0.9, 0.08, 0.4), CFrame.new(-0.4, 0, -0.2), Palette.Ivory)
		p(m, Vector3.new(0.3, 0.12, 0.3), CFrame.new(-0.9, 0, 0.5), Palette.Gold, Enum.Material.Metal)
	else
		p(m, Vector3.new(0.05, 0.75, 0.75), CFrame.new(0.9, -0.18, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromHex("2A1D16"), nil, CYL)
	end
	p(m, Vector3.new(3.6, 0.2, 0.35), CFrame.new(3.2, 0, 0), Palette.WoodDark, Enum.Material.Wood)
	p(m, Vector3.new(0.8, 0.22, 0.55), CFrame.new(5.3, 0, 0), Palette.WoodDark, Enum.Material.Wood)
	for i = -2, 2 do
		p(m, Vector3.new(4.8, 0.02, 0.02), CFrame.new(2.9, -0.12, i * 0.06), Palette.Champagne, Enum.Material.Metal)
	end
	return m, root
end

local function violinModel(): (Model, BasePart)
	local m = Instance.new("Model")
	m.Name = "Violin"
	local wood = Color3.fromHex("A45A2A")
	local root = p(m, Vector3.new(0.3, 1.1, 1.1), CFrame.Angles(0, math.pi / 2, 0), wood, nil, CYL)
	root.Name = "Body"
	p(m, Vector3.new(0.3, 0.95, 0.95), CFrame.new(0.95, 0, 0) * CFrame.Angles(0, math.pi / 2, 0), wood, nil, CYL)
	p(m, Vector3.new(1.4, 0.14, 0.2), CFrame.new(2, 0, 0), Color3.fromHex("1E1410"))
	p(m, Vector3.new(0.35, 0.3, 0.3), CFrame.new(2.85, 0, 0), Color3.fromHex("1E1410"), nil, BALL)
	-- bow
	local bow = p(m, Vector3.new(3.4, 0.06, 0.06), CFrame.new(0.4, 0.3, 0.6) * CFrame.Angles(0, math.rad(-60), 0), Palette.WoodDark, Enum.Material.Wood)
	bow.Name = "Bow"
	return m, root
end

local function pianoModel(): (Model, BasePart)
	local m = Instance.new("Model")
	m.Name = "Piano"
	local root = p(m, Vector3.new(8, 0.8, 2.6), CFrame.new(0, 3, 0), Palette.Plum)
	root.Name = "Body"
	for _, sx in { -3.6, 3.6 } do
		p(m, Vector3.new(0.4, 3, 2.2), CFrame.new(sx, 1.4, 0), Palette.Plum)
	end
	p(m, Vector3.new(8, 2.4, 0.3), CFrame.new(0, 4.6, 1.2), Palette.Plum)
	for i = 0, 20 do
		p(m, Vector3.new(0.34, 0.2, 1.3), CFrame.new(-3.5 + i * 0.35, 3.45, -0.55), Palette.Ivory)
	end
	local blackPattern = { 1, 1, 0, 1, 1, 1, 0 }
	for i = 0, 19 do
		if blackPattern[(i % 7) + 1] == 1 then
			p(m, Vector3.new(0.2, 0.25, 0.75), CFrame.new(-3.325 + i * 0.35, 3.62, -0.3), Color3.fromHex("1E1428"))
		end
	end
	p(m, Vector3.new(1.2, 0.12, 0.5), CFrame.new(0, 3.5, 0.9), Palette.Gold, Enum.Material.Metal)
	return m, root
end

local function drumModel(): (Model, BasePart)
	local m = Instance.new("Model")
	m.Name = "Drums"
	local shell = Palette.Rose
	local root = p(m, Vector3.new(2.4, 3.2, 3.2), CFrame.new(0, 1.8, 0) * CFrame.Angles(0, math.pi / 2, 0), shell, nil, CYL)
	root.Name = "Body"
	p(m, Vector3.new(0.1, 2.8, 2.8), CFrame.new(0, 1.8, -1.22) * CFrame.Angles(0, math.pi / 2, 0), Palette.Ivory, nil, CYL)
	local function drum(pos, d, h)
		p(m, Vector3.new(h, d, d), CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2), shell, nil, CYL)
		p(m, Vector3.new(0.06, d - 0.1, d - 0.1), CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Palette.Ivory, nil, CYL)
	end
	drum(Vector3.new(-1.8, 2.8, 0.6), 1.6, 0.7) -- snare
	drum(Vector3.new(-0.8, 3.8, -0.3), 1.2, 0.9)
	drum(Vector3.new(0.8, 3.8, -0.3), 1.3, 0.9)
	drum(Vector3.new(2.2, 2.2, 0.8), 1.9, 1.6)
	local function cymbal(pos, d)
		p(m, Vector3.new(0.08, 0.1, 0.1), CFrame.new(pos - Vector3.new(0, pos.Y / 2, 0)), Palette.Mist, Enum.Material.Metal)
		p(m, Vector3.new(pos.Y, 0.12, 0.12), CFrame.new(pos.X, pos.Y / 2, pos.Z) * CFrame.Angles(0, 0, math.pi / 2), Palette.Mist, Enum.Material.Metal, CYL)
		p(m, Vector3.new(0.06, d, d), CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2), Palette.Gold, Enum.Material.Metal, CYL)
	end
	cymbal(Vector3.new(-2.6, 4.6, -0.6), 2)
	cymbal(Vector3.new(2.8, 4.8, -0.6), 2.3)
	cymbal(Vector3.new(-2.6, 3.4, 1.2), 1.4)
	local seat = Instance.new("Seat")
	seat.Size = Vector3.new(1.4, 0.4, 1.4)
	seat.CFrame = CFrame.new(0, 1.7, 3.1) * CFrame.Angles(0, math.pi, 0)
	seat.Color = Palette.Plum
	seat.Parent = m
	return m, root
end

local function unequip(player: Player)
	local old = props[player]
	if old then
		old:Destroy()
		props[player] = nil
	end
	player:SetAttribute("Instrument", nil)
end

local function equip(player: Player, kind: string)
	unequip(player)
	if not Instruments.Info[kind] then
		return
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	player:SetAttribute("Instrument", kind)
	if kind == "Guitar" or kind == "Electric" or kind == "Violin" then
		local m, body
		local offset
		if kind == "Violin" then
			m, body = violinModel()
			local neck = Vector3.new(-0.45, 0.15, -0.88).Unit
			local z = neck:Cross(Vector3.new(0.2, 1, 0)).Unit
			local y = z:Cross(neck)
			offset = CFrame.new(-0.75, 1.05, -0.55) * CFrame.fromMatrix(Vector3.zero, neck, y)
		else
			m, body = guitarModel(kind)
			-- neck to the player's left, strings facing forward, tilted up
			offset = CFrame.new(0.3, -0.5, -0.95)
				* CFrame.Angles(0, 0, math.rad(-28))
				* CFrame.fromMatrix(Vector3.zero, Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1))
		end
		local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or root
		local target = torso.CFrame * offset
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				d.CFrame = target * d.CFrame
			end
		end
		weldAll(m, body)
		local w = Instance.new("WeldConstraint")
		w.Part0 = torso
		w.Part1 = body
		w.Parent = body
		m.Parent = char
		props[player] = m
	else
		local m
		if kind == "Piano" then
			m = pianoModel()
		else
			m = drumModel()
		end
		local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
		look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
		local ground = root.Position - Vector3.new(0, 3, 0) + look * (kind == "Piano" and 3.2 or 3.6)
		-- piano keys face the player (+Z away); drum throne is at +Z (towards the player)
		local place = kind == "Piano" and CFrame.lookAt(ground, ground - look) or CFrame.lookAt(ground, ground + look)
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				d.CFrame = place * d.CFrame
				d.Anchored = true
				d.CastShadow = false
			end
		end
		m.Parent = workspace
		props[player] = m
	end
end

local resolveBGM

-- ---------- sample fallback via public audio search ----------
local function searchSample(query: string): string?
	local ok, pages = pcall(function()
		local params = Instance.new("AudioSearchParams")
		params.SearchKeyword = query
		params.MaxDuration = 8
		params.AudioSubType = Enum.AudioSubType.SoundEffect
		return AssetService:SearchAudioAsync(params)
	end)
	if not ok or not pages then
		return nil
	end
	local ok2, page = pcall(function()
		return pages:GetCurrentPage()
	end)
	if not ok2 or not page then
		return nil
	end
	for _, item in page do
		local id = item.Id or item.AssetId
		if id then
			return "rbxassetid://" .. tostring(id)
		end
	end
	return nil
end

local function resolveSamples()
	-- always resolve backups too: if the uploaded pack fails to load
	-- (still in moderation, private, wrong id) clients fall back to these
	for kind, info in Instruments.Info do
		if info.Samples and #info.Samples == 0 and info.Search then
			for _, q in info.Search do
				local id = searchSample(q)
				if id then
					samplesFolder:SetAttribute(kind, id)
					break
				end
			end
		end
		if info.Pads then
			for _, pad in info.Pads do
				if pad.Sample == "" and pad.Search then
					local id = searchSample(pad.Search)
					if id then
						samplesFolder:SetAttribute("Drums_" .. pad.Id, id)
					end
				end
			end
		end
	end
	samplesFolder:SetAttribute("Resolved", true)
end

-- ---------- background music from Roblox's free licensed library ----------
-- Only used when Config.BGMId is empty. Tracks from the Roblox audio library
-- (licensed music) are free to use in any experience.
local bgmFolder = Instance.new("Configuration")
bgmFolder.Name = "BGMTracks"
bgmFolder.Parent = ReplicatedStorage

local function searchMusic(query: string, found: { string }, seen: { [string]: boolean })
	local ok, pages = pcall(function()
		local params = Instance.new("AudioSearchParams")
		params.SearchKeyword = query
		params.MinDuration = 60
		params.MaxDuration = 400
		params.AudioSubType = Enum.AudioSubType.Music
		return AssetService:SearchAudioAsync(params)
	end)
	if not ok or not pages then
		return
	end
	local ok2, page = pcall(function()
		return pages:GetCurrentPage()
	end)
	if not ok2 or not page then
		return
	end
	for _, item in page do
		local id = item.Id or item.AssetId
		if id and not seen[tostring(id)] and #found < 8 then
			seen[tostring(id)] = true
			table.insert(found, "rbxassetid://" .. tostring(id))
		end
	end
end

function resolveBGM()
	if typeof(Config.BGMId) == "string" and Config.BGMId ~= "" then
		return -- the uploaded original tracks are used instead
	end
	local lists = {
		Cafe = { "lofi cafe", "relaxing jazz", "chill lofi", "coffee shop" },
		Runway = { "fashion", "upbeat pop", "runway", "dance pop" },
	}
	for name, queries in lists do
		local found, seen = {}, {}
		for _, q in queries do
			if #found >= 8 then
				break
			end
			searchMusic(q, found, seen)
		end
		if #found > 0 then
			bgmFolder:SetAttribute(name, table.concat(found, ","))
		end
	end
	bgmFolder:SetAttribute("Resolved", true)
end

function MusicService.Init(deps)
	DataService = deps.DataService
	task.spawn(resolveSamples)
	task.spawn(resolveBGM)

	Remotes.Event("Music").OnServerEvent:Connect(function(player, action, a, b, c, d)
		local now = os.clock()
		local r = rate[player]
		if not r or now - r.t > 1 then
			rate[player] = { t = now, n = 0 }
			r = rate[player]
		end
		r.n += 1
		if r.n > Config.Music.MaxEventsPerSecond then
			return
		end
		if action == "Equip" then
			if typeof(a) == "string" then
				equip(player, a)
			end
			return
		elseif action == "Unequip" then
			unequip(player)
			return
		end
		local kind = player:GetAttribute("Instrument")
		if not kind then
			return
		end
		local onStage = Util.OnStage(player)
		if action == "On" then
			-- a = handle id, b = chord key or note list, c = style table
			if typeof(a) ~= "number" then
				return
			end
			if typeof(b) == "string" and not Chords.Get(b) then
				return
			end
			if typeof(b) == "table" then
				if #b > 8 then
					return
				end
				for _, n in b do
					if typeof(n) ~= "number" or n < 20 or n > 110 then
						return
					end
				end
			end
			for _, other in Players:GetPlayers() do
				if other ~= player then
					Remotes.Event("Music"):FireClient(other, "On", player, kind, a, b, typeof(c) == "table" and c or nil, onStage)
				end
			end
		elseif action == "Off" then
			if typeof(a) ~= "number" then
				return
			end
			for _, other in Players:GetPlayers() do
				if other ~= player then
					Remotes.Event("Music"):FireClient(other, "Off", player, a)
				end
			end
		elseif action == "Pad" then
			if typeof(a) ~= "string" then
				return
			end
			for _, other in Players:GetPlayers() do
				if other ~= player then
					Remotes.Event("Music"):FireClient(other, "Pad", player, a, onStage)
				end
			end
		end
	end)

	Remotes.Func("MusicCall").OnServerInvoke = function(player, action, kind, list)
		if action == "SavePreset" then
			if not Instruments.Info[kind] or not Chords.IsValidList(list, Config.Music.MinChords, Config.Music.MaxChords) then
				return false
			end
			local profile = DataService.Get(player)
			if profile then
				profile.Presets[kind] = list
				DataService.Sync(player)
			end
			return true
		end
		return false
	end

	Players.PlayerRemoving:Connect(function(pl)
		unequip(pl)
		rate[pl] = nil
	end)
	local function hook(pl: Player)
		pl.CharacterRemoving:Connect(function()
			unequip(pl)
		end)
	end
	Players.PlayerAdded:Connect(hook)
	for _, pl in Players:GetPlayers() do
		hook(pl)
	end
end

return MusicService
