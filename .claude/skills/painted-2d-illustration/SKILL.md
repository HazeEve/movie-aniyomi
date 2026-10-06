---
name: painted-2d-illustration
description: Construct 2D game artwork with code (SVG, HTML/CSS, Canvas, layered shapes, gradients, masks, filters, generated textures) that must look like a professionally hand-painted cozy casual-game illustration, never a flat vector icon, sticker, logo or diagram. Use whenever an image must be drawn without an image generator, including Aura Fizz assets when no generator quota is available, or when the user asks Claude itself to draw, paint or make an image.
---

# Painted 2D Game Illustration

## Purpose

Construct 2D illustrated game artwork with procedural, vector or shape-based methods when an image generator is not available.
The result must look like a professionally painted 2D game illustration, not a generic SVG, flat vector icon, technical diagram,
logo or simple cartoon.

Allowed tools: SVG, HTML/CSS, Canvas, procedural shapes, gradients, masks, filters, layered vector paths, generated textures,
hand-built highlights and shadows. The technology is secondary; the rendered appearance must feel painted.

## Tools in this skill

- `scripts/render.mjs`: renders an SVG or HTML file to PNG with the pre-installed Chromium at 2x supersampling.
  `node render.mjs art.svg out.png 1024 1024 2` (run from a folder where `playwright` is installed; never run `playwright install`).
- `scripts/paint_kit.svg`: ready `<defs>`: grain, brush blotch texture, hand-wobble edges, three shadow softnesses, lamp glow,
  warm contact shadow. Copy the pieces you need.
- Workflow: write the SVG in layers (order in section 22) → render → look at the PNG → run the quality check (section 24) →
  refine → render again. Judge only the rendered PNG, never the code. Keep each object in its own `<g id>` so moving parts can be
  exported separately for animation.
- For Aura Fizz, also follow `.claude/skills/aurafizz-art/SKILL.md` for the palette, front view and house rules.

## 1. Core visual target

cozy + polished + dimensional + painterly + warm + handcrafted + soft + game-art quality.
"A beautiful 2D casual/cozy game asset that looks hand-painted digitally." Not a clean vector illustration, not a flat SVG icon,
not a logo, not a photorealistic 3D render. It should have the visual richness of a professionally illustrated casual game.

## 2. Vector construction is not vector style (most important rule)

Shapes may be used to build the image, but the final look must not expose the vector construction. Avoid:
uniform thick outlines, perfectly clean geometric borders, large flat colour regions, identical edge treatment everywhere,
sticker-like highlights, simple two-tone shading, excessive symmetry, icon-like appearance, hard graphic shadows,
isolated objects floating on empty backgrounds. The viewer should think "this looks painted", not "this is an SVG".

## 3. Form construction

Build every major object from layers, roughly: main silhouette → secondary silhouette variation → base material colour →
large lighting gradient → ambient light → contact/occlusion shadows → reflected light → material variation → small surface
details → soft highlights → final accent highlights → cast shadow. Never one fill plus one shadow. Objects need physical volume.

## 4. Painterly colour model

No pure flat colours. A surface = base + light region + midtone + shadow region + reflected light.
Example, not "coffee machine = dark brown" but: deep brown shadow → warm brown body → slightly lighter brown planes →
warm reflected light → soft golden highlights → very dark contact areas. Transitions mostly gradual: gradients plus overlapping
semi-transparent shapes.

## 5. Lighting

The art must feel lit by a warm environment. Prefer large soft light sources, warm ambient light, gentle gradients, bounced
and reflected light, soft contact shadows, local highlights, atmospheric background light. Avoid one hard spotlight, one simple
drop shadow, pure white highlights everywhere, identical lighting on every object, sharp digital gradients, light that looks
pasted on. One light environment affects the whole scene.

## 6. Materials must look different

- **Metal:** dark reflected areas, narrow soft highlights, subtle warm reflections, controlled contrast. Not grey + white highlight.
- **Ceramic:** soft rounded gradients, warm reflected light, subtle edge highlights, gentle imperfections.
- **Glass:** transparent overlapping tones, edge highlights, internal reflections, soft transparency, visible contents.
- **Wood:** warm colour variation, subtle grain, darker seams, soft highlights, imperfect tones.
- **Fabric:** soft folds, broad gradients, subtle texture, low-contrast shadows.
- **Food:** irregular silhouettes, warm tonal variation, small highlights, subtle texture, appetizing colour transitions.
  Never geometric blobs.

## 7. Outlines

Do not outline every shape; that is the main cause of the generic vector look. Use outlines selectively: vary thickness, keep
them subtle, dark brown/charcoal rather than black, let light soften them, let some edges disappear into shadow. Many edges should
be defined by contrast, shadow, highlight or colour separation instead.

## 8. Edge variation

- **Hard edges:** important silhouette boundaries, mechanical parts, focal details.
- **Soft edges:** shadows, light transitions, rounded materials, background objects.
- **Lost edges:** let some edges merge into nearby tones.
Never make everything look cut with a digital knife.

## 9. Imperfection

Controlled handcrafted variation: slightly irregular curves, subtle asymmetry, small shape differences, organic silhouettes,
imperfect spacing, varied highlight shapes, tiny material variation. Polished + handcrafted, not rough + amateur.

## 10. Depth

Combine: foreground/midground/background separation, atmospheric perspective, scale variation, overlap, soft background blur,
lower contrast in the distance, cast shadows, ambient occlusion, lighting hierarchy. The main object has the strongest contrast
and detail; background objects have lower contrast, softer edges, less detail, slightly less saturation.

## 11. Focal hierarchy

Primary focal area: highest contrast, detail, material definition, lighting complexity. Secondary objects: moderate.
Background: lower contrast, sharpness, saturation and detail. Never a set of equally important stickers.

## 12. Background design

For a scene, build a simple environment instead of a plain fill (for a cozy café: warm wall, wooden shelves, hanging lights,
cups, jars, plants, windows, curtains, countertop, soft environmental shadows). The background gives place, atmosphere and depth
and never competes with the subject. (For a game asset that will be cut out, a plain background is correct; still give the object
its own contact and cast shadows and environment-coloured light.)

## 13. Atmospheric light

Unify everything with warm highlights, slightly warm shadows, soft golden ambient light, glow around lamps and windows, light
spill onto nearby surfaces. Everything must look lit by the same environment.

## 14. Shadow design

Never only a generic drop shadow. Use: contact shadow (very dark, where surfaces touch), form shadow (volume), cast shadow
(onto another surface), ambient occlusion (tight spaces), soft environmental shadow (large, low opacity). Each with its own
softness and opacity.

## 15. Highlight design

Not "small white oval = shiny". Highlights describe the material: broad soft, narrow reflected, warm, broken, edge highlights,
subtle specular accents. Pure white sparingly; most highlights take on environment colour.

## 16. Texture

Subtle: tiny tonal variation, soft grain, brush-like variation, ceramic variation, wood grain, fabric variation, food texture.
Texture supports form. Painted, not grainy.

## 17. Detail density

Important objects get secondary details that follow their real construction: seams, buttons, screws, handles, reflections,
small scratches, material boundaries, tiny shadows, surface transitions, subtle colour shifts. No random decorative marks.

## 18. Camera and composition

Clean readable perspective, front-facing or slightly elevated, strong silhouette, centred or deliberately composed subject,
comfortable negative space, readable proportions, no heavy perspective distortion. Designed for a game interface or environment.

## 19. Cozy casual-game aesthetic

Charming, welcoming, warm, playful, polished, slightly whimsical, premium casual-game quality. Rounded forms where they fit.
Avoid gritty or harsh realism, sterile corporate graphics, generic flat cartoon, overly childish shapes, photorealism.

## 20. Rendering strategy for shape-based art

Compensate for no image generator with more meaningful layers. A major object is never just silhouette + fill + outline + highlight.
Think: base silhouette + secondary planes + gradient shading + ambient light + form shadow + contact shadow + reflected light +
material variation + texture + small components + soft highlights + environmental light + cast shadow.
More meaningful layers, not more random shapes.

## 21. SVG specifics

Use gradients extensively but subtly; masks for controlled lighting; opacity layers; selective Gaussian blur; many overlapping
paths; subtle texture overlays; varied stroke widths; few strokes; semi-transparent shadows; warm reflected light; clip paths for
material effects. Nothing as one flat path. Evaluate the rasterized result as artwork.

## 22. Layer order (SVG, HTML/CSS or Canvas)

1. background 2. environmental lighting 3. distant objects 4. midground objects 5. main silhouette 6. large form shading
7. secondary components 8. material details 9. contact shadows 10. highlights 11. atmospheric effects 12. final colour unification.

## 23. Style failures

1. Flat vector icon: big flat fills, thick outlines, minimal shading.
2. Sticker look: every part has a dark border and an isolated highlight.
3. Emoji/cartoon: oversimplified shapes, exaggerated outlines.
4. Technical illustration: perfect geometry, sterile surfaces, no atmosphere.
5. Fake 3D: simple gradients without material behaviour.
6. Plastic everything: the same glossy highlight on every surface.
7. Random detail: marks that ignore the material.
8. Lighting inconsistency: each part lit from a different source.
9. Excessive black: black outlines and shadows overpower the palette.
10. Empty composition: one object floating on blank space when a scene is appropriate.

## 24. Quality check before finishing (on the rendered PNG)

- Style: painted rather than vectorized?
- Lighting: one coherent light environment?
- Depth: foreground, subject and background clearly separated?
- Materials: metal, ceramic, glass, wood, fabric, food distinguishable?
- Edges: intentional hard, soft and lost edges?
- Shadows: contact, form and environmental shadows present?
- Colour: tonal transitions rather than flat regions?
- Detail: concentrated where it matters?
- Atmosphere: warm and cohesive?
- Handcrafted: carefully illustrated, not mathematically assembled?
- Game-art quality: believable as a polished asset from a successful cozy game?
If several answers are "no", keep refining before showing the user.

## 25. Using a reference

Never copy the reference object's identity. Extract its lighting language, rendering language, colour behaviour, edge treatment,
material rendering, depth, texture, atmosphere, level of detail and composition principles, and apply them to the new object.
A blender drawn from a painted coffee-shop reference is a blender in that painted language, not a coffee shop.
The subject changes; the visual language stays.

## 26. Final style definition

A polished, digitally painted, cozy casual-game illustration constructed from layered shapes, with soft dimensional lighting,
subtle material texture, controlled imperfections, rich tonal variation, selective outlines, atmospheric depth, warm environmental
illumination and a handcrafted premium finish. The construction may be vector-based; the appearance must not feel vector-based.

**Build with shapes. Paint with layers. Light with gradients. Model materials with tone. Finish with atmosphere.**
