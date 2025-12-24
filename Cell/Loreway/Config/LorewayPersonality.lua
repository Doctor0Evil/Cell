-- Path: /Cell/Loreway/Config/LorewayPersonality.lua
-- Purpose: Personality-vector + brutality automation for Loreway-driven systems.
-- Any AI chat, IDE agent, or in-game tool calls this to align output with Cell.

local LorewayPersonality = {}

----------------------------------------------------------------------
-- Core scalar and vector types
----------------------------------------------------------------------

---@class BrutalityProfile
---@field global number                -- 0.0–1.0
---@field physical number              -- 0.0–1.0
---@field psychological number         -- 0.0–1.0
---@field social number                -- 0.0–1.0

---@class HorrorVector
---@field dread number                 -- 0.0–1.0
---@field shock number
---@field disgust number
---@field uncanny number
---@field moral_anxiety number

---@class SlavicToneVector
---@field rural_decay number           -- panelki, wet forests, collapsing farms
---@field bureaucratic_horror number   -- documents, offices, quotas, trials
---@field domestic_haunting number     -- apartments, family, neighbors
---@field cosmic_rot number            -- slow metaphysical infection

---@class LorewayPersonalityProfile
---@field id string
---@field label string
---@field brutality BrutalityProfile
---@field horror HorrorVector
---@field slavic SlavicToneVector
---@field surreal_temperature number   -- 0.0–1.0
---@field narrative_temperature number -- 0.0–1.0
---@field horror_temperature number    -- 0.0–1.0

----------------------------------------------------------------------
-- Default Cell-wide personality
----------------------------------------------------------------------

local DEFAULT_PROFILE = {
    id    = "CELL_CORE_DEFAULT",
    label = "Cell Core – Wet Forest Bureaucratic Rot",

    brutality = {
        global        = 0.85,
        physical      = 0.80,
        psychological = 0.95,
        social        = 0.90,
    },

    horror = {
        dread         = 0.95,
        shock         = 0.80,
        disgust       = 0.75,
        uncanny       = 0.85,
        moral_anxiety = 1.00,
    },

    slavic = {
        rural_decay         = 0.95,
        bureaucratic_horror = 0.90,
        domestic_haunting   = 0.85,
        cosmic_rot          = 0.70,
    },

    surreal_temperature   = 0.55,
    narrative_temperature = 0.70,
    horror_temperature    = 0.80,
}

LorewayPersonality.DEFAULT_PROFILE = DEFAULT_PROFILE



----------------------------------------------------------------------
-- Utility helpers
----------------------------------------------------------------------

local function clamp01(x)
    if x < 0.0 then return 0.0 end
    if x > 1.0 then return 1.0 end
    return x
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function deep_copy(tbl)
    local out = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            out[k] = deep_copy(v)
        else
            out[k] = v
        end
    end
    return out
end

----------------------------------------------------------------------
-- Personality construction and blending
----------------------------------------------------------------------

---Create a new personality by overriding defaults with partial fields.
---@param id string
---@param label string
---@param overrides table|nil
---@return LorewayPersonalityProfile
function LorewayPersonality.new_profile(id, label, overrides)
    local p = deep_copy(DEFAULT_PROFILE)
    p.id = id or p.id
    p.label = label or p.label

    overrides = overrides or {}

    local function merge_scalar(path, defaultValue)
        local t = overrides
        for i = 1, #path - 1 do
            local key = path[i]
            t = t[key]
            if t == nil then return end
        end
        local leaf = path[#path]
        if t and t[leaf] ~= nil then
            local current = p
            for i = 1, #path - 1 do
                current = current[path[i]]
            end
            current[leaf] = clamp01(t[leaf])
        end
    end

    -- Brutality
    merge_scalar({ "brutality", "global" }, p.brutality.global)
    merge_scalar({ "brutality", "physical" }, p.brutality.physical)
    merge_scalar({ "brutality", "psychological" }, p.brutality.psychological)
    merge_scalar({ "brutality", "social" }, p.brutality.social)

    -- Horror
    merge_scalar({ "horror", "dread" }, p.horror.dread)
    merge_scalar({ "horror", "shock" }, p.horror.shock)
    merge_scalar({ "horror", "disgust" }, p.horror.disgust)
    merge_scalar({ "horror", "uncanny" }, p.horror.uncanny)
    merge_scalar({ "horror", "moral_anxiety" }, p.horror.moral_anxiety)

    -- Slavic tones
    merge_scalar({ "slavic", "rural_decay" }, p.slavic.rural_decay)
    merge_scalar({ "slavic", "bureaucratic_horror" }, p.slavic.bureaucratic_horror)
    merge_scalar({ "slavic", "domestic_haunting" }, p.slavic.domestic_haunting)
    merge_scalar({ "slavic", "cosmic_rot" }, p.slavic.cosmic_rot)

    -- Temperatures
    if overrides.surreal_temperature ~= nil then
        p.surreal_temperature = clamp01(overrides.surreal_temperature)
    end
    if overrides.narrative_temperature ~= nil then
        p.narrative_temperature = clamp01(overrides.narrative_temperature)
    end
    if overrides.horror_temperature ~= nil then
        p.horror_temperature = clamp01(overrides.horror_temperature)
    end

    return p
end

---Blend two profiles over t (0..1).
---@param a LorewayPersonalityProfile
---@param b LorewayPersonalityProfile
---@param t number
---@return LorewayPersonalityProfile
function LorewayPersonality.blend_profiles(a, b, t)
    t = clamp01(t)
    local p = deep_copy(a)
    p.id    = a.id .. "_BLEND_" .. b.id
    p.label = "Blend(" .. a.label .. ", " .. b.label .. ")"

    local function blend_field(path)
        local left = a
        local right = b
        local dest = p
        for i = 1, #path - 1 do
            left  = left[path[i]]
            right = right[path[i]]
            dest  = dest[path[i]]
        end
        local k = path[#path]
        dest[k] = clamp01(lerp(left[k], right[k], t))
    end

    -- Brutality
    blend_field({ "brutality", "global" })
    blend_field({ "brutality", "physical" })
    blend_field({ "brutality", "psychological" })
    blend_field({ "brutality", "social" })

    -- Horror
    blend_field({ "horror", "dread" })
    blend_field({ "horror", "shock" })
    blend_field({ "horror", "disgust" })
    blend_field({ "horror", "uncanny" })
    blend_field({ "horror", "moral_anxiety" })

    -- Slavic tones
    blend_field({ "slavic", "rural_decay" })
    blend_field({ "slavic", "bureaucratic_horror" })
    blend_field({ "slavic", "domestic_haunting" })
    blend_field({ "slavic", "cosmic_rot" })

    -- Temperatures
    p.surreal_temperature   = clamp01(lerp(a.surreal_temperature,   b.surreal_temperature,   t))
    p.narrative_temperature = clamp01(lerp(a.narrative_temperature, b.narrative_temperature, t))
    p.horror_temperature    = clamp01(lerp(a.horror_temperature,    b.horror_temperature,    t))

    return p
end



----------------------------------------------------------------------
-- KG-aware scoring helpers
-- These functions operate on KG node tables that match Loreway schemas.
----------------------------------------------------------------------

---Score an Event node under a personality profile.
---@param eventNode table  -- Loreway Event_Node
---@param personality LorewayPersonalityProfile
---@return number
function LorewayPersonality.score_event(eventNode, personality)
    if eventNode.external_reference_allowed then
        -- Hard IP wall: never use externally-referenced content.
        return -math.huge
    end

    local score = 0.0
    local b = personality.brutality
    local h = personality.horror

    -- Base by event type (local_catastrophe, ritual_failure, disappearance, etc.).
    local t = eventNode.type or ""
    if t == "local_catastrophe" then
        score = score + 2.0 * personality.horror_temperature
        score = score + 1.5 * b.global
    elseif t == "ritual_failure" then
        score = score + 1.5 * personality.narrative_temperature
        score = score + 1.0 * b.physical
    elseif t == "disappearance" then
        score = score + 1.2 * h.dread + 1.2 * b.psychological
    else
        score = score + 0.5
    end

    -- Consequences: more harms = higher score when brutal.
    local cons = eventNode.consequences or {}
    local harmCount = #cons
    score = score + harmCount * 0.3 * b.global

    -- Tag-sensitive: children, plague, famine, betrayal, etc.
    local tags = eventNode.narrative_tags or {}
    for _, tag in ipairs(tags) do
        if tag == "origin_legend" then
            score = score + 0.5 * h.uncanny
        elseif tag == "plague" or tag == "disease" then
            score = score + 0.7 * b.physical
        elseif tag == "betrayal" then
            score = score + 0.8 * b.social + 0.5 * b.psychological
        elseif tag == "justifies_tabu" then
            score = score + 0.5 * h.moral_anxiety
        end
    end

    -- Brutality ramp: at high settings, prefer catastrophic events.
    if b.global > 0.8 and personality.horror_temperature > 0.7 then
        if t == "local_catastrophe" or t == "ritual_failure" then
            score = score + 1.5
        end
    end

    return score
end

---Score a Rumor node under personality.
---@param rumorNode table  -- Loreway Rumor_Node
---@param personality LorewayPersonalityProfile
---@return number
function LorewayPersonality.score_rumor(rumorNode, personality)
    if rumorNode.external_reference_allowed then
        return -math.huge
    end

    local score = 0.0
    local b = personality.brutality
    local h = personality.horror

    -- Rumors are more valuable for psychological and social brutality.
    score = score + 1.0 * b.psychological + 0.8 * b.social

    if rumorNode.truth_status == "partial" or rumorNode.truth_status == "unknown" then
        score = score + 0.8 * h.moral_anxiety
    elseif rumorNode.truth_status == "false" then
        score = score + 0.3 * h.uncanny
    end

    if rumorNode.topic == "disappearance" then
        score = score + 0.6 * h.dread
    end

    return score
end

---Score a DialogueUnit-like block.
---@param dialogueUnit table
---@param personality LorewayPersonalityProfile
---@return number
function LorewayPersonality.score_dialogue(dialogueUnit, personality)
    if dialogueUnit.external_reference_allowed then
        return -math.huge
    end

    local score = 0.0
    local b = personality.brutality
    local h = personality.horror

    local hf = dialogueUnit.horror_function or ""
    if hf == "dread" then
        score = score + 1.0 * h.dread
    elseif hf == "shock" then
        score = score + 1.0 * h.shock + 0.5 * b.physical
    elseif hf == "disgust" then
        score = score + 1.0 * h.disgust + 0.5 * b.physical
    elseif hf == "uncanny" then
        score = score + 1.0 * h.uncanny
    elseif hf == "moral_anxiety" then
        score = score + 1.2 * h.moral_anxiety + 0.6 * b.psychological
    end

    -- If we want more social brutality, favor dialogues tagged around families, debts, officials.
    local tags = dialogueUnit.narrative_tags or {}
    for _, tag in ipairs(tags) do
        if tag == "family_conflict" or tag == "betrayal" then
            score = score + 0.8 * b.social
        elseif tag == "bureaucratic_cruelty" then
            score = score + 0.9 * personality.slavic.bureaucratic_horror
        end
    end

    return score
end

---Score a NarrativeScene-like block.
---@param scene table
---@param personality LorewayPersonalityProfile
---@return number
function LorewayPersonality.score_scene(scene, personality)
    if scene.external_reference_allowed then
        return -math.huge
    end

    local score = 0.0
    local hf = scene.horror_function or ""

    score = score + LorewayPersonality._score_horror_function(hf, personality)

    -- Scene scope can be used as a light bias.
    if scene.scope == "local" then
        score = score + 0.5
    elseif scene.scope == "area" then
        score = score + 0.3
    end

    -- Slavic tone: rural decay & domestic haunting get bonuses in Cell.
    local tags = scene.environment_tags or {}
    for _, tag in ipairs(tags) do
        if tag == "wet_forest_edge" or tag == "post_soviet_decay" then
            score = score + 0.6 * personality.slavic.rural_decay
        elseif tag == "apartment_block" or tag == "domestic" then
            score = score + 0.6 * personality.slavic.domestic_haunting
        elseif tag == "bureaucratic" then
            score = score + 0.6 * personality.slavic.bureaucratic_horror
        end
    end

    return score
end

function LorewayPersonality._score_horror_function(hf, personality)
    local h = personality.horror
    if hf == "dread" then
        return 1.0 * h.dread
    elseif hf == "shock" then
        return 1.0 * h.shock
    elseif hf == "disgust" then
        return 1.0 * h.disgust
    elseif hf == "uncanny" then
        return 1.0 * h.uncanny
    elseif hf == "moral_anxiety" then
        return 1.2 * h.moral_anxiety
    end
    return 0.2
end



----------------------------------------------------------------------
-- Chat / IDE adapter
----------------------------------------------------------------------

---@class LorewayTaskRequest
---@field id string
---@field intent string
---@field brutality_profile BrutalityProfile|nil

---Create personality from a task request.
---@param task LorewayTaskRequest
---@return LorewayPersonalityProfile
function LorewayPersonality.personality_from_task(task)
    local overrides = {}

    if task.brutality_profile then
        overrides.brutality = {
            global        = task.brutality_profile.global,
            physical      = task.brutality_profile.physical,
            psychological = task.brutality_profile.psychological,
            social        = task.brutality_profile.social,
        }
    end

    return LorewayPersonality.new_profile(
        task.id or "TASK_UNNAMED",
        task.intent or "Loreway Task",
        overrides
    )
end

---Select the best KG node from a list using a scoring function.
---@generic T
---@param candidates T[]
---@param scorer fun(node:T, personality:LorewayPersonalityProfile):number
---@param personality LorewayPersonalityProfile
---@return T|nil, number
function LorewayPersonality.select_best(candidates, scorer, personality)
    local best = nil
    local bestScore = -math.huge
    for _, node in ipairs(candidates) do
        local s = scorer(node, personality)
        if s > bestScore then
            bestScore = s
            best = node
        end
    end
    return best, bestScore
end

----------------------------------------------------------------------
-- Example: brutal narrative context from free-form user input
----------------------------------------------------------------------

---Build a LorewayTaskRequest from a free-form user string.
---This can be used in an AI chat front-end.
---@param userPrompt string
---@return LorewayTaskRequest
function LorewayPersonality.task_from_user_prompt(userPrompt)
    local lower = string.lower(userPrompt)
    local profile = {
        global        = 0.85,
        physical      = 0.80,
        psychological = 0.95,
        social        = 0.90,
    }

    if string.find(lower, "maximum") or string.find(lower, "as brutal as possible") then
        profile.global        = 0.98
        profile.physical      = 0.95
        profile.psychological = 1.00
        profile.social        = 0.95
    elseif string.find(lower, "psychological") then
        profile.psychological = 1.00
        profile.physical      = 0.6
        profile.social        = 0.8
    elseif string.find(lower, "social") or string.find(lower, "village turning") then
        profile.social        = 1.00
        profile.psychological = 0.9
        profile.physical      = 0.6
    end

    return {
        id = "USER_PROMPT",
        intent = userPrompt,
        brutality_profile = profile,
    }
end

return LorewayPersonality
