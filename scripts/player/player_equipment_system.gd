extends Node
class_name PlayerEquipmentSystem

@export var vitality_system: PlayerVitalitySystem
@export var pools: PlayerPools

var _equipped_weapons: Dictionary = {}   # slot -> WeaponDefinition
var _equipped_armor: Dictionary = {}     # slot -> ArmorDefinition
var _equipped_implants: Dictionary = {}  # slot -> ImplantDefinition

func equip_weapon(def: WeaponDefinition) -> void:
    _equipped_weapons[def.slot] = def

func equip_armor(def: ArmorDefinition) -> void:
    _equipped_armor[def.slot] = def
    _recalc_vitality_mods()

func equip_implant(def: ImplantDefinition) -> void:
    _equipped_implants[def.slot] = def
    _recalc_vitality_mods()

func _recalc_vitality_mods() -> void:
    if not vitality_system:
        return

    # TODO: store and restore base values; for now assume vsys holds base each time
    vitality_system.recalc_maxima()
    pools.recalc_from_vitality()

    for armor in _equipped_armor.values():
        vitality_system.body_temperature_min += armor.body_temp_loss_mult < 1.0 ? -0.5 : 0.0
        vitality_system.body_temperature_max += armor.body_temp_loss_mult < 1.0 ? 0.5 : 0.0

    for implant in _equipped_implants.values():
        pools.oxygen_max *= implant.oxygen_efficiency_mult
        pools.stamina_max *= implant.stamina_recovery_mult

    pools.blood = clamp(pools.blood, 0.0, pools.blood_max)
    pools.oxygen = clamp(pools.oxygen, 0.0, pools.oxygen_max)
    pools.stamina = clamp(pools.stamina, 0.0, pools.stamina_max)

func use_consumable(def: ConsumableDefinition) -> void:
    if vitality_system.yield < def.min_yield_required:
        DebugLog.log("PlayerEquipmentSystem", "CONSUMABLE_REJECTED", {
            "id": def.id,
            "yield": vitality_system.yield,
            "min_yield_required": def.min_yield_required
        })
        return

    vitality_system.vitality += def.vitality_delta
    vitality_system.instinct += def.instinct_delta
    vitality_system.tenacity += def.tenacity_delta
    vitality_system.agility += def.agility_delta
    vitality_system.logic += def.logic_delta
    vitality_system.influence += def.influence_delta
    vitality_system.temper += def.temper_delta
    vitality_system.yield += def.yield_delta

    pools.blood = clamp(pools.blood + def.blood_delta, 0.0, pools.blood_max)
    pools.oxygen = clamp(pools.oxygen + def.oxygen_delta, 0.0, pools.oxygen_max)
    pools.stamina = clamp(pools.stamina + def.stamina_delta, 0.0, pools.stamina_max)
    pools.protein = clamp(pools.protein + def.protein_delta, 0.0, pools.protein_max)
    vitality_system.wellness = clamp(vitality_system.wellness + def.wellness_delta, 0.0, vitality_system.wellness_max)
    vitality_system.body_temperature = clamp(
        vitality_system.body_temperature + def.body_temp_delta,
        vitality_system.body_temperature_min,
        vitality_system.body_temperature_max
    )

    DebugLog.log("PlayerEquipmentSystem", "CONSUMABLE_USED", {
        "id": def.id,
        "blood": pools.blood,
        "oxygen": pools.oxygen,
        "stamina": pools.stamina,
        "protein": pools.protein,
        "wellness": vitality_system.wellness
    })
