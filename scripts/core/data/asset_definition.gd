extends Resource
class_name AssetDefinition

@export var id: StringName
@export var display_name: String
@export_multiline var description: String

@export var category: StringName = &"generic"
# weapon, armor, implant, consumable, tool, key_item, world_prop, ammo, resource
@export var rarity: StringName = &"common"
# common, rare, experimental, forbidden

@export var max_stack: int = 1
@export var weight_kg: float = 0.0
@export var volume_l: float = 0.0

@export var base_value_chips: int = 0

# Visual bindings
@export_file("*.tscn") var world_scene_path: String = ""
@export_file("*.png,*.tres") var icon_path: String = ""

# Audio bindings
@export var pickup_sfx_id: StringName = &""
@export var use_sfx_id: StringName = &""

# V.I.T.A.L.I.T.Y. deltas (permanent or while equipped)
@export var vitality_delta: float = 0.0
@export var instinct_delta: float = 0.0
@export var tenacity_delta: float = 0.0
@export var agility_delta: float = 0.0
@export var logic_delta: float = 0.0
@export var influence_delta: float = 0.0
@export var temper_delta: float = 0.0
@export var yield_delta: float = 0.0

# Pool limits / thresholds
@export var blood_max_delta: float = 0.0
@export var oxygen_max_delta: float = 0.0
@export var stamina_max_delta: float = 0.0
@export var wellness_max_delta: float = 0.0
@export var body_temp_min_delta: float = 0.0
@export var body_temp_max_delta: float = 0.0

# Tags (loot tables, filters, AI logic)
@export var tags: Array[StringName] = []
