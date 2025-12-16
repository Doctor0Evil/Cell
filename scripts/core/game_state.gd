extends Node
class_name GameState

var current_region_id: StringName = &""
var player_scene_path: String = "res://scenes/player/Player.tscn"
var current_profile_id: StringName = &""

var alert_level: float = 0.0
var player_sanity: float = 1.0
var infection_level: float = 0.0

var travel_load: float = 0.0
var awake_load: float = 0.0
var oxygen_drain_rate: float = 1.0
var exertion_level: float = 0.0
var stamina_recovery: float = 1.0
var contamination_level: float = 0.0
var current_region_cold: float = 0.0
var current_region_stress: float = 0.0

func reset_for_new_run() -> void:
    alert_level = 0.0
    player_sanity = 1.0
    infection_level = 0.0

func load_region(region_id: StringName) -> void:
    current_region_id = region_id
    var region_data := CellContentRegistry.get_region(region_id)
    if region_data.is_empty():
        push_error("Unknown region '%s'." % region_id)
        return
    var scene_path: String = region_data.get("scene_path", "")
    if scene_path == "":
        push_error("Region '%s' has no scene_path." % region_id)
        return
    get_tree().change_scene_to_file(scene_path)
