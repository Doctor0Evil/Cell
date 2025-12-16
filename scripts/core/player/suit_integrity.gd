extends Resource
class_name SuitIntegrity

# High‑level integrity
@export var max_integrity: float = 100.0

@export var integrity_head: float = 100.0        # visor / helm
@export var integrity_torso: float = 100.0
@export var integrity_limbs: float = 100.0

# Detailed zone health (0–100 each)
@export var integrity_faceplate: float = 100.0   # critical for vacuum
@export var integrity_seal_neck: float = 100.0
@export var integrity_seal_waist: float = 100.0
@export var integrity_joint_left_arm: float = 100.0
@export var integrity_joint_right_arm: float = 100.0
@export var integrity_joint_left_leg: float = 100.0
@export var integrity_joint_right_leg: float = 100.0
@export var integrity_tank_back: float = 100.0   # external tank housing
@export var integrity_hose_front: float = 100.0  # main O2 hose / umbilical

# Aggregate leak rates (used by gameplay systems, in O2/sec)
var leak_rate_head: float = 0.0
var leak_rate_torso: float = 0.0
var leak_rate_limbs: float = 0.0

# Developer‑facing granular leak map (for logs/tools), O2/sec
var leak_map: Dictionary = {
    "FACEPLATE": 0.0,
    "SEAL_NECK": 0.0,
    "SEAL_WAIST": 0.0,
    "JOINT_LEFT_ARM": 0.0,
    "JOINT_RIGHT_ARM": 0.0,
    "JOINT_LEFT_LEG": 0.0,
    "JOINT_RIGHT_LEG": 0.0,
    "TANK_BACK": 0.0,
    "HOSE_FRONT": 0.0
}

# Simple damage zones used by hitboxes / weapons
enum DamageZone {
    HEAD,
    TORSO,
    LEFT_ARM,
    RIGHT_ARM,
    LEFT_LEG,
    RIGHT_LEG
}

func apply_damage_zone(zone: DamageZone, amount: float, surface: StringName = &"DEFAULT") -> void:
    # Developer‑grade application: a hitbox calls this with zone + amount + surface (bullet, shrapnel, acid)
    match zone:
        DamageZone.HEAD:
            integrity_head = max(0.0, integrity_head - amount * 0.6)
            integrity_faceplate = max(0.0, integrity_faceplate - amount * _surface_multiplier(surface, "FACEPLATE"))
            integrity_seal_neck = max(0.0, integrity_seal_neck - amount * 0.25)
        DamageZone.TORSO:
            integrity_torso = max(0.0, integrity_torso - amount * 0.5)
            integrity_tank_back = max(0.0, integrity_tank_back - amount * _surface_multiplier(surface, "TANK"))
            integrity_seal_waist = max(0.0, integrity_seal_waist - amount * 0.25)
            integrity_hose_front = max(0.0, integrity_hose_front - amount * _surface_multiplier(surface, "HOSE"))
        DamageZone.LEFT_ARM:
            integrity_limbs = max(0.0, integrity_limbs - amount * 0.4)
            integrity_joint_left_arm = max(0.0, integrity_joint_left_arm - amount * 0.6)
        DamageZone.RIGHT_ARM:
            integrity_limbs = max(0.0, integrity_limbs - amount * 0.4)
            integrity_joint_right_arm = max(0.0, integrity_joint_right_arm - amount * 0.6)
        DamageZone.LEFT_LEG:
            integrity_limbs = max(0.0, integrity_limbs - amount * 0.4)
            integrity_joint_left_leg = max(0.0, integrity_joint_left_leg - amount * 0.6)
        DamageZone.RIGHT_LEG:
            integrity_limbs = max(0.0, integrity_limbs - amount * 0.4)
            integrity_joint_right_leg = max(0.0, integrity_joint_right_leg - amount * 0.6)

    _recalc_all_leaks()

    DebugLog.log("SuitIntegrity", "DAMAGE_ZONE", {
        "zone": int(zone),
        "surface": surface,
        "amount": amount,
        "integrity": {
            "head": integrity_head,
            "torso": integrity_torso,
            "limbs": integrity_limbs,
            "faceplate": integrity_faceplate,
            "seal_neck": integrity_seal_neck,
            "seal_waist": integrity_seal_waist,
            "joint_la": integrity_joint_left_arm,
            "joint_ra": integrity_joint_right_arm,
            "joint_ll": integrity_joint_left_leg,
            "joint_rl": integrity_joint_right_leg,
            "tank_back": integrity_tank_back,
            "hose_front": integrity_hose_front
        },
        "leak_map": leak_map.duplicate(true),
        "leak_total": get_total_leak()
    })

# Backwards‑compatible simple API
func apply_damage(part: StringName, amount: float) -> void:
    match part:
        "HEAD":
            apply_damage_zone(DamageZone.HEAD, amount)
        "TORSO":
            apply_damage_zone(DamageZone.TORSO, amount)
        "LIMB":
            # Split randomly across limbs for dev tools that only pass "LIMB"
            var limb_zone := DamageZone.LEFT_ARM
            var r := randi() % 4
            match r:
                0: limb_zone = DamageZone.LEFT_ARM
                1: limb_zone = DamageZone.RIGHT_ARM
                2: limb_zone = DamageZone.LEFT_LEG
                3: limb_zone = DamageZone.RIGHT_LEG
            apply_damage_zone(limb_zone, amount)
        _:
            apply_damage_zone(DamageZone.TORSO, amount)

func _surface_multiplier(surface: StringName, target: StringName) -> float:
    # Developer‑tunable mapping: bullets crack faceplates more, acid eats seals, etc.
    match surface:
        "BULLET":
            if target == "FACEPLATE": return 1.25
            if target == "TANK": return 1.1
            if target == "HOSE": return 1.15
        "SHRAPNEL":
            if target in ["FACEPLATE", "HOSE", "TANK"]: return 0.9
        "ACID":
            if target == "FACEPLATE": return 0.7
            if target == "TANK": return 0.5
            return 1.4 # seals and joints melt
        "BLUNT":
            if target == "FACEPLATE": return 0.6
            if target == "TANK": return 0.8
        _:
            pass
    return 1.0

func _recalc_all_leaks() -> void:
    _recalc_faceplate_leak()
    _recalc_seal_leak()
    _recalc_joint_leaks()
    _recalc_tank_hose_leak()
    _recalc_aggregate_leaks()

func _recalc_faceplate_leak() -> void:
    var leak := 0.0
    if integrity_faceplate <= 80.0: leak = 0.02
    if integrity_faceplate <= 60.0: leak = 0.08
    if integrity_faceplate <= 35.0: leak = 0.25
    if integrity_faceplate <= 15.0: leak = 0.70
    leak_map["FACEPLATE"] = leak

func _recalc_seal_leak() -> void:
    var leak_neck := 0.0
    if integrity_seal_neck <= 75.0: leak_neck = 0.03
    if integrity_seal_neck <= 50.0: leak_neck = 0.10
    if integrity_seal_neck <= 25.0: leak_neck = 0.30
    leak_map["SEAL_NECK"] = leak_neck

    var leak_waist := 0.0
    if integrity_seal_waist <= 75.0: leak_waist = 0.02
    if integrity_seal_waist <= 50.0: leak_waist = 0.08
    if integrity_seal_waist <= 25.0: leak_waist = 0.25
    leak_map["SEAL_WAIST"] = leak_waist

func _recalc_joint_leaks() -> void:
    leak_map["JOINT_LEFT_ARM"] = _joint_leak_from_integrity(integrity_joint_left_arm)
    leak_map["JOINT_RIGHT_ARM"] = _joint_leak_from_integrity(integrity_joint_right_arm)
    leak_map["JOINT_LEFT_LEG"] = _joint_leak_from_integrity(integrity_joint_left_leg)
    leak_map["JOINT_RIGHT_LEG"] = _joint_leak_from_integrity(integrity_joint_right_leg)

func _joint_leak_from_integrity(integrity: float) -> float:
    var leak := 0.0
    if integrity <= 70.0: leak = 0.01
    if integrity <= 50.0: leak = 0.04
    if integrity <= 25.0: leak = 0.12
    return leak

func _recalc_tank_hose_leak() -> void:
    var leak_tank := 0.0
    if integrity_tank_back <= 80.0: leak_tank = 0.01
    if integrity_tank_back <= 60.0: leak_tank = 0.05
    if integrity_tank_back <= 35.0: leak_tank = 0.20
    leak_map["TANK_BACK"] = leak_tank

    var leak_hose := 0.0
    if integrity_hose_front <= 80.0: leak_hose = 0.02
    if integrity_hose_front <= 55.0: leak_hose = 0.09
    if integrity_hose_front <= 30.0: leak_hose = 0.28
    leak_map["HOSE_FRONT"] = leak_hose

func _recalc_aggregate_leaks() -> void:
    leak_rate_head = leak_map["FACEPLATE"] + leak_map["SEAL_NECK"]
    leak_rate_torso = leak_map["SEAL_WAIST"] + leak_map["TANK_BACK"] + leak_map["HOSE_FRONT"]
    leak_rate_limbs = leak_map["JOINT_LEFT_ARM"] + leak_map["JOINT_RIGHT_ARM"] \
        + leak_map["JOINT_LEFT_LEG"] + leak_map["JOINT_RIGHT_LEG"]

func get_total_leak() -> float:
    return leak_rate_head + leak_rate_torso + leak_rate_limbs

func is_compromised() -> bool:
    return get_total_leak() > 0.0

func get_debug_snapshot() -> Dictionary:
    # For debug console, replay tools, and crash logs
    return {
        "integrity": {
            "head": integrity_head,
            "torso": integrity_torso,
            "limbs": integrity_limbs,
            "faceplate": integrity_faceplate,
            "seal_neck": integrity_seal_neck,
            "seal_waist": integrity_seal_waist,
            "joint_la": integrity_joint_left_arm,
            "joint_ra": integrity_joint_right_arm,
            "joint_ll": integrity_joint_left_leg,
            "joint_rl": integrity_joint_right_leg,
            "tank_back": integrity_tank_back,
            "hose_front": integrity_hose_front
        },
        "leak_map": leak_map.duplicate(true),
        "aggregate": {
            "head": leak_rate_head,
            "torso": leak_rate_torso,
            "limbs": leak_rate_limbs,
            "total": get_total_leak()
        }
    }
