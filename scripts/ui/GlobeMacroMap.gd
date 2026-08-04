extends Control

const MAP_TEXTURE: Texture2D = preload("res://assets/art/map/globe/fictional_world_v6_4096.webp")
const GLOBE_SHADER: Shader = preload("res://assets/art/map/globe/globe_macro_map.gdshader")

const SPHERE_RADIUS: float = 1.0
const WIDTH_SEGMENTS: int = 128
const HEIGHT_SEGMENTS: int = 64
const FIELD_OF_VIEW: float = 35.0
const MIN_PITCH: float = deg_to_rad(-55.0)
const MAX_PITCH: float = deg_to_rad(55.0)
const ZOOM_DAMPING: float = 11.0
const ROTATION_DAMPING: float = 7.25
const ROTATION_SENSITIVITY: float = 0.0062
const VERTICAL_DRAG_SCALE: float = 0.7
const DRAG_STIFFNESS: float = 72.0
const DRAG_DAMPING: float = 16.0
const ANCHOR_SURFACE_RADIUS: float = 1.018
const ANCHOR_SHOW_THRESHOLD: float = 0.20
const ANCHOR_HIDE_THRESHOLD: float = 0.14
const ANCHOR_FADE_DURATION: float = 0.14
const CARD_GAP: float = 14.0
const COUNTRY_TARGET_LINEAR_COVERAGE: float = 0.70710678

const CORE_COUNTRY_BOUNDARY: Array[Vector2] = [
	Vector2(-50, 8), Vector2(-47, 23), Vector2(-35, 34), Vector2(-16, 38),
	Vector2(5, 37), Vector2(25, 31), Vector2(43, 19), Vector2(52, 4),
	Vector2(49, -14), Vector2(38, -27), Vector2(21, -36), Vector2(1, -38),
	Vector2(-20, -34), Vector2(-37, -25), Vector2(-47, -11)
]

const REGION_ANCHORS: Array[Dictionary] = [
	{
		"region_id": "consumption", "name": "居民消费区", "longitude": -17.0, "latitude": 9.0,
		"color": Color("729da5"), "dark_color": Color("456f77")
	},
	{
		"region_id": "industry", "name": "工业投资区", "longitude": 10.0, "latitude": 12.0,
		"color": Color("7e86a8"), "dark_color": Color("596182")
	},
	{
		"region_id": "finance", "name": "金融货币区", "longitude": -18.0, "latitude": -15.0,
		"color": Color("628f82"), "dark_color": Color("3f6e62")
	},
	{
		"region_id": "government", "name": "政府财政区", "longitude": 8.0, "latitude": -12.0,
		"color": Color("a69360"), "dark_color": Color("78683e")
	}
]

var _ui_scale: float = 1.0
var _regions: Dictionary = {}
var _subviewport: SubViewport
var _display: TextureRect
var _sphere: MeshInstance3D
var _camera: Camera3D
var _overlay: Control
var _anchor_entries: Dictionary = {}
var _yaw: float = 0.0
var _pitch: float = 0.0
var _target_yaw: float = 0.0
var _target_pitch: float = 0.0
var _yaw_velocity: float = 0.0
var _pitch_velocity: float = 0.0
var _camera_distance: float = 4.8
var _target_camera_distance: float = 4.8
var _minimum_camera_distance: float = 3.5
var _maximum_camera_distance: float = 4.8
var _has_sized_viewport: bool = false
var _is_dragging: bool = false
var _last_drag_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_build_globe_viewport()
	_build_anchor_overlay()
	resized.connect(_on_resized)
	_on_resized()
	_refresh_region_cards()
	set_process(true)


func has_master_texture() -> bool:
	return MAP_TEXTURE != null


func set_ui_scale(value: float) -> void:
	_ui_scale = clampf(value, 0.75, 1.35)
	custom_minimum_size = Vector2(540.0, 413.0) * _ui_scale
	if is_node_ready():
		_rebuild_anchor_overlay()


func set_regions(regions: Array) -> void:
	_regions.clear()
	for item: Variant in regions:
		if item is Dictionary:
			var data: Dictionary = (item as Dictionary).duplicate(true)
			var region_id: String = str(data.get("region_id", ""))
			if not region_id.is_empty():
				_regions[region_id] = data
	if is_node_ready():
		_refresh_region_cards()


func clear_hover_state() -> void:
	pass


func get_hovered_region_id() -> String:
	return ""


func get_map_zoom() -> float:
	return _maximum_camera_distance / maxf(_camera_distance, 0.001)


func get_map_zoom_limits() -> Vector2:
	return Vector2(1.0, _maximum_camera_distance / maxf(_minimum_camera_distance, 0.001))


func get_map_rect() -> Rect2:
	var radius: float = _projected_sphere_radius(_camera_distance)
	return Rect2(size * 0.5 - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)


func handle_viewport_input(
	event: InputEvent,
	viewport_position: Vector2,
	_space_pressed: bool = false,
	allow_interaction: bool = true
) -> bool:
	if event is InputEventMouseButton:
		var button_event: InputEventMouseButton = event
		if button_event.button_index == MOUSE_BUTTON_LEFT:
			if button_event.pressed and allow_interaction:
				_begin_drag(viewport_position)
				return true
			if not button_event.pressed and _is_dragging:
				_end_drag()
				return true
		if button_event.pressed and allow_interaction:
			if button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_zoom_camera(-1.0, button_event.factor)
				return true
			if button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_camera(1.0, button_event.factor)
				return true
	elif event is InputEventMouseMotion and _is_dragging:
		var delta: Vector2 = viewport_position - _last_drag_position
		_target_yaw += delta.x * ROTATION_SENSITIVITY
		_target_pitch = clampf(
			_target_pitch + delta.y * ROTATION_SENSITIVITY * VERTICAL_DRAG_SCALE,
			MIN_PITCH,
			MAX_PITCH
		)
		_last_drag_position = viewport_position
		return true
	return false


func _build_globe_viewport() -> void:
	_subviewport = SubViewport.new()
	_subviewport.name = "GlobeViewport"
	_subviewport.disable_3d = false
	_subviewport.transparent_bg = false
	_subviewport.handle_input_locally = false
	_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_subviewport.msaa_3d = Viewport.MSAA_2X
	add_child(_subviewport)

	_display = TextureRect.new()
	_display.name = "GlobeDisplay"
	_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_display.stretch_mode = TextureRect.STRETCH_SCALE
	_display.texture = _subviewport.get_texture()
	add_child(_display)

	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color.WHITE
	environment.background_energy_multiplier = 1.0
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.0
	environment_node.environment = environment
	_subviewport.add_child(environment_node)

	_sphere = MeshInstance3D.new()
	_sphere.name = "GlobeSphere"
	_sphere.mesh = _create_sphere_mesh()
	var material := ShaderMaterial.new()
	material.shader = GLOBE_SHADER
	material.set_shader_parameter("map_texture", MAP_TEXTURE)
	_sphere.material_override = material
	_subviewport.add_child(_sphere)

	_camera = Camera3D.new()
	_camera.name = "GlobeCamera"
	_camera.fov = FIELD_OF_VIEW
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.current = true
	_subviewport.add_child(_camera)


func _create_sphere_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for y: int in range(HEIGHT_SEGMENTS + 1):
		var v: float = float(y) / float(HEIGHT_SEGMENTS)
		var latitude: float = v * PI - PI * 0.5
		var cos_latitude: float = cos(latitude)
		var sin_latitude: float = sin(latitude)
		for x: int in range(WIDTH_SEGMENTS + 1):
			var u: float = float(x) / float(WIDTH_SEGMENTS)
			var longitude: float = (u - 0.5) * TAU
			var normal := Vector3(
				cos_latitude * sin(longitude),
				sin_latitude,
				cos_latitude * cos(longitude)
			).normalized()
			vertices.append(normal * SPHERE_RADIUS)
			normals.append(normal)
			uvs.append(Vector2(u, v))

	for y: int in range(HEIGHT_SEGMENTS):
		for x: int in range(WIDTH_SEGMENTS):
			var first: int = y * (WIDTH_SEGMENTS + 1) + x
			var second: int = first + WIDTH_SEGMENTS + 1
			indices.append_array(PackedInt32Array([
				first, first + 1, second,
				second, first + 1, second + 1
			]))

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _build_anchor_overlay() -> void:
	_overlay = Control.new()
	_overlay.name = "GlobeAnchorOverlay"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	_anchor_entries.clear()

	for config: Dictionary in REGION_ANCHORS:
		var region_id: String = str(config.get("region_id", ""))
		var accent: Color = config.get("color", Color.GRAY) as Color
		var marker := Panel.new()
		marker.name = "%sAnchor" % region_id.capitalize()
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.size = Vector2.ONE * _dim(12.0)
		marker.add_theme_stylebox_override("panel", _marker_style(accent))
		_overlay.add_child(marker)

		var line := Line2D.new()
		line.name = "%sLeaderLine" % region_id.capitalize()
		line.width = _dim(1.35)
		line.default_color = Color(accent, 0.66)
		line.antialiased = true
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		_overlay.add_child(line)
		_overlay.move_child(line, 0)

		var card_data: Dictionary = _create_region_card(config)
		var card: PanelContainer = card_data.get("card") as PanelContainer
		_overlay.add_child(card)

		var local_point := _longitude_latitude_to_point(
			float(config.get("longitude", 0.0)),
			float(config.get("latitude", 0.0))
		)
		_anchor_entries[region_id] = {
			"config": config,
			"local_point": local_point,
			"marker": marker,
			"line": line,
			"card": card,
			"title": card_data.get("title"),
			"metrics": card_data.get("metrics"),
			"status": card_data.get("status"),
			"front_visible": false,
			"alpha": 0.0,
			"projection": Vector2.ZERO
		}


func _rebuild_anchor_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		remove_child(_overlay)
		_overlay.queue_free()
	_build_anchor_overlay()
	_refresh_region_cards()


func _create_region_card(config: Dictionary) -> Dictionary:
	var accent: Color = config.get("color", Color.GRAY) as Color
	var dark_color: Color = config.get("dark_color", accent.darkened(0.2)) as Color
	var card := PanelContainer.new()
	card.name = "%sInfoCard" % str(config.get("region_id", "region")).capitalize()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.custom_minimum_size = Vector2(_dim(190.0), 0.0)
	card.add_theme_stylebox_override("panel", _card_style(accent))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _int_dim(15))
	margin.add_theme_constant_override("margin_top", _int_dim(12))
	margin.add_theme_constant_override("margin_right", _int_dim(15))
	margin.add_theme_constant_override("margin_bottom", _int_dim(11))
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", _int_dim(6))
	margin.add_child(column)

	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", _int_dim(8))
	column.add_child(heading)
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2.ONE * _dim(8.0)
	dot.add_theme_stylebox_override("panel", _dot_style(accent))
	heading.add_child(dot)
	var title := Label.new()
	title.text = str(config.get("name", "区域"))
	title.add_theme_font_size_override("font_size", _int_dim(17))
	title.add_theme_color_override("font_color", Color("213637"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)

	var metrics := VBoxContainer.new()
	metrics.name = "Metrics"
	metrics.add_theme_constant_override("separation", _int_dim(3))
	column.add_child(metrics)

	var separator := HSeparator.new()
	separator.add_theme_color_override("separator", Color("e5ece9"))
	column.add_child(separator)

	var status_row := HBoxContainer.new()
	column.add_child(status_row)
	var status_label := Label.new()
	status_label.text = "状态"
	status_label.add_theme_font_size_override("font_size", _int_dim(13))
	status_label.add_theme_color_override("font_color", Color("728482"))
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(status_label)
	var status_value := Label.new()
	status_value.text = "适中"
	status_value.add_theme_font_size_override("font_size", _int_dim(13))
	status_value.add_theme_color_override("font_color", dark_color)
	status_row.add_child(status_value)

	return {"card": card, "title": title, "metrics": metrics, "status": status_value}


func _refresh_region_cards() -> void:
	for region_id_variant: Variant in _anchor_entries.keys():
		var region_id: String = str(region_id_variant)
		var entry: Dictionary = _anchor_entries[region_id]
		var config: Dictionary = entry.get("config", {}) as Dictionary
		var data: Dictionary = _regions.get(region_id, {}) as Dictionary
		var title: Label = entry.get("title") as Label
		var metrics: VBoxContainer = entry.get("metrics") as VBoxContainer
		var status: Label = entry.get("status") as Label
		if title != null:
			title.text = str(data.get("name", config.get("name", "区域")))
		if metrics == null:
			continue
		for child: Node in metrics.get_children():
			metrics.remove_child(child)
			child.queue_free()

		var lines_variant: Variant = data.get("lines", [])
		var lines: Array = lines_variant as Array if lines_variant is Array else []
		if lines.is_empty():
			lines = _fallback_lines(region_id)
		var status_text: String = "适中"
		for line_variant: Variant in lines:
			if not line_variant is Dictionary:
				continue
			var line_data: Dictionary = line_variant as Dictionary
			metrics.add_child(_metric_row(
				str(line_data.get("display_symbol", line_data.get("label", ""))),
				str(line_data.get("value_text", "--"))
			))
			if status_text == "适中":
				var candidate: String = str(line_data.get("status_text", ""))
				if not candidate.is_empty():
					status_text = candidate
		if status != null:
			status.text = status_text
	call_deferred("_refresh_card_sizes")


func _fallback_lines(region_id: String) -> Array[Dictionary]:
	match region_id:
		"consumption":
			return [{"display_symbol": "C", "value_text": "54"}, {"display_symbol": "Y", "value_text": "100"}]
		"industry":
			return [{"display_symbol": "I", "value_text": "23"}, {"display_symbol": "Y", "value_text": "100"}]
		"finance":
			return [{"display_symbol": "i", "value_text": "4.0%"}]
		_:
			return [{"display_symbol": "G", "value_text": "23"}, {"display_symbol": "Debt", "value_text": "60%"}]


func _metric_row(symbol: String, value: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var symbol_label := Label.new()
	symbol_label.text = symbol
	symbol_label.add_theme_font_size_override("font_size", _int_dim(13))
	symbol_label.add_theme_color_override("font_color", Color("728482"))
	symbol_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(symbol_label)
	var value_label := Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", _int_dim(13))
	value_label.add_theme_color_override("font_color", Color("263c3d"))
	row.add_child(value_label)
	return row


func _refresh_card_sizes() -> void:
	for entry_variant: Variant in _anchor_entries.values():
		var entry: Dictionary = entry_variant as Dictionary
		var card: PanelContainer = entry.get("card") as PanelContainer
		if card == null:
			continue
		var minimum: Vector2 = card.get_combined_minimum_size()
		card.size = Vector2(maxf(_dim(190.0), minimum.x), minimum.y)


func _process(delta: float) -> void:
	if _sphere == null or _camera == null:
		return
	if _is_dragging:
		_yaw_velocity += ((_target_yaw - _yaw) * DRAG_STIFFNESS - _yaw_velocity * DRAG_DAMPING) * delta
		_pitch_velocity += ((_target_pitch - _pitch) * DRAG_STIFFNESS - _pitch_velocity * DRAG_DAMPING) * delta
		_yaw += _yaw_velocity * delta
		_pitch = clampf(_pitch + _pitch_velocity * delta, MIN_PITCH, MAX_PITCH)
	else:
		_yaw += _yaw_velocity * delta
		_pitch = clampf(_pitch + _pitch_velocity * delta, MIN_PITCH, MAX_PITCH)
		var inertia_decay: float = exp(-ROTATION_DAMPING * delta)
		_yaw_velocity *= inertia_decay
		_pitch_velocity *= inertia_decay

	if absf(_yaw) > PI * 4.0:
		var wrapped_yaw: float = fmod(_yaw, TAU)
		_target_yaw -= _yaw - wrapped_yaw
		_yaw = wrapped_yaw

	var zoom_blend: float = 1.0 - exp(-ZOOM_DAMPING * delta)
	_camera_distance = lerpf(_camera_distance, _target_camera_distance, zoom_blend)
	_sphere.basis = Basis(Vector3.RIGHT, _pitch) * Basis(Vector3.UP, _yaw)
	_camera.position = Vector3(0.0, 0.0, _camera_distance)
	_camera.look_at(Vector3.ZERO, Vector3.UP)
	_update_anchor_overlay(delta)


func _begin_drag(viewport_position: Vector2) -> void:
	_is_dragging = true
	_last_drag_position = viewport_position
	_target_yaw = _yaw
	_target_pitch = _pitch
	_yaw_velocity = 0.0
	_pitch_velocity = 0.0


func _end_drag() -> void:
	_is_dragging = false


func _zoom_camera(direction: float, event_factor: float) -> void:
	var factor: float = absf(event_factor)
	if is_zero_approx(factor):
		factor = 1.0
	var zoom_factor: float = exp(direction * clampf(factor, 0.1, 3.0) * 0.16)
	_target_camera_distance = clampf(
		_target_camera_distance * zoom_factor,
		_minimum_camera_distance,
		_maximum_camera_distance
	)


func _on_resized() -> void:
	if _subviewport == null:
		return
	var viewport_size := Vector2i(maxi(1, roundi(size.x)), maxi(1, roundi(size.y)))
	_subviewport.size = viewport_size
	_update_camera_bounds()
	_refresh_card_sizes()


func _update_camera_bounds() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var old_range: float = _maximum_camera_distance - _minimum_camera_distance
	var old_progress: float = clampf(
		(_target_camera_distance - _minimum_camera_distance) / old_range,
		0.0,
		1.0
	) if old_range > 0.0 else 1.0
	var target_radius: float = minf(size.y / 3.0, (size.x - 48.0) / 2.0)
	_maximum_camera_distance = _projected_sphere_distance(maxf(80.0, target_radius))
	_minimum_camera_distance = _solve_minimum_camera_distance()
	if not _has_sized_viewport:
		_camera_distance = _maximum_camera_distance
		_target_camera_distance = _maximum_camera_distance
		_has_sized_viewport = true
		return
	_target_camera_distance = lerpf(_minimum_camera_distance, _maximum_camera_distance, old_progress)
	_camera_distance = clampf(_camera_distance, _minimum_camera_distance, _maximum_camera_distance)


func _projected_sphere_distance(target_radius_pixels: float) -> float:
	var normalized_radius: float = target_radius_pixels / (size.y * 0.5)
	var tangent: float = normalized_radius * tan(deg_to_rad(FIELD_OF_VIEW) * 0.5)
	return sqrt(SPHERE_RADIUS * SPHERE_RADIUS + pow(SPHERE_RADIUS / maxf(tangent, 0.001), 2.0))


func _projected_sphere_radius(distance: float) -> float:
	var tangent: float = SPHERE_RADIUS / sqrt(maxf(0.001, distance * distance - SPHERE_RADIUS * SPHERE_RADIUS))
	return size.y * 0.5 * tangent / tan(deg_to_rad(FIELD_OF_VIEW) * 0.5)


func _solve_minimum_camera_distance() -> float:
	var near_distance: float = 1.08
	var far_distance: float = maxf(_maximum_camera_distance, 5.0)
	while _country_coverage_at_distance(far_distance) > COUNTRY_TARGET_LINEAR_COVERAGE:
		far_distance *= 1.25
	for iteration: int in range(48):
		var midpoint: float = (near_distance + far_distance) * 0.5
		if _country_coverage_at_distance(midpoint) > COUNTRY_TARGET_LINEAR_COVERAGE:
			near_distance = midpoint
		else:
			far_distance = midpoint
	return minf(far_distance, _maximum_camera_distance - 0.08)


func _country_coverage_at_distance(distance: float) -> float:
	var focal_length: float = 1.0 / tan(deg_to_rad(FIELD_OF_VIEW) * 0.5)
	var aspect: float = size.x / maxf(size.y, 1.0)
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for sample: Vector2 in CORE_COUNTRY_BOUNDARY:
		var point: Vector3 = _longitude_latitude_to_point(sample.x, sample.y)
		var depth: float = maxf(0.02, distance - point.z)
		var normalized := Vector2(
			(point.x * focal_length / aspect) / depth,
			(point.y * focal_length) / depth
		)
		var screen_point := Vector2(
			(normalized.x * 0.5 + 0.5) * size.x,
			(0.5 - normalized.y * 0.5) * size.y
		)
		minimum = minimum.min(screen_point)
		maximum = maximum.max(screen_point)
	return maxf((maximum.x - minimum.x) / size.x, (maximum.y - minimum.y) / size.y)


func _update_anchor_overlay(delta: float) -> void:
	if _anchor_entries.is_empty() or size.x <= 1.0 or size.y <= 1.0:
		return
	var center: Vector2 = size * 0.5
	var sphere_radius_pixels: float = _projected_sphere_radius(_camera_distance)
	var safe_rect: Rect2 = _formal_hud_safe_rect()
	var visible_items: Array[Dictionary] = []

	for region_id_variant: Variant in _anchor_entries.keys():
		var region_id: String = str(region_id_variant)
		var entry: Dictionary = _anchor_entries[region_id]
		var local_point: Vector3 = entry.get("local_point", Vector3.FORWARD)
		var world_normal: Vector3 = (_sphere.basis * local_point).normalized()
		var world_point: Vector3 = world_normal * ANCHOR_SURFACE_RADIUS
		var camera_direction: Vector3 = (_camera.position - world_point).normalized()
		var facing: float = world_normal.dot(camera_direction)
		var was_visible: bool = bool(entry.get("front_visible", false))
		var threshold: float = ANCHOR_HIDE_THRESHOLD if was_visible else ANCHOR_SHOW_THRESHOLD
		var front_visible: bool = facing > threshold
		entry["front_visible"] = front_visible
		var alpha: float = float(entry.get("alpha", 0.0))
		alpha = move_toward(alpha, 1.0 if front_visible else 0.0, delta / ANCHOR_FADE_DURATION)
		entry["alpha"] = alpha
		var projection: Vector2 = _camera.unproject_position(world_point)
		entry["projection"] = projection

		var marker: Panel = entry.get("marker") as Panel
		var line: Line2D = entry.get("line") as Line2D
		var card: PanelContainer = entry.get("card") as PanelContainer
		var shown: bool = alpha > 0.001
		marker.visible = shown
		line.visible = shown
		card.visible = shown
		marker.modulate.a = alpha
		line.modulate.a = alpha
		card.modulate.a = alpha
		marker.position = projection - marker.size * 0.5
		if not shown:
			continue

		var card_size: Vector2 = card.size
		var radial_delta: Vector2 = projection - center
		var radial_length: float = maxf(radial_delta.length(), 1.0)
		var radial: Vector2 = radial_delta / radial_length
		var side: String = "left" if radial.x < 0.0 else "right"
		var left: float = safe_rect.position.x if side == "left" else safe_rect.end.x - card_size.x
		var outer_y: float = center.y + radial.y * (sphere_radius_pixels + 30.0 * _ui_scale)
		visible_items.append({
			"entry": entry,
			"side": side,
			"left": left,
			"desired_top": outer_y - card_size.y * 0.5,
			"top": 0.0,
			"width": card_size.x,
			"height": card_size.y,
			"radial": radial
		})

	_resolve_card_column(_items_on_side(visible_items, "left"), safe_rect)
	_resolve_card_column(_items_on_side(visible_items, "right"), safe_rect)

	for item: Dictionary in visible_items:
		var entry: Dictionary = item.get("entry", {}) as Dictionary
		var card: PanelContainer = entry.get("card") as PanelContainer
		var line: Line2D = entry.get("line") as Line2D
		var projection: Vector2 = entry.get("projection", Vector2.ZERO)
		var card_position := Vector2(float(item.get("left", 0.0)), float(item.get("top", 0.0)))
		card.position = card_position
		var side: String = str(item.get("side", "right"))
		var end_x: float = card_position.x + card.size.x if side == "left" else card_position.x
		var end_y: float = clampf(projection.y, card_position.y + _dim(18.0), card_position.y + card.size.y - _dim(18.0))
		var end := Vector2(end_x, end_y)
		var radial: Vector2 = item.get("radial", Vector2.RIGHT)
		var outward_distance: float = minf(_dim(54.0), maxf(_dim(28.0), projection.distance_to(end) * 0.24))
		var knee: Vector2 = projection + radial * outward_distance
		var approach := Vector2(end_x + (_dim(12.0) if side == "left" else -_dim(12.0)), end_y)
		line.points = PackedVector2Array([projection, knee, approach, end])


func _items_on_side(items: Array[Dictionary], side: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: Dictionary in items:
		if str(item.get("side", "")) == side:
			result.append(item)
	return result


func _resolve_card_column(items: Array[Dictionary], safe_rect: Rect2) -> void:
	if items.is_empty():
		return
	items.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		return float(first.get("desired_top", 0.0)) < float(second.get("desired_top", 0.0))
	)
	var cursor: float = safe_rect.position.y
	for item: Dictionary in items:
		var height: float = float(item.get("height", 0.0))
		var top: float = clampf(float(item.get("desired_top", cursor)), cursor, safe_rect.end.y - height)
		item["top"] = top
		cursor = top + height + _dim(CARD_GAP)
	var overflow: float = cursor - _dim(CARD_GAP) - safe_rect.end.y
	if overflow > 0.0:
		for item: Dictionary in items:
			item["top"] = float(item.get("top", 0.0)) - overflow
	for index: int in range(items.size() - 2, -1, -1):
		var current: Dictionary = items[index]
		var next: Dictionary = items[index + 1]
		current["top"] = minf(
			float(current.get("top", 0.0)),
			float(next.get("top", 0.0)) - _dim(CARD_GAP) - float(current.get("height", 0.0))
		)
	if float(items[0].get("top", 0.0)) < safe_rect.position.y:
		var correction: float = safe_rect.position.y - float(items[0].get("top", 0.0))
		for item: Dictionary in items:
			item["top"] = float(item.get("top", 0.0)) + correction


func _formal_hud_safe_rect() -> Rect2:
	var left: float = _dim(348.0)
	var right: float = size.x - _dim(352.0)
	var top: float = _dim(126.0)
	var bottom: float = size.y - _dim(224.0)
	if right - left < _dim(410.0) or bottom - top < _dim(250.0):
		var margin: float = _dim(24.0)
		return Rect2(Vector2.ONE * margin, size - Vector2.ONE * margin * 2.0)
	return Rect2(Vector2(left, top), Vector2(right - left, bottom - top))


func _longitude_latitude_to_point(longitude_degrees: float, latitude_degrees: float) -> Vector3:
	var longitude: float = deg_to_rad(longitude_degrees)
	var latitude: float = deg_to_rad(latitude_degrees)
	var cos_latitude: float = cos(latitude)
	return Vector3(
		cos_latitude * sin(longitude),
		sin(latitude),
		cos_latitude * cos(longitude)
	)


func _card_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.95)
	style.border_color = accent.lerp(Color("dce7e4"), 0.58)
	style.set_border_width_all(_int_dim(1))
	style.border_width_top = _int_dim(3)
	style.set_corner_radius_all(_int_dim(11))
	style.shadow_color = Color(0.18, 0.30, 0.31, 0.13)
	style.shadow_size = _int_dim(18)
	style.shadow_offset = Vector2(0.0, _dim(7.0))
	return style


func _marker_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = accent
	style.border_color = Color(1.0, 1.0, 1.0, 0.9)
	style.set_border_width_all(_int_dim(2))
	style.set_corner_radius_all(_int_dim(20))
	style.shadow_color = Color(accent, 0.24)
	style.shadow_size = _int_dim(5)
	return style


func _dot_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = accent
	style.set_corner_radius_all(_int_dim(10))
	return style


func _dim(value: float) -> float:
	return value * _ui_scale


func _int_dim(value: float) -> int:
	return maxi(1, roundi(_dim(value)))
