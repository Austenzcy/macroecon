extends Control

var _graph_data: Dictionary = {}
var _ui_scale: float = 1.0


func set_graph_data(graph_data: Dictionary) -> void:
	_graph_data = graph_data
	queue_redraw()


func set_ui_scale(value: float) -> void:
	_ui_scale = clampf(value, 0.8, 1.2)
	custom_minimum_size = Vector2(560, 360) * _ui_scale
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	if _graph_data.is_empty():
		_draw_empty_state()
		return

	var plot: Rect2 = _plot_rect()
	_draw_plot_background(plot)
	_draw_axes(plot)
	_draw_curve(plot, _graph_data.get("is_before", []), Color(0.45, 0.62, 0.78, 0.72), 2.0, "IS")
	_draw_curve(plot, _graph_data.get("lm_before", []), Color(0.54, 0.78, 0.62, 0.72), 2.0, "LM")
	_draw_curve(plot, _graph_data.get("is_after", []), Color(0.95, 0.74, 0.30, 1.0), 3.0, "IS'")
	_draw_curve(plot, _graph_data.get("lm_after", []), Color(0.42, 0.86, 1.0, 1.0), 3.0, "LM'")
	_draw_equilibrium(plot, _graph_data.get("equilibrium_before", {}), "E0", Color(0.86, 0.90, 0.95, 1.0))
	_draw_equilibrium(plot, _graph_data.get("equilibrium_after", {}), "E1", Color(1.0, 0.82, 0.34, 1.0))
	_draw_axis_labels(plot)


func _draw_empty_state() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.055, 0.065, 1.0), true)
	_draw_text(Vector2(24, size.y * 0.5), "当前没有可用的 IS-LM 图形数据。", 18, Color(0.82, 0.88, 0.92, 1.0))


func _plot_rect() -> Rect2:
	var left: float = 58.0 * _ui_scale
	var top: float = 24.0 * _ui_scale
	var right: float = 24.0 * _ui_scale
	var bottom: float = 48.0 * _ui_scale
	return Rect2(left, top, maxf(10.0, size.x - left - right), maxf(10.0, size.y - top - bottom))


func _draw_plot_background(plot: Rect2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.048, 0.058, 1.0), true)
	draw_rect(plot, Color(0.055, 0.075, 0.09, 1.0), true)
	draw_rect(plot, Color(0.24, 0.42, 0.52, 0.9), false, maxf(1.0, 1.5 * _ui_scale))
	for index in range(1, 4):
		var x: float = plot.position.x + plot.size.x * float(index) / 4.0
		var y: float = plot.position.y + plot.size.y * float(index) / 4.0
		draw_line(Vector2(x, plot.position.y), Vector2(x, plot.end.y), Color(0.18, 0.28, 0.34, 0.58), 1.0)
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), Color(0.18, 0.28, 0.34, 0.58), 1.0)


func _draw_axes(plot: Rect2) -> void:
	var axis_color: Color = Color(0.78, 0.88, 0.94, 0.96)
	draw_line(Vector2(plot.position.x, plot.end.y), Vector2(plot.end.x, plot.end.y), axis_color, maxf(1.0, 2.0 * _ui_scale))
	draw_line(Vector2(plot.position.x, plot.position.y), Vector2(plot.position.x, plot.end.y), axis_color, maxf(1.0, 2.0 * _ui_scale))
	_draw_text(Vector2(plot.end.x - 8.0 * _ui_scale, plot.end.y + 30.0 * _ui_scale), "Y", 16, axis_color)
	_draw_text(Vector2(plot.position.x - 32.0 * _ui_scale, plot.position.y + 10.0 * _ui_scale), "i", 16, axis_color)
	_draw_range_labels(plot)


func _draw_range_labels(plot: Rect2) -> void:
	_draw_text(Vector2(plot.position.x - 12.0 * _ui_scale, plot.end.y + 18.0 * _ui_scale), _fmt(_y_min(), 0), 12, Color(0.65, 0.74, 0.80, 1.0))
	_draw_text(Vector2(plot.end.x - 20.0 * _ui_scale, plot.end.y + 18.0 * _ui_scale), _fmt(_y_max(), 0), 12, Color(0.65, 0.74, 0.80, 1.0))
	_draw_text(Vector2(plot.position.x - 52.0 * _ui_scale, plot.end.y + 4.0 * _ui_scale), "%s%%" % _fmt(_i_min(), 1), 12, Color(0.65, 0.74, 0.80, 1.0))
	_draw_text(Vector2(plot.position.x - 52.0 * _ui_scale, plot.position.y + 8.0 * _ui_scale), "%s%%" % _fmt(_i_max(), 1), 12, Color(0.65, 0.74, 0.80, 1.0))


func _draw_curve(plot: Rect2, raw_points: Variant, color: Color, width: float, label: String) -> void:
	if not (raw_points is Array):
		return
	var polyline: PackedVector2Array = PackedVector2Array()
	for point_variant: Variant in raw_points:
		if point_variant is Dictionary:
			polyline.append(_to_screen(plot, point_variant as Dictionary))
	if polyline.size() < 2:
		return
	draw_polyline(polyline, color, maxf(1.0, width * _ui_scale), true)
	_draw_text(polyline[polyline.size() - 1] + Vector2(6.0 * _ui_scale, -4.0 * _ui_scale), label, 14, color)


func _draw_equilibrium(plot: Rect2, point_variant: Variant, label: String, color: Color) -> void:
	if not (point_variant is Dictionary):
		return
	var point: Vector2 = _to_screen(plot, point_variant as Dictionary)
	draw_circle(point, 5.5 * _ui_scale, color)
	draw_circle(point, 9.0 * _ui_scale, Color(color.r, color.g, color.b, 0.18))
	_draw_text(point + Vector2(10.0 * _ui_scale, -10.0 * _ui_scale), label, 15, color)


func _draw_axis_labels(plot: Rect2) -> void:
	var before: Variant = _graph_data.get("equilibrium_before", {})
	var after: Variant = _graph_data.get("equilibrium_after", {})
	if before is Dictionary:
		var before_point: Dictionary = before as Dictionary
		_draw_text(Vector2(plot.position.x + 10.0 * _ui_scale, plot.position.y + 18.0 * _ui_scale), "E0: Y=%s, i=%s%%" % [_fmt(float(before_point.get("Y", 0.0)), 1), _fmt(float(before_point.get("i", 0.0)), 2)], 13, Color(0.82, 0.88, 0.92, 1.0))
	if after is Dictionary:
		var after_point: Dictionary = after as Dictionary
		_draw_text(Vector2(plot.position.x + 10.0 * _ui_scale, plot.position.y + 38.0 * _ui_scale), "E1: Y=%s, i=%s%%" % [_fmt(float(after_point.get("Y", 0.0)), 1), _fmt(float(after_point.get("i", 0.0)), 2)], 13, Color(1.0, 0.82, 0.34, 1.0))


func _to_screen(plot: Rect2, point: Dictionary) -> Vector2:
	var y_value: float = float(point.get("Y", 0.0))
	var i_value: float = float(point.get("i", 0.0))
	var x_ratio: float = inverse_lerp(_y_min(), _y_max(), y_value)
	var y_ratio: float = inverse_lerp(_i_min(), _i_max(), i_value)
	return Vector2(
		plot.position.x + clampf(x_ratio, -0.05, 1.05) * plot.size.x,
		plot.end.y - clampf(y_ratio, -0.05, 1.05) * plot.size.y
	)


func _draw_text(pos: Vector2, text: String, base_size: int, color: Color) -> void:
	var font: Font = get_theme_default_font()
	var font_size: int = maxi(10, int(roundf(float(base_size) * _ui_scale)))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


func _y_min() -> float:
	return float(_graph_data.get("y_min", 80.0))


func _y_max() -> float:
	return float(_graph_data.get("y_max", 120.0))


func _i_min() -> float:
	return float(_graph_data.get("i_min", 2.0))


func _i_max() -> float:
	return float(_graph_data.get("i_max", 6.0))


func _fmt(value: float, decimals: int) -> String:
	match decimals:
		0:
			return "%.0f" % value
		1:
			return "%.1f" % value
		2:
			return "%.2f" % value
		_:
			return "%.2f" % value
