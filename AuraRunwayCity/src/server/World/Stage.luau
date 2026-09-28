--!nonstrict
-- Concert-style runway stage (galaxy LED walls, truss rigging, speaker stacks)
-- with a long rounded catwalk, tiered velvet seating on 3 sides, backstage
-- lounge, winners' podium and the auction block.
local Stage = {}

local GY = 0.5 -- ground top
local SY = 5.5 -- stage / runway top
Stage.GY = GY
Stage.SY = SY
Stage.RunwayEndZ = 48

function Stage.chair(B, P, parent, cf: CFrame, cushion: Color3)
	local m = B.model(parent, "Chair")
	local gold = { Material = Enum.Material.Metal }
	B.vcyl(m, (cf * CFrame.new(0, 0.6, 0)).Position, 1.2, 1.1, P.Gold, gold)
	B.part(m, cf * CFrame.new(0, 1.15, 0), Vector3.new(2.4, 0.2, 2.2), P.Gold, gold)
	local seat = B.seat(m, cf * CFrame.new(0, 1.6, 0.05), Vector3.new(2.8, 0.7, 2.5), cushion)
	B.cyl(m, cf * CFrame.new(0, 1.6, -1.2), 2.8, 0.7, cushion, { Material = Enum.Material.Fabric })
	B.soft(m, cf * CFrame.new(0, 3.35, 1.35) * CFrame.Angles(math.rad(-8), 0, 0), Vector3.new(2.8, 3.1, 0.6), 0.28, cushion, { Material = Enum.Material.Fabric })
	for _, s in { -1, 1 } do
		B.part(m, cf * CFrame.new(s * 1.55, 2.35, 0.15), Vector3.new(0.3, 0.3, 2.3), P.Gold, gold)
		B.ball(m, (cf * CFrame.new(s * 1.55, 2.35, -1.0)).Position, 0.45, P.Gold, gold)
		B.part(m, cf * CFrame.new(s * 1.55, 1.9, 0.9), Vector3.new(0.25, 0.9, 0.25), P.Gold, gold)
	end
	m.PrimaryPart = seat
	return m
end

local function arc(B, parent, center: Vector3, radius: number, fromDeg: number, toDeg: number, segs: number, thick: number, color: Color3)
	local prev
	for i = 0, segs do
		local a = math.rad(fromDeg + (toDeg - fromDeg) * i / segs)
		local p = center + Vector3.new(math.sin(a) * radius, 0, math.cos(a) * radius)
		if prev then
			B.neonLine(parent, prev, p, thick, color)
		end
		prev = p
	end
end
Stage.arc = arc

local function marker(B, parent, name: string, cf: CFrame)
	local p = B.part(parent, cf, Vector3.new(2, 1, 2), Color3.new(1, 1, 1), {
		Name = name,
		Transparency = 1,
		CanCollide = false,
		CastShadow = false,
		CanQuery = false,
	})
	p.CanTouch = false
	return p
end
Stage.marker = marker

local function movingHead(B, P, parent, pos: Vector3, targets: BasePart, target: Vector3, color: Color3, idx: number)
	local head = B.ball(parent, pos, 1.7, P.Charcoal, { Material = Enum.Material.Metal, CastShadow = false })
	head.Name = "MovingHead"
	B.part(parent, CFrame.new(pos + Vector3.new(0, 1.1, 0)), Vector3.new(1.8, 0.35, 0.6), P.Charcoal, { Material = Enum.Material.Metal, CastShadow = false })
	B.ball(parent, pos + (target - pos).Unit * 0.8, 0.9, color, { Material = Enum.Material.Neon, CastShadow = false, CanCollide = false })
	local a0 = Instance.new("Attachment")
	a0.Name = "Emit"
	a0.Parent = head
	local a1 = Instance.new("Attachment")
	a1.Name = "Target" .. idx
	a1.CFrame = CFrame.new(target - targets.CFrame.Position)
	a1.Parent = targets
	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Color = ColorSequence.new(color)
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(0.7, 0.85),
		NumberSequenceKeypoint.new(1, 1),
	})
	beam.Width0 = 0.7
	beam.Width1 = 9
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.FaceCamera = true
	beam.Segments = 1
	beam.Parent = head
	beam:SetAttribute("Home", target)
	beam:SetAttribute("Index", idx)
	beam:AddTag("StageBeam")
	return head
end

local function downlight(B, P, parent, pos: Vector3, color: Color3)
	local body = B.part(parent, CFrame.new(pos), Vector3.new(1.4, 1.6, 1.4), P.Charcoal, { Material = Enum.Material.Metal, CastShadow = false })
	B.neon(parent, CFrame.new(pos - Vector3.new(0, 0.85, 0)), Vector3.new(1, 0.1, 1), color, { CanCollide = false })
	B.light(body, "SpotLight", { Face = Enum.NormalId.Bottom, Angle = 55, Range = 36, Brightness = 2.2, Color = color, Shadows = false })
	body:AddTag("StageSpot")
	return body
end

local function speakerStack(B, P, parent, basePos: Vector3, count: number, facing: number)
	for i = 0, count - 1 do
		local cf = CFrame.new(basePos + Vector3.new(0, 1.6 + i * 3.1, 0)) * CFrame.Angles(0, facing, 0)
		B.soft(parent, cf, Vector3.new(7, 3, 5), 0.35, P.Charcoal, { CastShadow = true })
		B.part(parent, cf * CFrame.new(0, 0, -2.45), Vector3.new(6.2, 2.4, 0.2), P.PlumDeep, { Material = Enum.Material.Fabric })
		for _, sx in { -1.6, 1.6 } do
			B.disc(parent, cf * CFrame.new(sx, 0, -2.6), 0.2, 2, P.Charcoal, { Material = Enum.Material.Metal })
			B.disc(parent, cf * CFrame.new(sx, 0, -2.7), 0.1, 0.8, P.Dusk, { Material = Enum.Material.Metal })
		end
		B.neon(parent, cf * CFrame.new(0, -1.35, -2.56), Vector3.new(6.2, 0.1, 0.1), P.NeonLavender, { CanCollide = false })
	end
end

function Stage.build(B, P, Screens, root: Instance)
	local S = B.folder(root, "Stage")
	local markers = B.folder(S, "Markers")
	local deckOpts = { Reflectance = 0.18 }

	-- ============ Main deck ============
	B.rounded(S, CFrame.new(0, GY + 2.5, -70), Vector3.new(72, 5, 26), 0.8, P.PlumDeep, deckOpts)
	-- backstage deck
	B.rounded(S, CFrame.new(0, GY + 2.5, -88), Vector3.new(72, 5, 9.5), 0.8, P.Plum, {})
	for _, side in { -1, 1 } do
		local x0, x1 = side * 9, side * 35.5
		B.neonLine(S, Vector3.new(x0, GY + 3.9, -56.9), Vector3.new(x1, GY + 3.9, -56.9), 0.22, P.NeonLavender)
		B.neonLine(S, Vector3.new(x0, GY + 1.6, -56.9), Vector3.new(x1, GY + 1.6, -56.9), 0.18, P.NeonPink)
		B.neonLine(S, Vector3.new(x0, SY + 0.02, -57.15), Vector3.new(x1, SY + 0.02, -57.15), 0.2, P.NeonLavender)
	end
	-- sides of the deck
	for _, sx in { -36.2, 36.2 } do
		B.neonLine(S, Vector3.new(sx, SY + 0.02, -83), Vector3.new(sx, SY + 0.02, -57.4), 0.2, P.NeonLavender)
	end

	-- floor monitors
	for _, x in { -30, -22, -14, 14, 22, 30 } do
		B.wedge(S, CFrame.new(x, SY + 0.8, -58.8) * CFrame.Angles(0, math.pi, 0), Vector3.new(3, 1.6, 2.4), P.Charcoal, { Material = Enum.Material.Metal })
		B.neon(S, CFrame.new(x, SY + 0.1, -57.7), Vector3.new(2.6, 0.1, 0.1), P.NeonPink, { CanCollide = false })
	end

	-- ============ Runway (catwalk) ============
	local rw = B.folder(S, "Runway")
	local z0, z1 = -57, Stage.RunwayEndZ
	local len = z1 - z0
	local midZ = (z0 + z1) / 2
	B.part(rw, CFrame.new(0, GY + 0.5, midZ), Vector3.new(20, 1, len), P.Aubergine, {})
	B.vcyl(rw, Vector3.new(0, GY + 0.5, z1), 1, 20, P.Aubergine, {})
	local body = B.part(rw, CFrame.new(0, GY + 3, midZ), Vector3.new(16, 4, len), P.PlumDeep, { Reflectance = 0.28, Name = "RunwayFloor" })
	B.vcyl(rw, Vector3.new(0, GY + 3, z1), 4, 16, P.PlumDeep, { Reflectance = 0.28 })
	body:AddTag("RunwayFloor")
	-- gold lip trim
	for _, sx in { -10.02, 10.02 } do
		B.neonLine(rw, Vector3.new(sx, GY + 1.02, z0), Vector3.new(sx, GY + 1.02, z1), 0.12, P.NeonGold)
	end
	arc(B, rw, Vector3.new(0, GY + 1.02, z1), 10.02, -90, 90, 16, 0.12, P.NeonGold)
	-- top edge neon + pink underglow
	for _, sx in { -7.95, 7.95 } do
		B.neonLine(rw, Vector3.new(sx, SY + 0.04, z0), Vector3.new(sx, SY + 0.04, z1), 0.2, P.NeonLavender)
		B.neonLine(rw, Vector3.new(sx * 1.013, GY + 1.25, z0), Vector3.new(sx * 1.013, GY + 1.25, z1), 0.2, P.NeonPink)
	end
	arc(B, rw, Vector3.new(0, SY + 0.04, z1), 7.95, -90, 90, 18, 0.2, P.NeonLavender)
	arc(B, rw, Vector3.new(0, GY + 1.25, z1), 8.05, -90, 90, 18, 0.2, P.NeonPink)
	-- runway lights (little glowing studs)
	for z = z0 + 3, z1 - 4, 5 do
		for _, sx in { -6.4, 6.4 } do
			B.ball(rw, Vector3.new(sx, SY, z), 0.45, P.NeonGold, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		end
	end
	-- centre line
	B.part(rw, CFrame.new(0, SY + 0.01, midZ - 2), Vector3.new(0.35, 0.02, len - 8), P.Champagne, { Material = Enum.Material.Metal, CanCollide = false, CastShadow = false })
	-- pose spot
	local pose = B.vcyl(rw, Vector3.new(0, SY + 0.03, z1 - 1), 0.06, 9, P.Champagne, { Material = Enum.Material.Metal, Name = "PoseSpot", CastShadow = false })
	pose:AddTag("PoseSpot")
	arc(B, rw, Vector3.new(0, SY + 0.08, z1 - 1), 4.6, -180, 180, 24, 0.14, P.NeonPink)

	-- ============ LED walls ============
	local led = B.folder(S, "LED")
	local function screen(cf: CFrame, size: Vector3, opts)
		B.rounded(led, cf * CFrame.new(0, 0, -0.35), size + Vector3.new(1.4, 1.4, 0.2), 0.45, P.Charcoal, { Material = Enum.Material.Metal })
		local panel = B.part(led, cf, size, Color3.new(0, 0, 0), { Name = "Screen" })
		local gui = B.gui(panel, Enum.NormalId.Back, opts.PPS or 18, { Brightness = 1.6 })
		Screens.galaxy(gui, B, opts)
		return panel
	end
	screen(CFrame.new(0, SY + 10.6, -82.3), Vector3.new(34, 20, 0.6), { Seed = 11, Title = "AURA RUNWAY", Subtitle = "DRESS  •  WALK  •  WIN", PPS = 16 })
	screen(CFrame.new(-25.5, SY + 9.6, -80.6) * CFrame.Angles(0, math.rad(20), 0), Vector3.new(14, 17, 0.6), { Seed = 23, Sun = false, Vertical = true })
	screen(CFrame.new(25.5, SY + 9.6, -80.6) * CFrame.Angles(0, math.rad(-20), 0), Vector3.new(14, 17, 0.6), { Seed = 37, Sun = false, Vertical = true })

	-- wing towers with vertical LED faces
	for _, side in { -1, 1 } do
		local cx = side * 45
		B.soft(led, CFrame.new(cx, GY + 15, -73), Vector3.new(10, 30, 7), 0.9, P.Charcoal, {})
		local cf = CFrame.new(cx, GY + 15.5, -69.35) * CFrame.Angles(0, side * math.rad(-12), 0)
		local panel = B.part(led, cf, Vector3.new(8.4, 26, 0.4), Color3.new(0, 0, 0), { Name = "Screen" })
		local gui = B.gui(panel, Enum.NormalId.Back, 16, { Brightness = 1.6 })
		Screens.galaxy(gui, B, { Seed = 50 + side, Vertical = true, Title = side < 0 and "AURA" or "✦", Subtitle = side < 0 and "RUNWAY" or "CITY" })
		-- neon edges on the tower
		for _, ex in { -5.05, 5.05 } do
			B.neonLine(led, Vector3.new(cx + ex, GY + 0.2, -69.4), Vector3.new(cx + ex, GY + 29.8, -69.4), 0.2, P.NeonLavender)
		end
		-- speaker stacks
		speakerStack(B, P, led, Vector3.new(side * 55, GY, -70), 6, side * math.rad(-10))
		speakerStack(B, P, led, Vector3.new(side * 55, GY, -62.5), 2, side * math.rad(-10))
	end

	-- ============ Truss + lights ============
	local rig = B.folder(S, "Rig")
	local targets = marker(B, rig, "BeamTargets", CFrame.new(0, GY, 0))
	local trussColor = Color3.fromHex("B9B4C4")
	B.truss(rig, Vector3.new(-36.5, GY, -78), Vector3.new(-36.5, 36, -78), 2.4, trussColor)
	B.truss(rig, Vector3.new(36.5, GY, -78), Vector3.new(36.5, 36, -78), 2.4, trussColor)
	B.truss(rig, Vector3.new(-37.7, 37.2, -78), Vector3.new(37.7, 37.2, -78), 2.4, trussColor)
	B.truss(rig, Vector3.new(-61, GY, -66), Vector3.new(-61, 32, -66), 2, trussColor)
	B.truss(rig, Vector3.new(61, GY, -66), Vector3.new(61, 32, -66), 2, trussColor)

	local beamColors = { P.NeonLavender, P.NeonPink, P.NeonCyan }
	local idx = 0
	for i = 0, 8 do
		local x = -30 + i * 7.5
		idx += 1
		local target = Vector3.new(x * 0.4, SY, -40 + (i % 3) * 28)
		movingHead(B, P, rig, Vector3.new(x, 35.2, -77), targets, target, beamColors[(i % 3) + 1], idx)
	end
	for _, side in { -1, 1 } do
		for j = 0, 1 do
			idx += 1
			local target = Vector3.new(side * 4, SY, -20 + j * 40)
			movingHead(B, P, rig, Vector3.new(side * 61, 33.4 - j * 3, -64.5), targets, target, beamColors[((idx) % 3) + 1], idx)
		end
	end

	-- runway crossing trusses with spotlights
	for _, z in { -24, 20 } do
		B.truss(rig, Vector3.new(-38, GY, z), Vector3.new(-38, 30, z), 2, trussColor)
		B.truss(rig, Vector3.new(38, GY, z), Vector3.new(38, 30, z), 2, trussColor)
		B.truss(rig, Vector3.new(-39, 31, z), Vector3.new(39, 31, z), 2, trussColor)
		for _, x in { -9, -3, 3, 9 } do
			downlight(B, P, rig, Vector3.new(x, 29.2, z), x % 2 == 0 and P.Lilac or Color3.fromHex("FFE9F3"))
		end
	end
	-- warm wash on deck
	for _, x in { -24, 0, 24 } do
		local l = B.part(rig, CFrame.new(x, 36, -74), Vector3.new(1, 1, 1), P.Charcoal, { Transparency = 1, CanCollide = false, CastShadow = false })
		B.light(l, "SpotLight", { Face = Enum.NormalId.Bottom, Angle = 70, Range = 40, Brightness = 1.4, Color = P.Blush, Shadows = false })
	end

	-- ============ Stairs (front + backstage) ============
	local stairs = B.folder(S, "Stairs")
	for _, side in { -1, 1 } do
		local x = side * 30
		for i = 1, 8 do
			local h = i * 0.625
			local zc = -47 - (i - 0.5) * 1.25
			B.part(stairs, CFrame.new(x, GY + h / 2, zc), Vector3.new(8, h, 1.25), P.Aubergine, { Reflectance = 0.1 })
			B.neon(stairs, CFrame.new(x, GY + h - 0.03, zc + 0.6), Vector3.new(8, 0.08, 0.1), P.NeonLavender, { CanCollide = false })
		end
		for _, rx in { -4.1, 4.1 } do
			B.rod(stairs, Vector3.new(x + rx, GY + 3, -47.2), Vector3.new(x + rx, SY + 3, -57), 0.3, P.Gold, { Material = Enum.Material.Metal })
			B.vcyl(stairs, Vector3.new(x + rx, GY + 1.5, -47.2), 3, 0.3, P.Gold, { Material = Enum.Material.Metal })
		end
		-- back stairs to the backstage lounge
		for i = 1, 8 do
			local h = i * 0.625
			local xc = side * (46.2 - (i - 0.5) * 1.25)
			B.part(stairs, CFrame.new(xc, GY + h / 2, -88), Vector3.new(1.25, h, 8), P.Plum, {})
		end
	end

	-- ============ Backstage lounge ============
	local bs = B.folder(S, "Backstage")
	B.wall(bs, Vector3.new(-36, SY, -92.6), Vector3.new(36, SY, -92.6), 12, 0.8, P.Blush, {})
	for i = 0, 3 do
		local x = -27 + i * 18
		-- vanity with bulb mirror
		B.cushion(bs, CFrame.new(x, SY + 1.6, -91.4), Vector3.new(7, 3.2, 1.8), 0.3, P.Ivory, {})
		local mirror = B.part(bs, CFrame.new(x, SY + 6.4, -92.1), Vector3.new(5.6, 5, 0.2), Color3.fromHex("DDE7F0"), { Reflectance = 0.6, Material = Enum.Material.Glass })
		mirror.Name = "Mirror"
		for k = 0, 5 do
			B.ball(bs, Vector3.new(x - 3.1, SY + 4.2 + k * 0.9, -92), 0.45, P.Champagne, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
			B.ball(bs, Vector3.new(x + 3.1, SY + 4.2 + k * 0.9, -92), 0.45, P.Champagne, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		end
		local lp = B.part(bs, CFrame.new(x, SY + 9.5, -91.5), Vector3.new(0.5, 0.5, 0.5), P.Champagne, { Transparency = 1, CanCollide = false })
		B.light(lp, "PointLight", { Range = 12, Brightness = 1, Color = P.Champagne, Shadows = false })
		local stool = B.seat(bs, CFrame.new(x, SY + 1.4, -89.2), Vector3.new(2, 0.6, 2), P.Rose, {})
		stool.Name = "Seat"
	end
	local sign = B.part(bs, CFrame.new(0, SY + 10.8, -92.15), Vector3.new(16, 2.2, 0.2), P.Plum, {})
	Screens.sign(B.gui(sign, Enum.NormalId.Back, 20), B, "BACKSTAGE", {})

	-- ============ Podium ============
	local pod = B.folder(S, "Podium")
	local podiums = {
		{ 1, 0, 3.2, P.Gold },
		{ 2, -6.4, 2.2, P.Pearl },
		{ 3, 6.4, 1.4, P.RoseGold },
	}
	for _, d in podiums do
		local place, x, h, col = d[1], d[2], d[3], d[4]
		local block = B.cushion(pod, CFrame.new(x, SY + h / 2, -78), Vector3.new(6, h, 4), 0.3, col, { Material = Enum.Material.Metal })
		local face = B.part(pod, CFrame.new(x, SY + h / 2, -75.95), Vector3.new(3, math.min(h * 0.8, 2), 0.1), col, { CanCollide = false })
		local g = B.gui(face, Enum.NormalId.Back, 30)
		B.text(g, tostring(place), { FontFace = B.Fonts.Luxe(), TextColor3 = P.Plum })
		marker(B, markers, "Podium" .. place, CFrame.lookAt(Vector3.new(x, SY + h + 3, -78), Vector3.new(x, SY + h + 3, 0)))
		block.Name = "Podium" .. place
	end

	-- ============ Auction block ============
	local auc = B.folder(S, "Auction")
	B.cushion(auc, CFrame.new(24, SY + 1.9, -64), Vector3.new(4, 3.8, 2.4), 0.35, P.Aubergine, {})
	B.wedge(auc, CFrame.new(24, SY + 4.1, -64) * CFrame.Angles(0, math.pi, 0), Vector3.new(4.2, 0.6, 2.6), P.Gold, { Material = Enum.Material.Metal })
	B.vcyl(auc, Vector3.new(24, SY + 3.8, -65.3), 0.3, 0.6, P.Gold, { Material = Enum.Material.Metal })
	local gavel = B.cyl(auc, CFrame.new(24.6, SY + 4.5, -64) * CFrame.Angles(0, math.rad(30), 0), 1.1, 0.45, P.WoodDark, { Material = Enum.Material.Wood })
	gavel.Name = "Gavel"
	local scr = B.rounded(auc, CFrame.new(24, SY + 8.5, -67.6), Vector3.new(9.4, 6.2, 0.6), 0.3, P.Charcoal, {})
	local screenPart = B.part(auc, CFrame.new(24, SY + 8.5, -67.25), Vector3.new(8.8, 5.6, 0.1), Color3.new(0, 0, 0), { Name = "AuctionScreen" })
	screenPart:AddTag("AuctionScreen")
	local ag = B.gui(screenPart, Enum.NormalId.Back, 40, { Brightness = 1.3 })
	local bg = B.frame(ag, { Name = "Bg", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1) })
	B.gradient(bg, { P.Plum, P.Aubergine, P.Dusk }, 90)
	B.text(bg, "LIVE AUCTION", { Name = "Header", Size = UDim2.fromScale(1, 0.18), FontFace = B.Fonts.Luxe(), TextColor3 = P.Champagne })
	local img = Instance.new("ImageLabel")
	img.Name = "Item"
	img.BackgroundTransparency = 1
	img.Position = UDim2.fromScale(0.04, 0.22)
	img.Size = UDim2.fromScale(0.4, 0.72)
	img.ScaleType = Enum.ScaleType.Fit
	img.Parent = bg
	B.text(bg, "No auction running", { Name = "Title", Position = UDim2.fromScale(0.48, 0.24), Size = UDim2.fromScale(0.5, 0.18), TextColor3 = P.Ivory, TextXAlignment = Enum.TextXAlignment.Left })
	B.text(bg, "Models on stage can auction a limited!", { Name = "Bid", Position = UDim2.fromScale(0.48, 0.46), Size = UDim2.fromScale(0.5, 0.16), TextColor3 = P.Blush, TextXAlignment = Enum.TextXAlignment.Left })
	B.text(bg, "", { Name = "Timer", Position = UDim2.fromScale(0.48, 0.68), Size = UDim2.fromScale(0.5, 0.14), TextColor3 = P.Lilac, TextXAlignment = Enum.TextXAlignment.Left })
	B.vcyl(auc, Vector3.new(24, SY + 2.7, -67.6), 5.4, 0.5, P.Gold, { Material = Enum.Material.Metal })
	local aucPrompt = B.prompt(screenPart, "Open Auction", "Live Auction", { Distance = 16 })
	aucPrompt.Name = "AuctionPrompt"
	aucPrompt:AddTag("AuctionPrompt")

	-- ============ Seating ============
	local seats = B.folder(S, "Seating")
	local cushions = { P.Rose, P.Blush, P.Lavender }
	for _, side in { -1, 1 } do
		for row = 0, 2 do
			local x = side * (14 + row * 4.6)
			local rise = row * 1.1
			if rise > 0 then
				B.soft(seats, CFrame.new(x, GY + rise / 2, -2), Vector3.new(4.6, rise, 90), 0.4, P.Aubergine, {})
				B.neonLine(seats, Vector3.new(x - side * 2.3, GY + rise + 0.02, -46.5), Vector3.new(x - side * 2.3, GY + rise + 0.02, 42.5), 0.12, P.NeonLavender)
			end
			for z = -44, 40, 4.2 do
				local pos = Vector3.new(x, GY + rise, z)
				Stage.chair(B, P, seats, CFrame.lookAt(pos, pos + Vector3.new(-side, 0, 0)), cushions[row + 1])
			end
		end
	end
	for row = 0, 2 do
		local z = 62 + row * 4.6
		local rise = row * 1.1
		if rise > 0 then
			B.soft(seats, CFrame.new(0, GY + rise / 2, z), Vector3.new(58, rise, 4.6), 0.4, P.Aubergine, {})
		end
		for x = -24, 24, 4 do
			local pos = Vector3.new(x, GY + rise, z)
			Stage.chair(B, P, seats, CFrame.lookAt(pos, pos + Vector3.new(0, 0, -1)), cushions[row + 1])
		end
	end

	-- ============ Markers ============
	marker(B, markers, "RunwayStart", CFrame.lookAt(Vector3.new(0, SY + 3, -72), Vector3.new(0, SY + 3, 0)))
	marker(B, markers, "RunwayEnd", CFrame.lookAt(Vector3.new(0, SY + 3, z1 - 1), Vector3.new(0, SY + 3, 0)))
	for i = 1, 8 do
		local x = -28 + (i - 1) * 8
		marker(B, markers, "Lounge" .. i, CFrame.lookAt(Vector3.new(x, SY + 3, -86.5), Vector3.new(x, SY + 3, -80)))
	end
	for i = 1, 6 do
		local x = (i % 2 == 0 and 1 or -1) * (60 + (i // 2) * 4)
		marker(B, markers, "PlazaReturn" .. i, CFrame.lookAt(Vector3.new(x, GY + 3, 72), Vector3.new(0, GY + 3, 0)))
	end
	-- stage zone (for "on stage" checks)
	S:SetAttribute("ZoneMin", Vector3.new(-37, SY - 1, -93))
	S:SetAttribute("ZoneMax", Vector3.new(37, SY + 14, z1 + 9))
	return S
end

return Stage
