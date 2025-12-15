extends Node
class_name LicenseAwareAssetRegistry

# Logical groups for runtime usage
const ASSETS := {
    "audio_spooky_loop": {
        "path": "res://ASSETS/CC0/audio/spooky_facility_loop.ogg",
        "license": "CC0"
    },
    "tileset_psx_corridor": {
        "path": "res://ASSETS/CC0/tilesets/psx_corridor.tres",
        "license": "CC0"
    },
    "music_spinal_corridor": {
        "path": "res://ASSETS/CC_BY/music/spinal_corridor.ogg",
        "license": "CC BY 4.0"
    }
}

static func get_asset(id: String) -> Resource:
    if not ASSETS.has(id):
        push_warning("LicenseAwareAssetRegistry: asset id '%s' not registered." % id)
        return null

    var info := ASSETS[id]
    var path: String = info.get("path", "")
    var license: String = info.get("license", "UNKNOWN")

    # Safety: reject assets tagged with unsupported licenses at runtime
    if license.begins_with("CC BY-NC") or license.find("SA") != -1 or license == "GPL":
        push_error("Asset '%s' has unsupported license '%s'." % [id, license])
        return null

    if not ResourceLoader.exists(path):
        push_warning("Asset '%s' path '%s' missing on disk." % [id, path])
        return null

    return load(path)

static func get_license(id: String) -> String:
    return ASSETS.get(id, {}).get("license", "UNKNOWN")
