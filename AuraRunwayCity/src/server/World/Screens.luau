--!nonstrict
-- SurfaceGui "LED screen" art: synthwave galaxy, retro sun and city skyline.
local Screens = {}

local function frame(parent, props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	for k, v in props do
		f[k] = v
	end
	f.Parent = parent
	return f
end

local function corner(p, scale)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(scale or 0.5, 0)
	c.Parent = p
end

local function grad(p, colors, rot, transp)
	local g = Instance.new("UIGradient")
	local kps = {}
	for i, c in colors do
		table.insert(kps, ColorSequenceKeypoint.new((i - 1) / math.max(#colors - 1, 1), c))
	end
	g.Color = ColorSequence.new(kps)
	g.Rotation = rot or 0
	if transp then
		g.Transparency = transp
	end
	g.Parent = p
	return g
end

local hex = Color3.fromHex

-- opts: { Seed, Title, Subtitle, Sun = bool, Skyline = bool, Vertical = bool }
function Screens.galaxy(gui: SurfaceGui, B, opts)
	opts = opts or {}
	local r = B.rng(opts.Seed or 7)
	local root = frame(gui, { Name = "Galaxy", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), ClipsDescendants = true })
	local g = grad(root, { hex("120B2E"), hex("2A1558"), hex("5B2A8C"), hex("B24F9F"), hex("F39AB8") }, 90)
	g:AddTag("LEDGradient")

	-- nebula clouds
	local neb = { hex("FF8BCB"), hex("A88CFF"), hex("86DBFF"), hex("FFB3E1"), hex("C9A2FF") }
	for i = 1, 6 do
		local s = r.range(0.35, 0.8)
		local n = frame(root, {
			Name = "Nebula",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(r.range(0.05, 0.95), r.range(0.05, 0.6)),
			Size = UDim2.fromScale(s, s * 0.55),
			BackgroundColor3 = neb[(i - 1) % #neb + 1],
			BackgroundTransparency = 0.55,
			Rotation = r.range(-30, 30),
		})
		corner(n)
		grad(n, { Color3.new(1, 1, 1), Color3.new(1, 1, 1) }, 0, NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.35),
			NumberSequenceKeypoint.new(1, 1),
		}))
	end

	-- stars
	local stars = frame(root, { Name = "Stars", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	stars:AddTag("LEDStars")
	for _ = 1, 55 do
		local px = r.int(2, 5)
		local st = frame(stars, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(r.next(), r.range(0, opts.Skyline == false and 1 or 0.72)),
			Size = UDim2.fromOffset(px, px),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = r.range(0, 0.5),
		})
		corner(st)
	end

	local horizon = opts.Vertical and 0.78 or 0.72

	if opts.Sun ~= false then
		local sunSize = opts.Vertical and 0.55 or 0.46
		local sun = Instance.new("CanvasGroup")
		sun.Name = "Sun"
		sun.AnchorPoint = Vector2.new(0.5, 1)
		sun.Position = UDim2.fromScale(0.5, horizon + 0.02)
		sun.Size = UDim2.fromScale(sunSize, sunSize)
		sun.BackgroundColor3 = Color3.new(1, 1, 1)
		sun.BorderSizePixel = 0
		sun.SizeConstraint = opts.Vertical and Enum.SizeConstraint.RelativeXX or Enum.SizeConstraint.RelativeYY
		sun.Parent = root
		sun:AddTag("LEDSun")
		corner(sun)
		grad(sun, { hex("FFE39A"), hex("FFB27A"), hex("FF7FB8"), hex("C659C9") }, 90)
		for i = 1, 6 do
			local t = 0.02 + i * 0.012
			frame(sun, {
				Name = "Stripe",
				Position = UDim2.fromScale(0, 0.5 + i * 0.075),
				Size = UDim2.fromScale(1, t),
				BackgroundColor3 = hex("3A1A6A"),
			})
		end
	end

	if opts.Skyline ~= false then
		local sky = frame(root, { Name = "Skyline", Size = UDim2.fromScale(1, 1 - horizon + 0.12), Position = UDim2.fromScale(0, horizon - 0.12), BackgroundTransparency = 1 })
		local x = 0
		local winColors = { hex("FF8BCB"), hex("86DBFF"), hex("FFD27A"), hex("C9A2FF") }
		while x < 1 do
			local w = r.range(0.03, 0.08)
			local h = r.range(0.25, 0.95)
			local bld = frame(sky, {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(x, 1),
				Size = UDim2.fromScale(w, h),
				BackgroundColor3 = hex("1B1036"),
			})
			for _ = 1, r.int(1, 4) do
				frame(bld, {
					Position = UDim2.fromScale(r.range(0.15, 0.7), r.range(0.1, 0.8)),
					Size = UDim2.fromScale(0.16, 0.05),
					BackgroundColor3 = r.pick(winColors),
					BackgroundTransparency = 0.1,
				})
			end
			x += w + r.range(0, 0.012)
		end
		-- synthwave floor
		local floor = frame(root, {
			Name = "Floor",
			Position = UDim2.fromScale(0, horizon),
			Size = UDim2.fromScale(1, 1 - horizon),
			BackgroundColor3 = hex("1A0E35"),
			ClipsDescendants = true,
		})
		frame(floor, { Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = hex("FF8BCB") })
		for i = 1, 5 do
			local y = (i / 5.5) ^ 1.6
			frame(floor, {
				Position = UDim2.fromScale(0, y),
				Size = UDim2.new(1, 0, 0, 2),
				BackgroundColor3 = hex("FF8BCB"),
				BackgroundTransparency = 0.35,
			})
		end
		for i = -5, 5 do
			frame(floor, {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5 + i * 0.03, 0),
				Size = UDim2.new(0, 2, 3, 0),
				Rotation = -i * 11,
				BackgroundColor3 = hex("C98BFF"),
				BackgroundTransparency = 0.4,
			})
		end
	end

	if opts.Title then
		local title = B.text(root, opts.Title, {
			Name = "Title",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, opts.Vertical and 0.08 or 0.07),
			Size = UDim2.fromScale(0.9, opts.Vertical and 0.12 or 0.22),
			FontFace = B.Fonts.Luxe(),
			TextColor3 = hex("FFF3FA"),
			ZIndex = 5,
		})
		local st = Instance.new("UIStroke")
		st.Color = hex("FF8BCB")
		st.Thickness = 3
		st.Transparency = 0.2
		st.Parent = title
		title:AddTag("LEDTitle")
	end
	if opts.Subtitle then
		B.text(root, opts.Subtitle, {
			Name = "Subtitle",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, opts.Vertical and 0.21 or 0.29),
			Size = UDim2.fromScale(0.7, opts.Vertical and 0.05 or 0.08),
			FontFace = B.Fonts.Bold(),
			TextColor3 = hex("E9DDFF"),
			ZIndex = 5,
		})
	end
	return root
end

-- Simple elegant sign: gradient plate + luxe text
function Screens.sign(gui: SurfaceGui, B, text: string, opts)
	opts = opts or {}
	local root = frame(gui, { Name = "Sign", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1) })
	grad(root, opts.Colors or { hex("2B1D3F"), hex("3F2C5A") }, opts.Rotation or 90)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.05, 0)
	pad.PaddingRight = UDim.new(0.05, 0)
	pad.PaddingTop = UDim.new(0.12, 0)
	pad.PaddingBottom = UDim.new(0.12, 0)
	pad.Parent = root
	local label = B.text(root, text, {
		Name = "Text",
		FontFace = opts.Font or B.Fonts.Luxe(),
		TextColor3 = opts.TextColor or hex("F1DDB8"),
	})
	if opts.Stroke ~= false then
		local st = Instance.new("UIStroke")
		st.Color = opts.StrokeColor or hex("E2A792")
		st.Thickness = opts.StrokeThickness or 1.5
		st.Transparency = 0.35
		st.Parent = label
	end
	return root, label
end

return Screens
