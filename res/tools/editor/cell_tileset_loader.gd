@tool
extends EditorScript

const TILESETS_MANIFEST := "res://tools/generated-manifests/cell_tilesets.json"

func _run() -> void:
	var file := FileAccess.open(TILESETS_MANIFEST, FileAccess.READ)
	if file == null:
		push_error("Tileset manifest not found: %s" % TILESETS_MANIFEST)
		return
	var result := JSON.parse_string(file.get_as_text())
	if result.error != OK:
		push_error("Failed to parse tileset manifest: %s" % result.error_string)
		return
	var data := result.result
	if typeof(data) != TYPE_ARRAY:
		push_error("Tileset manifest must be an array.")
		return

	for entry in data:
		if not entry.has("file"):
			continue
		var png_path: String = entry["file"]
		var tex := load(png_path)
		if tex == null:
			push_error("Failed to load tileset texture: %s" % png_path)
			continue

		var ts := TileSet.new()
		var source_id := ts.add_source(TileSetAtlasSource.new())
		var atlas := ts.get_source(source_id) as TileSetAtlasSource
		atlas.texture = tex
		atlas.set_texture_region_size(Vector2i(int(entry.get("tile_size", 32)), int(entry.get("tile_size", 32))))

		# Auto-create atlas regions for each grid cell and collect simple tile metadata
		var tile_size := int(entry.get("tile_size", 32))
		var img := tex.get_image()
		img.lock()
		var tex_w := img.get_width()
		var tex_h := img.get_height()
		var cols := int(tex_w / tile_size)
		var rows := int(tex_h / tile_size)
		var tiles_meta := []

		for ry in range(rows):
			for rx in range(cols):
				var region_rect := Rect2(rx * tile_size, ry * tile_size, tile_size, tile_size)
				# Try several add methods to be compatible across Godot versions
				if atlas.has_method("create_tile"):
					atlas.create_tile(Vector2i(rx, ry))
				elif atlas.has_method("add_tile"):
					atlas.add_tile(Vector2i(rx, ry))
				elif atlas.has_method("add_region"):
					atlas.add_region(region_rect)
				# Heuristic: sample a small 3x3 area near center to determine "non-void"
				var cx := int(region_rect.position.x + tile_size / 2)
				var cy := int(region_rect.position.y + tile_size / 2)
				var non_void := false
				for sy in [-1, 0, 1]:
					for sx in [-1, 0, 1]:
						var sxp := clamp(cx + sx, 0, tex_w - 1)
						var syp := clamp(cy + sy, 0, tex_h - 1)
						var col := img.get_pixel(sxp, syp)
						if col.a > 0.02 or (col.r + col.g + col.b) > 0.01:
							non_void = true
							break
					if non_void:
						break
				tiles_meta.append({"atlas_coords": [rx, ry], "non_void": non_void, "walkable": (not non_void)})

		img.unlock()

		# Save TileSet alongside the PNG
		var ts_res_path := png_path.replace('.png', '.tres')
		ResourceSaver.save(ts, ts_res_path)

		# Write a companion .json manifest with tile metadata for later editing (collisions/navigation)
		var meta_path := png_path.replace('.png', '.tiles.json')
		var meta_out := { "file": png_path, "tile_size": tile_size, "cols": cols, "rows": rows, "tiles": tiles_meta }
		var f := FileAccess.open(meta_path, FileAccess.WRITE)
		if f:
			f.store_string(to_json(meta_out))
			f.close()
			print("Wrote tiles metadata: %s" % meta_path)

		print("Created TileSet resource: %s" % ts_res_path)
