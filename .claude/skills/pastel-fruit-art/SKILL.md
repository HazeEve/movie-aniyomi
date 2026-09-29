---
name: pastel-fruit-art
description: Create art in a soft, hand-painted pastel 3D style (chunky rounded forms, no outlines, 3-tone warm/cool painted shading, fully matte, simple cut-face details, dark navy ground), first as a 2D digital drawing and then as 3D models. Works for any subject (fruit, food, desserts, props, objects, nature) and any colour. Use when the user asks for "this style" of fruit/food/object art, stylized painted 3D assets, cute low-detail 3D food, a concept sheet then 3D model, or a Blender/three.js version of this look.
---

# Pastel Painted Art: 2D drawing → 3D model

Reproduces the look of the reference fruit sheet: whole objects plus their halves and slices, chunky toy-like forms, soft painted shading with no outlines and no gloss, on `#232b3d`.
It is **not limited to fruit or to the fruit palette**. Any hex colour is auto-toned, and the builders cover food, props and nature too.

Read `references/style-guide.md` before designing anything new. It holds the rules (form, shading, colour maths, finishes, and which shape builder fits which subject).
Example outputs are in `examples/`: `2d-concept-sheet.png`, `3d-fruit.png`, `3d-food.png`, `3d-materials.png` and `blender-demo.png`.

## Files

| file | role |
|---|---|
| `scripts/paint.js` | **2D drawing layer.** `paintShape()` brush, `tone()` any-colour → triad, path helpers, motif painters (seeds, leaves, citrus/kiwi/melon/pome cross-sections). |
| `scripts/profiles.js` | Shared lathe profiles. One profile drives both the 2D outline and the 3D lathe. |
| `scripts/concept-2d.html` | Example 2D concept sheet built with paint.js. |
| `scripts/painted3d.js` | **3D layer.** Painted unlit shader, `FINISH` presets, `mat()`, and builders: `lathe`, `latheHalf`, `domeHalf`, `wheel`, `slab`, `sweep`, `blob`, `lump`, `gem`, `stem`, `leaf`, `stage`. |
| `scripts/sets/{fruit,food,materials}.js` | Demo sets. Copy one as a template for new subjects. |
| `scripts/scene-3d.html` | Loader: `?set=fruit\|food\|materials`, `?bg=%23hex`, `?static`. |
| `scripts/render.mjs` | Headless PNG render (Playwright + Chromium). Works in Claude Code cloud sessions. |
| `scripts/blender_painted.py` | Same shader as Blender emission nodes, plus `tone()`, `lathe()`, `blob()`, `torus()`, `gem()` and `stage()`. |

## Workflow

1. **Understand the subject.** For each object, list the variants the reference style calls for (whole, half, slice or wedge) and 1–2 signature motifs (seeds, segments, stripes, sprinkles). Pick base colours freely, and pick a finish per surface (see the style guide). Everything is matte.
2. **Draw in 2D first.** Copy `concept-2d.html` to a new page. Block each silhouette as a profile (`[radius, height]` list) or a point list, fill it with `paintShape(ctx, path, '#anyhex', box)`, and add motifs with the helpers. Render it and check it against the style rules before modelling:
   ```bash
   cd .claude/skills/pastel-fruit-art/scripts
   node render.mjs my-sheet.html out/my-sheet.png
   ```
3. **Model in 3D.** Create `sets/<name>.js` exporting `build(place)`. Reuse the **same** profiles and points with the builders. Paint cut faces and labels as canvas textures using the same paint.js painters (`latheHalf(profile, skin, pomeCap(skin, flesh, 'seeds'))`, `wheel(side, (ctx,x,y,r)=>citrusSlice(...))`, `slab(pts, drawFace, sideColor)`). Arrange the pieces in rows with `place(obj, x, y, scale, rotY)`. The frame is about ±9.5 horizontally and ±5 vertically.
4. **Render and compare.**
   ```bash
   node render.mjs 'scene-3d.html?static&set=<name>' out/<name>.png
   ```
   Look at the PNG and fix things in this order: proportions and chunkiness, then colour (tweak the base hex, or pass an explicit triad), then motif spacing. Repeat until it reads like the reference.
5. **Deliver.** Send the 2D sheet and 3D renders. The interactive page (`scene-3d.html?set=<name>`, with a gentle turntable wobble) can be published as an artifact. If the user uses Blender, give them `blender_painted.py` and show how to call `painted_material(name, '#hex', finish)` on their own meshes.

## Hard rules (these make it "the exact style")

- No outlines and **no specular highlights or gloss**. Shiny materials use the `hard` finish and a cooler base colour instead.
- Light always comes from the top-left-front. Shadows are cooler and never black; lights are warmer and never white. Use `tone()`.
- Forms are chunky and rounded. Exaggerate thickness (slices are thick, stems stubby, leaves plump).
- Cut faces are nearly flat colour (`flat` finish), lighter than the skin, with a thin skin rim.
- Keep detail sparse and evenly spaced. Keep the ground flat (`#232b3d` default).
- Do **not** restrict colours to `P`. `P` is only the reference fruit palette, and any hex is valid.

## Environment notes

- three.js loads from jsdelivr via an importmap. If the headless browser can't reach the CDN, run `npm i three@0.170.0` in a scratch directory and set `THREE_MODULE=<that dir>/node_modules/three/build/three.module.js` for `render.mjs`.
- Playwright and Chromium are preinstalled in Claude Code cloud sessions. `render.mjs` falls back to the global Playwright install if it isn't installed locally.
- Blender headless without installing Blender: `python -m venv v && v/bin/pip install bpy && v/bin/python scripts/blender_painted.py --out demo.png` (Python 3.11; renders with Cycles on the CPU in a few seconds).
