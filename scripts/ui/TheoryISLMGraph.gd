extends Control

const ClassicalTheme = preload("res://scripts/ui/ClassicalTheme.gd")
const SUPPORTED_SHOCKS: Array[String] = ["IS_LEFT", "IS_RIGHT", "LM_LEFT", "LM_RIGHT"]

var _scenario: Dictionary = {}
var _ui_scale: float = 1.0


func _init() -> void:
	custom_minimum_size = Vector2(0.0, 180.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


func setup(scenario: Dictionary, ui_scale: float) -> void:
	_scenario = scenario.duplicate(true)
	set_ui_scale(ui_scale)


func set_ui_scale(value: float) -> void:
	_ui_scale = maxf(value, 0.1)
	custom_minimum_size = Vector2(0.0, _dim(180.0))
	queue_redraw()


func _draw() -> void:
	var shock_type: String = str(_scenario.get("shock_type", ""))
	var model_type: String = str(_scenario.get("model_type", "IS_LM"))
	if model_type != "IS_LM" or not SUPPORTED_SHOCKS.has(shock_type):
		_draw_fallback()
		return

	var graph_rect: Rect2 = Rect2(
		Vector2(_dim(42.0), _dim(16.0)),
		Vector2(maxf(size.x - _dim(64.0), _dim(220.0)), maxf(size.y - _dim(58.0), _dim(104.0)))
	)
	_draw_background(graph_rect)
	_draw_axes(graph_rect)
	_draw_shock_graph(graph_rect, shock_type)


func _draw_background(graph_rect: Rect2) -> void:
	var bg_rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(bg_rect, Color(0.045, 0.040, 0.033, 0.98), true)
	draw_rect(bg_rect, ClassicalTheme.BORDER_COPPER, false, _line(1.0))
	draw_rect(graph_rect, Color(0.035, 0.045, 0.044, 0.88), true)


func _draw_axes(graph_rect: Rect2) -> void:
	var axis_color: Color = Color(0.72, 0.66, 0.50, 0.88)
	var left_bottom: Vector2 = Vector2(graph_rect.position.x, graph_rect.end.y)
	var left_top: Vector2 = graph_rect.position
	var right_bottom: Vector2 = graph_rect.end
	draw_line(left_bottom, left_top, axis_color, _line(1.2), true)
	draw_line(left_bottom, right_bottom, axis_color, _line(1.2), true)
	_draw_arrow_head(left_top, Vector2(0.0, -1.0), axis_color)
	_draw_arrow_head(right_bottom, Vector2(1.0, 0.0), axis_color)
	_draw_text("i", left_top + Vector2(_dim(6.0), _dim(14.0)), ClassicalTheme.TEXT_SOFT, 13)
	_draw_text("Y", right_bottom + Vector2(_dim(-14.0), _dim(-8.0)), ClassicalTheme.TEXT_SOFT, 13)


func _draw_shock_graph(graph_rect: Rect2, shock_type: String) -> void:
	var is_start: Vector2 = Vector2(graph_rect.position.x + graph_rect.size.x * 0.23, graph_rect.position.y + graph_rect.size.y * 0.20)
	var is_end: Vector2 = Vector2(graph_rect.position.x + graph_rect.size.x * 0.78, graph_rect.position.y + graph_rect.size.y * 0.78)
	var lm_start: Vector2 = Vector2(graph_rect.position.x + graph_rect.size.x * 0.25, graph_rect.position.y + graph_rect.size.y * 0.78)
	var lm_end: Vector2 = Vector2(graph_rect.position.x + graph_rect.size.x * 0.78, graph_rect.position.y + graph_rect.size.y * 0.22)

	var is_after_start: Vector2 = is_start
	var is_after_end: Vector2 = is_end
	var lm_after_start: Vector2 = lm_start
	var lm_after_end: Vector2 = lm_end
	var arrow_start: Vector2
	var arrow_end: Vector2
	var moved_curve: String = ""

	match shock_type:
		"IS_LEFT":
			var is_left_shift: Vector2 = Vector2(-graph_rect.size.x * 0.14, graph_rect.size.y * 0.14)
			is_after_start += is_left_shift
			is_after_end += is_left_shift
			arrow_start = _lerp_vec(is_start, is_end, 0.50)
			arrow_end = _lerp_vec(is_after_start, is_after_end, 0.50)
			moved_curve = "IS"
		"IS_RIGHT":
			var is_right_shift: Vector2 = Vector2(graph_rect.size.x * 0.14, -graph_rect.size.y * 0.14)
			is_after_start += is_right_shift
			is_after_end += is_right_shift
			arrow_start = _lerp_vec(is_start, is_end, 0.50)
			arrow_end = _lerp_vec(is_after_start, is_after_end, 0.50)
			moved_curve = "IS"
		"LM_LEFT":
			var lm_left_shift: Vector2 = Vector2(-graph_rect.size.x * 0.13, -graph_rect.size.y * 0.13)
			lm_after_start += lm_left_shift
			lm_after_end += lm_left_shift
			arrow_start = _lerp_vec(lm_start, lm_end, 0.52)
			arrow_end = _lerp_vec(lm_after_start, lm_after_end, 0.52)
			moved_curve = "LM"
		"LM_RIGHT":
			var lm_right_shift: Vector2 = Vector2(graph_rect.size.x * 0.13, graph_rect.size.y * 0.13)
			lm_after_start += lm_right_shift
			lm_after_end += lm_right_shift
			arrow_start = _lerp_vec(lm_start, lm_end, 0.52)
			arrow_end = _lerp_vec(lm_after_start, lm_after_end, 0.52)
			moved_curve = "LM"
		_:
			return

	var is_color: Color = ClassicalTheme.ACCENT_BLUE
	var lm_color: Color = ClassicalTheme.STABLE_GREEN
	var after_color: Color = ClassicalTheme.ACCENT_GOLD
	var shock_color: Color = ClassicalTheme.WARNING_RED

	_draw_curve(is_start, is_end, is_color, "IS")
	_draw_curve(lm_start, lm_end, lm_color, "LM")
	if moved_curve == "IS":
		_draw_curve(is_after_start, is_after_end, after_color, "IS'")
	else:
		_draw_curve(lm_after_start, lm_after_end, after_color, "LM'")

	var e0: Vector2 = _line_intersection(is_start, is_end, lm_start, lm_end)
	var e1: Vector2
	if moved_curve == "IS":
		e1 = _line_intersection(is_after_start, is_after_end, lm_start, lm_end)
	else:
		e1 = _line_intersection(is_start, is_end, lm_after_start, lm_after_end)
	_draw_equilibrium(e0, "E0", ClassicalTheme.TEXT_MAIN)
	_draw_equilibrium(e1, "E1", after_color)
	_draw_arrow(arrow_start, arrow_end, shock_color)
	_draw_text("冲击方向", arrow_end + Vector2(_dim(8.0), _dim(-8.0)), shock_color, 12)


func _draw_curve(start: Vector2, end: Vector2, color: Color, label: String) -> void:
	draw_line(start, end, color, _line(2.2), true)
	var label_pos: Vector2 = end + Vector2(_dim(4.0), _dim(-2.0))
	if label.begins_with("LM"):
		label_pos = end + Vector2(_dim(4.0), _dim(10.0))
	_draw_text(label, label_pos, color, 13)


func _draw_equilibrium(point: Vector2, label: String, color: Color) -> void:
	draw_circle(point, _dim(4.0), color)
	_draw_text(label, point + Vector2(_dim(6.0), _dim(-6.0)), color, 12)


func _draw_arrow(start: Vector2, end: Vector2, color: Color) -> void:
	draw_line(start, end, color, _line(2.0), true)
	var direction: Vector2 = (end - start).normalized()
	_draw_arrow_head(end, direction, color)


func _draw_arrow_head(tip: Vector2, direction: Vector2, color: Color) -> void:
	if direction.length() <= 0.001:
		return
	var side: Vector2 = Vector2(-direction.y, direction.x)
	var length: float = _dim(8.0)
	var width: float = _dim(5.0)
	var p1: Vector2 = tip
	var p2: Vector2 = tip - direction * length + side * width
	var p3: Vector2 = tip - direction * length - side * width
	draw_colored_polygon(PackedVector2Array([p1, p2, p3]), color)


func _draw_fallback() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.045, 0.040, 0.033, 0.98), true)
	draw_rect(Rect2(Vector2.ZERO, size), ClassicalTheme.BORDER_COPPER, false, _line(1.0))
	_draw_text("当前关卡暂未配置冲击示意图", Vector2(_dim(18.0), _dim(52.0)), ClassicalTheme.TEXT_SOFT, 15)


func _draw_text(text: String, position: Vector2, color: Color, base_size: int) -> void:
	var font: Font = get_theme_default_font()
	var font_size: int = maxi(10, int(roundf(float(base_size) * _ui_scale)))
	draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


func _line(value: float) -> float:
	return maxf(1.0, value * _ui_scale)


func _dim(value: float) -> float:
	return maxf(1.0, roundf(value * _ui_scale))


func _lerp_vec(from: Vector2, to: Vector2, weight: float) -> Vector2:
	return from.lerp(to, weight)


func _line_intersection(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> Vector2:
	var da: Vector2 = a2 - a1
	var db: Vector2 = b2 - b1
	var denominator: float = da.cross(db)
	if absf(denominator) <= 0.001:
		return (a1 + a2 + b1 + b2) * 0.25
	var t: float = (b1 - a1).cross(db) / denominator
	return a1 + da * t
