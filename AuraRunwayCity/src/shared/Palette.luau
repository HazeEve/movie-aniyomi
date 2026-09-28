--!nonstrict
-- Aura Runway City palette: "soft luxury" — deep plum + champagne + blush,
-- with lavender/pink neon accents for the stage. Easy on the eyes, never flat.
local P = {}

local function hex(h: string): Color3
	return Color3.fromHex(h)
end

-- Core neutrals
P.PlumDeep = hex("1D1428")
P.Plum = hex("2B1D3F")
P.Aubergine = hex("3F2C5A")
P.Dusk = hex("594479")
P.Ivory = hex("FBF7F2")
P.Pearl = hex("EEE8F0")
P.Mist = hex("D3CADC")
P.Taupe = hex("C9B7AA")
P.Charcoal = hex("342E3D")
P.Asphalt = hex("3A3443")

-- Luxe accents
P.Champagne = hex("F1DDB8")
P.Gold = hex("D8B26E")
P.RoseGold = hex("E2A792")
P.Blush = hex("F4C7D6")
P.Rose = hex("E39AB4")
P.Lavender = hex("B9A5E6")
P.Lilac = hex("DCD0F3")
P.Violet = hex("7A5FB8")

-- Friendly pastels for the city
P.Sage = hex("B8CDB6")
P.Powder = hex("BCD0E8")
P.Peach = hex("F6CDB4")
P.Butter = hex("F4E4B0")
P.Mint = hex("A6DCCB")
P.Leaf = hex("7FAE86")
P.LeafDark = hex("5E8F6A")
P.Grass = hex("93B98A")
P.Wood = hex("A77E62")
P.WoodDark = hex("6E4E3C")

-- Stage neon
P.NeonLavender = hex("A88CFF")
P.NeonPink = hex("FF8BCB")
P.NeonCyan = hex("86DBFF")
P.NeonGold = hex("FFD27A")

-- UI
P.Text = hex("2B1D3F")
P.TextSoft = hex("6B5C80")
P.TextLight = hex("FBF7F2")
P.Success = hex("8ED5B4")
P.Danger = hex("F0899B")
P.Heart = hex("FF6FA8")

P.Facades = { P.Ivory, P.Champagne, P.Blush, P.Lilac, P.Powder, P.Sage, P.Peach, P.Butter, P.Pearl }
P.Trims = { P.RoseGold, P.Gold, P.Dusk, P.Violet, P.Aubergine }
P.Awnings = { P.Rose, P.Lavender, P.Sage, P.RoseGold, P.Powder, P.Violet }
P.CarColors = { P.Blush, P.Lilac, P.Champagne, P.Ivory, P.Powder, P.Mint, P.Plum, P.RoseGold }

return P
