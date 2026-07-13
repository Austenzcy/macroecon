extends PanelContainer

var _name_label: Label
var _line_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(0, 120)
	add_theme_stylebox_override("panel", _make_panel_style())
	_build_ui()


func set_advisor(advisor_name: String, line: String) -> void:
	if _name_label == null:
		return
	_name_label.text = advisor_name
	_line_label.text = line


func _build_ui() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	var avatar: ColorRect = ColorRect.new()
	avatar.custom_minimum_size = Vector2(70, 70)
	avatar.color = Color(0.22, 0.38, 0.50, 1.0)
	row.add_child(avatar)

	var text_box: VBoxContainer = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 8)
	row.add_child(text_box)

	_name_label = Label.new()
	_name_label.text = "顾问"
	_name_label.add_theme_font_size_override("font_size", 20)
	text_box.add_child(_name_label)

	_line_label = Label.new()
	_line_label.text = ""
	_line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line_label.modulate = Color(0.88, 0.92, 0.96)
	text_box.add_child(_line_label)


func _make_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.13, 0.17, 0.98)
	style.border_color = Color(0.30, 0.48, 0.62, 0.88)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style
