# Filename: res://design/traits/cell_traits_registry.gd
# Destination: /design/traits/

extends Resource
class_name CellTraitsRegistry

const TRAIT_DATA_PATH := "res://design/traits/data/"

# Common faction IDs (reference values for trait authors / tooling)
const FACTIONS := {
    "HULL_TECHS": "HULL_TECHS",
    "SCAVENGER_RINGS": "SCAVENGER_RINGS",
    "PIT_COMBAT": "PIT_COMBAT",
    "TACTICAL_COMMAND": "TACTICAL_COMMAND",
    "MEDIC_ARCHIVE": "MEDIC_ARCHIVE",
    "FORMAL_SECURITY": "FORMAL_SECURITY",
    "BULK_LOGISTICS": "BULK_LOGISTICS",
    "SHIFT_RATS": "SHIFT_RATS",
    "SUPERSTITION_CELLS": "SUPERSTITION_CELLS"
}

# Common region tags
const REGION_TAGS := [
    "COLD_VERGE", "ASHVEIL_DRIFT", "EXTERIOR_HULL", "MAINT_TUNNEL",
    "LOW_OXYGEN", "TOXIC_ATMOS", "FIRE_SUPPRESSED", "INTERIOR_TIGHT"
]

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

    # Expanded Cyberfrost / space‑wastepunk library (bulk of common + rare traits)
    traits.append(_make_heavy_frame())
    traits.append(_make_ambidextrous_grip())
    traits.append(_make_hull_bruiser())
    traits.append(_make_trigger_drift())
    traits.append(_make_containment_cautious())
    traits.append(_make_red_silence_optics())
    traits.append(_make_tunnel_focus())
    traits.append(_make_containment_face())
    traits.append(_make_hard_edge())
    traits.append(_make_compartmentalized())
    traits.append(_make_orbital_luck())
    traits.append(_make_jinxed_orbit())
    traits.append(_make_night_shift_mind())
    traits.append(_make_day_cycle_anchor())
    traits.append(_make_hull_claustrophobia())
    traits.append(_make_void_vertigo())
    traits.append(_make_keen_hearing())
    traits.append(_make_tinnitus_drift())
    traits.append(_make_light_sleeper())
    traits.append(_make_heavy_sleeper())
    traits.append(_make_thin_suit_skin())
    traits.append(_make_composite_skin())
    traits.append(_make_chemical_drift())
    traits.append(_make_weak_filter())
    traits.append(_make_ascetic_intake())
    traits.append(_make_techie())
    traits.append(_make_technophobe())
    traits.append(_make_book_depth())
    traits.append(_make_hands_on_learner())
    traits.append(_make_natural_leader())
    traits.append(_make_berserker_state())
    traits.append(_make_defender_posture())
    traits.append(_make_sniper_corridor())
    traits.append(_make_spray_and_pray())
    traits.append(_make_conservationist())
    traits.append(_make_chem_resistant())
    traits.append(_make_chem_reliant())
    traits.append(_make_clean_liver())
    traits.append(_make_addictive_pattern())
    traits.append(_make_magnetic_drift())
    traits.append(_make_static_sheath())
    traits.append(_make_rad_glow())

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

    # Environment behaviour (global rule)
    t.status_rules = {
        &"GLOBAL": {
            "natural_heal_mult": 1.25,
            "chem_positive_duration_mult": 0.75,
            "chem_negative_duration_mult": 1.25,
            "protein_efficiency_mult": 1.10
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

# -------------------------------------------------------------------
# Utility methods
# -------------------------------------------------------------------

func get_traits_with_tag(tag: StringName) -> Array[CellTraitDefinition]:
    if not _loaded:
        load_defaults()
    var out := []
    for t in traits:
        if t.narrative_tags.has(tag) or t.region_tags.has(tag):
            out.append(t)
    return out

func find_traits_by_predicate(predicate: Callable) -> Array[CellTraitDefinition]:
    # predicate should accept (CellTraitDefinition) -> bool
    if not _loaded:
        load_defaults()
    var out := []
    for t in traits:
        if predicate.call(t):
            out.append(t)
    return out

func sample_traits(count: int = 5, seed: int = 0) -> Array[CellTraitDefinition]:
    # Return a small, pseudo-random sample for UI/preview screens. Deterministic if seed != 0.
    if not _loaded:
        load_defaults()
    var pool := traits.duplicate()
    var rng := RandomNumberGenerator.new()
    if seed != 0:
        rng.seed = int(seed)
    else:
        rng.randomize()
    var out := []
    while pool.size() > 0 and out.size() < count:
        var idx := rng.randi_range(0, pool.size() - 1)
        out.append(pool[idx])
        pool.remove_at(idx)
    return out

func export_registry_to_json(path: String) -> bool:
    # Exports a compact JSON description of current traits for tooling/CI.
    if not _loaded:
        load_defaults()
    var dump := []
    for t in traits:
        dump.append({
            "id": String(t.id),
            "display_name": t.display_name,
            "description": t.description,
            "narrative_tags": t.narrative_tags.duplicate(),
            "region_tags": t.region_tags.duplicate(),
            "respect_deltas": t.respect_deltas.duplicate(),
            "status_rules": t.status_rules.duplicate()
        })
    var json := JSON.new()
    var err, text = json.stringify(dump)
    if err != OK:
        push_error("CellTraitsRegistry: JSON serialization failed: %s" % str(err))
        return false
    var file := FileAccess.open(path, FileAccess.WRITE)
    if not file:
        push_error("CellTraitsRegistry: unable to open %s for write." % path)
        return false
    file.store_string(text)
    file.close()
    return true

func debug_snapshot() -> String:
    if not _loaded:
        load_defaults()
    var lines := []
    lines.append("[Cell::TraitRegistrySnapshot]")
    lines.append("total_traits: %d" % traits.size())
    var by_cat := {}
    for t in traits:
        var cat := "UNSPEC"
        var maybe_cat := t.get("category", null)
        if maybe_cat != null and String(maybe_cat) != "":
            cat = String(maybe_cat)
        if not by_cat.has(cat):
            by_cat[cat] = 0
        by_cat[cat] += 1
    lines.append("by_category: %s" % str(by_cat))
    lines.append("sample:")
    for s in sample_traits(6):
        var line := "  - id=%s display='%s' tags=%s" % [s.id, s.display_name, str(s.narrative_tags)]
        lines.append(line)
    lines.append("[/Cell::TraitRegistrySnapshot]")
    return "\n".join(lines)

# -------------------------------------------------------------------
# Expanded trait constructors (continued)
# -------------------------------------------------------------------

func _make_heavy_frame() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"heavy_frame"
    t.display_name = "Heavy Frame"
    t.description = "Built like a ballast. Carry more; dodge less."

    t.strength_delta = 2.0
    t.agility_delta = -1.0
    t.speed_delta = -0.5

    t.stamina_max_mult = 1.10
    t.oxygen_decay_mult = 1.05

    t.status_rules = {
        &"GLOBAL": { "carry_capacity_bonus": 0.40 }
    }
    t.narrative_tags = [&"HEAVY_WORKER", &"BULK"]
    t.respect_deltas = { &"BULK_LOGISTICS": 6 }
    return t

func _make_ambidextrous_grip() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"ambidextrous_grip"
    t.display_name = "Ambidextrous Grip"
    t.description = "Two hands, one mind. Reloads and off-hand usage feel natural."

    t.dexterity_delta = 2.0
    t.status_rules = { &"GLOBAL": { "offhand_penalty_mult": 0.5, "dual_wield_recoil_mult": 0.9 } }
    t.narrative_tags = [&"GUN_HANDLING"]
    t.respect_deltas = { &"SECURITY_ARMS": 5 }
    return t

func _make_hull_bruiser() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"hull_bruiser"
    t.display_name = "Hull Bruiser"
    t.description = "You punch holes in hulls and expectations."

    t.strength_delta = 3.0
    t.agility_delta = -2.0
    t.status_rules = { &"COMBAT": { "melee_damage_mult": 1.20, "knockdown_resist": 0.15 } }
    t.respect_deltas = { &"PIT_COMBAT": 10 }
    return t

func _make_trigger_drift() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"trigger_drift"
    t.display_name = "Trigger Drift"
    t.description = "Comfort with brittle triggers; small gains, small risks."

    t.instinct_delta = 1.0
    t.temper_delta = -1.0
    t.status_rules = { &"GLOBAL": { "ranged_hit_bonus": 0.05, "oxygen_burst_cost_mult": 1.05, "misfire_chance": 0.03 } }
    t.respect_deltas = { &"CHAOTIC_MILITIAS": 5 }
    return t

func _make_containment_cautious() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"containment_cautious"
    t.display_name = "Containment Cautious"
    t.description = "Checks the corner twice. Pays attention to seals."

    t.instinct_delta = 1.0
    t.agility_delta = -1.0
    t.status_rules = { &"GLOBAL": { "stealth_vs_sensors_bonus": 0.10, "sprint_start_delay": 0.2 } }
    t.respect_deltas = { &"TACTICAL_COMMAND": 5 }
    return t

func _make_red_silence_optics() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"red_silence_optics"
    t.display_name = "Red Silence Optics"
    t.description = "A narrow, clinical focus at range; a blindness at your toes."

    t.logic_delta = 1.0
    t.instinct_delta = 1.0
    t.status_rules = { &"GLOBAL": { "long_range_accuracy_mult": 1.15, "close_range_instab_mult": 0.90 } }
    t.respect_deltas = { &"LONG_SPINE_MARKSMEN": 6 }
    return t

func _make_tunnel_focus() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"tunnel_focus"
    t.display_name = "Tunnel Focus"
    t.description = "You own the corridor. Frontal math is your friend."

    t.instinct_delta = 1.0
    t.status_rules = { &"MAINT_TUNNEL": { "frontal_cone_hit_bonus": 0.10, "flank_penalty": -0.15 } }
    t.respect_deltas = { &"SECTION_COMMAND": 5 }
    return t

func _make_containment_face() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"containment_face"
    t.display_name = "Containment Face"
    t.description = "Looks like someone who ran a console and lost patience gracefully."

    t.influence_delta = 2.0
    t.status_rules = { &"CONTAINMENT_ZONE": { "negotiation_bonus": 0.15, "barter_bonus": 0.10 } }
    t.respect_deltas = { &"ADMIN_CORE": 5 }
    return t

func _make_hard_edge() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"hard_edge"
    t.display_name = "Hard Edge"
    t.description = "You know how to hurt people and look like you meant it."

    t.temper_delta = 1.0
    t.influence_delta = -1.0
    t.status_rules = { &"GLOBAL": { "intimidation_bonus": 0.10 } }
    t.respect_deltas = { &"BLACK_SECTION_OPERATIVES": 7 }
    return t

func _make_compartmentalized() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"compartmentalized"
    t.display_name = "Compartmentalized"
    t.description = "The horrible things stay boxed; your head stays clearer."

    t.temper_delta = 2.0
    t.influence_delta = -1.0
    t.status_rules = { &"GLOBAL": { "stress_from_atrocities_mult": 0.5 } }
    t.respect_deltas = { &"MEDIC_ARCHIVE": 4 }
    return t

func _make_orbital_luck() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"orbital_luck"
    t.display_name = "Orbital Luck"
    t.description = "Tiny improbable events read in your favor more often."

    t.luck_delta = 2.0
    t.status_rules = { &"GLOBAL": { "rare_event_save_chance_mult": 1.5 } }
    t.respect_deltas = { &"SUPERSTITION_CELLS": 5 }
    return t

func _make_jinxed_orbit() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"jinxed_orbit"
    t.display_name = "Jinxed Orbit"
    t.description = "Everything is a little more likely to fail around you."

    t.luck_delta = -2.0
    t.status_rules = { &"GLOBAL": { "mishap_chance_mult": 1.5 } }
    t.respect_deltas = { &"SUPERSTITION_CELLS": -5 }
    return t

func _make_night_shift_mind() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"night_shift_mind"
    t.display_name = "Night Shift Mind"
    t.description = "The quiet keeps you sharp when lights go down."

    t.logic_delta = 1.0
    t.instinct_delta = 1.0
    t.status_rules = { &"NIGHT_MODE": { "low_light_stealth_bonus": 0.10 } }
    t.respect_deltas = { &"NOCTURNAL_CREWS": 6 }
    return t

func _make_day_cycle_anchor() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"day_cycle_anchor"
    t.display_name = "Day Cycle Anchor"
    t.description = "Your rhythm matches the maintenance clock; you do better in daylight."

    t.logic_delta = 1.0
    t.tenacity_delta = 1.0
    t.status_rules = { &"DAY_MODE": { "repair_speed_bonus": 0.10 } }
    return t

func _make_hull_claustrophobia() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"hull_claustrophobia"
    t.display_name = "Hull Claustrophobia"
    t.description = "Tight spaces fray your composure."

    t.status_rules = { &"INTERIOR_TIGHT": { "stamina_max_mult": 0.90, "stealth_penalty": -0.10, "sanity_loss_mult": 1.25 } }
    t.respect_deltas = { &"BUNKER_FACTIONS": -5 }
    return t

func _make_void_vertigo() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"void_vertigo"
    t.display_name = "Void Vertigo"
    t.description = "Heights are not an abstract problem."

    t.status_rules = { &"EXPOSED_HULL": { "agility_check_penalty": -0.20, "ranged_accuracy_penalty": -0.15 } }
    t.respect_deltas = { &"EVA_CREWS": -5 }
    return t

func _make_keen_hearing() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"keen_hearing"
    t.display_name = "Keen Hearing"
    t.description = "A quiet step is busy work for you."

    t.instinct_delta = 2.0
    t.status_rules = { &"GLOBAL": { "detection_radius_noise_mult": 1.25 } }
    return t

func _make_tinnitus_drift() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"tinnitus_drift"
    t.display_name = "Tinnitus Drift"
    t.description = "Ringing comes and goes. It’s always there."

    t.instinct_delta = -1.0
    t.logic_delta = -1.0
    t.status_rules = { &"GLOBAL": { "audio_perception_mult": 0.80, "random_ring_events": 0.05 } }
    return t

func _make_light_sleeper() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"light_sleeper"
    t.display_name = "Light Sleeper"
    t.description = "You wake at a whisper. Rest is watchful, not restful."

    t.status_rules = { &"REST": { "rest_recovery_mult": 0.90, "sleep_ambush_immunity": true } }
    return t

func _make_heavy_sleeper() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"heavy_sleeper"
    t.display_name = "Heavy Sleeper"
    t.description = "Deep, dangerous slumber. You get more rest, but risks increase."

    t.status_rules = { &"REST": { "rest_recovery_mult": 1.30, "sleep_ambush_vuln_mult": 1.30, "wake_delay": 1.0 } }
    return t

func _make_thin_suit_skin() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"thin_suit_skin"
    t.display_name = "Thin Suit Skin"
    t.description = "Less armor, more feeling."

    t.blood_max_mult = 0.90
    t.status_rules = { &"GLOBAL": { "suit_integrity_vuln": 1.20 } }
    return t

func _make_composite_skin() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"composite_skin"
    t.display_name = "Composite Skin"
    t.description = "Protected, heavy, reliable."

    t.status_rules = { &"GLOBAL": { "minor_dot_immunity": true, "movement_penalty_mult": 0.95 } }
    return t

func _make_chemical_drift() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"chemical_drift"
    t.display_name = "Chemical Drift"
    t.description = "Chemicals are easier to tolerate, but the hangover is real."

    t.status_rules = { &"GLOBAL": { "toxin_resist_mult": 0.75, "withdrawal_duration_mult": 0.75 } }
    t.respect_deltas = { &"BIOHAZARD_TEAMS": 5 }
    return t

func _make_weak_filter() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"weak_filter"
    t.display_name = "Weak Filter"
    t.description = "Contaminants take root more easily."

    t.status_rules = { &"GLOBAL": { "contaminant_chance_mult": 2.0, "illness_duration_mult": 1.3 } }
    return t

func _make_ascetic_intake() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"ascetic_intake"
    t.display_name = "Ascetic Intake"
    t.description = "Less need for rations; also less comfort."

    t.status_rules = { &"GLOBAL": { "hunger_decay_mult": 0.5, "thirst_decay_mult": 0.5, "starvation_delay_hours": 24 } }
    t.respect_deltas = { &"MONASTIC_HABITATS": 4 }
    return t

func _make_techie() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"techie"
    t.display_name = "Techie"
    t.description = "Knows wires and what they mean."

    t.logic_delta = 1.0
    t.yield_delta = 1.0
    t.status_rules = { &"GLOBAL": { "repair_success_mult": 1.20, "hack_success_mult": 1.15 } }
    t.respect_deltas = { &"HULL_TECHS": 6 }
    return t

func _make_technophobe() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"technophobe"
    t.display_name = "Technophobe"
    t.description = "Too many blinking things make you suspicious."

    t.logic_delta = -1.0
    t.status_rules = { &"GLOBAL": { "hack_penalty_mult": 0.80, "mechanical_detection_bonus": 0.10 } }
    return t

func _make_book_depth() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"book_depth"
    t.display_name = "Book‑Depth"
    t.description = "Learning from stacks, not from fighting."

    t.status_rules = { &"GLOBAL": { "book_xp_bonus_mult": 1.50, "read_time_mult": 1.5 } }
    return t

func _make_hands_on_learner() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"hands_on_learner"
    t.display_name = "Hands‑On Learner"
    t.description = "Learning by doing—fast and messy."

    t.status_rules = { &"GLOBAL": { "action_xp_bonus_mult": 1.25, "book_xp_penalty_mult": 0.75 } }
    return t

func _make_natural_leader() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"natural_leader"
    t.display_name = "Natural Leader"
    t.description = "People do better around you."

    t.influence_delta = 2.0
    t.status_rules = { &"GLOBAL": { "companion_effectiveness_mult": 1.10 } }
    t.respect_deltas = { &"SECTION_COMMAND": 10 }
    return t

func _make_berserker_state() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"berserker_state"
    t.display_name = "Berserker State"
    t.description = "When blood runs low you turn into lethal, reckless steel."

    t.status_rules = { &"LOW_BLOOD": { "damage_bonus": 0.25, "damage_resist_penalty": -0.15 } }
    return t

func _make_defender_posture() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"defender_posture"
    t.display_name = "Defender Posture"
    t.description = "You are better when you hold a point and stay there."

    t.status_rules = { &"GLOBAL": { "adjacent_ally_dr_bonus": 0.10, "cover_armor_bonus": 3 } }
    return t

func _make_sniper_corridor() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"sniper_corridor"
    t.display_name = "Sniper Corridor"
    t.description = "Lone shots in long, empty corridors mean everything."

    t.status_rules = { &"GLOBAL": { "scoped_accuracy_mult": 1.20, "hipfire_penalty_mult": 0.90 } }
    return t

func _make_spray_and_pray() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"spray_and_pray"
    t.display_name = "Spray and Pray"
    t.description = "Full auto lovin’. Ammo goes fast, hatred goes faster."

    t.status_rules = { &"GLOBAL": { "full_auto_hit_mult": 1.10, "ammo_consumption_mult": 1.50, "ally_stray_chance": 0.10 } }
    return t

func _make_conservationist() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"conservationist"
    t.display_name = "Conservationist"
    t.description = "Every shot matters. It’s a way of life."

    t.status_rules = { &"GLOBAL": { "ammo_save_chance": 0.25 } }
    return t

func _make_chem_resistant() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"chem_resistant"
    t.display_name = "Chem Resistant"
    t.description = "Chems pack less of a punch, and addiction is a shy thing."

    t.status_rules = { &"GLOBAL": { "chem_potency_mult": 0.5, "addiction_chance_mult": 0.1, "withdrawal_severity_mult": 0.5 } }
    return t

func _make_chem_reliant() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"chem_reliant"
    t.display_name = "Chem Reliant"
    t.description = "The world keeps running if you keep dosing."

    t.status_rules = { &"GLOBAL": { "chem_potency_mult": 1.5, "addiction_chance_mult": 2.0 } }
    t.respect_deltas = { &"SYNDICATE_DOPERS": 5 }
    return t

func _make_clean_liver() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"clean_liver"
    t.display_name = "Clean Liver"
    t.description = "You process poisons and chems better."

    t.status_rules = { &"GLOBAL": { "chem_negative_duration_mult": 0.5 } }
    return t

func _make_addictive_pattern() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"addictive_pattern"
    t.display_name = "Addictive Pattern"
    t.description = "There’s a muscle memory to wanting more."

    t.status_rules = { &"GLOBAL": { "addiction_chance_mult": 2.0 } }
    t.respect_deltas = { &"SYNDICATE_DOPERS": 6 }
    return t

func _make_magnetic_drift() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"magnetic_drift"
    t.display_name = "Magnetic Drift"
    t.description = "Metal bits don’t stay where you left them."

    t.status_rules = { &"GLOBAL": { "metal_pull_chance": 0.20, "metal_detector_noise_mult": 1.1 } }
    return t

func _make_static_sheath() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"static_sheath"
    t.display_name = "Static Sheath"
    t.description = "Charge builds; occasionally the station answers back."

    t.status_rules = { &"GLOBAL": { "emp_pulse_chance": 0.10, "self_stun_risk": 0.05 } }
    return t

func _make_rad_glow() -> CellTraitDefinition:
    var t := CellTraitDefinition.new()
    t.id = &"rad_glow"
    t.display_name = "Rad Glow"
    t.description = "You throw off a faint light and a faint, slow rot."

    t.status_rules = { &"GLOBAL": { "emit_light_radius": 3, "radiation_trickle_mult": 0.02 } }
    t.respect_deltas = { &"SUPERSTITION_CELLS": 4 }
    return t

# -------------------------------------------------------------------
# End of expanded registry
# -------------------------------------------------------------------
