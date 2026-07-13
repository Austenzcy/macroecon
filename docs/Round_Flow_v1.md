# Round Flow v1

## 用途

本阶段把游戏从一次性政策确认推进到最小两回合演示流程。目标是验证“结算结果进入本轮总结，再继承到下一回合”的基础链路。

## 当前回合流程

1. 玩家从 `PolicyDesk` 选择政策并点击确认政策。
2. `PolicyDesk` 调用 `MacroEngine.calculate_result(scenario, selected_policies, current_state)`。
3. `MacroEngine` 返回本轮 `result`。
4. `PolicyDesk` 将 `result` 保存到 `GameState.last_result`，同时写入 `round_history`。
5. 玩家可以继续查看右侧结果和 IS-LM 图形回放。
6. 玩家点击“本轮总结”进入 `Result` 页面。
7. `Result` 页面显示本轮已执行政策、宏观变量变化、summary 和 mechanism。
8. 如果还未到最后一回合，玩家点击“进入下一回合”。
9. `GameState.advance_round()` 将 `last_result.after` 写入 `current_state`，然后进入下一回合。
10. 回到 `PolicyDesk` 后，政策选择状态清空，但宏观状态继承上一轮结果。

## GameState 状态

`GameState` 当前保存：

- `current_scenario_id`：当前测试关卡。
- `current_round`：当前回合，初始为 1。
- `max_rounds`：当前演示版固定为 2。
- `current_state`：当前宏观状态，下一回合由上一轮 `result.after` 继承。
- `last_result`：上一轮 MacroEngine 返回的完整结果。
- `round_history`：每轮结果记录。

## Result 页面数据来源

`Result` 页面只读取 `GameState.last_result`，不重新计算变量，不推导政策效果，也不写死模型结果。

展示内容包括：

- 已执行政策；
- `before -> after` 宏观变量变化；
- `summary`；
- `mechanism`。

## 当前限制

- 当前只支持 2 回合演示。
- 当前没有评分系统。
- 当前没有突发事件系统。
- 当前没有长期副作用模块。
- 每回合 `Result` 页面只总结本回合在当前模型设定下的结果。

## 后续原则

- 评分系统以后应与关卡标签绑定。
- 如果关卡是“短期｜价格刚性｜IS-LM”，评分只评价该短期模型目标。
- 不属于当前时间视野的长期目标，只能在最终总结页提示，不计入当前关卡评分。
- 突发事件系统后期再加入。
- 长期副作用以后只放在所有回合结束后的最终总结页，不放在每回合总结页。
