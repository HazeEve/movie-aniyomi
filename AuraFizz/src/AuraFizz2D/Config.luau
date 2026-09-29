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

-- Mini-game difficulty (1 = as tuned in DrinkCatalog; lower = more forgiving time limits)
Config.TimeLimitScale = 1

-- Cooking-Mama-style variety: these actions from your DrinkCatalog play one of the extra
-- 2D game types instead of their original type. Delete a line (or set this to {}) to keep
-- your original Tap/Swipe/Hold/Circle/Cook/Timing games. New actions you add to your
-- catalog can also use these game names directly: game = "Trace", "Mash", ...
--   Trace     drag the knife along dotted cut lines
--   Mash      alternate left/right as fast as you can
--   Sequence  follow the arrow pattern (↑ ↓ ← →)
--   Catch     slide the cup to catch falling toppings, dodge the duds
--   Steady    keep the pour marker inside the drifting gold zone
--   Drag      drag garnish pieces onto the marked spots
Config.GameOverrides = {
	chop = "Trace", slice = "Trace", wedge = "Trace",
	crush = "Mash", muddle = "Mash", scrape = "Mash",
	shake = "Sequence", shake_boba = "Sequence", dry_shake = "Sequence",
	sprinkle = "Catch", add_topping = "Catch",
	layer = "Steady", float_cream = "Steady",
	garnish = "Drag",
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
Config.Theme = {
	Ground = "#232b3d",
	Panel = "#2f3950",
	PanelLight = "#3b4763",
	Paper = "#fbf3e2",
	Text = "#fbf7f2",
	TextDark = "#3a2f45",
	TextSoft = "#b9c0d4",
	Accent = "#f59ac0",
	Gold = "#f7c95b",
	Good = "#8ed5b4",
	Warn = "#f7c95b",
	Bad = "#f0899b",
	Wood = "#c98a52",
	Steel = "#aeb6c6",
}
Config.Pastels = { "#f4b6c2", "#a8d8b9", "#c7b3e6", "#ffd97a", "#8ec5f0", "#f5a86b", "#e6a0b4", "#9fd8d0" }
Config.CustomerNames = {
	"Mia", "Leo", "Zoe", "Kai", "Luna", "Nico", "Ivy", "Theo", "Aria", "Jax",
	"Ruby", "Finn", "Nova", "Eli", "Sage", "Remy", "Cleo", "Milo", "Skye", "Juno",
}
Config.SkinTones = { "#f6d7c3", "#eec1a0", "#d9a27c", "#b97c55", "#8d5a3b", "#5e3b28" }
Config.HairColors = { "#3a2a26", "#6b4430", "#c98a52", "#f2d27a", "#e0533d", "#c7b3e6", "#1d1d24" }

return Config
