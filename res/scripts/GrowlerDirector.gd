extends Node

@export var growler_pack_scene: PackedScene

var active_packs: Array = []

func _ready() -> void:
    WorldAPI.connect("growler_director_signal", Callable(self, "_on_world_director_signal"))

func _on_world_director_signal(event_name: String, payload: Dictionary) -> void:
    match event_name:
        "TABOO_FEIGN_DEATH_BROKEN":
            _spawn_pack(payload, "hunt")
        "CORPSE_INSPECTED", "INSPECT_CORPSE_FOCUS":
            _spawn_pack(payload, "investigation")

func schedule_growler_pack(params: Dictionary) -> void:
    _spawn_pack(params, params.get("type", "investigation"))

func _spawn_pack(payload: Dictionary, pack_type: String) -> void:
    if growler_pack_scene == null:
        push_warning("GrowlerDirector: growler_pack_scene is not set.")
        return

    var pack = growler_pack_scene.instantiate()
    var focus_pos: Vector3 = payload.get("focus_position", Vector3.ZERO)
    var radius: float = float(payload.get("focus_radius", 18.0))

    var angle := randf() * TAU
    var offset := Vector3(cos(angle), 0.0, sin(angle)) * radius
    if pack and pack.has_method("set_global_position"):
        pack.set_global_position(focus_pos + offset)
    elif pack and pack is Node3D:
        pack.global_position = focus_pos + offset

    if pack and pack.has_method("set_target_player_id"):
        pack.set_target_player_id(payload.get("target_player_id", ""))

    if pack and pack.has_method("set_encounter_reason"):
        pack.set_encounter_reason(payload.get("reason", pack_type))

    add_child(pack)
    active_packs.append(pack)

func _on_pack_removed(pack_node: Node) -> void:
    active_packs.erase(pack_node)

func _process(_delta: float) -> void:
    # Cleanup destroyed packs
    for pack in active_packs.duplicate():
        if not is_instance_valid(pack):
            active_packs.erase(pack)