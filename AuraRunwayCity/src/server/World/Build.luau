--!nonstrict
-- Geometry toolkit used by every world module.
-- Everything is made from Roblox parts: rounded/bevelled boxes are built from
-- boxes + cylinder edges + ball corners so nothing looks blocky.
-- Only uses plain Instance/datatype APIs, so it also runs in Lune (for baking).

local B = {}

local SMOOTH = Enum.Material.SmoothPlastic

local function clone(opts)
	local t = {}
	if opts then
		for k, v in opts do
			t[k] = v
		end
	end
	return t
end

-- Deterministic random (the same city every time)
function B.rng(seed: number)
	local state = seed % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	local r = {}
	function r.next(): number
		state = (state * 16807) % 2147483647
		return (state - 1) / 2147483646
	end
	function r.range(a: number, b: number): number
		return a + (b - a) * r.next()
	end
	function r.int(a: number, b: number): number
		return math.floor(a + (b - a + 1) * r.next())
	end
	function r.pick(t)
		return t[r.int(1, #t)]
	end
	return r
end

local partCount = 0
function B.count(): number
	return partCount
end

local yielder = nil
function B.setYield(fn)
	yielder = fn
end

local function tick()
	partCount += 1
	if yielder and partCount % 800 == 0 then
		yielder()
	end
end

function B.folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function B.model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

function B.tag(inst: Instance, tagName: string)
	inst:AddTag(tagName)
	return inst
end

-- Generic part. opts: Material, Transparency, Reflectance, CanCollide, CastShadow, Name, Class, Shape
function B.part(parent: Instance, cf: CFrame, size: Vector3, color: Color3, opts)
	opts = opts or {}
	local p = Instance.new(opts.Class or "Part")
	p.Anchored = true
	if opts.Shape then
		p.Shape = opts.Shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = opts.Material or SMOOTH
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if opts.Transparency then
		p.Transparency = opts.Transparency
	end
	if opts.Reflectance then
		p.Reflectance = opts.Reflectance
	end
	if opts.CanCollide == false then
		p.CanCollide = false
	end
	if opts.CastShadow == false then
		p.CastShadow = false
	end
	if opts.CanQuery == false then
		p.CanQuery = false
	end
	p.Name = opts.Name or "Part"
	p.Parent = parent
	tick()
	return p
end

function B.box(parent, cf, size, color, opts)
	return B.part(parent, cf, size, color, opts)
end

-- Cylinder whose axis is the CFrame's X axis
function B.cyl(parent, cf: CFrame, length: number, diameter: number, color: Color3, opts)
	opts = clone(opts)
	opts.Shape = Enum.PartType.Cylinder
	return B.part(parent, cf, Vector3.new(length, diameter, diameter), color, opts)
end

-- Vertical cylinder centred at pos
function B.vcyl(parent, pos: Vector3, height: number, diameter: number, color: Color3, opts)
	return B.cyl(parent, CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2), height, diameter, color, opts)
end

-- Cylinder facing along a CFrame's look direction (a disc/porthole on a wall)
function B.disc(parent, cf: CFrame, thickness: number, diameter: number, color: Color3, opts)
	return B.cyl(parent, cf * CFrame.Angles(0, math.pi / 2, 0), thickness, diameter, color, opts)
end

function B.ball(parent, pos: Vector3, diameter: number, color: Color3, opts)
	opts = clone(opts)
	opts.Shape = Enum.PartType.Ball
	return B.part(parent, CFrame.new(pos), Vector3.new(diameter, diameter, diameter), color, opts)
end

function B.wedge(parent, cf, size, color, opts)
	opts = clone(opts)
	opts.Class = "WedgePart"
	return B.part(parent, cf, size, color, opts)
end

-- Rod (cylinder) between two points
function B.rod(parent, a: Vector3, b: Vector3, diameter: number, color: Color3, opts)
	local d = b - a
	local len = d.Magnitude
	if len < 0.05 then
		return nil
	end
	local mid = (a + b) / 2
	local cf
	local u = d.Unit
	if math.abs(u.Y) > 0.999 then
		cf = CFrame.new(mid) * CFrame.Angles(0, 0, math.pi / 2)
	else
		cf = CFrame.lookAt(mid, b) * CFrame.Angles(0, math.pi / 2, 0)
	end
	return B.cyl(parent, cf, len, diameter, color, opts)
end

-- Beam-like box between two points
function B.beam(parent, a: Vector3, b: Vector3, w: number, h: number, color: Color3, opts)
	local d = b - a
	local len = d.Magnitude
	if len < 0.05 then
		return nil
	end
	local up = Vector3.new(0, 1, 0)
	if math.abs(d.Unit.Y) > 0.999 then
		up = Vector3.new(1, 0, 0)
	end
	local cf = CFrame.lookAt((a + b) / 2, b, up)
	return B.part(parent, cf, Vector3.new(w, h, len), color, opts)
end


-- Fully rounded box (all 12 edges and 8 corners). Returns the core part.
function B.rounded(parent, cf: CFrame, size: Vector3, r: number, color: Color3, opts)
	local minHalf = math.min(size.X, size.Y, size.Z) / 2
	r = math.min(r, minHalf - 0.02)
	if r < 0.08 then
		return B.part(parent, cf, size, color, opts)
	end
	local x, y, z = size.X, size.Y, size.Z
	local ix, iy, iz = x - 2 * r, y - 2 * r, z - 2 * r
	local core
	local function b(sz, off)
		if sz.X > 0.05 and sz.Y > 0.05 and sz.Z > 0.05 then
			local p = B.part(parent, cf * CFrame.new(off), sz, color, clone(opts))
			core = core or p
		end
	end
	b(Vector3.new(x, iy, iz), Vector3.zero)
	b(Vector3.new(ix, y, iz), Vector3.zero)
	b(Vector3.new(ix, iy, z), Vector3.zero)
	local d = 2 * r
	local ex, ey, ez = x / 2 - r, y / 2 - r, z / 2 - r
	for _, sy in { -1, 1 } do
		for _, sz in { -1, 1 } do
			if ix > 0.05 then
				B.cyl(parent, cf * CFrame.new(0, sy * ey, sz * ez), ix, d, color, clone(opts))
			end
		end
	end
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			if iy > 0.05 then
				B.cyl(parent, cf * CFrame.new(sx * ex, 0, sz * ez) * CFrame.Angles(0, 0, math.pi / 2), iy, d, color, clone(opts))
			end
		end
	end
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			if iz > 0.05 then
				B.cyl(parent, cf * CFrame.new(sx * ex, sy * ey, 0) * CFrame.Angles(0, math.pi / 2, 0), iz, d, color, clone(opts))
			end
		end
	end
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local o = clone(opts)
				o.Shape = Enum.PartType.Ball
				B.part(parent, cf * CFrame.new(sx * ex, sy * ey, sz * ez), Vector3.new(d, d, d), color, o)
			end
		end
	end
	return core
end

-- Box with only its 4 vertical edges rounded (cheaper; great for walls, counters, towers)
function B.soft(parent, cf: CFrame, size: Vector3, r: number, color: Color3, opts)
	r = math.min(r, math.min(size.X, size.Z) / 2 - 0.02)
	if r < 0.08 then
		return B.part(parent, cf, size, color, opts)
	end
	local core = B.part(parent, cf, Vector3.new(size.X, size.Y, size.Z - 2 * r), color, clone(opts))
	B.part(parent, cf, Vector3.new(size.X - 2 * r, size.Y, size.Z), color, clone(opts))
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			B.cyl(
				parent,
				cf * CFrame.new(sx * (size.X / 2 - r), 0, sz * (size.Z / 2 - r)) * CFrame.Angles(0, 0, math.pi / 2),
				size.Y,
				2 * r,
				color,
				clone(opts)
			)
		end
	end
	return core
end

-- Box with its top 4 edges rounded + vertical edges rounded (cushions, counters)
function B.cushion(parent, cf: CFrame, size: Vector3, r: number, color: Color3, opts)
	r = math.min(r, size.Y / 2 - 0.02, math.min(size.X, size.Z) / 2 - 0.02)
	if r < 0.08 then
		return B.part(parent, cf, size, color, opts)
	end
	-- lower body
	local lower = size.Y - r
	local core = B.soft(parent, cf * CFrame.new(0, -r / 2, 0), Vector3.new(size.X, lower, size.Z), r, color, clone(opts))
	-- top slab (inset)
	B.part(parent, cf * CFrame.new(0, size.Y / 2 - r / 2, 0), Vector3.new(size.X - 2 * r, r, size.Z - 2 * r), color, clone(opts))
	local topY = size.Y / 2 - r
	local ex, ez = size.X / 2 - r, size.Z / 2 - r
	for _, sz in { -1, 1 } do
		B.cyl(parent, cf * CFrame.new(0, topY, sz * ez), size.X - 2 * r, 2 * r, color, clone(opts))
	end
	for _, sx in { -1, 1 } do
		B.cyl(parent, cf * CFrame.new(sx * ex, topY, 0) * CFrame.Angles(0, math.pi / 2, 0), size.Z - 2 * r, 2 * r, color, clone(opts))
	end
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local o = clone(opts)
			o.Shape = Enum.PartType.Ball
			B.part(parent, cf * CFrame.new(sx * ex, topY, sz * ez), Vector3.new(2 * r, 2 * r, 2 * r), color, o)
		end
	end
	return core
end

-- Rectangular frame/ring of 4 bars around a centre (roof trims, borders)
function B.ring(parent, cf: CFrame, w: number, d: number, bar: number, h: number, color: Color3, opts)
	for _, sz in { -1, 1 } do
		B.part(parent, cf * CFrame.new(0, 0, sz * (d / 2 - bar / 2)), Vector3.new(w, h, bar), color, clone(opts))
	end
	for _, sx in { -1, 1 } do
		B.part(parent, cf * CFrame.new(sx * (w / 2 - bar / 2), 0, 0), Vector3.new(bar, h, d - 2 * bar), color, clone(opts))
	end
end

-- Pill: horizontal box with round ends along its X axis
function B.pill(parent, cf: CFrame, length: number, height: number, depth: number, color: Color3, opts)
	local r = math.min(height, depth) / 2
	local inner = math.max(length - 2 * r, 0.05)
	local core = B.part(parent, cf, Vector3.new(inner, height, depth), color, clone(opts))
	for _, s in { -1, 1 } do
		B.cyl(parent, cf * CFrame.new(s * inner / 2, 0, 0) * CFrame.Angles(0, 0, math.pi / 2), height, depth, color, clone(opts))
	end
	return core
end

function B.neon(parent, cf: CFrame, size: Vector3, color: Color3, opts)
	opts = clone(opts)
	opts.Material = Enum.Material.Neon
	opts.CastShadow = false
	return B.part(parent, cf, size, color, opts)
end

-- Neon line between two points (square cross-section)
function B.neonLine(parent, a: Vector3, b: Vector3, thickness: number, color: Color3)
	return B.beam(parent, a, b, thickness, thickness, color, { Material = Enum.Material.Neon, CastShadow = false, CanCollide = false })
end

function B.light(part: Instance, class: string, props)
	local l = Instance.new(class)
	for k, v in props or {} do
		l[k] = v
	end
	l.Parent = part
	return l
end

function B.prompt(part: Instance, actionText: string, objectText: string, opts)
	opts = opts or {}
	local p = Instance.new("ProximityPrompt")
	p.ActionText = actionText
	p.ObjectText = objectText or ""
	p.HoldDuration = opts.Hold or 0
	p.MaxActivationDistance = opts.Distance or 9
	p.RequiresLineOfSight = false
	p.KeyboardKeyCode = opts.Key or Enum.KeyCode.E
	p.Style = Enum.ProximityPromptStyle.Default
	if opts.Name then
		p.Name = opts.Name
	end
	p.Parent = part
	return p
end

function B.seat(parent, cf: CFrame, size: Vector3, color: Color3, opts)
	opts = clone(opts)
	opts.Class = "Seat"
	opts.Name = opts.Name or "Seat"
	opts.Material = opts.Material or Enum.Material.Fabric
	return B.part(parent, cf, size, color, opts)
end

function B.gui(part: BasePart, face: Enum.NormalId, pixelsPerStud: number, opts)
	opts = opts or {}
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = pixelsPerStud or 20
	g.LightInfluence = opts.LightInfluence or 0
	if opts.Brightness then
		g.Brightness = opts.Brightness
	end
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = part
	return g
end

function B.font(enumFont, weight)
	local f = Font.fromEnum(enumFont)
	if weight then
		f = Font.new(f.Family, weight)
	end
	return f
end

B.Fonts = {
	Luxe = function()
		return Font.fromEnum(Enum.Font.Bodoni)
	end,
	Bold = function()
		return Font.fromEnum(Enum.Font.GothamBold)
	end,
	Black = function()
		return Font.fromEnum(Enum.Font.GothamBlack)
	end,
	Body = function()
		return Font.fromEnum(Enum.Font.GothamMedium)
	end,
}

function B.frame(parent, props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	for k, v in props or {} do
		f[k] = v
	end
	f.Parent = parent
	return f
end

function B.corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or UDim.new(0, 8)
	c.Parent = parent
	return c
end

function B.gradient(parent, colors, rotation)
	local g = Instance.new("UIGradient")
	local kps = {}
	for i, c in colors do
		table.insert(kps, ColorSequenceKeypoint.new((i - 1) / math.max(#colors - 1, 1), c))
	end
	g.Color = ColorSequence.new(kps)
	g.Rotation = rotation or 0
	g.Parent = parent
	return g
end

function B.text(parent, text: string, props)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.BorderSizePixel = 0
	t.Text = text
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.FontFace = B.Fonts.Bold()
	t.Size = UDim2.fromScale(1, 1)
	for k, v in props or {} do
		t[k] = v
	end
	t.Parent = parent
	return t
end

function B.billboard(part: Instance, text: string, props)
	props = props or {}
	local bb = Instance.new("BillboardGui")
	bb.Size = props.Size or UDim2.fromOffset(220, 50)
	bb.StudsOffset = props.Offset or Vector3.new(0, 4, 0)
	bb.MaxDistance = props.MaxDistance or 80
	bb.LightInfluence = 0
	bb.AlwaysOnTop = props.AlwaysOnTop or false
	bb.Parent = part
	local t = B.text(bb, text, {
		TextColor3 = props.Color or Color3.new(1, 1, 1),
		FontFace = props.Font or B.Fonts.Bold(),
		TextStrokeTransparency = 0.6,
		Name = "Label",
	})
	return bb, t
end

-- Square box-truss between two points (like concert rigging)
function B.truss(parent, a: Vector3, b: Vector3, width: number, color: Color3, step: number?)
	local d = b - a
	local len = d.Magnitude
	local up = Vector3.new(0, 1, 0)
	if math.abs(d.Unit.Y) > 0.999 then
		up = Vector3.new(0, 0, 1)
	end
	local cf = CFrame.lookAt(a, b, up)
	local h = width / 2
	local opts = { Material = Enum.Material.Metal, CastShadow = false }
	local corners = { Vector3.new(-h, -h, 0), Vector3.new(h, -h, 0), Vector3.new(h, h, 0), Vector3.new(-h, h, 0) }
	for _, c in corners do
		B.rod(parent, (cf * CFrame.new(c)).Position, (cf * CFrame.new(c + Vector3.new(0, 0, -len))).Position, 0.34, color, clone(opts))
	end
	step = step or width * 1.4
	local n = math.max(1, math.floor(len / step))
	local seg = len / n
	for i = 0, n - 1 do
		local z0, z1 = -i * seg, -(i + 1) * seg
		for f = 1, 4 do
			local c1, c2 = corners[f], corners[(f % 4) + 1]
			local p0 = (cf * CFrame.new(c1 + Vector3.new(0, 0, z0))).Position
			local p1 = (cf * CFrame.new(c2 + Vector3.new(0, 0, z1))).Position
			if i % 2 == 1 then
				p0 = (cf * CFrame.new(c2 + Vector3.new(0, 0, z0))).Position
				p1 = (cf * CFrame.new(c1 + Vector3.new(0, 0, z1))).Position
			end
			B.rod(parent, p0, p1, 0.16, color, clone(opts))
		end
	end
end

-- Wall along a->b (on the ground at a.Y) with rectangular openings.
-- openings = { {at = distance from a, width = w, height = h, bottom = 0} }
function B.wall(parent, a: Vector3, b: Vector3, height: number, thickness: number, color: Color3, openings, opts)
	local d = b - a
	local len = d.Magnitude
	local dir = d.Unit
	local cf = CFrame.lookAt(a, b)
	openings = openings or {}
	table.sort(openings, function(x, y)
		return x.at < y.at
	end)
	local cursor = 0
	local function seg(z0, z1, y0, y1)
		if z1 - z0 > 0.05 and y1 - y0 > 0.05 then
			local mid = (z0 + z1) / 2
			B.part(parent, cf * CFrame.new(0, (y0 + y1) / 2, -mid), Vector3.new(thickness, y1 - y0, z1 - z0), color, clone(opts))
		end
	end
	for _, o in openings do
		local s = o.at - o.width / 2
		local e = o.at + o.width / 2
		seg(cursor, s, 0, height)
		seg(s, e, (o.bottom or 0) + o.height, height)
		if o.bottom and o.bottom > 0 then
			seg(s, e, 0, o.bottom)
		end
		cursor = e
	end
	seg(cursor, len, 0, height)
	return cf, dir, len
end

-- A tree with a round, soft canopy
function B.tree(parent, pos: Vector3, scale: number, leafColor: Color3, trunkColor: Color3, r)
	scale = scale or 1
	local m = parent
	local h = 8 * scale
	B.vcyl(m, pos + Vector3.new(0, h / 2, 0), h, 1.1 * scale, trunkColor, { Material = Enum.Material.Wood })
	local leafOpts = { Material = Enum.Material.Grass, CastShadow = true }
	local top = pos + Vector3.new(0, h, 0)
	local o1 = r and r.range(-0.8, 0.8) or 0.5
	local o2 = r and r.range(-0.8, 0.8) or -0.5
	B.ball(m, top + Vector3.new(0, 1.5 * scale, 0), 7.5 * scale, leafColor, clone(leafOpts))
	B.ball(m, top + Vector3.new(2.2 * scale, 0.2 * scale, o1 * scale), 5.2 * scale, leafColor:Lerp(Color3.new(1, 1, 1), 0.08), clone(leafOpts))
	B.ball(m, top + Vector3.new(-2 * scale, 0.5 * scale, o2 * scale), 5.6 * scale, leafColor:Lerp(Color3.new(0, 0, 0), 0.06), clone(leafOpts))
	B.ball(m, top + Vector3.new(o2 * scale, 3.6 * scale, o1 * scale), 4.6 * scale, leafColor:Lerp(Color3.new(1, 1, 1), 0.12), clone(leafOpts))
end

return B
