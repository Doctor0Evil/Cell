extends Node
class_name SaveSystem

const SAVE_DIR := "user://saves/"
const PROFILE_FILE := "profile.json"

var current_profile: Dictionary = {}

func _ready() -> void:
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)
    DebugLog.log("SaveSystem", "READY", {"save_dir": SAVE_DIR})

static func has_any_profile() -> bool:
    return FileAccess.file_exists(SAVE_DIR + PROFILE_FILE)

func new_profile() -> void:
    current_profile = {
        "created_at": Time.get_unix_time_from_system(),
        "last_region": "ASHVEIL_DEBRIS_STRATUM",
        "vitality": 5.0,
        "instinct": 5.0,
        "tenacity": 5.0,
        "agility": 5.0,
        "logic": 5.0,
        "influence": 5.0,
        "temper": 5.0,
        "yield": 5.0
    }
    _save_profile()
    GameState.current_profile_id = &"default"
    DebugLog.log("SaveSystem", "NEW_PROFILE", current_profile)

func load_last_profile() -> void:
    if not has_any_profile():
        DebugLog.log("SaveSystem", "LOAD_SKIPPED_NO_PROFILE", {})
        return
    var f := FileAccess.open(SAVE_DIR + PROFILE_FILE, FileAccess.READ)
    if f == null:
        DebugLog.log("SaveSystem", "LOAD_FAILED_FILE", {})
        return
    var text := f.get_as_text()
    var data := JSON.parse_string(text)
    if typeof(data) == TYPE_DICTIONARY:
        current_profile = data
        var region := StringName(current_profile.get("last_region", "ASHVEIL_DEBRIS_STRATUM"))
        GameState.current_profile_id = &"default"
        DebugLog.log("SaveSystem", "PROFILE_LOADED", {
            "region": String(region)
        })
        GameState.load_region(region)
    else:
        DebugLog.log("SaveSystem", "LOAD_FAILED_PARSE", {})

func save_run(vsys: PlayerVitalitySystem) -> void:
    if current_profile.is_empty():
        return
    current_profile["vitality"] = vsys.vitality
    current_profile["instinct"] = vsys.instinct
    current_profile["tenacity"] = vsys.tenacity
    current_profile["agility"] = vsys.agility
    current_profile["logic"] = vsys.logic
    current_profile["influence"] = vsys.influence
    current_profile["temper"] = vsys.temper
    current_profile["yield"] = vsys.yield
    current_profile["last_region"] = String(GameState.current_region_id)
    _save_profile()
    DebugLog.log("SaveSystem", "RUN_SAVED", {
        "last_region": current_profile["last_region"]
    })

func _save_profile() -> void:
    var f := FileAccess.open(SAVE_DIR + PROFILE_FILE, FileAccess.WRITE)
    if f == null:
        push_error("Failed to open save file.")
        DebugLog.log("SaveSystem", "SAVE_FAILED_FILE", {})
        return
    f.store_string(JSON.stringify(current_profile))
    f.flush()
    DebugLog.log("SaveSystem", "PROFILE_SAVED", {})
