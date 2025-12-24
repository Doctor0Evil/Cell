extends Resource
class_name RegionDefinition

# Compatibility fields used by the Region Baker pipeline
@export var region_id: StringName = &""
@export var biome_temp_c: float = 0.0
@export var oxygen_state: int = 0
@export var trigger_zones: PackedVector2Array = PackedVector2Array()
@export var nav_tag: String = ""

# Runtime / export fields
@export var scene_path: String = ""
@export var temperature_modifier: float = 0.0
@export var oxygen_modifier: float = 0.0
@export var infection_bias: float = 0.0
@export var tags: Array = []
@export var enemy_spawn_table: Array = []
@export var loot_spawn_table: Array = []
