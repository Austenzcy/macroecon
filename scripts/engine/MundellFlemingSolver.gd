extends RefCounted


static func solve(scenario: Dictionary, selected_policies: Array[Dictionary], current_state: Dictionary) -> Dictionary:
	return {
		"settlement_mode": "model",
		"model_type": str(scenario.get("model_type", "MUNDELL_FLEMING")),
		"executed_policies": selected_policies,
		"before": current_state.duplicate(true),
		"after": current_state.duplicate(true),
		"summary": "当前为 Mundell-Fleming 模型结算占位结果，后续将根据汇率制度和资本流动重新求解开放经济均衡。",
		"mechanism": [
			"识别开放经济标签",
			"识别政策对利率、汇率和净出口的影响",
			"根据汇率制度重新求解均衡",
			"输出 Y、i、e 与 NX 的变化"
		]
	}
