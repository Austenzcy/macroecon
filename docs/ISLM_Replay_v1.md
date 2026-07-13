# IS-LM Replay v1

## 用途

IS-LM 图形回放 v1 用于把 `MacroEngine / ISLMSolver` 返回的模型结算结果可视化。它不是新的计算系统，只是把同一个 `result` 中的曲线、均衡点和机制解释画出来，帮助玩家理解政策如何移动 IS / LM 曲线。

当前只服务于：

- `settlement_mode = "model"`
- `model_type = "IS_LM"`

基础教学关的 `demo` 结算不提供正式模型图形回放。

## graph_data 结构

`ISLMSolver.solve(...)` 返回的 `result.graph_data` 包括：

```text
graph_data = {
  y_min,
  y_max,
  i_min,
  i_max,
  is_before,
  lm_before,
  is_after,
  lm_after,
  equilibrium_before,
  equilibrium_after
}
```

其中：

- `is_before` / `lm_before`：政策执行前曲线采样点。
- `is_after` / `lm_after`：政策执行后曲线采样点。
- `equilibrium_before`：旧均衡点 E0。
- `equilibrium_after`：新均衡点 E1。

采样点格式：

```text
{"Y": 100.0, "i": 4.0}
```

## 曲线采样

Solver 使用同一套 IS-LM v1 参数生成图形数据。

IS 曲线：

```text
i = (A - Y) / b
```

LM 曲线：

```text
i = cY - d
```

Solver 根据政策前后的均衡点自动生成 `Y` 与 `i` 的显示范围，并在 `Y` 范围内为每条曲线生成一组采样点。UI 只负责连线和标注，不重新推导方程。

## UI 绘图

`ISLMReplayPanel.gd` 负责弹窗结构：

- 标题区；
- 图形区；
- 数值摘要；
- 机制解释；
- 关闭按钮。

`ISLMChart.gd` 负责 `_draw()` 绘制：

- i-Y 坐标轴；
- IS / LM；
- IS' / LM'；
- E0 / E1；
- Y 与 i 的简短标注。

绘图层只读取 `result.graph_data`、`result.before`、`result.after`、`result.curve_shifts` 和 `result.mechanism`。

## 当前限制

- 静态图形，无动画。
- 仅支持 IS-LM。
- 不处理 AD-AS、Mundell-Fleming、Solow。
- 坐标比例服务于教学可读性，不追求教材级精确排版。
- 图形回放暂时作为 PolicyDesk 内弹窗，不替代后续独立 ModelReplay 场景。
