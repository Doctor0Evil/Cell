tool
extends EditorScript
class_name TilesetMetadataValidator

const TILESET_DIR := "res://tilesets/"
const REQUIRED_KEYS := ["region_id", "biome_temp_c", "oxygen_state", "nav_tag"]

func _run():
    print("TilesetMetadataValidator: run via EditorScript API")

func validate_all() -> Dictionary:
    var report := {"ok": true, "errors": []}
    var files := DirAccess.get_files_at_path(TILESET_DIR)
    for f in files:
        if f.ends_with(".tres") or f.ends_with(".res"):
            var path := TILESET_DIR + f
            var ts := ResourceLoader.load(path)
            if ts == null:
                report["errors"].append({"file": path, "error": "load_failed"})
                report["ok"] = false
                continue
            # Iterate tile ids
            if not ts.has_method("get_tiles_ids"):
                continue
            for tid in ts.get_tiles_ids():
                var md := ts.tile_get_metadata(tid)
                if typeof(md) != TYPE_DICTIONARY:
                    report["errors"].append({"file": path, "tile": tid, "error": "missing_metadata"})
                    report["ok"] = false
                    continue
                for key in REQUIRED_KEYS:
                    if not md.has(key):
                        report["errors"].append({"file": path, "tile": tid, "error": "missing_key", "key": key})
                        report["ok"] = false
    return report

# Utility (DirAccess wrapper)
static func get_files_at_path(dir_path: String) -> Array:
    var out := []
    var da := DirAccess.open(dir_path)
    if not da:
        return out
    da.list_dir_begin()
    var fname := da.get_next()
    while fname != "":
        if not da.current_is_dir():
            out.append(fname)
        fname = da.get_next()
    da.list_dir_end()
    return out