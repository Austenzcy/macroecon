extends PanelContainer

const HudV2Theme = preload("res://scripts/ui/hud_v2/HudV2Theme.gd")

@export var shape_kind: String = "panel"
@export var accent_side: String = "left"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", HudV2Theme.transparent_panel_style())
	queue_redraw()


func set_shape_kind(kind: String, side: String = "left") -> void:
	shape_kind = kind
	accent_side = side
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 4.0 or h <= 4.0:
		return

	var notch: float = clampf(minf(w, h) * 0.075, 8.0, 18.0)
	var points: PackedVector2Array = _shape_points(w, h, notch)
	draw_colored_polygon(points, _surface_color())
	_draw_surface_layers(w, h)
	_draw_accents(w, h, notch)
	_draw_corner_marks(w, h, notch)


func _shape_points(w: float, h: float, notch: float) -> PackedVector2Array:
	match shape_kind:
		"top_challenge":
			return PackedVector2Array([
				Vector2(0, 0),
				Vector2(w, 0),
				Vector2(w - notch, h),
				Vector2(0, h)
			])
		"left_drawer":
			return PackedVector2Array([
				Vector2(0, 0),
				Vector2(w - notch, 0),
				Vector2(w, h * 0.42),
				Vector2(w - notch, h * 0.52),
				Vector2(w - notch, h),
				Vector2(0, h)
			])
		"right_drawer":
			return PackedVector2Array([
				Vector2(notch, 0),
				Vector2(w, 0),
				Vector2(w, h),
				Vector2(notch, h),
				Vector2(notch, h * 0.52),
				Vector2(0, h * 0.42)
			])
		"analysis":
			return PackedVector2Array([
				Vector2(notch, 0),
				Vector2(w, 0),
				Vector2(w, h - notch),
				Vector2(w - notch, h),
				Vector2(0, h),
				Vector2(0, notch)
			])
		"module":
			return PackedVector2Array([
				Vector2(0, 0),
				Vector2(w - notch * 0.6, 0),
				Vector2(w, notch * 0.6),
				Vector2(w, h),
				Vector2(notch * 0.6, h),
				Vector2(0, h - notch * 0.6)
			])
	return PackedVector2Array([
		Vector2(0, 0),
		Vector2(w, 0),
		Vector2(w, h),
		Vector2(0, h)
	])


func _surface_color() -> Color:
	match shape_kind:
		"left_drawer", "right_drawer":
			return Color(0.010, 0.030, 0.040, 0.70)
		"top_challenge":
			return Color(0.010, 0.030, 0.044, 0.54)
		"analysis":
			return Color(0.012, 0.032, 0.043, 0.56)
		"module":
			return Color(0.020, 0.050, 0.062, 0.46)
	return Color(0.014, 0.036, 0.046, 0.58)


func _stroke_color() -> Color:
	match shape_kind:
		"left_drawer", "right_drawer":
			return Color(0.48, 0.84, 0.95, 0.30)
		"analysis", "module":
			return Color(0.52, 0.88, 0.96, 0.22)
	return Color(0.52, 0.88, 0.96, 0.26)


func _draw_surface_layers(w: float, h: float) -> void:
	var top_wash := Color(0.42, 0.82, 0.94, 0.035)
	var bottom_depth := Color(0.0, 0.0, 0.0, 0.13)
	if shape_kind == "top_challenge":
		draw_rect(Rect2(0, 0, w, minf(h * 0.45, 42.0)), top_wash, true)
		draw_rect(Rect2(0, h * 0.58, w, h * 0.42), Color(0.0, 0.0, 0.0, 0.10), true)
	elif shape_kind == "analysis":
		draw_rect(Rect2(0, h * 0.38, w, h * 0.62), bottom_depth, true)
		draw_rect(Rect2(0, 0, w, minf(h * 0.28, 58.0)), Color(0.40, 0.82, 0.94, 0.030), true)
	else:
		draw_rect(Rect2(0, 0, w, minf(h * 0.18, 72.0)), top_wash, true)
		draw_rect(Rect2(0, h * 0.70, w, h * 0.30), Color(0.0, 0.0, 0.0, 0.08), true)


func _draw_accents(w: float, h: float, notch: float) -> void:
	var accent := HudV2Theme.ACCENT_SYSTEM
	var stroke := _stroke_color()
	if shape_kind == "left_drawer":
		draw_line(Vector2(0, 16), Vector2(0, h - 16), Color(accent.r, accent.g, accent.b, 0.30), 1.0, true)
		draw_line(Vector2(w - notch, 28), Vector2(w - notch, h * 0.38), stroke, 1.0, true)
		draw_line(Vector2(w - notch, h * 0.58), Vector2(w - notch, h - 28), Color(stroke.r, stroke.g, stroke.b, 0.16), 1.0, true)
	elif shape_kind == "right_drawer":
		draw_line(Vector2(w - 1, 16), Vector2(w - 1, h - 16), Color(accent.r, accent.g, accent.b, 0.30), 1.0, true)
		draw_line(Vector2(notch, 28), Vector2(notch, h * 0.38), stroke, 1.0, true)
		draw_line(Vector2(notch, h * 0.58), Vector2(notch, h - 28), Color(stroke.r, stroke.g, stroke.b, 0.16), 1.0, true)
	elif shape_kind == "top_challenge":
		draw_line(Vector2(18, 0.5), Vector2(w * 0.28, 0.5), Color(accent.r, accent.g, accent.b, 0.30), 1.0, true)
		draw_line(Vector2(w * 0.44, h - 1), Vector2(w * 0.74, h - 1), Color(accent.r, accent.g, accent.b, 0.34), 1.0, true)
		draw_line(Vector2(w - notch - 42, h - 1), Vector2(w - notch - 8, h - 1), Color(accent.r, accent.g, accent.b, 0.18), 1.0, true)
	elif shape_kind == "analysis":
		draw_line(Vector2(notch + 10, 1), Vector2(w * 0.34, 1), Color(accent.r, accent.g, accent.b, 0.28), 1.0, true)
		draw_line(Vector2(w * 0.58, h - 1), Vector2(w - notch - 10, h - 1), Color(accent.r, accent.g, accent.b, 0.22), 1.0, true)
	elif shape_kind == "module":
		draw_line(Vector2(10, 1), Vector2(minf(w - 22, w * 0.46), 1), Color(accent.r, accent.g, accent.b, 0.22), 1.0, true)
		draw_line(Vector2(w - 28, h - 1), Vector2(w - 10, h - 1), Color(accent.r, accent.g, accent.b, 0.16), 1.0, true)


func _draw_corner_marks(w: float, h: float, notch: float) -> void:
	var stroke := _stroke_color()
	var len: float = clampf(minf(w, h) * 0.16, 14.0, 34.0)
	var alpha_soft := Color(stroke.r, stroke.g, stroke.b, stroke.a * 0.58)
	if shape_kind == "left_drawer":
		_draw_corner(Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), len, stroke)
		_draw_corner(Vector2(0, h), Vector2(1, 0), Vector2(0, -1), len * 0.72, alpha_soft)
		draw_line(Vector2(w - notch, 0), Vector2(w - notch + minf(notch, 14.0), h * 0.18), alpha_soft, 1.0, true)
	elif shape_kind == "right_drawer":
		_draw_corner(Vector2(w, 0), Vector2(-1, 0), Vector2(0, 1), len, stroke)
		_draw_corner(Vector2(w, h), Vector2(-1, 0), Vector2(0, -1), len * 0.72, alpha_soft)
		draw_line(Vector2(notch, 0), Vector2(maxf(0.0, notch - 14.0), h * 0.18), alpha_soft, 1.0, true)
	elif shape_kind == "top_challenge":
		_draw_corner(Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), len * 0.9, alpha_soft)
		_draw_corner(Vector2(w, 0), Vector2(-1, 0), Vector2(0, 1), len * 0.9, alpha_soft)
	elif shape_kind == "analysis":
		_draw_corner(Vector2(notch, 0), Vector2(1, 0), Vector2(-0.65, 1), len, alpha_soft)
		_draw_corner(Vector2(w, h - notch), Vector2(0, -1), Vector2(-1, 0.65), len * 0.8, alpha_soft)
	elif shape_kind == "module":
		_draw_corner(Vector2(0, h), Vector2(1, 0), Vector2(0, -1), len * 0.55, alpha_soft)
		_draw_corner(Vector2(w, 0), Vector2(-1, 0), Vector2(0, 1), len * 0.55, alpha_soft)


func _draw_corner(origin: Vector2, dir_a: Vector2, dir_b: Vector2, length: float, color: Color) -> void:
	draw_line(origin, origin + dir_a.normalized() * length, color, 1.0, true)
	draw_line(origin, origin + dir_b.normalized() * length, color, 1.0, true)
