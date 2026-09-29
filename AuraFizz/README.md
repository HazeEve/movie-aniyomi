# AuraFizz2D: 2D gameplay GUI for AURAFIZZ

This adds Papa's / Cooking Mama-style **2D** gameplay to your AURAFIZZ drink game. A customer orders one drink. You make it step by step in 2D (shelf screens and mini-games), then serve it and get stars, a tip and confetti.

It is **only GUI**. It builds no parts, models or stations. It reads the modules your game already has in `ReplicatedStorage.Drinks`:

| Your module | What the 2D game uses it for |
|---|---|
| `DrinkRecipes` | Each drink's steps: storage → appliance mini-games → `ServeCounter` |
| `DrinkCatalog` | Stations, cups, storage items, and each action's mini-game type and settings |
| `DrinkLooks` | The liquid colours and layers in the live cup preview |
| `DrinkImages` | **Your pictures** of drinks, items and cups (`IMG.Apply`). Painted placeholders are used until the sheets are uploaded. |
| `Sounds` | Your sound IDs (`S.Ids`), mapped in `Config.SoundMap` |

All 232 all-ages drinks from Update v3 are playable. `tools/check_with_your_data.py` checks every recipe step against your catalog: 0 problems.

## Install (pick one)

**Studio Command Bar (like your AURAFIZZ updates)**
1. Install your AURAFIZZ drink modules first (`ReplicatedStorage.Drinks`).
2. Open `AuraFizz2D_Install.lua`, paste the whole file into the Command Bar (Edit mode) and press Enter.
3. Press Play. Click the **🧋 AURAFIZZ** button on the left, or press **F**.

Old copies go to `ServerStorage.AuraFizzRemoved`. Ctrl+Z undoes the install, and it's safe to run again.

**Rojo:** `rojo serve` with `default.project.json`. It only adds the three items below and changes nothing else.

It adds:
- `ReplicatedStorage.AuraFizz2D`: the modules (`Api`, `Cafe`, `MiniGames`, `Storage`, `Bridge`, `UI`, `FX`, `Paint`, `Config`).
- `ServerScriptService.AuraFizz2DServer`: orders and tips, with Hooks for your economy.
- `StarterPlayerScripts.AuraFizz2DClient`: the open button, the F key, and opens requested by the server.

## How a drink plays

1. **Order card:** the customer, your picture of the drink, its tier, its ingredient list, and a live "Yours" cup that fills as you work.
2. **Shelf screens** for each storage visit (Cup Rack, Pantry Shelf, Fridge, Freezer, Syrup Shelf). Tap the right items. Wrong picks cost a little, and an idle player gets a gentle hint.
3. **One of the 12 mini-games per appliance action,** each with its own painted station scene: coffee machine, stove, blender, juicer, cutting board, tea & boba, shaker, soda fountain, topping station, cup sealer and infusion barrel.
4. **Serve:** a star rating, a score bar and grade per step, a tip count-up, the customer's reaction, and confetti for 4.5★ and up.

**Serve customers** runs a shift of 6 orders. **Practice from the menu** lets you pick any drink by category.

## The 12 mini-games

There are 6 Papa's-style games (build it right) and 6 Cooking Mama-style games (skill and rhythm). Every one of your 56 catalog actions is assigned to one of them in `Config.Games`, so all 12 show up in real play:

| Papa's-style | How it plays | Your actions |
|---|---|---|
| **Fill** | Hold to pour into the actual cup; let go on the dashed line (it spills if you overfill) | hot_water, fizz, soda_water, pour_soda, carbonate, nitro, seal |
| **Blend** | Hold to blend while the arrow climbs Chunky → Regular → Smooth; let go on the target. The chunks in the jar melt away as you go | blend, puree, blend_fruit, squeeze, press, steam, scoop |
| **Cook** | A kitchen timer dial ticks round (°C shown for heat); stop it in the gold wedge. There's a *ding* when it's ready, and leaving it too long fails | pull_shot, brew_coffee, brew_tea, heat_milk, cook_pearls, boil_cezve, steep_cold_brew, mash, boil_wort, ferment, age_oak, age_french_oak, cellar, torch |
| **Stack** | The ticket shows the layers bottom → top; tap the recipe's ingredients in that order (with decoys) and each layer drops into the cup | layer, float_cream, spoon |
| **Toppings** | Drag each topping (your real fruit picture when the drink has fruit) onto the marked spots for an even spread | garnish, add_topping |
| **Drizzle** | Top view into the cup: hold and trace the sauce over the dotted swirl. You score for coverage, and messy sauce off the path costs points | drizzle, whip |

| Cooking Mama-style | How it plays | Your actions |
|---|---|---|
| **Trace** | Start at the gold dot and drag the knife along each dotted cut line | chop, slice, wedge |
| **Peel** | Swipe strips off (back and forth when `alternate`) | peel, zest, strain |
| **Mash** | Alternate ◀ ▶ as fast as you can (also A/D and ←/→) | crush, muddle, scrape |
| **Stir** | Drag in circles for the number of turns | grind, grind_fine, froth, melt, simmer, stir, whisk |
| **Shake** | Follow the arrow pattern ↑↓←→ (buttons, arrow keys or WASD) | shake, shake_boba, dry_shake |
| **Catch** | Slide the cup to catch the falling drops and dodge the grey bits | pump, sprinkle |

To change a game, edit its line in `Config.Games`. An action that isn't listed plays by its catalog type: Hold → Fill, Cook → Cook, Timing → Blend, Tap → Mash, Swipe → Peel, Circle → Stir. New catalog actions can also name a game directly (`game = "Drizzle"`). Each game still uses your catalog settings: `fillTime`, the gold zone, `duration`, `maxTemp`, `turns` and `count`.

Grades after each step: **Perfect! / Great! / Good / Okay… / Oops!**, with fun variants from `Config.GradeLines`. The words "Papa's" and "Cooking Mama" appear only in these docs and code comments, never on screen.

## Hooking up your 3D stations

Your stations can open a single 2D step instead of the whole café. From a client script:

```lua
local Fizz2D = require(game.ReplicatedStorage.AuraFizz2D.Api)
local score = Fizz2D.PlayAction("pull_shot", { drinkId = "cafe_latte", label = "Pull the espresso shot" }) -- 0..1
local score = Fizz2D.PickFromStorage("Pantry", { "coffee_beans", "sugar" })                             -- 0..1
local score = Fizz2D.PlayStep("americano", 5)       -- the 5th step in DrinkRecipes
local result = Fizz2D.MakeDrink("iced_latte")       -- whole drink -> { Total, Stars, Tip, Scores }
Fizz2D.OpenCafe()
```

From a server script (for example a ProximityPrompt handler):

```lua
game.ReplicatedStorage.AuraFizz2DOpen:FireClient(player, "Action", "pull_shot")
game.ReplicatedStorage.AuraFizz2DOpen:FireClient(player, "Storage", "Pantry", { "coffee_beans" })
```

The score comes back to the server in `Hooks.OnStepResult`.

## Things to set

| What | Where |
|---|---|
| Pay tips with your coins | `AuraFizz2DServer` → `Hooks.Reward` (default adds to `leaderstats.Coins` if it exists) |
| Only order drinks the player unlocked | `AuraFizz2DServer` → `Hooks.CanMake` |
| Which game each action plays | `Config.Games` |
| Tip per tier, customers per shift, open button, F key | `AuraFizz2D.Config` |
| Which sound plays when | `Config.SoundMap` (uses the names in your `Sounds` module) |
| Easier or harder time limits | `Config.TimeLimitScale` |
| Colours (pastel painted style) | `Config.Theme`, `Config.Pastels` |

**Pictures:** once you upload your sheets and paste the IDs with your `4_PasteUploadIDs.lua`, the 2D screens show your drink, item and cup pictures automatically.

## Next updates (bakery, sushi, …)

The 2D game follows your data. Add the new stations, items, actions and recipes to your Catalog and Recipes modules the same way as drinks, give each action one of the 12 game types, and it plays. A new station gets a generic scene until one is added in `MiniGames.luau` (`SCENES`).

## Checked here vs. in Studio

- ✅ Every file compiles, and the **Roblox type check** (luau-lsp with the official Roblox definitions) is clean.
- ✅ All 679 GUI property names were checked against the Roblox API dump.
- ✅ Your real `DrinkRecipes` and `DrinkCatalog` load through the bridge: 232 drinks, every station, item, cup and action found, and all 12 games are used.
- ❌ **Not yet seen running in Studio.** Layout, feel and timing still need a real playtest. Tell me what looks off, or send screenshots.

## Tools

- `python3 tools/build_installer.py`: rebuilds `AuraFizz2D_Install.lua` after editing `src/`.
- `python3 tools/check_with_your_data.py path/to/2_Update_v3.lua`: checks your recipes against the 2D game. It needs the [`luau` CLI](https://github.com/luau-lang/luau/releases).
