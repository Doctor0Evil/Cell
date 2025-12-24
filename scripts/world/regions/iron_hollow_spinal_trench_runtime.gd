extends Node3D
class_name IronHollowSpinalTrenchRuntime

@export var ambience_player_path: NodePath
@export var ambience_controller_3d_path: NodePath
@export var tilemap_floor_path: NodePath
@export var tilemap_walls_path: NodePath

@onready var ambience_player: ExtremeHorrorAmbiencePlayer = null
@onready var floor_map = null
@onready var walls_map = null

func _ready() -> void:
    ambience_player = (ambience_player_path and not ambience_player_path.is_empty()) ? get_node_or_null(ambience_player_path) : $AmbiencePlayer
    floor_map = tilemap_floor_path and not tilemap_floor_path.is_empty() ? get_node_or_null(tilemap_floor_path) : null
    walls_map = tilemap_walls_path and not tilemap_walls_path.is_empty() ? get_node_or_null(tilemap_walls_path) : null

    if ambience_player == null:
        push_warning("IronHollow: AmbiencePlayer missing.")
    else:
        GameState.extreme_ambience_player = ambience_player
        ambience_player.region_id = &"IRON_HOLLOW_SPINAL_TRENCH"
        ambience_player.start_ambience()

    var registry := get_node_or_null("/root/CellContentRegistry")
    var gs := get_node_or_null("/root/GameState")
    var region_def := {} if registry == null else registry.get_region(gs.current_region_id if gs else GameState.current_region_id)
    if not region_def.is_empty():
        var temp := float(region_def.get("temperature_modifier", 0.0))
        var oxy := float(region_def.get("oxygen_modifier", 0.0))
        GameState.current_region_cold = temp
        GameState.current_region_stress = oxy

    var ambience_controller_3d := (ambience_controller_3d_path and not ambience_controller_3d_path.is_empty()) ? get_node_or_null(ambience_controller_3d_path) : (has_node("AmbienceController3D") ? $AmbienceController3D : null)
    if ambience_controller_3d == null:
        for child in get_children():
            if child is AshveilAmbience3DController:
                ambience_controller_3d = child
                break
    if ambience_controller_3d:
        GameState.extreme_ambience_controller = ambience_controller_3d
        ambience_controller_3d.region_id = &"IRON_HOLLOW_SPINAL_TRENCH"
        if ambience_controller_3d.has_method("apply_region_profile"):
            ambience_controller_3d.apply_region_profile(region_def, int(region_def.get("difficulty", 1)))
        if ambience_controller_3d.has_method("start_ambience"):
            ambience_controller_3d.start_ambience()

    DebugLog.log("IronHollowRuntime", "READY", {
        "region": GameState.current_region_id,
        "ambience_player": ambience_player != null,
        "ambience_controller_3d": ambience_controller_3d != null
    })

func _setup_spawns() -> void:
    # placeholder hook for spawn init
    pass

func _setup_ambience() -> void:
    # placeholder for region-specific ambience tweaks
    pass

func trigger_pursuit() -> void:
    if ambience_player:
        ambience_player.switch_ambience("pursuit_static", 2.0)

func trigger_signal_flood() -> void:
    if ambience_player:
        ambience_player.switch_ambience("signal_flood", 3.0)