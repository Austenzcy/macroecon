extends Control

const CONTENT_WIDTH: float = 1100.0


func _ready() -> void:
	_build_ui()


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
	grid.add_child(_build_scoring_placeholder_panel())

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
	var panel: PanelContainer = _new_panel(Vector2(0, 360))
	var box: VBoxContainer = _panel_content(panel, "回合历史")
	if GameState.round_history.is_empty():
		_add_body_label(box, "暂无回合历史。", Color(0.82, 0.88, 0.92), 16)
		return panel

	for entry: Dictionary in GameState.round_history:
		var round_number: int = int(entry.get("round", 0))
		var result: Dictionary = _dictionary_from_variant(entry.get("result", {}))
		_add_section_label(box, "第 %d 回合" % round_number)
		_add_body_label(box, "已执行政策：%s" % _policy_names_text(_array_from_variant(result.get("executed_policies", []))), Color(0.96, 0.98, 1.0), 16)
		_add_body_label(box, "结算方式：%s" % _settlement_label(result), Color(0.92, 0.80, 0.46), 15)
		_add_body_label(box, "简要结果：%s" % _brief_result_text(result), Color(0.78, 0.86, 0.92), 15)

	return panel


func _build_variable_path_panel() -> PanelContainer:
	var panel: PanelContainer = _new_panel(Vector2(0, 360))
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
	_add_body_label(box, "当前阶段使用文字轨迹，变量走势图后续再加入。", Color(0.70, 0.78, 0.84), 14)
	return panel


func _build_learning_summary_panel() -> PanelContainer:
	var panel: PanelContainer = _new_panel(Vector2(0, 360))
	var box: VBoxContainer = _panel_content(panel, "学习总结")
	_add_body_label(box, "本关核心机制：", Color(0.86, 0.92, 0.96), 16)
	_add_body_label(box, "• 消费信心下降导致 C 下降，总需求走弱，IS 曲线左移。", Color(0.78, 0.86, 0.92), 15)

	var mechanisms: Array[String] = _unique_mechanisms()
	for item: String in mechanisms:
		_add_body_label(box, "• %s" % item, Color(0.78, 0.86, 0.92), 15)
	_add_body_label(box, "• 组合政策应先合并对模型参数的影响，再重新求解均衡，而不是简单相加。", Color(0.78, 0.86, 0.92), 15)
	return panel


func _build_scoring_placeholder_panel() -> PanelContainer:
	var panel: PanelContainer = _new_panel(Vector2(0, 360))
	var box: VBoxContainer = _panel_content(panel, "评分系统")
	_add_body_label(box, "评分系统将在下一阶段实现。", Color(0.96, 0.98, 1.0), 17)
	_add_body_label(box, "后续将根据关卡标签评价当前模型视野下的目标，例如产出缺口、失业率、通胀压力、债务压力和政策效率。", Color(0.78, 0.86, 0.92), 15)
	_add_body_label(box, "当前不计算分数，不做胜负判定，也不引入评分公式。", Color(0.92, 0.80, 0.46), 15)
	return panel


func _build_long_term_panel() -> PanelContainer:
	var panel: PanelContainer = _new_panel()
	var box: VBoxContainer = _panel_content(panel, "长期视角提示")
	_add_body_label(box, "本关为短期 IS-LM 情境，当前结果主要反映价格刚性条件下的短期需求管理效果。财政、货币政策的长期影响将在长期或综合关卡中单独讨论，不计入本关结果。", Color(0.82, 0.88, 0.92), 17)
	return panel


func _new_panel(minimum_size: Vector2 = Vector2.ZERO) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override("panel", _panel_style())
	return panel


func _panel_content(panel: PanelContainer, title: String) -> VBoxContainer:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
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


func _add_body_label(parent: VBoxContainer, text: String, color: Color, font_size: int) -> void:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = color
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)


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

	var value_label: Label = Label.new()
	value_label.text = value
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.add_theme_font_size_override("font_size", 16)
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
