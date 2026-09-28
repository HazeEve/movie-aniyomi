--!nonstrict
-- Aura Mall: 12 rentable UGC stalls + the big Creator's Atelier + atrium fountain.
local Mall = {}

-- Builds one stall. cf = floor centre, LookVector = open side facing shoppers.
function Mall.stall(B, P, Screens, parent, cf: CFrame, w: number, d: number, id: string, isCreator: boolean)
	local m = B.model(parent, id)
	m:SetAttribute("StallId", id)
	m:SetAttribute("IsCreator", isCreator)
	m:AddTag("Stall")
	local theme = isCreator and P.Gold or P.Lavender
	local wallH = isCreator and 14 or 11

	B.cushion(m, cf * CFrame.new(0, 0.15, 0), Vector3.new(w - 0.4, 0.3, d), 0.15, theme:Lerp(P.Ivory, 0.55), { Material = Enum.Material.Marble, Name = "ThemePad" })
	B.soft(m, cf * CFrame.new(0, wallH / 2, d / 2 - 0.4), Vector3.new(w, wallH, 0.8), 0.3, P.Ivory, {})
	for _, sx in { -1, 1 } do
		B.soft(m, cf * CFrame.new(sx * (w / 2 - 0.3), wallH / 2, 0), Vector3.new(0.6, wallH, d), 0.28, P.Ivory, {})
		B.vcyl(m, (cf * CFrame.new(sx * (w / 2 - 0.3), wallH / 2, -d / 2)).Position, wallH, 1.2, isCreator and P.Gold or P.RoseGold, { Material = Enum.Material.Metal })
	end
	-- accent stripe on back wall
	local stripe = B.part(m, cf * CFrame.new(0, wallH - 1.2, d / 2 - 0.85), Vector3.new(w - 1.4, 0.5, 0.1), theme, { Material = Enum.Material.Metal, Name = "ThemeStripe" })
	stripe.CanCollide = false

	-- display slots on the back wall
	local slots = B.folder(m, "Slots")
	local cols = isCreator and 8 or 4
	local rows = 2
	local slotSize = isCreator and 2.8 or 2.3
	local usable = w - 3
	local n = 0
	for row = 1, rows do
		for col = 1, cols do
			n += 1
			local x = -usable / 2 + usable * (col - 0.5) / cols
			local y = (isCreator and 3.8 or 3.3) + (row - 1) * (slotSize + 1.3)
			local slot = B.part(slots, cf * CFrame.new(x, y, d / 2 - 0.9), Vector3.new(slotSize, slotSize, 0.2), P.Pearl, { Name = "Slot" .. n })
			slot:SetAttribute("Index", n)
			local gui = B.gui(slot, Enum.NormalId.Front, 60, { LightInfluence = 0.3 })
			local bg = B.frame(gui, { Name = "Bg", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1) })
			B.gradient(bg, { P.Ivory, P.Pearl }, 90)
			local img = Instance.new("ImageLabel")
			img.Name = "Thumb"
			img.BackgroundTransparency = 1
			img.Size = UDim2.fromScale(0.86, 0.66)
			img.Position = UDim2.fromScale(0.07, 0.05)
			img.ScaleType = Enum.ScaleType.Fit
			img.Image = ""
			img.Parent = bg
			B.text(bg, "EMPTY", { Name = "Label", Position = UDim2.fromScale(0.05, 0.72), Size = UDim2.fromScale(0.9, 0.24), TextColor3 = P.TextSoft })
			local pr = B.prompt(slot, "Buy", "Item", { Distance = 6, Name = "BuyPrompt" })
			pr.Enabled = false
			pr.KeyboardKeyCode = Enum.KeyCode.F
			pr.UIOffset = Vector2.new(0, 0)
		end
	end

	-- counter with prompt
	local cw = isCreator and w * 0.45 or w * 0.5
	B.cushion(m, cf * CFrame.new(w * 0.15, 1.7, -d / 2 + 1.8), Vector3.new(cw, 3.4, 2), 0.3, theme, {})
	local counterTop = B.cushion(m, cf * CFrame.new(w * 0.15, 3.55, -d / 2 + 1.8), Vector3.new(cw + 0.3, 0.3, 2.3), 0.12, P.Ivory, { Material = Enum.Material.Marble })
	counterTop.Name = "Counter"
	local prompt = B.prompt(counterTop, isCreator and "Shop" or "Rent Stall", isCreator and "Creator's Atelier" or "Vacant Stall", { Distance = 9, Name = "StallPrompt" })
	prompt:AddTag("StallPrompt")
	-- register + little bag display on counter
	B.cushion(m, cf * CFrame.new(w * 0.15 + cw * 0.3, 4.1, -d / 2 + 1.8), Vector3.new(1.4, 0.8, 1), 0.12, P.Plum, {})
	B.cushion(m, cf * CFrame.new(w * 0.15 - cw * 0.3, 4.3, -d / 2 + 1.8), Vector3.new(1.2, 1.2, 0.5), 0.1, P.Blush, { Material = Enum.Material.Fabric })

	-- awning with scallops
	local awn = B.wedge(m, cf * CFrame.new(0, wallH + 0.7, -d / 2 + 1.6) * CFrame.Angles(0, math.pi, 0), Vector3.new(w, 1.4, 3.2), theme, { Material = Enum.Material.Fabric, Name = "Awning" })
	awn:AddTag("StallTheme")
	for k = 0, math.floor(w / 1.6) do
		local x = -w / 2 + 0.5 + k * 1.6
		if x < w / 2 then
			B.ball(m, (cf * CFrame.new(x, wallH - 0.05, -d / 2)).Position, 0.6, k % 2 == 0 and theme or P.Ivory, { Material = Enum.Material.Fabric, CanCollide = false, CastShadow = false })
		end
	end
	-- sign
	local signW = isCreator and w * 0.7 or w * 0.8
	local sign = B.rounded(m, cf * CFrame.new(0, wallH + 3, -d / 2 + 0.9), Vector3.new(signW + 0.6, isCreator and 3.4 or 2.6, 0.5), 0.2, P.Plum, {})
	local face = B.part(m, cf * CFrame.new(0, wallH + 3, -d / 2 + 0.6), Vector3.new(signW, isCreator and 2.9 or 2.1, 0.1), P.Plum, { Name = "SignFace", CanCollide = false })
	local _, label = Screens.sign(B.gui(face, Enum.NormalId.Front, 30), B, isCreator and "Creator's Atelier" or "For Rent", {})
	label.Name = "ShopName"
	face:AddTag("StallSign")
	sign.Name = "Sign"
	local lampPart = B.part(m, cf * CFrame.new(0, wallH - 0.3, 0), Vector3.new(0.5, 0.5, 0.5), P.Ivory, { Transparency = 1, CanCollide = false })
	B.light(lampPart, "SpotLight", { Face = Enum.NormalId.Bottom, Angle = 90, Range = 16, Brightness = 1.2, Color = Color3.fromHex("FFF1E6"), Shadows = false })

	-- mannequin plinths
	local spots = isCreator and { -w / 2 + 3, -w / 2 + 7 } or { -w / 2 + 2.3 }
	for i, x in spots do
		local base = cf * CFrame.new(x, 0.3, -d / 2 + 3.2)
		B.vcyl(m, (base * CFrame.new(0, 0.3, 0)).Position, 0.6, 2.8, P.Champagne, { Material = Enum.Material.Marble })
		local spot = B.part(m, base * CFrame.new(0, 3.6, 0), Vector3.new(1, 1, 1), P.Ivory, { Transparency = 1, CanCollide = false, CanQuery = false, Name = "MannequinSpot" .. i })
		spot.CanTouch = false
	end
	return m
end

function Mall.build(B, P, L, Screens, Rooms, root: Instance)
	local M = B.folder(root, "Mall")
	local center = Vector3.new(0, L.Floor, -182)
	local cf = CFrame.lookAt(center, center + Vector3.new(0, 0, 1)) -- front faces the stage (south)
	local w, d, h = 94, 90, 22
	Rooms.shell(B, P, M, cf, w, d, {
		Name = "MallShell",
		Height = h,
		Wall = P.Ivory,
		Trim = P.Gold,
		Floor = P.Pearl,
		Doors = { { "front", 0, 14, 12 }, { "back", 0, 10, 10 } },
		Windows = {
			{ "front", -30, 22, 12, 1 },
			{ "front", 30, 22, 12, 1 },
		},
		Roof = false,
	})
	-- roof with a long skylight
	B.part(M, cf * CFrame.new(-33.5, h + 0.4, 0), Vector3.new(27, 0.8, d + 0.8), P.Ivory, {})
	B.part(M, cf * CFrame.new(33.5, h + 0.4, 0), Vector3.new(27, 0.8, d + 0.8), P.Ivory, {})
	B.part(M, cf * CFrame.new(0, h + 0.4, -38), Vector3.new(40, 0.8, 14.8), P.Ivory, {})
	B.part(M, cf * CFrame.new(0, h + 0.4, 38), Vector3.new(40, 0.8, 14.8), P.Ivory, {})
	B.part(M, cf * CFrame.new(0, h + 0.3, 0), Vector3.new(40, 0.3, 61.4), P.Powder, { Material = Enum.Material.Glass, Transparency = 0.6, Reflectance = 0.2, Name = "Skylight" })
	for z = -30, 30, 7.5 do
		B.part(M, cf * CFrame.new(0, h + 0.55, z), Vector3.new(40, 0.4, 0.5), P.Gold, { Material = Enum.Material.Metal })
	end
	B.ring(M, cf * CFrame.new(0, h + 1.2, 0), w + 2, d + 2, 1.6, 0.8, P.Gold, { Material = Enum.Material.Metal })

	-- facade sign
	local signCf = cf * CFrame.new(0, h - 4, -d / 2 - 0.8)
	B.rounded(M, signCf, Vector3.new(36, 5, 0.8), 0.35, P.Plum, {})
	local face = B.part(M, signCf * CFrame.new(0, 0, -0.45), Vector3.new(34, 4.2, 0.1), P.Plum, { CanCollide = false })
	Screens.sign(B.gui(face, Enum.NormalId.Front, 20), B, "AURA  MALL", {})
	B.neonLine(M, (signCf * CFrame.new(-17.6, -2.6, -0.5)).Position, (signCf * CFrame.new(17.6, -2.6, -0.5)).Position, 0.14, P.NeonGold)
	Rooms.entrance(B, P, M, cf * CFrame.new(0, 0, -d / 2), 14, "Welcome", P.Rose, Screens)

	-- stalls
	local stalls = B.folder(M, "Stalls")
	local sw, sd = 11, 10
	local idx = 0
	for _, side in { -1, 1 } do
		for i = 0, 5 do
			idx += 1
			local z = -27.5 + i * 11
			local x = side * (w / 2 - 0.4 - sd / 2)
			local scf = cf * CFrame.new(x, 0, z) * CFrame.Angles(0, side < 0 and -math.pi / 2 or math.pi / 2, 0)
			Mall.stall(B, P, Screens, stalls, scf, sw, sd, "Stall" .. idx, false)
		end
	end
	local ccf = cf * CFrame.new(0, 0, d / 2 - 0.4 - 7)
	Mall.stall(B, P, Screens, stalls, ccf, 30, 14, "CreatorStall", true)

	-- atrium fountain
	local atrium = B.folder(M, "Atrium")
	local fc = cf * CFrame.new(0, 0, -4)
	B.vcyl(atrium, (fc * CFrame.new(0, 0.9, 0)).Position, 1.8, 17, P.Ivory, { Material = Enum.Material.Marble })
	B.vcyl(atrium, (fc * CFrame.new(0, 1.85, 0)).Position, 0.1, 15.6, Color3.fromHex("9FD3E6"), { Material = Enum.Material.Glass, Transparency = 0.35, Reflectance = 0.3, CanCollide = false })
	B.vcyl(atrium, (fc * CFrame.new(0, 3.5, 0)).Position, 3.2, 2.2, P.Ivory, { Material = Enum.Material.Marble })
	B.vcyl(atrium, (fc * CFrame.new(0, 5.3, 0)).Position, 0.8, 7, P.Ivory, { Material = Enum.Material.Marble })
	B.vcyl(atrium, (fc * CFrame.new(0, 5.72, 0)).Position, 0.06, 6.4, Color3.fromHex("9FD3E6"), { Material = Enum.Material.Glass, Transparency = 0.35, CanCollide = false })
	local spout = B.ball(atrium, (fc * CFrame.new(0, 6.6, 0)).Position, 1.4, P.Gold, { Material = Enum.Material.Metal })
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 45
	pe.Speed = NumberRange.new(9, 12)
	pe.SpreadAngle = Vector2.new(18, 18)
	pe.Lifetime = NumberRange.new(1, 1.4)
	pe.Acceleration = Vector3.new(0, -28, 0)
	pe.Size = NumberSequence.new(0.5, 0.2)
	pe.Transparency = NumberSequence.new(0.2, 0.9)
	pe.Color = ColorSequence.new(Color3.fromHex("DDF3FF"))
	pe.LightEmission = 0.3
	pe.EmissionDirection = Enum.NormalId.Top
	pe.Parent = spout
	for i = 0, 3 do
		local a = i * math.pi / 2 + math.pi / 4
		local pos = (fc * CFrame.new(math.cos(a) * 13, 0, math.sin(a) * 13)).Position
		require(script.Parent.City).bench(B, P, atrium, CFrame.lookAt(pos, Vector3.new(fc.Position.X, pos.Y, fc.Position.Z)) * CFrame.Angles(0, math.pi, 0))
	end
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local pos = (cf * CFrame.new(sx * 22, 0, -4 + sz * 22)).Position
			require(script.Parent.City).planter(B, P, atrium, pos, 6, nil)
			B.tree(atrium, pos + Vector3.new(0, 2, 0), 0.6, P.Leaf, P.WoodDark, nil)
		end
	end
	-- chandeliers
	for _, z in { -20, 14 } do
		local c = cf * CFrame.new(0, h - 5, z)
		B.vcyl(atrium, (c * CFrame.new(0, 3, 0)).Position, 4, 0.2, P.Gold, { Material = Enum.Material.Metal })
		require(script.Parent.Stage).arc(B, atrium, c.Position, 3.2, -180, 180, 16, 0.25, P.Champagne)
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			B.ball(atrium, c.Position + Vector3.new(math.cos(a) * 3.2, -0.6, math.sin(a) * 3.2), 0.5, P.Ivory, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		end
		local core = B.ball(atrium, c.Position - Vector3.new(0, 1, 0), 1.3, P.Champagne, { Material = Enum.Material.Neon, CanCollide = false })
		B.light(core, "PointLight", { Range = 34, Brightness = 1.1, Color = Color3.fromHex("FFE8D2"), Shadows = false })
	end
	-- info board
	local board = B.rounded(M, cf * CFrame.new(-10, 4, -d / 2 + 4) * CFrame.Angles(0, math.rad(25), 0), Vector3.new(7, 5, 0.5), 0.2, P.Plum, {})
	local bface = B.part(M, cf * CFrame.new(-10, 4, -d / 2 + 4) * CFrame.Angles(0, math.rad(25), 0) * CFrame.new(0, 0, -0.3), Vector3.new(6.4, 4.4, 0.05), P.Plum, { CanCollide = false })
	local bg = B.frame(B.gui(bface, Enum.NormalId.Front, 40), { Size = UDim2.fromScale(1, 1), BackgroundColor3 = P.Plum })
	B.text(bg, "RENT A STALL", { Size = UDim2.fromScale(1, 0.3), FontFace = B.Fonts.Luxe(), TextColor3 = P.Champagne })
	B.text(bg, "Sell your UGC & clothes!\nWalk to any empty counter\nand press Rent Stall.", { Position = UDim2.fromScale(0.05, 0.32), Size = UDim2.fromScale(0.9, 0.6), TextColor3 = P.Ivory, FontFace = B.Fonts.Body() })
	board.Name = "InfoBoard"
	B.vcyl(M, (cf * CFrame.new(-10, 0.8, -d / 2 + 4)).Position, 1.6, 0.4, P.Gold, { Material = Enum.Material.Metal })

	Rooms.travelPoint(B, root:FindFirstChild("Travel") or B.folder(root, "Travel"), "Aura Mall", cf * CFrame.new(0, 3, -d / 2 - 8) * CFrame.Angles(0, math.pi, 0), 2)
	return M
end

return Mall
