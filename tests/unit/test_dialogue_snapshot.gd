# Test that debug snapshot captures speech check results

func run_test() -> void:
	# Reuse the speech graph from previous test
	var graph_dict := {
		"id": "test_snapshot",
		"title": "Snapshot Test",
		"nodes": [
			{"id": "start", "type": "line", "speaker": "npc", "text": "Hi.", "next": "player_root"},
			{"id": "player_root", "type": "choice", "choices": [
				{ "id": "intimidate", "text": "[Hard Edge] Say it.", "checks": [ { "type": "stat", "stat": "vitality", "difficulty": 5 } ], "on_success_next": "succeed", "on_fail_next": "fail" }
			]},
			{"id":"succeed","type":"line","speaker":"npc","text":"Back down","next":"end"},
			{"id":"fail","type":"line","speaker":"npc","text":"Call backup","next":"end"},
			{"id":"end","type":"end"}
		]
	}

	var g := preload("res://res/scripts/narrative/dialogue_graph.gd").from_dict(graph_dict)
	# Fake player with vitality stat
	var player := Node.new()
	player.get_attribute = func(name):
		if str(name).to_lower() == "vitality": return 10
		return 0

	var evaluator := preload("res://res/scripts/narrative/dialogue_condition_evaluator.gd").new()
	var speech := preload("res://res/scripts/narrative/speech_check_evaluator.gd").new()
	speech.set_context({"player": player})

	var snapshot := preload("res://res/scripts/debug/dialogue_debug_snapshot.gd").new()

	var session := preload("res://res/scripts/narrative/dialogue_session.gd").new()
	session.condition_evaluator = evaluator
	session.speech_evaluator = speech
	session.debug_snapshot = snapshot

	session.start(g, "start", {"player": player})
	call_deferred(func(): session.choose(StringName("intimidate")))

	# Check snapshot
	var s := snapshot.last_snapshot
	if s.empty():
		printerr("[test_dialogue_snapshot] FAILED: snapshot empty")
	else:
		assert(s.has("extra"))
		var extra := s["extra"]
		assert(extra.has("speech_check_result"))
		print("[test_dialogue_snapshot] OK: snapshot contains speech_check_result", extra["speech_check_result"])
