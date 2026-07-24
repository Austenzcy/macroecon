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

