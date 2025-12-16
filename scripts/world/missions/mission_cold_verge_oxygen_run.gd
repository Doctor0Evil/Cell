# File: res://scripts/world/missions/mission_cold_verge_oxygen_run.gd
extends Node3D
class_name MissionColdVergeOxygenRun

@export var region_id: String = "COLD_VERGE_CRYO_RIM"
@export var required_capsules_to_extract: int = 2
@export var breather_spawn_enemy_id: String = "BREATHER"
@export var ash_eater_spawn_enemy_id: String = "ASH_EATER"

@export var oxygen_drain_per_tick: float = 8.0      # seconds of oxygen removed each tick
@export var oxygen_tick_interval: float = 3.0        # seconds
@export var cold_temp_drop_per_tick: float = 0.35    # degrees C
@export var cold_tick_interval: float = 4.0          # seconds

@export var breather_spawn_interval: float = 25.0
@export var breather_max_active: int = 4

var _mission_active: bool = false
var _mission_failed: bool = false
var _mission_completed: bool = false

var _capsules_collected: int = 0
var _current_region_config: Dictionary = {}

@onready var _start_trigger: Area3D = $StartTrigger
@onready var _cache_a_trigger: Area3D = $ObjectiveOxygenCacheA
@onready var _cache_b_trigger: Area3D = $ObjectiveOxygenCacheB
@onready var _extraction_trigger: Area3D = $ExtractionZone

@onready var _oxygen_timer: Timer = $OxygenDrainTick
@onready var _cold_timer: Timer = $ColdDamageTick
@onready var _breather_timer: Timer = $BreatherSpawnTimer

@onready var _spawn_root: Node3D = $EnemySpawnPoints

var _player: Node3D

func _ready() -> void:
    add_to_group("runtime")

    _player = get_tree().get_first_node_in_group("player")
    _bind_triggers()

    _oxygen_timer.wait_time = oxygen_tick_interval
    _oxygen_timer.timeout.connect(_on_oxygen_tick)

    _cold_timer.wait_time = cold_tick_interval
    _cold_timer.timeout.connect(_on_cold_tick)

    _breather_timer.wait_time = breather_spawn_interval
    _breather_timer.timeout.connect(_on_breather_spawn_tick)

    _load_region_config()
    _set_hud_objective("Reach the first oxygen cache.")
    DebugLog.log("MissionColdVergeOxygenRun", "INIT", {
        "region_id": region_id,
        "required_capsules_to_extract": required_capsules_to_extract
    })

func _bind_triggers() -> void:
    if _start_trigger:
        _start_trigger.body_entered.connect(_on_start_area_entered)
    if _cache_a_trigger:
        _cache_a_trigger.body_entered.connect(_on_cache_a_entered)
    if _cache_b_trigger:
        _cache_b_trigger.body_entered.connect(_on_cache_b_entered)
    if _extraction_trigger:
        _extraction_trigger.body_entered.connect(_on_extraction_entered)

func _load_region_config() -> void:
    var registry_res := load("res://config/cell_content_registry.tres")
    if registry_res:
        _current_region_config = registry_res.get_region(region_id)
    else:
        _current_region_config = {}

# --- Mission flow ---

func _on_start_area_entered(body: Node3D) -> void:
    if body.is_in_group("player") and not _mission_active and not _mission_failed:
        _mission_active = true
        _oxygen_timer.start()
        _cold_timer.start()
        _breather_timer.start()
        _set_hud_objective("Collect oxygen capsules and reach extraction.")
        DebugLog.log("MissionColdVergeOxygenRun", "MISSION_START", {
            "region_id": region_id
        })

func _on_cache_a_entered(body: Node3D) -> void:
    if not _mission_active or _mission_failed:
        return
    if body.is_in_group("player"):
        _grant_oxygen_capsule()
        _set_hud_objective("Oxygen cache A secured. Find cache B or head to extraction.")
        DebugLog.log("MissionColdVergeOxygenRun", "CACHE_A_COLLECTED", {
            "capsules_collected": _capsules_collected
        })
        _cache_a_trigger.monitoring = false

func _on_cache_b_entered(body: Node3D) -> void:
    if not _mission_active or _mission_failed:
        return
    if body.is_in_group("player"):
        _grant_oxygen_capsule()
        _set_hud_objective("Oxygen cache B secured. Reach extraction.")
        DebugLog.log("MissionColdVergeOxygenRun", "CACHE_B_COLLECTED", {
            "capsules_collected": _capsules_collected
        })
        _cache_b_trigger.monitoring = false

func _grant_oxygen_capsule() -> void:
    _capsules_collected += 1
    GameState.inventory.append({
        "id": "OXYGEN_CAPSULE",
        "stack": 1
    })
    # Optional: flash HUD indicator through a global UI event group.

func _on_extraction_entered(body: Node3D) -> void:
    if not _mission_active or _mission_failed or _mission_completed:
        return
    if not body.is_in_group("player"):
        return

    if _capsules_collected >= required_capsules_to_extract:
        _complete_mission()
    else:
        _set_hud_objective("Extraction locked. Required oxygen caches not secured.")
        DebugLog.log("MissionColdVergeOxygenRun", "EXTRACTION_DENIED", {
            "capsules_collected": _capsules_collected,
            "required": required_capsules_to_extract
        })

func _complete_mission() -> void:
    _mission_completed = true
    _mission_active = false
    _oxygen_timer.stop()
    _cold_timer.stop()
    _breather_timer.stop()

    GameState.modify_alert(-0.2)
    _set_hud_objective("Mission complete. Oxygen route stabilized.")
    DebugLog.log("MissionColdVergeOxygenRun", "MISSION_COMPLETE", {
        "capsules_collected": _capsules_collected
    })
    get_tree().call_group("runtime", "on_mission_complete", region_id)

# --- Survival enforcement ticks ---

func _on_oxygen_tick() -> void:
    if not _mission_active or _mission_failed:
        return
    # Pull current oxygen seconds from survival system or GameState proxy.
    # For now, use a generic inventory-based approximation hook.
    var survival := get_tree().get_first_node_in_group("survival_system")
    if survival and survival.has_method("drain_oxygen_seconds"):
        survival.drain_oxygen_seconds(oxygen_drain_per_tick)
        var remaining := survival.get_oxygen_seconds_remaining()
        DebugLog.log("MissionColdVergeOxygenRun", "OXYGEN_TICK", {
            "delta_seconds": oxygen_drain_per_tick,
            "remaining": remaining
        })
        if remaining <= 0.0:
            _fail_mission("Oxygen depleted.")
    else:
        # Fallback: apply direct damage if survival system is not present.
        GameState.apply_damage(5)
        DebugLog.log("MissionColdVergeOxygenRun", "OXYGEN_FALLBACK_DAMAGE", {
            "damage": 5,
            "player_health": GameState.player_health
        })
        if GameState.player_health <= 0:
            _fail_mission("Fatal hypoxia.")

func _on_cold_tick() -> void:
    if not _mission_active or _mission_failed:
        return
    var survival := get_tree().get_first_node_in_group("survival_system")
    if survival and survival.has_method("apply_cold_exposure"):
        survival.apply_cold_exposure(cold_temp_drop_per_tick)
        var temp := survival.get_body_temperature()
        DebugLog.log("MissionColdVergeOxygenRun", "COLD_TICK", {
            "delta_temp": -cold_temp_drop_per_tick,
            "player_temp": temp
        })
        if temp <= 28.0:
            _fail_mission("Core temperature collapse.")
    else:
        GameState.apply_damage(4)
        DebugLog.log("MissionColdVergeOxygenRun", "COLD_FALLBACK_DAMAGE", {
            "damage": 4,
            "player_health": GameState.player_health
        })
        if GameState.player_health <= 0:
            _fail_mission("Lethal hypothermia.")

func _fail_mission(reason: String) -> void:
    if _mission_failed:
        return
    _mission_failed = true
    _mission_active = false
    _oxygen_timer.stop()
    _cold_timer.stop()
    _breather_timer.stop()

    _set_hud_objective("Mission failed: " + reason)
    DebugLog.log("MissionColdVergeOxygenRun", "MISSION_FAIL", {
        "reason": reason
    })
    get_tree().call_group("runtime", "on_mission_failed", {
        "region_id": region_id,
        "reason": reason
    })

# --- Enemy pressure ---

func _on_breather_spawn_tick() -> void:
    if not _mission_active or _mission_failed:
        return

    var active_breathers := _count_active_enemies_by_id(breather_spawn_enemy_id)
    if active_breathers >= breather_max_active:
        return

    var spawn_points: Array[Node3D] = []
    for child in _spawn_root.get_children():
        if child is Marker3D and child.name.begins_with("Spawn_Breather"):
            spawn_points.append(child)

    if spawn_points.is_empty():
        return

    var spawn_point: Marker3D = spawn_points[randi() % spawn_points.size()]
    _spawn_enemy_in_region(breather_spawn_enemy_id, spawn_point.global_transform.origin)

func _spawn_enemy_in_region(enemy_id: String, position: Vector3) -> void:
    var registry_res := load("res://config/cell_content_registry.tres")
    if not registry_res:
        return

    var enemy_data := registry_res.get_enemy(enemy_id)
    if enemy_data.is_empty():
        return

    var scene_path: String = enemy_data.get("scene_path", "")
    if scene_path == "":
        return

    var scene_res := load(scene_path)
    if not scene_res:
        return

    var enemy_instance := scene_res.instantiate()
    get_tree().current_scene.add_child(enemy_instance)
    enemy_instance.global_transform.origin = position

    DebugLog.log("MissionColdVergeOxygenRun", "ENEMY_SPAWNED", {
        "enemy_id": enemy_id,
        "position": position
    })

func _count_active_enemies_by_id(enemy_id: String) -> int:
    var count := 0
    var registry_res := load("res://config/cell_content_registry.tres")
    if not registry_res:
        return 0
    var enemy_data := registry_res.get_enemy(enemy_id)
    if enemy_data.is_empty():
        return 0
    var display_name: String = enemy_data.get("display_name", "")

    for node in get_tree().get_nodes_in_group("enemy"):
        if node.has_method("get_display_name"):
            if node.get_display_name() == display_name:
                count += 1
    return count

# --- HUD integration stub ---

func _set_hud_objective(text: String) -> void:
    # Broadcast to any UI controller listening in the runtime group.
    get_tree().call_group_flags(
        SceneTree.GROUP_CALL_DEFERRED,
        "runtime",
        "on_objective_update",
        text
    )
