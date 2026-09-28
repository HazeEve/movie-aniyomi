--!nonstrict
-- Instrument picker, chord picker (all 300 chords, choose 3-19) and the
-- playable instrument pads: guitar strum sliders, piano keys/sustain, violin
-- bow pad and drum pads. Hold a button to sustain; release to stop.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(script.Parent.Parent.UI)
local State = require(script.Parent.Parent.State)
local Engine = require(script.Parent.Parent.MusicEngine)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Chords = require(ReplicatedStorage.Shared.Chords)
local Instruments = require(ReplicatedStorage.Shared.Instruments)
local Config = require(ReplicatedStorage.Shared.Config)
local P = UI.P

local Music = {}
local player = Players.LocalPlayer
local Notify

local current = nil -- instrument kind
local selection = {} -- chord keys
local playGui, playRoot
local handleCounter = 0
local activeInputs = {} :: { [InputObject]: string }
local lastChord = nil
local toggles = { Drive = false, Power = false, Mute = false, Arp = false, Pizz = false, Keys = false }
local octave = 0
local sustainHeld = false
local sustained = {}

local function isPress(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function newHandle(): (number, string)
	handleCounter += 1
	return handleCounter, tostring(player.UserId) .. ":" .. handleCounter
end

-- ============ network + local play ============
local function startChord(chordOrNotes, style): string
	local id, key = newHandle()
	style = style or {}
	style.O = style.O or octave
	style.P = toggles.Power or nil
	style.D = (current == "Electric" and toggles.Drive) or nil
	if toggles.Mute and current == "Electric" then
		style.M = true
	end
	if current == "Violin" and toggles.Pizz then
		style.M = true
	end
	Engine.Start(player, key, current, chordOrNotes, style, false)
	Remotes.Event("Music"):FireServer("On", id, chordOrNotes, style)
	return key
end

local function stopChord(key: string?)
	if not key then
		return
	end
	if sustainHeld and current == "Piano" then
		table.insert(sustained, key)
		return
	end
	Engine.Stop(key)
	local id = tonumber(key:match(":(%d+)$"))
	if id then
		Remotes.Event("Music"):FireServer("Off", id)
	end
end

local function releaseSustain()
	local list = sustained
	sustained = {}
	for _, key in list do
		Engine.Stop(key)
		local id = tonumber(key:match(":(%d+)$"))
		if id then
			Remotes.Event("Music"):FireServer("Off", id)
		end
	end
end

local function pad(padId: string)
	Engine.Pad(player, padId, false)
	Remotes.Event("Music"):FireServer("Pad", padId)
end

-- global release tracking (works even if the finger slides off the button)
UserInputService.InputEnded:Connect(function(input)
	local key = activeInputs[input]
	if key == nil and input.UserInputType == Enum.UserInputType.MouseButton1 then
		for inp, k in activeInputs do
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				input, key = inp, k
				break
			end
		end
	end
	if key then
		activeInputs[input] = nil
		if key ~= "" then
			stopChord(key)
		end
	end
end)

-- ============ styled pieces ============
local CHORD_COLORS = { P.Blush, P.Lilac, P.Champagne, P.Mint, P.Powder, P.Peach, P.Lavender }

local function blobButton(parent, text: string, sub: string?, color: Color3, size: Vector2)
	local b = UI.new("TextButton", {
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = color,
		Size = UDim2.fromOffset(size.X, size.Y),
		Parent = parent,
	})
	UI.corner(b, math.floor(size.Y * 0.45))
	UI.gradient(b, { color:Lerp(P.Ivory, 0.35), color }, 90)
	local st = UI.stroke(b, P.Plum, 3, 0.1)
	UI.label(b, text, { Size = UDim2.new(1, 0, sub and 0.62 or 1, 0), TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, TextColor3 = P.Plum, Font = UI.Font.Title, TextSize = math.floor(size.Y * 0.36), TextWrapped = false, TextScaled = false })
	if sub then
		UI.label(b, sub, { Position = UDim2.fromScale(0, 0.58), Size = UDim2.new(1, 0, 0.3, 0), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = P.Dusk, TextSize = 11, Font = UI.Font.Medium })
	end
	local sc = UI.new("UIScale", { Parent = b })
	return b, sc, st
end

local function pressFx(sc: UIScale, st: UIStroke, down: boolean)
	UI.tween(sc, down and 0.06 or 0.18, { Scale = down and 0.9 or 1 }, down and Enum.EasingStyle.Quad or Enum.EasingStyle.Back)
	st.Color = down and P.NeonPink or P.Plum
end

-- ============ picker ============
local pickerHolder
local function buildPicker(gui)
	local holder, body = UI.window(gui, "MusicPicker", "Choose Your Instrument", Vector2.new(900, 420))
	local row = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = body })
	UI.list(row, Enum.FillDirection.Horizontal, 14, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	local desc = {
		Guitar = "Chords + strum up / down",
		Piano = "Chords, keys & sustain pedal",
		Electric = "Power chords & drive",
		Drums = "9 hit pads, hold to roll",
		Violin = "Bow & hold to sustain",
	}
	for i, kind in Instruments.Order do
		local info = Instruments.Info[kind]
		local card = UI.card(row, { LayoutOrder = i, Size = UDim2.fromOffset(158, 260) })
		UI.stroke(card, P.Lavender, 2, 0.4)
		UI.label(card, info.Icon, { Size = UDim2.new(1, 0, 0, 90), Position = UDim2.fromOffset(0, 16), TextSize = 64, TextXAlignment = Enum.TextXAlignment.Center })
		UI.label(card, info.Name, { Position = UDim2.fromOffset(8, 110), Size = UDim2.new(1, -16, 0, 44), TextColor3 = P.Text, TextSize = 18, Font = UI.Font.Title, TextXAlignment = Enum.TextXAlignment.Center })
		UI.label(card, desc[kind], { Position = UDim2.fromOffset(8, 156), Size = UDim2.new(1, -16, 0, 40), TextColor3 = P.TextSoft, TextSize = 13, Font = UI.Font.Medium, TextXAlignment = Enum.TextXAlignment.Center })
		local pick = UI.button(card, "Play", "primary", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.new(1, -24, 0, 42) })
		pick.Activated:Connect(function()
			Music.Select(kind)
		end)
	end
	UI.registerModal("MusicPicker", holder)
	return holder
end

-- ============ chord picker ============
local chordGrid, trayList, countL, playBtn, rootButtons, searchBox
local selectedRoot = 7 -- G
local function inSelection(key)
	return table.find(selection, key)
end

local refreshChordPicker
local function toggleChord(key)
	local i = inSelection(key)
	if i then
		table.remove(selection, i)
	elseif #selection < Config.Music.MaxChords then
		table.insert(selection, key)
	else
		Notify.Show(("You can pick up to %d chords."):format(Config.Music.MaxChords), "warn")
	end
	refreshChordPicker()
end

function refreshChordPicker()
	if not chordGrid then
		return
	end
	for _, c in chordGrid:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local q = searchBox.Text:lower():gsub("%s+", "")
	local list = {}
	if q ~= "" then
		for _, info in Chords.All do
			local short = info.Short:lower()
			local long = info.Long:lower():gsub("%s+", "")
			if short == q or short:find(q, 1, true) == 1 or long:find(q, 1, true) then
				table.insert(list, info)
			end
		end
	else
		for _, info in Chords.All do
			if info.RootIndex == selectedRoot then
				table.insert(list, info)
			end
		end
	end
	for i, info in list do
		if i > 150 then
			break
		end
		local on = inSelection(info.Key) ~= nil
		local b = UI.button(chordGrid, "", on and "gold" or "light", { LayoutOrder = i, Size = UDim2.fromOffset(150, 64) })
		UI.label(b, info.Short, { Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = P.Plum, Font = UI.Font.Title, TextSize = 22 })
		UI.label(b, info.Long, { Position = UDim2.fromOffset(4, 36), Size = UDim2.new(1, -8, 0, 20), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = P.TextSoft, Font = UI.Font.Medium, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd })
		if on then
			UI.stroke(b, P.Plum, 2, 0.2)
		end
		b.Activated:Connect(function()
			toggleChord(info.Key)
			-- preview the chord locally
			if current and current ~= "Drums" then
				local id = select(2, newHandle())
				Engine.Start(player, id, current, info.Key, { S = "down" }, false)
				task.delay(0.9, function()
					Engine.Stop(id)
				end)
			end
		end)
	end
	for i, rb in rootButtons do
		UI.style(rb, (i - 1) == selectedRoot and q == "" and "primary" or "dark")
	end
	-- tray
	for _, c in trayList:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	for i, key in selection do
		local info = Chords.Get(key)
		local chip = UI.button(trayList, info.Short .. "  ✕", "secondary", { LayoutOrder = i, Size = UDim2.fromOffset(0, 38), AutomaticSize = Enum.AutomaticSize.X, TextSize = 16 })
		UI.pad(chip, 0, 12)
		chip.Activated:Connect(function()
			toggleChord(key)
		end)
	end
	countL.Text = ("%d / %d chords  (pick at least %d)"):format(#selection, Config.Music.MaxChords, Config.Music.MinChords)
	local ok = #selection >= Config.Music.MinChords
	UI.style(playBtn, ok and "gold" or "dark")
	playBtn.Text = ok and "Play  ▶" or "Pick more"
end

local function buildChordPicker(gui)
	local holder, body, title = UI.window(gui, "ChordPicker", "Pick Your Chords", Vector2.new(1180, 650))
	rootButtons = {}
	local roots = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -300, 0, 96), Parent = body })
	UI.grid(roots, UDim2.fromOffset(122, 42), UDim2.fromOffset(8, 8))
	for i, label in Chords.RootLabels do
		local b = UI.button(roots, label, "dark", { LayoutOrder = i, TextSize = 17 })
		b.Activated:Connect(function()
			selectedRoot = i - 1
			searchBox.Text = ""
			refreshChordPicker()
		end)
		rootButtons[i] = b
	end
	searchBox = UI.textbox(body, "🔍 Find a chord (Am, sus4, maj7…)", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(284, 44), TextSize = 15 })
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		refreshChordPicker()
	end)
	local help = UI.label(body, "Tap a root, then tap chords to add them. Tap again to remove. You can mix any chords!", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 50), Size = UDim2.fromOffset(284, 44), TextSize = 13, TextColor3 = P.Lilac, Font = UI.Font.Medium })
	help.TextWrapped = true
	chordGrid = UI.scroll(body, { Position = UDim2.fromOffset(0, 104), Size = UDim2.new(1, 0, 1, -214) })
	UI.grid(chordGrid, UDim2.fromOffset(150, 64), UDim2.fromOffset(8, 8))
	UI.pad(chordGrid, 4)
	local trayBg = UI.new("Frame", { BackgroundColor3 = P.PlumDeep, BackgroundTransparency = 0.3, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -48), Size = UDim2.new(1, 0, 0, 56), Parent = body })
	UI.corner(trayBg, 14)
	trayList = UI.scroll(trayBg, { Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 3 })
	UI.list(trayList, Enum.FillDirection.Horizontal, 6, nil, Enum.VerticalAlignment.Center)
	countL = UI.label(body, "", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.fromOffset(420, 40), TextSize = 16, TextColor3 = P.Champagne })
	local clear = UI.button(body, "Clear", "dark", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -340, 1, 0), Size = UDim2.fromOffset(100, 42) })
	local defaults = UI.button(body, "Defaults", "secondary", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -226, 1, 0), Size = UDim2.fromOffset(106, 42) })
	playBtn = UI.button(body, "Play  ▶", "gold", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0), Size = UDim2.fromOffset(214, 42), TextSize = 20 })
	clear.Activated:Connect(function()
		selection = {}
		refreshChordPicker()
	end)
	defaults.Activated:Connect(function()
		selection = table.clone(Chords.Defaults[current] or Chords.Defaults.Guitar)
		refreshChordPicker()
	end)
	playBtn.Activated:Connect(function()
		if #selection < Config.Music.MinChords then
			Notify.Show(("Pick at least %d chords."):format(Config.Music.MinChords), "warn")
			return
		end
		task.spawn(function()
			Remotes.Func("MusicCall"):InvokeServer("SavePreset", current, selection)
		end)
		UI.close("ChordPicker")
		Music.ShowPlay()
	end)
	UI.registerModal("ChordPicker", holder, function()
		title.Text = ("Pick Your Chords — %s"):format(Instruments.Info[current] and Instruments.Info[current].Name or "")
		local pos = Chords.RootIndex
		if selection[1] then
			local info = Chords.Get(selection[1])
			selectedRoot = info and info.RootIndex or pos.G
		end
		refreshChordPicker()
	end)
end

-- ============ play UI ============
local function clearPlay()
	if playRoot then
		playRoot:Destroy()
		playRoot = nil
	end
	for input, key in activeInputs do
		if key ~= "" then
			stopChord(key)
		end
		activeInputs[input] = nil
	end
	sustainHeld = false
	releaseSustain()
end

local function toggleButton(parent, label: string, name: string, order: number)
	local b = UI.button(parent, label, toggles[name] and "gold" or "dark", { LayoutOrder = order, Size = UDim2.fromOffset(92, 38), TextSize = 14 })
	b.Activated:Connect(function()
		toggles[name] = not toggles[name]
		UI.style(b, toggles[name] and "gold" or "dark")
		if name == "Keys" then
			Music.ShowPlay()
		end
	end)
	return b
end

local function chordArea(parent, size: Vector2, style)
	-- arranges up to 19 chord blobs in two rows (like the reference sketch)
	local n = #selection
	local rows = n > 4 and 2 or 1
	local perRow = math.ceil(n / rows)
	local gap = 10
	local bw = math.clamp(math.floor((size.X - gap * (perRow - 1)) / perRow), 58, 132)
	local bh = math.clamp(math.floor((size.Y - gap * (rows - 1)) / rows), 56, 96)
	local area = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(size.X, size.Y), Parent = parent })
	for i, key in selection do
		local info = Chords.Get(key)
		local r = (i <= perRow) and 0 or 1
		local c = (i <= perRow) and (i - 1) or (i - perRow - 1)
		local countInRow = r == 0 and perRow or (n - perRow)
		local rowW = countInRow * bw + (countInRow - 1) * gap
		local x0 = (size.X - rowW) / 2
		local b, sc, st = blobButton(area, info.Short, nil, CHORD_COLORS[((i - 1) % #CHORD_COLORS) + 1], Vector2.new(bw, bh))
		b.Position = UDim2.fromOffset(x0 + c * (bw + gap), r * (bh + gap))
		b.InputBegan:Connect(function(input)
			if not isPress(input) then
				return
			end
			lastChord = key
			pressFx(sc, st, true)
			local s = table.clone(style)
			if current == "Piano" and toggles.Arp then
				s.S = "arp"
			end
			activeInputs[input] = startChord(key, s)
			local conn
			conn = UserInputService.InputEnded:Connect(function(ended)
				if ended == input or (ended.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1) then
					pressFx(sc, st, false)
					conn:Disconnect()
				end
			end)
		end)
	end
	return area
end

-- vertical swipe strip for strumming (up or down)
local function strumStrip(parent, dir: string, pos: UDim2, size: Vector2)
	local strip = UI.new("TextButton", {
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = Color3.new(1, 1, 1),
		Position = pos,
		Size = UDim2.fromOffset(size.X, size.Y),
		Parent = parent,
	})
	UI.corner(strip, 22)
	UI.gradient(strip, dir == "up" and { P.Lavender, P.Plum } or { P.Plum, P.Rose }, 90)
	local st = UI.stroke(strip, P.Champagne, 2, 0.3)
	UI.label(strip, dir == "up" and "⬆" or "⬇", { Size = UDim2.new(1, 0, 0, 50), Position = UDim2.fromScale(0, dir == "up" and 0.08 or 0.62), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 40 })
	UI.label(strip, dir == "up" and "UP" or "DOWN", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromScale(0, 0.45), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 14, TextColor3 = P.Champagne })
	local tracking = {}
	local function strum()
		local chord = lastChord or selection[1]
		if not chord then
			return
		end
		st.Color = P.NeonPink
		task.delay(0.12, function()
			st.Color = P.Champagne
		end)
		local key = startChord(chord, { S = dir })
		task.delay(1.6, function()
			if not sustainHeld then
				stopChord(key)
			end
		end)
	end
	strip.InputBegan:Connect(function(input)
		if isPress(input) then
			tracking[input] = { y = input.Position.Y, moved = false }
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		local t = tracking[input]
		if not t then
			-- mouse drags report MouseMovement instead of the original input
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				for inp, tt in tracking do
					if inp.UserInputType == Enum.UserInputType.MouseButton1 then
						t = tt
						break
					end
				end
			end
		end
		if t then
			local dy = input.Position.Y - t.y
			if (dir == "down" and dy > 26) or (dir == "up" and dy < -26) then
				t.y = input.Position.Y
				t.moved = true
				strum()
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		local t = tracking[input]
		if not t and input.UserInputType == Enum.UserInputType.MouseButton1 then
			for inp, tt in tracking do
				if inp.UserInputType == Enum.UserInputType.MouseButton1 then
					t, input = tt, inp
					break
				end
			end
		end
		if t then
			tracking[input] = nil
			if not t.moved then
				strum()
			end
		end
	end)
	return strip
end

local function bowPad(parent, pos: UDim2, size: Vector2)
	local padF = UI.new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = Color3.new(1, 1, 1), Position = pos, Size = UDim2.fromOffset(size.X, size.Y), Parent = parent })
	UI.corner(padF, 22)
	UI.gradient(padF, { P.Plum, P.Violet, P.Plum }, 0)
	UI.stroke(padF, P.Champagne, 2, 0.3)
	UI.label(padF, "⟵  BOW  ⟶", { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 24, Font = UI.Font.Title, TextColor3 = P.Champagne })
	local bowKey, lastX, lastMove, dragging
	padF.InputBegan:Connect(function(input)
		if isPress(input) then
			dragging = input
			lastX = input.Position.X
			lastMove = os.clock()
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input == dragging or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local dx = math.abs(input.Position.X - lastX)
			lastX = input.Position.X
			if dx > 1 then
				lastMove = os.clock()
				if not bowKey then
					bowKey = startChord(lastChord or selection[1], { S = "block" })
				end
				Engine.SetVolume(bowKey, math.clamp(0.4 + dx / 25, 0.4, 1.3))
			end
		end
	end)
	local function endBow()
		if bowKey then
			stopChord(bowKey)
			bowKey = nil
		end
	end
	UserInputService.InputEnded:Connect(function(input)
		if dragging and (input == dragging or input.UserInputType == Enum.UserInputType.MouseButton1) then
			dragging = nil
			endBow()
		end
	end)
	task.spawn(function()
		while padF.Parent do
			task.wait(0.1)
			if bowKey and os.clock() - lastMove > 0.35 then
				endBow()
			end
		end
	end)
end

local function pianoKeys(parent, size: Vector2)
	local area = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(size.X, size.Y), Parent = parent })
	local whites = { 0, 2, 4, 5, 7, 9, 11 }
	local blacks = { [0] = 1, [2] = 3, [5] = 6, [7] = 8, [9] = 10 }
	local octaves = 2
	local ww = size.X / (7 * octaves)
	local function key(parentF, midi: number, x: number, w: number, h: number, black: boolean)
		local b = UI.new("TextButton", {
			AutoButtonColor = false,
			Text = black and "" or Chords.NoteName(midi):gsub("%d", ""),
			TextYAlignment = Enum.TextYAlignment.Bottom,
			Font = UI.Font.Bold,
			TextSize = 13,
			TextColor3 = P.TextSoft,
			BackgroundColor3 = black and P.PlumDeep or P.Ivory,
			Position = UDim2.fromOffset(x, 0),
			Size = UDim2.fromOffset(w, h),
			ZIndex = black and 3 or 2,
			Parent = parentF,
		})
		UI.corner(b, 8)
		UI.stroke(b, P.Plum, 1.5, 0.3)
		b.InputBegan:Connect(function(input)
			if isPress(input) then
				b.BackgroundColor3 = black and P.Violet or P.Blush
				activeInputs[input] = startChord({ midi + octave * 12 }, { S = "block" })
				local conn
				conn = UserInputService.InputEnded:Connect(function(e)
					if e == input or (e.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1) then
						b.BackgroundColor3 = black and P.PlumDeep or P.Ivory
						conn:Disconnect()
					end
				end)
			end
		end)
	end
	for o = 0, octaves - 1 do
		for i, semis in whites do
			local x = (o * 7 + i - 1) * ww
			key(area, 60 + o * 12 + semis, x, ww - 3, size.Y, false)
			local bk = blacks[semis]
			if bk then
				key(area, 60 + o * 12 + bk, x + ww * 0.62, ww * 0.7, size.Y * 0.6, true)
			end
		end
	end
	return area
end

local function drumPads(parent, size: Vector2)
	local area = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(size.X, size.Y), Parent = parent })
	local pads = Instruments.Info.Drums.Pads
	local cols = 3
	local gap = 10
	local pw = (size.X - gap * (cols - 1)) / cols
	local ph = (size.Y - gap * 2) / 3
	local colors = { P.Champagne, P.Lilac, P.Blush, P.Mint, P.Powder, P.Peach, P.Rose, P.Lavender, P.Butter }
	for i, p in pads do
		local c = (i - 1) % cols
		local r = (i - 1) // cols
		local b, sc, st = blobButton(area, p.Name, nil, colors[i], Vector2.new(pw, ph))
		b.Position = UDim2.fromOffset(c * (pw + gap), r * (ph + gap))
		b.InputBegan:Connect(function(input)
			if not isPress(input) then
				return
			end
			pressFx(sc, st, true)
			pad(p.Id)
			activeInputs[input] = ""
			-- hold to roll
			local held = true
			local conn
			conn = UserInputService.InputEnded:Connect(function(e)
				if e == input or (e.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1) then
					held = false
					pressFx(sc, st, false)
					conn:Disconnect()
				end
			end)
			task.delay(0.35, function()
				while held and b.Parent do
					pad(p.Id)
					task.wait(0.09)
				end
			end)
		end)
	end
	return area
end

function Music.ShowPlay()
	clearPlay()
	if not current then
		return
	end
	local info = Instruments.Info[current]
	local W, H = 1200, 300
	playRoot = UI.new("Frame", {
		Name = "PlayRoot",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.fromOffset(W, H),
		Parent = playGui,
	})
	UI.autoScale(playRoot)
	local bg = UI.panel(playRoot, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.25 })
	-- top bar
	local bar = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 40), Parent = bg })
	UI.list(bar, Enum.FillDirection.Horizontal, 8, nil, Enum.VerticalAlignment.Center)
	UI.label(bar, info.Icon .. "  " .. info.Name, { LayoutOrder = 0, Size = UDim2.fromOffset(250, 38), TextSize = 22, Font = UI.Font.Luxe, TextColor3 = P.Champagne })
	if current == "Electric" then
		toggleButton(bar, "🔥 Drive", "Drive", 1)
		toggleButton(bar, "⚡ Power", "Power", 2)
		toggleButton(bar, "🤚 Mute", "Mute", 3)
	elseif current == "Piano" then
		toggleButton(bar, "〰 Arp", "Arp", 1)
		toggleButton(bar, "🎹 Keys", "Keys", 2)
		local down = UI.button(bar, "Oct −", "dark", { LayoutOrder = 3, Size = UDim2.fromOffset(74, 38), TextSize = 14 })
		local octL = UI.label(bar, "Oct " .. octave, { LayoutOrder = 4, Size = UDim2.fromOffset(60, 38), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 14 })
		local up = UI.button(bar, "Oct +", "dark", { LayoutOrder = 5, Size = UDim2.fromOffset(74, 38), TextSize = 14 })
		down.Activated:Connect(function()
			octave = math.max(-1, octave - 1)
			octL.Text = "Oct " .. octave
		end)
		up.Activated:Connect(function()
			octave = math.min(1, octave + 1)
			octL.Text = "Oct " .. octave
		end)
	elseif current == "Violin" then
		toggleButton(bar, "✌ Pizz", "Pizz", 1)
	end
	local spacer = UI.new("Frame", { BackgroundTransparency = 1, LayoutOrder = 50, Size = UDim2.fromOffset(10, 10), Parent = bar })
	spacer.Size = UDim2.fromOffset(math.max(10, 300 - (current == "Piano" and 250 or 0)), 10)
	if current ~= "Drums" then
		local edit = UI.button(bar, "✎ Chords", "secondary", { LayoutOrder = 60, Size = UDim2.fromOffset(110, 38), TextSize = 15 })
		edit.Activated:Connect(function()
			UI.open("ChordPicker")
		end)
	end
	local swap = UI.button(bar, "⇄ Instrument", "light", { LayoutOrder = 61, Size = UDim2.fromOffset(130, 38), TextSize = 15 })
	swap.Activated:Connect(function()
		UI.open("MusicPicker")
	end)
	local stop = UI.button(bar, "✕ Stop", "danger", { LayoutOrder = 62, Size = UDim2.fromOffset(96, 38), TextSize = 15 })
	stop.Activated:Connect(function()
		Music.Stop()
	end)

	local content = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 58), Size = UDim2.new(1, -32, 1, -70), Parent = bg })
	local cw, ch = W - 32, H - 70
	if current == "Guitar" or current == "Electric" then
		chordArea(content, Vector2.new(cw - 210, ch), { S = "down" })
		strumStrip(content, "up", UDim2.new(1, -196, 0, 0), Vector2.new(90, ch))
		strumStrip(content, "down", UDim2.new(1, -96, 0, 0), Vector2.new(90, ch))
	elseif current == "Piano" then
		if toggles.Keys then
			pianoKeys(content, Vector2.new(cw - 150, ch))
		else
			chordArea(content, Vector2.new(cw - 150, ch), { S = "block" })
		end
		local sus, sc, st = blobButton(content, "Sustain", "hold pedal", P.Champagne, Vector2.new(136, ch))
		sus.Position = UDim2.new(1, -136, 0, 0)
		sus.InputBegan:Connect(function(input)
			if isPress(input) then
				sustainHeld = true
				pressFx(sc, st, true)
				local conn
				conn = UserInputService.InputEnded:Connect(function(e)
					if e == input or (e.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1) then
						sustainHeld = false
						pressFx(sc, st, false)
						releaseSustain()
						conn:Disconnect()
					end
				end)
			end
		end)
	elseif current == "Violin" then
		chordArea(content, Vector2.new(cw - 330, ch), { S = "block" })
		bowPad(content, UDim2.new(1, -316, 0, 0), Vector2.new(316, ch))
	elseif current == "Drums" then
		local pw = math.min(cw, 700)
		local area = drumPads(content, Vector2.new(pw, ch))
		area.Position = UDim2.fromOffset((cw - pw) / 2, 0)
	end
end

function Music.Select(kind: string)
	current = kind
	Remotes.Event("Music"):FireServer("Equip", kind)
	UI.close("MusicPicker")
	if kind == "Drums" then
		Music.ShowPlay()
		return
	end
	local preset = State.Data.Presets and State.Data.Presets[kind]
	if typeof(preset) == "table" and #preset >= Config.Music.MinChords then
		selection = table.clone(preset)
	elseif #selection < Config.Music.MinChords then
		selection = table.clone(Chords.Defaults[kind] or Chords.Defaults.Guitar)
	end
	toggles.Keys = false
	UI.open("ChordPicker")
end

function Music.Stop()
	clearPlay()
	current = nil
	Remotes.Event("Music"):FireServer("Unequip")
end

function Music.Toggle()
	if playRoot then
		UI.open("MusicPicker")
	else
		UI.toggle("MusicPicker")
	end
end

function Music.Init(controllers)
	Notify = controllers.Notify
	local gui = UI.screen("AuraMusic", 11)
	playGui = UI.screen("AuraMusicPlay", 6)
	pickerHolder = buildPicker(gui)
	buildChordPicker(gui)

	-- sounds from other players
	Remotes.Event("Music").OnClientEvent:Connect(function(kind, owner, a, b, c, d, e)
		if typeof(owner) ~= "Instance" or owner == player then
			return
		end
		if kind == "On" then
			-- a = instrument, b = handle id, c = chord/notes, d = style, e = onStage
			Engine.Start(owner, tostring(owner.UserId) .. ":" .. tostring(b), a, c, d, e)
		elseif kind == "Off" then
			Engine.Stop(tostring(owner.UserId) .. ":" .. tostring(a))
		elseif kind == "Pad" then
			Engine.Pad(owner, a, b)
		end
	end)
	Engine.MissingSamples.Event:Connect(function()
		Notify.Show("Instrument sounds are still loading (or not set). Owner: add sample IDs in Shared/Instruments.", "warn")
	end)
	player.CharacterAdded:Connect(function()
		if current then
			task.wait(1)
			Remotes.Event("Music"):FireServer("Equip", current)
		end
	end)
end

return Music
