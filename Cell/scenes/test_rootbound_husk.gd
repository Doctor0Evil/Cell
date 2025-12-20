extends Node

const CellCreatureSpec := preload("res://cell/creatures/cell_creature_spec.gd")

@export var creature_spec: CellCreatureSpec

func _ready() -> void:
	if creature_spec == null:
		push_error("No creature_spec assigned.")
		return

	print("=== CELL Creature Sanity ===")
	print("ID:", creature_spec.core.get("creature_id", ""))
	print("Name:", creature_spec.core.get("name", ""))
	print("Threat:", creature_spec.core.get("threat_level", 0))
	print("Classification:", creature_spec.core.get("classification", ""))
	print("Damage types:", creature_spec.gameplay.get("damage_type", []))
	print("Compliance license:", creature_spec.compliance.get("license_anchor", ""))

	# JSON preview (round-trip check)
	var dict := creature_spec.to_dict()
	var json := JSON.stringify(dict, "\t")
	print("Creature JSON preview:\n", json)