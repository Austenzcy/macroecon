extends Control

var _state: Dictionary = {}
var _ui_scale: float = 1.0


func setup(state: Dictionary, ui_scale: float = 1.0) -> void:
	_state = state.duplicate(true)
	_ui_scale = maxf(ui_scale, 0.5)
	custom_minimum_size = Vector2(180.0, 116.0) * _ui_scale
	queue_redraw()


func _draw() -> void:
	var values: Array[Dictionary] = [
		{"label": "C", "value": _number_for("C_value", "C"), "color": Color(0.25, 0.78, 0.92, 0.95)},
		{"label": "I", "value": _number_for("I_value", "I"), "color": Color(0.56, 0.64, 1.0, 0.95)},
		{"label": "G", "value": _number_for("G_value", "G"), "color": Color(1.0, 0.68, 0.30, 0.95)}
	]
	var total: float = 0.0
	for item: Dictionary in values:
		total += maxf(0.0, float(item.get("value", 0.0)))
	if total <= 0.001:
		_draw_empty()
		return

	var radius: float = minf(size.x * 0.23, size.y * 0.35)
	var center: Vector2 = Vector2(radius + 16.0 * _ui_scale, size.y * 0.53)
	var width: float = maxf(8.0 * _ui_scale, radius * 0.26)
	var start_angle: float = -PI * 0.5
	for item: Dictionary in values:
		var ratio: float = maxf(0.0, float(item.get("value", 0.0))) / total
		var end_angle: float = start_angle + TAU * ratio
		var segment_color: Color = item.get("color", Color.WHITE)
		_draw_arc_segment(center, radius, start_angle, end_angle, segment_color, width)
		start_angle = end_angle
	draw_arc(center, radius, 0.0, TAU, 96, Color(0.62, 0.86, 0.94, 0.18), maxf(1.0, 1.0 * _ui_scale), true)

	var font: Font = get_theme_default_font()
	if font == null:
		return
	draw_string(font, Vector2(center.x - radius * 0.55, center.y + 4.0 * _ui_scale), "C/I/G", HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(12 * _ui_scale), Color(0.82, 0.94, 0.98, 0.88))
	var x: float = center.x + radius + 18.0 * _ui_scale
	var y: float = maxf(20.0 * _ui_scale, size.y * 0.22)
	draw_string(font, Vector2(x, y), "总需求构成", HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(13 * _ui_scale), Color(0.86, 0.97, 1.0, 0.96))
	y += 23.0 * _ui_scale
	for item: Dictionary in values:
		var color: Color = item.get("color", Color.WHITE)
		draw_rect(Rect2(Vector2(x, y - 10.0 * _ui_scale), Vector2(9.0 * _ui_scale, 9.0 * _ui_scale)), color, true)
		var value: float = float(item.get("value", 0.0))
		var percent: float = value / total * 100.0
		var text: String = "%s  %.1f%%" % [str(item.get("label", "")), percent]
		draw_string(font, Vector2(x + 15.0 * _ui_scale, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(12 * _ui_scale), Color(0.74, 0.86, 0.90, 0.94))
		y += 19.0 * _ui_scale


func _number_for(primary_key: String, fallback_key: String) -> float:
	var raw: Variant = _state.get(primary_key, _state.get(fallback_key, 0.0))
	if raw is float or raw is int:
		return float(raw)
	var text: String = str(raw).replace("%", "").strip_edges()
	if text.is_valid_float():
		return text.to_float()
	return 0.0


func _draw_arc_segment(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color, width: float) -> void:
	if end_angle <= start_angle:
		return
	var point_count: int = maxi(10, int(ceilf((end_angle - start_angle) / TAU * 96.0)))
	draw_arc(center, radius, start_angle, end_angle, point_count, color, width, true)


func _draw_empty() -> void:
	var font: Font = get_theme_default_font()
	if font != null:
		draw_string(font, Vector2(8.0, size.y * 0.5), "暂无构成数据", HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(12 * _ui_scale), Color(0.74, 0.84, 0.88, 0.72))
