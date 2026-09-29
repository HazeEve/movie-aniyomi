--!nonstrict
-- Aura Music Kit — client start. Put the "AuraMusicClient" folder in
-- StarterPlayer > StarterPlayerScripts. Adds a "🎸 Music" button.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
player:WaitForChild("PlayerGui")

local UI = require(script.Parent.UI)
local State = require(script.Parent.State)
local C = script.Parent.Controllers
local controllers = { Notify = require(C.Notify), Music = require(C.Music) }

State.Init()
controllers.Notify.Init(controllers)
controllers.Music.Init(controllers)

local gui = UI.screen("AuraMusicKitButton", 5)
local holder = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0.4, 0), Size = UDim2.fromOffset(160, 48), Parent = gui })
UI.autoScale(holder)
local b = UI.button(holder, "🎸  Music", "gold", { Size = UDim2.fromScale(1, 1), TextSize = 18 })
b.Activated:Connect(function()
	controllers.Music.Toggle()
end)
