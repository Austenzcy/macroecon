# DialogueOverlay Bust Portrait v1

## Goal

This pass upgrades the narrative `DialogueOverlay` from the previous small badge-avatar layout to a formal bottom speaking area with a large bust / half-body character portrait on the left.

The latest user prompt and the three reference images take priority over older art manifests or badge-avatar plans.

## Generated / Replaced Portrait Assets

Image generation used the built-in Image Two path. A unified 3x2 source sheet was generated on a flat `#00ff00` chroma-key background, then locally split, chroma-keyed, despilled, cropped, and saved as transparent PNG files.

The following six P0 dialogue portraits were replaced:

| Role | File | Status |
| --- | --- | --- |
| 首席大臣 | `assets/art/characters/portraits/portrait_chief_minister.png` | Replaced with bust portrait |
| 首席经济顾问 | `assets/art/characters/portraits/portrait_economic_advisor.png` | Replaced with bust portrait |
| 财政部长 / 财政大臣 | `assets/art/characters/portraits/portrait_fiscal_minister.png` | Replaced with bust portrait |
| 央行行长 | `assets/art/characters/portraits/portrait_central_bank_governor.png` | Replaced with bust portrait |
| 产业大臣 | `assets/art/characters/portraits/portrait_industry_minister.png` | Replaced with bust portrait |
| 民生大臣 | `assets/art/characters/portraits/portrait_livelihood_minister.png` | Replaced with bust portrait |

Each output is a transparent PNG on a `512x704` canvas. The taller canvas is intentional: it lets the DialogueOverlay render the portrait as a standing bust rather than a square icon.

## DialogueOverlay Layout

`scripts/ui/DialogueOverlay.gd` now uses a layered structure:

- Full-screen root Control under the existing `DialogueOverlayLayer` CanvasLayer.
- Full-screen dimming and target highlight remain drawn by `_draw()`.
- Bottom `DialogueBox` remains anchored to the viewport bottom.
- New `SpeakerBustLayer` is an independent overlay child, drawn above the dialogue panel.
- `SpeakerBustTexture` displays the role portrait at a larger size and bottom-aligns it near the left edge of the panel.
- `DialogueTextMargin` reserves left-side space for the portrait so the bust does not cover speaker name or body text.

The portrait may extend above the top edge of the dialogue box, matching the intended "character standing beside the dialogue frame" direction.

## Resource Mapping And Fallback

`scripts/ui/ArtAssetRegistry.gd` now exposes:

```gdscript
texture_for_dialogue_portrait(speaker_id, avatar_id, speaker_name)
```

Resolution order:

1. Match the current speaker to a character key using `speaker_id`, `avatar`, and visible speaker name.
2. Load the matching portrait from `assets/art/characters/portraits/`.
3. If missing, load the generic `economic_advisor` portrait.
4. If that is unavailable, fall back to the old badge texture.
5. If no texture can be loaded, the text fallback remains available.

This preserves the existing narrative JSON structure and does not require changing story data.

## Preserved Systems

This pass intentionally keeps the following behavior unchanged:

- Single-click / touch to advance dialogue.
- Enter / Space to advance dialogue.
- Long-text pagination.
- Bottom placement and viewport synchronization.
- Dimming overlay and target highlight.
- Gameplay input blocking during narrative.
- Mouse wheel forwarding and Ctrl + wheel UI scaling.
- NarrativeManager sequence queueing and modal handling.

## Not In Scope

This pass does not change:

- MacroMap / MapRegion.
- PolicyCard layout.
- TheoryPanel or model replay.
- ScoreEngine, ISLMSolver, MacroEngine, or scenario data.
- AdvisorPanel full half-body redesign.

## Known Follow-Ups

- AdvisorPanel still uses the existing compact portrait slot. It can be redesigned later if the DialogueOverlay direction is approved.
- Future Image Two passes can produce per-role pose refinements if manual review finds any role too similar or too generic.
- The portrait cutouts use chroma-key removal rather than native transparent generation, so a small edge cleanup pass may be useful after visual review.
