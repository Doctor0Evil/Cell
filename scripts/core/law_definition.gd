extends Resource
class_name LawDefinition

@export var id: StringName
@export var display_name: String
@export_multiline var description: String

@export var category: StringName = &"civic" # civic, cosmic, environmental, faction_doctrine
@export var tree: StringName = &"adaptation" # adaptation, purpose_faith, purpose_order, labour, experimental
@export var exclusive_with: Array[StringName] = []

@export var settlement_stability_delta: float = 0.0
@export var discontent_delta: float = 0.0
@export var hope_delta: float = 0.0

@export var oxygen_use_mult: float = 1.0
@export var protein_consumption_mult: float = 1.0
@export var wellness_decay_mult: float = 1.0
@export var infection_risk_mult: float = 1.0

@export var enables_tags: Array[StringName] = []
@export var forbids_tags: Array[StringName] = []

@export var on_crime_events: Dictionary = {}
@export var on_disaster_events: Dictionary = {}

@export var cosmic_trigger_chance: float = 0.0
@export var cosmic_outcome_ids: Array[StringName] = []
