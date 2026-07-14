extends Node

signal wisdom_points_changed

const DialogueOverlayScript = preload("res://scripts/ui/DialogueOverlay.gd")
const HintConfirmModalScript = preload("res://scripts/ui/HintConfirmModal.gd")

const NARRATIVE_PATH: String = "res://data/chapters/ISLM_chapter_narrative_v1.json"

const INITIAL_WISDOM_POINTS: int = 10
const HINT_COST: int = 2
const MAX_HINTS_PER_LEVEL: int = 3
const START_YEAR: int = 1000
const START_QUARTER: int = 1

var wisdom_points: int = INITIAL_WISDOM_POINTS
var seen_tutorials: Dictionary = {}
var unlocked_hints: Dictionary = {}

var _active_overlay: Control
var _active_overlay_layer: CanvasLayer
var _active_modal_layer: CanvasLayer
var _pending_sequences: Array[Dictionary] = []
var _narrative_cache: Dictionary = {}

var characters: Dictionary = {
	"chief_minister": {"name": "首席大臣", "avatar": "placeholder_chief_minister"},
	"fiscal_minister": {"name": "财政大臣", "avatar": "placeholder_fiscal"},
	"central_bank_governor": {"name": "中央银行行长", "avatar": "placeholder_central_bank"},
	"industry_minister": {"name": "产业大臣", "avatar": "placeholder_industry"},
	"livelihood_minister": {"name": "民生大臣", "avatar": "placeholder_livelihood"},
	"economic_advisor": {"name": "首席经济顾问", "avatar": "placeholder_advisor"}
}


func reset_runtime_state() -> void:
	wisdom_points = INITIAL_WISDOM_POINTS
	seen_tutorials.clear()
	unlocked_hints.clear()
	_pending_sequences.clear()
	if _active_overlay != null and is_instance_valid(_active_overlay):
		_free_overlay_layer()
	_active_overlay = null
	if _active_modal_layer != null and is_instance_valid(_active_modal_layer):
		_active_modal_layer.queue_free()
	_active_modal_layer = null
	wisdom_points_changed.emit()


func get_characters() -> Dictionary:
	var data: Dictionary = _narrative_data()
	var value: Variant = data.get("characters", characters)
	if value is Dictionary:
		return value as Dictionary
	return characters


func get_wisdom_points() -> int:
	return wisdom_points


func has_seen_tutorial(tutorial_id: String) -> bool:
	return bool(seen_tutorials.get(tutorial_id, false))


func mark_tutorial_seen(tutorial_id: String) -> void:
	seen_tutorials[tutorial_id] = true


func play_tutorial_once(host: Control, tutorial_id: String, steps: Array, target_map: Dictionary = {}, on_finished: Callable = Callable()) -> bool:
	if has_seen_tutorial(tutorial_id):
		return false
	mark_tutorial_seen(tutorial_id)
	play_steps(host, steps, target_map, on_finished)
	return true


func play_steps(host: Control, steps: Array, target_map: Dictionary = {}, on_finished: Callable = Callable()) -> void:
	if host == null or not is_instance_valid(host) or steps.is_empty():
		if on_finished.is_valid():
			on_finished.call()
		return
	var request: Dictionary = {
		"host": host,
		"steps": steps.duplicate(true),
		"target_map": target_map.duplicate(),
		"on_finished": on_finished
	}
	if _active_overlay != null and is_instance_valid(_active_overlay):
		_pending_sequences.append(request)
		return
	_start_sequence(request)


func request_hint(host: Control, scenario_id: String, target_map: Dictionary = {}) -> void:
	var hints: Array = _hints_for_scenario(scenario_id)
	if hints.is_empty():
		play_steps(host, [_step("首席经济顾问", "本关的提示数据尚未接入，请先根据理论面板和当前状态判断政策方向。")], target_map)
		return

	var unlocked: Array = _unlocked_hint_indices(scenario_id)
	if unlocked.size() >= MAX_HINTS_PER_LEVEL or unlocked.size() >= hints.size():
		_show_unlocked_hints(host, scenario_id, target_map)
		return

	var next_index: int = unlocked.size()
	if wisdom_points < HINT_COST:
		play_steps(host, [_step("首席经济顾问", "智慧点数不足，暂时无法解锁新的提示。已解锁提示仍可重复查看。")], target_map)
		return

	var message: String = "查看第 %d 条提示将消耗 %d 点智慧点数。是否确认？" % [next_index + 1, HINT_COST]
	var modal: Control = HintConfirmModalScript.new() as Control
	modal.call("setup", message)
	var layer: CanvasLayer = _create_canvas_layer(host, "HintConfirmModalLayer", 101)
	_active_modal_layer = layer
	modal.connect("confirmed", _on_hint_confirmed.bind(layer, host, scenario_id, next_index, target_map))
	modal.connect("cancelled", _on_hint_cancelled.bind(layer, host, target_map))
	layer.add_child(modal)


func refresh_target_map(target_map: Dictionary) -> void:
	if _active_overlay != null and is_instance_valid(_active_overlay):
		_active_overlay.call("update_target_map", target_map)


func is_dialogue_active() -> bool:
	return _active_overlay != null and is_instance_valid(_active_overlay)


func is_modal_active() -> bool:
	return _active_modal_layer != null and is_instance_valid(_active_modal_layer)


func is_blocking_game_input() -> bool:
	return is_dialogue_active() or is_modal_active()


func replay_unlocked_hints(host: Control, scenario_id: String, target_map: Dictionary = {}) -> void:
	var unlocked: Array = _unlocked_hint_indices(scenario_id)
	if unlocked.is_empty():
		play_steps(host, [_step("首席经济顾问", "当前还没有已解锁的提示。请先请求提示，确认后再解锁。")], target_map)
		return
	_show_unlocked_hints(host, scenario_id, target_map)


func get_current_quarter_label(scenario_id: String = "") -> String:
	var level_index: int = _level_index_for_scenario(scenario_id)
	var absolute_quarter: int = (START_QUARTER - 1) + level_index
	var year: int = START_YEAR + int(floor(float(absolute_quarter) / 4.0))
	var quarter: int = absolute_quarter % 4 + 1
	return "公元%d年 %s" % [year, _quarter_name(quarter)]


func advance_quarter_for_level(level_index: int) -> String:
	var absolute_quarter: int = (START_QUARTER - 1) + max(level_index, 0)
	var year: int = START_YEAR + int(floor(float(absolute_quarter) / 4.0))
	var quarter: int = absolute_quarter % 4 + 1
	return "公元%d年 %s" % [year, _quarter_name(quarter)]


func basic_policy_desk_steps() -> Array:
	return _tutorial_sequence_steps("first_policy_desk_basic_intro", [
		_step("首席经济顾问", "陛下，这里是当前问题栏，会告诉您本关正在处理的经济冲击。", "problem_panel"),
		_step("首席经济顾问", "需要模型背景时，可以打开图表/理论面板，先看外生冲击如何移动 IS 或 LM 曲线。", "theory_panel"),
		_step("首席经济顾问", "左侧是政策卡牌区。您将在这里选择本回合要提交的政策。", "policy_cards"),
		_step("首席经济顾问", "右侧是宏观状态面板，会显示当前已经发生的变量状态。", "right_info_panel")
	])


func wisdom_intro_steps() -> Array:
	return _tutorial_sequence_steps("after_basic_intro_wisdom_system", [
		_step("首席经济顾问", "如果一时拿不准，可以使用智慧点数请求提示。每次解锁新提示会消耗 2 点。", "wisdom_panel"),
		_step("首席经济顾问", "已解锁的提示可以重复查看，不会再次扣点。智慧点数暂时不计入治理评分。", "wisdom_panel")
	])


func budget_intro_steps() -> Array:
	return _tutorial_sequence_steps("first_budget_mode_intro", [
		_step("财政大臣", "陛下，组合训练关中政策资源有限，每张政策卡都会消耗政策点数。", "policy_points_area"),
		_step("首席经济顾问", "请在点数限制内选择政策组合，不能无限叠加政策。", "policy_cards")
	])


func confirm_policy_steps() -> Array:
	return _tutorial_sequence_steps("after_first_card_selected", [
		_step("首席经济顾问", "您已经选择了政策。确认政策后，本回合将进入结算。", "confirm_policy_button")
	])


func replay_button_steps() -> Array:
	return _tutorial_sequence_steps("after_first_policy_confirmed", [
		_step("首席经济顾问", "政策已经执行。现在可以查看模型回放，看看政策如何移动 IS 或 LM 曲线。", "model_replay_button")
	])


func replay_window_steps() -> Array:
	return _tutorial_sequence_steps("first_model_replay_opened", [
		_step("首席经济顾问", "模型回放窗口会显示政策执行前后的曲线和均衡点，用来解释刚才的结算结果。", "model_replay_window")
	])


func score_steps() -> Array:
	return _tutorial_sequence_steps("first_scored_final_summary_intro", [
		_step("首席经济顾问", "这里是本关评分。它评价的是当前短期 IS-LM 情境下的治理效果，不代表长期影响。", "score_panel")
	])


func chapter_opening_steps() -> Array:
	var data: Dictionary = _narrative_data()
	var steps_variant: Variant = data.get("chapter_opening", [])
	if steps_variant is Array:
		return _normalize_steps(steps_variant as Array)
	return []


func level_opening_steps(scenario_id: String = "") -> Array:
	var level: Dictionary = _level_narrative_for_scenario(scenario_id)
	var steps_variant: Variant = level.get("opening_dialogue", [])
	if steps_variant is Array:
		return _normalize_steps(steps_variant as Array)
	return []


func after_result_comment_steps(scenario_id: String = "") -> Array:
	var level: Dictionary = _level_narrative_for_scenario(scenario_id)
	var steps_variant: Variant = level.get("after_result_comments", [])
	if steps_variant is Array:
		return _normalize_steps(steps_variant as Array)
	return []


func level_end_steps(scenario_id: String = "") -> Array:
	var level: Dictionary = _level_narrative_for_scenario(scenario_id)
	var steps_variant: Variant = level.get("level_end_dialogue", [])
	if steps_variant is Array:
		return _normalize_steps(steps_variant as Array)
	return []


func _start_sequence(request: Dictionary) -> void:
	var host: Control = request.get("host") as Control
	if host == null or not is_instance_valid(host):
		_start_next_pending()
		return
	var overlay: Control = DialogueOverlayScript.new() as Control
	_active_overlay = overlay
	var layer: CanvasLayer = _create_canvas_layer(host, "DialogueOverlayLayer", 100)
	_active_overlay_layer = layer
	overlay.call("setup", request.get("steps", []), request.get("target_map", {}))
	overlay.connect("finished", _on_overlay_finished.bind(request.get("on_finished", Callable())))
	layer.add_child(overlay)


func _on_overlay_finished(on_finished: Callable) -> void:
	_active_overlay = null
	_free_overlay_layer()
	if on_finished.is_valid():
		on_finished.call()
	_start_next_pending()


func _start_next_pending() -> void:
	if _pending_sequences.is_empty():
		return
	var next_request: Dictionary = _pending_sequences.pop_front()
	_start_sequence(next_request)


func _create_canvas_layer(host: Control, layer_name: String, layer_index: int) -> CanvasLayer:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = layer_name
	layer.layer = layer_index
	var tree: SceneTree = host.get_tree()
	if tree != null and tree.root != null:
		tree.root.add_child(layer)
	else:
		add_child(layer)
	return layer


func _free_overlay_layer() -> void:
	if _active_overlay_layer != null and is_instance_valid(_active_overlay_layer):
		_active_overlay_layer.queue_free()
	_active_overlay_layer = null


func _free_modal_layer(layer: CanvasLayer) -> void:
	if layer != null and is_instance_valid(layer):
		layer.queue_free()
	if _active_modal_layer == layer:
		_active_modal_layer = null


func _on_hint_confirmed(layer: CanvasLayer, host: Control, scenario_id: String, hint_index: int, target_map: Dictionary) -> void:
	_free_modal_layer(layer)
	wisdom_points = max(0, wisdom_points - HINT_COST)
	wisdom_points_changed.emit()
	var unlocked: Array = _unlocked_hint_indices(scenario_id)
	if not unlocked.has(hint_index):
		unlocked.append(hint_index)
		unlocked_hints[scenario_id] = unlocked
	var hints: Array = _hints_for_scenario(scenario_id)
	var hint: Dictionary = hints[hint_index] as Dictionary
	play_steps(host, [hint], target_map)


func _on_hint_cancelled(layer: CanvasLayer, host: Control, target_map: Dictionary) -> void:
	_free_modal_layer(layer)
	play_steps(host, [_step("首席经济顾问", "已取消查看提示，智慧点数没有变化。")], target_map)


func _show_unlocked_hints(host: Control, scenario_id: String, target_map: Dictionary) -> void:
	var hints: Array = _hints_for_scenario(scenario_id)
	var unlocked: Array = _unlocked_hint_indices(scenario_id)
	var steps: Array = []
	for index_variant: Variant in unlocked:
		var index: int = int(index_variant)
		if index >= 0 and index < hints.size():
			steps.append(hints[index])
	if steps.is_empty():
		steps.append(_step("首席经济顾问", "当前还没有已解锁的提示。"))
	play_steps(host, steps, target_map)


func _narrative_data() -> Dictionary:
	if _narrative_cache.is_empty():
		_narrative_cache = DataLoader.load_dict(NARRATIVE_PATH)
	return _narrative_cache


func _tutorial_sequence_steps(sequence_id: String, fallback: Array) -> Array:
	var data: Dictionary = _narrative_data()
	var sequences_variant: Variant = data.get("tutorial_sequences", {})
	if sequences_variant is Dictionary:
		var sequence_variant: Variant = (sequences_variant as Dictionary).get(sequence_id, {})
		if sequence_variant is Dictionary:
			var steps_variant: Variant = (sequence_variant as Dictionary).get("steps", [])
			if steps_variant is Array and not (steps_variant as Array).is_empty():
				return _normalize_steps(steps_variant as Array)
	return fallback


func _level_narrative_for_scenario(scenario_id: String = "") -> Dictionary:
	var id_to_find: String = scenario_id
	if id_to_find.is_empty():
		id_to_find = GameState.current_scenario_id
	var scenario: Dictionary = DataLoader.get_scenario_by_id(id_to_find)
	var narrative_id: String = str(scenario.get("narrative_level_id", scenario.get("level_group", "")))
	var content_id: String = str(scenario.get("content_level_id", scenario.get("level_group", "")))
	var data: Dictionary = _narrative_data()
	var levels_variant: Variant = data.get("levels", [])
	if levels_variant is Array:
		var levels: Array = levels_variant as Array
		for item: Variant in levels:
			if not (item is Dictionary):
				continue
			var level: Dictionary = item as Dictionary
			var level_id: String = str(level.get("level_id", ""))
			if level_id == narrative_id or level_id == content_id:
				return level
	return {}


func _normalize_steps(raw_steps: Array) -> Array:
	var steps: Array = []
	for item: Variant in raw_steps:
		if item is Dictionary:
			steps.append(_normalize_step(item as Dictionary))
	return steps


func _normalize_step(raw_step: Dictionary) -> Dictionary:
	var speaker_name: String = str(raw_step.get("speaker_name", raw_step.get("speaker", "")))
	var speaker_id: String = str(raw_step.get("speaker_id", ""))
	var character_data: Dictionary = get_characters()
	if speaker_name.is_empty() and not speaker_id.is_empty():
		var character_variant: Variant = character_data.get(speaker_id, {})
		if character_variant is Dictionary:
			speaker_name = str((character_variant as Dictionary).get("name", speaker_id))
	if speaker_name.is_empty():
		speaker_name = "首席经济顾问"

	var avatar: String = str(raw_step.get("avatar", "placeholder"))
	if avatar == "placeholder" and not speaker_id.is_empty():
		var avatar_character_variant: Variant = character_data.get(speaker_id, {})
		if avatar_character_variant is Dictionary:
			avatar = str((avatar_character_variant as Dictionary).get("avatar", avatar))

	return {
		"speaker": speaker_name,
		"speaker_id": speaker_id,
		"avatar": avatar,
		"text": str(raw_step.get("text", "")),
		"target": str(raw_step.get("target", "")),
		"continue_text": str(raw_step.get("continue_text", "单击以继续"))
	}


func _unlocked_hint_indices(scenario_id: String) -> Array:
	var value: Variant = unlocked_hints.get(scenario_id, [])
	if value is Array:
		return (value as Array).duplicate()
	return []


func _hints_for_scenario(scenario_id: String) -> Array:
	var level: Dictionary = _level_narrative_for_scenario(scenario_id)
	var hints_variant: Variant = level.get("hints", [])
	if hints_variant is Array and not (hints_variant as Array).is_empty():
		return _normalize_steps(hints_variant as Array)
	return [
		_step("首席经济顾问", "本关的提示数据尚未接入，请先根据理论面板和当前状态判断政策方向。", "theory_panel")
	]


func _step(speaker: String, text: String, target: String = "") -> Dictionary:
	return {
		"speaker": speaker,
		"avatar": "placeholder",
		"text": text,
		"target": target,
		"continue_text": "单击以继续"
	}


func _level_index_for_scenario(scenario_id: String) -> int:
	var id_to_find: String = scenario_id
	if id_to_find == "":
		id_to_find = GameState.current_scenario_id
	var current_scenario: Dictionary = DataLoader.get_scenario_by_id(id_to_find)
	if not current_scenario.is_empty() and current_scenario.has("level_order"):
		return maxi(int(current_scenario.get("level_order", 1)) - 1, 0)
	var scenarios: Array = DataLoader.load_array("res://data/scenarios.json")
	var groups: Array[String] = []
	for item: Variant in scenarios:
		if not item is Dictionary:
			continue
		var scenario: Dictionary = item as Dictionary
		var group: String = str(scenario.get("level_group", scenario.get("id", "")))
		if not groups.has(group):
			groups.append(group)
		if str(scenario.get("id", "")) == id_to_find:
			return max(0, groups.find(group))
	return 0


func _quarter_name(quarter: int) -> String:
	match quarter:
		1:
			return "第一季度"
		2:
			return "第二季度"
		3:
			return "第三季度"
		4:
			return "第四季度"
		_:
			return "第一季度"
