extends Control

const HudV2Theme = preload("res://scripts/ui/hud_v2/HudV2Theme.gd")

var icon_type: String = "policy"
var accent: Color = HudV2Theme.ACCENT_SYSTEM
var line_width: float = 2.0


func setup(type: String, color: Color = HudV2Theme.ACCENT_SYSTEM, width: float = 2.0) -> void:
	icon_type = type
	accent = color
	line_width = width
	custom_minimum_size = Vector2(28, 28)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	if s <= 2.0:
		return
	var o: Vector2 = (size - Vector2(s, s)) * 0.5
	match icon_type:
		"wisdom":
			_draw_wisdom(o, s)
		"policy_point":
			_draw_policy_point(o, s)
		"hint":
			_draw_hint(o, s)
		"review":
			_draw_review(o, s)
		"confirm":
			_draw_confirm(o, s)
		"government":
			_draw_government(o, s)
		"monetary":
			_draw_monetary(o, s)
		"tax":
			_draw_tax(o, s)
		"collapse_left":
			_draw_chevron(o, s, -1.0)
		"collapse_right":
			_draw_chevron(o, s, 1.0)
		_:
			_draw_policy_point(o, s)


func _p(o: Vector2, s: float, x: float, y: float) -> Vector2:
	return o + Vector2(x * s, y * s)


func _draw_wisdom(o: Vector2, s: float) -> void:
	var c := _p(o, s, 0.50, 0.45)
	draw_arc(c, s * 0.18, 0, TAU, 32, accent, line_width, true)
	for i in range(8):
		var a := TAU * float(i) / 8.0
		draw_line(c + Vector2(cos(a), sin(a)) * s * 0.27, c + Vector2(cos(a), sin(a)) * s * 0.36, accent, line_width * 0.75, true)
	draw_line(_p(o, s, 0.42, 0.68), _p(o, s, 0.58, 0.68), accent, line_width, true)
	draw_line(_p(o, s, 0.45, 0.78), _p(o, s, 0.55, 0.78), accent, line_width, true)


func _draw_policy_point(o: Vector2, s: float) -> void:
	var pts := PackedVector2Array()
	for i in range(6):
		var a := PI / 6.0 + TAU * float(i) / 6.0
		pts.append(_p(o, s, 0.5, 0.5) + Vector2(cos(a), sin(a)) * s * 0.32)
	draw_colored_polygon(pts, Color(accent.r, accent.g, accent.b, 0.13))
	var outline := PackedVector2Array(pts)
	outline.append(pts[0])
	draw_polyline(outline, accent, line_width, true)
	draw_line(_p(o, s, 0.50, 0.28), _p(o, s, 0.50, 0.72), accent, line_width * 0.85, true)
	draw_line(_p(o, s, 0.36, 0.50), _p(o, s, 0.64, 0.50), accent, line_width * 0.85, true)


func _draw_hint(o: Vector2, s: float) -> void:
	draw_arc(_p(o, s, 0.50, 0.48), s * 0.30, -PI * 0.85, PI * 0.55, 30, accent, line_width, true)
	draw_line(_p(o, s, 0.43, 0.78), _p(o, s, 0.57, 0.78), accent, line_width, true)
	draw_circle(_p(o, s, 0.50, 0.62), s * 0.035, accent)


func _draw_review(o: Vector2, s: float) -> void:
	var c := _p(o, s, 0.50, 0.52)
	draw_arc(c, s * 0.30, -PI * 0.18, TAU * 0.78, 36, accent, line_width, true)
	draw_line(c, _p(o, s, 0.50, 0.34), accent, line_width, true)
	draw_line(c, _p(o, s, 0.66, 0.56), accent, line_width, true)
	draw_colored_polygon(PackedVector2Array([_p(o, s, 0.24, 0.29), _p(o, s, 0.34, 0.23), _p(o, s, 0.35, 0.36)]), accent)


func _draw_confirm(o: Vector2, s: float) -> void:
	draw_polyline(PackedVector2Array([_p(o, s, 0.24, 0.52), _p(o, s, 0.42, 0.70), _p(o, s, 0.76, 0.30)]), accent, line_width * 1.35, true)


func _draw_government(o: Vector2, s: float) -> void:
	draw_polyline(PackedVector2Array([_p(o, s, 0.20, 0.40), _p(o, s, 0.50, 0.20), _p(o, s, 0.80, 0.40), _p(o, s, 0.20, 0.40)]), accent, line_width, true)
	draw_line(_p(o, s, 0.24, 0.78), _p(o, s, 0.76, 0.78), accent, line_width, true)
	for x in [0.32, 0.50, 0.68]:
		draw_line(_p(o, s, x, 0.44), _p(o, s, x, 0.74), accent, line_width * 0.8, true)


func _draw_monetary(o: Vector2, s: float) -> void:
	var c := _p(o, s, 0.45, 0.48)
	draw_arc(c, s * 0.26, 0, TAU, 36, accent, line_width, true)
	draw_arc(c, s * 0.38, -PI * 0.28, PI * 0.28, 18, Color(accent.r, accent.g, accent.b, 0.58), line_width * 0.7, true)
	draw_line(_p(o, s, 0.66, 0.26), _p(o, s, 0.78, 0.26), accent, line_width, true)
	draw_line(_p(o, s, 0.78, 0.26), _p(o, s, 0.78, 0.38), accent, line_width, true)


func _draw_tax(o: Vector2, s: float) -> void:
	draw_rect(Rect2(_p(o, s, 0.26, 0.20), Vector2(s * 0.42, s * 0.54)), Color(accent.r, accent.g, accent.b, 0.08), true)
	draw_rect(Rect2(_p(o, s, 0.26, 0.20), Vector2(s * 0.42, s * 0.54)), accent, false, line_width)
	draw_line(_p(o, s, 0.36, 0.38), _p(o, s, 0.58, 0.38), accent, line_width * 0.8, true)
	draw_polyline(PackedVector2Array([_p(o, s, 0.78, 0.35), _p(o, s, 0.78, 0.68), _p(o, s, 0.68, 0.58), _p(o, s, 0.78, 0.68), _p(o, s, 0.88, 0.58)]), accent, line_width, true)


func _draw_chevron(o: Vector2, s: float, dir: float) -> void:
	var a := _p(o, s, 0.60 if dir < 0.0 else 0.40, 0.25)
	var b := _p(o, s, 0.40 if dir < 0.0 else 0.60, 0.50)
	var c := _p(o, s, 0.60 if dir < 0.0 else 0.40, 0.75)
	draw_polyline(PackedVector2Array([a, b, c]), accent, line_width * 1.2, true)
