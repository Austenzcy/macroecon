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

	var border_points := PackedVector2Array(points)
	border_points.append(points[0])
	draw_polyline(border_points, _stroke_color(), 1.0, true)
	_draw_accents(w, h, notch)


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
			return Color(0.012, 0.034, 0.044, 0.76)
		"top_challenge":
			return Color(0.010, 0.032, 0.046, 0.62)
		"analysis":
			return Color(0.014, 0.036, 0.046, 0.64)
		"module":
			return Color(0.024, 0.055, 0.066, 0.55)
	return HudV2Theme.SURFACE


func _stroke_color() -> Color:
	match shape_kind:
		"left_drawer", "right_drawer":
			return Color(0.36, 0.72, 0.85, 0.40)
		"analysis", "module":
			return Color(0.45, 0.82, 0.90, 0.28)
	return HudV2Theme.STROKE


func _draw_accents(w: float, h: float, notch: float) -> void:
	var accent := HudV2Theme.ACCENT_SYSTEM
	if shape_kind == "left_drawer":
		draw_line(Vector2(w - notch, 18), Vector2(w - notch, h - 18), Color(accent.r, accent.g, accent.b, 0.26), 1.0, true)
	elif shape_kind == "right_drawer":
		draw_line(Vector2(notch, 18), Vector2(notch, h - 18), Color(accent.r, accent.g, accent.b, 0.26), 1.0, true)
	elif shape_kind == "top_challenge":
		draw_line(Vector2(14, h - 1), Vector2(w * 0.62, h - 1), Color(accent.r, accent.g, accent.b, 0.54), 1.0, true)
	elif shape_kind == "analysis":
		draw_line(Vector2(notch + 8, 1), Vector2(w * 0.46, 1), Color(accent.r, accent.g, accent.b, 0.38), 1.0, true)
	elif shape_kind == "module":
		draw_line(Vector2(8, 1), Vector2(minf(w - 18, w * 0.55), 1), Color(accent.r, accent.g, accent.b, 0.28), 1.0, true)
