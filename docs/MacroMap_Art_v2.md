# MacroMap Art v2

## Why The Old Map Changed

The old PolicyDesk map used four independent rectangular `MapRegion` panels. That structure was useful for the prototype, but it made the map read as four UI cards instead of one governed country. The previous region art also behaved like separate icons or plaques rather than economic districts.

MacroMap v2 follows the user's national-map reference direction: one complete abstract country, divided into four interlocking irregular economic regions, with all live labels, variables, arrows, and state feedback rendered by Godot.

## Final Structure

- Static art: one complete national map master texture.
- Dynamic region layer: four normalized polygon overlays for region state tint.
- Dynamic label layer: region names are Godot labels, not baked into the image.
- Dynamic variable layer: `C`, `Y`, `I`, `i`, `G`, and `Debt` are Godot labels.
- Dynamic arrow slots: each variable row uses a fixed-width arrow slot so `‚Üë`, `‚Üì`, and `‚Üí` do not shift the variable text.
- Fallback: if the master map cannot load, PolicyDesk uses the previous four-rectangle `MapRegion` grid.

## Image Two Generation

Resource generated with Image Two:

- Path: `assets/art/map/macro_map_master_v1.webp`
- Runtime size: `1440x1080`
- Aspect ratio: `4:3`
- File size: `475,352 bytes`
- Format: WebP

Prompt direction:

- Complete unified fantasy national map.
- Four interlocking irregular economic regions.
- Residential consumption district, industrial district, financial market district, and government district.
- Medieval to early-modern Western governance strategy style.
- Deep blue-black, old gold, copper, muted green, silver gray, parchment-map texture.
- No baked text, labels, variables, arrows, numbers, Chinese characters, or fake letters.
- No four independent cards, no straight cross division, no giant round badges.

## Region Polygon Spec

The map uses normalized component-local polygon points stored in `scripts/ui/map/MacroMapArtSpec.gd`.

Current region ids:

- `consumption`
- `industry`
- `finance`
- `government`

The polygons are approximate tracing regions, not pixel-perfect masks. They are intentionally lightweight and can be refined after visual review.

## Label And Variable Safety

Each region spec includes:

- `label_rect`
- `variable_rect`
- `label_anchor`
- `variable_anchor`
- `variable_row_spacing`
- `arrow_reserved_width`

Variables use a stable two-column row:

- variable label
- fixed-width arrow slot

This preserves readability and prevents layout jumps when arrows change.

## Variable Bindings

The existing PolicyDesk variable meanings are preserved:

- Â±ÖÊ∞ëÊ∂àË¥πÂå∫: `C`
- Â∑•‰∏ö‰∫ßÂå∫: `Y`, `I`
- ÈáëËûçÂ∏ÇÂú∫Âå∫: `i`
- ÊîøÂ∫úÈÉ®Èó®Âå∫: `G`, `Debt`

The existing state and arrow calculation functions remain in `scripts/scenes/PolicyDesk.gd`.

## State Tint Logic

`UnifiedMacroMap.gd` draws four translucent polygon overlays above the master art. Brightness values still come from the existing `_map_region_brightness()` logic.

Current behavior:

- near normal: very light neutral overlay
- negative / weak: cool blue-gray tint
- positive / hot: warm amber tint
- debug boundary: controlled by `MacroMapArtSpec.DEBUG_BOUNDARIES`, default `false`

The map art remains visible under the overlay.

## Fallback

Fallback order:

1. `UnifiedMacroMap` with `macro_map_master_v1.webp`
2. old four-region `MapRegion.tscn` grid

`MapRegion.gd` and `MapRegion.tscn` remain in the project.

## Scale Notes

The unified map follows the existing PolicyDesk UI scale (`0.8` to `1.2`). Coordinates are normalized relative to the rendered map rectangle, so label and polygon placement scale with the image at 90%, 100%, and 110%.

## Round 2 Readability And Fill Pass

The second pass focused only on the unified national map:

- Enlarged the map canvas by reducing the PolicyDesk map panel margins and increasing the unified map minimum display size.
- Added `MAP_DRAW_SCALE = 1.12`, so the master map draws slightly larger than the available fit rect and becomes the central panel's main visual instead of a small inserted image.
- Added `SHOW_REGION_OVERLAYS = false`. The polygon tint and outline layer remains available for later state/highlight work, but it is visually hidden by default in this pass.
- Kept `DEBUG_BOUNDARIES = false` by default; if enabled, only debug boundary lines are drawn.
- Reduced the region label panel margins, border alpha, background alpha, corner radius, and font sizes so labels read more like embedded map tags than floating UI cards.
- Kept the stable variable + fixed-width arrow-slot layout for all region variables.

## Layered Map Preparation Stage 1

Stage 1 only fixes the edge clipping caused by the enlarged map draw rect:

- Root cause: `UnifiedMacroMap` used `clip_contents = true`, while the previous draw rect multiplied the fitted map size by `MAP_DRAW_SCALE = 1.12`. When the scaled draw height exceeded the control height, the top and bottom map border were clipped by the control.
- The map rect calculation now uses a frame-local safe available size and clamps the requested draw scale to the available width/height instead of allowing the final rect to exceed the clipped control bounds.
- Added `MAP_EDGE_SAFE_INSET = Vector2(0.0, 4.0)`, giving the master map about 4 px of vertical safety at 100% UI scale.
- Increased the unified map minimum height from 405 px to 413 px so the full 4:3 map can still occupy the same horizontal width while preserving the top and bottom edges.
- Added integer pixel alignment to the final draw rect to reduce sub-pixel edge clipping at common UI scales.
- No Image Two assets were generated in this stage.
- No polygon, label anchor, label style, hover, or interaction changes were made in this stage.

## Layered Map Preparation Stage 2

Stage 2 prepares the unified map for future region-level visual control without changing labels, hover, or economic logic.

Image Two output:

- Generated a four-color region segmentation reference from the current master map.
- Saved the resized project reference as `assets/art/map/regions/macro_map_region_guide_v1.png` (`1440x1080`, 19,998 bytes).
- Saved the human-check overlay as `assets/art/map/regions/macro_map_region_guide_overlay_v1.png` (`1440x1080`, 3,260,425 bytes).

Mask and region extraction:

- Built all masks from the same four-color guide:
  - `macro_map_mask_consumption_v1.png` (`1440x1080`, 5,900 bytes)
  - `macro_map_mask_industry_v1.png` (`1440x1080`, 5,873 bytes)
  - `macro_map_mask_finance_v1.png` (`1440x1080`, 4,801 bytes)
  - `macro_map_mask_government_v1.png` (`1440x1080`, 5,181 bytes)
- Extracted the formal region layers from `macro_map_master_v1.webp` pixels, preserving the original art inside each mask:
  - `macro_map_region_consumption_v1.png` (`1440x1080`, 775,406 bytes)
  - `macro_map_region_industry_v1.png` (`1440x1080`, 660,073 bytes)
  - `macro_map_region_finance_v1.png` (`1440x1080`, 590,039 bytes)
  - `macro_map_region_government_v1.png` (`1440x1080`, 697,547 bytes)
- Saved validation outputs:
  - `macro_map_regions_recombined_v1.png` (`1440x1080`, 2,645,556 bytes)
  - `macro_map_regions_difference_v1.png` (`1440x1080`, 974,748 bytes)

Godot structure:

- `UnifiedMacroMap` still draws the complete BaseMap first.
- Four same-canvas transparent region layers now draw above BaseMap using the exact same `_map_rect`.
- Normal state draws all region layers at unchanged brightness; this should visually match the current master map.
- `REGION_LAYER_DEBUG_REGION` is default empty, meaning no debug isolation mode. Setting it to a region id can isolate one region for development checks.
- `SHOW_REGION_OVERLAYS` remains `false`, so the old white polygon tint layer stays hidden.
- Labels, polygons, variable bindings, fixed arrow slots, and label positions were not changed in this stage.
- Runtime needs only the four formal region layers. The guide, mask, recombined, and difference PNGs are excluded from Web export through `export_presets.cfg`.

## Layered Map Preparation Stage 3

Stage 3 fixes region label anchoring and UI-scale stability without changing map art, region layers, hover, or label styling.

Root cause:

- Labels were already positioned relative to the rendered map rect, but the layout used the combined label/variable bounds' top-left corner as the placement point.
- That made the visible label group behave like a top-left anchored overlay instead of a center-anchored map label.
- After map scaling and edge-safe rect changes, this made label groups feel offset from their intended regional centers.

Updated positioning:

- `UnifiedMacroMap._map_normalized_to_local()` converts map-normalized coordinates through the actual `_map_rect`.
- Each region now defines `label_group_anchor` in `MacroMapArtSpec.REGION_SPECS`.
- The label panel is positioned as `anchor_pixel - panel.size * 0.5`, so each tag is centered on its visual anchor.
- Final panel positions are pixel-rounded to reduce drift at common UI scales.
- The existing `label_rect` / `variable_rect` still define group size and safe area; `label_group_anchor` defines where that group sits on the map.

Current anchors:

- `consumption`: `Vector2(0.370, 0.430)`
- `industry`: `Vector2(0.775, 0.405)`
- `finance`: `Vector2(0.355, 0.715)`
- `government`: `Vector2(0.748, 0.700)`

Scope:

- No Image Two assets were generated.
- No hover, right-side details, region click behavior, polygon changes, or economic variable logic changes were added.
- Labels keep the previous lightweight map-tag style and fixed-width arrow slots.

Build and deployment:

- Web export completed through the standard project flow.
- CloudBase deployment completed with BuildId `20260728-033032`.
- Release URL: `/releases/20260728-033032/index.html`.
- Core artifact sizes: `index.pck` 10,657,072 bytes; `index.wasm.gz` 10,111,653 bytes.

## Pending Manual Review

- Whether the generated map's region boundaries feel close enough to the reference.
- Whether the four label groups need minor per-region anchor adjustment.
- Whether the region layer seams are acceptable when future hover/highlight states are enabled.
- Whether state tint should be reintroduced later with better mask/color tuning.
- Whether the map panel needs a later larger-layout pass after art approval.

## Label Scale Stabilization and Persistent Theory Layout

This pass fixes label scale instability after the 50% - 150% UI zoom expansion and changes the center PolicyDesk panel into a permanent map/theory stack.

Root cause:

- Region label panel size and position were map-local, based on `_map_rect` and normalized anchors.
- Label internals such as padding, border width, corner radius, shadow size, font size, variable column width, and arrow slot width still used the global `_ui_scale` directly.
- When the actual map draw rect changed through container allocation, edge-safe fitting, or zoom rebuilds, label containers and label internals could scale from two slightly different coordinate systems.

Final label scale rule:

- Region label position remains map-local and normalized through `_map_normalized_to_local()`.
- Region label panel size remains derived from normalized label bounds multiplied by `_map_rect.size`.
- Label internals now use a map-derived label scale: `_map_rect.size.x / MacroMapArtSpec.LABEL_REFERENCE_MAP_WIDTH`.
- This keeps label width, height, padding, fonts, borders, variable columns, and fixed arrow slots in the same visual coordinate system as the rendered map.
- No per-zoom offsets were added.

Persistent center layout:

- The visible `≥ÈœÛπ˙º“µÿÕº` header was removed from the center panel.
- The visible `Õº±Ì/¿Ì¬€` toggle button was removed.
- The map and theory panels are now always visible in a vertical stack.
- `MapSection` and `TheoryPanel` share the same parent width and use close stretch ratios (`1.05 : 0.95`) with minimum heights to keep both readable.
- The theory content is created during PolicyDesk initialization and no longer depends on a toggle state.

Scope:

- No map art, masks, region layers, DialogueOverlay, PolicyCard, theory content, economic logic, policy effects, scoring, or narrative text were changed.
- The previous hidden region overlay behavior remains unchanged.

## Irregular Map Restoration In Persistent Layout

The first persistent map/theory layout pass kept the new vertical layout, but the runtime map could still fall back to the old four-rectangle `MapRegion` grid.

Root cause:

- `PolicyDesk._build_macro_map_view()` still treated the legacy `MapRegion` grid as the official fallback when `UnifiedMacroMap.has_master_texture()` returned false during view construction.
- That fallback was useful during early art integration, but after the unified irregular map became the accepted production map it allowed the formal page to display the old four-panel visual again.
- The unified map assets and four same-canvas region layers were still present; this was an integration fallback problem, not an art-resource loss.

Fix:

- `MapSection` now always instantiates `scenes/components/UnifiedMacroMap.tscn`.
- `UnifiedMacroMap` receives the same region data and remains responsible for drawing the master map, the four transparent region layers, labels, variables, and fixed arrow slots.
- If a texture is missing, fallback remains inside `UnifiedMacroMap` instead of replacing the entire component with the old four-rectangle grid.
- The old `MapRegion` component is retained in the project for compatibility, but it is no longer the production path for the central PolicyDesk map.

Scope:

- The permanent top-bottom central layout was preserved.
- No Image Two resources were generated.
- No map art, region masks, region layers, labels, theory content, PolicyCard, DialogueOverlay, economic logic, policy effects, scoring, or narrative text were changed.
