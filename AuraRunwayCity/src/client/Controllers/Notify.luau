--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = require(script.Parent.Parent.UI)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local P = UI.P

local Notify = {}
local gui, stack

local KIND = {
	info = { P.Lavender, "✦" },
	success = { P.Success, "✓" },
	warn = { P.RoseGold, "!" },
	error = { P.Danger, "✕" },
}

function Notify.Show(text: string, kind: string?)
	local k = KIND[kind or "info"] or KIND.info
	local toast = UI.panel(stack, { Size = UDim2.fromOffset(460, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 0.05 })
	UI.pad(toast, 12, 16, 12, 56)
	local dot = UI.new("TextLabel", {
		BackgroundColor3 = k[1],
		Text = k[2],
		Font = UI.Font.Title,
		TextSize = 18,
		TextColor3 = P.Plum,
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.new(0, -42, 0, -3),
		Parent = toast,
	})
	UI.round(dot)
	UI.label(toast, text, { AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), TextSize = 17, Font = UI.Font.Medium })
	local sc = UI.new("UIScale", { Scale = 0.7, Parent = toast })
	UI.tween(sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(4.5, function()
		UI.tween(sc, 0.2, { Scale = 0.01 })
		task.wait(0.22)
		toast:Destroy()
	end)
end

function Notify.Init()
	gui = UI.screen("AuraNotify", 50)
	local holder = UI.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.fromOffset(460, 400),
		Parent = gui,
	})
	UI.autoScale(holder)
	stack = holder
	UI.list(stack, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Center)
	Remotes.Event("Notify").OnClientEvent:Connect(function(text, kind)
		Notify.Show(text, kind)
	end)
end

return Notify
