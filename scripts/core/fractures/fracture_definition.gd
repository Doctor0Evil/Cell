extends Resource
class_name FractureDefinition

enum FractureType {
    ADAPTIVE,   # Blue – purely beneficial
    SCARRING,   # Red – strong benefit + permanent drawback
    REACTIVE,   # Green – threshold-triggered
    SYNDICATE   # Violet – faction/forbidden
}

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var fracture_type: FractureType = FractureType.ADAPTIVE

# Flat attribute deltas (applied when fracture is acquired)
@export var vitality_delta: float = 0.0
@export var instinct_delta: float = 0.0
@export var tenacity_delta: float = 0.0
@export var agility_delta: float = 0.0
@export var logic_delta: float = 0.0
@export var influence_delta: float = 0.0
@export var temper_delta: float = 0.0
@export var yield_delta: float = 0.0

# Pool multipliers (applied as modifiers in PlayerVitalitySystem)
# 1.0 = no change, <1 = slower decay / reduced loss, >1 = faster decay / extra loss
@export var blood_loss_mult: float = 1.0
@export var oxygen_decay_mult: float = 1.0
@export var water_decay_mult: float = 1.0
@export var stamina_decay_mult: float = 1.0
@export var stamina_recovery_mult: float = 1.0
@export var temp_drop_mult: float = 1.0
@export var wellness_decay_mult: float = 1.0

# Max pool multipliers
@export var blood_max_mult: float = 1.0
@export var stamina_max_mult: float = 1.0
@export var wellness_max_mult: float = 1.0

# Trigger fields for REACTIVE/SYNDICATE behavior
@export var trigger_blood_ratio_lt: float = -1.0
@export var trigger_oxygen_ratio_lt: float = -1.0
@export var trigger_water_ratio_lt: float = -1.0
@export var trigger_wellness_ratio_lt: float = -1.0
@export var trigger_in_darkness: bool = false
@export var trigger_surrounded_radius: float = 0.0

# Duration effects (seconds) – used by a FractureSystem to spawn timed buffs
@export var surge_duration: float = 0.0
@export var move_speed_bonus: float = 0.0        # e.g. +0.15
@export var accuracy_bonus: float = 0.0          # 0–1 internal modifier
@export var damage_bonus_melee: float = 0.0      # fraction
@export var crit_bonus: float = 0.0

# Permanent scar increments (applied per trigger or per acquisition)
@export var wellness_max_scar: float = 0.0
@export var yield_scar: float = 0.0

# Thematic tags (for UI grouping and logs)
@export var tags: Array[StringName] = [] # e.g. ["ADAPTIVE", "COLD", "OXYGEN", "WATER"]

func is_reactive() -> bool:
    return fracture_type == FractureType.REACTIVE
