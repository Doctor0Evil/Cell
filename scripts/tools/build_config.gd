# File: res://scripts/tools/build_config.gd
extends Node
class_name BuildConfig

const SETTINGS_FILE := "user://settings.cfg"

# Canonical video presets for each platform family.
const VIDEO_PRESETS := {
    "Windows": {
        "id": "WIN_BASE_1080P",
        "width": 1920,
        "height": 1080,
        "fullscreen": true,
        "vsync": true
    },
    "Linux": {
        "id": "LIN_MID_900P",
        "width": 1600,
        "height": 900,
        "fullscreen": false,
        "vsync": true
    },
    "macOS": {
        "id": "MAC_HIGH_1440P",
        "width": 2560,
        "height": 1440,
        "fullscreen": true,
        "vsync": true
    },
    "Mobile": {
        "id": "MOB_720P",
        "width": 1280,
        "height": 720,
        "fullscreen": true,
        "vsync": true
    }
}

# Default audio curve tuned for tense, quiet corridors with sharp SFX.
const AUDIO_DEFAULTS := {
    "Master": -3.0,
    "SFX": -6.0,
    "Music": -10.0,
    "Ambient": -12.0,
    "UI": -14.0
}

# Debug / telemetry toggles for development builds.
const DEBUG_FLAGS := {
    "show_fps": true,
    "show_runtime_overlay": true,
    "log_to_file": false,
    "max_log_entries": 2048
}

# -------------------------------
# --- PLATFORM DEFAULTS ---
# -------------------------------

static func apply_default_windows_settings() -> void:
    var p := VIDEO_PRESETS["Windows"]
    _apply_core_video_defaults(p["width"], p["height"], p["fullscreen"], p["vsync"])
    ProjectSettings.set_setting("application/config/name", "CELL")
    ProjectSettings.set_setting("application/config/icon", "res://ASSETS/icons/cell_icon.ico")
    ProjectSettings.save()
    DebugLog.log("BuildConfig", "APPLY_WINDOWS_DEFAULTS", p)

static func apply_default_linux_settings() -> void:
    var p := VIDEO_PRESETS["Linux"]
    _apply_core_video_defaults(p["width"], p["height"], p["fullscreen"], p["vsync"])
    ProjectSettings.set_setting("application/config/name", "CELL")
    ProjectSettings.set_setting("application/config/icon", "res://ASSETS/icons/cell_icon.png")
    ProjectSettings.save()
    DebugLog.log("BuildConfig", "APPLY_LINUX_DEFAULTS", p)

static func apply_default_macos_settings() -> void:
    var p := VIDEO_PRESETS["macOS"]
    _apply_core_video_defaults(p["width"], p["height"], p["fullscreen"], p["vsync"])
    ProjectSettings.set_setting("application/config/name", "CELL")
    ProjectSettings.set_setting("application/config/icon", "res://ASSETS/icons/cell_icon.icns")
    ProjectSettings.save()
    DebugLog.log("BuildConfig", "APPLY_MACOS_DEFAULTS", p)

static func apply_default_mobile_settings() -> void:
    var p := VIDEO_PRESETS["Mobile"]
    _apply_core_video_defaults(p["width"], p["height"], p["fullscreen"], p["vsync"])
    ProjectSettings.set_setting("application/config/name", "CELL")
    ProjectSettings.set_setting("application/config/icon", "res://ASSETS/icons/cell_icon_mobile.png")
    ProjectSettings.set_setting("display/window/stretch/mode", "2d")
    ProjectSettings.set_setting("display/window/stretch/aspect", "keep")
    ProjectSettings.save()
    DebugLog.log("BuildConfig", "APPLY_MOBILE_DEFAULTS", p)

static func _apply_core_video_defaults(width: int, height: int, fullscreen: bool, vsync: bool) -> void:
    ProjectSettings.set_setting("display/window/size/viewport_width", width)
    ProjectSettings.set_setting("display/window/size/viewport_height", height)
    ProjectSettings.set_setting("display/window/size/window_width", width)
    ProjectSettings.set_setting("display/window/size/window_height", height)
    ProjectSettings.set_setting("display/window/stretch/mode", "viewport")
    ProjectSettings.set_setting("display/window/stretch/aspect", "keep")

    ProjectSettings.set_setting(
        "display/window/vsync/vsync_mode",
        DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
    )

    ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", 1) # 2x
    ProjectSettings.set_setting("rendering/environment/defaults/default_clear_color", Color(0, 0, 0, 1))

# -------------------------------
# --- SETTINGS PERSISTENCE ---
# -------------------------------

static func save_settings() -> void:
    var cfg := ConfigFile.new()

    # VIDEO
    var mode := DisplayServer.window_get_mode()
    cfg.set_value("video", "fullscreen", mode == DisplayServer.WINDOW_MODE_FULLSCREEN)
    cfg.set_value("video", "resolution", DisplayServer.window_get_size())
    cfg.set_value("video", "vsync", DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED)

    # AUDIO
    for bus_name in AUDIO_DEFAULTS.keys():
        var idx := AudioServer.get_bus_index(bus_name)
        if idx >= 0:
            var key := bus_name.to_lower() + "_db"
            cfg.set_value("audio", key, AudioServer.get_bus_volume_db(idx))

    # DEBUG
    for flag in DEBUG_FLAGS.keys():
        cfg.set_value("debug", flag, DEBUG_FLAGS[flag])

    var err := cfg.save(SETTINGS_FILE)
    DebugLog.log("BuildConfig", "SAVE_SETTINGS", {
        "file": SETTINGS_FILE,
        "result": err
    })

static func load_settings() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load(SETTINGS_FILE)
    if err != OK:
        DebugLog.log("BuildConfig", "LOAD_SETTINGS_FAILED", {
            "file": SETTINGS_FILE,
            "error": err
        })
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
        var idx := AudioServer.get_bus_index(bus_name)
        if idx >= 0:
            var key := bus_name.to_lower() + "_db"
            var default_db := AUDIO_DEFAULTS[bus_name]
            var db := float(cfg.get_value("audio", key, default_db))
            AudioServer.set_bus_volume_db(idx, db)

    # DEBUG (read for telemetry, not forced)
    var debug_state: Dictionary = {}
    for flag in DEBUG_FLAGS.keys():
        debug_state[flag] = cfg.get_value("debug", flag, DEBUG_FLAGS[flag])

    DebugLog.log("BuildConfig", "LOAD_SETTINGS", {
        "file": SETTINGS_FILE,
        "resolution": [res.x, res.y],
        "fullscreen": fullscreen,
        "vsync": vsync,
        "debug": debug_state
    })

# -------------------------------
# --- AUTO-DETECTION ---
# -------------------------------

static func apply_platform_defaults() -> void:
    var name := OS.get_name()
    match name:
        "Windows":
            apply_default_windows_settings()
        "Linux", "FreeBSD":
            apply_default_linux_settings()
        "macOS":
            apply_default_macos_settings()
        "Android", "iOS":
            apply_default_mobile_settings()
        _:
            DebugLog.log("BuildConfig", "UNKNOWN_PLATFORM", {"platform": name})

# -------------------------------
# --- RUNTIME SUMMARY (OPTIONAL)
# -------------------------------

static func get_runtime_profile() -> Dictionary:
    # Compact snapshot for debug overlays / telemetry.
    var size := DisplayServer.window_get_size()
    var mode := DisplayServer.window_get_mode()
    var vsync := DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED

    var audio_snapshot: Dictionary = {}
    for bus_name in AUDIO_DEFAULTS.keys():
        var idx := AudioServer.get_bus_index(bus_name)
        if idx >= 0:
            audio_snapshot[bus_name] = AudioServer.get_bus_volume_db(idx)

    return {
        "resolution": {"w": size.x, "h": size.y},
        "fullscreen": mode == DisplayServer.WINDOW_MODE_FULLSCREEN,
        "vsync": vsync,
        "audio": audio_snapshot
    }
