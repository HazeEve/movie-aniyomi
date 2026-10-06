"""Builds the Tripo batch prompt book (16:9 sheets, style written into every prompt)."""
import json, re, sys
sys.path.insert(0, sys.argv[1])  # scratchpad with s5.py
src = open(sys.argv[1] + '/s5.py').read().split('def code')[0]
exec(src)

STYLE = ("Art style: cute cozy 2D hand-painted cel-shaded mobile cooking game art like Good Coffee Great Coffee, "
         "bold dark warm-brown outlines, chunky rounded cute shapes, soft painted cel shading, warm lamp-lit highlights, "
         "rich warm colours; station furniture is matte black with thin gold trim. Straight-on front view.")
RULES = ("Plain flat light cream background, no floor, no shadows on the background, no faces or eyes, no characters, "
         "no text, no labels, no numbers.")

def block(n, rows, items):
    lines = "; ".join(f"({i+1}) {t}" for i, t in enumerate(items))
    return (f"16:9 game asset sheet with exactly {n} separate objects in {rows}, plenty of empty space between them, "
            f"each object complete and not touching or overlapping: {lines}. {STYLE} {RULES}")

def layout(n, big=False):
    if big: return "one row"
    return "one row" if n <= 4 else "two rows"

batches = []  # (section, title, codes, prompt)
def add(section, title, pairs, big=False):
    codes = [c for c, _ in pairs]
    batches.append((section, title, codes, block(len(pairs), layout(len(pairs), big), [t for _, t in pairs])))

def chunk(section, title, pairs, size=8):
    for k in range(0, len(pairs), size):
        part = pairs[k:k+size]
        n = k // size + 1
        tot = (len(pairs) + size - 1) // size
        add(section, f"{title} {n}/{tot}" if tot > 1 else title, part)

# ---------- 1. STATIONS (empty, moving parts drawn separately) ----------
S1 = "1. Stations (empty) and their moving parts"
add(S1, "Cup Rack + Fridge", [
 ("STN_CupRack", "a tall matte black cup rack cabinet with thin gold trim and three EMPTY open shelves, an empty drawer slot at the bottom"),
 ("PRT_CupRack_Drawer", "the cup rack's matte black drawer front with a gold handle"),
 ("STN_Fridge", "a tall matte black display fridge with thin gold trim, door removed, EMPTY white-lit shelves inside"),
 ("PRT_Fridge_Door", "the fridge's tall glass door with a black frame and a long gold handle")], big=True)
add(S1, "Freezer + Pantry", [
 ("STN_Freezer", "a matte black chest freezer with thin gold trim and a round gold snowflake emblem, open top, EMPTY inside with frosty walls"),
 ("PRT_Freezer_Lid", "the freezer's flat sliding glass lid with a black frame, seen from the front"),
 ("STN_Pantry", "a tall matte black pantry cabinet with thin gold trim and a gold plaque, EMPTY shelves, three empty drawer slots at the bottom"),
 ("PRT_Pantry_Drawer", "one pantry drawer front, matte black with a gold handle"),
 ("PRT_Pantry_JarLid", "a glass storage jar lid with a gold rim, alone"),
 ("PRT_Pantry_TinLid", "a round tin lid with a gold rim, alone")])
add(S1, "Syrup Shelf + Cutting Board", [
 ("STN_SyrupShelf", "a matte black syrup shelf cabinet with thin gold trim and three EMPTY shelf rows, a lower cupboard with its door removed"),
 ("PRT_SyrupShelf_Door", "the syrup shelf's lower cupboard door, matte black with a gold handle"),
 ("STN_CuttingBoard", "a large empty light wooden cutting board"),
 ("STN_Sink", "a small matte black sink with a gold faucet, no water")], big=True)
add(S1, "Juicer + Blender (by parts)", [
 ("STN_Juicer", "a black and silver electric juicer body with an empty feed chute and a front spout, pusher and jug removed"),
 ("PRT_Juicer_Pusher", "the juicer's black pusher"),
 ("PRT_Juicer_Jug", "an empty clear juice jug with a handle"),
 ("STN_Blender", "a white blender base with a silver dial socket and a black button, jar removed"),
 ("PRT_Blender_Jar", "an empty clear blender jar with steel blades, no lid"),
 ("PRT_Blender_Lid", "a black blender lid"),
 ("PRT_Blender_Dial", "a round silver blender dial")])
add(S1, "Coffee Machine (by parts)", [
 ("STN_CoffeeMachine", "a matte black espresso machine with gold trim, the dial face empty, with NO portafilter, NO knobs, NO steam wand and NO grinder jar attached, empty drip tray"),
 ("PRT_Coffee_Portafilter", "an espresso portafilter with a black handle and an empty steel basket"),
 ("PRT_Coffee_Knob", "one round gold espresso machine knob"),
 ("PRT_Coffee_Gauge", "a round gold-rimmed pressure gauge face with tick marks and NO needle"),
 ("PRT_Coffee_GaugeNeedle", "a thin red gauge needle"),
 ("PRT_Coffee_SteamWand", "a silver espresso steam wand"),
 ("PRT_Coffee_GrinderJar", "an empty glass coffee grinder hopper jar"),
 ("PRT_Coffee_GrinderLid", "the grinder jar's black lid")])
add(S1, "Stove + Tea/Boba Bar", [
 ("STN_Stove", "a matte black glass cooktop with thin gold trim and two burner rings, burners OFF, no pots"),
 ("PRT_Stove_Knob", "one round gold stove knob"),
 ("STN_TeaBar", "a matte black and gold tea bar cabinet with a gold sign plaque, EMPTY shelves and an empty counter top"),
 ("PRT_Tea_Canister", "a black tea canister with a gold rim, closed"),
 ("PRT_Tea_CanisterLid", "the black tea canister lid with a gold rim"),
 ("PRT_Boba_Pot", "an empty steel cooking pot with two handles")], big=False)
add(S1, "Mixing + Soda Fountain", [
 ("STN_MixingMat", "a black rubber bar mat with gold stripes, empty"),
 ("STN_SodaFountain", "a matte black soda fountain machine with thin gold trim, a blank glowing panel on top, six dispenser nozzles with the levers removed, an empty drip grate"),
 ("PRT_Soda_Lever", "one black soda dispenser lever with a gold tip"),
 ("STN_IceTray", "an empty steel ice tray")])
add(S1, "Topping Station", [
 ("STN_Topping", "a matte black and gold topping cabinet with a long EMPTY gold pump rail on top and a row of EMPTY square container slots below"),
 ("PRT_Top_PumpHead_Up", "a gold syrup pump head, raised"),
 ("PRT_Top_PumpHead_Down", "the same gold syrup pump head, pressed down")])
add(S1, "Cup Sealer + Infusion Barrel", [
 ("STN_CupSealer", "a matte black and gold cup sealing machine, empty cup holder, with the press head, the pull lever and the film roll removed"),
 ("PRT_Sealer_Press", "the sealer's black press head"),
 ("PRT_Sealer_Lever", "the sealer's gold pull lever"),
 ("PRT_Sealer_FilmRoll", "a roll of clear printed sealing film"),
 ("STN_Barrel", "a wooden barrel with gold hoops and a round gold emblem on a wooden stand, tap removed"),
 ("PRT_Barrel_Tap", "a gold barrel tap with its handle closed"),
 ("PRT_Barrel_TapOpen", "the same gold barrel tap with its handle turned open")])
add(S1, "Serving Counter", [
 ("STN_Coaster", "a round gold coaster"),
 ("PRT_Serve_Bell", "a small gold service bell"),
 ("STN_NapkinHolder", "a small black and gold napkin holder with white napkins"),
 ("STN_Vase", "a small glass vase with one flower")])

# ---------- 2. MATERIALS ----------
S2 = "2. Materials (cups, bottles, pumps, containers, tools)"
cups = [("CUP_EspressoCup","an EMPTY small white espresso cup with a gold rim on a saucer"),("CUP_CoffeeMug","an EMPTY white coffee mug with a gold rim"),
 ("CUP_GlassMug","an EMPTY clear glass mug with a gold rim"),("CUP_TallGlass","an EMPTY tall clear glass with a gold rim"),
 ("CUP_FrappeCup","an EMPTY clear frappe cup, no lid"),("CUP_DessertGlass","an EMPTY short stemmed dessert glass"),
 ("CUP_SmoothieGlass","an EMPTY curvy smoothie glass with a gold rim"),("CUP_MilkshakeGlass","an EMPTY tall fluted milkshake glass"),
 ("CUP_SodaGlass","an EMPTY clear soda glass with a gold rim"),("CUP_FloatMug","an EMPTY glass float mug with a handle"),
 ("CUP_BobaCup","an EMPTY clear boba cup, no seal"),("CUP_JuiceGlass","an EMPTY short clear juice glass with a gold rim"),
 ("CUP_MilkBottle","an EMPTY small glass milk bottle, no cap"),("CUP_HighballGlass","an EMPTY tall slim highball glass"),
 ("CUP_HurricaneGlass","an EMPTY curvy hurricane glass"),("CUP_FrappeLid","a clear dome lid for the frappe cup, alone")]
chunk(S2, "Glasses and cups", cups)
add(S2, "Cup extras", [("CUP_BobaSeal","a round printed boba cup seal film, flat"),("CUP_MilkBottleCap","a gold milk bottle cap"),
 ("CUP_BobaStraw","a wide boba straw"),("CUP_Straw","a thin drinking straw"),("CUP_Napkin","a folded white napkin"),
 ("CUP_Saucer","an empty white saucer with a gold rim")])
shelf = [(n, c) for n, c, _ in [("Agave Nectar","clear amber",0),("Blue Raspberry Syrup","bright blue",0),("Cherry Cordial","deep red",0),
 ("Coconut Syrup","milky white",0),("Coffee Syrup","dark brown",0),("Crystal Tonic","sparkling clear",0),("Cucumber Tonic","pale green",0),
 ("Golden Sparkling Juice","golden sparkling",0),("Golden Tea Syrup","golden",0),("Grape Syrup","purple",0),("Hibiscus Syrup","pink-red",0),
 ("Mandarin Syrup","orange",0),("Orange Syrup","warm orange",0),("Peach Syrup","soft peach",0),("Red Orange Soda","red-orange fizzy",0),
 ("Smoky Tea Syrup","smoky brown",0),("Sparkling Grape Juice","purple sparkling",0),("Sparkling White Grape","pale gold sparkling",0),
 ("Spiced Brown Sugar Syrup","dark amber",0),("Grenadine","deep ruby red",0)]]
code = lambda n: re.sub(r"[^A-Za-z]", "", n.title())
bottles = [(f"BTL_{code(n)}", f"a tall glass bottle with a gold cap, filled with {c} {n.lower()}") for n, c in shelf]
bottles += [("BTL_AromaDrops", "a tiny glass dropper bottle of aroma drops"), ("PRT_BottleCap", "one gold bottle cap, alone")]
chunk(S2, "Syrup Shelf bottles (closed)", bottles)
pumps = "Apple:pale gold,Blue Raspberry:bright blue,Blueberry:indigo,Butterfly Pea:deep blue,Lychee:pale pink,Caramel Sauce:thick amber,Caramel:amber,Cherry:red,Chocolate:dark brown,Peppermint:pale mint,Cinnamon:warm brown,Cola:dark brown,Cucumber:pale green,Ginger:pale gold,Grape:purple,Hazelnut:tan,Honey:gold,Honeydew:pale green,Kiwi:green,Lemon:yellow,Lime:green,Mango:orange-yellow,Mint:green,Orange:orange,Orgeat:milky white,Pandan:bright green,Passion Fruit:golden,Peach:soft peach,Raspberry:pink-red,Rose:pink,Simple:clear,Strawberry:red,Sweet Cream:white,Ube:purple,Vanilla:pale gold,Wintermelon:pale amber".split(",")
pumps = [(f"PMP_{code(p.split(':')[0])}", f"a clear glass pump bottle with a gold pump head, filled with {p.split(':')[1]} {p.split(':')[0].lower()} syrup") for p in pumps]
chunk(S2, "Topping pump bottles", pumps)
tops = ["popping pearls","coconut jelly cubes","crystal boba","rose jelly","nata de coco","sago pearls","basil seeds","chopped pistachio",
        "crushed hazelnuts","hazelnut crumble","dark chocolate shavings","white chocolate shavings","cooked black boba pearls","strawberry slices","blueberries","mint leaves"]
tops = [(f"CTN_{code(t)}", f"an open clear square acrylic topping container full of {t}") for t in tops]
chunk(S2, "Topping containers (full)", tops)
add(S2, "Sauces, shakers and empty containers", [
 ("SAU_Caramel","a squeeze bottle of caramel sauce"),("SAU_Chocolate","a squeeze bottle of chocolate sauce"),("SAU_Strawberry","a squeeze bottle of strawberry sauce"),
 ("SHK_Cinnamon","a small glass shaker with a gold lid filled with cinnamon"),("SHK_SeaSalt","a small glass shaker with a gold lid filled with sea salt"),
 ("SHK_EdibleGlitter","a small glass shaker with a gold lid filled with edible glitter"),("CTN_Empty","an EMPTY clear square acrylic topping container"),
 ("SHK_Empty","an EMPTY small glass shaker with a gold lid")])
add(S2, "Shakers 2 + cream tools", [
 ("SHK_GoldFlakes","a small glass shaker with a gold lid filled with edible gold flakes"),("SHK_SilverShimmer","a small glass shaker with a gold lid filled with edible silver shimmer"),
 ("SHK_GoldSprinkles","a small glass shaker with a gold lid filled with gold sprinkles"),("TL_WhipDispenser","a silver whipped cream dispenser bottle"),
 ("TL_PipingBag","a white piping bag with a star tip"),("TL_Torch","a small kitchen torch, flame off"),("TL_ToppingScoop","a small silver topping scoop"),
 ("TL_IceCreamScoop","a silver ice cream scoop")])
chunk(S2, "Tools", [("TL_Knife","a chef knife with a black handle, horizontal"),("TL_Peeler","a silver vegetable peeler"),("TL_Spoon","a silver spoon"),
 ("TL_RollingPin","a wooden rolling pin, horizontal"),("TL_MilkPitcher","an EMPTY steel milk frothing pitcher"),("TL_Cezve","an EMPTY gold Turkish cezve coffee pot with a long handle"),
 ("TL_Saucepan","an EMPTY small steel saucepan with a handle"),("TL_WoodenSpoon","a wooden spoon"),("TL_TeaPot","an EMPTY glass tea pot with its lid"),
 ("TL_Strainer","a strainer ladle"),("TL_Shaker","a closed silver cocktail shaker"),("TL_ShakerCap","the silver cocktail shaker cap, alone"),
 ("TL_Muddler","a wooden muddler"),("TL_Whisk","a silver hand whisk"),("TL_BarSpoon","a long gold bar spoon"),("TL_CocktailStrainer","a silver cocktail strainer"),
 ("TL_Jigger","a small gold jigger"),("TL_IceScoop","a small silver ice scoop"),("TL_Bowl","an EMPTY small white bowl"),("TL_Tamper","a gold espresso tamper"),
 ("TL_Tongs","small silver tongs"),("TL_Dropper","a small glass dropper")])

# ---------- 3. INGREDIENTS (as stored) ----------
S3 = "3. Ingredients as stored"
def whole(rows, pre):
    return [(f"ING_{code(n)}", look) for n, look, _ in rows]
chunk(S3, "Fridge", whole(F, "F"))
chunk(S3, "Freezer", whole(Z, "Z"))
chunk(S3, "Pantry", whole(P, "P"))

# ---------- 4. CUT / PREPARED (solid) and 5. LIQUIDS ----------
STREAM = {"Pour","Juice","Brewed","Syrup","Dissolved","Mixed","Blended","Boiled"}
LIQ = STREAM | {"Melted","Drizzle","Drops","Float","Foam","Whisked","Shaken","Steamed","Warm","Purée"}
QTY = ("a few", "a handful", "a pinch", "a spoonful", "a small pile", "a pile", "a dusting", "two ", "three ")
def named(v, n):
    nl = n.lower()
    if any(w.rstrip("s") in v.lower() for w in nl.replace("-", " ").split() if len(w) > 3):
        return v
    if v.startswith(QTY):
        return f"{v} of {nl}"
    return f"{v} ({nl})"
solid, liquid = [], []
for n, _, states in F + Z + P:
    for s in states.split("; "):
        k, v = s.split(": ", 1)
        kc = re.sub(r"[^A-Za-z]", "", k.replace("é", "e"))
        code_ = f"ING_{code(n)}_{kc}"
        if k in STREAM:
            v = re.sub(r"^(a|an) (jug|bottle) of ", "", v)
            v = re.sub(r"^(a|an) ", "", v)
            if "ribbon" in v:
                v = "a thick slow cream ribbon"
            elif "stream" in v or "splash" in v:
                v = "a " + v
            else:
                v = f"a falling stream of {v}"
            liquid.append((code_, v if n.lower() in v.lower() else f"{v} ({n.lower()})"))
        elif k == "Melted":
            liquid.append((code_, f"a glossy pool of {v} ({n.lower()})"))
        elif k == "Purée":
            liquid.append((code_, named("a soft dollop of " + v, n)))
        elif k in LIQ:
            liquid.append((code_, named(v, n)))
        else:
            solid.append((code_, named(v, n)))
S4 = "4. Ingredients cut and prepared (slices, wheels, wedges, cubes, crumbs)"
chunk(S4, "Prepared", solid)
S5 = "5. Liquids (pours, juices, drizzles, foams, layers)"
chunk(S5, "Ingredient liquids", liquid)
for n, c in shelf:
    pass
streams = [(f"LIQ_Pour_{code(n)}", f"a falling {c} stream of {n.lower()}") for n, c in shelf]
chunk(S5, "Syrup Shelf pour streams", streams)
pstreams = [(c.replace("PMP_", "LIQ_Pump_"), "a short pumped squirt of " + t.split("filled with ")[1]) for c, t in pumps]
chunk(S5, "Pump syrup squirts", pstreams)
chunk(S5, "Machine and drink liquids", [
 ("LIQ_Espresso","a thin dark brown espresso stream with a caramel highlight"),("LIQ_Coffee","a brown brewed coffee stream"),("LIQ_HotWater","a clear hot water stream"),
 ("LIQ_Nitro","a cascading creamy brown nitro coffee stream"),("LIQ_Crema","a round golden-brown espresso crema top"),("LIQ_MilkFoamPour","a white milk foam pour from a pitcher spout"),
 ("LIQ_Tea","an amber tea stream from a teapot spout"),("LIQ_Soda","a fizzy clear soda stream with bubbles"),("LIQ_Cola","a fizzy dark cola stream"),
 ("LIQ_Smoothie","a thick pink smoothie pour"),("LIQ_Barrel","an amber infusion stream from a tap"),("LIQ_CaramelDrizzle","a caramel sauce zigzag drizzle"),
 ("LIQ_ChocolateDrizzle","a chocolate sauce zigzag drizzle"),("LIQ_StrawberryDrizzle","a strawberry sauce zigzag drizzle"),("LIQ_WhippedCream","a swirl of white whipped cream from a dispenser"),
 ("LIQ_CreamFoam","a soft white cream foam cap"),("LIQ_CheeseFoam","a thick pale cheese foam cap"),("LIQ_SeaSaltFoam","a pale sea salt foam cap with salt flakes"),
 ("LIQ_Splash","a small clear liquid splash crown"),("LIQ_Drip","three single liquid drops")])

batches = [(s, t, c, p.replace("a small pile (shown in a clear square container) of chocolate chips", "a small pile of chocolate chips")) for s, t, c, p in batches]
out = {"style": STYLE, "rules": RULES, "batches": [dict(section=s, title=t, codes=c, prompt=p) for s, t, c, p in batches]}
json.dump(out, open(sys.argv[2], "w"), indent=1)
from collections import Counter
print(len(batches), "batches;", sum(len(b[2]) for b in batches), "items")
for s, n in Counter(b[0] for b in batches).items(): print(n, s)
