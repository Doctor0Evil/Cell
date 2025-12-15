extends Resource
class_name CellContentRegistry

# This Resource can be saved as `res://config/cell_content_registry.tres`
# and loaded by autoloads or scene managers.

# Survival configuration
var survival_config := {
    "body_temp": {
        "base_drop_rate": 0.08,        # degrees per second in exposed zones
        "safe_temp": 37.0,
        "critical_temp": 28.0,
        "heat_core_bonus": 5.0,        # degrees restored on use
        "heat_core_duration": 45.0     # seconds of slowed temp loss
    },
    "oxygen": {
        "max_capsules": 3,
        "seconds_per_capsule": 120.0,
        "low_oxygen_threshold": 30.0,  # seconds remaining when warnings start
        "mutation_risk_per_capsule": 0.02
    },
    "ration_chips": {
        "tier_costs": {
            "I": 1,
            "II": 3,
            "III": 5
        }
    }
}

# Region descriptors for the Forgotten Moon
var regions := {
    "ASHVEIL_DEBRIS_STRATUM": {
        "display_name": "Ashveil Debris Stratum",
        "difficulty": 1,
        "temperature_modifier": -0.5,
        "oxygen_modifier": -0.1,
        "primary_threats": ["SPINE_CRAWLER", "BREATHER"],
        "key_loot": ["OXYGEN_CAPSULE", "HEAT_CORE_FRAGMENT", "RATION_CHIP_TIER_I"],
        "scene_path": "res://scenes/world/ashveil_debris_stratum.tscn"
    },
    "IRON_HOLLOW_SPINAL_TRENCH": {
        "display_name": "Iron Hollow Spinal Trench",
        "difficulty": 2,
        "temperature_modifier": -0.2,
        "oxygen_modifier": -0.15,
        "primary_threats": ["SPINE_CRAWLER", "HOLLOW_MAN", "ASH_EATER"],
        "key_loot": ["RATION_CHIP_TIER_II", "WEAPON_SCHEMATIC", "HEAT_CORE_MODULE"],
        "scene_path": "res://scenes/world/iron_hollow_spinal_trench.tscn"
    },
    "COLD_VERGE_CRYO_RIM": {
        "display_name": "Cold Verge Cryo-Rim",
        "difficulty": 3,
        "temperature_modifier": -1.0,
        "oxygen_modifier": -0.3,
        "primary_threats": ["BREATHER", "ASH_EATER", "PULSE_TERROR"],
        "key_loot": ["OXYGEN_CAPSULE", "SUIT_UPGRADE_COLD", "RATION_CHIP_TIER_III"],
        "scene_path": "res://scenes/world/cold_verge_cryo_rim.tscn"
    },
    "RED_SILENCE_SIGNAL_CRADLE": {
        "display_name": "Red Silence Signal Cradle",
        "difficulty": 4,
        "temperature_modifier": -0.3,
        "oxygen_modifier": -0.2,
        "primary_threats": ["HOLLOW_MAN", "PULSE_TERROR"],
        "key_loot": ["BCI_MODULE", "AI_OVERRIDE_TOOL", "ADVANCED_MUTATION_SAMPLE"],
        "scene_path": "res://scenes/world/red_silence_signal_cradle.tscn"
    }
}

# Enemy archetype descriptors
var enemies := {
    "SPINE_CRAWLER": {
        "display_name": "Spine-Crawler",
        "role": "Flanking melee",
        "base_health": 80,
        "move_speed": 4.5,
        "attack_damage": 18,
        "perception": {
            "view_distance": 14.0,
            "view_angle_deg": 95.0,
            "hearing_radius": 8.0
        },
        "special": {
            "wall_crawl": true,
            "surprise_bonus_damage": 10
        },
        "scene_path": "res://scenes/enemy/spine_crawler.tscn"
    },
    "BREATHER": {
        "display_name": "Breather",
        "role": "Area denial",
        "base_health": 120,
        "move_speed": 1.5,
        "attack_damage": 6,
        "perception": {
            "view_distance": 10.0,
            "view_angle_deg": 60.0,
            "hearing_radius": 12.0
        },
        "special": {
            "gas_radius": 6.0,
            "gas_duration": 15.0,
            "death_gas_burst": true
        },
        "scene_path": "res://scenes/enemy/breather.tscn"
    },
    "HOLLOW_MAN": {
        "display_name": "Hollow-Man",
        "role": "Patrol threat",
        "base_health": 140,
        "move_speed": 2.2,
        "attack_damage": 22,
        "perception": {
            "view_distance": 20.0,
            "view_angle_deg": 50.0,
            "hearing_radius": 6.0
        },
        "special": {
            "tethered_to_area": true,
            "rage_threshold_distance": 10.0
        },
        "scene_path": "res://scenes/enemy/hollow_man.tscn"
    },
    "ASH_EATER": {
        "display_name": "Ash-Eater",
        "role": "Battlefield recycler",
        "base_health": 60,
        "move_speed": 2.8,
        "attack_damage": 14,
        "perception": {
            "view_distance": 12.0,
            "view_angle_deg": 80.0,
            "hearing_radius": 5.0
        },
        "special": {
            "corpse_armor_gain": 15, # bonus health per consumed corpse
            "max_corpse_stacks": 4
        },
        "scene_path": "res://scenes/enemy/ash_eater.tscn"
    },
    "PULSE_TERROR": {
        "display_name": "Pulse-Terror",
        "role": "Mini-boss hazard",
        "base_health": 350,
        "move_speed": 1.2,
        "attack_damage": 35,
        "perception": {
            "view_distance": 18.0,
            "view_angle_deg": 110.0,
            "hearing_radius": 10.0
        },
        "special": {
            "hallucination_radius": 10.0,
            "hud_distortion_intensity": 0.7,
            "heart_weak_spot_multiplier": 2.5
        },
        "scene_path": "res://scenes/enemy/pulse_terror.tscn"
    }
}

func get_region(id: String) -> Dictionary:
    if regions.has(id):
        return regions[id]
    return {}

func get_enemy(id: String) -> Dictionary:
    if enemies.has(id):
        return enemies[id]
    return {}

func get_survival_config() -> Dictionary:
    return survival_config
