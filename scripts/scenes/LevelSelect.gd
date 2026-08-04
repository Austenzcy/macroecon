extends Control

const LevelSelectDataScript = preload("res://scripts/ui/level_select/LevelSelectData.gd")
const CarouselControllerScript = preload("res://scripts/ui/level_select/CarouselController.gd")
const LevelCardScript = preload("res://scripts/ui/level_select/LevelCard.gd")
const TextRevealScript = preload("res://scripts/ui/level_select/TextReveal.gd")
const BackgroundScript = preload("res://scripts/ui/level_select/BackgroundRenderer.gd")
const LEVEL_SELECT_FONT: FontFile = preload("res://assets/fonts/NotoSansSC-Regular.ttf")

const POLICY_DESK_PATH := "res://scenes/PolicyDesk.tscn"
const SCENARIO_INTRO_PATH := "res://scenes/ScenarioIntro.tscn"
const HUD_REFERENCE_PROTOTYPE_PATH := "res://scenes/ui/hud_reference/HudReferencePrototype.tscn"

var _levels: Array[Dictionary] = []
var _cards: Array[Control] = []
var _controller: Node
var _info: Control
var _counter: Label
var _hud_button: Button
var _start_button: Button
var _lock_notice_anchor: Control
var _lock_notice: Label
var _lock_notice_tween: Tween
var _lock_notice_active := false
var _initial_index := 0

func _ready() -> void:
	_levels = LevelSelectDataScript.all()
	if _levels.is_empty():
		push_error("LevelSelect could not build visible levels from GameState.")
		return

	_initial_index = clampi(GameState.get_unlocked_visible_level() - 1, 0, _levels.size() - 1)
	_build_background()
	_build_header()
	_build_carousel()
	_build_information()
	_build_action()
	_layout_ui()
	_info.call("show_level", _levels[_initial_index], _initial_index, _levels.size(), true)
	get_viewport().size_changed.connect(_on_viewport_resized)
	set_process(true)
	_report_web_boot_ready()
	call_deferred("_preload_remaining_covers")

func _build_background() -> void:
	var background := BackgroundScript.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.z_index = -100
	add_child(background)

	var top_scrim := ColorRect.new()
	top_scrim.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_scrim.offset_bottom = 116
	top_scrim.color = Color(0.008, 0.012, 0.017, 0.55)
	top_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_scrim.z_index = 50
	add_child(top_scrim)

func _build_header() -> void:
	var brand := Label.new()
	brand.position = Vector2(43, 29)
	brand.text = "宏观经济政策模拟器"
	brand.add_theme_font_size_override("font_size", 16)
	brand.add_theme_color_override("font_color", Color(0.78, 0.83, 0.85, 0.88))
	brand.z_index = 60
	add_child(brand)

	var chapter := Label.new()
	chapter.position = Vector2(43, 55)
	chapter.text = "第一章  短期需求管理与 IS-LM 模型"
	chapter.add_theme_font_size_override("font_size", 13)
	chapter.add_theme_color_override("font_color", Color(0.54, 0.62, 0.66, 0.74))
	chapter.z_index = 60
	add_child(chapter)

	_counter = Label.new()
	_counter.name = "LevelCounter"
	_counter.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_counter.size = Vector2(128, 34)
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_counter.text = "%02d  /  %02d" % [_initial_index + 1, _levels.size()]
	_counter.add_theme_font_size_override("font_size", 19)
	_counter.add_theme_color_override("font_color", Color(0.91, 0.73, 0.39, 0.9))
	_counter.z_index = 60
	add_child(_counter)

	_hud_button = Button.new()
	_hud_button.name = "HudReferenceButton"
	_hud_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hud_button.size = Vector2(106, 32)
	_hud_button.text = "HUD 样板"
	_hud_button.add_theme_font_size_override("font_size", 12)
	_hud_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_hud_button.focus_mode = Control.FOCUS_ALL
	_hud_button.add_theme_color_override("font_color", Color(0.75, 0.81, 0.84, 0.92))
	_hud_button.add_theme_color_override("font_hover_color", Color(0.95, 0.82, 0.55, 1.0))
	_hud_button.add_theme_stylebox_override("normal", _hud_button_style(false))
	_hud_button.add_theme_stylebox_override("hover", _hud_button_style(true))
	_hud_button.add_theme_stylebox_override("pressed", _hud_button_style(true))
	_hud_button.pressed.connect(_on_hud_reference_pressed)
	_hud_button.z_index = 70
	add_child(_hud_button)

func _build_carousel() -> void:
	_controller = CarouselControllerScript.new()
	add_child(_controller)
	_controller.call("configure", _levels.size())
	_controller.call("set_index_immediate", _initial_index)
	_controller.active_index_changed.connect(_on_active_index_changed)

	for index in range(_levels.size()):
		var card := LevelCardScript.new()
		card.name = "LevelCard%02d" % [index + 1]
		add_child(card)
		card.call("setup", index, _levels[index], _is_neighbor(index, _initial_index))
		card.activated.connect(_on_card_activated)
		_cards.append(card)

func _build_information() -> void:
	_info = TextRevealScript.new()
	_info.name = "LevelInformation"
	_info.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_info.size = Vector2(640, 152)
	_info.z_index = 80
	add_child(_info)

func _build_action() -> void:
	_start_button = Button.new()
	_start_button.name = "StartLevelButton"
	_start_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_start_button.size = Vector2(188, 59)
	_start_button.text = "进入关卡"
	_start_button.add_theme_font_size_override("font_size", 23)
	var start_button_font := FontVariation.new()
	start_button_font.base_font = LEVEL_SELECT_FONT
	start_button_font.variation_embolden = 1.0
	_start_button.add_theme_font_override("font", start_button_font)
	_start_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_start_button.focus_mode = Control.FOCUS_ALL
	_start_button.add_theme_color_override("font_color", Color(0.055, 0.058, 0.06, 1.0))
	_start_button.add_theme_color_override("font_hover_color", Color(0.02, 0.025, 0.03, 1.0))
	_start_button.add_theme_stylebox_override("normal", _start_button_style(Color(0.91, 0.73, 0.39, 1.0)))
	_start_button.add_theme_stylebox_override("hover", _start_button_style(Color(0.98, 0.82, 0.52, 1.0)))
	_start_button.add_theme_stylebox_override("pressed", _start_button_style(Color(0.79, 0.61, 0.31, 1.0)))
	_start_button.pressed.connect(_on_start_pressed)
	_start_button.z_index = 90
	add_child(_start_button)

	_lock_notice_anchor = Control.new()
	_lock_notice_anchor.name = "LockedNoticeAnchor"
	_lock_notice_anchor.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_lock_notice_anchor.size = Vector2(256, 42)
	_lock_notice_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_notice_anchor.z_index = 95
	add_child(_lock_notice_anchor)

	_lock_notice = Label.new()
	_lock_notice.name = "LockedNotice"
	_lock_notice.position = Vector2.ZERO
	_lock_notice.size = _lock_notice_anchor.size
	_lock_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lock_notice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lock_notice.text = "关卡未解锁"
	_lock_notice.add_theme_font_size_override("font_size", 19)
	_lock_notice.add_theme_color_override("font_color", Color(0.84, 0.86, 0.88, 1.0))
	_lock_notice.add_theme_constant_override("outline_size", 8)
	_lock_notice.add_theme_color_override("font_outline_color", Color(0.015, 0.02, 0.025, 0.82))
	_lock_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_notice.modulate.a = 0.0
	_lock_notice_anchor.add_child(_lock_notice)

func _process(_delta: float) -> void:
	_layout_ui()
	var viewport_size := size
	for index in range(_cards.size()):
		var card_angle := float(index) * float(_controller.angle_step) + float(_controller.rotation)
		_cards[index].call("apply_cylinder_state", card_angle, viewport_size, int(_controller.active_index))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_controller.call("push_wheel", 1.0)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_controller.call("push_wheel", -1.0)
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_RIGHT or event.keycode == KEY_DOWN:
			_controller.call("step_by", 1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_LEFT or event.keycode == KEY_UP:
			_controller.call("step_by", -1)
			get_viewport().set_input_as_handled()

func handle_narrative_wheel(button_index: int, ctrl_pressed: bool) -> void:
	if ctrl_pressed:
		return
	_controller.call("push_wheel", -1.0 if button_index == MOUSE_BUTTON_WHEEL_UP else 1.0)

func _on_card_activated(index: int) -> void:
	_controller.call("snap_to_index", index)

func _on_active_index_changed(index: int) -> void:
	_info.call("show_level", _levels[index], index, _levels.size())
	_counter.text = "%02d  /  %02d" % [index + 1, _levels.size()]
	_ensure_neighbor_covers(index)

func _on_start_pressed() -> void:
	var selected_index := int(_controller.active_index)
	var level_number := int(_levels[selected_index].get("order", selected_index + 1))
	if not GameState.is_visible_level_unlocked(level_number):
		_show_locked_notice("关卡未解锁")
		return

	if not GameState.start_visible_level(level_number):
		_show_locked_notice("当前关卡暂不可用")
		return

	AudioManager.unlock_audio_from_user_gesture()
	AudioManager.play_bgm()
	get_tree().change_scene_to_file(_entry_scene_for_current_scenario())

func _on_hud_reference_pressed() -> void:
	AudioManager.unlock_audio_from_user_gesture()
	get_tree().change_scene_to_file(HUD_REFERENCE_PROTOTYPE_PATH)

func _entry_scene_for_current_scenario() -> String:
	if has_node("/root/NarrativeManager") and NarrativeManager.should_skip_scenario_intro(GameState.current_scenario_id):
		return POLICY_DESK_PATH
	return SCENARIO_INTRO_PATH

func _show_locked_notice(message: String) -> void:
	if _lock_notice_active:
		return
	_lock_notice_active = true
	_lock_notice.text = message
	_lock_notice.position = Vector2(0.0, 12.0)
	_lock_notice.modulate.a = 0.0

	_lock_notice_tween = create_tween().set_parallel(false)
	_lock_notice_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_lock_notice_tween.tween_property(_lock_notice, "position:y", 0.0, 0.12)
	_lock_notice_tween.parallel().tween_property(_lock_notice, "modulate:a", 1.0, 0.10)
	_lock_notice_tween.tween_interval(1.38)
	_lock_notice_tween.tween_property(_lock_notice, "position:y", -22.0, 0.18)
	_lock_notice_tween.parallel().tween_property(_lock_notice, "modulate:a", 0.0, 0.15)
	_lock_notice_tween.tween_callback(func() -> void: _lock_notice_active = false)

func _preload_remaining_covers() -> void:
	# The selected card and its neighbors load before first paint. Remaining
	# covers are decoded one per frame after Web reports ready, avoiding a long
	# synchronous pause at the end of Godot's loading progress.
	for card: Control in _cards:
		if not bool(card.call("is_cover_loaded")):
			await get_tree().process_frame
			card.call("ensure_cover_loaded")

func _ensure_neighbor_covers(center_index: int) -> void:
	for index in range(_cards.size()):
		if _is_neighbor(index, center_index):
			_cards[index].call("ensure_cover_loaded")

func _is_neighbor(index: int, center_index: int) -> bool:
	var direct_distance := absi(index - center_index)
	var wrapped_distance := _levels.size() - direct_distance
	return mini(direct_distance, wrapped_distance) <= 1

func _start_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 11
	style.corner_radius_top_right = 11
	style.corner_radius_bottom_left = 11
	style.corner_radius_bottom_right = 11
	style.shadow_color = Color(0.73, 0.48, 0.15, 0.2)
	style.shadow_size = 15
	return style

func _hud_button_style(hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.09, 0.92) if hovered else Color(0.035, 0.05, 0.062, 0.82)
	style.border_color = Color(0.83, 0.68, 0.39, 0.72) if hovered else Color(0.46, 0.56, 0.61, 0.34)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

func _on_viewport_resized() -> void:
	_layout_ui()
	queue_redraw()

func _layout_ui() -> void:
	if not is_instance_valid(_info):
		return
	_counter.position = Vector2(size.x - 307, 29)
	_hud_button.position = Vector2(size.x - 154, 27)
	_info.position = Vector2(43, size.y - 174)
	_start_button.position = Vector2(size.x - 246, size.y - 103)
	_lock_notice_anchor.position = Vector2(size.x * 0.52 - 128, maxf(32.0, size.y * 0.43 - 225.0))

func _report_web_boot_ready() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.macroPolicyGameReady && window.macroPolicyGameReady();")
