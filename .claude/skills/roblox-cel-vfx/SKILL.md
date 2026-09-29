---
name: roblox-cel-vfx
description: Make clean, shiny, cel-shaded anime-style VFX for Roblox, meaning flipbook sprite sheets (hard-edged tones, white-hot core, glow halo), beam rings plus a ParticleEmitter module that assembles them into auras, bursts and ability effects and recolours them per item. Use when the user wants Roblox VFX, auras, flipbooks, particle effects, "stylized/anime/toon VFX", effects for eating/drinking/abilities, or recoloured variants of effects without extra uploads.
---

# Roblox cel-style VFX: flipbooks + auras

Produces stylized (toon / anime) effects the way Roblox VFX artists build them: a few **flipbook sprite sheets**, and many effects built from them as layered ParticleEmitters. Colour comes from `ParticleEmitter.Color`, so variants cost **no extra uploads**.

## The look (hard rules)
- **Shiny comes from additive light, not the texture.** Textures are white/grey: core 1.0, mid 0.62, outer 0.34, plus a **soft glow halo** (a blurred alpha at about 40%). In Roblox set `LightEmission = 1`, `LightInfluence = 0`, `Brightness` 2–4 and tint with `Color`. The core then blows out to white-hot and the rim and halo glow in colour. A Bloom effect in Lighting pushes it further.
- **Clean strokes:** render at 4× and downsample (LANCZOS). Use tapered brush streaks (thick head, long thin tail) with a **white highlight line** inside.
- **Cel shapes:** 3 hard-edged tones with loopable-noise breakup, and detached flicks toward the tips.
- **Rings are Beams, not particles.** Use 4 quarter-circle Beams per ring (Bezier handles = 0.5523·r), `FaceCamera`, and a horizontally wrapping streak texture scrolled with `TextureSpeed`. Leave gaps between streaks so the ring reads brushy, not solid. Stack rings at different heights, sizes, tilts and spin directions for the tornado look (no centre orb unless asked).
- **Structure from layers:** a glow orb behind, then the base (fire, rings, bubbles), then accents (wisps, sparkles), then a one-shot burst (impact ring with speed spikes).
- **Always preview additively:** composite with add + bloom + a soft tone-map. An alpha-over preview looks flat and is not what Roblox shows.

## Files
| File | Role |
|---|---|
| `scripts/make_flipbooks.py` | Draws 1024² sheets of 4×4 frames (`FlipbookLayout = Grid4x4`) with numpy. The designs are Flame, Swirl, Wisp, Sparkle, Bolt, Impact, Bubbles, Puff and Glow, plus the `Streak` beam texture. Every shape gets the glow halo, and loop designs use integer time speeds so they tile perfectly. |
| `scripts/preview_auras.py` | Additive 2D sim with bloom, using the real sheets and the same layer settings, and beam rings drawn in 3D (back half behind the player). It writes a GIF before anything is uploaded. |
| `scripts/AuraVFX_template.luau` | Roblox module: layer defs → additive ParticleEmitters (flipbooks, bursts via `:Emit`) and beam rings, plus presets, tier extras, palette-from-any-colour, `Play` / `Stop`. |

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
