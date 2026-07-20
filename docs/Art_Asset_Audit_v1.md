# Art Asset Audit v1

## 1. 项目当前美术状态概述

当前项目是 Godot 4.7 Standard / GDScript / Web 导出的宏观经济学策略教学游戏。主流程已经从 LevelSelect 进入 7 个 IS-LM 关卡，并包含 PolicyDesk、DialogueOverlay、智慧点数、模型回放、Result、FinalSummary 等页面。

当前视觉实现以程序化 UI 为主：

- 大多数页面的真实 UI 节点由 `.gd` 脚本动态创建，而不是完整写在 `.tscn` 中。
- `scenes/*.tscn` 多数只保留一个根 `Control` 并挂载脚本。
- 复用组件集中在 `scenes/components/` 与 `scripts/ui/`。
- 现有图片资源几乎为空，当前实际打包资源主要是字体子集。
- 主题文件 `themes/default_theme.tres` 很小，目前仍未形成完整视觉系统。
- Web 加载性能是硬约束，第一轮美术应优先使用 Theme / StyleBox / Tween / 自绘 Control，谨慎添加图片。

美术方向应从当前“蓝黑色功能原型”升级为“架空古典政务策略风”：玩家应感觉自己坐在国政桌前，听大臣奏报，查看国家沙盘，批阅政策法令，并通过学士院推演理解经济模型。

## 2. 当前真实文件 / 场景审计

| 类型 | 当前路径 | 真实结构 / 备注 | 美术审计结论 |
|---|---|---|---|
| 项目配置 | `project.godot` | 主场景为 `res://scenes/LevelSelect.tscn`，自定义主题为 `res://themes/default_theme.tres`，autoload 包含 `GameState`、`AudioManager`、`DataLoader`、`NarrativeManager` | 美术应优先建立全局 Theme，不要逐页堆样式 |
| 导出配置 | `export_presets.cfg` | Web 导出配置存在 | 新资源加入后必须复查 PCK 体积 |
| 导出脚本 | `scripts/export_web.ps1` | 导出前自动生成字体子集，导出后生成 `index.wasm.gz` 并注入加载补丁 | 美术资源不能破坏字体子集和 wasm.gz 流程 |
| 字体脚本 | `scripts/generate_font_subset.py` | 自动扫描项目文本生成中文字体子集 | 新 UI 文案、图标标签加入后应自动覆盖用字 |
| 关卡选择 | `scenes/LevelSelect.tscn` + `scripts/scenes/LevelSelect.gd` | 根 `Control`，脚本动态创建背景、`ScrollContainer`、标题面板、7 个数字按钮、状态提示 | 第一轮美术 P0 |
| 政策桌面 | `scenes/PolicyDesk.tscn` + `scripts/scenes/PolicyDesk.gd` | 根 `Control`，动态创建政策卡区、当前问题栏、地图、理论面板、右侧面板、会议记录、确认按钮、缩放控件、智慧点数 | 第一轮美术 P0 |
| 剧情对话层 | `scripts/ui/DialogueOverlay.gd` | 由 `NarrativeManager` 动态创建到 `CanvasLayer`，底部对话框、遮罩、高亮框均由脚本创建 / 绘制 | 第一轮美术 P0 |
| 提示确认弹窗 | `scripts/ui/HintConfirmModal.gd` | 动态创建全屏遮罩和居中 `HintConfirmBox` | 第一轮美术 P0 |
| 本轮结果 | `scenes/Result.tscn` + `scripts/scenes/Result.gd` | 根 `Control`，动态创建 ScrollContainer、结果面板、变量变化、机制总结、关闭/下一步按钮 | 第一轮可轻改外框，P1 |
| 最终总结 | `scenes/FinalSummary.tscn` + `scripts/scenes/FinalSummary.gd` | 根 `Control`，动态创建标题、回合历史、变量轨迹、学习总结、评分、长期视角模块 | 第二轮整体美术，P2 |
| 模型回放 | `scenes/components/ISLMReplayPanel.tscn` + `scripts/ui/ISLMReplayPanel.gd` + `scripts/ui/ISLMChart.gd` | 面板由脚本填充，曲线由 `_draw()` 绘制 | 保持教学清晰，第一轮只做外框 P1 |
| 理论图 | `scripts/ui/TheoryISLMGraph.gd` | 由 `_draw()` 绘制 IS-LM 冲击示意图 | 保持清晰，第一轮只做外框 P1 |
| 国家地图 | `scenes/components/MapRegion.tscn` + `scripts/ui/MapRegion.gd`，由 `PolicyDesk.gd` 组装 | 四区域矩形地图，区域亮度和变量箭头已接入 | 第一轮做古典化边框和小图标 P1 |
| 政策卡 | `scenes/components/PolicyCard.tscn` + `scripts/ui/PolicyCard.gd` | `PanelContainer` 动态生成标题、类型、cost、描述，已有 hover/selected Tween | 第一轮美术 P0 |
| 状态条 | `scripts/ui/MacroStatBar.gd` | 自绘参考值、指针、状态条 | 可程序化强化，P1 |
| 辅助面板 | `AdvisorPanel`、`IndicatorPanel`、`ModelTagBar` | 简单脚本生成 Label / Panel | 与通用面板风格统一即可 |
| 数据 | `data/scenarios.json`、`data/policies.json`、`data/chapters/*.json` | 正式剧情和关卡内容已接入；PowerShell 解析时可见编码/格式风险，但 Godot 路径已运行 | 美术不应改剧情数据；需注意字体覆盖 |
| 资源目录 | `assets/advisors`、`assets/audio`、`assets/cards`、`assets/map`、`assets/ui` | 当前基本为空；字体在 `assets/fonts` | 可以按新资源类型细分 |
| 字体 | `assets/fonts/NotoSansSC-Regular.ttf` | 当前为约 493KB 子集；完整字体以 `.bak` 保留且应排除导出 | 禁止重新打包 17MB 完整字体 |

## 3. 整体美术方向

目标风格：架空古典政务策略风。

关键词：

- 古典政务、国家治理、内阁会议、政策沙盘、战略地图；
- 危机决策、资源有限、季度奏报、国政卷宗；
- 暗金描边、深色木质、羊皮纸卷宗、金属徽章；
- 旧纸质感、经济账册、学士院推演。

边界：

- 不做纯现代金融仪表盘。
- 不做重书法、重传统纹样的古风页面。
- 现代经济学概念可以包装为“学士院推演”“国政沙盘”“季度奏报”“经济账册”。
- 图表、变量、政策点数必须保持可读性，教学优先。

## 4. 页面级资源清单

| 页面 / 场景 | 当前文件 / 脚本 | 当前视觉问题 | 推荐美术包装 | 图片资源需求 | 程序化 UI 建议 | 图标需求 | 动效建议 | 优先级 |
|---|---|---|---|---|---|---|---|---|
| LevelSelect 关卡选择页 | `scenes/LevelSelect.tscn`、`scripts/scenes/LevelSelect.gd` | 数字格子功能清楚，但缺少章节卷宗感；锁定/完成状态表达偏原型 | “第一章卷宗柜 / 政务档案格”，7 个格子像可批阅的季度档案 | 可选轻纸纹、锁图标、完成印章 | 背景、面板、格子、hover、选中全部用 Theme/StyleBox | 锁、完成章、当前关卡光标 | hover、锁定点击反馈、解锁亮起 | P0 |
| PolicyDesk 政策桌面 | `scenes/PolicyDesk.tscn`、`scripts/scenes/PolicyDesk.gd` | 信息密度高但仍像工具面板；缺少“国政桌 / 沙盘 / 议事厅”包装 | 深木桌面 + 暗金卷宗面板 + 中央国政沙盘 | 可选极轻木纹/纸纹；地图小图标 | 主体面板、按钮、卡牌、分隔线用 StyleBox | 政策、地图区、理论、回放、总结、智慧点数 | 卡牌 hover/盖章、按钮反馈、提示入口出现 | P0 |
| DialogueOverlay 剧情对话层 | `scripts/ui/DialogueOverlay.gd` | 底部对话框功能稳定，但视觉仍是普通深色框；头像为文字占位 | “内阁奏报对话框”，头像为金属徽章，底板像羊皮纸/深木匣 | 6 个角色徽章头像；可选对话框轻纹理 | 对话框底板、遮罩、高亮框用 StyleBox/自绘 | 角色徽章、继续提示小符号 | 淡入、底部上滑、头像切换 | P0 |
| HintConfirmModal 智慧提示确认 | `scripts/ui/HintConfirmModal.gd` | 弹窗可用但缺少“谏言/密函”感 | “学士院提示确认函” | 可选智慧点数图标、小蜡封 | 弹窗底板、按钮、遮罩程序化 | 智慧点数、确认、取消 | 淡入、扣点数字跳动 | P0 |
| Result 本轮结果页 | `scenes/Result.tscn`、`scripts/scenes/Result.gd` | 结构清晰，但像报告表单 | “季度奏报 / 本轮施政回执” | 可选章印小图标 | 面板、标题栏、变量行程序化 | 已执行政策、变量变化 | 页面淡入、模块依次出现 | P1 |
| 本轮总结区域 / 入口 | `RoundSummaryButton` 由 `PolicyDesk.gd` 动态创建，Result 页面承载总结 | 入口较普通 | “打开奏报”按钮或卷轴按钮 | 可选卷轴/文书图标 | 按钮用 Theme，图标小资源 | 卷宗 / 奏报 | 入口出现轻提示 | P1 |
| FinalSummary 最终总结 | `scenes/FinalSummary.tscn`、`scripts/scenes/FinalSummary.gd` | 模块化布局已合理，视觉仍偏工具 | “章节总案 / 治国总评卷宗” | 可选大印章、评分徽章 | 模块底板、评分条、轨迹文本程序化 | 回合历史、评分、长期视角 | 评分条填充、章节完成盖章 | P2 |
| Model Replay 模型回放窗口 | `scenes/components/ISLMReplayPanel.tscn`、`scripts/ui/ISLMReplayPanel.gd`、`scripts/ui/ISLMChart.gd` | 图表功能清晰，窗口外观偏现代 | “学士院推演图”外框 | 不必新增大图；可选小徽章 | 图表线条继续自绘；只改外框和按钮 | 坐标图、回放、关闭 | 后续曲线逐步绘制 | P1 |
| TheoryPanel 理论面板 | `PolicyDesk.gd` 动态创建，图为 `TheoryISLMGraph.gd` | 教学可读性优先，外框可更有学术卷宗感 | “学士院理论批注” | 不需要图片 | 继续自绘曲线，外框程序化 | 理论/图表按钮 | 面板展开淡入 | P1 |
| ScenarioIntro fallback | `scenes/ScenarioIntro.tscn`、`scripts/scenes/ScenarioIntro.gd` | 正式 IS-LM 已跳过，保留 fallback；视觉优先级低 | 旧新闻/访谈/顾问卡片可包装为卷宗材料 | 暂不需要 | 保持 StyleBox | 可选新闻/访谈/顾问小图标 | 轻切换 | P3 |
| Loading 页面 / Web 加载提示 | `scripts/export_web.ps1` 注入加载提示，`web_build/index.html` 为产物 | 加载体验已优化，但视觉较基础 | “载入国政档案 / 启动学士院推演”文字即可 | 不建议新增图片 | HTML/CSS 轻量文本和进度提示 | 不需要 | 简单闪烁/阶段文案 | P1 |

## 5. UI 组件级资源清单

| 组件 | 当前对应节点 / 脚本 | 视觉改造建议 | 静态资源需求 | 程序化实现建议 | 动画需求 | 优先级 |
|---|---|---|---|---|---|---|
| 通用面板 | 多处 `PanelContainer`，样式散在 `PolicyDesk.gd`、`Result.gd`、`FinalSummary.gd` 等 | 统一暗木 / 深纸 / 暗金描边风格 | 可选 1 张轻纸纹或木纹 | 建立 Theme + StyleBoxFlat 变体 | 无或淡入 | P0 |
| 通用按钮 | 所有 `Button` | 统一为“金属边框 + 暗底 + hover 金边” | 可选小图标 | Theme Button 样式 | hover/pressed | P0 |
| 关卡格子 | `LevelSelect.gd` 动态 Button | 做成小卷宗格 / 档案格 | 锁图标、完成印章 | Button StyleBox 状态 | hover、锁点击反馈、解锁亮起 | P0 |
| 锁定图标 | `LevelSelect._build_level_button` 文本锁 | 改成小锁符号/图标，避免字体依赖 | 1 个锁图标 | 可先用字体符号，后续 PNG/SVG | 锁定点击轻震 | P0 |
| 已完成标记 | `GameState.mark_current_visible_level_completed` 后可在 LevelSelect 表示 | 加“已阅 / 完成”章 | 1 个章印图标 | 可用 Label/StyleBox 先做 | 完成章弹入 | P1 |
| 当前关卡高亮 | LevelSelect 当前可进入格 | 暗金外框和轻光 | 不需要 | StyleBoxFlat 边框/阴影 | 呼吸或轻亮 | P1 |
| 政策卡牌 | `PolicyCard.gd` | 法令卡 / 政策文书卡，顶部政策名，类型徽章，点数角标 | 政策类型小图标 | 卡底板、边框、选中态用 StyleBox | hover、选中、盖章 | P0 |
| 政策类型徽章 | `PolicyCard._type_label` | 财政/货币/观望用不同徽章 | 3-5 个类型图标 | 背景胶囊可程序化 | 轻淡入 | P1 |
| 政策点数资源条 | `_policy_points_label` | “国库/政令资源”条 | 资源图标 1 个 | 条形或点数徽章程序化 | 点数变化跳动 | P1 |
| 智慧点数资源条 | `WisdomPanel`、`WisdomPointsLabel` | “智慧点数”做成学士院烛火/书页资源 | 智慧点数图标 1 个 | 数字和底板程序化 | 扣点 -2 浮动 | P0 |
| 请求提示按钮 | `RequestHintButton` | “请教顾问 / 查看谏言”按钮风格 | 可选问号/书本图标 | Button Theme | hover/pressed | P0 |
| 确认弹窗 | `HintConfirmModal.gd` | 密函确认框，确认/取消清晰 | 可选蜡封小图标 | Panel/Buttons 程序化 | 淡入 | P0 |
| 底部对话框 | `DialogueOverlay.gd` 中 `DialogueBox` | 深木框 + 羊皮纸内衬或暗色奏报框 | 可选轻纸纹；角色徽章 | 底板可 StyleBoxTexture/Flat | 淡入/上滑 | P0 |
| 角色头像框 | `DialogueOverlay._avatar_label` | 圆形金属徽章框 | 6 个头像徽章 | 头像框可程序化 | 说话人切换淡入 | P0 |
| 高亮框 | `DialogueOverlay._draw` | 暗金描边，轻呼吸 | 不需要 | 自绘 Rect + Tween alpha | 呼吸 | P0 |
| 遮罩层 | `DialogueOverlay._draw` / `HintConfirmModal` dim | 稳定半透明暗幕 | 不需要 | ColorRect / draw_rect | 淡入 | P0 |
| 状态条 | `MacroStatBar.gd` | 做成账册刻度 / 金属指针 | 不需要 | 自绘条、参考值、指针 | 后续数值滑动 | P1 |
| 变量变化箭头 | `_direction_arrow` / `_reference_arrow` 显示 | 保持清晰，颜色统一 | 不需要 | 字体符号 + 颜色 | 变化时闪一下 | P1 |
| 模型图按钮 | `TheoryPanelButton`、`ModelReplayButton` | 学士院推演图入口 | 图表/曲线图标 | Button Theme | 出现时轻提示 | P1 |
| 本轮总结按钮 | `RoundSummaryButton` | 打开季度奏报 | 卷宗图标 | Button Theme | 出现时轻提示 | P1 |
| 返回按钮 | Result / FinalSummary / LevelSelect | 统一导航按钮 | 可选返回箭头 | Button Theme | hover/pressed | P1 |
| 关闭按钮 | Result / Replay 等 | 统一小关闭按钮 | 可选 X 图标 | Button Theme | hover/pressed | P1 |

## 6. 角色资源清单

当前角色配置来自 `data/chapters/ISLM_chapter_narrative_v1.json`，`NarrativeManager.gd` 内也有 fallback 角色表。当前没有真实头像资源，DialogueOverlay 使用说话人首字/文本占位。

第一版建议使用“徽章头像”，不要直接制作复杂半身像。徽章头像能更快进入游戏，也更适合 Web 体积控制。

| 角色 | 当前状态 | 第一版资源形式 | 推荐徽章元素 | 推荐主色 | 表情变化 | 推荐尺寸 | 格式 | 路径建议 | 优先级 |
|---|---|---|---|---|---|---|---|---|---|
| 首席大臣 | JSON 配置 + 占位头像 | 徽章头像 | 王冠、鹰徽、卷轴 | 暗金 + 深红 | 后续可加严肃/认可 | 源 512x512，游戏 64-96px | PNG 或 WebP，透明 | `assets/art/characters/badges/chief_minister.png` | P0 |
| 财政大臣 | JSON 配置 + 占位头像 | 徽章头像 | 金币、国库、天平 | 金色 + 棕黑 | 后续加担忧/提醒 | 源 512x512，游戏 64-96px | PNG/WebP | `assets/art/characters/badges/fiscal_minister.png` | P0 |
| 中央银行行长 | JSON 配置 + 占位头像 | 徽章头像 | 铸币、银行柱、利率符号 | 银蓝 + 暗金 | 后续加谨慎/警示 | 源 512x512，游戏 64-96px | PNG/WebP | `assets/art/characters/badges/central_bank_governor.png` | P0 |
| 产业大臣 | JSON 配置 + 占位头像 | 徽章头像 | 齿轮、锤子、工坊 | 铜色 + 钢灰 | 后续加焦急/乐观 | 源 512x512，游戏 64-96px | PNG/WebP | `assets/art/characters/badges/industry_minister.png` | P0 |
| 民生大臣 | JSON 配置 + 占位头像 | 徽章头像 | 房屋、人群、麦穗 | 暖绿 + 米金 | 后续加担忧/安抚 | 源 512x512，游戏 64-96px | PNG/WebP | `assets/art/characters/badges/livelihood_minister.png` | P0 |
| 首席经济顾问 | JSON 配置 + 占位头像 | 徽章头像 | 书本、星盘、曲线 | 靛蓝 + 金色 | 后续加讲解/判断 | 源 512x512，游戏 64-96px | PNG/WebP | `assets/art/characters/badges/economic_advisor.png` | P0 |

体积建议：单个徽章头像最好小于 50KB，最多不超过 80KB。第一轮 6 个徽章总量最好控制在 300-480KB 内。

## 7. 地图 / 区域资源清单

当前地图由 `PolicyDesk.gd` 的 `MAP_REGION_CONFIGS` 和 `MapRegion.gd` 共同实现，四个区域为：

- 居民消费区：绑定 C。
- 工业产区：绑定 Y 和 I，亮度按 Y 0.7 + I 0.3 综合。
- 金融市场区：绑定 i。
- 政府部门区：绑定 G 和 Debt，但亮度只使用 G，不使用 Debt。

| 地图元素 | 当前实现 | 第一轮建议 | 图片需求 | 程序化建议 | 动效建议 | 优先级 |
|---|---|---|---|---|---|---|
| 地图外框 | `MacroMapPanel` | 改成国政沙盘/地图桌外框 | 可选轻量地图底纹 | StyleBox + 暗金边 | 面板出现淡入 | P1 |
| 四个区域底板 | `MapRegion.gd` | 保留四矩形结构，边框古典化 | 不需要大图 | StyleBoxFlat 根据状态调亮度 | 状态变化时亮度缓动 | P1 |
| 居民消费区图标 | C 区域文本 | 加房屋/人群/集市小图标 | 1 个小图标 | 图标可放标题旁 | 状态变化轻闪 | P1 |
| 工业产区图标 | Y/I 区域文本 | 加齿轮/工坊小图标 | 1 个小图标 | 图标 + 文本 | 亮度变化 | P1 |
| 金融市场区图标 | i 区域文本 | 加铸币/银行柱小图标 | 1 个小图标 | 图标 + 文本 | 亮度变化 | P1 |
| 政府部门区图标 | G/Debt 区域文本 | 加国库/政令小图标 | 1 个小图标 | 图标 + 文本 | 亮度变化 | P1 |
| 真实战略地图 | 暂无 | 后期再做，不影响当前变量逻辑 | 需要较大资源 | 不建议第一轮 | 后期区域脉冲 | P3 |

第一轮不要大改地图逻辑，不做不规则地图。建议只做：古典边框、暗色地图底纹、小图标、状态亮度过渡，并保留现有变量绑定。

## 8. 模型图 / 理论面板资源清单

| 模块 | 当前实现 | 必须保持 | 可美术化部分 | 不建议做 | 动效建议 | 优先级 |
|---|---|---|---|---|---|---|
| TheoryPanel | `PolicyDesk.gd` 动态面板 + `TheoryISLMGraph.gd` | 冲击方向、IS/LM 标签、E0/E1 可读 | 外框做“学士院批注”，标题加小徽章 | 不要用背景纹理干扰图线 | 面板展开淡入 | P1 |
| TheoryISLMGraph | 自绘坐标轴、曲线、红色冲击箭头 | 曲线方向正确，红箭头醒目 | 坐标框边线、图例小标签 | 不做复杂动画 | 后续冲击箭头出现动画 | P2 |
| Model Replay Panel | `ISLMReplayPanel.gd` | 结果数据来自 Solver，图表清晰 | 外框、关闭按钮、模块间隔 | 不改变计算逻辑和曲线含义 | 后续逐步绘制曲线 | P1 |
| ISLMChart | `ISLMChart.gd` 自绘 graph_data | 坐标轴、IS/LM、E0/E1、before/after 可读 | 线条颜色更古典但保持对比 | 不做花纹背景 | 第三阶段做曲线移动动画 | P2 |
| 机制说明 | Replay / Result 中 Label | 文本可读、换行正常 | 卷宗段落样式 | 不做图片文字 | 模块淡入 | P1 |

经济图表可以包装成“学士院推演图”，但不能牺牲线条、标签、坐标轴和变量可读性。

## 9. 动效清单

### 第一阶段：低风险基础动效

| 动效 | 对应节点 / 场景 | 推荐实现 | 推荐时长 | 性能影响 | 第一轮实现 |
|---|---|---|---|---|---|
| 按钮 hover / pressed | 全局 Button、LevelSelect、PolicyDesk、Result | Theme 状态 + Tween `modulate` / `scale` | 0.08-0.14s | 极低 | 是 |
| 政策卡 hover | `PolicyCard.gd` | 已有 Tween scale，可配合阴影/边框 | 0.10s | 极低 | 是 |
| 政策卡选中 | `PolicyCard.gd` | 边框变暗金、轻发光、短促缩放 | 0.12-0.18s | 极低 | 是 |
| 政策卡取消选中 | `PolicyCard.gd` | 选中光还原 | 0.10s | 极低 | 是 |
| DialogueOverlay 淡入 | `DialogueOverlay.gd` | Tween `modulate:a` | 0.16-0.22s | 极低 | 是 |
| 高亮框轻微呼吸 | `DialogueOverlay._draw` | Tween alpha 参数或 `_process` 轻量 sin | 1.0-1.4s 循环 | 低，仅 overlay 活跃时 | 是 |
| HintConfirmModal 淡入 | `HintConfirmModal.gd` | Tween `modulate:a` + 轻 scale | 0.14-0.20s | 极低 | 是 |
| 关卡格 hover | `LevelSelect.gd` Button | Theme hover + Tween | 0.10s | 极低 | 是 |
| 锁定关卡点击反馈 | LevelSelect locked Button | Tween `position:x` 小幅震动或状态提示闪烁 | 0.18-0.24s | 极低 | 是 |

### 第二阶段：策略游戏感动效

| 动效 | 对应节点 / 场景 | 推荐实现 | 推荐时长 | 性能影响 | 是否后置 |
|---|---|---|---|---|---|
| 大臣头像快速进入 | `DialogueOverlay` avatar | Tween position / modulate | 0.16-0.24s | 低 | 后置 P1/P2 |
| 对话框从底部上滑 | `DialogueOverlay` DialogueBox | Tween `position:y` 或 margin | 0.18-0.26s | 低 | 后置 P1 |
| 更换说话人头像切换 | `DialogueOverlay` avatar | crossfade / scale pulse | 0.12-0.20s | 低 | 后置 P1 |
| 确认政策时已选卡牌发光 | `PolicyCard` + `PolicyDesk` | Tween border glow / modulate | 0.25-0.40s | 低 | 后置 P1 |
| 已选卡牌盖章 | `PolicyCard` | 章印图标弹入 | 0.18-0.30s | 低 | 后置 P1 |
| 智慧点数扣除 -2 | `WisdomPanel` | 浮动 Label + 数字 Tween | 0.45-0.70s | 低 | 后置 P1 |
| 关卡解锁 | `LevelSelect` | 锁图标打开、卡片亮起 | 0.45-0.80s | 低 | 后置 P1 |
| 本轮总结入口提示 | `RoundSummaryButton` | 轻呼吸或金边闪烁 2 次 | 0.6-1.2s | 低 | 后置 P1 |

### 第三阶段：教学演出动效

| 动效 | 对应节点 / 场景 | 推荐实现 | 推荐时长 | 性能影响 | 是否第一轮实现 |
|---|---|---|---|---|---|
| 模型回放曲线逐步绘制 | `ISLMChart.gd` | 自绘采样进度参数 + Tween | 0.6-1.0s | 中低 | 否 |
| IS / LM 曲线移动动画 | `ISLMChart.gd` | 插值 before/after 点位 | 0.8-1.2s | 中 | 否 |
| E0 / E1 依次出现 | `ISLMChart.gd` | Tween alpha / scale | 0.2-0.4s | 低 | 否 |
| 变量条旧值到新值滑动 | `MacroStatBar.gd` | Tween current_value | 0.4-0.7s | 低 | 否 |
| FinalSummary 评分条填充 | `FinalSummary.gd` | 自绘或 ProgressBar Tween | 0.5-1.0s | 低 | 否 |
| 季度推进转场 | LevelSelect / PolicyDesk | 轻淡出淡入 + 时间标签变化 | 0.6-1.0s | 低 | 否 |
| 章节完成盖章 | FinalSummary | 章印图标 scale + rotation | 0.3-0.6s | 低 | 否 |

动效原则：

- 轻量、克制，不影响阅读。
- 不拖慢 Web 加载，不依赖大型序列帧。
- 优先用 Godot Tween 操作 `position`、`scale`、`modulate`、自绘参数。
- DialogueOverlay 和滚动/缩放系统优先级最高，任何动效不能破坏输入阻断和滚轮转发。

## 10. 图片资源 vs 程序化 UI 区分

### 应优先程序化实现

| 内容 | 推荐方式 | 原因 |
|---|---|---|
| 面板边框 | Theme / StyleBoxFlat | 体积小、可统一换肤 |
| 按钮 | Theme Button 样式 | 状态多，程序化更灵活 |
| 高亮框 | `DialogueOverlay._draw` | 需根据目标节点实时计算，不适合图片 |
| 遮罩 | ColorRect / draw_rect | 简单且无资源体积 |
| 卡牌基础底板 | StyleBoxFlat / StyleBoxTexture | 可复用，选中态易变 |
| hover / selected 状态 | Theme + Tween | 不需要图片 |
| 状态条 | `MacroStatBar.gd` 自绘 | 数值驱动，必须动态 |
| 变量箭头 | 字体符号 + 颜色 | 清晰、体积零 |
| 关卡格基础样式 | Button StyleBox | 适合锁定/解锁/完成状态 |
| 对话框基础底板 | StyleBoxFlat，必要时轻纹理 | 避免大图 |
| 弹窗底板 | StyleBoxFlat | 稳定、响应式 |
| IS-LM 曲线 | 自定义 Control `_draw()` | 教学图表必须数据驱动 |

### 可以需要轻量图片资源

| 内容 | 建议资源 |
|---|---|
| 角色徽章头像 | 6 个透明 PNG/WebP |
| 政策类型图标 | 财政、货币、观望、收缩、扩张等小图标 |
| 锁图标 | 关卡锁定 |
| 已完成印章 | 关卡完成 / 政策确认 |
| 智慧点数图标 | 书本、烛火、星盘 |
| 地图区域小图标 | 居民、工业、金融、政府 |
| 轻量纸纹 / 木纹 | 1-2 张可平铺纹理，谨慎使用 |
| 章节卷宗装饰 | 小角标、页签、封蜡 |
| 关卡完成盖章 | 可复用章印 |

### 暂时不建议使用的大资源

- 大尺寸整屏背景图。
- 高清角色半身立绘。
- 大型动态背景。
- 视频。
- 大音频。
- 序列帧动画。
- 多套大字体。
- 未使用但放入 `assets/` 的素材包。

## 11. 资源规格建议

| 资源类型 | 推荐尺寸 | 游戏内显示 | 格式 | 透明背景 | 预计数量 | 单个体积限制 | 路径建议 | 命名建议 |
|---|---|---|---|---|---|---|---|---|
| 角色徽章 | 512x512 源文件，可导出 256x256 | 64-96px | PNG 或 WebP | 是 | 6 | 最好 <50KB，最多 <80KB | `assets/art/characters/badges/` | `badge_chief_minister.png` |
| 政策类型图标 | 128x128 | 24-48px | PNG/WebP，SVG 如项目确认支持 | 是 | 4-8 | <20KB | `assets/art/icons/policies/` | `icon_policy_fiscal.png` |
| 关卡锁图标 | 128x128 | 24-48px | PNG/WebP | 是 | 1-2 | <20KB | `assets/art/icons/ui/` | `icon_lock_closed.png` |
| 完成印章 | 256x256 | 40-96px | PNG/WebP | 是 | 1-3 | <40KB | `assets/art/icons/ui/` | `stamp_completed.png` |
| 智慧点数图标 | 128x128 | 20-32px | PNG/WebP | 是 | 1 | <20KB | `assets/art/icons/ui/` | `icon_wisdom.png` |
| 地图区域图标 | 128x128 | 24-40px | PNG/WebP | 是 | 4 | <20KB | `assets/art/icons/map/` | `icon_map_industry.png` |
| 轻纸纹 | 512x512 或 1024x1024 可平铺 | 面板低透明度 | WebP/PNG | 否 | 1 | <100KB | `assets/art/textures/` | `texture_parchment_tile.webp` |
| 轻木纹 | 512x512 或 1024x1024 可平铺 | 背景低透明度 | WebP/PNG | 否 | 1 | <100KB | `assets/art/textures/` | `texture_dark_wood_tile.webp` |
| 小页签/角标 | 128x64 / 256x128 | 20-80px | PNG/WebP | 是 | 3-6 | <20KB | `assets/art/ui/ornaments/` | `ornament_tab_gold.png` |

第一轮新增图片总量建议控制在 1-2MB 内。如果超过，应说明原因并重新评估是否可以程序化实现。

## 12. 性能与体积限制

Web 加载性能是硬约束：

1. 不要打包完整 17MB 中文字体，继续使用自动字体子集。
2. 不要把 `assets/fonts/NotoSansSC-Regular.full.ttf.bak` 纳入导出。
3. 不要新增大尺寸 PNG 背景。
4. 不要新增大音频或视频。
5. 不要把 `docs/`、`web_build/`、`releases/`、`.godot/`、临时目录打进 PCK。
6. 新增图片资源后必须重新检查 `index.pck`。
7. 第一轮美术结束后，`index.pck` 不应异常增长，建议总增长小于 1-2MB。
8. 所有新增资源必须有明确用途，不放“以后可能用”的素材。
9. 对可程序化实现的 UI，不制作图片。
10. 图片优先 WebP 或压缩 PNG，保留源文件时不要放入 Godot 导出目录。

建议阈值：

- 单个小图标：最好小于 20KB。
- 单个徽章头像：最好小于 50-80KB。
- 单个轻量纹理：最好小于 100KB。
- 第一轮全部新增资源总量：最好控制在 1-2MB 内。
- 若新增资源导致 `index.pck` 超过约 2-3MB，应重新审计。

## 13. 第一轮美术改造推荐范围

### P0：必须先做，最影响观感

1. DialogueOverlay 底部对话框：底板、头像徽章框、继续提示、遮罩、高亮框。
2. LevelSelect 关卡格：章节标题、数字格子、锁定/已完成状态。
3. 政策卡牌：文书卡外观、类型徽章、选中态、点数角标。
4. 通用按钮：统一 hover/pressed、确认、返回、关闭。
5. 智慧点数区域：资源图标、请求提示按钮、扣点反馈。
6. HintConfirmModal：确认弹窗外观和按钮。
7. 高亮框和遮罩：暗金框、轻呼吸、遮罩层稳定。

### P1：第一轮可以做

1. PolicyDesk 主面板统一为暗木/卷宗风。
2. MacroMap 四区域边框古典化和小图标。
3. TheoryPanel 与 Model Replay 外框古典化。
4. Result 页面改成季度奏报风格。
5. 本轮总结、模型回放入口添加小图标和出现提示。
6. LevelSelect 解锁动效。

### P2：第二轮做

1. FinalSummary 完整“章节总案”视觉改造。
2. 状态条数值滑动。
3. IS-LM 曲线逐步绘制和移动动画。
4. 角色徽章表情变化。
5. 章节完成盖章效果。

### P3：后期再做

1. 正式人物半身像。
2. 大型背景图。
3. 复杂地图重绘或不规则战略地图。
4. 大型转场动画。
5. 音效系统扩展。
6. 序列帧或视频演出。

## 14. 风险点

| 风险 | 说明 | 建议 |
|---|---|---|
| Web 包体增长 | Godot Web 已有 10MB 级 wasm.gz，PCK 应继续轻量 | 第一轮图片总量控制在 1-2MB |
| 字体缺字 | 正式剧情和脚本中有大量中文，且部分文件可见编码风险 | 继续使用 `generate_font_subset.py`，每次导出前生成 |
| 动态 UI 节点难找 | 大量节点由脚本动态创建，静态 `.tscn` 中看不到完整结构 | 美术改造应从脚本构建函数和组件脚本入手 |
| 对话层输入稳定性 | DialogueOverlay 负责遮罩、高亮、点击推进、滚轮转发 | 改美术时不要破坏 CanvasLayer 和 mouse/input 逻辑 |
| 图表可读性下降 | IS-LM 图是教学核心 | 外框可美化，曲线/坐标/标签不可花哨 |
| Style 分散 | 许多脚本各自创建 StyleBoxFlat | 第一轮可先建统一样式 helper 或 Theme，但避免大重构 |
| 完整源素材误打包 | 源 PSD/大 PNG/完整字体容易进入导出 | 源文件放导出排除目录或项目外 |

## 15. 需要用户确认的问题

1. 第一轮是否采用“徽章头像”作为正式角色资源，而不是半身像。
2. 角色徽章是否偏写实金属徽章，还是偏扁平图标徽章。
3. 整体底色是否继续保留当前蓝黑基底，叠加暗金/木纹/纸纹，还是转向更明显的深木色。
4. 是否允许加入 1-2 张可平铺轻纹理用于纸张/木桌质感。
5. 政策卡是否做成“法令卷宗卡”，还是更接近“内阁议案卡”。
6. 关卡格完成状态是否使用“已阅/完成/盖章”这类政务语义。
7. 第一轮是否只做 P0，还是同时包含部分 P1。

