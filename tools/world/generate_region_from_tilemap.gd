tool
extends EditorScript
class_name TileMapLayer3DExporter

# Simple export tool: loads a scene containing TileMapLayer3D nodes, scans tiles for metadata,
# and writes a RegionDefinition and RegionNavData resource and a baked placeholder scene.

const OUT_DIR := "res://assets/world/regions/"

func _run():
    print("TileMapLayer3DExporter: run via EditorScript API with 'run()'")

func generate_region_from_scene(scene_path: String) -> Dictionary:
    var result := {"ok": false}
    var scene := ResourceLoader.load(scene_path)
    if scene == null:
        printerr("generate_region_from_scene: couldn't load %s" % scene_path)
        return result

    var root := scene.instantiate()
    var region_id := root.name if root and root.name != "" else Path(scene_path).get_basename()

    var def := preload("res://resources/regions/region_definition.gd").new()
    def.id = region_id
    def.scene_path = scene_path

    # Collect basic tile-derived modifiers
    def.temperature_modifier = 0.0
    def.oxygen_modifier = 0.0
    def.infection_bias = 0.0
    def.tags = []
    def.enemy_spawn_table = []
    def.loot_spawn_table = []

    # Walk nodes looking for TileMapLayer3D by type name
    var tm_nodes := []
    for node in root.get_children():
        if node.get_class() == "TileMapLayer3D" or node.name.begins_with("TileMapLayer3D"):
            tm_nodes.append(node)

    # Try a more recursive find
    if tm_nodes.is_empty():
        tm_nodes = _find_nodes_by_class_recursive(root, "TileMapLayer3D")

    for t in tm_nodes:
        # For each tile in the tileset, try to extract custom metadata keys
        # Plugin-specific API varies; try to read tile_set via t.tile_set or t.tileset
        var ts := null
        if t.has_method("get_tileset"):
            ts = t.get_tileset()
        elif t.has_method("tile_set"):
            ts = t.tile_set

        if ts:
            for tid in ts.get_tiles_ids():
                var md := ts.tile_get_metadata(tid)
                if typeof(md) == TYPE_DICTIONARY:
                    if md.has("region_id"):
                        def.tags.append(md["region_id"])
                    if md.has("biome_temp_c"):
                        def.temperature_modifier = float(md["biome_temp_c"])
                    if md.has("oxygen_state"):
                        # Simple mapping: SAFE->0.0, LOW->-0.5, TOXIC->+1.0, VACUUM->-2.0
                        var s := String(md["oxygen_state"]).to_upper()
                        match s:
                            "SAFE": def.oxygen_modifier = 0.0
                            "LOW": def.oxygen_modifier = -0.5
                            "TOXIC": def.oxygen_modifier = 1.0
                            "VACUUM": def.oxygen_modifier = -2.0
                    if md.has("nav_tag"):
                        # Example: gather spawn anchors from tileset metadata
                        var nav := String(md["nav_tag"]).to_upper()
                        if nav.begins_with("SPAWN_"):
                            def.enemy_spawn_table.append({"id": nav.replace("SPAWN_", ""), "min": 1, "max": 3, "group": "auto"})

    # Save region definition
    var save_path := OUT_DIR + region_id + ".tres"
    ResourceSaver.save(def, save_path)

    # Create a placeholder nav data resource
    var nav := preload("res://resources/regions/region_nav_data.gd").new()
    nav.grid_size = 1
    nav.nav_mesh_path = ""
    ResourceSaver.save(nav, OUT_DIR + region_id + "_nav.tres")

    # Bake a placeholder scene containing each TileMapLayer3D as a child node (real bake should produce meshes)
    var baked_scene := PackedScene.new()
    var baked_root := Node3D.new()
    baked_root.name = region_id + "_BAKED"
    for t in tm_nodes:
        var copy := t.duplicate()
        baked_root.add_child(copy)
    baked_scene.pack(baked_root)
    ResourceSaver.save(baked_scene, OUT_DIR + region_id + "_mesh.tscn")

    DebugLog.log("TileMapLayer3DExporter", "EXPORT", {"region": region_id, "scene": scene_path})
    result["ok"] = true
    result["region_id"] = region_id
    result["definition"] = save_path
    return result

func _find_nodes_by_class_recursive(node: Node, class_name: String) -> Array:
    var out := []
    for child in node.get_children():
        if child.get_class() == class_name:
            out.append(child)
        out += _find_nodes_by_class_recursive(child, class_name)
    return out
