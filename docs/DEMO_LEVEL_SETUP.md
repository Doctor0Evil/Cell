This file describes how to run the Level01 demo scene locally in Godot 4.

Steps:

1) Open the project in Godot 4 (if you don't have a `project.godot`, create a new Godot project and point the project folder here).

2) Add the following AutoLoads (Project Settings -> AutoLoad):
   - `res://scripts/core/GameState.gd` as `GameState`
   - `res://scripts/core/asset_registry.gd` as `AssetRegistry` (if present)
   - `res://scripts/core/DebugLog.gd` as `DebugLog` (if present) or use your own logging autoload

3) Open the demo scene: `res://scenes/world/Level01.tscn` and run it.

Notes:
- The `MissionColdVergeOxygenRun` instance uses Area3D triggers; to start the mission, move a `player` node into the `StartTrigger` area or call the mission's public methods from the editor.
- `MissionHUD` listens on the `runtime` group for mission events (`on_objective_update`, `on_mission_update`, `on_mission_oxygen_tick`, `on_mission_started`, `on_mission_complete`, `on_mission_failed`).
- Debug logging is enabled by default on new scripts using `@export var debug_enabled: bool = true`. Disable per-node in the inspector to quiet logs.
