extends HBoxContainer

var _ui_scale: float = 1.0
var _tags: Array = []


func _ready() -> void:
	add_theme_constant_override("separation", int(roundf(8.0 * _ui_scale)))


func set_tags(tags: Array) -> void:
	_tags = tags
	for child: Node in get_children():
		child.queue_free()
	for tag_value: Variant in tags:
		var label: Label = Label.new()
		label.text = str(tag_value)
		label.add_theme_font_size_override("font_size", int(roundf(16.0 * _ui_scale)))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(104, 32) * _ui_scale
		label.add_theme_stylebox_override("normal", _make_tag_style())
		add_child(label)


func set_ui_scale(value: float) -> void:
	_ui_scale = clampf(value, 0.8, 1.2)
	add_theme_constant_override("separation", int(roundf(8.0 * _ui_scale)))
	set_tags(_tags)


func _make_tag_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.22, 0.29, 0.95)
	style.border_color = Color(0.42, 0.68, 0.86, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	return style
