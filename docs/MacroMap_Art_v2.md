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

## Pending Manual Review

- Whether the generated map's region boundaries feel close enough to the reference.
- Whether the four label groups need minor per-region anchor adjustment.
- Whether state tint should be reintroduced later with better mask/color tuning.
- Whether the map panel needs a later larger-layout pass after art approval.
