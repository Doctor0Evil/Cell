extends Node

signal player_inspect_corpse(context)
signal taboo_feign_death_broken(payload)
signal corpse_inspected(payload)
signal inspect_corpse_focus(payload)

func emit_player_inspect_corpse(context: Dictionary) -> void:
    emit_signal("player_inspect_corpse", context)
    WorldAPI.emit_event("PLAYER_INSPECT_CORPSE", context)

func emit_taboo_feign_death_broken(payload: Dictionary) -> void:
    emit_signal("taboo_feign_death_broken", payload)
    WorldAPI.emit_event("TABOO_FEIGN_DEATH_BROKEN", payload)

func emit_corpse_inspected(payload: Dictionary) -> void:
    emit_signal("corpse_inspected", payload)
    WorldAPI.emit_event("CORPSE_INSPECTED", payload)

func emit_inspect_corpse_focus(payload: Dictionary) -> void:
    emit_signal("inspect_corpse_focus", payload)
    WorldAPI.emit_event("INSPECT_CORPSE_FOCUS", payload)