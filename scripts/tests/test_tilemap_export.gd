extends Node

func _ready() -> void:
    # Run a simple smoke export on the Ashveil scene
    var exporter := preload("res://tools/world/generate_region_from_tilemap.gd")
    var res := exporter.new().generate_region_from_scene("res://scenes/world/regions/AshveilDebrisStratum.tscn")
    DebugLog.log("TestTilemapExport", "SMOKE", res)
    assert(res.has("ok") and res["ok"])