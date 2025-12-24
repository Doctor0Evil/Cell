extends Node
class_name CosmicEventSystem

@export var cosmic_events: Dictionary = {}

# Optional JSON manifest path that the editor/importer writes to.
const COSMIC_EVENTS_PATH := "res://scripts/core/cosmic_events.json"

func _ready() -> void:
    # Auto-load cosmic events from JSON if present (non-fatal).
    _load_cosmic_events_from_json()

func reload_cosmic_events() -> void:
    _load_cosmic_events_from_json()

func _load_cosmic_events_from_json() -> void:
    var f := FileAccess.open(COSMIC_EVENTS_PATH, FileAccess.READ)
    if not f:
        # Not an error — the project may not use the manifest.
        print("CosmicEventSystem: no cosmic events file at %s" % COSMIC_EVENTS_PATH)
        return
    var text := f.get_as_text()
    f.close()

    var parsed := JSON.parse_string(text)
    if parsed.error != OK:
        push_warning("CosmicEventSystem: failed to parse %s: %s" % [COSMIC_EVENTS_PATH, str(parsed.error)])
        return

    if typeof(parsed.result) != TYPE_DICTIONARY:
        push_warning("CosmicEventSystem: expected JSON object at %s" % COSMIC_EVENTS_PATH)
        return

    cosmic_events = parsed.result
    print("CosmicEventSystem: loaded %d cosmic events from %s" % [cosmic_events.size(), COSMIC_EVENTS_PATH])

static func fire(event_id: StringName) -> void:
    var sys := get_tree().get_first_node_in_group("CosmicEventSystemRoot") as CosmicEventSystem
    if sys:
        sys._fire_internal(event_id)

func _fire_internal(event_id: StringName) -> void:
    if not cosmic_events.has(event_id):
        DebugLog.log("CosmicEventSystem", "UNKNOWN_EVENT", {"id": event_id})
        return
    var cfg: Dictionary = cosmic_events[event_id]
    match String(cfg.get("type", "")):
        "plague":
            _apply_plague(cfg)
        "meteor_strike":
            _apply_meteor(cfg)
        "oxygen_collapse":
            _apply_oxygen_collapse(cfg)
        _:
            DebugLog.log("CosmicEventSystem", "UNHANDLED_TYPE", {"id": event_id})

func _apply_plague(cfg: Dictionary) -> void:
    var tag: StringName = cfg.get("affects_tag", &"cannibal")
    var severity: float = cfg.get("severity", 0.5)
    for npc in get_tree().get_nodes_in_group("npc"):
        if not npc is Node:
            continue
        if not npc.has_meta("traits"):
            continue
        var traits: Array = npc.get_meta("traits")
        if tag in traits and npc.has_method("apply_status_affliction"):
            npc.apply_status_affliction(&"flesh_eating_disease", {
                "severity": severity,
                "progression_rate": 1.0
            })
