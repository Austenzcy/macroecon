extends RefCounted

const COVER_PATHS := [
	"res://assets/art/level_select/covers/01-consumer-confidence.png",
	"res://assets/art/level_select/covers/02-investment-confidence.png",
	"res://assets/art/level_select/covers/03-money-market.png",
	"res://assets/art/level_select/covers/04-overheating.png",
	"res://assets/art/level_select/covers/05-crowding-out.png",
	"res://assets/art/level_select/covers/06-dual-shock.png",
	"res://assets/art/level_select/covers/07-stabilization.png"
]

const DESCRIPTIONS := [
	"居民消费信心下降，消费收缩推动 IS 曲线左移。",
	"企业投资意愿下降，总需求与短期产出同步承压。",
	"流动性偏好上升，利率压力使 LM 曲线左移。",
	"需求扩张过快，在增长与稳定之间寻找制动时机。",
	"政府支出托底需求，也可能经由利率压低私人投资。",
	"投资下降叠加货币需求上升，IS 与 LM 同时承压。",
	"跨越两轮政策反馈，在产出、利率与债务间维持平衡。"
]

static func all() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var visible_levels: Array[Dictionary] = GameState.get_visible_levels()
	for source: Dictionary in visible_levels:
		var level_number := int(source.get("level_number", result.size() + 1))
		var asset_index := clampi(level_number - 1, 0, COVER_PATHS.size() - 1)
		result.append({
			"id": str(source.get("group_id", source.get("scenario_id", ""))),
			"scenario_id": str(source.get("scenario_id", "")),
			"order": level_number,
			"title": str(source.get("title", "IS-LM 关卡")),
			"description": DESCRIPTIONS[asset_index],
			"cover": COVER_PATHS[asset_index],
			"unlocked": GameState.is_visible_level_unlocked(level_number),
			"completed": level_number < GameState.get_unlocked_visible_level()
		})
	return result
