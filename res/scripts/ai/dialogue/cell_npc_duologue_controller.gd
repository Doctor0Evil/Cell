# File: res/scripts/ai/dialogue/cell_npc_duologue_controller.gd
extends Node
class_name CellNpcDuologueController

## Lightweight controller that stages a 2-NPC scene and streams it to the runtime dialogue bus.
## Designed for CELL’s grounded survival-horror atmosphere.

signal duologue_started(meta)
signal duologue_line(line_data)
signal duologue_finished(meta)

const PERSONALITY_AXES := [
	"Friendly", "Cunning", "Cruel", "Nihilistic", "Paranoid",
	"Cold", "Altruistic", "Fanatic", "Curious", "Obedient"
]

var npc_a := {
	"id": "vent_scavenger",
	"name": "Kerr",
	"faction": "Ashveil_Scrappers",
	"personality": {
		"Friendly": 0.2,
		"Cunning": 0.7,
		"Cruel": 0.3,
		"Nihilistic": 0.6,
		"Paranoid": 0.8,
		"Cold": 0.5,
		"Altruistic": 0.1,
		"Fanatic": 0.4,
		"Curious": 0.6,
		"Obedient": 0.2
	}
}

var npc_b := {
	"id": "tremor_medic",
	"name": "Ine",
	"faction": "IGSF_Remnant",
	"personality": {
		"Friendly": 0.4,
		"Cunning": 0.5,
		"Cruel": 0.1,
		"Nihilistic": 0.3,
		"Paranoid": 0.7,
		"Cold": 0.4,
		"Altruistic": 0.6,
		"Fanatic": 0.5,
		"Curious": 0.5,
		"Obedient": 0.6
	}
}

var scene_context := {
	"region": "Forgotten_Moon_Cold_Verge",
	"room_tag": "maintenance_artery_vent_rattle",
	"threat_level": 0.6,
	"oxygen_scarcity": 0.8,
	"vitality_risk": 0.7,
	"fracture_pressure": 0.5, # likelihood of new mental fracture
	"player_is_listening": true,
	"player_distance_m": 9.0
}

var _lines : Array = []
var _cursor := 0
var _active := false


func _ready() -> void:
	_build_duologue_script()
	# Auto-run preview in editor or debug builds
	if Engine.is_editor_hint():
		return
	_start_duologue()


func _build_duologue_script() -> void:
	_lines.clear()
	var seed := Time.get_unix_time_from_system() % 2147483647
	seed = int(seed)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# Derived tension factors
	var paranoia_avg := (npc_a.personality["Paranoid"] + npc_b.personality["Paranoid"]) * 0.5
	var nihilism_avg := (npc_a.personality["Nihilistic"] + npc_b.personality["Nihilistic"]) * 0.5
	var cruelty_bias := npc_a.personality["Cruel"]
	var altruism_b := npc_b.personality["Altruistic"]

	var opener_a : String
	if paranoia_avg > 0.6:
		opener_a = "You feel that, Ine? Vent’s breathing wrong. Like something’s crawling back instead of out."
	else:
		opener_a = "Hear that pitch in the vent? Fans don’t whine like that unless something’s chewing on the bearings."

	var response_b : String
	if altruism_b > 0.5:
		response_b = "If the vent’s sick, so are we. That’s shared air, Kerr. Whatever’s in there, we’ve been swallowing it for cycles."
	else:
		response_b = "If it breaks, we move. Or we don’t. Either way, the vent doesn’t care whose lungs it shreds."

	var mid_a : String
	if cruelty_bias > 0.5:
		mid_a = "Saw a Breather choke on his own mask yesterday. Filters gummed thick, like he’d been inhaling meat. Sounded almost grateful when he stopped kicking."
	else:
		mid_a = "Ran into a Breather yesterday. Mask filters were clogged with this grey pulp, like the station had been exhaling rot straight into him."

	var mid_b : String
	if nihilism_avg > 0.5:
		mid_b = "That’s not rot. That’s the station learning what we are made of, then sending it back, improved."
	else:
		mid_b = "That’s exposure buildup. Tissue aerosol, coolant crystals, spores. Mix it long enough and you get something that thinks."

	var hook_b : String
	if scene_context["player_is_listening"] and scene_context["player_distance_m"] <= 10.0:
		hook_b = "Keep your voice down. Someone’s on the catwalk, listening for words they can trade for rations."
	else:
		hook_b = "Keep your voice down. These ducts carry whispers farther than air, and rumors pay better than scrap."

	var closer_a : String
	if scene_context["vitality_risk"] > 0.6:
		closer_a = "Fine. Patch your fractures, count your pulses. I’ll be busy selling coordinates to whoever survives the next pressure drop."
	else:
		closer_a = "Fine. You keep stitching dead veins back together. I’ll keep an exit mapped for when the Moon remembers how to kill us properly."

	_lines.append(_make_line(npc_a, opener_a, rng, {"mood": "uneasy", "seed": rng.randi()}))
	_lines.append(_make_line(npc_b, response_b, rng, {"mood": "clinical", "seed": rng.randi()}))
	_lines.append(_make_line(npc_a, mid_a, rng, {"mood": "relishing", "seed": rng.randi()}))
	_lines.append(_make_line(npc_b, mid_b, rng, {"mood": "detached", "seed": rng.randi()}))
	_lines.append(_make_line(npc_b, hook_b, rng, {"mood": "cautious", "seed": rng.randi(), "targets_player": scene_context["player_is_listening"]}))
	_lines.append(_make_line(npc_a, closer_a, rng, {"mood": "pragmatic", "seed": rng.randi()}))


func _make_line(npc_data: Dictionary, text: String, rng: RandomNumberGenerator, extra: Dictionary = {}) -> Dictionary:
	var paranoia := npc_data.personality.get("Paranoid", 0.5)
	var cruelty := npc_data.personality.get("Cruel", 0.0)
	var nihilism := npc_data.personality.get("Nihilistic", 0.0)

	var delivery_speed := lerp(0.7, 1.2, clamp(1.0 - paranoia, 0.0, 1.0))
	var pause_after := lerp(0.4, 1.5, clamp(nihilism + cruelty * 0.5, 0.0, 1.0))

	var line := {
		"speaker_id": npc_data.id,
		"speaker_name": npc_data.name,
		"faction": npc_data.faction,
		"text": text,
		"delivery_speed": delivery_speed,
		"pause_after": pause_after,
		"personality_snapshot": npc_data.personality.duplicate(true),
		"meta": extra
	}
	return line


func _start_duologue() -> void:
	if _lines.is_empty():
		return
	_active = true
	_cursor = 0
	var meta := {
		"scene_context": scene_context,
		"npc_a": npc_a,
		"npc_b": npc_b,
		"line_count": _lines.size()
	}
	emit_signal("duologue_started", meta)
	_emit_next_line()


func _emit_next_line() -> void:
	if not _active:
		return
	if _cursor >= _lines.size():
		_active = false
		var meta := {
			"ended": true,
			"scene_context": scene_context,
			"fracture_pressure": scene_context["fracture_pressure"]
		}
			# IDE hook: route completion to narrative bus
		get_tree().call_group("runtime", "on_dialog_scene_finished", meta)
		emit_signal("duologue_finished", meta)
		return

	var line := _lines[_cursor]
	_cursor += 1

	# IDE hook: forward each line as an event; UI or logging layer can render/print.
	get_tree().call_group("runtime", "on_dialog_line", line)
	emit_signal("duologue_line", line)

	var pause := float(line["pause_after"])
	await get_tree().create_timer(pause).timeout
	_emit_next_line()


func inject_scene_context(new_context: Dictionary) -> void:
	for k in new_context.keys():
		scene_context[k] = new_context[k]


func force_stop() -> void:
	if not _active:
		return
	_active = false
	var meta := {
		"interrupted": true,
		"cursor": _cursor,
		"scene_context": scene_context
	}
	emit_signal("duologue_finished", meta)
	get_tree().call_group("runtime", "on_dialog_scene_interrupted", meta)
