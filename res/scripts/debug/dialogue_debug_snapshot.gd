extends Node
class_name DialogueDebugSnapshot

var last_snapshot := {}

func capture(session: DialogueSession, evaluator: DialogueConditionEvaluator, extra: Dictionary = {}) -> void:
	var node_id := session.current_node_id
	var graph := session.graph
	var node := graph.get_node(node_id) if graph else null

	var snapshot := {
		"dialogue_id": graph.id if graph else "",
		"node_id": node_id,
		"node_type": node.type if node else "",
		"speaker": node.speaker if node else "",
		"text": node.text if node else "",
		"timestamp": Time.get_datetime_string_from_unix_time(Time.get_unix_time_from_system()),
		"player_traits": evaluator.trait_registry.get_active_trait_ids() if evaluator.trait_registry and evaluator.trait_registry.has_method("get_active_trait_ids") else [],
		"region_tags": evaluator.game_state.current_region_tags if evaluator.game_state and evaluator.game_state.has_method("current_region_tags") else [],
		"faction_standings": evaluator.faction_system.dump_standings() if evaluator.faction_system and evaluator.faction_system.has_method("dump_standings") else {},
		"extra": extra
	}

	last_snapshot = snapshot
	_print_snapshot(snapshot)

func _print_snapshot(s: Dictionary) -> void:
	print("--- CellDialogueDebugSnapshot ---")
	print("Dialogue:", s["dialogue_id"], "Node:", s["node_id"], "Type:", s["node_type"])
	print("Speaker:", s["speaker"])
	print("Text:", s["text"])
	print("RegionTags:", s["region_tags"])
	print("PlayerTraits:", s["player_traits"])
	print("FactionStandings:", s["faction_standings"])
	print("Extra:", s["extra"])
	print("--- EndSnapshot ---")
