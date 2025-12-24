extends Node
const CellCreatureSpec := preload("res://cell/creatures/cell_creature_spec.gd")

var CREATURES_DIR := "res://assets/creatures"
var SPEC_NAME := "creature.json"

func load_creature_spec(creature_id: String) -> CellCreatureSpec:
	var path := "%s/%s/%s" % [CREATURES_DIR, creature_id, SPEC_NAME]
	if not FileAccess.file_exists(path):
		push_error("Creature spec not found: %s" % path)
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open spec: %s" % path)
		return null

	var text := file.get_as_text()
	file.close()

	var result := JSON.parse_string(text)
	# Accept either an already-dictionary result or a JSONParse result
	if typeof(result) == TYPE_DICTIONARY:
		var data := result
	else:
		# Some Godot versions return a JSONParseResult-like object
		if typeof(result) == TYPE_OBJECT and result.has("result"):
			data = result.result
		else:
			push_error("Invalid JSON for creature: %s" % path)
			return null

	if typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid JSON for creature: %s" % path)
		return null

	return CellCreatureSpec.from_dict(data)
