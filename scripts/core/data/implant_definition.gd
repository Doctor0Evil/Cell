extends AssetDefinition
class_name ImplantDefinition

@export var slot: StringName = &"neural"  # neural, skeletal, circulatory, dermal

@export var blood_max_mult: float = 1.0
@export var oxygen_efficiency_mult: float = 1.0
@export var stamina_recovery_mult: float = 1.0
@export var sanity_stability_mult: float = 1.0

@export var infection_risk: float = 0.0
@export var maintenance_cost_protein: float = 0.0
@export var maintenance_cost_oxygen: float = 0.0
