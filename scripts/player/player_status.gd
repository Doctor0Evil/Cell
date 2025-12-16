extends Node
class_name PlayerStatus

@export var vitality_system: PlayerVitalitySystem

func _ready() -> void:
    if vitality_system == null:
        vitality_system = PlayerVitalitySystem.new()
    vitality_system.recalc_maxima()
    DebugLog.log("PlayerStatus", "ATTRIBUTES_INIT", {
        "vitality": vitality_system.vitality,
        "instinct": vitality_system.instinct,
        "tenacity": vitality_system.tenacity,
        "agility": vitality_system.agility,
        "logic": vitality_system.logic,
        "influence": vitality_system.influence,
        "temper": vitality_system.temper,
        "yield": vitality_system.yield,
        "constitution": vitality_system.constitution,
        "dexterity": vitality_system.dexterity,
        "intelligence": vitality_system.intelligence,
        "luck": vitality_system.luck,
        "speed": vitality_system.speed,
        "strength": vitality_system.strength,
        "blood": vitality_system.blood,
        "oxygen": vitality_system.oxygen,
        "stamina": vitality_system.stamina,
        "wellness": vitality_system.wellness,
        "body_temp": vitality_system.body_temperature
    })

func tick_environment(delta: float, env_cold: float, env_stress: float) -> void:
    vitality_system.tick_environment(delta, env_cold, env_stress)

func tick_protein(delta: float, travel_load: float, awake_load: float) -> void:
    vitality_system.tick_protein(delta, travel_load, awake_load)

func apply_damage(amount: float) -> void:
    var dead := vitality_system.apply_damage(amount)
    if dead:
        GameState.apply_damage(9999) # force death path
