extends Control

const ClassicalTheme = preload("res://scripts/ui/ClassicalTheme.gd")
const ArtAssetRegistry = preload("res://scripts/ui/ArtAssetRegistry.gd")
const POLICY_DESK_PATH: String = "res://scenes/PolicyDesk.tscn"
const SCENARIO_INTRO_PATH: String = "res://scenes/ScenarioIntro.tscn"
const SCALE_STEP: float = 0.1
const MIN_UI_SCALE: float = 0.8
const MAX_UI_SCALE: float = 1.2

var _main_scroll: ScrollContainer
var _status_label: Label
var _ui_scale: float = 1.0


func _ready() -> void:
	_ui_scale = GameState.ui_scale
	_build_ui()
	_report_web_boot_ready()


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
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()

	var background: ColorRect = ColorRect.new()
	background.color = ClassicalTheme.BG_DEEP
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	_main_scroll = ScrollContainer.new()
	_main_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_main_scroll.follow_focus = true
	_main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_main_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_main_scroll)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dim(56))
	margin.add_theme_constant_override("margin_top", _dim(52))
	margin.add_theme_constant_override("margin_right", _dim(56))
	margin.add_theme_constant_override("margin_bottom", _dim(116))
	_main_scroll.add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.custom_minimum_size = Vector2(_dim(760), _dim(480))
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", _dim(28))
	margin.add_child(root)

	root.add_child(_build_header())
	root.add_child(_build_level_grid())

	_status_label = Label.new()
	_status_label.text = "请选择已解锁关卡。"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ClassicalTheme.apply_label_color(_status_label, "soft")
	_status_label.add_theme_font_size_override("font_size", _font(18))
	root.add_child(_status_label)


func _build_header() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ClassicalTheme.panel_style("chapter", _ui_scale))

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dim(26))
	margin.add_theme_constant_override("margin_top", _dim(22))
	margin.add_theme_constant_override("margin_right", _dim(26))
	margin.add_theme_constant_override("margin_bottom", _dim(22))
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", _dim(10))
	margin.add_child(box)

	var title: Label = Label.new()
	title.text = "第一章：短期需求管理与 IS-LM 模型"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", _font(38))
	ClassicalTheme.apply_label_color(title, "title")
	box.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "按顺序完成 1–7 关。新关卡将在完成前一关后解锁。"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ClassicalTheme.apply_label_color(subtitle, "soft")
	subtitle.add_theme_font_size_override("font_size", _font(18))
	box.add_child(subtitle)

	return panel


func _build_level_grid() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ClassicalTheme.panel_style("desk", _ui_scale))

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dim(30))
	margin.add_theme_constant_override("margin_top", _dim(30))
	margin.add_theme_constant_override("margin_right", _dim(30))
	margin.add_theme_constant_override("margin_bottom", _dim(34))
	panel.add_child(margin)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 7
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", _dim(16))
	grid.add_theme_constant_override("v_separation", _dim(16))
	margin.add_child(grid)

	for level: Dictionary in GameState.get_visible_levels():
		var level_number: int = int(level.get("level_number", 0))
		grid.add_child(_build_level_button(level_number))

	return panel


func _build_level_button(level_number: int) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(_dim(104), _dim(104))
	button.pivot_offset = button.custom_minimum_size * 0.5
	button.add_theme_font_size_override("font_size", _font(34))
	if GameState.is_visible_level_unlocked(level_number):
		button.text = str(level_number)
		if level_number < GameState.get_unlocked_visible_level():
			var complete_icon := ArtAssetRegistry.texture_for_ui("level_complete")
			if complete_icon != null:
				button.icon = complete_icon
	else:
		var lock_icon := ArtAssetRegistry.texture_for_ui("lock_level")
		if lock_icon != null:
			button.text = str(level_number)
			button.icon = lock_icon
		else:
			button.text = "%d\n%s" % [level_number, ArtAssetRegistry.placeholder_for_ui("lock_level")]
	_apply_level_button_style(button, level_number, false)
	button.mouse_entered.connect(_on_level_button_hovered.bind(button, level_number, true))
	button.mouse_exited.connect(_on_level_button_hovered.bind(button, level_number, false))
	button.pressed.connect(_on_level_pressed.bind(level_number))
	return button


func _on_level_pressed(level_number: int) -> void:
	if not GameState.is_visible_level_unlocked(level_number):
		if _status_label != null:
			_status_label.text = "请先完成前一关。"
			var tween: Tween = _status_label.create_tween()
			tween.tween_property(_status_label, "modulate", ClassicalTheme.ACCENT_GOLD, 0.08)
			tween.tween_property(_status_label, "modulate", ClassicalTheme.TEXT_SOFT, 0.20)
		AudioManager.play_sfx(&"card_play")
		return
	if not GameState.start_visible_level(level_number):
		if _status_label != null:
			_status_label.text = "当前关卡暂不可用。"
		return
	AudioManager.unlock_audio_from_user_gesture()
	AudioManager.play_bgm()
	get_tree().change_scene_to_file(_entry_scene_for_current_scenario())


func _entry_scene_for_current_scenario() -> String:
	if has_node("/root/NarrativeManager") and NarrativeManager.should_skip_scenario_intro(GameState.current_scenario_id):
		return POLICY_DESK_PATH
	return SCENARIO_INTRO_PATH


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


func _set_ui_scale(value: float) -> void:
	var next_scale: float = clampf(roundf(value / SCALE_STEP) * SCALE_STEP, MIN_UI_SCALE, MAX_UI_SCALE)
	if is_equal_approx(next_scale, _ui_scale):
		return
	_ui_scale = next_scale
	GameState.set_ui_scale(_ui_scale)
	_build_ui()


func _dim(value: int) -> int:
	return maxi(1, int(roundf(float(value) * _ui_scale)))


func _font(value: int) -> int:
	return maxi(11, int(roundf(float(value) * _ui_scale)))


func _report_web_boot_ready() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.macroPolicyGameReady && window.macroPolicyGameReady();")


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


func _apply_level_button_style(button: Button, level_number: int, hovered: bool) -> void:
	var kind: String = "level_locked"
	if GameState.is_visible_level_unlocked(level_number):
		kind = "level_completed" if level_number < GameState.get_unlocked_visible_level() else "level_current"
	var normal: StyleBoxFlat = ClassicalTheme.panel_style(kind, _ui_scale)
	var hover: StyleBoxFlat = ClassicalTheme.panel_style(kind, _ui_scale)
	hover.bg_color = hover.bg_color.lightened(0.09)
	hover.border_color = ClassicalTheme.ACCENT_GOLD
	var pressed: StyleBoxFlat = ClassicalTheme.panel_style(kind, _ui_scale)
	pressed.bg_color = pressed.bg_color.darkened(0.12)
	button.add_theme_stylebox_override("normal", hover if hovered else normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", ClassicalTheme.panel_style("level_locked", _ui_scale))
	button.add_theme_color_override("font_color", ClassicalTheme.TEXT_MAIN if GameState.is_visible_level_unlocked(level_number) else ClassicalTheme.TEXT_MUTED)
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.86, 0.48, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.82, 0.70, 0.50, 1.0))


func _on_level_button_hovered(button: Button, level_number: int, hovered: bool) -> void:
	_apply_level_button_style(button, level_number, hovered)
	ClassicalTheme.hover_to(button, Vector2(1.035, 1.035) if hovered else Vector2.ONE, 0.10)
