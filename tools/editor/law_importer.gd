tool
extends EditorScript

# Simple importer: reads res://scripts/core/law_examples.json and writes
# res://scripts/core/laws/<ID>.tres for each law, plus res://scripts/core/cosmic_events.json

const MANIFEST_PATH := "res://scripts/core/law_examples.json"
const OUT_LAWS_DIR := "res://scripts/core/laws/"
const COSMIC_EVENTS_PATH := "res://scripts/core/cosmic_events.json"

func _run() -> void:
    var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
    if not file:
        printerr("LawImporter: could not open manifest: %s" % MANIFEST_PATH)
        return
    var text := file.get_as_text()
    file.close()

    var parsed := JSON.parse_string(text)
    if parsed.error != OK:
        printerr("LawImporter: JSON parse error: %s" % str(parsed.error))
        return
    var data := parsed.result

    if not data.has("laws"):
        printerr("LawImporter: manifest missing 'laws' array")
        return

    var laws := data["laws"]
    var created := 0
    for law_dict in laws:
        var ok := _create_law_tres(law_dict)
        if ok:
            created += 1

    # Dump cosmic events JSON to project for manual loading by CosmicEventSystem
    if data.has("cosmic_events"):
        var events_text := JSON.stringify(data["cosmic_events"], true)
        var outf := FileAccess.open(COSMIC_EVENTS_PATH, FileAccess.WRITE)
        if outf:
            outf.store_string(events_text)
            outf.close()
            print("LawImporter: wrote cosmic events to %s" % COSMIC_EVENTS_PATH)

    print("LawImporter: created %d law resources." % created)
    get_editor_interface().show_message("Law Import", "Created %d law resources." % created)

func _create_law_tres(dict: Dictionary) -> bool:
    if not dict.has("id"):
        printerr("LawImporter: law missing id: %s" % str(dict))
        return false
    var id := String(dict["id"])
    var path := OUT_LAWS_DIR + id + ".tres"

    # Create resource and populate fields
    var res := preload("res://scripts/core/law_definition.gd").new()
    res.id = id
    res.display_name = dict.get("display_name", "")
    res.description = dict.get("description", "")
    res.category = dict.get("category", res.category)
    res.tree = dict.get("tree", res.tree)
    res.exclusive_with = dict.get("exclusive_with", [])

    res.settlement_stability_delta = float(dict.get("settlement_stability_delta", res.settlement_stability_delta))
    res.discontent_delta = float(dict.get("discontent_delta", res.discontent_delta))
    res.hope_delta = float(dict.get("hope_delta", res.hope_delta))

    res.oxygen_use_mult = float(dict.get("oxygen_use_mult", res.oxygen_use_mult))
    res.protein_consumption_mult = float(dict.get("protein_consumption_mult", res.protein_consumption_mult))
    res.wellness_decay_mult = float(dict.get("wellness_decay_mult", res.wellness_decay_mult))
    res.infection_risk_mult = float(dict.get("infection_risk_mult", res.infection_risk_mult))

    res.enables_tags = dict.get("enables_tags", [])
    res.forbids_tags = dict.get("forbids_tags", [])

    res.on_crime_events = dict.get("on_crime_events", {})
    res.on_disaster_events = dict.get("on_disaster_events", {})

    res.cosmic_trigger_chance = float(dict.get("cosmic_trigger_chance", res.cosmic_trigger_chance))
    res.cosmic_outcome_ids = dict.get("cosmic_outcome_ids", [])

    # Save resource
    var err := ResourceSaver.save(res, path)
    if err != OK:
        printerr("LawImporter: failed saving %s (err %s)" % [path, str(err)])
        return false
    print("LawImporter: saved %s" % path)
    return true
