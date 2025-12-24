extends Control
class_name HUDNeurochipOverlay

@export var max_alpha: float = 0.65
@export var decay_per_second: float = 1.5
@export var min_oxygen_seconds: float = 0.0
@export var max_oxygen_seconds: float = 60.0

@export var send_audio_bus_flag: bool = true
@export var audio_bus_parameter: StringName = &"hallucination_intensity"

var glitch_layer: CanvasItem = null
var hallucination_intensity: float = 0.0
var _tween: Tween = null

func _ready() -> void:
    # Find a child named 'GlitchLayer' (ColorRect / CanvasItem) and prepare it
    glitch_layer = get_node_or_null("GlitchLayer") if has_node("GlitchLayer") else null
    if glitch_layer:
        var c := glitch_layer.modulate
        c.a = 0.0
        glitch_layer.modulate = c

    add_to_group("runtime")
    add_to_group("hud_neurochip")

    # The overlay is discoverable via group 'hud_neurochip' and will be driven by PlayerStatus relay.
    # If you need direct autoload connection for testing, uncomment the line below.
    # if typeof(RadioTransmissions) != TYPE_NIL:
    #     RadioTransmissions.connect("hallucination_pulse", Callable(self, "_on_hallucination_pulse"))

    # If the GlitchLayer already has a ShaderMaterial, set sensible defaults for tuning so designers get
    # the expected vignette/scanline behavior without opening the inspector.
    if glitch_layer and glitch_layer.material and glitch_layer.material is ShaderMaterial:
        var mat := glitch_layer.material as ShaderMaterial
        if mat.shader_has_param("vignette_inner"):
            mat.set_shader_parameter("vignette_inner", 0.25)
        if mat.shader_has_param("vignette_outer"):
            mat.set_shader_parameter("vignette_outer", 0.95)
        if mat.shader_has_param("time_scale"):
            mat.set_shader_parameter("time_scale", 1.0)
        # New shader params defaults
        if mat.shader_has_param("chromatic_strength"):
            mat.set_shader_parameter("chromatic_strength", 0.0)
        if mat.shader_has_param("world_scale"):
            mat.set_shader_parameter("world_scale", 0.1)
        if mat.shader_has_param("low_quality"):
            mat.set_shader_parameter("low_quality", false)
        # Ensure overlay does not block input when used as a ColorRect
        if glitch_layer is Control:
            glitch_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
            glitch_layer.focus_mode = Control.FOCUS_NONE

func _process(delta: float) -> void:
    if hallucination_intensity <= 0.0:
        return
    hallucination_intensity = max(0.0, hallucination_intensity - decay_per_second * delta)
    _update_visuals()

func on_radio_hallucination_pulse(oxygen_seconds: float) -> void:
    _on_hallucination_pulse(oxygen_seconds)

func _on_hallucination_pulse(oxygen_seconds: float) -> void:
    var t := clamp((oxygen_seconds - min_oxygen_seconds) / max(0.01, max_oxygen_seconds - min_oxygen_seconds), 0.0, 1.0)
    var severity := 1.0 - t
    hallucination_intensity = clamp(hallucination_intensity + severity * 0.45, 0.0, 1.0)
    _update_visuals()
    # Small chromatic pulse when suffocation is severe
    if oxygen_seconds <= 20.0:
        pulse_chromatic(0.8, 0.5)

func pulse_chromatic(strength: float, duration: float = 0.4) -> void:
    if not glitch_layer or not (glitch_layer.material is ShaderMaterial):
        return
    var mat := glitch_layer.material as ShaderMaterial
    if _tween and _tween.is_valid():
        _tween.kill()
    _tween = get_tree().create_tween()
    var half := duration * 0.5
    _tween.tween_method(
        func(v: float):
            if mat.shader_has_param("chromatic_strength"):
                mat.set_shader_parameter("chromatic_strength", v),
        0.0,
        strength,
        half
    )
    _tween.tween_method(
        func(v: float):
            if mat.shader_has_param("chromatic_strength"):
                mat.set_shader_parameter("chromatic_strength", v),
        strength,
        0.0,
        half
    )

func set_low_quality(flag: bool) -> void:
    if not glitch_layer or not (glitch_layer.material is ShaderMaterial):
        return
    var mat := glitch_layer.material as ShaderMaterial
    if mat.shader_has_param("low_quality"):
        mat.set_shader_parameter("low_quality", flag)

func _update_visuals() -> void:
    if not glitch_layer:
        return

    var base_color := glitch_layer.modulate
    base_color.a = max_alpha * hallucination_intensity
    glitch_layer.modulate = base_color

    if glitch_layer.material and glitch_layer.material is ShaderMaterial:
        var mat := glitch_layer.material as ShaderMaterial
        if mat.shader_has_param("distortion_amount"):
            mat.set_shader_parameter("distortion_amount", hallucination_intensity)
        if mat.shader_has_param("scanline_intensity"):
            mat.set_shader_parameter("scanline_intensity", hallucination_intensity * 0.75)
        if mat.shader_has_param("neurochip_bleed"):
            mat.set_shader_parameter("neurochip_bleed", hallucination_intensity)

    if send_audio_bus_flag and typeof(GameState) != TYPE_NIL:
        if GameState.has_method("set_ambience_param"):
            GameState.set_ambience_param(audio_bus_parameter, hallucination_intensity)
