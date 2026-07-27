# MacroMap Art v2

## Why The Old Map Changed

The old PolicyDesk map used four independent rectangular `MapRegion` panels. That structure was useful for the prototype, but it made the map read as four UI cards instead of one governed country. The previous region art also behaved like separate icons or plaques rather than economic districts.

MacroMap v2 follows the user's national-map reference direction: one complete abstract country, divided into four interlocking irregular economic regions, with all live labels, variables, arrows, and state feedback rendered by Godot.

## Final Structure

- Static art: one complete national map master texture.
- Dynamic region layer: four normalized polygon overlays for region state tint.
- Dynamic label layer: region names are Godot labels, not baked into the image.
- Dynamic variable layer: `C`, `Y`, `I`, `i`, `G`, and `Debt` are Godot labels.
- Dynamic arrow slots: each variable row uses a fixed-width arrow slot so `↑`, `↓`, and `→` do not shift the variable text.
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

- 居民消费区: `C`
- 工业产区: `Y`, `I`
- 金融市场区: `i`
- 政府部门区: `G`, `Debt`

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

## Pending Manual Review

- Whether the generated map's region boundaries feel close enough to the reference.
- Whether the four label groups need minor per-region anchor adjustment.
- Whether the region layer seams are acceptable when future hover/highlight states are enabled.
- Whether state tint should be reintroduced later with better mask/color tuning.
- Whether the map panel needs a later larger-layout pass after art approval.
