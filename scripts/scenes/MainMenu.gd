extends Control

const QUICK_START_SCENARIO_ID: String = "consumer_confidence_drop_basic"
const POLICY_DESK_PATH: String = "res://scenes/PolicyDesk.tscn"
const SCENARIO_INTRO_PATH: String = "res://scenes/ScenarioIntro.tscn"


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
	table_glow.anchor_top = 0.15
	table_glow.anchor_right = 0.90
	table_glow.anchor_bottom = 0.88
	add_child(table_glow)

	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -430
	box.offset_top = -250
	box.offset_right = 430
	box.offset_bottom = 250
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	add_child(box)

	var title: Label = Label.new()
	title.text = "宏观政策模拟器"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	box.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "进入 IS-LM 关卡库，选择不同宏观冲击下的政策决策模式。"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.76, 0.86, 0.92)
	subtitle.add_theme_font_size_override("font_size", 20)
	box.add_child(subtitle)

	box.add_child(_build_menu_button(
		"进入关卡选择",
		"查看第一批 IS-LM 测试关卡，每个关卡都支持基础教学和组合训练。",
		_on_level_select_pressed
	))
	box.add_child(_build_menu_button(
		"快速开始：消费信心下滑",
		"直接进入基础教学关，保留原有测试流程。",
		_on_quick_start_pressed
	))


func _build_menu_button(title: String, description: String, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = "%s\n%s" % [title, description]
	button.custom_minimum_size = Vector2(640, 88)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(callback)
	return button


func _on_level_select_pressed() -> void:
	AudioManager.unlock_audio_from_user_gesture()
	AudioManager.play_bgm()
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")


func _on_quick_start_pressed() -> void:
	GameState.set_current_scenario(QUICK_START_SCENARIO_ID)
	AudioManager.unlock_audio_from_user_gesture()
	AudioManager.play_bgm()
	var entry_scene: String = POLICY_DESK_PATH if has_node("/root/NarrativeManager") and NarrativeManager.should_skip_scenario_intro(QUICK_START_SCENARIO_ID) else SCENARIO_INTRO_PATH
	get_tree().change_scene_to_file(entry_scene)
