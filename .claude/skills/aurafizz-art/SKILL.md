---
name: aurafizz-art
description: Make 2D game art for the Aura Fizz Roblox cooking game in its one approved style (the cozy hand-painted cel look of reference/style_reference.png, like Good Coffee Great Coffee): station scenes, station parts, cups, bottles, pumps, tools, ingredients, cut pieces and liquids. Use whenever the user asks for Aura Fizz images, assets, sprites, sheets, prompts, cut-outs, or "this style"; also to cut, name, colour-match or check generated images. When no image generator is available, draw it with the painted-2d-illustration skill, never with plain flat shapes.
---

# Aura Fizz art

One job: every image must look like it was painted for `reference/style_reference.png`.
The user rejected everything else (code-drawn SVG/Blender shapes, pastel themes, side views,
sticker sheets with faces). Read this whole file before making any image.

## 1. The style (measured from the reference)

- **Look:** cute cozy 2D hand-painted cel-shaded mobile cooking game art, like Good Coffee Great Coffee.
- **Outlines:** bold, clean, dark espresso brown `#382619` (never pure black), about 3 px at 1536 px wide, rounded line ends.
- **Shapes:** chunky, rounded, slightly squat and cute; simple readable silhouettes; no tiny fussy detail.
- **Shading:** soft cel shading, 2–3 tones per material plus one soft white highlight; glass gets diagonal white highlight streaks.
- **Light:** warm lamp light from the upper left; whites read warm cream, blacks read warm near-black `#393331`.
- **Palette (by area):** near-black `#393331`, warm tan `#cc9e75`, brick red `#884233`, light tan `#dcb895`, cream `#f7e6c1`,
  chocolate `#683827`, caramel `#b2865e`, charcoal `#524d4c`, deep espresso `#231b17`, bronze `#9e7044`, porcelain `#f4f3ea`, orange accent `#d87a25`.
- **Stations:** matte black with thin gold trim, gold knobs and handles, cream marble counter with gold edge.
- **Camera:** straight-on FRONT view only, never side or three-quarter views.
- **House rules from the user:** toppings and sugar sit in clear square acrylic containers (gelato style); whipped cream comes from a
  dispenser bottle, never a tub; cream stays inside the cup rim; cups are drawn empty (drinks are colour layers added later);
  no faces or eyes on objects; no text, labels or numbers.
- **Scenes:** the user already has the backgrounds (peach plank wall, red curtains, two black pendant lamps, fairy lights, black
  wall shelves with jars, chalkboard, hanging pothos, gold arched rainy window, cream marble counter over black-and-gold cabinets).
  Only objects that go ON that counter are needed now.

The user also approved assets made from the batch prompts (sent in chat as screenshots; save them to `reference/approved/`
when the user sends them as files): a coffee machine with every part separate, an empty cup rack and fridge with a separate
drawer and door, and a chest freezer with the lid and pantry cabinet parts. Their traits: plain flat cream background, objects well
spaced, rounded corners, warm brown outlines, soft gradients, gold accents.

## 2. What to make (the asset list)

`AuraFizz/art/tripo/batches.json` holds the full list: 79 batches, 564 objects in five steps (empty stations with their
moving parts drawn separately → materials → ingredients as stored → cut and prepared pieces → liquids). Each batch has
`codes` (file names, in reading order) and a ready `prompt` with the style written in. `AuraFizz/art/tripo/build.py`
regenerates it from the ingredient data; the user-facing copy page is `AuraFizz/art/tripo/tripo_batches.html`
(published at https://claude.ai/artifact/9zyGZ2vSFbmadKvDV6niKC).

Batch rules that fixed earlier failures:
- At most 8 small objects per 16:9 image, 4 tall ones in one row.
- Never put a whole station and its loose part in the same image if the part could be mistaken for a whole object;
  describe parts as "alone" and "the X's door/lid", or put them on their own image.
- Always say EMPTY for cups, shelves, pots, jars meant to be filled later.

## 3. Generating (pick the first route that works)

Always give the generator the style reference image. Prompt = the batch prompt from `batches.json`, prefixed with:
"Use the attached image only as the ART STYLE reference: copy its exact outline weight, cel shading, warm lamp lighting,
colours and cute chunky shapes. Do NOT copy its scene, wall, counter or objects. Draw a completely new image: "

1. **Hugging Face via the Qwen_Image connector (best quality, Claude runs it):**
   `mcp__Qwen_Image__gr5_qwen_edit_image_api_predict` with
   `image` = `https://raw.githubusercontent.com/HazeEve/movie-aniyomi/claude/gallant-lovelace-tp39bm/.claude/skills/aurafizz-art/reference/style_reference.png`
   (any pushed branch works; the repo is public), `preserve_identity=false`, `output_size=1536`, `guidance_scale=2.5`, `steps=8`.
   Save the result from the tool-results path, then run `take.py`. Free ZeroGPU quota is about 1 image a day at these settings
   (`steps=4, guidance 1, output_size 1024` squeezes in when little quota is left, at lower quality); PRO gives 40 min a day.
   On "ZeroGPU quota exceeded", stop and tell the user the reset time from the error. Other ZeroGPU Spaces share the same quota.
2. **Google Colab notebook (free GPU, the user runs it):** `AuraFizz/art/colab/AuraFizz_Generate.ipynb`, FLUX.2 Klein 4B
   loaded in 4-bit so it fits free Colab, reference image attached, loops over the batches. Open link:
   https://colab.research.google.com/github/HazeEve/movie-aniyomi/blob/claude/gallant-lovelace-tp39bm/AuraFizz/art/colab/AuraFizz_Generate.ipynb
   Not yet confirmed working; if the user reports an error, ask for the last lines of the red text and fix the notebook.
3. **Chat image tools the user runs (free daily limits):** Gemini (Nano Banana) first, then ChatGPT, then Microsoft Designer.
   All accept the reference image. Tripo worked well while it had credits. Canva ignores long prompts: use the page's
   "Canva (one object at a time)" mode there.

Network note: this container cannot reach outside image APIs directly (proxy 403); only the MCP connectors work.

### How each generator wants to be prompted

- **Qwen-Image-Edit (2509/2511):** an instruction model. Start with a verb ("Replace the whole picture with a new image drawn
  in exactly the same art style…"), then list objects as `(1) …; (2) …`. Guidance 2.5 with 8 steps follows the list far better
  than the 1.0 / 4-step default. It obeys "EMPTY", "alone", "no wall, no counter". Spelling out "dark warm-brown outlines"
  fixed its default black outlines; "pure white porcelain" and "clear glass tinted light blue-grey" stopped beige drift.
  If it supports a second image (`image2`), pass the reference there and a blank cream canvas as `image`.
- **FLUX.2 Klein / FLUX Kontext:** plain descriptive sentences, style words first, then the objects. Distilled: 4 steps,
  guidance 1.0. Accepts several reference images; more approved assets as references means a closer match.
- **Z-Image-Turbo (text only, no reference input):** good for quick tests only; style must be carried by words, so it drifts.
- **Gemini (Nano Banana) / ChatGPT:** chat models keep context. In ONE conversation, first attach the reference and say
  "Study this art style. Every image I ask for next must use exactly this style." Then paste one batch per message and ask for
  16:9. Start a new chat if it begins copying the previous picture.
- **Canva Magic Media:** short single-object prompts only; long lists produce invented shelves, walls and text.
- **Any generator:** name the object count, say "plain flat cream background" and "not touching", and ban faces/text.
  Two tries per batch and picking the better one is cheaper than fixing a bad sheet.

## 4. After every generated image

```bash
python3 .claude/skills/aurafizz-art/scripts/take.py <batch number> <image.png>
```
It saves the sheet, cuts every object to a transparent PNG named by its code (`scripts/cut.py`: flood-fill from the border,
keeps light glass and white porcelain, removes handle holes, no halo), runs `scripts/style_match.py` on each cut-out, and
writes `/tmp/take_preview.png`. Look at the preview, then check against the reference:

- [ ] outlines dark brown and bold, not thin or black
- [ ] front view, chunky cute shapes
- [ ] right object count; no object turned into a different or whole object
- [ ] empty where it should be empty; no faces, text or labels
- [ ] colours warm like the reference (style_match handles small drift)

A "found N objects, expected M" warning means objects touched or one was missing: regenerate that batch, or split it.
Commit and push every finished sheet and cut-out right away (the container is temporary).

`style_match.py` only nudges an image toward the reference (warm neutrals, saturation, brown outlines, lamp light).
It cannot repaint a flat or off-style image; regenerate those instead.

## 5. Teaching a generator the style for real (LoRA)

The strongest fix for drift is a style LoRA trained on approved images. `lora_dataset/` holds 16 captioned crops of the
reference (trigger words `aurafizz style`). Add every approved sheet's cut-outs (20–40 images total is the goal) with captions
in the same format, then train a FLUX.2 Klein 4B or Qwen-Image LoRA (Colab with a trainer such as ai-toolkit, or a hosted
trainer). Once trained, put the LoRA in the Colab notebook and say so here.

## 6. Things that failed (do not repeat)

- Flat code-drawn art (plain SVG shapes, Blender toon renders): "sticks and shapes", rejected. Code drawing is only acceptable when it follows `.claude/skills/painted-2d-illustration`.
- Pastel redesigns, side views, sticker sheets with faces.
- One prompt with a station AND its parts: the generator drew extra whole furniture.
- Long many-object prompts in Canva: it invents shelves, walls and text.
- Asking any generator without the reference image: the style drifts.
