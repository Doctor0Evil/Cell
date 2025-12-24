extends Node

class_name NarrativeDB

var _cache: Dictionary = {}

func load_json(path: String) -> Dictionary:
    if _cache.has(path):
        return _cache[path]
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("Failed to open narrative file: %s" % path)
        return {}
    var data := JSON.parse_string(file.get_as_text())
    if typeof(data) != TYPE_DICTIONARY:
        push_error("Invalid JSON in narrative file: %s" % path)
        return {}
    _cache[path] = data
    return data


func get_artifact(id: String) -> Dictionary:
    var paths := [
        "res://narratives/artifacts/obitel_9_field_note_07.json",
        "res://narratives/artifacts/codex_khrust_fragment_12.json",
        "res://narratives/artifacts/dev_note_greenplain_protocol.json",
        "res://narratives/artifacts/patient_b7_profile.json",
        "res://narratives/artifacts/distress_clip_memories.json"
    ]
    for p in paths:
        var d := load_json(p)
        if d.get("id", "") == id:
            return d
    return {}