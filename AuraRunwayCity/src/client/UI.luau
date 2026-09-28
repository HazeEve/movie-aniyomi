--!nonstrict
-- Tiny UI toolkit with the Aura "soft luxury" look.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local P = require(ReplicatedStorage.Shared.Palette)

local UI = {}
UI.P = P
UI.Font = {
	Title = Enum.Font.GothamBlack,
	Bold = Enum.Font.GothamBold,
	Medium = Enum.Font.GothamMedium,
	Luxe = Enum.Font.Bodoni,
}
UI.ROBUX = utf8.char(0xE002)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

function UI.new(class: string, props, children)
	local inst = Instance.new(class)
	if inst:IsA("GuiObject") then
		inst.BorderSizePixel = 0
	end
	local parent
	for k, v in props or {} do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, c in children or {} do
		c.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function UI.corner(inst, px: number?)
	return UI.new("UICorner", { CornerRadius = UDim.new(0, px or 12), Parent = inst })
end

function UI.round(inst)
	return UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = inst })
end

function UI.stroke(inst, color: Color3?, thickness: number?, transparency: number?)
	return UI.new("UIStroke", {
		Color = color or P.Champagne,
		Thickness = thickness or 1.5,
		Transparency = transparency or 0.55,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = inst,
	})
end

function UI.gradient(inst, colors, rotation: number?, transparency)
	local kps = {}
	for i, c in colors do
		table.insert(kps, ColorSequenceKeypoint.new((i - 1) / math.max(#colors - 1, 1), c))
	end
	return UI.new("UIGradient", {
		Color = ColorSequence.new(kps),
		Rotation = rotation or 90,
		Transparency = transparency,
		Parent = inst,
	})
end

function UI.pad(inst, t: number, r: number?, b: number?, l: number?)
	return UI.new("UIPadding", {
		PaddingTop = UDim.new(0, t),
		PaddingRight = UDim.new(0, r or t),
		PaddingBottom = UDim.new(0, b or t),
		PaddingLeft = UDim.new(0, l or r or t),
		Parent = inst,
	})
end

function UI.list(inst, dir, padding: number?, hAlign, vAlign)
	return UI.new("UIListLayout", {
		FillDirection = dir or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, padding or 8),
		HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
		VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = inst,
	})
end

function UI.grid(inst, cell: UDim2, padding: UDim2?)
	return UI.new("UIGridLayout", {
		CellSize = cell,
		CellPadding = padding or UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = inst,
	})
end

function UI.tween(obj, t: number, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

function UI.label(parent, text: string, props)
	local l = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		Font = UI.Font.Bold,
		TextColor3 = P.TextLight,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 24),
		Parent = parent,
	})
	for k, v in props or {} do
		l[k] = v
	end
	return l
end

local STYLES = {
	primary = { { P.Rose, P.Lavender }, P.TextLight },
	gold = { { Color3.fromHex("F4E1B9"), P.Gold }, P.Plum },
	light = { { P.Ivory, P.Pearl }, P.Plum },
	secondary = { { P.Lilac, P.Lavender }, P.Plum },
	dark = { { P.Aubergine, P.Plum }, P.TextLight },
	success = { { Color3.fromHex("BDEBD5"), P.Success }, P.Plum },
	danger = { { Color3.fromHex("F7B6C0"), P.Danger }, P.Plum },
	ghost = { nil, P.TextLight },
}
UI.Styles = STYLES

function UI.style(btn, style: string)
	local s = STYLES[style] or STYLES.primary
	local g = btn:FindFirstChildOfClass("UIGradient")
	if s[1] then
		btn.BackgroundTransparency = 0
		btn.BackgroundColor3 = Color3.new(1, 1, 1)
		if not g then
			g = UI.gradient(btn, s[1], 90)
		else
			g.Color = ColorSequence.new(s[1][1], s[1][2])
		end
	else
		btn.BackgroundTransparency = 1
		if g then
			g:Destroy()
		end
	end
	if btn:IsA("TextButton") then
		btn.TextColor3 = s[2]
	end
end

function UI.button(parent, text: string, style: string?, props)
	local b = UI.new("TextButton", {
		AutoButtonColor = false,
		Text = text,
		Font = UI.Font.Bold,
		TextSize = 18,
		Size = UDim2.fromOffset(140, 44),
		Parent = parent,
	})
	UI.corner(b, 14)
	UI.style(b, style or "primary")
	local sc = UI.new("UIScale", { Parent = b })
	b.MouseButton1Down:Connect(function()
		UI.tween(sc, 0.08, { Scale = 0.94 })
	end)
	b.MouseButton1Up:Connect(function()
		UI.tween(sc, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
	b.MouseLeave:Connect(function()
		UI.tween(sc, 0.18, { Scale = 1 })
	end)
	for k, v in props or {} do
		b[k] = v
	end
	return b
end

-- Round emoji button with a caption underneath (dock / toolbar)
function UI.iconButton(parent, emoji: string, caption: string?, props)
	local holder = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(64, caption and 80 or 64), Parent = parent })
	local b = UI.new("TextButton", {
		AutoButtonColor = false,
		Text = emoji,
		Font = UI.Font.Bold,
		TextSize = 28,
		Size = UDim2.fromOffset(60, 60),
		Position = UDim2.fromOffset(2, 0),
		BackgroundColor3 = P.Plum,
		BackgroundTransparency = 0.1,
		Parent = holder,
	})
	UI.round(b)
	UI.gradient(b, { P.Aubergine, P.Plum }, 90)
	local st = UI.stroke(b, P.Champagne, 2, 0.45)
	local sc = UI.new("UIScale", { Parent = b })
	b.MouseEnter:Connect(function()
		UI.tween(st, 0.2, { Transparency = 0.05 })
	end)
	b.MouseLeave:Connect(function()
		UI.tween(st, 0.2, { Transparency = 0.45 })
		UI.tween(sc, 0.15, { Scale = 1 })
	end)
	b.MouseButton1Down:Connect(function()
		UI.tween(sc, 0.08, { Scale = 0.9 })
	end)
	b.MouseButton1Up:Connect(function()
		UI.tween(sc, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
	if caption then
		UI.label(holder, caption, {
			Size = UDim2.new(1, 12, 0, 16),
			Position = UDim2.new(0, -6, 0, 62),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = 12,
			TextStrokeTransparency = 0.6,
			TextStrokeColor3 = P.PlumDeep,
		})
	end
	for k, v in props or {} do
		b[k] = v
	end
	return b, holder
end

-- Dark glass panel
function UI.panel(parent, props)
	local f = UI.new("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.04,
		Parent = parent,
	})
	UI.corner(f, 22)
	UI.gradient(f, { P.Plum, P.PlumDeep }, 90)
	UI.stroke(f, P.Champagne, 2, 0.55)
	for k, v in props or {} do
		f[k] = v
	end
	return f
end

-- Light card
function UI.card(parent, props)
	local f = UI.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Parent = parent })
	UI.corner(f, 14)
	UI.gradient(f, { P.Ivory, P.Pearl }, 90)
	for k, v in props or {} do
		f[k] = v
	end
	return f
end

function UI.textbox(parent, placeholder: string, props)
	local box = UI.new("TextBox", {
		BackgroundColor3 = P.Ivory,
		PlaceholderText = placeholder,
		PlaceholderColor3 = P.TextSoft,
		Text = "",
		ClearTextOnFocus = false,
		Font = UI.Font.Medium,
		TextSize = 18,
		TextColor3 = P.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromOffset(240, 44),
		Parent = parent,
	})
	UI.corner(box, 14)
	UI.pad(box, 0, 14)
	UI.stroke(box, P.Lavender, 1.5, 0.4)
	for k, v in props or {} do
		box[k] = v
	end
	return box
end

function UI.scroll(parent, props)
	local s = UI.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		ScrollBarThickness = 12,
		ScrollBarImageColor3 = P.Blush,
		ScrollBarImageTransparency = 0,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = parent,
	})
	for k, v in props or {} do
		s[k] = v
	end
	return s
end

function UI.screen(name: string, order: number?)
	local g = playerGui:FindFirstChild(name)
	if g then
		g:Destroy()
	end
	return UI.new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = order or 1,
		Parent = playerGui,
	})
end

-- Keeps a design-size frame fitted to the screen (designed at 1280x720)
local scaled = {}
local function viewportScale(): number
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local s = math.min(vs.X / 1280, vs.Y / 720)
	if vs.X < 900 or vs.Y < 500 then
		-- phones: allow a little more size so text stays readable
		s = math.min(vs.X / 1100, vs.Y / 600)
	end
	return math.clamp(s, 0.45, 1.35)
end
local fits = {}
local function fitScale(fit: Vector2?): number
	local s = viewportScale()
	if fit then
		local cam = workspace.CurrentCamera
		local vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
		-- keep big windows fully on screen (leave room for the top bar)
		s = math.min(s, (vs.X - 16) / fit.X, (vs.Y - 64) / fit.Y)
	end
	return math.max(s, 0.3)
end
-- fit: the design size of the frame, so it always fits the screen
function UI.autoScale(inst, fit: Vector2?)
	local sc = UI.new("UIScale", { Scale = fitScale(fit), Parent = inst })
	table.insert(scaled, sc)
	fits[sc] = fit or false
	return sc
end
UI.viewportScale = viewportScale
local function hookCamera()
	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			for _, sc in scaled do
				sc.Scale = fitScale(fits[sc] or nil)
			end
		end)
	end
end
hookCamera()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hookCamera)

-- Modal manager: one big panel at a time
local modals = {}
UI.ModalChanged = Instance.new("BindableEvent")
function UI.registerModal(name: string, frame: GuiObject, onOpen, onClose)
	modals[name] = { Frame = frame, OnOpen = onOpen, OnClose = onClose }
	frame.Visible = false
end
function UI.isOpen(name: string): boolean
	local m = modals[name]
	return m ~= nil and m.Frame.Visible
end
function UI.close(name: string)
	local m = modals[name]
	if m and m.Frame.Visible then
		m.Frame.Visible = false
		if m.OnClose then
			task.spawn(m.OnClose)
		end
		UI.ModalChanged:Fire(name, false)
	end
end
function UI.open(name: string, ...)
	for other in modals do
		if other ~= name then
			UI.close(other)
		end
	end
	local m = modals[name]
	if not m then
		return
	end
	local args = table.pack(...)
	m.Frame.Visible = true
	-- pop the inner window (the holder already owns the fit-to-screen UIScale;
	-- a GuiObject may only have one UIScale)
	local inner = m.Frame:FindFirstChild("Window") or m.Frame:FindFirstChildWhichIsA("GuiObject")
	if inner then
		local sc = inner:FindFirstChild("PopScale")
		if not sc then
			sc = UI.new("UIScale", { Name = "PopScale", Parent = inner })
		end
		sc.Scale = 0.94
		UI.tween(sc, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	if m.OnOpen then
		task.spawn(m.OnOpen, table.unpack(args, 1, args.n))
	end
	UI.ModalChanged:Fire(name, true)
end
function UI.toggle(name: string, ...)
	if UI.isOpen(name) then
		UI.close(name)
	else
		UI.open(name, ...)
	end
end
function UI.closeAll()
	for n in modals do
		UI.close(n)
	end
end

-- Standard modal window: centred design-size frame with title + close button
function UI.window(gui: ScreenGui, name: string, title: string, size: Vector2)
	local holder = UI.new("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y),
		Parent = gui,
	})
	UI.autoScale(holder, size)
	local win = UI.panel(holder, { Name = "Window", Size = UDim2.fromScale(1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	local titleLabel = UI.label(win, title, {
		Name = "Title",
		Font = UI.Font.Luxe,
		TextSize = 30,
		TextColor3 = P.Champagne,
		Position = UDim2.fromOffset(24, 14),
		Size = UDim2.new(1, -110, 0, 38),
	})
	local close = UI.button(win, "X", "light", {
		Font = UI.Font.Title,
		Name = "Close",
		Size = UDim2.fromOffset(44, 44),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 12),
		TextSize = 20,
	})
	UI.stroke(close, P.Champagne, 1.5, 0.5)
	close.Activated:Connect(function()
		UI.close(name)
	end)
	local body = UI.new("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(20, 64),
		Size = UDim2.new(1, -40, 1, -80),
		Parent = win,
	})
	return holder, body, titleLabel
end

function UI.assetThumb(id: number, size: number?): string
	size = size or 150
	return ("rbxthumb://type=Asset&id=%d&w=%d&h=%d"):format(id, size, size)
end
function UI.bundleThumb(id: number): string
	return ("rbxthumb://type=BundleThumbnail&id=%d&w=150&h=150"):format(id)
end
function UI.headshot(userId: number): string
	return ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(userId)
end

function UI.priceText(price: number?, forSale: boolean?): string
	if forSale == false then
		return "Off Sale"
	end
	if not price or price == 0 then
		return "Free"
	end
	return UI.ROBUX .. " " .. tostring(price)
end

function UI.fmtTime(sec: number): string
	sec = math.max(0, math.floor(sec))
	return ("%d:%02d"):format(sec // 60, sec % 60)
end

function UI.parseId(text: string): number?
	if typeof(text) ~= "string" then
		return nil
	end
	local id = text:match("catalog/(%d+)") or text:match("bundles/(%d+)") or text:match("id=(%d+)") or text:match("(%d%d%d%d+)")
	return id and tonumber(id) or nil
end

return UI
