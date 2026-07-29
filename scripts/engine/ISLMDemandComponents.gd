extends RefCounted

# Teaching decomposition for closed-economy IS-LM levels.
# C, I, and G use the same abstract output unit as Y.

const COMPONENT_KEYS: Array[String] = ["C", "I", "G"]
const VALUE_KEYS: Dictionary = {
	"C": "C_value",
	"I": "I_value",
	"G": "G_value"
}
const STATUS_KEYS: Dictionary = {
	"C": "C_status",
	"I": "I_status",
	"G": "G_status"
}
const BASE_SHARES: Dictionary = {
	"C": 0.60,
	"I": 0.20,
	"G": 0.20
}
const STATUS_MULTIPLIERS: Dictionary = {
	"low": 0.90,
	"normal": 1.00,
	"high": 1.10
}
const NORMAL_MAX_MULTIPLIER: float = 1.15
const STATUS_LOW: String = "偏低"
const STATUS_NORMAL: String = "适中"
const STATUS_LEGACY_NORMAL: String = "正常"
const STATUS_HIGH: String = "偏高"


static func normalize_initial_state(scenario: Dictionary, state: Dictionary) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var y: float = _state_float(next_state, "Y", _scenario_initial_y(scenario))
	var statuses: Dictionary = _component_statuses(next_state)
	var values: Dictionary = _calibrated_values(y, statuses)
	_write_components(next_state, values, statuses)
	return next_state


static func update_after_policy(scenario: Dictionary, before_state: Dictionary, after_state: Dictionary, selected_policies: Array[Dictionary]) -> Dictionary:
	var next_state: Dictionary = after_state.duplicate(true)
	var y: float = _state_float(next_state, "Y", _scenario_initial_y(scenario))
	var statuses: Dictionary = _component_statuses(before_state)
	_apply_policy_status_signals(statuses, selected_policies)
	var values: Dictionary = _calibrated_values(y, statuses)
	_write_components(next_state, values, statuses)
	return next_state


static func validate_scenario_initial(scenario: Dictionary) -> Dictionary:
	var initial_variant: Variant = scenario.get("initial_state", {})
	var state: Dictionary = initial_variant as Dictionary if initial_variant is Dictionary else {}
	var normalized: Dictionary = normalize_initial_state(scenario, state)
	return validate_state(normalized)


static func validate_state(state: Dictionary) -> Dictionary:
	var y: float = _state_float(state, "Y", 0.0)
	var c: float = _state_float(state, "C_value", NAN)
	var i: float = _state_float(state, "I_value", NAN)
	var g: float = _state_float(state, "G_value", NAN)
	var residual: float = y - (c + i + g)
	var ok: bool = is_finite(c) and is_finite(i) and is_finite(g) and c >= 0.0 and i >= 0.0 and g >= 0.0 and absf(residual) <= 0.11
	return {
		"ok": ok,
		"Y": y,
		"C": c,
		"I": i,
		"G": g,
		"residual": residual,
		"C_status": str(state.get("C_status", state.get("C", STATUS_NORMAL))),
		"I_status": str(state.get("I_status", state.get("I", STATUS_NORMAL))),
		"G_status": str(state.get("G_status", state.get("G", STATUS_NORMAL)))
	}


static func value_key(symbol: String) -> String:
	return str(VALUE_KEYS.get(symbol, symbol))


static func status_key(symbol: String) -> String:
	return str(STATUS_KEYS.get(symbol, symbol))


static func _write_components(state: Dictionary, values: Dictionary, statuses: Dictionary) -> void:
	var rounded: Dictionary = {}
	var running_total: float = 0.0
	for key: String in COMPONENT_KEYS:
		if key == "G":
			continue
		var value: float = snappedf(float(values.get(key, 0.0)), 0.1)
		rounded[key] = value
		running_total += value
	var y: float = _state_float(state, "Y", running_total + float(values.get("G", 0.0)))
	rounded["G"] = snappedf(y - running_total, 0.1)

	for key: String in COMPONENT_KEYS:
		var value_key_name: String = value_key(key)
		var status_key_name: String = status_key(key)
		state[value_key_name] = _format_number(float(rounded.get(key, 0.0)), 1)
		var status_text: String = _display_status(str(statuses.get(key, STATUS_NORMAL)))
		state[status_key_name] = status_text
		if not state.has(key) or not _is_numeric_text(str(state.get(key))):
			state[key] = _legacy_status(status_text)


static func _calibrated_values(y: float, statuses: Dictionary) -> Dictionary:
	var base_values: Dictionary = {}
	for key: String in COMPONENT_KEYS:
		base_values[key] = y * float(BASE_SHARES.get(key, 0.0))

	var values: Dictionary = {}
	var fixed_total: float = 0.0
	var normal_keys: Array[String] = []
	for key: String in COMPONENT_KEYS:
		var bucket: String = _status_bucket(str(statuses.get(key, STATUS_NORMAL)))
		if bucket == "normal":
			normal_keys.append(key)
			continue
		var value: float = float(base_values.get(key, 0.0)) * float(STATUS_MULTIPLIERS.get(bucket, 1.0))
		values[key] = value
		fixed_total += value

	if normal_keys.is_empty():
		var raw_total: float = 0.0
		for key: String in COMPONENT_KEYS:
			if not values.has(key):
				values[key] = float(base_values.get(key, 0.0)) * float(STATUS_MULTIPLIERS.get(_status_bucket(str(statuses.get(key, STATUS_NORMAL))), 1.0))
			raw_total += float(values.get(key, 0.0))
		var scale: float = y / raw_total if raw_total > 0.0 else 1.0
		for key: String in COMPONENT_KEYS:
			values[key] = float(values.get(key, 0.0)) * scale
		return values

	var remaining: float = maxf(0.0, y - fixed_total)
	var normal_base_total: float = 0.0
	for key: String in normal_keys:
		normal_base_total += float(base_values.get(key, 0.0))
	var capped_normal_total: float = 0.0
	for key: String in normal_keys:
		var share: float = float(base_values.get(key, 0.0)) / normal_base_total if normal_base_total > 0.0 else 1.0 / float(normal_keys.size())
		var normal_value: float = remaining * share
		var normal_cap: float = float(base_values.get(key, 0.0)) * NORMAL_MAX_MULTIPLIER
		normal_value = minf(normal_value, normal_cap)
		values[key] = normal_value
		capped_normal_total += normal_value
	var capped_total: float = fixed_total + capped_normal_total
	if capped_total < y - 0.001:
		var adjustable_keys: Array[String] = []
		var adjustable_base_total: float = 0.0
		for key: String in COMPONENT_KEYS:
			var bucket: String = _status_bucket(str(statuses.get(key, STATUS_NORMAL)))
			if bucket == "low":
				adjustable_keys.append(key)
				adjustable_base_total += float(base_values.get(key, 0.0))
		if adjustable_keys.is_empty():
			adjustable_keys = COMPONENT_KEYS.duplicate()
			for key: String in COMPONENT_KEYS:
				adjustable_base_total += float(base_values.get(key, 0.0))
		var extra: float = y - capped_total
		for key: String in adjustable_keys:
			var share: float = float(base_values.get(key, 0.0)) / adjustable_base_total if adjustable_base_total > 0.0 else 1.0 / float(adjustable_keys.size())
			values[key] = float(values.get(key, 0.0)) + extra * share
	return values


static func _component_statuses(state: Dictionary) -> Dictionary:
	var statuses: Dictionary = {}
	for key: String in COMPONENT_KEYS:
		var status_text: String = str(state.get(status_key(key), state.get(key, STATUS_NORMAL)))
		statuses[key] = _display_status(status_text)
	return statuses


static func _apply_policy_status_signals(statuses: Dictionary, selected_policies: Array[Dictionary]) -> void:
	for policy: Dictionary in selected_policies:
		match str(policy.get("id", "")):
			"increase_government_purchase":
				statuses["G"] = STATUS_HIGH
			"tax_cut":
				statuses["C"] = _improved_demand_status(str(statuses.get("C", STATUS_NORMAL)))
			"expansionary_monetary_policy":
				statuses["I"] = _improved_demand_status(str(statuses.get("I", STATUS_NORMAL)))
			"contractionary_fiscal_policy":
				statuses["G"] = STATUS_LOW
			"contractionary_monetary_policy":
				statuses["I"] = STATUS_LOW


static func _improved_demand_status(status_text: String) -> String:
	var bucket: String = _status_bucket(status_text)
	if bucket == "low":
		return STATUS_NORMAL
	if bucket == "normal":
		return STATUS_HIGH
	return STATUS_HIGH


static func _scenario_initial_y(scenario: Dictionary) -> float:
	var initial_variant: Variant = scenario.get("initial_state", {})
	if initial_variant is Dictionary:
		return _state_float(initial_variant as Dictionary, "Y", 100.0)
	return 100.0


static func _state_float(state: Dictionary, key: String, fallback: float) -> float:
	if state.has(key):
		var text: String = str(state.get(key)).strip_edges().replace("%", "")
		if text.is_valid_float():
			return text.to_float()
	return fallback


static func _status_bucket(status_text: String) -> String:
	if status_text.find(STATUS_HIGH) >= 0 or status_text.find("较高") >= 0 or status_text == "high":
		return "high"
	if status_text.find(STATUS_LOW) >= 0 or status_text.find("较低") >= 0 or status_text == "low":
		return "low"
	return "normal"


static func _display_status(status_text: String) -> String:
	match _status_bucket(status_text):
		"high":
			return STATUS_HIGH
		"low":
			return STATUS_LOW
	return STATUS_NORMAL


static func _legacy_status(status_text: String) -> String:
	if status_text == STATUS_NORMAL:
		return STATUS_LEGACY_NORMAL
	return status_text


static func _is_numeric_text(text: String) -> bool:
	return text.strip_edges().replace("%", "").is_valid_float()


static func _format_number(value: float, decimals: int) -> String:
	match decimals:
		0:
			return "%.0f" % value
		1:
			return "%.1f" % value
		_:
			return "%.2f" % value
