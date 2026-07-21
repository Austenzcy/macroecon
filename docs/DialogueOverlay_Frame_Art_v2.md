# DialogueOverlay Frame Art v2

This pass replaces the first bust dialogue frame with a cleaner, text-safe v2 frame. The latest user prompt is the highest-priority direction for this work.

## Why v1 Was Replaced

`assets/art/ui/dialogue_frame_bust_v1.png` looked impressive as a standalone decoration, but it was not ideal as a long-dialogue container:

- The central crest and lower metal ornament competed with body text.
- The frame read more like a title banner / decorative beam than a complete text box.
- Large center ornaments were unsafe for `NinePatchRect` stretching.
- The body text felt like it floated on top of decoration instead of sitting inside a calm writing surface.
- The PNG was about 1.78 MB, heavier than needed for a Web UI frame.

v1 is still kept in the project as fallback.

## v2 Design Target

The v2 asset is designed as a real bottom dialogue box body:

- Wide, dark, continuous writing surface.
- Restrained antique-gold / copper border.
- Decoration concentrated in corners and thin edge lines.
- No large central crest.
- No large bottom ornament.
- No baked-in role names, dialogue text, or continue hint.
- Left side remains quiet enough for the existing bust portrait to overlap.
- Center and right areas are intentionally text-safe.

## Generated Asset

| Asset | Path | Dimensions | Size |
| --- | --- | ---: | ---: |
| Dialogue frame v2 | `assets/art/ui/dialogue_frame_bust_v2.png` | 1440 x 360 | 818,371 bytes |

The image was generated with Image Two on a flat chroma-key background, then converted to transparent PNG and lightly resized/optimized for Web use. The temporary chroma/raw sources are not kept in the project.

## NinePatch Configuration

`scripts/ui/DialogueOverlay.gd` renders v2 through `DialogueFrameArt`, a `NinePatchRect`.

Current margins:

```text
patch_margin_left: 380
patch_margin_top: 86
patch_margin_right: 92
patch_margin_bottom: 58
horizontal stretch: stretch
vertical stretch: stretch
```

The larger left margin protects the fixed left-side nameplate/transition shape and aligns with the portrait overlap area. The center stretch region is intentionally clean, so it can expand without distorting a major emblem.

## Node Layering

The effective presentation remains:

1. Full-screen dim/highlight drawing on `DialogueOverlay`.
2. Bottom `DialogueBox`.
3. `DialogueFrameArt` image-backed frame.
4. Independent `SpeakerBustLayer` above the frame.
5. Live Godot text over the frame: speaker name, body text, continue hint.

This keeps the intended result: the character stands in front of the frame while dialogue text sits naturally inside the frame.

## Text Safety

Live text is still rendered by Godot, not baked into the image.

- Speaker name: warm gold.
- Body text: warm ivory.
- Continue hint: muted warm gold.
- Body text has a small line separation increase.
- Pagination remains active and uses conservative character limits for the lower frame.

## Fallback Rules

`ArtAssetRegistry.texture_for_dialogue_frame()` checks:

1. `assets/art/ui/dialogue_frame_bust_v2.png`
2. `assets/art/ui/dialogue_frame_bust_v1.png`
3. Procedural panel fallback in `DialogueOverlay.gd`

Missing image assets should not crash the overlay.

## Preserved Scope

This pass did not change:

- Character portrait generation or crop.
- Macro map.
- Policy cards.
- Level select.
- Theory panel.
- ISLMSolver, MacroEngine, or ScoreEngine.
- Narrative JSON or dialogue text.

## Pending Manual Review

- Confirm the frame reads as a text container rather than a decorative banner.
- Confirm the left portrait overlap feels natural.
- Confirm long Chinese dialogue remains readable at common browser zoom levels.
- Confirm the v2 9-slice does not distort visibly on wide and narrow desktop viewports.
