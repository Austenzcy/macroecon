extends Control

const ClassicalTheme = preload("res://scripts/ui/ClassicalTheme.gd")

var _display_min: float = 0.0
var _display_max: float = 1.0
var _reference_value: float = 0.5
var _current_value: float = 0.5
var _ui_scale: float = 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_text = "竖线：参考值；三角：当前值"


func setup(config: Dictionary, current_value: float, ui_scale: float) -> void:
	_display_min = float(config.get("display_min", 0.0))
	_display_max = float(config.get("display_max", 1.0))
	_reference_value = float(config.get("reference_value", 0.5))
	_current_value = current_value
	_ui_scale = clampf(ui_scale, 0.8, 1.2)
	custom_minimum_size = Vector2(96.0, 28.0) * _ui_scale
	queue_redraw()


func _draw() -> void:
	var bar_height: float = maxf(5.0, 6.0 * _ui_scale)
	var center_y: float = size.y * 0.58
	var left: float = 4.0 * _ui_scale
	var right: float = maxf(left + 12.0, size.x - 4.0 * _ui_scale)
	var bar_width: float = right - left
	var base_rect: Rect2 = Rect2(left, center_y - bar_height * 0.5, bar_width, bar_height)

	draw_rect(base_rect, Color(0.095, 0.073, 0.050, 1.0), true)
	draw_rect(base_rect, ClassicalTheme.BORDER_COPPER, false, maxf(1.0, 1.0 * _ui_scale))

	var ref_x: float = left + bar_width * _normalized(_reference_value)
	draw_line(
		Vector2(ref_x, center_y - 10.0 * _ui_scale),
		Vector2(ref_x, center_y + 10.0 * _ui_scale),
		ClassicalTheme.ACCENT_GOLD,
		maxf(1.0, 1.4 * _ui_scale)
	)

	var pointer_x: float = left + bar_width * _normalized(_current_value)
	var pointer_color: Color = Color(0.92, 0.80, 0.52, 1.0)
	var tri: PackedVector2Array = PackedVector2Array([
		Vector2(pointer_x, center_y - 11.0 * _ui_scale),
		Vector2(pointer_x - 4.5 * _ui_scale, center_y - 3.0 * _ui_scale),
		Vector2(pointer_x + 4.5 * _ui_scale, center_y - 3.0 * _ui_scale)
	])
	draw_colored_polygon(tri, pointer_color)
	draw_line(
		Vector2(pointer_x, center_y - 2.0 * _ui_scale),
		Vector2(pointer_x, center_y + 8.0 * _ui_scale),
		pointer_color,
		maxf(1.0, 1.3 * _ui_scale)
	)

	var font: Font = get_theme_default_font()
	if font != null and size.x >= 82.0 * _ui_scale:
		draw_string(
			font,
			Vector2(clampf(ref_x - 16.0 * _ui_scale, left, right - 32.0 * _ui_scale), 9.0 * _ui_scale),
			"参考值",
			HORIZONTAL_ALIGNMENT_LEFT,
			48.0 * _ui_scale,
			int(roundf(10.0 * _ui_scale)),
			ClassicalTheme.TEXT_SOFT
		)


func _normalized(value: float) -> float:
	var span: float = _display_max - _display_min
	if absf(span) < 0.001:
		return 0.5
	return clampf((value - _display_min) / span, 0.0, 1.0)
