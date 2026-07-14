extends Control

const ScoreEngine = preload("res://scripts/engine/ScoreEngine.gd")
const CONTENT_WIDTH: float = 1100.0

var _score_panel: PanelContainer
var _guide_targets: Dictionary = {}


func _ready() -> void:
	_build_ui()
	call_deferred("_maybe_start_score_guide")


func _build_ui() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()

	var background: ColorRect = ColorRect.new()
	background.color = Color(0.015, 0.018, 0.022, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.follow_focus = true
	add_child(scroll)

	var outer_margin: MarginContainer = MarginContainer.new()
	outer_margin.add_theme_constant_override("margin_left", 52)
	outer_margin.add_theme_constant_override("margin_top", 42)
	outer_margin.add_theme_constant_override("margin_right", 52)
	outer_margin.add_theme_constant_override("margin_bottom", 132)
	scroll.add_child(outer_margin)

	var page: VBoxContainer = VBoxContainer.new()
	page.custom_minimum_size = Vector2(CONTENT_WIDTH, 0)
	page.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.add_theme_constant_override("separation", 18)
	outer_margin.add_child(page)

	page.add_child(_build_title_panel())

	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	page.add_child(grid)

	grid.add_child(_build_round_history_panel())
	grid.add_child(_build_variable_path_panel())
	grid.add_child(_build_learning_summary_panel())
	grid.add_child(_build_score_panel())

	page.add_child(_build_long_term_panel())
	page.add_child(_build_action_button("返回主菜单", _on_return_main_menu_pressed))


func _build_title_panel() -> PanelContainer:
	var panel: PanelContainer = _new_panel()
	var box: VBoxContainer = _panel_content(panel, "")
	var scenario: Dictionary = GameState.get_current_scenario()

	var title: Label = Label.new()
	title.text = "关卡最终总结"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	box.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "%s｜共 %d 回合已完成" % [
		str(scenario.get("title", "当前测试关卡")),
		GameState.round_history.size()
	]
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.92, 0.80, 0.46)
	subtitle.add_theme_font_size_override("font_size", 19)
	box.add_child(subtitle)

	return panel


func _build_round_history_panel() -> PanelContainer:
	var panel: PanelContainer = _new_panel(Vector2(0, 380))
	var box: VBoxContainer = _panel_content(panel, "回合历史")
	if GameState.round_history.is_empty():
		_add_paragraph(box, "暂无回合历史。", Color(0.82, 0.88, 0.92), 16)
		return panel

	for entry: Dictionary in GameState.round_history:
		var round_number: int = int(entry.get("round", 0))
		var result: Dictionary = _dictionary_from_variant(entry.get("result", {}))
		_add_section_label(box, "第 %d 回合" % round_number)
		_add_paragraph(box, "已执行政策：%s" % _policy_names_text(_array_from_variant(result.get("executed_policies", []))), Color(0.96, 0.98, 1.0), 16)
		_add_paragraph(box, "结算方式：%s" % _settlement_label(result), Color(0.92, 0.80, 0.46), 15)
		_add_paragraph(box, "简要结果：%s" % _brief_result_text(result), Color(0.78, 0.86, 0.92), 15)

	return panel


func _build_variable_path_panel() -> PanelContainer:
	var panel: PanelContainer = _new_panel(Vector2(0, 380))
	var box: VBoxContainer = _panel_content(panel, "宏观变量轨迹")
	var states: Array[Dictionary] = [GameState.get_initial_state()]
	for entry: Dictionary in GameState.round_history:
		var result: Dictionary = _dictionary_from_variant(entry.get("result", {}))
		var after: Dictionary = _dictionary_from_variant(result.get("after", {}))
		if not after.is_empty():
			states.append(after)

	for key: String in ["Y", "u", "π", "i", "Debt"]:
		var values: Array[String] = []
		for state: Dictionary in states:
			values.append(_state_value(state, key))
		_add_info_row(box, key, " → ".join(values))
	_add_paragraph(box, "当前阶段使用文字轨迹，变量走势图后续再加入。", Color(0.70, 0.78, 0.84), 14)
	return panel


func _build_learning_summary_panel() -> PanelContainer:
	var panel: PanelContainer = _new_panel(Vector2(0, 380))
	var box: VBoxContainer = _panel_content(panel, "学习总结")
	_add_paragraph(box, "本关核心机制：", Color(0.86, 0.92, 0.96), 16)
	var scenario: Dictionary = GameState.get_current_scenario()
	var learning_points: Array = _array_from_variant(scenario.get("learning_points", []))
	if learning_points.is_empty():
		var fallback_point: String = str(scenario.get("model_hint", scenario.get("problem_title", "请结合当前模型标签复盘政策传导。")))
		learning_points.append(fallback_point)
	for point: Variant in learning_points:
		_add_bullet(box, str(point))

	var mechanisms: Array[String] = _unique_mechanisms()
	for item: String in mechanisms:
		_add_bullet(box, item)
	if _has_policy_combination():
		_add_section_label(box, "组合政策提示")
		_add_bullet(box, "组合政策应先合并对模型参数的影响，再重新求解均衡，而不是简单相加。")
	return panel


func _build_score_panel() -> PanelContainer:
	var panel: PanelContainer = _new_panel(Vector2(0, 380))
	panel.name = "ScorePanel"
	_score_panel = panel
	var box: VBoxContainer = _panel_content(panel, "评分系统")
	var scenario: Dictionary = GameState.get_current_scenario()
	var score_result: Dictionary = ScoreEngine.calculate_score(scenario, GameState.round_history, GameState.get_initial_state(), _final_state())

	if not bool(score_result.get("enabled", false)):
		_add_paragraph(box, str(score_result.get("overall_comment", "当前关卡未启用评分系统。")), Color(0.82, 0.88, 0.92), 16)
		return panel

	_add_paragraph(box, "总分：%.1f / %.0f" % [
		float(score_result.get("total", 0.0)),
		float(score_result.get("max_total", 100.0))
	], Color(0.96, 0.98, 1.0), 22)

	var items: Array = _array_from_variant(score_result.get("items", []))
	for item_variant: Variant in items:
		if not item_variant is Dictionary:
			continue
		var item: Dictionary = item_variant as Dictionary
		_add_paragraph(box, "%s：%.1f / %.0f" % [
			str(item.get("name", "评分项")),
			float(item.get("score", 0.0)),
			float(item.get("max", 0.0))
		], Color(0.92, 0.80, 0.46), 15)
		_add_paragraph(box, str(item.get("comment", "")), Color(0.78, 0.86, 0.92), 14)

	_add_section_label(box, "总体评价")
	_add_paragraph(box, str(score_result.get("overall_comment", "")), Color(0.86, 0.92, 0.96), 15)
	_add_section_label(box, "评分边界")
	_add_paragraph(box, str(score_result.get("scope_note", "")), Color(0.70, 0.78, 0.84), 14)
	return panel
func _maybe_start_score_guide() -> void:
	_guide_targets = {"score_panel": _score_panel}
	var scenario: Dictionary = GameState.get_current_scenario()
	var score_result: Dictionary = ScoreEngine.calculate_score(scenario, GameState.round_history, GameState.get_initial_state(), _final_state())
	if not bool(score_result.get("enabled", false)):
		return
	NarrativeManager.play_tutorial_once(
		self,
		"score_panel_intro_v1",
		NarrativeManager.score_steps(),
		_guide_targets
	)

func _build_long_term_panel() -> PanelContainer:
	var panel: PanelContainer = _new_panel()
	var box: VBoxContainer = _panel_content(panel, "长期视角提示")
	_add_paragraph(box, "本关为短期 IS-LM 情境，当前结果主要反映价格刚性条件下的短期需求管理效果。财政、货币政策的长期影响将在长期或综合关卡中单独讨论，不计入本关结果。", Color(0.82, 0.88, 0.92), 17)
	return panel


func _new_panel(minimum_size: Vector2 = Vector2.ZERO) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override("panel", _panel_style())
	return panel


func _panel_content(panel: PanelContainer, title: String) -> VBoxContainer:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	if title != "":
		_add_panel_title(box, title)
	return box


func _build_action_button(text: String, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(260, 54)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(callback)
	return button


func _on_return_main_menu_pressed() -> void:
	GameState.reset_for_new_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _final_state() -> Dictionary:
	if not GameState.round_history.is_empty():
		var last_entry: Dictionary = GameState.round_history[GameState.round_history.size() - 1]
		var result: Dictionary = _dictionary_from_variant(last_entry.get("result", {}))
		var after: Dictionary = _dictionary_from_variant(result.get("after", {}))
		if not after.is_empty():
			return after
	return GameState.get_current_state()


func _policy_names_text(policies: Array) -> String:
	var names: Array[String] = []
	for policy: Variant in policies:
		if policy is Dictionary:
			names.append(str((policy as Dictionary).get("name", "未知政策")))
	if names.is_empty():
		return "暂无"
	return "、".join(names)


func _settlement_label(result: Dictionary) -> String:
	var mode: String = str(result.get("settlement_mode", "demo"))
	var model_type: String = str(result.get("model_type", ""))
	var model_version: String = str(result.get("model_version", ""))
	if mode == "model":
		if model_type == "IS_LM" and model_version == "v1":
			return "IS-LM 模型结算 v1"
		if model_type == "IS_LM":
			return "IS-LM 模型结算占位"
		return "模型结算占位"
	return "基础教学演示结算"


func _brief_result_text(result: Dictionary) -> String:
	var before: Dictionary = _dictionary_from_variant(result.get("before", {}))
	var after: Dictionary = _dictionary_from_variant(result.get("after", {}))
	var parts: Array[String] = []
	_append_direction_part(parts, before, after, "Y", "Y")
	_append_direction_part(parts, before, after, "u", "u")
	_append_direction_part(parts, before, after, "Debt", "Debt")
	if parts.is_empty():
		return str(result.get("summary", "本轮已完成结算。"))
	return "，".join(parts)


func _append_direction_part(parts: Array[String], before: Dictionary, after: Dictionary, key: String, label: String) -> void:
	var before_number: Dictionary = _parse_state_number(_state_value(before, key))
	var after_number: Dictionary = _parse_state_number(_state_value(after, key))
	if not bool(before_number.get("ok", false)) or not bool(after_number.get("ok", false)):
		return
	var delta: float = float(after_number.get("value", 0.0)) - float(before_number.get("value", 0.0))
	if delta > 0.001:
		parts.append("%s 上升" % label)
	elif delta < -0.001:
		parts.append("%s 下降" % label)


func _unique_mechanisms() -> Array[String]:
	var result: Array[String] = []
	var seen: Dictionary = {}
	for entry: Dictionary in GameState.round_history:
		var round_result: Dictionary = _dictionary_from_variant(entry.get("result", {}))
		var mechanism: Array = _array_from_variant(round_result.get("mechanism", []))
		for item: Variant in mechanism:
			var text: String = str(item)
			if text == "" or seen.has(text):
				continue
			seen[text] = true
			result.append(text)
			if result.size() >= 4:
				return result
	return result


func _has_policy_combination() -> bool:
	for entry: Dictionary in GameState.round_history:
		var policies: Array = _array_from_variant(entry.get("selected_policies", []))
		if policies.size() >= 2:
			return true
		var round_result: Dictionary = _dictionary_from_variant(entry.get("result", {}))
		policies = _array_from_variant(round_result.get("executed_policies", []))
		if policies.size() >= 2:
			return true
	return false


func _add_panel_title(parent: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	parent.add_child(label)


func _add_section_label(parent: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.modulate = Color(0.72, 0.86, 1.0)
	label.add_theme_font_size_override("font_size", 17)
	parent.add_child(label)


func _add_paragraph(parent: VBoxContainer, text: String, color: Color, font_size: int) -> void:
	var label: RichTextLabel = RichTextLabel.new()
	label.text = text
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.modulate = color
	label.add_theme_font_size_override("normal_font_size", font_size)
	parent.add_child(label)


func _add_bullet(parent: VBoxContainer, text: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var bullet: Label = Label.new()
	bullet.text = "•"
	bullet.custom_minimum_size = Vector2(18, 0)
	bullet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bullet.modulate = Color(0.78, 0.86, 0.92)
	bullet.add_theme_font_size_override("font_size", 15)
	row.add_child(bullet)

	var label: RichTextLabel = RichTextLabel.new()
	label.text = text
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.modulate = Color(0.78, 0.86, 0.92)
	label.add_theme_font_size_override("normal_font_size", 15)
	row.add_child(label)


func _add_info_row(parent: VBoxContainer, name: String, value: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var name_label: Label = Label.new()
	name_label.text = name
	name_label.custom_minimum_size = Vector2(72, 28)
	name_label.modulate = Color(0.72, 0.82, 0.90)
	name_label.add_theme_font_size_override("font_size", 16)
	row.add_child(name_label)

	var value_label: RichTextLabel = RichTextLabel.new()
	value_label.text = value
	value_label.fit_content = true
	value_label.scroll_active = false
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.add_theme_font_size_override("normal_font_size", 16)
	row.add_child(value_label)


func _dictionary_from_variant(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


func _array_from_variant(value: Variant) -> Array:
	if value is Array:
		return value as Array
	return []


func _state_value(state: Dictionary, key: String) -> String:
	if state.has(key):
		return str(state.get(key))
	if key == "π" and state.has("蟺"):
		return str(state.get("蟺"))
	if key == "蟺" and state.has("π"):
		return str(state.get("π"))
	return "-"


func _parse_state_number(value: String) -> Dictionary:
	var cleaned: String = value.strip_edges().replace("%", "")
	if cleaned.is_valid_float():
		return {"ok": true, "value": cleaned.to_float()}
	return {"ok": false, "value": 0.0}


func _panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.10, 0.12, 0.96)
	style.border_color = Color(0.26, 0.48, 0.58, 0.88)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style
