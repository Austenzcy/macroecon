extends PanelContainer

var _title_label: Label
var _lines_box: VBoxContainer
var _region_name: String = "区域"
var _lines: Array[Dictionary] = []
var _brightness: float = 0.0
var _ui_scale: float = 1.0


func _ready() -> void:
	_build_ui()
	set_ui_scale(_ui_scale)
	_apply_style()
	_refresh_text()


func set_region_name(region_name: String) -> void:
	_region_name = region_name
	_refresh_text()


func set_highlighted(value: bool) -> void:
	_brightness = 0.55 if value else 0.0
	_apply_style()


func set_region_data(region_name: String, lines: Array, brightness: float) -> void:
	_region_name = region_name
	_lines.clear()
	for item: Variant in lines:
		if item is Dictionary:
			_lines.append((item as Dictionary).duplicate(true))
	_brightness = clampf(brightness, -1.0, 1.0)
	_refresh_text()
	_apply_style()


func set_ui_scale(value: float) -> void:
	_ui_scale = clampf(value, 0.8, 1.2)
	custom_minimum_size = Vector2(210, 132) * _ui_scale
	if _title_label != null:
		_title_label.add_theme_font_size_override("font_size", int(roundf(19.0 * _ui_scale)))
	if _lines_box != null:
		_lines_box.add_theme_constant_override("separation", int(roundf(4.0 * _ui_scale)))
		for child: Node in _lines_box.get_children():
			if child is Label:
				(child as Label).add_theme_font_size_override("font_size", int(roundf(15.0 * _ui_scale)))


func _build_ui() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 19)
	box.add_child(_title_label)

	_lines_box = VBoxContainer.new()
	_lines_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_lines_box.add_theme_constant_override("separation", 4)
	box.add_child(_lines_box)


func _refresh_text() -> void:
	if _title_label != null:
		_title_label.text = _region_name
	if _lines_box == null:
		return
	for child: Node in _lines_box.get_children():
		child.queue_free()
	for line: Dictionary in _lines:
		var label: Label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = "%s %s" % [str(line.get("label", "")), str(line.get("arrow", "→"))]
		label.modulate = _line_color(str(line.get("arrow", "→")))
		label.add_theme_font_size_override("font_size", int(roundf(15.0 * _ui_scale)))
		_lines_box.add_child(label)


func _line_color(arrow: String) -> Color:
	if arrow == "↑":
		return Color(0.68, 0.95, 0.72, 1.0)
	if arrow == "↓":
		return Color(0.95, 0.62, 0.58, 1.0)
	return Color(0.78, 0.88, 0.94, 1.0)


func _apply_style() -> void:
	var normalized: float = (_brightness + 1.0) * 0.5
	var base: Color = Color(0.07, 0.13, 0.16, 0.95)
	var dim: Color = Color(0.045, 0.060, 0.070, 0.96)
	var bright: Color = Color(0.15, 0.28, 0.24, 0.98)
	var fill: Color = dim.lerp(base, clampf(normalized * 1.2, 0.0, 1.0))
	if _brightness > 0.05:
		fill = base.lerp(bright, clampf(_brightness, 0.0, 1.0))

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color(0.28, 0.52, 0.62, 0.88).lerp(Color(0.70, 0.92, 0.70, 1.0), maxf(_brightness, 0.0))
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.1, 0.8, 0.9, 0.10 + maxf(_brightness, 0.0) * 0.16)
	style.shadow_size = 10
	add_theme_stylebox_override("panel", style)
