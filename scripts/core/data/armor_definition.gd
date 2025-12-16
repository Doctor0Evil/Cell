extends AssetDefinition
class_name ArmorDefinition

@export var slot: StringName = &"torso"  # head, torso, arms, legs, full_suit

@export var ballistic_resistance: float = 0.0
@export var thermal_resistance: float = 0.0
@export var chemical_resistance: float = 0.0
@export var cell_resistance: float = 0.0

@export var movement_penalty_mult: float = 1.0
@export var noise_mult: float = 1.0
@export var body_temp_loss_mult: float = 1.0
@export var oxygen_use_mult: float = 1.0
