extends Node

var current_scenario_id: String = "consumer_confidence_drop_basic"
var selected_policy_id: String = ""
var selected_policy_name: String = ""
var ui_scale: float = 1.0

var current_round: int = 1
var max_rounds: int = 2
var current_state: Dictionary = {}
var last_result: Dictionary = {}
var round_history: Array[Dictionary] = []


func _ready() -> void:
	if current_state.is_empty():
		current_state = _load_initial_state()


func select_policy(policy_id: String, policy_name: String) -> void:
	selected_policy_id = policy_id
	selected_policy_name = policy_name


func clear_selection() -> void:
	selected_policy_id = ""
	selected_policy_name = ""


func set_current_scenario(scenario_id: String) -> void:
	start_scenario(scenario_id)


func start_scenario(scenario_id: String) -> void:
	current_scenario_id = scenario_id
	current_round = 1
	max_rounds = 2
	current_state = _load_initial_state()
	last_result = {}
	round_history.clear()
	clear_selection()


func reset_for_new_game() -> void:
	current_round = 1
	max_rounds = 2
	current_state = _load_initial_state()
	last_result = {}
	round_history.clear()
	clear_selection()


func get_current_scenario() -> Dictionary:
	return DataLoader.get_scenario_by_id(current_scenario_id)


func get_current_state() -> Dictionary:
	if current_state.is_empty():
		current_state = _load_initial_state()
	return current_state.duplicate(true)


func set_last_result(result: Dictionary) -> void:
	last_result = result.duplicate(true)
	round_history.append({
		"round": current_round,
		"scenario_id": current_scenario_id,
		"selected_policies": last_result.get("executed_policies", []),
		"result": last_result.duplicate(true)
	})


func update_current_state_from_result(result: Dictionary) -> void:
	var after_variant: Variant = result.get("after", {})
	if after_variant is Dictionary:
		current_state = (after_variant as Dictionary).duplicate(true)
		if current_state.has("π"):
			current_state["蟺"] = current_state.get("π")


func advance_round() -> void:
	if not last_result.is_empty():
		update_current_state_from_result(last_result)
	if current_round < max_rounds:
		current_round += 1
	clear_selection()


func is_final_round() -> bool:
	return current_round >= max_rounds


func set_ui_scale(value: float) -> void:
	ui_scale = clampf(value, 0.8, 1.2)


func _load_initial_state() -> Dictionary:
	var scenario: Dictionary = get_current_scenario()
	var initial_variant: Variant = scenario.get("initial_state", {})
	if initial_variant is Dictionary and not (initial_variant as Dictionary).is_empty():
		return (initial_variant as Dictionary).duplicate(true)
	return DataLoader.load_dict("res://data/variables.json").duplicate(true)
