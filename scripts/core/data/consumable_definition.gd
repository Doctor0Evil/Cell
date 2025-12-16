extends AssetDefinition
class_name ConsumableDefinition

@export var blood_delta: float = 0.0
@export var oxygen_delta: float = 0.0
@export var stamina_delta: float = 0.0
@export var wellness_delta: float = 0.0
@export var body_temp_delta: float = 0.0
@export var protein_delta: float = 0.0

@export var applied_effect_ids: Array[StringName] = []

@export var min_yield_required: float = 0.0
@export var safe_stack_limit: int = 3
