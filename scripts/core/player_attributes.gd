extends Resource
class_name PlayerAttributes

# Core V.I.T.A.L.I.T.Y. attributes
@export var vitality: float = 5.0    # biological resilience (0-10)
@export var instinct: float = 5.0    # situational awareness, reflex (0-10)
@export var tenacity: float = 5.0    # endurance under stress (0-10)
@export var agility: float = 5.0     # quick movement, dodging (0-10)
@export var logic: float = 5.0       # cold cognition, technical skill (0-10)
@export var influence: float = 5.0   # social/psychological presence (0-10)
@export var temper: float = 5.0      # emotional control, panic threshold (0-10)
@export var yield: float = 5.0       # efficiency with resources (0-10)

# Secondary attributes – can be calculated or stored directly
@export var constitution: float = 5.0
@export var dexterity: float = 5.0
@export var intelligence: float = 5.0
@export var luck: float = 5.0
@export var speed: float = 5.0
@export var strength: float = 5.0

func get_max_health() -> int:
    # Base HP influenced by vitality and constitution.
    return int(80 + vitality * 4.0 + constitution * 3.0)

func get_stamina_capacity() -> float:
    # Tenacity + agility define how long the player can sprint or fight before collapsing.
    return 5.0 + tenacity * 0.6 + agility * 0.4

func get_cold_resistance() -> float:
    # Higher vitality, tenacity, and constitution slow body-temp drop.
    return clamp((vitality + tenacity + constitution) / 30.0, 0.1, 1.5)

func get_oxygen_efficiency() -> float:
    # Yield and tenacity dictate how long oxygen capsules and tanks last.
    return clamp((yield * 0.7 + tenacity * 0.3) / 10.0, 0.5, 1.8)

func get_hacking_efficiency() -> float:
    # Logic + intelligence influence BCI/terminal interactions.
    return clamp((logic * 0.6 + intelligence * 0.4) / 10.0, 0.2, 2.0)

func get_sanity_stability() -> float:
    # Instinct + temper determine how fast sanity degrades under horror.
    return clamp((instinct * 0.5 + temper * 0.5) / 10.0, 0.2, 1.8)

func get_loot_luck_modifier() -> float:
    # Luck slightly nudges rare drops and ration-chip finds.
    return clamp(1.0 + (luck - 5.0) * 0.06, 0.7, 1.3)

func get_melee_damage_multiplier() -> float:
    return clamp(0.5 + strength * 0.1, 0.5, 2.5)

func get_move_speed_multiplier() -> float:
    # Speed + agility define movement; armor or exosuit load can reduce it later.
    return clamp(0.6 + speed * 0.06 + agility * 0.04, 0.6, 2.0)

func apply_ration_chip_tier(tier: int) -> void:
    # Ration-chips permanently improve certain stats; how much they help is gated by yield.
    var factor := 0.2 + yield * 0.05
    match tier:
        1:
            vitality = min(10.0, vitality + 0.5 * factor)
            constitution = min(10.0, constitution + 0.5 * factor)
        2:
            agility = min(10.0, agility + 0.4 * factor)
            dexterity = min(10.0, dexterity + 0.4 * factor)
            speed = min(10.0, speed + 0.3 * factor)
        3:
            logic = min(10.0, logic + 0.5 * factor)
            intelligence = min(10.0, intelligence + 0.5 * factor)
            strength = min(10.0, strength + 0.4 * factor)

func apply_oxygen_capsule_effect() -> void:
    # Capsules are powerful but dangerous: improve oxygen efficiency short-term,
    # slightly stress vitality and temper (long-term side effects).
    yield = min(10.0, yield + 0.2)
    tenacity = min(10.0, tenacity + 0.1)
    vitality = max(0.0, vitality - 0.05)
    temper = max(0.0, temper - 0.05)
