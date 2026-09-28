# Aura Runway City ✨

A Roblox fashion + roleplay game made entirely in code. It includes:

- **Catalog avatar creator:** search the whole Roblox catalog, try items on and take them off, buy them, and use favourites, recent, wearing and saved outfits. You can also change skin tone and body scales, undo/redo, and paste an item link.
- **Runway show (Dress To Impress style):** a random theme, a dressing timer, then each model walks the runway while everyone votes with **1–5 hearts**. Results go on a podium with coin rewards.
- **Shop the look:** tap any player (or the model on the runway) to see every item they wear, with **Buy** / **Try On** buttons and **Copy Full Look**.
- **Live auction:** a model on stage can auction a limited they own. Bids use in-game coins held in escrow, and there is anti-snipe.
- **Instruments:** guitar, piano, electric guitar, drums and violin. There are **300 chords** (12 roots × 25 chord types). You pick 3–19 chords, hold a button to sustain and release to stop. Guitar has up/down strum sliders, piano has sustain/octave/arpeggio and a keyboard, electric has drive/power/mute, violin has a bow pad, and drums have 9 pads with hold-to-roll. Other players hear you, and you're louder on stage.
- **Stage:** built like the concert-stage reference: galaxy LED walls, truss rigging with moving beams that chase the model, speaker stacks and neon stairs. A long rounded runway leads out from it. Velvet seats face the runway from the **left, right and front** (every seat can be sat on). There is also a backstage lounge, a winners' podium and an auction block.
- **City roleplay:** Aura Mall, Blush Café, Grand Hotel, Boutiques, Glow Salon, Petal Florist, Fountain Park, Aura Motors and Residences, plus towers, townhouses, roads, lamps and trees.
  - **Sit:** benches, sofas, café chairs, salon chairs and cars.
  - **Sleep:** beds (jump or tap *Wake Up* to get out).
  - **Eat and drink:** café, carts and kitchens.
  - **Pick up:** bags, flowers, balloons, phone, perfume and more.
  - **Drive:** spawn a car at Aura Motors, or use the cars parked around the stage.
  - **Change outfit:** mirrors open the catalog.
  - **Travel menu:** jump to any district.
  - **Hunger and energy bars.**
- **Mall stalls:** players rent a stall with coins, rename it (text is filtered), pick a colour and list **their own UGC or clothes**. Items appear on display frames and on a mannequin wearing them. Shoppers buy with the real Roblox purchase prompt. **You get a big Creator's Atelier stall.**

Everything is built from rounded, bevelled parts, so there are no meshes to upload. The palette is soft luxury: plum, champagne, blush and lavender, with neon accents on the stage.

---

## Open it (easiest)

1. On a **PC or Mac**, open **Roblox Studio**.
2. Open **`build/AuraRunwayCity.rbxl`**. The whole city is already placed and editable.
3. Press **Play** to test.
4. To keep saves, publish the game (**File → Publish to Roblox**), then turn on
   **Game Settings → Security → Enable Studio Access to API Services**. Coins, outfits, shops and presets are saved with DataStores.

## Or work with Rojo (for editing the code)

```bash
rojo serve            # live-sync src/ into Studio
rojo build -o build/AuraRunwayCity.rbxl
lune run tools/bake.luau build/AuraRunwayCity.rbxl   # optional: pre-place the world in the file
```

If the world isn't in the place file, the server builds it automatically when the game starts.

---

## Things to set

| What | Where |
|---|---|
| **Your UserId** (owner of the Creator's Atelier) | `src/shared/Config.luau` → `Config.CreatorUserId` (0 = place owner) |
| Items shown in your stall at first | `Config.CreatorStallItems = { 123, 456 }` (or add them in-game at the stall) |
| Show timings, themes, rewards | `Config.Show` |
| Stall rent price/time, "only your own UGC" rule | `Config.Stalls` |
| Auction length and increments | `Config.Auction` |
| **Instrument sounds** | `src/shared/Instruments.luau` (see below) |

### Instrument sounds (one upload)

All instrument sounds were **synthesized from scratch** for this game, so you own them. They are a concert grand piano, acoustic and electric guitar (physically-modelled strings), violin with vibrato and a sustaining bow, and a 9-piece drum kit. Everything is packed into **one file**: `build/AuraSoundPack.ogg` (0.9 MB, 41 samples).

1. Go to **create.roblox.com → Creations → Development Items → Audio → Upload Asset** (or use **Asset Manager → Import** in Studio) and upload `build/AuraSoundPack.ogg`.
2. Copy its ID and paste it in `src/shared/Config.luau`:
   `Config.SoundPackId = "rbxassetid://YOUR_ID"`. In the `.rbxl`, that's **ReplicatedStorage → Shared → Config**.
3. That's it. Every chord, strum, bow and drum hit plays from slices of that one sound, pitch-shifted note by note.

You can regenerate or tweak the sounds with `python tools/make_soundpack.py`. It rewrites the `.ogg` and `src/shared/SoundPack.luau`, which maps each slice. To use your own samples instead, fill `Samples` in `src/shared/Instruments.luau`; those take priority.

**Music features:**
- Pick 3–19 chords from all 300. The chord picker shows each chord's notes and lights them on a preview keyboard.
- The piano has a 5-octave keyboard that **lights up the notes you play**. It also has inversions, octave shift, a sustain pedal, arpeggio, and a playable Keys mode.
- **▶ Auto** plays your chord progression with a pattern at any BPM:
  - Piano: Block, Arp Up, Alberti, Waltz, Ballad
  - Guitar: Strum, Down 4, Fingerpick, Island
  - Electric: Power 8ths
  - Violin: Long Bow, Pulse
  - Drums: Pop, Rock, Hip-Hop, Disco and Waltz beats

---

## Honest limits (Roblox rules)

- **Auctions:** games cannot move limited items or Robux between players. The auction handles bidding with in-game coins (escrow, refunds, anti-snipe) and announces and logs the winner. The seller then sends the item through Roblox's **Trade** feature.
- **Stall sales** use the real Roblox purchase prompt. The item's creator earns the Robux as usual. By default players can only list items **they or their group created**. Set `Config.Stalls.RequireCreator = false` to allow any on-sale item.
- **Catalog try-on** works for any catalog item in-game. Buying opens Roblox's official purchase prompt.

## Controls

- **Dock (left):** 👗 Catalog · ✨ Join/Leave Show · 🎸 Music · 🔨 Auction · 🗺️ Travel
- **Tap or click a player:** Shop the Look
- **Cars:** sit in the driver seat, then WASD or the thumbstick; jump to exit
- **Beds:** press E / tap the prompt to sleep; jump to wake
- **Tools:** click or tap to use (eat, sip, spritz, selfie); Backspace to drop

## Code map

```
src/shared/     Config, Palette, Chords (300 chords + voicings), Instruments, AvatarTypes, Remotes
src/server/     Main.server.luau
  World/        Build (bevel toolkit), Stage, City, Mall (stalls), Places (RP districts), Rooms, CarModel, Screens
  Services/     Data, Avatar, Show (hearts voting), Auction, Stall, Music, RP, Vehicle, ToolFactory, Util
src/client/     Main.client.luau, UI toolkit, State, MusicEngine
  Controllers/  HUD, Catalog, Show, Look, Music, Auction, Stall, RP, StageFX, Notify
tools/bake.luau Lune script that pre-places the generated world in the .rbxl
```
