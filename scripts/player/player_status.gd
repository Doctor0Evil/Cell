extends Node
class_name PlayerStatus

@export var vitality_system: PlayerVitalitySystem
@export var pools: PlayerPools
@export var suit: SuitIntegrity
@export var env: OxygenEnvironment

@export var race: RaceDefinition
@export var factions: FactionSystem
@export var infection_model: CellInfectionModel

# High‑level state flags
var is_alive: bool = true
var is_conscious: bool = true
var is_bleeding: bool = false
var is_freezing: bool = false
var is_suffocating: bool = false
var is_panicking: bool = false

# Timers and progression values
var time_since_wake: float = 0.0
var time_since_last_damage: float = 0.0
var time_in_critical_oxygen: float = 0.0
var time_in_extreme_cold: float = 0.0
var time_in_high_alert: float = 0.0

# Thresholds for UI and audio cues
const CRITICAL_OXYGEN_SECONDS := 35.0
const CRITICAL_BODY_TEMP := 28.0
const WARNING_BODY_TEMP := 32.0
const HIGH_ALERT_LEVEL := 0.7
const PANIC_SANITY_THRESHOLD := 0.35
const BLEEDOUT_HEALTH_THRESHOLD := 0.25

# Cached display state for HUD (normalized 0.0–1.0)
var hud_state := {
    "health": 1.0,
    "oxygen": 1.0,
    "stamina": 1.0,
    "protein": 1.0,
    "body_temp": 1.0,
    "sanity": 1.0,
    "infection": 0.0,
    "alert": 0.0,
    "is_bleeding": false,
    "is_freezing": false,
    "is_suffocating": false,
    "is_panicking": false
}

# Per‑tick telemetry buffer
var last_tick_telemetry: Dictionary = {
    "env_cold": 0.0,
    "env_stress": 0.0,
    "travel_load": 0.0,
    "awake_load": 0.0,
    "oxygen_drain": 0.0,
    "exertion": 0.0,
    "stamina_recovery": 0.0,
    "contamination": 0.0,
    "infection_delta": 0.0,
    "health_after": 1.0,
    "body_temp_after": 37.0,
    "oxygen_seconds_after": 999.0
}

# Optional: aggregated heat from fires / campfires in current area
var ambient_heat_delta_c_per_sec: float = 0.0

func _ready() -> void:
    add_to_group("runtime")

    if vitality_system == null:
        vitality_system = PlayerVitalitySystem.new()
    if pools == null:
        pools = PlayerPools.new()
    if suit == null:
        suit = SuitIntegrity.new()

    if race:
        race.apply_to_vitality_system(vitality_system)

    vitality_system.recalc_maxima()
    pools.vitality_system = vitality_system
    pools.recalc_from_vitality()

    _sync_hud_from_systems()

    DebugLog.log("PlayerStatus", "INIT", {
        "race": race.display_name if race else "NONE",
        "vitality": vitality_system.vitality,
        "max_health": vitality_system.max_health if vitality_system.has_method("max_health") else 0.0,
        "sanity": GameState.player_sanity,
        "infection": GameState.infection_level,
        "oxygen_max": vitality_system.oxygen_max,
        "suit_snapshot": suit.get_debug_snapshot()
    })

    # Wire radio -> HUD relay
    _wire_radio_hallucinations()

func _physics_process(delta: float) -> void:
    if not is_alive:
        return

    time_since_wake += delta
    time_since_last_damage += delta

    var env_cold := GameState.current_region_cold
    var env_stress := GameState.current_region_stress

    last_tick_telemetry["env_cold"] = env_cold
    last_tick_telemetry["env_stress"] = env_stress
    last_tick_telemetry["travel_load"] = GameState.travel_load
    last_tick_telemetry["awake_load"] = GameState.awake_load
    last_tick_telemetry["oxygen_drain"] = GameState.oxygen_drain_rate
    last_tick_telemetry["exertion"] = GameState.exertion_level
    last_tick_telemetry["stamina_recovery"] = GameState.stamina_recovery
    last_tick_telemetry["contamination"] = GameState.contamination_level

    # --- Environment core tick (cold + stress) ---
    vitality_system.tick_environment(delta, env_cold, env_stress)

    # Apply ambient heat from FireNodes / CampfireRemains
    if ambient_heat_delta_c_per_sec != 0.0:
        vitality_system.bodytemperature = clampf(
            vitality_system.bodytemperature + ambient_heat_delta_c_per_sec * delta,
            vitality_system.bodytemperature_min,
            vitality_system.bodytemperature_max
        )

    # --- Core metabolic resources ---
    pools.tick_protein(delta, GameState.travel_load, GameState.awake_load)

    # --- Oxygen drain (environment + suit leaks) ---
    var base_drain := GameState.oxygen_drain_rate
    var env_factor := env.oxygen_factor if env else 0.0
    var oxygen_zero := pools.tick_oxygen_with_suit(delta, base_drain, env_factor, suit)

    DebugLog.log("PlayerVitalitySystem", "OXYGEN_TICK", {
        "env_state": env.state if env else -1,
        "env_factor": env_factor,
        "region_id": GameState.current_region_id,
        "base_drain": base_drain,
        "leak_total": suit.get_total_leak(),
        "suit_snapshot": suit.get_debug_snapshot(),
        "oxygen": pools.oxygen,
        "oxygen_max": pools.oxygen_max
    })

    if oxygen_zero and is_alive:
        is_suffocating = true
        GameState.kill_player(&"OXYGEN_ZERO")
        _on_player_death("OXYGEN_ZERO")
        return

    # --- Stamina / exertion ---
    var collapsed := pools.tick_stamina(delta, GameState.exertion_level, GameState.stamina_recovery)
    if collapsed and is_conscious:
        is_conscious = false
        GameState.on_player_collapse(&"STAMINA")
        DebugLog.log("PlayerStatus", "PLAYER_COLLAPSE", {
            "reason": "STAMINA",
            "exertion": GameState.exertion_level
        })

    # --- Infection accumulation ---
    if infection_model:
        var inf_delta := infection_model.tick_infection(
            delta,
            vitality_system,
            race,
            GameState.contamination_level
        )
        GameState.infection_level += inf_delta
        last_tick_telemetry["infection_delta"] = inf_delta

    # --- Update flags + HUD + log ---
    _update_state_flags(delta)
    _sync_hud_from_systems()
    _emit_hud_update()

    DebugLog.log("PlayerStatus", "TICK", last_tick_telemetry)

    # Drive radio hallucination/signal system (if loaded as autoload)
    _update_radio_hallucinations()

# -------------------------------------------------------------------
# STATE / HUD SYNC
# -------------------------------------------------------------------

func _update_state_flags(delta: float) -> void:
    var body_temp := 37.0
    if vitality_system.has_method("get_body_temperature"):
        body_temp = vitality_system.get_body_temperature()
    elif pools.has_method("body_temperature"):
        body_temp = pools.body_temperature

    last_tick_telemetry["body_temp_after"] = body_temp

    is_freezing = body_temp <= WARNING_BODY_TEMP
    if body_temp <= CRITICAL_BODY_TEMP:
        time_in_extreme_cold += delta
    else:
        time_in_extreme_cold = max(0.0, time_in_extreme_cold - delta * 0.5)

    var oxygen_seconds := 999.0
    if pools.has_method("get_oxygen_seconds_remaining"):
        oxygen_seconds = pools.get_oxygen_seconds_remaining()
    last_tick_telemetry["oxygen_seconds_after"] = oxygen_seconds

    is_suffocating = oxygen_seconds <= CRITICAL_OXYGEN_SECONDS
    if is_suffocating:
        time_in_critical_oxygen += delta
    else:
        time_in_critical_oxygen = max(0.0, time_in_critical_oxygen - delta * 0.5)

    var health_ratio := 1.0
    if pools.has_method("get_health_ratio"):
        health_ratio = pools.get_health_ratio()
    elif vitality_system.has_method("get_health_ratio"):
        health_ratio = vitality_system.get_health_ratio()
    last_tick_telemetry["health_after"] = health_ratio

    is_bleeding = health_ratio < BLEEDOUT_HEALTH_THRESHOLD

    var sanity := GameState.player_sanity
    hud_state["sanity"] = clamp(sanity, 0.0, 1.0)
    is_panicking = sanity <= PANIC_SANITY_THRESHOLD or GameState.alert_level >= HIGH_ALERT_LEVEL

    if GameState.alert_level >= HIGH_ALERT_LEVEL:
        time_in_high_alert += delta
    else:
        time_in_high_alert = max(0.0, time_in_high_alert - delta * 0.5)

func _sync_hud_from_systems() -> void:
    if pools.has_method("get_health_ratio"):
        hud_state["health"] = clamp(pools.get_health_ratio(), 0.0, 1.0)
    elif vitality_system.has_method("get_health_ratio"):
        hud_state["health"] = clamp(vitality_system.get_health_ratio(), 0.0, 1.0)

    if pools.has_method("get_oxygen_ratio"):
        hud_state["oxygen"] = clamp(pools.get_oxygen_ratio(), 0.0, 1.0)

    if pools.has_method("get_stamina_ratio"):
        hud_state["stamina"] = clamp(pools.get_stamina_ratio(), 0.0, 1.0)

    if pools.has_method("get_protein_ratio"):
        hud_state["protein"] = clamp(pools.get_protein_ratio(), 0.0, 1.0)

    var body_temp := 37.0
    if vitality_system.has_method("get_body_temperature"):
        body_temp = vitality_system.get_body_temperature()
    elif pools.has_method("body_temperature"):
        body_temp = pools.body_temperature
    hud_state["body_temp"] = clamp((body_temp - 24.0) / (40.0 - 24.0), 0.0, 1.0)

    hud_state["infection"] = clamp(GameState.infection_level, 0.0, 1.0)
    hud_state["alert"] = clamp(GameState.alert_level, 0.0, 1.0)

    hud_state["is_bleeding"] = is_bleeding
    hud_state["is_freezing"] = is_freezing
    hud_state["is_suffocating"] = is_suffocating
    hud_state["is_panicking"] = is_panicking

func _wire_radio_hallucinations() -> void:
    # Connect RadioTransmissions.hallucination_pulse -> _on_radio_hallucination_pulse.
    if typeof(RadioTransmissions) == TYPE_NIL:
        return
    var radio := RadioTransmissions
    if radio.has_signal("hallucination_pulse") and not radio.is_connected("hallucination_pulse", self, "_on_radio_hallucination_pulse"):
        radio.connect("hallucination_pulse", Callable(self, "_on_radio_hallucination_pulse"))

func _on_radio_hallucination_pulse(oxygen_seconds: float) -> void:
    # Relay the pulse to HUD nodes that opt-in by being in group 'hud_neurochip'.
    var hud_nodes := get_tree().get_nodes_in_group("hud_neurochip")
    for node in hud_nodes:
        if node and node.has_method("on_radio_hallucination_pulse"):
            node.on_radio_hallucination_pulse(oxygen_seconds)

func get_oxygen_seconds_remaining() -> float:
    if pools and pools.has_method("get_oxygen_seconds_remaining"):
        return pools.get_oxygen_seconds_remaining()
    return 999.0

func _update_radio_hallucinations() -> void:
    # Push current oxygen state into RadioTransmissions autoload (if available)
    if not pools or not pools.has_method("get_oxygen_seconds_remaining"):
        return

    var oxygen_seconds := pools.get_oxygen_seconds_remaining()
    var alive := is_alive

    # Safe-call the autoload singleton if it exists in the running project
    if typeof(RadioTransmissions) != TYPE_NIL:
        RadioTransmissions.set_oxygen_state(oxygen_seconds, is_suffocating, alive)

func _emit_hud_update() -> void:
    get_tree().call_group_flags(
        SceneTree.GROUP_CALL_DEFERRED,
        "runtime",
        "on_player_status_changed",
        hud_state
    )

# -------------------------------------------------------------------
# DAMAGE / HEALING
# -------------------------------------------------------------------

func apply_damage(amount: float, source: StringName = &"UNKNOWN") -> void:
    if not is_alive:
        return
    time_since_last_damage = 0.0

    if vitality_system.has_method("apply_damage"):
        vitality_system.apply_damage(amount)
    elif pools.has_method("apply_damage"):
        pools.apply_damage(amount)

    _sync_hud_from_systems()

    if hud_state["health"] <= 0.0 and is_alive:
        GameState.kill_player(&"HEALTH_ZERO")
        _on_player_death("HEALTH_ZERO")

    DebugLog.log("PlayerStatus", "APPLY_DAMAGE", {
        "amount": amount,
        "source": String(source),
        "health_after": hud_state["health"]
    })

func apply_heal(amount: float, source: StringName = &"UNKNOWN") -> void:
    if not is_alive:
        return

    if vitality_system.has_method("apply_heal"):
        vitality_system.apply_heal(amount)
    elif pools.has_method("apply_heal"):
        pools.apply_heal(amount)

    _sync_hud_from_systems()

    DebugLog.log("PlayerStatus", "APPLY_HEAL", {
        "amount": amount,
        "source": String(source),
        "health_after": hud_state["health"]
    })

# -------------------------------------------------------------------
# LIFECYCLE
# -------------------------------------------------------------------

func _on_player_death(reason: String) -> void:
    is_alive = false
    is_conscious = false
    DebugLog.log("PlayerStatus", "PLAYER_DEATH", {
        "reason": reason,
        "time_since_wake": time_since_wake,
        "infection": GameState.infection_level,
        "sanity": GameState.player_sanity,
        "alert": GameState.alert_level
    })
    get_tree().call_group_flags(
        SceneTree.GROUP_CALL_DEFERRED,
        "runtime",
        "on_player_death",
        reason
    )

# -------------------------------------------------------------------
# AMBIENT HEAT FROM FIRES / CAMPFIRES
# -------------------------------------------------------------------

func apply_fire_heat(heat_c_per_sec: float) -> void:
    ambient_heat_delta_c_per_sec = heat_c_per_sec

func clear_fire_heat() -> void:
    ambient_heat_delta_c_per_sec = 0.0
