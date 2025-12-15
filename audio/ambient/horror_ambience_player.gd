extends AudioStreamPlayer

@export var fade_in_time := 3.0
@export var target_volume_db := -10.0

func _ready() -> void:
    volume_db = -80.0
    if stream:
        play()
        fade_in()

func fade_in() -> void:
    var tween := get_tree().create_tween()
    tween.tween_property(self, "volume_db", target_volume_db, fade_in_time)
