extends Node

export(float) var evp_threshold: float = 0.25

onready var radio := $RadioTransmissions
onready var narrative_db := $NarrativeDB
onready var evp_player := $EVPPlayer

var _evp_triggered: bool = false

func _ready() -> void:
    # Start with a randomized distress variant for atmospheric demo
    if radio and radio.has_method("play_random_distress_variant"):
        radio.play_random_distress_variant()

    # Monitor nav_intrusion changes
    if radio:
        radio.connect("nav_intrusion_changed", self, "_on_nav_intrusion_changed")

    # Optionally force the player zone (demo only)
    if radio and radio.has_method("set_player_zone"):
        radio.set_player_zone(radio.PLAYER_ZONE.LAB)


func _on_nav_intrusion_changed(value: float) -> void:
    if value >= evp_threshold and not _evp_triggered:
        _evp_triggered = true
        _play_random_evp()


func _play_random_evp() -> void:
    var data := narrative_db.load_json("res://narratives/hallucinations/evp_micro_lines.json")
    var lines := data.get("lines", [])
    if lines.size() == 0:
        print("No EVP lines found")
        return
    var idx := randi() % lines.size()
    var chosen := lines[idx]
    var clip_path := chosen.get("audio_clip", "")
    if clip_path == "":
        print("EVP line missing audio_clip")
        return
    var stream := load(clip_path)
    if stream == null:
        print("Failed to load EVP audio: %s" % clip_path)
        return
    evp_player.stream = stream
    evp_player.play()
