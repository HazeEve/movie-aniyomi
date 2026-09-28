--!nonstrict
-- Enterable building shells + common furniture (beds, sofas, tables, counters).
local Rooms = {}

-- cf: centre of the floor (floor top height), LookVector = the building's front.
-- opts: Wall, Trim, Floor, FloorMaterial, Height, Doors = {{side, offset, width, height}},
--       Windows = {{side, offset, width, height, bottom}}, Roof = bool, Glass = color
function Rooms.shell(B, P, parent, cf: CFrame, w: number, d: number, opts)
	opts = opts or {}
	local h = opts.Height or 16
	local m = B.model(parent, opts.Name or "Building")
	local wall = opts.Wall or P.Ivory
	local trim = opts.Trim or P.RoseGold
	local t = 0.8
	B.part(m, cf * CFrame.new(0, -0.15, 0), Vector3.new(w, 0.3, d), opts.Floor or P.Pearl, { Material = opts.FloorMaterial or Enum.Material.Marble, Name = "Floor", CastShadow = false })
	local sides = {
		front = { Vector3.new(-w / 2, 0, -d / 2), Vector3.new(w / 2, 0, -d / 2), w },
		back = { Vector3.new(w / 2, 0, d / 2), Vector3.new(-w / 2, 0, d / 2), w },
		left = { Vector3.new(-w / 2, 0, d / 2), Vector3.new(-w / 2, 0, -d / 2), d },
		right = { Vector3.new(w / 2, 0, -d / 2), Vector3.new(w / 2, 0, d / 2), d },
	}
	local glassColor = opts.Glass or P.Powder:Lerp(P.Lilac, 0.4)
	for name, s in sides do
		local openings = {}
		for _, dr in opts.Doors or {} do
			if dr[1] == name then
				table.insert(openings, { at = s[3] / 2 + dr[2], width = dr[3], height = dr[4] or 9 })
			end
		end
		local windows = {}
		for _, wn in opts.Windows or {} do
			if wn[1] == name then
				local o = { at = s[3] / 2 + wn[2], width = wn[3], height = wn[4], bottom = wn[5] or 2 }
				table.insert(openings, o)
				table.insert(windows, o)
			end
		end
		local a = (cf * CFrame.new(s[1])).Position
		local b = (cf * CFrame.new(s[2])).Position
		local wcf = B.wall(m, a, b, h, t, wall, openings, {})
		for _, o in windows do
			B.part(m, wcf * CFrame.new(0, o.bottom + o.height / 2, -o.at), Vector3.new(0.3, o.height, o.width), glassColor, {
				Material = Enum.Material.Glass,
				Transparency = 0.55,
				Reflectance = 0.2,
				CastShadow = false,
				Name = "Window",
			})
			B.part(m, wcf * CFrame.new(0, o.bottom - 0.2, -o.at), Vector3.new(1.2, 0.4, o.width + 0.6), trim, { Material = Enum.Material.Metal })
		end
	end
	-- rounded corner columns
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			B.vcyl(m, (cf * CFrame.new(sx * w / 2, h / 2, sz * d / 2)).Position, h, 1.8, trim, { Material = Enum.Material.Marble })
		end
	end
	-- base plinth + cornice + roof
	B.ring(m, cf * CFrame.new(0, 0.5, 0), w + 1.6, d + 1.6, 1.6, 1, trim, { Material = Enum.Material.Marble, CastShadow = false })
	if opts.Roof ~= false then
		B.part(m, cf * CFrame.new(0, h + 0.4, 0), Vector3.new(w + 0.8, 0.8, d + 0.8), wall, { Name = "Roof" })
		B.ring(m, cf * CFrame.new(0, h + 1.1, 0), w + 2, d + 2, 1.4, 0.8, trim, { Material = Enum.Material.Metal })
		B.part(m, cf * CFrame.new(0, h - 0.05, 0), Vector3.new(w - 1, 0.1, d - 1), P.Ivory, { CastShadow = false, Name = "Ceiling" })
	end
	-- ceiling lights
	local lx = math.max(1, math.floor(w / 24))
	local lz = math.max(1, math.floor(d / 24))
	for i = 1, lx do
		for j = 1, lz do
			local p = cf * CFrame.new(-w / 2 + w * (i - 0.5) / lx, h - 0.4, -d / 2 + d * (j - 0.5) / lz)
			local lampPart = B.disc(m, p * CFrame.Angles(math.pi / 2, 0, 0), 0.3, 3, P.Champagne, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
			B.light(lampPart, "PointLight", { Range = 22, Brightness = 0.8, Color = Color3.fromHex("FFE9D6"), Shadows = false })
		end
	end
	return m
end

-- Door frame + awning + sign above a front opening
function Rooms.entrance(B, P, parent, cf: CFrame, width: number, name: string, colorA: Color3, Screens)
	B.wedge(parent, cf * CFrame.new(0, 10.4, -2) * CFrame.Angles(0, math.pi, 0), Vector3.new(width + 4, 1.4, 4), colorA, { Material = Enum.Material.Fabric })
	for k = 0, math.floor((width + 3) / 2.2) do
		local x = -(width + 3) / 2 + k * 2.2
		B.ball(parent, (cf * CFrame.new(x, 9.6, -4)).Position, 0.7, k % 2 == 0 and colorA or P.Ivory, { Material = Enum.Material.Fabric, CanCollide = false, CastShadow = false })
	end
	local sign = B.part(parent, cf * CFrame.new(0, 12.8, -0.55), Vector3.new(math.max(width + 6, 14), 2.6, 0.3), P.Plum, { CanCollide = false })
	Screens.sign(B.gui(sign, Enum.NormalId.Front, 24), B, name, {})
	return sign
end

function Rooms.bed(B, P, parent, cf: CFrame, blanket: Color3)
	local m = B.model(parent, "Bed")
	local wood = { Material = Enum.Material.Wood }
	B.cushion(m, cf * CFrame.new(0, 0.8, 0), Vector3.new(7.4, 1.6, 10.4), 0.3, P.WoodDark, wood)
	local mattress = B.cushion(m, cf * CFrame.new(0, 2.05, 0), Vector3.new(7, 1, 10), 0.4, P.Ivory, { Material = Enum.Material.Fabric })
	mattress.Name = "Mattress"
	B.cushion(m, cf * CFrame.new(0, 2.6, -1.4), Vector3.new(7.2, 0.4, 7), 0.18, blanket, { Material = Enum.Material.Fabric, CanCollide = false })
	B.cushion(m, cf * CFrame.new(0, 2.66, -4.4), Vector3.new(7.25, 0.4, 1.2), 0.18, P.Ivory, { Material = Enum.Material.Fabric, CanCollide = false })
	for _, s in { -1.7, 1.7 } do
		B.cushion(m, cf * CFrame.new(s, 2.9, 3.9), Vector3.new(2.8, 0.8, 1.6), 0.35, P.Pearl, { Material = Enum.Material.Fabric, CanCollide = false })
	end
	-- tufted headboard
	B.cushion(m, cf * CFrame.new(0, 4, 5.2) * CFrame.Angles(math.rad(90), 0, 0), Vector3.new(8, 0.8, 5.6), 0.35, blanket:Lerp(P.Plum, 0.2), { Material = Enum.Material.Fabric })
	for bx = -3, 3, 1.5 do
		for by = 2.6, 5.6, 1.5 do
			B.ball(m, (cf * CFrame.new(bx, by, 4.75)).Position, 0.25, P.Gold, { Material = Enum.Material.Metal, CanCollide = false })
		end
	end
	local sleepSpot = B.part(m, cf * CFrame.new(0, 3.6, 0.8) * CFrame.Angles(math.pi / 2, 0, 0), Vector3.new(1, 1, 1), P.Ivory, {
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Name = "SleepSpot",
	})
	sleepSpot.CanTouch = false
	B.prompt(mattress, "Sleep", "Bed", { Name = "SleepPrompt", Hold = 0.3, Distance = 8 })
	mattress:AddTag("Bed")
	-- nightstands with lamps
	for _, s in { -1, 1 } do
		local ns = cf * CFrame.new(s * 5.4, 1.4, 4)
		B.cushion(m, ns, Vector3.new(2.6, 2.8, 2.4), 0.25, P.Ivory, {})
		B.vcyl(m, (ns * CFrame.new(0, 1.8, 0)).Position, 0.8, 0.5, P.Gold, { Material = Enum.Material.Metal })
		local shade = B.vcyl(m, (ns * CFrame.new(0, 2.8, 0)).Position, 1.2, 1.4, P.Blush, { Material = Enum.Material.Fabric })
		B.light(shade, "PointLight", { Range = 10, Brightness = 0.7, Color = Color3.fromHex("FFE3C8"), Shadows = false })
	end
	return m
end

function Rooms.sofa(B, P, parent, cf: CFrame, color: Color3, width: number?)
	width = width or 8
	local m = B.model(parent, "Sofa")
	local fab = { Material = Enum.Material.Fabric }
	B.cushion(m, cf * CFrame.new(0, 0.9, 0.2), Vector3.new(width, 1.8, 3.4), 0.35, color, fab)
	local n = math.max(1, math.floor(width / 3))
	for i = 1, n do
		local x = -width / 2 + (width) * (i - 0.5) / n
		local s = B.seat(m, cf * CFrame.new(x, 2.1, -0.1), Vector3.new(width / n - 0.2, 0.6, 2.6), color:Lerp(P.Ivory, 0.12), fab)
		s.Name = "Seat"
	end
	B.cushion(m, cf * CFrame.new(0, 3, 1.55) * CFrame.Angles(math.rad(-10), 0, 0), Vector3.new(width, 2.6, 0.9), 0.4, color, fab)
	for _, sx in { -1, 1 } do
		B.cushion(m, cf * CFrame.new(sx * (width / 2 + 0.4), 1.6, 0.2), Vector3.new(0.9, 2.2, 3.4), 0.4, color, fab)
	end
	B.ball(m, (cf * CFrame.new(-width / 2 + 1.4, 2.9, 0.9)).Position, 1.1, P.Champagne, { Material = Enum.Material.Fabric, CanCollide = false })
	return m
end

function Rooms.table(B, P, parent, cf: CFrame, top: Color3, chairs: number, chairColor: Color3)
	local m = B.model(parent, "Table")
	B.vcyl(m, (cf * CFrame.new(0, 0.1, 0)).Position, 0.2, 2.2, P.Gold, { Material = Enum.Material.Metal })
	B.vcyl(m, (cf * CFrame.new(0, 1.6, 0)).Position, 3, 0.35, P.Gold, { Material = Enum.Material.Metal })
	B.vcyl(m, (cf * CFrame.new(0, 3.15, 0)).Position, 0.25, 4.2, top, { Material = Enum.Material.Marble })
	for i = 1, chairs or 0 do
		local a = (i - 1) / chairs * math.pi * 2
		local pos = (cf * CFrame.new(math.cos(a) * 3.3, 0, math.sin(a) * 3.3)).Position
		local ccf = CFrame.lookAt(pos, Vector3.new(cf.Position.X, pos.Y, cf.Position.Z))
		B.vcyl(m, (ccf * CFrame.new(0, 0.9, 0)).Position, 1.8, 0.3, P.Gold, { Material = Enum.Material.Metal })
		local s = B.seat(m, ccf * CFrame.new(0, 1.9, 0), Vector3.new(1.8, 0.4, 1.8), chairColor, { Material = Enum.Material.Fabric })
		s.Name = "Seat"
		B.cushion(m, ccf * CFrame.new(0, 3.1, 0.85) * CFrame.Angles(math.rad(-8), 0, 0), Vector3.new(1.8, 2, 0.3), 0.14, chairColor, { Material = Enum.Material.Fabric })
	end
	return m
end

function Rooms.counter(B, P, parent, cf: CFrame, w: number, color: Color3)
	B.cushion(parent, cf * CFrame.new(0, 1.8, 0), Vector3.new(w, 3.6, 2.6), 0.35, color, {})
	B.cushion(parent, cf * CFrame.new(0, 3.75, 0), Vector3.new(w + 0.4, 0.3, 3), 0.14, P.Ivory, { Material = Enum.Material.Marble })
	B.part(parent, cf * CFrame.new(0, 1.9, -1.32), Vector3.new(w - 1, 0.12, 0.05), P.Gold, { Material = Enum.Material.Metal, CanCollide = false })
end

-- A "giver" pad: prompts to take an item (food or holdable). Kind: "Food" | "Hold"
function Rooms.giver(B, P, parent, cf: CFrame, item: string, kind: string, label: string?)
	local pad = B.cushion(parent, cf, Vector3.new(1.8, 0.3, 1.8), 0.14, P.Champagne, { Material = Enum.Material.Metal })
	pad.Name = "Giver_" .. item
	pad:SetAttribute("Item", item)
	pad:SetAttribute("Kind", kind)
	pad:AddTag("Giver")
	B.prompt(pad, (kind == "Food" and "Take " or "Pick up ") .. (label or item), "", { Distance = 7 })
	return pad
end

-- Marker used by the travel menu
function Rooms.travelPoint(B, parent, name: string, cf: CFrame, order: number)
	local p = B.part(parent, cf, Vector3.new(2, 1, 2), Color3.new(1, 1, 1), {
		Name = name,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CastShadow = false,
	})
	p.CanTouch = false
	p:SetAttribute("Order", order)
	p:AddTag("TravelPoint")
	return p
end

function Rooms.catalogSpot(B, P, parent, cf: CFrame, label: string)
	local mirror = B.rounded(parent, cf * CFrame.new(0, 4.5, 0), Vector3.new(4.4, 8, 0.5), 0.22, P.Gold, { Material = Enum.Material.Metal })
	local glass = B.part(parent, cf * CFrame.new(0, 4.5, -0.3), Vector3.new(3.8, 7.4, 0.1), Color3.fromHex("DCE6EE"), { Reflectance = 0.55, Material = Enum.Material.Glass, Name = "Mirror" })
	B.prompt(glass, label or "Change Outfit", "Mirror", { Distance = 8 })
	glass:AddTag("OpenCatalog")
	return mirror
end

return Rooms
