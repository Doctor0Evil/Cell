extends Resource
class_name AssetDatabase

@export var assets: Array[AssetDefinition] = []

func get_by_id(id: StringName) -> AssetDefinition:
    var a: AssetDefinition
    for a in assets:
        if a.id == id:
            return a
    return null

func get_by_category(category: StringName) -> Array[AssetDefinition]:
    var out: Array[AssetDefinition] = []
    var a: AssetDefinition
    for a in assets:
        if a.category == category:
            out.append(a)
    return out

func get_with_tag(tag: StringName) -> Array[AssetDefinition]:
    var out: Array[AssetDefinition] = []
    var a: AssetDefinition
    for a in assets:
        if tag in a.tags:
            out.append(a)
    return out


# Convenience builder: populate the database with default assets on startup.
# Extend this with other category loaders as the project grows (weapons, armor, tools, etc.).
func load_default_assets() -> void:
    assets.clear()

    # ... existing weapons / armor / tools can be appended here ...

    # Meds
    for med_def in MedsRegistry.build_all():
        assets.append(med_def)

    # Oxygen hardware (LOX bottles / cryo cores)
    if ResourceLoader.exists("res://scripts/core/data/oxygen_registry.gd"):
        for ox_def in OxygenRegistry.build_all():
            assets.append(ox_def)

    # Generated consumables from disk (res://res/data/consumables/*.tres)
    var _da := DirAccess.open("res://res/data/consumables")
    if _da:
        _da.list_dir_begin()
        var _f := _da.get_next()
        while _f != "":
            if _f.endswith(".tres"):
                var _path := "res://res/data/consumables/" + _f
                var _r := ResourceLoader.load(_path)
                if _r and _r is ConsumableDefinition:
                    assets.append(_r)
            _f = _da.get_next()
        _da.list_dir_end()

    # (Note: ensure this function is called by your startup/init code.)
