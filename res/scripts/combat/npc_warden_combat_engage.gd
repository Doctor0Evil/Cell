extends Resource
class_name WardenCombatEngage

@export var player_vitality: PlayerVitalitySystem
@export var player_traits: CellTraitSet
@export var player_fractures: FractureSystem
@export var warden_vitality: PlayerVitalitySystem
@export var rng: RandomNumberGenerator

func _init() -> void:
    rng = rng if rng else RandomNumberGenerator.new()
    rng.randomize()

func compute_player_hit_chance(warden_agility: float, warden_invisible: bool) -> float:
    var instinct := player_vitality.instinct
    var dex := player_vitality.dexterity
    var agi_target := warden_agility

    var base := 0.70
    var from_attrs := 0.4 * instinct / 10.0 + 0.2 * dex / 10.0
    var vs_target := - agi_target / 20.0

    var hit := base + from_attrs + vs_target
    if warden_invisible:
        hit += -0.30
    return clamp(hit, 0.05, 0.95)

func compute_warden_hit_chance() -> float:
    var inst := warden_vitality.instinct
    var player_agi := player_vitality.agility

    var base := 0.85
    var from_attrs := 0.5 * inst / 10.0
    var vs_target := - player_agi / 20.0
    return clamp(base + from_attrs + vs_target, 0.05, 0.99)

func roll_attack(attacker_hit: float, base_damage: float, crit_chance: float, armor_dt: float, rupture_bonus: float = 0.0) -> Dictionary:
    var r_hit := rng.randf()
    if r_hit > attacker_hit:
        return {
            "hit": false,
            "crit": false,
            "damage": 0.0,
            "roll_hit": r_hit,
            "hit_chance": attacker_hit
        }

    var r_crit := rng.randf()
    var is_crit := r_crit < crit_chance

    var mult := 1.0
    if is_crit:
        mult = 1.0 + rupture_bonus

    var dmg := max(0.0, base_damage * mult - armor_dt)

    return {
        "hit": true,
        "crit": is_crit,
        "damage": dmg,
        "roll_hit": r_hit,
        "hit_chance": attacker_hit,
        "roll_crit": r_crit,
        "crit_chance": crit_chance
    }

func apply_hypothermia_tick(delta_turns: int, env_cold_factor: float, env_stress: float) -> void:
    if delta_turns % 3 != 0:
        return
    player_vitality.tickenvironment(1.0, env_cold_factor, env_stress)

func debug_snapshot_turn(turn_index: int, player_hit: float, warden_hit: float, last_player_attack: Dictionary, last_warden_attack: Dictionary) -> Dictionary:
    return {
        "turn": turn_index,
        "player_hit_chance": player_hit,
        "warden_hit_chance": warden_hit,
        "player_attack": last_player_attack,
        "warden_attack": last_warden_attack,
        "player_pools": {
            "blood": player_vitality.blood,
            "oxygen": player_vitality.oxygen,
            "stamina": player_vitality.stamina,
            "wellness": player_vitality.wellness,
            "body_temp": player_vitality.body_temperature
        },
        "warden_pools": {
            "blood": warden_vitality.blood
        }
    }
