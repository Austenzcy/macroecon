extends Control

const HudV2Theme = preload("res://scripts/ui/hud_v2/HudV2Theme.gd")

var display_name: String = ""
var symbol: String = ""
var value_text: String = ""
var status_text: String = ""
var status_score: float = 0.0
var current_value: float = 0.0
var display_min: float = 0.0
var display_max: float = 1.0
var reference_value: float = 0.0
var ui_scale: float = 1.0


func setup(label: String, metric_symbol: String, config: Dictionary, value: String, current_number: float, status: String, score: float, scale: float = 1.0) -> void:
	display_name = label
	symbol = metric_symbol
	value_text = value
	status_text = status
	status_score = score
	current_value = current_number
	display_min = float(config.get("display_min", 0.0))
	display_max = float(config.get("display_max", 1.0))
	reference_value = float(config.get("reference_value", 0.0))
	ui_scale = scale
	custom_minimum_size = Vector2(268, 42) * ui_scale
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var font: Font = get_theme_default_font()
	if font == null:
		return
	var title_size := HudV2Theme.font(13, ui_scale)
	var value_size := HudV2Theme.font(13, ui_scale)
	var status_size := HudV2Theme.font(12, ui_scale)
	var status_color := HudV2Theme.status_color(status_text, status_score)
	var y := size.y * 0.62
	var name_w := clampf(size.x * 0.28, 72.0, 95.0)
	var value_w := clampf(size.x * 0.18, 48.0, 64.0)
	var status_w := clampf(size.x * 0.18, 44.0, 58.0)
	var bar_left := name_w + 4.0
	var bar_right := size.x - value_w - status_w - 12.0
	var bar_w := maxf(36.0, bar_right - bar_left)

	draw_string(font, Vector2(0, y), "%s（%s）" % [display_name, symbol], HORIZONTAL_ALIGNMENT_LEFT, name_w, title_size, HudV2Theme.TEXT_BODY)
	_draw_bar(Rect2(bar_left, size.y * 0.42, bar_w, maxf(6.0, 6.0 * ui_scale)), status_color, font)
	draw_string(font, Vector2(bar_right + 8.0, y), value_text, HORIZONTAL_ALIGNMENT_RIGHT, value_w, value_size, HudV2Theme.TEXT_TITLE)
	draw_string(font, Vector2(bar_right + value_w + 14.0, y), status_text, HORIZONTAL_ALIGNMENT_LEFT, status_w, status_size, status_color)


func _draw_bar(track: Rect2, status_color: Color, font: Font) -> void:
	draw_rect(track, Color(1, 1, 1, 0.22), true)
	draw_rect(track, Color(1, 1, 1, 0.10), false, 1.0)
	var ref_x := track.position.x + track.size.x * _normalized(reference_value)
	draw_line(Vector2(ref_x, track.position.y - 7.0), Vector2(ref_x, track.end.y + 7.0), HudV2Theme.ACCENT_RESOURCE, 1.2, true)
	draw_string(font, Vector2(clampf(ref_x - 16.0, track.position.x, track.end.x - 32.0), track.position.y - 8.0), "参考值", HORIZONTAL_ALIGNMENT_LEFT, 46.0, HudV2Theme.font(9, ui_scale), HudV2Theme.TEXT_MUTED)
	var cur_x := track.position.x + track.size.x * _normalized(current_value)
	draw_line(Vector2(cur_x, track.position.y - 8.0), Vector2(cur_x, track.end.y + 8.0), status_color, 1.5, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cur_x, track.position.y - 11.0),
		Vector2(cur_x - 4.0, track.position.y - 4.0),
		Vector2(cur_x + 4.0, track.position.y - 4.0)
	]), status_color)


func _normalized(value: float) -> float:
	var span := display_max - display_min
	if absf(span) < 0.001:
		return 0.5
	return clampf((value - display_min) / span, 0.0, 1.0)
