extends RefCounted

const DEBUG_SAFE_AREAS := false

const SAFE_SPEAKER := "speaker_rect"
const SAFE_BODY := "body_rect"
const SAFE_CONTINUE := "continue_rect"
const SAFE_PORTRAIT_OVERLAP := "portrait_overlap_rect"
const SAFE_FRAME_CONTENT := "frame_content_rect"

const SAFE_TITLE := "title_rect"
const SAFE_CATEGORY := "category_rect"
const SAFE_DESCRIPTION := "description_rect"
const SAFE_COST := "cost_rect"
const SAFE_ILLUSTRATION := "illustration_rect"
const SAFE_CARD_CONTENT := "card_content_rect"


static func dialogue_frame_spec() -> Dictionary:
	return {
		SAFE_FRAME_CONTENT: Rect2(0.030, 0.080, 0.920, 0.820),
		SAFE_PORTRAIT_OVERLAP: Rect2(0.000, -0.440, 0.235, 1.420),
		SAFE_SPEAKER: Rect2(0.188, 0.125, 0.455, 0.145),
		SAFE_BODY: Rect2(0.232, 0.405, 0.600, 0.325),
		SAFE_CONTINUE: Rect2(0.705, 0.725, 0.170, 0.130),
		"speaker_font_min": 27,
		"speaker_font_max": 34,
		"speaker_font_viewport_ratio": 0.035,
		"body_font_min": 19,
		"body_font_max": 23,
		"body_font_viewport_ratio": 0.025,
		"body_line_separation_min": 7,
		"body_line_separation_max": 10,
		"continue_font_min": 13,
		"continue_font_max": 16,
		"continue_font_viewport_ratio": 0.017
	}


static func default_policy_card_spec() -> Dictionary:
	return {
		SAFE_CARD_CONTENT: Rect2(0.055, 0.040, 0.890, 0.905),
		SAFE_ILLUSTRATION: Rect2(0.095, 0.210, 0.810, 0.425),
		SAFE_TITLE: Rect2(0.105, 0.103, 0.790, 0.095),
		SAFE_CATEGORY: Rect2(0.245, 0.646, 0.510, 0.064),
		SAFE_DESCRIPTION: Rect2(0.125, 0.708, 0.585, 0.170),
		SAFE_COST: Rect2(0.745, 0.786, 0.178, 0.128),
		"title_font": 22,
		"category_font": 12,
		"description_font": 15,
		"description_line_spacing": 4,
		"cost_font": 31,
		"type_icon_size": 18,
		"stamp_font": 14
	}


static func policy_card_spec(policy_id: String, _card_art_key: String = "") -> Dictionary:
	var spec := default_policy_card_spec()
	match policy_id:
		"expansionary_monetary_policy":
			spec[SAFE_TITLE] = Rect2(0.105, 0.108, 0.790, 0.095)
			spec[SAFE_CATEGORY] = Rect2(0.255, 0.640, 0.490, 0.064)
			spec[SAFE_DESCRIPTION] = Rect2(0.125, 0.700, 0.585, 0.172)
			spec[SAFE_COST] = Rect2(0.748, 0.780, 0.176, 0.130)
		"tax_cut":
			spec[SAFE_DESCRIPTION] = Rect2(0.125, 0.704, 0.585, 0.172)
		"keep_policy_unchanged":
			spec[SAFE_DESCRIPTION] = Rect2(0.125, 0.706, 0.585, 0.170)
	return spec


static func rect_to_margins(rect: Rect2, total_size: Vector2) -> Dictionary:
	var left := int(roundf(rect.position.x * total_size.x))
	var top := int(roundf(rect.position.y * total_size.y))
	var right := int(roundf((1.0 - rect.position.x - rect.size.x) * total_size.x))
	var bottom := int(roundf((1.0 - rect.position.y - rect.size.y) * total_size.y))
	return {
		"left": maxi(left, 0),
		"top": maxi(top, 0),
		"right": maxi(right, 0),
		"bottom": maxi(bottom, 0)
	}


static func apply_margin_rect(control: MarginContainer, rect: Rect2, total_size: Vector2) -> void:
	var margins := rect_to_margins(rect, total_size)
	control.add_theme_constant_override("margin_left", margins["left"])
	control.add_theme_constant_override("margin_top", margins["top"])
	control.add_theme_constant_override("margin_right", margins["right"])
	control.add_theme_constant_override("margin_bottom", margins["bottom"])


static func apply_anchor_rect(control: Control, rect: Rect2) -> void:
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.position.x + rect.size.x
	control.anchor_bottom = rect.position.y + rect.size.y
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE


static func scaled_int(spec: Dictionary, key: String, ui_scale: float) -> int:
	return int(roundf(float(spec.get(key, 0)) * ui_scale))
