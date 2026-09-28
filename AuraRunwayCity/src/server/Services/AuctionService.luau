--!nonstrict
-- Live auction of a limited item worn/owned by the model on stage.
-- Bids are in-game coins held in escrow. Roblox does not allow games to move
-- limited items between accounts, so the result is announced + logged and the
-- two players finish the swap with Roblox's official Trade system.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Util = require(script.Parent.Util)

local AuctionService = {}
local DataService, AvatarService, ShowService

local state = Instance.new("Configuration")
state.Name = "AuctionState"
state:SetAttribute("Active", false)
state.Parent = ReplicatedStorage

local current = nil -- { Seller, AssetId, Name, TopBid, TopBidder, EndsAt, StartBid }
local logStore
pcall(function()
	logStore = DataStoreService:GetOrderedDataStore(Config.DataStoreName .. "_AuctionLog")
end)
local logDetail
pcall(function()
	logDetail = DataStoreService:GetDataStore(Config.DataStoreName .. "_AuctionLog")
end)

local function screen()
	local w = Util.World
	local s = w and w:FindFirstChild("Stage")
	local a = s and s:FindFirstChild("Auction")
	local part = a and a:FindFirstChild("AuctionScreen")
	local gui = part and part:FindFirstChildOfClass("SurfaceGui")
	return gui and gui:FindFirstChild("Bg")
end

local function publish()
	local bg = screen()
	if current then
		state:SetAttribute("Active", true)
		state:SetAttribute("SellerId", current.Seller.UserId)
		state:SetAttribute("SellerName", current.Seller.DisplayName)
		state:SetAttribute("AssetId", current.AssetId)
		state:SetAttribute("ItemName", current.Name)
		state:SetAttribute("TopBid", current.TopBid)
		state:SetAttribute("TopBidderId", current.TopBidder and current.TopBidder.UserId or 0)
		state:SetAttribute("TopBidderName", current.TopBidder and current.TopBidder.DisplayName or "")
		state:SetAttribute("EndsAt", current.EndsAt)
		state:SetAttribute("MinNext", AuctionService.MinNext())
		if bg then
			bg.Item.Image = ("rbxthumb://type=Asset&id=%d&w=420&h=420"):format(current.AssetId)
			bg.Title.Text = current.Name
			bg.Bid.Text = current.TopBidder and ("Top bid: %d coins\nby %s"):format(current.TopBid, current.TopBidder.DisplayName)
				or ("Starting bid: %d coins"):format(current.StartBid)
		end
	else
		state:SetAttribute("Active", false)
		state:SetAttribute("TopBidderId", 0)
		if bg then
			bg.Item.Image = ""
			bg.Title.Text = "No auction running"
			bg.Bid.Text = "Models on stage can auction a limited!"
			bg.Timer.Text = ""
		end
	end
end

function AuctionService.MinNext(): number
	if not current then
		return 0
	end
	if current.TopBidder then
		return current.TopBid + Config.Auction.MinIncrement
	end
	return current.StartBid
end

local function refund(player: Player?, amount: number)
	if player and player.Parent and amount > 0 then
		DataService.AddCoins(player, amount)
	end
end

local function finish(cancelled: boolean?)
	local a = current
	if not a then
		return
	end
	current = nil
	if cancelled then
		refund(a.TopBidder, a.TopBid)
		Util.Notify(nil, ("Auction for %s was cancelled."):format(a.Name), "warn")
	elseif a.TopBidder then
		if a.Seller.Parent then
			DataService.AddCoins(a.Seller, a.TopBid)
		end
		local msg = ("SOLD! %s won %s for %d coins. %s, please send it with Roblox Trade 🤝"):format(
			a.TopBidder.DisplayName,
			a.Name,
			a.TopBid,
			a.Seller.DisplayName
		)
		Util.Notify(nil, msg, "success")
		Remotes.Event("Auction"):FireAllClients("Sold", {
			Item = a.Name,
			AssetId = a.AssetId,
			Winner = a.TopBidder.DisplayName,
			WinnerId = a.TopBidder.UserId,
			Seller = a.Seller.DisplayName,
			SellerId = a.Seller.UserId,
			Price = a.TopBid,
		})
		task.spawn(function()
			local id = HttpService:GenerateGUID(false)
			pcall(function()
				if logDetail then
					logDetail:SetAsync("sale_" .. id, {
						Time = os.time(),
						AssetId = a.AssetId,
						Item = a.Name,
						SellerId = a.Seller.UserId,
						WinnerId = a.TopBidder.UserId,
						Price = a.TopBid,
					})
				end
				if logStore then
					logStore:SetAsync("sale_" .. id, os.time())
				end
			end)
		end)
	else
		Util.Notify(nil, ("No bids on %s — auction closed."):format(a.Name), "info")
	end
	publish()
end

local function isLimited(info): boolean
	if not info then
		return false
	end
	if info.IsLimited or info.IsLimitedUnique then
		return true
	end
	local cd = info.CollectiblesItemDetails
	return typeof(cd) == "table" and cd.IsLimited == true
end

local function start(player: Player, assetId, startBid)
	if current then
		return false, "An auction is already running."
	end
	if not (Util.OnStage(player) or ShowService.IsContestant(player)) then
		return false, "Only models on stage (or in the show) can start an auction."
	end
	assetId = tonumber(assetId)
	startBid = math.floor(tonumber(startBid) or 0)
	if not assetId then
		return false, "Enter the item's ID or link."
	end
	if startBid < Config.Auction.MinStartBid or startBid > Config.Auction.MaxStartBid then
		return false, ("Starting bid must be %d-%d coins."):format(Config.Auction.MinStartBid, Config.Auction.MaxStartBid)
	end
	local info = AvatarService.GetInfo(assetId)
	if not isLimited(info) then
		return false, "That item isn't a limited."
	end
	local ok, owns = pcall(function()
		return MarketplaceService:PlayerOwnsAsset(player, assetId)
	end)
	if not ok or not owns then
		return false, "You don't own that limited."
	end
	current = {
		Seller = player,
		AssetId = assetId,
		Name = info.Name or "Limited",
		StartBid = startBid,
		TopBid = 0,
		TopBidder = nil,
		EndsAt = Util.Now() + Config.Auction.Duration,
	}
	publish()
	Util.Notify(nil, ("🔨 %s is auctioning %s! Open the Auction to bid."):format(player.DisplayName, current.Name), "success")
	Remotes.Event("Auction"):FireAllClients("Started")
	return true
end

local function bid(player: Player, amount)
	local a = current
	if not a then
		return false, "No auction running."
	end
	if player == a.Seller then
		return false, "You can't bid on your own item."
	end
	amount = math.floor(tonumber(amount) or 0)
	if amount < AuctionService.MinNext() then
		return false, ("Bid at least %d coins."):format(AuctionService.MinNext())
	end
	local prevBidder, prevBid = a.TopBidder, a.TopBid
	-- raising your own bid only charges the difference
	local charge = amount
	if prevBidder == player then
		charge = amount - prevBid
	end
	if not DataService.Spend(player, charge) then
		return false, "Not enough coins."
	end
	if prevBidder and prevBidder ~= player then
		refund(prevBidder, prevBid)
		Util.Notify(prevBidder, "You were outbid! Your coins were refunded.", "warn")
	end
	a.TopBid = amount
	a.TopBidder = player
	if a.EndsAt - Util.Now() < Config.Auction.AntiSnipeSeconds then
		a.EndsAt = Util.Now() + Config.Auction.AntiSnipeSeconds
	end
	publish()
	Remotes.Event("Auction"):FireAllClients("Bid", player.DisplayName, amount)
	return true
end

function AuctionService.Init(deps)
	DataService = deps.DataService
	AvatarService = deps.AvatarService
	ShowService = deps.ShowService
	publish()
	Remotes.Func("AuctionCall").OnServerInvoke = function(player, action, a, b)
		if action == "Start" then
			return start(player, a, b)
		elseif action == "Bid" then
			return bid(player, a)
		elseif action == "Cancel" then
			if current and current.Seller == player and not current.TopBidder then
				finish(true)
				return true
			end
			return false, "You can only cancel your own auction before anyone bids."
		end
		return false
	end
	Players.PlayerRemoving:Connect(function(p)
		if current and current.Seller == p then
			finish(true)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			if current then
				local left = math.max(0, math.ceil(current.EndsAt - Util.Now()))
				local bg = screen()
				if bg then
					bg.Timer.Text = ("⏱ %ds left"):format(left)
				end
				if left <= 0 then
					finish(false)
				end
			end
		end
	end)
end

return AuctionService
