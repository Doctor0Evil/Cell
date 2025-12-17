extends Control
class_name MissionHUD

@export var debug_enabled: bool = true

@onready var _objective_label: Label = $ObjectiveLabel
@onready var _oxygen_label: Label = $OxygenLabel

func _ready() -> void:
    add_to_group("runtime")
    _objective_label.text = ""
    _oxygen_label.text = ""
    # assign shader materials to overlays
    if has_node("VignetteRect"):
        var v := get_node("VignetteRect") as ColorRect
        var s := load("res://shaders/vignette.shader")
        var mat := ShaderMaterial.new()
        mat.shader = s
        v.material = mat
    if has_node("DesaturateRect"):
        var d := get_node("DesaturateRect") as ColorRect
        var s2 := load("res://shaders/desaturate.shader")
        var mat2 := ShaderMaterial.new()
        mat2.shader = s2
        d.material = mat2

    if debug_enabled:
        DebugLog.log("MissionHUD", "READY", {})

func on_objective_update(text: String) -> void:
    _objective_label.text = text
    if debug_enabled:
        DebugLog.log("MissionHUD", "OBJECTIVE_UPDATE", {"text": text})

func on_mission_oxygen_tick(data: Dictionary) -> void:
    var remaining := data.get("remaining", 0.0)
    _oxygen_label.text = "Oxygen remaining: %d" % int(remaining)
    if debug_enabled:
        DebugLog.log("MissionHUD", "OXYGEN_TICK", {"remaining": remaining})

func on_mission_update(data: Dictionary) -> void:
    # general mission events
    if debug_enabled:
        DebugLog.log("MissionHUD", "MISSION_EVENT", data)

func on_mission_started(region_id: String) -> void:
    _objective_label.text = "Mission started: %s" % region_id

func on_mission_complete(info: Dictionary) -> void:
    _objective_label.text = "Mission complete"

func on_mission_failed(info: Dictionary) -> void:
    _objective_label.text = "Mission failed: %s" % info.get("reason", "")

# --- Low-state UI cues ---
var _oxygen_low_active: bool = false
var _temp_low_active: bool = false
var _oxygen_tween: Tween
var _objective_tween: Tween

func on_low_oxygen(data: Dictionary) -> void:
    _oxygen_low_active = true
    _oxygen_label.text = "OXYGEN LOW: %d" % int(data.get("remaining", 0))
    if debug_enabled:
        DebugLog.log("MissionHUD", "LOW_OXYGEN", data)
    # flash oxygen label red
    if _oxygen_tween:
        _oxygen_tween.kill()
    _oxygen_tween = get_tree().create_tween()
    _oxygen_tween.tween_property(_oxygen_label, "modulate", Color(1,0.25,0.25), 0.12)
    _oxygen_tween.tween_property(_oxygen_label, "modulate", Color(1,1,1), 0.6).set_loops(3)

    # vignette + desaturate effects
    if has_node("VignetteRect"):
        var v := get_node("VignetteRect") as ColorRect
        if v and v.material:
            var mat := v.material
            var t := get_tree().create_tween()
            t.tween_property(mat, "shader_param/intensity", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    if has_node("DesaturateRect"):
        var d := get_node("DesaturateRect") as ColorRect
        if d and d.material:
            var mat := d.material
            var t2 := get_tree().create_tween()
            t2.tween_property(mat, "shader_param/amount", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

    # notify ambience controller via group call (heartbeat intensify)
    get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "runtime", "on_low_oxygen", data)

func on_oxygen_recovered(data: Dictionary) -> void:
    _oxygen_low_active = false
    _oxygen_label.text = "Oxygen remaining: %d" % int(data.get("remaining", 0))
    if debug_enabled:
        DebugLog.log("MissionHUD", "OXYGEN_RECOVERED", data)
    if _oxygen_tween:
        _oxygen_tween.kill()
        _oxygen_label.modulate = Color(1,1,1)
    # fade vignette & desaturation back down
    if has_node("VignetteRect"):
        var v := get_node("VignetteRect") as ColorRect
        if v and v.material:
            var mat := v.material
            var t := get_tree().create_tween()
            t.tween_property(mat, "shader_param/intensity", 0.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    if has_node("DesaturateRect"):
        var d := get_node("DesaturateRect") as ColorRect
        if d and d.material:
            var mat := d.material
            var t2 := get_tree().create_tween()
            t2.tween_property(mat, "shader_param/amount", 0.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "runtime", "on_oxygen_recovered", data)

func on_low_temp(data: Dictionary) -> void:
    _temp_low_active = true
    if debug_enabled:
        DebugLog.log("MissionHUD", "LOW_TEMP", data)
    # briefly flash objective in orange
    if _objective_tween:
        _objective_tween.kill()
    _objective_tween = get_tree().create_tween()
    _objective_tween.tween_property(_objective_label, "modulate", Color(1,0.6,0.2), 0.12)
    _objective_tween.tween_property(_objective_label, "modulate", Color(1,1,1), 0.6).set_loops(2)

    # colder visual: stronger vignette + desaturation
    if has_node("VignetteRect"):
        var v := get_node("VignetteRect") as ColorRect
        if v and v.material:
            var mat := v.material
            var t := get_tree().create_tween()
            t.tween_property(mat, "shader_param/intensity", 0.5, 0.9)
    if has_node("DesaturateRect"):
        var d := get_node("DesaturateRect") as ColorRect
        if d and d.material:
            var mat := d.material
            var t2 := get_tree().create_tween()
            t2.tween_property(mat, "shader_param/amount", 0.6, 0.9)

    get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "runtime", "on_low_temp", data)

func on_temp_recovered(data: Dictionary) -> void:
    _temp_low_active = false
    if debug_enabled:
        DebugLog.log("MissionHUD", "TEMP_RECOVERED", data)
    if _objective_tween:
        _objective_tween.kill()
        _objective_label.modulate = Color(1,1,1)
    # fade vignette / desaturation back down
    if has_node("VignetteRect"):
        var v := get_node("VignetteRect") as ColorRect
        if v and v.material:
            var mat := v.material
            var t := get_tree().create_tween()
            t.tween_property(mat, "shader_param/intensity", 0.0, 0.9)
    if has_node("DesaturateRect"):
        var d := get_node("DesaturateRect") as ColorRect
        if d and d.material:
            var mat := d.material
            var t2 := get_tree().create_tween()
            t2.tween_property(mat, "shader_param/amount", 0.0, 0.9)
    get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "runtime", "on_temp_recovered", data)
