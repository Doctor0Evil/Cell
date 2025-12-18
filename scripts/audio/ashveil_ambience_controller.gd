extends Node3D
class_name AshveilAmbienceController

@export var profile: AshveilAmbienceProfile
@export var ambience_player_path: NodePath
var _ambience: ExtremeHorrorAmbiencePlayer = null
var _petrified_nodes: Array[Node3D] = []

func _ready() -> void:
    _ambience = get_node_or_null(ambience_player_path)
    if _ambience == null:
        push_warning("AshveilAmbienceController: AmbiencePlayer missing")
        return
    _ambience.region_id = "ASHVEIL_DRIFT"

    # Register loops and stingers. Expect local files under res://audio/loops and stingers.
    for loop_id in profile.base_loops:
        _ambience.register_loop(loop_id, "res://audio/loops/%s.ogg" % String(loop_id))
    for loop_id in profile.micro_loops_near_petrified:
        _ambience.register_loop(loop_id, "res://audio/loops/%s.ogg" % String(loop_id))
    for s_id in profile.stingers_collapse:
        _ambience.register_stinger(s_id, "res://audio/stingers/%s.ogg" % String(s_id))
    for s_id in profile.stingers_signal:
        _ambience.register_stinger(s_id, "res://audio/stingers/%s.ogg" % String(s_id))

    _scan_petrified_nodes()
    _ambience.start_ambience()

func _scan_petrified_nodes() -> void:
    _petrified_nodes.clear()
    for n in get_tree().get_nodes_in_group("ashveil_petrified"):
        if n is Node3D:
            _petrified_nodes.append(n)

func _process(delta: float) -> void:
    if _ambience == null or not GameState:
        return
    var player_node = GameState.player if GameState.has("player") else null
    if player_node == null:
        return
    var player_pos := player_node.global_transform.origin
    var min_dist_sq := INF
    for n in _petrified_nodes:
        var d := n.global_transform.origin.distance_squared_to(player_pos)
        if d < min_dist_sq:
            min_dist_sq = d
    var near_factor := clamp(1.0 - (sqrt(min_dist_sq) / 24.0), 0.0, 1.0)

    _ambience.set_layer_weight(&"Ashveil_Petrified_Promenade_Loop", near_factor)
    _ambience.set_layer_weight(&"Ashveil_Heat_Echo_Whispers", pow(near_factor, 2.0))

    if GameState.current_region_stress > 0.75 and randf() < delta * 0.05:
        var s_id := profile.stingers_collapse[randi() % profile.stingers_collapse.size()]
        _ambience.play_stinger(s_id)
