extends PanelContainer

var _box: VBoxContainer


func _ready() -> void:
	custom_minimum_size = Vector2(220, 300)
	add_theme_stylebox_override("panel", _make_panel_style())
	_build_ui()


func set_variables(variables: Dictionary) -> void:
	if _box == null:
		return
	for child: Node in _box.get_children():
		child.queue_free()

	var title: Label = Label.new()
	title.text = "经济指标"
	title.add_theme_font_size_override("font_size", 24)
	_box.add_child(title)

	for key: Variant in variables.keys():
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		_box.add_child(row)

		var name_label: Label = Label.new()
		name_label.text = str(key)
		name_label.custom_minimum_size = Vector2(70, 28)
		name_label.modulate = Color(0.72, 0.82, 0.90)
		row.add_child(name_label)

		var value_label: Label = Label.new()
		value_label.text = str(variables[key])
		value_label.add_theme_font_size_override("font_size", 20)
		row.add_child(value_label)


func _build_ui() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 14)
	margin.add_child(_box)


func _make_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.16, 0.96)
	style.border_color = Color(0.24, 0.42, 0.56, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style
