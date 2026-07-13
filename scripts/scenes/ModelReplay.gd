extends Control


func _ready() -> void:
	var label: Label = Label.new()
	label.text = "ModelReplay / 模型回放页\n下一阶段实现 IS-LM 曲线移动。"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(label)
