extends Node
class_name AssetRegistry

@export var database: AssetDatabase

var _by_id: Dictionary = {}

func _ready() -> void:
    _build_index()

func _build_index() -> void:
    _by_id.clear()
    if not database:
        push_warning("AssetRegistry: no AssetDatabase assigned.")
        return
    for a in database.assets:
        if a.id == StringName():
            push_warning("AssetRegistry: asset has empty id, skipping.")
            continue
        if _by_id.has(a.id):
            push_warning("AssetRegistry: duplicate id '%s', overwriting." % a.id)
        _by_id[a.id] = a

func get(id: StringName) -> AssetDefinition:
    if not _by_id.has(id):
        push_warning("AssetRegistry: unknown asset id '%s'." % id)
        return null
    return _by_id[id] as AssetDefinition

func get_weapon(id: StringName) -> WeaponDefinition:
    var a := get(id)
    return a as WeaponDefinition

func get_armor(id: StringName) -> ArmorDefinition:
    var a := get(id)
    return a as ArmorDefinition

func get_implant(id: StringName) -> ImplantDefinition:
    var a := get(id)
    return a as ImplantDefinition

func get_consumable(id: StringName) -> ConsumableDefinition:
    var a := get(id)
    return a as ConsumableDefinition
