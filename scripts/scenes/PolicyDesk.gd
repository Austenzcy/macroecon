extends Control

const MacroEngine = preload("res://scripts/engine/MacroEngine.gd")
const ISLMDemandComponents = preload("res://scripts/engine/ISLMDemandComponents.gd")
const ISLMReplayPanelScene = preload("res://scenes/components/ISLMReplayPanel.tscn")
const UnifiedMacroMapScene = preload("res://scenes/components/GlobeMacroMap.tscn")
const HudV2Theme = preload("res://scripts/ui/hud_v2/HudV2Theme.gd")
const HudPanelShapeScript = preload("res://scripts/ui/hud_v2/HudPanelShape.gd")
const HudIconScript = preload("res://scripts/ui/hud_v2/HudIcon.gd")
const ResourceChipV2Script = preload("res://scripts/ui/hud_v2/ResourceChipV2.gd")
const PolicyOptionV2Script = preload("res://scripts/ui/hud_v2/PolicyOptionV2.gd")
const MacroIndicatorRowV2Script = preload("res://scripts/ui/hud_v2/MacroIndicatorRowV2.gd")
const TheoryPanelV2Script = preload("res://scripts/ui/hud_v2/TheoryPanelV2.gd")
const ClassicalTheme = preload("res://scripts/ui/ClassicalTheme.gd")
const ArtAssetRegistry = preload("res://scripts/ui/ArtAssetRegistry.gd")
const UIInteractionConfig = preload("res://scripts/ui/UIInteractionConfig.gd")
const BASE_CONTENT_SIZE: Vector2 = Vector2(1220.0, 900.0)
const OUTER_MARGIN_X: int = 48
const OUTER_MARGIN_TOP: int = 48
const OUTER_MARGIN_BOTTOM: int = 144
const HUD_MARGIN: float = 12.0
const HUD_TOP_HEIGHT: float = 106.0
const HUD_SIDE_TOP: float = 126.0
const HUD_SIDE_WIDTH: float = 324.0
const HUD_RIGHT_WIDTH: float = 328.0
const HUD_BOTTOM_HEIGHT: float = 124.0
const HUD_THEORY_HEIGHT: float = 212.0
const HUD_CENTER_GAP: float = 12.0
const STAT_DISPLAY_DEFAULTS: Dictionary = {
	"Y": {"display_min": 80.0, "display_max": 130.0, "reference_value": 110.0},
	"u": {"display_min": 2.0, "display_max": 10.0, "reference_value": 4.5},
	"π": {"display_min": 0.0, "display_max": 6.0, "reference_value": 2.0},
	"i": {"display_min": 0.0, "display_max": 8.0, "reference_value": 4.0},
	"Debt": {"display_min": 40.0, "display_max": 90.0, "reference_value": 60.0}
}
const MAP_REGION_CONFIGS: Array[Dictionary] = [
	{"name": "居民消费区", "variables": ["C"], "weights": {"C": 1.0}},
	{"name": "工业产区", "variables": ["Y", "I"], "weights": {"Y": 0.7, "I": 0.3}},
	{"name": "金融市场区", "variables": ["i"], "weights": {"i": 1.0}},
	{"name": "政府部门区", "variables": ["G", "Debt"], "weights": {"G": 1.0}}
]

var _policy_cards: Array[Node] = []
var _advisor_panel: PanelContainer
var _main_scroll: ScrollContainer
var _outer_margin: MarginContainer
var _content_margin: MarginContainer
var _right_panel_box: VBoxContainer
var _right_panel: PanelContainer
var _problem_panel: PanelContainer
var _policy_column: VBoxContainer
var _map_panel: Control
var _theory_panel: PanelContainer
var _unified_macro_map: Control
var _hud_blockers: Array[Control] = []
var _replay_overlay: Control
var _confirm_button: Button
var _model_replay_button: Button
var _summary_button: Button
var _policy_points_label: Label
var _wisdom_label: Label
var _wisdom_chip: Control
var _top_policy_points_chip: Control
var _request_hint_button: Button
var _review_hint_button: Button
var _left_hud_panel: PanelContainer
var _right_hud_panel: PanelContainer
var _left_drawer_collapsed: bool = false
var _right_drawer_collapsed: bool = false
var _scenario: Dictionary = {}
var _selected_policies: Array[Dictionary] = []
var _last_result: Dictionary = {}
var _is_policy_confirmed: bool = false
var _is_replay_open: bool = false
var _ui_scale: float = 1.0
var _guide_targets: Dictionary = {}
var _target_scroll_y: float = 0.0
var _scroll_tween: Tween


func _ready() -> void:
	_scenario = _get_current_scenario()
	if not NarrativeManager.wisdom_points_changed.is_connected(_refresh_wisdom_ui):
		NarrativeManager.wisdom_points_changed.connect(_refresh_wisdom_ui)
	_selected_policies.clear()
	if GameState.consume_return_to_confirmed_policy_desk() and not GameState.last_result.is_empty():
		_last_result = GameState.last_result.duplicate(true)
		_selected_policies = _executed_policies_from_result(_last_result)
		_is_policy_confirmed = true
	else:
		GameState.clear_selection()
		_is_policy_confirmed = false
		_last_result = {}
	_ui_scale = 1.0
	GameState.set_ui_scale(_ui_scale)
	_build_ui()
	call_deferred("_refresh_initial_layout")
	call_deferred("_maybe_start_policy_desk_guides")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if _is_gameplay_input_blocked():
			return
		var is_wheel: bool = mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN
		if is_wheel and mouse_event.ctrl_pressed:
			get_viewport().set_input_as_handled()
			return
		if _replay_overlay != null and is_wheel:
			return
		_forward_map_input(event)
	elif event is InputEventMouseMotion:
		if _is_gameplay_input_blocked():
			return
		_forward_map_input(event)


func _build_ui() -> void:
	_policy_cards.clear()
	_advisor_panel = null
	_main_scroll = null
	_right_panel_box = null
	_right_panel = null
	_problem_panel = null
	_policy_column = null
	_map_panel = null
	_theory_panel = null
	_unified_macro_map = null
	_replay_overlay = null
	_confirm_button = null
	_model_replay_button = null
	_summary_button = null
	_policy_points_label = null
	_wisdom_label = null
	_wisdom_chip = null
	_top_policy_points_chip = null
	_request_hint_button = null
	_review_hint_button = null
	_left_hud_panel = null
	_right_hud_panel = null
	_outer_margin = null
	_content_margin = null
	_hud_blockers.clear()
	_guide_targets.clear()

	for child: Node in get_children():
		remove_child(child)
		child.queue_free()

	var background: ColorRect = ColorRect.new()
	background.color = ClassicalTheme.BG_DEEP
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	add_child(_build_fullscreen_map_layer())

	var hud_root: Control = Control.new()
	hud_root.name = "GameplayHudRoot"
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(hud_root)

	hud_root.add_child(_build_top_hud())
	hud_root.add_child(_build_policy_hud())
	hud_root.add_child(_build_right_column())
	hud_root.add_child(_build_theory_panel())

	if _is_policy_confirmed:
		_show_policy_result_panel(_last_result)
	else:
		_show_current_state_panel()

	if _is_replay_open:
		_open_replay_overlay()
	_register_guide_targets()


func _build_fullscreen_map_layer() -> Control:
	var layer: Control = Control.new()
	layer.name = "FullscreenMacroMapLayer"
	_map_panel = layer
	layer.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)

	var map_state: Dictionary = _visible_macro_state()
	var map_view: Control = _build_macro_map_view(map_state)
	map_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_view.offset_left = 0
	map_view.offset_top = 0
	map_view.offset_right = 0
	map_view.offset_bottom = 0
	map_view.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(map_view)
	return layer



func _build_top_hud() -> PanelContainer:
	var panel: PanelContainer = HudPanelShapeScript.new() as PanelContainer
	panel.name = "TopHud"
	panel.call("set_shape_kind", "top_challenge")
	_problem_panel = panel
	_register_hud_blocker(panel)
	_apply_hud_rect(panel, _hud_margin(), _hud_margin(), -_hud_margin(), _hud_margin() + _top_hud_height())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dim(20))
	margin.add_theme_constant_override("margin_top", _dim(8))
	margin.add_theme_constant_override("margin_right", _dim(18))
	margin.add_theme_constant_override("margin_bottom", _dim(8))
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _dim(14))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(row)

	var scenario: Dictionary = _get_current_scenario()
	var challenge_box := VBoxContainer.new()
	challenge_box.custom_minimum_size = Vector2(_dim(315), 0)
	challenge_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	challenge_box.size_flags_stretch_ratio = 0.95
	challenge_box.add_theme_constant_override("separation", _dim(2))
	row.add_child(challenge_box)
	_add_micro_label(challenge_box, "当前挑战", HudV2Theme.ACCENT_SYSTEM, 12)
	_add_single_line_label(challenge_box, str(scenario.get("problem_title", "消费信心下降")), HudV2Theme.TEXT_TITLE, 24, TextServer.OVERRUN_TRIM_ELLIPSIS)
	_add_single_line_label(challenge_box, _compact_mechanism_line(scenario), HudV2Theme.TEXT_BODY, 13, TextServer.OVERRUN_TRIM_ELLIPSIS)

	var center_box := VBoxContainer.new()
	center_box.custom_minimum_size = Vector2(_dim(390), 0)
	center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_box.size_flags_stretch_ratio = 1.0
	center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center_box.add_theme_constant_override("separation", _dim(6))
	row.add_child(center_box)

	var round_label := Label.new()
	round_label.text = "回合 %d / %d" % [GameState.current_round, GameState.max_rounds]
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_label.add_theme_font_size_override("font_size", _font(20))
	round_label.add_theme_constant_override("outline_size", 1)
	round_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.38))
	round_label.modulate = HudV2Theme.TEXT_TITLE
	center_box.add_child(round_label)
	center_box.add_child(_build_model_tag_row(_top_hud_tags(scenario)))

	var right_box := HBoxContainer.new()
	right_box.custom_minimum_size = Vector2(_dim(445), 0)
	right_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_box.size_flags_stretch_ratio = 1.0
	right_box.alignment = BoxContainer.ALIGNMENT_END
	right_box.add_theme_constant_override("separation", _dim(7))
	row.add_child(right_box)
	right_box.add_child(_build_time_label())
	right_box.add_child(_build_wisdom_panel())
	right_box.add_child(_build_top_policy_points_chip())
	right_box.add_child(_build_hud_icon_button("hint", "提示", Callable(self, "_on_request_hint_pressed")))
	right_box.add_child(_build_hud_icon_button("review", "回看", Callable(self, "_on_review_hint_pressed")))

	return panel

func _build_policy_hud() -> PanelContainer:
	var panel: PanelContainer = HudPanelShapeScript.new() as PanelContainer
	panel.name = "PolicyHudV2"
	panel.call("set_shape_kind", "left_drawer")
	_left_hud_panel = panel
	var margin_size: int = _hud_margin()
	var side_width: int = _left_hud_width()
	var top_y: int = _side_top_y()
	_apply_hud_rect(panel, margin_size, top_y, margin_size + side_width, -margin_size)
	_register_hud_blocker(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dim(10))
	margin.add_theme_constant_override("margin_top", _dim(10))
	margin.add_theme_constant_override("margin_right", _dim(16))
	margin.add_theme_constant_override("margin_bottom", _dim(10))
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", _dim(8))
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", _dim(6))
	root.add_child(header)
	_add_panel_title(header, "政策卡")
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	header.add_child(_build_drawer_toggle_button("collapse_left", Callable(self, "_toggle_left_drawer")))

	_policy_points_label = Label.new()
	_policy_points_label.name = "PolicyPointsArea"
	_policy_points_label.text = _policy_points_text()
	_policy_points_label.modulate = HudV2Theme.ACCENT_RESOURCE
	_policy_points_label.add_theme_font_size_override("font_size", _font(14))
	root.add_child(_policy_points_label)
	_add_wrapped_label(root, _policy_points_hint_text(), HudV2Theme.TEXT_MUTED, 11)

	var policy_column: VBoxContainer = _build_policy_column()
	policy_column.custom_minimum_size = Vector2(maxf(1.0, float(side_width - _dim(26))), 0.0)
	policy_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	policy_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(policy_column)
	return panel

func _top_hud_tags(scenario: Dictionary) -> Array[String]:
	var tags: Array[String] = []
	var raw_tags: Variant = scenario.get("model_tags", [])
	if raw_tags is Array:
		for item: Variant in raw_tags:
			var tag: String = str(item)
			if not tag.is_empty():
				tags.append(tag)
	var problem_tag: String = str(scenario.get("problem_tag", scenario.get("shock_tag", "")))
	if problem_tag.is_empty():
		problem_tag = "需求不足" if _state_score("Y", GameState.get_current_state()) < -0.15 else str(scenario.get("problem_title", "当前问题"))
	if not problem_tag.is_empty() and tags.find(problem_tag) == -1:
		tags.append(problem_tag)
	return tags


func _compact_mechanism_line(scenario: Dictionary) -> String:
	var hint: String = str(scenario.get("model_hint", "")).strip_edges()
	if hint.is_empty():
		return "核心变量变化会影响总需求，并通过 IS-LM 改变产出与利率。"
	hint = hint.replace("机制提示：", "")
	return hint

func _add_micro_label(parent: Control, text: String, color: Color, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.modulate = color
	label.add_theme_font_size_override("font_size", _font(font_size))
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	parent.add_child(label)
	return label


func _add_single_line_label(parent: Control, text: String, color: Color, font_size: int, overrun: TextServer.OverrunBehavior = TextServer.OVERRUN_TRIM_ELLIPSIS) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.modulate = color
	label.add_theme_font_size_override("font_size", _font(font_size))
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = overrun
	label.clip_text = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label


func _build_time_label() -> PanelContainer:
	var chip: PanelContainer = ResourceChipV2Script.new() as PanelContainer
	chip.call("setup", "review", "季度", NarrativeManager.get_current_quarter_label(GameState.current_scenario_id), "system")
	return chip


func _build_wisdom_panel() -> PanelContainer:
	var chip: PanelContainer = ResourceChipV2Script.new() as PanelContainer
	chip.name = "WisdomPanel"
	chip.call("setup", "wisdom", "智慧点", str(NarrativeManager.get_wisdom_points()), "resource")
	_wisdom_chip = chip
	_wisdom_label = chip.call("get_label_control") as Label
	_refresh_wisdom_ui()
	return chip


func _build_top_policy_points_chip() -> PanelContainer:
	var chip: PanelContainer = ResourceChipV2Script.new() as PanelContainer
	chip.name = "TopPolicyPointsChip"
	chip.call("setup", "policy_point", "政策点", _policy_points_value_text(), "resource")
	_top_policy_points_chip = chip
	return chip


func _build_hud_icon_button(icon_type: String, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = "    %s" % text
	button.custom_minimum_size = Vector2(_dim(68), _dim(34))
	button.add_theme_font_size_override("font_size", _font(13))
	HudV2Theme.apply_button(button, _ui_scale, "primary")
	button.pressed.connect(callback)
	var icon: Control = HudIconScript.new() as Control
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.call("setup", icon_type, HudV2Theme.ACCENT_SYSTEM, 1.5)
	icon.anchor_left = 0.0
	icon.anchor_top = 0.5
	icon.anchor_right = 0.0
	icon.anchor_bottom = 0.5
	icon.offset_left = _dim(9)
	icon.offset_top = -_dim(9)
	icon.offset_right = _dim(27)
	icon.offset_bottom = _dim(9)
	button.add_child(icon)
	if icon_type == "hint":
		_request_hint_button = button
	elif icon_type == "review":
		_review_hint_button = button
	return button


func _build_drawer_toggle_button(icon_type: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(_dim(30), _dim(30))
	button.add_theme_font_size_override("font_size", _font(18))
	HudV2Theme.apply_button(button, _ui_scale, "primary")
	button.pressed.connect(callback)
	var icon: Control = HudIconScript.new() as Control
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.call("setup", icon_type, HudV2Theme.ACCENT_SYSTEM, 1.6)
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = _dim(6)
	icon.offset_top = _dim(6)
	icon.offset_right = -_dim(6)
	icon.offset_bottom = -_dim(6)
	button.add_child(icon)
	return button


func _build_model_tag_row(tags: Array[String]) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", _dim(6))
	for tag in tags:
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", HudV2Theme.chip_style("system"))
		chip.custom_minimum_size = Vector2(_dim(72), _dim(24))
		var label := Label.new()
		label.text = tag
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", _font(12))
		label.modulate = HudV2Theme.ACCENT_SYSTEM
		chip.add_child(label)
		row.add_child(chip)
	return row

func _build_problem_banner() -> PanelContainer:
	var scenario: Dictionary = _get_current_scenario()
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "ProblemPanel"
	_problem_panel = panel
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_problem_panel_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dim(18))
	margin.add_theme_constant_override("margin_top", _dim(10))
	margin.add_theme_constant_override("margin_right", _dim(18))
	margin.add_theme_constant_override("margin_bottom", _dim(10))
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", _dim(3))
	margin.add_child(box)

	_add_wrapped_label(box, "第 %d 回合 / 共 %d 回合" % [GameState.current_round, GameState.max_rounds], Color(0.92, 0.80, 0.46), 16)
	_add_wrapped_label(box, "当前问题", Color(0.62, 0.84, 1.0), 17)
	_add_wrapped_label(box, "%s：%s" % [
		str(scenario.get("problem_title", "消费信心下降")),
		str(scenario.get("problem_description", "居民消费不足，经济面临需求偏弱压力。"))
	], Color(0.96, 0.98, 1.0), 20)
	_add_wrapped_label(box, str(scenario.get("model_hint", "核心变量：C ↓，总需求下降")), Color(0.80, 0.90, 0.82), 16)

	return panel


func _build_policy_column() -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.name = "PolicyCardsArea"
	_policy_column = column
	column.custom_minimum_size = Vector2(_dim(180), 0.0)
	column.add_theme_constant_override("separation", _dim(7))

	var policies: Array[Dictionary] = _available_policy_entries()
	var compact_scale: float = _policy_card_ui_scale(policies.size())
	for policy_data: Dictionary in policies:
		var card: PanelContainer = PolicyOptionV2Script.new() as PanelContainer
		card.call("setup", policy_data, _policy_cost(policy_data), compact_scale)
		card.call("set_selected", _is_policy_selected(str(policy_data.get("id", ""))))
		card.connect("selected", _on_policy_selected)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_policy_cards.append(card)
		column.add_child(card)

	return column

func _build_map_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "MacroMapPanel"
	_map_panel = panel
	panel.custom_minimum_size = Vector2(_dim(580), _dim(900))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_map_panel_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dim(10))
	margin.add_theme_constant_override("margin_top", _dim(12))
	margin.add_theme_constant_override("margin_right", _dim(10))
	margin.add_theme_constant_override("margin_bottom", _dim(10))
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", _dim(10))
	margin.add_child(box)

	var map_state: Dictionary = _visible_macro_state()
	box.add_child(_build_map_section(map_state))

	_theory_panel = _build_theory_panel()
	_theory_panel.name = "TheoryPanel"
	_theory_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_theory_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_theory_panel.size_flags_stretch_ratio = 0.95
	_theory_panel.visible = true
	box.add_child(_theory_panel)

	return panel


func _build_map_section(map_state: Dictionary) -> PanelContainer:
	var section: PanelContainer = PanelContainer.new()
	section.name = "MapSection"
	section.custom_minimum_size = Vector2(_dim(0), _dim(430))
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	section.size_flags_stretch_ratio = 1.05
	section.add_theme_stylebox_override("panel", _make_theory_panel_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dim(10))
	margin.add_theme_constant_override("margin_top", _dim(8))
	margin.add_theme_constant_override("margin_right", _dim(10))
	margin.add_theme_constant_override("margin_bottom", _dim(8))
	section.add_child(margin)

	var map_view: Control = _build_macro_map_view(map_state)
	map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(map_view)
	return section


func _build_macro_map_view(map_state: Dictionary) -> Control:
	var unified_map: Control = UnifiedMacroMapScene.instantiate() as Control
	_unified_macro_map = unified_map
	unified_map.name = "UnifiedMacroMap"
	unified_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unified_map.custom_minimum_size = Vector2(_dim(540), _dim(413))
	if unified_map.has_method("set_ui_scale"):
		unified_map.call("set_ui_scale", _ui_scale)
	if unified_map.has_method("set_regions"):
		unified_map.call("set_regions", _unified_map_region_data(map_state))
	return unified_map


func _build_legacy_map_grid(map_state: Dictionary) -> GridContainer:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.custom_minimum_size = Vector2(_dim(500), _dim(310))
	grid.add_theme_constant_override("h_separation", _dim(14))
	grid.add_theme_constant_override("v_separation", _dim(14))

	var region_scene: PackedScene = preload("res://scenes/components/MapRegion.tscn")
	var region_icon_keys: Array[String] = ["consumption", "industry", "finance", "government"]
	var region_index: int = 0
	for config: Dictionary in MAP_REGION_CONFIGS:
		var region: PanelContainer = region_scene.instantiate() as PanelContainer
		region.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		region.size_flags_vertical = Control.SIZE_EXPAND_FILL
		region.call("set_ui_scale", _ui_scale)
		region.call(
			"set_region_data",
			str(config.get("name", "区域")),
			_map_region_lines(config, map_state),
			_map_region_brightness(config, map_state)
		)
		if region.has_method("set_region_icon_key"):
			region.call("set_region_icon_key", region_icon_keys[min(region_index, region_icon_keys.size() - 1)])
		grid.add_child(region)
		region_index += 1
	return grid


func _unified_map_region_data(map_state: Dictionary) -> Array[Dictionary]:
	var region_ids: Array[String] = ["consumption", "industry", "finance", "government"]
	var regions: Array[Dictionary] = []
	for index: int in range(MAP_REGION_CONFIGS.size()):
		var config: Dictionary = MAP_REGION_CONFIGS[index]
		regions.append({
			"region_id": region_ids[min(index, region_ids.size() - 1)],
			"name": str(config.get("name", "区域")),
			"lines": _map_region_lines(config, map_state),
			"brightness": _map_region_brightness(config, map_state)
		})
	return regions


func _refresh_unified_macro_map(map_state: Dictionary) -> void:
	if _unified_macro_map == null or not is_instance_valid(_unified_macro_map):
		return
	if _unified_macro_map.has_method("set_regions"):
		_unified_macro_map.call("set_regions", _unified_map_region_data(map_state))



func _build_theory_panel() -> PanelContainer:
	var panel: PanelContainer = TheoryPanelV2Script.new() as PanelContainer
	panel.name = "BottomAnalysisHudV2"
	_theory_panel = panel
	var margin_size: int = _hud_margin()
	var side_left: int = margin_size * 2 + _left_hud_width()
	var side_right: int = -(margin_size * 2 + _right_hud_width())
	var theory_h: int = _theory_hud_height()
	_apply_hud_rect(panel, side_left, -(margin_size + theory_h), side_right, -margin_size)
	panel.call("setup", _get_current_scenario(), _visible_macro_state(), _ui_scale)
	_register_hud_blocker(panel)
	return panel


func _build_right_column() -> PanelContainer:
	var panel: PanelContainer = HudPanelShapeScript.new() as PanelContainer
	panel.name = "RightMacroHudV2"
	panel.call("set_shape_kind", "right_drawer")
	_right_panel = panel
	_right_hud_panel = panel
	var margin_size: int = _hud_margin()
	var right_width: int = _right_hud_width()
	var top_y: int = _side_top_y()
	_apply_hud_rect(panel, -(margin_size + right_width), top_y, -margin_size, -margin_size)
	_register_hud_blocker(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dim(16))
	margin.add_theme_constant_override("margin_top", _dim(12))
	margin.add_theme_constant_override("margin_right", _dim(10))
	margin.add_theme_constant_override("margin_bottom", _dim(12))
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.name = "RightMacroHudLayout"
	box.add_theme_constant_override("separation", _dim(9))
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(box)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", _dim(6))
	box.add_child(header)
	header.add_child(_build_drawer_toggle_button("collapse_right", Callable(self, "_toggle_right_drawer")))
	_add_panel_title(header, "宏观状态")
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_right_panel_box = VBoxContainer.new()
	_right_panel_box.name = "RightMacroContent"
	_right_panel_box.add_theme_constant_override("separation", _dim(8))
	_right_panel_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_panel_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	box.add_child(_right_panel_box)

	var spacer_bottom: Control = Control.new()
	spacer_bottom.name = "RightMacroSpacer"
	spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer_bottom)

	_confirm_button = _build_confirm_policy_button()
	box.add_child(_confirm_button)
	_refresh_confirm_button()
	return panel

func _build_confirm_policy_button() -> Button:
	var button: Button = Button.new()
	button.name = "ConfirmPolicyButton"
	button.custom_minimum_size = Vector2(_dim(0), _dim(52))
	button.add_theme_font_size_override("font_size", _font(17))
	HudV2Theme.apply_button(button, _ui_scale, "confirm")
	button.pressed.connect(_on_confirm_policy)
	return button


func _refresh_confirm_button() -> void:
	if _confirm_button == null:
		return
	_confirm_button.text = "政策已确认" if _is_policy_confirmed else "✓ 确认政策"
	_confirm_button.disabled = _is_policy_confirmed or _selected_policies.is_empty()

func _show_current_state_panel() -> void:
	_clear_right_panel()
	_model_replay_button = null
	_summary_button = null
	var scenario: Dictionary = _get_current_scenario()
	var variables: Dictionary = GameState.get_current_state()

	_add_section_label(_right_panel_box, "当前问题")
	_add_wrapped_label(_right_panel_box, str(scenario.get("problem_title", "消费信心下降")), HudV2Theme.TEXT_TITLE, 17)
	_add_section_label(_right_panel_box, "关键指标")
	for key: String in ["Y", "u", "π", "i", "Debt"]:
		_add_stat_row(_right_panel_box, key, variables, {})
	_add_section_label(_right_panel_box, "行动提示")
	_add_wrapped_label(_right_panel_box, "选择一张政策卡后，在右下角确认执行。", HudV2Theme.TEXT_BODY, 13)

	_refresh_confirm_button()

func _show_policy_result_panel(result: Dictionary) -> void:
	_clear_right_panel()
	var before: Dictionary = {}
	var after: Dictionary = {}
	var before_variant: Variant = result.get("before", {})
	var after_variant: Variant = result.get("after", {})
	if before_variant is Dictionary:
		before = before_variant
	if after_variant is Dictionary:
		after = after_variant
		_refresh_unified_macro_map(after)
	var executed_variant: Variant = result.get("executed_policies", [])
	var executed: Array = []
	if executed_variant is Array:
		executed = executed_variant

	_add_panel_title(_right_panel_box, "政策执行后状态")
	_add_section_label(_right_panel_box, "已执行政策：")
	_add_wrapped_label(_right_panel_box, _policy_names_text(executed), Color(0.96, 0.98, 1.0), 18)
	_add_section_label(_right_panel_box, "结算方式：")
	_add_wrapped_label(_right_panel_box, _settlement_mode_label(
		str(result.get("settlement_mode", "demo")),
		str(result.get("model_type", "")),
		str(result.get("model_version", ""))
	), Color(0.92, 0.80, 0.46), 16)
	_add_section_label(_right_panel_box, "宏观状态：")
	for key: String in ["Y", "u", "π", "i", "Debt"]:
		_add_stat_row(_right_panel_box, key, after, before)
	if _has_islm_graph_result(result):
		var replay_button: Button = Button.new()
		replay_button.name = "ModelReplayButton"
		_model_replay_button = replay_button
		replay_button.text = "查看模型回放"
		replay_button.custom_minimum_size = Vector2(_dim(0), _dim(42))
		replay_button.add_theme_font_size_override("font_size", _font(16))
		HudV2Theme.apply_button(replay_button, _ui_scale, "primary")
		replay_button.pressed.connect(_on_open_replay_pressed)
		_right_panel_box.add_child(replay_button)

	var summary_button: Button = Button.new()
	summary_button.name = "RoundSummaryButton"
	_summary_button = summary_button
	summary_button.text = "本轮总结"
	summary_button.custom_minimum_size = Vector2(_dim(0), _dim(42))
	summary_button.add_theme_font_size_override("font_size", _font(16))
	HudV2Theme.apply_button(summary_button, _ui_scale, "primary")
	summary_button.pressed.connect(_on_round_summary_pressed)
	_right_panel_box.add_child(summary_button)
	_refresh_confirm_button()
	_register_guide_targets()


func _set_advisor_message(title: String, message: String) -> void:
	if _advisor_panel != null and is_instance_valid(_advisor_panel):
		_advisor_panel.call("set_advisor", title, message)


func _set_default_advisor() -> void:
	if GameState.current_round > 1:
		_set_advisor_message( "会议记录", "第 %d 回合开始。上一轮后的宏观状态已带入本轮，请继续选择政策。" % GameState.current_round)
		return
	var advisors: Array = DataLoader.load_array("res://data/advisors.json")
	if advisors.size() > 0 and advisors[0] is Dictionary:
		var advisor: Dictionary = advisors[0] as Dictionary
		_set_advisor_message( str(advisor.get("name", "财政部长")), str(advisor.get("line", "")))


func _get_current_scenario() -> Dictionary:
	var scenario: Dictionary = DataLoader.find_by_id("res://data/scenarios.json", GameState.current_scenario_id)
	if not scenario.is_empty():
		return scenario
	return {
		"problem_title": "消费信心下降",
		"problem_description": "居民消费不足，经济面临需求偏弱压力。",
		"model_hint": "核心变量：C ↓，总需求下降"
	}


func _find_policy_data(policy_id: String) -> Dictionary:
	var policies: Array = DataLoader.load_array("res://data/policies.json")
	for policy: Variant in policies:
		if policy is Dictionary and str(policy.get("id", "")) == policy_id:
			return policy
	return {}


func _available_policy_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var all_policies: Array = DataLoader.load_array("res://data/policies.json")
	var available_variant: Variant = _scenario.get("available_policies", [])
	if not available_variant is Array:
		return result

	for available_item: Variant in available_variant:
		if not available_item is Dictionary:
			continue
		var policy_id: String = str(available_item.get("id", ""))
		var policy_data: Dictionary = {}
		for policy: Variant in all_policies:
			if policy is Dictionary and str(policy.get("id", "")) == policy_id:
				policy_data = (policy as Dictionary).duplicate(true)
				break
		if policy_data.is_empty():
			continue
		if available_item.has("cost"):
			policy_data["cost"] = int(available_item.get("cost", policy_data.get("default_cost", 0)))
		else:
			policy_data["cost"] = int(policy_data.get("default_cost", 0))
		result.append(policy_data)
	return result


func _available_policy_entry_by_id(policy_id: String) -> Dictionary:
	for policy_data: Dictionary in _available_policy_entries():
		if str(policy_data.get("id", "")) == policy_id:
			return policy_data
	return {}


func _is_budget_mode() -> bool:
	return str(_scenario.get("selection_mode", "single")) == "budget"


func _selection_mode_text() -> String:
	if _is_budget_mode():
		return "决策模式：政策点数决策"
	return "决策模式：单一政策决策"



func _policy_point_limit() -> int:
	if _is_budget_mode():
		return int(_scenario.get("policy_point_limit", 0))
	return 1


func _policy_cost(policy_data: Dictionary) -> int:
	if _is_budget_mode():
		return int(policy_data.get("cost", policy_data.get("default_cost", 0)))
	return 1


func _used_policy_points() -> int:
	var total: int = 0
	for policy: Dictionary in _selected_policies:
		total += _policy_cost(policy)
	return total


func _policy_points_text() -> String:
	return "政策点 %s" % _policy_points_value_text()


func _policy_points_value_text() -> String:
	var limit: int = _policy_point_limit()
	var remaining: int = maxi(0, limit - _used_policy_points())
	return "%d / %d" % [remaining, limit]


func _policy_points_hint_text() -> String:
	if _is_budget_mode():
		return "按政策点组合选择；卡牌右下角为消耗。"
	return "每张政策卡会消耗政策点。本关拥有 1 点政策点，只能执行一张政策卡。"


func _is_policy_selected(policy_id: String) -> bool:
	for policy: Dictionary in _selected_policies:
		if str(policy.get("id", "")) == policy_id:
			return true
	return false


func _toggle_single_policy(policy_data: Dictionary) -> void:
	var policy_id: String = str(policy_data.get("id", ""))
	if _is_policy_selected(policy_id):
		_selected_policies.clear()
		GameState.clear_selection()
		return
	_selected_policies = [policy_data]
	GameState.select_policy(policy_id, str(policy_data.get("name", "")))


func _toggle_budget_policy(policy_data: Dictionary) -> void:
	var policy_id: String = str(policy_data.get("id", ""))
	if _is_policy_selected(policy_id):
		for index in range(_selected_policies.size()):
			if str(_selected_policies[index].get("id", "")) == policy_id:
				_selected_policies.remove_at(index)
				break
		return

	var next_cost: int = _policy_cost(policy_data)
	if _used_policy_points() + next_cost > _policy_point_limit():
		_set_advisor_message( "会议记录", "政策点数不足，无法选择该政策。")
		return
	_selected_policies.append(policy_data)


func _refresh_card_selection() -> void:
	for card: Node in _policy_cards:
		card.call("set_selected", _is_policy_selected(str(card.get("policy_id"))))
	_refresh_policy_points_ui()
	_refresh_confirm_button()


func _refresh_policy_points_ui() -> void:
	if _policy_points_label != null:
		_policy_points_label.text = _policy_points_text()
	if _top_policy_points_chip != null and is_instance_valid(_top_policy_points_chip):
		_top_policy_points_chip.call("set_value", _policy_points_value_text())


func _selection_message(policy_name: String) -> String:
	if _selected_policies.is_empty():
		return "已取消选择。请先选择政策。"
	if _is_budget_mode():
		return "已选择政策：%s。当前已用政策点数：%d / %d。点击确认政策后执行。" % [
			_policy_names_text(_selected_policies),
			_used_policy_points(),
			_policy_point_limit()
		]
	return "已选择政策：%s。点击确认政策后执行。" % policy_name


func _policy_names_text(policies: Array) -> String:
	var names: Array[String] = []
	for policy: Variant in policies:
		if policy is Dictionary:
			names.append(str(policy.get("name", policy.get("id", "未知政策"))))
	return "、".join(names)


func _confirmed_meeting_log(summary: String) -> String:
	if str(_last_result.get("settlement_mode", "")) == "model" and str(_last_result.get("model_type", "")) == "IS_LM":
		var mechanisms: Array[String] = []
		var mechanism_variant: Variant = _last_result.get("mechanism", [])
		if mechanism_variant is Array:
			for item: Variant in mechanism_variant:
				mechanisms.append(str(item))
		return "已确认政策：%s\n\n模型结算：IS-LM v1\n\n机制：\n%s\n\n结果：%s" % [
			_policy_names_text(_selected_policies),
			"\n".join(mechanisms),
			summary
		]
	return "已确认政策：“%s”。%s" % [_policy_names_text(_selected_policies), summary]


func _has_islm_graph_result(result: Dictionary) -> bool:
	if str(result.get("settlement_mode", "")) != "model":
		return false
	if str(result.get("model_type", "")) != "IS_LM":
		return false
	var graph_variant: Variant = result.get("graph_data", {})
	if not (graph_variant is Dictionary):
		return false
	return not (graph_variant as Dictionary).is_empty()


func _settlement_mode_label(mode: String, model_type: String = "", model_version: String = "") -> String:
	if mode == "model":
		if model_type == "IS_LM" and model_version == "v1":
			return "IS-LM 模型结算 v1"
		if model_type == "IS_LM":
			return "IS-LM 模型结算占位"
		return "模型结算占位"
	return "基础教学演示结算"


func _current_state() -> Dictionary:
	return GameState.get_current_state()


func _executed_policies_from_result(result: Dictionary) -> Array[Dictionary]:
	var policies: Array[Dictionary] = []
	var executed_variant: Variant = result.get("executed_policies", [])
	if executed_variant is Array:
		for item: Variant in executed_variant:
			if item is Dictionary:
				policies.append((item as Dictionary).duplicate(true))
	return policies


func _state_value(state: Dictionary, key: String) -> String:
	if state.has(key):
		return str(state.get(key))
	if key == "π" and state.has("蟺"):
		return str(state.get("蟺"))
	if key == "蟺" and state.has("π"):
		return str(state.get("π"))
	return "-"


func _tag_text(value: Variant) -> String:
	var parts: Array[String] = []
	if value is Array:
		for item: Variant in value:
			parts.append(str(item))
	if parts.is_empty():
		return "封闭经济｜短期｜价格刚性｜IS-LM"
	return "｜".join(parts)


func _compact_theory_hint(scenario: Dictionary) -> String:
	var hint: String = str(scenario.get("model_hint", "")).strip_edges()
	if hint.is_empty():
		return "机制提示：观察当前冲击如何改变总需求，并通过 IS-LM 影响产出与利率。"
	if not hint.begins_with("机制提示"):
		hint = "机制提示：" + hint
	return hint


func _direction_arrow(before_value: String, after_value: String) -> String:
	var before_number: Dictionary = _parse_state_number(before_value)
	var after_number: Dictionary = _parse_state_number(after_value)
	if not bool(before_number.get("ok", false)) or not bool(after_number.get("ok", false)):
		return ""
	var delta: float = float(after_number.get("value", 0.0)) - float(before_number.get("value", 0.0))
	if delta > 0.001:
		return "↑"
	if delta < -0.001:
		return "↓"
	return "→"


func _parse_state_number(value: String) -> Dictionary:
	var cleaned: String = value.strip_edges().replace("%", "")
	if cleaned.is_valid_float():
		return {"ok": true, "value": cleaned.to_float()}
	return {"ok": false, "value": 0.0}


func _on_policy_selected(policy_id: String, policy_name: String) -> void:
	if _is_gameplay_input_blocked():
		_refresh_card_selection()
		return
	if _is_policy_confirmed:
		for card: Node in _policy_cards:
			card.call("set_selected", _is_policy_selected(str(card.get("policy_id"))))
		_set_advisor_message( "会议记录", "本轮政策已确认，暂不允许重复提交。")
		return

	var policy_data: Dictionary = _available_policy_entry_by_id(policy_id)
	if policy_data.is_empty():
		return

	if _is_budget_mode() and not _is_policy_selected(policy_id):
		var next_cost: int = _policy_cost(policy_data)
		if _used_policy_points() + next_cost > _policy_point_limit():
			_set_advisor_message( "会议记录", "政策点数不足，无法选择该政策。")
			AudioManager.play_sfx(&"card_play")
			return

	if _is_budget_mode():
		_toggle_budget_policy(policy_data)
	else:
		_toggle_single_policy(policy_data)

	_refresh_card_selection()
	AudioManager.play_sfx(&"card_play")
	_set_advisor_message( "政策秘书", _selection_message(policy_name))
	_register_guide_targets()
	if GameState.get_current_visible_level_number() == 1:
		NarrativeManager.play_tutorial_once(
			self,
			"confirm_policy_intro_v1",
			NarrativeManager.confirm_policy_steps(),
			_guide_targets
		)

func _on_confirm_policy() -> void:
	if _is_gameplay_input_blocked():
		return
	if _is_policy_confirmed:
		_set_advisor_message( "会议记录", "本轮政策已确认，暂不允许重复提交。")
		return
	if _selected_policies.is_empty():
		var empty_message: String = "请至少选择一张政策卡。" if _is_budget_mode() else "请先选择一张政策卡。"
		_set_advisor_message( "会议记录", empty_message)
		AudioManager.play_sfx(&"card_play")
		return

	_is_policy_confirmed = true
	_last_result = MacroEngine.calculate_result(_scenario, _selected_policies, _current_state())
	GameState.set_last_result(_last_result)
	_show_policy_result_panel(_last_result)
	_register_guide_targets()
	_confirm_button.text = "政策已确认"
	_confirm_button.disabled = true

	var summary: String = str(_last_result.get("summary", "政策已提交，宏观状态已进入测试更新。"))
	_set_advisor_message( "会议记录", _confirmed_meeting_log(summary))
	AudioManager.play_sfx(&"card_play")
	if _model_replay_button != null and _is_budget_mode():
		NarrativeManager.play_tutorial_once(
			self,
			"model_replay_button_intro_v1",
			NarrativeManager.replay_button_steps(),
			_guide_targets
		)
	var result_comment_steps: Array = NarrativeManager.after_result_comment_steps(GameState.current_scenario_id)
	if not result_comment_steps.is_empty():
		NarrativeManager.play_steps(self, result_comment_steps, _guide_targets, Callable(self, "_maybe_play_round_summary_guide"))
	else:
		_maybe_play_round_summary_guide()

func _on_round_summary_pressed() -> void:
	if _is_gameplay_input_blocked():
		return
	if _last_result.is_empty():
		_set_advisor_message( "会议记录", "请先确认政策，再进入本轮总结。")
		return
	get_tree().change_scene_to_file("res://scenes/Result.tscn")


func _on_open_replay_pressed() -> void:
	if _is_gameplay_input_blocked():
		return
	if not _has_islm_graph_result(_last_result):
		_set_advisor_message( "会议记录", "当前关卡为基础教学演示，暂不提供模型图形回放。")
		return
	_is_replay_open = true
	_open_replay_overlay()
	AudioManager.play_sfx(&"card_play")


func _open_replay_overlay() -> void:
	if _replay_overlay != null:
		_replay_overlay.queue_free()

	_replay_overlay = Control.new()
	_replay_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_replay_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_replay_overlay)

	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_replay_overlay.add_child(dim)

	var overlay_margin: MarginContainer = MarginContainer.new()
	overlay_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_margin.add_theme_constant_override("margin_left", _dim(42))
	overlay_margin.add_theme_constant_override("margin_top", _dim(30))
	overlay_margin.add_theme_constant_override("margin_right", _dim(42))
	overlay_margin.add_theme_constant_override("margin_bottom", _dim(30))
	_replay_overlay.add_child(overlay_margin)

	var replay_panel: PanelContainer = ISLMReplayPanelScene.instantiate() as PanelContainer
	replay_panel.name = "ModelReplayWindow"
	replay_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	replay_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	replay_panel.call("setup", _last_result, _scenario, _ui_scale)
	replay_panel.connect("closed", _on_replay_closed)
	overlay_margin.add_child(replay_panel)
	_register_guide_targets()
	NarrativeManager.play_tutorial_once(
		self,
		"model_replay_window_intro_v1",
		NarrativeManager.replay_window_steps(),
		_guide_targets
	)


func _on_replay_closed() -> void:
	if _is_gameplay_input_blocked():
		return
	_is_replay_open = false
	if _replay_overlay != null:
		_replay_overlay.queue_free()
		_replay_overlay = null
	AudioManager.play_sfx(&"card_play")



func handle_narrative_wheel(button_index: int, ctrl_pressed: bool) -> void:
	if ctrl_pressed:
		return
	if _main_scroll == null:
		return
	_scroll_page_from_wheel(button_index, 1.0)


func _refresh_initial_layout() -> void:
	if _content_margin != null:
		_content_margin.queue_sort()
	if _outer_margin != null:
		_outer_margin.queue_sort()
	if _main_scroll != null:
		_target_scroll_y = float(_main_scroll.scroll_vertical)
	_register_guide_targets()


func _forward_map_input(event: InputEvent) -> void:
	if _unified_macro_map == null or not is_instance_valid(_unified_macro_map):
		return
	if not _unified_macro_map.has_method("handle_viewport_input"):
		return
	var viewport_position: Vector2 = get_viewport().get_mouse_position()
	var over_hud: bool = _is_pointer_over_hud(viewport_position)
	var consumed: bool = bool(_unified_macro_map.call(
		"handle_viewport_input",
		event,
		viewport_position,
		Input.is_key_pressed(KEY_SPACE),
		not over_hud
	))
	if consumed:
		get_viewport().set_input_as_handled()


func _toggle_left_drawer() -> void:
	_left_drawer_collapsed = not _left_drawer_collapsed
	_apply_left_drawer_state(true)


func _toggle_right_drawer() -> void:
	_right_drawer_collapsed = not _right_drawer_collapsed
	_apply_right_drawer_state(true)


func _apply_left_drawer_state(animated: bool = false) -> void:
	if _left_hud_panel == null or not is_instance_valid(_left_hud_panel):
		return
	var width: int = _left_hud_width()
	var margin_size: int = _hud_margin()
	var tab_width: int = _drawer_tab_width()
	var target_left: float = float(-width + tab_width) if _left_drawer_collapsed else float(margin_size)
	var target_right: float = float(tab_width) if _left_drawer_collapsed else float(margin_size + width)
	_tween_drawer_offsets(_left_hud_panel, target_left, target_right, animated)


func _apply_right_drawer_state(animated: bool = false) -> void:
	if _right_hud_panel == null or not is_instance_valid(_right_hud_panel):
		return
	var width: int = _right_hud_width()
	var margin_size: int = _hud_margin()
	var tab_width: int = _drawer_tab_width()
	var target_left: float = float(-tab_width) if _right_drawer_collapsed else float(-(margin_size + width))
	var target_right: float = float(width - tab_width) if _right_drawer_collapsed else float(-margin_size)
	_tween_drawer_offsets(_right_hud_panel, target_left, target_right, animated)


func _tween_drawer_offsets(panel: Control, target_left: float, target_right: float, animated: bool) -> void:
	if not animated:
		panel.offset_left = target_left
		panel.offset_right = target_right
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(panel, "offset_left", target_left, 0.26)
	tween.parallel().tween_property(panel, "offset_right", target_right, 0.26)


func _drawer_tab_width() -> int:
	return _dim(34)


func _register_hud_blocker(control: Control) -> void:
	if control != null:
		_hud_blockers.append(control)


func _is_pointer_over_hud(viewport_position: Vector2) -> bool:
	for control: Control in _hud_blockers:
		if control == null or not is_instance_valid(control) or not control.visible:
			continue
		var local: Vector2 = control.get_global_transform_with_canvas().affine_inverse() * viewport_position
		if Rect2(Vector2.ZERO, control.size).has_point(local):
			return true
	return false


func _scroll_page_from_wheel(button_index: int, event_factor: float = 1.0) -> void:
	if _main_scroll == null:
		return
	_clear_macro_map_hover()
	var max_scroll: float = _scrollable_range()
	if max_scroll <= 0.0:
		_set_scroll_immediate(0.0)
		return
	var direction: float = -1.0 if button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
	var factor: float = absf(event_factor)
	if is_zero_approx(factor):
		factor = 1.0
	factor = clampf(factor, 0.05, 3.0)
	var current_scroll: float = float(_main_scroll.scroll_vertical)
	if _scroll_tween == null or not _scroll_tween.is_running():
		_target_scroll_y = current_scroll
	_target_scroll_y = clampf(_target_scroll_y + direction * _scroll_step() * factor, 0.0, max_scroll)
	_smooth_scroll_to(_target_scroll_y)


func _clear_macro_map_hover() -> void:
	if _unified_macro_map != null and is_instance_valid(_unified_macro_map) and _unified_macro_map.has_method("clear_hover_state"):
		_unified_macro_map.call("clear_hover_state")


func _scroll_step() -> float:
	var scrollable_range: float = _scrollable_range()
	if scrollable_range <= 0.0:
		return 0.0
	return clampf(
		scrollable_range / UIInteractionConfig.SCROLL_TARGET_DIVISIONS,
		UIInteractionConfig.SCROLL_MIN_STEP,
		UIInteractionConfig.SCROLL_MAX_STEP
	)


func _scrollable_range() -> float:
	if _main_scroll == null:
		return 0.0
	var bar: VScrollBar = _main_scroll.get_v_scroll_bar()
	if bar == null:
		return 0.0
	return maxf(0.0, float(bar.max_value - bar.page))


func _smooth_scroll_to(value: float) -> void:
	if _main_scroll == null:
		return
	var max_scroll: float = _scrollable_range()
	var next_value: float = clampf(value, 0.0, max_scroll)
	if _scroll_tween != null and _scroll_tween.is_running():
		_scroll_tween.kill()
	_scroll_tween = create_tween()
	_scroll_tween.set_trans(Tween.TRANS_SINE)
	_scroll_tween.set_ease(Tween.EASE_OUT)
	_scroll_tween.tween_property(_main_scroll, "scroll_vertical", int(roundf(next_value)), UIInteractionConfig.SCROLL_SMOOTH_DURATION)


func _set_scroll_immediate(value: float) -> void:
	if _scroll_tween != null and _scroll_tween.is_running():
		_scroll_tween.kill()
	if _main_scroll == null:
		return
	var next_value: float = clampf(value, 0.0, _scrollable_range())
	_main_scroll.scroll_vertical = int(roundf(next_value))
	_target_scroll_y = next_value


func _capture_scroll_center_ratio() -> float:
	if _main_scroll == null:
		return 0.0
	var max_scroll: float = _scrollable_range()
	var viewport_height: float = maxf(_main_scroll.size.y, 1.0)
	var content_height: float = maxf(max_scroll + viewport_height, viewport_height)
	var center_y: float = float(_main_scroll.scroll_vertical) + viewport_height * 0.5
	return clampf(center_y / content_height, 0.0, 1.0)


func _restore_scroll_after_scale(center_ratio: float) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if _main_scroll == null:
		return
	var max_scroll: float = _scrollable_range()
	var viewport_height: float = maxf(_main_scroll.size.y, 1.0)
	var content_height: float = maxf(max_scroll + viewport_height, viewport_height)
	var target: float = center_ratio * content_height - viewport_height * 0.5
	_set_scroll_immediate(target)
	_refresh_initial_layout()


func _register_guide_targets() -> void:
	_guide_targets = {
		"problem_panel": _problem_panel,
		"theory_panel": _theory_panel,
		"theory_button": _theory_panel,
		"macro_map": _map_panel,
		"map_panel": _map_panel,
		"policy_cards": _policy_column,
		"policy_points_area": _policy_points_label,
		"right_info_panel": _right_panel,
		"confirm_policy_button": _confirm_button,
		"model_replay_button": _model_replay_button,
		"round_summary_button": _summary_button,
		"wisdom_panel": _wisdom_label,
		"wisdom_points_display": _wisdom_label,
		"hint_button": _request_hint_button
	}
	if _replay_overlay != null:
		_guide_targets["model_replay_window"] = _replay_overlay
		_guide_targets["model_replay_panel"] = _replay_overlay
	NarrativeManager.refresh_target_map(_guide_targets)


func _maybe_start_policy_desk_guides() -> void:
	_register_guide_targets()
	if GameState.current_round != 1 or _is_policy_confirmed:
		return
	var chapter_steps: Array = NarrativeManager.chapter_opening_steps()
	if GameState.get_current_visible_level_number() == 1 and not chapter_steps.is_empty():
		NarrativeManager.play_tutorial_once(
			self,
			"islm_chapter_opening_v1",
			chapter_steps,
			_guide_targets
		)
	var level_steps: Array = NarrativeManager.level_opening_steps(GameState.current_scenario_id)
	if not level_steps.is_empty():
		NarrativeManager.play_tutorial_once(
			self,
			"level_opening_%s_v1" % GameState.current_scenario_id,
			level_steps,
			_guide_targets
		)
	if GameState.get_current_visible_level_number() == 1:
		NarrativeManager.play_tutorial_once(
			self,
			"policy_desk_intro_v1",
			NarrativeManager.basic_policy_desk_steps(),
			_guide_targets,
			Callable(self, "_on_policy_desk_intro_finished")
		)
	if _is_budget_mode():
		NarrativeManager.play_tutorial_once(
			self,
			"budget_mode_intro_v1",
			NarrativeManager.budget_intro_steps(),
			_guide_targets
		)


func _maybe_play_round_summary_guide() -> void:
	if GameState.get_current_visible_level_number() != 1:
		return
	if _summary_button == null:
		return
	_register_guide_targets()
	NarrativeManager.play_tutorial_once(
		self,
		"round_summary_intro_v1",
		NarrativeManager.round_summary_steps(),
		_guide_targets
	)


func _on_policy_desk_intro_finished() -> void:
	NarrativeManager.play_tutorial_once(
		self,
		"wisdom_points_intro_v1",
		NarrativeManager.wisdom_intro_steps(),
		_guide_targets
	)


func _is_first_level_scenario() -> bool:
	return GameState.current_scenario_id.begins_with("consumer_confidence_drop")


func _refresh_wisdom_ui() -> void:
	if _wisdom_chip != null and is_instance_valid(_wisdom_chip):
		_wisdom_chip.call("set_value", str(NarrativeManager.get_wisdom_points()))
	elif _wisdom_label != null:
		_wisdom_label.text = "智慧点 %d" % NarrativeManager.get_wisdom_points()
	if _review_hint_button != null:
		var unlocked_variant: Variant = NarrativeManager.unlocked_hints.get(GameState.current_scenario_id, [])
		_review_hint_button.disabled = not (unlocked_variant is Array and (unlocked_variant as Array).size() > 0)


func _on_request_hint_pressed() -> void:
	if _is_gameplay_input_blocked():
		return
	_register_guide_targets()
	NarrativeManager.request_hint(self, GameState.current_scenario_id, _guide_targets)
	_refresh_wisdom_ui()


func _on_review_hint_pressed() -> void:
	if _is_gameplay_input_blocked():
		return
	_register_guide_targets()
	NarrativeManager.replay_unlocked_hints(self, GameState.current_scenario_id, _guide_targets)


func _is_gameplay_input_blocked() -> bool:
	return NarrativeManager.is_blocking_game_input()


func _clear_right_panel() -> void:
	if _right_panel_box == null:
		return
	for child: Node in _right_panel_box.get_children():
		child.queue_free()


func _add_panel_title(parent: Control, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.modulate = Color(0.82, 0.96, 1.0, 0.96)
	label.add_theme_font_size_override("font_size", _font(19))
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	parent.add_child(label)


func _add_section_label(parent: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.modulate = Color(0.48, 0.78, 0.88)
	label.add_theme_font_size_override("font_size", _font(13))
	parent.add_child(label)


func _add_wrapped_label(parent: VBoxContainer, text: String, color: Color, base_font_size: int) -> void:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = color
	label.add_theme_font_size_override("font_size", _font(base_font_size))
	parent.add_child(label)


func _add_info_row(parent: VBoxContainer, name: String, value: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", _dim(10))
	parent.add_child(row)

	var name_label: Label = Label.new()
	name_label.text = name
	name_label.custom_minimum_size = Vector2(_dim(58), _dim(26))
	name_label.modulate = Color(0.72, 0.82, 0.90)
	name_label.add_theme_font_size_override("font_size", _font(15))
	row.add_child(name_label)

	var value_label: Label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", _font(17))
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value_label)


func _add_stat_row(parent: VBoxContainer, key: String, current_state: Dictionary, before_state: Dictionary) -> void:
	var config: Dictionary = _variable_display_config(key)
	var current_value_text: String = _state_value(current_state, key)
	var current_number: float = _state_number(current_state, key, float(config.get("reference_value", 0.0)))
	var score: float = _state_score(key, current_state)
	var status_text: String = _state_status_text(score)
	var row: Control = MacroIndicatorRowV2Script.new() as Control
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.call("setup", _variable_display_name(key), key, config, current_value_text, current_number, status_text, score, _ui_scale)
	parent.add_child(row)

func _visible_macro_state() -> Dictionary:
	if _is_policy_confirmed and not _last_result.is_empty():
		var after_variant: Variant = _last_result.get("after", {})
		if after_variant is Dictionary:
			return (after_variant as Dictionary).duplicate(true)
	return GameState.get_current_state()


func _map_region_lines(config: Dictionary, state: Dictionary) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	var variables: Array = config.get("variables", []) as Array
	for variable: Variant in variables:
		var key: String = str(variable)
		var score: float = _state_score(key, state)
		lines.append({
			"metric_id": _metric_id_for_symbol(key),
			"display_symbol": key,
			"label": key,
			"arrow": _reference_arrow(key, state),
			"value_text": _metric_value_text(key, state),
			"status_text": _state_status_text(score)
		})
	return lines


func _map_region_brightness(config: Dictionary, state: Dictionary) -> float:
	var weights: Dictionary = {}
	var weights_variant: Variant = config.get("weights", {})
	if weights_variant is Dictionary:
		weights = weights_variant as Dictionary
	if weights.is_empty():
		return 0.0

	var weighted_total: float = 0.0
	var weight_sum: float = 0.0
	for key_variant: Variant in weights.keys():
		var key: String = str(key_variant)
		var weight: float = float(weights.get(key, 0.0))
		if weight <= 0.0:
			continue
		weighted_total += _state_score(key, state) * weight
		weight_sum += weight
	if weight_sum <= 0.0:
		return 0.0
	return clampf(weighted_total / weight_sum, -1.0, 1.0)


func _variable_display_config(key: String) -> Dictionary:
	var normalized_key: String = "π" if key == "蟺" else key
	var config: Dictionary = {}
	if STAT_DISPLAY_DEFAULTS.has(normalized_key):
		config = (STAT_DISPLAY_DEFAULTS[normalized_key] as Dictionary).duplicate(true)
	else:
		config = {"display_min": -1.0, "display_max": 1.0, "reference_value": 0.0}

	var params: Dictionary = _islm_params()
	var score_config: Dictionary = _dictionary_from_variant(_scenario.get("score_config", {}))
	var targets: Dictionary = _dictionary_from_variant(score_config.get("targets", {}))
	var limits: Dictionary = _dictionary_from_variant(score_config.get("limits", {}))

	match normalized_key:
		"Y":
			config["reference_value"] = float(targets.get("Y_target", params.get("Y_potential", config.get("reference_value", 110.0))))
		"u":
			config["reference_value"] = float(targets.get("u_target", params.get("u_base", config.get("reference_value", 4.5))))
		"π":
			config["reference_value"] = float(targets.get("pi_target", params.get("pi_base", config.get("reference_value", 2.0))))
		"i":
			if params.has("A") and params.has("b") and params.has("c") and params.has("d"):
				var denominator: float = 1.0 + float(params.get("b", 8.0)) * float(params.get("c", 0.04))
				if not is_zero_approx(denominator):
					var y_ref: float = (float(params.get("A", 132.0)) + float(params.get("b", 8.0)) * float(params.get("d", 0.0))) / denominator
					config["reference_value"] = float(params.get("c", 0.04)) * y_ref - float(params.get("d", 0.0))
		"Debt":
			config["reference_value"] = float(params.get("debt_base", limits.get("debt_soft_limit", config.get("reference_value", 60.0))))

	var overrides: Dictionary = _dictionary_from_variant(_scenario.get("variable_display", {}))
	var override_variant: Variant = overrides.get(normalized_key, {})
	if override_variant is Dictionary:
		for override_key: Variant in (override_variant as Dictionary).keys():
			config[override_key] = (override_variant as Dictionary).get(override_key)
	return config


func _variable_display_name(key: String) -> String:
	match key:
		"Y":
			return "产出"
		"u":
			return "失业率"
		"π", "蟺":
			return "通胀率"
		"i":
			return "利率"
		"Debt":
			return "政府债务"
	return key


func _reference_arrow(key: String, state: Dictionary) -> String:
	var score: float = _state_score(key, state)
	if score > 0.15:
		return "↑"
	if score < -0.15:
		return "↓"
	return "→"


func _state_score(key: String, state: Dictionary) -> float:
	var status_key: String = ISLMDemandComponents.status_key(key)
	if status_key != key and state.has(status_key):
		return _qualitative_score(str(state.get(status_key)))
	var value_text: String = _state_value(state, key)
	var parsed: Dictionary = _parse_state_number(value_text)
	if bool(parsed.get("ok", false)):
		var config: Dictionary = _variable_display_config(key)
		var reference: float = float(config.get("reference_value", 0.0))
		var span: float = maxf(float(config.get("display_max", 1.0)) - float(config.get("display_min", 0.0)), 1.0)
		var tolerance: float = maxf(span * 0.08, 0.35)
		var delta: float = float(parsed.get("value", 0.0)) - reference
		if delta > tolerance:
			return 1.0
		if delta < -tolerance:
			return -1.0
		return 0.0
	return _qualitative_score(value_text)


func _state_status_text(score: float) -> String:
	if score > 0.15:
		return "偏高"
	if score < -0.15:
		return "偏低"
	return "适中"


func _metric_id_for_symbol(symbol: String) -> String:
	match symbol:
		"C":
			return "consumption"
		"Y":
			return "output"
		"I":
			return "investment"
		"i":
			return "interest_rate"
		"G":
			return "government_spending"
		"Debt":
			return "debt"
	return symbol


func _metric_value_text(symbol: String, state: Dictionary) -> String:
	var value_text: String = _state_value(state, ISLMDemandComponents.value_key(symbol))
	if bool(_parse_state_number(value_text).get("ok", false)):
		return value_text
	value_text = _state_value(state, symbol)
	if bool(_parse_state_number(value_text).get("ok", false)):
		return value_text
	match symbol:
		"i":
			return _state_value(state, "i")
		"Debt":
			return _state_value(state, "Debt")
		"Y":
			return _state_value(state, "Y")
	return "—"


func _qualitative_score(value_text: String) -> float:
	if value_text.find("偏高") >= 0 or value_text.find("较高") >= 0 or value_text.find("高") >= 0 or value_text.find("强") >= 0 or value_text.find("扩张") >= 0:
		return 1.0
	if value_text.find("偏低") >= 0 or value_text.find("较低") >= 0 or value_text.find("低") >= 0 or value_text.find("弱") >= 0 or value_text.find("下降") >= 0:
		return -1.0
	return 0.0


func _state_number(state: Dictionary, key: String, fallback: float) -> float:
	var parsed: Dictionary = _parse_state_number(_state_value(state, key))
	if bool(parsed.get("ok", false)):
		return float(parsed.get("value", fallback))
	return fallback


func _arrow_color(arrow: String) -> Color:
	if arrow == "↑":
		return Color(0.68, 0.95, 0.72, 1.0)
	if arrow == "↓":
		return Color(0.95, 0.62, 0.58, 1.0)
	return Color(0.78, 0.86, 0.92, 1.0)


func _dictionary_from_variant(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


func _islm_params() -> Dictionary:
	var model_params: Dictionary = _dictionary_from_variant(_scenario.get("model_params", {}))
	var islm_variant: Variant = model_params.get("IS_LM", {})
	if islm_variant is Dictionary:
		return (islm_variant as Dictionary).duplicate(true)
	return {}


func _scaled_content_size() -> Vector2:
	return Vector2(_dim(BASE_CONTENT_SIZE.x), _dim(BASE_CONTENT_SIZE.y))


func _dim(value: float) -> int:
	return maxi(1, int(roundf(value * _ui_scale)))


func _font(value: int) -> int:
	return maxi(11, int(roundf(float(value) * _ui_scale)))


func _hud_margin() -> int:
	var viewport: Vector2 = _viewport_size()
	return int(roundf(clampf(viewport.x * 0.010, 14.0, 20.0)))


func _hud_size(value: float, min_value: float, max_value: float) -> int:
	return int(roundf(clampf(value * _ui_scale, min_value, max_value)))


func _viewport_size() -> Vector2:
	var viewport: Vector2 = get_viewport_rect().size
	if viewport.x <= 1.0 or viewport.y <= 1.0:
		return Vector2(1600.0, 900.0)
	return viewport


func _top_hud_height() -> int:
	var viewport: Vector2 = _viewport_size()
	return int(roundf(clampf(viewport.y * 0.092, 76.0, 92.0)))


func _side_top_y() -> int:
	return _hud_margin() + _top_hud_height() + _hud_gap()


func _left_hud_width() -> int:
	var viewport: Vector2 = _viewport_size()
	return int(roundf(clampf(viewport.x * 0.135, 205.0, 270.0)))


func _right_hud_width() -> int:
	var viewport: Vector2 = _viewport_size()
	return int(roundf(clampf(viewport.x * 0.155, 260.0, 320.0)))



func _theory_hud_height() -> int:
	var viewport: Vector2 = _viewport_size()
	return int(roundf(clampf(viewport.y * 0.265, 210.0, 300.0)))


func _hud_gap() -> int:
	var viewport: Vector2 = _viewport_size()
	return int(roundf(clampf(viewport.y * 0.012, 8.0, 14.0)))


func _policy_card_ui_scale(policy_count: int) -> float:
	var viewport: Vector2 = _viewport_size()
	var count: int = maxi(1, policy_count)
	var side_height: float = viewport.y - float(_side_top_y()) - float(_hud_margin())
	var header_height: float = 92.0
	var available_card_height: float = maxf(120.0, side_height - header_height - float(maxi(0, count - 1)) * 7.0 - 8.0)
	var height_scale: float = available_card_height / float(count) / 92.0
	var inner_width: float = float(_left_hud_width() - _dim(16))
	var width_scale: float = inner_width / 238.0
	return clampf(minf(minf(height_scale, width_scale), 1.0), 0.76, 1.0)


func _apply_hud_rect(control: Control, left: int, top: int, right: int, bottom: int) -> void:
	control.anchor_left = 0.0 if left >= 0 else 1.0
	control.anchor_top = 0.0 if top >= 0 else 1.0
	control.anchor_right = 0.0 if right >= 0 else 1.0
	control.anchor_bottom = 0.0 if bottom >= 0 else 1.0
	control.offset_left = float(left)
	control.offset_top = float(top)
	control.offset_right = float(right)
	control.offset_bottom = float(bottom)
	control.grow_horizontal = Control.GROW_DIRECTION_BOTH
	control.grow_vertical = Control.GROW_DIRECTION_BOTH


func _make_hud_panel_style(kind: String = "default") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var alpha: float = 0.58
	if kind == "left" or kind == "right":
		alpha = 0.66
	elif kind == "top":
		alpha = 0.56
	elif kind == "theory":
		alpha = 0.62
	style.bg_color = Color(0.015, 0.040, 0.055, alpha)
	style.border_color = Color(0.28, 0.68, 0.82, 0.38)
	style.set_border_width_all(1)
	style.set_corner_radius_all(_dim(8))
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	style.shadow_size = _dim(10)
	style.shadow_offset = Vector2(0, _dim(3))
	return style


func _make_map_panel_style() -> StyleBoxFlat:
	return ClassicalTheme.panel_style("map", _ui_scale)


func _make_problem_panel_style() -> StyleBoxFlat:
	return ClassicalTheme.panel_style("problem", _ui_scale)


func _make_right_panel_style() -> StyleBoxFlat:
	return ClassicalTheme.panel_style("right", _ui_scale)


func _make_theory_panel_style() -> StyleBoxFlat:
	return ClassicalTheme.panel_style("theory", _ui_scale)


func _make_chart_style() -> StyleBoxFlat:
	return ClassicalTheme.panel_style("theory", _ui_scale)


func _make_compact_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.052, 0.068, 0.54)
	style.border_color = Color(0.32, 0.74, 0.88, 0.30)
	style.set_border_width_all(1)
	style.set_corner_radius_all(_dim(7))
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	return style


func _make_icon_slot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.10, 0.12, 0.72)
	style.border_color = Color(0.48, 0.88, 1.0, 0.46)
	style.set_border_width_all(1)
	style.set_corner_radius_all(_dim(6))
	return style

