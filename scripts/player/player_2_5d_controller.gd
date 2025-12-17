extends CharacterBody3D
class_name Player2_5DController

@export var grid_size: int = 1
@export var snap_to_grid: bool = true
@export var move_speed: float = 3.0

var _target: Vector3 = Vector3.ZERO
var _moving: bool = false

func _ready() -> void:
    add_to_group("runtime")

func move_to_grid(coord: Vector2i) -> void:
    _target = Vector3(coord.x * grid_size, global_transform.origin.y, coord.y * grid_size)
    _moving = true

func _physics_process(delta: float) -> void:
    if _moving:
        var dir := (_target - global_transform.origin)
        if dir.length() < 0.05:
            global_transform.origin = _target
            _moving = false
        else:
            var step := dir.normalized() * move_speed * delta
            translate(step)

func get_current_grid() -> Vector2i:
    return Vector2i(round(global_transform.origin.x / grid_size), round(global_transform.origin.z / grid_size))

# Utility: snap current position to nearest grid tile
func snap_position_to_grid() -> void:
    if snap_to_grid:
        var g := get_current_grid()
        global_transform.origin = Vector3(g.x * grid_size, global_transform.origin.y, g.y * grid_size)
