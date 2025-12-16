extends Resource
class_name PlayerVitalitySystem

# Primary V.I.T.A.L.I.T.Y. attributes (0-10)
@export var vitality: float = 5.0
@export var instinct: float = 5.0
@export var tenacity: float = 5.0
@export var agility: float = 5.0
@export var logic: float = 5.0
@export var influence: float = 5.0
@export var temper: float = 5.0
@export var yield: float = 5.0

# Secondary attributes (0-10)
@export var constitution: float = 5.0
@export var dexterity: float = 5.0
@export var intelligence: float = 5.0
@export var luck: float = 5.0
@export var speed: float = 5.0
@export var strength: float = 5.0

# Resource pools (runtime values)
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

var body_temperature: float = 37.0  # Celsius
var body_temperature_min: float = 26.0
var body_temperature_max: float = 41.0

func recalc_maxima() -> void:
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

func get_oxygen_decay_rate(base_rate: float) -> float:
    var eff := (yield * 0.4 + tenacity * 0.3 + instinct * 0.2 + logic * 0.1) / 10.0
    return base_rate * clamp(1.2 - eff, 0.4, 1.4)

func get_stamina_decay_rate(base_rate: float) -> float:
    var eff := (tenacity * 0.5 + agility * 0.3 + instinct * 0.2) / 10.0
    return base_rate * clamp(1.2 - eff, 0.3, 1.5)

func get_temp_drop_rate(base_rate: float) -> float:
    var eff := (vitality * 0.4 + tenacity * 0.4 + constitution * 0.2) / 10.0
    return base_rate * clamp(1.3 - eff, 0.3, 1.6)

func get_healing_efficiency() -> float:
    var eff := (yield * 0.6 + vitality * 0.2 + protein / max(1.0, protein_max)) / 10.0
    return clamp(0.5 + eff, 0.5, 2.0)

func get_sanity_stability() -> float:
    var eff := (temper * 0.5 + instinct * 0.3 + logic * 0.2) / 10.0
    return clamp(0.4 + eff, 0.4, 2.0)

func tick_environment(delta: float, env_cold_factor: float, env_stress: float) -> void:
    var temp_rate := get_temp_drop_rate(env_cold_factor)
    body_temperature -= temp_rate * delta

    var oxy_rate := get_oxygen_decay_rate(1.0 + env_stress * 0.4)
    oxygen = max(0.0, oxygen - oxy_rate * delta)

    var stamina_rate := get_stamina_decay_rate(0.0 + env_stress * 0.8)
    stamina = max(0.0, stamina - stamina_rate * delta)

    var sanity_factor := get_sanity_stability()
    var wellness_loss := env_stress * delta * (2.0 / sanity_factor)
    wellness = max(0.0, wellness - wellness_loss)

func apply_damage(amount: float) -> void:
    blood = max(0.0, blood - amount)
    if blood <= 0.0:
        wellness = max(0.0, wellness - 20.0)

func apply_heal(amount: float, protein_cost: float) -> void:
    if protein <= 0.0:
        return
    var eff := get_healing_efficiency()
    var heal := amount * eff
    var cost := protein_cost / eff
    protein = max(0.0, protein - cost)
    blood = min(blood_max, blood + heal)

func use_oxygen_capsule(strength: float) -> void:
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
