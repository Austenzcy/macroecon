extends Control

signal activated(index: int)

const LockIconScript = preload("res://scripts/ui/level_select/LockIcon.gd")

const CARD_SIZE := Vector2(318.0, 430.0)
const RADIUS_FACTOR := 0.355

var card_index := 0
var level: Dictionary = {}

var _panel: Panel
var _border: Panel
var _image: TextureRect
var _shade: ColorRect
var _lock_mask: ColorRect
var _lock_icon: Control
var _number: Label
var _selected := false
var _cover_loaded := false

func setup(index: int, data: Dictionary, load_cover_immediately := false) -> void:
	card_index = index
	level = data
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	pivot_offset = CARD_SIZE * 0.5
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_ALL
	_build_card()
	if load_cover_immediately:
		ensure_cover_loaded()

func _build_card() -> void:
	_panel = Panel.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	_image = TextureRect.new()
	_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_image)

	_shade = ColorRect.new()
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.color = Color(0.01, 0.025, 0.04, 0.15)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_shade)

	if not bool(level.get("unlocked", false)):
		_build_locked_state()

	_number = Label.new()
	_number.position = Vector2(18, 15)
	_number.text = "%02d" % int(level.get("order", card_index + 1))
	_number.add_theme_font_size_override("font_size", 16)
	_number.add_theme_color_override("font_color", Color(0.94, 0.82, 0.57, 0.92))
	_number.add_theme_constant_override("outline_size", 5)
	_number.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04, 0.78))
	_number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_number)

	# Draw the highlight after the image at the exact same bounds. Previously
	# the image was inset by two pixels while the rounded border was painted by
	# the parent Panel. Fractional scale/rotation then exposed the dark panel
	# background and made the two rasterized edges appear to follow different
	# trajectories during carousel motion.
	_border = Panel.new()
	_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_border)

	_apply_panel_style(false)

func _build_locked_state() -> void:
	_lock_mask = ColorRect.new()
	_lock_mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lock_mask.color = Color(0.53, 0.54, 0.56, 0.30)
	_lock_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_lock_mask)

	_lock_icon = LockIconScript.new()
	_lock_icon.size = Vector2(96, 106)
	_lock_icon.position = (CARD_SIZE - _lock_icon.size) * 0.5
	_lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_lock_icon)

func ensure_cover_loaded() -> void:
	if _cover_loaded:
		return
	var cover_path := str(level.get("cover", ""))
	if cover_path.is_empty():
		return
	_image.texture = load(cover_path)
	_cover_loaded = _image.texture != null

func is_cover_loaded() -> bool:
	return _cover_loaded

func is_locked() -> bool:
	return not bool(level.get("unlocked", false))

func apply_cylinder_state(angle: float, viewport_size: Vector2, selected_index: int) -> void:
	var wrapped := wrapf(angle + PI, 0.0, TAU) - PI
	var depth := cos(wrapped)
	var frontness := clampf((depth + 0.35) / 1.35, 0.0, 1.0)
	var cylinder_x := sin(wrapped) * viewport_size.x * RADIUS_FACTOR
	var viewport_scale := clampf(viewport_size.y / 900.0, 0.82, 1.0)
	var scale_value := lerpf(0.56, 1.055, pow(frontness, 1.35)) * viewport_scale

	visible = depth > -0.47
	if not visible:
		return

	position = Vector2(
		viewport_size.x * 0.52 + cylinder_x - CARD_SIZE.x * 0.5,
		viewport_size.y * 0.43 - CARD_SIZE.y * 0.5 + (1.0 - depth) * 32.0
	)
	scale = Vector2.ONE * scale_value
	rotation = -sin(wrapped) * 0.17
	modulate.a = lerpf(0.12, 1.0, pow(frontness, 1.2))
	z_index = int(depth * 20.0)

	_shade.color.a = lerpf(0.58, 0.06, frontness)
	var now_selected := card_index == selected_index
	if now_selected != _selected:
		_selected = now_selected
		_apply_panel_style(_selected)

func _apply_panel_style(is_selected: bool) -> void:
	var surface_style := StyleBoxFlat.new()
	surface_style.bg_color = Color(0.025, 0.038, 0.05, 1.0)
	surface_style.corner_radius_top_left = 14
	surface_style.corner_radius_top_right = 14
	surface_style.corner_radius_bottom_left = 14
	surface_style.corner_radius_bottom_right = 14
	surface_style.shadow_color = Color(0.82, 0.58, 0.22, 0.28) if is_selected else Color(0.0, 0.0, 0.0, 0.35)
	surface_style.shadow_size = 26 if is_selected else 12
	surface_style.anti_aliasing = true
	_panel.add_theme_stylebox_override("panel", surface_style)

	var border_style := StyleBoxFlat.new()
	border_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	border_style.corner_radius_top_left = 14
	border_style.corner_radius_top_right = 14
	border_style.corner_radius_bottom_left = 14
	border_style.corner_radius_bottom_right = 14
	border_style.set_border_width_all(2 if is_selected else 1)
	border_style.border_color = Color(0.91, 0.73, 0.39, 0.94) if is_selected else Color(0.55, 0.65, 0.72, 0.25)
	border_style.anti_aliasing = true
	_border.add_theme_stylebox_override("panel", border_style)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		activated.emit(card_index)
		accept_event()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
		activated.emit(card_index)
		accept_event()
