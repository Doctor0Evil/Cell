extends Resource
class_name OxygenEnvironment

enum AtmosState {
    SAFE,
    LOW,
    TOXIC,
    VACUUM,
    FIRE_SUPPRESSED
}

@export var state: AtmosState = AtmosState.SAFE
@export var oxygen_factor: float = 0.0        # 0 = no drain from env alone; 1 = full vacuum drain
@export var fire_risk: float = 1.0           # >1 = high spread, 0 = no fire
@export var water_vapor_factor: float = 0.0  # 0–1, dense fog and suppression
@export var mask_required: bool = false
@export var hull_breach_present: bool = false

@export var name_id: StringName = &"UNSPECIFIED_REGION"
@export var description: String = ""

static func make_pressurized_corridor() -> OxygenEnvironment:
    var env := OxygenEnvironment.new()
    env.state = AtmosState.SAFE
    env.oxygen_factor = 0.0
    env.fire_risk = 1.2
    env.water_vapor_factor = 0.1
    env.mask_required = false
    env.hull_breach_present = false
    env.name_id = &"PRESSURIZED_CORRIDOR"
    env.description = "Standard interior corridor: breathable, slightly flammable."
    return env

static func make_thin_air_tunnel() -> OxygenEnvironment:
    var env := OxygenEnvironment.new()
    env.state = AtmosState.LOW
    env.oxygen_factor = 0.3
    env.fire_risk = 0.8
    env.water_vapor_factor = 0.0
    env.mask_required = true
    env.hull_breach_present = false
    env.name_id = &"THIN_AIR_WASTE_TUNNEL"
    env.description = "Waste tunnel with thin, stale air; suit or mask recommended."
    return env

static func make_breached_hull() -> OxygenEnvironment:
    var env := OxygenEnvironment.new()
    env.state = AtmosState.VACUUM
    env.oxygen_factor = 1.0
    env.fire_risk = 0.0
    env.water_vapor_factor = 0.0
    env.mask_required = true
    env.hull_breach_present = true
    env.name_id = &"BREACHED_HULL"
    env.description = "Hard vacuum at the hull; any leak is lethal."
    return env

static func make_fire_suppressed() -> OxygenEnvironment:
    var env := OxygenEnvironment.new()
    env.state = AtmosState.FIRE_SUPPRESSED
    env.oxygen_factor = 0.2
    env.fire_risk = 0.0
    env.water_vapor_factor = 0.8
    env.mask_required = true
    env.hull_breach_present = false
    env.name_id = &"SUPPRESSION_FLOOD"
    env.description = "Inert gas/foam fill: fires die, breathing becomes difficult."
    return env
