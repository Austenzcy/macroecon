extends PanelContainer

signal closed

const ISLMChart = preload("res://scripts/ui/ISLMChart.gd")

var _result: Dictionary = {}
var _scenario: Dictionary = {}
var _ui_scale: float = 1.0


func setup(result: Dictionary, scenario: Dictionary, ui_scale: float) -> void:
	_result = result
	_scenario = scenario
	_ui_scale = clampf(ui_scale, 0.8, 1.2)
	_build_ui()


func _build_ui() -> void:
	for child: Node in get_children():
		child.queue_free()

	custom_minimum_size = Vector2(760, 420) * _ui_scale
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel", _make_panel_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dim(24))
	margin.add_theme_constant_override("margin_top", _dim(20))
	margin.add_theme_constant_override("margin_right", _dim(24))
	margin.add_theme_constant_override("margin_bottom", _dim(20))
	add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", _dim(14))
	margin.add_child(box)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", _dim(12))
	box.add_child(header)

	var title_box: VBoxContainer = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	_add_label(title_box, "IS-LM 图形回放", 28, Color(0.96, 0.98, 1.0, 1.0))
	_add_label(title_box, str(_scenario.get("title", "当前关卡")), 16, Color(0.70, 0.86, 1.0, 1.0))
	_add_label(title_box, "已执行政策：%s" % _policy_names_text(), 15, Color(0.84, 0.90, 0.94, 1.0))

	var close_button: Button = Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(_dim(92), _dim(40))
	close_button.add_theme_font_size_override("font_size", _font(16))
	close_button.pressed.connect(func() -> void: closed.emit())
	header.add_child(close_button)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	box.add_child(scroll)

	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", _dim(14))
	scroll.add_child(content)

	var chart: Control = Control.new()
	chart.set_script(ISLMChart)
	chart.call("set_ui_scale", _ui_scale)
	var graph_variant: Variant = _result.get("graph_data", {})
	if graph_variant is Dictionary:
		chart.call("set_graph_data", graph_variant as Dictionary)
	content.add_child(chart)

	content.add_child(_build_summary_panel())
	content.add_child(_build_mechanism_panel())


func _build_summary_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_inner_panel_style())
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dim(14))
	margin.add_theme_constant_override("margin_top", _dim(10))
	margin.add_theme_constant_override("margin_right", _dim(14))
	margin.add_theme_constant_override("margin_bottom", _dim(10))
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", _dim(24))
	margin.add_child(row)

	var before: Dictionary = _dict_from(_result.get("before", {}))
	var after: Dictionary = _dict_from(_result.get("after", {}))
	_add_label(row, "Y：%s → %s" % [str(before.get("Y", "-")), str(after.get("Y", "-"))], 18, Color(0.96, 0.98, 1.0, 1.0))
	_add_label(row, "i：%s → %s" % [str(before.get("i", "-")), str(after.get("i", "-"))], 18, Color(0.96, 0.98, 1.0, 1.0))

	var shifts: Dictionary = _dict_from(_result.get("curve_shifts", {}))
	_add_label(row, "IS：%s" % str(shifts.get("IS", "-")), 16, Color(0.95, 0.74, 0.30, 1.0))
	_add_label(row, "LM：%s" % str(shifts.get("LM", "-")), 16, Color(0.42, 0.86, 1.0, 1.0))
	return panel


func _build_mechanism_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_inner_panel_style())
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dim(14))
	margin.add_theme_constant_override("margin_top", _dim(10))
	margin.add_theme_constant_override("margin_right", _dim(14))
	margin.add_theme_constant_override("margin_bottom", _dim(10))
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", _dim(6))
	margin.add_child(box)
	_add_label(box, "图形解释", 18, Color(0.72, 0.86, 1.0, 1.0))

	var mechanisms: Array[String] = []
	var mechanism_variant: Variant = _result.get("mechanism", [])
	if mechanism_variant is Array:
		for item: Variant in mechanism_variant:
			mechanisms.append(str(item))
	for index in range(mini(mechanisms.size(), 4)):
		_add_wrapped_label(box, "· %s" % mechanisms[index], 15, Color(0.82, 0.88, 0.92, 1.0))
	return panel


func _add_label(parent: Container, text: String, base_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.modulate = color
	label.add_theme_font_size_override("font_size", _font(base_size))
	parent.add_child(label)
	return label


func _add_wrapped_label(parent: Container, text: String, base_size: int, color: Color) -> Label:
	var label: Label = _add_label(parent, text, base_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _policy_names_text() -> String:
	var names: Array[String] = []
	var executed_variant: Variant = _result.get("executed_policies", [])
	if executed_variant is Array:
		for policy_variant: Variant in executed_variant:
			if policy_variant is Dictionary:
				var policy: Dictionary = policy_variant as Dictionary
				names.append(str(policy.get("name", policy.get("id", "未知政策"))))
	return "、".join(names)


func _dict_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value as Dictionary
	return {}


func _dim(value: float) -> int:
	return maxi(1, int(roundf(value * _ui_scale)))


func _font(value: int) -> int:
	return maxi(11, int(roundf(float(value) * _ui_scale)))


func _make_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.065, 0.09, 0.11, 0.98)
	style.border_color = Color(0.42, 0.62, 0.74, 0.92)
	style.set_border_width_all(1)
	style.set_corner_radius_all(_dim(8))
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = _dim(24)
	return style


func _make_inner_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.06, 0.072, 0.96)
	style.border_color = Color(0.24, 0.42, 0.52, 0.82)
	style.set_border_width_all(1)
	style.set_corner_radius_all(_dim(6))
	return style
