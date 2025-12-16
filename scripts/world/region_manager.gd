extends Node
class_name RegionManager

@export var player_spawn: Node3D

func _ready() -> void:
    var player_scene := load(GameState.player_scene_path) as PackedScene
    var player := player_scene.instantiate()
    get_tree().current_scene.add_child(player)
    player.global_transform.origin = player_spawn.global_transform.origin

    var region_data := CellContentRegistry.get_region(GameState.current_region_id)
    GameState.current_region_cold = float(region_data.get("temperature_modifier", 0.0))
    GameState.current_region_stress = float(region_data.get("oxygen_modifier", 0.0))
