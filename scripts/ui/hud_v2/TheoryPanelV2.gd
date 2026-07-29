extends PanelContainer

const HudV2Theme = preload("res://scripts/ui/hud_v2/HudV2Theme.gd")
const HudPanelShapeScript = preload("res://scripts/ui/hud_v2/HudPanelShape.gd")
const ISLMChartV2Script = preload("res://scripts/ui/hud_v2/ISLMChartV2.gd")
const OutputCompositionChartV2Script = preload("res://scripts/ui/hud_v2/OutputCompositionChartV2.gd")

var _scenario: Dictionary = {}
var _state: Dictionary = {}
var _ui_scale: float = 1.0


func setup(scenario: Dictionary, state: Dictionary, ui_scale: float = 1.0) -> void:
	_scenario = scenario.duplicate(true)
	_state = state.duplicate(true)
	_ui_scale = ui_scale
	_rebuild()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", HudV2Theme.transparent_panel_style())
	if get_child_count() == 0:
		_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	add_theme_stylebox_override("panel", HudV2Theme.transparent_panel_style())
	mouse_filter = Control.MOUSE_FILTER_STOP

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", HudV2Theme.dim(10, _ui_scale))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(row)

	var theory_module := _module_panel("module")
	theory_module.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	theory_module.size_flags_vertical = Control.SIZE_EXPAND_FILL
	theory_module.size_flags_stretch_ratio = 1.4
	row.add_child(theory_module)
	_build_theory_module(theory_module)

	var composition_module := _module_panel("module")
	composition_module.custom_minimum_size = Vector2(HudV2Theme.dim(218, _ui_scale), 0)
	composition_module.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	composition_module.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(composition_module)
	_build_composition_module(composition_module)


func _module_panel(kind: String) -> PanelContainer:
	var panel: PanelContainer = HudPanelShapeScript.new() as PanelContainer
	panel.call("set_shape_kind", kind)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", HudV2Theme.dim(12, _ui_scale))
	margin.add_theme_constant_override("margin_top", HudV2Theme.dim(10, _ui_scale))
	margin.add_theme_constant_override("margin_right", HudV2Theme.dim(12, _ui_scale))
	margin.add_theme_constant_override("margin_bottom", HudV2Theme.dim(10, _ui_scale))
	panel.add_child(margin)
	return panel


func _build_theory_module(panel: PanelContainer) -> void:
	var margin := panel.get_child(0) as MarginContainer
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", HudV2Theme.dim(4, _ui_scale))
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(box)

	var title := Label.new()
	title.text = "IS-LM 分析"
	title.modulate = HudV2Theme.TEXT_TITLE
	title.add_theme_font_size_override("font_size", HudV2Theme.font(18, _ui_scale))
	box.add_child(title)

	var hint := Label.new()
	hint.text = _mechanism_hint()
	hint.modulate = HudV2Theme.TEXT_BODY
	hint.add_theme_font_size_override("font_size", HudV2Theme.font(12, _ui_scale))
	hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hint.clip_text = true
	box.add_child(hint)

	var chart := ISLMChartV2Script.new() as Control
	chart.call("setup", _scenario, _ui_scale)
	chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(chart)


func _build_composition_module(panel: PanelContainer) -> void:
	var margin := panel.get_child(0) as MarginContainer
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", HudV2Theme.dim(4, _ui_scale))
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(box)

	var title := Label.new()
	title.text = "总需求构成"
	title.modulate = HudV2Theme.TEXT_TITLE
	title.add_theme_font_size_override("font_size", HudV2Theme.font(16, _ui_scale))
	box.add_child(title)

	var chart := OutputCompositionChartV2Script.new() as Control
	chart.call("setup", _state, _ui_scale)
	chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(chart)


func _mechanism_hint() -> String:
	var hint := str(_scenario.get("model_hint", "")).strip_edges()
	if hint.is_empty():
		return "当前冲击改变总需求，并通过 IS-LM 影响产出与利率。"
	if hint.begins_with("机制提示："):
		hint = hint.replace("机制提示：", "")
	return hint
