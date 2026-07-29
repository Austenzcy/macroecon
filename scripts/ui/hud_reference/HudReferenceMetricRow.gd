extends Control

const HudReferenceTheme = preload("res://scripts/ui/hud_reference/HudReferenceTheme.gd")

var metric_name: String = "产出"
var symbol: String = "Y"
var value_text: String = "100.0"
var status_text: String = "适中"
var normalized_value: float = 0.48
var reference_value: float = 0.56


func setup(next_name: String, next_symbol: String, next_value: String, next_status: String, next_normalized: float, next_reference: float) -> void:
	metric_name = next_name
	symbol = next_symbol
	value_text = next_value
	status_text = next_status
	normalized_value = clampf(next_normalized, 0.0, 1.0)
	reference_value = clampf(next_reference, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var status_color: Color = HudReferenceTheme.status_color(status_text)
	var name_x: float = 0.0
	var track_x: float = size.x * 0.36
	var track_w: float = size.x * 0.32
	var value_x: float = size.x * 0.72
	var status_x: float = size.x * 0.87
	var mid_y: float = size.y * 0.56

	draw_string(font, Vector2(name_x, mid_y + 5), "%s（%s）" % [metric_name, symbol], HORIZONTAL_ALIGNMENT_LEFT, track_x - 10.0, 14, HudReferenceTheme.BODY)
	draw_rect(Rect2(Vector2(track_x, mid_y - 3), Vector2(track_w, 6)), Color(0.92, 0.98, 1.0, 0.22), true)
	draw_rect(Rect2(Vector2(track_x, mid_y - 3), Vector2(track_w * normalized_value, 6)), Color(status_color.r, status_color.g, status_color.b, 0.42), true)

	var ref_x: float = track_x + track_w * reference_value
	draw_line(Vector2(ref_x, mid_y - 11), Vector2(ref_x, mid_y + 11), HudReferenceTheme.GOLD, 1.2, true)
	draw_string(font, Vector2(ref_x - 18, mid_y - 14), "参考", HORIZONTAL_ALIGNMENT_CENTER, 36, 9, Color(HudReferenceTheme.GOLD.r, HudReferenceTheme.GOLD.g, HudReferenceTheme.GOLD.b, 0.78))

	var now_x: float = track_x + track_w * normalized_value
	var tri: PackedVector2Array = PackedVector2Array([
		Vector2(now_x, mid_y - 14),
		Vector2(now_x - 4, mid_y - 7),
		Vector2(now_x + 4, mid_y - 7),
	])
	draw_colored_polygon(tri, HudReferenceTheme.CYAN)
	draw_line(Vector2(now_x, mid_y - 5), Vector2(now_x, mid_y + 9), HudReferenceTheme.CYAN, 1.4, true)

	draw_string(font, Vector2(value_x, mid_y + 5), value_text, HORIZONTAL_ALIGNMENT_RIGHT, status_x - value_x - 8.0, 14, HudReferenceTheme.TITLE)
	draw_string(font, Vector2(status_x, mid_y + 5), status_text, HORIZONTAL_ALIGNMENT_RIGHT, size.x - status_x, 14, status_color)
