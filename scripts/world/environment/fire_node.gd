extends Node2D
class_name FireNode

enum FireState {
    IGNITING,       # just started, ramping up
    ACTIVE,         # burning and producing heat
    STARVING,       # low oxygen/fuel, intensity dropping
    EXTINGUISHING,  # being suppressed by water/foam
    EXTINGUISHED    # dead, heat falling
}

@export var base_intensity: float = 1.0          # nominal flame strength
@export var max_intensity: float = 3.0           # upper clamp
@export var oxygen_demand: float = 0.5           # O2/sec from local air
@export var heat_output_base: float = 20.0       # °C/sec contribution at intensity=1
@export var spreads_in_high_o2: bool = true
@export var extinguish_threshold: float = 0.2

# Material / biome flags
@export var fuel_class: StringName = &"GENERIC"  # "PLASTIC", "FUEL_LINE", "FABRIC", "BIOMECH"
@export var is_industrial_hull: bool = true
@export var can_ignite_biotech: bool = false     # e.g. biometal growths ignite differently

# Runtime state
var fire_state: FireState = FireState.IGNITING
var current_intensity: float = 0.0
var heat_output: float = 0.0                     # current °C/sec, exported to environment controller
var produce_heat: bool = true                    # developer flag, player only sees VFX

# Oxygen bookkeeping for region‑scale sims (optional)
var last_oxygen_consumed: float = 0.0

func _ready() -> void:
    current_intensity = clampf(base_intensity, 0.0, max_intensity)
    fire_state = FireState.ACTIVE if current_intensity > 0.1 else FireState.IGNITING

func tick(delta: float, env: OxygenEnvironment) -> void:
    if fire_state == FireState.EXTINGUISHED:
        # Residual cooling, no flames
        heat_output = lerp(heat_output, 0.0, delta * 0.5)
        produce_heat = heat_output > 0.1
        _debug_tick(env, 0.0)
        return

    var o2_factor := env.fire_risk                      # proxy for oxygen + fuel availability
    var water_factor := env.water_vapor_factor          # suppression / fog
    var state_before := fire_state

    # Intensity adjustment based on environment
    if env.state == OxygenEnvironment.AtmosState.FIRE_SUPPRESSED:
        fire_state = FireState.EXTINGUISHING
        current_intensity -= delta * (1.0 + water_factor)
    elif o2_factor <= extinguish_threshold:
        fire_state = FireState.STARVING
        current_intensity -= delta * (0.5 + (extinguish_threshold - o2_factor))
    else:
        # Actively burning or growing
        if fire_state in [FireState.IGNITING, FireState.STARVING, FireState.EXTINGUISHING]:
            fire_state = FireState.ACTIVE
        var growth := (o2_factor - 1.0) * delta   # >0 = growth in high fire_risk
        current_intensity += growth
        current_intensity -= delta * water_factor # water vapor slows it

    current_intensity = clampf(current_intensity, 0.0, max_intensity)

    # Oxygen consumption
    last_oxygen_consumed = 0.0
    if fire_state == FireState.ACTIVE and o2_factor > 0.1:
        last_oxygen_consumed = max(0.0, oxygen_demand * current_intensity * delta)
        # Hook: region.consume_oxygen(last_oxygen_consumed)

    # Heat production and “produce_heat” flag
    if fire_state in [FireState.ACTIVE, FireState.IGNITING]:
        heat_output = heat_output_base * current_intensity
        produce_heat = true
    elif fire_state in [FireState.STARVING, FireState.EXTINGUISHING]:
        heat_output = max(0.0, heat_output_base * current_intensity * 0.5)
        produce_heat = heat_output > 0.1
    else:
        heat_output = max(0.0, heat_output - delta * 10.0)
        produce_heat = heat_output > 0.1

    # Extinguish if fully starved or suppressed
    if current_intensity <= 0.0 and (o2_factor <= extinguish_threshold or env.state == OxygenEnvironment.AtmosState.FIRE_SUPPRESSED):
        _extinguish()
        _debug_tick(env, last_oxygen_consumed)
        return

    # Spread behavior in rich oxygen
    if spreads_in_high_o2 and o2_factor > 1.3 and fire_state == FireState.ACTIVE:
        _try_spread(env, delta)

    _debug_tick(env, last_oxygen_consumed, state_before)

func on_water_hit(amount: float, env: OxygenEnvironment) -> void:
    if fire_state == FireState.EXTINGUISHED:
        return

    fire_state = FireState.EXTINGUISHING
    current_intensity = max(0.0, current_intensity - amount)
    env.fire_risk = max(0.0, env.fire_risk - amount * 0.6)
    env.water_vapor_factor = clampf(env.water_vapor_factor + amount * 0.4, 0.0, 1.0)

    DebugLog.log("FireNode", "WATER_HIT", {
        "amount": amount,
        "intensity": current_intensity,
        "fire_risk": env.fire_risk,
        "water_vapor": env.water_vapor_factor,
        "state": int(fire_state)
    })

    if current_intensity <= 0.0:
        _extinguish()

func _extinguish() -> void:
    fire_state = FireState.EXTINGUISHED
    current_intensity = 0.0
    # Residual heat will cool in tick()
    DebugLog.log("FireNode", "EXTINGUISHED", {
        "heat_output": heat_output
    })

func _try_spread(env: OxygenEnvironment, delta: float) -> void:
    # Developer hook: call into a fire manager or tilemap controller
    DebugLog.log("FireNode", "SPREAD", {
        "origin": global_position,
        "fire_risk": env.fire_risk,
        "fuel_class": fuel_class
    })

func _debug_tick(env: OxygenEnvironment, oxy_used: float, state_before: int = -1) -> void:
    DebugLog.log("FireNode", "TICK", {
        "state_before": state_before,
        "state": int(fire_state),
        "intensity": current_intensity,
        "heat_output": heat_output,
        "produce_heat": produce_heat,
        "env_state": env.state,
        "env_fire_risk": env.fire_risk,
        "env_water_vapor": env.water_vapor_factor,
        "oxygen_used": oxy_used
    })
