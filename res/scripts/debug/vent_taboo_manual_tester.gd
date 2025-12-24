extends Node
class_name VentTabooManualTester

@export var player_sensor_path: NodePath
@export var vent_node_path: NodePath
@export var test_loudness: float = 0.85

func _ready() -> void:
	add_to_group("runtime_debug")
	DebugLog.log("VentTabooManualTester", "READY", {
		"sensor_path": str(player_sensor_path),
		"vent_path": str(vent_node_path)
	})

func trigger_test_once() -> void:
	var sensor := get_node_or_null(player_sensor_path)
	var vent := get_node_or_null(vent_node_path)
	if sensor == null or vent == null:
		DebugLog.log("VentTabooManualTester", "MISSING_NODES", {
			"sensor": str(player_sensor_path),
			"vent": str(vent_node_path)
		})
		return

	if not sensor.has_method("notify_player_voice"):
		DebugLog.log("VentTabooManualTester", "NO_NOTIFY_METHOD", {})
		return

	# Try to resolve a player node (sensor is expected to be child of Player)
	var player_node := sensor.get_parent()
	if player_node == null:
		DebugLog.log("VentTabooManualTester", "NO_PLAYER_PARENT", {})
		return

	# Call the sensor with a short test phrase and loudness so normal processing occurs
	sensor.notify_player_voice(player_node, "[TEST VOICE]", test_loudness)
	DebugLog.log("VentTabooManualTester", "TRIGGERED", {
		"loudness": test_loudness,
		"vent": str(vent.name)
	})
