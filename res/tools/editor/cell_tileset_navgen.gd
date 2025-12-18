@tool
extends EditorScript

const TILES_MANIFEST_GLOB := "res://assets/tilesets/*.tiles.json"

@export var nav_margin: int = 2 # pixels to inset nav polygon inside tile
@export var create_nav_scenes: bool = true
@export var nav_output_dir: String = "res://assets/tilesets/nav"
@export var force_overwrite: bool = false

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

	# Ensure nav output dir exists
	if create_nav_scenes:
		var da := DirAccess.open(nav_output_dir)
		if da == null:
			DirAccess.make_dir_recursive(nav_output_dir)

	for t in tiles:
		var coords := t.get("atlas_coords", [])
		if coords.size() < 2:
			continue
		var rx := int(coords[0])
		var ry := int(coords[1])
		var walkable := bool(t.get("walkable", false))
		if not walkable:
			continue

		# Create a simple rect navigation polygon for this tile
		var inset := float(nav_margin)
		var w := float(tile_size)
		var poly := NavigationPolygon.new()
		# Polygon points in local tile space (0..tile_size), inset by nav_margin
		var p0 := Vector2(inset, inset)
		var p1 := Vector2(w - inset, inset)
		var p2 := Vector2(w - inset, w - inset)
		var p3 := Vector2(inset, w - inset)
		var vertices := PoolVector2Array([p0, p1, p2, p3])
		poly.add_outline(vertices)
		poly.make_polygons_from_outlines()

		# Save as a NavigationRegion2D scene/resource so it can be placed in editor
		if create_nav_scenes:
			var scene := Node2D.new()
			scene.name = "%s_nav_%d_%d" % [png_path.get_file().get_basename(), rx, ry]
			var nav_region := NavigationRegion2D.new()
			nav_region.navigation_polygon = poly
			# Place region at tile origin (tile coordinates; consumers will translate by tile position)
			nav_region.position = Vector2(rx * tile_size, ry * tile_size)
			scene.add_child(nav_region)

			var out_scene_path := "%s/%s_nav_%d_%d.tscn" % [nav_output_dir, png_path.get_file().get_basename(), rx, ry]
			if (not force_overwrite) and FileAccess.file_exists(out_scene_path):
				print("Nav scene already exists, skipping (use force_overwrite to replace): %s" % out_scene_path)
			else:
				ResourceSaver.save(out_scene_path, scene)
				print("Wrote nav scene: %s" % out_scene_path)
				# companion metadata
				var meta := {"tileset": png_path, "atlas_coords": [rx, ry], "nav_scene": out_scene_path}
				var meta_path := out_scene_path.replace('.tscn', '.nav.json')
				var f := FileAccess.open(meta_path, FileAccess.WRITE)
				if f:
					f.store_string(to_json(meta))
					f.close()
					print("Wrote nav metadata: %s" % meta_path)

	print("Nav generation complete: %s" % path)