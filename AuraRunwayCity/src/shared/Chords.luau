--!nonstrict
-- Every chord the music system knows: 12 roots x 25 chord types = 300 chords.
-- Keys look like "G:maj", "A:min", "F#:maj7".
local Chords = {}

Chords.Roots = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" }
Chords.RootLabels = { "C", "C#/Db", "D", "D#/Eb", "E", "F", "F#/Gb", "G", "G#/Ab", "A", "A#/Bb", "B" }

Chords.Qualities = {
	{ Id = "maj", Suffix = "", Name = "Major", I = { 0, 4, 7 } },
	{ Id = "min", Suffix = "m", Name = "Minor", I = { 0, 3, 7 } },
	{ Id = "7", Suffix = "7", Name = "Dominant 7th", I = { 0, 4, 7, 10 } },
	{ Id = "maj7", Suffix = "maj7", Name = "Major 7th", I = { 0, 4, 7, 11 } },
	{ Id = "m7", Suffix = "m7", Name = "Minor 7th", I = { 0, 3, 7, 10 } },
	{ Id = "mmaj7", Suffix = "m(maj7)", Name = "Minor Major 7th", I = { 0, 3, 7, 11 } },
	{ Id = "6", Suffix = "6", Name = "Major 6th", I = { 0, 4, 7, 9 } },
	{ Id = "m6", Suffix = "m6", Name = "Minor 6th", I = { 0, 3, 7, 9 } },
	{ Id = "9", Suffix = "9", Name = "Dominant 9th", I = { 0, 4, 7, 10, 14 } },
	{ Id = "maj9", Suffix = "maj9", Name = "Major 9th", I = { 0, 4, 7, 11, 14 } },
	{ Id = "m9", Suffix = "m9", Name = "Minor 9th", I = { 0, 3, 7, 10, 14 } },
	{ Id = "add9", Suffix = "add9", Name = "Add 9", I = { 0, 4, 7, 14 } },
	{ Id = "madd9", Suffix = "m(add9)", Name = "Minor Add 9", I = { 0, 3, 7, 14 } },
	{ Id = "11", Suffix = "11", Name = "Dominant 11th", I = { 0, 4, 7, 10, 14, 17 } },
	{ Id = "13", Suffix = "13", Name = "Dominant 13th", I = { 0, 4, 7, 10, 14, 21 } },
	{ Id = "sus2", Suffix = "sus2", Name = "Suspended 2nd", I = { 0, 2, 7 } },
	{ Id = "sus4", Suffix = "sus4", Name = "Suspended 4th", I = { 0, 5, 7 } },
	{ Id = "7sus4", Suffix = "7sus4", Name = "7th Suspended 4th", I = { 0, 5, 7, 10 } },
	{ Id = "dim", Suffix = "dim", Name = "Diminished", I = { 0, 3, 6 } },
	{ Id = "dim7", Suffix = "dim7", Name = "Diminished 7th", I = { 0, 3, 6, 9 } },
	{ Id = "m7b5", Suffix = "m7b5", Name = "Half-Diminished", I = { 0, 3, 6, 10 } },
	{ Id = "aug", Suffix = "aug", Name = "Augmented", I = { 0, 4, 8 } },
	{ Id = "aug7", Suffix = "7#5", Name = "Augmented 7th", I = { 0, 4, 8, 10 } },
	{ Id = "7b9", Suffix = "7b9", Name = "7th Flat 9", I = { 0, 4, 7, 10, 13 } },
	{ Id = "5", Suffix = "5", Name = "Power Chord", I = { 0, 7, 12 } },
}

Chords.QualityById = {}
for _, q in Chords.Qualities do
	Chords.QualityById[q.Id] = q
end

Chords.RootIndex = {}
for i, r in Chords.Roots do
	Chords.RootIndex[r] = i - 1
end

Chords.All = {} -- ordered list of chord info tables
Chords.ByKey = {}
for ri, root in Chords.Roots do
	for _, q in Chords.Qualities do
		local key = root .. ":" .. q.Id
		local info = {
			Key = key,
			Root = root,
			RootIndex = ri - 1,
			Quality = q.Id,
			Short = root .. q.Suffix,
			Long = Chords.RootLabels[ri] .. " " .. q.Name,
			Intervals = q.I,
		}
		table.insert(Chords.All, info)
		Chords.ByKey[key] = info
	end
end

Chords.Defaults = {
	Guitar = { "G:maj", "D:maj", "E:min", "C:maj", "A:min", "E:maj" },
	Electric = { "E:5", "G:5", "A:5", "C:5", "D:5", "B:5" },
	Piano = { "C:maj", "G:maj", "A:min", "F:maj", "D:min", "E:min", "C:maj7" },
	Violin = { "G:maj", "D:maj", "A:min", "E:min", "C:maj" },
}

function Chords.Get(key: string)
	return Chords.ByKey[key]
end

function Chords.IsValidList(list, minCount: number, maxCount: number): boolean
	if typeof(list) ~= "table" or #list < minCount or #list > maxCount then
		return false
	end
	local seen = {}
	for _, k in list do
		if typeof(k) ~= "string" or not Chords.ByKey[k] or seen[k] then
			return false
		end
		seen[k] = true
	end
	return true
end

local function uniqueSorted(t)
	table.sort(t)
	local out = {}
	for _, n in t do
		if out[#out] ~= n then
			table.insert(out, n)
		end
	end
	return out
end

-- Returns MIDI note numbers for a chord on an instrument.
-- opts: { Power = bool, Octave = int }
function Chords.Voicing(key: string, instrument: string, opts): { number }
	opts = opts or {}
	local info = Chords.ByKey[key]
	if not info then
		return {}
	end
	local root = info.RootIndex
	local ints = info.Intervals
	local octave = (opts.Octave or 0) * 12

	if instrument == "Guitar" or instrument == "Electric" then
		local r = 40 + ((root - 4) % 12) -- lowest root between E2 and D#3
		if opts.Power or info.Quality == "5" then
			return { r + octave, r + 7 + octave, r + 12 + octave }
		end
		local candidates = {}
		for _, oct in { 0, 12, 24 } do
			for _, i in ints do
				table.insert(candidates, r + oct + (i % 12))
			end
		end
		candidates = uniqueSorted(candidates)
		local notes = { r }
		for _, n in candidates do
			if n > r and n <= r + 24 and #notes < 6 then
				local last = notes[#notes]
				-- keep the low strings open-sounding: no close intervals under r+12
				if n >= r + 12 or n - last >= 5 then
					table.insert(notes, n)
				end
			end
		end
		for i, n in notes do
			notes[i] = n + octave
		end
		return notes
	elseif instrument == "Piano" then
		local bass = 48 + root
		local notes = { bass - 12, bass }
		for _, i in ints do
			local n = 60 + ((root + i) % 12)
			if i > 12 then
				n += 12
			end
			table.insert(notes, n)
		end
		notes = uniqueSorted(notes)
		while #notes > 7 do
			table.remove(notes, 3)
		end
		for i, n in notes do
			notes[i] = n + octave
		end
		return notes
	elseif instrument == "Violin" then
		local r = 55 + ((root - 7) % 12)
		local notes = { r }
		for idx = 2, math.min(#ints, 3) do
			table.insert(notes, r + (ints[idx] % 12))
		end
		table.insert(notes, r + 12)
		notes = uniqueSorted(notes)
		for i, n in notes do
			notes[i] = n + octave
		end
		return notes
	end
	return {}
end

Chords.NoteNames = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" }
function Chords.NoteName(midi: number): string
	return Chords.NoteNames[(midi % 12) + 1] .. tostring(math.floor(midi / 12) - 1)
end

return Chords
