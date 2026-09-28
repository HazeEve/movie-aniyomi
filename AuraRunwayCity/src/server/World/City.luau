--!nonstrict
-- Ground, roads, sidewalks, plaza, street furniture and the skyline of
-- pastel/luxury buildings that surround the runway.
local City = {}

local SHOP_NAMES = {
	"Maison Lune", "Bijou", "Velvet & Co", "Lumière", "Atelier Rose", "Petal Parfum", "Gallery Nine",
	"Aura Bank", "Silk Studio", "Café Soleil", "Ivory Jewels", "Pearl Optics", "Cloud Bakery",
	"Lilac Books", "Opal Beauty", "Satin Lane", "Golden Hour", "Crème Boutique", "Muse Modeling", "Starlight Cinema",
}

local function lamp(B, P, parent, pos: Vector3, facing: Vector3, withLight: boolean)
	local metal = { Material = Enum.Material.Metal }
	B.vcyl(parent, pos + Vector3.new(0, 0.5, 0), 1, 1.6, P.Plum, metal)
	B.vcyl(parent, pos + Vector3.new(0, 7, 0), 13, 0.5, P.Plum, metal)
	local top = pos + Vector3.new(0, 13.5, 0)
	local armEnd = top + facing * 2.6
	B.rod(parent, top, armEnd + Vector3.new(0, 0.6, 0), 0.3, P.Plum, metal)
	B.ball(parent, top + Vector3.new(0, 0.3, 0), 0.7, P.Gold, metal)
	B.part(parent, CFrame.new(armEnd + Vector3.new(0, 0.9, 0)), Vector3.new(1.4, 0.3, 1.4), P.Plum, metal)
	local bulb = B.ball(parent, armEnd, 1.5, P.Champagne, { Material = Enum.Material.Neon, CastShadow = false })
	bulb.Name = "LampBulb"
	bulb:AddTag("StreetLamp")
	if withLight then
		B.light(bulb, "PointLight", { Range = 20, Brightness = 0.9, Color = Color3.fromHex("FFE2C4"), Shadows = false })
	end
end
City.lamp = lamp

local function bench(B, P, parent, cf: CFrame)
	local wood = { Material = Enum.Material.Wood }
	local metal = { Material = Enum.Material.Metal }
	local seat = B.seat(parent, cf * CFrame.new(0, 1.7, 0), Vector3.new(6, 0.4, 1.8), P.Wood, wood)
	seat.Material = Enum.Material.Wood
	for i = 0, 2 do
		B.part(parent, cf * CFrame.new(0, 2.5 + i * 0.6, 0.95) * CFrame.Angles(math.rad(-10), 0, 0), Vector3.new(6, 0.35, 0.2), P.Wood, wood)
	end
	for _, s in { -2.6, 2.6 } do
		B.part(parent, cf * CFrame.new(s, 0.85, 0), Vector3.new(0.3, 1.7, 1.6), P.Plum, metal)
		B.part(parent, cf * CFrame.new(s, 2.9, 0.95), Vector3.new(0.3, 2.4, 0.3), P.Plum, metal)
	end
	return seat
end
City.bench = bench

local function planter(B, P, parent, pos: Vector3, size: number, r)
	B.cushion(parent, CFrame.new(pos + Vector3.new(0, 1, 0)), Vector3.new(size, 2, size), 0.4, P.Champagne, { Material = Enum.Material.Marble })
	B.part(parent, CFrame.new(pos + Vector3.new(0, 2.05, 0)), Vector3.new(size - 0.8, 0.1, size - 0.8), P.LeafDark, { Material = Enum.Material.Grass })
	local flowers = { P.Rose, P.Blush, P.Lavender, P.Ivory, P.Butter }
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		B.ball(parent, pos + Vector3.new(math.cos(a) * size * 0.32, 2.4, math.sin(a) * size * 0.32), 0.9, flowers[(i % #flowers) + 1], { Material = Enum.Material.Fabric, CanCollide = false })
	end
end
City.planter = planter

-- Classic pastel building with windows, cornice, awning shops
local function classicBuilding(B, P, parent, cf: CFrame, w: number, d: number, floors: number, r)
	local m = B.model(parent, "Building")
	local facade = r.pick(P.Facades)
	local trim = r.pick(P.Trims)
	local floorH = 10
	local h = floors * floorH + 2
	B.soft(m, cf * CFrame.new(0, h / 2, 0), Vector3.new(w, h, d), 1.4, facade, { Material = Enum.Material.SmoothPlastic })
	B.soft(m, cf * CFrame.new(0, 1.5, 0), Vector3.new(w + 0.6, 3, d + 0.6), 1.6, trim, { Material = Enum.Material.Marble })
	-- floor bands
	for f = 1, floors - 1 do
		B.soft(m, cf * CFrame.new(0, f * floorH + 0.3, 0), Vector3.new(w + 0.4, 0.5, d + 0.4), 1.5, P.Ivory, {})
	end
	-- cornice
	B.soft(m, cf * CFrame.new(0, h + 0.4, 0), Vector3.new(w + 1.4, 0.8, d + 1.4), 1.8, trim, { Material = Enum.Material.Metal })
	B.soft(m, cf * CFrame.new(0, h + 1.2, 0), Vector3.new(w + 0.6, 0.8, d + 0.6), 1.5, facade, {})
	-- windows on all four faces
	local glass = P.Powder:Lerp(P.Lilac, r.next() * 0.6)
	local faces = {
		{ axis = "x", len = w, off = d / 2, rot = 0 },
		{ axis = "x", len = w, off = -d / 2, rot = math.pi },
		{ axis = "z", len = d, off = w / 2, rot = -math.pi / 2 },
		{ axis = "z", len = d, off = -w / 2, rot = math.pi / 2 },
	}
	for fi, face in faces do
		local n = math.floor((face.len - 6) / 8)
		local span = (n - 1) * 8
		for f = 1, floors - 1 do
			for i = 0, n - 1 do
				local t = -span / 2 + i * 8
				local local_
				if face.axis == "x" then
					local_ = CFrame.new(t, f * floorH + 5, face.off)
				else
					local_ = CFrame.new(face.off, f * floorH + 5, t)
				end
				local wcf = cf * local_ * CFrame.Angles(0, face.rot, 0)
				local win = B.part(m, wcf, Vector3.new(3.4, 5.6, 0.5), glass, { Material = Enum.Material.Glass, Reflectance = 0.25, CastShadow = false, Name = "Window" })
				if r.next() < 0.55 then
					win:AddTag("CityWindow")
				end
			end
		end
		-- ground floor storefront on the long faces
		if fi <= 2 then
			local fcf = cf * (face.axis == "x" and CFrame.new(0, 0, face.off) or CFrame.new(face.off, 0, 0)) * CFrame.Angles(0, face.rot, 0)
			B.part(m, fcf * CFrame.new(0, 5.4, 0), Vector3.new(face.len - 8, 5.4, 0.5), P.Powder:Lerp(P.Plum, 0.35), { Material = Enum.Material.Glass, Reflectance = 0.2, CastShadow = false })
			local awn = r.pick(P.Awnings)
			B.wedge(m, fcf * CFrame.new(0, 9.1, 1.8) * CFrame.Angles(0, math.pi, 0), Vector3.new(face.len - 7, 1.4, 3.4), awn, { Material = Enum.Material.Fabric })
			for k = 0, math.floor((face.len - 8) / 2.4) do
				local x = -(face.len - 8) / 2 + k * 2.4
				B.ball(m, (fcf * CFrame.new(x, 8.3, 3.4)).Position, 0.7, (k % 2 == 0) and awn or P.Ivory, { Material = Enum.Material.Fabric, CanCollide = false, CastShadow = false })
			end
			local sign = B.part(m, fcf * CFrame.new(0, 10.9, 0.35), Vector3.new(math.min(18, face.len - 10), 1.8, 0.2), P.Plum, { CanCollide = false })
			local gui = B.gui(sign, Enum.NormalId.Back, 24)
			require(script.Parent.Screens).sign(gui, B, r.pick(SHOP_NAMES), {})
		end
	end
	-- rooftop details
	if r.next() < 0.5 then
		B.vcyl(m, (cf * CFrame.new(w * 0.2, h + 4, d * 0.15)).Position, 5, 4.5, P.Wood, { Material = Enum.Material.WoodPlanks })
		B.part(m, cf * CFrame.new(w * 0.2, h + 7, d * 0.15) * CFrame.Angles(0, math.rad(45), 0), Vector3.new(3.4, 1.2, 3.4), P.WoodDark, { Material = Enum.Material.Wood })
	else
		B.part(m, cf * CFrame.new(0, h + 1.65, 0), Vector3.new(w - 6, 0.1, d - 6), P.Grass, { Material = Enum.Material.Grass })
		for i = 1, 3 do
			B.ball(m, (cf * CFrame.new(r.range(-w / 3, w / 3), h + 2.5, r.range(-d / 3, d / 3))).Position, r.range(2.5, 4), P.Leaf, { Material = Enum.Material.Grass })
		end
	end
	B.soft(m, cf * CFrame.new(-w * 0.25, h + 2.6, -d * 0.2), Vector3.new(5, 2.4, 4), 0.4, P.Mist, { Material = Enum.Material.Metal })
	return m
end

-- Glass luxury tower with rounded corners and a glowing crown
local function tower(B, P, parent, cf: CFrame, w: number, d: number, h: number, r)
	local m = B.model(parent, "Tower")
	local glass = r.pick({ P.Powder, P.Lilac, P.Blush, P.Mint }):Lerp(P.Plum, 0.25)
	local frameCol = r.pick({ P.Ivory, P.Champagne, P.Pearl })
	-- lobby
	B.soft(m, cf * CFrame.new(0, 7, 0), Vector3.new(w + 2, 14, d + 2), 5, frameCol, { Material = Enum.Material.Marble })
	B.soft(m, cf * CFrame.new(0, 7, 0), Vector3.new(w + 2.4, 9, d - 10), 4, glass, { Material = Enum.Material.Glass, Reflectance = 0.3 })
	-- shaft
	B.soft(m, cf * CFrame.new(0, 14 + (h - 14) / 2, 0), Vector3.new(w, h - 14, d), 5, glass, { Material = Enum.Material.Glass, Reflectance = 0.35 })
	for y = 14 + 8, h - 4, 8 do
		B.soft(m, cf * CFrame.new(0, y, 0), Vector3.new(w + 0.5, 0.7, d + 0.5), 5.2, frameCol, {})
	end
	-- vertical fins
	for _, sx in { -1, 1 } do
		for _, t in { -0.25, 0.25 } do
			B.part(m, cf * CFrame.new(t * w, 14 + (h - 14) / 2, sx * (d / 2 + 0.2)), Vector3.new(0.6, h - 14, 0.6), frameCol, {})
			B.part(m, cf * CFrame.new(sx * (w / 2 + 0.2), 14 + (h - 14) / 2, t * d), Vector3.new(0.6, h - 14, 0.6), frameCol, {})
		end
	end
	-- crown
	B.soft(m, cf * CFrame.new(0, h + 1.5, 0), Vector3.new(w - 4, 3, d - 4), 4, frameCol, { Material = Enum.Material.Metal })
	B.soft(m, cf * CFrame.new(0, h + 4.5, 0), Vector3.new(w - 10, 3, d - 10), 3, P.RoseGold, { Material = Enum.Material.Metal })
	local neonCol = r.pick({ P.NeonLavender, P.NeonPink, P.NeonGold })
	B.soft(m, cf * CFrame.new(0, h + 0.2, 0), Vector3.new(w + 0.3, 0.4, d + 0.3), 5.1, neonCol, { Material = Enum.Material.Neon, CastShadow = false })
	B.vcyl(m, (cf * CFrame.new(0, h + 10, 0)).Position, 8, 0.5, P.Gold, { Material = Enum.Material.Metal })
	B.ball(m, (cf * CFrame.new(0, h + 14.2, 0)).Position, 1.2, P.NeonPink, { Material = Enum.Material.Neon })
	return m
end

-- Row of townhouses with mansard roofs
local function townhouses(B, P, parent, cf: CFrame, width: number, count: number, r)
	local m = B.model(parent, "Townhouses")
	local hw = width / count
	for i = 0, count - 1 do
		local x = -width / 2 + hw * (i + 0.5)
		local col = r.pick(P.Facades)
		local h = r.range(22, 28)
		local hcf = cf * CFrame.new(x, 0, 0)
		B.soft(m, hcf * CFrame.new(0, h / 2, 0), Vector3.new(hw - 0.6, h, 30), 0.8, col, {})
		-- mansard roof
		B.wedge(m, hcf * CFrame.new(0, h + 2, -13), Vector3.new(hw - 0.6, 4, 4), P.Aubergine, { Material = Enum.Material.Slate })
		B.wedge(m, hcf * CFrame.new(0, h + 2, 13) * CFrame.Angles(0, math.pi, 0), Vector3.new(hw - 0.6, 4, 4), P.Aubergine, { Material = Enum.Material.Slate })
		B.part(m, hcf * CFrame.new(0, h + 2, 0), Vector3.new(hw - 0.6, 4, 22), P.Aubergine, { Material = Enum.Material.Slate })
		B.soft(m, hcf * CFrame.new(hw * 0.25, h + 5.5, 4), Vector3.new(2, 3, 2), 0.3, P.Taupe, { Material = Enum.Material.Brick })
		-- door + stoop
		B.part(m, hcf * CFrame.new(-hw * 0.2, 4.6, -15.1), Vector3.new(3.4, 7, 0.4), P.Plum, {})
		B.disc(m, hcf * CFrame.new(-hw * 0.2, 8.1, -15.1), 0.4, 3.4, P.Plum, {})
		B.ball(m, (hcf * CFrame.new(-hw * 0.2 + 1.1, 4.4, -15.4)).Position, 0.3, P.Gold, { Material = Enum.Material.Metal })
		for s = 1, 3 do
			B.part(m, hcf * CFrame.new(-hw * 0.2, s * 0.35, -15 - (4 - s) * 0.9), Vector3.new(5, s * 0.7, 0.9), P.Pearl, { Material = Enum.Material.Marble })
		end
		-- bay window
		B.soft(m, hcf * CFrame.new(hw * 0.18, 13, -15.6), Vector3.new(6, 7, 2.4), 0.8, P.Ivory, {})
		B.part(m, hcf * CFrame.new(hw * 0.18, 13, -16.85), Vector3.new(4.6, 5.4, 0.2), P.Powder, { Material = Enum.Material.Glass, Reflectance = 0.3 })
		for _, wy in { 5, 20 } do
			B.part(m, hcf * CFrame.new(hw * 0.18, wy, -15.1), Vector3.new(3.6, 4.4, 0.3), P.Powder, { Material = Enum.Material.Glass, Reflectance = 0.3 })
			B.part(m, hcf * CFrame.new(hw * 0.18, wy - 2.5, -15.35), Vector3.new(4.4, 0.4, 0.7), P.Ivory, {})
		end
		-- flower box
		B.part(m, hcf * CFrame.new(-hw * 0.2, 13, -15.4), Vector3.new(3.4, 0.8, 0.8), P.WoodDark, { Material = Enum.Material.Wood })
		for k = -1, 1 do
			B.ball(m, (hcf * CFrame.new(-hw * 0.2 + k * 1, 13.6, -15.4)).Position, 0.7, r.pick({ P.Rose, P.Blush, P.Lavender }), { Material = Enum.Material.Fabric, CanCollide = false })
		end
	end
	return m
end
City.classicBuilding = classicBuilding
City.tower = tower
City.townhouses = townhouses

function City.build(B, P, L, Screens, root: Instance)
	local C = B.folder(root, "City")
	local r = B.rng(20260928)

	-- ============ Ground ============
	local ground = B.part(C, CFrame.new(0, 0, 0), Vector3.new(1400, 1, 1400), P.Grass, { Material = Enum.Material.Grass, Name = "Ground" })
	ground.Locked = true
	-- soft hills at the edge of the world
	for i = 1, 26 do
		local a = i / 26 * math.pi * 2
		local rad = r.range(520, 620)
		local s = r.range(60, 120)
		B.ball(C, Vector3.new(math.cos(a) * rad, -s * 0.3, math.sin(a) * rad), s, P.Grass:Lerp(P.LeafDark, r.next() * 0.5), { Material = Enum.Material.Grass })
	end

	-- ============ Roads ============
	local roads = B.folder(C, "Roads")
	local ext = L.Extent
	local rt = L.RoadTop
	for _, line in L.Lines do
		B.part(roads, CFrame.new(line, rt - 0.05, 0), Vector3.new(L.RoadWidth, 0.1, ext * 2), P.Asphalt, { Material = Enum.Material.Asphalt, CastShadow = false, Name = "Road" })
		B.part(roads, CFrame.new(0, rt - 0.049, line), Vector3.new(ext * 2, 0.1, L.RoadWidth), P.Asphalt, { Material = Enum.Material.Asphalt, CastShadow = false, Name = "Road" })
	end
	-- lane dashes (skip intersections)
	local function inIntersection(v: number): boolean
		for _, line in L.Lines do
			if math.abs(v - line) < L.RoadWidth / 2 + 10 then
				return true
			end
		end
		return false
	end
	for _, line in L.Lines do
		for t = -ext + 6, ext - 6, 16 do
			if not inIntersection(t) then
				B.part(roads, CFrame.new(line, rt + 0.005, t), Vector3.new(0.5, 0.02, 8), P.Champagne, { CastShadow = false, CanCollide = false })
				B.part(roads, CFrame.new(t, rt + 0.005, line), Vector3.new(8, 0.02, 0.5), P.Champagne, { CastShadow = false, CanCollide = false })
			end
		end
	end
	-- crosswalks next to every intersection
	for _, lx in L.Lines do
		for _, lz in L.Lines do
			for k = -4, 4 do
				local o = k * 2.4
				for _, s in { -1, 1 } do
					B.part(roads, CFrame.new(lx + o, rt + 0.006, lz + s * (L.RoadWidth / 2 + 4)), Vector3.new(1.2, 0.02, 5), P.Ivory, { CastShadow = false, CanCollide = false })
					B.part(roads, CFrame.new(lx + s * (L.RoadWidth / 2 + 4), rt + 0.006, lz + o), Vector3.new(5, 0.02, 1.2), P.Ivory, { CastShadow = false, CanCollide = false })
				end
			end
		end
	end

	-- ============ Blocks / sidewalks / furniture ============
	local blocks = B.folder(C, "Blocks")
	local furniture = B.folder(C, "StreetFurniture")
	local sw = L.SidewalkWidth
	local lampCount = 0
	for _, cx in L.Cells do
		for _, cz in L.Cells do
			local sizeX, sizeZ = cx.s, cz.s
			local center = Vector3.new(cx.c, 0, cz.c)
			local fullX, fullZ = sizeX + sw * 2, sizeZ + sw * 2
			B.part(blocks, CFrame.new(cx.c, L.Walk - 0.1, cz.c), Vector3.new(fullX, 0.2, fullZ), P.Pearl, { Material = Enum.Material.Concrete, Name = "Sidewalk", CastShadow = false })
			-- curb trim
			B.part(blocks, CFrame.new(cx.c, L.Walk - 0.11, cz.c), Vector3.new(fullX + 0.6, 0.18, fullZ + 0.6), P.Mist, { Material = Enum.Material.Concrete, CastShadow = false, Name = "Curb" })
			-- lamps & trees along each side
			local sides = {
				{ Vector3.new(1, 0, 0), Vector3.new(0, 0, fullZ / 2 - 1.6), fullX, Vector3.new(0, 0, 1) },
				{ Vector3.new(1, 0, 0), Vector3.new(0, 0, -fullZ / 2 + 1.6), fullX, Vector3.new(0, 0, -1) },
				{ Vector3.new(0, 0, 1), Vector3.new(fullX / 2 - 1.6, 0, 0), fullZ, Vector3.new(1, 0, 0) },
				{ Vector3.new(0, 0, 1), Vector3.new(-fullX / 2 + 1.6, 0, 0), fullZ, Vector3.new(-1, 0, 0) },
			}
			for _, sd in sides do
				local along, off, len, outward = sd[1], sd[2], sd[3], sd[4]
				local n = math.floor((len - 24) / 36)
				for i = 0, n do
					local t = -((n * 36) / 2) + i * 36
					local pos = center + off + along * t + Vector3.new(0, L.Walk, 0)
					lampCount += 1
					lamp(B, P, furniture, pos, outward, lampCount % 2 == 0)
					if i < n then
						local tp = center + off - outward * 1.8 + along * (t + 18) + Vector3.new(0, L.Walk, 0)
						B.part(furniture, CFrame.new(tp + Vector3.new(0, 0.02, 0)), Vector3.new(4, 0.08, 4), P.WoodDark, { Material = Enum.Material.Ground, CastShadow = false })
						B.tree(furniture, tp, r.range(0.75, 0.95), r.pick({ P.Leaf, P.Sage:Lerp(P.Leaf, 0.5), P.LeafDark }), P.WoodDark, r)
					end
				end
			end

			local district = L.Districts[L.key(cx.c, cz.c)]
			if not district then
				-- skyline filler
				local roll = r.next()
				local bcf = CFrame.new(cx.c, L.Walk, cz.c)
				if roll < 0.4 then
					tower(B, P, blocks, bcf, r.range(40, 56), r.range(40, 56), r.range(80, 150), r)
					planter(B, P, blocks, center + Vector3.new(-38, L.Walk, -38), 8, r)
					planter(B, P, blocks, center + Vector3.new(38, L.Walk, 38), 8, r)
				elseif roll < 0.75 then
					local face = math.abs(cz.c) > math.abs(cx.c) and 0 or math.pi / 2
					local rot = CFrame.Angles(0, face, 0)
					classicBuilding(B, P, blocks, bcf * rot * CFrame.new(-24, 0, 0), 44, 60, r.int(3, 6), r)
					classicBuilding(B, P, blocks, bcf * rot * CFrame.new(24, 0, 0), 44, 60, r.int(3, 6), r)
				else
					local face = (cz.c > 0) and math.pi or 0
					if math.abs(cx.c) > math.abs(cz.c) then
						face = cx.c > 0 and math.pi / 2 or -math.pi / 2
					end
					local rot = CFrame.Angles(0, face, 0)
					townhouses(B, P, blocks, bcf * rot * CFrame.new(0, 0, -22), 96, 4, r)
					townhouses(B, P, blocks, bcf * rot * CFrame.Angles(0, math.pi, 0) * CFrame.new(0, 0, -22), 96, 4, r)
				end
			end
		end
	end

	-- ============ Plaza ============
	local plaza = B.folder(C, "Plaza")
	B.part(plaza, CFrame.new(0, L.Walk - 0.04, 0), Vector3.new(184, 0.2, 184), P.Ivory, { Material = Enum.Material.Marble, Name = "PlazaFloor", CastShadow = false })
	-- inlay border + diagonal pattern
	for _, s in { -1, 1 } do
		B.part(plaza, CFrame.new(0, L.Walk + 0.07, s * 88), Vector3.new(176, 0.02, 1.2), P.RoseGold, { Material = Enum.Material.Metal, CanCollide = false, CastShadow = false })
		B.part(plaza, CFrame.new(s * 88, L.Walk + 0.07, 0), Vector3.new(1.2, 0.02, 176), P.RoseGold, { Material = Enum.Material.Metal, CanCollide = false, CastShadow = false })
	end
	-- spawn pads
	for i, x in { -62, 62, 0 } do
		local z = i == 3 and 86 or 80
		local pad = Instance.new("SpawnLocation")
		pad.Name = "Spawn"
		pad.Anchored = true
		pad.Shape = Enum.PartType.Cylinder
		pad.Size = Vector3.new(0.3, 10, 10)
		pad.CFrame = CFrame.new(x, L.Walk + 0.15, z) * CFrame.Angles(0, 0, math.pi / 2)
		pad.Color = P.Champagne
		pad.Material = Enum.Material.Marble
		pad.Neutral = true
		pad.Duration = 0
		pad.AllowTeamChangeOnTouch = false
		pad.Parent = plaza
		require(script.Parent.Stage).arc(B, plaza, Vector3.new(x, L.Walk + 0.32, z), 4.7, -180, 180, 20, 0.15, P.NeonPink)
	end
	-- plaza planters, lamps and benches
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			planter(B, P, plaza, Vector3.new(sx * 80, L.Walk, sz * 80), 10, r)
			B.tree(plaza, Vector3.new(sx * 80, L.Walk + 2, sz * 80), 0.9, P.Leaf, P.WoodDark, r)
		end
		for z = -40, 40, 40 do
			lamp(B, P, plaza, Vector3.new(sx * 84, L.Walk, z), Vector3.new(-sx, 0, 0), true)
			local pos = Vector3.new(sx * 78, L.Walk, z + 20)
			bench(B, P, plaza, CFrame.lookAt(pos, pos + Vector3.new(-sx, 0, 0)))
		end
	end
	-- monument sign at the south entrance
	local mon = B.cushion(plaza, CFrame.new(0, L.Walk + 2.5, 90.5), Vector3.new(30, 5, 3), 0.6, P.Plum, {})
	local monFace = B.part(plaza, CFrame.new(0, L.Walk + 2.6, 92.05), Vector3.new(27, 3.6, 0.1), P.Plum, { CanCollide = false })
	Screens.sign(B.gui(monFace, Enum.NormalId.Back, 24), B, "AURA RUNWAY CITY", { Colors = { P.Plum, P.Aubergine } })
	B.neonLine(plaza, Vector3.new(-14.8, L.Walk + 5.05, 92.1), Vector3.new(14.8, L.Walk + 5.05, 92.1), 0.14, P.NeonGold)
	mon.Name = "Monument"

	-- ============ Distant edge hedge ============
	local e = L.Extent + 14
	for _, s in { -1, 1 } do
		B.soft(C, CFrame.new(0, 2.5, s * e), Vector3.new(e * 2, 4, 4), 2, P.LeafDark, { Material = Enum.Material.Grass })
		B.soft(C, CFrame.new(s * e, 2.5, 0), Vector3.new(4, 4, e * 2), 2, P.LeafDark, { Material = Enum.Material.Grass })
	end
	return C
end

return City
