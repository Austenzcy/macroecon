extends Control

const SCENARIO_INTRO_PATH: String = "res://scenes/ScenarioIntro.tscn"
const MAIN_MENU_PATH: String = "res://scenes/MainMenu.tscn"

const LEVELS: Array[Dictionary] = [
	{
		"title": "消费信心下滑",
		"shock": "居民消费意愿下降，C 减少。",
		"model_direction": "需求走弱，IS 曲线左移。",
		"learning_goal": "练习用财政或货币政策稳定短期总需求。",
		"basic_id": "consumer_confidence_drop_basic",
		"training_id": "consumer_confidence_drop_training"
	},
	{
		"title": "投资信心下降",
		"shock": "企业推迟扩产，投资 I 减少。",
		"model_direction": "投资需求下降，IS 曲线左移。",
		"learning_goal": "比较刺激投资与宽松货币条件的短期效果。",
		"basic_id": "investment_confidence_drop_basic",
		"training_id": "investment_confidence_drop_training"
	},
	{
		"title": "货币需求上升",
		"shock": "市场避险情绪升温，货币需求上升。",
		"model_direction": "利率上行，LM 曲线左移或上移。",
		"learning_goal": "观察货币市场冲击如何影响利率与产出。",
		"basic_id": "money_demand_rise_basic",
		"training_id": "money_demand_rise_training"
	},
	{
		"title": "政府支出扩张",
		"shock": "财政支出快速扩张，总需求偏强。",
		"model_direction": "自主支出上升，IS 曲线右移。",
		"learning_goal": "练习在过热压力下使用收缩性政策或观望策略。",
		"basic_id": "government_spending_expansion_basic",
		"training_id": "government_spending_expansion_training"
	}
]


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.018, 0.022, 0.028, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.follow_focus = true
	add_child(scroll)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 96)
	scroll.add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 22)
	margin.add_child(root)

	root.add_child(_build_header())

	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	root.add_child(grid)

	for level: Dictionary in LEVELS:
		grid.add_child(_build_level_card(level))

	var back_button: Button = Button.new()
	back_button.text = "返回主菜单"
	back_button.custom_minimum_size = Vector2(180, 48)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	back_button.add_theme_font_size_override("font_size", 18)
	back_button.pressed.connect(_on_back_pressed)
	root.add_child(back_button)


func _build_header() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.065, 0.095, 0.115, 0.95), Color(0.22, 0.42, 0.52)))

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var title: Label = Label.new()
	title.text = "IS-LM 关卡库"
	title.add_theme_font_size_override("font_size", 38)
	box.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "选择一个宏观冲击情境。每个情境都提供“基础教学”和“组合训练”两种入口。"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.modulate = Color(0.78, 0.88, 0.94)
	subtitle.add_theme_font_size_override("font_size", 18)
	box.add_child(subtitle)

	return panel


func _build_level_card(level: Dictionary) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 300)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.045, 0.057, 0.072, 0.96), Color(0.18, 0.36, 0.46)))

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title: Label = Label.new()
	title.text = str(level.get("title", "IS-LM 情境"))
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)

	_add_text(box, "冲击：" + str(level.get("shock", "")), Color(0.92, 0.96, 1.0), 17)
	_add_text(box, "模型方向：" + str(level.get("model_direction", "")), Color(0.76, 0.88, 1.0), 16)
	_add_text(box, "学习目标：" + str(level.get("learning_goal", "")), Color(0.82, 0.88, 0.86), 16)

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	box.add_child(actions)

	var basic_button: Button = _build_action_button("基础教学", "single + demo")
	basic_button.name = "BasicEntryButton"
	basic_button.pressed.connect(_on_scenario_pressed.bind(str(level.get("basic_id", ""))))
	actions.add_child(basic_button)

	var training_button: Button = _build_action_button("组合训练", "budget + model")
	training_button.name = "TrainingEntryButton"
	training_button.pressed.connect(_on_scenario_pressed.bind(str(level.get("training_id", ""))))
	actions.add_child(training_button)

	return panel


func _build_action_button(title: String, note: String) -> Button:
	var button: Button = Button.new()
	button.text = "%s\n%s" % [title, note]
	button.custom_minimum_size = Vector2(160, 58)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 17)
	return button


func _add_text(parent: Node, text: String, color: Color, font_size: int) -> void:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = color
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)


func _on_scenario_pressed(scenario_id: String) -> void:
	if scenario_id.is_empty():
		return
	GameState.set_current_scenario(scenario_id)
	AudioManager.unlock_audio_from_user_gesture()
	AudioManager.play_bgm()
	get_tree().change_scene_to_file(SCENARIO_INTRO_PATH)


func _on_back_pressed() -> void:
	GameState.reset_for_new_game()
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _make_panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
	style.shadow_size = 12
	return style
