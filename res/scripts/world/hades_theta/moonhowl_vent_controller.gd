extends Node3D
class_name MoonhowlVentController

@export var lore_entry: LoreEntryMoonhowlEvent
@export var growler_scene: PackedScene
@export var vent_howl_sfx: AudioStream
@export var whisper_warning_sfx: AudioStream

@export var max_active_growlers: int = 6
@export var vent_listen_radius: float = 14.0
@export var heartbeat_vent_group: StringName = &"vent_listener"
@export var growler_spawn_points_group: StringName = &"growler_spawn"
@export var taboo_flag_id: StringName = &"TABSVENTSILENCE01"

# Optional editor metadata for scene wiring
@export var place_id: StringName = &"PLCORBITALHADES01"
@export var taboo_ids: PackedStringArray = ["TABSVENTSILENCE01"]
@export var scene_id: StringName = &"SCN-HADES-VENT-TABOO-02"

var _active_growlers: Array = []
var _vent_nodes: Array = []
var _spawn_points: Array = []
var _taboo_broken: bool = false

func _ready() -> void:
	add_to_group(&"runtime")
	_collect_world_refs()
	DebugLog.log("MoonhowlVentController", "READY", {
		"vent_count": _vent_nodes.size(),
		"spawn_points": _spawn_points.size(),
		"event_id": str(lore_entry.event_id if lore_entry else "NONE")
	})

func _collect_world_refs() -> void:
	_vent_nodes.clear()
	_spawn_points.clear()
	for n in get_tree().get_nodes_in_group(heartbeat_vent_group):
		if n is Node3D:
			_vent_nodes.append(n)
	for n in get_tree().get_nodes_in_group(growler_spawn_points_group):
		if n is Node3D:
			_spawn_points.append(n)

func on_player_spoke_near_vent(player: Node3D, vent: Node3D, phrase: String) -> void:
	if _taboo_broken:
		return
	_taboo_broken = true
	GameState.alertlevel = clamp(GameState.alertlevel + 0.25, 0.0, 1.0)
	GameState.playersanity = clamp(GameState.playersanity - 0.1, 0.0, 1.0)
	DebugLog.log("MoonhowlVentController", "TABOO_BROKEN", {
		"taboo": str(taboo_flag_id),
		"vent": vent.name,
		"phrase": phrase
	})
	_play_vent_response(vent)
	_schedule_growler_hunt(player)

func _play_vent_response(vent: Node3D) -> void:
	var howl_player := AudioStreamPlayer3D.new()
	howl_player.stream = vent_howl_sfx
	howl_player.bus = "RES_SOUNDBUS_VENTS"
	add_child(howl_player)
	howl_player.global_transform.origin = vent.global_transform.origin
	howl_player.play()

	var whisper_player := AudioStreamPlayer3D.new()
	whisper_player.stream = whisper_warning_sfx
	whisper_player.bus = "RES_SOUNDBUS_VENTS"
	add_child(whisper_player)
	whisper_player.global_transform.origin = vent.global_transform.origin
	whisper_player.play()

func _schedule_growler_hunt(player: Node3D) -> void:
	if _spawn_points.empty() or growler_scene == null:
		DebugLog.log("MoonhowlVentController", "SPAWN_SKIPPED", {
			"reason": "NO_SPAWN_POINTS_OR_SCENE"
		})
		return

	var spawn_count := min(3, max_active_growlers - _active_growlers.size())
	for i in range(spawn_count):
		var sp := _spawn_points[randi() % _spawn_points.size()]
		_spawn_growler_at(sp, player)

func _spawn_growler_at(spawn_point: Node3D, player: Node3D) -> void:
	var g := growler_scene.instantiate()
	get_tree().get_current_scene().add_child(g)
	if g is Node3D:
		(g as Node3D).global_transform.origin = spawn_point.global_transform.origin
	g.add_to_group(&"enemy_growler")

	if g.has_method("set_target"):
		g.call("set_target", player)

	_active_growlers.append(g)
	g.tree_exited.connect(func() -> void:
		_active_growlers.erase(g))

	DebugLog.log("MoonhowlVentController", "GROWLER_SPAWNED", {
		"position": spawn_point.global_transform.origin,
		"active_count": _active_growlers.size()
	})

func pulse_long_night(delta: float, moon_intensity: float) -> void:
	GameState.oxygendrainrate = max(1.0, GameState.oxygendrainrate + 0.05 * moon_intensity * delta)
	GameState.currentregionstress += 0.02 * moon_intensity * delta
	for g in _active_growlers:
		if g and g.has_method("boost_aggression_from_moon"):
			g.call("boost_aggression_from_moon", moon_intensity)
