--!nonstrict
-- Auction panel: watch the live auction, bid with coins, or (if you're
-- modelling on stage) put one of your limiteds up for auction.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local UI = require(script.Parent.Parent.UI)
local State = require(script.Parent.Parent.State)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Config = require(ReplicatedStorage.Shared.Config)
local P = UI.P

local Auction = {}
local player = Players.LocalPlayer

function Auction.Init(controllers)
	local Notify = controllers.Notify
	local gui = UI.screen("AuraAuction", 13)
	local holder, body = UI.window(gui, "Auction", "🔨 Live Auction", Vector2.new(760, 520))
	local state = ReplicatedStorage:WaitForChild("AuctionState")

	-- live section
	local live = UI.card(body, { Size = UDim2.new(1, 0, 0, 230) })
	local img = UI.new("ImageLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(206, 206), ScaleType = Enum.ScaleType.Fit, Parent = live })
	local itemL = UI.label(live, "", { Position = UDim2.fromOffset(234, 14), Size = UDim2.new(1, -250, 0, 30), TextColor3 = P.Text, TextSize = 24, Font = UI.Font.Title, TextTruncate = Enum.TextTruncate.AtEnd })
	local sellerL = UI.label(live, "", { Position = UDim2.fromOffset(234, 46), Size = UDim2.new(1, -250, 0, 20), TextColor3 = P.TextSoft, TextSize = 15, Font = UI.Font.Medium })
	local bidL = UI.label(live, "", { Position = UDim2.fromOffset(234, 74), Size = UDim2.new(1, -250, 0, 30), TextColor3 = P.Violet, TextSize = 24, Font = UI.Font.Title })
	local timeL = UI.label(live, "", { Position = UDim2.fromOffset(234, 106), Size = UDim2.new(1, -250, 0, 22), TextColor3 = P.Rose, TextSize = 18 })
	local bidBox = UI.textbox(live, "Your bid (✨ Sparkles)", { Position = UDim2.fromOffset(234, 140), Size = UDim2.fromOffset(200, 48) })
	local minBtn = UI.button(live, "Min", "light", { Position = UDim2.fromOffset(442, 142), Size = UDim2.fromOffset(70, 44) })
	local bidBtn = UI.button(live, "Place Bid", "gold", { Position = UDim2.fromOffset(520, 142), Size = UDim2.fromOffset(170, 44), TextSize = 19 })
	local cancelBtn = UI.button(live, "Cancel", "danger", { Position = UDim2.fromOffset(520, 192), Size = UDim2.fromOffset(170, 30), TextSize = 14, Visible = false })
	local note = UI.label(live, "Bids use ✨ Sparkles (held until you're outbid; buy more in the 🛒 Store). The seller sends the limited to the winner with Roblox Trade 🤝", { Position = UDim2.fromOffset(234, 192), Size = UDim2.fromOffset(280, 34), TextColor3 = P.TextSoft, TextSize = 11, Font = UI.Font.Medium })
	note.TextWrapped = true
	local idle = UI.label(live, "No auction right now.\nModels on stage can start one below ✨", { Position = UDim2.fromOffset(234, 40), Size = UDim2.new(1, -250, 0, 80), TextColor3 = P.TextSoft, TextSize = 18 })

	-- start section
	local start = UI.panel(body, { Position = UDim2.fromOffset(0, 244), Size = UDim2.new(1, 0, 0, 180), BackgroundTransparency = 0.3 })
	UI.pad(start, 14)
	UI.label(start, "Auction your limited (you must be on stage / in the show)", { Size = UDim2.new(1, 0, 0, 22), TextColor3 = P.Champagne, TextSize = 16 })
	local idBox = UI.textbox(start, "Limited item link or ID", { Position = UDim2.fromOffset(0, 34), Size = UDim2.fromOffset(330, 46) })
	local startBox = UI.textbox(start, "Starting bid", { Position = UDim2.fromOffset(340, 34), Size = UDim2.fromOffset(150, 46), Text = tostring(Config.Auction.MinStartBid * 10) })
	local startBtn = UI.button(start, "Start Auction", "primary", { Position = UDim2.fromOffset(500, 35), Size = UDim2.fromOffset(190, 44) })
	local preview = UI.new("ImageLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 88), Size = UDim2.fromOffset(60, 60), Parent = start })
	UI.label(start, ("Lasts %ds • +%d min raise • last-second bids add time"):format(Config.Auction.Duration, Config.Auction.MinIncrement), { Position = UDim2.fromOffset(70, 100), Size = UDim2.new(1, -70, 0, 34), TextColor3 = P.Lilac, TextSize = 14, Font = UI.Font.Medium })
	idBox:GetPropertyChangedSignal("Text"):Connect(function()
		local id = UI.parseId(idBox.Text)
		preview.Image = id and UI.assetThumb(id) or ""
	end)

	local function refresh()
		local active = state:GetAttribute("Active") == true
		img.Visible = active
		itemL.Visible, sellerL.Visible, bidL.Visible, timeL.Visible = active, active, active, active
		bidBox.Visible, minBtn.Visible, bidBtn.Visible, note.Visible = active, active, active, active
		idle.Visible = not active
		if active then
			local assetId = state:GetAttribute("AssetId") or 0
			img.Image = UI.assetThumb(assetId, 420)
			itemL.Text = state:GetAttribute("ItemName") or ""
			sellerL.Text = "Seller: " .. (state:GetAttribute("SellerName") or "")
			local top = state:GetAttribute("TopBid") or 0
			local topName = state:GetAttribute("TopBidderName") or ""
			bidL.Text = (topName ~= "" and ("✨ %d  —  %s"):format(top, topName)) or ("Starts at ✨ %d"):format(state:GetAttribute("MinNext") or 0)
			local mine = state:GetAttribute("SellerId") == player.UserId
			bidBox.Visible, minBtn.Visible, bidBtn.Visible = not mine, not mine, not mine
			cancelBtn.Visible = mine and topName == ""
		else
			cancelBtn.Visible = false
		end
	end
	for _, a in { "Active", "TopBid", "TopBidderName", "ItemName", "MinNext" } do
		state:GetAttributeChangedSignal(a):Connect(refresh)
	end
	refresh()
	RunService.Heartbeat:Connect(function()
		if holder.Visible and state:GetAttribute("Active") then
			timeL.Text = "⏰ " .. UI.fmtTime((state:GetAttribute("EndsAt") or 0) - workspace:GetServerTimeNow()) .. " left"
		end
	end)

	minBtn.Activated:Connect(function()
		bidBox.Text = tostring(state:GetAttribute("MinNext") or 0)
	end)
	bidBtn.Activated:Connect(function()
		local amount = tonumber(bidBox.Text)
		if not amount then
			Notify.Show("Enter a bid amount.", "warn")
			return
		end
		local ok, msg = Remotes.Func("AuctionCall"):InvokeServer("Bid", amount)
		Notify.Show(ok and "Bid placed! 🔨" or (msg or "Bid failed."), ok and "success" or "warn")
	end)
	startBtn.Activated:Connect(function()
		local id = UI.parseId(idBox.Text)
		if not id then
			Notify.Show("Paste your limited's link or ID.", "warn")
			return
		end
		local ok, msg = Remotes.Func("AuctionCall"):InvokeServer("Start", id, tonumber(startBox.Text) or 0)
		if not ok then
			Notify.Show(msg or "Couldn't start the auction.", "warn")
		end
	end)
	cancelBtn.Activated:Connect(function()
		local ok, msg = Remotes.Func("AuctionCall"):InvokeServer("Cancel")
		if not ok and msg then
			Notify.Show(msg, "warn")
		end
	end)

	Remotes.Event("Auction").OnClientEvent:Connect(function(kind, a, b)
		if kind == "Started" and not UI.isOpen("Auction") then
			Notify.Show("🔨 A live auction just started! Tap Auction to bid.", "info")
		elseif kind == "Sold" and typeof(a) == "table" then
			if a.WinnerId == player.UserId then
				Notify.Show(("You won %s! Send %s a Roblox trade request to receive it 🤝"):format(a.Item, a.Seller), "success")
			elseif a.SellerId == player.UserId then
				Notify.Show(("%s won your %s for %d ✨ Sparkles. Please send it via Roblox Trade 🤝"):format(a.Winner, a.Item, a.Price), "success")
			end
		end
	end)
	UI.registerModal("Auction", holder, refresh)
end

return Auction
