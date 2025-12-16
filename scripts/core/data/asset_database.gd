extends Resource
class_name AssetDatabase

@export var assets: Array[AssetDefinition] = []

func get_by_id(id: StringName) -> AssetDefinition:
    for a in assets:
        if a.id == id:
            return a
    return null

func get_by_category(category: StringName) -> Array[AssetDefinition]:
    var out: Array[AssetDefinition] = []
    for a in assets:
        if a.category == category:
            out.append(a)
    return out

func get_with_tag(tag: StringName) -> Array[AssetDefinition]:
    var out: Array[AssetDefinition] = []
    for a in assets:
        if tag in a.tags:
            out.append(a)
    return out
