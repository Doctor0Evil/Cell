extends CharacterBody3D
class_name PlayerController

@export var speed := 4.0
@export var sprint_multiplier := 1.6

func _ready() -> void:
    add_to_group("runtime")

func _physics_process(delta: float) -> void:
    var dir := Vector3.ZERO
    if Input.is_action_pressed("move_forward"):
        dir -= transform.basis.z
    if Input.is_action_pressed("move_backward"):
        dir += transform.basis.z
    if Input.is_action_pressed("move_left"):
        dir -= transform.basis.x
    if Input.is_action_pressed("move_right"):
        dir += transform.basis.x
    if dir != Vector3.ZERO:
        dir = dir.normalized()
        var sp := speed * (sprint_multiplier if Input.is_action_pressed("sprint") else 1.0)
        velocity.x = dir.x * sp
        velocity.z = dir.z * sp
    else:
        velocity.x = move_toward(velocity.x, 0, 10 * delta)
        velocity.z = move_toward(velocity.z, 0, 10 * delta)
    velocity = move_and_slide()
