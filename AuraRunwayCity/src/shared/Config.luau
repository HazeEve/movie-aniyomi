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
	IntermissionTime = 25,
	DressingTime = 150,
	RunwayTimePerModel = 16,
	ResultsTime = 14,
	ParticipationCoins = 15,
	PlaceCoins = { 120, 70, 40 },
	Themes = {
		"Old Money Elegance", "Y2K Pop Princess", "Red Carpet Gala", "Dark Academia",
		"Cottagecore Picnic", "Galaxy Diva", "Streetwear Icon", "Witchy Glam",
		"Beach Resort Luxe", "Pastel Dream", "Rockstar", "Royal Ball",
		"Office Siren", "Kawaii Café", "Winter Wonderland", "Met Gala: Flowers",
		"Monochrome Black", "All White Party", "Fairy Core", "Vintage Hollywood",
		"Sporty Chic", "Masquerade", "Futuristic Cyber", "Candy Land",
	},
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
Config.SoundPackId = ""

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
