--[[
  Growlers_AIBehavior.lua
  Companion AI behavior layer for Growlers (state transitions, sound mapping,
  taboo hook adapters). Designed to be engine-agnostic and to signal to
  encounter director / ritual manager via world_api hooks.

  Depends (optionally) on:
    - cell.lore.space.Growlers_Pselgrova
    - cell.systems.space.TabooRitualManager (for inspect-corpse integration)
    - Encounter director via world_api.signal_growler_director
]]

local ok_lore, GrowlerLore = pcall(require, "cell.lore.space.Growlers_Pselgrova")
local ok_ritual, TabooRitualManager = pcall(require, "cell.systems.space.TabooRitualManager")

local Growlers_AIBehavior = {}

----------------------------------------------------------------------
--  CONFIG / SOUND MAP
----------------------------------------------------------------------

Growlers_AIBehavior.sound_map = {
  patrol           = "growler_patrol_breath",
  patrol_hurt      = "growler_patrol_whine_long",
  stalk_from_vents = "growler_vent_clicks_soft",
  stalk_hurt       = "growler_vent_scrape_hurt",
  solo_pounce      = "growler_lunge_snarl",
  pack_charge      = "growler_pack_howl_sync",
  pack_charge_broken = "growler_pack_howl_broken",
  inspect_corpse   = "growler_investigate_thump"
}

----------------------------------------------------------------------
--  TABOO HOOKS / EVENTS
----------------------------------------------------------------------

-- Called by the engine (or TabooRitualManager) when a taboo violation is escalated
-- payload: { player_id, taboo_id, location_entity }
function Growlers_AIBehavior.on_taboo_violation_escalated(world_api, payload)
  -- Best-effort: notify encounter director via world_api signaling.
  if world_api and world_api.signal_growler_director then
    world_api.signal_growler_director("TABOO_FEIGN_DEATH_ESCALATED", payload)
  end

  -- Increase local ambient tension if world_api supports it.
  if world_api and world_api.add_tension then
    world_api.add_tension(0.2)
  end
end

-- Interface for world to call when a corpse-inspect triggers growler interest.
-- context: { location_entity, position={x,y,z}, player_id }
function Growlers_AIBehavior.trigger_inspect_corpse_response(world_api, context)
  -- Notify director to schedule an "inspect_corpse" focused pack.
  if world_api and world_api.signal_growler_director then
    world_api.signal_growler_director("INSPECT_CORPSE_FOCUS", {
      location_entity = context.location_entity,
      position = context.position,
      player_id = context.player_id
    })
  end

  -- Also play an immediate close 3D sound to escalate dread.
  if world_api and world_api.play_3d_sound and context.position then
    world_api.play_3d_sound(Growlers_AIBehavior.sound_map.inspect_corpse, context.position)
  end
end

----------------------------------------------------------------------
--  WORLD HOOK REGISTRATION (engine calls this once at init)
----------------------------------------------------------------------

-- world_api should provide:
--   register_listener(event_name, callback)
--   play_3d_sound(name, position)
--   signal_growler_director(event_name, payload)
function Growlers_AIBehavior.register_world_hooks(world_api)
  if not world_api or not world_api.register_listener then
    return false, "world_api missing register_listener"
  end

  -- Taboo escalation from TabooRitualManager (if present) or the engine.
  world_api.register_listener("TABOO_FEIGN_DEATH_BROKEN", function(payload)
    -- Lean on TabooRitualManager to register and decide escalation.
    if ok_ritual and TabooRitualManager.register_taboo_violation then
      local count = TabooRitualManager.register_taboo_violation(payload.player_id, payload.taboo_id)
      if count > (TabooRitualManager.config and TabooRitualManager.config.taboo_grace_uses or 1) then
        Growlers_AIBehavior.on_taboo_violation_escalated(world_api, payload)
      else
        -- give soft feedback
        if world_api.show_inspect_text then
          world_api.show_inspect_text("You hold so still the vents sound closer.")
        end
      end
    else
      -- Default: escalate immediately
      Growlers_AIBehavior.on_taboo_violation_escalated(world_api, payload)
    end
  end)

  -- Engine may emit player inspect events for corpses; listen and forward
  world_api.register_listener("PLAYER_INSPECT_CORPSE", function(ctx)
    -- ctx: { player_id, corpse_entity_id, corpse_profile_id, position, is_feigning }
    if ctx.is_feigning and ctx.in_growler_territory then
      -- delegate to TabooRitualManager to count/act
      if ok_ritual and TabooRitualManager.inspect_corpse then
        TabooRitualManager.inspect_corpse(world_api, {
          player_id = ctx.player_id,
          corpse_entity_id = ctx.corpse_entity_id,
          corpse_profile_id = ctx.corpse_profile_id,
          is_player_feigning_death = true,
          in_growler_territory = ctx.in_growler_territory
        })
      else
        -- fallback: escalate
        Growlers_AIBehavior.on_taboo_violation_escalated(world_api, { player_id = ctx.player_id, taboo_id = "TABSCELLFEIGNDEATH01", location_entity = ctx.corpse_entity_id })
      end
    else
      -- Regular inspect -> open investigation/puzzle; inform ritual manager
      if ok_ritual and TabooRitualManager.inspect_corpse then
        TabooRitualManager.inspect_corpse(world_api, {
          player_id = ctx.player_id,
          corpse_entity_id = ctx.corpse_entity_id,
          corpse_profile_id = ctx.corpse_profile_id,
          is_player_feigning_death = false,
          in_growler_territory = ctx.in_growler_territory,
          time_focused = ctx.time_focused or 0.0,
          flags = ctx.flags or {}
        })
      end

      -- Trigger a localized response so the director can optionally investigate.
      Growlers_AIBehavior.trigger_inspect_corpse_response(world_api, { location_entity = ctx.corpse_entity_id, position = ctx.position, player_id = ctx.player_id })
    end
  end)

  return true
end

----------------------------------------------------------------------
--  UTILS: SOUND LOOKUP (for audio state updates)
----------------------------------------------------------------------

function Growlers_AIBehavior.get_sound_for_state(state, broken)
  if state == "patrol" and broken then
    return Growlers_AIBehavior.sound_map.patrol_hurt
  end
  if state == "stalk_from_vents" and broken then
    return Growlers_AIBehavior.sound_map.stalk_hurt
  end
  if state == "pack_charge" and broken then
    return Growlers_AIBehavior.sound_map.pack_charge_broken
  end
  return Growlers_AIBehavior.sound_map[state] or "growler_patrol_breath"
end

----------------------------------------------------------------------
--  EXPORT
----------------------------------------------------------------------

return Growlers_AIBehavior
