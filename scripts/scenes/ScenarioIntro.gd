extends Control

var _scenario: Dictionary = {}
var _story_steps: Array = []
var _step_index: int = 0

var _content_box: VBoxContainer
var _progress_label: Label
var _scenario_title_label: Label
var _mode_label: Label
var _title_label: Label
var _body_label: Label
var _tags: HBoxContainer
var _problem_panel: PanelContainer
var _problem_label: Label
var _model_hint_label: Label
var _next_button: Button


func _ready() -> void:
	_load_scenario()
	_build_ui()
	_show_step(0, false)


func _load_scenario() -> void:
	_scenario = GameState.get_current_scenario()
	if _scenario.is_empty():
		_scenario = {
			"title": "消费信心下滑：基础教学关",
			"selection_mode": "single",
			"policy_point_limit": null,
			"problem_title": "消费信心下降",
			"problem_description": "居民消费不足，经济面临需求偏弱压力。",
			"model_hint": "核心变量：C ↓，总需求下降",
			"model_tags": ["封闭经济", "短期", "价格刚性", "IS-LM"]
		}

	var steps_variant: Variant = _scenario.get("story_steps", [])
	if steps_variant is Array and steps_variant.size() > 0:
		_story_steps = steps_variant
	else:
		_story_steps = [
			{
				"title": str(_scenario.get("title", "消费信心下滑")),
				"body": str(_scenario.get("body", "")),
				"button": "进入政策桌面"
			}
		]


func _build_ui() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.045, 0.055, 0.065, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var panel: PanelContainer = PanelContainer.new()
	panel.anchor_left = 0.15
	panel.anchor_top = 0.12
	panel.anchor_right = 0.85
	panel.anchor_bottom = 0.88
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_bottom", 34)
	panel.add_child(margin)

	_content_box = VBoxContainer.new()
	_content_box.add_theme_constant_override("separation", 18)
	margin.add_child(_content_box)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	_content_box.add_child(header)

	var kicker: Label = Label.new()
	kicker.text = "情境开场"
	kicker.modulate = Color(0.68, 0.84, 1.0)
	kicker.add_theme_font_size_override("font_size", 18)
	kicker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(kicker)

	_progress_label = Label.new()
	_progress_label.modulate = Color(0.72, 0.82, 0.90)
	_progress_label.add_theme_font_size_override("font_size", 18)
	header.add_child(_progress_label)

	_scenario_title_label = Label.new()
	_scenario_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_scenario_title_label.modulate = Color(0.70, 0.86, 1.0)
	_scenario_title_label.add_theme_font_size_override("font_size", 22)
	_content_box.add_child(_scenario_title_label)

	_mode_label = Label.new()
	_mode_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mode_label.modulate = Color(0.92, 0.80, 0.46)
	_mode_label.add_theme_font_size_override("font_size", 18)
	_content_box.add_child(_mode_label)

	_title_label = Label.new()
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.add_theme_font_size_override("font_size", 40)
	_content_box.add_child(_title_label)

	_body_label = Label.new()
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.add_theme_font_size_override("font_size", 22)
	_body_label.modulate = Color(0.88, 0.92, 0.95)
	_content_box.add_child(_body_label)

	var tags_scene: PackedScene = preload("res://scenes/components/ModelTagBar.tscn")
	_tags = tags_scene.instantiate() as HBoxContainer
	_content_box.add_child(_tags)

	_problem_panel = PanelContainer.new()
	_problem_panel.add_theme_stylebox_override("panel", _make_problem_style())
	_content_box.add_child(_problem_panel)

	var problem_margin: MarginContainer = MarginContainer.new()
	problem_margin.add_theme_constant_override("margin_left", 18)
	problem_margin.add_theme_constant_override("margin_top", 14)
	problem_margin.add_theme_constant_override("margin_right", 18)
	problem_margin.add_theme_constant_override("margin_bottom", 14)
	_problem_panel.add_child(problem_margin)

	var problem_box: VBoxContainer = VBoxContainer.new()
	problem_box.add_theme_constant_override("separation", 8)
	problem_margin.add_child(problem_box)

	_problem_label = Label.new()
	_problem_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_problem_label.add_theme_font_size_override("font_size", 20)
	problem_box.add_child(_problem_label)

	_model_hint_label = Label.new()
	_model_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_model_hint_label.modulate = Color(0.80, 0.90, 0.82)
	problem_box.add_child(_model_hint_label)

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_box.add_child(spacer)

	_next_button = Button.new()
	_next_button.custom_minimum_size = Vector2(260, 56)
	_next_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_next_button.add_theme_font_size_override("font_size", 22)
	_next_button.pressed.connect(_on_next_pressed)
	_content_box.add_child(_next_button)


func _show_step(index: int, animate: bool) -> void:
	_step_index = clampi(index, 0, _story_steps.size() - 1)
	var step: Dictionary = _story_steps[_step_index] as Dictionary
	var is_last_step: bool = _step_index == _story_steps.size() - 1

	_progress_label.text = "%d / %d" % [_step_index + 1, _story_steps.size()]
	_scenario_title_label.text = str(_scenario.get("title", "消费信心下滑"))
	_mode_label.text = _selection_mode_text()
	_title_label.text = str(step.get("title", _scenario.get("title", "消费信心下滑")))
	_body_label.text = str(step.get("body", _scenario.get("body", "")))
	_next_button.text = str(step.get("button", "进入政策桌面"))

	_tags.visible = is_last_step
	_problem_panel.visible = is_last_step
	if is_last_step:
		_tags.call("set_tags", _scenario.get("model_tags", []))
		_problem_label.text = "当前问题：%s，%s" % [
			str(_scenario.get("problem_title", "消费信心下降")),
			str(_scenario.get("problem_description", "居民消费不足，经济面临需求偏弱压力。"))
		]
		_model_hint_label.text = str(_scenario.get("model_hint", "核心变量：C ↓，总需求下降"))

	if animate:
		_content_box.modulate = Color(1, 1, 1, 0.0)
		var tween: Tween = create_tween()
		tween.tween_property(_content_box, "modulate:a", 1.0, 0.16)
	else:
		_content_box.modulate = Color.WHITE


func _selection_mode_text() -> String:
	if str(_scenario.get("selection_mode", "single")) == "budget":
		return "决策模式：政策点数决策，总点数 %d" % int(_scenario.get("policy_point_limit", 0))
	return "决策模式：单一政策决策"


func _on_next_pressed() -> void:
	AudioManager.play_sfx(&"card_play")
	if _step_index >= _story_steps.size() - 1:
		get_tree().change_scene_to_file("res://scenes/PolicyDesk.tscn")
		return
	_show_step(_step_index + 1, true)


func _make_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.11, 0.14, 0.96)
	style.border_color = Color(0.32, 0.54, 0.68, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 18
	return style


func _make_problem_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.13, 0.15, 0.96)
	style.border_color = Color(0.45, 0.70, 0.86, 0.92)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style
