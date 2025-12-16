extends Node
class_name PlayerStatus

@export var vitality_system: PlayerVitalitySystem
@export var pools: PlayerPools
@export var race: RaceDefinition
@export var factions: FactionSystem
@export var infection_model: CellInfectionModel

func _ready() -> void:
    if race:
        race.apply_to_vitality_system(vitality_system)
    vitality_system.recalc_maxima()
    pools.vitality_system = vitality_system
    pools.recalc_from_vitality()
    DebugLog.log("PlayerStatus", "INIT", {
        "race": race.display_name,
        "vitality": vitality_system.vitality
    })

func _physics_process(delta: float) -> void:
    var env_cold := GameState.current_region_cold
    var env_stress := GameState.current_region_stress

    vitality_system.tick_environment(delta, env_cold, env_stress)
    pools.tick_protein(delta, GameState.travel_load, GameState.awake_load)

    if pools.tick_oxygen(delta, GameState.oxygen_drain_rate):
        GameState.kill_player("OXYGEN_ZERO")

    var collapsed := pools.tick_stamina(delta, GameState.exertion_level, GameState.stamina_recovery)
    if collapsed:
        GameState.on_player_collapse("STAMINA")

    var inf_delta := infection_model.tick_infection(delta, vitality_system, race, GameState.contamination_level)
    GameState.infection_level += inf_delta
