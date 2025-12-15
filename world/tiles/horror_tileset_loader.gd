extends Node
class_name HorrorTilesetLoader

@export var tilemap: TileMap
@export var tileset_key := "facility_corridor"

func _ready() -> void:
    if not tilemap:
        push_warning("HorrorTilesetLoader: tilemap not assigned.")
        return
    var tileset_path := HorrorAssetRegistry.get_tileset(tileset_key)
    if tileset_path == "":
        return
    var ts: TileSet = load(tileset_path)
    tilemap.tile_set = ts
