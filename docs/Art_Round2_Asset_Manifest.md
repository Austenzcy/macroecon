# Art Round2 Asset Manifest

## Integration Summary

Round2 adds human character portraits, vertical policy-card visuals, and macro-map region scene assets. The older Round1 badge/icon assets are retained only as secondary icons or fallbacks.

## Character Portraits

| Role | File | Use | Integrated | Fallback |
| --- | --- | --- | --- | --- |
| 首席大臣 | `assets/art/characters/portraits/portrait_chief_minister.png` | DialogueOverlay / AdvisorPanel portrait slot | Yes | `badge_chief_minister.png`, then text |
| 首席经济顾问 | `assets/art/characters/portraits/portrait_economic_advisor.png` | DialogueOverlay / AdvisorPanel portrait slot | Yes | `badge_economic_advisor.png`, then text |
| 财政大臣 / 财政部长 | `assets/art/characters/portraits/portrait_fiscal_minister.png` | DialogueOverlay / AdvisorPanel portrait slot | Yes | `badge_fiscal_minister.png`, then text |
| 中央银行行长 | `assets/art/characters/portraits/portrait_central_bank_governor.png` | DialogueOverlay / AdvisorPanel portrait slot | Yes | `badge_central_bank_governor.png`, then text |
| 产业大臣 | `assets/art/characters/portraits/portrait_industry_minister.png` | DialogueOverlay / AdvisorPanel portrait slot | Yes | `badge_industry_minister.png`, then text |
| 民生大臣 | `assets/art/characters/portraits/portrait_livelihood_minister.png` | DialogueOverlay / AdvisorPanel portrait slot | Yes | `badge_livelihood_minister.png`, then text |

Display slots:

- DialogueOverlay: roughly 72-96 px, clipped to the avatar frame.
- AdvisorPanel: roughly 64-88 px, clipped to the avatar frame.

## Policy Card Visuals

| Policy | File | Use | Integrated | Fallback |
| --- | --- | --- | --- | --- |
| 增加政府购买 | `assets/art/policy_cards/policy_card_government_purchase.png` | PolicyCard top visual slot | Yes | Policy type icon / text badge |
| 减税 | `assets/art/policy_cards/policy_card_tax_cut.png` | PolicyCard top visual slot | Yes | Policy type icon / text badge |
| 扩张性货币政策 | `assets/art/policy_cards/policy_card_monetary_expand.png` | PolicyCard top visual slot | Yes | Policy type icon / text badge |
| 收缩性财政政策 | `assets/art/policy_cards/policy_card_fiscal_contract.png` | PolicyCard top visual slot | Yes | Policy type icon / text badge |
| 收缩性货币政策 | `assets/art/policy_cards/policy_card_monetary_contract.png` | PolicyCard top visual slot | Yes | Policy type icon / text badge |
| 维持政策不变 | `assets/art/policy_cards/policy_card_keep_unchanged.png` | PolicyCard top visual slot | Yes | Policy type icon / text badge |

Display slots:

- PolicyCard card-art slot: fixed-height clipped slot near the top of the existing policy card.
- Policy type icon: remains a small auxiliary icon only.

## Macro Map Region Scenes

| Region | File | Use | Integrated | Fallback |
| --- | --- | --- | --- | --- |
| 居民消费区 | `assets/art/map_regions/region_scene_consumption.png` | MapRegion visual slot | Yes | `icon_region_consumption.png`, then text |
| 工业产区 | `assets/art/map_regions/region_scene_industry.png` | MapRegion visual slot | Yes | `icon_region_industry.png`, then text |
| 金融市场区 | `assets/art/map_regions/region_scene_finance.png` | MapRegion visual slot | Yes | `icon_region_finance.png`, then text |
| 政府部门区 | `assets/art/map_regions/region_scene_government.png` | MapRegion visual slot | Yes | `icon_region_government.png`, then text |

Display slots:

- MapRegion scene slot: clipped, constrained map vignette slot above the region title.
- Existing variables and arrows remain below the title.

## Retained Round1 Assets

| Resource | File | Current Use |
| --- | --- | --- |
| Wisdom points icon | `assets/art/icons/ui/icon_wisdom_points.png` | PolicyDesk top wisdom panel |
| Lock icon | `assets/art/icons/ui/icon_lock_level.png` | LevelSelect locked levels |
| Complete stamp | `assets/art/stamps/stamp_level_complete.png` | LevelSelect completed levels |
| Policy type icons | `assets/art/icons/policies/*.png` | Small auxiliary policy category icon |
| Old character badges | `assets/art/characters/badges/*.png` | Fallback only |
| Old map region icons | `assets/art/icons/map/*.png` | Fallback only |

## Generated Source Notes

- Image generation used the built-in image tool with a flat #00ff00 chroma-key background.
- Final project assets were cropped, chroma-keyed to alpha, despilled, and resized to UI-appropriate dimensions.
- No external images or downloaded asset packs were used.

## Manual Review Checklist

- Character portraits read as people, not abstract badges.
- Policy cards read as vertical decree cards and do not squeeze policy text.
- Map regions read as sandbox / national region scenes, not four circular buttons.
- Images do not overflow their slots.
- Gameplay flow, policy selection, narrative overlay, wisdom hints, and model replay remain unchanged.
