# File: res://scripts/ui/options_menu.gd
extends Control
class_name OptionsMenu

@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var resolution_option: OptionButton = %ResolutionOption
@onready var vsync_check: CheckBox = %VsyncCheck
@onready var quality_option: OptionButton = %QualityOption
@onready var fog_slider: HSlider = %FogDensity
@onready var bloom_check: CheckBox = %BloomCheck

@onready var master_slider: HSlider = %MasterVolume
@onready var sfx_slider: HSlider = %SfxVolume
@onready var music_slider: HSlider = %MusicVolume
@onready var ambient_slider: HSlider = %AmbientVolume

@onready var text_scale_slider: HSlider = %TextScale
@onready var colorblind_option: OptionButton = %ColorblindOption
@onready var motion_toggle: CheckBox = %MotionToggle

@onready var back_button: Button = %BackButton
@onready var apply_button: Button = %ApplyButton

const RESOLUTIONS := [
    Vector2i(1280, 720),
    Vector2i(1600, 900),
    Vector2i(1920, 1080),
    Vector2i(2560, 1440)
]

# Quality presets tuned for a dark survival‑horror look.
# 0 = Low, 1 = Medium, 2 = High, 3 = Nightmare (heavy fog/bloom, more tension).
const QUALITY_PRESETS := {
    0: { # Low
        "fog_density": 0.15,
        "bloom": false,
        "ssao": false,
        "shadows": 1,
        "lod_bias": 1.25
    },
    1: { # Medium
        "fog_density": 0.25,
        "bloom": true,
        "ssao": false,
        "shadows": 2,
        "lod_bias": 1.0
    },
    2: { # High
        "fog_density": 0.35,
        "bloom": true,
        "ssao": true,
        "shadows": 3,
        "lod_bias": 0.8
    },
    3: { # Nightmare
        "fog_density": 0.5,
        "bloom": true,
        "ssao": true,
        "shadows": 3,
        "lod_bias": 0.6
    }
}

# Colorblind modes are purely fictional overlays.
# 0 = None, 1 = Phosphor, 2 = Deep Contrast, 3 = Dusk Filter
const COLORBLIND_MODES := {
    0: "None",
    1: "Phosphor",
    2: "Deep Contrast",
    3: "Dusk Filter"
}

const CONFIG_PATH := "user://cell_options.cfg"
const CONFIG_SECTION_VIDEO := "video"
const CONFIG_SECTION_AUDIO := "audio"
const CONFIG_SECTION_ACCESS := "accessibility"

var _pending_video_settings: Dictionary = {}
var _pending_audio_settings: Dictionary = {}
var _pending_access_settings: Dictionary = {}

func _ready() -> void:
    back_button.pressed.connect(_on_back_pressed)
    apply_button.pressed.connect(_on_apply_pressed)

    fullscreen_check.toggled.connect(_on_fullscreen_toggled)
    resolution_option.item_selected.connect(_on_resolution_selected)
    vsync_check.toggled.connect(_on_vsync_toggled)
    quality_option.item_selected.connect(_on_quality_selected)
    fog_slider.value_changed.connect(_on_fog_changed)
    bloom_check.toggled.connect(_on_bloom_toggled)

    master_slider.value_changed.connect(_on_master_volume_changed)
    sfx_slider.value_changed.connect(_on_sfx_volume_changed)
    music_slider.value_changed.connect(_on_music_volume_changed)
    ambient_slider.value_changed.connect(_on_ambient_volume_changed)

    text_scale_slider.value_changed.connect(_on_text_scale_changed)
    colorblind_option.item_selected.connect(_on_colorblind_selected)
    motion_toggle.toggled.connect(_on_motion_toggled)

    _populate_resolutions()
    _populate_quality()
    _populate_colorblind()
    _load_current_settings()
    DebugLog.log("OptionsMenu", "READY", {})

# -------------------------------------------------------------------
# UI population
# -------------------------------------------------------------------

func _populate_resolutions() -> void:
    resolution_option.clear()
    var current_size := DisplayServer.window_get_size()
    var selected_index := 0
    for i in RESOLUTIONS.size():
        var r := RESOLUTIONS[i]
        var label := "%dx%d" % [r.x, r.y]
        resolution_option.add_item(label, i)
        if r == current_size:
            selected_index = i
    resolution_option.select(selected_index)

func _populate_quality() -> void:
    quality_option.clear()
    quality_option.add_item("Low", 0)
    quality_option.add_item("Medium", 1)
    quality_option.add_item("High", 2)
    quality_option.add_item("Nightmare", 3)
    quality_option.select(2) # default High

func _populate_colorblind() -> void:
    colorblind_option.clear()
    for i in COLORBLIND_MODES.keys():
        colorblind_option.add_item(COLORBLIND_MODES[i], i)
    colorblind_option.select(0)

# -------------------------------------------------------------------
# Loading and saving
# -------------------------------------------------------------------

func _load_current_settings() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load(CONFIG_PATH)
    if err != OK:
        _load_defaults()
        return

    # Video
    var fullscreen := cfg.get_value(CONFIG_SECTION_VIDEO, "fullscreen", true)
    var vsync := cfg.get_value(CONFIG_SECTION_VIDEO, "vsync", true)
    var res_index := int(cfg.get_value(CONFIG_SECTION_VIDEO, "resolution_index", 2))
    var quality_index := int(cfg.get_value(CONFIG_SECTION_VIDEO, "quality_index", 2))
    var fog_density := float(cfg.get_value(CONFIG_SECTION_VIDEO, "fog_density", 0.35))
    var bloom := cfg.get_value(CONFIG_SECTION_VIDEO, "bloom", true)

    fullscreen_check.button_pressed = fullscreen
    vsync_check.button_pressed = vsync
    resolution_option.select(clamp(res_index, 0, RESOLUTIONS.size() - 1))
    quality_option.select(clamp(quality_index, 0, QUALITY_PRESETS.size() - 1))
    fog_slider.value = clamp(fog_density, fog_slider.min_value, fog_slider.max_value)
    bloom_check.button_pressed = bloom

    _apply_fullscreen(fullscreen)
    _apply_resolution(resolution_option.get_selected_id())
    _apply_vsync(vsync)
    _apply_quality_preset(quality_index)

    # Audio
    var master_db := float(cfg.get_value(CONFIG_SECTION_AUDIO, "master_db", -6.0))
    var sfx_db := float(cfg.get_value(CONFIG_SECTION_AUDIO, "sfx_db", -8.0))
    var music_db := float(cfg.get_value(CONFIG_SECTION_AUDIO, "music_db", -12.0))
    var ambient_db := float(cfg.get_value(CONFIG_SECTION_AUDIO, "ambient_db", -10.0))

    master_slider.value = master_db
    sfx_slider.value = sfx_db
    music_slider.value = music_db
    ambient_slider.value = ambient_db

    _apply_bus_volume("Master", master_db)
    _apply_bus_volume("SFX", sfx_db)
    _apply_bus_volume("Music", music_db)
    _apply_bus_volume("Ambient", ambient_db)

    # Accessibility
    var text_scale := float(cfg.get_value(CONFIG_SECTION_ACCESS, "text_scale", 1.0))
    var colorblind_index := int(cfg.get_value(CONFIG_SECTION_ACCESS, "colorblind_index", 0))
    var motion_enabled := bool(cfg.get_value(CONFIG_SECTION_ACCESS, "motion_enabled", true))

    text_scale_slider.value = clamp(text_scale, text_scale_slider.min_value, text_scale_slider.max_value)
    colorblind_option.select(clamp(colorblind_index, 0, COLORBLIND_MODES.size() - 1))
    motion_toggle.button_pressed = motion_enabled

    _apply_text_scale(text_scale)
    _apply_colorblind_mode(colorblind_index)
    _apply_motion_toggle(motion_enabled)

func _load_defaults() -> void:
    fullscreen_check.button_pressed = true
    vsync_check.button_pressed = true
    resolution_option.select(2)
    quality_option.select(2)
    fog_slider.value = 0.35
    bloom_check.button_pressed = true

    master_slider.value = -6.0
    sfx_slider.value = -8.0
    music_slider.value = -12.0
    ambient_slider.value = -10.0

    text_scale_slider.value = 1.0
    colorblind_option.select(0)
    motion_toggle.button_pressed = true

    _apply_fullscreen(true)
    _apply_resolution(2)
    _apply_vsync(true)
    _apply_quality_preset(2)
    _apply_bus_volume("Master", -6.0)
    _apply_bus_volume("SFX", -8.0)
    _apply_bus_volume("Music", -12.0)
    _apply_bus_volume("Ambient", -10.0)
    _apply_text_scale(1.0)
    _apply_colorblind_mode(0)
    _apply_motion_toggle(true)

func _save_settings() -> void:
    var cfg := ConfigFile.new()

    # Video
    cfg.set_value(CONFIG_SECTION_VIDEO, "fullscreen", fullscreen_check.button_pressed)
    cfg.set_value(CONFIG_SECTION_VIDEO, "vsync", vsync_check.button_pressed)
    cfg.set_value(CONFIG_SECTION_VIDEO, "resolution_index", resolution_option.get_selected_id())
    cfg.set_value(CONFIG_SECTION_VIDEO, "quality_index", quality_option.get_selected_id())
    cfg.set_value(CONFIG_SECTION_VIDEO, "fog_density", fog_slider.value)
    cfg.set_value(CONFIG_SECTION_VIDEO, "bloom", bloom_check.button_pressed)

    # Audio
    cfg.set_value(CONFIG_SECTION_AUDIO, "master_db", master_slider.value)
    cfg.set_value(CONFIG_SECTION_AUDIO, "sfx_db", sfx_slider.value)
    cfg.set_value(CONFIG_SECTION_AUDIO, "music_db", music_slider.value)
    cfg.set_value(CONFIG_SECTION_AUDIO, "ambient_db", ambient_slider.value)

    # Accessibility
    cfg.set_value(CONFIG_SECTION_ACCESS, "text_scale", text_scale_slider.value)
    cfg.set_value(CONFIG_SECTION_ACCESS, "colorblind_index", colorblind_option.get_selected_id())
    cfg.set_value(CONFIG_SECTION_ACCESS, "motion_enabled", motion_toggle.button_pressed)

    var err := cfg.save(CONFIG_PATH)
    DebugLog.log("OptionsMenu", "SAVE", {
        "path": CONFIG_PATH,
        "result": err
    })

# -------------------------------------------------------------------
# Video handlers
# -------------------------------------------------------------------

func _on_back_pressed() -> void:
    DebugLog.log("OptionsMenu", "BACK", {})
    get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _on_apply_pressed() -> void:
    DebugLog.log("OptionsMenu", "APPLY", {
        "fullscreen": fullscreen_check.button_pressed,
        "vsync": vsync_check.button_pressed,
        "resolution_index": resolution_option.get_selected_id(),
        "quality_index": quality_option.get_selected_id(),
        "fog": fog_slider.value,
        "bloom": bloom_check.button_pressed,
        "master_db": master_slider.value,
        "text_scale": text_scale_slider.value
    })
    _save_settings()

func _on_fullscreen_toggled(pressed: bool) -> void:
    _apply_fullscreen(pressed)
    DebugLog.log("OptionsMenu", "FULLSCREEN", {"enabled": pressed})

func _apply_fullscreen(enabled: bool) -> void:
    var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
    DisplayServer.window_set_mode(mode)
    ProjectSettings.set_setting("display/window/size/mode", int(mode))
    ProjectSettings.save()

func _on_resolution_selected(index: int) -> void:
    _apply_resolution(index)

func _apply_resolution(index: int) -> void:
    if index < 0 or index >= RESOLUTIONS.size():
        return
    var res := RESOLUTIONS[index]
    DisplayServer.window_set_size(res)
    ProjectSettings.set_setting("display/window/size/viewport_width", res.x)
    ProjectSettings.set_setting("display/window/size/viewport_height", res.y)
    ProjectSettings.save()
    DebugLog.log("OptionsMenu", "RESOLUTION", {
        "width": res.x,
        "height": res.y
    })

func _on_vsync_toggled(pressed: bool) -> void:
    _apply_vsync(pressed)
    DebugLog.log("OptionsMenu", "VSYNC", {"enabled": pressed})

func _apply_vsync(enabled: bool) -> void:
    var mode := DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
    DisplayServer.window_set_vsync_mode(mode)

func _on_quality_selected(index: int) -> void:
    _apply_quality_preset(index)
    DebugLog.log("OptionsMenu", "QUALITY", {"level": index})

func _apply_quality_preset(index: int) -> void:
    if not QUALITY_PRESETS.has(index):
        return
    var preset := QUALITY_PRESETS[index]
    var fog_density := float(preset.get("fog_density", 0.35))
    var bloom_enabled := bool(preset.get("bloom", true))

    fog_slider.value = fog_density
    bloom_check.button_pressed = bloom_enabled

    _apply_fog_to_world(fog_density)
    _apply_bloom_to_world(bloom_enabled)

    # Optional future hooks: SSAO, shadow quality, LOD.
    # Here we log targeted values for later integration.
    DebugLog.log("OptionsMenu", "QUALITY_PRESET_APPLIED", preset)

func _on_fog_changed(value: float) -> void:
    _apply_fog_to_world(value)
    DebugLog.log("OptionsMenu", "FOG", {"density": value})

func _apply_fog_to_world(value: float) -> void:
    var env := _get_world_environment()
    if env and env.environment:
        var e := env.environment
        e.fog_enabled = value > 0.01
        e.fog_density = clamp(value, 0.0, 1.0)

func _on_bloom_toggled(pressed: bool) -> void:
    _apply_bloom_to_world(pressed)
    DebugLog.log("OptionsMenu", "BLOOM", {"enabled": pressed})

func _apply_bloom_to_world(enabled: bool) -> void:
    var env := _get_world_environment()
    if env and env.environment:
        var e := env.environment
        e.glow_enabled = enabled
        e.glow_intensity = 0.5 if enabled else 0.0

func _get_world_environment() -> WorldEnvironment:
    var nodes := get_tree().get_nodes_in_group("world_environment")
    if nodes.size() > 0 and nodes[0] is WorldEnvironment:
        return nodes[0]
    return null

# -------------------------------------------------------------------
# Audio handlers
# -------------------------------------------------------------------

func _apply_bus_volume(bus_name: String, db: float) -> void:
    var idx := AudioServer.get_bus_index(bus_name)
    if idx >= 0:
        AudioServer.set_bus_volume_db(idx, db)

func _on_master_volume_changed(value: float) -> void:
    _apply_bus_volume("Master", value)
    DebugLog.log("OptionsMenu", "MASTER_VOL", {"db": value})

func _on_sfx_volume_changed(value: float) -> void:
    _apply_bus_volume("SFX", value)
    DebugLog.log("OptionsMenu", "SFX_VOL", {"db": value})

func _on_music_volume_changed(value: float) -> void:
    _apply_bus_volume("Music", value)
    DebugLog.log("OptionsMenu", "MUSIC_VOL", {"db": value})

func _on_ambient_volume_changed(value: float) -> void:
    _apply_bus_volume("Ambient", value)
    DebugLog.log("OptionsMenu", "AMBIENT_VOL", {"db": value})

# -------------------------------------------------------------------
# Accessibility handlers
# -------------------------------------------------------------------

func _on_text_scale_changed(value: float) -> void:
    _apply_text_scale(value)
    DebugLog.log("OptionsMenu", "TEXT_SCALE", {"scale": value})

func _apply_text_scale(scale: float) -> void:
    # Broadcast to UI controllers; they rescale fonts/HUD.
    get_tree().call_group_flags(
        SceneTree.GROUP_CALL_DEFERRED,
        "runtime",
        "on_text_scale_changed",
        scale
    )

func _on_colorblind_selected(index: int) -> void:
    _apply_colorblind_mode(index)
    DebugLog.log("OptionsMenu", "COLORBLIND", {
        "mode_index": index,
        "mode_name": COLORBLIND_MODES.get(index, "Unknown")
    })

func _apply_colorblind_mode(index: int) -> void:
    get_tree().call_group_flags(
        SceneTree.GROUP_CALL_DEFERRED,
        "runtime",
        "on_color_profile_changed",
        index
    )

func _on_motion_toggled(pressed: bool) -> void:
    _apply_motion_toggle(pressed)
    DebugLog.log("OptionsMenu", "MOTION", {"enabled": pressed})

func _apply_motion_toggle(enabled: bool) -> void:
    # Example: tell camera controllers and post‑processing to clamp motion intensity.
    get_tree().call_group_flags(
        SceneTree.GROUP_CALL_DEFERRED,
        "runtime",
        "on_motion_settings_changed",
        enabled
    )
