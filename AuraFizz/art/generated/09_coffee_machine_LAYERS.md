# Coffee Machine scene (09_coffee_machine.png, 1536x864): layer plan for Blender
Source image is NOT redrawn: layers are cut from it; hidden areas are filled to match it (inpaint), and the stacked layers must rebuild the original.

## A+B. Layer list by group (back → front)
01_BACKGROUND
- 01_BACKGROUND_WALL: peach plank wall, full frame. Fill in behind the shelves, lamps, chalkboard, plant, window, curtains and machine.
- 01_BACKGROUND_WINDOW: gold arched window with the rainy street. Rain and bokeh live in the effects group.
- 01_BACKGROUND_BACKCOUNTER: back counter strip behind the main counter, left and right.
02_BACKGROUND_DECOR
- 02_SHELF_LEFT_TOP: shelf plus 3 jars.
- 02_SHELF_LEFT_BOTTOM: shelf plus 3 white cups.
- 02_TOASTER_OVEN
- 02_BACK_JARS: small jars and the tall bean jar on the back counter.
- 02_CHALKBOARD
- 02_PLANT_HANGING: pot plus vines.
- 02_LAMP_LEFT, 02_LAMP_RIGHT: shade, cord and bulb. The glow lives in the effects group.
- 02_STRING_LIGHTS: wire plus bulbs.
- 02_CURTAIN_LEFT, 02_CURTAIN_RIGHT: with tie-backs.
04_COUNTER
- 04_COUNTER_TOP: cream marble. Fill in under every object and its shadow.
- 04_COUNTER_CABINETS: black and gold drawers and knobs.
05_STATIC_EQUIPMENT
- 05_ESPRESSO_MACHINE_BODY: body, gold trim, gauge plate and drip-tray base. Fill in behind the portafilter, cup and wand.
- 05_MACHINE_GROUPHEAD_LEFT, 05_MACHINE_GROUPHEAD_RIGHT: chrome brew heads.
06_INTERACTIVE_OBJECTS (each with its own shadow)
- 06_JAR_BEANS (+ 06_JAR_BEANS_LID, 06_JAR_BEANS_SHADOW)
- 06_JAR_SUGAR (+ 06_JAR_SUGAR_LID, 06_JAR_SUGAR_SHADOW)
- 06_MILK_PITCHER (+ _SHADOW)
- 06_GRINDER_HOPPER: glass, grounds and lid together.
- 06_TOPCUP_1, 06_TOPCUP_2: the white cups on top of the machine.
- 06_COFFEE_CUP (+ 06_COFFEE_CUP_LIQUID, 06_COFFEE_CUP_SHADOW): the cup on the drip tray.
- 06_SYRUP_1_AMBER, 06_SYRUP_2_DARK, 06_SYRUP_3_BROWN (+ each _PUMP, + each _SHADOW)
- 06_CAKE_DOME_LID, 06_CAKE_STAND_CROISSANT (+ _SHADOW)
07_MOVING_PARTS
- 07_KNOB_1 … 07_KNOB_4: gold front knobs.
- 07_SIDE_KNOB: black knob on the right side.
- 07_GAUGE_NEEDLE: copy out the needle, then fill in the gauge face.
- 07_PORTAFILTER_LEFT: handle plus basket.
- 07_STEAM_WAND
- 07_DRIP_TRAY_GRILL
09_EFFECTS
- 09_STEAM_CUP: grey wisps above the cup.
- 09_COFFEE_STREAM: drip from the right group head. Replace with the Blender pour flipbook.
- 09_LAMP_GLOW_LEFT, 09_LAMP_GLOW_RIGHT
- 09_STRING_LIGHT_GLOW
- 09_WINDOW_RAIN, 09_WINDOW_BOKEH
10_FOREGROUND: nothing in this picture.
08_CHARACTERS: none in this picture.

## C. Animations
- KNOB_1-4: turn ±30°, then a small bounce.
- SIDE_KNOB: turn.
- GAUGE_NEEDLE: rises while brewing and wobbles slightly.
- PORTAFILTER_LEFT: lock and unlock by turning about 25°, slide down out of the head, and lift out toward the grinder.
- STEAM_WAND: swing out about 20° for milk.
- COFFEE_CUP: slide in under the head, squash on landing, slide out to serve. The LIQUID scales up from the bottom.
- COFFEE_STREAM: appear, stretch down, flicker, then shrink up.
- STEAM_CUP: rise, fade and grow slowly, on a loop.
- GRINDER_HOPPER: grounds level drops a little and the hopper shakes while grinding.
- TOPCUP_1/2: lift up and move down to the tray.
- JAR lids: lift up and tilt open, close with a bounce.
- MILK_PITCHER: lift, tilt about 35° to pour, return.
- SYRUP pumps: press down 6px and return, with a drip.
- CAKE_DOME_LID: lift, hold, lower.
- LAMP / STRING glows: slow breathing (opacity 0.85↔1).
- WINDOW_RAIN: scroll downward on a loop.
- BOKEH: slow drift.
- DRIP_TRAY_GRILL: none (reserved for a splash).
- Every _SHADOW follows its object, shrinking and fading when the object is lifted.

## D. Pivots (Blender origins)
- KNOBS, SIDE_KNOB: knob centre.
- GAUGE_NEEDLE: the hub at the gauge centre.
- PORTAFILTER_LEFT: where it attaches under the left group head, top centre of the basket.
- STEAM_WAND: top joint where it meets the body.
- COFFEE_CUP, JARS, PITCHER, SYRUP bottles, CAKE STAND, TOPCUPS: bottom centre.
- MILK_PITCHER when pouring: bottom of the spout side, so it tips forward.
- COFFEE_CUP_LIQUID: bottom of the liquid.
- JAR lids and CAKE_DOME_LID: back edge of the lid's base (hinge), or bottom centre for a straight lift.
- SYRUP pumps: base of the pump stem.
- GRINDER_HOPPER: bottom centre of the base.
- COFFEE_STREAM: top, at the spout.
- STEAM: bottom centre.
- Glows: centre of the bulb.

## E. Extraction order
1. Effects first, so nothing of them is left baked in: steam, coffee stream, the lamp and string-light glows, rain and bokeh.
2. Small moving parts: knobs, side knob, gauge needle, portafilter, steam wand.
3. Interactive objects, front to back, each with its shadow: cup with its liquid, syrups with their pumps, cake dome, pitcher, jars with their lids, top cups, grinder hopper.
4. Static equipment: machine body and group heads. Fill in where the parts were removed.
5. Counter top and cabinets: fill in under every removed object and shadow.
6. Background decor: shelves, toaster, jars, chalkboard, plant, lamps, string lights, curtains.
7. Last, the wall, window and back counter, completely filled in.
Stays baked into the background: plank texture, the window frame's static shading, the shadows of the back shelves and the curtain folds.
