extends AssetDefinition
class_name WeaponDefinition

@export var slot: StringName = &"primary"  # primary, secondary, melee, heavy
@export var damage_base: float = 10.0
@export var damage_type: StringName = &"ballistic" # ballistic, thermal, chemical, kinetic, cell_corruption
@export var rate_of_fire_rps: float = 2.0
@export var magazine_size: int = 10
@export var reload_time_s: float = 2.0
@export var spread_deg: float = 3.0
@export var recoil_impulse: float = 1.0

@export var effective_range_m: float = 15.0
@export var armor_pierce: float = 0.0
@export var noise_level: float = 1.0

@export var ammo_id: StringName = &"ammo_standard"
@export var on_hit_effect_ids: Array[StringName] = []
