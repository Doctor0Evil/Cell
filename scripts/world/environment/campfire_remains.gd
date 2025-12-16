extends Node2D
class_name CampfireRemains

@export var base_hold_time: float = 120.0      # seconds at neutral temperature
@export var max_intensity: float = 1.0         # ember heat cap
@export var min_intensity: float = 0.0

@export var start_intensity: float = 0.8
@export var biome_temp_c: float = 5.0          # ambient °C (Cold Verge exterior, sub‑decks, etc.)
@export var target_comfort_temp_c: float = 15.0
@export var is_rainy: bool = false             # set by weather/environment controller
@export var is_exposed: bool = true            # true = directly exposed to rain / coolant mist

# Optional: how much extra fuel was stacked (scrap, pallets, plastics)
@export var fuel_factor: float = 1.0           # 0.5–2.0; >1 = longer embers

# Runtime state
var current_intensity: float = 0.0
var time_alive: float = 0.0
var time_to_cold: float = 0.0                  # computed from base_hold_time + temp bias + fuel
var heat_output: float = 0.0                   # °C/sec local contribution (for region / player)
var active: bool = true

# Radius hint for environment / player temperature sampling (not enforced here)
@export var heat_radius_m: float = 2.5         # meters in which this ember matters

func _ready() -> void:
    current_intensity = clampf(start_intensity, min_intensity, max_intensity)
    time_alive = 0.0
    time_to_cold = _calculate_hold_time()
    DebugLog.log("CampfireRemains", "INIT", {
        "start_intensity": start_intensity,
        "biome_temp": biome_temp_c,
        "target_comfort": target_comfort_temp_c,
        "fuel_factor": fuel_factor,
        "time_to_cold": time_to_cold
    })

func _physics_process(delta: float) -> void:
    if not active:
        return

    time_alive += delta

    # Fully soaked, exposed remains: immediately dead embers
    if is_rainy and is_exposed:
        current_intensity = 0.0
        heat_output = 0.0
        active = false
        DebugLog.log("CampfireRemains", "COLD_RAIN", {
            "biome_temp": biome_temp_c,
            "time_alive": time_alive
        })
        queue_free()
        return

    # Ember lifetime curve: t = 0..1, quadratic fade for smoother tail
    var t := clampf(time_alive / max(0.1, time_to_cold), 0.0, 1.0)
    current_intensity = lerp(start_intensity, 0.0, t * t)

    if current_intensity > 0.0:
        # Heat output is the gap to comfort scaled by intensity; cold biomes → more useful heat.
        var temp_gap := max(0.0, target_comfort_temp_c - biome_temp_c)
        heat_output = temp_gap * 0.1 * current_intensity   # °C/sec in a small radius
    else:
        heat_output = 0.0
        active = false
        DebugLog.log("CampfireRemains", "COLD", {
            "biome_temp": biome_temp_c,
            "time_alive": time_alive
        })
        queue_free()
        return

    DebugLog.log("CampfireRemains", "TICK", {
        "intensity": current_intensity,
        "heat_output": heat_output,
        "time_alive": time_alive,
        "time_to_cold": time_to_cold,
        "biome_temp": biome_temp_c,
        "rainy": is_rainy,
        "exposed": is_exposed
    })

func _calculate_hold_time() -> float:
    # Colder than comfort: embers matter longer; hotter biomes: they cool quickly.
    var temp_delta := target_comfort_temp_c - biome_temp_c
    # At biome_temp well below comfort, hold up to 1.5x; above comfort, as low as 0.5x.
    var bias := clampf(1.0 + (temp_delta / 40.0), 0.5, 1.5)
    # Extra fuel extends ember life; low fuel shortens it.
    var fuel_bias := clampf(fuel_factor, 0.5, 2.0)
    return base_hold_time * bias * fuel_bias
