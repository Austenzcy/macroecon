extends RefCounted

const CardResolver = preload("res://scripts/engine/CardResolver.gd")
const ISLMSolver = preload("res://scripts/engine/ISLMSolver.gd")
const ADASSolver = preload("res://scripts/engine/ADASSolver.gd")
const MundellFlemingSolver = preload("res://scripts/engine/MundellFlemingSolver.gd")
const SolowSolver = preload("res://scripts/engine/SolowSolver.gd")


static func calculate_result(scenario: Dictionary, selected_policies: Array, current_state: Dictionary) -> Dictionary:
	var policies: Array[Dictionary] = CardResolver.normalize_selected_policies(selected_policies)
	var settlement_mode: String = str(scenario.get("settlement_mode", "demo"))
	var model_type: String = str(scenario.get("model_type", "IS_LM"))

	if settlement_mode == "demo":
		return calculate_demo_result(scenario, policies, current_state)

	if settlement_mode == "model":
		match model_type:
			"IS_LM":
				return ISLMSolver.solve(scenario, policies, current_state)
			"AD_AS":
				return ADASSolver.solve(scenario, policies, current_state)
			"MUNDELL_FLEMING":
				return MundellFlemingSolver.solve(scenario, policies, current_state)
			"SOLOW":
				return SolowSolver.solve(scenario, policies, current_state)
			_:
				return _fallback_model_result(scenario, policies, current_state, model_type)

	return calculate_demo_result(scenario, policies, current_state)


static func calculate_demo_result(scenario: Dictionary, selected_policies: Array[Dictionary], current_state: Dictionary) -> Dictionary:
	# Demo result is for basic teaching flow only. It is not a formal macro model calculation.
	var after: Dictionary = current_state.duplicate(true)
	var summary: String = "政策已执行，当前为基础教学演示结算。"
	var mechanism: Array[String] = []

	if selected_policies.size() > 1:
		after["Y"] = "103"
		after["u"] = "4.7%"
		after["π"] = "2.2%"
		after["i"] = "4.0%"
		after["Debt"] = "62%"
		summary = "多项扩张性政策共同支撑总需求，当前为演示结算，后续将由模型求解器重新计算均衡。"
		mechanism = [
			"识别多项政策对总需求的共同方向",
			"以统一组合演示结果呈现短期压力变化",
			"后续模型模式将重新求解均衡，而不是简单相加"
		]
	else:
		var policy_id: String = ""
		if selected_policies.size() == 1:
			policy_id = str(selected_policies[0].get("id", ""))
		match policy_id:
			"increase_government_purchase":
				after["Y"] = "102"
				after["u"] = "4.8%"
				after["π"] = "2.1%"
				after["i"] = "4.2%"
				after["Debt"] = "62%"
				summary = "政府购买增加支撑总需求，短期产出压力有所缓解，但债务压力上升。"
				mechanism = ["G 上升", "计划支出增加", "IS 曲线右移", "Y 上升压力增强"]
			"expansionary_monetary_policy":
				after["Y"] = "102"
				after["u"] = "4.8%"
				after["π"] = "2.1%"
				after["i"] = "3.5%"
				after["Debt"] = "60%"
				summary = "金融条件有所宽松，需求压力得到一定缓解。"
				mechanism = ["货币条件转松", "LM 曲线右移", "利率下降", "投资与总需求获得支撑"]
			"tax_cut":
				after["Y"] = "101"
				after["u"] = "4.9%"
				after["π"] = "2.1%"
				after["i"] = "4.1%"
				after["Debt"] = "61%"
				summary = "减税提高了可支配收入，消费压力有所缓解，但财政收入承压。"
				mechanism = ["T 下降", "可支配收入上升", "消费需求改善", "财政压力上升"]
			_:
				mechanism = ["当前政策尚未配置演示机制", "保持当前状态用于教学占位"]

	return {
		"settlement_mode": "demo",
		"model_type": str(scenario.get("model_type", "IS_LM")),
		"executed_policies": selected_policies,
		"before": current_state.duplicate(true),
		"after": after,
		"summary": summary,
		"mechanism": mechanism
	}


static func _fallback_model_result(_scenario: Dictionary, selected_policies: Array[Dictionary], current_state: Dictionary, model_type: String) -> Dictionary:
	return {
		"settlement_mode": "model",
		"model_type": model_type,
		"executed_policies": selected_policies,
		"before": current_state.duplicate(true),
		"after": current_state.duplicate(true),
		"summary": "当前为模型结算占位结果，后续将接入对应模型求解器。",
		"mechanism": ["识别模型类型", "读取政策影响结构", "调用模型求解器", "输出均衡变化"]
	}
