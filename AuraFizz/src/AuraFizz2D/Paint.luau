--!nonstrict
-- FizzPaint — the pastel painted art style for Roblox GUI.
-- Same rules as the pastel-fruit-art skill:
--   * chunky rounded shapes, NO outlines (no UIStroke on art)
--   * 3-tone shading: light (top-left) -> base -> shade (bottom-right)
--   * fully matte: no gloss/specular dots; soft paint blotches instead
--   * ANY hex works: tone() derives warm lights + cool shadows
local Config = require(script.Parent.Config)

local Paint = {}
Paint.Font = Enum.Font.FredokaOne

-- ---------------- colour ----------------
local function hsl(c: Color3)
	local r, g, b = c.R, c.G, c.B
	local mx, mn = math.max(r, g, b), math.min(r, g, b)
	local l = (mx + mn) / 2
	if mx == mn then
		return 0, 0, l
	end
	local d = mx - mn
	local s = if l > 0.5 then d / (2 - mx - mn) else d / (mx + mn)
	local h
	if mx == r then
		h = (g - b) / d + (if g < b then 6 else 0)
	elseif mx == g then
		h = (b - r) / d + 2
	else
		h = (r - g) / d + 4
	end
	return h * 60, s, l
end

local function fromHsl(h, s, l)
	h = h % 360
	s = math.clamp(s, 0, 1)
	l = math.clamp(l, 0, 1)
	local a = s * math.min(l, 1 - l)
	local function f(n)
		local k = (n + h / 30) % 12
		return l - a * math.max(-1, math.min(k - 3, 9 - k, 1))
	end
	return Color3.new(f(0), f(8), f(4))
end

local function toward(h, target, amt)
	local d = ((target - h + 540) % 360) - 180
	return h + math.sign(d) * math.min(math.abs(d), amt)
end

function Paint.C(hex): Color3
	if typeof(hex) == "Color3" then
		return hex
	end
	return Color3.fromHex(hex)
end

local toneCache = {}
-- Any colour -> { base, shade, light } (Color3s)
function Paint.tone(color)
	local key = typeof(color) == "Color3" and color:ToHex() or color
	if toneCache[key] then
		return toneCache[key]
	end
	local base = Paint.C(color)
	local h, s, l = hsl(base)
	local grey = s < 0.08
	local shade = fromHsl(if grey then 230 else toward(h, 245, 10), if grey then 0.1 else s * 0.88, math.max(l * 0.6, l - 0.12 - 0.05 * (1 - l)))
	local light = fromHsl(if grey then 50 else toward(h, 55, 8), if grey then 0.08 else s, l + math.min(0.1, (0.97 - l) * 0.5))
	local t = { base = base, shade = shade, light = light }
	toneCache[key] = t
	return t
end

function Paint.mix(a: Color3, b: Color3, t: number): Color3
	return a:Lerp(b, t)
end

-- ---------------- instance helpers ----------------
function Paint.new(class, props, children)
	local o = Instance.new(class)
	local parent
	for k, v in props or {} do
		if k == "Parent" then
			parent = v
		else
			o[k] = v
		end
	end
	for _, c in children or {} do
		c.Parent = o
	end
	if class:find("Frame") or class:find("Label") or class:find("Button") then
		if props == nil or props.BorderSizePixel == nil then
			o.BorderSizePixel = 0
		end
	end
	o.Parent = parent
	return o
end

function Paint.round(obj, r)
	Paint.new("UICorner", { CornerRadius = if typeof(r) == "UDim" then r else UDim.new(r or 0.5, 0), Parent = obj })
	return obj
end

function Paint.square(obj)
	Paint.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = obj })
	return obj
end

-- Apply the painted 3-tone gradient to a frame. rot = light direction (45 = top-left light)
function Paint.shade(obj, color, rot, flat)
	local t = Paint.tone(color)
	obj.BackgroundColor3 = Color3.new(1, 1, 1)
	local seq
	if flat then
		seq = ColorSequence.new({
			ColorSequenceKeypoint.new(0, t.base:Lerp(t.light, 0.5)),
			ColorSequenceKeypoint.new(1, t.base:Lerp(t.shade, 0.35)),
		})
	else
		seq = ColorSequence.new({
			ColorSequenceKeypoint.new(0, t.light),
			ColorSequenceKeypoint.new(0.38, t.base),
			ColorSequenceKeypoint.new(0.62, t.base),
			ColorSequenceKeypoint.new(1, t.shade),
		})
	end
	local g = obj:FindFirstChild("PaintGradient") or Paint.new("UIGradient", { Name = "PaintGradient", Parent = obj })
	g.Color = seq
	g.Rotation = rot or 45
	return obj
end

-- Soft paint blotch (NOT a highlight): low-contrast dab of the light tone.
local function blotch(parent, color, x, y, s, transp)
	local b = Paint.new("Frame", {
		BackgroundColor3 = Paint.tone(color).light,
		BackgroundTransparency = transp or 0.8,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(x, y),
		Size = UDim2.fromScale(s, s),
		ZIndex = parent.ZIndex + 1,
		Parent = parent,
	})
	Paint.round(b, 0.5)
	return b
end

-- Painted blob: the basic building block (circle by default).
-- opts: Position, Size, AnchorPoint, Rotation, Corner (0.5 = circle), Flat, Blotch, ZIndex
function Paint.blob(parent, color, opts)
	opts = opts or {}
	local f = Paint.new("Frame", {
		Name = opts.Name or "Blob",
		AnchorPoint = opts.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = opts.Position or UDim2.fromScale(0.5, 0.5),
		Size = opts.Size or UDim2.fromScale(1, 1),
		Rotation = opts.Rotation or 0,
		BackgroundTransparency = opts.Transparency or 0,
		ZIndex = opts.ZIndex or (parent:IsA("GuiObject") and parent.ZIndex or 1),
		Parent = parent,
	})
	Paint.round(f, opts.Corner or 0.5)
	Paint.shade(f, color, opts.LightRot or 45, opts.Flat)
	if opts.Blotch ~= false then
		blotch(f, color, 0.34, 0.3, 0.32, 0.78)
	end
	return f
end

function Paint.text(parent, text, opts)
	opts = opts or {}
	local l = Paint.new("TextLabel", {
		Name = opts.Name or "Text",
		BackgroundTransparency = 1,
		Text = text,
		Font = Paint.Font,
		TextScaled = true,
		TextColor3 = Paint.C(opts.Color or Config.Theme.Text),
		TextXAlignment = opts.AlignX or Enum.TextXAlignment.Center,
		TextYAlignment = opts.AlignY or Enum.TextYAlignment.Center,
		AnchorPoint = opts.AnchorPoint or Vector2.new(0, 0),
		Position = opts.Position or UDim2.fromScale(0, 0),
		Size = opts.Size or UDim2.fromScale(1, 1),
		ZIndex = opts.ZIndex or (parent:IsA("GuiObject") and parent.ZIndex + 1 or 1),
		Rotation = opts.Rotation or 0,
		RichText = opts.Rich or false,
		Parent = parent,
	})
	if opts.MaxSize then
		Paint.new("UITextSizeConstraint", { MaxTextSize = opts.MaxSize, Parent = l })
	end
	return l
end

-- ---------------- cups (your 25 Cup Rack styles) ----------------
-- w/h = vessel size, c = corner, stem = stem height (goblets), handle, lid = "dome",
-- neck = bottle neck, mat = "glass" | "ceramic" | "copper" | "frosted", rim = salted rim
Paint.CupStyles = { -- your 15 all-ages Cup Rack cups (DrinkCatalog v3)
	espresso_cup = { w = 0.4, h = 0.3, c = 0.3, handle = true, mat = "ceramic" },
	coffee_mug = { w = 0.5, h = 0.5, c = 0.18, handle = true, mat = "ceramic" },
	glass_mug = { w = 0.46, h = 0.56, c = 0.16, handle = true, mat = "glass" },
	tall_glass = { w = 0.34, h = 0.8, c = 0.14, mat = "glass" },
	frappe_cup = { w = 0.42, h = 0.66, c = 0.16, lid = "dome", mat = "glass" },
	dessert_glass = { w = 0.56, h = 0.34, c = 0.45, stem = 0.1, mat = "glass" },
	smoothie_glass = { w = 0.44, h = 0.68, c = 0.3, mat = "glass" },
	milkshake_glass = { w = 0.48, h = 0.6, c = 0.2, stem = 0.08, mat = "glass" },
	soda_glass = { w = 0.4, h = 0.72, c = 0.16, mat = "glass" },
	float_mug = { w = 0.5, h = 0.58, c = 0.16, handle = true, mat = "frosted" },
	boba_cup = { w = 0.44, h = 0.68, c = 0.14, lid = "dome", mat = "glass" },
	juice_glass = { w = 0.4, h = 0.56, c = 0.14, mat = "glass" },
	milk_bottle = { w = 0.36, h = 0.62, c = 0.2, neck = true, mat = "glass" },
	highball_glass = { w = 0.34, h = 0.78, c = 0.12, mat = "glass" },
	hurricane_glass = { w = 0.42, h = 0.66, c = 0.4, stem = 0.06, mat = "glass" },
}
local MAT = {
	glass = { "#e3f1f8", 0.5 },
	frosted = { "#eef6fb", 0.25 },
	ceramic = { "#f6e9dc", 0 },
	copper = { "#d9895a", 0 },
}

-- Draws a cup filling `holder` (a square frame). Returns the vessel (a CanvasGroup
-- that clips its children to the rounded glass, so liquid sits inside it) and parts.
function Paint.cup(holder, style, opts)
	opts = opts or {}
	local st = Paint.CupStyles[style] or Paint.CupStyles.tall_glass
	local z = holder.ZIndex + 1
	local P = UDim2.fromScale
	local m = MAT[st.mat] or MAT.glass
	local bottom = 0.96
	if st.stem then
		Paint.blob(holder, m[1], { Position = P(0.5, 0.95), Size = P(st.w * 0.7, 0.05), ZIndex = z, Blotch = false })
		local stem = Paint.blob(holder, m[1], { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.95), Size = P(0.05, st.stem), Corner = 0.4, ZIndex = z, Blotch = false })
		stem.BackgroundTransparency = m[2] * 0.6
		bottom = 0.95 - st.stem + 0.02
	else
		Paint.shadow(holder, { Position = P(0.5, 0.965), Size = P(st.w * 1.05, 0.05), ZIndex = z })
	end
	local vessel = Paint.new("CanvasGroup", {
		Name = "Vessel", AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, bottom), Size = P(st.w, st.h),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = m[2], ZIndex = z + 1, Parent = holder,
	})
	Paint.round(vessel, st.c)
	Paint.shade(vessel, m[1], 30)
	local top = bottom - st.h
	if st.handle then
		local h = Paint.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = P(0.5 + st.w / 2 + 0.03, bottom - st.h * 0.5),
			Size = P(st.h * 0.42, st.h * 0.5), BackgroundTransparency = 1, ZIndex = z, Parent = holder,
		})
		local ring = Paint.blob(h, m[1], { Size = P(1, 1), Corner = 0.45, ZIndex = z, Blotch = false })
		ring.BackgroundTransparency = m[2] * 0.5
		local hole = Paint.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = P(0.55, 0.5), Size = P(0.5, 0.56),
			BackgroundColor3 = Paint.C(opts.Behind or Config.Theme.Panel), ZIndex = z, Parent = ring })
		Paint.round(hole, 0.45)
	end
	if st.neck then
		local n = Paint.blob(holder, m[1], { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, top + 0.02), Size = P(st.w * 0.5, 0.14), Corner = 0.2, ZIndex = z + 2, Blotch = false })
		n.BackgroundTransparency = m[2]
		Paint.blob(holder, opts.Accent or "#e8c35a", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, top - 0.1), Size = P(st.w * 0.56, 0.05), Corner = 0.3, ZIndex = z + 3 })
		top -= 0.12
	end
	if st.rim then
		local r = Paint.blob(vessel, "#fbfbf8", { AnchorPoint = Vector2.new(0.5, 0), Position = P(0.5, 0), Size = P(1, 0.1), Corner = 0.1, ZIndex = z + 6, Blotch = false })
		r.BackgroundTransparency = 0.1
	end
	-- rim ellipse gives the top a 3D opening
	local rimEll = Paint.blob(holder, m[1], { Position = P(0.5, top + 0.005), Size = P(st.w * 1.02, 0.045), ZIndex = z + 5, Blotch = false, LightRot = 90 })
	rimEll.BackgroundTransparency = math.max(0, m[2] - 0.15)
	if st.lid == "dome" and not opts.NoLid then
		local lid = Paint.blob(holder, "#f4fafd", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, top + 0.02), Size = P(st.w * 1.04, st.w * 0.5), ZIndex = z + 6, Blotch = false, LightRot = 70 })
		lid.BackgroundTransparency = 0.45
	end
	return vessel, { top = top, bottom = bottom, style = st }
end

-- ---------------- ingredient art ----------------
-- Draws a painted placeholder inside `parent` (keep parent square for best results).
-- desc = { Color = hex|Color3, Shape = "jar"|"bottle"|"carton"|"fruit"|..., CupStyle = cup id, Image = "rbxassetid://..." }
-- (Bridge.icon() uses YOUR DrinkImages picture first and only falls back to this.)
function Paint.art(parent, desc, opts)
	opts = opts or {}
	local ing = if typeof(desc) == "table" then desc else { Color = desc, Shape = "circle" }
	local z = parent.ZIndex + 1
	local holder = Paint.new("Frame", {
		Name = "Art",
		BackgroundTransparency = 1,
		AnchorPoint = opts.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = opts.Position or UDim2.fromScale(0.5, 0.5),
		Size = opts.Size or UDim2.fromScale(1, 1),
		Rotation = opts.Rotation or 0,
		ZIndex = z,
		Parent = parent,
	})
	if ing.Image and ing.Image ~= "" then
		Paint.new("ImageLabel", {
			BackgroundTransparency = 1, Image = ing.Image, ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(1, 1), ZIndex = z, Parent = holder,
		})
		return holder
	end
	local c, shape = ing.Color, ing.Shape
	local P = UDim2.fromScale
	if shape == "circle" then
		Paint.blob(holder, c, { Size = P(0.86, 0.8), ZIndex = z })
	elseif shape == "dot" then
		Paint.blob(holder, c, { Size = P(0.6, 0.6), ZIndex = z })
	elseif shape == "cube" then
		local b = Paint.blob(holder, c, { Size = P(0.72, 0.72), Corner = 0.24, Rotation = 12, ZIndex = z })
		b.BackgroundTransparency = 0.12
	elseif shape == "square" then
		Paint.blob(holder, c, { Size = P(0.78, 0.66), Corner = 0.22, ZIndex = z })
	elseif shape == "slice" then
		local rind = Paint.blob(holder, c, { Size = P(0.9, 0.9), ZIndex = z, Blotch = false })
		local t = Paint.tone(c)
		local flesh = Paint.blob(rind, t.light:Lerp(Color3.new(1, 1, 1), 0.25), { Size = P(0.8, 0.8), ZIndex = z + 1, Flat = true, Blotch = false })
		for i = 0, 3 do
			Paint.new("Frame", {
				BackgroundColor3 = t.base, BackgroundTransparency = 0.35, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = P(0.5, 0.5), Size = P(0.05, 0.86), Rotation = i * 45, ZIndex = z + 2, Parent = flesh,
			})
		end
		Paint.blob(flesh, t.light:Lerp(Color3.new(1, 1, 1), 0.5), { Size = P(0.16, 0.16), ZIndex = z + 3, Blotch = false })
	elseif shape == "leaf" then
		local l = Paint.blob(holder, c, { Size = P(0.9, 0.46), Rotation = -32, ZIndex = z })
		Paint.new("Frame", {
			BackgroundColor3 = Paint.tone(c).light, BackgroundTransparency = 0.3, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = P(0.5, 0.5), Size = P(0.7, 0.07), ZIndex = z + 2, Parent = l,
		})
	elseif shape == "swirl" then
		Paint.blob(holder, c, { Position = P(0.5, 0.72), Size = P(0.9, 0.4), ZIndex = z })
		Paint.blob(holder, c, { Position = P(0.5, 0.5), Size = P(0.68, 0.34), ZIndex = z + 1 })
		Paint.blob(holder, c, { Position = P(0.52, 0.3), Size = P(0.42, 0.28), ZIndex = z + 2 })
	elseif shape == "pill" then
		Paint.blob(holder, c, { Size = P(0.26, 0.9), Rotation = 30, ZIndex = z })
	elseif shape == "drop" then
		Paint.blob(holder, c, { Position = P(0.5, 0.62), Size = P(0.7, 0.66), ZIndex = z })
		Paint.blob(holder, c, { Position = P(0.5, 0.36), Size = P(0.4, 0.4), Corner = 0.2, Rotation = 45, ZIndex = z, Blotch = false })
	elseif shape == "ring" then
		local r = Paint.blob(holder, c, { Size = P(0.92, 0.8), ZIndex = z })
		local hole = Paint.new("Frame", {
			BackgroundColor3 = Paint.C(opts.HoleColor or Config.Theme.Panel), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = P(0.5, 0.5), Size = P(0.3, 0.3), ZIndex = z + 2, Parent = r,
		})
		Paint.round(hole, 0.5)
	elseif shape == "star" then
		Paint.blob(holder, c, { Size = P(0.66, 0.66), Corner = 0.18, ZIndex = z, Blotch = false })
		Paint.blob(holder, c, { Size = P(0.66, 0.66), Corner = 0.18, Rotation = 45, ZIndex = z })
	elseif shape == "cup" then
		if ing.CupStyle then
			Paint.cup(holder, ing.CupStyle, { Behind = opts.HoleColor })
		else
			local s = ing.Size or 1
			local body = Paint.blob(holder, c, { Position = P(0.5, 0.56), Size = P(0.56 * s, 0.72 * s), Corner = 0.16, ZIndex = z, LightRot = 20 })
			body.BackgroundTransparency = 0.1
			Paint.blob(holder, c, { Position = P(0.5, 0.56 - 0.36 * s), Size = P(0.62 * s, 0.12 * s), ZIndex = z + 1, LightRot = 90, Blotch = false })
		end
	elseif shape == "jar" then -- pantry jar: glass, contents, pastel lid, paper label
		local body = Paint.new("CanvasGroup", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.94), Size = P(0.62, 0.64),
			BackgroundColor3 = Paint.C("#eaf4f9"), BackgroundTransparency = 0.35, ZIndex = z, Parent = holder })
		Paint.round(body, 0.22)
		Paint.blob(body, c, { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 1), Size = P(1, 0.74), Corner = 0.1, ZIndex = z + 1 })
		Paint.blob(holder, "#f4f0ea", { Position = P(0.5, 0.58), Size = P(0.46, 0.16), Corner = 0.25, ZIndex = z + 3, Blotch = false })
		Paint.blob(holder, Paint.tone(c).shade:Lerp(Color3.fromHex("#f59ac0"), 0.35), { Position = P(0.5, 0.29), Size = P(0.66, 0.13), Corner = 0.3, ZIndex = z + 2 })
	elseif shape == "bottle" then -- syrup bottle with pump cap
		Paint.shadow(holder, { Position = P(0.5, 0.95), Size = P(0.5, 0.05), ZIndex = z })
		Paint.blob(holder, c, { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.94), Size = P(0.46, 0.56), Corner = 0.24, ZIndex = z + 1 })
		Paint.blob(holder, c, { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.4), Size = P(0.22, 0.16), Corner = 0.25, ZIndex = z + 1, Blotch = false })
		Paint.blob(holder, "#3b4763", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.26), Size = P(0.26, 0.1), Corner = 0.3, ZIndex = z + 2, Blotch = false })
		Paint.blob(holder, "#fbf3e2", { Position = P(0.5, 0.68), Size = P(0.34, 0.18), Corner = 0.2, ZIndex = z + 3, Blotch = false })
	elseif shape == "carton" then -- dairy / juice carton with gable top
		Paint.shadow(holder, { Position = P(0.5, 0.95), Size = P(0.56, 0.05), ZIndex = z })
		Paint.blob(holder, "#fbf8f1", { Position = P(0.5, 0.3), Size = P(0.38, 0.38), Corner = 0.12, Rotation = 45, ZIndex = z, Blotch = false })
		Paint.blob(holder, "#fbf8f1", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.94), Size = P(0.52, 0.56), Corner = 0.1, ZIndex = z + 1 })
		Paint.blob(holder, c, { Position = P(0.5, 0.68), Size = P(0.52, 0.22), Corner = 0.1, ZIndex = z + 2 })
	elseif shape == "scoop" then -- freezer tub with a scoop on top
		Paint.blob(holder, "#8ec5f0", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.94), Size = P(0.66, 0.4), Corner = 0.2, ZIndex = z + 1 })
		Paint.blob(holder, c, { Position = P(0.5, 0.46), Size = P(0.56, 0.44), ZIndex = z + 2 })
	elseif shape == "fruit" then
		Paint.blob(holder, c, { Position = P(0.5, 0.56), Size = P(0.78, 0.72), ZIndex = z })
		Paint.blob(holder, "#7a5a3a", { AnchorPoint = Vector2.new(0.5, 1), Position = P(0.5, 0.26), Size = P(0.06, 0.14), Corner = 0.4, ZIndex = z + 1, Blotch = false })
		Paint.blob(holder, "#55a444", { Position = P(0.62, 0.18), Size = P(0.26, 0.13), Rotation = -25, ZIndex = z + 1 })
	elseif shape == "berries" then
		for i, o in { { 0.36, 0.62 }, { 0.64, 0.62 }, { 0.5, 0.38 } } do
			Paint.blob(holder, c, { Position = P(o[1], o[2]), Size = P(0.42, 0.42), ZIndex = z + i })
		end
	else
		Paint.blob(holder, c, { Size = P(0.8, 0.8), ZIndex = z })
	end
	return holder
end

-- A soft ground shadow under objects (value only, never black)
function Paint.shadow(parent, opts)
	opts = opts or {}
	local s = Paint.new("Frame", {
		Name = "Shadow",
		BackgroundColor3 = Paint.C("#161b29"),
		BackgroundTransparency = opts.Transparency or 0.55,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = opts.Position or UDim2.fromScale(0.5, 0.95),
		Size = opts.Size or UDim2.fromScale(0.7, 0.08),
		ZIndex = opts.ZIndex or parent.ZIndex,
		Parent = parent,
	})
	Paint.round(s, 0.5)
	return s
end

return Paint
