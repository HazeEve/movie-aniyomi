--!nonstrict
-- Branded loading screen (plum + champagne) shown while the city streams in.
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "AuraLoading"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
pcall(function()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

local function hex(h)
	return Color3.fromHex(h)
end

local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.new(1, 1, 1)
bg.BorderSizePixel = 0
bg.Parent = gui
local g = Instance.new("UIGradient")
g.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, hex("1D1428")),
	ColorSequenceKeypoint.new(0.55, hex("3F2C5A")),
	ColorSequenceKeypoint.new(1, hex("7A5FB8")),
})
g.Rotation = 90
g.Parent = bg

-- soft glowing orbs
local orbs = {}
for i, c in { "FF8BCB", "A88CFF", "F1DDB8", "86DBFF" } do
	local o = Instance.new("Frame")
	o.AnchorPoint = Vector2.new(0.5, 0.5)
	o.Size = UDim2.fromScale(0.35, 0.35)
	o.SizeConstraint = Enum.SizeConstraint.RelativeYY
	o.Position = UDim2.fromScale(0.2 + i * 0.15, 0.3 + (i % 2) * 0.35)
	o.BackgroundColor3 = hex(c)
	o.BackgroundTransparency = 0.82
	o.BorderSizePixel = 0
	o.Parent = bg
	local cr = Instance.new("UICorner")
	cr.CornerRadius = UDim.new(1, 0)
	cr.Parent = o
	orbs[i] = o
end

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.42)
title.Size = UDim2.fromScale(0.8, 0.16)
title.Font = Enum.Font.Bodoni
title.TextScaled = true
title.Text = "AURA RUNWAY"
title.TextColor3 = hex("F1DDB8")
title.Parent = bg
local st = Instance.new("UIStroke")
st.Color = hex("FF8BCB")
st.Thickness = 2
st.Transparency = 0.3
st.Parent = title

local sub = Instance.new("TextLabel")
sub.BackgroundTransparency = 1
sub.AnchorPoint = Vector2.new(0.5, 0)
sub.Position = UDim2.fromScale(0.5, 0.52)
sub.Size = UDim2.fromScale(0.6, 0.05)
sub.Font = Enum.Font.GothamBold
sub.TextScaled = true
sub.Text = "DRESS  •  WALK  •  WIN"
sub.TextColor3 = hex("DCD0F3")
sub.Parent = bg

local track = Instance.new("Frame")
track.AnchorPoint = Vector2.new(0.5, 0)
track.Position = UDim2.fromScale(0.5, 0.64)
track.Size = UDim2.fromScale(0.34, 0.012)
track.BackgroundColor3 = hex("1D1428")
track.BorderSizePixel = 0
track.Parent = bg
local tc = Instance.new("UICorner")
tc.CornerRadius = UDim.new(1, 0)
tc.Parent = track
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0.05, 1)
fill.BackgroundColor3 = hex("F4C7D6")
fill.BorderSizePixel = 0
fill.Parent = track
local fc = tc:Clone()
fc.Parent = fill

local tip = Instance.new("TextLabel")
tip.BackgroundTransparency = 1
tip.AnchorPoint = Vector2.new(0.5, 0)
tip.Position = UDim2.fromScale(0.5, 0.68)
tip.Size = UDim2.fromScale(0.7, 0.035)
tip.Font = Enum.Font.GothamMedium
tip.TextScaled = true
tip.TextColor3 = hex("B9A5E6")
tip.Parent = bg
local tips = {
	"Tap 👗 to try on anything from the Roblox catalog",
	"Tap any player to shop their look",
	"Join the show and win hearts on the runway 💗",
	"Rent a stall in Aura Mall and sell your UGC",
	"Grab a latte at Blush Café ☕  •  nap at the Grand Hotel 💤",
	"Play 300 chords on guitar, piano, violin & more 🎸",
}
tip.Text = tips[math.random(1, #tips)]

local t = 0
local conn = RunService.RenderStepped:Connect(function(dt)
	t += dt
	for i, o in orbs do
		o.Position = UDim2.fromScale(0.2 + i * 0.15 + math.sin(t * 0.4 + i) * 0.04, 0.3 + (i % 2) * 0.35 + math.cos(t * 0.3 + i) * 0.05)
	end
	st.Color = hex("FF8BCB"):Lerp(hex("A88CFF"), (math.sin(t * 1.5) + 1) / 2)
	if math.floor(t / 3) ~= math.floor((t - dt) / 3) then
		tip.Text = tips[math.random(1, #tips)]
	end
end)

local start = os.clock()
local function progress(a)
	TweenService:Create(fill, TweenInfo.new(0.4), { Size = UDim2.fromScale(math.clamp(a, 0.05, 1), 1) }):Play()
end
if not game:IsLoaded() then
	game.Loaded:Wait()
end
progress(0.5)
-- wait for our UI to be built (or a timeout)
local pg = player:WaitForChild("PlayerGui")
while not pg:FindFirstChild("AuraHUD") and os.clock() - start < 15 do
	task.wait(0.2)
	progress(0.5 + math.min(0.4, (os.clock() - start) / 30))
end
progress(1)
task.wait(0.6)
for _, d in bg:GetDescendants() do
	if d:IsA("TextLabel") then
		TweenService:Create(d, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
	elseif d:IsA("UIStroke") then
		TweenService:Create(d, TweenInfo.new(0.6), { Transparency = 1 }):Play()
	elseif d:IsA("Frame") then
		TweenService:Create(d, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
	end
end
TweenService:Create(bg, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
task.wait(0.9)
conn:Disconnect()
gui:Destroy()
