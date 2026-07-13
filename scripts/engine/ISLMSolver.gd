extends RefCounted

# IS-LM v1 for closed economy, short run, sticky prices.
# IS: Y = A - b i
# LM: i = cY - d
# Combined equilibrium:
# Y = (A + b d) / (1 + b c)
# i = cY - d
#
# Policies change model parameters such as A and d. Multiple policies are
# combined at the parameter level first, then the equilibrium is solved again.


static func solve(scenario: Dictionary, selected_policies: Array[Dictionary], current_state: Dictionary) -> Dictionary:
	var params: Dictionary = _get_islm_params(scenario)
	if params.is_empty():
		return _missing_params_result(scenario, selected_policies, current_state)

	var a_before: float = float(params.get("A", 132.0))
	var b: float = float(params.get("b", 8.0))
	var c: float = float(params.get("c", 0.04))
	var d_before: float = float(params.get("d", 0.0))
	var y_potential: float = float(params.get("Y_potential", 110.0))
	var u_base: float = float(params.get("u_base", 5.0))
	var pi_base: float = float(params.get("pi_base", 2.0))
	var debt_base: float = float(params.get("debt_base", 60.0))
	var okun_beta: float = float(params.get("okun_beta", 0.04))
	var pi_sensitivity: float = float(params.get("pi_sensitivity", 0.03))

	var before_eq: Dictionary = _solve_equilibrium(a_before, b, c, d_before)
	var total_delta_a: float = 0.0
	var total_delta_d: float = 0.0
	var total_debt_delta: float = 0.0
	var mechanisms: Array[String] = []

	for policy: Dictionary in selected_policies:
		var impact: Dictionary = _get_policy_impact(policy)
		total_delta_a += float(impact.get("delta_A", 0.0))
		total_delta_d += float(impact.get("delta_d", 0.0))
		total_debt_delta += float(impact.get("debt_delta", 0.0))
		var mechanism_text: String = str(impact.get("mechanism", ""))
		if mechanism_text != "":
			mechanisms.append(mechanism_text)

	var a_after: float = a_before + total_delta_a
	var d_after: float = d_before + total_delta_d
	var after_eq: Dictionary = _solve_equilibrium(a_after, b, c, d_after)
	var y_before: float = float(before_eq.get("Y", 0.0))
	var i_before: float = float(before_eq.get("i", 0.0))
	var y_after: float = float(after_eq.get("Y", y_before))
	var i_after: float = float(after_eq.get("i", i_before))
	var delta_y: float = y_after - y_before

	# These derived variables are intentionally simple v1 teaching rules, not a
	# full labor market, Phillips curve, or debt dynamics model.
	var u_after: float = u_base - okun_beta * delta_y
	var pi_after: float = pi_base + pi_sensitivity * maxf(delta_y, 0.0)
	var debt_after: float = debt_base + total_debt_delta
	var shifts: Dictionary = {
		"IS": _is_shift_label(total_delta_a),
		"LM": _lm_shift_label(total_delta_d)
	}

	mechanisms.append("模型先合并政策对 A 与 d 的影响，再重新求解 IS-LM 均衡。")
	mechanisms.append("新的均衡下，Y 从 %s 变为 %s，i 从 %s 变为 %s。" % [
		_format_number(y_before, 1),
		_format_number(y_after, 1),
		_format_percent(i_before, 2),
		_format_percent(i_after, 2)
	])

	var before_state: Dictionary = current_state.duplicate(true)
	before_state["Y"] = _format_number(y_before, 1)
	before_state["u"] = _format_percent(u_base, 1)
	before_state["π"] = _format_percent(pi_base, 1)
	before_state["i"] = _format_percent(i_before, 2)
	before_state["Debt"] = _format_percent(debt_base, 1)

	var after_state: Dictionary = before_state.duplicate(true)
	after_state["Y"] = _format_number(y_after, 1)
	after_state["u"] = _format_percent(u_after, 1)
	after_state["π"] = _format_percent(pi_after, 1)
	after_state["i"] = _format_percent(i_after, 2)
	after_state["Debt"] = _format_percent(debt_after, 1)

	return {
		"settlement_mode": "model",
		"model_type": "IS_LM",
		"model_version": "v1",
		"executed_policies": selected_policies,
		"before": before_state,
		"after": after_state,
		"model_before": {
			"A": a_before,
			"b": b,
			"c": c,
			"d": d_before,
			"Y": y_before,
			"i": i_before,
			"Y_potential": y_potential
		},
		"model_after": {
			"A": a_after,
			"b": b,
			"c": c,
			"d": d_after,
			"Y": y_after,
			"i": i_after,
			"Y_potential": y_potential,
			"delta_A": total_delta_a,
			"delta_d": total_delta_d
		},
		"curve_shifts": shifts,
		"summary": _summary_text(total_delta_a, total_delta_d, delta_y),
		"mechanism": mechanisms
	}


static func _get_islm_params(scenario: Dictionary) -> Dictionary:
	var all_params: Variant = scenario.get("model_params", {})
	if not (all_params is Dictionary):
		return {}
	var islm_params: Variant = (all_params as Dictionary).get("IS_LM", {})
	if islm_params is Dictionary:
		return islm_params as Dictionary
	return {}


static func _get_policy_impact(policy: Dictionary) -> Dictionary:
	var all_impacts: Variant = policy.get("policy_impacts", {})
	if not (all_impacts is Dictionary):
		return {}
	var islm_impact: Variant = (all_impacts as Dictionary).get("IS_LM", {})
	if islm_impact is Dictionary:
		return islm_impact as Dictionary
	return {}


static func _solve_equilibrium(a: float, b: float, c: float, d: float) -> Dictionary:
	var denominator: float = 1.0 + b * c
	if is_zero_approx(denominator):
		return {"Y": 0.0, "i": 0.0}
	var y: float = (a + b * d) / denominator
	var i: float = c * y - d
	return {"Y": y, "i": i}


static func _is_shift_label(delta_a: float) -> String:
	if delta_a > 0.0:
		return "右移"
	if delta_a < 0.0:
		return "左移"
	return "无明显移动"


static func _lm_shift_label(delta_d: float) -> String:
	if delta_d > 0.0:
		return "右移 / 下移"
	if delta_d < 0.0:
		return "左移 / 上移"
	return "无明显移动"


static func _summary_text(delta_a: float, delta_d: float, delta_y: float) -> String:
	if not is_zero_approx(delta_a) and not is_zero_approx(delta_d):
		return "多项政策共同改变 IS-LM 参数。模型重新求解均衡后，短期产出上升，失业率下降，利率变化取决于 IS 与 LM 移动的相对强度。"
	if not is_zero_approx(delta_a):
		return "财政类政策提高自主支出 A，推动 IS 曲线右移。模型重新求解均衡后，短期产出上升，利率随收入与货币需求变化而上升。"
	if not is_zero_approx(delta_d):
		return "货币条件宽松提高流动性参数 d，推动 LM 曲线右移或下移。模型重新求解均衡后，短期产出上升，利率下降。"
	if delta_y > 0.0:
		return "政策对模型参数影响较弱，但重新求解后短期产出略有改善。"
	return "当前政策没有可识别的 IS-LM v1 参数影响，模型均衡基本保持不变。"


static func _missing_params_result(scenario: Dictionary, selected_policies: Array[Dictionary], current_state: Dictionary) -> Dictionary:
	return {
		"settlement_mode": "model",
		"model_type": str(scenario.get("model_type", "IS_LM")),
		"model_version": "v1",
		"executed_policies": selected_policies,
		"before": current_state.duplicate(true),
		"after": current_state.duplicate(true),
		"model_before": {},
		"model_after": {},
		"curve_shifts": {"IS": "未知", "LM": "未知"},
		"summary": "当前关卡缺少 IS-LM 模型参数，已降级为保持现状的模型结果。",
		"mechanism": ["读取 scenario.model_params.IS_LM 失败", "保持当前宏观状态，避免游戏流程崩溃"]
	}


static func _format_number(value: float, decimals: int) -> String:
	match decimals:
		0:
			return "%.0f" % value
		1:
			return "%.1f" % value
		2:
			return "%.2f" % value
		_:
			return "%.2f" % value


static func _format_percent(value: float, decimals: int) -> String:
	return "%s%%" % _format_number(value, decimals)
