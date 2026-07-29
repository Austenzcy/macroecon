extends SceneTree

const ISLMDemandComponents = preload("res://scripts/engine/ISLMDemandComponents.gd")
const SCENARIOS_PATH: String = "res://data/scenarios.json"


func _init() -> void:
	var scenarios: Array = _load_scenarios()
	var has_error: bool = false
	for scenario_variant: Variant in scenarios:
		if not (scenario_variant is Dictionary):
			continue
		var scenario: Dictionary = scenario_variant as Dictionary
		if str(scenario.get("model_type", "")) != "IS_LM":
			continue
		var result: Dictionary = ISLMDemandComponents.validate_scenario_initial(scenario)
		var id: String = str(scenario.get("id", "unknown"))
		print("%s: C=%s I=%s G=%s Y=%s residual=%.3f %s" % [
			id,
			str(result.get("C", 0.0)),
			str(result.get("I", 0.0)),
			str(result.get("G", 0.0)),
			str(result.get("Y", 0.0)),
			float(result.get("residual", 0.0)),
			"PASS" if bool(result.get("ok", false)) else "FAIL"
		])
		if not bool(result.get("ok", false)):
			has_error = true
	quit(1 if has_error else 0)


func _load_scenarios() -> Array:
	if not FileAccess.file_exists(SCENARIOS_PATH):
		return []
	var file := FileAccess.open(SCENARIOS_PATH, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		return parsed as Array
	return []
