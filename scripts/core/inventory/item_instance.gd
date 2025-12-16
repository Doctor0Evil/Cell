extends Resource
class_name CellItemInstance

@export var definition: CellItemDefinition
@export var stack_count: int = 1
@export var condition: float = 100.0

# Optional runtime flags (e.g., custom name, contamination)
var custom_data: Dictionary = {}

func can_stack_with(other: CellItemInstance) -> bool:
    if definition == null or other.definition == null:
        return false
    if definition.item_id != other.definition.item_id:
        return false
    if definition.is_unique:
        return false
    # Simple rule: stack only if condition difference is small
    if abs(condition - other.condition) > 5.0 and definition.has_condition:
        return false
    return true

func get_weight() -> float:
    if definition == null:
        return 0.0
    return definition.weight * float(stack_count)

func apply_use_condition_loss() -> void:
    if definition == null or not definition.has_condition:
        return
    condition -= definition.condition_loss_per_use
    condition = clamp(condition, 0.0, 100.0)
