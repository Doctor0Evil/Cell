extends Node

signal memory_decrypted(amount: float)
signal distress_variant_played(variant_index: int, pitch_mod: float)
signal nav_intrusion_changed(value: float)

const PLAYER_ZONE = {
    "ANTEROOM": 0,
    "LAB": 1,
    "CORE": 2,
}

var nav_intrusion: float = 0.0
var cognitive_stability: float = 1.0
var exposure_time: float = 0.0
var audio_level_db: float = -60.0
var memory_sync: float = 0.0
var player_zone: int = PLAYER_ZONE.ANTEROOM

var _distress_variants: Array = [
    "res://audio/distress/we_use_your_memories_var1.ogg",
    "res://audio/distress/we_use_your_memories_var2.ogg",
    "res://audio/distress/we_use_your_memories_var3.ogg",
    "res://audio/distress/we_use_your_memories_var4.ogg",
]

onready var _vo_player: AudioStreamPlayer = $VOPlayer
onready var _sfx_player: AudioStreamPlayer = $SFXPlayer
onready var _subsonic_player: AudioStreamPlayer = $SubsonicRumble
onready var _memory_bleed_layer: CanvasLayer = $MemoryBleedLayer

func _ready() -> void:
    _setup_subsonic_rumble()
    set_process(true)


func _process(delta: float) -> void:
    _update_exposure(delta)
    _update_audio_reactive_effects()
    _update_subsonic_rumble()


func _update_exposure(delta: float) -> void:
    if player_zone == PLAYER_ZONE.CORE:
        exposure_time += delta
    else:
        exposure_time = max(exposure_time - delta * 0.5, 0.0)

    if exposure_time > 12.0 or cognitive_stability < 0.6:
        _trigger_memory_bleed_overlay()


func _update_audio_reactive_effects() -> void:
    if audio_level_db > -20.0 and nav_intrusion > 0.1:
        _play_breathing_static()


func _update_subsonic_rumble() -> void:
    if _subsonic_player.stream:
        _subsonic_player.volume_db = lerp(-40.0, -6.0, clamp(nav_intrusion * 0.8, 0.0, 1.0))


func _setup_subsonic_rumble() -> void:
    var stream: AudioStream = load("res://audio/static/subsonic_rumble.ogg")
    _subsonic_player.stream = stream
    _subsonic_player.bus = "SFX"
    _subsonic_player.volume_db = -40.0
    _subsonic_player.loop = true
    _subsonic_player.play()


func set_audio_level_db(level_db: float) -> void:
    audio_level_db = level_db


func set_player_zone(zone: int) -> void:
    player_zone = zone


func adjust_nav_intrusion(delta_value: float) -> void:
    nav_intrusion = clamp(nav_intrusion + delta_value, 0.0, 1.0)
    emit_signal("nav_intrusion_changed", nav_intrusion)


func adjust_cognitive_stability(delta_value: float) -> void:
    cognitive_stability = clamp(cognitive_stability + delta_value, 0.0, 1.0)


func set_memory_sync(value: float) -> void:
    memory_sync = clamp(value, 0.0, 1.0)
    if memory_sync > 0.4:
        trigger_memory_phrase()


func register_memory_decrypt(amount: float) -> void:
    adjust_nav_intrusion(0.05)
    memory_sync = clamp(memory_sync + amount, 0.0, 1.0)
    emit_signal("memory_decrypted", amount)
    trigger_memory_phrase()


func play_distress_variant(variant_index: int, pitch_mod: float = 1.0) -> void:
    variant_index = clamp(variant_index, 0, _distress_variants.size() - 1)
    var path: String = _distress_variants[variant_index]
    var stream: AudioStream = load(path)
    _vo_player.pitch_scale = pitch_mod
    _vo_player.stream = stream
    _vo_player.play()
    emit_signal("distress_variant_played", variant_index, pitch_mod)


func play_random_distress_variant() -> void:
    var idx := randi() % _distress_variants.size()
    var pitch := rand_range(0.8, 1.2)
    play_distress_variant(idx, pitch)


func trigger_memory_phrase() -> void:
    # Hook: spawn AR projection, overlay faces, prioritized VO clip.
    play_random_distress_variant()
    adjust_nav_intrusion(0.05)


func _play_breathing_static() -> void:
    if _sfx_player.playing:
        return
    var s := load("res://audio/static/breathing_static_loop.ogg")
    _sfx_player.stream = s
    _sfx_player.volume_db = lerp(-20.0, 0.0, clamp(nav_intrusion, 0.0, 1.0))
    _sfx_player.play()


func _trigger_memory_bleed_overlay(duration: float = 2.0) -> void:
    if _memory_bleed_layer.has_method("play_bleed"):
        _memory_bleed_layer.call("play_bleed", duration, nav_intrusion)
