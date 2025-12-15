extends Node2D
class_name PixelHorrorTilesetLoader

@export var tilemap: TileMap
@export var tileset_path: String = "res://ASSETS/CC0/tilesets/pixel_horror_facility.tres"

func _ready() -> void:
    if not tilemap:
        push_warning("PixelHorrorTilesetLoader: tilemap not assigned.")
        return
    if not ResourceLoader.exists(tileset_path):
        push_warning("PixelHorrorTilesetLoader: tileset '%s' not found." % tileset_path)
        return

    var ts: TileSet = load(tileset_path)
    tilemap.tile_set = ts

    # Example: tag cell (0,0) as a blocked, bloody floor tile for quick testing
    # layer 0, source_id 0, atlas (3,1) – assumes a CC0 tileset with blood tile at that coord
    tilemap.set_cell(0, Vector2i(0, 0), 0, Vector2i(3, 1))
