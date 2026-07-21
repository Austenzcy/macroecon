extends PanelContainer

signal selected(policy_id: String, policy_name: String)

const ClassicalTheme = preload("res://scripts/ui/ClassicalTheme.gd")
const ArtAssetRegistry = preload("res://scripts/ui/ArtAssetRegistry.gd")

var policy_id: String = ""
var policy_name: String = ""
var policy_type: String = ""
var description: String = ""
var _is_selected: bool = false
var _ui_scale: float = 1.0

var _name_label: Label
var _type_label: Label
var _type_icon_label: Label
var _type_icon_texture: TextureRect
var _type_icon_shell: PanelContainer
var _cost_label: Label
var _description_label: Label
var _stamp_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	set_ui_scale(_ui_scale)
	_apply_style(false, false)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)


func set_policy(data: Dictionary) -> void:
	policy_id = str(data.get("id", ""))
	policy_name = str(data.get("name", "政策卡"))
	policy_type = str(data.get("type", "政策"))
	description = str(data.get("description", ""))
	if _name_label != null:
		_name_label.text = policy_name
		_type_label.text = policy_type
		_description_label.text = description
		_refresh_type_icon()


func set_selected(value: bool) -> void:
	_is_selected = value
	_apply_style(false, _is_selected)


func set_ui_scale(value: float) -> void:
	_ui_scale = clampf(value, 0.8, 1.2)
	custom_minimum_size = Vector2(210, 180) * _ui_scale
	pivot_offset = custom_minimum_size * 0.5
	if _name_label != null:
		_name_label.add_theme_font_size_override("font_size", int(roundf(24.0 * _ui_scale)))
		_type_label.add_theme_font_size_override("font_size", int(roundf(15.0 * _ui_scale)))
		_type_icon_label.add_theme_font_size_override("font_size", int(roundf(13.0 * _ui_scale)))
		_type_icon_shell.custom_minimum_size = Vector2(28, 28) * _ui_scale
		_cost_label.add_theme_font_size_override("font_size", int(roundf(14.0 * _ui_scale)))
		_description_label.add_theme_font_size_override("font_size", int(roundf(16.0 * _ui_scale)))
		_stamp_label.add_theme_font_size_override("font_size", int(roundf(15.0 * _ui_scale)))


func set_cost(cost: int, show_cost: bool) -> void:
	if _cost_label == null:
		return
	_cost_label.visible = show_cost
	_cost_label.text = "消耗 %d 点" % cost


func _build_ui() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	_name_label = Label.new()
	_name_label.text = policy_name
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.add_theme_font_size_override("font_size", 24)
	ClassicalTheme.apply_label_color(_name_label, "title")
	box.add_child(_name_label)

	var type_row: HBoxContainer = HBoxContainer.new()
	type_row.add_theme_constant_override("separation", 8)
	box.add_child(type_row)

	_type_icon_shell = PanelContainer.new()
	_type_icon_shell.custom_minimum_size = Vector2(28, 28)
	_type_icon_shell.add_theme_stylebox_override("panel", _icon_shell_style())
	type_row.add_child(_type_icon_shell)

	_type_icon_label = Label.new()
	_type_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_type_icon_label.add_theme_font_size_override("font_size", 13)
	_type_icon_label.modulate = ClassicalTheme.TEXT_MAIN
	_type_icon_shell.add_child(_type_icon_label)

	_type_icon_texture = TextureRect.new()
	_type_icon_texture.name = "PolicyTypeIconTexture"
	_type_icon_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_type_icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_type_icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_type_icon_texture.visible = false
	_type_icon_texture.offset_left = 4
	_type_icon_texture.offset_top = 4
	_type_icon_texture.offset_right = -4
	_type_icon_texture.offset_bottom = -4
	_type_icon_shell.add_child(_type_icon_texture)

	_type_label = Label.new()
	_type_label.text = policy_type
	_type_label.add_theme_font_size_override("font_size", 15)
	_type_label.modulate = ClassicalTheme.ACCENT_BLUE
	_type_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	type_row.add_child(_type_label)

	_cost_label = Label.new()
	_cost_label.visible = false
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cost_label.modulate = ClassicalTheme.ACCENT_GOLD
	box.add_child(_cost_label)

	var line: ColorRect = ColorRect.new()
	line.custom_minimum_size = Vector2(0, 2)
	line.color = Color(0.62, 0.43, 0.20, 0.86)
	box.add_child(line)

	_description_label = Label.new()
	_description_label.text = description
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.add_theme_font_size_override("font_size", 16)
	_description_label.modulate = ClassicalTheme.TEXT_SOFT
	box.add_child(_description_label)

	_stamp_label = Label.new()
	_stamp_label.text = "已选"
	_stamp_label.visible = false
	_stamp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stamp_label.modulate = ClassicalTheme.ACCENT_GOLD
	box.add_child(_stamp_label)
	_refresh_type_icon()


func _refresh_type_icon() -> void:
	if _type_icon_label == null:
		return
	var texture := ArtAssetRegistry.texture_for_policy_type(policy_type, policy_id)
	if texture != null:
		_type_icon_texture.texture = texture
		_type_icon_texture.visible = true
		_type_icon_label.text = ""
	else:
		_type_icon_texture.visible = false
		_type_icon_label.text = ArtAssetRegistry.placeholder_for_policy_type(policy_type, policy_id)


func _icon_shell_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.12, 0.08, 0.92)
	style.border_color = Color(0.62, 0.43, 0.20, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style


func _on_mouse_entered() -> void:
	_apply_style(true, _is_selected)
	ClassicalTheme.hover_to(self, Vector2(1.035, 1.035), 0.10)


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
	var kind: String = "card_selected" if is_chosen else ("card_hover" if is_hover else "card")
	add_theme_stylebox_override("panel", ClassicalTheme.panel_style(kind, _ui_scale))
	if _stamp_label != null:
		_stamp_label.visible = is_chosen
