extends AudioStreamPlayer
class_name ExtremeHorrorAmbiencePlayer

@export var fade_in_time := 4.0
@export var target_volume_db := -10.0
@export var audio_bus := &"AMBIENT_RAW" # route to a bus chain with EQ/distortion

var _tween: Tween

func _ready() -> void:
    bus = audio_bus
    volume_db = -80.0
    if stream:
        play()
        _fade_in()

func _fade_in() -> void:
    if _tween:
        _tween.kill()
    _tween = get_tree().create_tween()
    _tween.tween_property(self, "volume_db", target_volume_db, fade_in_time)

func glitch_pulse(delta_db: float = -6.0, duration: float = 0.8) -> void:
    if _tween:
        _tween.kill()
    var t := get_tree().create_tween()
    t.tween_property(self, "volume_db", target_volume_db + delta_db, duration * 0.5)
    t.tween_property(self, "volume_db", target_volume_db, duration * 0.5)
