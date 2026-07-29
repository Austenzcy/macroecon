extends Control

const RefTheme = preload("res://scripts/ui/hud_reference/HudReferenceTheme.gd")

@export var kind: String = "panel"
@export var accent: Color = RefTheme.CYAN


func setup(panel_kind: String, accent_color: Color = RefTheme.CYAN) -> void:
	kind = panel_kind
	accent = accent_color
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if size.x <= 6.0 or size.y <= 6.0:
		return
	var w := size.x
	var h := size.y
	var cut := clampf(minf(w, h) * 0.10, 10.0, 26.0)
	var pts := _points(w, h, cut)
	draw_colored_polygon(pts, _base_color())
	_draw_depth(w, h)
	_draw_structure(w, h, cut)


func _points(w: float, h: float, cut: float) -> PackedVector2Array:
	match kind:
		"top_band":
			return PackedVector2Array([
				Vector2(cut * 0.6, 0),
				Vector2(w - cut * 0.8, 0),
				Vector2(w, cut * 0.65),
				Vector2(w - cut * 0.55, h),
				Vector2(cut * 0.35, h),
				Vector2(0, h - cut * 0.55)
			])
		"left_drawer":
			return PackedVector2Array([
				Vector2(0, 0),
				Vector2(w - cut, 0),
				Vector2(w, cut * 1.25),
				Vector2(w - cut * 0.55, h * 0.42),
				Vector2(w - cut * 0.55, h),
				Vector2(0, h)
			])
		"right_drawer":
			return PackedVector2Array([
				Vector2(cut, 0),
				Vector2(w, 0),
				Vector2(w, h),
				Vector2(cut * 0.55, h),
				Vector2(cut * 0.55, h * 0.42),
				Vector2(0, cut * 1.25)
			])
		"analysis":
			return PackedVector2Array([
				Vector2(cut, 0),
				Vector2(w - cut * 0.65, 0),
				Vector2(w, cut * 0.7),
				Vector2(w, h),
				Vector2(cut * 0.55, h),
				Vector2(0, h - cut * 0.8),
				Vector2(0, cut * 0.7)
			])
		"module":
			return PackedVector2Array([
				Vector2(cut * 0.55, 0),
				Vector2(w, 0),
				Vector2(w, h - cut * 0.55),
				Vector2(w - cut * 0.55, h),
				Vector2(0, h),
				Vector2(0, cut * 0.55)
			])
		"policy":
			return PackedVector2Array([
				Vector2(cut * 0.45, 0),
				Vector2(w, 0),
				Vector2(w, h - cut * 0.45),
				Vector2(w - cut * 0.45, h),
				Vector2(0, h),
				Vector2(0, cut * 0.45)
			])
		"chip", "button":
			return PackedVector2Array([
				Vector2(cut * 0.45, 0),
				Vector2(w - cut * 0.35, 0),
				Vector2(w, h * 0.5),
				Vector2(w - cut * 0.35, h),
				Vector2(cut * 0.45, h),
				Vector2(0, h * 0.5)
			])
	return PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, h), Vector2(0, h)])


func _base_color() -> Color:
	match kind:
		"top_band":
			return Color(0.004, 0.018, 0.026, 0.58)
		"left_drawer", "right_drawer":
			return Color(0.004, 0.018, 0.024, 0.70)
		"analysis":
			return Color(0.004, 0.018, 0.024, 0.56)
		"module":
			return Color(0.010, 0.036, 0.048, 0.50)
		"policy":
			return Color(0.010, 0.036, 0.050, 0.42)
		"chip", "button":
			return Color(0.018, 0.050, 0.064, 0.40)
	return RefTheme.PANEL_DARK


func _draw_depth(w: float, h: float) -> void:
	draw_rect(Rect2(0, 0, w, minf(h * 0.30, 54.0)), RefTheme.GLASS, true)
	draw_rect(Rect2(0, h * 0.58, w, h * 0.42), Color(0, 0, 0, 0.13), true)
	if kind == "top_band":
		draw_rect(Rect2(w * 0.34, 0, w * 0.32, h), Color(0.16, 0.44, 0.56, 0.035), true)
	elif kind == "analysis":
		draw_rect(Rect2(0, h * 0.35, w, h * 0.65), Color(0, 0, 0, 0.18), true)


func _draw_structure(w: float, h: float, cut: float) -> void:
	var faint := Color(accent.r, accent.g, accent.b, 0.18)
	var mid := Color(accent.r, accent.g, accent.b, 0.34)
	var strong := Color(accent.r, accent.g, accent.b, 0.58)
	match kind:
		"top_band":
			_line(Vector2(cut, 1), Vector2(w * 0.25, 1), mid)
			_line(Vector2(w * 0.43, h - 1), Vector2(w * 0.62, h - 1), strong)
			_line(Vector2(w * 0.74, 1), Vector2(w - cut * 1.2, 1), faint)
			_bracket(Vector2(0, h - cut * 0.55), Vector2(1, 0), Vector2(0, -1), 28, faint)
			_bracket(Vector2(w, cut * 0.65), Vector2(-1, 0), Vector2(0, 1), 28, faint)
		"left_drawer":
			_line(Vector2(0, 18), Vector2(0, h - 18), mid)
			_line(Vector2(w - cut * 0.55, h * 0.14), Vector2(w - cut * 0.55, h * 0.38), faint)
			_line(Vector2(w - cut * 0.55, h * 0.58), Vector2(w - cut * 0.55, h - 24), Color(faint.r, faint.g, faint.b, 0.12))
			_bracket(Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), 30, strong)
			_bracket(Vector2(0, h), Vector2(1, 0), Vector2(0, -1), 24, faint)
		"right_drawer":
			_line(Vector2(w - 1, 18), Vector2(w - 1, h - 18), mid)
			_line(Vector2(cut * 0.55, h * 0.14), Vector2(cut * 0.55, h * 0.38), faint)
			_line(Vector2(cut * 0.55, h * 0.58), Vector2(cut * 0.55, h - 24), Color(faint.r, faint.g, faint.b, 0.12))
			_bracket(Vector2(w, 0), Vector2(-1, 0), Vector2(0, 1), 30, strong)
			_bracket(Vector2(w, h), Vector2(-1, 0), Vector2(0, -1), 24, faint)
		"analysis":
			_line(Vector2(cut + 12, 1), Vector2(w * 0.35, 1), mid)
			_line(Vector2(w * 0.56, h - 1), Vector2(w - cut, h - 1), faint)
			_bracket(Vector2(cut, 0), Vector2(1, 0), Vector2(-0.55, 1), 24, faint)
		"module", "policy":
			_line(Vector2(cut * 0.8, 1), Vector2(minf(w * 0.48, w - 28), 1), faint)
			_line(Vector2(w - 26, h - 1), Vector2(w - 8, h - 1), Color(faint.r, faint.g, faint.b, 0.12))
		"chip", "button":
			_line(Vector2(cut * 0.55, 1), Vector2(w - cut * 0.65, 1), faint)
			_line(Vector2(cut * 0.55, h - 1), Vector2(w - cut * 0.65, h - 1), Color(faint.r, faint.g, faint.b, 0.10))


func _line(a: Vector2, b: Vector2, color: Color) -> void:
	draw_line(a, b, color, 1.0, true)


func _bracket(origin: Vector2, dir_a: Vector2, dir_b: Vector2, length: float, color: Color) -> void:
	draw_line(origin, origin + dir_a.normalized() * length, color, 1.0, true)
	draw_line(origin, origin + dir_b.normalized() * length, color, 1.0, true)
