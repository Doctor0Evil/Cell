@tool
extends EditorScript

# Cell TileSet collision + navigation postprocess.
# - Scans tools/generated-manifests for *.tiles.json
# - For each non-void tile, ensures:
#   * A full-rect collision shape on physics layer 0, if none exists
#   * An optional full-rect NavigationPolygon on navigation layer 0, if enabled
#
# This implementation is defensive about Godot 4 TileSetAtlasSource API differences.

const MANIFEST_ROOT := "res://tools/generated-manifests"
const TILE_MANIFEST_SUFFIX := ".tiles.json"

# Global control flags for this pass.
const NAV_ENABLED := true
const COLLISION_LAYER_INDEX := 0
const NAVIGATION_LAYER_INDEX := 0

func _run() -> void:
	var fs := DirAccess.open(MANIFEST_ROOT)
	if fs == null:
		push_error("CellTilesetCollisionNavPass: Manifest root not found: %s" % MANIFEST_ROOT)
		return
	
	var manifests := _collect_tiles_manifests()
	if manifests.is_empty():
		print("CellTilesetCollisionNavPass: No *.tiles.json manifests found under %s" % MANIFEST_ROOT)
		return

	var edited_tilesets: Dictionary = {}
	for manifest_path in manifests:
		var manifest := _load_json(manifest_path)
		if manifest.is_empty():
			continue
		if not manifest.has("tileset"):
			push_warning("CellTilesetCollisionNavPass: Manifest missing 'tileset': %s" % manifest_path)
			continue
		var tileset_path: String = manifest["tileset"]
		if tileset_path.is_empty():
			push_warning("CellTilesetCollisionNavPass: Empty tileset path in %s" % manifest_path)
			continue
		var tileset: TileSet = _load_tileset(tileset_path)
		if tileset == null:
			push_error("CellTilesetCollisionNavPass: Failed to load TileSet: %s" % tileset_path)
			continue
		var tile_size := 32
		if manifest.has("tile_size") and typeof(manifest["tile_size"]) == TYPE_INT:
			tile_size = manifest["tile_size"]
		if not manifest.has("tiles") or typeof(manifest["tiles"]) != TYPE_ARRAY:
			push_warning("CellTilesetCollisionNavPass: Manifest has no 'tiles' array: %s" % manifest_path)
			continue
		var tiles: Array = manifest["tiles"]
		var atlas_sources := _ensure_atlas_source_index_map(tileset, tile_size)
		for tile_desc in tiles:
			if typeof(tile_desc) != TYPE_DICTIONARY:
				continue
			_process_tile_entry(tileset, atlas_sources, tile_desc, tile_size)
		ResourceSaver.save(tileset_path, tileset)
		edited_tilesets[tileset_path] = true
		print("CellTilesetCollisionNavPass: Updated collisions+nav in %s" % tileset_path)

	if edited_tilesets.size() == 0:
		print("CellTilesetCollisionNavPass: No TileSets modified.")
	else:
		print("CellTilesetCollisionNavPass: Completed. Modified TileSets:")
		for path in edited_tilesets.keys():
			print("  - %s" % path)


func _collect_tiles_manifests() -> Array:
	var results: Array = []
	var stack: Array = [MANIFEST_ROOT]
	while not stack.is_empty():
		var current := stack.pop_back()
		var dir := DirAccess.open(current)
		if dir == null:
			continue
		dir.list_dir_begin()
		while true:
			var name := dir.get_next()
			if name == "":
				break
			if dir.current_is_dir():
				if name.begins_with("."):
					continue
				stack.push_back(current.path_join(name))
			else:
				if name.ends_with(TILE_MANIFEST_SUFFIX):
					results.push_back(current.path_join(name))
		dir.list_dir_end()
	return results


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("CellTilesetCollisionNavPass: Cannot open JSON: %s" % path)
		return {}
	var text := file.get_as_text()
	file.close()
	var data := JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("CellTilesetCollisionNavPass: JSON is not an object: %s" % path)
		return {}
	return data


func _load_tileset(path: String) -> TileSet:
	var ts := ResourceLoader.load(path)
	if ts == null or not (ts is TileSet):
		return null
	return ts


func _ensure_atlas_source_index_map(tileset: TileSet, tile_size: int) -> Dictionary:
	# Map from atlas key (Vector2i(grid_x, grid_y)) to atlas source id.
	var atlas_sources: Dictionary = {}
	for source_id in tileset.get_source_ids():
		var source := tileset.get_source(source_id)
		if source is TileSetAtlasSource:
			var atlas_source: TileSetAtlasSource = source
			var tex := atlas_source.get_texture()
			if tex == null:
				continue
			var tex_size := tex.get_size()
			var cols := int(tex_size.x / tile_size)
			var rows := int(tex_size.y / tile_size)
			for y in range(rows):
				for x in range(cols):
					var coord := Vector2i(x, y)
					if atlas_source.has_tile(coord):
						atlas_sources[coord] = source_id
	return atlas_sources


func _process_tile_entry(tileset: TileSet, atlas_sources: Dictionary, tile_desc: Dictionary, tile_size: int) -> void:
	if not tile_desc.has("id"):
		return
	var kind := ""
	if tile_desc.has("kind") and typeof(tile_desc["kind"]) == TYPE_STRING:
		kind = tile_desc["kind"]
	if kind == "void":
		return
	var blocking := false
	if tile_desc.has("blocking"):
		blocking = bool(tile_desc["blocking"])
	var walkable := false
	if tile_desc.has("walkable"):
		walkable = bool(tile_desc["walkable"])
	elif kind == "walkable":
		walkable = true
	var atlas_x := 0
	var atlas_y := 0
	if tile_desc.has("atlas_x"):
		atlas_x = int(tile_desc["atlas_x"])
	if tile_desc.has("atlas_y"):
		atlas_y = int(tile_desc["atlas_y"])
	var coord := Vector2i(atlas_x, atlas_y)
	var source_id := _ensure_atlas_tile(tileset, atlas_sources, coord, tile_size)
	if source_id < 0:
		return
	var atlas_source: TileSetAtlasSource = tileset.get_source(source_id)
	if atlas_source == null:
		return
	if blocking:
		_ensure_tile_collision(tileset, atlas_source, coord, tile_size)
	if NAV_ENABLED and walkable:
		_ensure_tile_navigation(tileset, atlas_source, coord, tile_size)


func _ensure_atlas_tile(tileset: TileSet, atlas_sources: Dictionary, coord: Vector2i, tile_size: int) -> int:
	if atlas_sources.has(coord):
		return int(atlas_sources[coord])
	# Fallback: use any existing atlas source that has the coord defined.
	for source_id in tileset.get_source_ids():
		var source := tileset.get_source(source_id)
		if source is TileSetAtlasSource:
			var atlas_source: TileSetAtlasSource = source
			if atlas_source.has_tile(coord):
				atlas_sources[coord] = source_id
				return source_id
	# If no atlas has this coordinate, we do not create tiles here because
	# the loader is responsible for the atlas layout.
	return -1


func _ensure_tile_collision(tileset: TileSet, atlas_source: TileSetAtlasSource, coord: Vector2i, tile_size: int) -> void:
	# Attempt Godot 4 physics-layer API first
	var layer := COLLISION_LAYER_INDEX
	var existing := []
	if atlas_source.has_method("get_physics_layer_collision_shapes"):
		existing = atlas_source.get_physics_layer_collision_shapes(coord, layer)
	elif atlas_source.has_method("get_collision_shapes"):
		existing = atlas_source.get_collision_shapes(coord, layer)
	if existing.size() > 0:
		# Preserve manual edits; do not overwrite.
		return
	# create rectangle shape
	var shape := RectangleShape2D.new()
	shape.size = Vector2(tile_size, tile_size)
	# Try using physics-layer shape setters
	var ok := false
	if atlas_source.has_method("add_physics_layer_shape"):
		var shape_index := 0
		# get count if available
		if atlas_source.has_method("get_physics_layer_shape_count"):
			shape_index = int(atlas_source.get_physics_layer_shape_count(coord, layer))
		atlas_source.add_physics_layer_shape(coord, layer)
		# set shape and transform
		if atlas_source.has_method("set_physics_layer_shape_shape"):
			atlas_source.set_physics_layer_shape_shape(coord, layer, shape_index, shape)
		if atlas_source.has_method("set_physics_layer_shape_transform"):
			atlas_source.set_physics_layer_shape_transform(coord, layer, shape_index, Transform2D.IDENTITY.translated(Vector2(tile_size * 0.5, tile_size * 0.5)))
		ok = true
	# Fallback to older add_collision_shape call
	if not ok and atlas_source.has_method("add_collision_shape"):
		# create a simple shape container if API expects it
		var shape_data := {
			"shape": shape,
			"transform": Transform2D.IDENTITY.translated(Vector2(tile_size * 0.5, tile_size * 0.5))
		}
		atlas_source.add_collision_shape(coord, layer, shape_data)
		ok = true
	if ok:
		print("Added collision for tile [%d,%d]" % [coord.x, coord.y])


func _ensure_tile_navigation(tileset: TileSet, atlas_source: TileSetAtlasSource, coord: Vector2i, tile_size: int) -> void:
	# Try to preserve manual nav edits
	var nav_exists := false
	if atlas_source.has_method("get_navigation_polygon"):
		var existing_nav := atlas_source.get_navigation_polygon(coord, NAVIGATION_LAYER_INDEX)
		if existing_nav != null:
			nav_exists = true
	if nav_exists:
		return
	# create simple rect nav polygon
	var nav_polygon := NavigationPolygon.new()
	var points := PackedVector2Array()
	points.push_back(Vector2(0.0, 0.0))
	points.push_back(Vector2(tile_size, 0.0))
	points.push_back(Vector2(tile_size, tile_size))
	points.push_back(Vector2(0.0, tile_size))
	nav_polygon.add_outline(points)
	nav_polygon.make_polygons_from_outlines()
	# set it via available API
	if atlas_source.has_method("set_navigation_polygon"):
		atlas_source.set_navigation_polygon(coord, NAVIGATION_LAYER_INDEX, nav_polygon)
		atlas_source.set_navigation_polygon_offset(coord, NAVIGATION_LAYER_INDEX, Vector2.ZERO)
		print("Added nav polygon for tile [%d,%d]" % [coord.x, coord.y])
	else:
		# fallback: write a navigation scene resource next to tileset for manual placement
		var nav_dir := "res://assets/tilesets/nav"
		DirAccess.make_dir_recursive(nav_dir)
		var scene := Node2D.new()
		scene.name = "%s_nav_%d_%d" % [tileset.resource_path.get_file().get_basename(), coord.x, coord.y]
		var nav_region := NavigationRegion2D.new()
		nav_region.navigation_polygon = nav_polygon
		nav_region.position = Vector2(coord.x * tile_size, coord.y * tile_size)
		scene.add_child(nav_region)
		var out_scene_path := "%s/%s_nav_%d_%d.tscn" % [nav_dir, tileset.resource_path.get_file().get_basename(), coord.x, coord.y]
		ResourceSaver.save(out_scene_path, scene)
		print("Wrote nav scene fallback: %s" % out_scene_path)
