extends Node2D
class_name PixelHorrorTilesetLoader

@export var tilemap: TileMap
@export var tileset: TileSet
@export var license_tag := "CC0"  # "CC0" or "CC_BY" – for internal audit

func _ready() -> void:
    if not tilemap:
        push_warning("PixelHorrorTilesetLoader: tilemap not assigned.")
        return
    if not tileset:
        push_warning("PixelHorrorTilesetLoader: tileset not assigned.")
        return

    # Internal safety: only allow vetted tilesets (you enforce in import pipeline).
    if license_tag != "CC0" and license_tag != "CC_BY":
        push_error("PixelHorrorTilesetLoader: tileset has unsupported license_tag: %s" % license_tag)
        return

    tilemap.tile_set = tileset
