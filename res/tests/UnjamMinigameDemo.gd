extends Node

onready var _minigame: Control = $KeycardUnjamMinigame
onready var _status_label: Label = $StatusLabel
onready var _restart_button: Button = $RestartButton
onready var _access_button: Button = $AccessibilityButton

var _accessibility_enabled: bool = false

func _ready() -> void:
    _ensure_input_map()

    _status_label.text = "Press RESTART to begin Jam III."
    _restart_button.text = "Restart Jam III"
    _access_button.text = "Accessibility: OFF"

    _restart_button.connect("pressed", self, "_on_restart_pressed")
    _access_button.connect("pressed", self, "_on_accessibility_pressed")

    _connect_minigame_signals()
    _start_jam()


func _ensure_input_map() -> void:
    # Add key mappings at runtime if they don't exist
    if not InputMap.has_action("interact"):
        InputMap.add_action("interact")
        var ev := InputEventKey.new()
        ev.scancode = KEY_SPACE
        InputMap.action_add_event("interact", ev)
        var ev2 := InputEventKey.new()
        ev2.scancode = KEY_E
        InputMap.action_add_event("interact", ev2)

    if not InputMap.has_action("ui_left"):
        InputMap.add_action("ui_left")
        var evl := InputEventKey.new()
        evl.scancode = KEY_A
        InputMap.action_add_event("ui_left", evl)
        var evl2 := InputEventKey.new()
        evl2.scancode = KEY_LEFT
        InputMap.action_add_event("ui_left", evl2)

    if not InputMap.has_action("ui_right"):
        InputMap.add_action("ui_right")
        var evr := InputEventKey.new()
        evr.scancode = KEY_D
        InputMap.action_add_event("ui_right", evr)
        var evr2 := InputEventKey.new()
        evr2.scancode = KEY_RIGHT
        InputMap.action_add_event("ui_right", evr2)


func _connect_minigame_signals() -> void:
    if not _minigame.is_connected("on_grip", self, "_on_grip"):
        _minigame.connect("on_grip", self, "_on_grip")
    if not _minigame.is_connected("on_slip", self, "_on_slip"):
        _minigame.connect("on_slip", self, "_on_slip")
    if not _minigame.is_connected("on_success", self, "_on_success"):
        _minigame.connect("on_success", self, "_on_success")
    if not _minigame.is_connected("on_hard_fail", self, "_on_hard_fail"):
        _minigame.connect("on_hard_fail", self, "_on_hard_fail")
    if not _minigame.is_connected("nav_intrusion_delta", self, "_on_nav_intrusion_delta"):
        _minigame.connect("nav_intrusion_delta", self, "_on_nav_intrusion_delta")


func _start_jam() -> void:
    _status_label.text = "Jam III: move clamp into grip zone, press INTERACT, then hold while keeping angle in green."
    _minigame.call("configure_for_accessibility", _accessibility_enabled)
    _minigame.call("begin_jam", 3)


func _on_restart_pressed() -> void:
    _start_jam()


func _on_accessibility_pressed() -> void:
    _accessibility_enabled = not _accessibility_enabled
    _access_button.text = "Accessibility: %s" % (_accessibility_enabled ? "ON" : "OFF")
    _status_label.text = "Accessibility changed. Restart jam to apply."


func _on_grip() -> void:
    _status_label.text = "GRIP: Find safe angle (green) and press INTERACT to pull."


func _on_slip(reason: String) -> void:
    _status_label.text = "SLIP: %s — clamp reset to SEEKING_GRIP." % reason


func _on_success() -> void:
    _status_label.text = "SUCCESS: Card freed. Jam complete."


func _on_hard_fail() -> void:
    _status_label.text = "HARD FAIL: Card cracked. Max slips reached."


func _on_nav_intrusion_delta(amount: float) -> void:
    # For now just log; later this can route into RadioTransmissions.
    print("nav_intrusion_delta from minigame: ", amount)