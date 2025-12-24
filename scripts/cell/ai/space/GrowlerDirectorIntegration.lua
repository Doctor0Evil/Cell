--[[
  GrowlerDirectorIntegration.lua
  High-level encounter director glue for corpse-inspection / taboo events.
  Engine-agnostic: expects world_api to implement schedule_growler_pack, add_tension,
  get_time, register_listener and play_3d_sound (optional).
]]

local GrowlerDirectorIntegration = {}

local _state = {
  active_investigations = {},
  global_cooldowns = {},
  config = {
    investigation_cooldown = 30.0,
    max_parallel_investigations = 3,
    base_tension_gain = 5,
    feign_death_bonus_tension = 10,
    focus_radius = 18.0
  },
  world_api = nil
}

local function _now(world_api)
  if world_api and world_api.get_time then return world_api.get_time() end
  return os.time()
end

local function _is_on_cooldown(key, world_api)
  local cd = _state.global_cooldowns[key]
  if not cd then return false end
  local t = _now(world_api)
  return t < cd
end

local function _set_cooldown(key, duration, world_api)
  local t = _now(world_api)
  _state.global_cooldowns[key] = t + duration
end

local function _count_active_investigations()
  local n = 0
  for _, inv in pairs(_state.active_investigations) do
    if inv.active then n = n + 1 end
  end
  return n
end

local function _start_investigation(key, payload)
  _state.active_investigations[key] = {
    active = true,
    started_at = _now(_state.world_api),
    payload = payload
  }
end

local function _end_investigation(key)
  local inv = _state.active_investigations[key]
  if inv then inv.active = false end
end

function GrowlerDirectorIntegration.schedule_inspect_corpse_investigation(world_api, payload)
  _state.world_api = world_api

  if _count_active_investigations() >= _state.config.max_parallel_investigations then return end

  local key = payload.location_entity or payload.corpse_entity_id or ("loc_" .. tostring((payload.position and payload.position.x) or "0") .. "_" .. tostring((payload.position and payload.position.z) or "0"))

  if _is_on_cooldown(key, world_api) then return end

  _start_investigation(key, payload)
  _set_cooldown(key, _state.config.investigation_cooldown, world_api)

  if world_api and world_api.schedule_growler_pack then
    world_api.schedule_growler_pack({
      type = "investigation",
      focus_position = payload.position,
      focus_radius = _state.config.focus_radius,
      target_player_id = payload.player_id,
      reason = payload.reason or "INSPECT_CORPSE",
      taboo_id = payload.taboo_id
    })
  end

  if world_api and world_api.add_tension then
    world_api.add_tension(_state.config.base_tension_gain)
  end
end

function GrowlerDirectorIntegration.handle_taboo_feign_death_broken(world_api, payload)
  _state.world_api = world_api

  local key = payload.taboo_id or "TABOO_FEIGN_DEATH_BROKEN"
  if _is_on_cooldown(key, world_api) then return end

  _set_cooldown(key, _state.config.investigation_cooldown * 2, world_api)

  if world_api and world_api.schedule_growler_pack then
    world_api.schedule_growler_pack({
      type = "hunt",
      focus_position = payload.position,
      focus_radius = _state.config.focus_radius,
      target_player_id = payload.player_id,
      reason = "TABOO_FEIGN_DEATH_BROKEN",
      taboo_id = payload.taboo_id
    })
  end

  if world_api and world_api.add_tension then
    world_api.add_tension(_state.config.base_tension_gain + _state.config.feign_death_bonus_tension)
  end

  if world_api and world_api.play_3d_sound and payload.position then
    world_api.play_3d_sound("growler_alert_taboo", payload.position)
  end
end

function GrowlerDirectorIntegration.on_investigation_resolved(world_api, key)
  _state.world_api = world_api
  _end_investigation(key)
end

function GrowlerDirectorIntegration.register_director_hooks(world_api)
  _state.world_api = world_api
  if not world_api or not world_api.register_listener then return end

  world_api.register_listener("TABOO_FEIGN_DEATH_BROKEN", function(payload)
    GrowlerDirectorIntegration.handle_taboo_feign_death_broken(world_api, payload)
  end)

  world_api.register_listener("CORPSE_INSPECTED", function(payload)
    payload.reason = payload.reason or "CORPSE_INSPECTED"
    GrowlerDirectorIntegration.schedule_inspect_corpse_investigation(world_api, payload)
  end)

  world_api.register_listener("INSPECT_CORPSE_FOCUS", function(payload)
    payload.reason = payload.reason or "INSPECT_CORPSE_FOCUS"
    GrowlerDirectorIntegration.schedule_inspect_corpse_investigation(world_api, payload)
  end)
end

return GrowlerDirectorIntegration
