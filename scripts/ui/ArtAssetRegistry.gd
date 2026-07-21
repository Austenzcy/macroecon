extends RefCounted

const CHARACTER_BADGES := {
	"chief_minister": "res://assets/art/characters/badges/badge_chief_minister.png",
	"economic_advisor": "res://assets/art/characters/badges/badge_economic_advisor.png",
	"fiscal_minister": "res://assets/art/characters/badges/badge_fiscal_minister.png",
	"central_bank_governor": "res://assets/art/characters/badges/badge_central_bank_governor.png",
	"industry_minister": "res://assets/art/characters/badges/badge_industry_minister.png",
	"livelihood_minister": "res://assets/art/characters/badges/badge_livelihood_minister.png"
}

const AVATAR_TO_CHARACTER := {
	"placeholder_chief_minister": "chief_minister",
	"placeholder_advisor": "economic_advisor",
	"placeholder_fiscal": "fiscal_minister",
	"placeholder_central_bank": "central_bank_governor",
	"placeholder_industry": "industry_minister",
	"placeholder_livelihood": "livelihood_minister"
}

const CHARACTER_FALLBACK := {
	"chief_minister": "首",
	"economic_advisor": "学",
	"fiscal_minister": "财",
	"central_bank_governor": "央",
	"industry_minister": "工",
	"livelihood_minister": "民"
}

const POLICY_TYPE_ICONS := {
	"fiscal_expand": "res://assets/art/icons/policies/icon_policy_fiscal_expand.png",
	"fiscal_contract": "res://assets/art/icons/policies/icon_policy_fiscal_contract.png",
	"monetary_expand": "res://assets/art/icons/policies/icon_policy_monetary_expand.png",
	"monetary_contract": "res://assets/art/icons/policies/icon_policy_monetary_contract.png",
	"tax": "res://assets/art/icons/policies/icon_policy_tax.png",
	"investment": "res://assets/art/icons/policies/icon_policy_investment.png",
	"consumption": "res://assets/art/icons/policies/icon_policy_consumption.png",
	"financial_stability": "res://assets/art/icons/policies/icon_policy_financial_stability.png",
	"generic": "res://assets/art/icons/policies/icon_policy_generic.png"
}

const POLICY_FALLBACK := {
	"fiscal_expand": "财",
	"fiscal_contract": "缩",
	"monetary_expand": "币",
	"monetary_contract": "紧",
	"tax": "税",
	"investment": "投",
	"consumption": "民",
	"financial_stability": "金",
	"generic": "策"
}

const UI_ICONS := {
	"wisdom_points": "res://assets/art/icons/ui/icon_wisdom_points.png",
	"lock_level": "res://assets/art/icons/ui/icon_lock_level.png",
	"level_complete": "res://assets/art/stamps/stamp_level_complete.png"
}

const UI_FALLBACK := {
	"wisdom_points": "智",
	"lock_level": "锁",
	"level_complete": "章"
}

const MAP_REGION_ICONS := {
	"consumption": "res://assets/art/icons/map/icon_region_consumption.png",
	"industry": "res://assets/art/icons/map/icon_region_industry.png",
	"finance": "res://assets/art/icons/map/icon_region_finance.png",
	"government": "res://assets/art/icons/map/icon_region_government.png"
}

const MAP_REGION_FALLBACK := {
	"consumption": "民",
	"industry": "工",
	"finance": "金",
	"government": "政"
}

const TEXTURE_SLOTS := {
	"paper": "res://assets/art/textures/texture_paper_light.png",
	"wood": "res://assets/art/textures/texture_dark_wood.png",
	"dossier_corner": "res://assets/art/textures/decor_dossier_corner.png",
	"policy_stamp": "res://assets/art/stamps/stamp_policy_confirmed.png"
}

static func texture_for_character(speaker_id: String, avatar_id: String = "") -> Texture2D:
	var character_key := normalize_character_key(speaker_id, avatar_id)
	return _load_texture(str(CHARACTER_BADGES.get(character_key, "")))


static func placeholder_for_character(speaker_id: String, avatar_id: String = "") -> String:
	var character_key := normalize_character_key(speaker_id, avatar_id)
	return str(CHARACTER_FALLBACK.get(character_key, "顾"))


static func normalize_character_key(speaker_id: String, avatar_id: String = "") -> String:
	if CHARACTER_BADGES.has(speaker_id):
		return speaker_id
	if AVATAR_TO_CHARACTER.has(avatar_id):
		return str(AVATAR_TO_CHARACTER[avatar_id])
	var lowered := speaker_id.to_lower()
	if lowered.find("fiscal") >= 0:
		return "fiscal_minister"
	if lowered.find("central") >= 0 or lowered.find("bank") >= 0:
		return "central_bank_governor"
	if lowered.find("industry") >= 0:
		return "industry_minister"
	if lowered.find("livelihood") >= 0:
		return "livelihood_minister"
	if lowered.find("advisor") >= 0:
		return "economic_advisor"
	if lowered.find("chief") >= 0:
		return "chief_minister"
	return "economic_advisor"


static func texture_for_policy_type(policy_type: String, policy_id: String = "") -> Texture2D:
	var key := normalize_policy_key(policy_type, policy_id)
	return _load_texture(str(POLICY_TYPE_ICONS.get(key, POLICY_TYPE_ICONS["generic"])))


static func placeholder_for_policy_type(policy_type: String, policy_id: String = "") -> String:
	var key := normalize_policy_key(policy_type, policy_id)
	return str(POLICY_FALLBACK.get(key, POLICY_FALLBACK["generic"]))


static func normalize_policy_key(policy_type: String, policy_id: String = "") -> String:
	var source := "%s %s" % [policy_type, policy_id]
	var lowered := source.to_lower()
	if source.find("税") >= 0 or lowered.find("tax") >= 0:
		return "tax"
	if source.find("投资") >= 0 or source.find("企业") >= 0 or source.find("产业") >= 0 or lowered.find("invest") >= 0:
		return "investment"
	if source.find("消费") >= 0 or source.find("居民") >= 0 or source.find("民生") >= 0 or lowered.find("consum") >= 0:
		return "consumption"
	if source.find("金融") >= 0 or source.find("利率") >= 0 or lowered.find("financial") >= 0 or lowered.find("rate") >= 0:
		return "financial_stability"
	if source.find("紧缩") >= 0 and (source.find("货币") >= 0 or lowered.find("monetary") >= 0):
		return "monetary_contract"
	if source.find("扩张") >= 0 and (source.find("货币") >= 0 or lowered.find("monetary") >= 0):
		return "monetary_expand"
	if source.find("紧缩") >= 0 and source.find("财政") >= 0:
		return "fiscal_contract"
	if source.find("财政") >= 0 or source.find("政府") >= 0:
		return "fiscal_expand"
	if source.find("货币") >= 0:
		return "monetary_expand"
	return "generic"


static func texture_for_ui(key: String) -> Texture2D:
	return _load_texture(str(UI_ICONS.get(key, "")))


static func placeholder_for_ui(key: String) -> String:
	return str(UI_FALLBACK.get(key, ""))


static func texture_for_map_region(region_key: String) -> Texture2D:
	return _load_texture(str(MAP_REGION_ICONS.get(region_key, "")))


static func placeholder_for_map_region(region_key: String) -> String:
	return str(MAP_REGION_FALLBACK.get(region_key, "区"))


static func texture_for_slot(slot_key: String) -> Texture2D:
	return _load_texture(str(TEXTURE_SLOTS.get(slot_key, "")))


static func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var resource := load(path)
	if resource is Texture2D:
		return resource
	return null
