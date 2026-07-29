extends RefCounted

const TITLE := Color(0.94, 0.98, 1.0, 1.0)
const BODY := Color(0.76, 0.82, 0.84, 0.98)
const MUTED := Color(0.48, 0.58, 0.64, 0.94)
const CYAN := Color(0.38, 0.82, 0.96, 1.0)
const CYAN_SOFT := Color(0.30, 0.66, 0.82, 0.72)
const GOLD := Color(0.91, 0.72, 0.34, 1.0)
const GREEN := Color(0.36, 0.78, 0.52, 1.0)
const YELLOW := Color(0.86, 0.72, 0.30, 1.0)
const RED := Color(0.90, 0.38, 0.35, 1.0)
const BLUE := Color(0.34, 0.64, 0.92, 1.0)
const PANEL_DARK := Color(0.006, 0.020, 0.028, 0.74)
const PANEL_MID := Color(0.016, 0.052, 0.068, 0.52)
const GLASS := Color(0.28, 0.70, 0.86, 0.055)


static func dim(value: float, scale: float = 1.0) -> int:
	return maxi(1, int(roundf(value * scale)))


static func font(value: int, scale: float = 1.0) -> int:
	return maxi(10, int(roundf(float(value) * scale)))


static func status_color(status: String) -> Color:
	if status.find("偏高") >= 0:
		return RED
	if status.find("偏低") >= 0:
		return BLUE
	if status.find("正常") >= 0:
		return GREEN
	return YELLOW


static func add_text_shadow(label: Label, alpha: float = 0.48) -> void:
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, alpha))
