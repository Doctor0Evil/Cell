extends Node3D
class_name FacilityAmbienceController

@export var debug_enabled: bool = true

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

# Low-state flags
@export var heartbeat_boost_db: float = 6.0
@export var heartbeat_boost_pitch: float = 0.15
var _low_oxygen_active: bool = false
var _low_temp_active: bool = false

@onready var _heartbeat_player_soft: AudioStreamPlayer3D = $HeartbeatSoft
@onready var _heartbeat_player_intense: AudioStreamPlayer3D = $HeartbeatIntense
var _heartbeat_tween: Tween = null

func _ready() -> void:
    add_to_group("runtime")
    _collect_lights()
    _configure_audio()
    if debug_enabled:
        DebugLog.log("FacilityAmbienceController", "READY", {
            "light_count": _lights.size()
        })

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

    # Configure heartbeat layers: soft + intense
    if _heartbeat_player_soft:
        _heartbeat_player_soft.volume_db = -40.0
        _heartbeat_player_soft.autoplay = false
        if not _heartbeat_player_soft.playing:
            _heartbeat_player_soft.play()
    if _heartbeat_player_intense:
        _heartbeat_player_intense.volume_db = -80.0
        _heartbeat_player_intense.autoplay = false
        if not _heartbeat_player_intense.playing:
            _heartbeat_player_intense.play()
    # Ensure tween slot
    _heartbeat_tween = null

func _update_hum_volume(alert: float) -> void:
    if not _hum_player:
        return
    var t := clamp(alert, 0.0, 1.0)
    var vol := lerp(base_hum_volume_db, max_hum_volume_db, t)
    _hum_player.volume_db = vol
    if debug_enabled:
        DebugLog.log("FacilityAmbienceController", "HUM_UPDATE", {
            "alert": alert,
            "volume_db": vol
        })

func _update_heartbeat(alert: float, sanity: float) -> void:
    if not _heartbeat_player:
        return

    var trigger := alert >= heartbeat_threshold_alert or sanity <= heartbeat_threshold_sanity

    if trigger:
        if not _heartbeat_player.playing:
            _heartbeat_player.play()
        var intensity := clamp(alert * (1.0 - sanity), 0.0, 1.0)

        # apply low-oxygen / low-temp boosts to make heartbeat more urgent
        var extra_intensity := 0.0
        if _low_oxygen_active:
            extra_intensity += 0.4
        if _low_temp_active:
            extra_intensity += 0.3
        intensity = clamp(intensity + extra_intensity, 0.0, 1.0)

        var vol := lerp(-32.0, -10.0, intensity)
        var soft_vol := vol
        var intense_vol := vol - 12.0 # start quieter for intense layer

        # apply low-oxygen / low-temp boosts to make heartbeat more urgent
        if _low_oxygen_active or _low_temp_active:
            soft_vol = max(-12.0, soft_vol + heartbeat_boost_db * 0.5)
            intense_vol = max(-6.0, intense_vol + heartbeat_boost_db)

        # tween volumes for smooth transitions
        _set_heartbeat_layer_levels(soft_vol, intense_vol)

        var pitch := lerp(0.85, 1.25, intensity)
        if _low_oxygen_active:
            pitch += heartbeat_boost_pitch
        # apply pitch to both layers
        if _heartbeat_player_soft:
            _heartbeat_player_soft.pitch_scale = pitch
        if _heartbeat_player_intense:
            _heartbeat_player_intense.pitch_scale = pitch + ( _low_oxygen_active ? 0.05 : 0.0 )
    else:
        if _heartbeat_player.playing:
            _heartbeat_player.stop()
    if debug_enabled:
        DebugLog.log("FacilityAmbienceController", "HEARTBEAT_UPDATE", {
            "trigger": trigger,
            "alert": alert,
            "sanity": sanity,
            "low_oxygen": _low_oxygen_active,
            "low_temp": _low_temp_active
        })

func _set_heartbeat_layer_levels(soft_db: float, intense_db: float) -> void:
    # Smoothly tween volumes on both heartbeat layers
    if _heartbeat_tween:
        _heartbeat_tween.kill()
    _heartbeat_tween = get_tree().create_tween()
    if _heartbeat_player_soft:
        _heartbeat_tween.tween_property(_heartbeat_player_soft, "volume_db", soft_db, 0.6)
    if _heartbeat_player_intense:
        _heartbeat_tween.tween_property(_heartbeat_player_intense, "volume_db", intense_db, 0.6)

func _update_lights(alert: float, sanity: float) -> void:
    var instability := clamp(alert * (1.0 - sanity), 0.0, 1.0)
    var target_energy := lerp(base_light_energy, min_light_energy, instability)

    if debug_enabled:
        DebugLog.log("FacilityAmbienceController", "LIGHT_UPDATE_START", {
            "instability": instability,
            "light_count": _lights.size()
        })

    for i in range(_lights.size()):
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

# Runtime hooks for survival warnings (called via group calls to 'runtime')
func on_low_oxygen(data: Dictionary) -> void:
    _low_oxygen_active = true
    if debug_enabled:
        DebugLog.log("FacilityAmbienceController", "LOW_OXYGEN_ACTIVE", data)

func on_oxygen_recovered(data: Dictionary) -> void:
    _low_oxygen_active = false
    if debug_enabled:
        DebugLog.log("FacilityAmbienceController", "OXYGEN_RECOVERED", data)

func on_low_temp(data: Dictionary) -> void:
    _low_temp_active = true
    if debug_enabled:
        DebugLog.log("FacilityAmbienceController", "LOW_TEMP_ACTIVE", data)

func on_temp_recovered(data: Dictionary) -> void:
    _low_temp_active = false
    if debug_enabled:
        DebugLog.log("FacilityAmbienceController", "TEMP_RECOVERED", data)
