# UI Art Integration Workflow v1

## Purpose

This document records the workflow for image-backed UI components that still need live Godot text.

The main rule is: **art assets and dynamic text must each have explicit responsibilities**. A finished UI image provides the frame, illustration, texture, ornament, and empty visual slots. Godot owns all gameplay text, values, labels, and interaction states.

## Required Workflow

1. Confirm the art asset.
2. Mark the text-safe areas in component-local normalized coordinates.
3. Store those safe areas in a layout spec, not scattered script offsets.
4. Render dynamic text inside the safe areas.
5. Check common UI scales such as 90%, 100%, and 110%.
6. Only then polish font size, weight, color, hover, and selected states.

## Current Spec System

`scripts/ui/ArtLayoutSpecs.gd` is the lightweight registry for art-aligned text specs.

It currently defines:

- DialogueOverlay frame-local areas: `speaker_rect`, `body_rect`, `continue_rect`, `portrait_overlap_rect`, `frame_content_rect`.
- PolicyCard card-local areas: `title_rect`, `category_rect`, `description_rect`, `cost_rect`, `illustration_rect`, `card_content_rect`.
- A default policy-card spec plus a small `policy_id` override path for cards whose generated art differs slightly.

Coordinates are normalized `Rect2` values relative to the component itself. This keeps the text aligned when the component scales.

## Debug Safe Areas

`ArtLayoutSpecs.DEBUG_SAFE_AREAS` can be set to `true` during development to draw colored text-safe rectangles.

Default: `false`.

This is a development aid only. It must stay off in normal builds.

## Current Scope

This pass did not change:

- policy effects;
- policy costs;
- scenario data;
- narrative text;
- ISLMSolver;
- MacroEngine;
- ScoreEngine;
- font files;
- font subset generation.

The DialogueOverlay left-edge body-text blur issue remains intentionally out of scope.

## Follow-Up Calibration Notes

The next calibration pass kept the same safe-area system and only adjusted the affected text zones:

- PolicyCard formal art no longer displays the middle category text label (`Ë¥¢ÊîøÊîøÁ≠ñ`, `Ë¥ßÂ∏ÅÊîøÁ≠ñ`, etc.). That label remains available for procedural fallback, but the generated v2 card art now relies on title, description, and cost zones as the main readable text hierarchy.
- PolicyCard descriptions were moved upward by changing `description_rect`, not by adding per-node offsets. This reuses the lower parchment area after the category label was hidden.
- PolicyCard cost remains dynamic and number-only. Its `cost_rect` was moved lower and slightly enlarged so the number sits closer to the badge center.
- DialogueOverlay long speaker names are handled by widening the frame-local `speaker_rect` and applying a small long-name font fallback. Short four-character names keep the larger default size.

For future image-backed UI, long labels should first be solved by safe-area width and component-local fit rules. Per-name hard-coded offsets should remain a last resort.

## Unified MacroMap Case

MacroMap v2 extends the same workflow to non-rectangular map art:

1. Treat the national map as one static Image Two master illustration.
2. Keep all live gameplay content outside the image: region names, variables, arrows, values, and state feedback remain Godot-rendered.
3. Store map-local normalized polygon specs for each irregular region.
4. Store separate label and variable safe areas for each region.
5. Split each variable row into a variable label plus a fixed-width arrow slot. Arrow changes must not move the variable text.
6. Render state feedback as a translucent polygon overlay above the map art, not as a baked image variation.
7. Keep the old four-rectangle `MapRegion` grid as fallback if the map master texture is missing.

This map workflow should replace the old "four separate panels with icons" approach for future national-map iterations. The map art and dynamic economic teaching layer must remain separate.

## Map-Local Labels Under Global Zoom

For layered map UI, dynamic labels must not mix coordinate systems.

Required workflow:

1. Render or fit the static map first and record its actual `map_draw_rect`.
2. Place region labels with normalized map-local anchors, not viewport coordinates.
3. Size the label panel from normalized map-local safe bounds.
4. Derive label internals from the same map draw rect, including padding, border, radius, font size, variable column width, and arrow slot width.
5. Keep fixed arrow slots for variables so arrow changes do not shift text.
6. Do not add separate offsets for 50%, 75%, 100%, 125%, or 150% zoom.

When replacing art or changing panel layout, first verify the map draw rect, then retune normalized anchors or label bounds. Do not solve label drift by hard-coding screen-pixel positions.

## Permanent Map And Theory Stack

For the PolicyDesk center panel, the accepted structure is now a stable vertical stack:

- `MapSection`: unified national map and dynamic region labels.
- `TheorySection`: existing IS-LM theory graph and explanation content.

The map title header and `Õº±Ì/¿Ì¬€` toggle button should not occupy visible layout space. Theory content should be initialized with the page and remain visible, so page scrolling and UI zoom can be tested against the final always-on layout.

## Alpha-Mask Region Hover Workflow

For irregular map hover, production hit testing must follow the accepted art mask, not a rough polygon approximation.

Required workflow:
- Validate the master map, region layers, and masks before adding hover.
- Keep masks, region layers, and master map in the same source size and coordinate origin.
- Cache mask images once during component initialization.
- Convert pointer position from component-local coordinates through the actual map draw rect into source texture pixels.
- Sample the mask at that pixel with a documented threshold.
- Keep debug hit overlays disabled by default.
- Place hover tooltip in a top-level layer and set it to ignore mouse input.
- Hide or recompute tooltip state on page scroll and global UI zoom.

For MacroMap v2, the old polygons remain only as debug/reference data. Formal hover uses alpha/white mask sampling. Permanent map labels are removed from normal gameplay and the same dynamic variable data is shown in the hover tooltip.

## Demand Component Data Rule

For dynamic macro-map tooltip content, visual symbols must not double as data keys. C/I/G now use separate numeric fields (`C_value`, `I_value`, `G_value`) and status fields (`C_status`, `I_status`, `G_status`). The tooltip value column reads only numeric value fields; the status column reads status fields. Missing numeric values should be treated as data problems, not replaced by status text.
