extends Control

const BASIC_SCENARIO_ID: String = "consumer_confidence_drop_basic"
const BUDGET_SCENARIO_ID: String = "consumer_confidence_drop_budget"


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.045, 0.06, 0.075, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var table_glow: ColorRect = ColorRect.new()
	table_glow.color = Color(0.08, 0.14, 0.17, 0.92)
	table_glow.anchor_left = 0.10
	table_glow.anchor_top = 0.16
	table_glow.anchor_right = 0.90
	table_glow.anchor_bottom = 0.86
	add_child(table_glow)

	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -430
	box.offset_top = -230
	box.offset_right = 430
	box.offset_bottom = 230
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	add_child(box)

	var title: Label = Label.new()
	title.text = "宏观政策模拟器"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	box.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "选择一个测试关卡，体验不同的政策决策模式。"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.76, 0.86, 0.92)
	subtitle.add_theme_font_size_override("font_size", 20)
	box.add_child(subtitle)

	box.add_child(_build_scenario_button(
		"基础教学关：单一政策决策",
		"只能选择一张政策卡，适合练习识别冲击与判断政策方向。",
		BASIC_SCENARIO_ID
	))
	box.add_child(_build_scenario_button(
		"组合训练关：政策点数决策",
		"拥有有限政策点数，可以组合多张政策卡，适合测试资源约束与政策组合。",
		BUDGET_SCENARIO_ID
	))


func _build_scenario_button(title: String, description: String, scenario_id: String) -> Button:
	var button: Button = Button.new()
	button.text = "%s\n%s" % [title, description]
	button.custom_minimum_size = Vector2(620, 86)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(_on_scenario_pressed.bind(scenario_id))
	return button


func _on_scenario_pressed(scenario_id: String) -> void:
	GameState.set_current_scenario(scenario_id)
	AudioManager.unlock_audio_from_user_gesture()
	AudioManager.play_bgm()
	get_tree().change_scene_to_file("res://scenes/ScenarioIntro.tscn")
