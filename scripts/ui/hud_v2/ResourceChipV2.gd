extends PanelContainer

const HudV2Theme = preload("res://scripts/ui/hud_v2/HudV2Theme.gd")
const HudIconScript = preload("res://scripts/ui/hud_v2/HudIcon.gd")

var _icon: Control
var _label: Label
var _prefix: String = ""
var _tone: String = "system"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _label == null:
		_build()


func setup(icon_type: String, label_prefix: String, value_text: String, tone: String = "system") -> void:
	_prefix = label_prefix
	_tone = tone
	if _label == null:
		_build()
	add_theme_stylebox_override("panel", HudV2Theme.chip_style(tone))
	var accent: Color = HudV2Theme.ACCENT_RESOURCE if tone == "resource" else HudV2Theme.ACCENT_SYSTEM
	_icon.call("setup", icon_type, accent, 1.8)
	set_value(value_text)


func set_value(value_text: String) -> void:
	if _label == null:
		return
	_label.text = "%s %s" % [_prefix, value_text]


func get_label_control() -> Label:
	return _label


func _build() -> void:
	add_theme_stylebox_override("panel", HudV2Theme.chip_style(_tone))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	add_child(row)

	_icon = HudIconScript.new() as Control
	_icon.custom_minimum_size = Vector2(24, 24)
	row.add_child(_icon)

	_label = Label.new()
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 14)
	_label.modulate = HudV2Theme.TEXT_TITLE
	row.add_child(_label)
