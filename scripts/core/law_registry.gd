extends Resource
class_name LawRegistry

@export var laws: Array[LawDefinition] = []

func get_law(id: StringName) -> LawDefinition:
    for l in laws:
        if l.id == id:
            return l
    return null
