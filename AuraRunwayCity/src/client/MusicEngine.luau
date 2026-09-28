--!nonstrict
-- Plays instrument notes as 3D sounds from a player's character.
-- Every chord is built by pitch-shifting single-note samples.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Chords = require(ReplicatedStorage.Shared.Chords)
local Instruments = require(ReplicatedStorage.Shared.Instruments)
local Config = require(ReplicatedStorage.Shared.Config)

local Engine = {}
local handles = {} :: { [string]: any }
local samplesCfg = ReplicatedStorage:WaitForChild("InstrumentSamples")
local warned = false
Engine.MissingSamples = Instance.new("BindableEvent")

local groupClean = Instance.new("SoundGroup")
groupClean.Name = "AuraInstruments"
groupClean.Volume = 0.9
groupClean.Parent = SoundService
local rev = Instance.new("ReverbSoundEffect")
rev.DecayTime = 1.4
rev.Density = 0.8
rev.Diffusion = 0.9
rev.WetLevel = -10
rev.DryLevel = 0
rev.Parent = groupClean

local groupDrive = Instance.new("SoundGroup")
groupDrive.Name = "AuraDrive"
groupDrive.Volume = 0.75
groupDrive.Parent = SoundService
local dist = Instance.new("DistortionSoundEffect")
dist.Level = 0.55
dist.Parent = groupDrive
local eq = Instance.new("EqualizerSoundEffect")
eq.HighGain = -6
eq.MidGain = 2
eq.LowGain = 1
eq.Parent = groupDrive
local rev2 = rev:Clone()
rev2.Parent = groupDrive

local function emitter(player: Player): Instance?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local a = root:FindFirstChild("MusicEmitter")
	if not a then
		a = Instance.new("Attachment")
		a.Name = "MusicEmitter"
		a.Position = Vector3.new(0, 1, 0)
		a.Parent = root
	end
	return a
end

-- returns soundId, playbackSpeed for (instrument, midi)
function Engine.Sample(kind: string, note: number): (string?, number)
	local info = Instruments.Info[kind]
	if info and info.Samples and #info.Samples > 0 then
		return Instruments.SampleFor(info.Samples, note)
	end
	local auto = samplesCfg:GetAttribute(kind)
	if auto then
		return auto, 2 ^ ((note - 60) / 12)
	end
	return nil, 1
end

function Engine.PadSample(padId: string): string?
	local info = Instruments.Info.Drums
	for _, p in info.Pads do
		if p.Id == padId then
			if p.Sample ~= "" then
				return p.Sample
			end
			return samplesCfg:GetAttribute("Drums_" .. padId)
		end
	end
	return nil
end

local function makeSound(parent: Instance, id: string, speed: number, volume: number, looped: boolean, onStage: boolean?, drive: boolean?)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.PlaybackSpeed = math.clamp(speed, 0.05, 8)
	s.Volume = volume
	s.Looped = looped
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 12
	s.RollOffMaxDistance = onStage and Config.Music.StageHearDistance or Config.Music.HearDistance
	s.SoundGroup = drive and groupDrive or groupClean
	s.Parent = parent
	return s
end

local function notifyMissing()
	if not warned then
		warned = true
		Engine.MissingSamples:Fire()
	end
end

-- style: { S = "down"|"up"|"block"|"arp", P = power, O = octave, M = mute, D = drive, V = volume mult }
function Engine.Start(owner: Player, handleKey: string, kind: string, chordOrNotes, style, onStage: boolean?)
	style = style or {}
	local info = Instruments.Info[kind]
	local parent = emitter(owner)
	if not info or not parent then
		return
	end
	local notes
	if typeof(chordOrNotes) == "string" then
		notes = Chords.Voicing(chordOrNotes, kind, { Power = style.P, Octave = style.O })
	else
		notes = chordOrNotes
	end
	if #notes == 0 then
		return
	end
	local order = table.clone(notes)
	if style.S == "up" then
		local rev = {}
		for i = #order, 1, -1 do
			table.insert(rev, order[i])
		end
		order = rev
	end
	local gap = info.StrumGap or 0
	if style.S == "block" then
		gap = 0
	elseif style.S == "arp" then
		gap = 0.09
	end
	local h = { Sounds = {}, Released = false, Kind = kind }
	if handles[handleKey] then
		Engine.Stop(handleKey, 0.08)
	end
	handles[handleKey] = h
	local vol = (info.Volume or 0.5) * (style.V or 1) / math.sqrt(#order)
	for i, n in order do
		local function fire()
			if h.Released and not style.M then
				return
			end
			local id, speed = Engine.Sample(kind, n)
			if not id then
				notifyMissing()
				return
			end
			local s = makeSound(parent, id, speed, vol * (0.85 + math.random() * 0.2), info.Looped == true, onStage, style.D)
			s:Play()
			table.insert(h.Sounds, s)
			if not info.Looped then
				s.Ended:Connect(function()
					s:Destroy()
				end)
				task.delay(6, function()
					if s.Parent then
						s:Destroy()
					end
				end)
			end
		end
		if gap > 0 and i > 1 then
			task.delay(gap * (i - 1), fire)
		else
			fire()
		end
	end
	if style.M then
		task.delay(0.14 + gap * #order, function()
			Engine.Stop(handleKey, 0.08)
		end)
	end
	return h
end

function Engine.Stop(handleKey: string, fade: number?)
	local h = handles[handleKey]
	if not h then
		return
	end
	handles[handleKey] = nil
	h.Released = true
	local info = Instruments.Info[h.Kind]
	fade = fade or (info and info.Release) or 0.4
	for _, s in h.Sounds do
		if s.Parent then
			local tw = TweenService:Create(s, TweenInfo.new(fade, Enum.EasingStyle.Quad), { Volume = 0 })
			tw:Play()
			tw.Completed:Connect(function()
				s:Destroy()
			end)
		end
	end
end

function Engine.SetVolume(handleKey: string, mult: number)
	local h = handles[handleKey]
	if not h then
		return
	end
	local info = Instruments.Info[h.Kind]
	local base = (info and info.Volume or 0.5) / math.sqrt(math.max(#h.Sounds, 1))
	for _, s in h.Sounds do
		s.Volume = base * mult
	end
end

function Engine.Pad(owner: Player, padId: string, onStage: boolean?)
	local parent = emitter(owner)
	local id = Engine.PadSample(padId)
	if not parent then
		return
	end
	if not id then
		notifyMissing()
		return
	end
	local s = makeSound(parent, id, 1, Instruments.Info.Drums.Volume or 0.8, false, onStage, false)
	s:Play()
	s.Ended:Connect(function()
		s:Destroy()
	end)
	task.delay(5, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

function Engine.StopAllFor(owner: Player)
	local prefix = tostring(owner.UserId) .. ":"
	for key in handles do
		if key:sub(1, #prefix) == prefix then
			Engine.Stop(key, 0.1)
		end
	end
end

Players.PlayerRemoving:Connect(Engine.StopAllFor)

return Engine
