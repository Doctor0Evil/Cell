extends Node
class_name CreditsRegistry

const CC_BY_ASSETS := [
    {
        "type": "music",
        "title": "Spinal Corridor",
        "author": "Jane Doe",
        "license": "CC BY 4.0",
        "source_url": "https://example.com/spinal-corridor"
    },
    {
        "type": "sfx",
        "title": "Rust Door Hit",
        "author": "John Smith",
        "license": "CC BY 3.0",
        "source_url": "https://example.com/rust-door-hit"
    }
]

static func get_assets_by_type(asset_type: String) -> Array:
    var out: Array = []
    for entry in CC_BY_ASSETS:
        if entry.get("type", "") == asset_type:
            out.append(entry)
    return out
