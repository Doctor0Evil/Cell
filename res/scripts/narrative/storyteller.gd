# Path: res://scripts/narrative/storyteller.gd
# Purpose: Minimal Storyteller example integrating LorewayPersona autoload

extends Node
class_name Storyteller

# Local cached personality (optional, kept for convenience)
var personality: LorewayPersonality.PersonalityProfile

func _ready() -> void:
	# Example: set from a natural-language prompt for a region
	LorewayPersona.set_from_prompt("as brutal as possible for Ashditch")
	personality = LorewayPersona.profile

# Brutality-aware event picker
func pick_next_event(candidates: Array) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -INF
	var persona := LorewayPersona.profile
	for ev in candidates:
		var score := LorewayPersonality.score_event(ev, persona)
		if score > best_score:
			best_score = score
			best = ev
	return best

# Other selectors: rumors, scenes, dialogue
func pick_next_rumor(candidates: Array) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -INF
	var persona := LorewayPersona.profile
	for r in candidates:
		var score := LorewayPersonality.score_rumor(r, persona)
		if score > best_score:
			best_score = score
			best = r
	return best

func pick_next_scene(candidates: Array) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -INF
	var persona := LorewayPersona.profile
	for s in candidates:
		var score := LorewayPersonality.score_scene(s, persona)
		if score > best_score:
			best_score = score
			best = s
	return best

func pick_next_dialogue(candidates: Array) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -INF
	var persona := LorewayPersona.profile
	for d in candidates:
		var score := LorewayPersonality.score_dialogue(d, persona)
		if score > best_score:
			best_score = score
			best = d
	return best
