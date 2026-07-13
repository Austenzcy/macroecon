extends Control

@onready var _policy_card: Button = $PolicyCard
@onready var _map_color: ColorRect = $MapPanel/MapColor
@onready var _map_label: Label = $MapPanel/MapLabel
@onready var _y_label: Label = $IndicatorPanel/IndicatorBox/YLabel
@onready var _u_label: Label = $IndicatorPanel/IndicatorBox/ULabel
@onready var _pi_label: Label = $IndicatorPanel/IndicatorBox/PiLabel
@onready var _debt_label: Label = $IndicatorPanel/IndicatorBox/DebtLabel

var _round := 0
var _output_y: float = 100.0
var _unemployment_u: float = 6.0
var _inflation_pi: float = 2.5
var _debt_ratio: float = 60.0


func _ready() -> void:
	_policy_card.pressed.connect(_on_policy_card_pressed)
	_update_indicators()


func _on_policy_card_pressed() -> void:
	_round += 1
	AudioManager.play_sfx(&"card_play")
	_play_card_tween()
	_apply_test_policy()
	_update_indicators()
	_update_map_feedback()


func _play_card_tween() -> void:
	_policy_card.pivot_offset = _policy_card.size * 0.5
	var tween := create_tween()
	tween.tween_property(_policy_card, "scale", Vector2(1.08, 1.08), 0.12)
	tween.tween_property(_policy_card, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


func _apply_test_policy() -> void:
	_output_y += 3.2
	_unemployment_u = maxf(_unemployment_u - 0.4, 0.0)
	_inflation_pi += 0.2
	_debt_ratio += 1.5


func _update_indicators() -> void:
	_y_label.text = "Y: %.1f" % _output_y
	_u_label.text = "u: %.1f%%" % _unemployment_u
	_pi_label.text = "π: %.1f%%" % _inflation_pi
	_debt_label.text = "Debt: %.1f%%" % _debt_ratio


func _update_map_feedback() -> void:
	var pulse: float = minf(float(_round) * 0.08, 0.35)
	_map_color.color = Color(0.12 + pulse, 0.19 + pulse * 0.5, 0.22, 1.0)
	_map_label.text = "抽象国家地图区域\n\n财政扩张测试回合：%d\n产出上升，债务压力上升" % _round
