# UI Skin v1 Implementation

## 1. 本轮目标

本轮实现第一轮“架空古典政务策略风”UI 皮肤。目标是把现有蓝黑色功能原型初步统一为国政卷宗、内阁奏报、政策法令、学士院推演的视觉语言。

本轮只使用 Godot 程序化 UI：`StyleBoxFlat`、颜色常量、自绘控件和轻量 `Tween`。未新增图片、头像、音频、视频或序列帧资源。

## 2. 依据

已找到并参考 `docs/Art_Asset_Audit_v1.md`。本轮优先处理其中的 P0 项：

- LevelSelect 关卡选择页
- DialogueOverlay 剧情对话框
- PolicyCard 政策卡牌
- 通用按钮
- 智慧点数区域
- HintConfirmModal
- 高亮框和遮罩

## 3. 实际修改文件

| 文件 | 修改内容 |
|---|---|
| `scripts/ui/ClassicalTheme.gd` | 新增古典政务风样式 helper，集中管理颜色、面板、按钮、卡牌、弹窗、对话框、头像占位和轻量 Tween |
| `scripts/scenes/LevelSelect.gd` | 关卡选择页改为卷宗/档案格风格，关卡格使用铜边、暗金高亮、hover 反馈，锁定点击有轻提示闪烁 |
| `scripts/ui/DialogueOverlay.gd` | 对话框改为暗色奏报框，增加暗金边框、徽章头像占位、柔和遮罩、淡入和高亮框呼吸效果 |
| `scripts/ui/PolicyCard.gd` | 政策卡改为政令/奏章卡风格，统一暗色卡底、铜边、暗金选中态、hover 放大和“已选”印记 |
| `scripts/scenes/PolicyDesk.gd` | 政策桌面背景、主要面板、确认政策、提示、缩放、理论、模型回放、本轮总结按钮接入统一皮肤 |
| `scripts/ui/HintConfirmModal.gd` | 提示确认弹窗改为卷宗式弹窗，统一遮罩、按钮和淡入效果 |
| `scripts/ui/MacroStatBar.gd` | 状态条从现代蓝色改为账册/铜色刻度风格，保留原数据逻辑 |
| `scripts/ui/ISLMChart.gd` | 模型回放图外观换为学士院推演图色系，保留原绘图逻辑 |
| `scripts/ui/ISLMReplayPanel.gd` | 模型回放窗口外框与关闭按钮接入统一皮肤 |
| `scripts/ui/TheoryISLMGraph.gd` | 理论图色系改为暗底、铜边、低饱和曲线，保留冲击图逻辑 |
| `scripts/scenes/Result.gd` | 本轮结果页背景、面板和按钮接入统一皮肤 |
| `scripts/scenes/FinalSummary.gd` | 最终总结页背景、模块面板和按钮接入统一皮肤 |
| `scripts/scenes/ScenarioIntro.gd` | fallback 情景页背景、面板和继续按钮接入统一皮肤 |

## 4. 样式 helper

新增 `scripts/ui/ClassicalTheme.gd`，集中提供：

- 深墨黑、暗木、深皮革、羊皮纸暗底、暗金、铜色、旧银、米白等颜色常量；
- `panel_style(kind, ui_scale)`：生成章节、桌面、问题栏、地图、右侧面板、理论面板、弹窗、对话框、卡牌、关卡格等样式；
- `button_style(state, ui_scale, variant)` 与 `apply_button(...)`：统一按钮 normal / hover / pressed / disabled；
- `apply_label_color(...)`：统一标题、分节、正文、弱提示文字色；
- `avatar_style(...)`：为不同说话人生成程序化徽章头像占位；
- `hover_to(...)`、`fade_in(...)`、`shake_control(...)`：轻量 Tween 动效工具。

## 5. 页面改造

### LevelSelect

- 背景改为深色国政档案感；
- 标题区使用章节卷宗样式；
- 7 个数字关卡格改为铜边方牌；
- 已解锁 / 当前可选 / 已完成 / 锁定状态使用不同 StyleBox；
- hover 时轻微放大；
- 点击锁定关卡时状态提示短暂闪烁；
- 未改关卡映射、锁定、解锁和进入逻辑。

### DialogueOverlay

- 底部对话框改为暗色半透明奏报框；
- 边框改为暗金 / 铜色；
- 头像区域使用程序化徽章占位，内部仍显示角色首字；
- 说话人姓名使用暗金色，正文使用米白色；
- “单击以继续”使用浅金色；
- 遮罩改为更柔和的暗色；
- 高亮框改为暗金描边、圆角、轻微外发光和低频呼吸；
- 保留底部固定、长文本分页、左键推进、滚轮转发和 Ctrl+滚轮缩放兼容。

### PolicyCard

- 卡牌底板改为暗色法令卡；
- 政策名称使用暗金标题色；
- 政策类型保留清晰标签；
- 点数消耗改为右侧金色角标感；
- selected 状态增加暗金高亮和“已选”程序化印记；
- hover / unhover 使用 Tween 轻微缩放；
- 未改政策选择、点数、禁用和结算输入逻辑。

### Button / Wisdom / Modal

- 主要按钮统一为暗底、铜边、暗金 hover；
- 确认政策、请求提示、模型回放、本轮总结使用 primary 按钮；
- 关闭、回看、缩放、理论按钮使用 quiet 按钮；
- 智慧点数区域沿用当前布局，改为小型资源条质感；
- HintConfirmModal 使用卷宗式居中弹窗、柔和遮罩和淡入效果；
- 未改智慧点数扣除、取消不扣点、已解锁提示不重复扣点逻辑。

## 6. 基础动效

本轮已实现：

- 按钮 hover / pressed 视觉反馈；
- LevelSelect 关卡格 hover 放大；
- 锁定关卡点击提示闪烁；
- PolicyCard hover 放大；
- PolicyCard selected / unselected 样式切换；
- DialogueOverlay 淡入；
- HintConfirmModal 淡入；
- 高亮框低频呼吸。

后置未做：

- 大臣头像飞入；
- 对话框复杂上滑；
- 政策卡确认飞行动画；
- 智慧点数 `-2` 浮动；
- 模型曲线动画；
- FinalSummary 评分条动画；
- 季度转场动画；
- 音效。

## 7. 性能检查

本轮未新增图片、音频、视频或字体文件，未恢复完整中文字体。仍依赖现有自动中文字体子集脚本和 `index.wasm.gz` 导出流程。

本轮导出与部署记录：

- BuildId：`20260720-224348`
- 字体子集：492,644 bytes
- `index.pck`：724,324 bytes
- `index.wasm.gz`：10,111,653 bytes
- `index.js`：279,815 bytes
- `index.html`：10,266 bytes
- CloudBase 部署：成功
- 线上检查：`latest.json`、直接 release `index.html`、`index.pck`、`index.wasm.gz` 均返回 HTTP 200

本轮 PCK 从上一轮约 717 KB 增至约 724 KB，增长主要来自新增样式 helper 和脚本改动，未出现资源体积异常。

## 8. 已知限制

- 本轮是程序化皮肤 v1，缺少正式纸纹、木纹、徽章头像和图标资源；
- 部分旧 fallback 页面仍以功能稳定优先，只做轻量统一；
- 模型图只调整外观色系，未做曲线动画；
- 角色头像仍为首字 / 占位徽章；
- 复杂地图美术和正式图标留到后续资源接入阶段。

## 9. 下一轮建议

1. 制作 6 个角色徽章头像；
2. 制作政策类型小图标和智慧点数图标；
3. 给 LevelSelect 增加轻量完成印章图标；
4. 给 DialogueOverlay 接入徽章头像资源；
5. 第二轮再处理地图区域小图标和更细的图表外框；
6. 每轮新增资源后继续检查 `index.pck` 和 Web 首屏加载时间。

## Polish Pass Reverted

- The polish: refine classical governance UI skin pass was abandoned and rolled back.
- Reason: the visual gain was not clear enough, and the pass introduced a functional issue where the PolicyDesk policy-card area could become invisible or display incorrectly after entering a level.
- Current stable code is restored to the pre-polish UI Skin v1 version: commit e0c3778 feat: add classical governance UI skin v1.
- The project keeps the UI Skin v1 classical governance direction, including the first-pass LevelSelect, DialogueOverlay, PolicyCard, button, wisdom area, modal, and highlight styling.
- We will not continue over-polishing the pure procedural UI pass. The next art step should move toward image two resource generation and controlled lightweight asset integration.
- Re-exported and deployed the restored stable version. BuildId: 20260721-120817; index.pck 724,324 bytes; index.wasm.gz 10,111,653 bytes.
