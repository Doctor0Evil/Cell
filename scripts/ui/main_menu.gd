# File: res://scripts/ui/main_menu.gd
extends Control
class_name MainMenu

@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton
@onready var options_button: Button = %OptionsButton
@onready var credits_button: Button = %CreditsButton
@onready var codex_button: Button = %CodexButton
@onready var quit_button: Button = %QuitButton

@onready var profile_label: Label = %ProfileLabel
@onready var version_label: Label = %VersionLabel
@onready var build_channel_label: Label = %BuildChannelLabel
@onready var warning_label: Label = %WarningLabel

@onready var background_anim: AnimatedSprite2D = %BackgroundAnim
@onready var ambient_player: AudioStreamPlayer = %AmbientPlayer
@onready var ui_click_player: AudioStreamPlayer = %UIClickPlayer
@onready var ui_hover_player: AudioStreamPlayer = %UIHoverPlayer

@onready var corruption_label: Label = %CorruptionLabel
@onready var incident_code_label: Label = %IncidentCodeLabel

const BUILD_VERSION := "v1.0.0"
const BUILD_CHANNEL := "VEIL-STACK INTERNAL BRANCH"
const COMPLIANCE_TAG := "Incident Tier: Red-Class"
const DEFAULT_PROFILE_NAME := "Unindexed Subject"

const INCIDENT_CODE := "CELL/MOON-K47/ASHVEIL"
const MENU_TELEMETRY_TAG := "ASHVEIL_DEBRIS_STRATUM_CONSOLE"

var _input_locked: bool = false
var _hover_button: BaseButton = null
var _boot_timestamp: int = 0

func _ready() -> void:
    add_to_group("runtime")
    _boot_timestamp = Time.get_unix_time_from_system()

    _wire_buttons()
    _refresh_profile_metadata()
    _apply_build_metadata()
    _configure_presentation()
    _start_ambient()

    DebugLog.log("MainMenu", "READY", {
        "can_continue": not continue_button.disabled,
        "build_version": BUILD_VERSION,
        "build_channel": BUILD_CHANNEL,
        "compliance": COMPLIANCE_TAG,
        "incident_code": INCIDENT_CODE,
        "timestamp": _boot_timestamp
    })

func _process(delta: float) -> void:
    # Mild diegetic flicker when no profile exists, hinting at degraded console.
    if not SaveSystem.has_any_profile():
        var t := sin(Time.get_ticks_msec() / 900.0)
        warning_label.modulate.a = 0.8 + 0.15 * t
    else:
        warning_label.modulate.a = 1.0

    # Optional: hover pulse for currently focused button.
    if _hover_button:
        var h := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 600.0)
        _hover_button.modulate = Color(1.0, 1.0, 1.0, 0.8 + 0.2 * h)

func _wire_buttons() -> void:
    # Press
    start_button.pressed.connect(_on_start_pressed)
    continue_button.pressed.connect(_on_continue_pressed)
    options_button.pressed.connect(_on_options_pressed)
    credits_button.pressed.connect(_on_credits_pressed)
    codex_button.pressed.connect(_on_codex_pressed)
    quit_button.pressed.connect(_on_quit_pressed)

    # Hover
    for b in [
        start_button,
        continue_button,
        options_button,
        credits_button,
        codex_button,
        quit_button
    ]:
        b.mouse_entered.connect(func() -> void:
            _on_button_hover(b))
        b.focus_entered.connect(func() -> void:
            _on_button_hover(b))

func _refresh_profile_metadata() -> void:
    var has_profile := SaveSystem.has_any_profile()
    continue_button.disabled = not has_profile

    if not has_profile:
        profile_label.text = "NO ACTIVE SUBJECT RECORDS / TERMINAL OPERATES IN OBSERVER MODE"
        corruption_label.text = "PROFILE INTEGRITY: N/A / SIGNAL NOISE NOMINAL"
        DebugLog.log("MainMenu", "PROFILE_STATUS", {
            "has_profile": false
        })
        return

    var meta := SaveSystem.get_last_profile_meta()
    # Expected shape: { "id": String, "created_at": int, "last_region": String }
    var profile_id := String(meta.get("id", DEFAULT_PROFILE_NAME))
    var created_at := int(meta.get("created_at", 0))
    var last_region := String(meta.get("last_region", "ASHVEIL_DEBRIS_STRATUM"))

    var created_str := ""
    if created_at > 0:
        created_str = Time.get_datetime_string_from_unix_time(created_at, true)
    else:
        created_str = "UNMARKED"

    profile_label.text = "Last Subject: %s | Stamped: %s | Zone: %s" % [
        profile_id,
        created_str,
        last_region
    ]

    # Simple corruption hint based on last_region and age.
    var age_seconds := max(0, Time.get_unix_time_from_system() - created_at)
    var hours := int(age_seconds / 3600)
    var corruption_hint := "PROFILE INTEGRITY: DEGRADED"
    if hours < 1:
        corruption_hint = "PROFILE INTEGRITY: STABLE"
    elif hours < 24:
        corruption_hint = "PROFILE INTEGRITY: DRIFTING"
    corruption_label.text = "%s / ARCHIVE DELTA ≈ %dh" % [corruption_hint, hours]

    DebugLog.log("MainMenu", "PROFILE_STATUS", {
        "has_profile": true,
        "profile_id": profile_id,
        "created_at": created_at,
        "last_region": last_region,
        "age_hours": hours
    })

func _apply_build_metadata() -> void:
    version_label.text = "CELL %s" % BUILD_VERSION
    build_channel_label.text = "%s | %s" % [
        BUILD_CHANNEL,
        COMPLIANCE_TAG
    ]
    warning_label.text = "NOTICE: CURRENT STRATUM IS FLAGGED NON-RECOVERABLE. CONTINUATION BINDS THIS NODE TO INCIDENT TELEMETRY."
    incident_code_label.text = INCIDENT_CODE

func _configure_presentation() -> void:
    if background_anim and background_anim.sprite_frames \
    and background_anim.sprite_frames.has_animation("pulsate"):
        background_anim.play("pulsate")

    # Slight desaturation when there is no subject bound to this console.
    if continue_button.disabled:
        modulate = Color(0.78, 0.78, 0.78, 1.0)
    else:
        modulate = Color(1.0, 1.0, 1.0, 1.0)

func _start_ambient() -> void:
    if ambient_player and not ambient_player.playing and ambient_player.stream:
        ambient_player.bus = "AMBIENT_UI"
        ambient_player.volume_db = -14.0
        ambient_player.autoplay = false
        ambient_player.play()
        DebugLog.log("MainMenu", "AMBIENT_STARTED", {
            "bus": "AMBIENT_UI",
            "volume_db": ambient_player.volume_db
        })

func _lock_input(lock: bool) -> void:
    _input_locked = lock
    # Preserve real disabled state of Continue while still freezing everything under lock.
    var can_continue := not continue_button.disabled and not lock

    start_button.disabled = lock
    continue_button.disabled = not can_continue
    options_button.disabled = lock
    credits_button.disabled = lock
    codex_button.disabled = lock
    quit_button.disabled = lock

    DebugLog.log("MainMenu", "INPUT_LOCK", {"locked": lock})

func _on_button_hover(button: BaseButton) -> void:
    _hover_button = button
    if ui_hover_player and ui_hover_player.stream and not _input_locked:
        ui_hover_player.stop()
        ui_hover_player.play()
    DebugLog.log("MainMenu", "BUTTON_HOVER", {
        "button": button.name,
        "telemetry_tag": MENU_TELEMETRY_TAG
    })

func _play_click() -> void:
    if ui_click_player and ui_click_player.stream:
        ui_click_player.stop()
        ui_click_player.play()

func _transition_to_scene(path: String) -> void:
    if _input_locked:
        return
    _lock_input(true)
    _play_click()
    DebugLog.log("MainMenu", "SCENE_TRANSITION", {
        "target": path,
        "telemetry_tag": MENU_TELEMETRY_TAG
    })
    get_tree().change_scene_to_file(path)

func _on_start_pressed() -> void:
    if _input_locked:
        return

    DebugLog.log("MainMenu", "START_PRESSED", {
        "telemetry_tag": MENU_TELEMETRY_TAG
    })
    _play_click()

    SaveSystem.new_profile()
    GameState.reset_for_new_run()
    var gs := get_node_or_null("/root/GameState")
    if gs:
        gs.load_region(&"ASHVEIL_DEBRIS_STRATUM")
    else:
        GameState.load_region(&"ASHVEIL_DEBRIS_STRATUM")

func _on_continue_pressed() -> void:
    if _input_locked:
        return
    if continue_button.disabled:
        DebugLog.log("MainMenu", "CONTINUE_BLOCKED", {
            "reason": "NO_PROFILE",
            "telemetry_tag": MENU_TELEMETRY_TAG
        })
        return

    DebugLog.log("MainMenu", "CONTINUE_PRESSED", {
        "telemetry_tag": MENU_TELEMETRY_TAG
    })
    _play_click()
    SaveSystem.load_last_profile()

func _on_options_pressed() -> void:
    if _input_locked:
        return
    DebugLog.log("MainMenu", "OPTIONS_PRESSED", {
        "telemetry_tag": MENU_TELEMETRY_TAG
    })
    _transition_to_scene("res://scenes/ui/OptionsMenu.tscn")

func _on_credits_pressed() -> void:
    if _input_locked:
        return
    DebugLog.log("MainMenu", "CREDITS_PRESSED", {
        "telemetry_tag": MENU_TELEMETRY_TAG
    })
    _transition_to_scene("res://scenes/ui/Credits.tscn")

func _on_codex_pressed() -> void:
    if _input_locked:
        return
    DebugLog.log("MainMenu", "CODEX_PRESSED", {
        "telemetry_tag": MENU_TELEMETRY_TAG
    })
    _transition_to_scene("res://scenes/ui/LoreCodex.tscn")

func _on_quit_pressed() -> void:
    if _input_locked:
        return
    DebugLog.log("MainMenu", "QUIT_PRESSED", {
        "uptime_seconds": Time.get_unix_time_from_system() - _boot_timestamp,
        "telemetry_tag": MENU_TELEMETRY_TAG
    })
    _play_click()
    get_tree().quit()
