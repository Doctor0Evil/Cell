extends CharacterBody3D
class_name GrowlerBasicAI

@export var move_speed: float = 5.2
@export var zero_g_pounce_speed: float = 8.5
@export var hearing_radius: float = 18.0
@export var heartbeat_bias: float = 1.4
@export var aggression: float = 0.5

var _target: Node3D = null

func set_target(t: Node3D) -> void:
	_target = t

func boost_aggression_from_moon(intensity: float) -> void:
	aggression = clamp(aggression + 0.25 * intensity, 0.0, 1.0)

func _physics_process(delta: float) -> void:
	if _target == null:
		return
	var dir := (_target.global_transform.origin - global_transform.origin)
	var flat_dir := dir.normalized()
	velocity = flat_dir * lerp(move_speed, zero_g_pounce_speed, aggression)
	move_and_slide()
