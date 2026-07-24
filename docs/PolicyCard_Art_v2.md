# PolicyCard Art v2

## Goal

This pass replaces the earlier "functional panel with an inserted image slot" approach with integrated vertical policy cards.

The highest-priority visual anchor is the user-provided "increase government purchase" reference card:

- one complete vertical decree / governance card face;
- ornate but controlled dark-gold border;
- a clean top nameplate for the dynamic policy title;
- a large policy-specific illustration in the middle;
- a lower parchment area for dynamic description text;
- a smaller policy type badge area;
- a bottom-right policy point badge base;
- no baked-in Chinese title, description, or policy point number.

## Current Policies

The current IS-LM chapter uses six policy ids:

| Policy id | Display role |
| --- | --- |
| `increase_government_purchase` | fiscal expansion / public purchase |
| `tax_cut` | fiscal expansion / tax relief |
| `expansionary_monetary_policy` | expansionary monetary policy |
| `contractionary_fiscal_policy` | contractionary fiscal policy |
| `contractionary_monetary_policy` | contractionary monetary policy |
| `keep_policy_unchanged` | wait-and-observe policy |

No unused policy cards were generated in this pass.

## Implementation Choice

Chosen approach: **Scheme A, one complete card-face background per policy**.

Reason:

- It best matches the user's reference image.
- It makes each card feel like a real decree card rather than a panel with separate image pieces.
- The current chapter only has six policy cards, so package growth is manageable after downscaling.

Dynamic Godot text still renders:

- policy title;
- policy type;
- policy description;
- policy point value;
- selected state.

The image asset provides only the card face, frame, thematic illustration, blank title plate, blank text panel, and empty badge bases.

## Generated Assets

All v2 card assets were generated with Image Two on a chroma-key background, then background-removed, despilled, and resized to `360x540` PNG.

| Policy | Path | Size |
| --- | --- | --- |
| Increase government purchase | `assets/art/policy_cards/policy_card_government_purchase.png` | 360x540, 376,891 bytes |
| Tax cut | `assets/art/policy_cards/policy_card_tax_cut.png` | 360x540, 369,688 bytes |
| Expansionary monetary policy | `assets/art/policy_cards/policy_card_monetary_expand.png` | 360x540, 366,961 bytes |
| Contractionary fiscal policy | `assets/art/policy_cards/policy_card_fiscal_contract.png` | 360x540, 352,681 bytes |
| Contractionary monetary policy | `assets/art/policy_cards/policy_card_monetary_contract.png` | 360x540, 348,205 bytes |
| Keep policy unchanged | `assets/art/policy_cards/policy_card_keep_unchanged.png` | 360x540, 345,449 bytes |

Total new policy-card image size is about 2.16 MB.

## PolicyCard Node Structure

`scripts/ui/PolicyCard.gd` now keeps the public API unchanged:

- `set_policy(data)`;
- `set_cost(cost, show_cost)`;
- `set_selected(value)`;
- `selected(policy_id, policy_name)`.

Internal structure:

```text
PolicyCard
└── PolicyCardFace
    ├── PolicyCardFaceTexture
    ├── PolicyCardProceduralFallback
    ├── TitleArea / TitleLabel
    ├── TypeBadgeArea / PolicyTypeIcon + TypeLabel
    ├── DescriptionArea / DescriptionLabel
    ├── CostBadgeArea / CostLabel
    ├── SelectedOverlay
    ├── DisabledOverlay
    └── SelectedStamp
```

Default display size is `240x360` at 100% UI scale. The source asset is `360x540`, so it remains clear while avoiding excessive package growth.

## Text Safe Areas

Text is now positioned through `scripts/ui/ArtLayoutSpecs.gd`, using normalized card-local rectangles instead of one-off offsets in `PolicyCard.gd`.

- Title: `title_rect`, centered in the top nameplate and moved down from the previous over-high position.
- Type badge: `category_rect`, centered on the lower badge. On formal card art, the old policy-type icon is hidden so it no longer pushes the label right/down.
- Description: `description_rect`, moved upward into the parchment text panel with stronger dark text.
- Cost: `cost_rect`, centered in the bottom-right badge and now displays only the dynamic number.

The description area intentionally leaves the right side clear for the policy point badge.

`ArtLayoutSpecs.policy_card_spec(policy_id)` supports per-policy overrides. The first override is used for `expansionary_monetary_policy`, whose generated art needed a slightly different title/category/description/cost calibration.

`ArtLayoutSpecs.DEBUG_SAFE_AREAS` can be enabled during development to draw title/category/description/cost safe rectangles. It is disabled by default.

## Interaction States

Preserved:

- click-to-select behavior;
- policy id and policy name signal;
- selected / unselected state;
- hover feedback;
- budget and policy cost logic in `PolicyDesk`;
- MacroEngine input data.

Visual states:

- Default: full card face with dynamic text.
- Hover: very light scale to `1.04` and a subtle gold border overlay.
- Selected: stronger gold overlay and `已选` stamp.
- Missing art: procedural card fallback plus dynamic text and type icon fallback.

No large hover preview was added in this pass.

## Fallback Rules

`ArtAssetRegistry.texture_for_policy_card(policy_id, policy_type, policy_name)` remains the central entry point.

Fallback order:

1. exact policy id card face;
2. policy-name/type heuristic mapping to one of the six current card faces;
3. small policy type icon via `texture_for_policy_type`;
4. text placeholder / procedural card fallback.

Missing image assets should not crash the card.

## Pending Manual Review

- Confirm that the default `240x360` display size is readable enough in the left policy column.
- Confirm whether policy point display should stay visible even in single-policy teaching levels.
- Confirm whether the `1.04` hover scale feels good inside the ScrollContainer.
- Confirm whether a later round should add an optional hover enlargement preview.
- Confirm the new number-only cost display is visually centered in each badge.
- Confirm the darker description text is readable enough at the default `240x360` display size.
