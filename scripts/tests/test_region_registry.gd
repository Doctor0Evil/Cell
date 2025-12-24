extends Node

func _ready() -> void:
    var registry := CellContentRegistry.new()
    var ids := ["ASHVEIL_DEBRIS_STRATUM", "IRON_HOLLOW_SPINAL_TRENCH", "COLD_VERGE_CRYO_RIM", "RED_SILENCE_SIGNAL_CRADLE"]
    for id in ids:
        var desc := registry.get_region(id)
        assert(desc.size() > 0, "Region descriptor missing for %s" % id)
        var scene_path := String(desc.get("scene_path", ""))
        assert(scene_path != "", "Scene path empty for %s" % id)
        var ok := ResourceLoader.exists(scene_path)
        assert(ok, "Scene file does not exist: %s (region %s)" % [scene_path, id])
        # Check predictable new fields (with sane defaults)
        assert(desc.has("tags"), "Region %s missing tags" % id)
        assert(desc.has("runtime_script_path"), "Region %s missing runtime_script_path" % id)
    print("Region registry smoke tests passed for: ", ids)