extends Control

const CONTENT_WIDTH: float = 980.0


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
	outer_margin.add_theme_constant_override("margin_left", 56)
	outer_margin.add_theme_constant_override("margin_top", 48)
	outer_margin.add_theme_constant_override("margin_right", 56)
	outer_margin.add_theme_constant_override("margin_bottom", 128)
	scroll.add_child(outer_margin)

	var page: VBoxContainer = VBoxContainer.new()
	page.custom_minimum_size = Vector2(CONTENT_WIDTH, 0)
	page.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.add_theme_constant_override("separation", 18)
	outer_margin.add_child(page)

	var result: Dictionary = GameState.last_result
	if result.is_empty():
		_add_title(page, "本轮政策总结")
		_add_panel_text(page, "还没有可展示的本轮结算结果。请先在政策桌面确认政策。")
		page.add_child(_build_action_button("返回主菜单", _on_return_main_menu_pressed))
		return

	_add_title(page, "本轮政策总结")
	_add_subtitle(page, "第 %d 回合结果" % GameState.current_round)

	page.add_child(_build_policies_panel(result))
	page.add_child(_build_variables_panel(result))
	page.add_child(_build_mechanism_panel(result))

	if GameState.is_final_round():
		page.add_child(_build_action_button("测试结束，返回主菜单", _on_return_main_menu_pressed))
	else:
		page.add_child(_build_action_button("进入下一回合", _on_next_round_pressed))


func _build_policies_panel(result: Dictionary) -> PanelContainer:
	var box: VBoxContainer = _panel_box("已执行政策")
	var policies: Array = _array_from_variant(result.get("executed_policies", []))
	if policies.is_empty():
		_add_body_label(box, "暂无政策记录。", Color(0.82, 0.88, 0.92), 17)
	else:
		for policy: Variant in policies:
			if policy is Dictionary:
				_add_body_label(box, "• %s" % str((policy as Dictionary).get("name", "未知政策")), Color(0.96, 0.98, 1.0), 18)
	return box.get_parent().get_parent() as PanelContainer


func _build_variables_panel(result: Dictionary) -> PanelContainer:
	var box: VBoxContainer = _panel_box("宏观变量变化")
	var before: Dictionary = _dictionary_from_variant(result.get("before", {}))
	var after: Dictionary = _dictionary_from_variant(result.get("after", {}))
	for key: String in ["Y", "u", "π", "i", "Debt"]:
		var old_value: String = _state_value(before, key)
		var new_value: String = _state_value(after, key)
		if new_value == "-":
			new_value = old_value
		_add_info_row(box, key, "%s → %s" % [old_value, new_value])
	return box.get_parent().get_parent() as PanelContainer


func _build_mechanism_panel(result: Dictionary) -> PanelContainer:
	var box: VBoxContainer = _panel_box("机制总结")
	var summary: String = str(result.get("summary", "本轮政策已经完成结算。"))
	_add_body_label(box, summary, Color(0.86, 0.92, 0.96), 17)

	var mechanism: Array = _array_from_variant(result.get("mechanism", []))
	if not mechanism.is_empty():
		_add_section_label(box, "机制路径")
		for item: Variant in mechanism:
			_add_body_label(box, "• %s" % str(item), Color(0.78, 0.86, 0.92), 16)
	return box.get_parent().get_parent() as PanelContainer


func _panel_box(title: String) -> VBoxContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style())

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


func _on_next_round_pressed() -> void:
	GameState.advance_round()
	get_tree().change_scene_to_file("res://scenes/PolicyDesk.tscn")


func _on_return_main_menu_pressed() -> void:
	GameState.reset_for_new_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _add_title(parent: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 34)
	parent.add_child(label)


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
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = color
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)


func _add_panel_text(parent: VBoxContainer, text: String) -> void:
	var box: VBoxContainer = _panel_box("提示")
	_add_body_label(box, text, Color(0.86, 0.92, 0.96), 18)
	parent.add_child(box.get_parent().get_parent())


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

	var value_label: Label = Label.new()
	value_label.text = value
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.add_theme_font_size_override("font_size", 18)
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


func _panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.10, 0.12, 0.96)
	style.border_color = Color(0.26, 0.48, 0.58, 0.88)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style
