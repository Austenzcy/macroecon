extends Node

var current_scenario_id: String = "confidence_slump"
var selected_policy_id: String = ""
var selected_policy_name: String = ""
var ui_scale: float = 1.0


func select_policy(policy_id: String, policy_name: String) -> void:
	selected_policy_id = policy_id
	selected_policy_name = policy_name


func clear_selection() -> void:
	selected_policy_id = ""
	selected_policy_name = ""


func set_ui_scale(value: float) -> void:
	ui_scale = clampf(value, 0.8, 1.2)
