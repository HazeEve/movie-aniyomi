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

local SoundPack = require(ReplicatedStorage.Shared.SoundPack)

local function packId(): string?
	local id = Config.SoundPackId
	if typeof(id) == "string" and id ~= "" then
		if not id:find("rbxassetid://") and tonumber(id) then
			id = "rbxassetid://" .. id
		end
		return id
	end
	return nil
end

-- Returns a playback spec for (instrument, midi):
-- { Id, Speed, Region = NumberRange?, Loop = NumberRange? } or nil
function Engine.Sample(kind: string, note: number)
	local info = Instruments.Info[kind]
	if info and info.Samples and #info.Samples > 0 then
		local id, speed = Instruments.SampleFor(info.Samples, note)
		return { Id = id, Speed = speed }
	end
	local pack = packId()
	local slices = SoundPack[kind]
	if pack and slices and #slices > 0 then
		local best, bestD = slices[1], math.huge
		for _, sl in slices do
			local d = math.abs(note - sl.Note)
			if d < bestD then
				best, bestD = sl, d
			end
		end
		return {
			Id = pack,
			Speed = 2 ^ ((note - best.Note) / 12),
			Region = NumberRange.new(best.Start, best.Start + best.Length),
			Loop = best.LoopStart and NumberRange.new(best.LoopStart, best.LoopEnd) or nil,
		}
	end
	local auto = samplesCfg:GetAttribute(kind)
	if auto then
		return { Id = auto, Speed = 2 ^ ((note - 60) / 12) }
	end
	return nil
end

function Engine.PadSample(padId: string)
	local info = Instruments.Info.Drums
	for _, p in info.Pads do
		if p.Id == padId and p.Sample ~= "" then
			return { Id = p.Sample, Speed = 1 }
		end
	end
	local pack = packId()
	local sl = SoundPack.Drums and SoundPack.Drums[padId]
	if pack and sl then
		return { Id = pack, Speed = 1, Region = NumberRange.new(sl.Start, sl.Start + sl.Length) }
	end
	local auto = samplesCfg:GetAttribute("Drums_" .. padId)
	return auto and { Id = auto, Speed = 1 } or nil
end

local function makeSound(parent: Instance, spec, volume: number, looped: boolean, onStage: boolean?, drive: boolean?)
	local s = Instance.new("Sound")
	s.SoundId = spec.Id
	s.PlaybackSpeed = math.clamp(spec.Speed or 1, 0.05, 8)
	s.Volume = volume
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 12
	s.RollOffMaxDistance = onStage and Config.Music.StageHearDistance or Config.Music.HearDistance
	s.SoundGroup = drive and groupDrive or groupClean
	if spec.Region then
		s.PlaybackRegionsEnabled = true
		s.PlaybackRegion = spec.Region
		if looped and spec.Loop then
			s.LoopRegion = spec.Loop
			s.Looped = true
		else
			s.Looped = false
		end
	else
		s.Looped = looped
	end
	s.Parent = parent
	return s
end

-- warm the pack up so the first note plays instantly
task.spawn(function()
	local id = packId()
	if id then
		local s = Instance.new("Sound")
		s.SoundId = id
		pcall(function()
			game:GetService("ContentProvider"):PreloadAsync({ s })
		end)
	end
end)

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
		notes = Chords.Voicing(chordOrNotes, kind, { Power = style.P, Octave = style.O, Inversion = style.I })
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
			local spec = Engine.Sample(kind, n)
			if not spec then
				notifyMissing()
				return
			end
			local s = makeSound(parent, spec, vol * (0.85 + math.random() * 0.2), info.Looped == true, onStage, style.D)
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

function Engine.Notes(kind: string, chordOrNotes, style): { number }
	style = style or {}
	if typeof(chordOrNotes) == "string" then
		return Chords.Voicing(chordOrNotes, kind, { Power = style.P, Octave = style.O, Inversion = style.I })
	end
	return chordOrNotes
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
	local spec = Engine.PadSample(padId)
	if not parent then
		return
	end
	if not spec then
		notifyMissing()
		return
	end
	local s = makeSound(parent, spec, Instruments.Info.Drums.Volume or 0.8, false, onStage, false)
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
