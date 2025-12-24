Growler Director Integration — Quick Setup

Overview
--------
This document explains how to wire the Lua growler systems with the Godot runtime using the provided engine-agnostic WorldAPI and EventBus.

Files added:
- scripts/cell/ai/space/GrowlerDirectorIntegration.lua
- scripts/cell/init/init_growlers.lua
- res/scripts/WorldAPI.gd (Autoload as `WorldAPI`)
- res/scripts/EventBus.gd (Autoload as `EventBus`)
- res/scripts/GrowlerDirector.gd (Autoload or placed at /root/GrowlerDirector)
- res/scripts/PlayerInspect.gd (attach to player)

Godot setup
-----------
1. Add `res/scripts/WorldAPI.gd` and `res/scripts/EventBus.gd` as singletons (Project Settings -> Autoload).
2. Add a `GrowlerDirector` node to your main scene or make `GrowlerDirector.gd` an autoload.
3. Assign `growler_pack_scene` on `GrowlerDirector.gd` to a `GrowlerPack.tscn` scene.
4. Ensure `PlayerInspect.gd` is attached to the player node and that corpses have `corpse_profile_id` meta set.

Lua init
--------
Call the initializer at game bootstrap with the `world_api` bridge (WorldAPI methods exposed to Lua):

local init_growlers = require("cell.init.init_growlers")
init_growlers(world_api)

This will register Lua listeners and expose `world_api.inspect_corpse` helper.

Notes
-----
- The engine expects a small API on WorldAPI (schedule_growler_pack, play_3d_sound, add_tension, register_listener, get_time, show_inspect_text, grant_item, reveal_map_layer, set_flag, get_flag).
- See `scripts/cell/ai/Growlers_AIBehavior.lua` and `scripts/cell/systems/space/TabooRitualManager.lua` for example usage and event names.

Next steps
----------
- Create a `GrowlerPack.tscn` with script hooks `set_target_player_id`, `set_encounter_reason` and lifecycle behaviors.
- Add debug UI to show active_investigations and cooldowns while tuning.
