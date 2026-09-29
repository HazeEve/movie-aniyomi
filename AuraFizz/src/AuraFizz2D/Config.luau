--!nonstrict
-- AuraFizz2D · Config
-- The 2D gameplay layer for AURAFIZZ. It reads your existing modules in
-- ReplicatedStorage.Drinks (DrinkRecipes, DrinkCatalog, DrinkLooks, DrinkImages, Sounds)
-- and builds NO parts or models: only ScreenGui screens.
local Config = {}

-- Where your game's drink modules live.
Config.DrinksFolder = "Drinks" -- ReplicatedStorage.Drinks

-- Standalone café mode (customers order one drink, you make it in 2D, then serve).
Config.ShowOpenButton = true -- small "Aura Fizz" button on the left of the screen
Config.OpenKey = Enum.KeyCode.F -- keyboard shortcut to open the café (nil = none)
Config.CustomersPerShift = 6

-- Tips per tier (coins at 100%). Your own economy can override this in the server Hooks.
Config.TierTip = {
	Tasty = 8, Delish = 12, Mouthwatering = 18, Scrumptious = 25,
	Toothsome = 35, Luscious = 50, Delectable = 70, Ambrosial = 100,
}
Config.TierColor = {
	Tasty = "#a8d8b9", Delish = "#8ec5f0", Mouthwatering = "#c7b3e6", Scrumptious = "#ffd97a",
	Toothsome = "#f5a86b", Luscious = "#f59ac0", Delectable = "#ff8a8a", Ambrosial = "#f7d25a",
}
Config.TierOrder = { "Tasty", "Delish", "Mouthwatering", "Scrumptious", "Toothsome", "Luscious", "Delectable", "Ambrosial" }

-- Your real 3D stations shown inside the 2D screens (instead of drawn shapes).
-- Models are found by name anywhere in Workspace ("ToppingStation", "Topping Station", ...).
-- If a model has another name, point to it here, e.g.
--   Config.StationModels = { ToppingStation = "Workspace.Kitchen.Toppings", Stove = "Workspace.Cafe.Oven" }
-- StationView lets you turn/tilt/zoom a shot: { ToppingStation = { yaw = 180, pitch = 20, zoom = 0.9 } }
Config.UseStationModels = true
Config.StationModels = {}
Config.StationModelsFolder = nil -- e.g. "ReplicatedStorage.StationModels" to look there first
Config.StationView = {}

-- See-through window so you keep seeing the game behind it (0 = solid, 1 = invisible).
Config.WindowTransparency = 0.55 -- the big window behind everything
Config.PanelTransparency = 0.35  -- the station panel (keeps text readable)

-- Mini-game difficulty (1 = as tuned in DrinkCatalog; lower = more forgiving time limits)
Config.TimeLimitScale = 1

-- The 12 mini-games (6 Papa's-style + 6 Cooking-Mama-style) and which of YOUR
-- DrinkCatalog actions plays which. Change any line to swap a game. An action that
-- isn't listed plays by its catalog type: Hold -> Fill, Cook -> Cook, Timing -> Blend,
-- Tap -> Mash, Swipe -> Peel, Circle -> Stir. New catalog actions can also name a
-- game directly: game = "Drizzle".
--
--  Papa's-style                                     Cooking-Mama-style
--   Fill      pour into the cup, stop on the line    Trace   knife along dotted cut lines
--   Blend     hold, let go on Chunky/Regular/Smooth  Peel    swipe strips off
--   Cook      timer dial, stop in the gold wedge     Mash    alternate left/right fast
--   Stack     add layers in the ticket's order       Stir    drag in circles
--   Toppings  drag toppings evenly onto the drink    Shake   follow the arrow pattern
--   Drizzle   trace sauce over the dotted swirl      Catch   catch falling drops in the cup
Config.Games = {
	-- Papa's-style
	hot_water = "Fill", fizz = "Fill", soda_water = "Fill", pour_soda = "Fill", carbonate = "Fill", nitro = "Fill", seal = "Fill",
	blend = "Blend", puree = "Blend", blend_fruit = "Blend", squeeze = "Blend", press = "Blend", steam = "Blend", scoop = "Blend",
	pull_shot = "Cook", brew_coffee = "Cook", steep_cold_brew = "Cook", heat_milk = "Cook", boil_cezve = "Cook", mash = "Cook",
	boil_wort = "Cook", brew_tea = "Cook", cook_pearls = "Cook", ferment = "Cook", age_oak = "Cook", age_french_oak = "Cook",
	cellar = "Cook", torch = "Cook",
	layer = "Stack", float_cream = "Stack", spoon = "Stack",
	garnish = "Toppings", add_topping = "Toppings",
	drizzle = "Drizzle", whip = "Drizzle",
	-- Cooking-Mama-style
	chop = "Trace", slice = "Trace", wedge = "Trace",
	peel = "Peel", zest = "Peel", strain = "Peel",
	crush = "Mash", muddle = "Mash", scrape = "Mash",
	grind = "Stir", grind_fine = "Stir", froth = "Stir", melt = "Stir", simmer = "Stir", stir = "Stir", whisk = "Stir",
	shake = "Shake", shake_boba = "Shake", dry_shake = "Shake",
	pump = "Catch", sprinkle = "Catch",
}

-- Fun lines shown with the grade after each step (picked at random).
Config.GradeLines = {
	Perfect = { "Perfect!", "Fizz-tastic!", "Aura-mazing!", "Sparkling!" },
	Great = { "Great!", "So smooth!", "Lovely!" },
	Good = { "Good", "Nice try!", "Not bad!" },
	Okay = { "Okay...", "Almost!", "Keep going!" },
	Oops = { "Oops!", "Uh-oh!", "Try again next time!" },
}

-- Hint: after this many idle seconds at a storage shelf, the next needed item pulses.
Config.StorageHintAfter = 6

-- Which of YOUR Sounds (ReplicatedStorage.Drinks.Sounds -> S.Ids) each moment plays.
Config.SoundMap = {
	Click = "UIClick", Open = "UIOpen", Close = "UIClose", Pick = "Pop", Wrong = "Poof",
	Pour = "Pour", Fizz = "Fizz", Perfect = "Sparkle", Good = "Pop", Oops = "Poof",
	Serve = "Serve", Sip = "Sip", Happy = "Happy", Angry = "Angry", Coins = "Coin",
	LevelUp = "LevelUp", Order = "OrderPing", Whoosh = "Whoosh",
}

-- Pastel painted UI (same rules as the pastel-fruit-art skill: soft 3-tone shading,
-- chunky rounded shapes, no outlines, no gloss).
Config.Theme = { -- black & gold, to match your appliances
	Ground = "#121015",
	Panel = "#1d1a21",
	PanelLight = "#2a2530",
	Paper = "#fbf3e2",
	Text = "#fbf3e2",
	TextDark = "#2a2016",
	TextSoft = "#b8ab98",
	Accent = "#d8b45a",
	Gold = "#f2d27a",
	Good = "#8ed5b4",
	Warn = "#f7c95b",
	Bad = "#f0899b",
	Wood = "#6b4a33",
	Steel = "#3a3440",
	Appliance = "#221e27", -- black appliance bodies
	Trim = "#d8b45a",      -- gold trim
}
Config.Pastels = { "#f2d27a", "#d8b45a", "#f7e3a5", "#e8c46a", "#fbf3e2", "#c9a24a", "#f5d98c", "#e0c07a" } -- gold sparkle tones
Config.CustomerNames = {
	"Mia", "Leo", "Zoe", "Kai", "Luna", "Nico", "Ivy", "Theo", "Aria", "Jax",
	"Ruby", "Finn", "Nova", "Eli", "Sage", "Remy", "Cleo", "Milo", "Skye", "Juno",
}
Config.SkinTones = { "#f6d7c3", "#eec1a0", "#d9a27c", "#b97c55", "#8d5a3b", "#5e3b28" }
Config.HairColors = { "#3a2a26", "#6b4430", "#c98a52", "#f2d27a", "#e0533d", "#c7b3e6", "#1d1d24" }

return Config
