--!nonstrict
-- AuraFizz2D client starter (StarterPlayerScripts).
-- Adds the "AURAFIZZ" open button + keyboard shortcut, and listens for the server
-- asking to open a 2D step (ReplicatedStorage.AuraFizz2DOpen:FireClient(player, what, ...)).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Pkg = ReplicatedStorage:WaitForChild("AuraFizz2D")
local Config = require(Pkg:WaitForChild("Config"))
local Paint = require(Pkg:WaitForChild("Paint"))
local FX = require(Pkg:WaitForChild("FX"))
local Api = require(Pkg:WaitForChild("Api"))

local function toggle()
	if Api.IsOpen() then
		Api.Close()
	else
		Api.OpenCafe()
	end
end

if Config.ShowOpenButton then
	local sg = Paint.new("ScreenGui", { Name = "AuraFizz2DButton", ResetOnSpawn = false, DisplayOrder = 5,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui") })
	local b = Paint.new("TextButton", { Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(150, 52), Parent = sg })
	Paint.round(b, UDim.new(0.5, 0))
	Paint.shade(b, Config.Theme.Accent, 90)
	Paint.text(b, "🧋 AURAFIZZ", { Color = Config.Theme.TextDark, Position = UDim2.fromScale(0.08, 0.18), Size = UDim2.fromScale(0.84, 0.64) })
	FX.bob(b, 0.004, 2.6)
	b.Activated:Connect(function()
		FX.bounce(b, 0.15)
		toggle()
	end)
end

if Config.OpenKey then
	UserInputService.InputBegan:Connect(function(input, gp)
		if not gp and input.KeyCode == Config.OpenKey then
			toggle()
		end
	end)
end

-- server-driven opens (e.g. from a ProximityPrompt handled on the server)
local open = ReplicatedStorage:WaitForChild("AuraFizz2DOpen", 10)
local remote = ReplicatedStorage:FindFirstChild("AuraFizz2DRemote")
if open then
	open.OnClientEvent:Connect(function(what, a, b)
		task.spawn(function()
			local score
			if what == "Cafe" then
				Api.OpenCafe()
			elseif what == "Drink" then
				local r = Api.MakeDrink(a)
				score = r and r.Total and r.Total / 100
			elseif what == "Action" then
				score = Api.PlayAction(a, b)
			elseif what == "Storage" then
				score = Api.PickFromStorage(a, b)
			elseif what == "Step" then
				score = Api.PlayStep(a, b)
			end
			if score ~= nil and remote then
				pcall(remote.InvokeServer, remote, "StepResult", what, a, score)
			end
		end)
	end)
end
