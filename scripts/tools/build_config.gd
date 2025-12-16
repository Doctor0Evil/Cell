extends Node
class_name BuildConfig

static func apply_default_windows_settings() -> void:
    ProjectSettings.set_setting("display/window/size/viewport_width", 1920)
    ProjectSettings.set_setting("display/window/size/viewport_height", 1080)
    ProjectSettings.set_setting("application/config/name", "CELL")
    ProjectSettings.set_setting("application/config/icon", "res://ASSETS/icons/cell_icon.ico")
    ProjectSettings.save()
