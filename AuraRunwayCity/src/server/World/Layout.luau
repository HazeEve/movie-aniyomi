--!nonstrict
-- City grid. Roads run along these lines (both X and Z). Cells sit between them.
local L = {}

L.RoadTop = 0.55
L.Walk = 0.6 -- sidewalk / plaza walking height
L.Floor = 0.62 -- interior floors
L.RoadWidth = 24
L.SidewalkWidth = 8
L.Lines = { -392, -252, -112, 112, 252, 392 }
L.Extent = 404

-- cells: centre + buildable size (between sidewalks)
L.Cells = {
	{ c = -322, s = 100 },
	{ c = -182, s = 100 },
	{ c = 0, s = 184 },
	{ c = 182, s = 100 },
	{ c = 322, s = 100 },
}

-- special districts (x, z cell centres)
L.Districts = {
	["0,0"] = "Plaza",
	["0,-182"] = "Mall",
	["-182,-182"] = "Cafe",
	["182,-182"] = "Hotel",
	["-182,0"] = "Boutiques",
	["182,0"] = "Salon",
	["0,182"] = "Park",
	["-182,182"] = "Dealer",
	["182,182"] = "Residences",
}

function L.key(x: number, z: number): string
	return tostring(x) .. "," .. tostring(z)
end

return L
