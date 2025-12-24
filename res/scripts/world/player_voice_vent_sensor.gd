extends Node3D
class_name PlayerVoiceVentSensor

@export var listen_radius: float = 14.0
@export var loudness_threshold: float = 0.25
@export var vent_group: StringName = &"vent_listener"

# External: VentTabooHookBus should be available as an autoload
var _hook_bus: VentTabooHookBus = null

func _ready() -> void:
	_hook_bus = get_node_or_null("/root/VentTabooHookBus")
	add_to_group(&"runtime")

# Called by your dialogue/voice system when player speaks
func notify_player_voice(player: Node3D, phrase: String, loudness: float) -> void:
	if loudness < loudness_threshold:
		return
	# find nearest vent within radius
	var closest: Node = null
	var best_d := 1e9
	for v in get_tree().get_nodes_in_group(vent_group):
		if v is Node3D:
			var d := v.global_transform.origin.distance_to(player.global_transform.origin)
			if d <= listen_radius and d < best_d:
				closest = v
				best_d = d
	if closest != null and _hook_bus != null:
		_hook_bus.postplayervoice_route_to_vent_bus(closest.name, loudness)
		DebugLog.log("PlayerVoiceVentSensor", "PLAYER_SPOKE_NEAR_VENT", {
			"vent": str(closest.name),
			"loudness": loudness,
			"phrase": phrase
		})
