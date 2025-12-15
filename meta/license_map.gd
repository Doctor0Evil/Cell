extends Node
class_name LicenseMap

const ENTRIES := [
    {
        "id": "tileset_psx_corridor",
        "path": "res://ASSETS/CC0/tilesets/psx_corridor.tres",
        "license": "CC0",
        "source": "https://itch.io/game-assets/assets-cc0/tag-horror"
    },
    {
        "id": "music_spinal_corridor",
        "path": "res://ASSETS/CC_BY/music/spinal_corridor.ogg",
        "license": "CC BY 4.0",
        "source": "https://example.com/spinal-corridor"
    }
]

static func get_entry(id: String) -> Dictionary:
    for e in ENTRIES:
        if e.get("id", "") == id:
            return e
    return {}

static func safe_load(id: String) -> Resource:
    var e := get_entry(id)
    if e.is_empty():
        push_warning("LicenseMap: unknown asset id '%s'." % id)
        return null

    var lic := e.get("license", "UNKNOWN")
    if lic.find("NC") != -1 or lic.find("ND") != -1 or lic.find("SA") != -1 or lic == "GPL":
        push_error("LicenseMap: asset '%s' has unsupported license '%s'." % [id, lic])
        return null

    var path := e.get("path", "")
    if not ResourceLoader.exists(path):
        push_warning("LicenseMap: missing resource '%s'." % path)
        return null

    return load(path)
