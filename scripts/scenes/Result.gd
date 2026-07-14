extends Control

const CONTENT_WIDTH: float = 980.0


func _ready() -> void:
	_build_ui()
	call_deferred("_maybe_play_level_end_dialogue")


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
	outer_margin.add_theme_constant_override("margin_left", 56)
	outer_margin.add_theme_constant_override("margin_top", 42)
	outer_margin.add_theme_constant_override("margin_right", 56)
	outer_margin.add_theme_constant_override("margin_bottom", 128)
	scroll.add_child(outer_margin)

	var page: VBoxContainer = VBoxContainer.new()
	page.custom_minimum_size = Vector2(CONTENT_WIDTH, 0)
	page.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.add_theme_constant_override("separation", 18)
	outer_margin.add_child(page)

	page.add_child(_build_header())

	var result: Dictionary = GameState.last_result
	if result.is_empty():
		page.add_child(_build_text_panel("提示", "还没有可展示的本轮结算结果。请先在政策桌面确认政策。"))
		page.add_child(_build_action_button("返回主菜单", _on_return_main_menu_pressed))
		return

	_add_subtitle(page, "第 %d 回合结果" % GameState.current_round)
	page.add_child(_build_policies_panel(result))
	page.add_child(_build_variables_panel(result))
	page.add_child(_build_mechanism_panel(result))

	if GameState.is_final_round():
		page.add_child(_build_action_button("查看最终总结", _on_final_summary_pressed))
	else:
		page.add_child(_build_action_button("进入下一回合", _on_next_round_pressed))


func _build_header() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var title_box: VBoxContainer = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_box)

	var title: Label = Label.new()
	title.text = "本轮政策总结"
	title.add_theme_font_size_override("font_size", 34)
	title_box.add_child(title)

	var scenario: Dictionary = GameState.get_current_scenario()
	var scenario_title: Label = Label.new()
	scenario_title.text = str(scenario.get("title", "当前测试关卡"))
	scenario_title.modulate = Color(0.92, 0.80, 0.46)
	scenario_title.add_theme_font_size_override("font_size", 18)
	title_box.add_child(scenario_title)

	var close_button: Button = Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(92, 40)
	close_button.add_theme_font_size_override("font_size", 17)
	close_button.pressed.connect(_on_close_pressed)
	row.add_child(close_button)

	return row


func _build_policies_panel(result: Dictionary) -> PanelContainer:
	var panel: PanelContainer = _new_panel()
	var box: VBoxContainer = _panel_content(panel, "已执行政策")
	var policies: Array = _array_from_variant(result.get("executed_policies", []))
	if policies.is_empty():
		_add_body_label(box, "暂无政策记录。", Color(0.82, 0.88, 0.92), 17)
	else:
		for policy: Variant in policies:
			if policy is Dictionary:
				_add_bullet(box, str((policy as Dictionary).get("name", "未知政策")), Color(0.96, 0.98, 1.0), 18)
	return panel


func _build_variables_panel(result: Dictionary) -> PanelContainer:
	var panel: PanelContainer = _new_panel()
	var box: VBoxContainer = _panel_content(panel, "宏观变量变化")
	var before: Dictionary = _dictionary_from_variant(result.get("before", {}))
	var after: Dictionary = _dictionary_from_variant(result.get("after", {}))
	for key: String in ["Y", "u", "π", "i", "Debt"]:
		var old_value: String = _state_value(before, key)
		var new_value: String = _state_value(after, key)
		if new_value == "-":
			new_value = old_value
		_add_info_row(box, key, "%s → %s" % [old_value, new_value])
	return panel


func _build_mechanism_panel(result: Dictionary) -> PanelContainer:
	var panel: PanelContainer = _new_panel()
	var box: VBoxContainer = _panel_content(panel, "机制总结")
	var summary: String = str(result.get("summary", "本轮政策已经完成结算。"))
	_add_body_label(box, summary, Color(0.86, 0.92, 0.96), 17)

	var mechanism: Array = _array_from_variant(result.get("mechanism", []))
	if not mechanism.is_empty():
		_add_section_label(box, "机制路径")
		for item: Variant in mechanism:
			_add_bullet(box, str(item), Color(0.78, 0.86, 0.92), 16)
	return panel


func _build_text_panel(title: String, text: String) -> PanelContainer:
	var panel: PanelContainer = _new_panel()
	var box: VBoxContainer = _panel_content(panel, title)
	_add_body_label(box, text, Color(0.86, 0.92, 0.96), 18)
	return panel


func _new_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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


func _on_close_pressed() -> void:
	GameState.mark_return_to_confirmed_policy_desk()
	get_tree().change_scene_to_file("res://scenes/PolicyDesk.tscn")


func _on_next_round_pressed() -> void:
	GameState.advance_round()
	get_tree().change_scene_to_file("res://scenes/PolicyDesk.tscn")


func _on_final_summary_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/FinalSummary.tscn")


func _on_return_main_menu_pressed() -> void:
	GameState.reset_for_new_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _maybe_play_level_end_dialogue() -> void:
	if not has_node("/root/NarrativeManager"):
		return
	if GameState.last_result.is_empty():
		return
	var steps: Array = NarrativeManager.level_end_steps(GameState.current_scenario_id)
	if steps.is_empty():
		return
	NarrativeManager.play_tutorial_once(
		self,
		"level_end_%s_round_%d_v1" % [GameState.current_scenario_id, GameState.current_round],
		steps
	)


func _add_subtitle(parent: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate = Color(0.92, 0.80, 0.46)
	label.add_theme_font_size_override("font_size", 20)
	parent.add_child(label)


func _add_panel_title(parent: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	parent.add_child(label)


func _add_section_label(parent: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.modulate = Color(0.72, 0.86, 1.0)
	label.add_theme_font_size_override("font_size", 16)
	parent.add_child(label)


func _add_body_label(parent: VBoxContainer, text: String, color: Color, font_size: int) -> void:
	var label: RichTextLabel = RichTextLabel.new()
	label.text = text
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.modulate = color
	label.add_theme_font_size_override("normal_font_size", font_size)
	parent.add_child(label)


func _add_bullet(parent: VBoxContainer, text: String, color: Color, font_size: int) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var bullet: Label = Label.new()
	bullet.text = "•"
	bullet.custom_minimum_size = Vector2(18, 0)
	bullet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bullet.modulate = color
	bullet.add_theme_font_size_override("font_size", font_size)
	row.add_child(bullet)

	var label: RichTextLabel = RichTextLabel.new()
	label.text = text
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.modulate = color
	label.add_theme_font_size_override("normal_font_size", font_size)
	row.add_child(label)


func _add_info_row(parent: VBoxContainer, name: String, value: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var name_label: Label = Label.new()
	name_label.text = name
	name_label.custom_minimum_size = Vector2(90, 28)
	name_label.modulate = Color(0.72, 0.82, 0.90)
	name_label.add_theme_font_size_override("font_size", 17)
	row.add_child(name_label)

	var value_label: RichTextLabel = RichTextLabel.new()
	value_label.text = value
	value_label.fit_content = true
	value_label.scroll_active = false
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.add_theme_font_size_override("normal_font_size", 18)
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


func _panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.10, 0.12, 0.96)
	style.border_color = Color(0.26, 0.48, 0.58, 0.88)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style
