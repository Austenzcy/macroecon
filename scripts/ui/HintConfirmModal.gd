extends Control

signal confirmed
signal cancelled

const ClassicalTheme = preload("res://scripts/ui/ClassicalTheme.gd")

var _message: String = ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	_sync_viewport_rect()
	_build_ui()
	ClassicalTheme.fade_in(self, 0.18)


func _process(_delta: float) -> void:
	_sync_viewport_rect()


func setup(message: String) -> void:
	_message = message


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


func _build_ui() -> void:
	var dim: ColorRect = ColorRect.new()
	dim.color = ClassicalTheme.DIM_OVERLAY
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.name = "HintConfirmBox"
	panel.custom_minimum_size = Vector2(460, 230)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

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
	ClassicalTheme.apply_label_color(title, "title")
	box.add_child(title)

	var body: Label = Label.new()
	body.text = _message
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ClassicalTheme.apply_label_color(body, "soft")
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
	ClassicalTheme.apply_button(cancel_button, 1.0, "quiet")
	cancel_button.pressed.connect(_on_cancel_pressed)
	buttons.add_child(cancel_button)

	var confirm_button: Button = Button.new()
	confirm_button.text = "确认"
	confirm_button.custom_minimum_size = Vector2(96, 40)
	ClassicalTheme.apply_button(confirm_button, 1.0, "primary")
	confirm_button.pressed.connect(_on_confirm_pressed)
	buttons.add_child(confirm_button)


func _on_confirm_pressed() -> void:
	confirmed.emit()
	queue_free()


func _on_cancel_pressed() -> void:
	cancelled.emit()
	queue_free()


func _panel_style() -> StyleBoxFlat:
	return ClassicalTheme.panel_style("modal", 1.0)
