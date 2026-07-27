extends RefCounted

const UI_SCALE_MIN: float = 0.50
const UI_SCALE_DEFAULT: float = 1.00
const UI_SCALE_MAX: float = 1.50
const UI_SCALE_STEP: float = 0.05

const SCROLL_TARGET_DIVISIONS: float = 6.5
const SCROLL_MIN_STEP: float = 42.0
const SCROLL_MAX_STEP: float = 170.0
const SCROLL_SMOOTH_DURATION: float = 0.14


static func normalized_scale(value: float) -> float:
	var min_step: int = int(roundf(UI_SCALE_MIN / UI_SCALE_STEP))
	var max_step: int = int(roundf(UI_SCALE_MAX / UI_SCALE_STEP))
	var step_index: int = clampi(int(roundf(value / UI_SCALE_STEP)), min_step, max_step)
	return float(roundi(float(step_index) * UI_SCALE_STEP * 100.0)) / 100.0
