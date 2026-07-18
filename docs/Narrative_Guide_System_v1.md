# Narrative Guide System v1

## 用途

本系统用于 IS-LM 章节的剧情对话、新手引导、智慧点数提示和季度时间标签。当前版本是功能框架，只使用少量 mock 文案验证流程，不接入完整剧情 JSON。

## 对话框机制

- `NarrativeManager` 是全局 Autoload，负责播放对话序列、记录已播放引导、管理智慧点数和季度标签。
- `DialogueOverlay` 是底部对话层，每次只显示一句发言。
- 玩家单击对话层后进入下一句。
- 引导播放时画面整体变暗。
- 如果 step 配置了 target，`DialogueOverlay` 会根据真实 Control 节点位置绘制高亮矩形。
- 如果 target 不存在或不可见，系统自动退化为普通底部对话，不中断流程。

## 角色配置

当前在 `NarrativeManager.characters` 中保留基础角色配置，并使用占位头像显示首字。

- `chief_minister`：首席大臣
- `fiscal_minister`：财政大臣
- `central_bank_governor`：中央银行行长
- `industry_minister`：产业大臣
- `livelihood_minister`：民生大臣
- `economic_advisor`：首席经济顾问

## 新手引导触发点

- 第一次进入第 1 关 PolicyDesk：引导当前问题栏、理论面板入口、政策卡牌区、右侧信息面板。
- 第 1 关基础界面引导完成后：介绍智慧点数和提示机制。
- 玩家第一次选择政策卡后：引导确认政策按钮。
- 玩家第一次确认政策后且模型回放按钮出现时：引导模型回放按钮。
- 玩家第一次打开模型回放窗口时：解释模型回放窗口用途。
- 玩家第一次进入 budget / training 模式：引导政策点数和政策卡牌区。
- 第一次进入启用评分的 FinalSummary：引导评分模块。basic / demo 未启用评分时不触发。

## UI Target Mapping 审计结果

当前主要 UI 由脚本运行时构建，因此本轮在构建时给关键节点设置了稳定名称，并在 `PolicyDesk.gd` / `FinalSummary.gd` 中注册到 target map。

| target id | 实际节点来源 | 当前状态 |
| --- | --- | --- |
| `problem_panel` | `PolicyDesk/ScrollContainer/MarginContainer/MarginContainer/VBoxContainer/ProblemPanel` | 可高亮 |
| `theory_panel` | 当前映射到 `TheoryPanelButton`；理论面板默认关闭，按钮是稳定入口 | 可高亮 |
| `theory_button` | `PolicyDesk/.../MacroMapPanel/.../TheoryPanelButton` | 可高亮 |
| `macro_map` / `map_panel` | `PolicyDesk/.../MacroMapPanel` | 可高亮 |
| `policy_cards` | `PolicyDesk/.../PolicyCardsArea` | 可高亮 |
| `policy_points_area` | budget 模式下的 `PolicyPointsArea` Label | budget 可高亮；single 中不存在，自动 fallback |
| `right_info_panel` | `PolicyDesk/.../RightInfoPanel` | 可高亮 |
| `confirm_policy_button` | `PolicyDesk/.../ConfirmPolicyButton` | 可高亮 |
| `model_replay_button` | 政策确认后右侧面板内的 `ModelReplayButton` | 仅有 IS-LM model result 时可高亮；demo fallback |
| `round_summary_button` | 政策确认后右侧面板内的 `RoundSummaryButton` | 可高亮 |
| `model_replay_window` | 打开的模型回放 overlay / `ModelReplayWindow` | 可高亮 |
| `score_panel` | `FinalSummary/.../ScorePanel` | 评分启用时可高亮 |
| `basic_entry` | LevelSelect 卡片中的 `BasicEntryButton` | 已具名，当前未触发引导 |
| `training_entry` | LevelSelect 卡片中的 `TrainingEntryButton` | 已具名，当前未触发引导 |

暂未定位到独立的 `RightInfoPanel.tscn`、`MacroMapView.tscn` 或 `TheoryPanel.tscn`，因为这些区域目前由 `PolicyDesk.gd` 动态创建。当前映射以运行时节点引用为准。

## 智慧点数规则

- 初始智慧点数：10。
- 每次解锁新提示消耗：2。
- 每关最多 3 条提示。
- 点击“请求提示”后先弹出确认框。
- 确认后扣点并播放提示。
- 取消不扣点。
- 已解锁提示可以通过“回看”重复查看，不重复扣点。
- 智慧点数暂时不参与 ScoreEngine 评分。

## 季度时间标签

季度标签显示在 PolicyDesk 顶部栏，模型标签右侧、智慧点数区域左侧。

规则：

- 第 1 个关卡：公元1000年 第一季度。
- 第 2 个关卡：公元1000年 第二季度。
- 第 3 个关卡：公元1000年 第三季度。
- 第 4 个关卡：公元1000年 第四季度。
- 第 5 个关卡：公元1001年 第一季度。

当前根据 `scenarios.json` 中 `level_group` 的出现顺序计算季度，basic / training 共享同一季度。

## 当前 Mock 数据

当前只内置少量 mock 文案：

- 第 1 关基础 UI 引导。
- budget 模式政策点数引导。
- 确认政策引导。
- 模型回放按钮和回放窗口引导。
- consumer confidence 关卡的三层智慧提示。
- 其他关卡使用通用 fallback 提示。

## 后续接入完整剧情 JSON

后续可把完整 `ISLM_chapter_narrative_v1.json` 映射到：

- `characters`
- `quarter_intro`
- `ui_tutorial_steps`
- `policy_debate`
- `hints`
- `after_result_comments`
- `level_end_dialogue`

UI 脚本不应硬编码正式剧情，只负责调用 `NarrativeManager` 播放数据驱动的 steps。

## 当前限制

- 不含正式角色头像。
- 不含打字机动画、语音、音效或双人同屏对话。
- 不做长期存档，当前状态只在一次运行流程中保存。
- 智慧点数不进入评分。
- LevelSelect 入口已具名但当前未启用入口引导。

## Overlay 稳定性修复记录

人工验收时发现底部对话框、提示弹窗和高亮框曾受到 PolicyDesk 滚动 / UI 缩放 / 父容器裁切影响，表现为对话框跑到左上角、文字被裁切、Ctrl+滚轮缩放后 Overlay 消失。

当前修复方案：

- `DialogueOverlay` 不再挂到 `PolicyDesk` 普通 Control 子节点下，而是由 `NarrativeManager` 创建 `DialogueOverlayLayer` (`CanvasLayer.layer = 100`) 并挂到当前 `SceneTree.root`。
- `HintConfirmModal` 不再挂到 `PolicyDesk` 普通 Control 子节点下，而是由 `NarrativeManager` 创建 `HintConfirmModalLayer` (`CanvasLayer.layer = 101`) 并挂到当前 `SceneTree.root`。
- `DialogueOverlay` 根节点使用 full rect anchors；底部对话框使用全屏 `MarginContainer + VBoxContainer + spacer + PanelContainer` 固定在 viewport 底部，不依赖写死屏幕坐标。
- `HintConfirmModal` 使用 full rect 根节点和 `CenterContainer` 居中显示，避免被 ScrollContainer / Panel / MarginContainer 裁切。
- 高亮框仍基于目标 Control 的 `get_global_rect()` 计算；Overlay 位于全屏 CanvasLayer 后，用目标全局矩形减去 Overlay 全局原点，转换到 Overlay 本地坐标绘制。
- `DialogueOverlay` 在可见时每帧 `queue_redraw()`，因此页面滚动、窗口尺寸变化或 UI 缩放后，高亮框会重新读取目标 Control 的当前屏幕位置。
- PolicyDesk 缩放会重建主界面；重建后 `_register_guide_targets()` 会调用 `NarrativeManager.refresh_target_map(...)`，把新的运行时节点引用同步给当前 Overlay。若目标暂时不存在，只隐藏高亮框，不关闭底部对话框。

已知限制：

- 当前高亮为矩形框，不支持不规则镂空遮罩。
- 若目标节点滚动到 viewport 外，高亮框会按目标全局位置绘制，后续可增加“自动滚动到目标”。
- Ctrl+滚轮缩放由 PolicyDesk 处理；Overlay 位于独立 CanvasLayer，不会随 PolicyDesk 内容缩放或被 `_build_ui()` 重建删除。

## 点击推进与输入阻断

人工验收时发现 DialogueOverlay 可见但无法点击进入下一句，同时底层 PolicyDesk 仍能选择政策卡和确认政策。当前修复采用两层防护：

### DialogueOverlay 输入处理

- `DialogueOverlay` 根 Control 覆盖整个 viewport，并保持 `mouse_filter = STOP`。
- Overlay 使用 `_input(event)` 统一监听鼠标左键、触摸、Enter 和 Space。
- 任意 Overlay 区域点击都会调用 `_advance()`，每次只推进一条 dialogue step。
- 推进后调用 `get_viewport().set_input_as_handled()`，避免同一次点击继续传到底层 PolicyDesk。
- 对话框、头像、文本、提示小字等子 Control 统一设置 `mouse_filter = IGNORE`，避免子节点吃掉点击但不推进。
- 如果 `HintConfirmModal` 正在显示，DialogueOverlay 不响应点击，避免点击确认弹窗背景时误推进剧情。

### NarrativeManager 输入锁

`NarrativeManager` 提供：

- `is_dialogue_active()`
- `is_modal_active()`
- `is_blocking_game_input()`

当剧情 Overlay 或提示确认弹窗存在时，`is_blocking_game_input()` 返回 true。

### PolicyDesk 防穿透入口

以下操作入口已加入 `NarrativeManager.is_blocking_game_input()` 防御：

- 政策卡选择 `_on_policy_selected`
- 确认政策 `_on_confirm_policy`
- 本轮总结 `_on_round_summary_pressed`
- 打开模型回放 `_on_open_replay_pressed`
- 关闭模型回放 `_on_replay_closed`
- 理论面板开关 `_on_toggle_theory_panel`
- 缩放按钮 `_on_zoom_out` / `_on_zoom_in` / `_on_zoom_reset`
- 请求提示 `_on_request_hint_pressed`
- 回看提示 `_on_review_hint_pressed`

当前所有新手引导 step 都是“点击继续”模式，不允许玩家在高亮区域直接操作底层 UI。后续如果需要“允许指定目标点击”的教程步骤，将单独设计交互模式。

## Dialogue Layout Stabilization and ScenarioIntro Skip

Formal narrative text is longer than the original mock dialogue, so the dialogue layer now uses a viewport-sized root Control under `DialogueOverlayLayer` instead of relying only on anchors. A `CanvasLayer` is not a Control parent, so anchors alone can leave the overlay root at a tiny default size and make the dialogue box appear near the upper-left corner. The overlay now synchronizes its root position and size with the viewport every frame while visible.

Current layout:
- `DialogueOverlayLayer` is attached to `SceneTree.root` with `CanvasLayer.layer = 100`.
- `DialogueOverlay` root covers the full viewport.
- The dim layer and highlight drawing use the same full-viewport coordinate space.
- The dialogue box is placed by a full-rect `MarginContainer` and a vertical spacer, so it stays fixed at the bottom.
- The dialogue box uses about 30% of viewport height, clamped to a readable range.
- Width is controlled by responsive side margins, keeping the box close to full width without touching the screen edge.

Long text pagination:
- JSON dialogue is not modified.
- Runtime dialogue steps are expanded into internal pages.
- Each page preserves the original `speaker`, `avatar`, `target`, and `continue_text`.
- Splitting prefers Chinese punctuation: `。` `；` `！` `？` `，`.
- If no good punctuation boundary exists, the text falls back to a character-count split.
- Each click advances one page; after all pages of a step are shown, the next dialogue step begins.

Formal IS-LM chapter flow:
- Scenarios with `narrative_level_id` and formal `opening_dialogue` skip the legacy `ScenarioIntro`.
- `LevelSelect` and Quick Start route those scenarios directly to `PolicyDesk`.
- `PolicyDesk` becomes the visual background for quarter and level-opening dialogue.
- The old `ScenarioIntro` scene is kept as fallback for scenarios without formal narrative opening.
- `ScenarioIntro` fallback now uses `ScrollContainer` and supports Ctrl + mouse wheel UI scaling.

Scroll and zoom self-check notes:
- `MainMenu` remains compact and does not require scrolling in the current layout.
- `LevelSelect` uses `ScrollContainer`.
- `PolicyDesk` keeps its internal `ScrollContainer`, black safe margins, and Ctrl + wheel scale.
- `DialogueOverlay` and `HintConfirmModal` use viewport-sized roots under CanvasLayer, so they do not move with PolicyDesk scrolling or UI rebuilding.
- `Result`, `ModelReplay`, and `FinalSummary` already use scrollable panel layouts for small viewport heights.

Known limits:
- Dialogue pagination is character-count based and not a full text-measurement layout engine.
- Highlight rectangles are still rectangular and do not auto-scroll hidden targets into view.
- Ctrl + wheel scaling is scene-level; a future global UI scale manager could unify behavior across all screens.

## Level Flow Refinement

The formal web entry now uses `LevelSelect` directly as the Godot main scene. `MainMenu` is kept as a fallback scene, but its script immediately redirects to `LevelSelect`, so players no longer see a two-button home page or a Quick Start entry in the normal flow.

`LevelSelect` is simplified into seven chapter boxes labeled `1` through `7`. The UI no longer exposes the old `basic` / `training` branch choice. Internally, the project still keeps those scenarios for data and testing, but the visible chapter route maps them into a single ordered path:

1. `consumer_confidence_drop_basic`
2. `investment_confidence_drop_training`
3. `money_market_tightening_training`
4. `overheating_and_cooling_training`
5. `fiscal_expansion_crowding_out_training`
6. `double_shock_investment_and_money_demand_training`
7. `two_round_stabilization_challenge_training`

Runtime unlocking is handled by `GameState.unlocked_visible_level`. The first level is unlocked at startup. Completing a level and returning from `FinalSummary` calls `GameState.mark_current_visible_level_completed()`, which unlocks the next visible level. This is currently runtime-only and does not introduce a persistent save system.

Round counts are now tied to the visible chapter path:

- Levels 1-5: 1 round.
- Levels 6-7: 2 rounds.

The chapter timeline is continuous across the visible path rather than being reset inside hidden scenario groups. The quarter index is:

`global_quarter_index = sum(round_count of visible levels before current level) + (current_round - 1)`

The label is then computed from year 1000, quarter 1.

Narrative playback is scoped by tutorial type:

- `chapter_opening` only plays in visible level 1 and only once per runtime session.
- `basic_desk_tutorial` only plays in visible level 1 and only once.
- Each visible level may still play its own `level_opening`.
- `policy_points_tutorial` plays once when the first budget/model level appears.
- Confirm-policy guidance plays after the first level's first successful policy card selection.
- Round-summary guidance plays after the first level's result comments and highlights the round summary button.
- Model replay guidance is delayed until the first budget/model level has confirmed policy and the replay button is available.

During `DialogueOverlay`, left-click and touch advance dialogue and remain blocked from the gameplay layer. Mouse wheel is forwarded to the active scene's `handle_narrative_wheel(...)`; ordinary wheel scrolls the current page, while Ctrl + wheel uses the scene's UI scaling where available. If the highlighted target scrolls out of view, the overlay keeps running and refreshes the highlight on the next frame instead of closing.
## Formal JSON Integration v1

本轮已接入两份正式 IS-LM 章节 JSON：

- `data/chapters/ISLM_chapter_demo_content_v1.json`
- `data/chapters/ISLM_chapter_narrative_v1.json`

接入方式：

- `ISLM_chapter_demo_content_v1.json` 作为正式关卡内容来源，已合并生成运行用的 `data/scenarios.json`。
- `data/scenarios.json` 保留现有运行字段，包括 `selection_mode`、`settlement_mode`、`model_type`、`shock_type`、`model_tags`、`available_policies`、`score_config`、`initial_state`、`model_params` 和 `round_count`。
- `ISLM_chapter_narrative_v1.json` 作为剧情来源，由 `NarrativeManager` 动态读取。
- `NarrativeManager` 会从 JSON 读取 `characters`、`chapter_opening`、`tutorial_sequences`、每关 `opening_dialogue`、`hints`、`after_result_comments` 和 `level_end_dialogue`。
- JSON 中的 `speaker_id`、`speaker_name`、`avatar`、`text`、`target` 会被适配成 `DialogueOverlay` 使用的 step 结构。
- 如果某个字段缺失，则使用原有 fallback 文案，不让关卡流程崩溃。

当前 7 个正式 IS-LM 关卡已接入 LevelSelect：

1. 消费信心下滑
2. 投资信心下降
3. 货币市场紧张
4. 经济过热与政策降温
5. 财政扩张与挤出效应
6. 双重冲击：投资下降与货币需求上升
7. 两回合综合治理挑战

前 4 关提供 `basic + training` 两个入口；第 5-7 关按正式内容仅提供 `training` 入口。

智慧点数提示现在从每关 narrative JSON 的 `hints` 字段读取，仍保留：

- 查看前确认扣点；
- 取消不扣点；
- 已解锁提示回看不重复扣点；
- 智慧点数暂不参与评分。

字体子集已根据当前项目文本、两份正式 JSON、fallback 文案和经济学符号重新生成。正式剧情接入后仍使用子集字体，不恢复完整 17 MB 字体。

当前限制：

- 本轮未接入更复杂的剧情分支系统。
- `after_result_comments` 当前按 JSON 顺序播放，`condition` 字段暂不做精细判定。
- 正式角色头像仍使用占位头像。
- 本轮未修改 DialogueOverlay 底层输入和高亮机制。
