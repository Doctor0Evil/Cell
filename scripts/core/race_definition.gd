extends Resource
class_name RaceDefinition

enum RaceId {
    HUMAN,
    AUG,
    CYBORG,
    REPZILLION
}

@export var race_id: RaceId = RaceId.HUMAN
@export var display_name: String = "Human"

@export var base_vitality_mod: float = 0.0
@export var base_instinct_mod: float = 0.0
@export var base_tenacity_mod: float = 0.0
@export var base_agility_mod: float = 0.0
@export var base_logic_mod: float = 0.0
@export var base_influence_mod: float = 0.0
@export var base_temper_mod: float = 0.0
@export var base_yield_mod: float = 0.0

@export var base_constitution_mod: float = 0.0
@export var base_dexterity_mod: float = 0.0
@export var base_intelligence_mod: float = 0.0
@export var base_luck_mod: float = 0.0
@export var base_speed_mod: float = 0.0
@export var base_strength_mod: float = 0.0

@export var immune_to_cell: bool = false
@export var cell_resistance_factor: float = 1.0

static func make_human() -> RaceDefinition:
    var r := RaceDefinition.new()
    r.race_id = RaceId.HUMAN
    r.display_name = "Human"
    r.cell_resistance_factor = 1.0
    return r

static func make_aug() -> RaceDefinition:
    var r := RaceDefinition.new()
    r.race_id = RaceId.AUG
    r.display_name = "Aug"
    r.base_logic_mod = 1.0
    r.base_yield_mod = 0.5
    r.base_instinct_mod = 0.5
    r.base_temper_mod = -0.3
    r.cell_resistance_factor = 0.7
    return r

static func make_cyborg() -> RaceDefinition:
    var r := RaceDefinition.new()
    r.race_id = RaceId.CYBORG
    r.display_name = "Cyborg"
    r.base_vitality_mod = 0.5
    r.base_tenacity_mod = 1.0
    r.base_constitution_mod = 1.0
    r.base_strength_mod = 1.0
    r.immune_to_cell = true
    r.cell_resistance_factor = 0.0
    return r

static func make_repzillion() -> RaceDefinition:
    var r := RaceDefinition.new()
    r.race_id = RaceId.REPZILLION
    r.display_name = "Repzillion"
    r.base_instinct_mod = 1.0
    r.base_strength_mod = 1.0
    r.base_speed_mod = 0.5
    r.cell_resistance_factor = 0.5
    return r

func apply_to_vitality_system(vsys: PlayerVitalitySystem) -> void:
    vsys.vitality += base_vitality_mod
    vsys.instinct += base_instinct_mod
    vsys.tenacity += base_tenacity_mod
    vsys.agility += base_agility_mod
    vsys.logic += base_logic_mod
    vsys.influence += base_influence_mod
    vsys.temper += base_temper_mod
    vsys.yield += base_yield_mod

    vsys.constitution += base_constitution_mod
    vsys.dexterity += base_dexterity_mod
    vsys.intelligence += base_intelligence_mod
    vsys.luck += base_luck_mod
    vsys.speed += base_speed_mod
    vsys.strength += base_strength_mod
