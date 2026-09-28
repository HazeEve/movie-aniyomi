--!nonstrict
-- 1000 runway themes (Dress-To-Impress style).
-- A hand-picked list first, then stylish "Adjective + Character" combos fill
-- the rest up to exactly 1000. Add/remove freely.
local curated = {
	"Old Money Elegance", "Y2K Pop Princess", "Red Carpet Gala", "Dark Academia", "Cottagecore Picnic",
	"Galaxy Diva", "Streetwear Icon", "Witchy Glam", "Beach Resort Luxe", "Pastel Dream", "Rockstar",
	"Royal Ball", "Office Siren", "Kawaii Café", "Winter Wonderland", "Met Gala: Flowers", "Monochrome Black",
	"All White Party", "Fairy Core", "Vintage Hollywood", "Sporty Chic", "Masquerade", "Futuristic Cyber",
	"Candy Land", "Mermaid Lagoon", "Vampire Romance", "Angel vs Devil", "Cowgirl Country", "Disco Fever",
	"Tropical Vacation", "Ballerina", "Pop Star Concert", "Barbiecore", "Emo Night", "Grunge 90s",
	"Preppy School", "Villain Era", "Superhero", "Ice Queen", "Fire Goddess", "Garden Party", "Tea Party",
	"Wedding Guest", "Bride", "Prom Night", "Graduation", "Birthday Queen", "Halloween Spooky",
	"Christmas Cozy", "Valentine's Date", "Spring Blossom", "Summer Festival", "Autumn Leaves", "Rainy Day",
	"Pajama Party", "Gym Rat", "Tennis Club", "Ski Trip", "Camping Trip", "Airport Outfit",
	"First Day of School", "Job Interview", "Detective Noir", "Secret Agent", "Pirate Queen",
	"Space Explorer", "Alien Invasion", "Zombie Apocalypse", "Steampunk", "Renaissance Painting",
	"Greek Goddess", "Egyptian Royalty", "Viking Warrior", "K-Pop Idol", "Harajuku", "Sweet Lolita",
	"Gothic Lolita", "Punk Rock", "Hippie 70s", "Groovy 60s", "Roaring 20s", "50s Diner", "80s Aerobics",
	"Hip-Hop 2000s", "Skater Girl", "Surfer Babe", "Farm Life", "Circus Ringmaster", "Magician",
	"Fortune Teller", "Movie Star", "Model Off Duty", "Influencer", "Soft Girl", "E-Girl", "Clean Girl",
	"Coquette", "Balletcore", "Mob Wife", "Coastal Grandmother", "Quiet Luxury", "Maximalist", "Minimalist",
	"Monochrome Pink", "Neon Night", "Metallic Chrome", "Crystal Couture", "Denim on Denim", "Leather & Lace",
	"Animal Print", "Polka Dots", "Plaid Everything", "Tie Dye", "Pearls & Diamonds", "Rainbow Pride",
	"Under the Sea", "In the Clouds", "Enchanted Forest", "Desert Mirage", "Starry Night", "Moon Goddess",
	"Sun Goddess", "Your Zodiac Sign", "Your Favorite Food", "Dessert Fashion", "Bubble Tea", "Chef Couture",
	"Flight Attendant", "Rich Heiress", "Thrift Store Queen", "Opposite Day", "Fairy Tale Twist",
	"Anime Protagonist", "Video Game Hero", "Cartoon Character", "Toy Doll", "Paris Fashion Week",
	"Tokyo Street Style", "London Rain", "Hawaiian Luau", "Carnival Rio", "Bollywood Glam",
}
local adjectives = {
	"Pastel", "Neon", "Royal", "Midnight", "Crystal", "Golden", "Silver", "Velvet", "Satin", "Cosmic",
	"Vintage", "Futuristic", "Glitter", "Candy", "Frozen", "Tropical", "Gothic", "Dreamy", "Sunset", "Cherry",
	"Lavender", "Rose", "Ocean", "Forest", "Desert", "Arctic", "Electric", "Holographic", "Chrome", "Pearl",
	"Ruby", "Emerald", "Sapphire", "Honey", "Cotton Candy", "Starlight", "Moonlit", "Autumn", "Spring", "Summer",
}
local characters = {
	"Princess", "Diva", "Queen", "Idol", "Witch", "Fairy", "Angel", "Mermaid", "Goddess", "Pop Star",
	"Model", "Heiress", "Ballerina", "Cowgirl", "Detective", "Pirate", "Astronaut", "Vampire", "Sorceress",
	"Bride", "Rockstar", "Skater", "Mafia Boss", "Tea Party", "Gala",
}

local themes, seen = {}, {}
local function add(t)
	if not seen[t] and #themes < 1000 then
		seen[t] = true
		table.insert(themes, t)
	end
end
for _, t in curated do
	add(t)
end
-- deterministic interleave so combos feel varied
local i = 0
while #themes < 1000 do
	local a = adjectives[(i % #adjectives) + 1]
	local c = characters[((i * 7 + i // #adjectives) % #characters) + 1]
	add(a .. " " .. c)
	i += 1
	if i > 5000 then
		break
	end
end
return themes
