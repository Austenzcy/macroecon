extends Control


func _ready() -> void:
	var label: Label = Label.new()
	label.text = "Settings / 设置页\n当前为占位场景。"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(label)
