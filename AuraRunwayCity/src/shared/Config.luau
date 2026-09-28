--!nonstrict
-- ============================================================
--  AURA RUNWAY CITY — main settings. Edit freely.
-- ============================================================
local Config = {}

Config.GameName = "Aura Runway"
Config.Tagline = "Dress • Walk • Win"

-- Your Roblox UserId (owner of the big Creator Stall). 0 = the place owner (game.CreatorId).
Config.CreatorUserId = 0

-- DataStore name. Change the suffix to wipe everyone's saves.
Config.DataStoreName = "AuraRunway_v1"

-- ============ ECONOMY (in-game coins, not Robux) ============
Config.StartCoins = 250
Config.PlaytimeRewardCoins = 10
Config.PlaytimeRewardEvery = 120 -- seconds

-- ============ RUNWAY SHOW (Dress To Impress style) ============
Config.Show = {
	MinModels = 1, -- set to 2+ for live servers
	MaxModels = 12,
	IntermissionTime = 30,
	DressingTime = 8 * 60, -- 8 minutes to get ready
	ExtraDressingTime = 10 * 60, -- with the Extra Time gamepass
	RunwayTimePerModel = 20,
	ResultsTime = 15,
	ParticipationCoins = 15,
	PlaceCoins = { 120, 70, 40 },
	Themes = require(script.Parent.Themes), -- 1000 themes
}

-- ============ MONETIZATION ============
-- Create these on create.roblox.com (your experience > Monetization) and paste the ids.
Config.Products = {
	-- Developer Product (can be bought again and again): re-rolls the runway theme
	ChangeTheme = 0,
}
Config.GamePasses = {
	-- Game Pass: dressing time becomes 10 minutes in rounds you join
	ExtraTime = 0,
}
-- ✨ SPARKLES = the game currency (bids, stall rent, rewards).
-- Make one Developer Product per bundle and paste its id.
Config.CurrencyName = "Sparkles"
Config.CurrencyIcon = "✨"
Config.SparkleBundles = {
	{ Name = "Pinch of Sparkles", Amount = 500, Robux = 25, ProductId = 0 },
	{ Name = "Sparkle Pouch", Amount = 1200, Robux = 50, ProductId = 0 },
	{ Name = "Sparkle Jar", Amount = 3000, Robux = 110, ProductId = 0 },
	{ Name = "Sparkle Chest", Amount = 8000, Robux = 250, ProductId = 0 },
	{ Name = "Galaxy Vault", Amount = 25000, Robux = 700, ProductId = 0 },
}
-- Game passes listed in the Store (Extra Time is automatic).
Config.StorePasses = {
	{ Name = "⏰ 10 Min Dress Time", Key = "ExtraTime", Desc = "Dress for 10 minutes instead of 8." },
}

-- ============ AUCTION (limiteds shown on stage) ============
-- NOTE: Roblox does not let games move limited items between accounts.
-- Bids use in-game coins (escrowed); the winner and seller finish the
-- swap with Roblox's official Trade feature. The result is logged.
Config.Auction = {
	Duration = 60,
	MinIncrement = 10,
	AntiSnipeSeconds = 10,
	MinStartBid = 10,
	MaxStartBid = 1000000,
}

-- ============ STALLS (mall shops for UGC) ============
Config.Stalls = {
	RentCost = 150,
	RentMinutes = 45,
	MaxItems = 8,
	CreatorMaxItems = 16,
	-- true  = players may only list items THEY (or a group they are in) created.
	-- false = any on-sale catalog item may be listed.
	RequireCreator = true,
}

-- Items shown in YOUR big creator stall until you edit it in-game (asset ids).
Config.CreatorStallItems = {}
Config.CreatorStallName = "Creator's Atelier"

-- ============ MUSIC ============
-- Upload build/AuraSoundPack.ogg to Roblox ONCE (Creator Hub > Audio) and paste
-- its id here, e.g. "rbxassetid://1234567890". It contains every instrument.
Config.SoundPackId = "rbxassetid://102166305460032"

Config.Music = {
	MinChords = 3,
	MaxChords = 19,
	HearDistance = 110,
	StageHearDistance = 320,
	MaxEventsPerSecond = 40,
}

-- ============ ROLEPLAY ============
Config.RP = {
	HungerDrainEvery = 25, -- seconds per -1
	EnergyDrainEvery = 35,
	SleepEnergyPerSecond = 4,
	CarMaxSpeed = 70,
	CarReverseSpeed = 25,
	CarTurnRate = 1.6,
	MaxCarsPerPlayer = 1,
}

-- ============ WORLD ============
Config.DayNightCycle = true
Config.MinutesPerDay = 24
Config.StartClockTime = 16.8

return Config
