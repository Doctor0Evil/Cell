extends Resource
class_name FractureLibrary

@export var fractures: Array[FractureDefinition] = []

func get(id: StringName) -> FractureDefinition:
    for f in fractures:
        if f.id == id:
            return f
    return null
