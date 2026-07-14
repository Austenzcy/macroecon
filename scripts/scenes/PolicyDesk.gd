extends Control

const MacroEngine = preload("res://scripts/engine/MacroEngine.gd")
const ISLMReplayPanelScene = preload("res://scenes/components/ISLMReplayPanel.tscn")
const MacroStatBarScript = preload("res://scripts/ui/MacroStatBar.gd")
const TheoryISLMGraphScript = preload("res://scripts/ui/TheoryISLMGraph.gd")
const BASE_CONTENT_SIZE: Vector2 = Vector2(1220.0, 900.0)
const OUTER_MARGIN_X: int = 48
const OUTER_MARGIN_TOP: int = 48
const OUTER_MARGIN_BOTTOM: int = 144
const SCALE_STEP: float = 0.1
const MIN_UI_SCALE: float = 0.8
const MAX_UI_SCALE: float = 1.2
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
var _outer_margin: MarginContainer
var _content_margin: MarginContainer
var _scale_label: Label
var _right_panel_box: VBoxContainer
var _right_panel: PanelContainer
var _problem_panel: PanelContainer
var _policy_column: VBoxContainer
var _map_panel: PanelContainer
var _theory_panel: PanelContainer
var _theory_button: Button
var _replay_overlay: Control
var _confirm_button: Button
var _model_replay_button: Button
var _summary_button: Button
var _policy_points_label: Label
var _wisdom_label: Label
var _request_hint_button: Button
var _review_hint_button: Button
var _scenario: Dictionary = {}
var _selected_policies: Array[Dictionary] = []
var _last_result: Dictionary = {}
var _is_policy_confirmed: bool = false
var _is_theory_open: bool = false
var _is_replay_open: bool = false
var _ui_scale: float = 1.0
var _guide_targets: Dictionary = {}


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
		if not mouse_event.pressed or not mouse_event.ctrl_pressed:
			return
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_ui_scale(_ui_scale + SCALE_STEP)
			get_viewport().set_input_as_handled()
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_ui_scale(_ui_scale - SCALE_STEP)
			get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_policy_cards.clear()
	_advisor_panel = null
	_right_panel_box = null
	_right_panel = null
	_problem_panel = null
	_policy_column = null
	_map_panel = null
	_theory_panel = null
	_theory_button = null
	_replay_overlay = null
	_confirm_button = null
	_model_replay_button = null
	_summary_button = null
	_policy_points_label = null
	_wisdom_label = null
	_request_hint_button = null
	_review_hint_button = null
	_scale_label = null
	_outer_margin = null
	_content_margin = null
	_guide_targets.clear()

	for child: Node in get_children():
		remove_child(child)
		child.queue_free()

	var background: ColorRect = ColorRect.new()
	background.color = Color(0.015, 0.018, 0.022, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)

	_outer_margin = MarginContainer.new()
	_outer_margin.custom_minimum_size = _scaled_content_size() + Vector2(float(OUTER_MARGIN_X * 2), float(OUTER_MARGIN_TOP + OUTER_MARGIN_BOTTOM))
	_outer_margin.add_theme_constant_override("margin_left", OUTER_MARGIN_X)
	_outer_margin.add_theme_constant_override("margin_top", OUTER_MARGIN_TOP)
	_outer_margin.add_theme_constant_override("margin_right", OUTER_MARGIN_X)
	_outer_margin.add_theme_constant_override("margin_bottom", OUTER_MARGIN_BOTTOM)
	scroll.add_child(_outer_margin)

	_content_margin = MarginContainer.new()
	_content_margin.custom_minimum_size = _scaled_content_size()
	_content_margin.add_theme_constant_override("margin_left", _dim(24))
	_content_margin.add_theme_constant_override("margin_top", _dim(18))
	_content_margin.add_theme_constant_override("margin_right", _dim(24))
	_content_margin.add_theme_constant_override("margin_bottom", _dim(20))
	_outer_margin.add_child(_content_margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", _dim(14))
	_content_margin.add_child(root)

	root.add_child(_build_top_row())
	root.add_child(_build_problem_banner())

	var desk: HBoxContainer = HBoxContainer.new()
	desk.add_theme_constant_override("separation", _dim(18))
	root.add_child(desk)

	desk.add_child(_build_policy_column())
	desk.add_child(_build_map_panel())
	desk.add_child(_build_right_column())

	var bottom_row: HBoxContainer = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", _dim(14))
	root.add_child(bottom_row)

	var advisor_scene: PackedScene = preload("res://scenes/components/AdvisorPanel.tscn")
	_advisor_panel = advisor_scene.instantiate() as PanelContainer
	_advisor_panel.custom_minimum_size = Vector2(_dim(0), _dim(132))
	_advisor_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(_advisor_panel)
	_set_default_advisor()

	_confirm_button = Button.new()
	_confirm_button.name = "ConfirmPolicyButton"
	_confirm_button.text = "政策已确认" if _is_policy_confirmed else "确认政策"
	_confirm_button.disabled = _is_policy_confirmed
	_confirm_button.custom_minimum_size = Vector2(_dim(160), _dim(64))
	_confirm_button.add_theme_font_size_override("font_size", _font(20))
	_confirm_button.pressed.connect(_on_confirm_policy)
	bottom_row.add_child(_confirm_button)

	if _is_policy_confirmed:
		_show_policy_result_panel(_last_result)
	else:
		_show_current_state_panel()

	if _is_replay_open:
		_open_replay_overlay()
	_register_guide_targets()


func _build_top_row() -> HBoxContainer:
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", _dim(14))

	var tag_scene: PackedScene = preload("res://scenes/components/ModelTagBar.tscn")
	var tag_bar: HBoxContainer = tag_scene.instantiate() as HBoxContainer
	tag_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(tag_bar)
	tag_bar.call("set_ui_scale", _ui_scale)
	var default_tags: Variant = _scenario.get("model_tags", ["封闭经济", "短期", "价格刚性", "IS-LM"])
	tag_bar.call("set_tags", default_tags)

	top_row.add_child(_build_time_label())
	top_row.add_child(_build_wisdom_panel())
	top_row.add_child(_build_scale_controls())
	return top_row


func _build_time_label() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "QuarterTimeLabel"
	panel.add_theme_stylebox_override("panel", _make_compact_panel_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dim(12))
	margin.add_theme_constant_override("margin_top", _dim(7))
	margin.add_theme_constant_override("margin_right", _dim(12))
	margin.add_theme_constant_override("margin_bottom", _dim(7))
	panel.add_child(margin)

	var label: Label = Label.new()
	label.text = NarrativeManager.get_current_quarter_label(GameState.current_scenario_id)
	label.add_theme_font_size_override("font_size", _font(15))
	label.modulate = Color(0.92, 0.80, 0.46)
	margin.add_child(label)
	return panel


func _build_wisdom_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "WisdomPanel"
	panel.add_theme_stylebox_override("panel", _make_compact_panel_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dim(10))
	margin.add_theme_constant_override("margin_top", _dim(6))
	margin.add_theme_constant_override("margin_right", _dim(10))
	margin.add_theme_constant_override("margin_bottom", _dim(6))
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", _dim(8))
	margin.add_child(row)

	_wisdom_label = Label.new()
	_wisdom_label.name = "WisdomPointsLabel"
	_wisdom_label.custom_minimum_size = Vector2(_dim(86), _dim(30))
	_wisdom_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_wisdom_label.add_theme_font_size_override("font_size", _font(14))
	row.add_child(_wisdom_label)

	_request_hint_button = Button.new()
	_request_hint_button.name = "RequestHintButton"
	_request_hint_button.text = "请求提示"
	_request_hint_button.custom_minimum_size = Vector2(_dim(82), _dim(32))
	_request_hint_button.add_theme_font_size_override("font_size", _font(14))
	_request_hint_button.pressed.connect(_on_request_hint_pressed)
	row.add_child(_request_hint_button)

	_review_hint_button = Button.new()
	_review_hint_button.name = "ReviewHintButton"
	_review_hint_button.text = "回看"
	_review_hint_button.custom_minimum_size = Vector2(_dim(54), _dim(32))
	_review_hint_button.add_theme_font_size_override("font_size", _font(14))
	_review_hint_button.pressed.connect(_on_review_hint_pressed)
	row.add_child(_review_hint_button)

	_refresh_wisdom_ui()
	return panel


func _build_scale_controls() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_compact_panel_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dim(8))
	margin.add_theme_constant_override("margin_top", _dim(6))
	margin.add_theme_constant_override("margin_right", _dim(8))
	margin.add_theme_constant_override("margin_bottom", _dim(6))
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", _dim(8))
	margin.add_child(row)

	var minus_button: Button = Button.new()
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(_dim(34), _dim(32))
	minus_button.add_theme_font_size_override("font_size", _font(16))
	minus_button.pressed.connect(_on_zoom_out)
	row.add_child(minus_button)

	_scale_label = Label.new()
	_scale_label.custom_minimum_size = Vector2(_dim(58), _dim(28))
	_scale_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_scale_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_scale_label.add_theme_font_size_override("font_size", _font(15))
	_scale_label.text = "%d%%" % int(roundf(_ui_scale * 100.0))
	row.add_child(_scale_label)

	var plus_button: Button = Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(_dim(34), _dim(32))
	plus_button.add_theme_font_size_override("font_size", _font(16))
	plus_button.pressed.connect(_on_zoom_in)
	row.add_child(plus_button)

	var reset_button: Button = Button.new()
	reset_button.text = "重置"
	reset_button.custom_minimum_size = Vector2(_dim(58), _dim(32))
	reset_button.add_theme_font_size_override("font_size", _font(15))
	reset_button.pressed.connect(_on_zoom_reset)
	row.add_child(reset_button)

	return panel


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
	column.custom_minimum_size = Vector2(_dim(250), 0)
	column.add_theme_constant_override("separation", _dim(12))

	_add_panel_title(column, "政策卡区")
	_add_wrapped_label(column, _selection_mode_text(), Color(0.72, 0.86, 1.0), 15)
	if _is_budget_mode():
		_policy_points_label = Label.new()
		_policy_points_label.name = "PolicyPointsArea"
		_policy_points_label.text = _policy_points_text()
		_policy_points_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_policy_points_label.modulate = Color(0.92, 0.80, 0.46)
		_policy_points_label.add_theme_font_size_override("font_size", _font(15))
		column.add_child(_policy_points_label)

	var card_scene: PackedScene = preload("res://scenes/components/PolicyCard.tscn")
	var policies: Array[Dictionary] = _available_policy_entries()
	for policy_data: Dictionary in policies:
		var card: PanelContainer = card_scene.instantiate() as PanelContainer
		card.call("set_policy", policy_data)
		card.call("set_ui_scale", _ui_scale)
		card.call("set_cost", int(policy_data.get("cost", policy_data.get("default_cost", 0))), _is_budget_mode())
		card.call("set_selected", _is_policy_selected(str(policy_data.get("id", ""))))
		card.connect("selected", _on_policy_selected)
		_policy_cards.append(card)
		column.add_child(card)

	return column


func _build_map_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "MacroMapPanel"
	_map_panel = panel
	panel.custom_minimum_size = Vector2(_dim(560), _dim(520))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_map_panel_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dim(18))
	margin.add_theme_constant_override("margin_top", _dim(18))
	margin.add_theme_constant_override("margin_right", _dim(18))
	margin.add_theme_constant_override("margin_bottom", _dim(18))
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", _dim(14))
	margin.add_child(box)

	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", _dim(12))
	box.add_child(title_row)

	var title: Label = Label.new()
	title.text = "抽象国家地图"
	title.add_theme_font_size_override("font_size", _font(26))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	_theory_button = Button.new()
	_theory_button.name = "TheoryPanelButton"
	_theory_button.text = "关闭理论" if _is_theory_open else "图表/理论"
	_theory_button.custom_minimum_size = Vector2(_dim(112), _dim(38))
	_theory_button.add_theme_font_size_override("font_size", _font(16))
	_theory_button.pressed.connect(_on_toggle_theory_panel)
	title_row.add_child(_theory_button)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.custom_minimum_size = Vector2(_dim(500), _dim(310))
	grid.add_theme_constant_override("h_separation", _dim(14))
	grid.add_theme_constant_override("v_separation", _dim(14))
	box.add_child(grid)

	var region_scene: PackedScene = preload("res://scenes/components/MapRegion.tscn")
	var map_state: Dictionary = _visible_macro_state()
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
		grid.add_child(region)

	_theory_panel = _build_theory_panel()
	_theory_panel.name = "TheoryPanel"
	_theory_panel.visible = _is_theory_open
	box.add_child(_theory_panel)

	return panel


func _build_theory_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_theory_panel_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dim(16))
	margin.add_theme_constant_override("margin_top", _dim(14))
	margin.add_theme_constant_override("margin_right", _dim(16))
	margin.add_theme_constant_override("margin_bottom", _dim(14))
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", _dim(10))
	margin.add_child(box)

	var scenario: Dictionary = _get_current_scenario()
	_add_panel_title(box, "理论面板：IS-LM 分析")
	_add_wrapped_label(box, "当前冲击：%s" % str(scenario.get("problem_title", "当前宏观冲击")), Color(0.88, 0.94, 1.0), 17)
	_add_wrapped_label(box, "机制提示：%s" % str(scenario.get("model_hint", "请结合当前模型标签观察 IS-LM 传导。")), Color(0.84, 0.90, 0.94), 16)
	_add_wrapped_label(box, "当前模型：%s" % _tag_text(scenario.get("model_tags", [])), Color(0.72, 0.86, 1.0), 16)
	box.add_child(_build_theory_graph(scenario))
	_add_wrapped_label(box, "这里只解释当前冲击的传导机制，不提前展示任何政策卡的执行结果。", Color(0.82, 0.86, 0.90), 15)

	return panel


func _build_theory_graph(scenario: Dictionary) -> Control:
	var graph: Control = TheoryISLMGraphScript.new() as Control
	graph.call("setup", scenario, _ui_scale)
	return graph


func _build_right_column() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "RightInfoPanel"
	_right_panel = panel
	panel.custom_minimum_size = Vector2(_dim(282), _dim(520))
	panel.add_theme_stylebox_override("panel", _make_right_panel_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dim(16))
	margin.add_theme_constant_override("margin_top", _dim(16))
	margin.add_theme_constant_override("margin_right", _dim(16))
	margin.add_theme_constant_override("margin_bottom", _dim(16))
	panel.add_child(margin)

	_right_panel_box = VBoxContainer.new()
	_right_panel_box.add_theme_constant_override("separation", _dim(10))
	margin.add_child(_right_panel_box)

	return panel


func _show_current_state_panel() -> void:
	_clear_right_panel()
	_model_replay_button = null
	_summary_button = null
	var scenario: Dictionary = _get_current_scenario()
	var variables: Dictionary = GameState.get_current_state()

	_add_panel_title(_right_panel_box, "宏观状态监测")
	_add_section_label(_right_panel_box, "当前问题：")
	_add_wrapped_label(_right_panel_box, str(scenario.get("problem_title", "消费信心下降")), Color(0.96, 0.98, 1.0), 18)
	_add_section_label(_right_panel_box, "关键变量：")
	for key: String in ["Y", "u", "π", "i", "Debt"]:
		_add_stat_row(_right_panel_box, key, variables, {})
	_add_section_label(_right_panel_box, "提示：")
	_add_wrapped_label(_right_panel_box, "请选择一张政策卡，并在确认后观察宏观状态变化。", Color(0.78, 0.86, 0.92), 15)


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
		replay_button.pressed.connect(_on_open_replay_pressed)
		_right_panel_box.add_child(replay_button)

	var summary_button: Button = Button.new()
	summary_button.name = "RoundSummaryButton"
	_summary_button = summary_button
	summary_button.text = "本轮总结"
	summary_button.custom_minimum_size = Vector2(_dim(0), _dim(42))
	summary_button.add_theme_font_size_override("font_size", _font(16))
	summary_button.pressed.connect(_on_round_summary_pressed)
	_right_panel_box.add_child(summary_button)
	_register_guide_targets()


func _set_default_advisor() -> void:
	if GameState.current_round > 1:
		_advisor_panel.call("set_advisor", "会议记录", "第 %d 回合开始。上一轮后的宏观状态已带入本轮，请继续选择政策。" % GameState.current_round)
		return
	var advisors: Array = DataLoader.load_array("res://data/advisors.json")
	if advisors.size() > 0 and advisors[0] is Dictionary:
		var advisor: Dictionary = advisors[0] as Dictionary
		_advisor_panel.call("set_advisor", str(advisor.get("name", "财政部长")), str(advisor.get("line", "")))


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
	return int(_scenario.get("policy_point_limit", 0))


func _used_policy_points() -> int:
	var total: int = 0
	for policy: Dictionary in _selected_policies:
		total += int(policy.get("cost", policy.get("default_cost", 0)))
	return total


func _policy_points_text() -> String:
	return "政策点数：已用 %d / %d" % [_used_policy_points(), _policy_point_limit()]


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

	var next_cost: int = int(policy_data.get("cost", policy_data.get("default_cost", 0)))
	if _used_policy_points() + next_cost > _policy_point_limit():
		_advisor_panel.call("set_advisor", "会议记录", "政策点数不足，无法选择该政策。")
		return
	_selected_policies.append(policy_data)


func _refresh_card_selection() -> void:
	for card: Node in _policy_cards:
		card.call("set_selected", _is_policy_selected(str(card.get("policy_id"))))
	if _policy_points_label != null:
		_policy_points_label.text = _policy_points_text()


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
	if _is_policy_confirmed:
		for card: Node in _policy_cards:
			card.call("set_selected", _is_policy_selected(str(card.get("policy_id"))))
		_advisor_panel.call("set_advisor", "会议记录", "本轮政策已确认，暂不允许重复提交。")
		return

	var policy_data: Dictionary = _available_policy_entry_by_id(policy_id)
	if policy_data.is_empty():
		return

	if _is_budget_mode() and not _is_policy_selected(policy_id):
		var next_cost: int = int(policy_data.get("cost", policy_data.get("default_cost", 0)))
		if _used_policy_points() + next_cost > _policy_point_limit():
			_advisor_panel.call("set_advisor", "会议记录", "政策点数不足，无法选择该政策。")
			AudioManager.play_sfx(&"card_play")
			return

	if _is_budget_mode():
		_toggle_budget_policy(policy_data)
	else:
		_toggle_single_policy(policy_data)

	_refresh_card_selection()
	AudioManager.play_sfx(&"card_play")
	_advisor_panel.call("set_advisor", "政策秘书", _selection_message(policy_name))
	_register_guide_targets()
	NarrativeManager.play_tutorial_once(
		self,
		"confirm_policy_intro_v1",
		NarrativeManager.confirm_policy_steps(),
		_guide_targets
	)

func _on_confirm_policy() -> void:
	if _is_policy_confirmed:
		_advisor_panel.call("set_advisor", "会议记录", "本轮政策已确认，暂不允许重复提交。")
		return
	if _selected_policies.is_empty():
		var empty_message: String = "请至少选择一张政策卡。" if _is_budget_mode() else "请先选择一张政策卡。"
		_advisor_panel.call("set_advisor", "会议记录", empty_message)
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
	_advisor_panel.call("set_advisor", "会议记录", _confirmed_meeting_log(summary))
	AudioManager.play_sfx(&"card_play")
	if _model_replay_button != null:
		NarrativeManager.play_tutorial_once(
			self,
			"model_replay_button_intro_v1",
			NarrativeManager.replay_button_steps(),
			_guide_targets
		)

func _on_round_summary_pressed() -> void:
	if _last_result.is_empty():
		_advisor_panel.call("set_advisor", "会议记录", "请先确认政策，再进入本轮总结。")
		return
	get_tree().change_scene_to_file("res://scenes/Result.tscn")


func _on_open_replay_pressed() -> void:
	if not _has_islm_graph_result(_last_result):
		_advisor_panel.call("set_advisor", "会议记录", "当前关卡为基础教学演示，暂不提供模型图形回放。")
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
	_is_replay_open = false
	if _replay_overlay != null:
		_replay_overlay.queue_free()
		_replay_overlay = null
	AudioManager.play_sfx(&"card_play")


func _on_toggle_theory_panel() -> void:
	_is_theory_open = not _is_theory_open
	if _theory_panel != null:
		_theory_panel.visible = _is_theory_open
	if _theory_button != null:
		_theory_button.text = "关闭理论" if _is_theory_open else "图表/理论"
	AudioManager.play_sfx(&"card_play")


func _on_zoom_out() -> void:
	_set_ui_scale(_ui_scale - SCALE_STEP)


func _on_zoom_in() -> void:
	_set_ui_scale(_ui_scale + SCALE_STEP)


func _on_zoom_reset() -> void:
	_set_ui_scale(1.0)


func _set_ui_scale(value: float) -> void:
	var next_scale: float = clampf(roundf(value / SCALE_STEP) * SCALE_STEP, MIN_UI_SCALE, MAX_UI_SCALE)
	if is_equal_approx(next_scale, _ui_scale):
		return
	_ui_scale = next_scale
	GameState.set_ui_scale(_ui_scale)
	_build_ui()
	call_deferred("_refresh_initial_layout")


func _refresh_initial_layout() -> void:
	if _content_margin != null:
		_content_margin.queue_sort()
	if _outer_margin != null:
		_outer_margin.queue_sort()
	_register_guide_targets()


func _register_guide_targets() -> void:
	_guide_targets = {
		"problem_panel": _problem_panel,
		"theory_panel": _theory_button,
		"theory_button": _theory_button,
		"macro_map": _map_panel,
		"map_panel": _map_panel,
		"policy_cards": _policy_column,
		"policy_points_area": _policy_points_label,
		"right_info_panel": _right_panel,
		"confirm_policy_button": _confirm_button,
		"model_replay_button": _model_replay_button,
		"round_summary_button": _summary_button,
		"wisdom_panel": _wisdom_label
	}
	if _replay_overlay != null:
		_guide_targets["model_replay_window"] = _replay_overlay


func _maybe_start_policy_desk_guides() -> void:
	_register_guide_targets()
	if GameState.current_round != 1 or _is_policy_confirmed:
		return
	if _is_first_level_scenario():
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
	if _wisdom_label != null:
		_wisdom_label.text = "智慧点数：%d" % NarrativeManager.get_wisdom_points()
	if _review_hint_button != null:
		var unlocked_variant: Variant = NarrativeManager.unlocked_hints.get(GameState.current_scenario_id, [])
		_review_hint_button.disabled = not (unlocked_variant is Array and (unlocked_variant as Array).size() > 0)


func _on_request_hint_pressed() -> void:
	_register_guide_targets()
	NarrativeManager.request_hint(self, GameState.current_scenario_id, _guide_targets)
	_refresh_wisdom_ui()


func _on_review_hint_pressed() -> void:
	_register_guide_targets()
	NarrativeManager.replay_unlocked_hints(self, GameState.current_scenario_id, _guide_targets)


func _clear_right_panel() -> void:
	if _right_panel_box == null:
		return
	for child: Node in _right_panel_box.get_children():
		child.queue_free()


func _add_panel_title(parent: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", _font(24))
	parent.add_child(label)


func _add_section_label(parent: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.modulate = Color(0.72, 0.86, 1.0)
	label.add_theme_font_size_override("font_size", _font(15))
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
	var arrow: String = _reference_arrow(key, current_state)
	if not before_state.is_empty():
		var before_value_text: String = _state_value(before_state, key)
		arrow = _direction_arrow(before_value_text, current_value_text)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", _dim(7))
	parent.add_child(row)

	var name_label: Label = Label.new()
	name_label.text = key
	name_label.custom_minimum_size = Vector2(_dim(34), _dim(30))
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.modulate = Color(0.72, 0.82, 0.90)
	name_label.add_theme_font_size_override("font_size", _font(14))
	row.add_child(name_label)

	var arrow_label: Label = Label.new()
	arrow_label.text = arrow
	arrow_label.custom_minimum_size = Vector2(_dim(24), _dim(30))
	arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow_label.modulate = _arrow_color(arrow)
	arrow_label.add_theme_font_size_override("font_size", _font(17))
	row.add_child(arrow_label)

	var bar: Control = MacroStatBarScript.new() as Control
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.call("setup", config, current_number, _ui_scale)
	row.add_child(bar)

	var value_label: Label = Label.new()
	value_label.text = current_value_text
	value_label.custom_minimum_size = Vector2(_dim(58), _dim(30))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", _font(14))
	row.add_child(value_label)


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
		lines.append({
			"label": key,
			"arrow": _reference_arrow(key, state),
			"value": _state_value(state, key)
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


func _reference_arrow(key: String, state: Dictionary) -> String:
	var score: float = _state_score(key, state)
	if score > 0.15:
		return "↑"
	if score < -0.15:
		return "↓"
	return "→"


func _state_score(key: String, state: Dictionary) -> float:
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


func _make_map_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.10, 0.12, 0.96)
	style.border_color = Color(0.26, 0.48, 0.58, 0.88)
	style.set_border_width_all(1)
	style.set_corner_radius_all(_dim(8))
	return style


func _make_problem_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.12, 0.135, 0.96)
	style.border_color = Color(0.45, 0.70, 0.86, 0.92)
	style.set_border_width_all(1)
	style.set_corner_radius_all(_dim(8))
	style.shadow_color = Color(0.10, 0.38, 0.56, 0.28)
	style.shadow_size = _dim(14)
	return style


func _make_right_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.16, 0.96)
	style.border_color = Color(0.24, 0.42, 0.56, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(_dim(8))
	return style


func _make_theory_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.085, 0.98)
	style.border_color = Color(0.42, 0.62, 0.74, 0.88)
	style.set_border_width_all(1)
	style.set_corner_radius_all(_dim(8))
	return style


func _make_chart_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.055, 0.065, 0.98)
	style.border_color = Color(0.26, 0.48, 0.58, 0.78)
	style.set_border_width_all(1)
	style.set_corner_radius_all(_dim(6))
	return style


func _make_compact_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.10, 0.12, 0.92)
	style.border_color = Color(0.26, 0.46, 0.58, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(_dim(8))
	return style
