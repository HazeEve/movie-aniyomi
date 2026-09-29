--!nonstrict
-- Aura Music Kit — server start. Put the "AuraMusicServer" folder in ServerScriptService.
local Services = script.Parent
local DataService = require(Services.DataService)
local MusicService = require(Services.MusicService)
DataService.Init()
MusicService.Init({ DataService = DataService })
