extends PanelContainer

signal selected(policy_id: String, policy_name: String)

var policy_id: String = ""
var policy_name: String = ""
var policy_type: String = ""
var description: String = ""
var _is_selected: bool = false
var _ui_scale: float = 1.0

var _name_label: Label
var _type_label: Label
var _cost_label: Label
var _description_label: Label


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
		_cost_label.add_theme_font_size_override("font_size", int(roundf(14.0 * _ui_scale)))
		_description_label.add_theme_font_size_override("font_size", int(roundf(16.0 * _ui_scale)))


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
	box.add_child(_name_label)

	_type_label = Label.new()
	_type_label.text = policy_type
	_type_label.add_theme_font_size_override("font_size", 15)
	_type_label.modulate = Color(0.72, 0.86, 1.0)
	box.add_child(_type_label)

	_cost_label = Label.new()
	_cost_label.visible = false
	_cost_label.modulate = Color(0.92, 0.80, 0.46)
	box.add_child(_cost_label)

	var line: ColorRect = ColorRect.new()
	line.custom_minimum_size = Vector2(0, 2)
	line.color = Color(0.38, 0.62, 0.86, 0.9)
	box.add_child(line)

	_description_label = Label.new()
	_description_label.text = description
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.add_theme_font_size_override("font_size", 16)
	_description_label.modulate = Color(0.86, 0.91, 0.95)
	box.add_child(_description_label)


func _on_mouse_entered() -> void:
	_apply_style(true, _is_selected)
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.035, 1.035), 0.10)


func _on_mouse_exited() -> void:
	_apply_style(false, _is_selected)
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.10)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_is_selected = true
			_apply_style(true, true)
			selected.emit(policy_id, policy_name)


func _apply_style(is_hover: bool, is_chosen: bool) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.15, 0.20, 0.96)
	if is_hover:
		style.bg_color = Color(0.13, 0.20, 0.27, 0.98)
	if is_chosen:
		style.bg_color = Color(0.16, 0.24, 0.30, 1.0)
	style.border_color = Color(0.35, 0.55, 0.72, 0.85)
	if is_chosen:
		style.border_color = Color(0.92, 0.78, 0.38, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 8
	add_theme_stylebox_override("panel", style)
