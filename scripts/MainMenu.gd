extends Control

@onready var _start_button: Button = $VBoxContainer/StartButton


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)


func _on_start_pressed() -> void:
	AudioManager.unlock_audio_from_user_gesture()
	AudioManager.play_bgm()
	get_tree().change_scene_to_file("res://TestScene.tscn")
