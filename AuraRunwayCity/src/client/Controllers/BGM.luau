--!nonstrict
-- Background music: relaxing "Blush Café" around the city, upbeat
-- "Runway Glow" near the stage and during the show. Soft crossfades,
-- ducks while you play an instrument, and a mute toggle in the HUD.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.Config)
local Tracks = require(ReplicatedStorage.Shared.MusicTracks)

local BGM = {}
local player = Players.LocalPlayer
local muted = false
local changed = Instance.new("BindableEvent")
BGM.Changed = changed.Event

local STAGE = Vector3.new(0, 0, 40)
local STAGE_RADIUS = 150

function BGM.IsMuted(): boolean
	return muted
end

function BGM.Toggle()
	muted = not muted
	changed:Fire(muted)
end

function BGM.Init(controllers)
	local id = Config.BGMId
	if typeof(id) == "number" then
		id = id ~= 0 and ("rbxassetid://" .. id) or ""
	end
	if typeof(id) ~= "string" or id == "" then
		return -- no music uploaded yet
	end
	if not id:find("rbxassetid://") then
		id = "rbxassetid://" .. id
	end
	local group = Instance.new("SoundGroup")
	group.Name = "AuraBGM"
	group.Volume = 1
	group.Parent = SoundService

	local function make(name, tr)
		local s = Instance.new("Sound")
		s.Name = "BGM_" .. name
		s.SoundId = id
		s.PlaybackRegionsEnabled = true
		s.PlaybackRegion = NumberRange.new(tr.Start, tr.Start + tr.Length)
		s.LoopRegion = NumberRange.new(tr.Start, tr.Start + tr.Length)
		s.Looped = true
		s.Volume = 0
		s.SoundGroup = group
		s.Parent = SoundService
		return s
	end
	local sounds = {
		Cafe = make("Cafe", Tracks.Cafe),
		Runway = make("Runway", Tracks.Runway),
	}
	local base = { Cafe = Config.BGMVolume or 0.32, Runway = (Config.BGMVolume or 0.32) * 0.9 }
	local show = ReplicatedStorage:WaitForChild("ShowState")

	local function wanted(): string
		local phase = show:GetAttribute("Phase")
		if phase == "Runway" or phase == "Results" then
			return "Runway"
		end
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and (root.Position * Vector3.new(1, 0, 1) - STAGE).Magnitude < STAGE_RADIUS then
			return "Runway"
		end
		if player:GetAttribute("InShow") and phase == "Dressing" then
			return "Runway"
		end
		return "Cafe"
	end

	local vol = { Cafe = 0, Runway = 0 }
	RunService.Heartbeat:Connect(function(dt)
		local want = wanted()
		local playing = controllers.Music and controllers.Music.IsPlaying and controllers.Music.IsPlaying()
		for name, s in sounds do
			local target = 0
			if not muted and name == want then
				target = base[name] * (playing and 0.25 or 1)
			end
			-- smooth ~2.5s crossfade
			local k = math.clamp(dt / 2.5, 0, 1)
			vol[name] += (target - vol[name]) * k * 3
			if math.abs(target - vol[name]) < 0.002 then
				vol[name] = target
			end
			s.Volume = vol[name]
			if vol[name] > 0.001 and not s.IsPlaying then
				if s.IsPaused then
					s:Resume()
				else
					s:Play()
				end
			elseif vol[name] <= 0.001 and s.IsPlaying and target == 0 then
				s:Pause() -- resumes where it left off
			end
		end
	end)
end

return BGM
