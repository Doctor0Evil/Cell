extends AudioStreamPlayer
class_name HorrorAmbienceController

@export var fade_in_time := 3.0
@export var target_volume_db := -10.0
@export var ambient_channel := "facility_low_hum"

var _tween: Tween

func _ready() -> void:
    volume_db = -80.0
    _load_stream()
    if stream:
        play()
        _fade_in()

func _load_stream() -> void:
    var path := HorrorAssetRegistry.get_ambient(ambient_channel)
    if path == "":
        return
    stream = load(path)

func _fade_in() -> void:
    if _tween:
        _tween.kill()
    _tween = get_tree().create_tween()
    _tween.tween_property(self, "volume_db", target_volume_db, fade_in_time)

func switch_ambient(new_channel: String, crossfade_time: float = 4.0) -> void:
    ambient_channel = new_channel
    if _tween:
        _tween.kill()
    var t := get_tree().create_tween()
    t.tween_property(self, "volume_db", -80.0, crossfade_time * 0.5)
    t.tween_callback(_on_faded_out)
    t.tween_property(self, "volume_db", target_volume_db, crossfade_time * 0.5)

func _on_faded_out() -> void:
    stop()
    _load_stream()
    if stream:
        play()
