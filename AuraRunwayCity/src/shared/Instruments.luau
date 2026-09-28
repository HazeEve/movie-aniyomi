--!nonstrict
-- ============================================================
--  INSTRUMENT SOUNDS
--  Put single-note samples here (Creator Store > Audio, or upload your own).
--  "Note" = the MIDI note the sample was recorded at (60 = middle C / C4).
--  Chords are built by pitch-shifting these notes, so one clean note per
--  instrument is enough (more samples across the range = more realistic).
--
--  If a list is empty the game searches Roblox's public audio library at
--  startup for a matching sample (best effort). Setting your own IDs is
--  strongly recommended.
-- ============================================================
local Instruments = {}

Instruments.Order = { "Guitar", "Piano", "Electric", "Drums", "Violin" }

Instruments.Info = {
	Guitar = {
		Name = "Acoustic Guitar",
		Icon = "🎸",
		Samples = {
			-- { Id = "rbxassetid://123456789", Note = 52 },
		},
		Search = { "acoustic guitar single note", "guitar pluck note", "acoustic guitar note" },
		Volume = 0.55,
		Release = 0.6,
		Looped = false,
		StrumGap = 0.022,
		Style = "Strum",
	},
	Electric = {
		Name = "Electric Guitar",
		Icon = "⚡",
		Samples = {},
		Search = { "electric guitar single note", "electric guitar note clean", "guitar note" },
		Volume = 0.5,
		Release = 0.35,
		Looped = false,
		StrumGap = 0.014,
		Style = "Strum",
		Drive = true,
	},
	Piano = {
		Name = "Grand Piano",
		Icon = "🎹",
		Samples = {},
		Search = { "piano single note c4", "piano note c", "grand piano note" },
		Volume = 0.5,
		Release = 0.9,
		Looped = false,
		StrumGap = 0,
		Style = "Keys",
	},
	Violin = {
		Name = "Violin",
		Icon = "🎻",
		Samples = {},
		Search = { "violin sustained note", "violin long note", "violin note" },
		Volume = 0.45,
		Release = 0.55,
		Looped = true,
		StrumGap = 0.03,
		Style = "Bow",
	},
	Drums = {
		Name = "Drum Kit",
		Icon = "🥁",
		Style = "Pads",
		Volume = 0.8,
		Pads = {
			{ Id = "Crash", Name = "Crash", Sample = "", Search = "crash cymbal" },
			{ Id = "Ride", Name = "Ride", Sample = "", Search = "ride cymbal" },
			{ Id = "HiHat", Name = "Hi-Hat", Sample = "", Search = "closed hi hat" },
			{ Id = "Tom1", Name = "Tom 1", Sample = "", Search = "high tom drum" },
			{ Id = "Tom2", Name = "Tom 2", Sample = "", Search = "mid tom drum" },
			{ Id = "Floor", Name = "Floor Tom", Sample = "", Search = "floor tom drum" },
			{ Id = "Snare", Name = "Snare", Sample = "", Search = "snare drum hit" },
			{ Id = "Kick", Name = "Kick", Sample = "", Search = "kick drum" },
			{ Id = "OpenHat", Name = "Open Hat", Sample = "", Search = "open hi hat" },
		},
	},
}

-- Picks the best sample for a MIDI note: returns soundId, playbackSpeed
function Instruments.SampleFor(samples, note: number)
	if not samples or #samples == 0 then
		return nil, 1
	end
	local best, bestD = samples[1], math.huge
	for _, s in samples do
		local d = math.abs(note - (s.Note or 60))
		if d < bestD then
			best, bestD = s, d
		end
	end
	return best.Id, 2 ^ ((note - (best.Note or 60)) / 12)
end

return Instruments
