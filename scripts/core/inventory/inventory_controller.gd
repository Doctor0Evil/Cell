extends Node
class_name InventoryController

@export var capacity_slots: int = 32
@export var quick_slots_count: int = 6

var slots: Array[CellItemInstance] = []
var quick_slots: Array[int] = [] # indices into slots, -1 means empty

var vitality_system: PlayerVitalitySystem
var player_status: PlayerStatus

func _ready() -> void:
    slots.resize(capacity_slots)
    for i in range(capacity_slots):
        slots[i] = null
    quick_slots.resize(quick_slots_count)
    for i in range(quick_slots_count):
        quick_slots[i] = -1

    if player_status == null:
        player_status = get_tree().get_first_node_in_group("player_status")
    if player_status:
        vitality_system = player_status.vitalitysystem
