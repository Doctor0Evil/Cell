extends Node
class_name LawSystem

@export var registry: LawRegistry

var _active_laws: Dictionary = {}
var recent_crimes: Dictionary = {}
var recent_disasters: Dictionary = {}

func can_enact(id: StringName) -> bool:
    var law := registry.get_law(id)
    if law == null:
        return false
    for ex in law.exclusive_with:
        if _active_laws.has(ex):
            return false
    return true

func enact(id: StringName) -> void:
    if not can_enact(id):
        return
    var law := registry.get_law(id)
    _active_laws[id] = law
    _apply_global_effects()

func _apply_global_effects() -> void:
    GameState.oxygen_law_mult = 1.0
    GameState.protein_law_mult = 1.0
    GameState.wellness_law_mult = 1.0
    GameState.infection_law_mult = 1.0

    for law in _active_laws.values():
        GameState.oxygen_law_mult *= law.oxygen_use_mult
        GameState.protein_law_mult *= law.protein_consumption_mult
        GameState.wellness_law_mult *= law.wellness_decay_mult
        GameState.infection_law_mult *= law.infection_risk_mult

func is_tag_enabled(tag: StringName) -> bool:
    for law in _active_laws.values():
        if tag in law.forbids_tags:
            return false
    for law in _active_laws.values():
        if tag in law.enables_tags:
            return true
    return false

func tick_cosmic_justice() -> void:
    for law in _active_laws.values():
        if law.category != &"cosmic":
            continue
        var weight := _compute_cosmic_weight(law)
        if weight <= 0.0:
            continue
        if randf() < law.cosmic_trigger_chance * weight:
            _trigger_cosmic_outcome(law)

func _compute_cosmic_weight(law: LawDefinition) -> float:
    var total_heinous := float(recent_crimes.get("cannibalism", 0)) * 2.0 \
        + float(recent_crimes.get("mass_murder", 0)) * 3.0 \
        + float(recent_crimes.get("betrayal", 0)) * 1.5
    return clamp(total_heinous / 10.0, 0.0, 3.0)

func _trigger_cosmic_outcome(law: LawDefinition) -> void:
    if law.cosmic_outcome_ids.is_empty():
        return
    var outcome_id: StringName = law.cosmic_outcome_ids[randi() % law.cosmic_outcome_ids.size()]
    CosmicEventSystem.fire(outcome_id)
    recent_crimes.clear()
    recent_disasters.clear()
