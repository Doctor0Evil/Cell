extends Node
class_name LorewayBridge

@export_dir var dialogue_dir := "res/narrative/loreway/dialogue"
var _cache: Dictionary = {}

func _ready() -> void:
	_load_all_dialogues()

func _load_all_dialogues() -> void:
	_cache.clear()
	var dir := DirAccess.open(dialogue_dir)
	if dir == null:
		push_warning("LorewayBridge: cannot open dir %s" % dialogue_dir)
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if not dir.current_is_dir() and f.ends_with(".json"):
			var path := dialogue_dir.path_join(f)
			var text := FileAccess.get_file_as_string(path)
			if text == "":
				f = dir.get_next()
				continue
			var parsed := JSON.parse_string(text)
			var data := null
			if typeof(parsed) == TYPE_DICTIONARY and parsed.has("result"):
				data = parsed["result"]
			elif typeof(parsed) == TYPE_DICTIONARY:
				data = parsed
			if data != null:
				var graph := DialogueGraph.from_dict(data)
				_cache[graph.id] = graph
		f = dir.get_next()
	dir.list_dir_end()

func get_graph(id: StringName) -> DialogueGraph:
	return _cache.get(id, null)

func get_dialogues_for_tags(tags: Array[StringName], region_tags: Array[StringName], faction: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	for g_id in _cache.keys():
		var g: DialogueGraph = _cache[g_id]
		var meta := g.meta
		var g_tags: Array = meta.get("narrative_tags", [])
		var g_regions: Array = meta.get("region_tags", [])
		var g_factions: Array = meta.get("factions", [])
		if not g_factions.is_empty() and faction not in g_factions:
			continue
		var match_score := 0
		for t in tags:
			if t in g_tags:
				match_score += 1
		for rt in region_tags:
			if rt in g_regions:
				match_score += 1
		if match_score > 0:
			result.append(g.id)
	return result
