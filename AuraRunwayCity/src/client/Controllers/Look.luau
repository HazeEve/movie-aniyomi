--!nonstrict
-- Tap / click any player to see what they're wearing and BUY or TRY each item.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(script.Parent.Parent.UI)
local State = require(script.Parent.Parent.State)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local P = UI.P

local Look = {}
local player = Players.LocalPlayer
local list, header, headImg, nameL, subL, copyBtn
local currentId = 0
local Catalog, Notify

local infoCache = {}
local function info(id: number)
	if infoCache[id] then
		return infoCache[id]
	end
	local ok, res = pcall(function()
		return MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset)
	end)
	if ok and res then
		infoCache[id] = res
		return res
	end
	return nil
end

local function row(item, order: number)
	local card = UI.card(list, { LayoutOrder = order, Size = UDim2.new(1, -8, 0, 84) })
	UI.new("ImageLabel", { BackgroundTransparency = 1, Image = UI.assetThumb(item.Id), Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(72, 72), Parent = card })
	local nameLabel = UI.label(card, "…", { Position = UDim2.fromOffset(90, 10), Size = UDim2.new(1, -290, 0, 22), TextColor3 = P.Text, TextSize = 16, TextTruncate = Enum.TextTruncate.AtEnd })
	local typeLabel = UI.label(card, item.Type or "", { Position = UDim2.fromOffset(90, 32), Size = UDim2.new(1, -290, 0, 18), TextColor3 = P.TextSoft, TextSize = 13, Font = UI.Font.Medium })
	local priceLabel = UI.label(card, "", { Position = UDim2.fromOffset(90, 52), Size = UDim2.new(1, -290, 0, 22), TextColor3 = P.Violet, TextSize = 16, Font = UI.Font.Title })
	local try = UI.button(card, "Try On", "secondary", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -110, 0.5, 0), Size = UDim2.fromOffset(90, 40), TextSize = 15 })
	local buy = UI.button(card, "Buy", "gold", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(90, 40), TextSize = 17 })
	task.spawn(function()
		local i = info(item.Id)
		if i and card.Parent then
			nameLabel.Text = i.Name
			local creator = i.Creator and i.Creator.Name or ""
			typeLabel.Text = (item.Type or "") .. (creator ~= "" and ("  •  by " .. creator) or "")
			priceLabel.Text = UI.priceText(i.PriceInRobux, i.IsForSale)
			if not i.IsForSale then
				UI.style(buy, "dark")
				buy.Text = "Off Sale"
			end
		end
	end)
	try.Activated:Connect(function()
		Catalog.Call("Toggle", item.Id, true)
	end)
	buy.Activated:Connect(function()
		MarketplaceService:PromptPurchase(player, item.Id)
	end)
end

function Look.Open(userId: number)
	currentId = userId
	UI.open("Look", userId)
end

local function populate(userId: number)
	for _, c in list:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local target = Players:GetPlayerByUserId(userId)
	headImg.Image = UI.headshot(userId)
	nameL.Text = target and target.DisplayName or "Player"
	subL.Text = target and ("@" .. target.Name) or ""
	local data = Remotes.Func("GetLook"):InvokeServer(userId)
	if currentId ~= userId then
		return
	end
	if not data or #data.Items == 0 then
		UI.label(list, "Nothing to show right now.", { TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = P.Lilac })
		return
	end
	local order = 0
	for _, item in data.Items do
		if item.Type ~= "Animation" then
			order += 1
			row(item, order)
		end
	end
end

function Look.Init(controllers)
	Catalog = controllers.Catalog
	Notify = controllers.Notify
	local gui = UI.screen("AuraLook", 12)
	local holder, body = UI.window(gui, "Look", "Shop the Look", Vector2.new(620, 560))
	header = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 80), Parent = body })
	headImg = UI.new("ImageLabel", { BackgroundColor3 = P.Lilac, Size = UDim2.fromOffset(72, 72), Parent = header })
	UI.round(headImg)
	nameL = UI.label(header, "", { Position = UDim2.fromOffset(86, 8), Size = UDim2.new(1, -280, 0, 30), TextSize = 24, Font = UI.Font.Title, TextColor3 = P.Champagne })
	subL = UI.label(header, "", { Position = UDim2.fromOffset(86, 40), Size = UDim2.new(1, -280, 0, 20), TextSize = 15, TextColor3 = P.Lilac, Font = UI.Font.Medium })
	copyBtn = UI.button(header, "✨ Copy Full Look", "primary", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 14), Size = UDim2.fromOffset(180, 46), TextSize = 16 })
	copyBtn.Activated:Connect(function()
		Catalog.Call("CopyLook", currentId)
	end)
	list = UI.scroll(body, { Position = UDim2.fromOffset(0, 90), Size = UDim2.new(1, 0, 1, -90) })
	UI.list(list, Enum.FillDirection.Vertical, 8)
	UI.registerModal("Look", holder, function(userId)
		populate(userId)
	end)

	-- tap a character to open their look
	local downPos, downTime
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			downPos = input.Position
			downTime = os.clock()
		end
	end)
	UserInputService.InputEnded:Connect(function(input, processed)
		if processed or not downPos then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local moved = (Vector2.new(input.Position.X, input.Position.Y) - Vector2.new(downPos.X, downPos.Y)).Magnitude
		local quick = os.clock() - downTime < 0.35
		downPos = nil
		if moved > 12 or not quick then
			return
		end
		local cam = workspace.CurrentCamera
		local ray = cam:ViewportPointToRay(input.Position.X, input.Position.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { player.Character }
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 250, params)
		if hit and hit.Instance then
			local model = hit.Instance:FindFirstAncestorOfClass("Model")
			while model and not model:FindFirstChildOfClass("Humanoid") do
				model = model:FindFirstAncestorOfClass("Model")
			end
			local other = model and Players:GetPlayerFromCharacter(model)
			if other and other ~= player then
				Look.Open(other.UserId)
			end
		end
	end)
end

return Look
