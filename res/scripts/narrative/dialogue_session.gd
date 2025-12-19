extends Node
class_name DialogueSession

signal line_shown(speaker: StringName, text: String)
signal choices_shown(choices: Array)
signal dialogue_ended(id: StringName)
signal speech_check_resolved(choice_id: StringName, result: Dictionary)

@export var condition_evaluator: DialogueConditionEvaluator
@export var speech_evaluator: Node    # SpeechCheckEvaluator or compatible
@export var debug_snapshot: Node      # DialogueDebugSnapshot (optional)

var graph: DialogueGraph
var current_node_id: StringName
var dialogue_id: StringName
var context: Dictionary = {}
var last_check_result: Dictionary = {}

func get_current_lines() -> Dictionary:
	var node := graph.get_node(current_node_id) if graph else null
	if node == null:
		return {}
	return {"type": node.type, "speaker": node.speaker, "text": node.text, "choices": node.choices}

func is_finished() -> bool:
	var node := graph.get_node(current_node_id) if graph else null
	if node == null:
		return true
	return node.type == DialogueGraph.NODE_END

func start(graph_res: DialogueGraph, entry_id: StringName = &"start", ctx: Dictionary = {}) -> void:
	graph = graph_res
	dialogue_id = graph.id
	current_node_id = entry_id
	# store context and push to evaluator if available
	self.context = ctx.duplicate()
	if condition_evaluator and condition_evaluator.has_method("set_context"):
		condition_evaluator.set_context(self.context)
	_advance()

func _advance() -> void:
	if not graph:
		return
	var node := graph.get_node(current_node_id)
	if node == null:
		emit_signal("dialogue_ended", dialogue_id)
		return

	match node.type:
		DialogueGraph.NODE_LINE:
			emit_signal("line_shown", node.speaker, node.text)
			if node.next != StringName():
				current_node_id = node.next
				call_deferred("_advance")
			else:
				emit_signal("dialogue_ended", dialogue_id)
		DialogueGraph.NODE_CHOICE:
			var available := condition_evaluator.filter_choices(node.choices)
			emit_signal("choices_shown", available)
		DialogueGraph.NODE_END:
			emit_signal("dialogue_ended", dialogue_id)

func choose(choice_id: StringName) -> void:
	var node := graph.get_node(current_node_id)
	if node == null or node.type != DialogueGraph.NODE_CHOICE:
		return
	for c in node.choices:
		if c.id == choice_id:
			# Run speech checks if present
			var check_result: Dictionary = {}
			if c.checks and c.checks.size() > 0 and speech_evaluator:
				# We only handle the first check for now
				var check_spec: Dictionary = c.checks[0]
				if speech_evaluator.has_method("set_context"):
					speech_evaluator.set_context(context)
				var raw: Dictionary = speech_evaluator.roll_speech_check(check_spec)
				# Normalize to a common shape
				check_result = {
					"passed": bool(raw.get("success", raw.get("success", raw.get("passed", false)))),
					"roll": int(raw.get("roll", 0)),
					"target": int(raw.get("difficulty", 0)),
					"stat_value": float(raw.get("base", 0.0)),
					"raw": raw
				}
				last_check_result = check_result
				emit_signal("speech_check_resolved", c.id, check_result)
				# Build snapshot extras
				var extras: Dictionary = {
					"speech_check_result": check_result,
					"chosen_choice": c.id,
					"evaluated_traits": false,
					"evaluated_factions": false,
					"evaluated_vitality": false
				}
				# Inspect conditions to set evaluated flags
				for cond in c.conditions:
					var t: String = str(cond.get("type", "")).to_lower()
					if t.find("trait") != -1:
						extras["evaluated_traits"] = true
					if t.find("faction") != -1 or t.find("respect") != -1:
						extras["evaluated_factions"] = true
					if t.find("vitality") != -1 or t.find("stat") != -1:
						extras["evaluated_vitality"] = true
				# Decide routing based on check success
				var success: bool = check_result.get("passed", false)
				var next_id: StringName = c.next
				var effects: Array = c.effects
				if success:
					if c.on_success_next != StringName():
						next_id = c.on_success_next
					if c.effects_success and c.effects_success.size() > 0:
						effects = c.effects_success
				else:
					if c.on_fail_next != StringName():
						next_id = c.on_fail_next
					if c.effects_fail and c.effects_fail.size() > 0:
						effects = c.effects_fail
				condition_evaluator.apply_effects(effects)
				current_node_id = next_id
				# Capture snapshot if available
				if debug_snapshot and debug_snapshot.has_method("capture"):
					debug_snapshot.capture(self, condition_evaluator, extras)
				_advance()
				return
			# No check: apply standard effects and continue
			condition_evaluator.apply_effects(c.effects)
			current_node_id = c.next
			if debug_snapshot and debug_snapshot.has_method("capture"):
				debug_snapshot.capture(self, condition_evaluator, {"chosen_choice": c.id})
			_advance()
			return
