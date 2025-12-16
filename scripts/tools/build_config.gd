# File: res://scripts/tools/build_config.gd
extends Node
class_name BuildConfig

const SETTINGS_FILE := "user://settings.cfg"

# Canonical Windows desktop resolutions ordered by cost.
const VIDEO_PRESETS := [
    {
        "id": "LOW_720P",
        "width": 1280,
        "height": 720,
        "fullscreen": false,
        "vsync": true,
        "description": "Lower resolution for unstable systems."
    },
    {
        "id": "MID_900P",
        "width": 1600,
        "height": 900,
        "fullscreen": false,
        "vsync": true,
        "description": "Balanced resolution for typical laptops."
    },
    {
        "id": "BASE_1080P",
        "width": 1920,
        "height": 1080,
        "fullscreen": true,
        "vsync": true,
        "description": "Default target for CELL on desktop."
    },
    {
        "id": "HIGH_1440P",
        "width": 2560,
        "height": 1440,
        "fullscreen": true,
        "vsync": true,
        "description": "High‑end displays; heavier cost."
    }
]

# Default audio mix aimed at grounded survival‑horror ambience.
const AUDIO_DEFAULTS := {
    "Master": -3.0,
    "SFX": -6.0,
    "Music": -8.0,
    "Ambient": -10.0,
    "UI": -10.0
}

# Input defaults so automation and in‑game prompts have a stable map.
# These correspond to Godot InputMap actions configured in project.godot.
const INPUT_DEFAULTS := {
    "move_forward": { "type": "key", "keycode": KEY_W },
    "move_backward": { "type": "key", "keycode": KEY_S },
    "move_left": { "type": "key", "keycode": KEY_A },
    "move_right": { "type": "key", "keycode": KEY_D },
    "sprint": { "type": "key", "keycode": KEY_SHIFT },
    "crouch": { "type": "key", "keycode": KEY_CTRL },
    "interact": { "type": "key", "keycode": KEY_E },
    "flashlight": { "type": "key", "keycode": KEY_F },
    "inventory": { "type": "key", "keycode": KEY_TAB },
    "pause": { "type": "key", "keycode": KEY_ESCAPE }
}

# Debug and telemetry toggles for development builds.
const DEBUG_FLAGS := {
    "show_fps": true,
    "show_runtime_overlay": true,
    "log_to_file": false,
    "log_max_entries": 2048
}

# -------------------------------------------------------------------
# WINDOWS VIDEO / APP DEFAULTS
# -------------------------------------------------------------------

static func apply_default_windows_settings() -> void:
    var base := VIDEO_PRESETS[2]  # BASE_1080P
    ProjectSettings.set_setting("display/window/size/viewport_width", base["width"])
    ProjectSettings.set_setting("display/window/size/viewport_height", base["height"])
    ProjectSettings.set_setting("display/window/size/window_width", base["width"])
    ProjectSettings.set_setting("display/window/size/window_height", base["height"])
    ProjectSettings.set_setting("display/window/stretch/mode", "viewport")
    ProjectSettings.set_setting("display/window/stretch/aspect", "keep")
    ProjectSettings.set_setting("display/window/vsync/vsync_mode", DisplayServer.VSYNC_ENABLED)

    ProjectSettings.set_setting("application/config/name", "CELL")
    ProjectSettings.set_setting("application/config/icon", "res://ASSETS/icons/cell_icon.ico")
    ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", 1) # 2x
    ProjectSettings.set_setting("rendering/environment/defaults/default_clear_color", Color(0, 0, 0, 1))
    ProjectSettings.save()

    DebugLog.log("BuildConfig", "APPLY_WINDOWS_DEFAULTS", {
        "width": base["width"],
        "height": base["height"],
        "preset_id": base["id"]
    })

# -------------------------------------------------------------------
# AUDIO DEFAULTS
# -------------------------------------------------------------------

static func apply_default_audio_settings() -> void:
    for bus_name in AUDIO_DEFAULTS.keys():
        var idx := AudioServer.get_bus_index(bus_name)
        if idx >= 0:
            AudioServer.set_bus_volume_db(idx, AUDIO_DEFAULTS[bus_name])
    DebugLog.log("BuildConfig", "APPLY_AUDIO_DEFAULTS", AUDIO_DEFAULTS)

# -------------------------------------------------------------------
# INPUT MAP DEFAULTS (OPTIONAL)
# -------------------------------------------------------------------

static func apply_default_input_map() -> void:
    for action in INPUT_DEFAULTS.keys():
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        # Clear existing events and re‑apply defaults.
        InputMap.action_erase_events(action)
        var data := INPUT_DEFAULTS[action]
        if data["type"] == "key":
            var ev := InputEventKey.new()
            ev.physical_keycode = data["keycode"]
            InputMap.action_add_event(action, ev)
    DebugLog.log("BuildConfig", "APPLY_INPUT_DEFAULTS", {
        "actions": INPUT_DEFAULTS.keys()
    })

# -------------------------------------------------------------------
# SETTINGS SAVE / LOAD
# -------------------------------------------------------------------

static func save_settings() -> void:
    var cfg := ConfigFile.new()

    # VIDEO
    var mode := DisplayServer.window_get_mode()
    cfg.set_value("video", "fullscreen", mode == DisplayServer.WINDOW_MODE_FULLSCREEN)
    cfg.set_value("video", "resolution", DisplayServer.window_get_size())
    cfg.set_value("video", "vsync", DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED)

    # Store nearest known preset ID for analytics / quick restore.
    var res := DisplayServer.window_get_size()
    var preset_id := _get_closest_preset_id(res)
    cfg.set_value("video", "preset_id", preset_id)

    # AUDIO
    for bus_name in AUDIO_DEFAULTS.keys():
        var idx := AudioServer.get_bus_index(bus_name)
        if idx >= 0:
            cfg.set_value("audio", bus_name.to_lower() + "_db", AudioServer.get_bus_volume_db(idx))

    # DEBUG
    for flag in DEBUG_FLAGS.keys():
        cfg.set_value("debug", flag, DEBUG_FLAGS[flag])

    var err := cfg.save(SETTINGS_FILE)
    DebugLog.log("BuildConfig", "SAVE_SETTINGS", {
        "file": SETTINGS_FILE,
        "result": err,
        "preset_id": preset_id,
        "resolution": [res.x, res.y]
    })

static func load_settings() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load(SETTINGS_FILE)
    if err != OK:
        DebugLog.log("BuildConfig", "LOAD_SETTINGS_FAILED", {
            "file": SETTINGS_FILE,
            "error": err
        })
        # Fallback to defaults.
        apply_default_windows_settings()
        apply_default_audio_settings()
        return

    # VIDEO
    var res := cfg.get_value("video", "resolution", Vector2i(1920, 1080))
    var fullscreen := bool(cfg.get_value("video", "fullscreen", true))
    var vsync := bool(cfg.get_value("video", "vsync", true))

    DisplayServer.window_set_size(res)
    DisplayServer.window_set_mode(
        DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
    )
    DisplayServer.window_set_vsync_mode(
        DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
    )

    # AUDIO
    for bus_name in AUDIO_DEFAULTS.keys():
        var key := bus_name.to_lower() + "_db"
        var default_db := AUDIO_DEFAULTS[bus_name]
        var db := float(cfg.get_value("audio", key, default_db))
        var idx := AudioServer.get_bus_index(bus_name)
        if idx >= 0:
            AudioServer.set_bus_volume_db(idx, db)

    # DEBUG (read‑only at runtime, but logged for diagnostics)
    var debug_state: Dictionary = {}
    for flag in DEBUG_FLAGS.keys():
        debug_state[flag] = cfg.get_value("debug", flag, DEBUG_FLAGS[flag])

    DebugLog.log("BuildConfig", "LOAD_SETTINGS", {
        "file": SETTINGS_FILE,
        "resolution": [res.x, res.y],
        "fullscreen": fullscreen,
        "vsync": vsync,
        "debug_flags": debug_state
    })

# -------------------------------------------------------------------
# EXPORT / BUILD‑TIME HELPERS
# -------------------------------------------------------------------

static func export_profile_summary() -> Dictionary:
    # Returns a compact snapshot of tuning so build scripts can embed it.
    var current_res := DisplayServer.window_get_size()
    var current_mode := DisplayServer.window_get_mode()
    var vsync := DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED

    var audio_snapshot: Dictionary = {}
    for bus_name in AUDIO_DEFAULTS.keys():
        var idx := AudioServer.get_bus_index(bus_name)
        if idx >= 0:
            audio_snapshot[bus_name] = AudioServer.get_bus_volume_db(idx)

    var summary := {
        "resolution": {
            "width": current_res.x,
            "height": current_res.y
        },
        "mode": current_mode,
        "fullscreen": current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN,
        "vsync": vsync,
        "audio": audio_snapshot
    }

    DebugLog.log("BuildConfig", "EXPORT_PROFILE_SUMMARY", summary)
    return summary

# -------------------------------------------------------------------
# INTERNAL HELPERS
# -------------------------------------------------------------------

static func _get_closest_preset_id(size: Vector2i) -> String:
    var best_id := VIDEO_PRESETS[2]["id"]
    var best_score := 99999999
    for preset in VIDEO_PRESETS:
        var dx := int(preset["width"]) - size.x
        var dy := int(preset["height"]) - size.y
        var score := abs(dx) + abs(dy)
        if score < best_score:
            best_score = score
            best_id = preset["id"]
    return best_id
