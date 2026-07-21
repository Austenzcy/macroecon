# Art Round2 Redesign Plan

## Priority

This pass follows the latest user prompt as the highest priority when it conflicts with the earlier art spec, Round1 documents, or previous generated assets.

## Why This Pass Exists

Round1 P0 assets were successfully generated and loaded, but the first integration exposed two separate problems:

- Several PNGs used their source dimensions during layout, causing oversized wisdom icons, policy card artwork, map artwork, and advisor portraits.
- The visual direction of some P0 assets was too emblem-like. Role "avatars" looked like symbols instead of people, policy cards read as large circular badges, and map regions read as four independent emblem buttons rather than economic regions on an abstract national map.

## Kept Resources

The following Round1 assets can remain in use because they are small UI-state resources or secondary symbols:

| Resource | Status | Notes |
| --- | --- | --- |
| `assets/art/icons/ui/icon_wisdom_points.png` | Kept | Still used as the wisdom points icon, now constrained to a small top-bar slot. |
| `assets/art/icons/ui/icon_lock_level.png` | Kept | Still used for locked levels. |
| `assets/art/stamps/stamp_level_complete.png` | Kept | Still used for completed levels. |
| `assets/art/icons/policies/*.png` | Kept as auxiliary | Downgraded to small policy-type icons, not the policy card main visual. |
| `assets/art/icons/map/*.png` | Kept as fallback | Used only if the new map region scene assets are missing. |
| `assets/art/characters/badges/*.png` | Kept as fallback | Used only if the new human portrait assets are missing. |

## Redone Resources

| Group | New Direction | Integration Rule |
| --- | --- | --- |
| Character portraits | Actual human bust portraits of ministers/advisors in a medieval to early-modern Western governance style. | `ArtAssetRegistry.texture_for_character()` prefers portraits, then falls back to old badges, then text placeholders. |
| Policy card visuals | Vertical decree / law-card artwork with parchment, antique trim, and policy-specific illustration. | `PolicyCard.gd` shows these in a constrained top card-art slot; type icons remain small auxiliaries. |
| Macro map regions | Small isometric sandbox / region scenes, not round emblems. | `MapRegion.gd` prefers new scene assets, then falls back to old region icons, then text placeholders. |

## Sizing And Layout Fixes

- TextureRect nodes that display generated art use `expand_mode = TextureRect.EXPAND_IGNORE_SIZE`.
- Art slots use fixed `custom_minimum_size` and `clip_contents = true`.
- DialogueOverlay and AdvisorPanel portrait areas are clipped so portraits cannot overflow the avatar frame.
- Wisdom points, policy type icons, policy card art, map region scenes, and level icons remain visually constrained.

## Design Constraints

- No Chinese historical / poet imagery.
- No Q-version cartoon characters.
- No modern dashboard / flat icon direction for core art.
- No pure circular badge composition for role portraits, policy card main visuals, or map regions.
- No gameplay, scoring, narrative, or model logic changes.

## Minimal Validation Boundary

This pass intentionally avoids broad automatic UI testing. Validation consists of static asset/path checks, alpha transparency checks, Web export, CloudBase deployment, and basic launch readiness for manual review.
