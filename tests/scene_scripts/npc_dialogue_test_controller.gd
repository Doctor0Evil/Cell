extends Control

@onready var line_label := Label.new()
@onready var choices_vbox := VBoxContainer.new()

func _ready():
	# Build simple UI
	add_child(line_label)
	add_child(choices_vbox)
	line_label.text = "(dialogue will appear here)"

	# Load bridge and graph
	var bridge := preload("res://res/scripts/narrative/loreway_bridge.gd").new()
	add_child(bridge)
	bridge._load_all_dialogues()
	var g := bridge.get_graph("ashveil_scavenger_intro")
	if not g:
		printerr("[NPCDialogueTestController] failed to load graph")
		return

	# Setup fake player and npc
	var player := Node.new()
	player.set_meta("traits", ["containmentface", "chemdiscipline"])
	player.get_active_trait_ids = func():
		return player.get_meta("traits")
	player.get_attribute = func(name):
		match str(name).to_lower():
			"influence": return 7.0
			"temper": return 5.0
			_ : return 0.0

	var npc := preload("res://res/scripts/world/npc/npc_personality.gd").new()
	npc.trait_ids = ["ashveilscavenger"]
	npc.narrative_tags = ["SCRAPROUTE"]

	# Create evaluator and session
	var evaluator := preload("res://res/scripts/narrative/dialogue_condition_evaluator.gd").new()
	evaluator.trait_registry = preload("res://design/traits/cell_traits_registry.gd").new()
	evaluator.faction_system = get_node_or_null("/root/FactionSystem")

	var session := preload("res://res/scripts/narrative/dialogue_session.gd").new()
	session.condition_evaluator = evaluator

	# Set context and start
	var ctx := {"player": player, "npc": npc}
	session.start(g, "start", ctx)

	# Wire signals
	session.connect("line_shown", Callable(self, "_on_line_shown"))
	session.connect("choices_shown", Callable(self, "_on_choices_shown"))
	session.connect("dialogue_ended", Callable(self, "_on_dialogue_ended"))

func _on_line_shown(speaker, text):
	line_label.text = str(speaker) + ": " + str(text)
	print("LINE:", speaker, text)

func _on_choices_shown(choices):
	# clear vbox
	for child in choices_vbox.get_children():
		child.queue_free()
	for c in choices:
		var b := Button.new()
		b.text = c.text if c.text != "" else c.label
		b.pressed.connect(func(cid=c.id):
			session.choose(StringName(cid))
		)
		choices_vbox.add_child(b)
		print("CHOICE:", c.id, c.text)

func _on_dialogue_ended(id):
	print("Dialogue ended:", id)
	line_label.text = "(ended)"