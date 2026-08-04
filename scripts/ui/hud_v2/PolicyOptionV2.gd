extends PanelContainer

signal selected(policy_id: String, policy_name: String)

const HudV2Theme = preload("res://scripts/ui/hud_v2/HudV2Theme.gd")
const HudIconScript = preload("res://scripts/ui/hud_v2/HudIcon.gd")

var policy_id: String = ""
var policy_name: String = ""
var policy_type: String = ""
var description: String = ""
var policy_cost: int = 1

var _ui_scale: float = 1.0
var _is_selected: bool = false
var _is_hover: bool = false
var _is_disabled: bool = false
var _icon: Control
var _title: Label
var _description: Label
var _cost_icon: Control
var _cost_label: Label
var _accent_bar: ColorRect


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	_build()
	_sync_content()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	_apply_state()


func setup(data: Dictionary, cost: int, ui_scale: float = 1.0) -> void:
	policy_id = str(data.get("id", ""))
	policy_name = str(data.get("name", "Policy"))
	policy_type = str(data.get("type", ""))
	description = str(data.get("description", ""))
	policy_cost = cost
	_ui_scale = clampf(ui_scale, 0.72, 1.0)
	custom_minimum_size = Vector2(238, 92) * _ui_scale
	if _title == null:
		return
	_sync_content()
	_apply_state()


func set_selected(value: bool) -> void:
	_is_selected = value
	_apply_state()


func set_disabled(value: bool) -> void:
	_is_disabled = value
	_apply_state()


func set_cost(cost: int, _show_cost: bool = true) -> void:
	policy_cost = cost
	if _cost_label != null:
		_cost_label.text = str(policy_cost)


func _build() -> void:
	add_theme_stylebox_override("panel", _style())
	_accent_bar = ColorRect.new()
	_accent_bar.color = HudV2Theme.ACCENT_SYSTEM
	_accent_bar.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_accent_bar.offset_right = 3
	add_child(_accent_bar)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	margin.add_child(row)

	var icon_shell := PanelContainer.new()
	icon_shell.custom_minimum_size = Vector2(44, 44)
	icon_shell.add_theme_stylebox_override("panel", HudV2Theme.chip_style("system"))
	row.add_child(icon_shell)
	_icon = HudIconScript.new() as Control
	_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icon.offset_left = 7
	_icon.offset_top = 7
	_icon.offset_right = -7
	_icon.offset_bottom = -7
	icon_shell.add_child(_icon)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 3)
	row.add_child(text_box)

	_title = Label.new()
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.clip_text = true
	_title.modulate = HudV2Theme.TEXT_TITLE
	text_box.add_child(_title)

	_description = Label.new()
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_description.clip_text = true
	_description.modulate = HudV2Theme.TEXT_BODY
	text_box.add_child(_description)

	var cost_row := HBoxContainer.new()
	cost_row.alignment = BoxContainer.ALIGNMENT_END
	cost_row.add_theme_constant_override("separation", 4)
	text_box.add_child(cost_row)
	_cost_icon = HudIconScript.new() as Control
	_cost_icon.custom_minimum_size = Vector2(18, 18)
	cost_row.add_child(_cost_icon)
	_cost_label = Label.new()
	_cost_label.modulate = HudV2Theme.ACCENT_RESOURCE
	_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_row.add_child(_cost_label)
	_sync_content()


func _sync_content() -> void:
	if _title == null:
		return
	_title.text = policy_name
	_description.text = _short_description(description)
	_cost_label.text = str(policy_cost)
	_icon.call("setup", _icon_type(), HudV2Theme.ACCENT_SYSTEM, 1.9)
	_cost_icon.call("setup", "policy_point", HudV2Theme.ACCENT_RESOURCE, 1.6)
	_apply_typography()


func _apply_typography() -> void:
	_title.add_theme_font_size_override("font_size", HudV2Theme.font(17, _ui_scale))
	_title.add_theme_constant_override("outline_size", 1)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
	_description.add_theme_font_size_override("font_size", HudV2Theme.font(13, _ui_scale))
	_description.add_theme_constant_override("line_spacing", 1)
	_cost_label.add_theme_font_size_override("font_size", HudV2Theme.font(15, _ui_scale))


func _apply_state() -> void:
	if _accent_bar != null:
		_accent_bar.visible = _is_selected
	add_theme_stylebox_override("panel", _style())
	modulate = Color(1, 1, 1, 0.42 if _is_disabled else 1.0)
	var target_scale := Vector2.ONE
	if _is_hover and not _is_disabled:
		target_scale = Vector2(1.012, 1.012)
	if _is_selected:
		target_scale = Vector2(1.018, 1.018)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.14)


func _style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var alpha := 0.34
	if _is_hover:
		alpha = 0.48
	if _is_selected:
		alpha = 0.58
	style.bg_color = Color(0.014, 0.042, 0.054, alpha)
	style.border_color = Color(HudV2Theme.ACCENT_SYSTEM.r, HudV2Theme.ACCENT_SYSTEM.g, HudV2Theme.ACCENT_SYSTEM.b, 0.14 if not _is_selected else 0.52)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	return style


func _icon_type() -> String:
	var probe := "%s %s %s" % [policy_id, policy_name, policy_type]
	if probe.find("tax") >= 0 or probe.find("税") >= 0:
		return "tax"
	if probe.find("monetary") >= 0 or probe.find("货币") >= 0 or probe.find("利率") >= 0:
		return "monetary"
	if probe.find("fiscal") >= 0 or probe.find("政府") >= 0 or probe.find("购买") >= 0:
		return "government"
	return "policy_point"


func _short_description(text: String) -> String:
	var cleaned := text.strip_edges().replace("\n", " ")
	if cleaned.length() <= 42:
		return cleaned
	return cleaned.substr(0, 40) + "…"


func _on_mouse_entered() -> void:
	_is_hover = true
	_apply_state()


func _on_mouse_exited() -> void:
	_is_hover = false
	_apply_state()


func _on_gui_input(event: InputEvent) -> void:
	if _is_disabled:
		return
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
			selected.emit(policy_id, policy_name)
