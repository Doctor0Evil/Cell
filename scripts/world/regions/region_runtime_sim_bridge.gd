extends Node3D
class_name RegionRuntimeSimBridge

@export var region_id: StringName = &""
@export var sim_manager_path: NodePath
var sim_manager: RegionSimManager = null

func _ready() -> void:
    sim_manager = get_node_or_null(sim_manager_path)
    if sim_manager == null:
        push_warning("RegionRuntimeSimBridge: no sim manager set")
        return
    sim_manager.register_region(region_id, _get_region_biome_tags())

func _physics_process(delta: float) -> void:
    if sim_manager == null:
        return
    var game_minutes := GameState.get_game_minutes() if GameState.has_method("get_game_minutes") else (Time.get_unix_time_from_system() / 60.0)
    sim_manager.simulate_region(region_id, game_minutes)

    var state: RegionSimManager.RegionSimState = sim_manager.regions.get(region_id, null)
    if state == null:
        return

    GameState.oxygen_drain_rate = lerp(0.8, 1.3, state.scarcity)
    GameState.current_region_stress = lerp(0.1, 1.0, state.tension)
    GameState.set_meta("current_region_unrest", state.unrest)

    if GameState.extreme_ambience_player:
        var world_bias := lerp(0.0, 0.3, state.tension) + lerp(0.0, 0.2, state.unrest)
        GameState.extreme_ambience_player.set_debug_tension_override(clamp(world_bias, 0.0, 1.0))

func _get_region_biome_tags() -> Array[StringName]:
    var tags: Array[StringName] = []
    if region_id == &"ASHVEIL_DEBRIS_STRATUM":
        tags = [StringName("ASHVEIL_DRIFT"), StringName("DEBRIS_STRATUM")]
    elif region_id == &"COLD_VERGE_BELT":
        tags = [StringName("COLDVERGE"), StringName("EXTERIOR_HULL")]
    return tags