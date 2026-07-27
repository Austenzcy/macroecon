extends Control

const ArtAssetRegistry = preload("res://scripts/ui/ArtAssetRegistry.gd")
const MacroMapArtSpec = preload("res://scripts/ui/map/MacroMapArtSpec.gd")

var _ui_scale: float = 1.0
var _map_texture: Texture2D
var _map_rect: Rect2 = Rect2()
var _regions: Dictionary = {}
var _region_panels: Dictionary = {}
var _region_titles: Dictionary = {}
var _region_line_boxes: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_map_texture = ArtAssetRegistry.texture_for_unified_macro_map()
	custom_minimum_size = MacroMapArtSpec.MINIMUM_SIZE * _ui_scale
	_rebuild_region_nodes()
	_layout_region_nodes()
	queue_redraw()


func has_master_texture() -> bool:
	if _map_texture == null:
		_map_texture = ArtAssetRegistry.texture_for_unified_macro_map()
	return _map_texture != null


func set_ui_scale(value: float) -> void:
	_ui_scale = clampf(value, 0.8, 1.2)
	custom_minimum_size = MacroMapArtSpec.MINIMUM_SIZE * _ui_scale
	for panel: Variant in _region_panels.values():
		if panel is Control:
			_apply_region_panel_style(panel as Control)
	for title: Variant in _region_titles.values():
		if title is Label:
			(title as Label).add_theme_font_size_override("font_size", _font(17))
	for box: Variant in _region_line_boxes.values():
		if box is VBoxContainer:
			(box as VBoxContainer).add_theme_constant_override("separation", _dim(2))
			for child: Node in (box as VBoxContainer).get_children():
				_update_variable_row_fonts(child)
	call_deferred("_layout_region_nodes")
	queue_redraw()


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
		_layout_region_nodes()
		queue_redraw()


func _draw() -> void:
	_map_rect = _calculate_map_rect()
	if _map_texture != null:
		draw_texture_rect(_map_texture, _map_rect, false)
	else:
		draw_rect(_map_rect, Color(0.06, 0.09, 0.10, 0.96), true)
	for region_id: String in MacroMapArtSpec.all_region_ids():
		_draw_region_overlay(region_id)


func _calculate_map_rect() -> Rect2:
	var available: Vector2 = size
	if available.x <= 1.0 or available.y <= 1.0:
		available = custom_minimum_size
	var aspect: float = MacroMapArtSpec.PREFERRED_ASPECT_RATIO
	var width: float = available.x
	var height: float = width / aspect
	if height > available.y:
		height = available.y
		width = height * aspect
	var pos: Vector2 = (available - Vector2(width, height)) * 0.5
	return Rect2(pos, Vector2(width, height))


func _draw_region_overlay(region_id: String) -> void:
	var spec: Dictionary = MacroMapArtSpec.region_spec(region_id)
	if spec.is_empty():
		return
	var polygon: PackedVector2Array = _polygon_points(spec)
	if polygon.size() < 3:
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


func _rebuild_region_nodes() -> void:
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
		margin.add_theme_constant_override("margin_left", _dim(8))
		margin.add_theme_constant_override("margin_top", _dim(5))
		margin.add_theme_constant_override("margin_right", _dim(8))
		margin.add_theme_constant_override("margin_bottom", _dim(6))
		panel.add_child(margin)

		var box: VBoxContainer = VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_theme_constant_override("separation", _dim(3))
		margin.add_child(box)

		var title: Label = Label.new()
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title.autowrap_mode = TextServer.AUTOWRAP_OFF
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		title.modulate = Color(0.96, 0.86, 0.58, 1.0)
		title.add_theme_font_size_override("font_size", _font(17))
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(title)
		_region_titles[region_id] = title

		var lines: VBoxContainer = VBoxContainer.new()
		lines.alignment = BoxContainer.ALIGNMENT_CENTER
		lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lines.add_theme_constant_override("separation", _dim(2))
		box.add_child(lines)
		_region_line_boxes[region_id] = lines
	_refresh_region_text()


func _refresh_region_text() -> void:
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
	row.add_theme_constant_override("separation", _dim(3))

	var variable_label: Label = Label.new()
	variable_label.text = str(line.get("label", ""))
	variable_label.custom_minimum_size = Vector2(_variable_label_width(region_id), _dim(20))
	variable_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	variable_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	variable_label.modulate = Color(0.88, 0.92, 0.90, 1.0)
	variable_label.add_theme_font_size_override("font_size", _font(15))
	variable_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(variable_label)

	var arrow: String = str(line.get("arrow", "→"))
	var arrow_label: Label = Label.new()
	arrow_label.text = arrow
	arrow_label.custom_minimum_size = Vector2(_arrow_slot_width(region_id), _dim(20))
	arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow_label.modulate = _line_color(arrow)
	arrow_label.add_theme_font_size_override("font_size", _font(16))
	arrow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(arrow_label)
	return row


func _layout_region_nodes() -> void:
	_map_rect = _calculate_map_rect()
	for region_id: String in MacroMapArtSpec.all_region_ids():
		var panel: Control = _region_panels.get(region_id) as Control
		if panel == null:
			continue
		var spec: Dictionary = MacroMapArtSpec.region_spec(region_id)
		var bounds: Rect2 = _combined_label_bounds(spec, _regions.get(region_id, {}))
		panel.position = _map_rect.position + bounds.position * _map_rect.size
		panel.size = bounds.size * _map_rect.size
		panel.pivot_offset = panel.size * 0.5


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
	return bounds.grow(0.010)


func _apply_region_panel_style(panel: Control) -> void:
	if not panel is PanelContainer:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.045, 0.050, 0.56)
	style.border_color = Color(0.72, 0.56, 0.30, 0.62)
	style.set_border_width_all(maxi(1, _dim(1)))
	style.set_corner_radius_all(_dim(6))
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	style.shadow_size = _dim(5)
	(panel as PanelContainer).add_theme_stylebox_override("panel", style)


func _update_variable_row_fonts(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Label:
			var label: Label = child as Label
			label.add_theme_font_size_override("font_size", _font(16 if label.text in ["↑", "↓", "→"] else 15))


func _region_brightness(region_id: String) -> float:
	var data: Dictionary = _regions.get(region_id, {})
	return clampf(float(data.get("brightness", 0.0)), -1.0, 1.0)


func _variable_label_width(region_id: String) -> float:
	if region_id == "government":
		return _dim(42)
	return _dim(24)


func _arrow_slot_width(region_id: String) -> float:
	var spec: Dictionary = MacroMapArtSpec.region_spec(region_id)
	return _dim(float(spec.get("arrow_reserved_width", 26.0)))


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
