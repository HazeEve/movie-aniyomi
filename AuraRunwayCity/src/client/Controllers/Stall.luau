--!nonstrict
-- Mall stall panel: rent, rename, add/remove your UGC items, choose a colour,
-- and for shoppers: browse, try on, buy.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local UI = require(script.Parent.Parent.UI)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local P = UI.P

local Stall = {}
local player = Players.LocalPlayer

function Stall.Init(controllers)
	local Notify, Catalog = controllers.Notify, controllers.Catalog
	local gui = UI.screen("AuraStall", 13)
	local holder, body, title = UI.window(gui, "Stall", "Shop", Vector2.new(820, 580))
	local currentId, data = nil, nil

	local ownerL = UI.label(body, "", { Size = UDim2.new(1, -260, 0, 22), TextColor3 = P.Lilac, TextSize = 15, Font = UI.Font.Medium })
	local timeL = UI.label(body, "", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(250, 22), TextColor3 = P.Blush, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Right })

	-- owner tools
	local tools = UI.panel(body, { Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 120), BackgroundTransparency = 0.35 })
	UI.pad(tools, 10)
	local nameBox = UI.textbox(tools, "Shop name", { Size = UDim2.fromOffset(250, 44) })
	local renameBtn = UI.button(tools, "Rename", "secondary", { Position = UDim2.fromOffset(258, 1), Size = UDim2.fromOffset(96, 42) })
	local addBox = UI.textbox(tools, "Item link or ID (your UGC)", { Position = UDim2.fromOffset(366, 0), Size = UDim2.fromOffset(250, 44) })
	local addBtn = UI.button(tools, "+ Add", "gold", { Position = UDim2.fromOffset(624, 1), Size = UDim2.fromOffset(92, 42) })
	local themes = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 54), Size = UDim2.new(1, -230, 0, 40), Parent = tools })
	UI.list(themes, Enum.FillDirection.Horizontal, 8, nil, Enum.VerticalAlignment.Center)
	local extendBtn = UI.button(tools, "+ Time", "light", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -112, 0, 54), Size = UDim2.fromOffset(100, 40), TextSize = 15 })
	local closeShop = UI.button(tools, "Close Shop", "danger", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 54), Size = UDim2.fromOffset(106, 40), TextSize = 14 })

	-- rent card
	local rentCard = UI.card(body, { Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 180) })
	local rentL = UI.label(rentCard, "", { Position = UDim2.fromOffset(20, 18), Size = UDim2.new(1, -40, 0, 90), TextColor3 = P.Text, TextSize = 19, Font = UI.Font.Medium })
	local rentBtn = UI.button(rentCard, "Rent this Stall", "gold", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.fromOffset(260, 50), TextSize = 20 })

	local list = UI.scroll(body, { Position = UDim2.fromOffset(0, 160), Size = UDim2.new(1, 0, 1, -160) })
	UI.grid(list, UDim2.fromOffset(186, 220), UDim2.fromOffset(10, 10))

	local function call(action, a)
		local ok, res = Remotes.Func("StallCall"):InvokeServer(action, currentId, a)
		if ok and typeof(res) == "table" then
			data = res
			Stall.Render()
		elseif not ok and res then
			Notify.Show(res, "warn")
		end
		return ok
	end

	function Stall.Render()
		if not data then
			return
		end
		title.Text = data.Vacant and "Vacant Stall" or data.Name
		ownerL.Text = data.Vacant and "Rent it and sell your own creations!" or ((data.IsCreator and "Creator: " or "Owner: ") .. (data.OwnerName or ""))
		local manage = data.CanManage and not data.Vacant
		tools.Visible = manage
		rentCard.Visible = data.Vacant
		extendBtn.Visible = manage and not data.IsCreator
		closeShop.Visible = manage and not data.IsCreator
		list.Position = UDim2.fromOffset(0, manage and 160 or (data.Vacant and 220 or 32))
		list.Size = UDim2.new(1, 0, 1, -(manage and 160 or (data.Vacant and 220 or 32)))
		rentL.Text = ("Rent for 🪙 %d coins — %d minutes.\nList up to %d of your own UGC items / clothes. Shoppers buy them with a real Roblox purchase (you earn from your items as the creator)."):format(data.RentCost, data.RentMinutes, data.MaxItems)
		if manage and nameBox.Text == "" then
			nameBox.Text = data.Name
		end
		for _, c in themes:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		for i, t in data.Themes or {} do
			local b = UI.new("TextButton", { Text = "", BackgroundColor3 = Color3.fromHex(t[2]), Size = UDim2.fromOffset(34, 34), LayoutOrder = i, Parent = themes })
			UI.round(b)
			UI.stroke(b, data.Theme == t[1] and P.Ivory or P.Plum, data.Theme == t[1] and 3 or 1.5, 0)
			b.Activated:Connect(function()
				call("Theme", t[1])
			end)
		end
		for _, c in list:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		for i, item in data.Items or {} do
			local card = UI.card(list, { LayoutOrder = i })
			UI.new("ImageLabel", { BackgroundTransparency = 1, Image = UI.assetThumb(item.Id), Position = UDim2.fromOffset(18, 6), Size = UDim2.fromOffset(150, 110), ScaleType = Enum.ScaleType.Fit, Parent = card })
			UI.label(card, item.Name, { Position = UDim2.fromOffset(8, 116), Size = UDim2.new(1, -16, 0, 20), TextColor3 = P.Text, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd })
			UI.label(card, UI.priceText(item.Price, item.ForSale), { Position = UDim2.fromOffset(8, 136), Size = UDim2.new(1, -16, 0, 20), TextColor3 = P.Violet, TextSize = 15, Font = UI.Font.Title })
			local try = UI.button(card, "Try", "secondary", { Position = UDim2.fromOffset(8, 164), Size = UDim2.fromOffset(78, 44), TextSize = 15 })
			local buy = UI.button(card, "Buy", "gold", { Position = UDim2.fromOffset(92, 164), Size = UDim2.fromOffset(86, 44), TextSize = 17 })
			try.Activated:Connect(function()
				Catalog.Call("Toggle", item.Id, true)
			end)
			buy.Activated:Connect(function()
				MarketplaceService:PromptPurchase(player, item.Id)
			end)
			if manage then
				local rm = UI.button(card, "✕", "danger", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(32, 32), TextSize = 14 })
				rm.Activated:Connect(function()
					call("RemoveItem", item.Id)
				end)
			end
		end
		if #(data.Items or {}) == 0 and not data.Vacant then
			UI.label(list, manage and "Add your first item above ⬆" or "This shop is still setting up ✨", { Size = UDim2.fromOffset(400, 40), TextColor3 = P.Lilac })
		end
	end

	renameBtn.Activated:Connect(function()
		call("Rename", nameBox.Text)
	end)
	addBtn.Activated:Connect(function()
		local id = UI.parseId(addBox.Text)
		if not id then
			Notify.Show("Paste your item's catalog link or ID.", "warn")
			return
		end
		if call("AddItem", id) then
			addBox.Text = ""
			Notify.Show("Item added to your stall! 🛍", "success")
		end
	end)
	rentBtn.Activated:Connect(function()
		call("Rent")
	end)
	extendBtn.Activated:Connect(function()
		call("Extend")
	end)
	closeShop.Activated:Connect(function()
		call("Leave")
		UI.close("Stall")
	end)
	RunService.Heartbeat:Connect(function()
		if holder.Visible and data and not data.Vacant and not data.IsCreator then
			timeL.Text = "⏱ " .. UI.fmtTime((data.ExpiresAt or 0) - workspace:GetServerTimeNow()) .. " left"
		elseif holder.Visible then
			timeL.Text = ""
		end
	end)

	UI.registerModal("Stall", holder, function(stallId)
		currentId = stallId
		nameBox.Text = ""
		data = nil
		call("Get")
	end)
	Remotes.Event("Stall").OnClientEvent:Connect(function(kind, stallId)
		if kind == "Open" then
			UI.open("Stall", stallId)
		end
	end)
end

return Stall
