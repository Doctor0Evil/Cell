# Unit-like smoke tests for DialogueConditionEvaluator

func run_test() -> void:
	var evaluator := preload("res://res/scripts/narrative/dialogue_condition_evaluator.gd").new()
	evaluator.trait_registry = preload("res://design/traits/cell_traits_registry.gd").new()

	# fake player
	var player := Node.new()
	player.set_meta("traits", ["containmentface"])
	player.get_active_trait_ids = func():
		return player.get_meta("traits")

	# fake faction system stub
	var faction := Node.new()
	faction.get_standing = func(f):
		if str(f) == "SCAVENGERRINGS":
			return -5
		return 0

	# context
	var ctx := {"player": player, "npc": null}
	evaluator.set_context(ctx)
	evaluator.faction_system = faction

	# has_trait
t	var c1 := {"type": "has_trait", "value": "containmentface", "subject": "player"}
	assert(evaluator.evaluate_condition(c1) == true)

	# missing_trait
	var c2 := {"type": "missing_trait", "value": "hardedge", "subject": "player"}
	assert(evaluator.evaluate_condition(c2) == true)

	# faction standing min (should fail because -5 < -3)
	var c3 := {"type": "faction_standing_min", "faction": "SCAVENGERRINGS", "standing": -3}
	assert(evaluator.evaluate_condition(c3) == false)

	print("[test_dialogue_trait_hooks] OK")
