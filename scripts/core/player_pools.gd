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

    blood = clamp(blood, 0.0, blood_max)
    protein = clamp(protein, 0.0, protein_max)
    oxygen = clamp(oxygen, 0.0, oxygen_max)
    stamina = clamp(stamina, 0.0, stamina_max)

func tick_blood(delta: float, bleed_rate: float) -> bool:
    blood = max(0.0, blood - bleed_rate * delta)
    if blood <= 0.0:
        return true
    if blood < blood_max * 0.25:
        if blood_collapse_count == 0 or randi() % 100 < 5:
            blood_collapse_count += 1
            vitality_system.wellness = max(0.0, vitality_system.wellness - 5.0)
            vitality_system.tenacity = max(0.0, vitality_system.tenacity - 0.1)
            return false
    return false

func tick_protein(delta: float, travel_load: float, awake_load: float) -> void:
    var base_rate := travel_load + awake_load
    var eff := clamp((vitality_system.yield + vitality_system.vitality) / 20.0, 0.5, 1.5)
    var rate := base_rate * eff
    protein = max(0.0, protein - rate * delta)
    if protein <= 0.0:
        if starving_stacks < 20:
            starving_stacks += 1
        if starving_stacks % 3 == 0:
            vitality_system.vitality = max(0.0, vitality_system.vitality - 0.1)
            vitality_system.tenacity = max(0.0, vitality_system.tenacity - 0.1)
            vitality_system.wellness = max(0.0, vitality_system.wellness - 3.0)

func tick_oxygen(delta: float, base_drain: float) -> bool:
    var rate := vitality_system.get_oxygen_decay_rate(base_drain)
    oxygen = max(0.0, oxygen - rate * delta)
    return oxygen <= 0.0

func tick_stamina(delta: float, exertion: float, base_recovery: float) -> bool:
    var decay := vitality_system.get_stamina_decay_rate(exertion)
    var recovery := base_recovery * clamp((vitality_system.tenacity + vitality_system.agility) / 20.0, 0.5, 1.8)
    stamina = clamp(stamina - decay * delta + recovery * delta, 0.0, stamina_max)

    if stamina <= 0.0:
        stamina_collapse_count += 1
        vitality_system.wellness = max(0.0, vitality_system.wellness - 2.0)
        protein = max(0.0, protein - 0.5)
        return true
    return false

func apply_meal(protein_gain: float) -> void:
    protein = min(protein_max, protein + protein_gain)
    if protein > protein_max * 0.3 and starving_stacks > 0:
        starving_stacks -= 1

func apply_lox_bottle(amount: float) -> void:
	# New LOX-aware API: amount is Standard Liters (SL) to be converted via vitality system
	vitality_system.use_lox_bottle(amount)
	oxygen = min(oxygen_max, oxygen + amount * vitality_system.get_oxygen_efficiency())

# Deprecated compatibility wrapper - prefer `apply_lox_bottle(amount)` instead.
func apply_oxygen_capsule(amount: float) -> void:
	DebugLog.log("PlayerPools", "DEPRECATION", {"deprecated": "apply_oxygen_capsule", "recommended": "apply_lox_bottle"})
	apply_lox_bottle(amount)

func apply_rest(hours: float) -> void:
    var stamina_recover := hours * 12.0
    stamina = min(stamina_max, stamina + stamina_recover)
    var protein_cost := hours * 0.15
    protein = max(0.0, protein - protein_cost)
