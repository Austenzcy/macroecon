extends Control

const HudV2Theme = preload("res://scripts/ui/hud_v2/HudV2Theme.gd")

var _scenario: Dictionary = {}
var _ui_scale: float = 1.0


func setup(scenario: Dictionary, ui_scale: float = 1.0) -> void:
	_scenario = scenario.duplicate(true)
	_ui_scale = ui_scale
	custom_minimum_size = Vector2(300, 220) * _ui_scale
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var font: Font = get_theme_default_font()
	if font == null:
		return
	var pad_l := maxf(34.0, size.x * 0.13)
	var pad_t := maxf(20.0, size.y * 0.12)
	var pad_r := maxf(24.0, size.x * 0.08)
	var pad_b := maxf(34.0, size.y * 0.16)
	var plot := Rect2(pad_l, pad_t, maxf(40.0, size.x - pad_l - pad_r), maxf(40.0, size.y - pad_t - pad_b))
	var axis := Color(0.73, 0.83, 0.87, 0.86)
	draw_line(Vector2(plot.position.x, plot.end.y), Vector2(plot.end.x, plot.end.y), axis, 1.2, true)
	draw_line(Vector2(plot.position.x, plot.position.y), Vector2(plot.position.x, plot.end.y), axis, 1.2, true)
	draw_string(font, Vector2(plot.end.x - 6, plot.end.y + 22), "Y", HORIZONTAL_ALIGNMENT_LEFT, 18, HudV2Theme.font(11, _ui_scale), HudV2Theme.TEXT_MUTED)
	draw_string(font, Vector2(plot.position.x - 22, plot.position.y + 10), "i", HORIZONTAL_ALIGNMENT_LEFT, 18, HudV2Theme.font(11, _ui_scale), HudV2Theme.TEXT_MUTED)

	var lm := PackedVector2Array([
		_p(plot, 0.12, 0.92),
		_p(plot, 0.36, 0.70),
		_p(plot, 0.60, 0.47),
		_p(plot, 0.86, 0.20)
	])
	var is0 := PackedVector2Array([
		_p(plot, 0.15, 0.18),
		_p(plot, 0.38, 0.38),
		_p(plot, 0.63, 0.62),
		_p(plot, 0.88, 0.86)
	])
	var is1 := _shifted_is_curve(plot)
	draw_polyline(lm, Color(0.39, 0.72, 0.95, 0.95), 1.8, true)
	draw_polyline(is0, Color(0.93, 0.42, 0.38, 0.50), 1.4, true)
	draw_polyline(is1, Color(0.96, 0.58, 0.48, 0.95), 1.8, true)

	var e0 := _p(plot, 0.56, 0.51)
	var e1 := _p(plot, 0.46, 0.60)
	draw_circle(e0, 3.6, Color(0.90, 0.92, 0.93, 0.80))
	draw_circle(e1, 4.6, HudV2Theme.ACCENT_SYSTEM)
	draw_string(font, lm[lm.size() - 1] + Vector2(-24, -2), "LM", HORIZONTAL_ALIGNMENT_LEFT, 30, HudV2Theme.font(10, _ui_scale), Color(0.58, 0.84, 1.0, 0.95))
	draw_string(font, is0[is0.size() - 1] + Vector2(-32, -2), "IS", HORIZONTAL_ALIGNMENT_LEFT, 30, HudV2Theme.font(10, _ui_scale), Color(0.93, 0.62, 0.58, 0.58))
	draw_string(font, is1[is1.size() - 1] + Vector2(-42, -12), "IS'", HORIZONTAL_ALIGNMENT_LEFT, 34, HudV2Theme.font(10, _ui_scale), Color(1.0, 0.68, 0.58, 0.96))
	draw_string(font, e0 + Vector2(6, -5), "E0", HORIZONTAL_ALIGNMENT_LEFT, 28, HudV2Theme.font(10, _ui_scale), HudV2Theme.TEXT_MUTED)
	draw_string(font, e1 + Vector2(6, -5), "E1", HORIZONTAL_ALIGNMENT_LEFT, 28, HudV2Theme.font(10, _ui_scale), HudV2Theme.ACCENT_SYSTEM)


func _p(rect: Rect2, x: float, y: float) -> Vector2:
	return Vector2(rect.position.x + rect.size.x * x, rect.position.y + rect.size.y * y)


func _shifted_is_curve(plot: Rect2) -> PackedVector2Array:
	var hint := str(_scenario.get("model_hint", ""))
	var right_shift := hint.find("右") >= 0 or hint.find("增加") >= 0 or hint.find("扩张") >= 0
	var dx := 0.10 if right_shift else -0.10
	return PackedVector2Array([
		_p(plot, clampf(0.15 + dx, 0.06, 0.92), 0.22),
		_p(plot, clampf(0.38 + dx, 0.06, 0.92), 0.43),
		_p(plot, clampf(0.63 + dx, 0.06, 0.92), 0.66),
		_p(plot, clampf(0.88 + dx, 0.06, 0.92), 0.88)
	])
