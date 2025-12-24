extends Node
class_name EncounterManager

@export var npc_personality_db: Array = []
@export var dialogue_loader: Node
@export var region_manager: Node
@export var rng: RandomNumberGenerator

func _ready() -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

func try_spawn_dialogue_encounter(player: Node) -> void:
	var region_tags: Array[StringName] = region_manager.get_current_region_tags()
	var oxygen_low := player.get("oxygen_ratio") < 0.35
	var sanity_low := player.get("sanity_ratio") < 0.5

	var context := {
		"region_tags": region_tags,
		"oxygen_low": oxygen_low,
		"sanity_low": sanity_low,
		"is_first_meeting": true
	}

	var pool: Array = []
	for p in npc_personality_db:
		for t in p.encounter_tags:
			if t in region_tags:
				pool.append(p)
				break

	if pool.is_empty():
		return

	var picked := _weighted_pick(pool, context)
	_spawn_npc_and_start_dialogue(picked, context)

func _weighted_pick(pool: Array, context: Dictionary) -> Object:
	var weights: Array[float] = []
	var total := 0.0
	for p in pool:
		var w := 1.0
		if "ASHVEILDRIFT" in context["region_tags"] and "SCRAPROUTE" in p.narrative_tags:
			w += 2.0
		if context["oxygen_low"]:
			w += p.empathy * 0.5 + p.greed * 0.5
		if context["sanity_low"]:
			w += p.paranoia if p.has("paranoia") else 0.0
		weights.append(w)
		total += w

	var roll := rng.randf_range(0.0, total)
	var acc := 0.0
	for i in pool.size():
		acc += weights[i]
		if roll <= acc:
			return pool[i]
	return pool[pool.size() - 1]

func _spawn_npc_and_start_dialogue(personality: Object, context: Dictionary) -> void:
	var npc_scene: PackedScene = preload("res/scenes/npc/humanoid_npc.tscn")
	var npc := npc_scene.instantiate()
	get_tree().current_scene.add_child(npc)
	npc.global_position = region_manager.get_encounter_spawn_point()

	var controller := npc.get_node("DialogueController") if npc.has_node("DialogueController") else null
	if controller:
		controller.personality = personality
		controller.dialogue_loader = dialogue_loader
		controller.start_best_dialogue(context)
