extends Control

var _title: Label
var _description: Label
var _meta: Label
var _content: Control
var _tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()

func _build() -> void:
	# The outer control belongs to responsive layout. Only this inner layer is
	# animated, preventing layout updates from turning a small offset into a jump.
	_content = Control.new()
	_content.position = Vector2.ZERO
	_content.size = size
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)

	_meta = Label.new()
	_meta.position = Vector2(0, 0)
	_meta.add_theme_font_size_override("font_size", 16)
	_meta.add_theme_color_override("font_color", Color(0.91, 0.73, 0.39, 0.88))
	_content.add_child(_meta)

	_title = Label.new()
	_title.position = Vector2(0, 27)
	_title.size = Vector2(608, 61)
	_title.add_theme_font_size_override("font_size", 42)
	_title.add_theme_color_override("font_color", Color(0.94, 0.96, 0.97, 1.0))
	_title.add_theme_constant_override("outline_size", 6)
	_title.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.03, 0.5))
	_content.add_child(_title)

	_description = Label.new()
	_description.position = Vector2(2, 86)
	_description.size = Vector2(576, 54)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.add_theme_font_size_override("font_size", 18)
	_description.add_theme_color_override("font_color", Color(0.68, 0.74, 0.78, 1.0))
	_description.add_theme_constant_override("line_spacing", 4)
	_content.add_child(_description)

func show_level(data: Dictionary, index: int, total: int, immediate := false) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	var title_text := str(data.get("title", ""))
	var description_text := str(data.get("description", ""))

	var apply_text := func() -> void:
		_meta.text = "IS-LM 档案  %02d / %02d" % [index + 1, total]
		_title.text = title_text
		_description.text = description_text
		_title.add_theme_font_size_override("font_size", 34 if title_text.length() > 15 else 42)
		_title.visible_characters = -1 if immediate else 0
		_description.visible_characters = -1 if immediate else 0

	if immediate:
		apply_text.call()
		modulate.a = 1.0
		_content.position.y = 0.0
		return

	_tween = create_tween().set_parallel(false)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 0.0, 0.11)
	_tween.parallel().tween_property(_content, "position:y", -6.0, 0.11)
	_tween.tween_callback(apply_text)
	_tween.tween_property(_content, "position:y", 0.0, 0.01)
	_tween.tween_property(self, "modulate:a", 1.0, 0.16)
	_tween.parallel().tween_method(_set_title_characters, 0, title_text.length(), 0.42)
	_tween.tween_interval(0.05)
	_tween.tween_method(_set_description_characters, 0, description_text.length(), 0.5)

func _set_title_characters(value: int) -> void:
	_title.visible_characters = value

func _set_description_characters(value: int) -> void:
	_description.visible_characters = value
