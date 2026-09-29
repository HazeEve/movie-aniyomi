--!nonstrict
-- AuraFizz2D · Storage — the 2D shelf screen for your storage stations
-- (Cup Rack, Pantry Shelf, Fridge, Freezer, Syrup Shelf).
-- Shows every item kept there (DrinkCatalog.Items / Cups) with YOUR pictures;
-- tap the ones the recipe needs. Wrong picks cost a little score.
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

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
		Name = "Shelf", BackgroundTransparency = 1, Position = P(0.03, 0.29), Size = P(0.94, 0.69), ZIndex = z + 1,
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

	return (function()
		local done = Instance.new("BindableEvent")
		local conns, finished = {}, false
		local mistakes, lastAction = 0, os.clock()
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
			table.insert(conns, cell.Activated:Connect(function()
				if finished or cell:GetAttribute("Taken") then
					return
				end
				lastAction = os.clock()
				if want[id] then
					cell:SetAttribute("Taken", true)
					FX.sound("Pick")
					FX.bounce(ic, 0.3)
					-- fly a copy up toward the checklist chip
					local chip = chipOf[id]
					local fly = ic:Clone()
					fly.Parent = panel
					fly.ZIndex = z + 40
					for _, d in fly:GetDescendants() do
						if d:IsA("GuiObject") then
							d.ZIndex += 40
						end
					end
					fly.AnchorPoint = Vector2.new(0.5, 0.5)
					local pa, ps = panel.AbsolutePosition, panel.AbsoluteSize
					local from = ic.AbsolutePosition + ic.AbsoluteSize / 2 - pa
					local to = chip.AbsolutePosition + chip.AbsoluteSize / 2 - pa
					fly.Position = P(from.X / ps.X, from.Y / ps.Y)
					fly.Size = UDim2.fromOffset(ic.AbsoluteSize.X, ic.AbsoluteSize.Y)
					FX.tween(fly, 0.45, { Position = P(to.X / ps.X, to.Y / ps.Y), Size = UDim2.fromOffset(20, 20) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
					task.delay(0.46, function()
						fly:Destroy()
						if chip.Parent then
							Paint.shade(chip, T.Good, 60, true)
							FX.bounce(chip, 0.3)
							FX.sparkle(panel, P(to.X / ps.X, to.Y / ps.Y), T.Gold, 5)
						end
					end)
					ic.Visible = false
					if opts.onPick then
						task.spawn(opts.onPick, id)
					end
					remaining -= 1
					if remaining <= 0 then
						finish(math.clamp(total / (total + mistakes * 0.6), 0, 1))
					end
				else
					mistakes += 1
					FX.sound("Wrong")
					FX.wobble(cell, 10, 0.35)
					FX.floatText(panel, "Not in this drink!", T.Bad, P(0.5, 0.27), P(0.45, 0.06))
				end
			end))
		end

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
