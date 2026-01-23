extends RefCounted
class_name _ArrayTools


func deduplicate(array):
	var seen := {}
	var dedup := []

	for t in array:
		if not seen.has(t):
			seen[t] = true
			dedup.append(t)

	return dedup
