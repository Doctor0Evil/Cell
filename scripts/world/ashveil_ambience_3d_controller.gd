@tool
extends Node3D
class_name AshveilAmbience3DController

# 3D, non-breaking Ashveil ambience controller for live mixing across buses.
# Attach to an Ashveil level Node3D and wire child AudioStreamPlayer3D nodes
# into the exported player slots. Recommended buses: "AshveilBase", "AshveilMid",
# "AshveilEvent", "AshveilCollapse". Works with GameState and DebugLog.

@export var base_player: AudioStreamPlayer3D
@export var mid_players: Array[AudioStreamPlayer3D]
@export var event_players: Array[AudioStreamPlayer3D]
@export var collapse_players: Array[AudioStreamPlayer3D]

@export var base_bus: StringName = &"AshveilBase"
@export var mid_bus: StringName = &"AshveilMid"
@export var event_bus: StringName = &"AshveilEvent"
@export var collapse_bus: StringName = &"AshveilCollapse"

@export var min_roar_interval: float = 22.0
@export var max_roar_interval: float = 55.0
@export var min_small_creak_interval: float = 6.0
@export var max_small_creak_interval: float = 14.0

# Tuning: ranges and curves
@export var roar_volume_db_range: Vector2 = Vector2(-20.0, -9.0)
@export var creak_volume_db_range: Vector2 = Vector2(-20.0, -10.0)
@export var roar_pitch_range: Vector2 = Vector2(0.8, 1.05)

@export var roar_volume_curve: Curve
@export var creak_volume_curve: Curve
@export var roar_pitch_curve: Curve
@export var creak_pitch_curve: Curve
@export var creak_pitch_range: Vector2 = Vector2(0.95, 1.05)

# How much intensity shortens timing (0..1). 0 = no change, 1 = full shortening.
@export var timing_intensity_bias: float = 0.35

var _next_roar_time: float = 0.0
var _next_creak_time: float = 0.0
var _time_accum: float = 0.0
var _rng := RandomNumberGenerator.new()

@export var region_id: StringName = &""
@export var preview_profile_id: StringName = &""

@export var auto_bind_on_ready: bool = true
@export var loops_folder: String = "res://audio/loops"
@export var stingers_folder: String = "res://audio/stingers"

var _last_roar_player_name: String = ""
var _last_creak_player_name: String = ""

@export var inspector_bound_player_streams: Dictionary = {}

var _editor_update_accum: float = 0.0
var _editor_update_interval: float = 0.5

func get_effective_intensity() -> float:
	return clamp(GameState.alert_level + (1.0 - GameState.player_sanity), 0.0, 1.0)

func get_last_roar_player_name() -> String:
	return _last_roar_player_name

func get_last_creak_player_name() -> String:
	return _last_creak_player_name

func get_next_roar_in() -> float:
	return max(0.0, _next_roar_time - _time_accum)

func get_next_creak_in() -> float:
	return max(0.0, _next_creak_time - _time_accum)

func refresh_inspector_bindings() -> void:
	# Public method callable from the editor to refresh the Inspector view
	_update_bound_player_streams()
	DebugLog.log("AshveilAmbience3D", "INSPECTOR_REFRESH", {"bindings": inspector_bound_player_streams})
# Auto-bind production assets to players by filename convention.
func auto_bind_assets(loop_folder: String = "", stinger_folder: String = "") -> void:
	var lf := loop_folder if loop_folder != "" else loops_folder
	var sf := stinger_folder if stinger_folder != "" else stingers_folder
	var candidates: Array = []
	func _scan_folder(folder: String) -> Array:
		var da := DirAccess.open(folder)
		if da == null:
			return []
		var files: Array = []
		da.list_dir_begin()
		var fn := da.get_next()
		while fn != "":
			if da.current_is_dir():
				fn = da.get_next()
				continue
			var lname := fn.to_lower()
			if lname.ends_with(".ogg") or lname.ends_with(".wav") or lname.ends_with(".mp3"):
				files.append(folder + "/" + fn)
			fn = da.get_next()
		da.list_dir_end()
		return files
	candidates += _scan_folder(lf)
	candidates += _scan_folder(sf)

	func _find_match_for_player(player_name: String, files: Array) -> String:
		var lname := player_name.to_lower()
		# direct substring match
		for p in files:
			var fname := p.get_slice("/", -1).to_lower()
			if lname in fname:
				return p
		# token heuristics
		var tokens := ["base", "mid", "event", "collapse", "roar", "stinger", "petrified", "promenade", "heat", "whisper"]
		for t in tokens:
			if t in lname:
				for p in files:
					if t in p.get_slice("/", -1).to_lower():
						return p
		# fallback: return first matching type-appropriate file
		if files.size() > 0:
			return files[0]
		return ""

	# Use an available list so we avoid binding the same asset to multiple players when possible
	var available := candidates.duplicate()
	# Clear inspector bindings first
	inspector_bound_player_streams.clear()

	if base_player and base_player.stream == null:
		var pth := _find_match_for_player(base_player.name, available)
		if pth != "":
			base_player.stream = ResourceLoader.load(pth)
			inspector_bound_player_streams[base_player.name] = pth
			available.erase(pth)
			DebugLog.log("AshveilAmbience3D", "AUTO_BIND", {"player": base_player.name, "path": pth})

	for player in mid_players:
		if player and player.stream == null:
			var pth := _find_match_for_player(player.name, available)
			if pth != "":
				player.stream = ResourceLoader.load(pth)
				inspector_bound_player_streams[player.name] = pth
				available.erase(pth)
				DebugLog.log("AshveilAmbience3D", "AUTO_BIND", {"player": player.name, "path": pth})

	for player in collapse_players:
		if player and player.stream == null:
			var pth := _find_match_for_player(player.name, available)
			if pth != "":
				player.stream = ResourceLoader.load(pth)
				inspector_bound_player_streams[player.name] = pth
				available.erase(pth)
				DebugLog.log("AshveilAmbience3D", "AUTO_BIND", {"player": player.name, "path": pth})

	for player in event_players:
		if player and player.stream == null:
			var pth := _find_match_for_player(player.name, available)
			if pth != "":
				player.stream = ResourceLoader.load(pth)
				inspector_bound_player_streams[player.name] = pth
				available.erase(pth)
				DebugLog.log("AshveilAmbience3D", "AUTO_BIND", {"player": player.name, "path": pth})

	# Ensure editor shows new data
	_update_bound_player_streams()

func apply_region_profile(hazard_profile: Dictionary, difficulty: int) -> void:
	# Adjust timing and intensity heuristics based on region hazard profile.
	var stress := float(hazard_profile.get("oxygen_penalty", 0.0))
	stress = clamp(stress, 0.0, 1.0)
	min_roar_interval = max(4.0, lerp(min_roar_interval, min_roar_interval * 0.5, stress))
	max_roar_interval = max(8.0, lerp(max_roar_interval, max_roar_interval * 0.5, stress))
	var diff_bias := clamp(float(difficulty - 1) * 0.1, 0.0, 1.0)
	min_small_creak_interval = max(1.0, lerp(min_small_creak_interval, min_small_creak_interval * (1.0 - diff_bias), 0.5))
	max_small_creak_interval = max(2.0, lerp(max_small_creak_interval, max_small_creak_interval * (1.0 - diff_bias), 0.5))
	DebugLog.log("AshveilAmbience3D", "APPLY_REGION", {"stress": stress, "difficulty": difficulty})
	# show bindings that result from changes
	_update_bound_player_streams()

func start_ambience() -> void:
	if base_player and not base_player.playing:
		base_player.play()

func stop_ambience() -> void:
	if base_player and base_player.playing:
		base_player.stop()

func trigger_collapse_event() -> void:
	_play_random_roar()

func _ready() -> void:
	_rng.randomize()
	if base_player:
		base_player.bus = base_bus
		if not base_player.playing:
			base_player.play()
	for p in mid_players:
		if p:
			p.bus = mid_bus
	for p in event_players:
		if p:
			p.bus = event_bus
	for p in collapse_players:
		if p:
			p.bus = collapse_bus
	_schedule_next_roar()
	_schedule_next_creak()
	# Ensure default tuning curves exist (created in-editor if missing)
	_ensure_default_curves()
	# Apply preview profile at edit/test time
	if preview_profile_id != &"":
		var registry: Node = get_node_or_null("/root/CellContentRegistry")
		var region_def: Dictionary = {} if registry == null else registry.get_region(preview_profile_id)
		if region_def and region_def.size() > 0 and has_method("apply_region_profile"):
			apply_region_profile(region_def, int(region_def.get("difficulty", 1)))
	# Auto-bind if enabled
	if auto_bind_on_ready:
		auto_bind_assets()

func _process(delta: float) -> void:
	# Editor-time inspector updates
	if Engine.is_editor_hint():
		_editor_update_accum += delta
		if _editor_update_accum >= _editor_update_interval:
			_editor_update_accum = 0.0
			_update_bound_player_streams()
		return

	if GameState.is_paused:
		return
	_time_accum += delta
	if _time_accum >= _next_roar_time:
		_play_random_roar()
		_schedule_next_roar()
	if _time_accum >= _next_creak_time:
		_play_random_creak()
		_schedule_next_creak()

func trigger_evac_memory_event() -> void:
	if event_players.is_empty():
		return
	var p := event_players[_rng.randi_range(0, event_players.size() - 1)]
	if p and not p.playing:
		p.pitch_scale = _rng.randf_range(0.9, 1.05)
		p.volume_db = _rng.randf_range(-9.0, -3.0)
		p.play()

func _play_random_creak() -> void:
	if mid_players.is_empty():
		return
	var p := mid_players[_rng.randi_range(0, mid_players.size() - 1)]
	if not p:
		return
	if p.playing:
		return
	var intensity := get_effective_intensity()
	p.pitch_scale = _map_via_curve(creak_pitch_curve, creak_pitch_range, intensity)
	p.volume_db = _map_via_curve(creak_volume_curve, creak_volume_db_range, intensity)
	_last_creak_player_name = p.name if p else ""
	p.play()
	DebugLog.log("AshveilAmbience3D", "CREAK", {"time": _time_accum, "node": p.name})

# Duplicate creak handler removed; see the primary `_play_random_creak` implementation above.

func _map_via_curve(curve: Curve, range: Vector2, intensity: float) -> float:
	var t := clamp(intensity, 0.0, 1.0)
	if curve == null or curve.get_point_count() == 0:
		return lerp(range.x, range.y, t)
	var v := clamp(curve.sample(t), 0.0, 1.0)
	return lerp(range.x, range.y, v)

func _schedule_next_roar() -> void:
	# Shorten intervals with intensity (controlled by timing_intensity_bias)
	var intensity := get_effective_intensity()
	var shrink := clamp(1.0 - intensity * timing_intensity_bias, 0.2, 1.0)
	_next_roar_time = _time_accum + _rng.randf_range(min_roar_interval * shrink, max_roar_interval * shrink)

func _schedule_next_creak() -> void:
	var intensity := get_effective_intensity()
	var shrink := clamp(1.0 - intensity * timing_intensity_bias * 0.5, 0.3, 1.0)
	_next_creak_time = _time_accum + _rng.randf_range(min_small_creak_interval * shrink, max_small_creak_interval * shrink)

func preview_tuning_sweep(steps: int = 6) -> void:
	# Logs sampled tuning points across intensity so designers can inspect mappings
	if steps <= 0:
		steps = 6
	for i in range(steps):
		var t := float(i) / float(max(1, steps - 1))
		var r_db := _map_via_curve(roar_volume_curve, roar_volume_db_range, t)
		var r_pitch := _map_via_curve(roar_pitch_curve, roar_pitch_range, t)
		var c_db := _map_via_curve(creak_volume_curve, creak_volume_db_range, t)
		var c_pitch := _map_via_curve(creak_pitch_curve, creak_pitch_range, t)
		DebugLog.log("AshveilAmbience3D", "PREVIEW_TUNING", {"t": t, "roar_db": r_db, "roar_pitch": r_pitch, "creak_db": c_db, "creak_pitch": c_pitch})

# Editor helper: keep a Dictionary of bound streams for easy inspection
func _update_bound_player_streams() -> void:
	var d: Dictionary = {}
	if base_player:
		d[base_player.name] = base_player.stream.resource_path if base_player.stream else ""
	for p in mid_players:
		if p:
			d[p.name] = p.stream.resource_path if p.stream else ""
	for p in collapse_players:
		if p:
			d[p.name] = p.stream.resource_path if p.stream else ""
	for p in event_players:
		if p:
			d[p.name] = p.stream.resource_path if p.stream else ""
	inspector_bound_player_streams = d

func _ensure_default_curves() -> void:
	# Create sensible default curves for tuning if none are provided.
	var base_dir := "res://resources/ambience"
	# Roar volume: S-curve (restrained until mid, ramp near 0.7-1.0) — top compressed for smoother ramp
	if roar_volume_curve == null:
		var c := Curve.new()
		c.add_point(Vector2(0.0, 0.0))
		c.add_point(Vector2(0.5, 0.12))
		c.add_point(Vector2(0.75, 0.6))
		# slightly lower the 0.9 point to soften the top of the S-curve
		c.add_point(Vector2(0.9, 0.7))
		c.add_point(Vector2(1.0, 1.0))
		roar_volume_curve = c
		var pth := "%s/ashveil_roar_volume_curve.tres" % base_dir
		if Engine.is_editor_hint() and not ResourceLoader.exists(pth):
			ResourceSaver.save(c, pth)
			DebugLog.log("AshveilAmbience3D", "SAVE_CURVE", {"path": pth})

	# Roar pitch: gentle near-linear rise
	if roar_pitch_curve == null:
		var c2 := Curve.new()
		c2.add_point(Vector2(0.0, 0.0))
		c2.add_point(Vector2(0.5, 0.48))
		c2.add_point(Vector2(1.0, 1.0))
		roar_pitch_curve = c2
		var pth2 := "%s/ashveil_roar_pitch_curve.tres" % base_dir
		if Engine.is_editor_hint() and not ResourceLoader.exists(pth2):
			ResourceSaver.save(c2, pth2)
			DebugLog.log("AshveilAmbience3D", "SAVE_CURVE", {"path": pth2})

	# Creak volume: mild bump at mid intensity (slightly reduced bump)
	if creak_volume_curve == null:
		var c3 := Curve.new()
		c3.add_point(Vector2(0.0, 0.0))
		c3.add_point(Vector2(0.4, 0.35))
		c3.add_point(Vector2(0.7, 0.75))
		c3.add_point(Vector2(1.0, 1.0))
		creak_volume_curve = c3
		var pth3 := "%s/ashveil_creak_volume_curve.tres" % base_dir
		if Engine.is_editor_hint() and not ResourceLoader.exists(pth3):
			ResourceSaver.save(c3, pth3)
			DebugLog.log("AshveilAmbience3D", "SAVE_CURVE", {"path": pth3})

	# Creak pitch: very shallow uptick at high intensity
	if creak_pitch_curve == null:
		var c4 := Curve.new()
		c4.add_point(Vector2(0.0, 0.0))
		c4.add_point(Vector2(0.8, 0.03))
		c4.add_point(Vector2(1.0, 0.12))
		creak_pitch_curve = c4
		var pth4 := "%s/ashveil_creak_pitch_curve.tres" % base_dir
		if Engine.is_editor_hint() and not ResourceLoader.exists(pth4):
			ResourceSaver.save(c4, pth4)
			DebugLog.log("AshveilAmbience3D", "SAVE_CURVE", {"path": pth4})
