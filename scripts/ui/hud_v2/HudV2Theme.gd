extends RefCounted

const TEXT_TITLE := Color(0.95, 0.98, 1.0, 1.0)
const TEXT_BODY := Color(0.76, 0.82, 0.84, 0.98)
const TEXT_MUTED := Color(0.52, 0.60, 0.65, 0.95)
const ACCENT_SYSTEM := Color(0.41, 0.78, 0.91, 1.0)
const ACCENT_RESOURCE := Color(0.91, 0.73, 0.35, 1.0)
const STATUS_HIGH := Color(0.91, 0.41, 0.38, 1.0)
const STATUS_LOW := Color(0.33, 0.66, 0.91, 1.0)
const STATUS_NORMAL := Color(0.40, 0.79, 0.53, 1.0)
const STATUS_BALANCED := Color(0.85, 0.72, 0.29, 1.0)
const SURFACE := Color(0.018, 0.045, 0.057, 0.70)
const SURFACE_LIGHT := Color(0.034, 0.078, 0.095, 0.64)
const STROKE := Color(0.42, 0.76, 0.88, 0.38)
const STROKE_STRONG := Color(0.52, 0.86, 0.96, 0.74)
const SHADOW := Color(0.0, 0.0, 0.0, 0.36)


static func dim(value: float, ui_scale: float = 1.0) -> int:
	return maxi(1, int(roundf(value * ui_scale)))


static func font(value: int, ui_scale: float = 1.0) -> int:
	return maxi(11, int(roundf(float(value) * ui_scale)))


static func transparent_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color.TRANSPARENT
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	return style


static func chip_style(tone: String = "system", selected: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var accent: Color = ACCENT_RESOURCE if tone == "resource" else ACCENT_SYSTEM
	style.bg_color = Color(0.018, 0.052, 0.066, 0.44 if not selected else 0.62)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.18 if not selected else 0.48)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	style.shadow_color = Color(0, 0, 0, 0.16)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 1)
	return style


static func button_style(state: String = "normal", variant: String = "primary") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var accent: Color = ACCENT_SYSTEM
	if variant == "confirm":
		accent = ACCENT_RESOURCE
	var alpha := 0.24
	if state == "hover":
		alpha = 0.42
	elif state == "pressed":
		alpha = 0.58
	elif state == "disabled":
		alpha = 0.10
	style.bg_color = Color(accent.r * 0.13, accent.g * 0.17, accent.b * 0.19, alpha)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.22 if state != "disabled" else 0.08)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	style.shadow_color = Color(0, 0, 0, 0.14)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 1)
	return style


static func apply_button(button: Button, ui_scale: float = 1.0, variant: String = "primary") -> void:
	button.add_theme_stylebox_override("normal", button_style("normal", variant))
	button.add_theme_stylebox_override("hover", button_style("hover", variant))
	button.add_theme_stylebox_override("pressed", button_style("pressed", variant))
	button.add_theme_stylebox_override("disabled", button_style("disabled", variant))
	button.add_theme_color_override("font_color", TEXT_TITLE if variant == "confirm" else TEXT_BODY)
	button.add_theme_color_override("font_hover_color", TEXT_TITLE)
	button.add_theme_color_override("font_pressed_color", TEXT_TITLE)
	button.add_theme_color_override("font_disabled_color", Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.48))
	button.add_theme_font_size_override("font_size", font(15, ui_scale))


static func status_color(status_text: String, score: float = 0.0) -> Color:
	if status_text.find("偏高") >= 0 or status_text.find("过热") >= 0 or score > 0.15:
		return STATUS_HIGH
	if status_text.find("偏低") >= 0 or score < -0.15:
		return STATUS_LOW
	if status_text.find("正常") >= 0:
		return STATUS_NORMAL
	return STATUS_BALANCED
