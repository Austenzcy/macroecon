extends Control

const HudReferenceTheme = preload("res://scripts/ui/hud_reference/HudReferenceTheme.gd")
const HudReferencePanel = preload("res://scripts/ui/hud_reference/HudReferencePanel.gd")
const HudReferenceIcon = preload("res://scripts/ui/hud_reference/HudReferenceIcon.gd")
const HudReferenceChart = preload("res://scripts/ui/hud_reference/HudReferenceChart.gd")
const HudReferenceMetricRow = preload("res://scripts/ui/hud_reference/HudReferenceMetricRow.gd")
const UnifiedMacroMapScene = preload("res://scenes/components/UnifiedMacroMap.tscn")

const LEVEL_SELECT_PATH := "res://scenes/LevelSelect.tscn"

var _layout_version: int = 0
var _unified_macro_map: Control
var _hud_blocker_rects: Array[Rect2] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	_build_ui()
	_report_web_boot_ready()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		_build_ui()
		queue_redraw()


func _build_ui() -> void:
	_layout_version += 1
	_unified_macro_map = null
	_hud_blocker_rects.clear()
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	if size.x < 200.0 or size.y < 200.0:
		return
	_build_reference_map()

	var scale: float = _responsive_scale()
	var margin: float = _d(14, scale)
	var top_h: float = clampf(size.y * 0.125, _d(108, scale), _d(138, scale))
	var left_w: float = clampf(size.x * 0.162, _d(248, scale), _d(318, scale))
	var right_w: float = clampf(size.x * 0.174, _d(274, scale), _d(344, scale))
	var bottom_h: float = clampf(size.y * 0.265, _d(214, scale), _d(304, scale))
	var gap: float = _d(18, scale)

	var top_rect := Rect2(margin, margin, size.x - margin * 2.0, top_h)
	var left_rect := Rect2(margin, top_h + margin + gap, left_w, size.y - top_h - bottom_h - margin * 2.0 - gap * 2.0)
	var right_rect := Rect2(size.x - margin - right_w, top_h + margin + gap, right_w, size.y - top_h - margin * 2.0 - gap)
	_build_top_band(top_rect, scale)
	_build_left_drawer(left_rect, scale)
	_build_right_drawer(right_rect, scale)

	var central_left: float = margin + left_w + gap * 1.25
	var central_right: float = size.x - margin - right_w - gap * 1.25
	var bottom_w: float = clampf(central_right - central_left, _d(620, scale), _d(930, scale))
	var bottom_x: float = central_left + maxf(0.0, (central_right - central_left - bottom_w) * 0.5)
	var bottom_rect := Rect2(bottom_x, size.y - margin - bottom_h, bottom_w, bottom_h)
	_build_bottom_analysis(bottom_rect, scale)
	_hud_blocker_rects.assign([top_rect, left_rect, right_rect, bottom_rect])


func _build_reference_map() -> void:
	var map := UnifiedMacroMapScene.instantiate() as Control
	if map == null:
		return
	_unified_macro_map = map
	map.name = "UnifiedMacroMap"
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map)
	if map.has_method("set_regions"):
		map.call("set_regions", _reference_region_data())


func _reference_region_data() -> Array[Dictionary]:
	return [
		{
			"region_id": "consumption", "name": "居民消费区",
			"lines": [{"display_symbol": "C", "value_text": "54.0", "status_text": "偏低"}]
		},
		{
			"region_id": "industry", "name": "工业产区",
			"lines": [
				{"display_symbol": "Y", "value_text": "100.0", "status_text": "正常"},
				{"display_symbol": "I", "value_text": "23.0", "status_text": "适中"}
			]
		},
		{
			"region_id": "finance", "name": "金融市场区",
			"lines": [{"display_symbol": "i", "value_text": "5.0%", "status_text": "正常"}]
		},
		{
			"region_id": "government", "name": "政府部门区",
			"lines": [
				{"display_symbol": "G", "value_text": "23.0", "status_text": "适中"},
				{"display_symbol": "Debt", "value_text": "50.0", "status_text": "适中"}
			]
		}
	]


func _input(event: InputEvent) -> void:
	if _unified_macro_map == null or not is_instance_valid(_unified_macro_map):
		return
	if not (event is InputEventMouseButton or event is InputEventMouseMotion):
		return
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		var is_wheel := button_event.button_index == MOUSE_BUTTON_WHEEL_UP or button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN
		if is_wheel and button_event.ctrl_pressed:
			get_viewport().set_input_as_handled()
			return
	var viewport_position := get_viewport().get_mouse_position()
	var local_position := get_global_transform_with_canvas().affine_inverse() * viewport_position
	var over_hud := _is_pointer_over_hud(local_position)
	var consumed := bool(_unified_macro_map.call(
		"handle_viewport_input",
		event,
		viewport_position,
		Input.is_key_pressed(KEY_SPACE),
		not over_hud
	))
	if consumed:
		get_viewport().set_input_as_handled()


func _is_pointer_over_hud(local_position: Vector2) -> bool:
	for rect: Rect2 in _hud_blocker_rects:
		if rect.has_point(local_position):
			return true
	return false


func _build_top_band(rect: Rect2, scale: float) -> void:
	var panel: Control = _panel("top_band", rect, HudReferenceTheme.CYAN)
	var pad: float = _d(22, scale)
	var left_w: float = rect.size.x * 0.34
	var right_w: float = rect.size.x * 0.31
	var center_x: float = rect.position.x + left_w
	var center_w: float = rect.size.x - left_w - right_w

	_label("当前挑战", Rect2(rect.position + Vector2(pad, _d(14, scale)), Vector2(left_w - pad * 2.0, _d(22, scale))), HudReferenceTheme.FONT_CHALLENGE_KICKER, HudReferenceTheme.TEXT_CYAN, scale, false, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, HudReferenceTheme.WEIGHT_MEDIUM, Color(HudReferenceTheme.TEXT_CYAN.r, HudReferenceTheme.TEXT_CYAN.g, HudReferenceTheme.TEXT_CYAN.b, 0.18))
	_label("消费信心下降", Rect2(rect.position + Vector2(pad, _d(35, scale)), Vector2(left_w - pad * 2.0, _d(40, scale))), HudReferenceTheme.FONT_CHALLENGE_TITLE, HudReferenceTheme.TEXT_PRIMARY, scale, true, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, HudReferenceTheme.WEIGHT_SEMIBOLD)
	_label("核心变量：C↓，总需求下降，IS 曲线左移。", Rect2(rect.position + Vector2(pad, _d(77, scale)), Vector2(left_w - pad * 2.0, _d(42, scale))), HudReferenceTheme.FONT_CHALLENGE_MECHANISM, HudReferenceTheme.TEXT_BODY, scale, false, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, HudReferenceTheme.WEIGHT_REGULAR)
	_line_segment(rect.position + Vector2(left_w - _d(10, scale), _d(20, scale)), rect.position + Vector2(left_w - _d(10, scale), rect.size.y - _d(20, scale)), Color(0.66, 0.92, 1.0, 0.16))

	_label("回合 1 / 1", Rect2(Vector2(center_x, rect.position.y + _d(18, scale)), Vector2(center_w, _d(34, scale))), HudReferenceTheme.FONT_ROUND, HudReferenceTheme.TEXT_PRIMARY, scale, true, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_TOP, HudReferenceTheme.WEIGHT_SEMIBOLD)
	var tags: Array[String] = ["封闭经济", "短期", "价格粘性", "IS-LM", "需求不足"]
	var tag_w: float = minf(_d(82, scale), (center_w - _d(28, scale)) / float(tags.size()))
	var total_tags_w: float = tag_w * tags.size() + _d(7, scale) * float(tags.size() - 1)
	var tag_x: float = center_x + (center_w - total_tags_w) * 0.5
	for tag: String in tags:
		_chip(tag, Rect2(Vector2(tag_x, rect.position.y + _d(56, scale)), Vector2(tag_w, _d(25, scale))), HudReferenceTheme.CYAN, scale, "none")
		tag_x += tag_w + _d(7, scale)
	_line_segment(Vector2(center_x + center_w + _d(10, scale), rect.position.y + _d(20, scale)), Vector2(center_x + center_w + _d(10, scale), rect.position.y + rect.size.y - _d(20, scale)), Color(0.66, 0.92, 1.0, 0.16))

	var rx: float = rect.position.x + rect.size.x - right_w + _d(20, scale)
	_label("公元1000年 第一季度", Rect2(Vector2(rx, rect.position.y + _d(16, scale)), Vector2(right_w - _d(38, scale), _d(26, scale))), HudReferenceTheme.FONT_TOP_META, HudReferenceTheme.TEXT_BODY, scale, false, HORIZONTAL_ALIGNMENT_RIGHT, VERTICAL_ALIGNMENT_TOP, HudReferenceTheme.WEIGHT_MEDIUM)
	_resource_chip("wisdom", "智慧点 10", Rect2(Vector2(rx + _d(8, scale), rect.position.y + _d(47, scale)), Vector2(_d(118, scale), _d(34, scale))), HudReferenceTheme.GOLD, scale)
	_resource_chip("policy_point", "政策点 1 / 1", Rect2(Vector2(rx + _d(136, scale), rect.position.y + _d(47, scale)), Vector2(_d(138, scale), _d(34, scale))), HudReferenceTheme.GOLD, scale)
	_icon_button("hint", "提示", Rect2(Vector2(rect.position.x + rect.size.x - _d(154, scale), rect.position.y + _d(47, scale)), Vector2(_d(66, scale), _d(34, scale))), HudReferenceTheme.CYAN, scale)
	_icon_button("review", "回看", Rect2(Vector2(rect.position.x + rect.size.x - _d(78, scale), rect.position.y + _d(47, scale)), Vector2(_d(62, scale), _d(34, scale))), HudReferenceTheme.CYAN, scale)


func _build_left_drawer(rect: Rect2, scale: float) -> void:
	_panel("left_drawer", rect, HudReferenceTheme.CYAN)
	_label("政策卡", Rect2(rect.position + Vector2(_d(18, scale), _d(16, scale)), Vector2(rect.size.x - _d(72, scale), _d(34, scale))), HudReferenceTheme.FONT_DRAWER_TITLE, HudReferenceTheme.TEXT_PRIMARY, scale, true, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, HudReferenceTheme.WEIGHT_SEMIBOLD)
	_resource_chip("policy_point", "政策点 1 / 1", Rect2(rect.position + Vector2(_d(18, scale), _d(50, scale)), Vector2(rect.size.x - _d(50, scale), _d(34, scale))), HudReferenceTheme.GOLD, scale)
	_drawer_tab(Rect2(Vector2(rect.position.x + rect.size.x - _d(28, scale), rect.position.y + _d(17, scale)), Vector2(_d(40, scale), _d(54, scale))), "collapse_left", scale)

	var cards: Array[Dictionary] = [
		{"title": "增加政府购买", "desc": "提高政府支出，直接拉动总需求。", "icon": "government"},
		{"title": "扩张性货币政策", "desc": "降低利率，刺激投资和消费。", "icon": "monetary"},
		{"title": "减税", "desc": "减轻税负，增加居民可支配收入。", "icon": "tax"},
	]
	var top: float = rect.position.y + _d(100, scale)
	var gap: float = _d(12, scale)
	var card_h: float = minf(_d(124, scale), (rect.position.y + rect.size.y - top - _d(18, scale) - gap * 2.0) / 3.0)
	for i: int in range(cards.size()):
		var card_rect: Rect2 = Rect2(Vector2(rect.position.x + _d(14, scale), top + (card_h + gap) * float(i)), Vector2(rect.size.x - _d(30, scale), card_h))
		_build_policy_card(card_rect, cards[i], i == 0, scale)


func _build_policy_card(rect: Rect2, data: Dictionary, selected: bool, scale: float) -> void:
	var accent: Color = HudReferenceTheme.CYAN if selected else Color(0.54, 0.78, 0.86, 0.66)
	_panel("policy", rect, accent)
	if selected:
		_line_segment(rect.position + Vector2(_d(5, scale), _d(14, scale)), rect.position + Vector2(_d(5, scale), rect.size.y - _d(14, scale)), HudReferenceTheme.CYAN, 2.4)
	var icon_rect: Rect2 = Rect2(rect.position + Vector2(_d(14, scale), _d(25, scale)), Vector2(_d(46, scale), _d(46, scale)))
	_icon(String(data["icon"]), icon_rect, HudReferenceTheme.CYAN)
	_label(String(data["title"]), Rect2(rect.position + Vector2(_d(72, scale), _d(16, scale)), Vector2(rect.size.x - _d(94, scale), _d(28, scale))), HudReferenceTheme.FONT_POLICY_TITLE, HudReferenceTheme.TEXT_PRIMARY, scale, true, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, HudReferenceTheme.WEIGHT_SEMIBOLD)
	_label(String(data["desc"]), Rect2(rect.position + Vector2(_d(72, scale), _d(48, scale)), Vector2(rect.size.x - _d(92, scale), _d(48, scale))), HudReferenceTheme.FONT_POLICY_DESCRIPTION, HudReferenceTheme.TEXT_BODY, scale, false, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, HudReferenceTheme.WEIGHT_REGULAR)
	_resource_chip("policy_point", "1", Rect2(rect.position + Vector2(rect.size.x - _d(56, scale), rect.size.y - _d(35, scale)), Vector2(_d(40, scale), _d(24, scale))), HudReferenceTheme.GOLD, scale)


func _build_right_drawer(rect: Rect2, scale: float) -> void:
	_panel("right_drawer", rect, HudReferenceTheme.CYAN)
	_drawer_tab(Rect2(Vector2(rect.position.x - _d(12, scale), rect.position.y + _d(17, scale)), Vector2(_d(40, scale), _d(54, scale))), "collapse_right", scale)
	_label("宏观状态", Rect2(rect.position + Vector2(_d(20, scale), _d(18, scale)), Vector2(rect.size.x - _d(40, scale), _d(34, scale))), HudReferenceTheme.FONT_DRAWER_TITLE, HudReferenceTheme.TEXT_PRIMARY, scale, true, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, HudReferenceTheme.WEIGHT_SEMIBOLD)
	_label("当前问题：消费信心下降", Rect2(rect.position + Vector2(_d(20, scale), _d(58, scale)), Vector2(rect.size.x - _d(40, scale), _d(27, scale))), HudReferenceTheme.FONT_CURRENT_PROBLEM, HudReferenceTheme.TEXT_PRIMARY, scale, true, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, HudReferenceTheme.WEIGHT_SEMIBOLD)
	_label("核心指标", Rect2(rect.position + Vector2(_d(20, scale), _d(94, scale)), Vector2(rect.size.x - _d(40, scale), _d(23, scale))), HudReferenceTheme.FONT_DRAWER_SUBTITLE, HudReferenceTheme.TEXT_GOLD, scale, false, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, HudReferenceTheme.WEIGHT_MEDIUM)
	_line_segment(rect.position + Vector2(_d(20, scale), _d(118, scale)), rect.position + Vector2(rect.size.x - _d(20, scale), _d(118, scale)), Color(0.7, 0.9, 1.0, 0.16))

	var metrics: Array[Dictionary] = [
		{"name": "产出", "symbol": "Y", "value": "100.0", "status": "偏低", "n": 0.44, "r": 0.60},
		{"name": "失业率", "symbol": "u", "value": "5.0%", "status": "适中", "n": 0.51, "r": 0.50},
		{"name": "通胀率", "symbol": "π", "value": "2.0%", "status": "适中", "n": 0.50, "r": 0.50},
		{"name": "利率", "symbol": "i", "value": "4.0%", "status": "适中", "n": 0.53, "r": 0.50},
		{"name": "政府债务", "symbol": "Debt", "value": "60.0%", "status": "适中", "n": 0.57, "r": 0.50},
	]
	var y: float = rect.position.y + _d(134, scale)
	for metric: Dictionary in metrics:
		var row: Control = HudReferenceMetricRow.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.set_anchors_preset(Control.PRESET_TOP_LEFT)
		row.position = Vector2(rect.position.x + _d(20, scale), y)
		row.size = Vector2(rect.size.x - _d(40, scale), _d(43, scale))
		row.setup(metric["name"], metric["symbol"], metric["value"], metric["status"], metric["n"], metric["r"])
		add_child(row)
		y += _d(49, scale)

	_label("行动提示", Rect2(rect.position + Vector2(_d(20, scale), rect.size.y - _d(128, scale)), Vector2(rect.size.x - _d(40, scale), _d(23, scale))), HudReferenceTheme.FONT_ACTION_HEADING, HudReferenceTheme.TEXT_GOLD, scale, false, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, HudReferenceTheme.WEIGHT_MEDIUM)
	_label("选择一张政策卡，并确认执行。", Rect2(rect.position + Vector2(_d(20, scale), rect.size.y - _d(102, scale)), Vector2(rect.size.x - _d(40, scale), _d(34, scale))), HudReferenceTheme.FONT_ACTION_BODY, HudReferenceTheme.TEXT_BODY, scale, false)
	var button_rect: Rect2 = Rect2(rect.position + Vector2(_d(20, scale), rect.size.y - _d(62, scale)), Vector2(rect.size.x - _d(40, scale), _d(44, scale)))
	_panel("button", button_rect, HudReferenceTheme.GOLD)
	_icon("confirm", Rect2(button_rect.position + Vector2(_d(28, scale), _d(10, scale)), Vector2(_d(24, scale), _d(24, scale))), HudReferenceTheme.GOLD)
	_label("确认政策", Rect2(button_rect.position, button_rect.size), HudReferenceTheme.FONT_CONFIRM_BUTTON, HudReferenceTheme.TEXT_PRIMARY, scale, true, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, HudReferenceTheme.WEIGHT_SEMIBOLD)


func _build_bottom_analysis(rect: Rect2, scale: float) -> void:
	_panel("analysis", rect, HudReferenceTheme.CYAN)
	var gap: float = _d(14, scale)
	var left_w: float = minf(rect.size.x * 0.58, rect.size.y * 1.33)
	var right_w: float = rect.size.x - left_w - gap - _d(28, scale)
	var module_y: float = rect.position.y + _d(14, scale)
	var module_h: float = rect.size.y - _d(28, scale)
	var islm_rect: Rect2 = Rect2(rect.position + Vector2(_d(14, scale), _d(14, scale)), Vector2(left_w, module_h))
	var donut_rect: Rect2 = Rect2(Vector2(islm_rect.position.x + islm_rect.size.x + gap, module_y), Vector2(right_w, module_h))
	_panel("module", islm_rect, HudReferenceTheme.CYAN)
	_panel("module", donut_rect, HudReferenceTheme.GOLD)
	_label("IS-LM 分析", Rect2(islm_rect.position + Vector2(_d(16, scale), _d(11, scale)), Vector2(islm_rect.size.x - _d(32, scale), _d(29, scale))), HudReferenceTheme.FONT_ANALYSIS_TITLE, HudReferenceTheme.TEXT_PRIMARY, scale, true, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, HudReferenceTheme.WEIGHT_SEMIBOLD)
	_label("消费信心下降 → C 减少 → 总需求下降 → IS 曲线左移", Rect2(islm_rect.position + Vector2(_d(16, scale), _d(42, scale)), Vector2(islm_rect.size.x - _d(32, scale), _d(38, scale))), HudReferenceTheme.FONT_ANALYSIS_HINT, HudReferenceTheme.TEXT_BODY, scale, false)
	var chart: Control = HudReferenceChart.new()
	chart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chart.position = islm_rect.position + Vector2(_d(14, scale), _d(78, scale))
	chart.size = islm_rect.size - Vector2(_d(28, scale), _d(90, scale))
	chart.setup_islm()
	add_child(chart)

	_label("总需求构成", Rect2(donut_rect.position + Vector2(_d(16, scale), _d(11, scale)), Vector2(donut_rect.size.x - _d(32, scale), _d(29, scale))), HudReferenceTheme.FONT_ANALYSIS_TITLE, HudReferenceTheme.TEXT_PRIMARY, scale, true, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, HudReferenceTheme.WEIGHT_SEMIBOLD)
	var donut: Control = HudReferenceChart.new()
	donut.mouse_filter = Control.MOUSE_FILTER_IGNORE
	donut.position = donut_rect.position + Vector2(_d(10, scale), _d(46, scale))
	donut.size = donut_rect.size - Vector2(_d(20, scale), _d(58, scale))
	donut.setup_donut(54.0, 23.0, 23.0)
	add_child(donut)


func _panel(kind: String, rect: Rect2, accent: Color) -> Control:
	var panel: Control = HudReferencePanel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = rect.position
	panel.size = rect.size
	panel.setup(kind, accent)
	add_child(panel)
	return panel


func _label(text: String, rect: Rect2, font_size: int, color: Color, scale: float, strong: bool = false, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, valign: VerticalAlignment = VERTICAL_ALIGNMENT_TOP, weight: String = "", glow: Color = Color.TRANSPARENT) -> Label:
	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.position = rect.position
	label.size = rect.size
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = valign
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var actual_weight: String = weight
	if actual_weight == "":
		actual_weight = HudReferenceTheme.WEIGHT_SEMIBOLD if strong else HudReferenceTheme.WEIGHT_REGULAR
	HudReferenceTheme.apply_label_font(label, font_size, color, _font_scale(), actual_weight, glow)
	add_child(label)
	return label


func _chip(text: String, rect: Rect2, accent: Color, scale: float, icon_type: String = "none") -> void:
	_panel("chip", rect, accent)
	var text_rect: Rect2 = rect
	if icon_type != "none":
		_icon(icon_type, Rect2(rect.position + Vector2(_d(8, scale), _d(6, scale)), Vector2(rect.size.y - _d(12, scale), rect.size.y - _d(12, scale))), accent)
		text_rect.position.x += rect.size.y
		text_rect.size.x -= rect.size.y
	_label(text, text_rect, HudReferenceTheme.FONT_MODEL_TAG, accent if icon_type == "none" else HudReferenceTheme.TEXT_PRIMARY, scale, false, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, HudReferenceTheme.WEIGHT_MEDIUM, Color(accent.r, accent.g, accent.b, 0.14) if icon_type == "none" else Color.TRANSPARENT)


func _resource_chip(icon_type: String, text: String, rect: Rect2, accent: Color, scale: float) -> void:
	_panel("chip", rect, accent)
	_icon(icon_type, Rect2(rect.position + Vector2(_d(8, scale), _d(6, scale)), Vector2(rect.size.y - _d(12, scale), rect.size.y - _d(12, scale))), accent)
	var split_index: int = text.rfind(" ")
	var label_text: String = text
	var value_text: String = ""
	if text.begins_with("智慧点"):
		label_text = "智慧点"
		value_text = text.trim_prefix("智慧点").strip_edges()
	elif text.begins_with("政策点"):
		label_text = "政策点"
		value_text = text.trim_prefix("政策点").strip_edges()
	elif split_index > 0:
		label_text = text.substr(0, split_index)
		value_text = text.substr(split_index + 1)
	else:
		label_text = ""
		value_text = text
	var label_rect: Rect2 = Rect2(rect.position + Vector2(rect.size.y, 0), Vector2(rect.size.x - rect.size.y - _d(42, scale), rect.size.y))
	var value_rect: Rect2 = Rect2(rect.position + Vector2(rect.size.x - _d(44, scale), 0), Vector2(_d(38, scale), rect.size.y))
	_label(label_text, label_rect, HudReferenceTheme.FONT_RESOURCE_LABEL, HudReferenceTheme.TEXT_GOLD, scale, false, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, HudReferenceTheme.WEIGHT_MEDIUM)
	_label(value_text, value_rect, HudReferenceTheme.FONT_RESOURCE_VALUE, HudReferenceTheme.TEXT_PRIMARY, scale, true, HORIZONTAL_ALIGNMENT_RIGHT, VERTICAL_ALIGNMENT_CENTER, HudReferenceTheme.WEIGHT_SEMIBOLD)


func _icon_button(icon_type: String, text: String, rect: Rect2, accent: Color, scale: float) -> void:
	_panel("button", rect, accent)
	_icon(icon_type, Rect2(rect.position + Vector2(_d(8, scale), _d(7, scale)), Vector2(_d(20, scale), _d(20, scale))), accent)
	_label(text, Rect2(rect.position + Vector2(_d(28, scale), 0), Vector2(rect.size.x - _d(30, scale), rect.size.y)), HudReferenceTheme.FONT_TOP_ACTION, HudReferenceTheme.TEXT_BODY, scale, false, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, HudReferenceTheme.WEIGHT_MEDIUM)


func _drawer_tab(rect: Rect2, icon_type: String, scale: float) -> void:
	_panel("button", rect, HudReferenceTheme.CYAN)
	_icon(icon_type, Rect2(rect.position + Vector2(_d(10, scale), _d(15, scale)), Vector2(_d(22, scale), _d(22, scale))), HudReferenceTheme.CYAN)


func _icon(icon_type: String, rect: Rect2, color: Color) -> void:
	var icon: Control = HudReferenceIcon.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_TOP_LEFT)
	icon.position = rect.position
	icon.size = rect.size
	icon.setup(icon_type, color)
	add_child(icon)


func _line_segment(a: Vector2, b: Vector2, color: Color, width: float = 1.0) -> void:
	var line: Line2D = Line2D.new()
	line.width = width
	line.default_color = color
	line.points = PackedVector2Array([a, b])
	line.z_index = 2
	add_child(line)


func _responsive_scale() -> float:
	return clampf(size.x / 1600.0, 0.86, 1.08)


func _font_scale() -> float:
	if size.x >= 1800.0 or size.y >= 1000.0:
		return 1.0
	if size.x >= 1500.0 or size.y >= 850.0:
		return 0.94
	return 0.88


func _d(value: float, scale: float) -> float:
	return roundf(value * scale)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(LEVEL_SELECT_PATH)


func _report_web_boot_ready() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.macroPolicyGameReady && window.macroPolicyGameReady();")
