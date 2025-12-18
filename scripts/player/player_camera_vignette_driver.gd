extends Node3D

@export var glitch_layer_path: NodePath
@export var world_offset_scale: float = 0.01
@export var update_rate: float = 0.1

var _accum: float = 0.0
var _glitch_layer: Node = null

func _ready() -> void:
    if glitch_layer_path and glitch_layer_path != "":
        _glitch_layer = get_node_or_null(glitch_layer_path)
    else:
        # Try to find first hud_neurochip node and its GlitchLayer child
        var candidates := get_tree().get_nodes_in_group("hud_neurochip")
        for c in candidates:
            if c and c.has_node("GlitchLayer"):
                _glitch_layer = c.get_node("GlitchLayer")
                break

func _process(delta: float) -> void:
    if not _glitch_layer:
        return
    _accum += delta
    if _accum < update_rate:
        return
    _accum = 0.0

    var wp := global_transform.origin
    var world_vec := Vector2(wp.x, wp.z) * world_offset_scale

    if _glitch_layer and _glitch_layer is CanvasItem and _glitch_layer.material and _glitch_layer.material is ShaderMaterial:
        var mat := _glitch_layer.material as ShaderMaterial
        if mat.shader_has_param("world_offset"):
            mat.set_shader_parameter("world_offset", world_vec)
*** End Patch