extends Node

@export var tilemap: TileMap
@export var tileset_resource: TileSet

func _ready() -> void:
    if tilemap and tileset_resource:
        tilemap.tile_set = tileset_resource
