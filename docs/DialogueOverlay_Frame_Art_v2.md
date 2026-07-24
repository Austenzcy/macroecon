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

## Art-Aligned Text Spec

The live text layer now uses `scripts/ui/ArtLayoutSpecs.gd` instead of viewport-scattered offsets.

Current frame-local safe areas:

| Area | Purpose |
| --- | --- |
| `speaker_rect` | Speaker name only. This replaces the old portrait-width offset rule and moves the name slightly left/up with a larger font. |
| `body_rect` | Dialogue body text. Its position remains broadly consistent with the accepted v2 layout, with slightly larger text and line spacing. |
| `continue_rect` | Independent bottom-right continue/page prompt. |
| `portrait_overlap_rect` | Documents the left portrait overlap zone for future art calibration. |
| `frame_content_rect` | Documents the general clean content area inside the frame. |

Coordinates are normalized to the displayed `DialogueBox` frame, so the same spec applies at common UI scales such as 90%, 100%, and 110%.

`ArtLayoutSpecs.DEBUG_SAFE_AREAS` can be enabled during development to draw the safe rectangles. It is disabled by default.

## Text Safe Area Recalibration

After manual review, the frame image itself was kept unchanged and only the live Godot text layout was recalibrated.

Changes:

- `SpeakerNameLabel` and `DialogueBodyLabel` remain in `DialogueTextSafeArea`, but the safe area starts lower inside the frame.
- Top safe margin now scales to roughly `44-60 px`, moving the speaker name and first body line away from the upper inner ornament.
- Right safe margin now scales to roughly `150-220 px`, preventing long body lines from reaching the right corner decoration.
- Bottom safe margin now scales to roughly `56-82 px`, reserving space for the independent continue prompt.
- `ContinuePromptLabel` now lives in its own `ContinuePromptContainer` instead of sharing the body-text VBox.
- Continue prompt right margin now scales to roughly `110-170 px`, and bottom margin to roughly `28-42 px`, keeping it away from the lower-right ornament.
- Body line separation increased to make short and medium dialogue pages less cramped near the top.

Portrait size, portrait position, portrait crop, frame image, frame size, NinePatch margins, click advance, highlight, input blocking, wheel forwarding, and narrative text were not changed in this recalibration pass.

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
- Confirm the new speaker-name safe area is far enough left/up without overlapping the bust portrait.
- The left-edge body-text blur issue was not handled in this pass.
