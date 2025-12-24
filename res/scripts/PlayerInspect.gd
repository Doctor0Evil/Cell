extends Node3D

@export var max_inspect_distance: float = 3.0
@export var inspect_layer_mask: int = 1 << 2

var _focus_time: float = 0.0

func _physics_process(delta: float) -> void:
    if Input.is_action_pressed("inspect"):
        _focus_time += delta
    else:
        _focus_time = 0.0

    if Input.is_action_just_pressed("inspect"):
        _try_inspect()

func _try_inspect() -> void:
    var space_state = get_world_3d().direct_space_state
    var from = global_transform.origin
    var to = from + -global_transform.basis.z * max_inspect_distance

    var result = space_state.intersect_ray(from, to, [], inspect_layer_mask)
    if result.empty():
        return

    var collider = result.get("collider")
    if not collider:
        return

    if not collider.has_meta("corpse_profile_id"):
        return

    var context := {
        "player_id": "player_1",
        "corpse_entity_id": str(collider.get_instance_id()),
        "corpse_profile_id": collider.get_meta("corpse_profile_id"),
        "position": result.get("position"),
        "is_feigning": collider.has_meta("is_feigning_death") and collider.get_meta("is_feigning_death"),
        "in_growler_territory": true,
        "time_focused": _focus_time,
        "flags": {}
    }

    EventBus.emit_player_inspect_corpse(context)