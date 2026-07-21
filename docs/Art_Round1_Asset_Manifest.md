# Art Round1 Asset Manifest

## 1. 用途

本清单用于第一轮正式美术资源接入。当前阶段不生成、不下载、不接入正式图片，只建立统一资源入口和占位插槽。后续 image two 生成的资源放入建议目录后，可通过 `scripts/ui/ArtAssetRegistry.gd` 统一加载。

第一轮资源范围：

- P0：角色徽章头像、政策类型图标、智慧点数图标、关卡锁图标、完成印章、地图四区域图标。
- P1：轻量纸纹、木纹、卷宗边角装饰、政策确认盖章插槽。
- 不包含：大背景图、人物半身像、不规则大地图、音频、视频、序列帧动画。

## 2. 统一接入结构

| 项目 | 当前接入口 |
|---|---|
| 资源注册脚本 | `scripts/ui/ArtAssetRegistry.gd` |
| 角色徽章 | `ArtAssetRegistry.texture_for_character(speaker_id, avatar_id)` |
| 政策类型图标 | `ArtAssetRegistry.texture_for_policy_type(policy_type, policy_id)` |
| 智慧点数 / 锁 / 完成章 | `ArtAssetRegistry.texture_for_ui(key)` |
| 地图区域图标 | `ArtAssetRegistry.texture_for_map_region(region_key)` |
| 轻量纹理 / 装饰 | `ArtAssetRegistry.texture_for_slot(slot_key)` |
| 缺图回退 | `placeholder_for_*` 系列方法返回统一文字徽章 |

所有正式图片都使用 `ResourceLoader.exists()` 运行时检查；资源不存在时不报错、不崩溃。

## 3. 建议目录与命名

| 类别 | 建议目录 | 命名示例 |
|---|---|---|
| 角色徽章 | `assets/art/characters/badges/` | `badge_chief_minister.png` |
| 政策图标 | `assets/art/icons/policies/` | `icon_policy_fiscal_expand.png` |
| UI 图标 | `assets/art/icons/ui/` | `icon_wisdom_points.png`、`icon_lock_level.png` |
| 地图图标 | `assets/art/icons/map/` | `icon_region_consumption.png` |
| 纹理 | `assets/art/textures/` | `texture_paper_light.png`、`texture_dark_wood.png` |
| 印章 | `assets/art/stamps/` | `stamp_level_complete.png`、`stamp_policy_confirmed.png` |

## 4. 角色徽章头像 P0

| 资源名 | 数量 | 用途 | 接入页面 / 节点 / 脚本 | 源尺寸 | 游戏内显示 | 格式 | 透明 | 外框 | image two | 当前占位 | 替换方式 |
|---|---:|---|---|---|---|---|---|---|---|---|---|
| 首席大臣徽章 | 1 | 章节开场、政务汇报头像 | `DialogueOverlay.gd` 的 `SpeakerBadgeTexture`；`AdvisorPanel.gd` 的 `AdvisorBadgeTexture` | 512x512 | 64-96px | PNG/WebP | 是 | 金属徽章 | 必须 | “首”字徽章 | 放入 `assets/art/characters/badges/badge_chief_minister.png` |
| 首席经济顾问徽章 | 1 | 理论讲解、提示、教程头像 | 同上 | 512x512 | 64-96px | PNG/WebP | 是 | 金属徽章 | 必须 | “学”字徽章 | `badge_economic_advisor.png` |
| 财政大臣徽章 | 1 | 财政政策争论与结果评价 | 同上 | 512x512 | 64-96px | PNG/WebP | 是 | 金属徽章 | 必须 | “财”字徽章 | `badge_fiscal_minister.png` |
| 中央银行行长徽章 | 1 | 货币政策、利率、流动性说明 | 同上 | 512x512 | 64-96px | PNG/WebP | 是 | 金属徽章 | 必须 | “央”字徽章 | `badge_central_bank_governor.png` |
| 产业大臣徽章 | 1 | 投资、工业、产出说明 | 同上 | 512x512 | 64-96px | PNG/WebP | 是 | 金属徽章 | 必须 | “工”字徽章 | `badge_industry_minister.png` |
| 民生大臣徽章 | 1 | 消费、居民、失业说明 | 同上 | 512x512 | 64-96px | PNG/WebP | 是 | 金属徽章 | 必须 | “民”字徽章 | `badge_livelihood_minister.png` |

体积限制：单个徽章最好小于 50KB，最多不超过 80KB；6 个徽章合计建议小于 480KB。

## 5. 政策类型图标 P0

| 资源名 | 数量 | 用途 | 接入页面 / 节点 / 脚本 | 源尺寸 | 游戏内显示 | 格式 | 透明 | image two | 当前占位 | 替换方式 |
|---|---:|---|---|---|---|---|---|---|---|---|
| 财政扩张 | 1 | 政策卡类型图标 | `PolicyCard.gd` 的 `PolicyTypeIconTexture` | 128x128 | 20-32px | PNG/WebP | 是 | 必须 | “财” | `assets/art/icons/policies/icon_policy_fiscal_expand.png` |
| 财政紧缩 | 1 | 紧缩财政类卡 | 同上 | 128x128 | 20-32px | PNG/WebP | 是 | 必须 | “缩” | `icon_policy_fiscal_contract.png` |
| 扩张性货币政策 | 1 | 宽松货币类卡 | 同上 | 128x128 | 20-32px | PNG/WebP | 是 | 必须 | “币” | `icon_policy_monetary_expand.png` |
| 紧缩性货币政策 | 1 | 收紧货币类卡 | 同上 | 128x128 | 20-32px | PNG/WebP | 是 | 必须 | “紧” | `icon_policy_monetary_contract.png` |
| 税收相关 | 1 | 减税 / 增税类卡 | 同上 | 128x128 | 20-32px | PNG/WebP | 是 | 必须 | “税” | `icon_policy_tax.png` |
| 投资 / 企业相关 | 1 | 投资补贴、企业信心类卡 | 同上 | 128x128 | 20-32px | PNG/WebP | 是 | 必须 | “投” | `icon_policy_investment.png` |
| 消费 / 居民相关 | 1 | 消费券、居民支持类卡 | 同上 | 128x128 | 20-32px | PNG/WebP | 是 | 必须 | “民” | `icon_policy_consumption.png` |
| 金融稳定 / 利率相关 | 1 | 金融稳定和利率类卡 | 同上 | 128x128 | 20-32px | PNG/WebP | 是 | 需要时生成 | “金” | `icon_policy_financial_stability.png` |
| 通用政策 | 1 | fallback | 同上 | 128x128 | 20-32px | PNG/WebP | 是 | 可选 | “策” | `icon_policy_generic.png` |

体积限制：单个图标最好小于 20KB；全部政策图标建议小于 200KB。

## 6. 智慧点数图标 P0

| 资源名 | 数量 | 用途 | 接入位置 | 源尺寸 | 游戏内显示 | 格式 | 透明 | image two | 当前占位 | 替换方式 |
|---|---:|---|---|---|---|---|---|---|---|---|
| 智慧点数图标 | 1 | PolicyDesk 顶部智慧点数资源条 | `PolicyDesk.gd` 的 `WisdomIconSlot` / `WisdomIconTexture` | 128x128 | 22-30px | PNG/WebP | 是 | 必须 | “智” | `assets/art/icons/ui/icon_wisdom_points.png` |

视觉建议：书本、烛火、星盘或学士院符号，暗金和旧银色，小尺寸清楚。

## 7. 关卡状态图标 P0

| 资源名 | 数量 | 用途 | 接入位置 | 源尺寸 | 游戏内显示 | 格式 | 透明 | image two | 当前占位 | 替换方式 |
|---|---:|---|---|---|---|---|---|---|---|---|
| 关卡锁图标 | 1 | LevelSelect 未解锁关卡 | `LevelSelect.gd` 的 `Button.icon` | 128x128 | 24-36px | PNG/WebP | 是 | 必须 | “锁”文字 | `assets/art/icons/ui/icon_lock_level.png` |
| 已完成印章 | 1 | LevelSelect 已完成关卡 | `LevelSelect.gd` 的 `Button.icon` | 256x256 | 28-44px | PNG/WebP | 是 | 必须 | 完成色块 / 文字 | `assets/art/stamps/stamp_level_complete.png` |

体积限制：锁图标小于 20KB；完成印章小于 40KB。

## 8. 地图四区域图标 P0

| 资源名 | 数量 | 用途 | 接入位置 | 源尺寸 | 游戏内显示 | 格式 | 透明 | image two | 当前占位 | 替换方式 |
|---|---:|---|---|---|---|---|---|---|---|---|
| 居民消费区图标 | 1 | MacroMap 居民消费区 | `MapRegion.gd` 的 `RegionIconTexture`，key `consumption` | 128x128 | 28-38px | PNG/WebP | 是 | 必须 | “民” | `assets/art/icons/map/icon_region_consumption.png` |
| 工业产区图标 | 1 | MacroMap 工业产区 | 同上，key `industry` | 128x128 | 28-38px | PNG/WebP | 是 | 必须 | “工” | `icon_region_industry.png` |
| 金融市场区图标 | 1 | MacroMap 金融市场区 | 同上，key `finance` | 128x128 | 28-38px | PNG/WebP | 是 | 必须 | “金” | `icon_region_finance.png` |
| 政府部门区图标 | 1 | MacroMap 政府部门区 | 同上，key `government` | 128x128 | 28-38px | PNG/WebP | 是 | 必须 | “政” | `icon_region_government.png` |

注意：第一轮仅接小图标，不改四区域矩形地图逻辑，不改变变量绑定和亮度规则。

## 9. 轻量纹理 / 装饰 P1

| 资源名 | 数量 | 用途 | 接入口 | 源尺寸 | 游戏内显示 | 格式 | 透明 | image two | 当前状态 | 替换方式 |
|---|---:|---|---|---|---|---|---|---|---|---|
| 轻纸纹 | 1 | 后续面板 / 对话框内衬 | `ArtAssetRegistry.texture_for_slot("paper")` | 512x512 | 九宫格或平铺 | WebP/PNG | 否 | 可选 | 仅预留 | `assets/art/textures/texture_paper_light.png` |
| 深木纹 | 1 | 后续 PolicyDesk / LevelSelect 背景轻纹理 | `texture_for_slot("wood")` | 512x512 | 平铺 | WebP/PNG | 否 | 可选 | 仅预留 | `assets/art/textures/texture_dark_wood.png` |
| 卷宗边角装饰 | 1-2 | 面板角标 | `texture_for_slot("dossier_corner")` | 256x256 | 16-40px | PNG/WebP | 是 | 可选 | 仅预留 | `assets/art/textures/decor_dossier_corner.png` |
| 政策确认盖章 | 1 | 后续政策卡确认动画 | `texture_for_slot("policy_stamp")` | 256x256 | 40-72px | PNG/WebP | 是 | 可选 | 仅预留 | `assets/art/stamps/stamp_policy_confirmed.png` |

第一轮可以先不启用纹理，避免 Web 包体增长；如启用，全部纹理合计建议控制在 300KB 内。

## 10. 已预留插槽

| 插槽 | 文件 | 当前实现 |
|---|---|---|
| DialogueOverlay 角色徽章 | `scripts/ui/DialogueOverlay.gd` | `SpeakerBadgeTexture`；缺图时显示角色字徽章 |
| 顾问发言框头像 | `scripts/ui/AdvisorPanel.gd` | `AdvisorBadgeTexture`；缺图时显示角色字徽章 |
| 政策类型图标 | `scripts/ui/PolicyCard.gd` | `PolicyTypeIconTexture`；缺图时显示类型字徽章 |
| 智慧点数图标 | `scripts/scenes/PolicyDesk.gd` | `WisdomIconSlot`；缺图时显示“智” |
| 关卡锁 / 完成章 | `scripts/scenes/LevelSelect.gd` | 图存在时使用 `Button.icon`，否则保留文字 |
| 地图区域图标 | `scripts/ui/MapRegion.gd` + `PolicyDesk.gd` | `RegionIconTexture`；缺图时显示区域字徽章 |
| 纸纹 / 木纹 / 装饰 | `scripts/ui/ArtAssetRegistry.gd` | 仅提供路径入口，默认不启用 |

## 11. 性能规则

- 不恢复完整中文字体；继续使用自动字体子集。
- 不把 `docs/`、`web_build/`、`releases/`、`.godot/` 打入 PCK。
- 第一轮新增图片总量建议控制在 1MB 内，最好 500-800KB。
- 小图标优先透明 PNG/WebP，单个 20KB 左右。
- 角色徽章单个最好 50KB 左右，不超过 80KB。
- 纹理谨慎启用，避免让 `index.pck` 异常增长。
- 新增资源必须有明确接入口，不放未使用大图。

## 12. 后续替换流程

1. 按 `docs/Art_Round1_ImageTwo_PromptPack.md` 分组生成资源。
2. 将文件放入本清单建议目录，保持文件名一致。
3. 运行 `scripts/generate_font_subset.py` 或直接执行 `scripts/build_and_deploy.ps1`。
4. Godot 启动时通过 `ArtAssetRegistry.gd` 自动检测并加载存在的贴图。
5. 检查 LevelSelect、PolicyDesk、DialogueOverlay、PolicyCard、MacroMap 是否显示正式图标。
6. 检查 `index.pck` 大小和 Web 加载速度。

## 13. 第二轮资源生成状态

本轮已使用 image two 生成并处理第一批 P0 正式资源。处理流程为：image two 生成绿幕源图，Pillow 本地去 chroma-key、裁切、方形补边、缩放并压缩为透明 PNG。未使用网络下载素材，未使用随机素材包。

| 类别 | 文件 | 状态 | 备注 |
|---|---|---|---|
| 角色徽章 | `assets/art/characters/badges/badge_chief_minister.png` | 已生成，待人工验收 | 512x512，透明 PNG |
| 角色徽章 | `assets/art/characters/badges/badge_economic_advisor.png` | 已生成，待人工验收 | 512x512，透明 PNG |
| 角色徽章 | `assets/art/characters/badges/badge_fiscal_minister.png` | 已生成，待人工验收 | 512x512，透明 PNG |
| 角色徽章 | `assets/art/characters/badges/badge_central_bank_governor.png` | 已生成，待人工验收 | 512x512，透明 PNG，使用纯纹章版 |
| 角色徽章 | `assets/art/characters/badges/badge_industry_minister.png` | 已生成，待人工验收 | 512x512，透明 PNG |
| 角色徽章 | `assets/art/characters/badges/badge_livelihood_minister.png` | 已生成，待人工验收 | 512x512，透明 PNG，使用纯纹章版 |
| 政策类型图标 | `assets/art/icons/policies/icon_policy_fiscal_expand.png` | 已生成，待人工验收 | 256x256，透明 PNG |
| 政策类型图标 | `assets/art/icons/policies/icon_policy_fiscal_contract.png` | 已生成，待人工验收 | 256x256，透明 PNG |
| 政策类型图标 | `assets/art/icons/policies/icon_policy_monetary_expand.png` | 已生成，待人工验收 | 256x256，透明 PNG |
| 政策类型图标 | `assets/art/icons/policies/icon_policy_monetary_contract.png` | 已生成，待人工验收 | 256x256，透明 PNG |
| 政策类型图标 | `assets/art/icons/policies/icon_policy_tax.png` | 已生成，待人工验收 | 256x256，透明 PNG |
| 政策类型图标 | `assets/art/icons/policies/icon_policy_investment.png` | 已生成，待人工验收 | 256x256，透明 PNG |
| 政策类型图标 | `assets/art/icons/policies/icon_policy_consumption.png` | 已生成，待人工验收 | 256x256，透明 PNG |
| 政策类型图标 | `assets/art/icons/policies/icon_policy_financial_stability.png` | 已生成，待人工验收 | 256x256，透明 PNG |
| UI 图标 | `assets/art/icons/ui/icon_wisdom_points.png` | 已生成，待人工验收 | 256x256，透明 PNG |
| UI 图标 | `assets/art/icons/ui/icon_lock_level.png` | 已生成，待人工验收 | 256x256，透明 PNG |
| 印章 | `assets/art/stamps/stamp_level_complete.png` | 已生成，待人工验收 | 256x256，透明 PNG |
| 地图区域图标 | `assets/art/icons/map/icon_region_consumption.png` | 已生成，待人工验收 | 256x256，透明 PNG |
| 地图区域图标 | `assets/art/icons/map/icon_region_industry.png` | 已生成，待人工验收 | 256x256，透明 PNG |
| 地图区域图标 | `assets/art/icons/map/icon_region_finance.png` | 已生成，待人工验收 | 256x256，透明 PNG |
| 地图区域图标 | `assets/art/icons/map/icon_region_government.png` | 已生成，待人工验收 | 256x256，透明 PNG |
| 轻量纹理 / 装饰 | 纸纹、木纹、卷宗角饰、政策确认盖章 | 待生成 | 本轮优先 P0 核心资源，P1 资源后置 |

当前生成资源总体积约 654KB。由于上一轮已完成统一资源接入口，本轮未做额外 UI 接入改造；这些文件已位于 `ArtAssetRegistry.gd` 预设路径，后续运行 / 导出时会被自动识别。

## 14. 第一批资源小范围修订记录

人工初看后发现两类风格问题：一是 `icon_policy_tax.png` 带有偏东方诗人 / 书卷文人感，和当前西欧中世纪 / 近现代政务风不统一；二是部分资源重复使用类似议政厅、银行柱廊或雅典卫城式建筑意象，视觉符号略显单一。

本次仅小范围重做并替换以下 5 个资源，没有全量重生成：

| 文件 | 修订原因 | 新方向 |
|---|---|---|
| `assets/art/icons/policies/icon_policy_tax.png` | 去除东方诗人 / 书卷文人感 | 西欧税务账册、天平、钱币、计数板 |
| `assets/art/characters/badges/badge_central_bank_governor.png` | 减少柱廊 / 神庙重复 | 铸币机、利率曲线、金融罗盘、天平 |
| `assets/art/icons/map/icon_region_finance.png` | 减少银行柱廊重复 | 商会账册、钱币、天平、金融仪表 |
| `assets/art/icons/map/icon_region_government.png` | 减少议政厅 / 神庙建筑重复 | 国库、政令卷轴、钥匙、城堡塔楼 |
| `assets/art/icons/policies/icon_policy_financial_stability.png` | 减少金融建筑重复 | 稳定盾徽、锚、天平、钱币和利率盘 |

替换图仍使用 image two 生成，采用绿幕去底、裁切、透明 PNG 压缩流程。为控制 Web 包体，替换后的徽章保存为 256x256，替换后的图标保存为 192x192；游戏内显示尺寸较小，不影响当前 UI 接入。
