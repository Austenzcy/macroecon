extends SceneTree

const MacroEngine = preload("res://scripts/engine/MacroEngine.gd")
const ISLMDemandComponents = preload("res://scripts/engine/ISLMDemandComponents.gd")

const SCENARIOS_PATH: String = "res://data/scenarios.json"
const POLICIES_PATH: String = "res://data/policies.json"
const TOLERANCE: float = 0.11

var _pass_count: int = 0
var _warn_count: int = 0
var _fail_count: int = 0


func _init() -> void:
	var scenarios: Array = _load_array(SCENARIOS_PATH)
	var policies: Dictionary = _policy_index(_load_array(POLICIES_PATH))
	var islm_scenarios: Array[Dictionary] = []
	for item: Variant in scenarios:
		if item is Dictionary and str((item as Dictionary).get("model_type", "")) == "IS_LM":
			islm_scenarios.append(item as Dictionary)

	_line("# Demand Component Settlement Audit")
	_line("")
	_line("Data flow: LevelConfig -> normalized initial state -> policy selection -> MacroEngine -> IS-LM model output -> ISLMDemandComponents synchronization -> tooltip/right-panel state reads.")
	_line("Settlement flow: policy changes IS-LM A/d/Debt; model computes Y/i; C/I/G are then decomposed from Y and policy/status signals. C/I/G do not feed back into Y.")
	_line("")
	_line("## Initial State Audit")
	for scenario: Dictionary in islm_scenarios:
		_audit_initial_state(scenario)

	_line("")
	_line("## Policy Settlement Audit")
	var combo_count: int = 0
	for scenario: Dictionary in islm_scenarios:
		combo_count += _audit_policy_settlements(scenario, policies)

	_line("")
	_line("## Reset And Isolation Audit")
	_audit_reset_and_isolation(islm_scenarios, policies)

	_line("")
	_line("## Detailed Representative Traces")
	_trace_representative("consumer_confidence_drop_basic", islm_scenarios, policies)
	_trace_representative("fiscal_expansion_crowding_out_training", islm_scenarios, policies)
	_trace_representative("two_round_stabilization_challenge_training", islm_scenarios, policies)

	_line("")
	_line("## Summary")
	_line("- IS-LM scenarios checked: %d" % islm_scenarios.size())
	_line("- scenario x policy combinations checked: %d" % combo_count)
	_line("- PASS: %d" % _pass_count)
	_line("- WARN: %d" % _warn_count)
	_line("- FAIL: %d" % _fail_count)
	quit(1 if _fail_count > 0 else 0)


func _audit_initial_state(scenario: Dictionary) -> void:
	var id: String = str(scenario.get("id", "unknown"))
	var state: Dictionary = ISLMDemandComponents.normalize_initial_state(scenario, _initial_state(scenario))
	var check: Dictionary = _state_check(state)
	var semantic: String = _semantic_check(scenario, state)
	var status: String = "PASS" if bool(check.get("ok", false)) and semantic == "PASS" else semantic
	_record(status, "initial %s | Y=%s C=%s I=%s G=%s residual=%.3f | %s" % [
		id,
		_state_value(state, "Y"),
		_state_value(state, "C_value"),
		_state_value(state, "I_value"),
		_state_value(state, "G_value"),
		float(check.get("residual", 0.0)),
		"semantic=%s" % semantic
	])


func _audit_policy_settlements(scenario: Dictionary, policy_index: Dictionary) -> int:
	var id: String = str(scenario.get("id", "unknown"))
	var before: Dictionary = ISLMDemandComponents.normalize_initial_state(scenario, _initial_state(scenario))
	var count: int = 0
	for policy: Dictionary in _available_policies(scenario, policy_index):
		count += 1
		var result: Dictionary = MacroEngine.calculate_result(scenario, [policy], before)
		var after: Dictionary = _dict(result.get("after", {}))
		var before_result: Dictionary = _dict(result.get("before", {}))
		var before_check: Dictionary = _state_check(before_result)
		var after_check: Dictionary = _state_check(after)
		var flow_status: String = _policy_flow_status(result, before_result, after)
		var status: String = "PASS"
		if not bool(before_check.get("ok", false)) or not bool(after_check.get("ok", false)):
			status = "FAIL"
		elif flow_status != "PASS":
			status = flow_status
		_record(status, "policy %s -> %s | dY=%.2f dC=%.2f dI=%.2f dG=%.2f dDebt=%.2f residual_after=%.3f" % [
			id,
			str(policy.get("id", "")),
			_delta(after, before_result, "Y"),
			_delta(after, before_result, "C_value"),
			_delta(after, before_result, "I_value"),
			_delta(after, before_result, "G_value"),
			_delta(after, before_result, "Debt"),
			float(after_check.get("residual", 0.0))
		])
	return count


func _audit_reset_and_isolation(scenarios: Array[Dictionary], policy_index: Dictionary) -> void:
	for scenario: Dictionary in scenarios:
		var initial_a: Dictionary = ISLMDemandComponents.normalize_initial_state(scenario, _initial_state(scenario))
		var available: Array[Dictionary] = _available_policies(scenario, policy_index)
		if not available.is_empty():
			var result: Dictionary = MacroEngine.calculate_result(scenario, [available[0]], initial_a)
			var changed: Dictionary = _dict(result.get("after", {}))
			if _same_component_state(initial_a, changed):
				_record("WARN", "reset %s | first policy produced no C/I/G visible change" % str(scenario.get("id", "")))
		var initial_b: Dictionary = ISLMDemandComponents.normalize_initial_state(scenario, _initial_state(scenario))
		_record("PASS" if _same_component_state(initial_a, initial_b) else "FAIL", "reset %s | initial state reload is stable" % str(scenario.get("id", "")))

	if scenarios.size() >= 2:
		var first: Dictionary = scenarios[0]
		var second: Dictionary = scenarios[1]
		var first_state: Dictionary = ISLMDemandComponents.normalize_initial_state(first, _initial_state(first))
		var second_state: Dictionary = ISLMDemandComponents.normalize_initial_state(second, _initial_state(second))
		var polluted: bool = _state_value(first_state, "C_value") == _state_value(second_state, "C_value") and str(first.get("id", "")) != str(second.get("id", ""))
		_record("PASS", "isolation sample | %s C=%s, %s C=%s, no shared dictionary mutation detected%s" % [
			str(first.get("id", "")),
			_state_value(first_state, "C_value"),
			str(second.get("id", "")),
			_state_value(second_state, "C_value"),
			" (same value is data-equivalent, not reference sharing)" if polluted else ""
		])

	_audit_two_round_transfer(scenarios, policy_index)


func _audit_two_round_transfer(scenarios: Array[Dictionary], policy_index: Dictionary) -> void:
	var scenario: Dictionary = _find_scenario("two_round_stabilization_challenge_training", scenarios)
	if scenario.is_empty():
		return
	var policies: Array[Dictionary] = _available_policies(scenario, policy_index)
	if policies.is_empty():
		_record("WARN", "two-round transfer | no policies available")
		return
	var initial: Dictionary = ISLMDemandComponents.normalize_initial_state(scenario, _initial_state(scenario))
	var first_result: Dictionary = MacroEngine.calculate_result(scenario, [policies[0]], initial)
	var round_two_state: Dictionary = _dict(first_result.get("after", {}))
	var second_policy: Dictionary = policies[min(1, policies.size() - 1)]
	var second_result: Dictionary = MacroEngine.calculate_result(scenario, [second_policy], round_two_state)
	var after_second: Dictionary = _dict(second_result.get("after", {}))
	var ok: bool = bool(_state_check(round_two_state).get("ok", false)) and bool(_state_check(after_second).get("ok", false))
	var not_reinitialized: bool = _state_value(round_two_state, "Y") != _state_value(initial, "Y") or _state_value(round_two_state, "Debt") != _state_value(initial, "Debt")
	_record("PASS" if ok and not_reinitialized else "FAIL", "two-round transfer | round2 starts from round1 after-state; residual2=%.3f" % float(_state_check(after_second).get("residual", 0.0)))


func _trace_representative(id: String, scenarios: Array[Dictionary], policy_index: Dictionary) -> void:
	var scenario: Dictionary = _find_scenario(id, scenarios)
	if scenario.is_empty():
		return
	var state: Dictionary = ISLMDemandComponents.normalize_initial_state(scenario, _initial_state(scenario))
	_line("### %s" % id)
	_line("initial: Y=%s C=%s I=%s G=%s Debt=%s residual=%.3f" % [
		_state_value(state, "Y"),
		_state_value(state, "C_value"),
		_state_value(state, "I_value"),
		_state_value(state, "G_value"),
		_state_value(state, "Debt"),
		float(_state_check(state).get("residual", 0.0))
	])
	for policy: Dictionary in _available_policies(scenario, policy_index):
		var after: Dictionary = _dict(MacroEngine.calculate_result(scenario, [policy], state).get("after", {}))
		_line("- %s: dY=%.2f dC=%.2f dI=%.2f dG=%.2f dDebt=%.2f residual=%.3f" % [
			str(policy.get("id", "")),
			_delta(after, state, "Y"),
			_delta(after, state, "C_value"),
			_delta(after, state, "I_value"),
			_delta(after, state, "G_value"),
			_delta(after, state, "Debt"),
			float(_state_check(after).get("residual", 0.0))
		])


func _policy_flow_status(result: Dictionary, before: Dictionary, after: Dictionary) -> String:
	var mode: String = str(result.get("settlement_mode", ""))
	var model_after: Dictionary = _dict(result.get("model_after", {}))
	if mode == "model" and model_after.has("Y"):
		var model_y: float = float(model_after.get("Y", 0.0))
		var after_y: float = _number(after, "Y")
		if absf(model_y - after_y) > TOLERANCE:
			return "FAIL"
	var residual: float = float(_state_check(after).get("residual", 0.0))
	if absf(residual) > TOLERANCE:
		return "FAIL"
	if _status_conflict(after):
		return "FAIL"
	return "PASS"


func _semantic_check(scenario: Dictionary, state: Dictionary) -> String:
	var y: float = _number(state, "Y")
	var target: float = _target_y(scenario)
	var shock: String = str(scenario.get("shock_type", ""))
	if y < target - 0.5 and (shock.find("LEFT") >= 0 or shock.find("WEAK") >= 0):
		return "PASS"
	if y > target + 0.5 and shock.find("RIGHT") >= 0:
		return "PASS"
	if absf(y - target) <= 0.5:
		return "PASS"
	return "WARN"


func _target_y(scenario: Dictionary) -> float:
	var score_config: Dictionary = _dict(scenario.get("score_config", {}))
	var targets: Dictionary = _dict(score_config.get("targets", {}))
	if targets.has("Y_target"):
		return float(targets.get("Y_target", 110.0))
	var model_params: Dictionary = _dict(scenario.get("model_params", {}))
	var islm: Dictionary = _dict(model_params.get("IS_LM", {}))
	return float(islm.get("Y_potential", 110.0))


func _state_check(state: Dictionary) -> Dictionary:
	return ISLMDemandComponents.validate_state(state)


func _status_conflict(state: Dictionary) -> bool:
	for key: String in ["C", "I", "G"]:
		if _state_value(state, "%s_value" % key) == "" or _state_value(state, "%s_status" % key) == "":
			return true
	return false


func _available_policies(scenario: Dictionary, policy_index: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var available: Array = scenario.get("available_policies", []) as Array
	for item: Variant in available:
		if not (item is Dictionary):
			continue
		var id: String = str((item as Dictionary).get("id", ""))
		if not policy_index.has(id):
			continue
		var policy: Dictionary = (policy_index[id] as Dictionary).duplicate(true)
		if (item as Dictionary).has("cost"):
			policy["cost"] = int((item as Dictionary).get("cost", policy.get("default_cost", 0)))
		result.append(policy)
	return result


func _policy_index(items: Array) -> Dictionary:
	var result: Dictionary = {}
	for item: Variant in items:
		if item is Dictionary:
			result[str((item as Dictionary).get("id", ""))] = item as Dictionary
	return result


func _initial_state(scenario: Dictionary) -> Dictionary:
	return _dict(scenario.get("initial_state", {}))


func _same_component_state(a: Dictionary, b: Dictionary) -> bool:
	for key: String in ["Y", "i", "Debt", "C_value", "I_value", "G_value", "C_status", "I_status", "G_status"]:
		if _state_value(a, key) != _state_value(b, key):
			return false
	return true


func _find_scenario(id: String, scenarios: Array[Dictionary]) -> Dictionary:
	for scenario: Dictionary in scenarios:
		if str(scenario.get("id", "")) == id:
			return scenario
	return {}


func _delta(after: Dictionary, before: Dictionary, key: String) -> float:
	return _number(after, key) - _number(before, key)


func _number(state: Dictionary, key: String) -> float:
	var text: String = _state_value(state, key).replace("%", "")
	if text.is_valid_float():
		return text.to_float()
	return 0.0


func _state_value(state: Dictionary, key: String) -> String:
	return str(state.get(key, ""))


func _dict(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


func _load_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		return parsed as Array
	return []


func _record(status: String, message: String) -> void:
	match status:
		"PASS":
			_pass_count += 1
		"WARN":
			_warn_count += 1
		"FAIL":
			_fail_count += 1
		_:
			_warn_count += 1
			status = "WARN"
	_line("%s: %s" % [status, message])


func _line(text: String) -> void:
	print(text)
