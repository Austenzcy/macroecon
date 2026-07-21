extends Control

signal finished

const ClassicalTheme = preload("res://scripts/ui/ClassicalTheme.gd")
const ArtAssetRegistry = preload("res://scripts/ui/ArtAssetRegistry.gd")

var _steps: Array = []
var _target_map: Dictionary = {}
var _index: int = 0
var _last_advance_msec: int = 0
var _dialogue_panel: PanelContainer
var _bottom_layout: MarginContainer
var _speaker_label: Label
var _text_label: RichTextLabel
var _avatar_label: Label
var _avatar_texture: TextureRect
var _continue_label: Label
var _current_target_id: String = ""
var _current_speaker_id: String = ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	_sync_viewport_rect()
	_build_ui()
	_set_non_interactive_children(self)
	_show_current_step()
	ClassicalTheme.fade_in(self, 0.18)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_layout_metrics()


func _input(event: InputEvent) -> void:
	if not visible or _is_modal_active():
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and (mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			if has_node("/root/NarrativeManager"):
				NarrativeManager.handle_overlay_wheel(mouse_event.button_index, mouse_event.ctrl_pressed)
			get_viewport().set_input_as_handled()
			return
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_try_advance()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			_try_advance()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and not key_event.echo and (key_event.keycode == KEY_ENTER or key_event.keycode == KEY_SPACE):
			_try_advance()
			get_viewport().set_input_as_handled()


func setup(steps: Array, target_map: Dictionary = {}) -> void:
	_steps = _paginate_dialogue_steps(steps)
	_target_map = target_map.duplicate()
	_index = 0
	if is_inside_tree():
		_show_current_step()


func update_target_map(target_map: Dictionary) -> void:
	_target_map = target_map.duplicate()
	queue_redraw()


func _process(_delta: float) -> void:
	if visible:
		_sync_viewport_rect()
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if mouse_event.pressed and has_node("/root/NarrativeManager"):
				NarrativeManager.handle_overlay_wheel(mouse_event.button_index, mouse_event.ctrl_pressed)
			accept_event()
			get_viewport().set_input_as_handled()
			return
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_try_advance()
			accept_event()
			get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), ClassicalTheme.DIM_OVERLAY, true)
	var current_target: Control = _lookup_target(_current_target_id)
	if current_target == null or not current_target.visible:
		return
	var rect: Rect2 = _target_rect(current_target)
	if rect.size.x <= 2.0 or rect.size.y <= 2.0:
		return
	var padding: float = 8.0
	rect.position -= Vector2(padding, padding)
	rect.size += Vector2(padding * 2.0, padding * 2.0)
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 1000.0 * TAU / 1.25)
	var glow_color: Color = Color(0.95, 0.68, 0.22, 0.10 + pulse * 0.08)
	var edge_color: Color = Color(0.98, 0.75, 0.30, 0.78 + pulse * 0.20)
	var glow: StyleBoxFlat = StyleBoxFlat.new()
	glow.bg_color = glow_color
	glow.border_color = edge_color
	glow.set_border_width_all(2)
	glow.set_corner_radius_all(10)
	glow.shadow_color = Color(0.95, 0.60, 0.18, 0.20 + pulse * 0.16)
	glow.shadow_size = 14
	draw_style_box(glow, rect)


func _build_ui() -> void:
	_bottom_layout = MarginContainer.new()
	_bottom_layout.name = "DialogueBottomLayout"
	_bottom_layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bottom_layout)

	var vertical_layout: VBoxContainer = VBoxContainer.new()
	vertical_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vertical_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bottom_layout.add_child(vertical_layout)

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vertical_layout.add_child(spacer)

	_dialogue_panel = PanelContainer.new()
	_dialogue_panel.name = "DialogueBox"
	_dialogue_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dialogue_panel.size_flags_vertical = Control.SIZE_SHRINK_END
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
	_avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_avatar_label.add_theme_stylebox_override("normal", _avatar_style())
	_avatar_label.modulate = ClassicalTheme.TEXT_MAIN
	row.add_child(_avatar_label)

	_avatar_texture = TextureRect.new()
	_avatar_texture.name = "SpeakerBadgeTexture"
	_avatar_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_avatar_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_avatar_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar_texture.visible = false
	_avatar_label.add_child(_avatar_texture)

	var text_box: VBoxContainer = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 8)
	row.add_child(text_box)

	_speaker_label = Label.new()
	_speaker_label.modulate = ClassicalTheme.ACCENT_GOLD
	text_box.add_child(_speaker_label)

	_text_label = RichTextLabel.new()
	_text_label.scroll_active = false
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.modulate = ClassicalTheme.TEXT_MAIN
	text_box.add_child(_text_label)

	_continue_label = Label.new()
	_continue_label.text = "单击以继续"
	_continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_label.modulate = Color(0.86, 0.68, 0.36, 0.92)
	text_box.add_child(_continue_label)
	_update_layout_metrics()


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
	var page_index: int = int(step.get("_page_index", 0))
	var page_count: int = int(step.get("_page_count", 1))
	var target_id: String = str(step.get("target", step.get("target_ui", "")))
	_current_speaker_id = str(step.get("speaker_id", ""))
	var avatar_id: String = str(step.get("avatar", ""))

	_speaker_label.text = speaker
	_text_label.text = text
	_continue_label.text = "%s  %d/%d" % [continue_text, page_index + 1, page_count] if page_count > 1 else continue_text
	var badge_texture := ArtAssetRegistry.texture_for_character(_current_speaker_id, avatar_id)
	if badge_texture != null:
		_avatar_texture.texture = badge_texture
		_avatar_texture.visible = true
		_avatar_label.text = ""
	else:
		_avatar_texture.visible = false
		_avatar_label.text = ArtAssetRegistry.placeholder_for_character(_current_speaker_id, avatar_id)
		if _avatar_label.text == "":
			_avatar_label.text = _avatar_initial(speaker)
	_avatar_label.add_theme_stylebox_override("normal", _avatar_style())
	_current_target_id = target_id
	queue_redraw()


func _try_advance() -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_advance_msec < 80:
		return
	_last_advance_msec = now
	_advance()


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


func _sync_viewport_rect() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	position = Vector2.ZERO
	custom_minimum_size = viewport_size
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	size = viewport_size
	_update_layout_metrics()


func _update_layout_metrics() -> void:
	if _bottom_layout == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = size
	var side_margin: int = int(roundf(clampf(viewport_size.x * 0.045, 28.0, 72.0)))
	var bottom_margin: int = int(roundf(clampf(viewport_size.y * 0.035, 20.0, 42.0)))
	_bottom_layout.add_theme_constant_override("margin_left", side_margin)
	_bottom_layout.add_theme_constant_override("margin_top", 18)
	_bottom_layout.add_theme_constant_override("margin_right", side_margin)
	_bottom_layout.add_theme_constant_override("margin_bottom", bottom_margin)
	if _dialogue_panel != null:
		var panel_height: float = clampf(viewport_size.y * 0.30, 220.0, 330.0)
		_dialogue_panel.custom_minimum_size = Vector2(0.0, panel_height)
	if _avatar_label != null:
		var avatar_size: float = clampf(viewport_size.y * 0.105, 66.0, 92.0)
		_avatar_label.custom_minimum_size = Vector2(avatar_size, avatar_size)
		_avatar_label.add_theme_font_size_override("font_size", int(roundf(avatar_size * 0.34)))
		if _avatar_texture != null:
			_avatar_texture.offset_left = 6
			_avatar_texture.offset_top = 6
			_avatar_texture.offset_right = -6
			_avatar_texture.offset_bottom = -6
	if _speaker_label != null:
		_speaker_label.add_theme_font_size_override("font_size", int(roundf(clampf(viewport_size.y * 0.026, 18.0, 23.0))))
	if _text_label != null:
		_text_label.custom_minimum_size = Vector2(0.0, clampf(viewport_size.y * 0.155, 118.0, 178.0))
		_text_label.add_theme_font_size_override("normal_font_size", int(roundf(clampf(viewport_size.y * 0.025, 18.0, 22.0))))
	if _continue_label != null:
		_continue_label.add_theme_font_size_override("font_size", int(roundf(clampf(viewport_size.y * 0.018, 13.0, 16.0))))


func _paginate_dialogue_steps(raw_steps: Array) -> Array:
	var pages: Array = []
	var max_chars: int = _dialogue_page_char_limit()
	for raw_step: Variant in raw_steps:
		if not (raw_step is Dictionary):
			continue
		var step: Dictionary = (raw_step as Dictionary).duplicate(true)
		var text: String = str(step.get("text", ""))
		var text_pages: Array[String] = _split_text_to_pages(text, max_chars)
		for page_index: int in range(text_pages.size()):
			var page_step: Dictionary = step.duplicate(true)
			page_step["text"] = text_pages[page_index]
			page_step["_page_index"] = page_index
			page_step["_page_count"] = text_pages.size()
			pages.append(page_step)
	return pages


func _dialogue_page_char_limit() -> int:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 1.0:
		return 84
	return clampi(int(roundf(viewport_size.x / 15.0)), 64, 96)


func _split_text_to_pages(text: String, max_chars: int) -> Array[String]:
	var cleaned: String = text.strip_edges()
	if cleaned.length() <= max_chars:
		return [cleaned]
	var pages: Array[String] = []
	var remaining: String = cleaned
	while remaining.length() > max_chars:
		var cut: int = _find_page_cut(remaining, max_chars)
		pages.append(remaining.substr(0, cut).strip_edges())
		remaining = remaining.substr(cut).strip_edges()
	if not remaining.is_empty():
		pages.append(remaining)
	return pages


func _find_page_cut(text: String, max_chars: int) -> int:
	var preferred: Array[String] = ["。", "；", "！", "？", "，"]
	for mark: String in preferred:
		var best: int = -1
		var search_from: int = 0
		while true:
			var found: int = text.find(mark, search_from)
			if found == -1 or found >= max_chars:
				break
			best = found + mark.length()
			search_from = found + mark.length()
		if best >= int(float(max_chars) * 0.46):
			return best
	return max_chars


func _is_modal_active() -> bool:
	if has_node("/root/NarrativeManager"):
		return bool(NarrativeManager.is_modal_active())
	return false


func _set_non_interactive_children(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Control:
			var control: Control = child as Control
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_non_interactive_children(child)


func _avatar_initial(name: String) -> String:
	if name.is_empty():
		return "?"
	return name.substr(0, 1)


func _panel_style() -> StyleBoxFlat:
	return ClassicalTheme.panel_style("dialogue", 1.0)


func _avatar_style() -> StyleBoxFlat:
	return ClassicalTheme.avatar_style(_current_speaker_id, 1.0)
