extends PanelContainer

const ClassicalTheme = preload("res://scripts/ui/ClassicalTheme.gd")
const ArtAssetRegistry = preload("res://scripts/ui/ArtAssetRegistry.gd")

var _name_label: Label
var _line_label: Label
var _avatar_label: Label
var _avatar_texture: TextureRect


func _ready() -> void:
	custom_minimum_size = Vector2(0, 120)
	add_theme_stylebox_override("panel", _make_panel_style())
	_build_ui()


func set_advisor(advisor_name: String, line: String) -> void:
	if _name_label == null:
		return
	_name_label.text = advisor_name
	_line_label.text = line
	_refresh_avatar(advisor_name)


func _build_ui() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	_avatar_label = Label.new()
	_avatar_label.custom_minimum_size = Vector2(70, 70)
	_avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_avatar_label.text = ArtAssetRegistry.placeholder_for_character("economic_advisor")
	_avatar_label.modulate = ClassicalTheme.TEXT_MAIN
	_avatar_label.add_theme_font_size_override("font_size", 24)
	_avatar_label.add_theme_stylebox_override("normal", ClassicalTheme.avatar_style("economic_advisor", 1.0))
	row.add_child(_avatar_label)

	_avatar_texture = TextureRect.new()
	_avatar_texture.name = "AdvisorBadgeTexture"
	_avatar_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_avatar_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_avatar_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar_texture.visible = false
	_avatar_texture.offset_left = 6
	_avatar_texture.offset_top = 6
	_avatar_texture.offset_right = -6
	_avatar_texture.offset_bottom = -6
	_avatar_label.add_child(_avatar_texture)

	var text_box: VBoxContainer = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 8)
	row.add_child(text_box)

	_name_label = Label.new()
	_name_label.text = "顾问"
	_name_label.add_theme_font_size_override("font_size", 20)
	text_box.add_child(_name_label)

	_line_label = Label.new()
	_line_label.text = ""
	_line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line_label.modulate = Color(0.88, 0.92, 0.96)
	text_box.add_child(_line_label)


func _refresh_avatar(advisor_name: String) -> void:
	if _avatar_label == null:
		return
	var character_id := _advisor_character_id(advisor_name)
	var texture := ArtAssetRegistry.texture_for_character(character_id)
	if texture != null:
		_avatar_texture.texture = texture
		_avatar_texture.visible = true
		_avatar_label.text = ""
	else:
		_avatar_texture.visible = false
		_avatar_label.text = ArtAssetRegistry.placeholder_for_character(character_id)
	_avatar_label.add_theme_stylebox_override("normal", ClassicalTheme.avatar_style(character_id, 1.0))


func _advisor_character_id(advisor_name: String) -> String:
	if advisor_name.find("财政") >= 0:
		return "fiscal_minister"
	if advisor_name.find("央") >= 0 or advisor_name.find("银行") >= 0 or advisor_name.find("货币") >= 0:
		return "central_bank_governor"
	if advisor_name.find("产业") >= 0 or advisor_name.find("工业") >= 0:
		return "industry_minister"
	if advisor_name.find("民生") >= 0 or advisor_name.find("居民") >= 0:
		return "livelihood_minister"
	if advisor_name.find("首席") >= 0 and advisor_name.find("大臣") >= 0:
		return "chief_minister"
	return "economic_advisor"


func _make_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.13, 0.17, 0.98)
	style.border_color = Color(0.30, 0.48, 0.62, 0.88)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style
