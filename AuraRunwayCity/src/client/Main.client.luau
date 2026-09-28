--!nonstrict
-- Aura Runway City — client bootstrap
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
player:WaitForChild("PlayerGui")

local State = require(script.Parent.State)
local C = script.Parent.Controllers
local controllers = {}
for _, name in { "Notify", "HUD", "Catalog", "Look", "Show", "Music", "Auction", "Stall", "RP", "StageFX", "NightLights" } do
	controllers[name] = require(C:WaitForChild(name))
end

State.Init()
local order = { "Notify", "Catalog", "Look", "Show", "Music", "Auction", "Stall", "RP", "StageFX", "NightLights", "HUD" }
for _, name in order do
	local ok, err = pcall(controllers[name].Init, controllers)
	if not ok then
		warn("[Aura] " .. name .. " failed to start:", err)
	end
end

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

task.delay(2, function()
	controllers.Notify.Show("Welcome to Aura Runway City ✨ Tap 👗 to style your look, ✨ to join the show!", "info")
end)
