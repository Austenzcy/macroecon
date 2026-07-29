extends RefCounted

const UI_FONT: FontFile = preload("res://assets/fonts/NotoSansSC-Regular.ttf")

const TEXT_PRIMARY := Color("#F4F7F9")
const TEXT_BODY := Color("#D3DDE2")
const TEXT_MUTED := Color("#9FB1BC")
const TEXT_CYAN := Color("#72D4F1")
const TEXT_GOLD := Color("#F0C45C")
const TEXT_GREEN := Color("#65D694")
const TEXT_YELLOW := Color("#E0C052")
const TEXT_RED := Color("#EE6A66")
const TEXT_BLUE := Color("#62B5EE")
const TEXT_DISABLED := Color("#708089")

const TITLE := TEXT_PRIMARY
const BODY := TEXT_BODY
const MUTED := TEXT_MUTED
const CYAN := TEXT_CYAN
const CYAN_SOFT := Color(0.38, 0.82, 0.96, 0.72)
const GOLD := TEXT_GOLD
const GREEN := TEXT_GREEN
const YELLOW := TEXT_YELLOW
const RED := TEXT_RED
const BLUE := TEXT_BLUE

const PANEL_DARK := Color(0.006, 0.020, 0.028, 0.74)
const PANEL_MID := Color(0.016, 0.052, 0.068, 0.52)
const GLASS := Color(0.28, 0.70, 0.86, 0.055)

const WEIGHT_REGULAR := "regular"
const WEIGHT_MEDIUM := "medium"
const WEIGHT_SEMIBOLD := "semibold"

const FONT_CHALLENGE_KICKER := 15
const FONT_CHALLENGE_TITLE := 29
const FONT_CHALLENGE_MECHANISM := 16
const FONT_ROUND := 25
const FONT_MODEL_TAG := 14
const FONT_TOP_META := 15
const FONT_RESOURCE_LABEL := 15
const FONT_RESOURCE_VALUE := 18
const FONT_TOP_ACTION := 15
const FONT_DRAWER_TITLE := 26
const FONT_DRAWER_SUBTITLE := 15
const FONT_POLICY_TITLE := 18
const FONT_POLICY_DESCRIPTION := 15
const FONT_POLICY_COST := 16
const FONT_CURRENT_PROBLEM := 20
const FONT_METRIC_NAME := 16
const FONT_METRIC_VALUE := 17
const FONT_METRIC_STATUS := 15
const FONT_REFERENCE_LABEL := 13
const FONT_ACTION_HEADING := 15
const FONT_ACTION_BODY := 15
const FONT_CONFIRM_BUTTON := 18
const FONT_ANALYSIS_TITLE := 21
const FONT_ANALYSIS_HINT := 15
const FONT_CHART_AXIS := 14
const FONT_DONUT_CENTER_TITLE := 22
const FONT_DONUT_CENTER_VALUE := 16
const FONT_DONUT_LEGEND := 15


static func dim(value: float, scale: float = 1.0) -> int:
	return maxi(1, int(roundf(value * scale)))


static func font(value: int, scale: float = 1.0, minimum: int = -1) -> int:
	var floor_size: int = _minimum_for_font(value) if minimum < 0 else minimum
	return maxi(floor_size, int(roundf(float(value) * scale)))


static func status_color(status: String) -> Color:
	if status.find("偏高") >= 0:
		return TEXT_RED
	if status.find("偏低") >= 0:
		return TEXT_BLUE
	if status.find("正常") >= 0:
		return TEXT_GREEN
	return TEXT_YELLOW


static func apply_label_font(label: Label, font_size: int, color: Color, scale: float, weight: String = WEIGHT_REGULAR, glow: Color = Color.TRANSPARENT) -> void:
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", font(font_size, scale))
	label.add_theme_color_override("font_color", color)
	if glow.a > 0.0:
		label.add_theme_constant_override("outline_size", 1)
		label.add_theme_color_override("font_outline_color", Color(glow.r, glow.g, glow.b, minf(glow.a, 0.22)))
		return
	if weight == WEIGHT_SEMIBOLD:
		add_text_shadow(label, 0.60)
	elif weight == WEIGHT_MEDIUM:
		add_text_shadow(label, 0.42)
	else:
		label.add_theme_constant_override("outline_size", 0)
		label.add_theme_color_override("font_outline_color", Color.TRANSPARENT)


static func add_text_shadow(label: Label, alpha: float = 0.48) -> void:
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, alpha))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, alpha * 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)


static func _minimum_for_font(value: int) -> int:
	if value >= FONT_CHALLENGE_TITLE:
		return 25
	if value >= FONT_DRAWER_TITLE:
		return 22
	if value == FONT_POLICY_TITLE:
		return 16
	if value == FONT_POLICY_DESCRIPTION:
		return 14
	if value == FONT_METRIC_NAME:
		return 14
	if value == FONT_METRIC_VALUE:
		return 15
	if value == FONT_METRIC_STATUS:
		return 14
	if value == FONT_CHART_AXIS:
		return 12
	if value >= 15:
		return 14
	return 12
