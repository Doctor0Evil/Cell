# Test speech check flow through DialogueSession

func run_test() -> void:
	# Build a simple graph with a speech check
	var graph_dict := {
		"id": "test_speech",
		"title": "Speech Test",
		"nodes": [
			{"id": "start", "type": "line", "speaker": "npc", "text": "Hello.", "next": "player_root"},
			{"id": "player_root", "type": "choice", "choices": [
				{ "id": "calm_negotiation", "text": "[Containment Face] \"We both want this deck breathing tomorrow.\"", 
				  "checks": [ { "type": "speech_skill", "subtype": "NEGOTIATION", "attribute": "Influence", "difficulty": 12 } ],
				  "on_success_next": "npc_soften", "on_fail_next": "npc_suspicious",
				  "effects_success": [{"type":"respect_delta","faction":"ADMINCORE","value":5}],
				  "effects_fail": [{"type":"respect_delta","faction":"ADMINCORE","value":-3}]
				}
			]},
			{"id":"npc_soften","type":"line","speaker":"npc","text":"Fine.","next":"end"},
			{"id":"npc_suspicious","type":"line","speaker":"npc","text":"I do not trust you.","next":"end"},
			{"id":"end","type":"end"}
		]
	}

	var g := preload("res://res/scripts/narrative/dialogue_graph.gd").from_dict(graph_dict)

	# Fake player with Influence 15 to pass
	var player := Node.new()
	player.get_attribute = func(name):
		if str(name).to_lower() == "influence": return 15
		return 0

	# Setup evaluators and session
	var evaluator := preload("res://res/scripts/narrative/dialogue_condition_evaluator.gd").new()
	var speech := preload("res://res/scripts/narrative/speech_check_evaluator.gd").new()
	speech.set_context({"player": player})

	var session := preload("res://res/scripts/narrative/dialogue_session.gd").new()
	session.condition_evaluator = evaluator
	session.speech_evaluator = speech

	# Connect signal spies
	var saw_check := false
	var last := {}
	session.connect("speech_check_resolved", Callable(self, "_on_check_resolved"))

	func _on_check_resolved(choice_id, result):
		saw_check = true
		last = result

	# Start and choose
	session.start(g, "start", {"player": player})
	# Advance from line to choices is deferred, so force a small delay via call_deferred pattern
	call_deferred(func(): session.choose(StringName("calm_negotiation")))

	# Run a soft wait loop - in test environment this runs immediate
	# Validate
	if not saw_check:
		printerr("[test_dialogue_speech_checks] FAILED: check not seen")
	else:
		print("[test_dialogue_speech_checks] OK: check fired, passed=", last.get("passed"))
		assert(last.get("passed", false) == true)
		assert(session.get_current_lines().type == "line")
		assert(g.get_node(session.current_node_id).id == StringName("npc_soften"))
