extends RefCounted


static func calculate_score(scenario: Dictionary, round_history: Array, initial_state: Dictionary, final_state: Dictionary) -> Dictionary:
	var config: Dictionary = _dictionary_from_variant(scenario.get("score_config", {}))
	if not bool(config.get("enabled", false)):
		return {
			"enabled": false,
			"total": 0.0,
			"max_total": 100.0,
			"items": [],
			"overall_comment": "当前关卡未启用评分系统。",
			"scope_note": "评分系统只在配置启用时显示。"
		}

	var weights: Dictionary = _dictionary_from_variant(config.get("weights", {}))
	var targets: Dictionary = _dictionary_from_variant(config.get("targets", {}))
	var bands: Dictionary = _dictionary_from_variant(config.get("bands", {}))
	var limits: Dictionary = _dictionary_from_variant(config.get("limits", {}))

	var y_final: float = _state_number(final_state, "Y", 100.0)
	var u_final: float = _state_number(final_state, "u", 5.0)
	var pi_final: float = _state_number(final_state, "π", _state_number(final_state, "蟺", 2.0))
	var debt_final: float = _state_number(final_state, "Debt", 60.0)
	var y_initial: float = _state_number(initial_state, "Y", 100.0)

	var y_target: float = float(targets.get("Y_target", 110.0))
	var u_target: float = float(targets.get("u_target", 4.5))
	var pi_target: float = float(targets.get("pi_target", 2.0))

	var output_max: float = float(weights.get("output_stability", 40.0))
	var employment_max: float = float(weights.get("employment", 15.0))
	var inflation_max: float = float(weights.get("inflation_control", 15.0))
	var debt_max: float = float(weights.get("debt_control", 15.0))
	var efficiency_max: float = float(weights.get("policy_efficiency", 15.0))

	var output_score: float = score_with_ideal_band(
		absf(y_final - y_target),
		float(bands.get("Y_ideal_band", 2.0)),
		float(bands.get("Y_zero_band", 15.0)),
		output_max
	)
	var employment_score: float = score_with_ideal_band(
		absf(u_final - u_target),
		float(bands.get("u_ideal_band", 0.3)),
		float(bands.get("u_zero_band", 2.0)),
		employment_max
	)
	var inflation_score: float = score_with_ideal_band(
		absf(pi_final - pi_target),
		float(bands.get("pi_ideal_band", 0.3)),
		float(bands.get("pi_zero_band", 2.5)),
		inflation_max
	)
	var debt_score: float = _debt_score(
		debt_final,
		float(limits.get("debt_soft_limit", 65.0)),
		float(limits.get("debt_hard_limit", 75.0)),
		debt_max
	)
	var efficiency_score: float = _policy_efficiency_score(
		scenario,
		round_history,
		y_initial,
		y_final,
		y_target,
		efficiency_max
	)

	var items: Array[Dictionary] = [
		_score_item("output_stability", "产出稳定", output_score, output_max, _output_comment(y_final, y_target)),
		_score_item("employment", "就业改善", employment_score, employment_max, _employment_comment(u_final, u_target)),
		_score_item("inflation_control", "通胀控制", inflation_score, inflation_max, _inflation_comment(pi_final, pi_target)),
		_score_item("debt_control", "债务压力", debt_score, debt_max, _debt_comment(debt_final, float(limits.get("debt_soft_limit", 65.0)))),
		_score_item("policy_efficiency", "政策效率", efficiency_score, efficiency_max, _efficiency_comment(efficiency_score, efficiency_max))
	]

	var total: float = 0.0
	var max_total: float = 0.0
	for item: Dictionary in items:
		total += float(item.get("score", 0.0))
		max_total += float(item.get("max", 0.0))

	return {
		"enabled": true,
		"total": _round1(total),
		"max_total": _round1(max_total),
		"items": items,
		"overall_comment": _overall_comment(output_score, output_max, debt_score, debt_max),
		"scope_note": "本评分只评价短期 IS-LM 情境下的需求管理效果，长期影响不计入本关评分。"
	}


static func score_with_ideal_band(gap: float, ideal_band: float, zero_band: float, max_score: float) -> float:
	if max_score <= 0.0:
		return 0.0
	if gap <= ideal_band:
		return _round1(max_score)
	if zero_band <= ideal_band:
		return 0.0
	var ratio: float = (gap - ideal_band) / (zero_band - ideal_band)
	var score: float = max_score * maxf(0.0, 1.0 - ratio * ratio)
	return _round1(clampf(score, 0.0, max_score))


static func _debt_score(debt_final: float, soft_limit: float, hard_limit: float, max_score: float) -> float:
	if debt_final <= soft_limit:
		return _round1(max_score)
	if hard_limit <= soft_limit:
		return 0.0
	var ratio: float = (debt_final - soft_limit) / (hard_limit - soft_limit)
	var score: float = max_score * maxf(0.0, 1.0 - ratio * ratio)
	return _round1(clampf(score, 0.0, max_score))


static func _policy_efficiency_score(scenario: Dictionary, round_history: Array, y_initial: float, y_final: float, y_target: float, max_score: float) -> float:
	var initial_gap: float = absf(y_initial - y_target)
	var final_gap: float = absf(y_final - y_target)
	var gap_closure: float = 1.0
	if initial_gap > 0.001:
		gap_closure = clampf((initial_gap - final_gap) / initial_gap, 0.0, 1.0)

	var used_points: float = 0.0
	for entry: Variant in round_history:
		if not entry is Dictionary:
			continue
		var result: Dictionary = _dictionary_from_variant((entry as Dictionary).get("result", {}))
		var policies: Array = _array_from_variant(result.get("executed_policies", []))
		for policy: Variant in policies:
			if policy is Dictionary:
				used_points += float((policy as Dictionary).get("cost", (policy as Dictionary).get("default_cost", 0.0)))

	var limit: float = float(scenario.get("policy_point_limit", 0.0))
	var total_available: float = limit * float(round_history.size()) if limit > 0.0 else 0.0
	var point_usage: float = 1.0
	if total_available > 0.0:
		point_usage = clampf(used_points / total_available, 0.0, 1.0)
	var resource_saving: float = 1.0 - point_usage
	var score: float = max_score * gap_closure * (0.8 + 0.2 * resource_saving)
	return _round1(clampf(score, 0.0, max_score))


static func _score_item(id: String, name: String, score: float, max_score: float, comment: String) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"score": _round1(score),
		"max": _round1(max_score),
		"comment": comment
	}


static func _state_number(state: Dictionary, key: String, fallback: float) -> float:
	if state.has(key):
		return _parse_number(str(state.get(key)), fallback)
	if key == "π" and state.has("蟺"):
		return _parse_number(str(state.get("蟺")), fallback)
	return fallback


static func _parse_number(value: String, fallback: float) -> float:
	var cleaned: String = value.strip_edges().replace("%", "")
	if cleaned.is_valid_float():
		return cleaned.to_float()
	return fallback


static func _dictionary_from_variant(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


static func _array_from_variant(value: Variant) -> Array:
	if value is Array:
		return value as Array
	return []


static func _round1(value: float) -> float:
	return roundf(value * 10.0) / 10.0


static func _output_comment(y_final: float, y_target: float) -> String:
	if absf(y_final - y_target) <= 2.0:
		return "最终产出接近目标产出，需求不足得到明显缓解。"
	if y_final < y_target:
		return "最终产出仍低于目标，短期刺激力度可能不足。"
	return "最终产出高于目标，可能存在过度刺激压力。"


static func _employment_comment(u_final: float, u_target: float) -> String:
	if absf(u_final - u_target) <= 0.3:
		return "失业率接近目标，就业修复较稳。"
	if u_final > u_target:
		return "失业率仍偏高，需求恢复尚不充分。"
	return "失业率低于目标，需留意经济过热压力。"


static func _inflation_comment(pi_final: float, pi_target: float) -> String:
	if absf(pi_final - pi_target) <= 0.3:
		return "通胀接近目标，短期价格压力可控。"
	if pi_final > pi_target:
		return "通胀高于目标，扩张政策带来一定价格压力。"
	return "通胀低于目标，需求修复仍可能偏弱。"


static func _debt_comment(debt_final: float, soft_limit: float) -> String:
	if debt_final <= soft_limit:
		return "债务率仍在短期财政空间约束内。"
	return "债务率超过短期软约束，财政压力有所上升。"


static func _efficiency_comment(score: float, max_score: float) -> String:
	if max_score <= 0.0:
		return "当前关卡未配置政策效率权重。"
	if score >= max_score * 0.8:
		return "政策组合较有效地缩小产出缺口，并保持了较好的资源效率。"
	if score >= max_score * 0.45:
		return "政策组合改善了产出缺口，但资源效率仍有提升空间。"
	return "产出缺口改善有限，政策效率偏低。"


static func _overall_comment(output_score: float, output_max: float, debt_score: float, debt_max: float) -> String:
	if output_score >= output_max * 0.75 and debt_score >= debt_max * 0.65:
		return "政策组合有效缓解了需求不足，并保持了较可控的短期财政压力。"
	if output_score >= output_max * 0.75:
		return "政策组合有效缓解了需求不足，但债务压力有所上升。"
	return "政策组合对需求不足有所帮助，但最终产出距离目标仍有差距。"
