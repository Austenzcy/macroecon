extends Control

signal confirmed
signal cancelled

var _message: String = ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()


func setup(message: String) -> void:
	_message = message


func _build_ui() -> void:
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.58)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel: PanelContainer = PanelContainer.new()
	panel.name = "HintConfirmBox"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(430, 210)
	panel.offset_left = -215.0
	panel.offset_top = -105.0
	panel.offset_right = 215.0
	panel.offset_bottom = 105.0
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)

	var title: Label = Label.new()
	title.text = "确认查看提示"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)

	var body: Label = Label.new()
	body.text = _message
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.modulate = Color(0.86, 0.92, 0.96)
	body.add_theme_font_size_override("font_size", 17)
	box.add_child(body)

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)

	var cancel_button: Button = Button.new()
	cancel_button.text = "取消"
	cancel_button.custom_minimum_size = Vector2(96, 40)
	cancel_button.pressed.connect(_on_cancel_pressed)
	buttons.add_child(cancel_button)

	var confirm_button: Button = Button.new()
	confirm_button.text = "确认"
	confirm_button.custom_minimum_size = Vector2(96, 40)
	confirm_button.pressed.connect(_on_confirm_pressed)
	buttons.add_child(confirm_button)


func _on_confirm_pressed() -> void:
	confirmed.emit()
	queue_free()


func _on_cancel_pressed() -> void:
	cancelled.emit()
	queue_free()


func _panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.085, 0.10, 0.98)
	style.border_color = Color(0.52, 0.70, 0.82, 0.92)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = 16
	return style
