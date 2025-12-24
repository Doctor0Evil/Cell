extends Resource
class_name PlayerPools

@export var vitality_system: PlayerVitalitySystem

@export var blood: float = 100.0
@export var blood_max: float = 100.0
@export var protein: float = 50.0
@export var protein_max: float = 50.0
@export var oxygen: float = 100.0
@export var oxygen_max: float = 100.0
@export var stamina: float = 100.0
@export var stamina_max: float = 100.0
@export var wellness: float = 100.0
@export var wellness_max: float = 100.0

var starving_stacks: int = 0
var blood_collapse_count: int = 0
var stamina_collapse_count: int = 0

func recalc_from_vitality() -> void:
    if vitality_system == null:
        return
    vitality_system.recalc_maxima()

    blood_max = vitality_system.blood_max
    protein_max = vitality_system.protein_max
    oxygen_max = vitality_system.oxygen_max
    stamina_max = vitality_system.stamina_max
    wellness_max = vitality_system.wellness_max

    blood = clampf(blood, 0.0, blood_max)
    protein = clampf(protein, 0.0, protein_max)
    oxygen = clampf(oxygen, 0.0, oxygen_max)
    stamina = clampf(stamina, 0.0, stamina_max)
    wellness = clampf(wellness, 0.0, wellness_max)

func tick_oxygen(delta: float, base_drain: float, env_factor: float) -> bool:
    if vitality_system == null:
        return false
    # base_drain: nominal oxygen per second at env_factor = 1.0
    var scaled_base := base_drain * env_factor
    var rate := vitality_system.get_oxygen_decay_rate(scaled_base)
    oxygen = max(0.0, oxygen - rate * delta)

    DebugLog.log("PlayerPools", "OXYGEN_TICK", {
        "base_drain": base_drain,
        "env_factor": env_factor,
        "decay_rate": rate,
        "oxygen": oxygen,
        "oxygen_max": oxygen_max
    })

    return oxygen <= 0.0

func tick_oxygen_with_suit(
        delta: float,
        base_drain: float,
        env_factor: float,
        suit: SuitIntegrity
    ) -> bool:
    var leak := suit.get_total_leak()
    var total_base := base_drain * env_factor + leak
    var death := tick_oxygen(delta, total_base, 1.0)
    DebugLog.log("PlayerPools", "OXYGEN_TICK_SUIT", {
        "base_drain": base_drain,
        "env_factor": env_factor,
        "leak_total": leak,
        "oxygen": oxygen
    })
    return death

func apply_lox_bottle(amount: float) -> void:
	if vitality_system == null:
		return
	vitality_system.use_lox_bottle(amount)
	oxygen = min(oxygen_max, oxygen + amount * vitality_system.get_oxygen_efficiency())
	DebugLog.log("PlayerPools", "LOX_BOTTLE", {
		"amount": amount,
		"oxygen": oxygen,
		"wellness": vitality_system.wellness,
		"vitality": vitality_system.vitality,
		"temper": vitality_system.temper
	})

# Deprecated compatibility wrapper - prefer `apply_lox_bottle(amount)` instead.
func apply_oxygen_capsule(amount: float) -> void:
	DebugLog.log("PlayerPools", "DEPRECATION", {"deprecated": "apply_oxygen_capsule", "recommended": "apply_lox_bottle"})
	apply_lox_bottle(amount)
