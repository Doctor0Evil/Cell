extends Node
class_name FractureSystem

@export var vitality_system: PlayerVitalitySystem
@export var library: FractureLibrary

var active_fractures: Array[FractureDefinition] = []
var active_surge_time: float = 0.0
var active_surge: FractureDefinition = null

func add_fracture(id: StringName) -> void:
    var def := library.get(id)
    if def == null:
        return
    # Apply flat attribute deltas and max pool scars
    vitality_system.vitality += def.vitality_delta
    vitality_system.instinct += def.instinct_delta
    vitality_system.tenacity += def.tenacity_delta
    vitality_system.agility += def.agility_delta
    vitality_system.logic += def.logic_delta
    vitality_system.influence += def.influence_delta
    vitality_system.temper += def.temper_delta
    vitality_system.yield += def.yield_delta

    vitality_system.wellness_max -= def.wellness_max_scar
    vitality_system.yield -= def.yield_scar
    vitality_system.recalc_maxima()

    active_fractures.append(def)

func get_pool_multipliers() -> Dictionary:
    # Aggregate multiplicative effects for core loops
    var mul := {
        "blood_loss": 1.0,
        "oxygen_decay": 1.0,
        "water_decay": 1.0,
        "stamina_decay": 1.0,
        "stamina_recovery": 1.0,
        "temp_drop": 1.0,
        "wellness_decay": 1.0,
        "blood_max": 1.0,
        "stamina_max": 1.0,
        "wellness_max": 1.0
    }

    for f in active_fractures:
        mul["blood_loss"] *= f.blood_loss_mult
        mul["oxygen_decay"] *= f.oxygen_decay_mult
        mul["water_decay"] *= f.water_decay_mult
        mul["stamina_decay"] *= f.stamina_decay_mult
        mul["stamina_recovery"] *= f.stamina_recovery_mult
        mul["temp_drop"] *= f.temp_drop_mult
        mul["wellness_decay"] *= f.wellness_decay_mult
        mul["blood_max"] *= f.blood_max_mult
        mul["stamina_max"] *= f.stamina_max_mult
        mul["wellness_max"] *= f.wellness_max_mult

    return mul

func tick(delta: float, is_in_darkness: bool, surrounded_radius: float) -> void:
    if vitality_system == null:
        return

    # Handle reactive surges like Last Tank
    if active_surge and active_surge.surge_duration > 0.0:
        active_surge_time += delta
        if active_surge_time >= active_surge.surge_duration:
            # End surge, apply scars
            vitality_system.wellness_max -= active_surge.wellness_max_scar
            vitality_system.yield -= active_surge.yield_scar
            vitality_system.recalc_maxima()
            active_surge = null
            active_surge_time = 0.0

    if active_surge == null:
        for f in active_fractures:
            if not f.is_reactive():
                continue
            if _should_trigger(f, is_in_darkness, surrounded_radius):
                active_surge = f
                active_surge_time = 0.0
                DebugLog.log("FractureSystem", "SURGE_TRIGGER", {"fracture": f.id})
                break

func _should_trigger(f: FractureDefinition, is_in_darkness: bool, surrounded_radius: float) -> bool:
    var blood_ratio := vitality_system.blood / max(1.0, vitality_system.blood_max)
    var oxy_ratio := vitality_system.oxygen / max(1.0, vitality_system.oxygen_max)
    var water_ratio := vitality_system.water / max(1.0, vitality_system.water_max)
    var well_ratio := vitality_system.wellness / max(1.0, vitality_system.wellness_max)

    if f.trigger_blood_ratio_lt >= 0.0 and blood_ratio < f.trigger_blood_ratio_lt:
        return true
    if f.trigger_oxygen_ratio_lt >= 0.0 and oxy_ratio < f.trigger_oxygen_ratio_lt:
        return true
    if f.trigger_water_ratio_lt >= 0.0 and water_ratio < f.trigger_water_ratio_lt:
        return true
    if f.trigger_wellness_ratio_lt >= 0.0 and well_ratio < f.trigger_wellness_ratio_lt:
        return true
    if f.trigger_in_darkness and is_in_darkness:
        return true
    if f.trigger_surrounded_radius > 0.0 and surrounded_radius > 0.0 and surrounded_radius <= f.trigger_surrounded_radius:
        return true

    return false
