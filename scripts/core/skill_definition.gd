extends Resource
class_name SkillDefinition

@export var id: StringName
@export var display_name: String
@export var description: String
@export var max_rank: int = 10

# Governing V.I.T.A.L.I.T.Y. weights (0-1)
@export var vitality_weight: float = 0.0
@export var instinct_weight: float = 0.0
@export var tenacity_weight: float = 0.0
@export var agility_weight: float = 0.0
@export var logic_weight: float = 0.0
@export var influence_weight: float = 0.0
@export var temper_weight: float = 0.0
@export var yield_weight: float = 0.0

func get_attribute_factor(vsys: PlayerVitalitySystem) -> float:
    var sum := 0.0
    sum += vsys.vitality * vitality_weight
    sum += vsys.instinct * instinct_weight
    sum += vsys.tenacity * tenacity_weight
    sum += vsys.agility * agility_weight
    sum += vsys.logic * logic_weight
    sum += vsys.influence * influence_weight
    sum += vsys.temper * temper_weight
    sum += vsys.yield * yield_weight
    return clamp(sum / 10.0, 0.0, 2.0)
