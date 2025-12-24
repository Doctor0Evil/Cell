extends Control

signal on_grip()
signal on_slip(reason: String)
signal on_success()
signal nav_intrusion_delta(amount: float)
signal on_hard_fail()

enum State {
    IDLE,
    SEEKING_GRIP,
    GRIPPED,
    PULLING,
    RESULT
}

var state: int = State.IDLE
var state_time: float = 0.0

var grip_zone_start: float = 0.2
var grip_zone_end: float = 0.35
var safe_cone_size: float = 0.40
var pulls_required: int = 3
var red_tolerance: float = 0.35

var current_pull_stage: int = 0
var current_angle: float = 0.0
var safe_center_angle: float = 0.0
var slips_count: int = 0
var max_slips: int = 5

onready var _rail: Node = $ClampRail
onready var _tension_ring: Node = $TensionRing
onready var _progress_ring: Node = $ProgressRing
onready var _vo_player: AudioStreamPlayer = $VOPlayer

func _ready() -> void:
    hide()
    set_process(false)


func begin_jam(jam_tier: int) -> void:
    # Jam tier can scale difficulty; for now just set defaults.
    grip_zone_start = 0.2
    grip_zone_end = 0.35
    safe_cone_size = 0.40
    pulls_required = 3
    red_tolerance = 0.35
    slips_count = 0
    current_pull_stage = 0
    safe_center_angle = 0.0
    state = State.IDLE
    state_time = 0.0
    show()
    set_process(true)
    _play_whisper_intro()


func _process(delta: float) -> void:
    state_time += delta
    match state:
        State.IDLE:
            if state_time > 0.6:
                _enter_state(State.SEEKING_GRIP)
        State.SEEKING_GRIP:
            _update_seeking_grip(delta)
        State.GRIPPED:
            _update_gripped(delta)
        State.PULLING:
            _update_pulling(delta)
        State.RESULT:
            pass


func _enter_state(new_state: int) -> void:
    state = new_state
    state_time = 0.0

    match state:
        State.SEEKING_GRIP:
            # UI hint: highlight grip zone.
            pass
        State.GRIPPED:
            emit_signal("on_grip")
            _add_choir_voice()
        State.PULLING:
            _reset_progress_visuals()


func _update_seeking_grip(_delta: float) -> void:
    var cursor_pos := _get_player_clamp_pos()
    if cursor_pos >= grip_zone_start and cursor_pos <= grip_zone_end:
        if Input.is_action_just_pressed("interact"):
            _enter_state(State.GRIPPED)


func _update_gripped(_delta: float) -> void:
    current_angle = _get_player_angle_input()
    _update_tension_ring_visuals()

    if Input.is_action_just_pressed("interact"):
        if _is_angle_in_green(current_angle):
            _enter_state(State.PULLING)
        else:
            _register_slip("bad_angle")


func _update_pulling(delta: float) -> void:
    current_angle = _get_player_angle_input()
    _update_tension_ring_visuals()

    if not _is_angle_in_green(current_angle):
        _register_slip("slip_outside_cone")
        return

    var progress_delta := delta / red_tolerance
    _advance_pull_progress(progress_delta)

    if _get_pull_progress() >= 1.0:
        current_pull_stage += 1
        _apply_random_bump()
        if current_pull_stage >= pulls_required:
            _complete_success()
        else:
            _enter_state(State.GRIPPED)


func _register_slip(reason: String) -> void:
    slips_count += 1
    emit_signal("on_slip", reason)
    emit_signal("nav_intrusion_delta", 0.02)
    _surge_choir()
    _reset_pull_progress()
    if slips_count >= max_slips:
        _complete_hard_fail()
    else:
        _enter_state(State.SEEKING_GRIP)


func _complete_success() -> void:
    state = State.RESULT
    _play_card_pop()
    emit_signal("on_success")
    emit_signal("nav_intrusion_delta", 0.05)
    _whisper_thank_you()
    _finish_minigame()


func _complete_hard_fail() -> void:
    state = State.RESULT
    emit_signal("on_hard_fail")
    _finish_minigame()


func _finish_minigame() -> void:
    set_process(false)
    yield(get_tree().create_timer(0.2), "timeout")
    hide()


func _apply_random_bump() -> void:
    var offset := rand_range(-0.2, 0.2)
    safe_center_angle += offset
    safe_cone_size = max(0.2, safe_cone_size - 0.05)


func _is_angle_in_green(angle: float) -> bool:
    return abs(angle - safe_center_angle) <= safe_cone_size * 0.5


func _get_player_clamp_pos() -> float:
    # Return normalized 0..1 position along rail from input or cursor.
    return clamp(get_local_mouse_position().x / max(1.0, rect_size.x), 0.0, 1.0)


func _get_player_angle_input() -> float:
    # Example: map left/right to -1..1 radius.
    var input_val := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    return clamp(input_val, -1.0, 1.0)


func _update_tension_ring_visuals() -> void:
    if _tension_ring.has_method("set_angle_and_cone"):
        _tension_ring.call("set_angle_and_cone", current_angle, safe_center_angle, safe_cone_size)


func _advance_pull_progress(amount: float) -> void:
    if _progress_ring.has_method("add_progress"):
        _progress_ring.call("add_progress", amount)


func _reset_pull_progress() -> void:
    if _progress_ring.has_method("reset_progress"):
        _progress_ring.call("reset_progress")


func _get_pull_progress() -> float:
    if _progress_ring.has_method("get_progress"):
        return _progress_ring.call("get_progress")
    return 0.0


func _reset_progress_visuals() -> void:
    _reset_pull_progress()


func _play_whisper_intro() -> void:
    var s := load("res://audio/vo/keycard_careful_intro.ogg")
    _vo_player.stream = s
    _vo_player.play()


func _whisper_thank_you() -> void:
    var s := load("res://audio/vo/keycard_thank_you.ogg")
    _vo_player.stream = s
    _vo_player.play()


func _add_choir_voice() -> void:
    # Hook into global audio bus or choir layer.
    pass


func _surge_choir() -> void:
    # Increase choir intensity on slip.
    pass


func configure_for_accessibility(enabled: bool) -> void:
    if enabled:
        safe_cone_size *= 1.3
        red_tolerance *= 1.3