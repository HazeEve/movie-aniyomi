--!nonstrict
-- Builds the whole Aura Runway City world under `parent` (usually Workspace).
-- Runs automatically on server start if the world is missing, and is also
-- used by tools/bake.luau to pre-place everything in the .rbxl file.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local World = {}
World.RootName = "AuraWorld"

function World.Build(parent: Instance, yieldFn)
	local B = require(script.Build)
	local P = require(ReplicatedStorage.Shared.Palette)
	local L = require(script.Layout)
	local Screens = require(script.Screens)
	local Rooms = require(script.Rooms)
	local Stage = require(script.Stage)
	local City = require(script.City)
	local Mall = require(script.Mall)
	local Places = require(script.Places)
	local CarModel = require(script.CarModel)

	if yieldFn then
		B.setYield(yieldFn)
	end
	local root = Instance.new("Folder")
	root.Name = World.RootName
	B.folder(root, "Travel")
	City.build(B, P, L, Screens, root)
	Stage.build(B, P, Screens, root)
	Mall.build(B, P, L, Screens, Rooms, root)
	Places.build(B, P, L, Screens, Rooms, CarModel, root)
	root:SetAttribute("PartCount", B.count())
	root.Parent = parent
	return root
end

return World
