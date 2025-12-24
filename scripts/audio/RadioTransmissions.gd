extends Node
class_name RadioTransmissions

signal hallucination_pulse(oxygen_seconds: float)

@onready var radio_static: AudioStreamPlayer = $RadioStatic if has_node("RadioStatic") else null
@onready var voice_signal: AudioStreamPlayer = $VoiceSignal if has_node("VoiceSignal") else null

var is_active: bool = false
var signal_strength: float = 0.0
var last_oxygen_seconds: float = 999.0

var _hallucination_timer: float = 0.0

var _phrases_critical := [
	"we're using your memories...",
	"this isn't static, it's you...",
	"breathe slower... there is no air...",
	"we kept them alive in the lower decks...",
]

var _phrases_terminal := [
	"they're already inside your lungs...",
	"this isn't a rescue, it's an autopsy...",
	"you died in the pod. this is playback...",
	"stop fighting it. join the others...",
]

func _ready() -> void:
	randomize()
	_hallucination_timer = 0.0
	# Allow assets to be absent in the editor; load if present
	if radio_static == null and ResourceLoader.exists("res://audio/static_loop.ogg"):
		radio_static = AudioStreamPlayer.new()
		radio_static.stream = preload("res://audio/static_loop.ogg")
		add_child(radio_static)

	if voice_signal == null and ResourceLoader.exists("res://audio/transmissions/distress_recording_01.ogg"):
		voice_signal = AudioStreamPlayer.new()
		voice_signal.stream = preload("res://audio/transmissions/distress_recording_01.ogg")
		add_child(voice_signal)

func reset_state() -> void:
	is_active = false
	signal_strength = 0.0
	last_oxygen_seconds = 999.0
	_hallucination_timer = 0.0
	if radio_static and radio_static.playing:
		radio_static.stop()
	if voice_signal and voice_signal.playing:
		voice_signal.stop()

func set_oxygen_state(oxygen_seconds: float, is_suffocating: bool, is_alive: bool) -> void:
	last_oxygen_seconds = oxygen_seconds
	if not is_alive:
		reset_state()
		return

	if is_suffocating:
		if not is_active:
			_start_broadcast()
		var t := clamp(1.0 - (oxygen_seconds / 35.0), 0.0, 1.0)
		signal_strength = lerp(0.3, 1.0, t)
	else:
		signal_strength = max(signal_strength - 0.5 * get_process_delta_time(), 0.0)
		if signal_strength <= 0.05:
			reset_state()

func _start_broadcast() -> void:
	is_active = true
	_hallucination_timer = randf_range(2.5, 5.0)
	if radio_static and not radio_static.playing:
		radio_static.volume_db = -10.0
		radio_static.play()

func _process(delta: float) -> void:
	if not is_active:
		return

	_hallucination_timer -= delta
	if radio_static:
		radio_static.volume_db = lerp(-24.0, -4.0, signal_strength)

	if _hallucination_timer <= 0.0:
		_emit_hallucination()
		_hallucination_timer = randf_range(3.0, 7.0)

func _emit_hallucination() -> void:
	var pool := _phrases_critical
	if last_oxygen_seconds <= 10.0:
		pool = _phrases_terminal

	var phrase := pool.pick_random()
	emit_signal("hallucination_pulse", last_oxygen_seconds)
	DebugLog.log("RadioTransmissions", "HALLUCINATION", {"phrase": phrase, "oxygen_seconds": last_oxygen_seconds})

	if voice_signal:
		voice_signal.volume_db = -6.0
		voice_signal.pitch_scale = randf_range(0.9, 1.1)
		voice_signal.play()

func trigger_hallucination_pulse(oxygen_seconds: float = -1.0) -> void:
	# For editor/testing: emit a pulse with a specific oxygen value (or the last known value)
	var oxy := last_oxygen_seconds
	if oxygen_seconds >= 0.0:
		oxy = oxygen_seconds
	emit_signal("hallucination_pulse", oxy)
	DebugLog.log("RadioTransmissions", "TRIGGER_PULSE", {"oxy": oxy})
