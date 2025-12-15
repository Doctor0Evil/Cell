extends Node
class_name HorrorAssetRegistry

# Logical channels for ambience; map to CC0 or CC-BY assets from Itch / CC0 libraries.
const AMBIENT_BANK := {
    "facility_low_hum": "res://ASSETS/CC0/audio/ambience/facility_low_hum.ogg",
    "vent_draft": "res://ASSETS/CC0/audio/ambience/vent_draft.ogg",
    "meat_corridor": "res://ASSETS/CC0/audio/ambience/meat_corridor.ogg"
}

# One-shot stingers (doors, gore, radio bursts) from curated CC0 / CC-BY horror SFX packs.
const SFX_BANK := {
    "door_rattle_locked": "res://ASSETS/CC0/audio/sfx/door_rattle_locked.wav",
    "flesh_drop_heavy": "res://ASSETS/CC0/audio/sfx/flesh_drop_heavy.wav",
    "metal_creak_far": "res://ASSETS/CC0/audio/sfx/metal_creak_far.wav",
    "radio_whine_glitch": "res://ASSETS/CC0/audio/sfx/radio_whine_glitch.wav"
}

# Tilesets from CC0 horror tiles + PSX-style textures (Itch CC0 horror tag).
const TILESET_BANK := {
    "facility_corridor": "res://ASSETS/CC0/tilesets/facility_corridor.tres",
    "meat_garden": "res://ASSETS/CC0/tilesets/meat_garden.tres",
    "maintenance_tunnels": "res://ASSETS/CC0/tilesets/maintenance_tunnels.tres"
}

# Fonts from open CC0 / permissive horror / glitch font packs.
const FONT_BANK := {
    "terminal_glitch": "res://ASSETS/CC0/fonts/terminal_glitch.tres",
    "scribbled_warning": "res://ASSETS/CC0/fonts/scribbled_warning.tres"
}

# Sanity: verify a path actually exists before use.
static func get_safe_path(bank: Dictionary, key: String) -> String:
    if not bank.has(key):
        push_warning("HorrorAssetRegistry: key '%s' not found in bank." % key)
        return ""
    var path := bank[key]
    if not ResourceLoader.exists(path):
        push_warning("HorrorAssetRegistry: resource '%s' missing on disk." % path)
        return ""
    return path

static func get_ambient(name: String) -> String:
    return get_safe_path(AMBIENT_BANK, name)

static func get_sfx(name: String) -> String:
    return get_safe_path(SFX_BANK, name)

static func get_tileset(name: String) -> String:
    return get_safe_path(TILESET_BANK, name)

static func get_font(name: String) -> String:
    return get_safe_path(FONT_BANK, name)
