extends Node
class_name HorrorAmbienceRegistry

# Logical ambience IDs → asset IDs in LicenseAwareAssetRegistry.
const AMBIENCE_BANK := {
    # Low-tension loops
    "facility_low_hum": {
        "asset_id": "audio_spooky_loop",
        "base_tempo": 0.8,
        "intensity_range": Vector2(0.1, 0.4)
    },
    "vent_draft": {
        "asset_id": "audio_spooky_loop",
        "base_tempo": 0.9,
        "intensity_range": Vector2(0.2, 0.5)
    },

    # Mid-tension, exploration
    "meat_corridor": {
        "asset_id": "music_spinal_corridor",
        "base_tempo": 1.0,
        "intensity_range": Vector2(0.4, 0.7)
    },
    "reactor_spine": {
        "asset_id": "music_spinal_corridor",
        "base_tempo": 1.05,
        "intensity_range": Vector2(0.3, 0.8)
    },

    # High-tension / chase
    "pursuit_static": {
        "asset_id": "audio_spooky_loop",
        "base_tempo": 1.25,
        "intensity_range": Vector2(0.7, 1.0)
    },
    "signal_flood": {
        "asset_id": "audio_spooky_loop",
        "base_tempo": 1.35,
        "intensity_range": Vector2(0.8, 1.0)
    }
}

static func get_definition(id: String) -> Dictionary:
    if AMBIENCE_BANK.has(id):
        return AMBIENCE_BANK[id]
    DebugLog.log("HorrorAmbienceRegistry", "MISSING_AMBIENCE_ID", {"id": id})
    return {}

static func get_stream_for(id: String) -> AudioStream:
    var def := get_definition(id)
    if def.is_empty():
        return null

    var asset_id := String(def.get("asset_id", ""))
    if asset_id == "":
        return null

    var res := LicenseAwareAssetRegistry.get_asset(asset_id)
    if res is AudioStream:
        return res
    return null
