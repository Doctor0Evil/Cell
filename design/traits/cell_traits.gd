extends Resource
class_name CellTraitDefinition

@export var id: StringName
@export var display_name: String
@export var description: String

# Attribute deltas (primary V.I.T.A.L.I.T.Y.)
@export var vitality_delta: float = 0.0
@export var instinct_delta: float = 0.0
@export var tenacity_delta: float = 0.0
@export var agility_delta: float = 0.0
@export var logic_delta: float = 0.0
@export var influence_delta: float = 0.0
@export var temper_delta: float = 0.0
@export var yield_delta: float = 0.0

# Secondary attributes
@export var constitution_delta: float = 0.0
@export var dexterity_delta: float = 0.0
@export var intelligence_delta: float = 0.0
@export var luck_delta: float = 0.0
@export var speed_delta: float = 0.0
@export var strength_delta: float = 0.0

# Pool modifiers (multipliers are applied in VitalitySystem / PlayerPools)
@export var blood_max_mult: float = 1.0
@export var oxygen_max_mult: float = 1.0
@export var water_max_mult: float = 1.0
@export var stamina_max_mult: float = 1.0
@export var wellness_max_mult: float = 1.0

@export var oxygen_decay_mult: float = 1.0
@export var water_decay_mult: float = 1.0
@export var stamina_decay_mult: float = 1.0
@export var temp_drop_mult: float = 1.0

# Environment tags where special rules apply
@export var region_tags: Array[StringName] = []
@export var status_rules: Dictionary = {}    # e.g. {"COLD_VERGE": {"stamina_decay_mult": 0.9}}

# Faction respect / reputation deltas
@export var respect_deltas: Dictionary = {}  # {"HULL_TECHS": 10, "BLACK_SECTION": -5}
@export var reputation_deltas: Dictionary = {}

# Narrative / system flags (strings used by higher-level systems)
@export var narrative_tags: Array[StringName] = []  # e.g. ["BERSERK_TRIGGER", "CLAUSTROPHOBIA"]

func apply_to_vitality(vitality: PlayerVitalitySystem) -> void:
    # Example: called once when trait is acquired, then recalc_maxima in VitalitySystem.[file:38]
    vitality.vitality += vitality_delta
    vitality.instinct += instinct_delta
    vitality.tenacity += tenacity_delta
    vitality.agility += agility_delta
    vitality.logic += logic_delta
    vitality.influence += influence_delta
    vitality.temper += temper_delta
    vitality.yield += yield_delta
    vitality.constitution += constitution_delta
    vitality.dexterity += dexterity_delta
    vitality.intelligence += intelligence_delta
    vitality.luck += luck_delta
    vitality.speed += speed_delta
    vitality.strength += strength_delta
    vitality.recalc_maxima()

func get_region_modifiers(region_tag: StringName) -> Dictionary:
    if status_rules.has(region_tag):
        return status_rules[region_tag]
    return {}
