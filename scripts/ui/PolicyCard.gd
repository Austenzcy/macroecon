extends PanelContainer

signal selected(policy_id: String, policy_name: String)

const ClassicalTheme = preload("res://scripts/ui/ClassicalTheme.gd")
const ArtAssetRegistry = preload("res://scripts/ui/ArtAssetRegistry.gd")
const ArtLayoutSpecs = preload("res://scripts/ui/ArtLayoutSpecs.gd")

var policy_id: String = ""
var policy_name: String = ""
var policy_type: String = ""
var description: String = ""
var policy_cost: int = 0
var _is_selected: bool = false
var _ui_scale: float = 1.0
var _has_card_art: bool = false

var _card_root: Control
var _card_texture: TextureRect
var _fallback_panel: Panel
var _title_area: MarginContainer
var _type_area: Control
var _description_area: MarginContainer
var _cost_area: MarginContainer
var _title_label: Label
var _type_label: Label
var _type_icon_texture: TextureRect
var _type_icon_label: Label
var _description_label: Label
var _cost_label: Label
var _selected_overlay: Panel
var _disabled_overlay: ColorRect
var _stamp_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	clip_contents = false
	_build_ui()
	set_ui_scale(_ui_scale)
	_apply_style(false, false)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_layout_spec()
		queue_redraw()


func set_policy(data: Dictionary) -> void:
	policy_id = str(data.get("id", ""))
	policy_name = str(data.get("name", "Policy Card"))
	policy_type = str(data.get("type", "Policy"))
	description = str(data.get("description", ""))
	policy_cost = int(data.get("cost", data.get("default_cost", policy_cost)))
	if _title_label != null:
		_title_label.text = policy_name
		_type_label.text = policy_type
		_description_label.text = description
		_cost_label.text = "%d" % policy_cost
		_refresh_art()
		_apply_layout_spec()


func set_selected(value: bool) -> void:
	_is_selected = value
	_apply_style(false, _is_selected)


func set_ui_scale(value: float) -> void:
	_ui_scale = clampf(value, 0.8, 1.2)
	custom_minimum_size = Vector2(240, 360) * _ui_scale
	pivot_offset = custom_minimum_size * 0.5
	_apply_typography()
	_apply_layout_spec()


func set_cost(cost: int, _show_cost: bool) -> void:
	policy_cost = cost
	if _cost_label == null:
		return
	_cost_label.visible = true
	_cost_label.text = "%d" % policy_cost


func _build_ui() -> void:
	add_theme_stylebox_override("panel", _transparent_panel_style())

	_card_root = Control.new()
	_card_root.name = "PolicyCardFace"
	_card_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card_root)

	_card_texture = TextureRect.new()
	_card_texture.name = "PolicyCardFaceTexture"
	_card_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_card_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_card_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_root.add_child(_card_texture)

	_fallback_panel = Panel.new()
	_fallback_panel.name = "PolicyCardProceduralFallback"
	_fallback_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fallback_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fallback_panel.add_theme_stylebox_override("panel", ClassicalTheme.panel_style("card", _ui_scale))
	_card_root.add_child(_fallback_panel)

	_title_area = MarginContainer.new()
	_title_area.name = "TitleArea"
	_card_root.add_child(_title_area)

	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.text = policy_name
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.modulate = Color(1.0, 0.78, 0.36, 1.0)
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_area.add_child(_title_label)

	_type_area = Control.new()
	_type_area.name = "TypeBadgeArea"
	_type_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_root.add_child(_type_area)

	_type_icon_texture = TextureRect.new()
	_type_icon_texture.name = "PolicyTypeIcon"
	_type_icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_type_icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_type_icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_type_area.add_child(_type_icon_texture)

	_type_icon_label = Label.new()
	_type_icon_label.name = "PolicyTypeFallback"
	_type_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_type_icon_label.modulate = Color(0.95, 0.78, 0.42, 0.95)
	_type_icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_type_area.add_child(_type_icon_label)

	_type_label = Label.new()
	_type_label.name = "TypeLabel"
	_type_label.text = policy_type
	_type_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_type_label.clip_text = true
	_type_label.modulate = Color(0.95, 0.79, 0.45, 0.98)
	_type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_type_area.add_child(_type_label)

	_description_area = MarginContainer.new()
	_description_area.name = "DescriptionArea"
	_description_area.add_theme_constant_override("margin_left", 4)
	_description_area.add_theme_constant_override("margin_top", 2)
	_description_area.add_theme_constant_override("margin_right", 4)
	_description_area.add_theme_constant_override("margin_bottom", 2)
	_card_root.add_child(_description_area)

	_description_label = Label.new()
	_description_label.name = "DescriptionLabel"
	_description_label.text = description
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_description_label.modulate = Color(0.070, 0.045, 0.024, 1.0)
	_description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_description_area.add_child(_description_label)

	_cost_area = MarginContainer.new()
	_cost_area.name = "CostBadgeArea"
	_card_root.add_child(_cost_area)

	_cost_label = Label.new()
	_cost_label.name = "CostLabel"
	_cost_label.text = "%d" % policy_cost
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cost_label.modulate = Color(1.0, 0.78, 0.36, 1.0)
	_cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cost_area.add_child(_cost_label)

	_selected_overlay = Panel.new()
	_selected_overlay.name = "SelectedOverlay"
	_selected_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_selected_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selected_overlay.add_theme_stylebox_override("panel", _selected_overlay_style())
	_selected_overlay.visible = false
	_card_root.add_child(_selected_overlay)

	_disabled_overlay = ColorRect.new()
	_disabled_overlay.name = "DisabledOverlay"
	_disabled_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_disabled_overlay.color = Color(0.02, 0.018, 0.014, 0.0)
	_disabled_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_root.add_child(_disabled_overlay)

	_stamp_label = Label.new()
	_stamp_label.name = "SelectedStamp"
	_stamp_label.text = "已选"
	_stamp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stamp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stamp_label.modulate = Color(1.0, 0.76, 0.32, 1.0)
	_stamp_label.visible = false
	_card_root.add_child(_stamp_label)
	_refresh_art()
	_apply_typography()
	_apply_layout_spec()


func _draw() -> void:
	if not ArtLayoutSpecs.DEBUG_SAFE_AREAS:
		return
	var spec := _current_spec()
	_draw_named_safe_rect(spec[ArtLayoutSpecs.SAFE_TITLE], "title", Color(1.0, 0.72, 0.22, 0.9))
	_draw_named_safe_rect(spec[ArtLayoutSpecs.SAFE_CATEGORY], "category", Color(0.60, 1.0, 0.55, 0.9))
	_draw_named_safe_rect(spec[ArtLayoutSpecs.SAFE_DESCRIPTION], "description", Color(0.45, 0.85, 1.0, 0.9))
	_draw_named_safe_rect(spec[ArtLayoutSpecs.SAFE_COST], "cost", Color(1.0, 0.45, 0.45, 0.9))


func _current_spec() -> Dictionary:
	return ArtLayoutSpecs.policy_card_spec(policy_id)


func _apply_layout_spec() -> void:
	if _card_root == null:
		return
	var spec := _current_spec()
	if _title_area != null:
		ArtLayoutSpecs.apply_anchor_rect(_title_area, spec[ArtLayoutSpecs.SAFE_TITLE])
	if _type_area != null:
		ArtLayoutSpecs.apply_anchor_rect(_type_area, spec[ArtLayoutSpecs.SAFE_CATEGORY])
	if _description_area != null:
		ArtLayoutSpecs.apply_anchor_rect(_description_area, spec[ArtLayoutSpecs.SAFE_DESCRIPTION])
	if _cost_area != null:
		ArtLayoutSpecs.apply_anchor_rect(_cost_area, spec[ArtLayoutSpecs.SAFE_COST])
	if _stamp_label != null:
		ArtLayoutSpecs.apply_anchor_rect(_stamp_label, Rect2(0.125, 0.205, 0.220, 0.070))
	_position_type_fallback_icon()


func _apply_typography() -> void:
	if _title_label == null:
		return
	var spec := _current_spec()
	_title_label.add_theme_font_size_override("font_size", ArtLayoutSpecs.scaled_int(spec, "title_font", _ui_scale))
	_title_label.add_theme_constant_override("outline_size", 1)
	_title_label.add_theme_color_override("font_outline_color", Color(0.12, 0.07, 0.025, 0.65))
	_type_label.add_theme_font_size_override("font_size", ArtLayoutSpecs.scaled_int(spec, "category_font", _ui_scale))
	_type_icon_label.add_theme_font_size_override("font_size", int(roundf(10.0 * _ui_scale)))
	_description_label.add_theme_font_size_override("font_size", ArtLayoutSpecs.scaled_int(spec, "description_font", _ui_scale))
	_description_label.add_theme_constant_override("line_spacing", ArtLayoutSpecs.scaled_int(spec, "description_line_spacing", _ui_scale))
	_description_label.add_theme_constant_override("outline_size", 1)
	_description_label.add_theme_color_override("font_outline_color", Color(0.070, 0.045, 0.024, 0.22))
	_cost_label.add_theme_font_size_override("font_size", ArtLayoutSpecs.scaled_int(spec, "cost_font", _ui_scale))
	_cost_label.add_theme_constant_override("outline_size", 1)
	_cost_label.add_theme_color_override("font_outline_color", Color(0.10, 0.055, 0.020, 0.78))
	_stamp_label.add_theme_font_size_override("font_size", ArtLayoutSpecs.scaled_int(spec, "stamp_font", _ui_scale))


func _position_type_fallback_icon() -> void:
	if _type_area == null or _type_icon_texture == null or _type_icon_label == null:
		return
	var spec := _current_spec()
	var icon_size := float(ArtLayoutSpecs.scaled_int(spec, "type_icon_size", _ui_scale))
	var icon_rect := Rect2(Vector2(4.0 * _ui_scale, maxf((_type_area.size.y - icon_size) * 0.5, 0.0)), Vector2(icon_size, icon_size))
	for control_variant: Variant in [_type_icon_texture, _type_icon_label]:
		var control := control_variant as Control
		control.set_anchors_preset(Control.PRESET_TOP_LEFT)
		control.position = icon_rect.position
		control.size = icon_rect.size
		control.custom_minimum_size = icon_rect.size


func _set_fractional_rect(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _refresh_art() -> void:
	var card_texture := ArtAssetRegistry.texture_for_policy_card(policy_id, policy_type, policy_name)
	_has_card_art = card_texture != null
	if _has_card_art:
		_card_texture.texture = card_texture
		_card_texture.visible = true
		_fallback_panel.visible = false
	else:
		_card_texture.texture = null
		_card_texture.visible = false
		_fallback_panel.visible = true
	var type_texture := ArtAssetRegistry.texture_for_policy_type(policy_type, policy_id)
	if _has_card_art:
		_type_icon_texture.texture = null
		_type_icon_texture.visible = false
		_type_icon_label.visible = false
	elif type_texture != null:
		_type_icon_texture.texture = type_texture
		_type_icon_texture.visible = true
		_type_icon_label.visible = false
	else:
		_type_icon_texture.texture = null
		_type_icon_texture.visible = false
		_type_icon_label.visible = true
		_type_icon_label.text = ArtAssetRegistry.placeholder_for_policy_type(policy_type, policy_id)
	_position_type_fallback_icon()


func _transparent_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	return style


func _selected_overlay_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.70, 0.22, 0.035)
	style.border_color = Color(1.0, 0.76, 0.28, 0.92)
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	return style


func _on_mouse_entered() -> void:
	_apply_style(true, _is_selected)
	ClassicalTheme.hover_to(self, Vector2(1.04, 1.04), 0.10)


func _on_mouse_exited() -> void:
	_apply_style(false, _is_selected)
	ClassicalTheme.hover_to(self, Vector2.ONE, 0.10)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_is_selected = true
			_apply_style(true, true)
			selected.emit(policy_id, policy_name)


func _apply_style(is_hover: bool, is_chosen: bool) -> void:
	if _selected_overlay != null:
		_selected_overlay.visible = is_chosen or is_hover
		var style := _selected_overlay_style()
		if is_hover and not is_chosen:
			style.bg_color = Color(1.0, 0.76, 0.32, 0.025)
			style.border_color = Color(0.86, 0.62, 0.26, 0.55)
			style.set_border_width_all(2)
		_selected_overlay.add_theme_stylebox_override("panel", style)
	if _stamp_label != null:
		_stamp_label.visible = is_chosen
	if _disabled_overlay != null:
		_disabled_overlay.color = Color(0.02, 0.018, 0.014, 0.0)


func _draw_named_safe_rect(rect_ratio: Rect2, label: String, color: Color) -> void:
	var rect := Rect2(
		Vector2(rect_ratio.position.x * size.x, rect_ratio.position.y * size.y),
		Vector2(rect_ratio.size.x * size.x, rect_ratio.size.y * size.y)
	)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.08), true)
	draw_rect(rect, color, false, 1.0)
	var font := get_theme_default_font()
	if font != null:
		draw_string(font, rect.position + Vector2(4, 13), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, color)
