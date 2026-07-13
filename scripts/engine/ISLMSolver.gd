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

	var a_before: float = _state_float(current_state, "_islm_A", float(params.get("A", 132.0)))
	var b: float = _state_float(current_state, "_islm_b", float(params.get("b", 8.0)))
	var c: float = _state_float(current_state, "_islm_c", float(params.get("c", 0.04)))
	var d_before: float = _state_float(current_state, "_islm_d", float(params.get("d", 0.0)))
	var y_potential: float = float(params.get("Y_potential", 110.0))
	var u_before: float = _state_float(current_state, "u", float(params.get("u_base", 5.0)))
	var pi_before: float = _state_float(current_state, "π", _state_float(current_state, "蟺", float(params.get("pi_base", 2.0))))
	var debt_before: float = _state_float(current_state, "Debt", float(params.get("debt_base", 60.0)))
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
	var u_after: float = u_before - okun_beta * delta_y
	var pi_after: float = pi_before + pi_sensitivity * maxf(delta_y, 0.0)
	var debt_after: float = debt_before + total_debt_delta
	var shifts: Dictionary = {
		"IS": _is_shift_label(total_delta_a),
		"LM": _lm_shift_label(total_delta_d)
	}
	var graph_data: Dictionary = _build_graph_data(
		a_before,
		b,
		c,
		d_before,
		a_after,
		d_after,
		y_before,
		i_before,
		y_after,
		i_after
	)

	mechanisms.append("模型先合并政策对 A 与 d 的影响，再重新求解 IS-LM 均衡。")
	mechanisms.append("新的均衡下，Y 从 %s 变为 %s，i 从 %s 变为 %s。" % [
		_format_number(y_before, 1),
		_format_number(y_after, 1),
		_format_percent(i_before, 2),
		_format_percent(i_after, 2)
	])

	var before_state: Dictionary = current_state.duplicate(true)
	before_state["Y"] = _format_number(y_before, 1)
	before_state["u"] = _format_percent(u_before, 1)
	before_state["π"] = _format_percent(pi_before, 1)
	before_state["蟺"] = _format_percent(pi_before, 1)
	before_state["i"] = _format_percent(i_before, 2)
	before_state["Debt"] = _format_percent(debt_before, 1)
	before_state["_islm_A"] = a_before
	before_state["_islm_b"] = b
	before_state["_islm_c"] = c
	before_state["_islm_d"] = d_before

	var after_state: Dictionary = before_state.duplicate(true)
	after_state["Y"] = _format_number(y_after, 1)
	after_state["u"] = _format_percent(u_after, 1)
	after_state["π"] = _format_percent(pi_after, 1)
	after_state["蟺"] = _format_percent(pi_after, 1)
	after_state["i"] = _format_percent(i_after, 2)
	after_state["Debt"] = _format_percent(debt_after, 1)
	after_state["_islm_A"] = a_after
	after_state["_islm_b"] = b
	after_state["_islm_c"] = c
	after_state["_islm_d"] = d_after

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
		"graph_data": graph_data,
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


static func _state_float(state: Dictionary, key: String, fallback: float) -> float:
	if state.has(key):
		var value_text: String = str(state.get(key)).strip_edges().replace("%", "")
		if value_text.is_valid_float():
			return value_text.to_float()
	return fallback


static func _solve_equilibrium(a: float, b: float, c: float, d: float) -> Dictionary:
	var denominator: float = 1.0 + b * c
	if is_zero_approx(denominator):
		return {"Y": 0.0, "i": 0.0}
	var y: float = (a + b * d) / denominator
	var i: float = c * y - d
	return {"Y": y, "i": i}


static func _build_graph_data(a_before: float, b: float, c: float, d_before: float, a_after: float, d_after: float, y_before: float, i_before: float, y_after: float, i_after: float) -> Dictionary:
	var y_span: float = maxf(absf(y_after - y_before), 12.0)
	var y_margin: float = maxf(y_span * 0.75, 10.0)
	var y_min: float = minf(y_before, y_after) - y_margin
	var y_max: float = maxf(y_before, y_after) + y_margin

	var is_before_points: Array[Dictionary] = _sample_is_curve(a_before, b, y_min, y_max)
	var lm_before_points: Array[Dictionary] = _sample_lm_curve(c, d_before, y_min, y_max)
	var is_after_points: Array[Dictionary] = _sample_is_curve(a_after, b, y_min, y_max)
	var lm_after_points: Array[Dictionary] = _sample_lm_curve(c, d_after, y_min, y_max)
	var i_bounds: Dictionary = _curve_i_bounds([
		is_before_points,
		lm_before_points,
		is_after_points,
		lm_after_points
	])
	var raw_i_min: float = minf(minf(i_before, i_after), float(i_bounds.get("min", minf(i_before, i_after))))
	var raw_i_max: float = maxf(maxf(i_before, i_after), float(i_bounds.get("max", maxf(i_before, i_after))))
	var i_span: float = maxf(raw_i_max - raw_i_min, 1.5)
	var i_margin: float = maxf(i_span * 0.12, 0.35)

	return {
		"y_min": y_min,
		"y_max": y_max,
		"i_min": raw_i_min - i_margin,
		"i_max": raw_i_max + i_margin,
		"is_before": is_before_points,
		"lm_before": lm_before_points,
		"is_after": is_after_points,
		"lm_after": lm_after_points,
		"equilibrium_before": {"Y": y_before, "i": i_before},
		"equilibrium_after": {"Y": y_after, "i": i_after}
	}


static func _sample_is_curve(a: float, b: float, y_min: float, y_max: float) -> Array[Dictionary]:
	var points: Array[Dictionary] = []
	var count: int = 28
	var denominator: float = maxf(b, 0.001)
	for index in range(count):
		var t: float = float(index) / float(count - 1)
		var y: float = lerpf(y_min, y_max, t)
		points.append({"Y": y, "i": (a - y) / denominator})
	return points


static func _sample_lm_curve(c: float, d: float, y_min: float, y_max: float) -> Array[Dictionary]:
	var points: Array[Dictionary] = []
	var count: int = 28
	for index in range(count):
		var t: float = float(index) / float(count - 1)
		var y: float = lerpf(y_min, y_max, t)
		points.append({"Y": y, "i": c * y - d})
	return points


static func _curve_i_bounds(curves: Array) -> Dictionary:
	var has_value: bool = false
	var min_value: float = 0.0
	var max_value: float = 0.0
	for curve_variant: Variant in curves:
		if not (curve_variant is Array):
			continue
		for point_variant: Variant in curve_variant:
			if not (point_variant is Dictionary):
				continue
			var point: Dictionary = point_variant as Dictionary
			var i_value: float = float(point.get("i", 0.0))
			if not has_value:
				min_value = i_value
				max_value = i_value
				has_value = true
			else:
				min_value = minf(min_value, i_value)
				max_value = maxf(max_value, i_value)
	return {"min": min_value, "max": max_value}


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
		return "多项政策共同改变 IS-LM 参数。模型重新求解均衡后，产出和利率的变化取决于 IS 与 LM 移动的相对强度。"
	if delta_a > 0.0:
		return "财政类政策提高自主支出 A，推动 IS 曲线右移。模型重新求解均衡后，短期产出上升，利率随收入与货币需求变化而上升。"
	if delta_a < 0.0:
		return "收缩性财政政策降低自主支出 A，推动 IS 曲线左移。模型重新求解均衡后，需求过热压力下降。"
	if delta_d > 0.0:
		return "货币条件宽松提高流动性参数 d，推动 LM 曲线右移或下移。模型重新求解均衡后，短期产出上升，利率下降。"
	if delta_d < 0.0:
		return "货币条件收紧降低流动性参数 d，推动 LM 曲线左移或上移。模型重新求解均衡后，需求和价格压力得到抑制。"
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
		"graph_data": {},
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
