extends Control


func _ready() -> void:
	_show_placeholder("Result / 结算页", "下一阶段接入政策结算与学习总结。")


func _show_placeholder(title_text: String, body_text: String) -> void:
	var label: Label = Label.new()
	label.text = "%s\n%s" % [title_text, body_text]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(label)
