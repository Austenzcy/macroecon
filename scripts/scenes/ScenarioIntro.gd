extends Control

const POLICY_DESK_PATH: String = "res://scenes/PolicyDesk.tscn"
const ClassicalTheme = preload("res://scripts/ui/ClassicalTheme.gd")
const SCALE_STEP: float = 0.1
const MIN_UI_SCALE: float = 0.8
const MAX_UI_SCALE: float = 1.2

var _scenario: Dictionary = {}
var _story_steps: Array = []
var _step_index: int = 0
var _ui_scale: float = 1.0

var _content_box: VBoxContainer
var _main_scroll: ScrollContainer
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
	if has_node("/root/NarrativeManager") and NarrativeManager.should_skip_scenario_intro(str(_scenario.get("id", GameState.current_scenario_id))):
		call_deferred("_go_to_policy_desk")
		return
	_ui_scale = GameState.ui_scale
	_build_ui()
	_show_step(0, false)
	call_deferred("_maybe_play_opening_dialogue")


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
	_content_box = null
	_progress_label = null
	_scenario_title_label = null
	_mode_label = null
	_title_label = null
	_body_label = null
	_tags = null
	_problem_panel = null
	_problem_label = null
	_model_hint_label = null
	_next_button = null
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()

	var background: ColorRect = ColorRect.new()
	background.color = ClassicalTheme.BG_DEEP
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var scroll: ScrollContainer = ScrollContainer.new()
	_main_scroll = scroll
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)

	var outer_margin: MarginContainer = MarginContainer.new()
	outer_margin.add_theme_constant_override("margin_left", _dim(48))
	outer_margin.add_theme_constant_override("margin_top", _dim(42))
	outer_margin.add_theme_constant_override("margin_right", _dim(48))
	outer_margin.add_theme_constant_override("margin_bottom", _dim(112))
	scroll.add_child(outer_margin)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 720) * _ui_scale
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	outer_margin.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dim(42))
	margin.add_theme_constant_override("margin_top", _dim(34))
	margin.add_theme_constant_override("margin_right", _dim(42))
	margin.add_theme_constant_override("margin_bottom", _dim(34))
	panel.add_child(margin)

	_content_box = VBoxContainer.new()
	_content_box.add_theme_constant_override("separation", _dim(18))
	margin.add_child(_content_box)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	_content_box.add_child(header)

	var kicker: Label = Label.new()
	kicker.text = "情境开场"
	kicker.modulate = Color(0.68, 0.84, 1.0)
	kicker.add_theme_font_size_override("font_size", _fs(18))
	kicker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(kicker)

	_progress_label = Label.new()
	_progress_label.modulate = Color(0.72, 0.82, 0.90)
	_progress_label.add_theme_font_size_override("font_size", _fs(18))
	header.add_child(_progress_label)

	_scenario_title_label = Label.new()
	_scenario_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_scenario_title_label.modulate = Color(0.70, 0.86, 1.0)
	_scenario_title_label.add_theme_font_size_override("font_size", _fs(22))
	_content_box.add_child(_scenario_title_label)

	_mode_label = Label.new()
	_mode_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mode_label.modulate = Color(0.92, 0.80, 0.46)
	_mode_label.add_theme_font_size_override("font_size", _fs(18))
	_content_box.add_child(_mode_label)

	_title_label = Label.new()
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.add_theme_font_size_override("font_size", _fs(40))
	_content_box.add_child(_title_label)

	_body_label = Label.new()
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.add_theme_font_size_override("font_size", 22)
	_body_label.add_theme_font_size_override("font_size", _fs(22))
	_body_label.modulate = Color(0.88, 0.92, 0.95)
	_content_box.add_child(_body_label)

	var tags_scene: PackedScene = preload("res://scenes/components/ModelTagBar.tscn")
	_tags = tags_scene.instantiate() as HBoxContainer
	_content_box.add_child(_tags)

	_problem_panel = PanelContainer.new()
	_problem_panel.add_theme_stylebox_override("panel", _make_problem_style())
	_content_box.add_child(_problem_panel)

	var problem_margin: MarginContainer = MarginContainer.new()
	problem_margin.add_theme_constant_override("margin_left", _dim(18))
	problem_margin.add_theme_constant_override("margin_top", _dim(14))
	problem_margin.add_theme_constant_override("margin_right", _dim(18))
	problem_margin.add_theme_constant_override("margin_bottom", _dim(14))
	_problem_panel.add_child(problem_margin)

	var problem_box: VBoxContainer = VBoxContainer.new()
	problem_box.add_theme_constant_override("separation", _dim(8))
	problem_margin.add_child(problem_box)

	_problem_label = Label.new()
	_problem_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_problem_label.add_theme_font_size_override("font_size", _fs(20))
	problem_box.add_child(_problem_label)

	_model_hint_label = Label.new()
	_model_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_model_hint_label.modulate = Color(0.80, 0.90, 0.82)
	_model_hint_label.add_theme_font_size_override("font_size", _fs(17))
	problem_box.add_child(_model_hint_label)

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_box.add_child(spacer)

	_next_button = Button.new()
	_next_button.custom_minimum_size = Vector2(260, 56) * _ui_scale
	_next_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_next_button.add_theme_font_size_override("font_size", _fs(22))
	ClassicalTheme.apply_button(_next_button, _ui_scale, "primary")
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
		_go_to_policy_desk()
		return
	_show_step(_step_index + 1, true)


func _go_to_policy_desk() -> void:
	get_tree().change_scene_to_file(POLICY_DESK_PATH)


func _maybe_play_opening_dialogue() -> void:
	if not has_node("/root/NarrativeManager"):
		return
	var chapter_steps: Array = NarrativeManager.chapter_opening_steps()
	if not chapter_steps.is_empty():
		NarrativeManager.play_tutorial_once(
			self,
			"islm_chapter_opening_v1",
			chapter_steps
		)
	var level_steps: Array = NarrativeManager.level_opening_steps(GameState.current_scenario_id)
	if not level_steps.is_empty():
		NarrativeManager.play_tutorial_once(
			self,
			"level_opening_%s_v1" % GameState.current_scenario_id,
			level_steps
		)


func _make_panel_style() -> StyleBoxFlat:
	return ClassicalTheme.panel_style("chapter", _ui_scale)


func _make_problem_style() -> StyleBoxFlat:
	return ClassicalTheme.panel_style("problem", _ui_scale)


func _set_ui_scale(value: float) -> void:
	var next_scale: float = clampf(value, MIN_UI_SCALE, MAX_UI_SCALE)
	if is_equal_approx(next_scale, _ui_scale):
		return
	_ui_scale = next_scale
	GameState.set_ui_scale(_ui_scale)
	_build_ui()
	_show_step(_step_index, false)


func handle_narrative_wheel(button_index: int, ctrl_pressed: bool) -> void:
	if ctrl_pressed:
		if button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_ui_scale(_ui_scale + SCALE_STEP)
		elif button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_ui_scale(_ui_scale - SCALE_STEP)
		return
	if _main_scroll == null:
		return
	var delta: int = -72 if button_index == MOUSE_BUTTON_WHEEL_UP else 72
	_main_scroll.scroll_vertical = maxi(0, _main_scroll.scroll_vertical + delta)


func _dim(value: int) -> int:
	return maxi(1, int(roundf(float(value) * _ui_scale)))


func _fs(value: int) -> int:
	return maxi(11, int(roundf(float(value) * _ui_scale)))
