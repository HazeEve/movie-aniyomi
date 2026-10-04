# Aura Fizz — hand-off for the next session (image generation)

Goal: Good Coffee Great Coffee-quality 2D cooking screens for every Aura Fizz station, painted (not vector shapes),
using AI image generation through the Hugging Face connector (Space: mcp-tools/Qwen-Image or mcp-tools/FLUX.1-Krea-dev).

Always check `AuraFizz/art/reference/` first (owner's rule):
- How_Every_Station_Looks.docx + stations_overview.webp: real stations are black & gold with cream marble tops.
- How_Every_Drink_Looks.docx: glasses, liquid colours, toppings (cream stays inside the rim), striped straws, gold rims.
- Ingredients_Drinks__Recipes.docx: 145 ingredients, storage, 232 recipes, steps per station.
- Toppings & sugar go in clear square containers; whipped cream comes from a dispenser bottle.

Owner's feedback so far: vector/SVG and Blender toon renders look like "shapes and sticks"; pastel redesign NOT wanted.
Wants their real black & gold stations, painted in GCGC's art style but even prettier; GCGC composition
(top-down-ish front view, big items filling the screen, few props). Keep replies short.

Plan: generate one station (Coffee Machine) first for approval, then the rest in kitchen order:
Cup Rack, Fridge, Freezer, Pantry, Syrup Shelf, Cutting Board, Juicer, Blender, Coffee Machine, Stove,
Tea & Boba, Mixing Station, Soda Fountain, Topping Station, Cup Sealer, Infusion Barrel.
Then cut into sprites (background removal Space), and wire them into AuraFizz/src/AuraFizz2D (ImageLabels).
