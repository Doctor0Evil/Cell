extends Resource
class_name CellItemDefinition

@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

enum ItemType {
    WEAPON,
    AMMO,
    MEDICAL,
    TOOL,
    CONSUMABLE,
    ARMOR,
    COMPONENT,
    QUEST
}

@export var item_type: ItemType = ItemType.CONSUMABLE

# Inventory properties
@export var max_stack: int = 1
@export var weight: float = 0.5
@export var volume: float = 1.0
@export var is_unique: bool = false
@export var is_perishable: bool = false

# Condition (0–100). Some items degrade on use or exposure.
@export var has_condition: bool = false
@export var initial_condition: float = 100.0
@export var condition_loss_per_use: float = 0.0

# V.I.T.A.L.I.T.Y. and pool interactions (delta values)
@export var blood_delta: float = 0.0
@export var protein_delta: float = 0.0
@export var oxygen_delta: float = 0.0
@export var stamina_delta: float = 0.0
@export var wellness_delta: float = 0.0
@export var body_temp_delta: float = 0.0

# Attribute deltas (applied once on use or while equipped)
@export var vitality_delta: float = 0.0
@export var instinct_delta: float = 0.0
@export var tenacity_delta: float = 0.0
@export var agility_delta: float = 0.0
@export var logic_delta: float = 0.0
@export var influence_delta: float = 0.0
@export var temper_delta: float = 0.0
@export var yield_delta: float = 0.0

# Temporary effects in seconds (handled by a buff system)
@export var effect_tags: Array[String] = [] # e.g. "PAIN_SUPPRESS", "BLEED_SLOW"
@export var effect_duration: float = 0.0

# Equipping & slot usage
@export var equip_slot: String = "" # "PRIMARY", "SECONDARY", "HEAD", "TORSO", etc.
@export var move_speed_mult: float = 1.0
@export var oxygen_decay_mult: float = 1.0
@export var temp_drop_mult: float = 1.0

# Crafting metadata
@export var crafting_tags: Array[String] = []   # e.g. ["CLOTH", "BANDAGE_BASE"]
@export var known_pair_ids: Array[String] = []  # item_ids of best-known combos to show in UI
@export var crafted_result_id: String = ""      # result when used as primary item
@export var crafted_result_count: int = 1

# Visuals
@export var icon: Texture2D
@export var world_scene: PackedScene

func has_any_vitality_effect() -> bool:
    return blood_delta != 0.0 \
        or protein_delta != 0.0 \
        or oxygen_delta != 0.0 \
        or stamina_delta != 0.0 \
        or wellness_delta != 0.0 \
        or body_temp_delta != 0.0
