extends Node

var _cache: Dictionary = {}


func load_json(path: String) -> Variant:
	if _cache.has(path):
		return _cache[path]
	if not FileAccess.file_exists(path):
		push_error("JSON file not found: %s" % path)
		return null

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open JSON file: %s" % path)
		return null

	var text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("Cannot parse JSON file: %s" % path)
		return null

	_cache[path] = parsed
	return parsed


func load_array(path: String) -> Array:
	var data: Variant = load_json(path)
	if data is Array:
		return data
	return []


func load_dict(path: String) -> Dictionary:
	var data: Variant = load_json(path)
	if data is Dictionary:
		return data
	return {}


func find_by_id(path: String, id_value: String) -> Dictionary:
	var items: Array = load_array(path)
	for item: Variant in items:
		if item is Dictionary and str(item.get("id", "")) == id_value:
			return item
	return {}


func get_scenario_by_id(id_value: String) -> Dictionary:
	return find_by_id("res://data/scenarios.json", id_value)
