extends Control

const ArtAssetRegistry = preload("res://scripts/ui/ArtAssetRegistry.gd")
const MacroMapArtSpec = preload("res://scripts/ui/map/MacroMapArtSpec.gd")
const UIInteractionConfig = preload("res://scripts/ui/UIInteractionConfig.gd")
const MASTER_MAP_TEXTURE: Texture2D = preload("res://assets/art/map/macro_map_master_v1.webp")
const REGION_LAYER_TEXTURES := {
	"consumption": preload("res://assets/art/map/regions/macro_map_region_consumption_v1.png"),
	"industry": preload("res://assets/art/map/regions/macro_map_region_industry_v1.png"),
	"finance": preload("res://assets/art/map/regions/macro_map_region_finance_v1.png"),
	"government": preload("res://assets/art/map/regions/macro_map_region_government_v1.png")
}

var _ui_scale: float = 1.0
var _map_texture: Texture2D
var _map_rect: Rect2 = Rect2()
var _region_textures: Dictionary = {}
var _region_masks: Dictionary = {}
var _region_pivots: Dictionary = {}
var _regions: Dictionary = {}
var _region_panels: Dictionary = {}
var _region_titles: Dictionary = {}
var _region_line_boxes: Dictionary = {}
var _hovered_region_id: String = ""
var _hover_progress: Dictionary = {}
var _hover_tweens: Dictionary = {}
var _last_mouse_viewport_position: Vector2 = Vector2.ZERO
var _debug_hit_text: String = ""
var _map_pan_offset: Vector2 = Vector2.ZERO
var _is_dragging_map: bool = false
var _last_drag_position: Vector2 = Vector2.ZERO

var _tooltip_layer: CanvasLayer
var _tooltip_panel: PanelContainer
var _tooltip_margin: MarginContainer
var _tooltip_box: VBoxContainer
var _tooltip_title: Label
var _tooltip_lines: VBoxContainer
var _tooltip_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	mouse_exited.connect(_on_mouse_exited)
	_map_texture = _resolve_master_texture()
	_load_region_layer_textures()
	_load_region_mask_images()
	custom_minimum_size = MacroMapArtSpec.MINIMUM_SIZE * _ui_scale
	_rebuild_region_nodes()
	_build_tooltip()
	_layout_region_nodes()
	queue_redraw()


func has_master_texture() -> bool:
	return _resolve_master_texture() != null


func set_ui_scale(value: float) -> void:
	_ui_scale = UIInteractionConfig.normalized_scale(value)
	custom_minimum_size = MacroMapArtSpec.MINIMUM_SIZE * _ui_scale
	_clear_hover(false)
	_refresh_tooltip_metrics()
	call_deferred("_layout_region_nodes")
	queue_redraw()


func clear_hover_state() -> void:
	_clear_hover(false)


func set_regions(regions: Array) -> void:
	_regions.clear()
	for item: Variant in regions:
		if item is Dictionary:
			var data: Dictionary = (item as Dictionary).duplicate(true)
			var region_id: String = str(data.get("region_id", ""))
			if not region_id.is_empty():
				_regions[region_id] = data
	_rebuild_region_nodes()
	_refresh_region_text()
	_layout_region_nodes()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_map_pan_offset = _clamped_pan_offset(_map_pan_offset)
		_layout_region_nodes()
		_clear_hover(false)
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_event: InputEventMouseMotion = event
		handle_viewport_input(event, get_viewport().get_mouse_position(), Input.is_key_pressed(KEY_SPACE), true)
	elif event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_clear_hover(false)
		else:
			handle_viewport_input(event, get_viewport().get_mouse_position(), Input.is_key_pressed(KEY_SPACE), true)


func handle_viewport_input(event: InputEvent, viewport_position: Vector2, space_pressed: bool = false, allow_hover: bool = true) -> bool:
	if event is InputEventMouseButton:
		var button_event: InputEventMouseButton = event
		var drag_button: bool = button_event.button_index == MOUSE_BUTTON_MIDDLE or (button_event.button_index == MOUSE_BUTTON_LEFT and space_pressed)
		if drag_button:
			if button_event.pressed and allow_hover:
				_begin_map_drag(viewport_position)
				return true
			if not button_event.pressed and _is_dragging_map:
				_end_map_drag()
				return true
		if button_event.button_index == MOUSE_BUTTON_WHEEL_UP or button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_clear_hover(false)
			return false
	if event is InputEventMouseMotion:
		var motion_event: InputEventMouseMotion = event
		_last_mouse_viewport_position = viewport_position
		if _is_dragging_map:
			_pan_map(viewport_position - _last_drag_position)
			_last_drag_position = viewport_position
			return true
		if allow_hover:
			_update_hover_at_local_position(_viewport_to_local(viewport_position))
		else:
			_clear_hover(false)
	return false


func _begin_map_drag(viewport_position: Vector2) -> void:
	_is_dragging_map = true
	_last_drag_position = viewport_position
	_clear_hover(false)
	mouse_default_cursor_shape = Control.CURSOR_DRAG


func _end_map_drag() -> void:
	_is_dragging_map = false
	mouse_default_cursor_shape = Control.CURSOR_ARROW


func _viewport_to_local(viewport_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_position


func _pan_map(delta: Vector2) -> void:
	if delta.length_squared() <= 0.0:
		return
	_map_pan_offset = _clamped_pan_offset(_map_pan_offset + delta)
	_layout_region_nodes()
	_clear_hover(false)
	queue_redraw()


func _draw() -> void:
	_map_rect = _calculate_map_rect()
	if _map_texture != null:
		draw_texture_rect(_map_texture, _map_rect, false)
	else:
		draw_rect(_map_rect, Color(0.06, 0.09, 0.10, 0.96), true)
	_draw_region_layers()
	for region_id: String in MacroMapArtSpec.all_region_ids():
		_draw_region_overlay(region_id)
	if MacroMapArtSpec.DEBUG_ALPHA_HIT_TEST:
		_draw_alpha_hit_debug()


func _load_region_layer_textures() -> void:
	_region_textures.clear()
	for region_id: String in MacroMapArtSpec.all_region_ids():
		var texture: Texture2D = REGION_LAYER_TEXTURES.get(region_id) as Texture2D
		if texture == null:
			texture = ArtAssetRegistry.texture_for_unified_macro_map_region(region_id)
		if texture != null:
			_region_textures[region_id] = texture
			_hover_progress[region_id] = 0.0


func _load_region_mask_images() -> void:
	_region_masks.clear()
	_region_pivots.clear()
	for region_id: String in MacroMapArtSpec.all_region_ids():
		var path: String = str(MacroMapArtSpec.REGION_MASK_TEXTURES.get(region_id, ""))
		var texture := load(path) as Texture2D
		if texture == null:
			continue
		var image: Image = texture.get_image()
		if image == null or image.is_empty():
			continue
		_region_masks[region_id] = image
		_region_pivots[region_id] = _calculate_mask_centroid(image)


func _resolve_master_texture() -> Texture2D:
	if MASTER_MAP_TEXTURE != null:
		return MASTER_MAP_TEXTURE
	return ArtAssetRegistry.texture_for_unified_macro_map()


func _draw_region_layers() -> void:
	var debug_region: String = MacroMapArtSpec.REGION_LAYER_DEBUG_REGION
	var region_ids := MacroMapArtSpec.all_region_ids()
	for region_id: String in region_ids:
		if region_id == _hovered_region_id:
			continue
		if not debug_region.is_empty() and debug_region != region_id:
			continue
		_draw_region_layer(region_id)
	if not _hovered_region_id.is_empty() and (debug_region.is_empty() or debug_region == _hovered_region_id):
		_draw_region_layer(_hovered_region_id)


func _draw_region_layer(region_id: String) -> void:
	var texture: Texture2D = _region_textures.get(region_id) as Texture2D
	if texture == null:
		return
	var progress: float = float(_hover_progress.get(region_id, 0.0))
	var scale: float = lerpf(1.0, MacroMapArtSpec.HOVER_SCALE, progress)
	var brightness: float = lerpf(1.0, MacroMapArtSpec.HOVER_BRIGHTNESS, progress)
	var pivot: Vector2 = _region_pivots.get(region_id, Vector2(0.5, 0.5)) as Vector2
	var pivot_px: Vector2 = _map_rect.position + pivot * _map_rect.size
	var draw_pos: Vector2 = pivot_px - (pivot_px - _map_rect.position) * scale
	var draw_size: Vector2 = _map_rect.size * scale
	var modulate := Color(brightness, brightness, brightness, 1.0)
	draw_texture_rect(texture, Rect2(draw_pos, draw_size), false, modulate)


func _calculate_map_rect() -> Rect2:
	var available: Vector2 = size
	if available.x <= 1.0 or available.y <= 1.0:
		available = custom_minimum_size
	var aspect: float = MacroMapArtSpec.PREFERRED_ASPECT_RATIO
	var width: float = available.x
	var height: float = width / aspect
	if height < available.y:
		height = available.y
		width = height * aspect
	var overscan: float = maxf(1.0, MacroMapArtSpec.MAP_FULLSCREEN_OVERSCAN)
	width *= overscan
	height *= overscan
	var rect_size := Vector2(ceilf(width), ceilf(height))
	_map_pan_offset = _clamped_pan_offset(_map_pan_offset, rect_size)
	var pos: Vector2 = (available - rect_size) * 0.5 + _map_pan_offset
	pos = Vector2(roundf(pos.x), roundf(pos.y))
	return Rect2(pos, rect_size)


func _clamped_pan_offset(offset: Vector2, rect_size: Vector2 = Vector2.ZERO) -> Vector2:
	var available: Vector2 = size
	if available.x <= 1.0 or available.y <= 1.0:
		available = custom_minimum_size
	if rect_size == Vector2.ZERO:
		var aspect: float = MacroMapArtSpec.PREFERRED_ASPECT_RATIO
		var width: float = available.x
		var height: float = width / aspect
		if height < available.y:
			height = available.y
			width = height * aspect
		var overscan: float = maxf(1.0, MacroMapArtSpec.MAP_FULLSCREEN_OVERSCAN)
		rect_size = Vector2(ceilf(width * overscan), ceilf(height * overscan))
	var max_x: float = maxf(0.0, (rect_size.x - available.x) * 0.5)
	var max_y: float = maxf(0.0, (rect_size.y - available.y) * 0.5)
	return Vector2(
		clampf(offset.x, -max_x, max_x),
		clampf(offset.y, -max_y, max_y)
	)


func _draw_region_overlay(region_id: String) -> void:
	var spec: Dictionary = MacroMapArtSpec.region_spec(region_id)
	if spec.is_empty():
		return
	var polygon: PackedVector2Array = _polygon_points(spec)
	if polygon.size() < 3:
		return
	if not MacroMapArtSpec.SHOW_REGION_OVERLAYS:
		if MacroMapArtSpec.DEBUG_BOUNDARIES:
			for i: int in range(polygon.size()):
				draw_line(polygon[i], polygon[(i + 1) % polygon.size()], Color(0.2, 0.85, 1.0, 0.90), 2.0, true)
		return
	var brightness: float = _region_brightness(region_id)
	var tint: Color = spec.get("region_tint_color", Color(0.8, 0.7, 0.4, 0.14))
	var alpha_range: Vector2 = MacroMapArtSpec.OVERLAY_ALPHA_RANGE
	var alpha: float = lerpf(alpha_range.x, alpha_range.y, absf(brightness))
	if is_zero_approx(brightness):
		alpha = 0.035
	if brightness < -0.05:
		tint = tint.lerp(MacroMapArtSpec.DANGER_TINT, 0.55)
	elif brightness > 0.05:
		tint = tint.lerp(MacroMapArtSpec.WARNING_TINT, 0.45)
	tint.a = alpha
	draw_colored_polygon(polygon, tint)

	var outline: Color = Color(0.80, 0.64, 0.34, 0.18 + absf(brightness) * 0.18)
	for i: int in range(polygon.size()):
		draw_line(polygon[i], polygon[(i + 1) % polygon.size()], outline, maxf(1.0, 1.35 * _ui_scale), true)

	if MacroMapArtSpec.DEBUG_BOUNDARIES:
		for i: int in range(polygon.size()):
			draw_line(polygon[i], polygon[(i + 1) % polygon.size()], Color(0.2, 0.85, 1.0, 0.90), 2.0, true)


func _polygon_points(spec: Dictionary) -> PackedVector2Array:
	var points := PackedVector2Array()
	var normalized: Array = spec.get("polygon", []) as Array
	for item: Variant in normalized:
		if item is Vector2:
			points.append(_map_rect.position + (item as Vector2) * _map_rect.size)
	return points


func _update_hover_at_local_position(local_position: Vector2) -> void:
	_map_rect = _calculate_map_rect()
	var next_region_id: String = _region_at_local_position(local_position)
	if MacroMapArtSpec.DEBUG_ALPHA_HIT_TEST:
		_debug_hit_text = _alpha_hit_debug_text(local_position, next_region_id)
	if next_region_id != _hovered_region_id:
		_set_hovered_region(next_region_id)
	elif not next_region_id.is_empty():
		_update_tooltip(next_region_id)
	queue_redraw()


func _region_at_local_position(local_position: Vector2) -> String:
	if not _map_rect.has_point(local_position):
		return ""
	var pixel: Vector2i = _map_local_to_texture_pixel(local_position)
	var best_region_id: String = ""
	var best_alpha: float = 0.0
	for region_id: String in MacroMapArtSpec.all_region_ids():
		var alpha: float = _sample_region_mask(region_id, pixel)
		if alpha >= MacroMapArtSpec.MASK_ALPHA_THRESHOLD and alpha > best_alpha:
			best_alpha = alpha
			best_region_id = region_id
	return best_region_id


func _map_local_to_texture_pixel(local_position: Vector2) -> Vector2i:
	var normalized: Vector2 = (local_position - _map_rect.position) / _map_rect.size
	normalized.x = clampf(normalized.x, 0.0, 1.0)
	normalized.y = clampf(normalized.y, 0.0, 1.0)
	var reference_image: Image = _first_mask_image()
	if reference_image == null:
		return Vector2i.ZERO
	var width: int = reference_image.get_width()
	var height: int = reference_image.get_height()
	return Vector2i(
		clampi(int(floorf(normalized.x * float(width))), 0, width - 1),
		clampi(int(floorf(normalized.y * float(height))), 0, height - 1)
	)


func _sample_region_mask(region_id: String, pixel: Vector2i) -> float:
	var image: Image = _region_masks.get(region_id) as Image
	if image == null:
		return 0.0
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= image.get_width() or pixel.y >= image.get_height():
		return 0.0
	var color: Color = image.get_pixelv(pixel)
	return maxf(color.r, color.a if color.a < 0.999 else 0.0)


func _first_mask_image() -> Image:
	for region_id: String in MacroMapArtSpec.all_region_ids():
		var image: Image = _region_masks.get(region_id) as Image
		if image != null:
			return image
	return null


func _calculate_mask_centroid(image: Image) -> Vector2:
	var width: int = image.get_width()
	var height: int = image.get_height()
	var sum_x: float = 0.0
	var sum_y: float = 0.0
	var weight_sum: float = 0.0
	for y: int in range(0, height, 2):
		for x: int in range(0, width, 2):
			var color: Color = image.get_pixel(x, y)
			var weight: float = maxf(color.r, color.a if color.a < 0.999 else 0.0)
			if weight < MacroMapArtSpec.MASK_ALPHA_THRESHOLD:
				continue
			sum_x += (float(x) + 0.5) * weight
			sum_y += (float(y) + 0.5) * weight
			weight_sum += weight
	if weight_sum <= 0.0:
		return Vector2(0.5, 0.5)
	return Vector2(sum_x / weight_sum / float(width), sum_y / weight_sum / float(height))


func _set_hovered_region(region_id: String) -> void:
	var previous_region_id: String = _hovered_region_id
	_hovered_region_id = region_id
	for item_id: String in MacroMapArtSpec.all_region_ids():
		var target: float = 1.0 if item_id == region_id else 0.0
		_animate_region_hover(item_id, target)
	if region_id.is_empty():
		_hide_tooltip()
	else:
		_update_tooltip(region_id)
	if previous_region_id != region_id:
		queue_redraw()


func _animate_region_hover(region_id: String, target: float) -> void:
	var tween: Tween = _hover_tweens.get(region_id) as Tween
	if tween != null and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	_hover_tweens[region_id] = tween
	tween.tween_method(
		Callable(self, "_set_region_hover_progress").bind(region_id),
		float(_hover_progress.get(region_id, 0.0)),
		target,
		MacroMapArtSpec.HOVER_ANIMATION_DURATION
	)


func _set_region_hover_progress(value: float, region_id: String) -> void:
	_hover_progress[region_id] = value
	queue_redraw()


func _clear_hover(animated: bool = true) -> void:
	if _hovered_region_id.is_empty() and not _is_tooltip_visible():
		return
	_hovered_region_id = ""
	for item_id: String in MacroMapArtSpec.all_region_ids():
		if animated:
			_animate_region_hover(item_id, 0.0)
		else:
			_hover_progress[item_id] = 0.0
	_hide_tooltip()
	queue_redraw()


func _on_mouse_exited() -> void:
	_clear_hover(true)


func _rebuild_region_nodes() -> void:
	if not MacroMapArtSpec.SHOW_PERMANENT_REGION_LABELS:
		for panel: Variant in _region_panels.values():
			if panel is Control:
				(panel as Control).visible = false
		return
	for region_id: String in MacroMapArtSpec.all_region_ids():
		if _region_panels.has(region_id):
			continue
		var panel: PanelContainer = PanelContainer.new()
		panel.name = "%sMapLabel" % region_id.capitalize()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_region_panel_style(panel)
		add_child(panel)
		_region_panels[region_id] = panel

		var margin: MarginContainer = MarginContainer.new()
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", _label_dim(5))
		margin.add_theme_constant_override("margin_top", _label_dim(3))
		margin.add_theme_constant_override("margin_right", _label_dim(5))
		margin.add_theme_constant_override("margin_bottom", _label_dim(4))
		panel.add_child(margin)

		var box: VBoxContainer = VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_theme_constant_override("separation", _label_dim(3))
		margin.add_child(box)

		var title: Label = Label.new()
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title.autowrap_mode = TextServer.AUTOWRAP_OFF
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		title.modulate = Color(0.98, 0.86, 0.56, 0.96)
		title.add_theme_font_size_override("font_size", _label_font(15))
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(title)
		_region_titles[region_id] = title

		var lines: VBoxContainer = VBoxContainer.new()
		lines.alignment = BoxContainer.ALIGNMENT_CENTER
		lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lines.add_theme_constant_override("separation", _label_dim(2))
		box.add_child(lines)
		_region_line_boxes[region_id] = lines
	_refresh_region_text()


func _refresh_region_text() -> void:
	if not MacroMapArtSpec.SHOW_PERMANENT_REGION_LABELS:
		return
	for region_id: String in MacroMapArtSpec.all_region_ids():
		var data: Dictionary = _regions.get(region_id, {})
		var title: Label = _region_titles.get(region_id) as Label
		if title != null:
			title.text = str(data.get("name", _fallback_region_name(region_id)))
		var line_box: VBoxContainer = _region_line_boxes.get(region_id) as VBoxContainer
		if line_box == null:
			continue
		for child: Node in line_box.get_children():
			child.queue_free()
		var lines: Array = data.get("lines", []) as Array
		for line: Variant in lines:
			if line is Dictionary:
				line_box.add_child(_make_variable_row(region_id, line as Dictionary))


func _make_variable_row(region_id: String, line: Dictionary) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", _label_dim(3))

	var variable_label: Label = Label.new()
	variable_label.text = str(line.get("label", ""))
	variable_label.custom_minimum_size = Vector2(_variable_label_width(region_id), _label_dim(20))
	variable_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	variable_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	variable_label.modulate = Color(0.90, 0.92, 0.86, 0.94)
	variable_label.add_theme_font_size_override("font_size", _label_font(14))
	variable_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(variable_label)

	var arrow: String = str(line.get("arrow", "→"))
	var arrow_label: Label = Label.new()
	arrow_label.text = arrow
	arrow_label.custom_minimum_size = Vector2(_arrow_slot_width(region_id), _label_dim(20))
	arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow_label.modulate = _line_color(arrow)
	arrow_label.add_theme_font_size_override("font_size", _label_font(15))
	arrow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(arrow_label)
	return row


func _layout_region_nodes() -> void:
	_map_rect = _calculate_map_rect()
	if not MacroMapArtSpec.SHOW_PERMANENT_REGION_LABELS:
		return
	_refresh_region_label_metrics()
	for region_id: String in MacroMapArtSpec.all_region_ids():
		var panel: Control = _region_panels.get(region_id) as Control
		if panel == null:
			continue
		var spec: Dictionary = MacroMapArtSpec.region_spec(region_id)
		var bounds: Rect2 = _combined_label_bounds(spec, _regions.get(region_id, {}))
		panel.size = bounds.size * _map_rect.size
		var anchor: Vector2 = _label_group_anchor(spec, bounds)
		panel.position = _map_normalized_to_local(anchor) - panel.size * 0.5
		panel.position = Vector2(roundf(panel.position.x), roundf(panel.position.y))
		panel.pivot_offset = panel.size * 0.5


func _refresh_region_label_metrics() -> void:
	for region_id: String in MacroMapArtSpec.all_region_ids():
		var panel: Control = _region_panels.get(region_id) as Control
		if panel != null:
			_apply_region_panel_style(panel)
			var margin: MarginContainer = null
			if panel.get_child_count() > 0 and panel.get_child(0) is MarginContainer:
				margin = panel.get_child(0) as MarginContainer
			if margin != null:
				margin.add_theme_constant_override("margin_left", _label_dim(5))
				margin.add_theme_constant_override("margin_top", _label_dim(3))
				margin.add_theme_constant_override("margin_right", _label_dim(5))
				margin.add_theme_constant_override("margin_bottom", _label_dim(4))
		var title: Label = _region_titles.get(region_id) as Label
		if title != null:
			title.add_theme_font_size_override("font_size", _label_font(15))
			title.custom_minimum_size = Vector2(0.0, _label_dim(22))
		var box: VBoxContainer = _region_line_boxes.get(region_id) as VBoxContainer
		if box != null:
			box.add_theme_constant_override("separation", _label_dim(2))
			for child: Node in box.get_children():
				_update_variable_row_metrics(region_id, child)


func _build_tooltip() -> void:
	_tooltip_layer = CanvasLayer.new()
	_tooltip_layer.name = "MacroMapHoverTooltipLayer"
	_tooltip_layer.layer = 60
	add_child(_tooltip_layer)

	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.name = "MacroMapHoverTooltip"
	_tooltip_panel.visible = false
	_tooltip_panel.modulate.a = 0.0
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.custom_minimum_size = Vector2(_dim(210), 0)
	_tooltip_panel.add_theme_stylebox_override("panel", _tooltip_style())
	_tooltip_layer.add_child(_tooltip_panel)

	var margin: MarginContainer = MarginContainer.new()
	_tooltip_margin = margin
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", _dim(12))
	margin.add_theme_constant_override("margin_top", _dim(10))
	margin.add_theme_constant_override("margin_right", _dim(12))
	margin.add_theme_constant_override("margin_bottom", _dim(10))
	_tooltip_panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	_tooltip_box = box
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", _dim(7))
	margin.add_child(box)

	_tooltip_title = Label.new()
	_tooltip_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_title.modulate = Color(1.0, 0.82, 0.42, 1.0)
	_tooltip_title.add_theme_font_size_override("font_size", _font(16))
	box.add_child(_tooltip_title)

	var separator: HSeparator = HSeparator.new()
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(separator)

	_tooltip_lines = VBoxContainer.new()
	_tooltip_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_lines.add_theme_constant_override("separation", _dim(4))
	box.add_child(_tooltip_lines)
	_refresh_tooltip_metrics()


func _update_tooltip(region_id: String) -> void:
	if _tooltip_panel == null:
		return
	var data: Dictionary = _regions.get(region_id, {})
	_tooltip_title.text = str(data.get("name", _fallback_region_name(region_id)))
	for child: Node in _tooltip_lines.get_children():
		child.queue_free()
	var lines: Array = data.get("lines", []) as Array
	for line: Variant in lines:
		if line is Dictionary:
			_tooltip_lines.add_child(_make_tooltip_variable_row(line as Dictionary))
	_show_tooltip()
	_position_tooltip()


func _make_tooltip_variable_row(line: Dictionary) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", _dim(8))

	var variable_label := _make_tooltip_label(str(line.get("display_symbol", line.get("label", ""))), Color(0.92, 0.95, 0.90, 1.0), 14)
	variable_label.custom_minimum_size.x = _dim(42)
	variable_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(variable_label)

	var value_label := _make_tooltip_label(str(line.get("value_text", line.get("value", "—"))), Color(0.96, 0.90, 0.74, 1.0), 14)
	value_label.custom_minimum_size.x = _dim(70)
	row.add_child(value_label)

	var status: String = str(line.get("status_text", line.get("status", "暂无判断")))
	var status_label := _make_tooltip_label(status, _status_color(status), 14)
	status_label.custom_minimum_size.x = _dim(62)
	row.add_child(status_label)
	return row


func _make_tooltip_label(text: String, color: Color, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.modulate = color
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", _font(font_size))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _refresh_tooltip_metrics() -> void:
	if _tooltip_panel == null:
		return
	_tooltip_panel.custom_minimum_size = Vector2(_dim(210), 0)
	_tooltip_panel.add_theme_stylebox_override("panel", _tooltip_style())
	if _tooltip_margin != null:
		_tooltip_margin.add_theme_constant_override("margin_left", _dim(12))
		_tooltip_margin.add_theme_constant_override("margin_top", _dim(10))
		_tooltip_margin.add_theme_constant_override("margin_right", _dim(12))
		_tooltip_margin.add_theme_constant_override("margin_bottom", _dim(10))
	if _tooltip_box != null:
		_tooltip_box.add_theme_constant_override("separation", _dim(7))
	if _tooltip_title != null:
		_tooltip_title.add_theme_font_size_override("font_size", _font(16))
	if _tooltip_lines != null:
		_tooltip_lines.add_theme_constant_override("separation", _dim(4))


func _show_tooltip() -> void:
	if _tooltip_panel.visible and _tooltip_panel.modulate.a >= 0.99:
		return
	if _tooltip_tween != null and _tooltip_tween.is_running():
		_tooltip_tween.kill()
	_tooltip_panel.visible = true
	_tooltip_tween = create_tween()
	_tooltip_tween.tween_property(_tooltip_panel, "modulate:a", 1.0, 0.12)


func _hide_tooltip() -> void:
	if _tooltip_panel == null or not _tooltip_panel.visible:
		return
	if _tooltip_tween != null and _tooltip_tween.is_running():
		_tooltip_tween.kill()
	_tooltip_tween = create_tween()
	_tooltip_tween.tween_property(_tooltip_panel, "modulate:a", 0.0, 0.10)
	_tooltip_tween.tween_callback(func() -> void:
		if _tooltip_panel != null:
			_tooltip_panel.visible = false
	)


func _position_tooltip() -> void:
	if _tooltip_panel == null:
		return
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var offset: Vector2 = MacroMapArtSpec.HOVER_TOOLTIP_OFFSET * _ui_scale
	var estimated_size: Vector2 = Vector2(
		maxf(_tooltip_panel.size.x, _dim(220)),
		maxf(_tooltip_panel.size.y, _dim(112))
	)
	var position: Vector2 = _last_mouse_viewport_position + offset
	if position.x + estimated_size.x > viewport_rect.size.x - _dim(10):
		position.x = _last_mouse_viewport_position.x - estimated_size.x - offset.x
	if position.y + estimated_size.y > viewport_rect.size.y - _dim(10):
		position.y = viewport_rect.size.y - estimated_size.y - _dim(10)
	position.x = clampf(position.x, _dim(10), maxf(_dim(10), viewport_rect.size.x - estimated_size.x - _dim(10)))
	position.y = clampf(position.y, _dim(10), maxf(_dim(10), viewport_rect.size.y - estimated_size.y - _dim(10)))
	_tooltip_panel.position = Vector2(roundf(position.x), roundf(position.y))


func _is_tooltip_visible() -> bool:
	return _tooltip_panel != null and _tooltip_panel.visible


func _tooltip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.030, 0.035, 0.036, 0.94)
	style.border_color = Color(0.72, 0.55, 0.30, 0.90)
	style.set_border_width_all(maxi(1, _dim(1)))
	style.set_corner_radius_all(_dim(7))
	style.shadow_color = Color(0, 0, 0, 0.48)
	style.shadow_size = _dim(8)
	return style


func _status_color(status: String) -> Color:
	match status:
		"偏低":
			return Color(0.58, 0.78, 0.96, 1.0)
		"偏高":
			return Color(1.0, 0.62, 0.42, 1.0)
		"适中":
			return Color(0.66, 0.90, 0.62, 1.0)
	return Color(0.78, 0.82, 0.86, 1.0)


func _draw_alpha_hit_debug() -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	var text: String = _debug_hit_text if not _debug_hit_text.is_empty() else "alpha hit: none"
	draw_rect(Rect2(_map_rect.position + Vector2(8, 8), Vector2(280, 52)), Color(0, 0, 0, 0.55), true)
	draw_string(font, _map_rect.position + Vector2(14, 28), text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font(12), Color(0.78, 0.94, 1.0, 1.0))


func _alpha_hit_debug_text(local_position: Vector2, region_id: String) -> String:
	if not _map_rect.has_point(local_position):
		return "alpha hit: none | outside map"
	var pixel: Vector2i = _map_local_to_texture_pixel(local_position)
	var parts: Array[String] = []
	for item_id: String in MacroMapArtSpec.all_region_ids():
		parts.append("%s=%.2f" % [item_id.substr(0, 3), _sample_region_mask(item_id, pixel)])
	return "hit: %s | px: %s | %s" % [region_id if not region_id.is_empty() else "none", str(pixel), " ".join(parts)]


func _map_normalized_to_local(normalized_point: Vector2) -> Vector2:
	return _map_rect.position + normalized_point * _map_rect.size


func _label_group_anchor(spec: Dictionary, bounds: Rect2) -> Vector2:
	if spec.has("label_group_anchor"):
		return spec.get("label_group_anchor", bounds.get_center()) as Vector2
	return bounds.get_center()


func _combined_label_bounds(spec: Dictionary, data: Dictionary) -> Rect2:
	var label_rect: Rect2 = spec.get("label_rect", Rect2(Vector2(0.4, 0.4), Vector2(0.2, 0.08)))
	var variable_rect: Rect2 = spec.get("variable_rect", Rect2(label_rect.position + Vector2(0.0, 0.07), Vector2(label_rect.size.x, 0.09)))
	var top_left: Vector2 = Vector2(
		minf(label_rect.position.x, variable_rect.position.x),
		minf(label_rect.position.y, variable_rect.position.y)
	)
	var bottom_right: Vector2 = Vector2(
		maxf(label_rect.end.x, variable_rect.end.x),
		maxf(label_rect.end.y, variable_rect.end.y)
	)
	var bounds: Rect2 = Rect2(top_left, bottom_right - top_left)
	var lines: Array = data.get("lines", []) as Array
	if lines.size() > 1:
		bounds.size.y += 0.025 * float(lines.size() - 1)
	return bounds.grow(0.004)


func _apply_region_panel_style(panel: Control) -> void:
	if not panel is PanelContainer:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.030, 0.030, 0.24)
	style.border_color = Color(0.72, 0.56, 0.30, 0.22)
	style.set_border_width_all(maxi(1, _label_dim(1)))
	style.set_corner_radius_all(_label_dim(4))
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = _label_dim(3)
	(panel as PanelContainer).add_theme_stylebox_override("panel", style)


func _update_variable_row_metrics(region_id: String, node: Node) -> void:
	for child: Node in node.get_children():
		if child is Label:
			var label: Label = child as Label
			var is_arrow: bool = label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", _label_font(16 if is_arrow else 15))
			label.custom_minimum_size.y = _label_dim(20)
			if is_arrow:
				label.custom_minimum_size.x = _arrow_slot_width(region_id)
			else:
				label.custom_minimum_size.x = _variable_label_width(region_id)


func _region_brightness(region_id: String) -> float:
	var data: Dictionary = _regions.get(region_id, {})
	return clampf(float(data.get("brightness", 0.0)), -1.0, 1.0)


func _variable_label_width(region_id: String) -> float:
	if region_id == "government":
		return _label_dim(42)
	return _label_dim(24)


func _arrow_slot_width(region_id: String) -> float:
	var spec: Dictionary = MacroMapArtSpec.region_spec(region_id)
	return _label_dim(float(spec.get("arrow_reserved_width", 26.0)))


func _line_color(arrow: String) -> Color:
	if arrow == "↑":
		return Color(0.68, 0.95, 0.72, 1.0)
	if arrow == "↓":
		return Color(0.95, 0.62, 0.58, 1.0)
	return Color(0.78, 0.88, 0.94, 1.0)


func _fallback_region_name(region_id: String) -> String:
	match region_id:
		"consumption":
			return "居民消费区"
		"industry":
			return "工业产区"
		"finance":
			return "金融市场区"
		"government":
			return "政府部门区"
	return "区域"


func _dim(value: float) -> int:
	return int(roundf(value * _ui_scale))


func _font(value: float) -> int:
	return maxi(10, int(roundf(value * _ui_scale)))


func _label_scale() -> float:
	if _map_rect.size.x > 1.0:
		return maxf(0.1, _map_rect.size.x / MacroMapArtSpec.LABEL_REFERENCE_MAP_WIDTH)
	return _ui_scale


func _label_dim(value: float) -> int:
	return maxi(1, int(roundf(value * _label_scale())))


func _label_font(value: float) -> int:
	return maxi(9, int(roundf(value * _label_scale())))
