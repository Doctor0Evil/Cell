extends Resource
class_name FactionSystem

enum FactionId {
    IGSF,
    IMPERIAL_KNIGHTS,
    VLR,
    REPZILLIONS
}

enum ReputationBand {
    HOSTILE,
    SUSPICIOUS,
    NEUTRAL,
    TRUSTED,
    FAVORED
}

var reputation: Dictionary = {
    FactionId.IGSF: 0.0,
    FactionId.IMPERIAL_KNIGHTS: -50.0,
    FactionId.VLR: 0.0,
    FactionId.REPZILLIONS: -25.0
}

func modify_reputation(faction: int, delta: float) -> void:
    if not reputation.has(faction):
        return
    reputation[faction] = clamp(reputation[faction] + delta, -100.0, 100.0)

func get_reputation_band(faction: int) -> ReputationBand:
    var value := reputation.get(faction, 0.0)
    if value <= -50.0:
        return ReputationBand.HOSTILE
    if value < -10.0:
        return ReputationBand.SUSPICIOUS
    if value <= 25.0:
        return ReputationBand.NEUTRAL
    if value <= 70.0:
        return ReputationBand.TRUSTED
    return ReputationBand.FAVORED

func get_oxygen_multiplier_for_zone(faction: int) -> float:
    var band := get_reputation_band(faction)
    match faction:
        FactionId.IGSF:
            match band:
                ReputationBand.HOSTILE, ReputationBand.SUSPICIOUS:
                    return 1.1 # worse conditions, fewer supplies
                ReputationBand.NEUTRAL:
                    return 1.0
                ReputationBand.TRUSTED, ReputationBand.FAVORED:
                    return 0.8 # more efficient shelter, better seals
        FactionId.VLR:
            if band == ReputationBand.TRUSTED or band == ReputationBand.FAVORED:
                return 0.9
    return 1.0

func get_medical_efficiency_bonus(faction: int) -> float:
    var band := get_reputation_band(faction)
    if faction == FactionId.IGSF:
        match band:
            ReputationBand.TRUSTED:
                return 1.2
            ReputationBand.FAVORED:
                return 1.4
    if faction == FactionId.VLR and band >= ReputationBand.NEUTRAL:
        return 1.1
    return 1.0

func should_trigger_knight_ambush() -> bool:
    var band := get_reputation_band(FactionId.IMPERIAL_KNIGHTS)
    if band == ReputationBand.HOSTILE:
        return true
    if band == ReputationBand.SUSPICIOUS:
        return randf() < 0.4
    return randf() < 0.2
