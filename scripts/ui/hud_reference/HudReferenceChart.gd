extends Control

const HudReferenceTheme = preload("res://scripts/ui/hud_reference/HudReferenceTheme.gd")

var chart_type: String = "islm"
var c_value: float = 54.0
var i_value: float = 23.0
var g_value: float = 23.0


func setup_islm() -> void:
	chart_type = "islm"
	queue_redraw()


func setup_donut(next_c: float, next_i: float, next_g: float) -> void:
	chart_type = "donut"
	c_value = next_c
	i_value = next_i
	g_value = next_g
	queue_redraw()


func _draw() -> void:
	if chart_type == "donut":
		_draw_donut()
	else:
		_draw_islm()


func _draw_islm() -> void:
	var pad: float = minf(size.x, size.y) * 0.13
	var rect: Rect2 = Rect2(Vector2(pad, pad * 0.9), size - Vector2(pad * 1.75, pad * 1.65))
	if rect.size.x <= 32.0 or rect.size.y <= 32.0:
		return
	var axis: Color = Color(0.72, 0.82, 0.86, 0.70)
	var grid: Color = Color(0.55, 0.74, 0.82, 0.13)
	var cyan: Color = HudReferenceTheme.CYAN
	var red: Color = HudReferenceTheme.RED
	var blue: Color = HudReferenceTheme.BLUE
	var gold: Color = HudReferenceTheme.GOLD

	draw_rect(rect.grow(8.0), Color(0.0, 0.02, 0.028, 0.32), true)
	for i: int in range(1, 4):
		var x: float = rect.position.x + rect.size.x * float(i) / 4.0
		var y: float = rect.position.y + rect.size.y * float(i) / 4.0
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.position.y + rect.size.y), grid, 1.0, true)
		draw_line(Vector2(rect.position.x, y), Vector2(rect.position.x + rect.size.x, y), grid, 1.0, true)

	var origin: Vector2 = Vector2(rect.position.x, rect.position.y + rect.size.y)
	var y_top: Vector2 = Vector2(rect.position.x, rect.position.y)
	var x_right: Vector2 = Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y)
	draw_line(origin, y_top, axis, 1.6, true)
	draw_line(origin, x_right, axis, 1.6, true)
	draw_line(y_top, y_top + Vector2(-4, 8), axis, 1.3, true)
	draw_line(y_top, y_top + Vector2(4, 8), axis, 1.3, true)
	draw_line(x_right, x_right + Vector2(-8, -4), axis, 1.3, true)
	draw_line(x_right, x_right + Vector2(-8, 4), axis, 1.3, true)

	var lm_a: Vector2 = rect.position + Vector2(rect.size.x * 0.22, rect.size.y * 0.83)
	var lm_b: Vector2 = rect.position + Vector2(rect.size.x * 0.82, rect.size.y * 0.17)
	var is_a: Vector2 = rect.position + Vector2(rect.size.x * 0.21, rect.size.y * 0.18)
	var is_b: Vector2 = rect.position + Vector2(rect.size.x * 0.83, rect.size.y * 0.84)
	var is2_a: Vector2 = rect.position + Vector2(rect.size.x * 0.12, rect.size.y * 0.24)
	var is2_b: Vector2 = rect.position + Vector2(rect.size.x * 0.70, rect.size.y * 0.88)
	draw_line(lm_a, lm_b, cyan, 2.0, true)
	draw_line(is_a, is_b, red, 2.0, true)
	draw_line(is2_a, is2_b, Color(red.r, red.g, red.b, 0.48), 1.8, true)

	var e0: Vector2 = rect.position + Vector2(rect.size.x * 0.52, rect.size.y * 0.50)
	var e1: Vector2 = rect.position + Vector2(rect.size.x * 0.43, rect.size.y * 0.60)
	draw_circle(e0, 4.0, gold)
	draw_arc(e0, 7.5, 0.0, TAU, 18, Color(gold.r, gold.g, gold.b, 0.58), 1.2, true)
	draw_circle(e1, 4.0, blue)
	draw_arc(e1, 7.5, 0.0, TAU, 18, Color(blue.r, blue.g, blue.b, 0.56), 1.2, true)
	draw_dashed_line(Vector2(rect.position.x, e0.y), e0, Color(1, 1, 1, 0.20), 1.0, 5.0, true)
	draw_dashed_line(Vector2(e0.x, rect.position.y + rect.size.y), e0, Color(1, 1, 1, 0.20), 1.0, 5.0, true)

	var font: Font = ThemeDB.fallback_font
	var fs: int = 13
	draw_string(font, y_top + Vector2(-16, 4), "i", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, HudReferenceTheme.BODY)
	draw_string(font, x_right + Vector2(-2, 18), "Y", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, HudReferenceTheme.BODY)
	draw_string(font, lm_b + Vector2(8, 2), "LM", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, cyan)
	draw_string(font, is_b + Vector2(-20, 18), "IS", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, red)
	draw_string(font, is2_a + Vector2(-4, -8), "IS'", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(red.r, red.g, red.b, 0.72))
	draw_string(font, e0 + Vector2(8, -7), "E0", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, HudReferenceTheme.MUTED)
	draw_string(font, e1 + Vector2(8, 15), "E1", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, HudReferenceTheme.MUTED)


func _draw_donut() -> void:
	var total: float = maxf(c_value + i_value + g_value, 1.0)
	var center: Vector2 = Vector2(size.x * 0.42, size.y * 0.48)
	var radius: float = minf(size.x * 0.22, size.y * 0.33)
	var width: float = maxf(9.0, radius * 0.24)
	var start: float = -PI * 0.5
	var items: Array = [
		{"label": "C", "value": c_value, "color": Color(0.32, 0.78, 0.92, 1.0)},
		{"label": "I", "value": i_value, "color": Color(0.58, 0.58, 0.92, 1.0)},
		{"label": "G", "value": g_value, "color": HudReferenceTheme.GOLD},
	]
	for item: Dictionary in items:
		var span: float = TAU * float(item["value"]) / total
		draw_arc(center, radius, start, start + span, 48, item["color"], width, true)
		start += span
	draw_arc(center, radius, 0, TAU, 64, Color(1, 1, 1, 0.12), 1.0, true)
	draw_circle(center, radius - width * 0.58, Color(0.0, 0.02, 0.028, 0.56))

	var font: Font = ThemeDB.fallback_font
	draw_string(font, center + Vector2(-22, -2), "Y", HORIZONTAL_ALIGNMENT_CENTER, 44, 18, HudReferenceTheme.TITLE)
	draw_string(font, center + Vector2(-30, 18), "100", HORIZONTAL_ALIGNMENT_CENTER, 60, 12, HudReferenceTheme.MUTED)

	var y: float = size.y * 0.27
	var x: float = size.x * 0.70
	for item: Dictionary in items:
		var percent: float = 100.0 * float(item["value"]) / total
		draw_circle(Vector2(x, y - 5), 4.0, item["color"])
		draw_string(font, Vector2(x + 12, y), "%s  %.0f%%" % [String(item["label"]), percent], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, HudReferenceTheme.BODY)
		y += 25.0
