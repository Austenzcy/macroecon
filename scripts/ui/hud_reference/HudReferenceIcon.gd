extends Control

const HudReferenceTheme = preload("res://scripts/ui/hud_reference/HudReferenceTheme.gd")

var icon_type: String = "policy"
var accent: Color = HudReferenceTheme.CYAN
var muted: Color = HudReferenceTheme.MUTED


func setup(next_type: String, next_accent: Color = HudReferenceTheme.CYAN) -> void:
	icon_type = next_type
	accent = next_accent
	queue_redraw()


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var c: Vector2 = rect.get_center()
	var r: float = minf(size.x, size.y) * 0.38
	match icon_type:
		"wisdom":
			_draw_wisdom(c, r)
		"policy_point":
			_draw_policy_point(c, r)
		"hint":
			_draw_hint(c, r)
		"review":
			_draw_review(c, r)
		"government":
			_draw_government(c, r)
		"monetary":
			_draw_monetary(c, r)
		"tax":
			_draw_tax(c, r)
		"confirm":
			_draw_confirm(c, r)
		"collapse_left":
			_draw_chevron(c, r, -1.0)
		"collapse_right":
			_draw_chevron(c, r, 1.0)
		_:
			_draw_policy_point(c, r)


func _line(a: Vector2, b: Vector2, color: Color = accent, width: float = 1.6) -> void:
	draw_line(a, b, color, width, true)


func _draw_wisdom(c: Vector2, r: float) -> void:
	draw_arc(c, r * 0.54, 0.0, TAU, 32, accent, 1.8, true)
	for i: int in range(8):
		var angle: float = TAU * float(i) / 8.0
		var a: Vector2 = c + Vector2(cos(angle), sin(angle)) * r * 0.78
		var b: Vector2 = c + Vector2(cos(angle), sin(angle)) * r * 1.04
		_line(a, b, accent, 1.4)
	_line(c + Vector2(-r * 0.20, r * 0.58), c + Vector2(r * 0.20, r * 0.58), accent, 1.6)
	_line(c + Vector2(-r * 0.12, r * 0.76), c + Vector2(r * 0.12, r * 0.76), accent, 1.4)


func _draw_policy_point(c: Vector2, r: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(6):
		var angle: float = -PI * 0.5 + TAU * float(i) / 6.0
		pts.append(c + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(pts, Color(accent.r, accent.g, accent.b, 0.08))
	for i: int in range(6):
		_line(pts[i], pts[(i + 1) % 6], accent, 1.7)
	_line(c + Vector2(-r * 0.34, 0), c + Vector2(r * 0.34, 0), accent, 1.4)
	_line(c + Vector2(0, -r * 0.34), c + Vector2(0, r * 0.34), accent, 1.4)


func _draw_hint(c: Vector2, r: float) -> void:
	draw_arc(c, r * 0.60, -PI * 0.08, TAU * 0.86, 28, accent, 1.7, true)
	_line(c + Vector2(0, r * 0.18), c + Vector2(0, r * 0.48), accent, 1.7)
	draw_circle(c + Vector2(0, r * 0.73), 1.7, accent)


func _draw_review(c: Vector2, r: float) -> void:
	draw_arc(c, r * 0.74, PI * 0.24, PI * 1.78, 32, accent, 1.7, true)
	_line(c + Vector2(-r * 0.64, -r * 0.16), c + Vector2(-r * 0.92, -r * 0.16), accent, 1.7)
	_line(c + Vector2(-r * 0.64, -r * 0.16), c + Vector2(-r * 0.74, -r * 0.44), accent, 1.7)
	_line(c + Vector2(-r * 0.25, 0), c + Vector2(r * 0.42, 0), muted, 1.2)
	_line(c + Vector2(-r * 0.25, r * 0.26), c + Vector2(r * 0.26, r * 0.26), muted, 1.2)


func _draw_government(c: Vector2, r: float) -> void:
	var roof: PackedVector2Array = PackedVector2Array([
		c + Vector2(-r * 0.86, -r * 0.25),
		c + Vector2(0, -r * 0.78),
		c + Vector2(r * 0.86, -r * 0.25)
	])
	draw_polyline(roof, accent, 1.8, true)
	_line(c + Vector2(-r * 0.78, -r * 0.16), c + Vector2(r * 0.78, -r * 0.16), accent, 1.6)
	for x: float in [-0.48, 0.0, 0.48]:
		_line(c + Vector2(r * x, -r * 0.06), c + Vector2(r * x, r * 0.55), accent, 1.6)
	_line(c + Vector2(-r * 0.80, r * 0.62), c + Vector2(r * 0.80, r * 0.62), accent, 1.8)


func _draw_monetary(c: Vector2, r: float) -> void:
	draw_arc(c, r * 0.58, 0, TAU, 32, accent, 1.7, true)
	draw_arc(c, r * 0.92, PI * 0.18, PI * 1.48, 28, Color(accent.r, accent.g, accent.b, 0.46), 1.2, true)
	_line(c + Vector2(r * 0.38, r * 0.18), c + Vector2(r * 0.78, r * 0.58), accent, 1.5)
	_line(c + Vector2(r * 0.78, r * 0.58), c + Vector2(r * 0.46, r * 0.60), accent, 1.5)
	_line(c + Vector2(r * 0.78, r * 0.58), c + Vector2(r * 0.76, r * 0.26), accent, 1.5)


func _draw_tax(c: Vector2, r: float) -> void:
	var p0: Vector2 = c + Vector2(-r * 0.58, -r * 0.70)
	var p1: Vector2 = c + Vector2(r * 0.54, -r * 0.70)
	var p2: Vector2 = c + Vector2(r * 0.54, r * 0.60)
	var p3: Vector2 = c + Vector2(-r * 0.58, r * 0.60)
	draw_polyline(PackedVector2Array([p0, p1, p2, p3, p0]), accent, 1.5, true)
	_line(c + Vector2(-r * 0.32, -r * 0.30), c + Vector2(r * 0.30, -r * 0.30), muted, 1.1)
	_line(c + Vector2(-r * 0.32, r * 0.02), c + Vector2(r * 0.16, r * 0.02), muted, 1.1)
	_line(c + Vector2(0, -r * 0.06), c + Vector2(0, r * 0.42), accent, 1.8)
	_line(c + Vector2(0, r * 0.42), c + Vector2(-r * 0.18, r * 0.22), accent, 1.8)
	_line(c + Vector2(0, r * 0.42), c + Vector2(r * 0.18, r * 0.22), accent, 1.8)


func _draw_confirm(c: Vector2, r: float) -> void:
	_line(c + Vector2(-r * 0.70, 0), c + Vector2(r * 0.48, 0), accent, 2.0)
	_line(c + Vector2(r * 0.48, 0), c + Vector2(r * 0.18, -r * 0.28), accent, 2.0)
	_line(c + Vector2(r * 0.48, 0), c + Vector2(r * 0.18, r * 0.28), accent, 2.0)


func _draw_chevron(c: Vector2, r: float, direction: float) -> void:
	_line(c + Vector2(-direction * r * 0.25, -r * 0.46), c + Vector2(direction * r * 0.28, 0), accent, 2.0)
	_line(c + Vector2(direction * r * 0.28, 0), c + Vector2(-direction * r * 0.25, r * 0.46), accent, 2.0)
