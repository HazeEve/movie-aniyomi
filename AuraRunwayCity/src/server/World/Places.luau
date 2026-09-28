--!nonstrict
-- Roleplay districts: café, hotel, boutiques, salon & florist, park, car
-- dealership and residences. Everything is interactable (sit, sleep, eat,
-- pick up, change outfit, spawn & drive cars).
local Places = {}

local function faceCF(center: Vector3, dir: Vector3): CFrame
	return CFrame.lookAt(center, center + dir)
end

local function umbrellaTable(B, P, Rooms, parent, pos: Vector3, canopy: Color3)
	local cf = CFrame.new(pos)
	Rooms.table(B, P, parent, cf, P.Ivory, 3, P.Blush)
	B.vcyl(parent, pos + Vector3.new(0, 5, 0), 4, 0.25, P.Ivory, { Material = Enum.Material.Metal })
	B.vcyl(parent, pos + Vector3.new(0, 7.1, 0), 0.3, 8, canopy, { Material = Enum.Material.Fabric, CanCollide = false })
	B.vcyl(parent, pos + Vector3.new(0, 7.45, 0), 0.4, 5, canopy, { Material = Enum.Material.Fabric, CanCollide = false })
	B.ball(parent, pos + Vector3.new(0, 7.8, 0), 0.8, P.Gold, { Material = Enum.Material.Metal, CanCollide = false })
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		B.ball(parent, pos + Vector3.new(math.cos(a) * 3.9, 6.9, math.sin(a) * 3.9), 0.55, k % 2 == 0 and P.Ivory or canopy, { Material = Enum.Material.Fabric, CanCollide = false, CastShadow = false })
	end
end

local function rack(B, P, parent, cf: CFrame, r)
	local metal = { Material = Enum.Material.Metal }
	for _, s in { -2.4, 2.4 } do
		B.vcyl(parent, (cf * CFrame.new(s, 2.8, 0)).Position, 5.6, 0.25, P.Gold, metal)
		B.part(parent, cf * CFrame.new(s, 0.1, 0), Vector3.new(0.3, 0.2, 2), P.Gold, metal)
	end
	B.cyl(parent, cf * CFrame.new(0, 5.4, 0), 5, 0.22, P.Gold, metal)
	local colors = { P.Blush, P.Lavender, P.Ivory, P.Rose, P.Champagne, P.Powder, P.Plum, P.Sage }
	for i = 0, 6 do
		local x = -1.8 + i * 0.6
		local c = colors[((i + (r and r.int(0, 7) or 0)) % #colors) + 1]
		B.part(parent, cf * CFrame.new(x, 4.1, 0), Vector3.new(0.2, 2.4, 1.8), c, { Material = Enum.Material.Fabric, CanCollide = false })
		B.part(parent, cf * CFrame.new(x, 5.2, 0), Vector3.new(0.1, 0.35, 0.6), P.Gold, { CanCollide = false, Material = Enum.Material.Metal })
	end
end

-- decorative dress form
local function dressForm(B, P, parent, pos: Vector3, dress: Color3)
	B.vcyl(parent, pos + Vector3.new(0, 0.1, 0), 0.2, 2, P.Gold, { Material = Enum.Material.Metal })
	B.vcyl(parent, pos + Vector3.new(0, 1.4, 0), 2.6, 0.2, P.Gold, { Material = Enum.Material.Metal })
	B.vcyl(parent, pos + Vector3.new(0, 3.3, 0), 1.6, 2.6, dress, { Material = Enum.Material.Fabric })
	B.vcyl(parent, pos + Vector3.new(0, 4.5, 0), 1, 1.8, dress, { Material = Enum.Material.Fabric })
	B.ball(parent, pos + Vector3.new(0, 5.3, 0), 1.5, P.Ivory, {})
	B.vcyl(parent, pos + Vector3.new(0, 6.1, 0), 0.4, 0.3, P.Gold, { Material = Enum.Material.Metal })
end

local function menuBoard(B, P, parent, cf: CFrame, title: string, lines: { string })
	local frame = B.rounded(parent, cf, Vector3.new(12, 6, 0.4), 0.2, P.Plum, {})
	local face = B.part(parent, cf * CFrame.new(0, 0, -0.25), Vector3.new(11.4, 5.4, 0.05), P.Plum, { CanCollide = false })
	local bg = B.frame(B.gui(face, Enum.NormalId.Front, 30), { Size = UDim2.fromScale(1, 1), BackgroundColor3 = P.Plum })
	B.text(bg, title, { Size = UDim2.fromScale(1, 0.25), FontFace = B.Fonts.Luxe(), TextColor3 = P.Champagne })
	B.text(bg, table.concat(lines, "   •   "), { Position = UDim2.fromScale(0.05, 0.3), Size = UDim2.fromScale(0.9, 0.62), TextColor3 = P.Ivory, FontFace = B.Fonts.Body(), TextWrapped = true })
	return frame
end

-- ================= CAFÉ =================
function Places.cafe(B, P, L, Screens, Rooms, root, center: Vector3, travel)
	local F = B.folder(root, "BlushCafe")
	local cf = faceCF(center + Vector3.new(0, L.Floor, -14), Vector3.new(0, 0, 1))
	local w, d = 64, 44
	Rooms.shell(B, P, F, cf, w, d, {
		Name = "CafeShell",
		Height = 14,
		Wall = P.Blush,
		Trim = P.Ivory,
		Floor = Color3.fromHex("E9DCCB"),
		FloorMaterial = Enum.Material.WoodPlanks,
		Doors = { { "front", 0, 10, 10 } },
		Windows = { { "front", -19, 18, 8, 1.5 }, { "front", 19, 18, 8, 1.5 }, { "left", 0, 20, 7, 2.5 }, { "right", 0, 20, 7, 2.5 } },
	})
	Rooms.entrance(B, P, F, cf * CFrame.new(0, 0, -d / 2), 10, "Blush Café", P.Rose, Screens)
	-- counter with food givers
	local ccf = cf * CFrame.new(0, 0, d / 2 - 7)
	Rooms.counter(B, P, F, ccf, 34, P.Plum)
	local foods = {
		{ "Coffee", "Latte" }, { "Boba", "Boba Tea" }, { "Croissant" }, { "Donut" }, { "Macaron", "Macarons" },
		{ "Cake", "Cake Slice" }, { "Cupcake" }, { "Burger" }, { "Pizza", "Pizza Slice" }, { "IceCream", "Ice Cream" },
	}
	for i, f in foods do
		local x = -15.3 + (i - 1) * 3.4
		Rooms.giver(B, P, F, ccf * CFrame.new(x, 4.05, 0), f[1], "Food", f[2])
	end
	menuBoard(B, P, F, cf * CFrame.new(0, 10, d / 2 - 0.9), "MENU", { "Latte", "Boba", "Croissant", "Donut", "Macarons", "Cake", "Cupcake", "Burger", "Pizza", "Ice Cream" })
	-- pastry case
	local pc = cf * CFrame.new(-24, 0, d / 2 - 7)
	B.cushion(F, pc * CFrame.new(0, 1.6, 0), Vector3.new(8, 3.2, 3), 0.3, P.Ivory, {})
	B.part(F, pc * CFrame.new(0, 4.4, 0), Vector3.new(7.6, 2.4, 2.6), Color3.fromHex("E6F2F7"), { Material = Enum.Material.Glass, Transparency = 0.6 })
	for k = 0, 5 do
		B.ball(F, (pc * CFrame.new(-3 + k * 1.2, 3.8, 0)).Position, 0.9, ({ P.Rose, P.Butter, P.Lavender, P.Peach, P.Mint, P.Blush })[k + 1], { Material = Enum.Material.Fabric })
	end
	-- tables
	for _, x in { -18, -6, 6, 18 } do
		for _, z in { -10, 2 } do
			Rooms.table(B, P, F, cf * CFrame.new(x, 0, z), P.Ivory, 3, P.Lavender)
		end
	end
	-- pendant lamps
	for _, x in { -18, -6, 6, 18 } do
		local lp = cf * CFrame.new(x, 11, -4)
		B.vcyl(F, (lp * CFrame.new(0, 1.6, 0)).Position, 3, 0.1, P.Gold, { Material = Enum.Material.Metal })
		local shade = B.ball(F, lp.Position, 1.6, P.Champagne, { Material = Enum.Material.Neon, CanCollide = false })
		B.light(shade, "PointLight", { Range = 12, Brightness = 0.8, Color = Color3.fromHex("FFE3C8"), Shadows = false })
	end
	-- terrace with umbrellas
	local terr = B.folder(F, "Terrace")
	B.part(terr, cf * CFrame.new(0, -0.1, -d / 2 - 14), Vector3.new(w, 0.2, 26), Color3.fromHex("E9DCCB"), { Material = Enum.Material.WoodPlanks, CastShadow = false })
	local canopies = { P.Rose, P.Lavender, P.Sage, P.RoseGold }
	local i = 0
	for _, x in { -22, -8, 8, 22 } do
		i += 1
		umbrellaTable(B, P, Rooms, terr, (cf * CFrame.new(x, 0, -d / 2 - 14)).Position, canopies[i])
	end
	for _, x in { -30, 30 } do
		require(script.Parent.City).planter(B, P, terr, (cf * CFrame.new(x, 0, -d / 2 - 4)).Position, 4, nil)
	end
	Rooms.travelPoint(B, travel, "Blush Café", cf * CFrame.new(0, 3, -d / 2 - 28) * CFrame.Angles(0, math.pi, 0), 3)
end

-- ================= HOTEL =================
function Places.hotel(B, P, L, Screens, Rooms, root, center: Vector3, travel)
	local F = B.folder(root, "GrandHotel")
	local cf = faceCF(center + Vector3.new(0, L.Floor, -8), Vector3.new(0, 0, 1))
	local w, d, h = 90, 64, 16
	local roomDoors = {}
	Rooms.shell(B, P, F, cf, w, d, {
		Name = "HotelShell",
		Height = h,
		Wall = P.Champagne,
		Trim = P.Gold,
		Floor = P.Pearl,
		Doors = { { "front", 0, 12, 11 } },
		Windows = { { "front", -28, 22, 10, 1.5 }, { "front", 28, 22, 10, 1.5 } },
	})
	-- tower above (decorative)
	require(script.Parent.City).tower(B, P, F, cf * CFrame.new(0, h + 1.3, 12), 66, 32, 80, B.rng(4242))
	Rooms.entrance(B, P, F, cf * CFrame.new(0, 0, -d / 2), 12, "The Grand Aura Hotel", P.Plum, Screens)
	-- red-carpet steps
	B.part(F, cf * CFrame.new(0, 0.05, -d / 2 - 6), Vector3.new(8, 0.1, 12), P.Rose, { Material = Enum.Material.Fabric, CanCollide = false })
	for _, s in { -1, 1 } do
		B.vcyl(F, (cf * CFrame.new(s * 5, 1.6, -d / 2 - 10)).Position, 3.2, 0.3, P.Gold, { Material = Enum.Material.Metal })
		B.ball(F, (cf * CFrame.new(s * 5, 3.3, -d / 2 - 10)).Position, 0.6, P.Gold, { Material = Enum.Material.Metal })
	end
	-- lobby
	Rooms.counter(B, P, F, cf * CFrame.new(-26, 0, -12), 16, P.Plum)
	local bell = B.ball(F, (cf * CFrame.new(-26, 4.2, -12)).Position, 0.6, P.Gold, { Material = Enum.Material.Metal })
	bell.Name = "Bell"
	Rooms.sofa(B, P, F, cf * CFrame.new(18, 0, -22) * CFrame.Angles(0, math.pi, 0), P.Lavender, 9)
	Rooms.sofa(B, P, F, cf * CFrame.new(18, 0, -8), P.Lavender, 9)
	Rooms.table(B, P, F, cf * CFrame.new(18, 0, -15), P.Ivory, 0, P.Blush)
	-- chandelier
	local ch = cf * CFrame.new(0, h - 4, -16)
	require(script.Parent.Stage).arc(B, F, ch.Position, 3.4, -180, 180, 16, 0.25, P.Champagne)
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		B.ball(F, ch.Position + Vector3.new(math.cos(a) * 3.4, -0.7, math.sin(a) * 3.4), 0.5, P.Ivory, { Material = Enum.Material.Neon, CanCollide = false })
	end
	B.vcyl(F, ch.Position + Vector3.new(0, 2, 0), 4, 0.2, P.Gold, { Material = Enum.Material.Metal })
	-- corridor wall with room doors
	local wallA = (cf * CFrame.new(-w / 2, 0, -2)).Position
	local wallB = (cf * CFrame.new(w / 2, 0, -2)).Position
	local openings = {}
	for i = 0, 3 do
		local x = -w / 2 + w * (i + 0.5) / 4
		table.insert(openings, { at = x + w / 2, width = 5, height = 9 })
		table.insert(roomDoors, x)
	end
	B.wall(F, wallA, wallB, h, 0.6, P.Ivory, openings, {})
	-- room partitions + rooms
	local blankets = { P.Blush, P.Lavender, P.Sage, P.Powder }
	for i = 1, 3 do
		local x = -w / 2 + w * i / 4
		B.wall(F, (cf * CFrame.new(x, 0, -2)).Position, (cf * CFrame.new(x, 0, d / 2)).Position, h, 0.6, P.Ivory, {}, {})
	end
	for i, x in roomDoors do
		B.part(F, cf * CFrame.new(x, 0.02, 14), Vector3.new(14, 0.05, 16), blankets[i]:Lerp(P.Ivory, 0.3), { Material = Enum.Material.Fabric, CanCollide = false, CastShadow = false })
		Rooms.bed(B, P, F, cf * CFrame.new(x, 0, d / 2 - 6.5), blankets[i])
		Rooms.sofa(B, P, F, cf * CFrame.new(x + 6, 0, 3) * CFrame.Angles(0, math.pi / 2, 0), P.Champagne, 6)
		local tvcf = cf * CFrame.new(x - 9.5, 6, 12) * CFrame.Angles(0, -math.pi / 2, 0)
		B.rounded(F, tvcf, Vector3.new(6, 3.6, 0.3), 0.12, P.Charcoal, {})
		local screen = B.part(F, tvcf * CFrame.new(0, 0, -0.18), Vector3.new(5.6, 3.2, 0.05), Color3.new(0, 0, 0), { CanCollide = false })
		Screens.galaxy(B.gui(screen, Enum.NormalId.Front, 30, { Brightness = 1.2 }), B, { Seed = 90 + i, Title = "AURA TV", Skyline = true })
		local plate = B.part(F, cf * CFrame.new(x + 3.5, 8, -2.35), Vector3.new(2.6, 0.9, 0.1), P.Gold, { CanCollide = false, Material = Enum.Material.Metal })
		B.text(B.gui(plate, Enum.NormalId.Front, 40), "Suite " .. (100 + i), { TextColor3 = P.Plum })
	end
	-- lounge seating by windows
	for _, x in { -36, 36 } do
		Rooms.sofa(B, P, F, cf * CFrame.new(x, 0, -26) * CFrame.Angles(0, math.pi, 0), P.Blush, 7)
	end
	Rooms.travelPoint(B, travel, "Grand Hotel", cf * CFrame.new(0, 3, -d / 2 - 16) * CFrame.Angles(0, math.pi, 0), 4)
end

-- ================= BOUTIQUES =================
function Places.boutiques(B, P, L, Screens, Rooms, root, center: Vector3, travel)
	local F = B.folder(root, "Boutiques")
	local base = faceCF(center + Vector3.new(0, L.Floor, 0), Vector3.new(1, 0, 0))
	local shops = {
		{ "Maison Blush", P.Blush, P.Rose, { { "ShoppingBag", "Shopping Bag" }, { "Handbag" } } },
		{ "Lilac Luxe", P.Lilac, P.Violet, { { "Perfume" }, { "Sunglasses", "Sunglasses Case" } } },
		{ "Champagne & Co", P.Champagne, P.Gold, { { "Jewelry", "Jewelry Box" }, { "ShoppingBag", "Shopping Bag" } } },
	}
	local r = B.rng(77)
	for i, s in shops do
		local cf = base * CFrame.new((i - 2) * 33, 0, 8)
		local w, d = 30, 36
		Rooms.shell(B, P, F, cf, w, d, {
			Name = s[1],
			Height = 15,
			Wall = s[2],
			Trim = P.Ivory,
			Floor = P.Ivory,
			Doors = { { "front", 0, 8, 10 } },
			Windows = { { "front", -9.5, 8, 9, 1.2 }, { "front", 9.5, 8, 9, 1.2 } },
		})
		Rooms.entrance(B, P, F, cf * CFrame.new(0, 0, -d / 2), 8, s[1], s[3], Screens)
		rack(B, P, F, cf * CFrame.new(-8, 0, 2) * CFrame.Angles(0, math.pi / 2, 0), r)
		rack(B, P, F, cf * CFrame.new(8, 0, 2) * CFrame.Angles(0, math.pi / 2, 0), r)
		dressForm(B, P, F, (cf * CFrame.new(-10, 0, -13)).Position, s[3])
		dressForm(B, P, F, (cf * CFrame.new(10, 0, -13)).Position, P.Ivory)
		Rooms.catalogSpot(B, P, F, cf * CFrame.new(-11, 0, d / 2 - 1.2), "Try Outfits")
		Rooms.catalogSpot(B, P, F, cf * CFrame.new(11, 0, d / 2 - 1.2), "Try Outfits")
		local ccf = cf * CFrame.new(0, 0, d / 2 - 6)
		Rooms.counter(B, P, F, ccf, 10, s[3])
		for k, it in s[4] do
			Rooms.giver(B, P, F, ccf * CFrame.new(-2.5 + (k - 1) * 5, 4.05, 0), it[1], "Hold", it[2])
		end
		Rooms.sofa(B, P, F, cf * CFrame.new(0, 0, 8) * CFrame.Angles(0, math.pi, 0), P.Ivory, 6)
	end
	Rooms.travelPoint(B, travel, "Boutiques", base * CFrame.new(0, 3, -24) * CFrame.Angles(0, math.pi, 0), 5)
end

-- ================= SALON & FLORIST =================
function Places.salon(B, P, L, Screens, Rooms, root, center: Vector3, travel)
	local F = B.folder(root, "SalonRow")
	local base = faceCF(center + Vector3.new(0, L.Floor, 0), Vector3.new(-1, 0, 0))
	-- Glow Salon
	local cf = base * CFrame.new(-24, 0, 8)
	Rooms.shell(B, P, F, cf, 44, 36, {
		Name = "GlowSalon",
		Height = 15,
		Wall = P.Lilac,
		Trim = P.Gold,
		Floor = P.Ivory,
		Doors = { { "front", 0, 8, 10 } },
		Windows = { { "front", -13, 12, 9, 1.2 }, { "front", 13, 12, 9, 1.2 } },
	})
	Rooms.entrance(B, P, F, cf * CFrame.new(0, 0, -18), 8, "Glow Salon", P.Violet, Screens)
	for k = 0, 3 do
		local x = -15 + k * 10
		Rooms.catalogSpot(B, P, F, cf * CFrame.new(x, 0, 16.8), "Style Hair & Makeup")
		local chair = cf * CFrame.new(x, 0, 12) * CFrame.Angles(0, math.pi, 0)
		B.vcyl(F, (chair * CFrame.new(0, 0.9, 0)).Position, 1.8, 0.6, P.Gold, { Material = Enum.Material.Metal })
		B.seat(F, chair * CFrame.new(0, 2, 0), Vector3.new(2.6, 0.7, 2.6), P.Rose, {})
		B.cushion(F, chair * CFrame.new(0, 3.8, 1.2), Vector3.new(2.6, 3.2, 0.6), 0.25, P.Rose, { Material = Enum.Material.Fabric })
	end
	Rooms.sofa(B, P, F, cf * CFrame.new(0, 0, -8), P.Blush, 10)
	-- Petal Florist
	local fcf = base * CFrame.new(24, 0, 8)
	Rooms.shell(B, P, F, fcf, 44, 36, {
		Name = "PetalFlorist",
		Height = 15,
		Wall = P.Sage,
		Trim = P.Ivory,
		Floor = Color3.fromHex("E9DCCB"),
		FloorMaterial = Enum.Material.WoodPlanks,
		Doors = { { "front", 0, 8, 10 } },
		Windows = { { "front", -13, 12, 9, 1.2 }, { "front", 13, 12, 9, 1.2 } },
	})
	Rooms.entrance(B, P, F, fcf * CFrame.new(0, 0, -18), 8, "Petal Florist", P.Leaf, Screens)
	local ccf = fcf * CFrame.new(0, 0, 11)
	Rooms.counter(B, P, F, ccf, 18, P.Ivory)
	local flowers = { { "Bouquet", "Rose Bouquet" }, { "Tulips" }, { "Sunflower" }, { "Lilies", "Lily Bunch" } }
	for k, f in flowers do
		Rooms.giver(B, P, F, ccf * CFrame.new(-6.75 + (k - 1) * 4.5, 4.05, 0), f[1], "Hold", f[2])
	end
	local fc = { P.Rose, P.Blush, P.Butter, P.Lavender, P.Ivory, P.Peach }
	for k = 0, 5 do
		local bucket = fcf * CFrame.new(-16 + k * 6.4, 0, -10)
		B.vcyl(F, (bucket * CFrame.new(0, 1, 0)).Position, 2, 2.2, P.Champagne, { Material = Enum.Material.Metal })
		for j = 0, 4 do
			local a = j / 5 * math.pi * 2
			B.ball(F, (bucket * CFrame.new(math.cos(a) * 0.6, 2.6 + (j % 2) * 0.4, math.sin(a) * 0.6)).Position, 0.9, fc[k + 1], { Material = Enum.Material.Fabric, CanCollide = false })
		end
	end
	Rooms.travelPoint(B, travel, "Salon & Florist", base * CFrame.new(0, 3, -24) * CFrame.Angles(0, math.pi, 0), 6)
end

-- ================= PARK =================
function Places.park(B, P, L, Screens, Rooms, root, center: Vector3, travel)
	local F = B.folder(root, "Park")
	local City = require(script.Parent.City)
	local y = L.Floor
	local c = Vector3.new(center.X, y, center.Z)
	B.part(F, CFrame.new(c.X, y - 0.1, c.Z), Vector3.new(100, 0.2, 100), P.Grass:Lerp(P.Leaf, 0.2), { Material = Enum.Material.Grass, CastShadow = false, Name = "Lawn" })
	local path = Color3.fromHex("E6DDD3")
	B.part(F, CFrame.new(c.X, y + 0.01, c.Z), Vector3.new(100, 0.2, 8), path, { Material = Enum.Material.Cobblestone, CastShadow = false })
	B.part(F, CFrame.new(c.X, y + 0.012, c.Z), Vector3.new(8, 0.2, 100), path, { Material = Enum.Material.Cobblestone, CastShadow = false })
	B.vcyl(F, Vector3.new(c.X, y + 0.015, c.Z), 0.2, 34, path, { Material = Enum.Material.Cobblestone, CastShadow = false })
	-- grand fountain
	B.vcyl(F, c + Vector3.new(0, 1.1, 0), 2.2, 26, P.Ivory, { Material = Enum.Material.Marble })
	B.vcyl(F, c + Vector3.new(0, 2.25, 0), 0.1, 24.4, Color3.fromHex("9FD3E6"), { Material = Enum.Material.Glass, Transparency = 0.3, Reflectance = 0.35, CanCollide = false })
	B.vcyl(F, c + Vector3.new(0, 4.5, 0), 4.6, 3, P.Ivory, { Material = Enum.Material.Marble })
	B.vcyl(F, c + Vector3.new(0, 7, 0), 1, 11, P.Ivory, { Material = Enum.Material.Marble })
	B.vcyl(F, c + Vector3.new(0, 7.52, 0), 0.06, 10, Color3.fromHex("9FD3E6"), { Material = Enum.Material.Glass, Transparency = 0.3, CanCollide = false })
	B.vcyl(F, c + Vector3.new(0, 9, 0), 3, 1.6, P.Ivory, { Material = Enum.Material.Marble })
	local top = B.ball(F, c + Vector3.new(0, 11, 0), 2, P.Gold, { Material = Enum.Material.Metal })
	for _, setup in { { top, 60, 14 }, { top, 30, 8 } } do
		local pe = Instance.new("ParticleEmitter")
		pe.Rate = setup[2]
		pe.Speed = NumberRange.new(setup[3], setup[3] + 3)
		pe.SpreadAngle = Vector2.new(25, 25)
		pe.Lifetime = NumberRange.new(1.2, 1.6)
		pe.Acceleration = Vector3.new(0, -30, 0)
		pe.Size = NumberSequence.new(0.7, 0.25)
		pe.Transparency = NumberSequence.new(0.15, 0.9)
		pe.Color = ColorSequence.new(Color3.fromHex("E6F7FF"))
		pe.LightEmission = 0.35
		pe.EmissionDirection = Enum.NormalId.Top
		pe.Parent = setup[1]
	end
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2 + math.pi / 8
		local pos = c + Vector3.new(math.cos(a) * 19, 0, math.sin(a) * 19)
		City.bench(B, P, F, CFrame.lookAt(pos, Vector3.new(c.X, pos.Y, c.Z)) * CFrame.Angles(0, math.pi, 0))
	end
	-- trees & flower beds
	local r = B.rng(99)
	for _, q in { { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		local qc = c + Vector3.new(q[1] * 28, 0, q[2] * 28)
		for k = 1, 3 do
			local off = Vector3.new(r.range(-12, 12), 0, r.range(-12, 12))
			B.tree(F, qc + off, r.range(0.9, 1.25), r.pick({ P.Leaf, P.LeafDark, P.Sage:Lerp(P.Leaf, 0.4) }), P.WoodDark, r)
		end
		local fb = qc + Vector3.new(-q[1] * 8, 0, -q[2] * 8)
		B.vcyl(F, fb + Vector3.new(0, 0.3, 0), 0.6, 9, P.WoodDark, { Material = Enum.Material.Ground })
		for k = 1, 14 do
			local a = r.next() * math.pi * 2
			local rad = r.range(0.5, 3.8)
			B.ball(F, fb + Vector3.new(math.cos(a) * rad, 0.9, math.sin(a) * rad), 0.9, r.pick({ P.Rose, P.Blush, P.Lavender, P.Butter, P.Ivory }), { Material = Enum.Material.Fabric, CanCollide = false })
		end
	end
	-- picnic blankets (sit spots)
	for k, pos in { c + Vector3.new(-36, 0, 14), c + Vector3.new(36, 0, -14), c + Vector3.new(14, 0, 38) } do
		B.part(F, CFrame.new(pos + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, k, 0), Vector3.new(8, 0.1, 6), ({ P.Rose, P.Lavender, P.Butter })[k], { Material = Enum.Material.Fabric, CanCollide = false })
		for j = -1, 1, 2 do
			local s = B.seat(F, CFrame.new(pos + Vector3.new(j * 2, 0.25, 0)) * CFrame.Angles(0, k + (j > 0 and math.pi or 0), 0), Vector3.new(2, 0.3, 2), P.Ivory, {})
			s.Transparency = 1
		end
		B.cushion(F, CFrame.new(pos + Vector3.new(0, 0.6, 0)), Vector3.new(2, 1, 1.4), 0.2, P.WoodDark, { Material = Enum.Material.Wood })
	end
	-- gazebo
	local gz = c + Vector3.new(-30, 0, -30)
	B.vcyl(F, gz + Vector3.new(0, 0.5, 0), 1, 20, P.Ivory, { Material = Enum.Material.Marble })
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		B.vcyl(F, gz + Vector3.new(math.cos(a) * 8.5, 6, math.sin(a) * 8.5), 10, 0.8, P.Ivory, { Material = Enum.Material.Marble })
	end
	B.vcyl(F, gz + Vector3.new(0, 11.3, 0), 0.8, 20, P.Blush, {})
	B.vcyl(F, gz + Vector3.new(0, 12.3, 0), 1.2, 15, P.Blush, {})
	B.vcyl(F, gz + Vector3.new(0, 13.5, 0), 1.2, 9, P.Blush, {})
	B.ball(F, gz + Vector3.new(0, 14.6, 0), 2, P.Gold, { Material = Enum.Material.Metal })
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2
		local pos = gz + Vector3.new(math.cos(a) * 6, 1, math.sin(a) * 6)
		City.bench(B, P, F, CFrame.lookAt(pos, Vector3.new(gz.X, pos.Y, gz.Z)) * CFrame.Angles(0, math.pi, 0))
	end
	-- carts
	local function cart(pos: Vector3, facing: Vector3, color: Color3, title: string, items)
		local ccf = CFrame.lookAt(pos, pos + facing)
		B.cushion(F, ccf * CFrame.new(0, 2.4, 0), Vector3.new(7, 3, 3.6), 0.4, color, {})
		for _, s in { -1, 1 } do
			B.cyl(F, ccf * CFrame.new(s * 2.6, 0.9, 1.9), 0.4, 1.8, P.Charcoal, {})
		end
		for _, s in { -3.2, 3.2 } do
			B.vcyl(F, (ccf * CFrame.new(s, 6, 1.2)).Position, 5, 0.2, P.Ivory, { Material = Enum.Material.Metal })
		end
		B.wedge(F, ccf * CFrame.new(0, 9, 0.2) * CFrame.Angles(0, math.pi, 0), Vector3.new(8, 1.2, 4.4), P.Ivory, { Material = Enum.Material.Fabric })
		local sign = B.part(F, ccf * CFrame.new(0, 7, -0.6), Vector3.new(5, 1.4, 0.2), P.Plum, { CanCollide = false })
		Screens.sign(B.gui(sign, Enum.NormalId.Front, 30), B, title, {})
		for k, it in items do
			Rooms.giver(B, P, F, ccf * CFrame.new(-1.8 + (k - 1) * 3.6, 4.05, -0.6), it[1], it[2], it[3])
		end
	end
	cart(c + Vector3.new(10, 0, -24), Vector3.new(0, 0, 1), P.Blush, "Gelato", { { "IceCream", "Food", "Gelato" }, { "Popsicle", "Food" } })
	cart(c + Vector3.new(-10, 0, 24), Vector3.new(0, 0, -1), P.Powder, "Balloons", { { "Balloon", "Hold" }, { "HeartBalloon", "Hold", "Heart Balloon" } })
	cart(c + Vector3.new(24, 0, 10), Vector3.new(-1, 0, 0), P.Butter, "Snacks", { { "Popcorn", "Food" }, { "Lemonade", "Food" } })
	-- string lights along the main path
	for _, s in { -1, 1 } do
		for k = -2, 2 do
			local pos = c + Vector3.new(k * 18, 0, s * 6)
			B.vcyl(F, pos + Vector3.new(0, 4, 0), 8, 0.3, P.Plum, { Material = Enum.Material.Metal })
			if k < 2 then
				for j = 1, 5 do
					local t = j / 6
					local p = pos + Vector3.new(18 * t, 8 - math.sin(t * math.pi) * 1.4, 0)
					B.ball(F, p, 0.45, ({ P.NeonGold, P.NeonPink, P.Champagne })[(j % 3) + 1], { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
				end
			end
		end
	end
	Rooms.travelPoint(B, travel, "Fountain Park", CFrame.lookAt(c + Vector3.new(0, 3, -44), c + Vector3.new(0, 3, 0)), 7)
end

-- ================= DEALERSHIP =================
function Places.dealer(B, P, L, Screens, Rooms, root, center: Vector3, travel, CarModel)
	local F = B.folder(root, "Dealership")
	local base = faceCF(center + Vector3.new(0, L.Floor, 0), Vector3.new(0, 0, -1))
	local cf = base * CFrame.new(0, 0, 26)
	local w, d = 70, 38
	Rooms.shell(B, P, F, cf, w, d, {
		Name = "Showroom",
		Height = 16,
		Wall = P.Pearl,
		Trim = P.RoseGold,
		Floor = P.Ivory,
		Doors = { { "front", 0, 12, 11 } },
		Windows = { { "front", -22, 22, 12, 1 }, { "front", 22, 22, 12, 1 } },
	})
	Rooms.entrance(B, P, F, cf * CFrame.new(0, 0, -d / 2), 12, "Aura Motors", P.RoseGold, Screens)
	local styles = { { "Cabrio", P.Blush }, { "Coupe", P.Lilac }, { "SUV", P.Champagne } }
	for i, s in styles do
		local pcf = cf * CFrame.new((i - 2) * 21, 0, 4)
		B.vcyl(F, (pcf * CFrame.new(0, 0.3, 0)).Position, 0.6, 17, P.Ivory, { Material = Enum.Material.Marble })
		require(script.Parent.Stage).arc(B, F, (pcf * CFrame.new(0, 0.62, 0)).Position, 8.5, -180, 180, 24, 0.15, P.NeonPink)
		local car = CarModel.build(B, P, F, pcf * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, math.rad(-25), 0), s[1], s[2])
		car.Name = "Display" .. s[1]
		for _, p in car:GetDescendants() do
			if p:IsA("Seat") or p:IsA("VehicleSeat") then
				p.Disabled = true
			end
		end
		local kiosk = B.cushion(F, pcf * CFrame.new(0, 1.8, -10), Vector3.new(3, 3.6, 1.4), 0.3, P.Plum, {})
		kiosk.Name = "Kiosk"
		kiosk:SetAttribute("Style", s[1])
		kiosk:SetAttribute("Color", s[2])
		kiosk:AddTag("CarSpawner")
		B.prompt(kiosk, "Get " .. s[1], "Free test drive", { Distance = 9, Hold = 0.4 })
		local label = B.part(F, pcf * CFrame.new(0, 3.9, -10.72), Vector3.new(2.6, 0.9, 0.05), P.Plum, { CanCollide = false })
		B.text(B.gui(label, Enum.NormalId.Front, 40), s[1], { TextColor3 = P.Champagne, FontFace = B.Fonts.Luxe() })
	end
	-- parking lot in front
	local lot = B.folder(F, "Lot")
	B.part(lot, base * CFrame.new(0, -0.08, -18), Vector3.new(96, 0.2, 44), P.Asphalt, { Material = Enum.Material.Asphalt, CastShadow = false })
	for i = 0, 8 do
		local x = -40 + i * 10
		B.part(lot, base * CFrame.new(x, 0.03, -26), Vector3.new(0.4, 0.05, 14), P.Ivory, { CanCollide = false, CastShadow = false })
		if i < 8 then
			local spot = B.part(lot, base * CFrame.new(x + 5, 0.5, -26), Vector3.new(2, 1, 2), P.Ivory, { Transparency = 1, CanCollide = false, CanQuery = false, Name = "CarSpot" })
			spot:AddTag("CarSpot")
			spot.CanTouch = false
		end
	end
	Rooms.travelPoint(B, travel, "Aura Motors", base * CFrame.new(0, 3, -6) * CFrame.Angles(0, math.pi, 0), 8)
end

-- ================= RESIDENCES =================
function Places.residences(B, P, L, Screens, Rooms, root, center: Vector3, travel)
	local F = B.folder(root, "Residences")
	local base = faceCF(center + Vector3.new(0, L.Floor, 0), Vector3.new(0, 0, -1))
	local palette = { { P.Peach, P.Blush }, { P.Powder, P.Lavender } }
	for i, x in { -24, 24 } do
		local cf = base * CFrame.new(x, 0, 6)
		local w, d = 44, 42
		local cols = palette[i]
		Rooms.shell(B, P, F, cf, w, d, {
			Name = "Home" .. i,
			Height = 13,
			Wall = cols[1],
			Trim = P.Ivory,
			Floor = Color3.fromHex("E3D3C1"),
			FloorMaterial = Enum.Material.WoodPlanks,
			Doors = { { "front", -12, 6, 9 } },
			Windows = { { "front", 8, 14, 7, 2.5 }, { "left", 0, 12, 6, 3 }, { "right", 0, 12, 6, 3 } },
		})
		-- porch roof + door
		B.wedge(F, cf * CFrame.new(-12, 10.6, -d / 2 - 2) * CFrame.Angles(0, math.pi, 0), Vector3.new(9, 1.4, 4), P.Aubergine, { Material = Enum.Material.Slate })
		local mailbox = B.cushion(F, cf * CFrame.new(-20, 2.2, -d / 2 - 5), Vector3.new(1.2, 1, 1.8), 0.3, cols[2], {})
		mailbox.Name = "Mailbox"
		B.vcyl(F, (cf * CFrame.new(-20, 0.9, -d / 2 - 5)).Position, 1.8, 0.25, P.Ivory, {})
		-- interior wall (bedroom at back)
		B.wall(F, (cf * CFrame.new(-w / 2, 0, 6)).Position, (cf * CFrame.new(w / 2, 0, 6)).Position, 13, 0.5, P.Ivory, { { at = 10, width = 5, height = 9 } }, {})
		Rooms.bed(B, P, F, cf * CFrame.new(6, 0, d / 2 - 6.5), cols[2])
		Rooms.sofa(B, P, F, cf * CFrame.new(-8, 0, -4), cols[2], 8)
		Rooms.table(B, P, F, cf * CFrame.new(-8, 0, -9.5), P.Ivory, 0, P.Blush)
		B.part(F, cf * CFrame.new(-8, 0.02, -7), Vector3.new(14, 0.05, 10), P.Ivory, { Material = Enum.Material.Fabric, CanCollide = false, CastShadow = false })
		local tvcf = cf * CFrame.new(-8, 5, -d / 2 + 0.7)
		B.rounded(F, tvcf, Vector3.new(7, 4, 0.3), 0.12, P.Charcoal, {})
		local screen = B.part(F, tvcf * CFrame.new(0, 0, 0.18), Vector3.new(6.6, 3.6, 0.05), Color3.new(0, 0, 0), { CanCollide = false })
		Screens.galaxy(B.gui(screen, Enum.NormalId.Back, 30, { Brightness = 1.2 }), B, { Seed = 300 + i, Title = "AURA TV" })
		-- kitchen
		local kcf = cf * CFrame.new(w / 2 - 2.2, 0, -8) * CFrame.Angles(0, math.pi / 2, 0)
		Rooms.counter(B, P, F, kcf, 14, P.Ivory)
		Rooms.giver(B, P, F, kcf * CFrame.new(-3, 4.05, 0), "Juice", "Food", "Orange Juice")
		Rooms.giver(B, P, F, kcf * CFrame.new(3, 4.05, 0), "Sandwich", "Food")
		Rooms.giver(B, P, F, kcf * CFrame.new(0, 4.05, 0), "Phone", "Hold")
		Rooms.catalogSpot(B, P, F, cf * CFrame.new(-17, 0, d / 2 - 1), "Wardrobe")
	end
	Rooms.travelPoint(B, travel, "Residences", base * CFrame.new(0, 3, -26) * CFrame.Angles(0, math.pi, 0), 9)
end

function Places.build(B, P, L, Screens, Rooms, CarModel, root: Instance)
	local travel = root:FindFirstChild("Travel") or B.folder(root, "Travel")
	local D = B.folder(root, "Districts")
	for key, name in L.Districts do
		local xs, zs = string.match(key, "^(-?%d+),(-?%d+)$")
		local center = Vector3.new(tonumber(xs), 0, tonumber(zs))
		if name == "Cafe" then
			Places.cafe(B, P, L, Screens, Rooms, D, center, travel)
		elseif name == "Hotel" then
			Places.hotel(B, P, L, Screens, Rooms, D, center, travel)
		elseif name == "Boutiques" then
			Places.boutiques(B, P, L, Screens, Rooms, D, center, travel)
		elseif name == "Salon" then
			Places.salon(B, P, L, Screens, Rooms, D, center, travel)
		elseif name == "Park" then
			Places.park(B, P, L, Screens, Rooms, D, center, travel)
		elseif name == "Dealer" then
			Places.dealer(B, P, L, Screens, Rooms, D, center, travel, CarModel)
		elseif name == "Residences" then
			Places.residences(B, P, L, Screens, Rooms, D, center, travel)
		end
	end
	-- parked cars along the plaza ring road
	local parked = B.folder(root, "ParkedCars")
	local spots = {
		{ Vector3.new(-60, 0.6, 106), Vector3.new(1, 0, 0) },
		{ Vector3.new(60, 0.6, 106), Vector3.new(-1, 0, 0) },
		{ Vector3.new(-106, 0.6, -40), Vector3.new(0, 0, 1) },
		{ Vector3.new(106, 0.6, 40), Vector3.new(0, 0, -1) },
		{ Vector3.new(-106, 0.6, 50), Vector3.new(0, 0, -1) },
		{ Vector3.new(106, 0.6, -50), Vector3.new(0, 0, 1) },
	}
	for i, s in spots do
		local p = B.part(parked, CFrame.lookAt(s[1], s[1] + s[2]), Vector3.new(2, 1, 2), P.Ivory, { Transparency = 1, CanCollide = false, CanQuery = false, Name = "ParkedSpot" .. i })
		p.CanTouch = false
		p:AddTag("ParkedCarSpot")
	end
	Rooms.travelPoint(B, travel, "Runway Stage", CFrame.lookAt(Vector3.new(0, 3.6, 84), Vector3.new(0, 3.6, 0)), 1)
end

return Places
