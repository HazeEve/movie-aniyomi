--!nonstrict
-- Background music: relaxing café music around the city, upbeat music
-- near the stage and during the show. Soft crossfades, ducks while you
-- play an instrument, and a mute toggle in the HUD.
--
-- Source 1: Config.BGMId (our own original tracks in build/AuraMusic.ogg)
-- Source 2: songs the server finds in Roblox's free licensed music library
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.Config)
local Tracks = require(ReplicatedStorage.Shared.MusicTracks)

local BGM = {}
local player = Players.LocalPlayer
local muted = false

local STAGE = Vector3.new(0, 0, 40)
local STAGE_RADIUS = 150

function BGM.IsMuted(): boolean
	return muted
end

function BGM.Toggle()
	muted = not muted
end

local function ownId(): string?
	local id = Config.BGMId
	if typeof(id) == "number" then
		id = id ~= 0 and tostring(id) or ""
	end
	if typeof(id) ~= "string" or id == "" then
		return nil
	end
	if not id:find("rbxassetid://") then
		id = "rbxassetid://" .. id
	end
	return id
end

function BGM.Init(controllers)
	local group = Instance.new("SoundGroup")
	group.Name = "AuraBGM"
	group.Parent = SoundService
	local show = ReplicatedStorage:WaitForChild("ShowState")
	local found = ReplicatedStorage:FindFirstChild("BGMTracks")
	local volume = Config.BGMVolume or 0.32

	-- one channel per mood; each holds a playlist and one Sound
	local channels = {}
	local function channel(name)
		local s = Instance.new("Sound")
		s.Name = "BGM_" .. name
		s.Volume = 0
		s.SoundGroup = group
		s.Parent = SoundService
		local ch = { Name = name, Sound = s, List = {}, Index = 0, Vol = 0, Region = nil }
		channels[name] = ch
		return ch
	end
	local cafe, runway = channel("Cafe"), channel("Runway")

	local function loadNext(ch)
		if ch.Region then
			return -- our own looping track
		end
		if #ch.List == 0 then
			ch.Sound.SoundId = ""
			return
		end
		ch.Index = ch.Index % #ch.List + 1
		ch.Sound.SoundId = ch.List[ch.Index]
		ch.Sound.TimePosition = 0
	end

	local function setup()
		local id = ownId()
		for _, ch in { cafe, runway } do
			local s = ch.Sound
			if id then
				local tr = Tracks[ch.Name]
				ch.Region = NumberRange.new(tr.Start, tr.Start + tr.Length)
				s.SoundId = id
				s.PlaybackRegionsEnabled = true
				s.PlaybackRegion = ch.Region
				s.LoopRegion = ch.Region
				s.Looped = true
			else
				ch.Region = nil
				s.PlaybackRegionsEnabled = false
				s.Looped = false
				local raw = found and found:GetAttribute(ch.Name) or ""
				ch.List = string.split(raw, ",")
				if ch.List[1] == "" then
					ch.List = {}
				end
				-- shuffle so every server sounds a bit different
				for i = #ch.List, 2, -1 do
					local j = math.random(1, i)
					ch.List[i], ch.List[j] = ch.List[j], ch.List[i]
				end
				loadNext(ch)
			end
		end
	end
	local function watch(f)
		found = f
		f:GetAttributeChangedSignal("Resolved"):Connect(setup)
		setup()
	end
	setup()
	if found then
		watch(found)
	else
		ReplicatedStorage.ChildAdded:Connect(function(c)
			if c.Name == "BGMTracks" and not found then
				watch(c)
			end
		end)
	end
	for _, ch in { cafe, runway } do
		ch.Sound.Ended:Connect(function()
			if not ch.Region then
				loadNext(ch)
				if ch.Vol > 0.001 then
					ch.Sound:Play()
				end
			end
		end)
	end

	local function wanted(): string
		local phase = show:GetAttribute("Phase")
		if phase == "Runway" or phase == "Results" then
			return "Runway"
		end
		if player:GetAttribute("InShow") and phase == "Dressing" then
			return "Runway"
		end
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and (root.Position * Vector3.new(1, 0, 1) - STAGE).Magnitude < STAGE_RADIUS then
			return "Runway"
		end
		return "Cafe"
	end

	RunService.Heartbeat:Connect(function(dt)
		local want = wanted()
		local playing = controllers.Music and controllers.Music.IsPlaying and controllers.Music.IsPlaying()
		for name, ch in channels do
			local s = ch.Sound
			local target = 0
			if not muted and name == want and s.SoundId ~= "" then
				target = volume * (name == "Runway" and 0.9 or 1) * (playing and 0.25 or 1)
			end
			-- smooth ~1s crossfade
			ch.Vol += (target - ch.Vol) * math.clamp(dt * 1.2, 0, 1)
			if math.abs(target - ch.Vol) < 0.002 then
				ch.Vol = target
			end
			s.Volume = ch.Vol
			if ch.Vol > 0.001 and not s.IsPlaying and s.SoundId ~= "" then
				if s.IsPaused then
					s:Resume()
				else
					s:Play()
				end
			elseif ch.Vol <= 0.001 and s.IsPlaying and target == 0 then
				s:Pause() -- resumes where it left off
			end
		end
	end)
end

return BGM
