extends AudioStreamPlayer
class_name ExtremeHorrorAmbiencePlayer

@export var fade_in_time: float = 4.0
@export var fade_out_time: float = 3.0
@export var target_volume_db: float = -10.0
@export var audio_bus: String = "AMBIENT_RAW"  # Routed through AMBIENT_RAW → BLOOD_ROOM / VENT, etc.

@export var initial_ambience_id: String = "facility_low_hum"

var _tween: Tween
var _current_id: String = ""
var _current_base_tempo: float = 1.0
var _intensity_min: float = 0.1
var _intensity_max: float = 1.0

# Debug / test override. If not null, this value is used instead of GameState-derived tension.
var _debug_tension_override: float = -1.0

# Optional region id for telemetry and region-specific rules
var region_id: StringName = &""

func _ready() -> void:
    bus = audio_bus
    volume_db = -80.0
    autoplay = false
    _switch_to(initial_ambience_id, true)

func _process(delta: float) -> void:
    # Allow manual override for testing.
    var tension := 0.0
    if _debug_tension_override >= 0.0 and _debug_tension_override <= 1.0:
        tension = clamp(_debug_tension_override, 0.0, 1.0)
    else:
        # Drive tempo/tone from GameState tension (alert + 1 - sanity).
        tension = clamp(GameState.alert_level + (1.0 - GameState.player_sanity), 0.0, 1.0)
    _apply_tension_to_playback(tension)

# Start/stop helpers for simple API
func start_ambience() -> void:
    _switch_to(_current_id if _current_id != "" else initial_ambience_id, false)

func stop_ambience(fade_time: float = 1.0) -> void:
    if _tween:
        _tween.kill()
    _tween = get_tree().create_tween()
    _tween.tween_property(self, "volume_db", -80.0, fade_time)
    _tween.tween_callback(Callable(self, "stop"))

func set_debug_tension_override(value: float) -> void:
    # value in [0,1], set negative to clear override
    if value >= 0.0 and value <= 1.0:
        _debug_tension_override = value
    else:
        _debug_tension_override = -1.0

func _apply_tension_to_playback(tension: float) -> void:
    if stream == null:
        return

    var local_intensity := lerp(_intensity_min, _intensity_max, tension)
    # Pitch slightly speeds up with tension; never fully chipmunk.
    pitch_scale = lerp(_current_base_tempo, _current_base_tempo * 1.25, local_intensity)

    # Subtle volume rise with tension; main dynamic range still done on buses.
    var target_db := lerp(target_volume_db - 4.0, target_volume_db + 2.0, local_intensity)
    volume_db = target_db

    # Optional glitch pulse when near maximum tension.
    if tension > 0.85 and randi() % 240 == 0:
        _glitch_pulse(-6.0, 0.6)

func _glitch_pulse(delta_db: float, duration: float) -> void:
    if _tween:
        _tween.kill()
    _tween = get_tree().create_tween()
    var mid_db := target_volume_db + delta_db
    _tween.tween_property(self, "volume_db", mid_db, duration * 0.5)
    _tween.tween_property(self, "volume_db", target_volume_db, duration * 0.5)

# Layered loops and one-shot stingers
var _loop_players: Dictionary = {} # id -> AudioStreamPlayer
var _layer_weights: Dictionary = {} # id -> float (0..1)
var _stinger_streams: Dictionary = {} # id -> AudioStream
var _target_tension_override: float = -1.0
var _world_tension_bias: float = 0.0

func get_base_tension() -> float:
    return (_intensity_min + _intensity_max) * 0.5

func set_target_tension(value: float) -> void:
    _target_tension_override = clamp(value, 0.0, 1.0)

func set_world_tension_bias(value: float) -> void:
    _world_tension_bias = clamp(value, -1.0, 1.0)

# Register loop by id and stream path (path optional if using LicenseAwareAssetRegistry)
func register_loop(id: StringName, path_or_asset: String) -> void:
    var stream: AudioStream = null
    if ResourceLoader.exists(path_or_asset):
        stream = ResourceLoader.load(path_or_asset)
    else:
        # Try license-aware registry
        stream = LicenseAwareAssetRegistry.get_asset(String(path_or_asset)) if LicenseAwareAssetRegistry else null
    if stream == null:
        DebugLog.log("ExtremeHorrorAmbiencePlayer", "REGISTER_LOOP_FAILED", {"id": id, "path": path_or_asset})
        return
    var player := AudioStreamPlayer.new()
    player.stream = stream
    player.bus = audio_bus
    player.volume_db = -80.0
    player.autoplay = false
    player.name = "Loop_%s" % id
    add_child(player)
    player.play()
    _loop_players[id] = player
    _layer_weights[id] = 0.0

func register_stinger(id: StringName, path_or_asset: String) -> void:
    var stream: AudioStream = null
    if ResourceLoader.exists(path_or_asset):
        stream = ResourceLoader.load(path_or_asset)
    else:
        stream = LicenseAwareAssetRegistry.get_asset(String(path_or_asset)) if LicenseAwareAssetRegistry else null
    if stream == null:
        DebugLog.log("ExtremeHorrorAmbiencePlayer", "REGISTER_STINGER_FAILED", {"id": id, "path": path_or_asset})
        return
    _stinger_streams[id] = stream

func set_layer_weight(id: StringName, weight: float) -> void:
    weight = clamp(weight, 0.0, 1.0)
    _layer_weights[id] = weight
    if _loop_players.has(id):
        var p: AudioStreamPlayer = _loop_players[id]
        # map weight -> volume between -80 and target_volume_db
        var db := lerp(-80.0, target_volume_db, weight)
        p.volume_db = db

func play_stinger(id: StringName) -> void:
    if not _stinger_streams.has(id):
        return
    var stream := _stinger_streams[id]
    var p := AudioStreamPlayer.new()
    p.stream = stream
    p.bus = audio_bus
    p.autoplay = false
    add_child(p)
    p.play()
    # cleanup when done
    p.connect("finished", Callable(p, "queue_free"))

# Overriding process to consider target/world tension if set
func _process(delta: float) -> void:
    var tension := 0.0
    if _debug_tension_override >= 0.0 and _debug_tension_override <= 1.0:
        tension = clamp(_debug_tension_override, 0.0, 1.0)
    elif _target_tension_override >= 0.0:
        tension = clamp(_target_tension_override + _world_tension_bias, 0.0, 1.0)
    else:
        tension = clamp(GameState.alert_level + (1.0 - GameState.player_sanity) + _world_tension_bias, 0.0, 1.0)
    _apply_tension_to_playback(tension)

# Existing switch_ambience still works for single-track style ambience
func switch_ambience(ambience_id: String, crossfade_time: float = 4.0) -> void:
    if ambience_id == _current_id:
        return

    var def := HorrorAmbienceRegistry.get_definition(ambience_id)
    if def.is_empty():
        return

    _current_id = ambience_id
    _current_base_tempo = float(def.get("base_tempo", 1.0))
    var range: Vector2 = def.get("intensity_range", Vector2(0.1, 1.0))
    _intensity_min = range.x
    _intensity_max = range.y

    var new_stream := HorrorAmbienceRegistry.get_stream_for(ambience_id)
    if new_stream == null:
        return

    if _tween:
        _tween.kill()
    _tween = get_tree().create_tween()

    _tween.tween_property(self, "volume_db", -80.0, crossfade_time * 0.5)
    _tween.tween_callback(Callable(self, "_on_faded_out").bind(new_stream))
    _tween.tween_property(self, "volume_db", target_volume_db, crossfade_time * 0.5)

func _on_faded_out(new_stream: AudioStream) -> void:
    if playing:
        stop()
    stream = new_stream
    if stream:
        play()

func _switch_to(ambience_id: String, immediate: bool) -> void:
    var def := HorrorAmbienceRegistry.get_definition(ambience_id)
    if def.is_empty():
        return

    _current_id = ambience_id
    _current_base_tempo = float(def.get("base_tempo", 1.0))
    var range: Vector2 = def.get("intensity_range", Vector2(0.1, 1.0))
    _intensity_min = range.x
    _intensity_max = range.y

    var new_stream := HorrorAmbienceRegistry.get_stream_for(ambience_id)
    if new_stream == null:
        return

    stream = new_stream
    if immediate:
        volume_db = target_volume_db
        play()
    else:
        volume_db = -80.0
        play()
        _glitch_pulse(-4.0, fade_in_time)
