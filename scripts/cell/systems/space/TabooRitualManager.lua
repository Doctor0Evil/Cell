--[[
  TabooRitualManager.lua
  Manages rituals, taboos, and corpse inspection for Hades-Theta.
  Lightweight, engine-bridged module that provides 'inspect corpse' as both
  an investigative verb and a taboo hook that can notify the encounter director.
]]

local GrowlerLore = nil
pcall(function() GrowlerLore = require("cell.lore.space.Growlers_Pselgrova") end)

local TabooRitualManager = {}

----------------------------------------------------------------------
--  CONFIG & REGISTRY
----------------------------------------------------------------------

TabooRitualManager.config = {
  taboo_grace_uses = 1,
  corpse_inspect_focus_time = 2.5,
  puzzle_hint_chance = 0.65
}

TabooRitualManager.taboo_violations = {}
TabooRitualManager.ritual_progress = {}

TabooRitualManager.corpse_profiles = {
  GENERIC_CREW = {
    id = "CORPSE_PROFILE_GENERIC_CREW",
    description_layers = {
      surface = {
        "Body slumped against the bulkhead, visor fogged from the inside.",
        "Standard work harness, pockets half-turned as if someone searched in a hurry."
      },
      detail = {
        "There’s a smear of blue frost across the jawline, like something chewed from within.",
        "Badge is cracked; only the first three letters of the surname remain."
      }
    },
    puzzle_hooks = {
      {
        id = "PUZZLE_DATASTRIP_LOCKER_C19",
        requirement_flag = "QUEST_C19_LOCKER_KNOWN",
        grant_flag = "QUEST_C19_LOCKER_CODE_FOUND",
        hint_text = "A datastrip wedged under the chest rig blinks faintly.",
        on_grant = function(world_api, player_id, corpse_entity_id)
          if world_api and world_api.grant_item then
            world_api.grant_item(player_id, "ITEM_DATASTRIP_LOCKER_C19")
          end
        end
      }
    }
  },

  ENGINEER_GROWLER_VICTIM = {
    id = "CORPSE_PROFILE_ENGINEER_GROWLER_VICTIM",
    description_layers = {
      surface = {
        "Exosuit torn open at the throat; helmet glass bitten through from the inside.",
        "Hands still clenched around a maintenance tablet, screen long dead."
      },
      detail = {
        "Teeth marks along the collar ring don’t match human spacing.",
        "Under the suit, the ribs seem cracked outward, as if something pushed to escape."
      }
    },
    puzzle_hooks = {
      {
        id = "PUZZLE_VENT_ROUTE_MAP",
        requirement_flag = nil,
        grant_flag = "MAP_VENT_NETWORK_UNLOCKED",
        hint_text = "Tablet flickers when you tap it; a schematic of vent routes blinks on for a moment.",
        on_grant = function(world_api, player_id, corpse_entity_id)
          if world_api and world_api.reveal_map_layer then
            world_api.reveal_map_layer("VENT_NETWORK_LEVEL_C")
          end
        end
      }
    }
  }
}

----------------------------------------------------------------------
--  TABOO VIOLATION TRACKING
----------------------------------------------------------------------

local function get_violation_table(player_id)
  local t = TabooRitualManager.taboo_violations[player_id]
  if not t then t = {} TabooRitualManager.taboo_violations[player_id] = t end
  return t
end

function TabooRitualManager.register_taboo_violation(player_id, taboo_id)
  local t = get_violation_table(player_id)
  local c = t[taboo_id] or 0
  t[taboo_id] = c + 1
  return t[taboo_id]
end

function TabooRitualManager.get_violation_count(player_id, taboo_id)
  local t = get_violation_table(player_id)
  return t[taboo_id] or 0
end

----------------------------------------------------------------------
--  CORPSE INSPECTION: MAIN ENTRY POINT
----------------------------------------------------------------------

-- context: see user module for fields
function TabooRitualManager.inspect_corpse(world_api, context)
  local profile = TabooRitualManager.corpse_profiles[context.corpse_profile_id or "GENERIC_CREW"]
  if not profile then profile = TabooRitualManager.corpse_profiles.GENERIC_CREW end

  local player_id = context.player_id
  local taboo_feign = GrowlerLore and GrowlerLore.taboos and GrowlerLore.taboos.FEIGN_DEATH and GrowlerLore.taboos.FEIGN_DEATH.id or "TABSCELLFEIGNDEATH01"

  if context.is_player_feigning_death and context.in_growler_territory then
    local count = TabooRitualManager.register_taboo_violation(player_id, taboo_feign)

    if count <= TabooRitualManager.config.taboo_grace_uses then
      if world_api and world_api.show_inspect_text then
        world_api.show_inspect_text("You go still, counting breaths. Somewhere in the ducts, something counts with you.")
      end
    else
      -- Escalate: signal director / AI layer
      if world_api and world_api.signal_growler_director then
        world_api.signal_growler_director("TABOO_FEIGN_DEATH_BROKEN", {
          player_id = player_id,
          taboo_id = taboo_feign,
          location_entity = context.corpse_entity_id
        })
      end
      if world_api and world_api.show_inspect_text then
        world_api.show_inspect_text("You hold your breath. The vents answer with a new one, closer than before.")
      end
    end

    return
  end

  -- Regular corpse inspection logic (investigation / light puzzle)
  if (context.time_focused or 0.0) < TabooRitualManager.config.corpse_inspect_focus_time then
    if world_api and world_api.show_inspect_text then
      local line = profile.description_layers.surface and profile.description_layers.surface[1]
      if line then world_api.show_inspect_text(line) end
    end
    return
  end

  -- Deeper description
  if world_api and world_api.show_inspect_text then
    local detail_lines = profile.description_layers.detail
    if detail_lines and #detail_lines > 0 then
      local idx = math.random(1, #detail_lines)
      world_api.show_inspect_text(detail_lines[idx])
    end
  end

  -- Possibly trigger puzzle hook
  local hooks = profile.puzzle_hooks or {}
  if #hooks > 0 and math.random() < TabooRitualManager.config.puzzle_hint_chance then
    for _, hook in ipairs(hooks) do
      local already = world_api.get_flag and world_api.get_flag(hook.grant_flag)
      if not already then
        if not hook.requirement_flag or (world_api.get_flag and world_api.get_flag(hook.requirement_flag)) then
          if world_api.set_flag then world_api.set_flag(hook.grant_flag, true) end
          if hook.on_grant then hook.on_grant(world_api, player_id, context.corpse_entity_id) end
          if hook.hint_text and world_api.show_inspect_text then world_api.show_inspect_text(hook.hint_text) end
          break
        end
      end
    end
  end

  -- Always notify Director/AI that a normal inspection occurred so it can optionally investigate
  if world_api and world_api.signal_growler_director then
    world_api.signal_growler_director("CORPSE_INSPECTED", {
      player_id = player_id,
      location_entity = context.corpse_entity_id,
      position = context.position
    })
  end
end

----------------------------------------------------------------------
--  RITUAL PROGRESS / DEBUG
----------------------------------------------------------------------

local function get_ritual_state(player_id, ritual_id)
  local per_player = TabooRitualManager.ritual_progress[player_id]
  if not per_player then per_player = {} TabooRitualManager.ritual_progress[player_id] = per_player end
  local st = per_player[ritual_id]
  if not st then st = { completed_steps = {}, done = false } per_player[ritual_id] = st end
  return st
end

function TabooRitualManager.mark_ritual_step(world_api, player_id, ritual_id, step_index, location_id)
  local ritual = TabooRitualManager.rituals and TabooRitualManager.rituals[ritual_id]
  if not ritual then return end
  local st = get_ritual_state(player_id, ritual_id)
  if st.done then return end

  st.completed_steps[step_index] = true

  local all_done = true
  for i = 1, #ritual.steps do if not st.completed_steps[i] then all_done = false break end end

  if all_done then
    st.done = true
    if ritual.system_hooks and ritual.system_hooks.on_completed then
      ritual.system_hooks.on_completed(world_api, player_id, location_id)
    end
  end
end

function TabooRitualManager.reset_player(player_id)
  TabooRitualManager.taboo_violations[player_id] = nil
  TabooRitualManager.ritual_progress[player_id] = nil
end

function TabooRitualManager.get_debug(player_id)
  return { taboo_violations = TabooRitualManager.taboo_violations[player_id], ritual_progress = TabooRitualManager.ritual_progress[player_id] }
end

----------------------------------------------------------------------
--  EXPORT
----------------------------------------------------------------------

return TabooRitualManager
