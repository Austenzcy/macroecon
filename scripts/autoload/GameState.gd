extends Node

var current_scenario_id: String = "consumer_confidence_drop_basic"
var selected_policy_id: String = ""
var selected_policy_name: String = ""
var ui_scale: float = 1.0


func select_policy(policy_id: String, policy_name: String) -> void:
	selected_policy_id = policy_id
	selected_policy_name = policy_name


func clear_selection() -> void:
	selected_policy_id = ""
	selected_policy_name = ""


func set_current_scenario(scenario_id: String) -> void:
	current_scenario_id = scenario_id
	clear_selection()


func get_current_scenario() -> Dictionary:
	return DataLoader.get_scenario_by_id(current_scenario_id)


func set_ui_scale(value: float) -> void:
	ui_scale = clampf(value, 0.8, 1.2)
