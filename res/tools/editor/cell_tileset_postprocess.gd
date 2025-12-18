@tool
extends EditorScript

const TILES_MANIFEST_GLOB := "res://assets/tilesets/*.tiles.json"

@export var collision_margin: int = 2 # pixels to inset collision rect from tile edges
@export var create_nav_polygons: bool = true

func _run() -> void:
	var dir := DirAccess.open("res://assets/tilesets")
	if dir == null:
		push_error("Tilesets folder not found: res://assets/tilesets")
		return
	var files := dir.get_files()
	for f in files:
		if not f.ends_with(".tiles.json"):
			continue
		var manifest_path := "res://assets/tilesets/%s" % f
		_process_manifest(manifest_path)

func _process_manifest(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open tiles manifest: %s" % path)
		return
	var data := JSON.parse_string(file.get_as_text())
	if data.error != OK:
		push_error("Failed to parse tiles manifest: %s" % data.error_string)
		return
	var manifest := data.result
	var png_path := manifest.get("file", "")
	var tile_size := int(manifest.get("tile_size", 32))
	var cols := int(manifest.get("cols", 0))
	var rows := int(manifest.get("rows", 0))
	var tiles := manifest.get("tiles", [])
	if png_path == "":
		push_error("Manifest missing file field: %s" % path)
		return
	# derive tileset resource path
	var ts_res_path := png_path.replace('.png', '.tres')
	var ts := ResourceLoader.load(ts_res_path)
	if ts == null:
		push_warning("TileSet resource not found for %s, creating collision scene assets only." % ts_res_path)

	# Ensure collisions output folder
	var coll_dir := "res://assets/tilesets/collisions"
	var da := DirAccess.open(coll_dir)
	if da == null:
		DirAccess.make_dir_recursive(coll_dir)

	for t in tiles:
		var coords := t.get("atlas_coords", [])
		if coords.size() < 2:
			continue
		var rx := int(coords[0])
		var ry := int(coords[1])
		var non_void := bool(t.get("non_void", false))
		if not non_void:
			continue
		# Attempt to apply a RectangleShape2D to the TileSet if API available
		var applied := false
		if ts != null and ts.has_method("tile_set_shape"):
			# create rectangle shape and transform
			var shape := RectangleShape2D.new()
			shape.extents = Vector2((tile_size / 2) - collision_margin, (tile_size / 2) - collision_margin)
			var transform := Transform2D.IDENTITY
			# try to set shape on tile (source_id + atlas coords supported in Godot 4 TileSet API)
			# defensively call a couple possible method signatures
			var ok := false
			# signature trial 1: tile_set_shape(source_id, atlas_coords, shape)
			try:
				ts.tile_set_shape(rx + ry * cols, shape) # best-effort attempt using a numeric id
				ok = true
			except:
				ok = false
			if ok:
				applied = true
				print("Applied shape to %s tile [%d,%d] (TileSet)" % [ts_res_path, rx, ry])
		if not applied:
			# Fallback: create a small scene with a StaticBody2D and CollisionShape2D
			var scene := Node2D.new()
			scene.name = "%s_tile_%d_%d" % [png_path.get_file().get_basename(), rx, ry]
			var body := StaticBody2D.new()
			var cs := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.extents = Vector2((tile_size / 2) - collision_margin, (tile_size / 2) - collision_margin)
			cs.shape = rect
			cs.position = Vector2(tile_size / 2, tile_size / 2)
			body.add_child(cs)
			scene.add_child(body)
			var out_scene_path := "%s/%s_tile_%d_%d.tscn" % [coll_dir, png_path.get_file().get_basename(), rx, ry]
			ResourceSaver.save(out_scene_path, scene)
			print("Wrote collision scene: %s" % out_scene_path)
			# Optionally write a small metadata file linking this collision to the tileset tile
			var meta := {"tileset": ts_res_path, "atlas_coords": [rx, ry], "collision_scene": out_scene_path}
			var meta_path := out_scene_path.replace('.tscn', '.collision.json')
			var f := FileAccess.open(meta_path, FileAccess.WRITE)
			if f:
				f.store_string(to_json(meta))
				f.close()
				print("Wrote collision metadata: %s" % meta_path)

	# After processing each manifest, save TileSet resource if modified
	if ts != null:
		ResourceSaver.save(ts_res_path, ts)
		print("Saved TileSet: %s" % ts_res_path)

	print("Postprocess complete: %s" % path)
