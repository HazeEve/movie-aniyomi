# Pastel Painted Style — Style Bible

Distilled from the reference fruit sheet (whole fruit and cut pieces on a dark navy ground).
Applies to **any subject** (fruit, food, props, nature, objects) and **any colour**.

## 1. What makes it look like this

| Trait | Do | Don't |
|---|---|---|
| **Form** | Chunky, rounded, slightly squashed. Wide shoulders, soft dimples, stubby stems. Think toy or clay. | Realistic proportions, thin parts, sharp corners. |
| **Edges** | No outlines. Silhouettes separate from the background through value alone, with a slightly darker rim. | Ink lines, strokes, cel outlines. |
| **Shading** | 3 tones: **shade → base → light**, blended softly. Light always from the **top-left-front**. | Hard 2-step cel shading, cast shadows, ambient occlusion blackness. |
| **Surface** | Fully **matte**, with faint low-contrast "brush blotches" of the light and shade tone. | Specular highlights, reflections, gloss dots, rim lights. The style has none, even on "shiny" things. |
| **Colour** | Warm, saturated-but-soft mid-tones. Shadows shift **cooler** (toward blue-violet), lights shift **warmer** (toward yellow). | Black shadows, white highlights, grey desaturation. |
| **Cut faces** | Nearly flat colour, lighter than the skin. A thin skin-coloured rim, pale inner rings, simple teardrop seeds and radial segments. | Photoreal pulp and fibre detail. |
| **Detail** | 1–2 motifs per object (seeds, segments, stripes, sprinkles), simplified and evenly spaced. | Noise-heavy texture, many small details. |
| **Composition** | Rows of whole object + half + slice variants, evenly spaced on a flat dark ground (`#232b3d`). | Busy backgrounds, perspective scenes, props overlapping heavily. |

## 2. Colour: any hex works

You are **not** limited to the fruit palette. `tone(hex)` (in JS `paint.js`, and in Python `blender_painted.py`) derives the triad:

- **shade**: hue moved up to 10° toward 245° (blue-violet), saturation ×0.88, lightness −(0.12 + 0.05·(1−L)), never below 60% of the base lightness (so it never turns black)
- **light**: hue moved up to 8° toward 55° (warm yellow), lightness + min(0.10, (0.97−L)/2)
- **greys**: the shadow gets a slight cool tint (hue 230) and the light a slight warm tint (hue 50)

Hand-tuned triads in `P` (paint.js) are only the reference fruit colours. Pass any `'#rrggbb'` anywhere a colour is expected.
If a result looks too hot or too dull, pass a triad `{base, shade, light}` yourself.

Background: `#232b3d` by default. Light grounds also work (`?bg=%23f4efe6`). Keep the ground flat.

## 3. Finishes (the material, separate from the colour)

All finishes are matte. They differ only in brush noise and how soft the shadow edge is.

| finish | noise | ramp edge | use for |
|---|---|---|---|
| `matte` | 0.16 | 0.18–0.62 | most fruit, clay, paper, wood, ceramics |
| `fuzzy` | 0.32 | 0.10–0.70 | peach, kiwi, fabric, felt, plush |
| `rough` | 0.45 | 0.20–0.60 | stone, bark, bread crumb, rice |
| `smooth` | 0.07 | 0.20–0.60 | icing, candy, glaze, plastic, waxy skins |
| `hard` | 0.05 | 0.36–0.54 | metal, glass, gems, anything "shiny" |
| `flat` | 0.05 | flattened | painted cut faces, labels, decals |

To show "shiny" (metal, glaze), use a cooler, greyer base colour plus the `hard` finish. **Do not add a highlight.**

## 4. Shape recipes (subject → builder)

| Subject kind | Builder | Examples |
|---|---|---|
| Round and symmetric | `lathe(profile)` | apple, pear, pot, mug, cupcake liner, mushroom cap, vase, bottle |
| Cut lengthwise | `latheHalf(profile, skin, drawCap)` | apple/pear/peach/avocado halves |
| Cut across | `domeHalf(skin, drawCap)` | citrus half, kiwi half, cake dome, egg half |
| Round slice | `wheel(side, drawCap)` | fruit wheels, cookies, log ends, coins, pepperoni |
| Flat shape with thickness | `slab(pts, drawFace, sideColor)` | watermelon wedge, cheese, pizza, toast, sushi topping, leaf-shaped things |
| Along a curve | `sweep(points, radius(t), color(t))` | banana, croissant, sausage, churro, handles, tails |
| Organic lump | `lump(color, amt)` | rocks, potatoes, bread rolls, bushes, clouds, ice-cream scoops |
| Ball / ellipsoid | `blob(color, sx, sy)` | berries, oranges, macaron shells, cushions |
| Faceted | `gem(color)` or `lump(..., {faceted:true})` | crystals, low-poly rocks |
| Ring | `THREE.TorusGeometry` + `mat()` | donuts, bagels, rims, frosting swirls |

Profiles are `[radius, height]` pairs from bottom to top, about 1 unit tall. The **same profile** drives both the 2D outline (`profileOutline`) and the 3D lathe. This is what keeps the drawing and the model matching.

## 5. Drawing → model workflow

1. **Draw** (paint.js, Canvas 2D): block the silhouette as a profile or point list. Fill it with `paintShape(ctx, path, colour, box)` and add motifs (seeds, segments, stripes). Iterate on this concept sheet first; it is cheap.
2. **Model** (painted3d.js): turn the same profile or points into geometry with the builders above. Every painted surface (cut faces, labels, stripes, waffle patterns) is a **Canvas texture drawn with the same paint.js functions**, so 2D and 3D share one look.
3. **Shade**: `mat(colour, {finish})` applies the painted unlit shader. Nothing else is needed: no lights, no post-processing.
4. **Render**: `node scripts/render.mjs 'scene-3d.html?static&set=<name>' out.png`. Compare against the reference and tweak proportions first, colour second.
5. **Blender (optional)**: `blender_painted.py` rebuilds the same shader as emission nodes (works in Cycles and EEVEE). Use `painted_material(name, '#hex', finish)` on any mesh.
