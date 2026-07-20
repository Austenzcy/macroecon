extends RefCounted

const BG_DEEP: Color = Color(0.025, 0.023, 0.020, 1.0)
const BG_INK: Color = Color(0.035, 0.045, 0.048, 1.0)
const SURFACE_WOOD: Color = Color(0.125, 0.088, 0.055, 0.97)
const SURFACE_LEATHER: Color = Color(0.105, 0.076, 0.058, 0.98)
const SURFACE_PARCHMENT_DARK: Color = Color(0.145, 0.116, 0.075, 0.97)
const SURFACE_PANEL: Color = Color(0.070, 0.082, 0.080, 0.97)
const SURFACE_RECESSED: Color = Color(0.043, 0.050, 0.052, 0.96)
const BORDER_GOLD: Color = Color(0.72, 0.55, 0.26, 0.96)
const BORDER_COPPER: Color = Color(0.54, 0.35, 0.18, 0.92)
const BORDER_SILVER: Color = Color(0.54, 0.58, 0.55, 0.88)
const TEXT_MAIN: Color = Color(0.94, 0.88, 0.74, 1.0)
const TEXT_SOFT: Color = Color(0.80, 0.76, 0.66, 1.0)
const TEXT_MUTED: Color = Color(0.63, 0.66, 0.62, 1.0)
const ACCENT_GOLD: Color = Color(0.95, 0.72, 0.30, 1.0)
const ACCENT_AMBER: Color = Color(0.86, 0.56, 0.22, 1.0)
const ACCENT_BLUE: Color = Color(0.55, 0.70, 0.78, 1.0)
const STABLE_GREEN: Color = Color(0.50, 0.72, 0.48, 1.0)
const WARNING_RED: Color = Color(0.78, 0.34, 0.26, 1.0)
const DIM_OVERLAY: Color = Color(0.015, 0.013, 0.010, 0.50)


static func panel_style(kind: String = "default", ui_scale: float = 1.0) -> StyleBoxFlat:
	var bg: Color = SURFACE_PANEL
	var border: Color = BORDER_COPPER
	var width: int = _dim(1.0, ui_scale)
	var radius: int = _dim(8.0, ui_scale)
	var shadow: float = 10.0

	match kind:
		"chapter":
			bg = Color(0.115, 0.075, 0.046, 0.98)
			border = BORDER_GOLD
			width = _dim(2.0, ui_scale)
			shadow = 18.0
		"desk":
			bg = Color(0.060, 0.055, 0.046, 0.98)
			border = Color(0.42, 0.31, 0.17, 0.90)
			shadow = 14.0
		"problem":
			bg = Color(0.135, 0.095, 0.058, 0.98)
			border = BORDER_GOLD
			width = _dim(2.0, ui_scale)
			shadow = 18.0
		"map":
			bg = Color(0.055, 0.067, 0.058, 0.98)
			border = Color(0.44, 0.34, 0.18, 0.94)
		"right":
			bg = Color(0.060, 0.070, 0.066, 0.98)
			border = Color(0.43, 0.34, 0.20, 0.90)
		"theory":
			bg = Color(0.050, 0.060, 0.060, 0.98)
			border = Color(0.45, 0.44, 0.34, 0.90)
		"compact":
			bg = Color(0.100, 0.075, 0.050, 0.94)
			border = Color(0.50, 0.36, 0.18, 0.84)
		"modal":
			bg = Color(0.125, 0.092, 0.060, 0.99)
			border = BORDER_GOLD
			width = _dim(2.0, ui_scale)
			shadow = 24.0
		"dialogue":
			bg = Color(0.080, 0.057, 0.043, 0.985)
			border = BORDER_GOLD
			width = _dim(2.0, ui_scale)
			radius = _dim(12.0, ui_scale)
			shadow = 24.0
		"card":
			bg = Color(0.110, 0.083, 0.055, 0.985)
			border = Color(0.50, 0.34, 0.17, 0.92)
			width = _dim(2.0, ui_scale)
			shadow = 12.0
		"card_hover":
			bg = Color(0.145, 0.105, 0.065, 0.99)
			border = Color(0.72, 0.50, 0.24, 1.0)
			width = _dim(2.0, ui_scale)
			shadow = 16.0
		"card_selected":
			bg = Color(0.165, 0.115, 0.060, 1.0)
			border = ACCENT_GOLD
			width = _dim(3.0, ui_scale)
			shadow = 20.0
		"level_locked":
			bg = Color(0.050, 0.050, 0.045, 0.92)
			border = Color(0.25, 0.22, 0.17, 0.80)
		"level_unlocked":
			bg = Color(0.120, 0.080, 0.045, 0.97)
			border = BORDER_COPPER
			width = _dim(2.0, ui_scale)
			shadow = 12.0
		"level_current":
			bg = Color(0.155, 0.105, 0.052, 0.99)
			border = ACCENT_GOLD
			width = _dim(3.0, ui_scale)
			shadow = 18.0
		"level_completed":
			bg = Color(0.100, 0.112, 0.070, 0.98)
			border = Color(0.66, 0.58, 0.30, 0.96)
			width = _dim(2.0, ui_scale)
			shadow = 14.0

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	style.shadow_size = _dim(shadow, ui_scale)
	style.shadow_offset = Vector2(0, _dim(3.0, ui_scale))
	return style


static func button_style(state: String = "normal", ui_scale: float = 1.0, variant: String = "default") -> StyleBoxFlat:
	var bg: Color = Color(0.115, 0.082, 0.050, 0.98)
	var border: Color = BORDER_COPPER
	if variant == "primary":
		bg = Color(0.150, 0.095, 0.043, 0.99)
		border = BORDER_GOLD
	elif variant == "quiet":
		bg = Color(0.072, 0.070, 0.060, 0.94)
		border = Color(0.40, 0.32, 0.20, 0.80)
	elif variant == "danger":
		bg = Color(0.125, 0.060, 0.045, 0.98)
		border = WARNING_RED

	match state:
		"hover":
			bg = bg.lightened(0.10)
			border = ACCENT_GOLD
		"pressed":
			bg = bg.darkened(0.12)
			border = Color(0.58, 0.40, 0.18, 0.95)
		"disabled":
			bg = Color(bg.r * 0.60, bg.g * 0.60, bg.b * 0.60, 0.54)
			border = Color(border.r * 0.55, border.g * 0.55, border.b * 0.55, 0.50)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(_dim(1.5, ui_scale))
	style.set_corner_radius_all(_dim(7.0, ui_scale))
	style.content_margin_left = _dim(10.0, ui_scale)
	style.content_margin_right = _dim(10.0, ui_scale)
	style.content_margin_top = _dim(6.0, ui_scale)
	style.content_margin_bottom = _dim(6.0, ui_scale)
	return style


static func apply_button(button: Button, ui_scale: float = 1.0, variant: String = "default") -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal", button_style("normal", ui_scale, variant))
	button.add_theme_stylebox_override("hover", button_style("hover", ui_scale, variant))
	button.add_theme_stylebox_override("pressed", button_style("pressed", ui_scale, variant))
	button.add_theme_stylebox_override("disabled", button_style("disabled", ui_scale, variant))
	button.add_theme_color_override("font_color", TEXT_MAIN)
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.88, 0.46, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.82, 0.70, 0.48, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.45, 0.43, 0.38, 0.85))


static func apply_label_color(label: Label, role: String = "main") -> void:
	if label == null:
		return
	match role:
		"title":
			label.modulate = Color(0.98, 0.86, 0.54, 1.0)
		"section":
			label.modulate = Color(0.86, 0.68, 0.36, 1.0)
		"muted":
			label.modulate = TEXT_MUTED
		"soft":
			label.modulate = TEXT_SOFT
		"blue":
			label.modulate = ACCENT_BLUE
		_:
			label.modulate = TEXT_MAIN


static func avatar_style(speaker_id: String = "", ui_scale: float = 1.0) -> StyleBoxFlat:
	var style: StyleBoxFlat = panel_style("compact", ui_scale)
	var tint: Color = Color(0.130, 0.095, 0.060, 1.0)
	if speaker_id.find("central") >= 0:
		tint = Color(0.065, 0.085, 0.090, 1.0)
	elif speaker_id.find("industry") >= 0:
		tint = Color(0.115, 0.085, 0.060, 1.0)
	elif speaker_id.find("livelihood") >= 0:
		tint = Color(0.075, 0.105, 0.065, 1.0)
	elif speaker_id.find("advisor") >= 0:
		tint = Color(0.075, 0.070, 0.105, 1.0)
	style.bg_color = tint
	style.border_color = BORDER_GOLD
	style.set_border_width_all(_dim(2.0, ui_scale))
	style.set_corner_radius_all(_dim(18.0, ui_scale))
	return style


static func hover_to(control: Control, target_scale: Vector2, seconds: float = 0.10) -> void:
	if control == null:
		return
	var tween: Tween = control.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", target_scale, seconds)


static func fade_in(control: CanvasItem, seconds: float = 0.20) -> void:
	if control == null:
		return
	control.modulate.a = 0.0
	var tween: Tween = control.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, seconds)


static func shake_control(control: Control, distance: float = 8.0, seconds: float = 0.22) -> void:
	if control == null:
		return
	var origin: Vector2 = control.position
	var tween: Tween = control.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(control, "position", origin + Vector2(distance, 0), seconds * 0.20)
	tween.tween_property(control, "position", origin - Vector2(distance, 0), seconds * 0.30)
	tween.tween_property(control, "position", origin + Vector2(distance * 0.45, 0), seconds * 0.25)
	tween.tween_property(control, "position", origin, seconds * 0.25)


static func _dim(value: float, ui_scale: float) -> int:
	return maxi(1, int(roundf(value * ui_scale)))
