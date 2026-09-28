--!nonstrict
-- Car geometry (rounded, glossy). Used for showroom displays and drivable cars.
-- cf = ground point under the car centre; the car faces cf.LookVector.
local CarModel = {}

CarModel.Styles = { "Cabrio", "Coupe", "SUV" }

function CarModel.build(B, P, parent: Instance, cf: CFrame, style: string, color: Color3)
	local m = B.model(parent, style)
	m:SetAttribute("Style", style)
	local gloss = { Reflectance = 0.22 }
	local chrome = { Material = Enum.Material.Metal, Reflectance = 0.3 }
	local tall = style == "SUV"
	local lift = tall and 0.6 or 0

	local root = B.cyl(m, cf * CFrame.new(0, 1, 0), 6.4, 2, color, { Transparency = 1, Name = "Root" })
	m.PrimaryPart = root

	-- lower & upper body
	B.rounded(m, cf * CFrame.new(0, 2.1 + lift, 0), Vector3.new(6.8, 1.9, 13.6), 0.8, color, gloss)
	B.cushion(m, cf * CFrame.new(0, 3.35 + lift, 0.3), Vector3.new(6.5, 0.8, 12.6), 0.38, color, gloss)
	-- hood bulge
	B.wedge(m, cf * CFrame.new(0, 4.05 + lift, -4.3), Vector3.new(5.6, 0.6, 4), color, gloss)
	-- side accent line
	for _, s in { -1, 1 } do
		B.part(m, cf * CFrame.new(s * 3.42, 2.6 + lift, 0), Vector3.new(0.06, 0.18, 11.5), P.Champagne, { Material = Enum.Material.Metal, CanCollide = false })
	end

	-- cabin
	local glass = Color3.fromHex("2A2438")
	if style == "Cabrio" then
		B.part(m, cf * CFrame.new(0, 4.6 + lift, -1.7) * CFrame.Angles(math.rad(-35), 0, 0), Vector3.new(5.6, 2, 0.2), glass, { Material = Enum.Material.Glass, Transparency = 0.45, CanCollide = false })
		B.part(m, cf * CFrame.new(0, 3.8 + lift, 0.9), Vector3.new(5.8, 0.25, 5.2), P.Ivory, { Material = Enum.Material.Fabric, CanCollide = false })
		-- rear deck with rolled roof
		B.pill(m, cf * CFrame.new(0, 4.1 + lift, 4.6), 5.4, 0.9, 1.4, P.Plum, { Material = Enum.Material.Fabric })
	else
		local cabH = tall and 3.4 or 2.6
		B.rounded(m, cf * CFrame.new(0, 3.8 + lift + cabH / 2, 1), Vector3.new(6.1, cabH, tall and 8.4 or 6.4), 0.6, glass, { Material = Enum.Material.Glass, Transparency = 0.25, Reflectance = 0.3, CanCollide = false })
		B.cushion(m, cf * CFrame.new(0, 3.8 + lift + cabH + 0.15, 1), Vector3.new(6, 0.4, tall and 7.6 or 5.4), 0.18, color, gloss)
		for _, s in { -1, 1 } do
			B.part(m, cf * CFrame.new(s * 3.05, 3.8 + lift + cabH / 2, 1), Vector3.new(0.12, cabH, 0.35), color, { CanCollide = false })
		end
		if tall then
			for _, s in { -1, 1 } do
				B.part(m, cf * CFrame.new(s * 2.4, 3.8 + lift + cabH + 0.5, 1), Vector3.new(0.25, 0.25, 6.6), P.Charcoal, chrome)
			end
		end
	end

	-- wheels
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local wcf = cf * CFrame.new(sx * 3.05, 1.5, sz * 4.4)
			local wheel = B.cyl(m, wcf, 1.3, 3, P.Charcoal, { Material = Enum.Material.Plastic, Name = "Wheel", CanCollide = false })
			wheel:SetAttribute("Side", sx)
			B.cyl(m, wcf * CFrame.new(sx * 0.62, 0, 0), 0.12, 1.9, P.Champagne, { Material = Enum.Material.Metal, Name = "Hub", CanCollide = false })
			B.cyl(m, wcf * CFrame.new(sx * 0.68, 0, 0), 0.1, 0.6, P.Gold, { Material = Enum.Material.Metal, Name = "Hub", CanCollide = false })
		end
	end

	-- lights & grille
	for _, s in { -1, 1 } do
		B.disc(m, cf * CFrame.new(s * 2.2, 2.7 + lift, -6.85), 0.2, 1.1, P.Ivory, { Material = Enum.Material.Neon, CanCollide = false, Name = "Headlight" })
		B.part(m, cf * CFrame.new(s * 2.3, 2.7 + lift, 6.83), Vector3.new(1.6, 0.4, 0.1), P.Rose, { Material = Enum.Material.Neon, CanCollide = false, Name = "Taillight" })
		B.part(m, cf * CFrame.new(s * 3.5, 4.1 + lift, -1.8), Vector3.new(0.5, 0.35, 0.6), color, { CanCollide = false })
	end
	B.rounded(m, cf * CFrame.new(0, 2.2 + lift, -6.82), Vector3.new(2.8, 1, 0.2), 0.08, P.Charcoal, chrome)
	B.part(m, cf * CFrame.new(0, 2.2 + lift, -6.95), Vector3.new(2.6, 0.12, 0.05), P.Gold, { Material = Enum.Material.Metal, CanCollide = false })
	B.part(m, cf * CFrame.new(0, 1.35, -6.75), Vector3.new(6, 0.35, 0.3), P.Charcoal, chrome)
	B.part(m, cf * CFrame.new(0, 1.35, 6.75), Vector3.new(6, 0.35, 0.3), P.Charcoal, chrome)

	-- seats
	local seatY = 3.3 + lift
	local driver = B.part(m, cf * CFrame.new(-1.35, seatY, 0.2), Vector3.new(2.2, 0.6, 2.2), P.Ivory, { Class = "VehicleSeat", Name = "DriverSeat", Material = Enum.Material.Fabric })
	driver.MaxSpeed = 0
	driver.Torque = 0
	driver.HeadsUpDisplay = false
	B.seat(m, cf * CFrame.new(1.35, seatY, 0.2), Vector3.new(2.2, 0.6, 2.2), P.Ivory, { Name = "Passenger" })
	if style ~= "Coupe" then
		B.seat(m, cf * CFrame.new(-1.35, seatY + 0.1, 3.4), Vector3.new(2.2, 0.6, 2), P.Ivory, { Name = "Passenger" })
		B.seat(m, cf * CFrame.new(1.35, seatY + 0.1, 3.4), Vector3.new(2.2, 0.6, 2), P.Ivory, { Name = "Passenger" })
	end
	for _, x in { -1.35, 1.35 } do
		B.cushion(m, cf * CFrame.new(x, seatY + 1.2, 1.5), Vector3.new(2, 2.2, 0.5), 0.22, P.Ivory, { Material = Enum.Material.Fabric, CanCollide = false })
	end
	-- steering wheel
	B.disc(m, cf * CFrame.new(-1.35, seatY + 1.4, -1.4) * CFrame.Angles(math.rad(25), 0, 0), 0.15, 1.3, P.Charcoal, { CanCollide = false })
	return m, root, driver
end

return CarModel
