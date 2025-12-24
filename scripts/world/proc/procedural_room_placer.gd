extends Node
class_name ProceduralRoomPlacer

# Prototype: snaps RoomArchetypes to anchors found in TileMapLayer3D metadata.
@export var archetype_paths: Array = [] # PackedScene paths

func place_rooms_on_map(tilemap_root: Node, seed: int = 1337) -> Array:
    var placed := []
    randomize()
    var anchors := _find_anchor_tiles(tilemap_root, "ROOM_ANCHOR")
    for a in anchors:
        var scene_path := archetype_paths[randi() % archetype_paths.size()]
        var packed := ResourceLoader.load(scene_path)
        if packed and packed is PackedScene:
            var inst := packed.instantiate()
            inst.global_transform.origin = a
            tilemap_root.add_child(inst)
            placed.append(inst)
    return placed

func _find_anchor_tiles(root: Node, anchor_tag: String) -> Array:
    var anchors := []
    var tm_nodes := _find_nodes_by_class_recursive(root, "TileMapLayer3D")
    for t in tm_nodes:
        if t.has_method("get_used_cells"):
            for cell in t.get_used_cells():
                var tid := t.get_cell_tile(cell)
                var ts := null
                if t.has_method("get_tileset"):
                    ts = t.get_tileset()
                if ts:
                    var md := ts.tile_get_metadata(tid)
                    if typeof(md) == TYPE_DICTIONARY and md.get("nav_tag", "").to_upper() == anchor_tag:
                        anchors.append(t.map_to_world(cell))
    return anchors

func _find_nodes_by_class_recursive(node: Node, class_name: String) -> Array:
    var out := []
    for child in node.get_children():
        if child.get_class() == class_name:
            out.append(child)
        out += _find_nodes_by_class_recursive(child, class_name)
    return out