# Round1 P0 Art Minimal Integration

## 1. Scope

This pass integrates the first batch of P0 formal art assets with minimal UI and logic risk. It does not generate new images, rewrite UI layouts, change gameplay logic, alter narrative text, or modify model / scoring / settlement code.

Integrated asset groups:

- 6 character badge avatars.
- 8 policy type icons.
- Wisdom points icon.
- Level lock icon and level complete stamp.
- 4 MacroMap region icons.

Not integrated in this pass:

- P1 paper texture.
- P1 wood texture.
- Dossier corner decoration.
- Policy confirmation stamp animation.
- Large background art, portraits, audio, video, or sequence animation.

## 2. Registry

All image lookup remains centralized in `scripts/ui/ArtAssetRegistry.gd`.

The registry provides:

- `texture_for_character(speaker_id, avatar_id, speaker_name)`
- `texture_for_policy_type(policy_type, policy_id)`
- `texture_for_ui(key)`
- `texture_for_map_region(region_key)`
- `texture_for_slot(slot_key)`

If a texture is missing or a key cannot be matched, the registry returns `null`; the UI then keeps the existing procedural text badge fallback.

## 3. Character Badges

Integrated positions:

- `scripts/ui/DialogueOverlay.gd`
  - Node: `SpeakerBadgeTexture`
  - Display size: existing responsive avatar slot, roughly 66-92px.
  - Matching: `speaker_id`, `avatar`, and now also visible `speaker` name.
- `scripts/ui/AdvisorPanel.gd`
  - Node: `AdvisorBadgeTexture`
  - Display size: 70px slot.
  - Matching: advisor name routed to registry character keys.

Supported aliases include:

- `chief_minister`, `placeholder_chief_minister`, 首席大臣 / 大臣
- `economic_advisor`, `placeholder_economic_advisor`, `placeholder_advisor`, 首席经济顾问 / 经济顾问
- `fiscal_minister`, `finance_minister`, `placeholder_fiscal_minister`, `placeholder_finance_minister`, 财政大臣 / 财政部长
- `central_bank_governor`, `placeholder_central_bank_governor`, 中央银行行长 / 央行行长
- `industry_minister`, `placeholder_industry_minister`, 产业大臣 / 工业顾问
- `livelihood_minister`, `civil_affairs_minister`, `placeholder_livelihood_minister`, `placeholder_civil_affairs_minister`, 民生大臣 / 民生顾问 / 居民 / 市场

Fallback: original procedural character badge text such as `首`, `学`, `财`, `央`, `工`, `民`, or `顾`.

## 4. Policy Type Icons

Integrated position:

- `scripts/ui/PolicyCard.gd`
  - Node: `PolicyTypeIconTexture`
  - Display size: existing 28px icon shell, scaled with UI scale.

Mapping rules use both `policy_type` and `policy_id`:

- Fiscal expansion: 财政 / 政府 / `fiscal` / `government_purchase` / `purchase`
- Fiscal contraction: 紧缩 + 财政 / `contraction` + `fiscal`
- Monetary expansion: 扩张 + 货币 / `expansionary_monetary_policy`
- Monetary contraction: 紧缩 + 货币 / `contractionary_monetary_policy`
- Tax: 税 / `tax`
- Investment: 投资 / 企业 / 产业 / `invest`
- Consumption: 消费 / 居民 / 民生 / `consum`
- Financial stability: 金融 / 利率 / `financial` / `rate`

Fallback: original text badge such as `策`, `财`, `币`, `税`, `投`, `民`, or `金`.

## 5. Wisdom Points Icon

Integrated positions:

- `scripts/scenes/PolicyDesk.gd`
  - Node: `WisdomIconSlot` / `WisdomIconTexture`
  - Display size: 26px slot, scaled by UI scale.

Fallback: original `智` text marker.

The hint request / confirm / cancel / unlocked-repeat logic was not changed.

## 6. Level State Icons

Integrated positions:

- `scripts/scenes/LevelSelect.gd`
  - Locked levels: `ArtAssetRegistry.texture_for_ui("lock_level")`
  - Completed levels: `ArtAssetRegistry.texture_for_ui("level_complete")`
  - Display path: existing `Button.icon`.

Fallback: locked levels use the original `锁` text marker. Level unlock and completed-state logic was not changed.

## 7. MacroMap Region Icons

Integrated positions:

- `scripts/ui/MapRegion.gd`
  - Node: `RegionIconTexture`
  - Display size: existing 34px region icon shell, scaled by UI scale.

Region keys:

- `consumption`
- `industry`
- `finance`
- `government`

Fallback: original text badges `民`, `工`, `金`, `政`.

Map brightness, variable binding, arrows, and four-region layout were not changed.

## 8. Minimal Check

Performed lightweight static checks only:

- Confirmed 21 PNG files exist under `assets/art/`.
- Confirmed total art PNG size is about 806KB.
- Confirmed the relevant UI scripts reference the centralized registry rather than scattering raw paths.
- Confirmed Git changes are limited to minimal registry / speaker matching updates, documentation, and progress notes.

No broad automated gameplay test, screenshot suite, font subset regeneration, CloudBase deployment, or image generation was performed in this pass.

## 9. Manual Review Notes

Please manually verify:

- DialogueOverlay shows correct badges for all six ministers / advisor roles.
- Policy cards show appropriate small icons without crowding title or description text.
- Wisdom points icon remains readable next to the number.
- Locked and completed level states remain clear.
- MacroMap icons do not obscure region title or variable arrows.
- Existing fallback text badges still appear if a future asset is missing.

## 10. Known Limits

- P1 textures and decorative corner assets remain unintegrated.
- Policy matching is keyword-based and intentionally conservative; future policy categories may need new registry keys.
- This pass does not optimize imported Godot texture settings; export/import verification should happen during the later deployment pass.

## 11. P0 Asset Rendering Fix

After manual review, the UI still showed text fallbacks such as `财`, `币`, `民`, `工`, `金`, and `政` instead of the generated PNG assets.

Root cause:

- The P0 PNG files existed under `assets/art/`.
- The UI slots were already present: `PolicyTypeIconTexture`, `RegionIconTexture`, `WisdomIconTexture`, `SpeakerBadgeTexture`, and level button icons.
- However, the generated PNG files did not have Godot `.png.import` metadata yet, so `ResourceLoader.exists(path)` returned false and `load(path)` never produced a `Texture2D`.
- Because the registry returned `null`, each UI component correctly fell back to its procedural text badge.

Fix:

- `ArtAssetRegistry.gd` now keeps a small texture cache.
- `_load_texture(path)` still prefers Godot-imported `Texture2D` resources when available.
- If the imported resource is unavailable, the registry falls back to `FileAccess.file_exists(path)`, `Image.load(path)`, and `ImageTexture.create_from_image(image)`.
- This allows the existing P0 PNG files to render immediately without requiring this pass to run Godot import, regenerate fonts, or deploy.

Current priority render paths:

- Policy cards: `PolicyCard.gd` continues to show `PolicyTypeIconTexture` first and hides the text badge when a texture is available.
- MacroMap regions: `MapRegion.gd` continues to show `RegionIconTexture` first and hides `民` / `工` / `金` / `政` when a texture is available.
- LevelSelect: `LevelSelect.gd` uses `Button.icon` for lock and completion assets when available.
- Wisdom points: `PolicyDesk.gd` shows `WisdomIconTexture` when available.
- Dialogue / advisor badges: `DialogueOverlay.gd` and `AdvisorPanel.gd` show role badge textures when the speaker can be matched.

Fallback rule remains unchanged: if an image file is missing, invalid, or unmatched, the UI displays the original procedural text badge and does not crash.

This fix did not modify PNG files, call image two, generate new art, run the font subset script, deploy CloudBase, or perform broad automated UI validation.
