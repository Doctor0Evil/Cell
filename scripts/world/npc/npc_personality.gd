extends Resource
class_name NpcPersonality

@export var seed: int = 0

# Core behavioral axes, compact floats [-1, 1].
@export var aggression: float = 0.0
@export var discipline: float = 0.0
@export var caution: float = 0.0
@export var empathy: float = 0.0
@export var curiosity: float = 0.0
@export var greed: float = 0.0

# Hooks into existing trait/skill systems to avoid duplicating data.
@export var trait_ids: Array[StringName] = []
@export var skill_profile_id: StringName = &""

# Region/biome tags this NPC belongs to, for cheap filtering.
@export var home_region_id: StringName = &""
@export var biome_tags: Array[StringName] = []

func randomize_for_region(region_id: StringName, biome_tags_in: Array[StringName], base_seed: int) -> void:
    home_region_id = region_id
    biome_tags = biome_tags_in.duplicate()
    seed = hash(str(region_id, ":", base_seed, ":", randi()))
    var rng := RandomNumberGenerator.new()
    rng.seed = seed

    # Region-biased ranges – cheap, no external data needed.
    match region_id:
        &"ASHVEIL_DRIFT":
            aggression = lerp(-0.1, 0.6, rng.randf())
            discipline = lerp(-0.4, 0.3, rng.randf())
            caution = lerp(-0.2, 0.7, rng.randf())
            empathy = lerp(-0.5, 0.4, rng.randf())
            greed = lerp(0.0, 0.8, rng.randf())
        &"COLD_VERGE_BELT":
            aggression = lerp(-0.3, 0.4, rng.randf())
            discipline = lerp(0.0, 0.9, rng.randf())
            caution = lerp(0.2, 1.0, rng.randf())
            empathy = lerp(-0.2, 0.6, rng.randf())
            greed = lerp(-0.2, 0.5, rng.randf())
        _:
            aggression = lerp(-0.3, 0.5, rng.randf())
            discipline = lerp(-0.3, 0.7, rng.randf())
            caution = lerp(-0.3, 0.7, rng.randf())
            empathy = lerp(-0.3, 0.7, rng.randf())
            greed = lerp(-0.3, 0.7, rng.randf())

    curiosity = lerp(-0.2, 0.8, rng.randf())

    # Attach 1–3 traits cheaply; traits carry the heavy behavior.
    trait_ids.clear()
    var possible := [
        &"ashveilscavenger",
        &"coldvergerunner",
        &"ironlungssuit",
        &"packspine",
        &"signalempath",
        &"fastmetabolismhotcore"
    ]
    possible.shuffle()
    var count := 1 + int(rng.randf() * 2.9) # 1–3
    for i in count:
        if i < possible.size():
            trait_ids.append(possible[i])

    # Coarse skill archetype.
    if "ASHVEIL_DRIFT" in biome_tags:
        skill_profile_id = &"ASHVEIL_SCAVENGER_BASIC"
    elif "COLD_VERGE" in biome_tags:
        skill_profile_id = &"COLDVERGE_HULL_TECH"
    else:
        skill_profile_id = &"GENERIC_STATION_DRIFTER"
