extends Node

const SCENARIOS_PATH: String = "res://data/scenarios.json"

var current_scenario_id: String = "consumer_confidence_drop_basic"
var selected_policy_id: String = ""
var selected_policy_name: String = ""
var ui_scale: float = 1.0

var current_round: int = 1
var max_rounds: int = 1
var initial_state: Dictionary = {}
var current_state: Dictionary = {}
var last_result: Dictionary = {}
var round_history: Array[Dictionary] = []
var return_to_confirmed_policy_desk: bool = false

var current_visible_level: int = 1
var unlocked_visible_level: int = 1


func _ready() -> void:
	if current_state.is_empty():
		initial_state = _load_initial_state()
		current_state = initial_state.duplicate(true)


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
	current_visible_level = get_visible_level_for_scenario(scenario_id)
	current_round = 1
	max_rounds = _load_max_rounds()
	initial_state = _load_initial_state()
	current_state = initial_state.duplicate(true)
	last_result = {}
	round_history.clear()
	return_to_confirmed_policy_desk = false
	clear_selection()


func start_visible_level(level_number: int) -> bool:
	if not is_visible_level_unlocked(level_number):
		return false
	var level: Dictionary = get_visible_level(level_number)
	var scenario_id: String = str(level.get("scenario_id", ""))
	if scenario_id.is_empty():
		return false
	current_visible_level = level_number
	start_scenario(scenario_id)
	return true


func reset_for_new_game() -> void:
	current_visible_level = 1
	unlocked_visible_level = 1
	current_round = 1
	max_rounds = _load_max_rounds()
	initial_state = _load_initial_state()
	current_state = initial_state.duplicate(true)
	last_result = {}
	round_history.clear()
	return_to_confirmed_policy_desk = false
	clear_selection()
	if has_node("/root/NarrativeManager"):
		NarrativeManager.reset_runtime_state()


func clear_current_run() -> void:
	current_round = 1
	last_result = {}
	round_history.clear()
	return_to_confirmed_policy_desk = false
	clear_selection()


func mark_current_visible_level_completed() -> void:
	var next_level: int = current_visible_level + 1
	unlocked_visible_level = mini(maxi(unlocked_visible_level, next_level), get_visible_levels().size())


func is_visible_level_unlocked(level_number: int) -> bool:
	return level_number >= 1 and level_number <= unlocked_visible_level


func get_unlocked_visible_level() -> int:
	return unlocked_visible_level


func get_visible_level(level_number: int) -> Dictionary:
	for level: Dictionary in get_visible_levels():
		if int(level.get("level_number", 0)) == level_number:
			return level.duplicate(true)
	return {}


func get_current_visible_level_number() -> int:
	if current_visible_level <= 0:
		current_visible_level = get_visible_level_for_scenario(current_scenario_id)
	return current_visible_level


func get_visible_level_for_scenario(scenario_id: String) -> int:
	for level: Dictionary in get_visible_levels():
		if str(level.get("scenario_id", "")) == scenario_id:
			return int(level.get("level_number", 1))
	var scenario: Dictionary = DataLoader.get_scenario_by_id(scenario_id)
	if not scenario.is_empty():
		return maxi(int(scenario.get("level_order", 1)), 1)
	return 1


func get_visible_levels() -> Array[Dictionary]:
	var scenarios: Array = DataLoader.load_array(SCENARIOS_PATH)
	var grouped: Dictionary = {}
	var order: Array[String] = []
	for item: Variant in scenarios:
		if not (item is Dictionary):
			continue
		var scenario: Dictionary = item as Dictionary
		var group_id: String = str(scenario.get("level_group", scenario.get("id", "")))
		if group_id.is_empty():
			continue
		if not grouped.has(group_id):
			grouped[group_id] = {
				"group_id": group_id,
				"level_order": int(scenario.get("level_order", order.size() + 1)),
				"title": str(scenario.get("level_name", scenario.get("title", "IS-LM 关卡"))),
				"basic_id": "",
				"training_id": "",
				"fallback_id": str(scenario.get("id", ""))
			}
			order.append(group_id)
		var level: Dictionary = grouped[group_id] as Dictionary
		var scenario_id: String = str(scenario.get("id", ""))
		if str(scenario.get("selection_mode", "")) == "single" and str(scenario.get("settlement_mode", "")) == "demo":
			level["basic_id"] = scenario_id
		elif str(scenario.get("selection_mode", "")) == "budget" or str(scenario.get("settlement_mode", "")) == "model":
			level["training_id"] = scenario_id

	var levels: Array[Dictionary] = []
	for group_id: String in order:
		levels.append(grouped[group_id] as Dictionary)
	levels.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("level_order", 0)) < int(b.get("level_order", 0))
	)

	var visible: Array[Dictionary] = []
	var level_number: int = 1
	for level: Dictionary in levels:
		if level_number > 7:
			break
		var scenario_id: String = str(level.get("basic_id", ""))
		if level_number > 1 and not str(level.get("training_id", "")).is_empty():
			scenario_id = str(level.get("training_id", ""))
		if scenario_id.is_empty():
			scenario_id = str(level.get("fallback_id", ""))
		var scenario: Dictionary = DataLoader.get_scenario_by_id(scenario_id)
		visible.append({
			"level_number": level_number,
			"group_id": str(level.get("group_id", "")),
			"scenario_id": scenario_id,
			"title": str(level.get("title", scenario.get("title", "IS-LM 关卡"))),
			"round_count": _round_count_for_scenario(scenario)
		})
		level_number += 1
	return visible


func get_global_quarter_index(scenario_id: String = "", round_number: int = -1) -> int:
	var level_number: int = get_current_visible_level_number() if scenario_id.is_empty() else get_visible_level_for_scenario(scenario_id)
	var total: int = 0
	for level: Dictionary in get_visible_levels():
		var visible_number: int = int(level.get("level_number", 0))
		if visible_number >= level_number:
			break
		total += maxi(int(level.get("round_count", 1)), 1)
	var round_index: int = (current_round - 1) if round_number < 0 else (round_number - 1)
	return total + maxi(round_index, 0)


func get_current_scenario() -> Dictionary:
	return DataLoader.get_scenario_by_id(current_scenario_id)


func get_current_state() -> Dictionary:
	if current_state.is_empty():
		initial_state = _load_initial_state()
		current_state = initial_state.duplicate(true)
	return current_state.duplicate(true)


func get_initial_state() -> Dictionary:
	if initial_state.is_empty():
		initial_state = _load_initial_state()
	return initial_state.duplicate(true)


func set_last_result(result: Dictionary) -> void:
	last_result = result.duplicate(true)
	round_history.append({
		"round": current_round,
		"visible_level": get_current_visible_level_number(),
		"scenario_id": current_scenario_id,
		"selected_policies": last_result.get("executed_policies", []),
		"result": last_result.duplicate(true)
	})


func update_current_state_from_result(result: Dictionary) -> void:
	var after_variant: Variant = result.get("after", {})
	if after_variant is Dictionary:
		current_state = (after_variant as Dictionary).duplicate(true)
		if current_state.has("π") and not current_state.has("pi"):
			current_state["pi"] = current_state.get("π")
		elif current_state.has("pi") and not current_state.has("π"):
			current_state["π"] = current_state.get("pi")


func advance_round() -> void:
	if not last_result.is_empty():
		update_current_state_from_result(last_result)
	if current_round < max_rounds:
		current_round += 1
	return_to_confirmed_policy_desk = false
	clear_selection()


func is_final_round() -> bool:
	return current_round >= max_rounds


func mark_return_to_confirmed_policy_desk() -> void:
	return_to_confirmed_policy_desk = true


func consume_return_to_confirmed_policy_desk() -> bool:
	var should_restore: bool = return_to_confirmed_policy_desk
	return_to_confirmed_policy_desk = false
	return should_restore


func set_ui_scale(value: float) -> void:
	ui_scale = clampf(value, 0.8, 1.2)


func _load_initial_state() -> Dictionary:
	var scenario: Dictionary = get_current_scenario()
	var initial_variant: Variant = scenario.get("initial_state", {})
	if initial_variant is Dictionary and not (initial_variant as Dictionary).is_empty():
		return (initial_variant as Dictionary).duplicate(true)
	return DataLoader.load_dict("res://data/variables.json").duplicate(true)


func _load_max_rounds() -> int:
	return _round_count_for_scenario(get_current_scenario())


func _round_count_for_scenario(scenario: Dictionary) -> int:
	var round_value: int = int(scenario.get("round_count", scenario.get("max_rounds", 1)))
	return maxi(round_value, 1)
