--!nonstrict
-- Warm window glow across the city after sunset.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local NightLights = {}
local WARM = { Color3.fromHex("FFE2B8"), Color3.fromHex("FFD6E4"), Color3.fromHex("E8DCFF"), Color3.fromHex("FFF1D6") }

local function isNight(): boolean
	local t = Lighting.ClockTime
	return t >= 18.2 or t < 6.1
end

local function apply(part: BasePart, night: boolean)
	if night then
		if part:GetAttribute("DayColor") == nil then
			part:SetAttribute("DayColor", part.Color)
		end
		part.Material = Enum.Material.Neon
		part.Color = WARM[(math.floor(part.Position.X + part.Position.Z) % #WARM) + 1]
		part.Transparency = 0.2
	else
		local day = part:GetAttribute("DayColor")
		if day then
			part.Color = day
		end
		part.Material = Enum.Material.Glass
		part.Transparency = 0
	end
end

function NightLights.Init()
	local night = isNight()
	local function applyAll()
		for _, p in CollectionService:GetTagged("CityWindow") do
			if p:IsA("BasePart") then
				apply(p, night)
			end
		end
	end
	CollectionService:GetInstanceAddedSignal("CityWindow"):Connect(function(p)
		if p:IsA("BasePart") then
			apply(p, night)
		end
	end)
	applyAll()
	Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
		local n = isNight()
		if n ~= night then
			night = n
			applyAll()
		end
	end)
end

return NightLights
