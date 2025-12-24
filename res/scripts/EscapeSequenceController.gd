extends Node

enum EscapeState {
    ENTRY,
    ORIENTATION,
    CORPSE_CONNECT,
    KEYPAD_SEARCH,
    UNJAM_MINIGAME,
    DOOR_OPEN,
    BULKHEAD_QTE,
    EXIT
}

var state: int = EscapeState.ENTRY
var state_time: float = 0.0

onready var _radio: Node = $"../RadioTransmissions"
onready var _door: Node = $Door
onready var _keypad: Node = $Keypad
onready var _corpse_socket: Node = $CorpseSocket
onready var _unjam_minigame: Control = $KeycardUnjamMinigame
onready var _hud: CanvasLayer = $HUD

func _ready() -> void:
    _enter_state(EscapeState.ENTRY)
    set_process(true)


func _process(delta: float) -> void:
    state_time += delta
    match state:
        EscapeState.ENTRY:
            _update_entry(delta)
        EscapeState.ORIENTATION:
            _update_orientation(delta)
        EscapeState.CORPSE_CONNECT:
            _update_corpse_connect(delta)
        EscapeState.KEYPAD_SEARCH:
            _update_keypad_search(delta)
        EscapeState.UNJAM_MINIGAME:
            _update_unjam_minigame(delta)
        EscapeState.DOOR_OPEN:
            _update_door_open(delta)
        EscapeState.BULKHEAD_QTE:
            _update_bulkhead_qte(delta)
        EscapeState.EXIT:
            pass


func _enter_state(new_state: int) -> void:
    state = new_state
    state_time = 0.0

    match state:
        EscapeState.ENTRY:
            _hud.call("show_note", "Power low — comms degraded.")
            _radio.adjust_nav_intrusion(0.01)
            _radio.set_audio_level_db(-30.0)
        EscapeState.ORIENTATION:
            _hud.call("show_hint", "Tones repeat... listen.")
        EscapeState.CORPSE_CONNECT:
            _hud.call("show_hint", "Route power through the body-mounted chip.")
        EscapeState.KEYPAD_SEARCH:
            _hud.call("show_hint", "Find the tones that match the codex.")
        EscapeState.UNJAM_MINIGAME:
            _start_unjam_minigame()
        EscapeState.DOOR_OPEN:
            _open_door_with_chant_sync()
        EscapeState.BULKHEAD_QTE:
            _start_bulkhead_qte()
        EscapeState.EXIT:
            _radio.adjust_nav_intrusion(0.15)
            _hud.call("set_persistent_hum", true)


func _update_entry(_delta: float) -> void:
    if state_time > 2.0:
        _enter_state(EscapeState.ORIENTATION)


func _update_orientation(_delta: float) -> void:
    # Transition when player interacts with radio
    if _player_interacted_with_radio():
        _radio.play_random_distress_variant()
        _enter_state(EscapeState.CORPSE_CONNECT)


func _update_corpse_connect(_delta: float) -> void:
    if _corpse_socket.get("is_connected"):
        _radio.adjust_nav_intrusion(0.08)
        _hud.call("show_log_popup", "Aux relay online. Conscious residue detected.")
        _enter_state(EscapeState.KEYPAD_SEARCH)


func _update_keypad_search(_delta: float) -> void:
    if _keypad.get("is_solved"):
        _enter_state(EscapeState.UNJAM_MINIGAME)


func _update_unjam_minigame(_delta: float) -> void:
    # Logic handled by KeycardUnjamMinigame via signals
    pass


func _update_door_open(_delta: float) -> void:
    if state_time > 1.5:
        _enter_state(EscapeState.BULKHEAD_QTE)


func _update_bulkhead_qte(_delta: float) -> void:
    # Placeholder: hook in your QTE system here
    if _bulkhead_qte_completed_success():
        _enter_state(EscapeState.EXIT)


func _start_unjam_minigame() -> void:
    _unjam_minigame.show()
    _unjam_minigame.call("begin_jam", 3) # Example tier index
    _unjam_minigame.connect("on_success", self, "_on_unjam_success", [], CONNECT_ONESHOT)
    _unjam_minigame.connect("on_hard_fail", self, "_on_unjam_hard_fail", [], CONNECT_ONESHOT)
    _unjam_minigame.connect("nav_intrusion_delta", _radio, "adjust_nav_intrusion")


func _on_unjam_success() -> void:
    _radio.adjust_nav_intrusion(0.05)
    _hud.call("whisper", "Thank you.")
    _enter_state(EscapeState.DOOR_OPEN)


func _on_unjam_hard_fail() -> void:
    _door.set("card_damaged", true)
    _hud.call("show_note", "Find alternate clearance.")
    _enter_state(EscapeState.DOOR_OPEN)


func _open_door_with_chant_sync() -> void:
    _door.call("open_with_tempo", 1.0)


func _start_bulkhead_qte() -> void:
    # Hook: start your 2-phase QTE here (hold + timed choice)
    pass


func _player_interacted_with_radio() -> bool:
    # Implement actual interaction check.
    return false


func _bulkhead_qte_completed_success() -> bool:
    # Implement actual QTE completion check.
    return false