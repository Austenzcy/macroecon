# ScoreEngine v1

## 用途

`ScoreEngine` 负责在关卡结束后计算连续评分。当前 v1 只服务短期 IS-LM 组合训练关，用于评价玩家在价格刚性、短期需求管理情境中的政策结果。

FinalSummary 只展示 `ScoreEngine.calculate_score(...)` 返回的数据，不在 UI 层计算分数。

## 100 分结构

当前总分为 100 分，包含五个子项：

- 产出稳定：40 分
- 就业改善：15 分
- 通胀控制：15 分
- 债务压力：15 分
- 政策效率：15 分

本版不加入“模型理解分”。

## 连续计分规则

产出、就业、通胀使用统一连续计分函数：

```text
如果 gap <= ideal_band:
  score = max_score
否则:
  score = max_score * max(0, 1 - ((gap - ideal_band) / (zero_band - ideal_band))^2)
```

分数会被限制在 0 到 `max_score` 之间，并保留 1 位小数。

债务压力使用软上限和硬上限：

- 低于软上限不扣分；
- 超过软上限后连续扣分；
- 接近硬上限时趋近 0 分。

政策效率主要看产出缺口是否缩小，资源节约只占 20% 权重，避免“少用政策但没有改善经济”也拿高分。

## score_config 字段

组合训练关在 `data/scenarios.json` 中配置 `score_config`：

- `enabled`：是否启用评分。
- `score_type`：当前为 `short_run_is_lm`。
- `weights`：五个子项权重。
- `targets`：目标产出、目标失业率、目标通胀率。
- `bands`：理想区间和零分区间。
- `limits`：债务软上限和硬上限。
- `policy_efficiency`：政策效率配置。
- `scope_notes`：评分适用范围说明。

ScoreEngine 优先读取 `scenario.score_config`，缺失时使用 fallback 默认值，并保证不崩溃。

## 为什么不用离散档位

连续评分可以更平滑地反映政策效果。例如产出距离目标 2.1 和 6.0 不应落入同一个粗糙档位。连续规则也便于后续调参和解释边际改善。

## 长期影响不计入短期评分

当前关卡标签是短期、价格刚性、IS-LM。评分只评价短期需求管理效果。长期债务可持续性、长期通胀预期、潜在产出变化等内容只在最终总结页作为边界提示，不计入本关分数。

## 当前限制与后续扩展

- 当前只实现短期 IS-LM 评分。
- 当前不实现胜负判定。
- 当前不实现评分动画。
- 当前不加入模型理解分。
- 后续可为 AD-AS、Mundell-Fleming、Solow 等关卡配置不同 `score_type` 和评分规则。
