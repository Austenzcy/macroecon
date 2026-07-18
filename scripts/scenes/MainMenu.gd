extends Control


func _ready() -> void:
	call_deferred("_go_to_level_select")


func _go_to_level_select() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
