extends PanelContainer

var _label: Label
var _region_name: String = "区域"
var _highlighted: bool = false
var _ui_scale: float = 1.0


func _ready() -> void:
	_build_ui()
	set_ui_scale(_ui_scale)
	_apply_style()


func set_region_name(region_name: String) -> void:
	_region_name = region_name
	if _label != null:
		_label.text = _region_name


func set_highlighted(value: bool) -> void:
	_highlighted = value
	_apply_style()


func set_ui_scale(value: float) -> void:
	_ui_scale = clampf(value, 0.8, 1.2)
	custom_minimum_size = Vector2(210, 132) * _ui_scale
	if _label != null:
		_label.add_theme_font_size_override("font_size", int(roundf(20.0 * _ui_scale)))


func _build_ui() -> void:
	_label = Label.new()
	_label.text = _region_name
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 20)
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_label)


func _apply_style() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.20, 0.22, 0.92)
	style.border_color = Color(0.30, 0.58, 0.62, 0.9)
	if _highlighted:
		style.bg_color = Color(0.18, 0.31, 0.26, 0.98)
		style.border_color = Color(0.70, 0.92, 0.62, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.1, 0.8, 0.9, 0.18)
	style.shadow_size = 10
	add_theme_stylebox_override("panel", style)
