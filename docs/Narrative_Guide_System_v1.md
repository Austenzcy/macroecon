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
