# File: res://scripts/world/region_manager.gd
extends Node
class_name RegionManager

@export var player_spawn: Node3D
@export var ambience_controller_path: NodePath
@export var ambience_player_path: NodePath
@export var enemy_spawner_root: NodePath
@export var loot_spawner_root: NodePath

# Cached references
var _ambience_controller: Node = null
var _ambience_player: ExtremeHorrorAmbiencePlayer = null
var _enemy_spawner_root: Node = null
var _loot_spawner_root: Node = null

# Region runtime state
var region_id: StringName = &""
var region_difficulty: int = 1
var region_tags: Array[StringName] = []
var region_hazard_profile: Dictionary = {
    "cold": 0.0,
    "oxygen_penalty": 0.0,
    "radiation": 0.0,
    "infection_bias": 0.0,
    "darkness": 0.0
}

# Spawn tables pulled from CellContentRegistry
var enemy_spawn_table: Array[Dictionary] = []
var loot_spawn_table: Array[Dictionary] = []

func _ready() -> void:
    add_to_group("runtime")

    region_id = GameState.current_region_id
    _ambience_controller = get_node_or_null(ambience_controller_path)
    _ambience_player = get_node_or_null(ambience_player_path)
    _enemy_spawner_root = get_node_or_null(enemy_spawner_root)
    _loot_spawner_root = get_node_or_null(loot_spawner_root)

    _load_region_descriptor()
    _spawn_player()
    _apply_region_modifiers()
    _apply_region_audio_profile()
    _spawn_initial_enemies()
    _spawn_initial_loot()

    DebugLog.log("RegionManager", "READY", {
        "region_id": String(region_id),
        "difficulty": region_difficulty,
        "tags": region_tags.duplicate()
    })

func _apply_region_audio_profile() -> void:
    if not _ambience_player:
        return

    # Simple mapping based on difficulty / tags.
    if region_difficulty <= 1:
        _ambience_player.switch_ambience("facility_low_hum")
    elif region_difficulty == 2:
        _ambience_player.switch_ambience("meat_corridor")
    elif region_difficulty >= 3:
        _ambience_player.switch_ambience("reactor_spine")

    # Allow tags to augment ambience choices (e.g., 'vent', 'pursuit_zone')
    if region_tags.has("vent"):
        _ambience_player.switch_ambience("vent_draft")
    if region_tags.has("pursuit_zone"):
        _ambience_player.switch_ambience("pursuit_static", 2.0)

# -------------------------------------------------------------------
# REGION DESCRIPTOR
# -------------------------------------------------------------------

func _load_region_descriptor() -> void:
    var region_data := CellContentRegistry.get_region(region_id)
    if region_data.is_empty():
        DebugLog.log("RegionManager", "REGION_DESCRIPTOR_MISSING", {
            "region_id": String(region_id)
        })
        return

    region_difficulty = int(region_data.get("difficulty", 1))
    region_tags = region_data.get("tags", []) if region_data.has("tags") else []
    region_hazard_profile["cold"] = float(region_data.get("temperature_modifier", 0.0))
    region_hazard_profile["oxygen_penalty"] = float(region_data.get("oxygen_modifier", 0.0))
    region_hazard_profile["radiation"] = float(region_data.get("radiation", 0.0))
    region_hazard_profile["infection_bias"] = float(region_data.get("infection_bias", 0.0))
    region_hazard_profile["darkness"] = float(region_data.get("darkness", 0.5))

    enemy_spawn_table = region_data.get("enemy_spawn_table", [])
    loot_spawn_table = region_data.get("loot_spawn_table", [])

    DebugLog.log("RegionManager", "REGION_DESCRIPTOR_LOADED", {
        "region_id": String(region_id),
        "difficulty": region_difficulty,
        "hazards": region_hazard_profile,
        "enemy_entries": enemy_spawn_table.size(),
        "loot_entries": loot_spawn_table.size()
    })

# -------------------------------------------------------------------
# PLAYER
# -------------------------------------------------------------------

func _spawn_player() -> void:
    var player_scene := load(GameState.player_scene_path) as PackedScene
    if player_scene == null:
        push_error("Player scene missing at %s" % GameState.player_scene_path)
        DebugLog.log("RegionManager", "PLAYER_SCENE_MISSING", {
            "path": GameState.player_scene_path
        })
        return

    var player := player_scene.instantiate()
    get_tree().current_scene.add_child(player)

    if player_spawn:
        player.global_transform.origin = player_spawn.global_transform.origin

    player.add_to_group("player")

    DebugLog.log("RegionManager", "PLAYER_SPAWNED", {
        "region": String(GameState.current_region_id),
        "position": player.global_transform.origin
    })

# -------------------------------------------------------------------
# ENVIRONMENT MODIFIERS
# -------------------------------------------------------------------

func _apply_region_modifiers() -> void:
    var region_data := CellContentRegistry.get_region(GameState.current_region_id)

    GameState.current_region_cold = float(region_data.get("temperature_modifier", 0.0))
    GameState.current_region_stress = float(region_data.get("oxygen_modifier", 0.0))
    GameState.contamination_level = float(region_data.get("infection_bias", 0.0))

    # Optionally inform ambience controller of darkness level and tension.
    if _ambience_controller and _ambience_controller.has_method("apply_region_profile"):
        _ambience_controller.apply_region_profile(region_hazard_profile, region_difficulty)

    DebugLog.log("RegionManager", "REGION_ENV_APPLIED", {
        "cold": GameState.current_region_cold,
        "stress": GameState.current_region_stress,
        "contamination": GameState.contamination_level
    })

# -------------------------------------------------------------------
# ENEMIES
# -------------------------------------------------------------------

func _spawn_initial_enemies() -> void:
    if not _enemy_spawner_root:
        return

    # enemy_spawn_table entry example:
    # { "id": "SPINECRAWLER", "min": 2, "max": 4, "group": "spinecrawler_spawn" }
    for entry in enemy_spawn_table:
        var enemy_id := String(entry.get("id", ""))
        var min_count := int(entry.get("min", 0))
        var max_count := int(entry.get("max", 0))
        var spawn_group := String(entry.get("group", ""))

        if enemy_id == "" or spawn_group == "":
            continue

        var count := randi_range(min_count, max_count)
        var points := _get_spawn_markers_by_group(_enemy_spawner_root, spawn_group)
        if points.is_empty():
            continue

        for i in count:
            var marker := points[randi() % points.size()]
            _spawn_enemy_at(enemy_id, marker.global_transform.origin)

    DebugLog.log("RegionManager", "ENEMY_SPAWN_INIT", {
        "region": String(region_id),
        "entries": enemy_spawn_table.size()
    })

func _spawn_enemy_at(enemy_id: String, position: Vector3) -> void:
    var enemy_data := CellContentRegistry.get_enemy(enemy_id)
    if enemy_data.is_empty():
        DebugLog.log("RegionManager", "ENEMY_DATA_MISSING", {
            "enemy_id": enemy_id
        })
        return

    var scene_path: String = enemy_data.get("scene_path", "")
    if scene_path == "":
        DebugLog.log("RegionManager", "ENEMY_SCENE_MISSING", {
            "enemy_id": enemy_id
        })
        return

    var scene := load(scene_path) as PackedScene
    if scene == null:
        DebugLog.log("RegionManager", "ENEMY_SCENE_LOAD_FAILED", {
            "enemy_id": enemy_id,
            "path": scene_path
        })
        return

    var instance := scene.instantiate()
    get_tree().current_scene.add_child(instance)
    if instance is Node3D:
        instance.global_transform.origin = position
    instance.add_to_group("enemy")

    DebugLog.log("RegionManager", "ENEMY_SPAWNED", {
        "enemy_id": enemy_id,
        "position": position
    })

# -------------------------------------------------------------------
# LOOT / RESOURCES
# -------------------------------------------------------------------

func _spawn_initial_loot() -> void:
    if not _loot_spawner_root:
        return

    # loot_spawn_table entry example:
    # { "id": "OXYGEN_CAPSULE", "min": 1, "max": 3, "group": "oxygen_cache" }
    for entry in loot_spawn_table:
        var item_id := String(entry.get("id", ""))
        var min_count := int(entry.get("min", 0))
        var max_count := int(entry.get("max", 0))
        var spawn_group := String(entry.get("group", ""))

        if item_id == "" or spawn_group == "":
            continue

        var count := randi_range(min_count, max_count)
        var points := _get_spawn_markers_by_group(_loot_spawner_root, spawn_group)
        if points.is_empty():
            continue

        for i in count:
            var marker := points[randi() % points.size()]
            _spawn_loot_at(item_id, marker.global_transform.origin)

    DebugLog.log("RegionManager", "LOOT_SPAWN_INIT", {
        "region": String(region_id),
        "entries": loot_spawn_table.size()
    })

func _spawn_loot_at(item_id: String, position: Vector3) -> void:
    var item_data := CellContentRegistry.get_loot(item_id)
    if item_data.is_empty():
        DebugLog.log("RegionManager", "LOOT_DATA_MISSING", {
            "item_id": item_id
        })
        return

    var scene_path: String = item_data.get("scene_path", "")
    if scene_path == "":
        DebugLog.log("RegionManager", "LOOT_SCENE_MISSING", {
            "item_id": item_id
        })
        return

    var scene := load(scene_path) as PackedScene
    if scene == null:
        DebugLog.log("RegionManager", "LOOT_SCENE_LOAD_FAILED", {
            "item_id": item_id,
            "path": scene_path
        })
        return

    var instance := scene.instantiate()
    get_tree().current_scene.add_child(instance)
    if instance is Node3D:
        instance.global_transform.origin = position
    instance.add_to_group("loot")

    DebugLog.log("RegionManager", "LOOT_SPAWNED", {
        "item_id": item_id,
        "position": position
    })

# -------------------------------------------------------------------
# UTILS
# -------------------------------------------------------------------

func _get_spawn_markers_by_group(root: Node, group_name: String) -> Array:
    var markers: Array = []
    for child in root.get_children():
        if child is Node3D and child.is_in_group(group_name):
            markers.append(child)
    return markers
