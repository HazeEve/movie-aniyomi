--!nonstrict
-- FizzFX — the "juice": bouncy pops, sparkles, confetti, floating grades.
-- Everything is painted in the pastel style (no outlines, no gloss).
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Config = require(script.Parent.Config)
local Paint = require(script.Parent.Paint)
local Bridge = require(script.Parent.Bridge)

local FX = {}
local rng = Random.new()

function FX.tween(obj, t, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function scaleOf(obj)
	local s = obj:FindFirstChild("FXScale")
	if not s then
		s = Instance.new("UIScale")
		s.Name = "FXScale"
		s.Parent = obj
	end
	return s
end

-- Pop in from nothing with a springy overshoot.
function FX.pop(obj, delay, dur)
	local s = scaleOf(obj)
	s.Scale = 0
	task.delay(delay or 0, function()
		FX.tween(s, dur or 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
	return obj
end

-- Quick squash on press.
function FX.bounce(obj, amount)
	local s = scaleOf(obj)
	s.Scale = 1 - (amount or 0.12)
	FX.tween(s, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- Gentle idle bob (for customers, the order card, the logo).
function FX.bob(obj, amp, period)
	local base = obj.Position
	task.spawn(function()
		local t0 = os.clock()
		while obj.Parent do
			local y = math.sin((os.clock() - t0) * math.pi * 2 / (period or 2.4)) * (amp or 0.006)
			obj.Position = base + UDim2.fromScale(0, y)
			task.wait(1 / 30)
		end
	end)
end

-- Wobble rotation (shaking cups, happy customers).
function FX.wobble(obj, deg, dur)
	task.spawn(function()
		local base = obj.Rotation
		local t0 = os.clock()
		while os.clock() - t0 < (dur or 0.5) and obj.Parent do
			local k = 1 - (os.clock() - t0) / (dur or 0.5)
			obj.Rotation = base + math.sin((os.clock() - t0) * 40) * (deg or 8) * k
			task.wait()
		end
		if obj.Parent then
			obj.Rotation = base
		end
	end)
end

-- Plays one of YOUR sounds (ReplicatedStorage.Drinks.Sounds) through Config.SoundMap.
function FX.sound(name)
	local id = Bridge.soundId(Config.SoundMap[name] or name)
	if not id then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = 0.6
	s.Parent = SoundService
	s:Play()
	s.Ended:Connect(function()
		s:Destroy()
	end)
end

-- Floating grade text: "Perfect!" pops, rises, fades.
function FX.floatText(parent, text, color, pos, size)
	local holder = Paint.new("Frame", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = pos or UDim2.fromScale(0.5, 0.4), Size = size or UDim2.fromScale(0.5, 0.14),
		ZIndex = 80, Parent = parent,
	})
	local shadow = Paint.text(holder, text, { Color = "#1b2131", Position = UDim2.fromScale(0.012, 0.05), ZIndex = 81 })
	shadow.TextTransparency = 0.5
	local l = Paint.text(holder, text, { Color = color or Config.Theme.Good, ZIndex = 82 })
	FX.pop(holder, 0, 0.4)
	task.delay(0.75, function()
		FX.tween(holder, 0.6, { Position = holder.Position - UDim2.fromScale(0, 0.08) })
		FX.tween(l, 0.6, { TextTransparency = 1 })
		FX.tween(shadow, 0.6, { TextTransparency = 1 })
		task.wait(0.65)
		holder:Destroy()
	end)
end

-- Little painted stars bursting out of a point.
function FX.sparkle(parent, pos, color, n)
	for _ = 1, n or 8 do
		local c = color or Config.Pastels[rng:NextInteger(1, #Config.Pastels)]
		local s = Paint.new("Frame", {
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = pos,
			Size = UDim2.fromOffset(18, 18), ZIndex = 85, Parent = parent,
		})
		Paint.blob(s, c, { Size = UDim2.fromScale(1, 1), Corner = 0.2, ZIndex = 85, Blotch = false })
		Paint.blob(s, c, { Size = UDim2.fromScale(1, 1), Corner = 0.2, Rotation = 45, ZIndex = 85, Blotch = false })
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(0.05, 0.14)
		FX.tween(s, 0.7, {
			Position = pos + UDim2.fromScale(math.cos(a) * d, math.sin(a) * d),
			Rotation = rng:NextNumber(-180, 180), Size = UDim2.fromOffset(4, 4),
		})
		task.delay(0.72, function()
			s:Destroy()
		end)
	end
end

-- Confetti rain over the whole panel.
function FX.confetti(parent, n)
	for _ = 1, n or 40 do
		local c = Config.Pastels[rng:NextInteger(1, #Config.Pastels)]
		local p = Paint.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(rng:NextNumber(0, 1), -0.05),
			Size = UDim2.fromScale(rng:NextNumber(0.008, 0.016), rng:NextNumber(0.02, 0.035)),
			Rotation = rng:NextNumber(0, 360), ZIndex = 90, Parent = parent,
		})
		Paint.round(p, 0.3)
		Paint.shade(p, c, 45, true)
		local t = rng:NextNumber(1.4, 2.4)
		task.delay(rng:NextNumber(0, 0.5), function()
			FX.tween(p, t, {
				Position = UDim2.fromScale(p.Position.X.Scale + rng:NextNumber(-0.1, 0.1), 1.05),
				Rotation = p.Rotation + rng:NextNumber(-540, 540),
			}, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
			task.wait(t)
			p:Destroy()
		end)
	end
end

-- Count a number label up (coins, scores).
function FX.countUp(label, from, to, dur, fmt)
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < dur do
			local k = (os.clock() - t0) / dur
			label.Text = string.format(fmt or "%d", math.floor(from + (to - from) * (1 - (1 - k) ^ 3) + 0.5))
			task.wait()
		end
		label.Text = string.format(fmt or "%d", to)
	end)
end

-- Something drops in from above and lands with a bounce.
function FX.drop(obj, fromOffset)
	local target = obj.Position
	obj.Position = target - UDim2.fromScale(0, fromOffset or 0.35)
	FX.tween(obj, 0.55, { Position = target }, Enum.EasingStyle.Bounce)
end

-- Slide a whole screen in from the right.
function FX.slideIn(obj)
	local target = obj.Position
	obj.Position = target + UDim2.fromScale(0.35, 0)
	FX.tween(obj, 0.45, { Position = target }, Enum.EasingStyle.Back)
end

return FX
