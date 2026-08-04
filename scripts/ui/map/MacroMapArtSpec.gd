extends RefCounted

const DEBUG_BOUNDARIES: bool = false
const SHOW_REGION_OVERLAYS: bool = false
const REGION_LAYER_DEBUG_REGION: String = ""
const DEBUG_ALPHA_HIT_TEST: bool = false
const SHOW_PERMANENT_REGION_LABELS: bool = false

const MASTER_MAP_TEXTURE: String = "res://assets/art/map/macro_map_master_v2.webp"
const REGION_LAYER_TEXTURES := {
	"consumption": "res://assets/art/map/regions_v3/macro_map_region_consumption_v3.webp",
	"industry": "res://assets/art/map/regions_v3/macro_map_region_industry_v3.webp",
	"finance": "res://assets/art/map/regions_v3/macro_map_region_finance_v3.webp",
	"government": "res://assets/art/map/regions_v3/macro_map_region_government_v3.webp"
}
const REGION_MASK_TEXTURES := {
	"consumption": "res://assets/art/map/regions_v3/macro_map_mask_consumption_v3.png",
	"industry": "res://assets/art/map/regions_v3/macro_map_mask_industry_v3.png",
	"finance": "res://assets/art/map/regions_v3/macro_map_mask_finance_v3.png",
	"government": "res://assets/art/map/regions_v3/macro_map_mask_government_v3.png"
}
const REGION_LAYER_RECTS := {
	"consumption": Rect2(0.2509766, 0.1879883, 0.2994792, 0.2929688),
	"industry": Rect2(0.4736328, 0.1772461, 0.2792969, 0.3291016),
	"finance": Rect2(0.2542318, 0.4165039, 0.2467448, 0.3574219),
	"government": Rect2(0.4697266, 0.4594727, 0.2864583, 0.3242188)
}
const PREFERRED_ASPECT_RATIO: float = 3.0 / 2.0
const MINIMUM_SIZE: Vector2 = Vector2(540.0, 360.0)
const MAP_DRAW_SCALE: float = 1.12
const MAP_FULLSCREEN_OVERSCAN: float = 1.0
const MAP_EDGE_SAFE_INSET: Vector2 = Vector2(0.0, 4.0)
const MAP_CONTENT_RECT: Rect2 = Rect2(Vector2(0.245, 0.195), Vector2(0.510, 0.585))
const LABEL_REFERENCE_MAP_WIDTH: float = 540.0
const MASK_ALPHA_THRESHOLD: float = 0.45
const HOVER_SCALE: float = 1.03
const HOVER_ANIMATION_DURATION: float = 0.16
const HOVER_BRIGHTNESS: float = 1.16
const HOVER_TOOLTIP_OFFSET: Vector2 = Vector2(24.0, 4.0)
const MAP_MIN_ZOOM: float = 1.0
const MAP_MAX_ZOOM: float = 1.55
const MAP_ZOOM_FACTOR: float = 1.12
const MAP_ZOOM_ANIMATION_DURATION: float = 0.14

const NORMAL_TINT: Color = Color(0.08, 0.11, 0.12, 0.00)
const WARNING_TINT: Color = Color(0.95, 0.58, 0.32, 0.16)
const DANGER_TINT: Color = Color(0.28, 0.55, 0.72, 0.14)
const HIGHLIGHT_TINT: Color = Color(0.96, 0.78, 0.36, 0.14)
const OVERLAY_ALPHA_RANGE: Vector2 = Vector2(0.04, 0.22)

const REGION_SPECS := {
	"consumption": {
		"polygon": [
			Vector2(0.080, 0.135), Vector2(0.300, 0.045), Vector2(0.495, 0.095),
			Vector2(0.560, 0.455), Vector2(0.442, 0.548), Vector2(0.142, 0.575),
			Vector2(0.035, 0.405)
		],
		"label_rect": Rect2(Vector2(0.280, 0.385), Vector2(0.210, 0.070)),
		"variable_rect": Rect2(Vector2(0.325, 0.465), Vector2(0.120, 0.085)),
		"label_group_anchor": Vector2(0.370, 0.430),
		"label_anchor": Vector2(0.385, 0.420),
		"variable_anchor": Vector2(0.385, 0.505),
		"variable_row_spacing": 2.0,
		"arrow_reserved_width": 26.0,
		"region_tint_color": Color(0.96, 0.72, 0.34, 0.18),
		"highlight_strength": 0.18
	},
	"industry": {
		"polygon": [
			Vector2(0.510, 0.075), Vector2(0.875, 0.055), Vector2(0.972, 0.245),
			Vector2(0.945, 0.498), Vector2(0.672, 0.565), Vector2(0.565, 0.468)
		],
		"label_rect": Rect2(Vector2(0.690, 0.345), Vector2(0.190, 0.070)),
		"variable_rect": Rect2(Vector2(0.728, 0.425), Vector2(0.118, 0.120)),
		"label_group_anchor": Vector2(0.775, 0.405),
		"label_anchor": Vector2(0.785, 0.380),
		"variable_anchor": Vector2(0.785, 0.485),
		"variable_row_spacing": 2.0,
		"arrow_reserved_width": 26.0,
		"region_tint_color": Color(0.95, 0.42, 0.18, 0.18),
		"highlight_strength": 0.20
	},
	"finance": {
		"polygon": [
			Vector2(0.070, 0.598), Vector2(0.435, 0.558), Vector2(0.535, 0.815),
			Vector2(0.430, 0.935), Vector2(0.138, 0.902), Vector2(0.035, 0.725)
		],
		"label_rect": Rect2(Vector2(0.250, 0.680), Vector2(0.210, 0.070)),
		"variable_rect": Rect2(Vector2(0.320, 0.760), Vector2(0.100, 0.085)),
		"label_group_anchor": Vector2(0.355, 0.715),
		"label_anchor": Vector2(0.355, 0.715),
		"variable_anchor": Vector2(0.370, 0.800),
		"variable_row_spacing": 2.0,
		"arrow_reserved_width": 26.0,
		"region_tint_color": Color(0.40, 0.70, 0.58, 0.16),
		"highlight_strength": 0.17
	},
	"government": {
		"polygon": [
			Vector2(0.555, 0.580), Vector2(0.705, 0.545), Vector2(0.945, 0.520),
			Vector2(0.972, 0.805), Vector2(0.820, 0.935), Vector2(0.510, 0.850)
		],
		"label_rect": Rect2(Vector2(0.655, 0.675), Vector2(0.225, 0.070)),
		"variable_rect": Rect2(Vector2(0.700, 0.755), Vector2(0.165, 0.128)),
		"label_group_anchor": Vector2(0.748, 0.700),
		"label_anchor": Vector2(0.768, 0.710),
		"variable_anchor": Vector2(0.782, 0.820),
		"variable_row_spacing": 2.0,
		"arrow_reserved_width": 28.0,
		"region_tint_color": Color(0.34, 0.48, 0.78, 0.15),
		"highlight_strength": 0.18
	}
}


static func master_map_path() -> String:
	return MASTER_MAP_TEXTURE


static func region_spec(region_id: String) -> Dictionary:
	var spec: Dictionary = REGION_SPECS.get(region_id, {})
	return spec.duplicate(true)


static func all_region_ids() -> Array[String]:
	return ["consumption", "industry", "finance", "government"]


static func region_layer_rect(region_id: String) -> Rect2:
	return REGION_LAYER_RECTS.get(region_id, Rect2(Vector2.ZERO, Vector2.ONE)) as Rect2
