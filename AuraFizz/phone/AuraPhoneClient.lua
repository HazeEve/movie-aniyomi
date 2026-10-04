--!nonstrict
-- AuraPhone · client — the phone UI (built by code, no images to upload).
-- Apps: Messages, Contacts, Send Robux, Wallet, Settings. Open with the phone button or the P key.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("AuraPhoneRemotes")
local Fn = remotes:WaitForChild("Fn") :: RemoteFunction
local Event = remotes:WaitForChild("Event") :: RemoteEvent

-- ================= settings you can change =================
local OPEN_KEY = Enum.KeyCode.P
local SHOW_SHOUTOUTS = true -- little popup for everyone when someone sends Robux
local W, H = 390, 820 -- phone screen design size (scaled to fit the player's screen)

local WALLPAPERS = {
	{ "Peach Fizz", "#ffafc5", "#ffd3a8", "#fff3b8" },
	{ "Lavender", "#c9b2e0", "#ffc8dd", "#bfe0ff" },
	{ "Ocean", "#7fb8ff", "#a9d6ff", "#d4f4ff" },
	{ "Matcha", "#9fd8b4", "#d3f0dc", "#fbf6dc" },
	{ "Sunset", "#ff7fa3", "#ff9f8a", "#ffd27a" },
	{ "Midnight", "#17152f", "#2f2766", "#6c4ab6" },
	{ "Black & Gold", "#0f0d12", "#2a2530", "#c9a24a" },
	{ "Cotton Candy", "#ffc6ff", "#c9b8ff", "#a8ccff" },
}

local APPS = {
	{ id = "messages", name = "Messages", glyph = "💬", a = "#6ff59b", b = "#22b955" },
	{ id = "contacts", name = "Contacts", glyph = "👥", a = "#a6bdff", b = "#5674f5" },
	{ id = "send", name = "Send Robux", glyph = "💸", a = "#ffe48f", b = "#f2a900" },
	{ id = "wallet", name = "Wallet", glyph = "💳", a = "#3a3644", b = "#121017" },
	{ id = "settings", name = "Settings", glyph = "⚙️", a = "#e4e4ea", b = "#9b9aa8" },
}

-- ================= helpers =================
local function C(hex)
	return Color3.fromHex(hex)
end
local INK = C("#1d1b24")
local SOFT = C("#77748a")
local PAGE = C("#f6f5fb")
local BLUE = C("#5b7cfa")
local GOLD = C("#f2a900")
local RED = C("#ff4d6d")

local function new(class, props, children)
	local o = Instance.new(class)
	local parent = props.Parent
	props.Parent = nil
	for k, v in props do
		o[k] = v
	end
	for _, c in children or {} do
		c.Parent = o
	end
	o.Parent = parent
	return o
end
local function corner(o, px)
	return new("UICorner", { CornerRadius = UDim.new(0, px), Parent = o })
end
local function round(o)
	return new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = o })
end
local function stroke(o, color, thick, tr)
	return new("UIStroke", { Color = color, Thickness = thick or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = o })
end
local function grad(o, a, b, rot, c)
	local seq = if c
		then ColorSequence.new({ ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(0.5, b), ColorSequenceKeypoint.new(1, c) })
		else ColorSequence.new(a, b)
	return new("UIGradient", { Color = seq, Rotation = rot or 90, Parent = o })
end
local function pad(o, l, r, t, b)
	return new("UIPadding", { PaddingLeft = UDim.new(0, l), PaddingRight = UDim.new(0, r or l), PaddingTop = UDim.new(0, t or l), PaddingBottom = UDim.new(0, b or t or l), Parent = o })
end
local function frame(parent, props)
	props.Parent = parent
	if props.BackgroundTransparency == nil then
		props.BackgroundTransparency = 1
	end
	props.BorderSizePixel = 0
	return new("Frame", props)
end
local function text(parent, str, size, color, font, props)
	props = props or {}
	props.Parent = parent
	props.Text = str
	props.TextSize = size
	props.TextColor3 = color or INK
	props.Font = font or Enum.Font.BuilderSansBold
	props.BackgroundTransparency = 1
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	props.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
	return new("TextLabel", props)
end
local function tween(o, t, props, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
-- a press-bounce button (invisible hit box around any content)
local function button(parent, props, onClick)
	props.Parent = parent
	props.AutoButtonColor = false
	props.Text = props.Text or ""
	props.BorderSizePixel = 0
	if props.BackgroundTransparency == nil then
		props.BackgroundTransparency = 1
	end
	local b = new("TextButton", props)
	local sc = new("UIScale", { Parent = b })
	b.MouseButton1Down:Connect(function()
		tween(sc, 0.12, { Scale = 0.92 })
	end)
	local function up()
		tween(sc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	b.MouseButton1Up:Connect(up)
	b.MouseLeave:Connect(up)
	b.Activated:Connect(function()
		if onClick then
			onClick()
		end
	end)
	return b
end
local function pill(parent, str, bg, fg, props, onClick)
	local size = props.TextSizeOverride or 16
	props.TextSizeOverride = nil
	props.BackgroundColor3 = bg
	props.BackgroundTransparency = 0
	local b = button(parent, props, onClick)
	round(b)
	text(b, str, size, fg or Color3.new(1, 1, 1), Enum.Font.BuilderSansBold,
		{ Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center })
	return b
end
local function list(parent, props, gap)
	props.Parent = parent
	props.BackgroundTransparency = 1
	props.BorderSizePixel = 0
	props.ScrollBarThickness = 3
	props.ScrollBarImageColor3 = SOFT
	props.CanvasSize = UDim2.new()
	props.AutomaticCanvasSize = Enum.AutomaticSize.Y
	props.ScrollingDirection = Enum.ScrollingDirection.Y
	local s = new("ScrollingFrame", props)
	new("UIListLayout", { Padding = UDim.new(0, gap or 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = s })
	return s
end
local function clear(o)
	for _, c in o:GetChildren() do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
end
local function call(...)
	local ok, a, b = pcall(Fn.InvokeServer, Fn, ...)
	if not ok then
		return false, "Connection problem. Try again."
	end
	return a, b
end

local thumbs = {}
local function avatar(parent, userId, px, props)
	props = props or {}
	props.Parent = parent
	props.Size = UDim2.fromOffset(px, px)
	props.BackgroundColor3 = C("#dcdbe6")
	props.Image = thumbs[userId] or ""
	local img = new("ImageLabel", props)
	round(img)
	if not thumbs[userId] then
		task.spawn(function()
			local ok, url = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			if ok then
				thumbs[userId] = url
				img.Image = url
			end
		end)
	end
	return img
end

local soundOn = true
local ping = new("Sound", { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.4, Parent = SoundService })
local function playPing()
	if soundOn then
		SoundService:PlayLocalSound(ping)
	end
end

local names = {}
local function nameOf(userId)
	local p = Players:GetPlayerByUserId(userId)
	if p then
		names[userId] = p.DisplayName
	end
	return names[userId] or "Player"
end

-- ================= the phone =================
local gui = new("ScreenGui", { Name = "AuraPhone", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 40,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })

-- phone button on the right edge
local toggle = button(gui, { Name = "PhoneButton", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
	Size = UDim2.fromOffset(58, 58), BackgroundColor3 = C("#ffffff"), BackgroundTransparency = 0.1 })
round(toggle)
stroke(toggle, C("#ffffff"), 2, 0.3)
grad(toggle, C("#ffffff"), C("#e9e6f5"), 90)
text(toggle, "📱", 28, INK, nil, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center })
local badge = frame(toggle, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.86, 0.14), Size = UDim2.fromOffset(22, 22),
	BackgroundColor3 = RED, BackgroundTransparency = 0, Visible = false, ZIndex = 3 })
round(badge)
local badgeText = text(badge, "1", 13, Color3.new(1, 1, 1), nil, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4 })

local phone = frame(gui, { Name = "Phone", AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(W + 20, H + 20),
	BackgroundColor3 = C("#0c0b10"), BackgroundTransparency = 0, Visible = false })
corner(phone, 58)
stroke(phone, C("#3b3846"), 3, 0)
local scale = new("UIScale", { Parent = phone })
-- side buttons
frame(phone, { Position = UDim2.new(1, 0, 0, 190), Size = UDim2.fromOffset(4, 90), BackgroundColor3 = C("#2a2733"), BackgroundTransparency = 0 })
frame(phone, { Position = UDim2.new(0, -4, 0, 160), Size = UDim2.fromOffset(4, 50), BackgroundColor3 = C("#2a2733"), BackgroundTransparency = 0 })
frame(phone, { Position = UDim2.new(0, -4, 0, 220), Size = UDim2.fromOffset(4, 50), BackgroundColor3 = C("#2a2733"), BackgroundTransparency = 0 })

local screen = new("CanvasGroup", { Name = "Screen", Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(W, H),
	BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = phone })
corner(screen, 48)

-- wallpaper with slowly drifting soft blobs
local wall = frame(screen, { Name = "Wallpaper", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0 })
local wallGrad = grad(wall, Color3.new(1, 1, 1), Color3.new(1, 1, 1), 125)
local blobs = {}
for i, spec in { { 0.15, 0.2, 300 }, { 0.85, 0.55, 360 }, { 0.3, 0.9, 280 } } do
	local b = frame(wall, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(spec[1], spec[2]), Size = UDim2.fromOffset(spec[3], spec[3]),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.6 })
	round(b)
	blobs[i] = b
	TweenService:Create(b, TweenInfo.new(7 + i * 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Position = UDim2.fromScale(spec[1] + (i % 2 == 0 and -0.18 or 0.18), spec[2] + 0.08) }):Play()
end
local wallIndex = 1
local darkWall = false
local function setWallpaper(n)
	local w = WALLPAPERS[n] or WALLPAPERS[1]
	wallIndex = n
	local a, b, c = C(w[2]), C(w[3]), C(w[4])
	wallGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(0.55, b), ColorSequenceKeypoint.new(1, c) })
	local lum = (a.R + b.R + c.R) / 3
	darkWall = lum < 0.45
	for i, bl in blobs do
		bl.BackgroundColor3 = (if i == 2 then c else b):Lerp(Color3.new(1, 1, 1), if darkWall then 0.1 else 0.45)
		bl.BackgroundTransparency = if darkWall then 0.75 else 0.55
	end
end

-- pages live in here; status bar + island + home bar float above
local pagesHolder = frame(screen, { Name = "Pages", Size = UDim2.fromScale(1, 1), ZIndex = 2 })
local statusBar = frame(screen, { Name = "Status", Size = UDim2.new(1, 0, 0, 54), ZIndex = 50 })
local clockLabel = text(statusBar, "9:41", 16, Color3.new(1, 1, 1), Enum.Font.BuilderSansBold,
	{ Position = UDim2.fromOffset(38, 14), Size = UDim2.fromOffset(80, 24), ZIndex = 51, TextXAlignment = Enum.TextXAlignment.Center })
local iconsLabel = text(statusBar, "▂▄▆  ◉  ▭", 13, Color3.new(1, 1, 1), Enum.Font.BuilderSansBold,
	{ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -34, 0, 14), Size = UDim2.fromOffset(90, 24), ZIndex = 51, TextXAlignment = Enum.TextXAlignment.Right })
local island = frame(screen, { Name = "Island", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 11), Size = UDim2.fromOffset(118, 34),
	BackgroundColor3 = C("#000000"), BackgroundTransparency = 0, ZIndex = 60 })
round(island)
local homeBar = button(screen, { Name = "HomeBar", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(0.6, 0, 0, 30), ZIndex = 55 })
local homeLine = frame(homeBar, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(134, 5),
	BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, ZIndex = 56 })
round(homeLine)

local function statusColor(dark)
	local col = if dark then INK else Color3.new(1, 1, 1)
	clockLabel.TextColor3 = col
	iconsLabel.TextColor3 = col
	homeLine.BackgroundColor3 = if dark then C("#1d1b24") else Color3.new(1, 1, 1)
end

-- ================= page system =================
local pages = {}
local current = nil
local history = {}

local function page(name, opts)
	opts = opts or {}
	local g = new("CanvasGroup", { Name = name, Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Visible = false,
		BackgroundColor3 = PAGE, BackgroundTransparency = if opts.clear then 1 else 0.04, Parent = pagesHolder })
	local sc = new("UIScale", { Parent = g })
	pages[name] = { frame = g, scale = sc, dark = not opts.clear, onOpen = opts.onOpen }
	return g
end

local function goTo(name, how, ...)
	local nxt = pages[name]
	if not nxt or current == name then
		if nxt and nxt.onOpen then
			nxt.onOpen(...)
		end
		return
	end
	local prev = current and pages[current]
	if how ~= "back" and current and how ~= "home" then
		table.insert(history, current)
	end
	current = name
	if nxt.onOpen then
		nxt.onOpen(...)
	end
	statusColor(nxt.dark)
	local f = nxt.frame
	f.Visible = true
	f.ZIndex = 5
	if prev then
		prev.frame.ZIndex = 4
	end
	if how == "app" then
		f.Position = UDim2.new()
		f.GroupTransparency = 1
		nxt.scale.Scale = 0.86
		tween(f, 0.3, { GroupTransparency = 0 })
		tween(nxt.scale, 0.42, { Scale = 1 })
	elseif how == "push" then
		f.GroupTransparency = 0
		nxt.scale.Scale = 1
		f.Position = UDim2.fromScale(1, 0)
		tween(f, 0.38, { Position = UDim2.new() })
		if prev then
			tween(prev.frame, 0.38, { Position = UDim2.fromScale(-0.3, 0) })
		end
	elseif how == "back" then
		f.GroupTransparency = 0
		nxt.scale.Scale = 1
		f.Position = UDim2.fromScale(-0.3, 0)
		tween(f, 0.38, { Position = UDim2.new() })
		if prev then
			prev.frame.ZIndex = 6
			tween(prev.frame, 0.38, { Position = UDim2.fromScale(1, 0) })
		end
	else -- home / fade
		f.Position = UDim2.new()
		f.GroupTransparency = 0
		nxt.scale.Scale = 1.06
		tween(nxt.scale, 0.4, { Scale = 1 })
		if prev then
			prev.frame.ZIndex = 6
			tween(prev.frame, 0.25, { GroupTransparency = 1 })
			tween(prev.scale, 0.3, { Scale = 0.86 })
		end
	end
	if prev then
		local pf = prev.frame
		task.delay(0.42, function()
			if current ~= name or pf == f then
				return
			end
			pf.Visible = false
			pf.Position = UDim2.new()
			pf.GroupTransparency = 0
			prev.scale.Scale = 1
		end)
	end
end

local function back()
	local prev = table.remove(history)
	goTo(prev or "home", "back")
end
local function goHome()
	if current == "lock" then
		return
	end
	table.clear(history)
	goTo("home", "home")
end
homeBar.Activated:Connect(goHome)

-- app header with optional back button
local function header(pg, title, withBack)
	local h = frame(pg, { Name = "Header", Size = UDim2.new(1, 0, 0, 108), ZIndex = 10 })
	local t = text(h, title, 32, INK, Enum.Font.BuilderSansExtraBold, { Position = UDim2.fromOffset(24, 58), Size = UDim2.new(1, -48, 0, 40), ZIndex = 11 })
	if withBack then
		button(h, { Position = UDim2.fromOffset(12, 52), Size = UDim2.fromOffset(40, 44), ZIndex = 12 }, back)
		text(h, "‹", 40, BLUE, Enum.Font.BuilderSansBold, { Position = UDim2.fromOffset(16, 48), Size = UDim2.fromOffset(30, 44), ZIndex = 12 })
		t.Position = UDim2.fromOffset(52, 58)
		t.TextSize = 26
	end
	return h, t
end

local function card(parent, height, props)
	props = props or {}
	props.Size = props.Size or UDim2.new(1, -32, 0, height)
	props.BackgroundColor3 = props.BackgroundColor3 or Color3.new(1, 1, 1)
	props.BackgroundTransparency = props.BackgroundTransparency or 0
	local f = frame(parent, props)
	corner(f, 20)
	return f
end

local function emptyState(parent, glyph, msg)
	local f = frame(parent, { Size = UDim2.new(1, -40, 0, 200), LayoutOrder = 999 })
	text(f, glyph, 54, INK, nil, { Size = UDim2.new(1, 0, 0, 80), TextXAlignment = Enum.TextXAlignment.Center })
	text(f, msg, 16, SOFT, Enum.Font.BuilderSansMedium, { Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 90),
		TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true })
	return f
end

-- ================= notifications =================
local bannerQueue = {}
local bannerBusy = false
local isOpen = false
local unread = 0

local toastHolder = frame(gui, { Name = "Toasts", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -82, 0.5, -40), Size = UDim2.fromOffset(300, 300) })
new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8), Parent = toastHolder })

local function toast(userId, title, body, accent)
	local t = frame(toastHolder, { Size = UDim2.fromOffset(290, 64), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.06 })
	corner(t, 22)
	stroke(t, accent or C("#ffffff"), 2, 0.2)
	local inner = frame(t, { Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(340, 0) })
	if userId then
		avatar(inner, userId, 44, { Position = UDim2.fromOffset(10, 10) })
	end
	text(inner, title, 15, INK, nil, { Position = UDim2.fromOffset(62, 10), Size = UDim2.new(1, -72, 0, 20), TextTruncate = Enum.TextTruncate.AtEnd })
	text(inner, body, 13, SOFT, Enum.Font.BuilderSansMedium, { Position = UDim2.fromOffset(62, 32), Size = UDim2.new(1, -72, 0, 20), TextTruncate = Enum.TextTruncate.AtEnd })
	t.BackgroundTransparency = 1
	tween(t, 0.3, { BackgroundTransparency = 0.06 })
	tween(inner, 0.45, { Position = UDim2.new() }, Enum.EasingStyle.Back)
	task.delay(3.6, function()
		tween(inner, 0.3, { Position = UDim2.fromOffset(340, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tween(t, 0.3, { BackgroundTransparency = 1 })
		task.wait(0.32)
		t:Destroy()
	end)
end

local bannerFrame = frame(screen, { Name = "Banner", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -100), Size = UDim2.new(1, -24, 0, 76),
	BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.04, ZIndex = 70 })
corner(bannerFrame, 26)
local bannerAvatarHolder = frame(bannerFrame, { Position = UDim2.fromOffset(12, 14), Size = UDim2.fromOffset(48, 48), ZIndex = 71 })
local bannerTitle = text(bannerFrame, "", 16, INK, nil, { Position = UDim2.fromOffset(70, 14), Size = UDim2.new(1, -84, 0, 22), ZIndex = 71, TextTruncate = Enum.TextTruncate.AtEnd })
local bannerBody = text(bannerFrame, "", 14, SOFT, Enum.Font.BuilderSansMedium, { Position = UDim2.fromOffset(70, 38), Size = UDim2.new(1, -84, 0, 22), ZIndex = 71, TextTruncate = Enum.TextTruncate.AtEnd })
local bannerTap = nil
local bannerBtn = button(bannerFrame, { Size = UDim2.fromScale(1, 1), ZIndex = 72 }, function()
	if bannerTap then
		bannerTap()
	end
end)
local _ = bannerBtn

local function runBanners()
	if bannerBusy then
		return
	end
	bannerBusy = true
	while #bannerQueue > 0 do
		local b = table.remove(bannerQueue, 1)
		clear(bannerAvatarHolder)
		if b.userId then
			avatar(bannerAvatarHolder, b.userId, 48, { ZIndex = 71 })
		end
		bannerTitle.Text = b.title
		bannerBody.Text = b.body
		bannerTap = b.onTap
		tween(island, 0.35, { Size = UDim2.fromOffset(150, 34) }, Enum.EasingStyle.Back)
		tween(bannerFrame, 0.5, { Position = UDim2.new(0.5, 0, 0, 52) }, Enum.EasingStyle.Back)
		task.wait(3)
		tween(bannerFrame, 0.35, { Position = UDim2.new(0.5, 0, 0, -100) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tween(island, 0.35, { Size = UDim2.fromOffset(118, 34) })
		task.wait(0.4)
	end
	bannerBusy = false
end

local function setUnread(n)
	unread = math.max(n, 0)
	badge.Visible = unread > 0 and not isOpen
	badgeText.Text = if unread > 9 then "9+" else tostring(unread)
end

local function notify(userId, title, body, onTap, accent)
	playPing()
	if isOpen then
		table.insert(bannerQueue, { userId = userId, title = title, body = body, onTap = onTap })
		task.spawn(runBanners)
	else
		toast(userId, title, body, accent)
	end
end

local confettiColors = { "#ff5c8a", "#ffd166", "#06d6a0", "#5b7cfa", "#c77dff" }
local function confetti()
	for i = 1, 36 do
		local c = frame(screen, { Position = UDim2.new(math.random(), 0, 0, -20), Size = UDim2.fromOffset(math.random(6, 11), math.random(10, 16)),
			BackgroundColor3 = C(confettiColors[i % #confettiColors + 1]), BackgroundTransparency = 0, Rotation = math.random(0, 360), ZIndex = 80 })
		corner(c, 2)
		local t = 1.4 + math.random() * 1.2
		tween(c, t, { Position = UDim2.new(c.Position.X.Scale + (math.random() - 0.5) * 0.3, 0, 1, 20), Rotation = c.Rotation + math.random(-400, 400) },
			Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(t, function()
			c:Destroy()
		end)
	end
end

-- ================= state =================
local me = { received = 0, sent = 0, passes = {}, saving = true }
local convos = {} -- [userId] = { msgs = { {mine, text, t} }, unread = n, last = time }
local refresh: { [string]: any } = {} -- page refreshers

local function convo(userId)
	local c = convos[userId]
	if not c then
		c = { msgs = {}, unread = 0, last = 0 }
		convos[userId] = c
		nameOf(userId)
	end
	return c
end

local function timeText(t)
	local s = os.date("%I:%M %p", t)
	return (string.gsub(s, "^0", ""))
end

-- ================= LOCK =================
local lock = page("lock", { clear = true })
local lockTime = text(lock, "9:41", 96, Color3.new(1, 1, 1), Enum.Font.BuilderSansExtraBold,
	{ Position = UDim2.fromOffset(0, 120), Size = UDim2.new(1, 0, 0, 110), TextXAlignment = Enum.TextXAlignment.Center })
local lockDate = text(lock, "", 20, Color3.new(1, 1, 1), Enum.Font.BuilderSansBold,
	{ Position = UDim2.fromOffset(0, 92), Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Center })
for _, l in { lockTime, lockDate } do
	l.TextStrokeTransparency = 0.85
end
local hint = text(lock, "Tap to unlock", 16, Color3.new(1, 1, 1), Enum.Font.BuilderSansBold,
	{ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -46), Size = UDim2.fromOffset(200, 24), TextXAlignment = Enum.TextXAlignment.Center })
TweenService:Create(hint, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { TextTransparency = 0.6 }):Play()
button(lock, { Size = UDim2.fromScale(1, 1), ZIndex = 3 }, function()
	goTo("home", "home")
end)

-- ================= HOME =================
local home = page("home", { clear = true, onOpen = function()
	if refresh.home then
		refresh.home()
	end
end })
-- widgets
local clockW = frame(home, { Position = UDim2.fromOffset(20, 70), Size = UDim2.fromOffset(166, 166), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.72 })
corner(clockW, 30)
stroke(clockW, Color3.new(1, 1, 1), 1.5, 0.5)
local wTime = text(clockW, "9:41", 46, Color3.new(1, 1, 1), Enum.Font.BuilderSansExtraBold, { Position = UDim2.fromOffset(18, 40), Size = UDim2.new(1, -36, 0, 54) })
local wDay = text(clockW, "", 15, Color3.new(1, 1, 1), Enum.Font.BuilderSansBold, { Position = UDim2.fromOffset(18, 16), Size = UDim2.new(1, -36, 0, 22) })
local wHello = text(clockW, "Hi, " .. player.DisplayName, 15, Color3.new(1, 1, 1), Enum.Font.BuilderSansBold,
	{ Position = UDim2.fromOffset(18, 112), Size = UDim2.new(1, -36, 0, 36), TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd })
for _, l in { wTime, wDay, wHello } do
	l.TextStrokeTransparency = 0.85
end

local walletW = button(home, { Position = UDim2.fromOffset(204, 70), Size = UDim2.fromOffset(166, 166), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0 })
corner(walletW, 30)
grad(walletW, C("#ffe08a"), C("#f0a500"), 135)
text(walletW, "💰  Received", 15, C("#5a3d00"), nil, { Position = UDim2.fromOffset(18, 16), Size = UDim2.new(1, -36, 0, 22) })
local wReceived = text(walletW, "R$ 0", 36, C("#3a2600"), Enum.Font.BuilderSansExtraBold, { Position = UDim2.fromOffset(18, 48), Size = UDim2.new(1, -36, 0, 44), TextScaled = false })
local wSent = text(walletW, "Sent R$ 0", 14, C("#6b4a00"), Enum.Font.BuilderSansBold, { Position = UDim2.fromOffset(18, 96), Size = UDim2.new(1, -36, 0, 20) })
text(walletW, "Open Wallet ›", 14, C("#3a2600"), nil, { Position = UDim2.fromOffset(18, 128), Size = UDim2.new(1, -36, 0, 20) })

-- app grid
local appIcons = {}
local grid = frame(home, { Position = UDim2.fromOffset(14, 262), Size = UDim2.new(1, -28, 0, 240) })
new("UIGridLayout", { CellSize = UDim2.fromOffset(90, 104), CellPadding = UDim2.fromOffset(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
for i, app in APPS do
	local cell = button(grid, { Name = app.id, LayoutOrder = i }, function()
		goTo(app.id, "app")
	end)
	local icon = frame(cell, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.fromOffset(66, 66),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0 })
	corner(icon, 18)
	grad(icon, C(app.a), C(app.b), 135)
	local shine = frame(icon, { Size = UDim2.new(1, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.82 })
	corner(shine, 18)
	text(icon, app.glyph, 32, Color3.new(1, 1, 1), nil, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center })
	local lbl = text(cell, app.name, 13, Color3.new(1, 1, 1), Enum.Font.BuilderSansBold,
		{ Position = UDim2.fromOffset(0, 74), Size = UDim2.new(1, 0, 0, 18), TextXAlignment = Enum.TextXAlignment.Center })
	lbl.TextStrokeTransparency = 0.8
	local b = frame(icon, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(24, 24),
		BackgroundColor3 = RED, BackgroundTransparency = 0, Visible = false, ZIndex = 3 })
	round(b)
	stroke(b, Color3.new(1, 1, 1), 2, 0)
	local bt = text(b, "", 13, Color3.new(1, 1, 1), nil, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4 })
	appIcons[app.id] = { label = lbl, badge = b, badgeText = bt }
end

-- dock
local dock = frame(home, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -30), Size = UDim2.new(1, -28, 0, 92),
	BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.7 })
corner(dock, 32)
stroke(dock, Color3.new(1, 1, 1), 1.5, 0.55)
local online = text(dock, "", 15, Color3.new(1, 1, 1), Enum.Font.BuilderSansBold,
	{ Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -40, 1, 0), TextXAlignment = Enum.TextXAlignment.Center })
online.TextStrokeTransparency = 0.85

refresh.home = function()
	wReceived.Text = "R$ " .. tostring(me.received)
	wSent.Text = "Sent R$ " .. tostring(me.sent)
	local labelCol = Color3.new(1, 1, 1)
	for _, ic in appIcons do
		ic.label.TextColor3 = labelCol
	end
	local m = appIcons.messages
	m.badge.Visible = unread > 0
	m.badgeText.Text = if unread > 9 then "9+" else tostring(unread)
	online.Text = "🟢  " .. #Players:GetPlayers() .. " players in this server"
end

-- ================= player rows (Contacts / Send) =================
local function others()
	local out = {}
	for _, p in Players:GetPlayers() do
		if p ~= player then
			table.insert(out, p)
		end
	end
	table.sort(out, function(a, b)
		return a.DisplayName:lower() < b.DisplayName:lower()
	end)
	return out
end

local function playerRow(parent, p, order, actions, onTap)
	local row = card(parent, 70, { LayoutOrder = order })
	local hit = button(row, { Size = UDim2.fromScale(1, 1) }, onTap)
	local _ = hit
	avatar(row, p.UserId, 48, { Position = UDim2.fromOffset(12, 11) })
	text(row, p.DisplayName, 17, INK, nil, { Position = UDim2.fromOffset(72, 13), Size = UDim2.new(1, -190, 0, 22), TextTruncate = Enum.TextTruncate.AtEnd })
	text(row, "@" .. p.Name, 13, SOFT, Enum.Font.BuilderSansMedium, { Position = UDim2.fromOffset(72, 36), Size = UDim2.new(1, -190, 0, 18), TextTruncate = Enum.TextTruncate.AtEnd })
	for i, a in actions do
		local b = pill(row, a[1], a[2], Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12 - (i - 1) * 50, 0.5, 0),
			Size = UDim2.fromOffset(42, 42), ZIndex = 3, TextSizeOverride = 18 }, a[3])
		local _ = b
	end
	return row
end

-- ================= MESSAGES (inbox) =================
local msgs = page("messages", { onOpen = function()
	refresh.messages()
end })
header(msgs, "Messages")
pill(msgs, "✎", BLUE, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 60), Size = UDim2.fromOffset(40, 40), ZIndex = 12, TextSizeOverride = 20 }, function()
	goTo("contacts", "push")
end)
local inbox = list(msgs, { Position = UDim2.fromOffset(0, 112), Size = UDim2.new(1, 0, 1, -142) }, 8)

local openChat -- forward
refresh.messages = function()
	clear(inbox)
	local ids = {}
	for id, c in convos do
		if #c.msgs > 0 then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a, b)
		return convos[a].last > convos[b].last
	end)
	if #ids == 0 then
		emptyState(inbox, "💬", "No messages yet.\nTap ✎ to text someone in this server.")
		return
	end
	for i, id in ids do
		local c = convos[id]
		local lastMsg = c.msgs[#c.msgs]
		local row = card(inbox, 76, { LayoutOrder = i })
		button(row, { Size = UDim2.fromScale(1, 1), ZIndex = 3 }, function()
			openChat(id)
		end)
		avatar(row, id, 52, { Position = UDim2.fromOffset(12, 12) })
		text(row, nameOf(id), 17, INK, nil, { Position = UDim2.fromOffset(76, 14), Size = UDim2.new(1, -170, 0, 22), TextTruncate = Enum.TextTruncate.AtEnd })
		text(row, (if lastMsg.mine then "You: " else "") .. lastMsg.text, 14, SOFT, Enum.Font.BuilderSansMedium,
			{ Position = UDim2.fromOffset(76, 40), Size = UDim2.new(1, -110, 0, 20), TextTruncate = Enum.TextTruncate.AtEnd })
		text(row, timeText(c.last), 12, SOFT, Enum.Font.BuilderSansMedium,
			{ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 16), Size = UDim2.fromOffset(80, 18), TextXAlignment = Enum.TextXAlignment.Right })
		if c.unread > 0 then
			local d = frame(row, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 42), Size = UDim2.fromOffset(22, 22), BackgroundColor3 = BLUE, BackgroundTransparency = 0 })
			round(d)
			text(d, tostring(c.unread), 12, Color3.new(1, 1, 1), nil, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center })
		end
		if not Players:GetPlayerByUserId(id) then
			text(row, "left the server", 11, RED, Enum.Font.BuilderSansMedium,
				{ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -40, 0, 44), Size = UDim2.fromOffset(100, 16), TextXAlignment = Enum.TextXAlignment.Right })
		end
	end
end

-- ================= CHAT =================
local chat = page("chat")
local chatHead = frame(chat, { Size = UDim2.new(1, 0, 0, 120), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.15, ZIndex = 10 })
button(chatHead, { Position = UDim2.fromOffset(10, 58), Size = UDim2.fromOffset(44, 50), ZIndex = 12 }, back)
text(chatHead, "‹", 40, BLUE, Enum.Font.BuilderSansBold, { Position = UDim2.fromOffset(18, 54), Size = UDim2.fromOffset(30, 50), ZIndex = 12 })
local chatAvatarHolder = frame(chatHead, { Position = UDim2.fromOffset(58, 60), Size = UDim2.fromOffset(46, 46), ZIndex = 11 })
local chatName = text(chatHead, "", 19, INK, nil, { Position = UDim2.fromOffset(114, 60), Size = UDim2.new(1, -230, 0, 24), ZIndex = 11, TextTruncate = Enum.TextTruncate.AtEnd })
local chatStatus = text(chatHead, "", 13, SOFT, Enum.Font.BuilderSansMedium, { Position = UDim2.fromOffset(114, 84), Size = UDim2.new(1, -230, 0, 18), ZIndex = 11 })
local chatGift = pill(chatHead, "💸", GOLD, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 62), Size = UDim2.fromOffset(42, 42), ZIndex = 12, TextSizeOverride = 18 })
local bubbles = list(chat, { Position = UDim2.fromOffset(0, 124), Size = UDim2.new(1, 0, 1, -224) }, 6)
pad(bubbles, 14, 14, 10, 10)

local inputBar = frame(chat, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -38), Size = UDim2.new(1, -28, 0, 52),
	BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, ZIndex = 10 })
round(inputBar)
stroke(inputBar, C("#dcdbe6"), 1.5, 0)
local box = new("TextBox", { Parent = inputBar, Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -80, 1, 0), BackgroundTransparency = 1,
	Text = "", PlaceholderText = "Message", PlaceholderColor3 = SOFT, TextColor3 = INK, Font = Enum.Font.BuilderSansMedium, TextSize = 17,
	TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 11 })
local sendBtn = pill(inputBar, "↑", BLUE, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(40, 40), ZIndex = 12, TextSizeOverride = 22 })

local chatWith = nil
local chatOrder = 0
local function bubble(m, order)
	local row = frame(bubbles, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order })
	new("UIListLayout", { HorizontalAlignment = if m.mine then Enum.HorizontalAlignment.Right else Enum.HorizontalAlignment.Left, Parent = row })
	local b = new("TextLabel", { Parent = row, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), BackgroundColor3 = if m.mine then BLUE else Color3.new(1, 1, 1),
		BackgroundTransparency = 0, Text = m.text, TextWrapped = true, TextSize = 16, Font = Enum.Font.BuilderSansMedium,
		TextColor3 = if m.mine then Color3.new(1, 1, 1) else INK, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0 })
	new("UISizeConstraint", { MaxSize = Vector2.new(250, math.huge), Parent = b })
	pad(b, 14, 14, 9, 9)
	corner(b, 20)
	if m.mine then
		grad(b, C("#7c97ff"), C("#4f6ff2"), 90)
	end
	if m.failed then
		b.BackgroundTransparency = 0.4
	end
	m.label = b
	return row
end

local function scrollDown()
	task.defer(function()
		bubbles.CanvasPosition = Vector2.new(0, math.max(0, bubbles.AbsoluteCanvasSize.Y - bubbles.AbsoluteWindowSize.Y))
	end)
end

local function renderChat()
	clear(bubbles)
	local c = convo(chatWith)
	for i, m in c.msgs do
		bubble(m, i)
	end
	chatOrder = #c.msgs
	scrollDown()
end

local function addMessage(userId, m)
	local c = convo(userId)
	table.insert(c.msgs, m)
	if #c.msgs > 80 then
		table.remove(c.msgs, 1)
	end
	c.last = m.t
	if current == "chat" and chatWith == userId then
		chatOrder += 1
		bubble(m, chatOrder)
		local lbl = m.label
		local sc = new("UIScale", { Scale = 0.6, Parent = lbl })
		tween(sc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
		scrollDown()
	end
end

openChat = function(userId)
	goTo("chat", "push", userId)
end
pages.chat.onOpen = function(userId)
	if userId then
		chatWith = userId
	end
	local c = convo(chatWith)
	setUnread(unread - c.unread)
	c.unread = 0
	clear(chatAvatarHolder)
	avatar(chatAvatarHolder, chatWith, 46, { ZIndex = 11 })
	chatName.Text = nameOf(chatWith)
	local here = Players:GetPlayerByUserId(chatWith) ~= nil
	chatStatus.Text = if here then "🟢 In this server" else "Left the server"
	chatGift.Visible = here
	renderChat()
end

local sending = false
local function send()
	local str = box.Text
	if sending or not chatWith or not string.match(str, "%S") then
		return
	end
	sending = true
	box.Text = ""
	local m: { [string]: any } = { mine = true, text = str, t = os.time() }
	addMessage(chatWith, m)
	local ok, result = call("Message", chatWith, str)
	if ok then
		m.text = result
		if m.label then
			m.label.Text = result
		end
	else
		m.failed = true
		if m.label then
			m.label.BackgroundTransparency = 0.45
		end
		if result then
			notify(nil, "Not sent", result)
		end
	end
	sending = false
end
sendBtn.Activated:Connect(send)
box.FocusLost:Connect(function(enter)
	if enter then
		send()
	end
end)

-- ================= CONTACTS =================
local contacts = page("contacts", { onOpen = function()
	refresh.contacts()
end })
header(contacts, "Contacts")
local contactList = list(contacts, { Position = UDim2.fromOffset(0, 112), Size = UDim2.new(1, 0, 1, -142) }, 8)
local openSendTo -- forward
refresh.contacts = function()
	clear(contactList)
	local ps = others()
	if #ps == 0 then
		emptyState(contactList, "🫧", "Nobody else is in this server yet.\nInvite your friends!")
		return
	end
	for i, p in ps do
		playerRow(contactList, p, i, {
			{ "💸", GOLD, function()
				openSendTo(p.UserId)
			end },
			{ "💬", BLUE, function()
				openChat(p.UserId)
			end },
		}, function()
			openChat(p.UserId)
		end)
	end
end

-- ================= SEND ROBUX (pick a player) =================
local sendPage = page("send", { onOpen = function()
	refresh.send()
end })
header(sendPage, "Send Robux")
local sendList = list(sendPage, { Position = UDim2.fromOffset(0, 112), Size = UDim2.new(1, 0, 1, -142) }, 8)
refresh.send = function()
	clear(sendList)
	local info = card(sendList, 84, { LayoutOrder = 0 })
	grad(info, C("#fff4cf"), C("#ffe39a"), 135)
	text(info, "Pick a player, then choose an amount.\nYou buy one of their game passes and the Robux goes to them.", 13, C("#5a3d00"),
		Enum.Font.BuilderSansMedium, { Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -32, 1, 0), TextWrapped = true })
	local ps = others()
	if #ps == 0 then
		emptyState(sendList, "🫧", "Nobody else is in this server yet.")
		return
	end
	for i, p in ps do
		playerRow(sendList, p, i, { { "›", GOLD, function()
			openSendTo(p.UserId)
		end } }, function()
			openSendTo(p.UserId)
		end)
	end
end

-- ================= SEND TO (amounts) =================
local sendTo = page("sendTo")
header(sendTo, "", true)
local stAvatarHolder = frame(sendTo, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 104), Size = UDim2.fromOffset(84, 84) })
local stName = text(sendTo, "", 22, INK, Enum.Font.BuilderSansExtraBold, { Position = UDim2.fromOffset(0, 192), Size = UDim2.new(1, 0, 0, 28), TextXAlignment = Enum.TextXAlignment.Center })
local stSub = text(sendTo, "Choose an amount to send", 14, SOFT, Enum.Font.BuilderSansMedium, { Position = UDim2.fromOffset(0, 220), Size = UDim2.new(1, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Center })
local passList = list(sendTo, { Position = UDim2.fromOffset(0, 252), Size = UDim2.new(1, 0, 1, -282) }, 10)
local sendTarget = nil
local loadToken = 0

local function loadPasses()
	clear(passList)
	loadToken += 1
	local token = loadToken
	local spinner = text(passList, "◌", 34, SOFT, nil, { Size = UDim2.new(1, 0, 0, 60), TextXAlignment = Enum.TextXAlignment.Center })
	local spin = TweenService:Create(spinner, TweenInfo.new(0.8, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
	spin:Play()
	local target = sendTarget
	local passes = call("GetPasses", target)
	if token ~= loadToken then
		return
	end
	spin:Cancel()
	clear(passList)
	if type(passes) ~= "table" or #passes == 0 then
		emptyState(passList, "👛", nameOf(target) .. " hasn't added any game passes to their Wallet yet.\nAsk them to open Wallet ➜ Add a pass.")
		pill(passList, "💬  Message them", BLUE, Color3.new(1, 1, 1), { Size = UDim2.fromOffset(200, 46), LayoutOrder = 1000 }, function()
			openChat(target)
		end)
		return
	end
	for i, p in passes do
		local row = card(passList, 74, { LayoutOrder = i })
		local ic = new("ImageLabel", { Parent = row, Position = UDim2.fromOffset(12, 11), Size = UDim2.fromOffset(52, 52), BackgroundColor3 = C("#fff1c7"),
			Image = if p.icon and p.icon > 0 then "rbxassetid://" .. p.icon else "" })
		corner(ic, 14)
		if not (p.icon and p.icon > 0) then
			text(ic, "💛", 26, INK, nil, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center })
		end
		text(row, p.name, 16, INK, nil, { Position = UDim2.fromOffset(76, 14), Size = UDim2.new(1, -200, 0, 22), TextTruncate = Enum.TextTruncate.AtEnd })
		text(row, if p.owned then "You already sent this one" else "Game pass", 13, SOFT, Enum.Font.BuilderSansMedium,
			{ Position = UDim2.fromOffset(76, 38), Size = UDim2.new(1, -200, 0, 18), TextTruncate = Enum.TextTruncate.AtEnd })
		local label = if p.owned then "Sent ✓" else "R$ " .. p.price
		pill(row, label, if p.owned then C("#c9c7d4") else GOLD, Color3.new(1, 1, 1),
			{ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(104, 44) }, function()
				if p.owned then
					return
				end
				local ok, err = call("Gift", target, p.id)
				if not ok and err then
					notify(nil, "Can't send", err)
				end
			end)
	end
end

openSendTo = function(userId)
	goTo("sendTo", "push", userId)
end
pages.sendTo.onOpen = function(userId)
	if userId then
		sendTarget = userId
	end
	clear(stAvatarHolder)
	avatar(stAvatarHolder, sendTarget, 84)
	stName.Text = "Send to " .. nameOf(sendTarget)
	stSub.Text = "Choose an amount"
	task.spawn(loadPasses)
end

-- ================= WALLET =================
local wallet = page("wallet", { onOpen = function()
	refresh.wallet()
end })
header(wallet, "Wallet")
local walletList = list(wallet, { Position = UDim2.fromOffset(0, 112), Size = UDim2.new(1, 0, 1, -142) }, 12)

local balance = card(walletList, 150, { LayoutOrder = 1 })
grad(balance, C("#2b2733"), C("#0f0d13"), 135)
stroke(balance, C("#d8b45a"), 1.5, 0.3)
text(balance, "ROBUX RECEIVED", 12, C("#d8b45a"), nil, { Position = UDim2.fromOffset(20, 18), Size = UDim2.new(1, -40, 0, 16) })
local balReceived = text(balance, "R$ 0", 44, C("#f7e3a5"), Enum.Font.BuilderSansExtraBold, { Position = UDim2.fromOffset(20, 38), Size = UDim2.new(1, -40, 0, 52) })
local balSent = text(balance, "You sent R$ 0", 14, C("#b8ab98"), Enum.Font.BuilderSansMedium, { Position = UDim2.fromOffset(20, 94), Size = UDim2.new(1, -40, 0, 18) })
text(balance, "Roblox keeps its usual cut, and new Robux may show as Pending for a few days.", 11, C("#8e8578"), Enum.Font.BuilderSansMedium,
	{ Position = UDim2.fromOffset(20, 114), Size = UDim2.new(1, -40, 0, 30), TextWrapped = true })

local addCard = card(walletList, 168, { LayoutOrder = 2 })
text(addCard, "Add a game pass", 18, INK, nil, { Position = UDim2.fromOffset(18, 14), Size = UDim2.new(1, -36, 0, 24) })
text(addCard, "Other players buy your passes to send you Robux. Make a few at different prices (each can be bought once per player).", 13, SOFT,
	Enum.Font.BuilderSansMedium, { Position = UDim2.fromOffset(18, 40), Size = UDim2.new(1, -36, 0, 50), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top })
local addBoxBg = frame(addCard, { Position = UDim2.fromOffset(16, 100), Size = UDim2.new(1, -120, 0, 48), BackgroundColor3 = C("#f1f0f6"), BackgroundTransparency = 0 })
corner(addBoxBg, 14)
local addBox = new("TextBox", { Parent = addBoxBg, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -28, 1, 0), BackgroundTransparency = 1, Text = "",
	PlaceholderText = "Paste pass link or ID", PlaceholderColor3 = SOFT, TextColor3 = INK, Font = Enum.Font.BuilderSansMedium, TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ClipsDescendants = true })
local adding = false
pill(addCard, "Add", BLUE, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 100), Size = UDim2.fromOffset(88, 48) }, function()
	if adding then
		return
	end
	adding = true
	local ok, res = call("AddPass", addBox.Text)
	adding = false
	if ok then
		addBox.Text = ""
		me.passes = res
		refresh.wallet()
		confetti()
		notify(nil, "Pass added ✨", "Players can now send you Robux with it.")
	else
		notify(nil, "Couldn't add pass", res or "Try again.")
	end
end)

local passHeader = text(walletList, "MY PASSES", 12, SOFT, nil, { Size = UDim2.new(1, -40, 0, 20), LayoutOrder = 3 })
local passHolder = frame(walletList, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 4 })
new("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = passHolder })

local how = card(walletList, 196, { LayoutOrder = 5 })
text(how, "How to make a game pass", 16, INK, nil, { Position = UDim2.fromOffset(18, 14), Size = UDim2.new(1, -36, 0, 22) })
text(how, "1. Go to create.roblox.com ➜ Creations\n2. Open any experience you own ➜ Monetization ➜ Passes\n3. Create a Pass, then turn on \"Item for Sale\" and set a price\n4. Copy the pass link (or the number in it) and paste it above",
	13, SOFT, Enum.Font.BuilderSansMedium, { Position = UDim2.fromOffset(18, 42), Size = UDim2.new(1, -36, 0, 140), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top })
frame(walletList, { Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 6 })

refresh.wallet = function()
	balReceived.Text = "R$ " .. tostring(me.received)
	balSent.Text = "You sent R$ " .. tostring(me.sent)
	clear(passHolder)
	passHeader.Text = "MY PASSES (" .. #me.passes .. ")"
	if #me.passes == 0 then
		local e = card(passHolder, 60, { LayoutOrder = 1 })
		text(e, "No passes yet. Add one above 👆", 14, SOFT, Enum.Font.BuilderSansMedium, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center })
	end
	for i, p in me.passes do
		local row = card(passHolder, 60, { LayoutOrder = i })
		text(row, p.name, 16, INK, nil, { Position = UDim2.fromOffset(18, 0), Size = UDim2.new(1, -170, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
		local price = frame(row, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -60, 0.5, 0), Size = UDim2.fromOffset(84, 32),
			BackgroundColor3 = C("#fff1c7"), BackgroundTransparency = 0 })
		round(price)
		text(price, "R$ " .. p.price, 14, C("#8a5d00"), nil, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center })
		pill(row, "✕", C("#f1f0f6"), SOFT, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(36, 36), TextSizeOverride = 14 }, function()
			local res = call("RemovePass", p.id)
			if type(res) == "table" then
				me.passes = res
				refresh.wallet()
			end
		end)
	end
end

-- ================= SETTINGS =================
local settings = page("settings")
header(settings, "Settings")
local setList = list(settings, { Position = UDim2.fromOffset(0, 112), Size = UDim2.new(1, 0, 1, -142) }, 12)
text(setList, "WALLPAPER", 12, SOFT, nil, { Size = UDim2.new(1, -40, 0, 20), LayoutOrder = 1 })
local wpCard = card(setList, 236, { LayoutOrder = 2 })
local wpGrid = frame(wpCard, { Position = UDim2.fromOffset(14, 14), Size = UDim2.new(1, -28, 1, -28) })
new("UIGridLayout", { CellSize = UDim2.fromOffset(74, 100), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = wpGrid })
local wpRings = {}
for i, w in WALLPAPERS do
	local b = button(wpGrid, { LayoutOrder = i, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0 }, function()
		setWallpaper(i)
		for j, r in wpRings do
			r.Transparency = if j == i then 0 else 1
		end
		call("Wallpaper", i)
	end)
	corner(b, 16)
	new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C(w[2])), ColorSequenceKeypoint.new(0.55, C(w[3])), ColorSequenceKeypoint.new(1, C(w[4])) }),
		Rotation = 125, Parent = b })
	wpRings[i] = stroke(b, BLUE, 3, 1)
end
text(setList, "PHONE", 12, SOFT, nil, { Size = UDim2.new(1, -40, 0, 20), LayoutOrder = 3 })
local soundCard = card(setList, 60, { LayoutOrder = 4 })
text(soundCard, "🔔  Notification sounds", 16, INK, nil, { Position = UDim2.fromOffset(18, 0), Size = UDim2.new(1, -110, 1, 0) })
local sw = button(soundCard, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(54, 32), BackgroundColor3 = C("#34c759"), BackgroundTransparency = 0 })
round(sw)
local knob = frame(sw, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, -30, 0.5, 0), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0 })
round(knob)
sw.Activated:Connect(function()
	soundOn = not soundOn
	tween(knob, 0.25, { Position = if soundOn then UDim2.new(1, -30, 0.5, 0) else UDim2.new(0, 2, 0.5, 0) })
	tween(sw, 0.25, { BackgroundColor3 = if soundOn then C("#34c759") else C("#d4d3dc") })
end)
local keyCard = card(setList, 60, { LayoutOrder = 5 })
text(keyCard, "⌨️  Open / close phone", 16, INK, nil, { Position = UDim2.fromOffset(18, 0), Size = UDim2.new(1, -110, 1, 0) })
text(keyCard, OPEN_KEY.Name, 16, SOFT, nil, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 0), Size = UDim2.fromOffset(80, 60), TextXAlignment = Enum.TextXAlignment.Right })
local saveCard = card(setList, 60, { LayoutOrder = 6 })
local saveText = text(saveCard, "💾  Saving: on", 16, INK, nil, { Position = UDim2.fromOffset(18, 0), Size = UDim2.new(1, -36, 1, 0) })

-- ================= open / close =================
local closedAt = -math.huge
local function fit()
	local cam = workspace.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	local s = math.min((vp.Y - 24) / (H + 20), (vp.X - 100) / (W + 20), 1)
	scale.Scale = math.max(s, 0.3)
	return scale.Scale
end
local function openX()
	return UDim2.new(1, -82, 0.5, 0)
end
local function closedX()
	return UDim2.new(1, (W + 20) * scale.Scale + 40, 0.5, 0)
end

local function setOpen(on)
	if on == isOpen then
		return
	end
	isOpen = on
	fit()
	if on then
		phone.Visible = true
		phone.Position = closedX()
		phone.Rotation = 8
		tween(phone, 0.55, { Position = openX(), Rotation = 0 }, Enum.EasingStyle.Back)
		badge.Visible = false
		if os.clock() - closedAt > 30 or not current then
			table.clear(history)
			for name, pg in pages do
				pg.frame.Visible = name == "lock"
				pg.frame.Position = UDim2.new()
				pg.frame.GroupTransparency = 0
				pg.scale.Scale = 1
			end
			current = "lock"
			statusColor(false)
		elseif pages[current] and pages[current].onOpen and current ~= "chat" and current ~= "sendTo" then
			pages[current].onOpen()
		end
		if refresh.home then
			refresh.home()
		end
	else
		closedAt = os.clock()
		box:ReleaseFocus()
		addBox:ReleaseFocus()
		local tw = tween(phone, 0.35, { Position = closedX(), Rotation = 6 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tw.Completed:Connect(function()
			if not isOpen then
				phone.Visible = false
			end
		end)
		setUnread(unread)
	end
end
toggle.Activated:Connect(function()
	setOpen(not isOpen)
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or UserInputService:GetFocusedTextBox() then
		return
	end
	if input.KeyCode == OPEN_KEY then
		setOpen(not isOpen)
	end
end)
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		fit()
		if isOpen then
			phone.Position = openX()
		end
	end)
end

-- clock
task.spawn(function()
	while true do
		local t = timeText(os.time())
		local short = string.gsub(t, " [AP]M$", "")
		clockLabel.Text = short
		lockTime.Text = short
		wTime.Text = short
		local day = os.date("%A, %B ", os.time()) .. tostring(tonumber(os.date("%d", os.time())))
		lockDate.Text = day
		wDay.Text = os.date("%A", os.time())
		task.wait(5)
	end
end)

-- ================= server events =================
Event.OnClientEvent:Connect(function(kind, a, b, c)
	if kind == "Message" then
		local fromId, str = a, b
		local m: { [string]: any } = { mine = false, text = str, t = os.time() }
		addMessage(fromId, m)
		local cv = convo(fromId)
		local reading = isOpen and current == "chat" and chatWith == fromId
		if not reading then
			cv.unread += 1
			setUnread(unread + 1)
			notify(fromId, nameOf(fromId), str, function()
				openChat(fromId)
			end)
		end
		if current == "messages" then
			refresh.messages()
		end
		if refresh.home then
			refresh.home()
		end
	elseif kind == "Received" then
		me.received += b
		refresh.home()
		refresh.wallet()
		notify(a, "You got R$ " .. b .. "! 💖", nameOf(a) .. " sent you Robux", nil, GOLD)
		if isOpen then
			confetti()
		end
	elseif kind == "Sent" then
		me.sent += b
		refresh.home()
		refresh.wallet()
		notify(a, "Sent R$ " .. b .. " 💸", "to " .. nameOf(a) .. ". So kind!", nil, GOLD)
		if isOpen then
			confetti()
		end
		if current == "sendTo" then
			task.spawn(loadPasses)
		end
	elseif kind == "Shoutout" and SHOW_SHOUTOUTS then
		if a ~= player.UserId and b ~= player.UserId then
			toast(a, nameOf(a) .. " ➜ " .. nameOf(b), "sent R$ " .. c .. " 💛", GOLD)
		end
	end
end)

Players.PlayerAdded:Connect(function(p)
	names[p.UserId] = p.DisplayName
	if isOpen and refresh[current] then
		refresh[current]()
	end
end)
Players.PlayerRemoving:Connect(function(p)
	names[p.UserId] = p.DisplayName
	task.defer(function()
		if isOpen and refresh[current] then
			refresh[current]()
		end
		if current == "chat" and chatWith == p.UserId then
			chatStatus.Text = "Left the server"
			chatGift.Visible = false
		end
	end)
end)

chatGift.Activated:Connect(function()
	if chatWith then
		openSendTo(chatWith)
	end
end)

-- ================= start =================
setWallpaper(1)
current = "lock"
pages.lock.frame.Visible = true
statusColor(false)
task.spawn(function()
	local data = call("GetMe")
	if type(data) == "table" then
		me.received = data.received or 0
		me.sent = data.sent or 0
		me.passes = data.passes or {}
		me.saving = data.saving
		setWallpaper(data.wallpaper or 1)
		for j, r in wpRings do
			r.Transparency = if j == wallIndex then 0 else 1
		end
		saveText.Text = if data.saving then "💾  Saving: on" else "💾  Saving: off (turn on API access)"
		refresh.home()
		refresh.wallet()
	end
end)
