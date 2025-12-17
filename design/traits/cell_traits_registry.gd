# Filename: res://design/traits/cell_traits_registry.gd
# Destination: /design/traits/

extends Resource
class_name CellTraitsRegistry

const TRAIT_DATA_PATH := "res://design/traits/data/"

@export var traits: Array[CellTraitDefinition] = []

# Indexes for fast lookup and tooling
var _by_id: Dictionary = {}           # id:StringName -> CellTraitDefinition
var _by_region_tag: Dictionary = {}   # region_tag:StringName -> Array[CellTraitDefinition]
var _by_faction: Dictionary = {}      # faction_id:StringName -> Array[CellTraitDefinition]
var _loaded: bool = false


func _init() -> void:
    # Optional eager init; editor tools can call load_defaults() explicitly.
    pass


func load_defaults() -> void:
    if _loaded:
        return

    traits.clear()
    _by_id.clear()
    _by_region_tag.clear()
    _by_faction.clear()

    # Manually constructed baseline traits for Cell’s core fantasy.
    # These align with V.I.T.A.L.I.T.Y., oxygen/water, and environment tags. [file:38]

    traits.append(_make_fast_metabolism_hot_core())
    traits.append(_make_bruiser_frame())
    traits.append(_make_pack_spine())
    traits.append(_make_cold_verge_runner())
    traits.append(_make_ashveil_scavenger())
    traits.append(_make_signal_empath())
    traits.append(_make_unknown_casefile())
    traits.append(_make_deckside_myth())
    traits.append(_make_iron_lungs_suit())
    traits.append(_make_caffeine_loop())

    # Build secondary indices
    for t in traits:
        _register_trait(t)

    _loaded = true


func _register_trait(trait: CellTraitDefinition) -> void:
    if trait == null:
        return

    _by_id[trait.id] = trait

    for tag in trait.region_tags:
        if not _by_region_tag.has(tag):
            _by_region_tag[tag] = []
        _by_region_tag[tag].append(trait)

    for faction_id in trait.respect_deltas.keys():
        if not _by_faction.has(faction_id):
            _by_faction[faction_id] = []
        _by_faction[faction_id].append(trait)


func get_trait(id: StringName) -> CellTraitDefinition:
    if not _loaded:
        load_defaults()
    if _by_id.has(id):
        return _by_id[id]
    return null


func has_trait(id: StringName) -> bool:
    if not _loaded:
        load_defaults()
    return _by_id.has(id)


func get_all_traits() -> Array[CellTraitDefinition]:
    if not _loaded:
        load_defaults()
    # Return a shallow copy so tools can sort/filter without mutating registry.
    return traits.duplicate()


func get_traits_for_region_tag(region_tag: StringName) -> Array[CellTraitDefinition]:
    if not _loaded:
        load_defaults()
    if _by_region_tag.has(region_tag):
        return _by_region_tag[region_tag]
    return []


func get_traits_touching_faction(faction_id: StringName) -> Array[CellTraitDefinition]:
    if not _loaded:
        load_defaults()
    if _by_faction.has(faction_id):
        return _by_faction[faction_id]
    return []


func reload_from_disk() -> void:
    # Optional override: load .tres/.res trait definitions dropped under TRAIT_DATA_PATH.
    traits.clear()
    _by_id.clear()
    _by_region_tag.clear()
    _by_faction.clear()
    _loaded = false

    var dir := DirAccess.open(TRAIT_DATA_PATH)
    if dir:
        dir.list_dir_begin()
        var file_name := dir.get_next()
        while file_name != "":
            if not dir.current_is_dir() and file_name.ends_with(".tres"):
                var full_path := TRAIT_DATA_PATH + file_name
                var res := load(full_path)
                if res is CellTraitDefinition:
                    traits.append(res)
            file_name = dir.get_next()
        dir.list_dir_end()

    if traits.is_empty():
        load_defaults()
        return

    for t in traits:
        _register_trait(t)
    _loaded = true


# -------------------------------------------------------------------
# Concrete Cyberfrost / space‑wastepunk trait constructors
# These mirror the design you already use for Fractures and V.I.T.A.L.I.T.Y. [file:38]
# -------------------------------------------------------------------

func _make_fast_metabolism_hot_core() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"fast_metabolism_hot_core"
    t.display_name = "Fast Metabolism: Hot Core"
    t.description = "Burns everything faster: heals quick, starves quicker. Suit chems barely catch up."

    # V.I.T.A.L.I.T.Y.
    t.vitality_delta = 1.0
    t.tenacity_delta = -0.5

    # Pools
    t.wellness_max_mult = 1.10
    t.water_decay_mult = 1.25
    t.stamina_decay_mult = 1.10
    t.protein_efficiency_mult = 1.10  # custom key you can read in VitalitySystem

    # Environment behaviour (global rule)
    t.status_rules = {
        &"GLOBAL": {
            "natural_heal_mult": 1.25,
            "chem_positive_duration_mult": 0.75,
            "chem_negative_duration_mult": 1.25
        }
    }

    t.narrative_tags = [&"METABOLIC_OUTLIER", &"MEDICAL_INTEREST"]
    t.respect_deltas = {
        &"MEDIC_ARCHIVE": 5  # med staff fascinated by your readings.
    }
    return t


func _make_bruiser_frame() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"bruiser_frame"
    t.display_name = "Bruiser Frame"
    t.description = "Bulk‑built for close‑quarters. The corridors move slower. The things in them do not."

    t.strength_delta = 2.0
    t.agility_delta = -1.0
    t.speed_delta = -0.5

    t.stamina_max_mult = 1.10
    t.oxygen_decay_mult = 1.05

    t.status_rules = {
        &"COMBAT": {
            "melee_damage_mult": 1.20,
            "ranged_stability_mult": 0.90
        }
    }

    t.narrative_tags = [&"CLOSE_QUARTERS", &"HEAVY_HULL_FRAME"]
    t.respect_deltas = {
        &"PIT_COMBAT": 8,
        &"TACTICAL_COMMAND": -4
    }
    return t


func _make_pack_spine() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"pack_spine"
    t.display_name = "Pack Spine"
    t.description = "Every deck is a cargo deck if your spine doesn’t quit."

    t.strength_delta = 1.0

    t.stamina_max_mult = 0.95
    t.status_rules = {
        &"GLOBAL": {
            "carry_capacity_bonus": 0.60,     # +60% carrying capacity
            "overload_threshold": 0.75,       # >75% load threshold
            "overload_speed_mult": 0.90,      # slower when overloaded
            "overload_oxygen_mult": 1.05      # burns more O2 when overloaded
        }
    }

    t.narrative_tags = [&"LOADER", &"SCAVENGER_HABIT"]
    t.respect_deltas = {
        &"BULK_LOGISTICS": 10,
        &"MINIMALIST_CELLS": -3
    }
    return t


func _make_cold_verge_runner() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"cold_verge_runner"
    t.display_name = "Cold Verge Runner"
    t.description = "Knows the frozen ribs of the station well enough to come back."

    t.tenacity_delta = 1.0
    t.agility_delta = 1.0

    t.region_tags = [&"COLD_VERGE", &"EXTERIOR_HULL"]

    t.status_rules = {
        &"COLD_VERGE": {
            "temp_drop_mult": 0.80,
            "stamina_decay_mult": 0.90,
            "sprint_cost_mult": 0.90
        },
        &"EXTERIOR_HULL": {
            "fall_risk_mult": 0.90,
            "oxygen_decay_mult": 0.95
        }
    }

    t.narrative_tags = [&"VERGE_VETERAN"]
    t.respect_deltas = {
        &"HULL_TECHS": 10,
        &"ASHVEIL_SCAVENGERS": 4
    }
    return t


func _make_ashveil_scavenger() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"ashveil_scavenger"
    t.display_name = "Ashveil Scavenger"
    t.description = "Reads the dust‑storms and solvent rain in Ashveil like signage."

    t.instinct_delta = 1.0
    t.yield_delta = 1.0

    t.region_tags = [&"ASHVEIL_DRIFT"]

    t.status_rules = {
        &"ASHVEIL_DRIFT": {
            "loot_quantity_mult": 1.20,
            "rare_scrap_chance_mult": 1.15,
            "encounter_chance_mult": 1.10,
            "suit_corrosion_mult": 1.15
        }
    }

    t.narrative_tags = [&"SCRAP_ROUTE", &"NOISE_INTOLERANT_ZONE"]
    t.respect_deltas = {
        &"SCAVENGER_RINGS": 10,
        &"FORMAL_SECURITY": -5
    }
    return t


func _make_signal_empath() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"signal_empath"
    t.display_name = "Signal Empath"
    t.description = "People and signals bleed straight into your head."

    t.instinct_delta = 1.0
    t.temper_delta = -1.0

    t.status_rules = {
        &"DIALOG": {
            "speech_empathy_mult": 1.20,
            "lie_detection_bonus": 0.15
        },
        &"HORROR_SIGNAL": {
            "sanity_loss_mult": 1.25
        }
    }

    t.narrative_tags = [&"EMPATHIC_HAZARD"]
    t.respect_deltas = {
        &"WHISPER_ARCHIVE": 5
    }
    return t


func _make_unknown_casefile() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"unknown_casefile"
    t.display_name = "Unknown Casefile"
    t.description = "Your file is mostly redactions and missing decks."

    t.status_rules = {
        &"GLOBAL": {
            "starting_rep_shift": 0.0
        }
    }

    t.narrative_tags = [&"MYSTERY_SUBJECT"]
    t.respect_deltas = {
        &"INFO_BROKERS": 5,
        &"RISK_AVERSE_FACTIONS": -3
    }
    return t


func _make_deckside_myth() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"deckside_myth"
    t.display_name = "Deckside Myth"
    t.description = "Stories about you move faster than the air recyclers."

    t.influence_delta = 1.0

    t.status_rules = {
        &"GLOBAL": {
            "rep_polarization_mult": 1.50
        }
    }

    t.narrative_tags = [&"RUMOR_MAGNET"]
    t.respect_deltas = {
        &"OUTPOST_FRONTLINE": 8,
        &"BLACK_SECTION": 5
    }
    return t


func _make_iron_lungs_suit() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"iron_lungs_suit"
    t.display_name = "Iron Lungs"
    t.description = "Breath comes slower, even when the station doesn’t."

    t.tenacity_delta = 1.0

    t.oxygen_max_mult = 1.10
    t.oxygen_decay_mult = 0.80

    t.region_tags = [&"LOW_OXYGEN", &"TOXIC_ATMOS", &"FIRE_SUPPRESSED"]

    t.status_rules = {
        &"LOW_OXYGEN": {
            "oxygen_decay_mult": 0.75
        },
        &"TOXIC_ATMOS": {
            "oxygen_decay_mult": 0.80,
            "poison_inhale_mult": 0.75
        },
        &"FIRE_SUPPRESSED": {
            "oxygen_decay_mult": 0.70
        }
    }

    t.narrative_tags = [&"OXYGEN_SPECIALIST"]
    t.respect_deltas = {
        &"HULL_TECHS": 10,
        &"FIRESUPPRESSION_TEAMS": 6
    }
    return t


func _make_caffeine_loop() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"caffeine_loop"
    t.display_name = "Caffeine Loop"
    t.description = "The station only feels upright when the stimulants hit."

    t.logic_delta = 0.5
    t.agility_delta = 0.5

    t.status_rules = {
        &"NO_STIM_6H": {
            "logic_penalty": -1.0,
            "instinct_penalty": -1.0,
            "action_speed_mult": 0.90
        },
        &"ON_STIM": {
            "agility_bonus": 1.0,
            "action_speed_mult": 1.10,
            "duration_hours": 4.0
        }
    }

    t.narrative_tags = [&"STIM_HABIT"]
    t.respect_deltas = {
        &"SHIFT_RATS": 4
    }
    return t
