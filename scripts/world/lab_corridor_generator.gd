extends Node2D
class_name LabCorridorGenerator

@export var width: int = 32
@export var height: int = 12
@export var debug_enabled: bool = true

@export var tileset: TileSet

@onready var _floor: TileMapLayer = $LabCorridorFloor
@onready var _walls: TileMapLayer = $LabCorridorWalls
@onready var _props: TileMapLayer = $LabCorridorProps

const FLOOR_FLESH_GROUP := "FLESH_FLOOR"
const FLOOR_METAL_GROUP := "METAL_FLOOR"
const FLOOR_BLOOD_GROUP := "CORRIDOR_BLOOD"
const WALL_LAB_GROUP := "NANOTECH_WALL"
const PROP_CONTAINMENT_GROUP := "CONTAINMENT_TUBE"
const PROP_TERMINAL_GROUP := "CORRUPTED_TERMINAL"
const OVERLAY_GROWTH_GROUP := "GROWTH_OVERLAY"

var _tile_lookup: Dictionary = {} # group -> Array[Dictionary{source_id, atlas_coords: Vector2i}]

func _ready() -> void:
    randomize()
    if tileset:
        _build_tile_lookup()
    _generate_corridor()

func _build_tile_lookup() -> void:
    _tile_lookup.clear()

    func add_group(group: String, names: Array) -> void:
        var entries: Array = []
        for name in names:
            var match := _get_tile_by_name(name)
            if not match.is_empty():
                entries.append(match)
        _tile_lookup[group] = entries

    add_group(FLOOR_FLESH_GROUP, [
        "floor_flesh_panel_a",
        "floor_flesh_panel_b"
    ])

    add_group(FLOOR_METAL_GROUP, [
        "floor_metal_panel_clean",
        "floor_metal_panel_stain"
    ])

    add_group(FLOOR_BLOOD_GROUP, [
        "floor_corridor_blood_light",
        "floor_corridor_blood_heavy"
    ])

    add_group(WALL_LAB_GROUP, [
        "wall_nanotech_clean",
        "wall_nanotech_cracked",
        "wall_nanotech_growth"
    ])

    add_group(PROP_CONTAINMENT_GROUP, [
        "prop_containment_broken",
        "prop_containment_intact"
    ])

    add_group(PROP_TERMINAL_GROUP, [
        "prop_terminal_corrupted",
        "prop_terminal_off"
    ])

    add_group(OVERLAY_GROWTH_GROUP, [
        "overlay_growth_pulse_a",
        "overlay_growth_pulse_b"
    ])

func _get_tile_by_name(tile_name: String) -> Dictionary:
    if tileset == null:
        return {}

    var source_count := tileset.get_source_count()
    for i in range(source_count):
        var source_id := tileset.get_source_id(i)
        var src := tileset.get_source(source_id)
        if src == null:
            continue
        if src.resource_name == tile_name and src is TileSetAtlasSource:
            var tile_ids := src.get_tiles_ids()
            if tile_ids.size() == 0:
                continue
            var first_id: Vector2i = tile_ids[^1]
            return {
                "source_id": source_id,
                "atlas_coords": first_id
            }

    return {}

func _generate_corridor() -> void:
    _floor.clear()
    _walls.clear()
    _props.clear()

    if debug_enabled:
        DebugLog.log("LabCorridorGenerator", "GENERATE_START", {"width": width, "height": height})

    for x in range(width):
        for y in range(height):
            var cell := Vector2i(x, y)
            var is_edge_y := (y == 0 or y == height - 1)
            var is_edge_x := (x == 0 or x == width - 1)

            # Base floor selection
            var base_group := FLOOR_METAL_GROUP
            if randf() < 0.25:
                base_group = FLOOR_FLESH_GROUP
            if randf() < 0.15 and y > 1 and y < height - 2:
                base_group = FLOOR_BLOOD_GROUP

            _set_tile_random(_floor, base_group, cell)

            # Walls around edges
            if is_edge_y or is_edge_x:
                _set_tile_random(_walls, WALL_LAB_GROUP, cell)

            # Props and overlays inside corridor
            if not is_edge_x and not is_edge_y:
                if randf() < 0.06 and y == 1:
                    _set_tile_random(_props, PROP_CONTAINMENT_GROUP, cell)
                elif randf() < 0.04 and y == height - 2:
                    _set_tile_random(_props, PROP_TERMINAL_GROUP, cell)
                elif randf() < 0.08:
                    _set_tile_random(_props, OVERLAY_GROWTH_GROUP, cell)

    if debug_enabled:
        DebugLog.log("LabCorridorGenerator", "GENERATE_FINISH", {"floor_tiles": _floor.get_used_cells().size()})

func _set_tile_random(tilemap: TileMapLayer, group: String, cell: Vector2i) -> void:
    if not _tile_lookup.has(group):
        return
    var arr: Array = _tile_lookup[group]
    if arr.is_empty():
        return

    var pick: Dictionary = arr[randi() % arr.size()]
    var source_id: int = pick["source_id"]
    var atlas_coords: Vector2i = pick["atlas_coords"]

    tilemap.set_cell(cell, source_id, atlas_coords)
