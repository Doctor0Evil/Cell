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

func add_item(instance: CellItemInstance) -> bool:
    if instance == null or instance.definition == null:
        return false

    # Try stacking first
    for i in range(slots.size()):
        var s := slots[i]
        if s == null:
            continue
        if s.can_stack_with(instance):
            var max_stack := s.definition.max_stack
            var can_add := max_stack - s.stack_count
            if can_add <= 0:
                continue
            var to_add := min(can_add, instance.stack_count)
            s.stack_count += to_add
            instance.stack_count -= to_add
            DebugLog.log("Inventory", "STACKED", {"slot": i, "item": s.definition.item_id, "added": to_add})
            if instance.stack_count <= 0:
                return true

    # Need new slots for remaining stack
    while instance.stack_count > 0:
        var empty_idx := _find_empty_slot()
        if empty_idx == -1:
            DebugLog.log("Inventory", "FULL", {"remaining": instance.stack_count, "item": instance.definition.item_id})
            return false
        var split := instance.duplicate() as CellItemInstance
        var split_count := min(split.definition.max_stack, instance.stack_count)
        split.stack_count = split_count
        instance.stack_count -= split_count
        slots[empty_idx] = split
        DebugLog.log("Inventory", "ADDED", {"slot": empty_idx, "item": split.definition.item_id, "count": split_count})

    return true

func _find_empty_slot() -> int:
    for i in range(slots.size()):
        if slots[i] == null:
            return i
    return -1

func use_item(slot_index: int) -> void:
    if slot_index < 0 or slot_index >= slots.size():
        return
    var inst := slots[slot_index]
    if inst == null or inst.definition == null:
        return

    var def := inst.definition
    if vitality_system == null:
        DebugLog.log("Inventory", "USE_FAILED_NO_VITALITY", {"item": def.item_id})
        return

    # Apply pool deltas via vitality system
    if def.blood_delta != 0.0 or def.protein_delta != 0.0:
        if def.blood_delta > 0.0:
            vitality_system.apply_heal(def.blood_delta, max(def.protein_delta, 0.0))
        else:
            vitality_system.apply_damage(abs(def.blood_delta))

    if def.oxygen_delta != 0.0:
        if def.oxygen_delta > 0.0:
            vitality_system.use_oxygencapsule(def.oxygen_delta)
        else:
            vitality_system.oxygen = max(0.0, vitality_system.oxygen + def.oxygen_delta)

    if def.stamina_delta != 0.0:
        vitality_system.stamina = clamp(vitality_system.stamina + def.stamina_delta, 0.0, vitality_system.staminamax)

    if def.wellness_delta != 0.0:
        vitality_system.wellness = clamp(vitality_system.wellness + def.wellness_delta, 0.0, vitality_system.wellnessmax)

    if def.body_temp_delta != 0.0:
        vitality_system.bodytemperature = clamp(
            vitality_system.bodytemperature + def.body_temp_delta,
            vitality_system.bodytemperaturemin,
            vitality_system.bodytemperaturemax
        )

    # Attribute hits (e.g. rationchips or drugs)
    vitality_system.vitality += def.vitality_delta
    vitality_system.instinct += def.instinct_delta
    vitality_system.tenacity += def.tenacity_delta
    vitality_system.agility += def.agility_delta
    vitality_system.logic += def.logic_delta
    vitality_system.influence += def.influence_delta
    vitality_system.temper += def.temper_delta
    vitality_system.yield += def.yield_delta

    vitality_system.recalcmaxima()

    # TODO: emit effects to buff system based on def.effect_tags

    # Condition & consumption
    inst.apply_use_condition_loss()
    inst.stack_count -= 1
    if inst.stack_count <= 0 or inst.condition <= 0.0:
        slots[slot_index] = null

    DebugLog.log("Inventory", "ITEM_USED", {
        "slot": slot_index,
        "item": def.item_id,
        "blood": vitality_system.blood,
        "oxygen": vitality_system.oxygen,
        "stamina": vitality_system.stamina,
        "wellness": vitality_system.wellness
    })
