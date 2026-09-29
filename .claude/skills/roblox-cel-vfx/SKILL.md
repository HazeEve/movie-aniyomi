---
name: roblox-cel-vfx
description: Make cel-shaded anime-style VFX for Roblox, meaning flipbook sprite sheets (hard-edged flat tones, white-hot core, no gradients) plus a ParticleEmitter module that assembles them into auras, bursts and ability effects and recolours them per item. Use when the user wants Roblox VFX, auras, flipbooks, particle effects, "stylized/anime/toon VFX", effects for eating/drinking/abilities, or recoloured variants of effects without extra uploads.
---

# Roblox cel-style VFX: flipbooks + auras

Produces stylized (toon / anime) effects the way Roblox VFX artists build them: a few **flipbook sprite sheets**, and many effects built from them as layered ParticleEmitters. Colour comes from `ParticleEmitter.Color`, so variants cost **no extra uploads**.

## The look (hard rules)
- **Cel tones, not gradients.** Every design uses 3 flat tones with hard edges: outer 0.50 grey, mid 0.76, core 1.0 white. There is no soft blur.
- **Draw in grayscale and tint in Roblox.** White becomes the tint colour. Use `LightEmission` 0.6–1 and `Brightness` 1.5–4 so the core blows out toward white-hot.
- **Break-up and flicks.** Shapes are distorted by loopable noise, and detached blobs appear toward the tips (see `flame()`).
- **Top-left light** on solid shapes like puffs, the same as the pastel painted style.
- **Structure from layers:** a base shape (flame, rings, bubbles), plus accents (wisps, sparkles), plus a one-shot burst (shockwave, puffs).

## Files
| File | Role |
|---|---|
| `scripts/make_flipbooks.py` | Draws 1024² sheets of 4×4 frames (`FlipbookLayout = Grid4x4`) with numpy. The designs are Flame, Swirl (top-view brush rings), Wisp, Sparkle, Bolt, Shockwave, Bubbles and Puff. Loop designs use integer time speeds so they tile perfectly. |
| `scripts/preview_auras.py` | 2D particle sim that uses the real sheets and the same layer settings, and writes a GIF preview before anything is uploaded. |
| `scripts/AuraVFX_template.luau` | Roblox module: layer defs → ParticleEmitters (flipbook mode, flat rings via `VelocityPerpendicular`, bursts via `:Emit`), presets, tier extras, palette-from-any-colour, `Play` / `Stop`. |

## Workflow
1. **Pick the structures** from the user's references (e.g. rings with no centre orb, a fire aura, or a burst) and list the designs they need. Reuse the 8 designs where you can.
2. **Draw the sheets:** `pip install numpy pillow`, then `python3 scripts/make_flipbooks.py`. Look at `preview/contact_sheet.png`. If a shape reads badly, tune its function (thresholds in `cel()`, noise amplitude, sizes) and re-run. New design = a new function `fn(i) -> (tone, alpha)` added to `DESIGNS`.
3. **Assemble the effects** as layers in the module: `where` (Body / Feet / Waist / Chest), `rate` or `burst`, `life`, `size` (3 keys), `speed`, `spread`, `flat`, `once` (OneShot flipbook) and `tint` (main / light / dark / gold). Group the layers into presets.
4. **Preview:** `python3 scripts/preview_auras.py` renders every preset as a GIF. Mirror any layer changes into its `LAYERS` table.
5. **Recolour per item:** map item → preset (by category) and colour (the item's own colour → `palette()` makes it vivid, with light, dark and gold variants). Tiers add extra layers (lightning, gold sparkles).
6. **Deliver:** the PNG sheets to upload, the module (or a Command Bar installer that keeps any pasted texture IDs), and the preview GIF.

## Roblox notes
- Max texture 1024². `Grid4x4` gives 16 frames of 256 px. Use `Grid8x8` for longer loops at 128 px.
- `FlipbookMode.Loop` + `FlipbookStartRandom` suits continuous effects. Use `OneShot` so the frames span each particle's lifetime (bursts, sparkles, wisps).
- Flat rings on the ground: set `Orientation = VelocityPerpendicular` with a tiny upward `Speed` (0.01) and zero spread.
- Create effects on the **server** so they replicate. Clean up with `Enabled = false`, then destroy after the longest lifetime.
- Before textures are uploaded, fall back to a built-in texture so the code still runs.
