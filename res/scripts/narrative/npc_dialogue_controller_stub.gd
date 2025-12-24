extends Node
class_name NPCDialogueControllerStub

var personality: Resource
var dialogue_loader: Node

func start_best_dialogue(context: Dictionary) -> void:
	# minimal stub: load first graph matching personality or return
	if not dialogue_loader:
		return
	var id := null
	if personality and personality.has("preferred_dialogues"):
		var pd := personality.get("preferred_dialogues")
		if pd and pd.size() > 0:
			id = pd[0]
	# fallback: get by tags
	if id == null and personality and personality.has("encounter_tags"):
		var tags := personality.get("encounter_tags")
		var cands := dialogue_loader.get_dialogues_for_tags(tags, context.get("region_tags", []), personality.get("base_faction", ""))
		if cands.size() > 0:
			id = cands[0]
	if id != null:
		var graph := dialogue_loader.get_graph(id)
		if graph and get_parent() and get_tree():
			var session := DialogueSession.new()
			session.condition_evaluator = preload("res://res/scripts/narrative/dialogue_condition_evaluator.gd").new()
			session.start(graph)
