extends RefCounted


static func solve(scenario: Dictionary, selected_policies: Array[Dictionary], current_state: Dictionary) -> Dictionary:
	return {
		"settlement_mode": "model",
		"model_type": str(scenario.get("model_type", "SOLOW")),
		"executed_policies": selected_policies,
		"before": current_state.duplicate(true),
		"after": current_state.duplicate(true),
		"summary": "当前为 Solow 模型结算占位结果，后续将根据储蓄、资本积累和技术进步重新计算长期均衡。",
		"mechanism": [
			"识别长期增长政策",
			"更新储蓄、折旧、人口或技术参数",
			"重新求解稳态资本",
			"输出长期人均产出变化"
		]
	}
