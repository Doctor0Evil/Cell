extends Node
class_name VentTabooHookBus

@export var vent_howl_bus_name: StringName = &"RES_SOUNDBUS_VENTS"
@export var vent_lockon_sfx_id: StringName = &"VENT_HISS_LOCKON"
@export var desaturate_layer_name: StringName = &"PostFXLayer_Main"
@export var oxygen_warning_threshold: float = 0.28

var _growler_attraction_bias: float = 0.0
var _last_vent_event_time: float = 0.0

func _ready() -> void:
	_add_to_group("runtime_hooks")
	DebugLog.log("VentTabooHookBus", "INIT", {
		"vent_bus": str(vent_howl_bus_name),
		"lockon_sfx": str(vent_lockon_sfx_id)
	})

# === YAML hook entrypoints =========================================
# Names mirror SCN-HADES-VENT-TABOO-02.yaml systemhooks

func postplayervoice_route_to_vent_bus(vent_id: StringName, loudness: float) -> void:
	_last_vent_event_time = Time.get_unix_time_from_system()
	_route_voice_to_vent_bus(vent_id, loudness)
	_flag_taboo_break(vent_id, loudness)

func screen_desaturate_0_15_over_2s() -> void:
	_apply_screen_desaturation(0.15, 2.0)

func flash_oxygen_warning_once() -> void:
	_flash_oxygen()

func play_sfx_VENT_HISS_LOCKON(at_vent_id: StringName) -> void:
	_play_lockon_sfx(at_vent_id)

func reroute_growler_paths_toward_player_deck(deck_id: StringName, weight: float = 1.0) -> void:
	_bias_growler_routing(deck_id, weight)

# === Implementations ================================================
func _route_voice_to_vent_bus(vent_id: StringName, loudness: float) -> void:
	# Hook into your audio routing; here we just log.
	DebugLog.log("VentTabooHookBus", "VOICE_TO_VENT", {
		"vent_id": str(vent_id),
		"loudness": loudness
	})

func _flag_taboo_break(vent_id: StringName, loudness: float) -> void:
	GameState.set_flag("TABSVENTSILENCE01_BROKEN", true)
	GameState.set_flag("TABSVENTSILENCE01_LAST_VENT", str(vent_id))
	GameState.set_flag("TABSVENTSILENCE01_LAST_LOUDNESS", loudness)
	DebugLog.log("VentTabooHookBus", "TABOO_BROKEN", {
		"vent": str(vent_id),
		"loudness": loudness
	})

func _apply_screen_desaturation(amount: float, duration: float) -> void:
	var fx_layer := get_tree().get_first_node_in_group(desaturate_layer_name)
	if fx_layer == null:
		DebugLog.log("VentTabooHookBus", "DESAT_MISSING_LAYER", {})
		return
	if not fx_layer.has_method("apply_desaturation"):
		DebugLog.log("VentTabooHookBus", "DESAT_NO_METHOD", {})
		return
	fx_layer.apply_desaturation(amount, duration)
	DebugLog.log("VentTabooHookBus", "DESAT_APPLIED", {
		"amount": amount,
		"duration": duration
	})

func _flash_oxygen() -> void:
	var status := get_tree().get_first_node_in_group("PlayerStatus")
	if status == null or not status.has_method("get_oxygen_ratio"):
		DebugLog.log("VentTabooHookBus", "OXY_WARN_NO_STATUS", {})
		return
	var ratio: float = status.get_oxygen_ratio()
	if ratio <= oxygen_warning_threshold:
		status.call_deferred("flash_oxygen_warning_once")
		DebugLog.log("VentTabooHookBus", "OXY_WARN_TRIGGERED", {
			"ratio": ratio
		})
	else:
		DebugLog.log("VentTabooHookBus", "OXY_WARN_SKIPPED", {
			"ratio": ratio
		})

func _play_lockon_sfx(vent_id: StringName) -> void:
	var sfx_player := get_tree().get_first_node_in_group("SFX_Vents")
	if sfx_player == null:
		DebugLog.log("VentTabooHookBus", "LOCKON_NO_SFX_PLAYER", {})
		return
	if sfx_player.has_method("play_event"):
		sfx_player.play_event(vent_lockon_sfx_id, vent_id)
	DebugLog.log("VentTabooHookBus", "LOCKON_PLAY", {
		"vent": str(vent_id),
		"event": str(vent_lockon_sfx_id)
	})

func _bias_growler_routing(deck_id: StringName, weight: float) -> void:
	_growler_attraction_bias = clampf(weight, 0.0, 3.0)
	var ai_director := get_tree().get_first_node_in_group("AIDirector")
	if ai_director and ai_director.has_method("set_growler_deck_bias"):
		ai_director.set_growler_deck_bias(deck_id, _growler_attraction_bias)
	DebugLog.log("VentTabooHookBus", "GROWLER_BIAS", {
		"deck": str(deck_id),
		"bias": _growler_attraction_bias
	})
