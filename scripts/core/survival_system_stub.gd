extends Node
class_name SurvivalSystemStub

@export var debug_enabled: bool = true
@export var oxygen_seconds: float = 180.0
@export var body_temperature: float = 37.0

# Low-state thresholds
@export var low_oxygen_threshold: float = 30.0
@export var low_temp_threshold: float = 35.0

var _low_oxygen_warned: bool = false
var _low_temp_warned: bool = false

func _ready() -> void:
    add_to_group("survival_system")
    add_to_group("runtime")
    if debug_enabled:
        DebugLog.log("SurvivalSystemStub", "READY", {
            "oxygen_seconds": oxygen_seconds,
            "body_temperature": body_temperature,
            "low_oxygen_threshold": low_oxygen_threshold,
            "low_temp_threshold": low_temp_threshold
        })

func drain_oxygen_seconds(amount: float) -> void:
    oxygen_seconds = max(0.0, oxygen_seconds - amount)
    if debug_enabled:
        DebugLog.log("SurvivalSystemStub", "DRAIN_OXYGEN", {"amount": amount, "remaining": oxygen_seconds})

    # Low-oxygen warning / recovery
    if oxygen_seconds <= low_oxygen_threshold and not _low_oxygen_warned:
        _low_oxygen_warned = true
        if debug_enabled:
            DebugLog.log("SurvivalSystemStub", "LOW_OXYGEN_TRIGGER", {"remaining": oxygen_seconds})
        get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "runtime", "on_low_oxygen", {"remaining": oxygen_seconds})
    elif oxygen_seconds > low_oxygen_threshold and _low_oxygen_warned:
        _low_oxygen_warned = false
        if debug_enabled:
            DebugLog.log("SurvivalSystemStub", "OXYGEN_RECOVERED", {"remaining": oxygen_seconds})
        get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "runtime", "on_oxygen_recovered", {"remaining": oxygen_seconds})

func get_oxygen_seconds_remaining() -> float:
    return oxygen_seconds

func apply_cold_exposure(delta_temp: float) -> void:
    body_temperature = max(-273.0, body_temperature - delta_temp)
    if debug_enabled:
        DebugLog.log("SurvivalSystemStub", "COLD_EXPOSURE", {"delta_temp": delta_temp, "body_temperature": body_temperature})

    # Low-temp warnings / recovery
    if body_temperature <= low_temp_threshold and not _low_temp_warned:
        _low_temp_warned = true
        if debug_enabled:
            DebugLog.log("SurvivalSystemStub", "LOW_TEMP_TRIGGER", {"body_temperature": body_temperature})
        get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "runtime", "on_low_temp", {"body_temperature": body_temperature})
    elif body_temperature > low_temp_threshold and _low_temp_warned:
        _low_temp_warned = false
        if debug_enabled:
            DebugLog.log("SurvivalSystemStub", "TEMP_RECOVERED", {"body_temperature": body_temperature})
        get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "runtime", "on_temp_recovered", {"body_temperature": body_temperature})

func get_body_temperature() -> float:
    return body_temperature

# utility: refill oxygen (editor/test)
func refill_oxygen(amount: float) -> void:
    oxygen_seconds += amount
    if debug_enabled:
        DebugLog.log("SurvivalSystemStub", "REFILL_OXYGEN", {"amount": amount, "remaining": oxygen_seconds})
    if oxygen_seconds > low_oxygen_threshold and _low_oxygen_warned:
        _low_oxygen_warned = false
        get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "runtime", "on_oxygen_recovered", {"remaining": oxygen_seconds})
