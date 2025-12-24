extends Node
class_name GameState

var current_region_id: StringName = &""
var player_scene_path: String = "res://scenes/player/Player.tscn"
var current_profile_id: StringName = &""
var inventory: Array = []

# Optional: runtime handle to the global ambience player for test/debug hooks
var extreme_ambience_player: Node = null
# Optional: runtime handle to the region-specific 3D ambience controller (e.g., Ashveil)
var extreme_ambience_controller: Node = null

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

signal player_killed(reason: StringName)
signal player_collapsed(reason: StringName)

func _ready() -> void:
    DebugLog.log("GameState", "READY", {})

    # Handle CLI flags for dev usage when running outside editor.
    if not Engine.is_editor_hint():
        _handle_command_line_flags()

func _handle_command_line_flags() -> void:
    var args := OS.get_cmdline_args()
    if args.is_empty():
        return

    for a in args:
        match String(a):
            "--run-tests":
                DebugLog.log("GameState", "CMDLINE_RUN_TESTS", {"args": args})
                # Switch to test runner scene and exit when done.
                get_tree().change_scene_to_file("res://scenes/tests/TestRunner.tscn")
                return
            "--dev-harness":
                DebugLog.log("GameState", "CMDLINE_DEV_HARNESS", {"args": args})
                get_tree().change_scene_to_file("res://scenes/debug/DevHarness.tscn")
                return
            _:
                # Ignore other flags for now.
                pass

func reset_for_new_run() -> void:
    alert_level = 0.0
    player_sanity = 1.0
    infection_level = 0.0
    travel_load = 0.0
    awake_load = 0.0
    oxygen_drain_rate = 1.0
    exertion_level = 0.0
    stamina_recovery = 1.0
    contamination_level = 0.0
    current_region_cold = 0.0
    current_region_stress = 0.0
    DebugLog.log("GameState", "RESET_FOR_NEW_RUN", {})

func load_region(region_id: StringName) -> void:
    current_region_id = region_id
    var registry: Node = get_node_or_null("/root/CellContentRegistry")
    var region_data: Dictionary = {} if registry == null else registry.get_region(region_id)
    if region_data == null or (region_data is Dictionary and region_data.is_empty()):
        push_error("Unknown region '%s'." % region_id)
        DebugLog.log("GameState", "REGION_LOAD_FAILED", {"region_id": String(region_id)})
        return
    var scene_path: String = region_data.get("scene_path", "")
    if scene_path == "":
        push_error("Region '%s' has no scene_path." % region_id)
        DebugLog.log("GameState", "REGION_SCENE_MISSING", {"region_id": String(region_id)})
        return
    DebugLog.log("GameState", "REGION_LOADING", {
        "region_id": String(region_id),
        "scene_path": scene_path
    })
    get_tree().change_scene_to_file(scene_path)

func kill_player(reason: StringName) -> void:
    DebugLog.log("GameState", "PLAYER_KILLED", {"reason": String(reason)})
    player_killed.emit(reason)
    get_tree().call_group_flags(
        SceneTree.GROUP_CALL_DEFERRED,
        "runtime",
        "on_player_killed",
        reason
    )

func on_player_collapse(reason: StringName) -> void:
    DebugLog.log("GameState", "PLAYER_COLLAPSE", {"reason": String(reason)})
    player_collapsed.emit(reason)
    get_tree().call_group("runtime", "on_player_collapsed", reason)

# Minimal game-time helper for simulations (minutes since epoch).
func get_game_minutes() -> float:
    return float(Time.get_unix_time_from_system()) / 60.0

