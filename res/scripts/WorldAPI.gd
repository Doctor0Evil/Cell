extends Node

signal growler_director_signal(event_name, payload)

var tension: float = 0.0
var _listeners := {} # { String: Array[Callable] }

func _ready() -> void:
    _listeners.clear()

func register_listener(event_name: String, callback: Callable) -> void:
    if not _listeners.has(event_name):
        _listeners[event_name] = []
    _listeners[event_name].append(callback)

func emit_event(event_name: String, payload: Dictionary = {}) -> void:
    if _listeners.has(event_name):
        for cb in _listeners[event_name]:
            if cb and cb.is_valid():
                cb.call(payload)

func signal_growler_director(event_name: String, payload: Dictionary = {}) -> void:
    emit_signal("growler_director_signal", event_name, payload)

func schedule_growler_pack(params: Dictionary) -> void:
    if Engine.has_singleton("GrowlerDirector"):
        Engine.get_singleton("GrowlerDirector").schedule_growler_pack(params)
    elif has_node("/root/GrowlerDirector"):
        get_node("/root/GrowlerDirector").schedule_growler_pack(params)

func show_inspect_text(text: String) -> void:
    if has_node("/root/Main/InspectUI"):
        get_node("/root/Main/InspectUI").show_text(text)

func play_3d_sound(name: String, position: Vector3) -> void:
    if has_node("/root/Audio3D"):
        get_node("/root/Audio3D").play_at(name, position)

func grant_item(player_id: String, item_id: String) -> void:
    if has_node("/root/GameState"):
        get_node("/root/GameState").grant_item(player_id, item_id)

func reveal_map_layer(layer_name: String) -> void:
    if has_node("/root/MapController"):
        get_node("/root/MapController").reveal_layer(layer_name)

func set_flag(name: String, value: bool) -> void:
    if has_node("/root/GameState"):
        get_node("/root/GameState").set_flag(name, value)

func get_flag(name: String) -> bool:
    if has_node("/root/GameState"):
        return get_node("/root/GameState").get_flag(name)
    return false

func add_tension(amount: float) -> void:
    tension += amount
    if has_node("/root/TensionController"):
        get_node("/root/TensionController").on_tension_changed(tension)

func get_time() -> float:
    return OS.get_unix_time() + (OS.get_unix_time_msec() / 1000.0) % 1.0