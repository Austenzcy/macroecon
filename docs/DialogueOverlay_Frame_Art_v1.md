# DialogueOverlay Frame Art v1

This pass continues the bust-portrait `DialogueOverlay` direction and changes the dialogue box body from a mostly procedural panel to an image-backed game UI frame.

The latest user prompt is the highest-priority direction for this pass. Older art manifests and skin notes remain historical context only where they do not conflict with this implementation.

## Three-Step Workflow

### Step 1: Structure And Position

`scripts/ui/DialogueOverlay.gd` keeps the existing independent `SpeakerBustLayer` for the character portrait, but the dialogue box body is lower and slightly shorter.

The goal is for the character bust to feel like it is standing in front of the box:

- The portrait position and scale stay broadly consistent with the previous bust version.
- The dialogue box top edge is lower, roughly behind the lower half of the bust.
- `DialogueTextMargin` reserves more left-side space so the portrait does not cover the speaker name or body text.
- The overlay still uses the full-screen root under `DialogueOverlayLayer`, preserving click advance, dimming, highlight drawing, wheel forwarding, and Ctrl+wheel compatibility.

### Step 2: Image-Backed Frame

Image Two generated a dedicated dialogue frame asset:

| Asset | Path | Purpose |
| --- | --- | --- |
| Bust dialogue frame | `assets/art/ui/dialogue_frame_bust_v1.png` | Bottom dialogue box background, border, and ornament |

The source generation used a flat chroma-key background, then local chroma removal produced the final transparent PNG. The intermediate chroma source is not kept in the project to avoid unnecessary exported size.

The image contains only the frame, border, ornament, and dark writing surface. It does not bake in any dialogue text.

`DialogueOverlay.gd` renders the frame with a `NinePatchRect` named `DialogueFrameArt`, so the central area can stretch while the border remains visually stable. If the image is missing, the overlay falls back to the previous procedural panel style.

`ArtAssetRegistry.gd` now exposes the frame through:

```gdscript
texture_for_slot("dialogue_frame_bust")
```

### Step 3: Text And Layout

Text remains live Godot UI:

- Speaker name: warm gold, slightly larger than the body text.
- Body text: warm ivory for readability over the dark image frame.
- Continue hint: visible warm gold, weaker than the body copy.
- Runtime pagination remains active; character-per-page limits were tightened for the lower, image-backed panel.

## Preserved Behavior

- Single click / touch advances one page or one step.
- Enter / Space still advance dialogue.
- Gameplay input remains blocked during narrative dialogue.
- Hint modal blocking still prevents accidental background advance.
- Highlight drawing and dim overlay remain unchanged.
- Mouse wheel and Ctrl+wheel routing are preserved.

## Follow-Up Notes

- The image frame is a first usable UI art pass and should be manually reviewed in the deployed Web build.
- Later passes can produce a cleaner 9-slice-specific frame if the current ornament stretches poorly at extreme viewport sizes.
- Character bust placement should not be broadly changed unless the user asks; this pass intentionally focuses on the dialogue box body.
