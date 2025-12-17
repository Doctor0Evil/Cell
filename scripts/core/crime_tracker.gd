extends Node
class_name CrimeTracker

@export var law_system: LawSystem

func report_crime(crime_tag: StringName, offenders: Array[Node]) -> void:
    law_system.recent_crimes[crime_tag] = int(law_system.recent_crimes.get(crime_tag, 0)) + 1
    DebugLog.log("CrimeTracker", "CRIME", {
        "tag": crime_tag,
        "offender_count": offenders.size()
    })
    _apply_immediate_karmic_checks(crime_tag, offenders)

func _apply_immediate_karmic_checks(crime_tag: StringName, offenders: Array[Node]) -> void:
    if crime_tag == &"cannibalism":
        var chance := 0.01 # 1% direct “wild card”
        if randf() < chance:
            for npc in offenders:
                if not npc.has_method("apply_status_affliction"):
                    continue
                npc.apply_status_affliction(&"flesh_eating_disease", {
                    "severity": 0.7,
                    "contagious": true
                })
            DebugLog.log("CrimeTracker", "KARMA_PLAGUE", {
                "crime": crime_tag,
                "offenders": offenders.size()
            })
