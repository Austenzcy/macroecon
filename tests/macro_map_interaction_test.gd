extends Node

const MAP_SCENE := preload("res://scenes/components/UnifiedMacroMap.tscn")
const HUD_REFERENCE_SCENE := preload("res://scenes/ui/hud_reference/HudReferencePrototype.tscn")
const MacroMapArtSpec = preload("res://scripts/ui/map/MacroMapArtSpec.gd")

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_verify_region_asset_alignment()
	var map := MAP_SCENE.instantiate() as Control
	_expect(map != null, "统一国家地图场景应能实例化")
	if map == null:
		_finish()
		return

	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(map)
	map.set_regions(_sample_regions())
	await get_tree().process_frame
	await get_tree().process_frame

	_expect(map.has_master_texture(), "国家地图应加载高清主纹理")
	var zoom_limits: Vector2 = map.get_map_zoom_limits()
	_expect(is_equal_approx(zoom_limits.x, 1.0), "地图最小缩放应为完整覆盖视口")
	_expect(zoom_limits.y > 1.1, "地图应保留可用的放大范围")
	_expect(_covers_viewport(map.get_map_rect(), map.size), "最小缩放时地图不能出现黑边")

	var consumption_point := _point_on_map(map, Vector2(0.40, 0.33))
	var hover_event := InputEventMouseMotion.new()
	map.handle_viewport_input(hover_event, consumption_point, false, true)
	await get_tree().create_timer(0.18).timeout
	_expect(map.get_hovered_region_id() == "consumption", "居民消费区应能通过透明命中蒙版触发 Hover")

	var blocked_wheel := _wheel_event(MOUSE_BUTTON_WHEEL_UP)
	var blocked_zoom: float = map.get_map_zoom()
	_expect(not map.handle_viewport_input(blocked_wheel, consumption_point, false, false), "HUD 上方滚轮不应被地图消费")
	await get_tree().create_timer(0.18).timeout
	_expect(is_equal_approx(map.get_map_zoom(), blocked_zoom), "HUD 上方滚轮不应改变地图缩放")

	for index: int in range(8):
		map.handle_viewport_input(_wheel_event(MOUSE_BUTTON_WHEEL_UP), consumption_point, false, true)
		await get_tree().create_timer(0.17).timeout
	zoom_limits = map.get_map_zoom_limits()
	_expect(map.get_map_zoom() <= zoom_limits.y + 0.01, "地图放大不能越过动态上限")
	_expect(map.get_map_zoom() >= zoom_limits.y - 0.03, "连续滚轮应能达到地图放大上限")
	_expect(_covers_viewport(map.get_map_rect(), map.size), "放大后地图仍应覆盖视口")

	var drag_start := Vector2(map.size.x * 0.50, map.size.y * 0.48)
	var drag_end := drag_start + Vector2(180.0, 120.0)
	var middle_down := InputEventMouseButton.new()
	middle_down.button_index = MOUSE_BUTTON_MIDDLE
	middle_down.pressed = true
	_expect(map.handle_viewport_input(middle_down, drag_start, false, true), "中键按下应开始移动地图")
	var drag_motion := InputEventMouseMotion.new()
	_expect(map.handle_viewport_input(drag_motion, drag_end, false, true), "中键拖动应移动地图")
	var middle_up := InputEventMouseButton.new()
	middle_up.button_index = MOUSE_BUTTON_MIDDLE
	middle_up.pressed = false
	_expect(map.handle_viewport_input(middle_up, drag_end, false, true), "中键松开应结束地图移动")
	_expect(_covers_viewport(map.get_map_rect(), map.size), "地图平移边界应阻止黑边出现")

	for index: int in range(10):
		map.handle_viewport_input(_wheel_event(MOUSE_BUTTON_WHEEL_DOWN), drag_start, false, true)
		await get_tree().create_timer(0.17).timeout
	_expect(is_equal_approx(map.get_map_zoom(), zoom_limits.x), "缩小应在完整地图覆盖视口时停止")
	_expect(_covers_viewport(map.get_map_rect(), map.size), "缩小到下限仍不能出现黑边")

	map.queue_free()
	await get_tree().process_frame

	var reference := HUD_REFERENCE_SCENE.instantiate() as Control
	get_tree().root.add_child(reference)
	await get_tree().process_frame
	await get_tree().process_frame
	var reference_map := reference.get_node_or_null("UnifiedMacroMap")
	_expect(reference_map != null, "HUD 参考样板应接入统一国家地图")
	if reference_map != null:
		_expect(bool(reference_map.call("has_master_texture")), "HUD 参考样板应使用高清地图纹理")
	reference.queue_free()
	await get_tree().process_frame

	_finish()


func _wheel_event(button_index: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = true
	return event


func _point_on_map(map: Control, normalized_position: Vector2) -> Vector2:
	var rect: Rect2 = map.get_map_rect()
	return rect.position + normalized_position * rect.size


func _covers_viewport(rect: Rect2, viewport_size: Vector2) -> bool:
	return rect.position.x <= 0.01 and rect.position.y <= 0.01 \
		and rect.end.x >= viewport_size.x - 0.01 and rect.end.y >= viewport_size.y - 0.01


func _sample_regions() -> Array[Dictionary]:
	return [
		{"region_id": "consumption", "name": "居民消费区", "lines": [{"display_symbol": "C", "value_text": "54.0", "status_text": "偏低"}]},
		{"region_id": "industry", "name": "工业产区", "lines": [{"display_symbol": "Y", "value_text": "100.0", "status_text": "正常"}]},
		{"region_id": "finance", "name": "金融市场区", "lines": [{"display_symbol": "i", "value_text": "5.0%", "status_text": "正常"}]},
		{"region_id": "government", "name": "政府部门区", "lines": [{"display_symbol": "G", "value_text": "23.0", "status_text": "适中"}]}
	]


func _verify_region_asset_alignment() -> void:
	var master := load(MacroMapArtSpec.MASTER_MAP_TEXTURE) as Texture2D
	_expect(master != null, "高清地图主纹理应可用于切片对齐核验")
	if master == null:
		return
	var master_size := master.get_size()
	for region_id: String in MacroMapArtSpec.all_region_ids():
		var mask := load(str(MacroMapArtSpec.REGION_MASK_TEXTURES.get(region_id, ""))) as Texture2D
		var layer := load(str(MacroMapArtSpec.REGION_LAYER_TEXTURES.get(region_id, ""))) as Texture2D
		_expect(mask != null, "%s 区域命中蒙版应可加载" % region_id)
		_expect(layer != null, "%s 区域 Hover 图层应可加载" % region_id)
		if mask == null or layer == null:
			continue
		var rect: Rect2 = MacroMapArtSpec.region_layer_rect(region_id)
		var expected_layer_size := rect.size * master_size
		_expect(layer.get_size().distance_to(expected_layer_size) <= 2.0, "%s Hover 图层尺寸应与运行时定位矩形一致" % region_id)

		var mask_image := mask.get_image()
		var layer_image := layer.get_image()
		var mask_centroid := _weighted_centroid(mask_image, false, 3) / Vector2(mask_image.get_size())
		var layer_centroid := _weighted_centroid(layer_image, true, 3) / Vector2(layer_image.get_size())
		var mapped_layer_centroid := rect.position + layer_centroid * rect.size
		_expect(mask_centroid.distance_to(mapped_layer_centroid) <= 0.0035, "%s Hover 图层应与命中蒙版保持像素级定位一致" % region_id)


func _weighted_centroid(image: Image, use_alpha: bool, step: int) -> Vector2:
	var weighted_sum := Vector2.ZERO
	var total_weight := 0.0
	for y: int in range(0, image.get_height(), step):
		for x: int in range(0, image.get_width(), step):
			var color := image.get_pixel(x, y)
			var weight: float = color.a if use_alpha else color.r
			if weight <= 0.01:
				continue
			weighted_sum += Vector2(x, y) * weight
			total_weight += weight
	if total_weight <= 0.0:
		return Vector2.ZERO
	return weighted_sum / total_weight


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("MACRO_MAP_INTERACTION_OK")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		printerr("MAP INTERACTION FAILURE: ", failure)
	get_tree().quit(1)
