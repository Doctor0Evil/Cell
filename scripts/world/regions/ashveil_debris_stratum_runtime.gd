extends Node3D
class_name AshveilDebrisStratumRuntime

@export var ambience_player_path: NodePath
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
        push_warning("AshveilDebrisStratum: AmbiencePlayer missing.")
    else:
        GameState.extreme_ambience_player = ambience_player
        ambience_player.region_id = &"ASHVEIL_DEBRIS_STRATUM"
        ambience_player.start_ambience()

    # Example: set base environmental modifiers from a RegionDefinition if present
    var region_def := CellContentRegistry.get_region(GameState.current_region_id)
    if not region_def.is_empty():
        var temp := float(region_def.get("temperature_modifier", 0.0))
        var oxy := float(region_def.get("oxygen_modifier", 0.0))
        GameState.current_region_cold = temp
        GameState.current_region_stress = oxy

    DebugLog.log("AshveilRuntime", "READY", {
        "region": GameState.current_region_id,
        "ambience_player": ambience_player != null
    })

# Hook for external systems to bump ambience (e.g., on detection)
func trigger_pursuit() -> void:
    if ambience_player:
        ambience_player.switch_ambience("pursuit_static", 2.0)

func trigger_signal_flood() -> void:
    if ambience_player:
        ambience_player.switch_ambience("signal_flood", 3.0)
