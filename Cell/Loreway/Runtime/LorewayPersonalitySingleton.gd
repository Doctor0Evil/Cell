# Path: res://Cell/Loreway/Runtime/LorewayPersonalitySingleton.gd
# Autoload singleton exposing a global Loreway personality profile

extends Node
class_name LorewayPersonalitySingleton

# Current global personality profile used throughout the game/editor
var profile: LorewayPersonality.PersonalityProfile

func _ready() -> void:
	# Default to the Cell core brutal profile
	profile = LorewayPersonality.default_profile()

func set_from_task(task: Dictionary) -> void:
	profile = LorewayPersonality.personality_from_task(task)

func set_from_prompt(prompt: String) -> void:
	var task := LorewayPersonality.task_from_user_prompt(prompt)
	set_from_task(task)

func get_profile() -> LorewayPersonality.PersonalityProfile:
	return profile
