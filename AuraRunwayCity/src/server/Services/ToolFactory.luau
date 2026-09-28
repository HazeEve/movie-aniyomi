--!nonstrict
-- Builds pick-up / food tools out of parts (no uploaded meshes needed).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local P = require(ReplicatedStorage.Shared.Palette)

local ToolFactory = {}

local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

local function part(parent, size, cf, color, opts)
	opts = opts or {}
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = opts.Material or Enum.Material.SmoothPlastic
	if opts.Shape then
		p.Shape = opts.Shape
	end
	if opts.Transparency then
		p.Transparency = opts.Transparency
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.Massless = true
	p.CastShadow = false
	p.Name = opts.Name or "Detail"
	p.Parent = parent
	return p
end

local function vcyl(parent, h, d, cf, color, opts)
	opts = opts or {}
	opts.Shape = CYL
	return part(parent, Vector3.new(h, d, d), cf * CFrame.Angles(0, 0, math.pi / 2), color, opts)
end

local function ball(parent, d, cf, color, opts)
	opts = opts or {}
	opts.Shape = BALL
	return part(parent, Vector3.new(d, d, d), cf, color, opts)
end

-- Each builder gets (tool, handle) with the handle at the origin and returns grip offset
local builders = {}

builders.Coffee = function(t, h)
	h.Size = Vector3.new(0.6, 0.9, 0.6)
	h.Shape = CYL
	h.Size = Vector3.new(0.9, 0.6, 0.6)
	h.CFrame = CFrame.Angles(0, 0, math.pi / 2)
	h.Color = P.Ivory
	vcyl(t, 0.15, 0.65, CFrame.new(0, 0.5, 0), P.Plum)
	vcyl(t, 0.2, 0.62, CFrame.new(0, 0, 0), P.Blush, { Material = Enum.Material.Fabric })
end
builders.Lemonade = function(t, h)
	builders.Coffee(t, h)
	h.Color = Color3.fromHex("FFF1A8")
	h.Transparency = 0.2
	vcyl(t, 0.9, 0.08, CFrame.new(0.12, 0.55, 0) * CFrame.Angles(0, 0, math.rad(15)), P.Rose)
end
builders.Juice = function(t, h)
	builders.Lemonade(t, h)
	h.Color = Color3.fromHex("FFB65C")
end
builders.Boba = function(t, h)
	builders.Coffee(t, h)
	h.Color = Color3.fromHex("E8CFB3")
	h.Transparency = 0.1
	for i = 0, 5 do
		ball(t, 0.14, CFrame.new(math.cos(i) * 0.18, -0.35, math.sin(i) * 0.18), Color3.fromHex("3B2418"))
	end
	vcyl(t, 1, 0.1, CFrame.new(0.1, 0.6, 0), P.Lavender)
end
builders.Croissant = function(t, h)
	h.Shape = BALL
	h.Size = Vector3.new(0.6, 0.6, 0.6)
	h.Color = Color3.fromHex("E3A55C")
	for _, x in { -0.35, 0.35 } do
		ball(t, 0.45, CFrame.new(x, -0.05, 0.08), Color3.fromHex("D38F45"))
	end
end
builders.Donut = function(t, h)
	h.Shape = CYL
	h.Size = Vector3.new(0.3, 0.9, 0.9)
	h.Color = Color3.fromHex("E3B07A")
	part(t, Vector3.new(0.12, 0.85, 0.85), CFrame.new(0.12, 0, 0), P.Blush, { Shape = CYL })
	part(t, Vector3.new(0.4, 0.3, 0.3), CFrame.new(0, 0, 0), Color3.fromHex("C98E55"), { Shape = CYL })
	for i = 1, 6 do
		part(t, Vector3.new(0.05, 0.05, 0.14), CFrame.new(0.19, math.cos(i) * 0.3, math.sin(i) * 0.3), ({ P.Lavender, P.Mint, P.Butter })[(i % 3) + 1])
	end
end
builders.Macaron = function(t, h)
	h.Shape = CYL
	h.Size = Vector3.new(0.2, 0.55, 0.55)
	h.CFrame = CFrame.Angles(0, 0, math.pi / 2)
	h.Color = P.Rose
	vcyl(t, 0.08, 0.5, CFrame.new(0, 0.13, 0), P.Ivory)
	vcyl(t, 0.18, 0.55, CFrame.new(0, 0.26, 0), P.Rose)
end
builders.Cake = function(t, h)
	h.Size = Vector3.new(0.7, 0.6, 0.9)
	h.Color = Color3.fromHex("F7E1C8")
	part(t, Vector3.new(0.72, 0.12, 0.92), CFrame.new(0, 0.1, 0), P.Blush)
	part(t, Vector3.new(0.72, 0.1, 0.92), CFrame.new(0, 0.33, 0), P.Ivory)
	ball(t, 0.25, CFrame.new(0, 0.48, 0.2), Color3.fromHex("E0455F"))
end
builders.Cupcake = function(t, h)
	h.Shape = CYL
	h.Size = Vector3.new(0.5, 0.6, 0.6)
	h.CFrame = CFrame.Angles(0, 0, math.pi / 2)
	h.Color = P.Lavender
	ball(t, 0.72, CFrame.new(0, 0.35, 0), P.Blush)
	ball(t, 0.22, CFrame.new(0, 0.72, 0), Color3.fromHex("E0455F"))
end
builders.Burger = function(t, h)
	h.Shape = CYL
	h.Size = Vector3.new(0.25, 1, 1)
	h.CFrame = CFrame.Angles(0, 0, math.pi / 2)
	h.Color = Color3.fromHex("D99A55")
	vcyl(t, 0.18, 1.02, CFrame.new(0, 0.2, 0), Color3.fromHex("6B3D24"))
	vcyl(t, 0.06, 1.06, CFrame.new(0, 0.31, 0), Color3.fromHex("8FCB6B"))
	vcyl(t, 0.05, 1.02, CFrame.new(0, 0.36, 0), Color3.fromHex("FFD152"))
	ball(t, 1, CFrame.new(0, 0.45, 0), Color3.fromHex("D99A55"))
end
builders.Sandwich = function(t, h)
	h.Size = Vector3.new(1, 0.2, 1)
	h.Color = Color3.fromHex("F2D7A6")
	part(t, Vector3.new(1.02, 0.08, 1.02), CFrame.new(0, 0.13, 0), Color3.fromHex("8FCB6B"))
	part(t, Vector3.new(1, 0.08, 1), CFrame.new(0, 0.2, 0), Color3.fromHex("F5A3A3"))
	part(t, Vector3.new(1, 0.2, 1), CFrame.new(0, 0.33, 0), Color3.fromHex("F2D7A6"))
end
builders.Pizza = function(t, h)
	h.Size = Vector3.new(0.9, 0.1, 1.3)
	h.Color = Color3.fromHex("F6C451")
	part(t, Vector3.new(0.95, 0.16, 0.25), CFrame.new(0, 0.02, 0.6), Color3.fromHex("D38F45"))
	for i = 1, 3 do
		part(t, Vector3.new(0.22, 0.05, 0.22), CFrame.new(-0.2 + i * 0.12, 0.07, -0.3 + i * 0.2), Color3.fromHex("C4453E"), { Shape = CYL })
	end
end
builders.IceCream = function(t, h)
	h.Shape = CYL
	h.Size = Vector3.new(0.9, 0.4, 0.4)
	h.CFrame = CFrame.Angles(0, 0, math.pi / 2)
	h.Color = Color3.fromHex("E3B07A")
	ball(t, 0.6, CFrame.new(0, 0.6, 0), P.Blush)
	ball(t, 0.55, CFrame.new(0, 1, 0), P.Mint)
	ball(t, 0.16, CFrame.new(0, 1.3, 0), Color3.fromHex("E0455F"))
end
builders.Popsicle = function(t, h)
	h.Size = Vector3.new(0.12, 0.7, 0.2)
	h.Color = Color3.fromHex("E8CFA8")
	part(t, Vector3.new(0.5, 0.9, 0.25), CFrame.new(0, 0.75, 0), P.Lavender)
end
builders.Popcorn = function(t, h)
	h.Size = Vector3.new(0.8, 1, 0.8)
	h.Color = P.Ivory
	for _, x in { -0.28, 0, 0.28 } do
		part(t, Vector3.new(0.12, 1.01, 0.82), CFrame.new(x, 0, 0), Color3.fromHex("E0455F"))
	end
	for i = 1, 6 do
		ball(t, 0.3, CFrame.new(math.cos(i) * 0.2, 0.55 + (i % 2) * 0.1, math.sin(i) * 0.2), Color3.fromHex("FFF4C8"))
	end
end

builders.ShoppingBag = function(t, h)
	h.Size = Vector3.new(0.3, 0.3, 0.3)
	h.Transparency = 1
	part(t, Vector3.new(1.4, 1.5, 0.6), CFrame.new(0, -1, 0), P.Blush)
	part(t, Vector3.new(1.42, 0.2, 0.62), CFrame.new(0, -0.35, 0), P.Plum)
	part(t, Vector3.new(0.08, 0.6, 0.08), CFrame.new(-0.35, -0.1, 0) * CFrame.Angles(0, 0, math.rad(20)), P.Plum)
	part(t, Vector3.new(0.08, 0.6, 0.08), CFrame.new(0.35, -0.1, 0) * CFrame.Angles(0, 0, math.rad(-20)), P.Plum)
end
builders.Handbag = function(t, h)
	h.Size = Vector3.new(0.3, 0.3, 0.3)
	h.Transparency = 1
	part(t, Vector3.new(1.2, 0.8, 0.5), CFrame.new(0, -0.7, 0), P.Plum)
	part(t, Vector3.new(1.22, 0.3, 0.52), CFrame.new(0, -0.4, 0), P.Aubergine)
	part(t, Vector3.new(0.2, 0.15, 0.1), CFrame.new(0, -0.45, -0.28), P.Gold, { Material = Enum.Material.Metal })
	part(t, Vector3.new(0.9, 0.08, 0.08), CFrame.new(0, 0, 0), P.Gold, { Material = Enum.Material.Metal })
end
builders.Perfume = function(t, h)
	h.Size = Vector3.new(0.6, 0.7, 0.35)
	h.Color = P.Blush
	h.Transparency = 0.25
	h.Material = Enum.Material.Glass
	vcyl(t, 0.25, 0.25, CFrame.new(0, 0.45, 0), P.Gold, { Material = Enum.Material.Metal })
	ball(t, 0.3, CFrame.new(0, 0.7, 0), P.Lavender)
end
builders.Sunglasses = function(t, h)
	h.Size = Vector3.new(1, 0.4, 0.5)
	h.Color = P.Rose
	part(t, Vector3.new(0.7, 0.05, 0.3), CFrame.new(0, 0.22, 0), P.Charcoal)
end
builders.Jewelry = function(t, h)
	h.Size = Vector3.new(0.8, 0.5, 0.7)
	h.Color = P.Lavender
	part(t, Vector3.new(0.82, 0.15, 0.72), CFrame.new(0, 0.3, 0), P.Plum)
	ball(t, 0.25, CFrame.new(0, 0.45, 0), Color3.fromHex("D6F1FF"), { Material = Enum.Material.Glass })
end
builders.Phone = function(t, h)
	h.Size = Vector3.new(0.5, 1, 0.1)
	h.Color = P.Rose
	part(t, Vector3.new(0.44, 0.9, 0.02), CFrame.new(0, 0, -0.06), P.Plum, { Material = Enum.Material.Glass })
end

local function flower(t, color, stemTop)
	vcyl(t, stemTop, 0.08, CFrame.new(0, stemTop / 2, 0), P.LeafDark)
	ball(t, 0.45, CFrame.new(0, stemTop, 0), color, { Material = Enum.Material.Fabric })
end
builders.Bouquet = function(t, h)
	h.Size = Vector3.new(0.4, 1, 0.4)
	h.Color = P.Ivory
	part(t, Vector3.new(0.7, 0.5, 0.7), CFrame.new(0, 0.5, 0), P.Blush, { Material = Enum.Material.Fabric })
	for i = 0, 6 do
		local a = i / 7 * math.pi * 2
		ball(t, 0.42, CFrame.new(math.cos(a) * 0.25, 1 + (i % 2) * 0.12, math.sin(a) * 0.25), Color3.fromHex("D93A5A"), { Material = Enum.Material.Fabric })
	end
	ball(t, 0.45, CFrame.new(0, 1.2, 0), Color3.fromHex("D93A5A"), { Material = Enum.Material.Fabric })
end
builders.Tulips = function(t, h)
	h.Size = Vector3.new(0.3, 0.8, 0.3)
	h.Color = P.Leaf
	for i, c in { P.Rose, P.Butter, P.Lavender } do
		local tt = t
		ball(tt, 0.35, CFrame.new((i - 2) * 0.2, 1.1 + (i % 2) * 0.1, 0), c, { Material = Enum.Material.Fabric })
		part(tt, Vector3.new(0.06, 0.8, 0.06), CFrame.new((i - 2) * 0.1, 0.6, 0) * CFrame.Angles(0, 0, math.rad((i - 2) * -10)), P.LeafDark)
	end
end
builders.Sunflower = function(t, h)
	h.Size = Vector3.new(0.12, 1.2, 0.12)
	h.Color = P.LeafDark
	part(t, Vector3.new(0.12, 1.1, 1.1), CFrame.new(0, 0.9, 0) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromHex("FFD152"), { Shape = CYL })
	part(t, Vector3.new(0.16, 0.5, 0.5), CFrame.new(0, 0.9, -0.03) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromHex("6B3D24"), { Shape = CYL })
end
builders.Lilies = function(t, h)
	h.Size = Vector3.new(0.3, 0.8, 0.3)
	h.Color = P.Leaf
	for i = 1, 3 do
		flower(t, P.Ivory, 0.9 + i * 0.12)
	end
end
builders.Balloon = function(t, h)
	h.Size = Vector3.new(0.2, 0.2, 0.2)
	h.Color = P.Ivory
	part(t, Vector3.new(0.03, 4, 0.03), CFrame.new(0, 2, 0), P.Ivory)
	ball(t, 1.8, CFrame.new(0, 4.6, 0), P.Lavender, { Material = Enum.Material.Glass, Transparency = 0.1 })
end
builders.HeartBalloon = function(t, h)
	h.Size = Vector3.new(0.2, 0.2, 0.2)
	h.Color = P.Ivory
	part(t, Vector3.new(0.03, 4, 0.03), CFrame.new(0, 2, 0), P.Ivory)
	ball(t, 1.3, CFrame.new(-0.42, 4.9, 0), P.Heart, { Material = Enum.Material.Glass })
	ball(t, 1.3, CFrame.new(0.42, 4.9, 0), P.Heart, { Material = Enum.Material.Glass })
	part(t, Vector3.new(1.3, 1.3, 1.1), CFrame.new(0, 4.3, 0) * CFrame.Angles(0, 0, math.rad(45)), P.Heart, { Material = Enum.Material.Glass })
end

ToolFactory.Food = {
	Coffee = true, Lemonade = true, Juice = true, Boba = true, Croissant = true, Donut = true, Macaron = true,
	Cake = true, Cupcake = true, Burger = true, Sandwich = true, Pizza = true, IceCream = true, Popsicle = true, Popcorn = true,
}
ToolFactory.Drinks = { Coffee = true, Lemonade = true, Juice = true, Boba = true }

ToolFactory.Names = {
	Coffee = "Latte", Boba = "Boba Tea", IceCream = "Ice Cream", ShoppingBag = "Shopping Bag", HeartBalloon = "Heart Balloon",
	Jewelry = "Jewelry Box", Bouquet = "Rose Bouquet", Lilies = "Lily Bunch", Juice = "Orange Juice", Cake = "Cake Slice",
	Pizza = "Pizza Slice",
}

function ToolFactory.Make(item: string): Tool?
	local builder = builders[item]
	if not builder then
		return nil
	end
	local tool = Instance.new("Tool")
	tool.Name = ToolFactory.Names[item] or item
	tool.CanBeDropped = true
	tool.RequiresHandle = true
	tool:SetAttribute("Item", item)
	local model = Instance.new("Folder")
	-- the visible "body" is a normal detail; the real Handle is an invisible,
	-- unrotated part at the origin so every item is held upright.
	local body = part(model, Vector3.new(0.5, 0.5, 0.5), CFrame.new(), P.Ivory, { Name = "Body" })
	builder(model, body)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 0.4, 0.4)
	handle.CFrame = CFrame.new()
	handle.Transparency = 1
	handle.CanCollide = false
	handle.Massless = true
	handle.CastShadow = false
	handle.Parent = tool
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") then
			local w = Instance.new("WeldConstraint")
			w.Part0 = handle
			w.Part1 = d
			w.Parent = d
			d.Parent = tool
		end
	end
	model:Destroy()
	tool.Grip = CFrame.new(0, -0.1, 0)
	if item == "Balloon" or item == "HeartBalloon" then
		tool.Grip = CFrame.new(0, 0, 0)
	end
	return tool
end

return ToolFactory
