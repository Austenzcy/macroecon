# Art Reference Direction v1

## 1. Priority

This note records the latest visual direction from the three user-provided reference images:

- Abstract national map reference
- "Increase government purchase" policy card reference
- Bottom dialogue box reference

When this note conflicts with older art specs, Round1 manifests, previous generated assets, or earlier implementation plans, the latest user prompt and these references take priority.

This pass is directional only. It does not generate new images, rewrite UI layout, change gameplay logic, or push to GitHub.

## 2. Overall Direction

Future UI and art work should move toward a fictional classical governance strategy-game presentation:

- A complete national governance table, not a modern dashboard.
- Ministers and advisors speaking through dramatic portrait dialogue.
- Policies presented as formal decree cards.
- The macro map shown as a unified abstract country divided into economic regions.
- Clear teaching readability remains mandatory.

New formal images should default to the Image Two route. Programmatic UI remains useful for responsive layout, borders, states, fallbacks, and data-driven elements.

## 3. Abstract National Map Direction

The target is a complete map with economic districts, not four separate rectangular panels with one icon each.

Future implementation should aim for:

- One visually unified abstract country map.
- Four functional regions: residents / consumption, industry, financial market, and government.
- Irregular or organic boundaries between regions instead of a simple 2x2 rectangular grid.
- Rich internal regional content, such as housing and markets for consumption, factories and workshops for industry, banking and ledgers for finance, and administrative buildings for government.
- Region labels and variable markers overlaid on top of the map.

Required variable marker slots:

- Consumption region: `C` plus reserved arrow slot.
- Industry region: `Y / I` plus reserved arrow slots.
- Finance region: `i` plus reserved arrow slot.
- Government region: `G` plus reserved arrow slot.

The region artwork must leave clean readable space for names, variables, and arrows. The map should support the existing teaching logic: current macro-state brightness, variable arrows, and no policy-result recalculation inside the art layer.

Current relevant entry points:

- `scripts/scenes/PolicyDesk.gd`
- `scripts/ui/MapRegion.gd`
- `scripts/ui/ArtAssetRegistry.gd`
- `assets/art/map_regions/`

Likely future work:

- Replace the current four independent `MapRegion` card layout with either a single map view component or a coordinated map container.
- Keep existing variable-binding and brightness logic, but render it over a unified map.
- Preserve fallback for simple four-region layout if a large map asset is missing.

## 4. Policy Card Direction

The target is a complete vertical decree / policy card, not a small text card with an inserted icon.

Future policy cards should:

- Read as one integrated card face.
- Include a primary illustration area, title, category, description, and policy point information as parts of the same card design.
- Avoid using a single large circular icon as the main visual.
- Keep the title, policy type, description, and cost readable at the actual in-game card size.
- Stay within the medieval / early-modern Western governance and strategy-game style.

The "increase government purchase" reference is a strong target for the card language: ornate frame, clear title, large policy-specific illustration, parchment text area, and prominent policy point badge.

Current relevant entry points:

- `scripts/ui/PolicyCard.gd`
- `scripts/scenes/PolicyDesk.gd`
- `scripts/ui/ArtAssetRegistry.gd`
- `assets/art/policy_cards/`
- `assets/art/icons/policies/`

Likely future work:

- Treat `policy_card_*.png` as the card-face art direction rather than a decorative slot.
- Decide whether card text remains Godot-rendered for readability, or whether only the card frame / illustration comes from Image Two while dynamic text remains native UI.
- If needed later, add hover enlargement carefully so small card text remains readable without changing policy selection logic.

## 5. Bottom Dialogue / Character Speaking Direction

The target is a formal bottom dialogue frame with a visible character portrait, not a small emblem-only avatar.

Future dialogue presentation should:

- Keep the bottom dialogue position.
- Use a polished frame with classical trim and readable text.
- Show the speaker name with clear hierarchy.
- Prefer character bust / half-body portraits, potentially extending partly beyond the dialogue box edge for more presence.
- Avoid pure badge-only avatars as the final direction.

The current portrait slot is a useful intermediate step, but the long-term target is a stronger character speaking composition.

Current relevant entry points:

- `scripts/ui/DialogueOverlay.gd`
- `scripts/ui/AdvisorPanel.gd`
- `scripts/autoload/NarrativeManager.gd`
- `scripts/ui/ArtAssetRegistry.gd`
- `assets/art/characters/portraits/`

Likely future work:

- Add a dedicated portrait presentation layer for DialogueOverlay, separate from the clipped small avatar slot.
- Keep current click-to-continue, pagination, wheel forwarding, Ctrl + wheel scaling, and gameplay input blocking unchanged.
- Preserve fallback to smaller portrait / badge / text if a full character portrait asset is missing.

## 6. What Can Stay

The following current systems are useful and should be preserved unless a future task explicitly changes them:

- `ArtAssetRegistry.gd` as the central resource registry and fallback layer.
- Existing policy selection, MacroEngine / ISLMSolver / ScoreEngine logic.
- Existing DialogueOverlay input behavior and pagination.
- Existing wisdom points, hint modal, and guide target systems.
- Existing native labels for dynamic economic values, arrows, and teaching text.

## 7. What Must Change Later

The following items should not be treated as final art direction:

- Four independent rectangular map panels as the final national map.
- Large circular region emblems as the main map visual.
- Pure emblem / symbol-only role avatars.
- Policy cards whose main visual is only a pasted icon inside a functional card.

## 8. Recommended Next Landing Order

Recommended next implementation order:

1. DialogueOverlay character presentation, because it has the highest narrative impact and the reference direction is clearest.
2. PolicyCard integrated card-face structure, because it directly affects decision-making feel.
3. MacroMap unified abstract map, because it likely requires the largest layout change and should be isolated in its own round.

Each landing pass should stay small: generate assets with Image Two, integrate through the registry, preserve fallbacks, run only basic build/deploy checks, and leave detailed visual review to the user.
