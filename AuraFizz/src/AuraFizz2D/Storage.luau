--!nonstrict
-- AuraFizz2D · Storage — the 2D shelf screen for your storage stations
-- (Cup Rack, Pantry Shelf, Fridge, Freezer, Syrup Shelf).
-- Shows every item kept there (DrinkCatalog.Items / Cups) with YOUR pictures;
-- pick up the ones the recipe needs and drag them into the prep tray (a quick tap works too).
-- Wrong ones bounce back out and cost a little score.
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(script.Parent.Config)
local Paint = require(script.Parent.Paint)
local FX = require(script.Parent.FX)
local UI = require(script.Parent.UI)
local Bridge = require(script.Parent.Bridge)

local Storage = {}
local T = Config.Theme
local P = UDim2.fromScale

local SHELF_COLOR = {
	CupRack = "#c7b3e6", Pantry = T.Wood, Fridge = "#dff1fa", Freezer = "#bfe3f5", BarShelf = "#f4b6c2",
}
local GLYPH = { CupRack = "🥤", Pantry = "🫙", Fridge = "🧊", Freezer = "❄", BarShelf = "🍯" }

-- Plays one shelf visit. needed = { itemId, ... }. Yields; returns score 0..1 (nil if closed).
-- opts.onPick(itemId) is called for each correct pick (to update the drink preview).
function Storage.play(panel, stationKey, needed, opts)
	opts = opts or {}
	panel:ClearAllChildren()
	local z = panel.ZIndex
	local st = Bridge.station(stationKey)
	local kind = if stationKey == "CupRack" then "cup" else "item"
	local want, remaining = {}, 0
	for _, id in needed do
		if not want[id] then
			want[id] = true
			remaining += 1
		end
	end
	local total = remaining

	Paint.text(panel, (GLYPH[stationKey] or "📦") .. "  " .. (st.name or stationKey), {
		Position = P(0.04, 0.04), Size = P(0.6, 0.085), AlignX = Enum.TextXAlignment.Left, ZIndex = z + 2 })
	Paint.text(panel, string.format("Take %d item%s", total, total == 1 and "" or "s"), {
		Color = T.TextSoft, Position = P(0.04, 0.125), Size = P(0.4, 0.05), AlignX = Enum.TextXAlignment.Left, ZIndex = z + 2 })

	-- checklist chips of what to take
	local chips = Paint.new("Frame", { BackgroundTransparency = 1, Position = P(0.04, 0.19), Size = P(0.92, 0.075), ZIndex = z + 1, Parent = panel })
	Paint.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.012, 0),
		VerticalAlignment = Enum.VerticalAlignment.Center, Parent = chips })
	local chipOf = {}
	local order = 0
	for id in want do
		order += 1
		local chip = UI.card(chips, T.PanelLight, { Size = P(math.min(0.3, 0.92 / math.max(total, 1) - 0.012), 1), Corner = UDim.new(0.5, 0) })
		chip.LayoutOrder = order
		local ic = Paint.new("Frame", { BackgroundTransparency = 1, Position = P(0.02, 0.05), Size = P(0.9, 0.9), ZIndex = chip.ZIndex + 1, Parent = chip })
		Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height, Parent = ic })
		Bridge.icon(ic, kind, id, { Behind = T.PanelLight })
		Paint.text(chip, Bridge.itemName(id), { Color = T.Text, Position = P(0.3, 0.18), Size = P(0.66, 0.64), AlignX = Enum.TextXAlignment.Left,
			ZIndex = chip.ZIndex + 1, MaxSize = 22 })
		chipOf[id] = chip
	end

	-- the shelf: a scrolling grid of every item in this storage
	local shelf = Paint.new("ScrollingFrame", {
		Name = "Shelf", BackgroundTransparency = 1, Position = P(0.03, 0.29), Size = P(0.94, 0.5), ZIndex = z + 1,
		ScrollBarThickness = 6, ScrollBarImageColor3 = Paint.C(T.TextSoft), CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = panel,
	})
	local grid = Paint.new("UIGridLayout", { CellPadding = UDim2.new(0, 0, 0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = shelf })
	local cols = if stationKey == "CupRack" then 5 else 6
	local function resize()
		local w = shelf.AbsoluteSize.X - 8
		local cell = math.floor(w / cols)
		grid.CellSize = UDim2.fromOffset(cell, math.floor(cell * 1.18))
	end
	resize()
	local shelfColor = SHELF_COLOR[stationKey] or T.Wood

	-- the prep tray: drag ingredients here (black tray with a gold rim, like your stations)
	local tray = Paint.new("Frame", { Name = "Tray", AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0.81), Size = P(0.7, 0.16), ZIndex = z + 2, Parent = panel })
	Paint.round(tray, UDim.new(0.3, 0))
	Paint.shade(tray, T.Appliance, 90, true)
	local rim = Paint.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0), Size = P(0.96, 0.08), ZIndex = z + 3, Parent = tray })
	Paint.round(rim, 0.5)
	Paint.shade(rim, T.Trim, 90, true)
	local trayHint = Paint.text(tray, "Drag ingredients here", { Color = T.TextSoft, Position = P(0.1, 0.3), Size = P(0.8, 0.4), ZIndex = z + 3 })
	local traySlots = 0

	return (function()
		local done = Instance.new("BindableEvent")
		local conns, finished = {}, false
		local mistakes, lastAction = 0, os.clock()
		local dragging = nil
		local cells = {}
		table.insert(conns, shelf:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize))

		local function finish(score)
			if finished then
				return
			end
			finished = true
			for _, c in conns do
				c:Disconnect()
			end
			local word, col = UI.grade(score)
			FX.floatText(panel, word, col, P(0.5, 0.5), P(0.5, 0.14))
			if score >= 0.95 then
				FX.sparkle(panel, P(0.5, 0.5), nil, 12)
				FX.sound("Perfect")
			end
			task.delay(0.9, function()
				done:Fire(score)
			end)
		end

		for i, id in Bridge.itemsIn(stationKey) do
			local cell = Paint.new("TextButton", { Name = id, Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
				LayoutOrder = i, ZIndex = z + 2, Parent = shelf })
			-- shelf plank under each item: adjacent cells form one continuous shelf
			local plank = Paint.new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.83), Size = P(1.02, 0.07), ZIndex = z + 2, Parent = cell })
			Paint.shade(plank, shelfColor, 90, true)
			local ic = Paint.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.8), Size = P(0.84, 0.66),
				ZIndex = z + 3, Parent = cell })
			Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = ic })
			Bridge.icon(ic, kind, id, { Behind = T.Panel })
			Paint.text(cell, Bridge.itemName(id), { Color = T.TextSoft, Position = P(0.02, 0.85), Size = P(0.96, 0.14), ZIndex = z + 3, MaxSize = 16 })
			cells[id] = cell
			ic:SetAttribute("Id", id)
			table.insert(conns, cell.InputBegan:Connect(function(input)
				if finished or dragging or cell:GetAttribute("Taken") or not UI.isPress(input) then
					return
				end
				lastAction = os.clock()
				-- pick up: the ingredient lifts off the shelf, grows a little and tilts
				local held = ic:Clone()
				for _, d in held:GetDescendants() do
					if d:IsA("GuiObject") then
						d.ZIndex += 60
					end
				end
				held.ZIndex = z + 60
				held.AnchorPoint = Vector2.new(0.5, 0.5)
				held.Size = UDim2.fromOffset(ic.AbsoluteSize.X, ic.AbsoluteSize.Y)
				local p0 = UI.pointer(input) - panel.AbsolutePosition
				held.Position = UDim2.fromOffset(p0.X, p0.Y)
				held.Parent = panel
				ic.Visible = false
				FX.tween(held, 0.12, { Size = UDim2.fromOffset(ic.AbsoluteSize.X * 1.18, ic.AbsoluteSize.Y * 1.18), Rotation = -8 }, Enum.EasingStyle.Back)
				FX.sound("Pick")
				dragging = { id = id, held = held, ic = ic, cell = cell, start = UI.pointer(input), last = UI.pointer(input) }
			end))
		end

		local function inTray(pos)
			local a, sz = tray.AbsolutePosition, tray.AbsoluteSize
			return pos.X >= a.X - 20 and pos.X <= a.X + sz.X + 20 and pos.Y >= a.Y - 30 and pos.Y <= a.Y + sz.Y + 20
		end
		-- the held ingredient follows the finger and tilts with the movement
		table.insert(conns, UserInputService.InputChanged:Connect(function(input)
			if not dragging then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local pos = UI.pointer(input)
			local rel = pos - panel.AbsolutePosition
			dragging.held.Position = UDim2.fromOffset(rel.X, rel.Y)
			dragging.held.Rotation = math.clamp((pos.X - dragging.last.X) * 1.2, -22, 22)
			dragging.last = pos
			rim.BackgroundColor3 = if inTray(pos) then Paint.C(T.Gold) else Color3.new(1, 1, 1)
		end))
		table.insert(conns, UserInputService.InputEnded:Connect(function(input)
			if not (dragging and UI.isPress(input)) then
				return
			end
			local d = dragging
			dragging = nil
			rim.BackgroundColor3 = Color3.new(1, 1, 1)
			local pos = UI.pointer(input)
			local tapped = (pos - d.start).Magnitude < 10 -- a quick tap still works (it hops into the tray)
			local function back()
				local home = d.ic.AbsolutePosition + d.ic.AbsoluteSize / 2 - panel.AbsolutePosition
				FX.tween(d.held, 0.35, { Position = UDim2.fromOffset(home.X, home.Y), Rotation = 0,
					Size = UDim2.fromOffset(d.ic.AbsoluteSize.X, d.ic.AbsoluteSize.Y) }, Enum.EasingStyle.Back)
				task.delay(0.36, function()
					d.held:Destroy()
					d.ic.Visible = true
					FX.bounce(d.ic, 0.2)
				end)
			end
			if not (tapped or inTray(pos)) then
				back() -- dropped somewhere else: floats back to its shelf spot
				return
			end
			if want[d.id] then
				-- lands in the tray with a squash, stays there
				d.cell:SetAttribute("Taken", true)
				traySlots += 1
				trayHint.Visible = false
				local slotX = 0.12 + (traySlots - 1) * 0.16
				local target = tray.AbsolutePosition + Vector2.new(tray.AbsoluteSize.X * slotX, tray.AbsoluteSize.Y * 0.55) - panel.AbsolutePosition
				local sz = tray.AbsoluteSize.Y * 0.95
				FX.tween(d.held, 0.28, { Position = UDim2.fromOffset(target.X, target.Y), Rotation = 0, Size = UDim2.fromOffset(sz, sz) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				task.delay(0.29, function()
					if not d.held.Parent then
						return
					end
					FX.squash(d.held, 0.2)
					FX.sparkle(panel, UDim2.fromOffset(target.X, target.Y), T.Gold, 5)
					FX.sound("Pick")
					local chip = chipOf[d.id]
					if chip and chip.Parent then
						Paint.shade(chip, T.Good, 60, true)
						FX.bounce(chip, 0.3)
					end
				end)
				if opts.onPick then
					task.spawn(opts.onPick, d.id)
				end
				remaining -= 1
				if remaining <= 0 then
					task.delay(0.35, function()
						finish(math.clamp(total / (total + mistakes * 0.6), 0, 1))
					end)
				end
			else
				-- wrong ingredient: it bounces out of the tray and hops home
				mistakes += 1
				FX.sound("Wrong")
				FX.wobble(d.held, 16, 0.3)
				FX.floatText(panel, "Not in this drink!", T.Bad, P(0.5, 0.74), P(0.45, 0.06))
				task.delay(0.3, back)
			end
		end))

		-- gentle hint: pulse the next needed item after a while idle
		table.insert(conns, RunService.Heartbeat:Connect(function()
			if finished or os.clock() - lastAction < Config.StorageHintAfter then
				return
			end
			lastAction = os.clock()
			for id in want do
				local cell = cells[id]
				if cell and not cell:GetAttribute("Taken") then
					local y = cell.AbsolutePosition.Y - shelf.AbsolutePosition.Y + shelf.CanvasPosition.Y
					TweenService:Create(shelf, TweenInfo.new(0.4), { CanvasPosition = Vector2.new(0, math.max(0, y - 20)) }):Play()
					FX.bounce(cell, 0.25)
					break
				end
			end
		end))
		table.insert(conns, panel.AncestryChanged:Connect(function()
			if not panel:IsDescendantOf(game) and not finished then
				finished = true
				done:Fire(nil)
			end
		end))

		if remaining == 0 then
			finish(1)
		end
		local score = done.Event:Wait()
		done:Destroy()
		return score
	end)()
end

return Storage
