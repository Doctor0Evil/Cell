extends Resource
class_name PlayerVitalitySystem

# Primary V.I.T.A.L.I.T.Y. attributes (0–10)
@export var vitality: float = 5.0    # Biological resilience, bleed-out, infection resistance
@export var instinct: float = 5.0    # Threat awareness, reflex
@export var tenacity: float = 5.0    # Endurance under stress
@export var agility: float = 5.0     # Dodging, short-burst movement
@export var logic: float = 5.0       # Technical cognition, BCI stability
@export var influence: float = 5.0   # Social presence
@export var temper: float = 5.0      # Emotional control, panic
@export var yield: float = 5.0       # Resource conversion efficiency

# Secondary attributes (0–10)
@export var constitution: float = 5.0
@export var dexterity: float = 5.0
@export var intelligence: float = 5.0
@export var luck: float = 5.0
@export var speed: float = 5.0
@export var strength: float = 5.0

# Runtime resource pools – these are the hard edges of survival
var blood: float = 100.0
var blood_max: float = 100.0

var protein: float = 50.0
var protein_max: float = 50.0

var oxygen: float = 100.0
var oxygen_max: float = 100.0

var stamina: float = 100.0
var stamina_max: float = 100.0

var wellness: float = 100.0
var wellness_max: float = 100.0

var body_temperature: float = 37.0        # Celsius
var body_temperature_min: float = 26.0
var body_temperature_max: float = 41.0

# Collapse / failure counters
var starving_stacks: int = 0
var blood_collapse_count: int = 0
var stamina_collapse_count: int = 0

func recalc_maxima() -> void:
    # Max pool values derived from attributes
    blood_max = 70.0 + vitality * 4.0 + constitution * 3.0
    stamina_max = 60.0 + tenacity * 5.0 + agility * 3.0
    wellness_max = 60.0 + temper * 4.0 + influence * 3.0 + instinct * 2.0
    protein_max = 30.0 + yield * 4.0 + vitality * 2.0
    oxygen_max = 80.0 + tenacity * 3.0 + logic * 2.0 + yield * 2.0

    blood = clamp(blood, 0.0, blood_max)
    stamina = clamp(stamina, 0.0, stamina_max)
    wellness = clamp(wellness, 0.0, wellness_max)
    protein = clamp(protein, 0.0, protein_max)
    oxygen = clamp(oxygen, 0.0, oxygen_max)

# === Derived multipliers ===

func get_move_speed_multiplier() -> float:
    var m := 0.6 + speed * 0.06 + agility * 0.04
    return clamp(m, 0.6, 2.0)

func get_melee_damage_multiplier() -> float:
    return clamp(0.5 + strength * 0.1, 0.5, 2.5)

func get_healing_efficiency() -> float:
    var eff := yield * 0.6 + vitality * 0.2 + max(1.0, protein_max) / 10.0
    return clamp(0.5 + eff * 0.05, 0.5, 2.0)

func get_sanity_stability() -> float:
    var eff := temper * 0.5 + instinct * 0.3 + logic * 0.2
    return clamp(0.4 + eff * 0.06, 0.4, 2.0)

func get_oxygen_decay_rate(base_rate: float) -> float:
    var eff := (yield * 0.4 + tenacity * 0.3 + instinct * 0.2 + logic * 0.1) / 10.0
    return base_rate * clamp(1.2 - eff, 0.4, 1.4)

func get_temp_drop_rate(base_rate: float) -> float:
    var eff := (vitality * 0.4 + tenacity * 0.4 + constitution * 0.2) / 10.0
    return base_rate * clamp(1.3 - eff, 0.3, 1.6)

func get_stamina_decay_rate(base_rate: float) -> float:
    var eff := (tenacity * 0.5 + agility * 0.3 + instinct * 0.2) / 10.0
    return base_rate * clamp(1.2 - eff, 0.3, 1.5)

# === Core tick logic ===

func tick_environment(delta: float, env_cold_factor: float, env_stress: float) -> void:
    # Temperature
    var temp_rate := get_temp_drop_rate(env_cold_factor)
    body_temperature -= temp_rate * delta
    body_temperature = clamp(body_temperature, body_temperature_min, body_temperature_max)

    # Oxygen
    var oxy_rate := get_oxygen_decay_rate(1.0 + env_stress * 0.4)
    oxygen = max(0.0, oxygen - oxy_rate * delta)

    # Stamina
    var stamina_rate := get_stamina_decay_rate(env_stress * 0.8)
    stamina = max(0.0, stamina - stamina_rate * delta)

    # Sanity / wellness
    var stability := get_sanity_stability()
    var wellness_loss := env_stress * delta * (2.0 / stability)
    wellness = max(0.0, wellness - wellness_loss)

func tick_protein(delta: float, travel_load: float, awake_load: float) -> void:
    var base_rate := travel_load + awake_load
    var eff := clamp((yield + vitality) / 20.0, 0.5, 1.5)
    var rate := base_rate * eff
    protein = max(0.0, protein - rate * delta)

    if protein <= 0.0:
        if starving_stacks < 20:
            starving_stacks += 1
        if starving_stacks % 3 == 0:
            vitality = max(0.0, vitality - 0.1)
            tenacity = max(0.0, tenacity - 0.1)
            wellness = max(0.0, wellness - 3.0)

# === Damage / healing / exertion ===

func apply_damage(amount: float) -> bool:
    blood = max(0.0, blood - amount)
    if blood <= 0.0:
        wellness = max(0.0, wellness - 20.0)
        return true    # dead
    if blood < blood_max * 0.25:
        if blood_collapse_count == 0 or randi() % 100 < 5:
            blood_collapse_count += 1
            wellness = max(0.0, wellness - 5.0)
            tenacity = max(0.0, tenacity - 0.1)
    return false

func apply_heal(amount: float, protein_cost: float) -> void:
    if protein <= 0.0:
        return
    var eff := get_healing_efficiency()
    var heal := amount * eff
    var cost := protein_cost * eff
    protein = max(0.0, protein - cost)
    blood = min(blood_max, blood + heal)

func tick_stamina(delta: float, exertion: float, base_recovery: float) -> bool:
    var decay := get_stamina_decay_rate(exertion)
    var recovery := base_recovery * clamp((tenacity + agility) / 20.0, 0.5, 1.8)
    stamina = clamp(stamina - decay * delta + recovery * delta, 0.0, stamina_max)
    if stamina <= 0.0:
        stamina_collapse_count += 1
        wellness = max(0.0, wellness - 2.0)
        protein = max(0.0, protein - 0.5)
        return true
    return false

# === Oxygen capsule and ration-chip logic ===

func use_oxygen_capsule(strength: float) -> void:
    # Brutal but useful: more oxygen, but long-term strain.
    var factor := clamp(0.8 + yield * 0.05, 0.8, 1.8)
    oxygen = min(oxygen_max, oxygen + strength * factor)
    wellness = max(0.0, wellness - 2.0)
    vitality = max(0.0, vitality - 0.05)
    temper = max(0.0, temper - 0.05)

func apply_ration_chip_tier(tier: int) -> void:
    var factor := 0.15 + yield * 0.03
    match tier:
        1:
            vitality = min(10.0, vitality + factor)
            constitution = min(10.0, constitution + factor)
            protein = min(protein_max, protein + 5.0)
        2:
            agility = min(10.0, agility + factor)
            speed = min(10.0, speed + factor)
            dexterity = min(10.0, dexterity + factor * 0.8)
        3:
            logic = min(10.0, logic + factor)
            intelligence = min(10.0, intelligence + factor)
            yield = min(10.0, yield + factor * 0.8)
    recalc_maxima()
