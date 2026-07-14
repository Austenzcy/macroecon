extends Control

signal finished

var _steps: Array = []
var _target_map: Dictionary = {}
var _index: int = 0
var _dialogue_panel: PanelContainer
var _speaker_label: Label
var _text_label: RichTextLabel
var _avatar_label: Label
var _continue_label: Label
var _current_target_id: String = ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_show_current_step()


func setup(steps: Array, target_map: Dictionary = {}) -> void:
	_steps = steps.duplicate(true)
	_target_map = target_map.duplicate()
	_index = 0
	if is_inside_tree():
		_show_current_step()


func update_target_map(target_map: Dictionary) -> void:
	_target_map = target_map.duplicate()
	queue_redraw()


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_advance()
			accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.58), true)
	var current_target: Control = _lookup_target(_current_target_id)
	if current_target == null or not current_target.visible:
		return
	var rect: Rect2 = _target_rect(current_target)
	if rect.size.x <= 2.0 or rect.size.y <= 2.0:
		return
	var padding: float = 8.0
	rect.position -= Vector2(padding, padding)
	rect.size += Vector2(padding * 2.0, padding * 2.0)
	draw_rect(rect, Color(0.95, 0.78, 0.30, 0.12), true)
	draw_rect(rect, Color(1.0, 0.82, 0.32, 1.0), false, 3.0)


func _build_ui() -> void:
	var bottom_layout: MarginContainer = MarginContainer.new()
	bottom_layout.name = "DialogueBottomLayout"
	bottom_layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	bottom_layout.add_theme_constant_override("margin_left", 56)
	bottom_layout.add_theme_constant_override("margin_top", 24)
	bottom_layout.add_theme_constant_override("margin_right", 56)
	bottom_layout.add_theme_constant_override("margin_bottom", 32)
	add_child(bottom_layout)

	var vertical_layout: VBoxContainer = VBoxContainer.new()
	vertical_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vertical_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_layout.add_child(vertical_layout)

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vertical_layout.add_child(spacer)

	_dialogue_panel = PanelContainer.new()
	_dialogue_panel.name = "DialogueBox"
	_dialogue_panel.custom_minimum_size = Vector2(0.0, 164.0)
	_dialogue_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dialogue_panel.add_theme_stylebox_override("panel", _panel_style())
	vertical_layout.add_child(_dialogue_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 14)
	_dialogue_panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	_avatar_label = Label.new()
	_avatar_label.custom_minimum_size = Vector2(82, 82)
	_avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_avatar_label.add_theme_font_size_override("font_size", 30)
	_avatar_label.add_theme_stylebox_override("normal", _avatar_style())
	row.add_child(_avatar_label)

	var text_box: VBoxContainer = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 8)
	row.add_child(text_box)

	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 20)
	_speaker_label.modulate = Color(0.92, 0.80, 0.46)
	text_box.add_child(_speaker_label)

	_text_label = RichTextLabel.new()
	_text_label.custom_minimum_size = Vector2(0.0, 62.0)
	_text_label.scroll_active = false
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.add_theme_font_size_override("normal_font_size", 20)
	_text_label.modulate = Color(0.95, 0.98, 1.0)
	text_box.add_child(_text_label)

	_continue_label = Label.new()
	_continue_label.text = "单击以继续"
	_continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_label.add_theme_font_size_override("font_size", 14)
	_continue_label.modulate = Color(0.70, 0.80, 0.86)
	text_box.add_child(_continue_label)


func _show_current_step() -> void:
	if _steps.is_empty() or _index >= _steps.size():
		_finish()
		return
	var step: Dictionary = {}
	var raw_step: Variant = _steps[_index]
	if raw_step is Dictionary:
		step = raw_step as Dictionary
	var speaker: String = str(step.get("speaker", "首席经济顾问"))
	var text: String = str(step.get("text", ""))
	var continue_text: String = str(step.get("continue_text", "单击以继续"))
	var target_id: String = str(step.get("target", step.get("target_ui", "")))

	_speaker_label.text = speaker
	_text_label.text = text
	_continue_label.text = continue_text
	_avatar_label.text = _avatar_initial(speaker)
	_current_target_id = target_id
	queue_redraw()


func _advance() -> void:
	_index += 1
	_show_current_step()


func _finish() -> void:
	finished.emit()
	queue_free()


func _lookup_target(target_id: String) -> Control:
	if target_id == "" or not _target_map.has(target_id):
		return null
	var node_variant: Variant = _target_map.get(target_id)
	if node_variant is Control and is_instance_valid(node_variant):
		return node_variant as Control
	return null


func _target_rect(target: Control) -> Rect2:
	var target_rect: Rect2 = target.get_global_rect()
	var origin: Vector2 = get_global_rect().position
	return Rect2(target_rect.position - origin, target_rect.size)


func _avatar_initial(name: String) -> String:
	if name.is_empty():
		return "?"
	return name.substr(0, 1)


func _panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.085, 0.98)
	style.border_color = Color(0.42, 0.62, 0.74, 0.94)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = 18
	return style


func _avatar_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.22, 0.28, 1.0)
	style.border_color = Color(0.66, 0.84, 0.94, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(42)
	return style
