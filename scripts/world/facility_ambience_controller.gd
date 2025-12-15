extends Node3D
class_name FacilityAmbienceController

@export var base_light_energy: float = 1.2
@export var min_light_energy: float = 0.35
@export var max_flicker_intensity: float = 0.25

@export var base_hum_volume_db: float = -18.0
@export var max_hum_volume_db: float = -6.0

@export var heartbeat_threshold_alert: float = 0.6
@export var heartbeat_threshold_sanity: float = 0.45

@export var flicker_update_interval: float = 0.11
@export var noise_speed: float = 1.7

@onready var _lights: Array[Light3D] = []
@onready var _hum_player: AudioStreamPlayer3D = $Hum3D
@onready var _heartbeat_player: AudioStreamPlayer3D = $Heartbeat3D

var _time_accum: float = 0.0
var _flicker_timer: float = 0.0

func _ready() -> void:
    add_to_group("runtime")
    _collect_lights()
    _configure_audio()

func _physics_process(delta: float) -> void:
    if GameState.is_paused:
        return

    _time_accum += delta
    _flicker_timer += delta

    var alert := GameState.alert_level
    var sanity := GameState.player_sanity

    _update_hum_volume(alert)
    _update_heartbeat(alert, sanity)

    if _flicker_timer >= flicker_update_interval:
        _flicker_timer = 0.0
        _update_lights(alert, sanity)

func _collect_lights() -> void:
    _lights.clear()
    for child in get_tree().get_nodes_in_group("facility_light"):
        if child is Light3D:
            _lights.append(child)

func _configure_audio() -> void:
    if _hum_player:
        _hum_player.volume_db = base_hum_volume_db
        _hum_player.autoplay = false
        if not _hum_player.playing:
            _hum_player.play()

    if _heartbeat_player:
        _heartbeat_player.volume_db = -40.0
        _heartbeat_player.autoplay = false

func _update_hum_volume(alert: float) -> void:
    if not _hum_player:
        return
    var t := clamp(alert, 0.0, 1.0)
    var vol := lerp(base_hum_volume_db, max_hum_volume_db, t)
    _hum_player.volume_db = vol

func _update_heartbeat(alert: float, sanity: float) -> void:
    if not _heartbeat_player:
        return

    var trigger := alert >= heartbeat_threshold_alert or sanity <= heartbeat_threshold_sanity

    if trigger:
        if not _heartbeat_player.playing:
            _heartbeat_player.play()
        var intensity := clamp(alert * (1.0 - sanity), 0.0, 1.0)
        var vol := lerp(-32.0, -10.0, intensity)
        _heartbeat_player.volume_db = vol
        _heartbeat_player.pitch_scale = lerp(0.85, 1.25, intensity)
    else:
        if _heartbeat_player.playing:
            _heartbeat_player.stop()

func _update_lights(alert: float, sanity: float) -> void:
    var instability := clamp(alert * (1.0 - sanity), 0.0, 1.0)
    var target_energy := lerp(base_light_energy, min_light_energy, instability)

    for i in _lights.size():
        var light := _lights[i]
        if not is_instance_valid(light):
            continue

        var n := _per_light_noise(i, _time_accum, instability)
        var flicker_scale := 1.0 - max_flicker_intensity * instability * n
        light.light_energy = max(0.05, target_energy * flicker_scale)

        if light.has_method("set_meta"):
            light.set_meta("instability", instability)
            light.set_meta("noise", n)

func _per_light_noise(index: int, t: float, instability: float) -> float:
    var seed_val := float(index) * 13.37
    var v := sin(t * noise_speed + seed_val) + sin(t * (noise_speed * 0.73) + seed_val * 0.37)
    v = (v * 0.5) + 0.5
    return lerp(0.2, 1.0, v * instability)
