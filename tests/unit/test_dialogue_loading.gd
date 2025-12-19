# Simple unit test to validate dialogue loading
# This script can be used by a test runner or executed manually in the editor.

func run_test() -> void:
	var bridge := preload("res://res/scripts/narrative/loreway_bridge.gd").new()
	bridge._load_all_dialogues()
	var g = bridge.get_graph("ashveil_scavenger_intro")
	if g == null:
		printerr("[test_dialogue_loading] FAILED: graph was not loaded")
	else:
		print("[test_dialogue_loading] OK: loaded graph", g.id)
