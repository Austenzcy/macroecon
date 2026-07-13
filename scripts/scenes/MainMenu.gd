extends Control


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.045, 0.06, 0.075, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var table_glow: ColorRect = ColorRect.new()
	table_glow.color = Color(0.08, 0.14, 0.17, 0.92)
	table_glow.anchor_left = 0.12
	table_glow.anchor_top = 0.22
	table_glow.anchor_right = 0.88
	table_glow.anchor_bottom = 0.82
	add_child(table_glow)

	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -360
	box.offset_top = -150
	box.offset_right = 360
	box.offset_bottom = 150
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 26)
	add_child(box)

	var title: Label = Label.new()
	title.text = "宏观政策模拟器"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	box.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "政策会议桌已就绪"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.76, 0.86, 0.92)
	subtitle.add_theme_font_size_override("font_size", 20)
	box.add_child(subtitle)

	var start_button: Button = Button.new()
	start_button.text = "开始游戏"
	start_button.custom_minimum_size = Vector2(260, 56)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.add_theme_font_size_override("font_size", 24)
	start_button.pressed.connect(_on_start_pressed)
	box.add_child(start_button)


func _on_start_pressed() -> void:
	AudioManager.unlock_audio_from_user_gesture()
	AudioManager.play_bgm()
	get_tree().change_scene_to_file("res://scenes/ScenarioIntro.tscn")
