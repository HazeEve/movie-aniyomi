--!nonstrict
-- Dress-To-Impress style show loop with HEART voting (1-5 hearts).
-- Intermission -> Dressing (theme) -> Runway (each model walks, everyone votes) -> Results (podium)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Util = require(script.Parent.Util)

local ShowService = {}
local DataService

local state = Instance.new("Configuration")
state.Name = "ShowState"
state:SetAttribute("Phase", "Intermission")
state:SetAttribute("Theme", "")
state:SetAttribute("EndsAt", 0)
state:SetAttribute("ModelId", 0)
state:SetAttribute("ModelIndex", 0)
state:SetAttribute("ModelCount", 0)
state:SetAttribute("Round", 0)
state.Parent = ReplicatedStorage
ShowService.State = state

local joinOrder = {} :: { Player }
local votes = {} :: { [number]: { [number]: number } }
local lastThemes = {}
local passCache = {} :: { [number]: boolean }
local MarketplaceService = game:GetService("MarketplaceService")

-- ---------- Extra Time (repurchasable product: one credit = one round) ----------
local function hasExtraTime(player: Player): boolean
	return passCache[player.UserId] == true
end

-- stretch the dressing timer by +2 min if any model owns the pass
local function applyExtraTime()
	if state:GetAttribute("Phase") ~= "Dressing" then
		return
	end
	for _, p in joinOrder do
		if p.Parent and p:GetAttribute("InShow") and hasExtraTime(p) then
			local target = (state:GetAttribute("DressStart") or Util.Now()) + Config.Show.ExtraDressingTime
			if not state:GetAttribute("ExtraTime") then
				passCache[p.UserId] = nil -- credit used for this round
			end
			if target > (state:GetAttribute("EndsAt") or 0) then
				state:SetAttribute("EndsAt", target)
				state:SetAttribute("ExtraTime", true)
				Util.Notify(nil, ("⏰ %s has Extra Time: everyone gets +2 minutes to dress!"):format(p.DisplayName), "success")
			end
			return
		end
	end
end

-- ---------- theme on the stage LED screens ----------
local function showThemeOnStage(theme: string?)
	local stage = Util.World and Util.World:FindFirstChild("Stage")
	local led = stage and stage:FindFirstChild("LED")
	if not led then
		return
	end
	for _, d in led:GetDescendants() do
		if d:IsA("TextLabel") and d.Name == "Subtitle" then
			if d:GetAttribute("Default") == nil then
				d:SetAttribute("Default", d.Text)
			end
			d.Text = (theme and theme ~= "") and ("THEME: " .. string.upper(theme)) or d:GetAttribute("Default")
		end
	end
end

local function setPhase(phase: string, duration: number)
	state:SetAttribute("Phase", phase)
	state:SetAttribute("EndsAt", Util.Now() + duration)
end

local function contestants(): { Player }
	local list = {}
	for _, p in joinOrder do
		if p.Parent and p:GetAttribute("InShow") then
			table.insert(list, p)
		end
	end
	return list
end

function ShowService.IsContestant(player: Player): boolean
	return player:GetAttribute("InShow") == true
end

function ShowService.CurrentModel(): number
	return state:GetAttribute("ModelId") or 0
end

local function join(player: Player)
	local phase = state:GetAttribute("Phase")
	if phase ~= "Intermission" and phase ~= "Dressing" then
		Util.Notify(player, "The show already started — join the next round!", "warn")
		return
	end
	if player:GetAttribute("InShow") then
		return
	end
	if #contestants() >= Config.Show.MaxModels then
		Util.Notify(player, "The runway is full this round.", "warn")
		return
	end
	player:SetAttribute("InShow", true)
	table.insert(joinOrder, player)
	Util.Notify(player, "You're in the show! Dress up for the theme ✨", "success")
	applyExtraTime()
end

local function leave(player: Player)
	player:SetAttribute("InShow", nil)
	local i = table.find(joinOrder, player)
	if i then
		table.remove(joinOrder, i)
	end
end

local function pickTheme(): string
	local themes = Config.Show.Themes
	for _ = 1, 10 do
		local t = themes[math.random(1, #themes)]
		if not table.find(lastThemes, t) then
			table.insert(lastThemes, t)
			if #lastThemes > 6 then
				table.remove(lastThemes, 1)
			end
			return t
		end
	end
	return themes[math.random(1, #themes)]
end

local function waitUntilEnd()
	while Util.Now() < (state:GetAttribute("EndsAt") or 0) do
		task.wait(0.25)
	end
end

local function lounge(player: Player, i: number)
	local m = Util.Marker("Lounge" .. (((i - 1) % 8) + 1))
	if m then
		Util.Teleport(player, m.CFrame)
	end
end

local function returnToPlaza(player: Player, i: number)
	local m = Util.Marker("PlazaReturn" .. (((i - 1) % 6) + 1))
	if m then
		Util.Teleport(player, m.CFrame)
	end
end

local function runRound()
	-- ============ Intermission ============
	state:SetAttribute("ModelId", 0)
	setPhase("Intermission", Config.Show.IntermissionTime)
	waitUntilEnd()
	if #contestants() < Config.Show.MinModels then
		return
	end
	-- ============ Dressing ============
	local theme = state:GetAttribute("NextTheme")
	if not theme or theme == "" then
		theme = pickTheme()
	end
	state:SetAttribute("NextTheme", "")
	state:SetAttribute("Theme", theme)
	state:SetAttribute("ExtraTime", false)
	state:SetAttribute("Round", (state:GetAttribute("Round") or 0) + 1)
	state:SetAttribute("DressStart", Util.Now())
	setPhase("Dressing", Config.Show.DressingTime)
	Remotes.Event("Show"):FireAllClients("Theme", theme)
	showThemeOnStage(theme)
	applyExtraTime()
	waitUntilEnd()
	local models = contestants()
	if #models < Config.Show.MinModels then
		Util.Notify(nil, "Not enough models this round — the show was cancelled.", "warn")
		return
	end
	-- ============ Runway ============
	votes = {}
	state:SetAttribute("ModelCount", #models)
	setPhase("Runway", #models * Config.Show.RunwayTimePerModel)
	for i, p in models do
		lounge(p, i)
	end
	task.wait(1.5)
	for i, p in models do
		if p.Parent and p:GetAttribute("InShow") then
			votes[p.UserId] = {}
			state:SetAttribute("ModelIndex", i)
			state:SetAttribute("ModelId", p.UserId)
			state:SetAttribute("ModelName", p.DisplayName)
			state:SetAttribute("EndsAt", Util.Now() + Config.Show.RunwayTimePerModel)
			local start = Util.Marker("RunwayStart")
			if start then
				Util.Teleport(p, start.CFrame)
			end
			local hum = Util.Humanoid(p)
			if hum then
				hum.WalkSpeed = 13
			end
			Remotes.Event("Show"):FireAllClients("Model", p.UserId, p.DisplayName, i, #models)
			waitUntilEnd()
			if hum and hum.Parent then
				hum.WalkSpeed = game:GetService("StarterPlayer").CharacterWalkSpeed
			end
			if p.Parent then
				lounge(p, i)
			end
		end
	end
	state:SetAttribute("ModelId", 0)

	-- ============ Results ============
	local results = {}
	for _, p in models do
		local v = votes[p.UserId]
		if v and p.Parent then
			local sum, n = 0, 0
			for _, h in v do
				sum += h
				n += 1
			end
			table.insert(results, {
				UserId = p.UserId,
				Name = p.Name,
				DisplayName = p.DisplayName,
				Score = n > 0 and sum / n or 0,
				Votes = n,
				Total = sum,
				Player = p,
			})
		end
	end
	table.sort(results, function(a, b)
		if a.Score ~= b.Score then
			return a.Score > b.Score
		end
		return a.Votes > b.Votes
	end)
	for place, r in results do
		local coins = Config.Show.ParticipationCoins + (Config.Show.PlaceCoins[place] or 0)
		r.Coins = coins
		local profile = DataService.Get(r.Player)
		if profile then
			profile.Shows += 1
			if place == 1 and r.Votes > 0 then
				profile.Wins += 1
			end
			DataService.AddHearts(r.Player, r.Total)
			DataService.AddCoins(r.Player, coins)
		end
		if place <= 3 then
			local m = Util.Marker("Podium" .. place)
			if m then
				Util.Teleport(r.Player, m.CFrame * CFrame.Angles(0, 0, 0))
			end
		end
	end
	local payload = {}
	for i, r in results do
		payload[i] = { UserId = r.UserId, DisplayName = r.DisplayName, Score = r.Score, Votes = r.Votes, Coins = r.Coins }
	end
	setPhase("Results", Config.Show.ResultsTime)
	Remotes.Event("Show"):FireAllClients("Results", payload, state:GetAttribute("Theme"))
	waitUntilEnd()
	for i, p in models do
		if p.Parent then
			returnToPlaza(p, i)
			leave(p)
		end
	end
	state:SetAttribute("Theme", "")
	showThemeOnStage(nil)
end

-- Change Theme developer product (can be bought again and again)
function ShowService.ChangeTheme(buyer: Player)
	local newTheme = pickTheme()
	if state:GetAttribute("Phase") == "Dressing" then
		state:SetAttribute("Theme", newTheme)
		Remotes.Event("Show"):FireAllClients("Theme", newTheme)
		showThemeOnStage(newTheme)
		Util.Notify(nil, ('🔄 %s changed the theme to "%s"!'):format(buyer.DisplayName, newTheme), "success")
	else
		state:SetAttribute("NextTheme", newTheme)
		Util.Notify(nil, ('🔄 %s picked the next theme: "%s"'):format(buyer.DisplayName, newTheme), "success")
	end
end

function ShowService.Init(deps)
	DataService = deps.DataService
	Remotes.Event("Show").OnServerEvent:Connect(function(player, action, a)
		if action == "Join" then
			join(player)
		elseif action == "Leave" then
			local phase = state:GetAttribute("Phase")
			if phase == "Runway" or phase == "Results" then
				Util.Notify(player, "You can't leave mid-show, stay fabulous!", "warn")
				return
			end
			leave(player)
			Util.Notify(player, "You left the show.", "info")
		elseif action == "Vote" then
			if state:GetAttribute("Phase") ~= "Runway" then
				return
			end
			local modelId = state:GetAttribute("ModelId")
			local hearts = tonumber(a)
			if not modelId or modelId == 0 or modelId == player.UserId or not hearts then
				return
			end
			hearts = math.clamp(math.floor(hearts), 1, 5)
			local v = votes[modelId]
			if v then
				v[player.UserId] = hearts
				player:SetAttribute("LastVote", hearts)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		leave(p)
		passCache[p.UserId] = nil
	end)
	MarketplaceService.ProcessReceipt = function(info)
		local buyer = Players:GetPlayerByUserId(info.PlayerId)
		if not buyer then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if info.ProductId == Config.Products.ExtraTime then
			passCache[buyer.UserId] = true
			Util.Notify(buyer, "⏰ Extra Time ready! Your next dressing round gets +2 minutes.", "success")
			applyExtraTime()
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		if info.ProductId == Config.Products.ChangeTheme then
			local ok = pcall(ShowService.ChangeTheme, buyer)
			return ok and Enum.ProductPurchaseDecision.PurchaseGranted or Enum.ProductPurchaseDecision.NotProcessedYet
		end
		for _, b in Config.SparkleBundles do
			if b.ProductId ~= 0 and info.ProductId == b.ProductId then
				local ok = pcall(DataService.AddCoins, buyer, b.Amount)
				if ok then
					Util.Notify(buyer, ("+%d ✨ Sparkles! Thank you 💖"):format(b.Amount), "success")
					return Enum.ProductPurchaseDecision.PurchaseGranted
				end
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	task.spawn(function()
		while true do
			local ok, err = pcall(runRound)
			if not ok then
				warn("[Show] round error:", err)
				task.wait(3)
			end
		end
	end)
end

return ShowService
