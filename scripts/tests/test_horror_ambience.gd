extends Node

@onready var player: ExtremeHorrorAmbiencePlayer = $ExtremeHorrorAmbiencePlayer

func _ready() -> void:
    var def := HorrorAmbienceRegistry.get_definition("facility_low_hum")
    assert(not def.is_empty())
    player._switch_to("facility_low_hum", true)
    player.set_debug_tension_override(0.75)
    player.start_ambience()
    DebugLog.log("TestHorrorAmbience", "SMOKE", {"region": "ASHVEIL_DEBRIS_STRATUM", "tension_override": 0.75})
