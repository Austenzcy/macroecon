extends Control

const HudV2Theme = preload("res://scripts/ui/hud_v2/HudV2Theme.gd")

var _state: Dictionary = {}
var _ui_scale: float = 1.0


func setup(state: Dictionary, ui_scale: float = 1.0) -> void:
	_state = state.duplicate(true)
	_ui_scale = ui_scale
	custom_minimum_size = Vector2(210, 210) * _ui_scale
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var font: Font = get_theme_default_font()
	if font == null:
		return
	var values: Array[Dictionary] = [
		{"label": "C", "value": _number_for("C_value", "C"), "color": Color(0.31, 0.76, 0.92, 0.96)},
		{"label": "I", "value": _number_for("I_value", "I"), "color": Color(0.62, 0.64, 1.0, 0.96)},
		{"label": "G", "value": _number_for("G_value", "G"), "color": HudV2Theme.ACCENT_RESOURCE}
	]
	var total := 0.0
	for item in values:
		total += maxf(0.0, float(item.get("value", 0.0)))
	if total <= 0.001:
		draw_string(font, Vector2(12, size.y * 0.5), "暂无构成数据", HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, HudV2Theme.font(12, _ui_scale), HudV2Theme.TEXT_MUTED)
		return

	var radius := minf(size.x * 0.23, size.y * 0.25)
	var center := Vector2(size.x * 0.32, size.y * 0.50)
	var width := maxf(9.0, radius * 0.28)
	var start := -PI * 0.5
	for item in values:
		var ratio := maxf(0.0, float(item.get("value", 0.0))) / total
		var end := start + TAU * ratio
		_draw_arc_segment(center, radius, start, end, item.get("color", Color.WHITE), width)
		start = end
	draw_arc(center, radius, 0, TAU, 96, Color(1, 1, 1, 0.14), 1.0, true)
	draw_string(font, center + Vector2(-radius * 0.48, 4), "C/I/G", HORIZONTAL_ALIGNMENT_CENTER, radius * 0.96, HudV2Theme.font(11, _ui_scale), HudV2Theme.TEXT_TITLE)

	var x := size.x * 0.58
	var y := size.y * 0.30
	for item in values:
		var color: Color = item.get("color", Color.WHITE)
		var percent := float(item.get("value", 0.0)) / total * 100.0
		draw_rect(Rect2(Vector2(x, y - 9), Vector2(8, 8)), color, true)
		draw_string(font, Vector2(x + 14, y), "%s  %.1f%%" % [str(item.get("label", "")), percent], HORIZONTAL_ALIGNMENT_LEFT, size.x - x - 16, HudV2Theme.font(12, _ui_scale), HudV2Theme.TEXT_BODY)
		y += 21.0


func _number_for(primary_key: String, fallback_key: String) -> float:
	var raw: Variant = _state.get(primary_key, _state.get(fallback_key, 0.0))
	if raw is float or raw is int:
		return float(raw)
	var text := str(raw).replace("%", "").strip_edges()
	if text.is_valid_float():
		return text.to_float()
	return 0.0


func _draw_arc_segment(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color, width: float) -> void:
	if end_angle <= start_angle:
		return
	var point_count := maxi(10, int(ceilf((end_angle - start_angle) / TAU * 96.0)))
	draw_arc(center, radius, start_angle, end_angle, point_count, color, width, true)
