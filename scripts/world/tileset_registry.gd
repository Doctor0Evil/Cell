extends Resource
class_name TilesetRegistry

var tile_groups := {
    "FLESH_FLOOR": [
        "tiles/floor/flesh_floor_a",
        "tiles/floor/flesh_floor_b",
        "tiles/floor/flesh_floor_bone",
        "tiles/floor/flesh_floor_pool"
    ],
    "NANOTECH_WALL_CRACKED": [
        "tiles/wall/nanotech_wall_cracked_a",
        "tiles/wall/nanotech_wall_cracked_b",
        "tiles/wall/nanotech_wall_bio_push"
    ],
    "GROWTH_PULSATING": [
        "tiles/overlay/growth_pulse_a",
        "tiles/overlay/growth_pulse_b",
        "tiles/overlay/growth_node_core"
    ],
    "TERMINAL_CORRUPTED": [
        "tiles/prop/terminal_corrupted_a",
        "tiles/prop/terminal_corrupted_b",
        "tiles/prop/terminal_fused_biomass"
    ],
    "CORRIDOR_BLOOD": [
        "tiles/floor/corridor_blood_light",
        "tiles/floor/corridor_blood_heavy",
        "tiles/floor/corridor_blood_drag"
    ]
}

func get_random_tile(group: String) -> String:
    if not tile_groups.has(group):
        return ""
    var arr := tile_groups[group]
    if arr.is_empty():
        return ""
    return arr[randi() % arr.size()]
