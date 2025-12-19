extends Node
class_name RegionSimManager

# One entry per loaded/known region – not per-NPC node.

class RegionSimState:
    var region_id: StringName
    var biome_tags: Array[StringName] = []
    var npcs: Array[Dictionary] = []   # minimal dictionaries, no Nodes
    var tension: float = 0.0           # 0–1
    var scarcity: float = 0.0          # 0–1, rations/oxygen scarcity
    var unrest: float = 0.0            # 0–1, social instability
    var last_sim_time: float = 0.0     # game-time minutes

var regions: Dictionary = {} # region_id -> RegionSimState
var sim_step_minutes: float = 10.0     # coarse world step
var max_npcs_per_region: int = 64      # cap for performance

func _ready() -> void:
    DebugLog.log("RegionSimManager", "READY", {})

func register_region(region_id: StringName, biome_tags: Array[StringName]) -> void:
    if regions.has(region_id):
        return
    var state := RegionSimState.new()
    state.region_id = region_id
    state.biome_tags = biome_tags.duplicate()
    # Seed a small population.
    var rng := RandomNumberGenerator.new()
    rng.seed = hash(str(region_id))
    var count := 8 + rng.randi_range(0, max_npcs_per_region / 4)
    for i in count:
        var npc_dict := _create_npc_stub(region_id, biome_tags, i, rng)
        state.npcs.append(npc_dict)
    # Start mid-level tension/scarcity tuned by biome.
    state.tension = biome_tags.has("COLDVERGE") ? 0.35 : 0.25
    state.scarcity = biome_tags.has("ASHVEIL_DRIFT") ? 0.5 : 0.3
    state.unrest = 0.2
    state.last_sim_time = 0.0
    regions[region_id] = state
    DebugLog.log("RegionSimManager", "REGISTER_REGION", {"region": region_id, "npcs": len(state.npcs)})

func _create_npc_stub(region_id: StringName, biome_tags: Array[StringName], idx: int, rng: RandomNumberGenerator) -> Dictionary:
    var p := preload("res://scripts/world/npc/npc_personality.gd").new()
    p.randomize_for_region(region_id, biome_tags, idx)
    return {
        "id": StringName(str(region_id, "_npc_", idx)),
        "personality": p,
        "alive": true,
        "fatigue": rng.randf(),
        "loyalty": rng.randf(),
        "oxygen_buffer": rng.randf(),
        "ration_buffer": rng.randf(),
        "incident_risk": 0.0
    }

func simulate_region(region_id: StringName, current_time_minutes: float) -> void:
    var state: RegionSimState = regions.get(region_id, null)
    if state == null:
        return
    var elapsed := current_time_minutes - state.last_sim_time
    if elapsed < sim_step_minutes:
        return
    var steps := int(elapsed / sim_step_minutes)
    for i in steps:
        _step_region(state, sim_step_minutes)
    state.last_sim_time += sim_step_minutes * steps

func _step_region(state: RegionSimState, step_minutes: float) -> void:
    if state.npcs.is_empty():
        return

    var rng := RandomNumberGenerator.new()
    rng.seed = hash(str(state.region_id, ":", int(state.last_sim_time)))

    var tension_delta := 0.0
    var scarcity_delta := 0.0
    var unrest_delta := 0.0

    for npc in state.npcs:
        if not npc["alive"]:
            continue
        var p: NpcPersonality = npc["personality"]
        var fatigue: float = npc["fatigue"]
        var oxy: float = npc["oxygen_buffer"]
        var ration: float = npc["ration_buffer"]
        var risk: float = npc["incident_risk"]

        var metabolic_load := 0.5 + 0.5 * max(p.aggression, p.curiosity)
        var oxy_use := metabolic_load * 0.02 * step_minutes
        var ration_use := (0.3 + 0.4 * p.greed) * 0.015 * step_minutes

        oxy = max(0.0, oxy - oxy_use * (1.0 + state.scarcity * 0.5))
        ration = max(0.0, ration - ration_use * (1.0 + state.scarcity * 0.6))

        fatigue = clamp(fatigue + 0.01 * step_minutes - 0.02, 0.0, 1.0)

        var local_risk := 0.0
        local_risk += max(0.0, p.aggression) * 0.02
        local_risk += max(0.0, p.curiosity) * 0.01
        local_risk += max(0.0, -p.empathy) * 0.01
        local_risk += (1.0 - ration) * 0.015
        local_risk += (1.0 - oxy) * 0.02

        risk += local_risk * step_minutes
        npc["fatigue"] = fatigue
        npc["oxygen_buffer"] = oxy
        npc["ration_buffer"] = ration
        npc["incident_risk"] = risk

        scarcity_delta += (0.5 - ration) * 0.0005 * step_minutes
        tension_delta += local_risk * 0.0002 * step_minutes
        unrest_delta += (max(0.0, -p.discipline) + max(0.0, -p.empathy)) * 0.0001 * step_minutes

        if risk > 1.0 and rng.randf() < min(0.15, risk * 0.05):
            _resolve_npc_incident(state, npc, rng)

    state.tension = clamp(state.tension + tension_delta, 0.0, 1.0)
    state.scarcity = clamp(state.scarcity + scarcity_delta, 0.0, 1.0)
    state.unrest = clamp(state.unrest + unrest_delta, 0.0, 1.0)

    _apply_long_term_escalation(state, step_minutes)

func _resolve_npc_incident(state: RegionSimState, npc: Dictionary, rng: RandomNumberGenerator) -> void:
    var p: NpcPersonality = npc["personality"]
    var risk: float = npc["incident_risk"]
    npc["incident_risk"] = 0.0

    var roll := rng.randf()
    if roll < 0.3:
        var delta_tension := 0.03 + 0.04 * max(0.0, p.aggression)
        state.tension = clamp(state.tension + delta_tension, 0.0, 1.0)
    elif roll < 0.6:
        var delta_scarcity := 0.04 + 0.03 * (1.0 - p.caution)
        state.scarcity = clamp(state.scarcity + delta_scarcity, 0.0, 1.0)
    elif roll < 0.85:
        npc["alive"] = false
        state.unrest = clamp(state.unrest + 0.05 + 0.05 * (1.0 - p.empathy), 0.0, 1.0)
    else:
        state.unrest = clamp(state.unrest + 0.1, 0.0, 1.0)
        state.tension = clamp(state.tension + 0.08, 0.0, 1.0)

    DebugLog.log("RegionSimManager", "INCIDENT", {"region": state.region_id, "type": roll, "tension": state.tension, "scarcity": state.scarcity})

func _apply_long_term_escalation(state: RegionSimState, step_minutes: float) -> void:
    if state.scarcity > 0.7:
        state.tension = clamp(state.tension + 0.005 * step_minutes, 0.0, 1.0)
    if state.tension > 0.8:
        state.unrest = clamp(state.unrest + 0.004 * step_minutes, 0.0, 1.0)

    if state.scarcity < 0.3 and state.tension < 0.3:
        state.unrest = max(0.0, state.unrest - 0.003 * step_minutes)

func get_debug_snapshot() -> Dictionary:
    var out := {}
    for region_id in regions.keys():
        var s: RegionSimState = regions[region_id]
        var alive := 0
        for npc in s.npcs:
            if npc["alive"]:
                alive += 1
        out[region_id] = {
            "alive_npcs": alive,
            "tension": s.tension,
            "scarcity": s.scarcity,
            "unrest": s.unrest
        }
    return out