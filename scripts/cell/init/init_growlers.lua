-- init_growlers.lua
-- Call this from your bootstrap with world_api to register Growler systems.
local Growlers_AIBehavior = pcall(require, "cell.ai.space.Growlers_AIBehavior") and require("cell.ai.space.Growlers_AIBehavior") or nil
local TabooRitualManager = pcall(require, "cell.systems.space.TabooRitualManager") and require("cell.systems.space.TabooRitualManager") or nil
local GrowlerDirectorIntegration = pcall(require, "cell.ai.space.GrowlerDirectorIntegration") and require("cell.ai.space.GrowlerDirectorIntegration") or nil

return function(world_api)
  if Growlers_AIBehavior and Growlers_AIBehavior.register_world_hooks then
    Growlers_AIBehavior.register_world_hooks(world_api)
  end

  if GrowlerDirectorIntegration and GrowlerDirectorIntegration.register_director_hooks then
    GrowlerDirectorIntegration.register_director_hooks(world_api)
  end

  -- Expose helper binding for engine-side interactions (e.g. PlayerInspect in Godot)
  if TabooRitualManager and TabooRitualManager.inspect_corpse then
    world_api.inspect_corpse = function(context)
      return TabooRitualManager.inspect_corpse(world_api, context)
    end
  end
end
