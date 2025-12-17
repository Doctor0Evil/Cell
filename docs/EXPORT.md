Windows export guide

1. Open the project in Godot 4.
2. Open Project → Export.
3. Add a preset: "Windows Desktop".
   - Architecture: x86_64
   - Main Scene: res://scenes/ui/MainMenu.tscn
   - Icon: res://ASSETS/icons/cell_icon.ico (if present)
   - Embed PCK or not depending on distribution.
4. Export to a target folder to produce a .exe.

Tip: Run `res://scripts/tools/build_config.gd` methods from the editor to apply default settings programmatically (call `BuildConfig.apply_default_windows_settings()`).