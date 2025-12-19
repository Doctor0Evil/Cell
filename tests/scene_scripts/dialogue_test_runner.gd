extends Node

func _ready():
	var bridge := get_node("LorewayBridge") if has_node("LorewayBridge") else null
	if bridge == null:
		bridge = preload("res://res/scripts/narrative/loreway_bridge.gd").new()
		add_child(bridge)
	bridge._load_all_dialogues()
	var g := bridge.get_graph("ashveil_scavenger_intro")
	if g:
		print("[DialogueTestRunner] Graph loaded:", g.id)
		var session := DialogueSession.new()
		session.condition_evaluator = preload("res://res/scripts/narrative/dialogue_condition_evaluator.gd").new()
		session.start(g)
		# Listen for signals for quick smoke test
		session.connect("line_shown", Callable(self, "_on_line_shown"))
		session.connect("choices_shown", Callable(self, "_on_choices_shown"))
	else:
		printerr("[DialogueTestRunner] Failed to load graph")

func _on_line_shown(speaker, text):
	print("LINE:", speaker, text)

func _on_choices_shown(choices):
	print("CHOICES:")
	for c in choices:
		print(" - ", c.id, c.text)
