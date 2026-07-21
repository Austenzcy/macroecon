extends RefCounted

static var _texture_cache: Dictionary = {}

const CHARACTER_BADGES := {
	"chief_minister": "res://assets/art/characters/badges/badge_chief_minister.png",
	"economic_advisor": "res://assets/art/characters/badges/badge_economic_advisor.png",
	"fiscal_minister": "res://assets/art/characters/badges/badge_fiscal_minister.png",
	"central_bank_governor": "res://assets/art/characters/badges/badge_central_bank_governor.png",
	"industry_minister": "res://assets/art/characters/badges/badge_industry_minister.png",
	"livelihood_minister": "res://assets/art/characters/badges/badge_livelihood_minister.png"
}

const CHARACTER_PORTRAITS := {
	"chief_minister": "res://assets/art/characters/portraits/portrait_chief_minister.png",
	"economic_advisor": "res://assets/art/characters/portraits/portrait_economic_advisor.png",
	"fiscal_minister": "res://assets/art/characters/portraits/portrait_fiscal_minister.png",
	"central_bank_governor": "res://assets/art/characters/portraits/portrait_central_bank_governor.png",
	"industry_minister": "res://assets/art/characters/portraits/portrait_industry_minister.png",
	"livelihood_minister": "res://assets/art/characters/portraits/portrait_livelihood_minister.png"
}

const AVATAR_TO_CHARACTER := {
	"placeholder_chief_minister": "chief_minister",
	"placeholder_advisor": "economic_advisor",
	"placeholder_economic_advisor": "economic_advisor",
	"placeholder_fiscal": "fiscal_minister",
	"placeholder_fiscal_minister": "fiscal_minister",
	"placeholder_finance_minister": "fiscal_minister",
	"placeholder_central_bank": "central_bank_governor",
	"placeholder_central_bank_governor": "central_bank_governor",
	"placeholder_industry": "industry_minister",
	"placeholder_industry_minister": "industry_minister",
	"placeholder_livelihood": "livelihood_minister",
	"placeholder_livelihood_minister": "livelihood_minister",
	"placeholder_civil_affairs_minister": "livelihood_minister"
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
	"financial_stability": "res://assets/art/icons/policies/icon_policy_financial_stability.png"
}

const POLICY_CARD_ART := {
	"increase_government_purchase": "res://assets/art/policy_cards/policy_card_government_purchase.png",
	"tax_cut": "res://assets/art/policy_cards/policy_card_tax_cut.png",
	"expansionary_monetary_policy": "res://assets/art/policy_cards/policy_card_monetary_expand.png",
	"contractionary_fiscal_policy": "res://assets/art/policy_cards/policy_card_fiscal_contract.png",
	"contractionary_monetary_policy": "res://assets/art/policy_cards/policy_card_monetary_contract.png",
	"keep_policy_unchanged": "res://assets/art/policy_cards/policy_card_keep_unchanged.png"
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

const MAP_REGION_SCENES := {
	"consumption": "res://assets/art/map_regions/region_scene_consumption.png",
	"industry": "res://assets/art/map_regions/region_scene_industry.png",
	"finance": "res://assets/art/map_regions/region_scene_finance.png",
	"government": "res://assets/art/map_regions/region_scene_government.png"
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

static func texture_for_character(speaker_id: String, avatar_id: String = "", speaker_name: String = "") -> Texture2D:
	var character_key := normalize_character_key(speaker_id, avatar_id, speaker_name)
	var portrait := _load_texture(str(CHARACTER_PORTRAITS.get(character_key, "")))
	if portrait != null:
		return portrait
	return _load_texture(str(CHARACTER_BADGES.get(character_key, "")))


static func texture_for_dialogue_portrait(speaker_id: String, avatar_id: String = "", speaker_name: String = "") -> Texture2D:
	var character_key := normalize_character_key(speaker_id, avatar_id, speaker_name)
	var portrait := _load_texture(str(CHARACTER_PORTRAITS.get(character_key, "")))
	if portrait != null:
		return portrait
	var generic_portrait := _load_texture(str(CHARACTER_PORTRAITS.get("economic_advisor", "")))
	if generic_portrait != null:
		return generic_portrait
	return _load_texture(str(CHARACTER_BADGES.get(character_key, "")))


static func placeholder_for_character(speaker_id: String, avatar_id: String = "", speaker_name: String = "") -> String:
	var character_key := normalize_character_key(speaker_id, avatar_id, speaker_name)
	return str(CHARACTER_FALLBACK.get(character_key, "顾"))


static func normalize_character_key(speaker_id: String, avatar_id: String = "", speaker_name: String = "") -> String:
	if CHARACTER_BADGES.has(speaker_id):
		return speaker_id
	if AVATAR_TO_CHARACTER.has(avatar_id):
		return str(AVATAR_TO_CHARACTER[avatar_id])
	var source := "%s %s %s" % [speaker_id, avatar_id, speaker_name]
	var lowered := source.to_lower()
	if source.find("财政") >= 0 or source.find("财务") >= 0 or lowered.find("fiscal") >= 0 or lowered.find("finance_minister") >= 0:
		return "fiscal_minister"
	if source.find("中央银行") >= 0 or source.find("央行") >= 0 or lowered.find("central") >= 0 or lowered.find("bank") >= 0:
		return "central_bank_governor"
	if source.find("产业") >= 0 or source.find("工业") >= 0 or source.find("企业") >= 0 or lowered.find("industry") >= 0:
		return "industry_minister"
	if source.find("民生") >= 0 or source.find("居民") >= 0 or source.find("市场") >= 0 or lowered.find("livelihood") >= 0 or lowered.find("civil") >= 0:
		return "livelihood_minister"
	if source.find("经济顾问") >= 0 or source.find("顾问") >= 0 or lowered.find("advisor") >= 0:
		return "economic_advisor"
	if source.find("首席大臣") >= 0 or source == "大臣" or lowered.find("chief") >= 0:
		return "chief_minister"
	return ""


static func texture_for_policy_type(policy_type: String, policy_id: String = "") -> Texture2D:
	var key := normalize_policy_key(policy_type, policy_id)
	return _load_texture(str(POLICY_TYPE_ICONS.get(key, "")))


static func texture_for_policy_card(policy_id: String, policy_type: String = "", policy_name: String = "") -> Texture2D:
	var direct := _load_texture(str(POLICY_CARD_ART.get(policy_id, "")))
	if direct != null:
		return direct
	var source := "%s %s %s" % [policy_id, policy_type, policy_name]
	var lowered := source.to_lower()
	if lowered.find("government") >= 0 or source.find("政府") >= 0 or source.find("购买") >= 0:
		return _load_texture(str(POLICY_CARD_ART.get("increase_government_purchase", "")))
	if lowered.find("tax") >= 0 or source.find("税") >= 0:
		return _load_texture(str(POLICY_CARD_ART.get("tax_cut", "")))
	if (lowered.find("monetary") >= 0 or source.find("货币") >= 0) and (lowered.find("contract") >= 0 or source.find("紧缩") >= 0 or source.find("收缩") >= 0):
		return _load_texture(str(POLICY_CARD_ART.get("contractionary_monetary_policy", "")))
	if lowered.find("monetary") >= 0 or source.find("货币") >= 0:
		return _load_texture(str(POLICY_CARD_ART.get("expansionary_monetary_policy", "")))
	if lowered.find("contract") >= 0 or source.find("紧缩") >= 0 or source.find("收缩") >= 0:
		return _load_texture(str(POLICY_CARD_ART.get("contractionary_fiscal_policy", "")))
	if lowered.find("keep") >= 0 or source.find("不变") >= 0 or source.find("观望") >= 0:
		return _load_texture(str(POLICY_CARD_ART.get("keep_policy_unchanged", "")))
	return null


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
	if (source.find("紧缩") >= 0 or lowered.find("contraction") >= 0 or lowered.find("contract") >= 0) and (source.find("货币") >= 0 or lowered.find("monetary") >= 0):
		return "monetary_contract"
	if (source.find("扩张") >= 0 or lowered.find("expansion") >= 0 or lowered.find("expand") >= 0) and (source.find("货币") >= 0 or lowered.find("monetary") >= 0):
		return "monetary_expand"
	if (source.find("紧缩") >= 0 or lowered.find("contraction") >= 0 or lowered.find("contract") >= 0) and (source.find("财政") >= 0 or lowered.find("fiscal") >= 0):
		return "fiscal_contract"
	if source.find("财政") >= 0 or source.find("政府") >= 0 or lowered.find("fiscal") >= 0 or lowered.find("government_purchase") >= 0 or lowered.find("purchase") >= 0:
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


static func texture_for_map_region_scene(region_key: String) -> Texture2D:
	return _load_texture(str(MAP_REGION_SCENES.get(region_key, "")))


static func placeholder_for_map_region(region_key: String) -> String:
	return str(MAP_REGION_FALLBACK.get(region_key, "区"))


static func texture_for_slot(slot_key: String) -> Texture2D:
	return _load_texture(str(TEXTURE_SLOTS.get(slot_key, "")))


static func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return _load_png_as_image_texture(path)
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D
	var resource: Resource = load(path)
	if resource is Texture2D:
		_texture_cache[path] = resource
		return resource as Texture2D
	var image_texture := _load_png_as_image_texture(path)
	if image_texture != null:
		_texture_cache[path] = image_texture
		return image_texture
	return null


static func _load_png_as_image_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D
	if path.is_empty() or not path.ends_with(".png") or not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	_texture_cache[path] = texture
	return texture
