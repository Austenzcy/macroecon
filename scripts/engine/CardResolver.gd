extends RefCounted


static func normalize_selected_policies(selected_policies: Array) -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	for policy: Variant in selected_policies:
		if policy is Dictionary:
			normalized.append(policy)
	return normalized


static func policy_names(selected_policies: Array) -> Array[String]:
	var names: Array[String] = []
	for policy: Variant in selected_policies:
		if policy is Dictionary:
			names.append(str(policy.get("name", policy.get("id", "未知政策"))))
	return names
