extends Node

const LevelSelectDataScript = preload("res://scripts/ui/level_select/LevelSelectData.gd")
const LEVEL_SELECT_SCENE := "res://scenes/LevelSelect.tscn"
const HUD_REFERENCE_SCENE := "res://scenes/ui/hud_reference/HudReferencePrototype.tscn"

var _failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	GameState.reset_for_new_game()
	var initial_levels: Array[Dictionary] = LevelSelectDataScript.all()
	_expect(initial_levels.size() == 7, "正式关卡选择应展示 7 个关卡")
	_expect(bool(initial_levels[0].get("unlocked", false)), "新游戏首关应解锁")
	for index in range(1, initial_levels.size()):
		_expect(not bool(initial_levels[index].get("unlocked", true)), "新游戏第 %d 关应锁定" % [index + 1])

	# Exercise the same GameState calls used by the Start button and FinalSummary.
	for level_number in range(1, initial_levels.size() + 1):
		var visible_level := GameState.get_visible_level(level_number)
		var expected_scenario := str(visible_level.get("scenario_id", ""))
		_expect(GameState.is_visible_level_unlocked(level_number), "第 %d 关应按顺序解锁" % level_number)
		_expect(not expected_scenario.is_empty(), "第 %d 关应映射到正式场景" % level_number)
		_expect(GameState.start_visible_level(level_number), "第 %d 关应可成功启动" % level_number)
		_expect(GameState.current_scenario_id == expected_scenario, "第 %d 关应启动正确场景" % level_number)
		_expect(GameState.get_current_visible_level_number() == level_number, "当前关卡编号应同步")
		GameState.mark_current_visible_level_completed()
		GameState.clear_current_run()
		if level_number < initial_levels.size():
			_expect(GameState.is_visible_level_unlocked(level_number + 1), "通关后应解锁第 %d 关" % [level_number + 1])

	_expect(GameState.get_unlocked_visible_level() == 7, "末关完成后解锁上限应保持第 7 关")
	_expect(ResourceLoader.exists(HUD_REFERENCE_SCENE), "HUD 参考样板场景应继续存在")

	GameState.reset_for_new_game()
	var packed := load(LEVEL_SELECT_SCENE) as PackedScene
	_expect(packed != null, "新的 LevelSelect 场景应可加载")
	if packed != null:
		var scene := packed.instantiate()
		get_tree().root.add_child(scene)
		await get_tree().process_frame
		await get_tree().process_frame
		_expect(scene.get_node_or_null("StartLevelButton") != null, "正式界面应包含进入关卡按钮")
		_expect(scene.get_node_or_null("HudReferenceButton") != null, "右上角应包含 HUD 样板入口")
		_expect(scene.get_node_or_null("LevelCard01") != null, "应创建首关卡片")
		_expect(scene.get_node_or_null("LevelCard07") != null, "应创建末关卡片")
		var first_card := scene.get_node_or_null("LevelCard01")
		var second_card := scene.get_node_or_null("LevelCard02")
		if first_card != null and second_card != null:
			_expect(not bool(first_card.call("is_locked")), "首关卡片不应显示锁定状态")
			_expect(bool(second_card.call("is_locked")), "第二关卡片应显示锁定状态")
		scene.queue_free()
		await get_tree().process_frame

	if _failures.is_empty():
		print("FORMAL_LEVEL_SELECT_INTEGRATION_OK")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			printerr("INTEGRATION FAILURE: ", failure)
		get_tree().quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
