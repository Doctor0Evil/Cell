extends Node
class_name SpeechCheckEvaluator

@export var vitality: Node      # PlayerVitalitySystem
@export var trait_system: Node  # CellTraitsRegistry
@export var fracture_system: Node
@export var buff_system: Node

var rng := RandomNumberGenerator.new()
var context: Dictionary = {}

func set_context(ctx: Dictionary) -> void:
	context = ctx.duplicate()

func _ready() -> void:
	rng.randomize()

func roll_speech_check(check: Dictionary) -> Dictionary:
	# Support two check styles:
	# - speech_skill style (subtype/attribute/difficulty)
	# - stat style: {"type":"stat","stat":"vitality","difficulty":12}
	if str(check.get("type", "")).to_lower() == "stat":
		var stat := StringName(check.get("stat", "vitality"))
		var difficulty := int(check.get("difficulty", 10))
		var base := _get_stat_value(stat)
		var roll := rng.randi_range(1, 20)
		var total := base + roll
		var success := total >= difficulty
		return {
			"type": "stat",
			"stat": stat,
			"difficulty": difficulty,
			"base": base,
			"roll": roll,
			"total": total,
			"success": success
		}

	var subtype := StringName(check.get("subtype", ""))
	var attribute := StringName(check.get("attribute", "Influence"))
	var difficulty := int(check.get("difficulty", 10))
	var allowed_mods: Array = check.get("mods", ["trait", "consumable", "fracture"])

	var base := _get_base_attribute(attribute)
	var mod := 0.0

	if "trait" in allowed_mods:
		mod += _get_trait_mod(subtype)
	if "fracture" in allowed_mods:
		mod += _get_fracture_mod(subtype)
	if "consumable" in allowed_mods:
		mod += _get_buff_mod(subtype)

	var roll := rng.randi_range(1, 20)
	var total := base + mod + roll
	var success := total >= difficulty

	return {
		"subtype": subtype,
		"attribute": attribute,
		"difficulty": difficulty,
		"base": base,
		"mod": mod,
		"roll": roll,
		"total": total,
		"success": success
	}

func _get_base_attribute(attr: StringName) -> float:
	# Try player context first
	if context.has("player"):
		var p := context["player"]
		if p and p.has_method("get_attribute"):
			return float(p.get_attribute(str(attr)))
	# fallback to vitality system
	if vitality == null:
		return 0.0
	if vitality.has_method("influence") and str(attr).to_lower() == "influence":
		return vitality.influence
	if vitality.has_method("get_attribute"):
		return float(vitality.get_attribute(str(attr)))
	return 0.0

func _get_trait_mod(subtype: StringName) -> float:
	if trait_system == null:
		return 0.0
	var sum := 0.0
	if trait_system.has_method("get_active_traits"):
		for t in trait_system.get_active_traits():
			if t is Dictionary and t.has("narrativetags"):
				if subtype in t["narrativetags"]:
					sum += 2.0
	return sum

func _get_fracture_mod(subtype: StringName) -> float:
	if fracture_system == null:
		return 0.0
	var sum := 0.0
	if fracture_system.has_method("get_active_fractures"):
		for f in fracture_system.get_active_fractures():
			if f is Dictionary and f.has("tags"):
				if subtype in f["tags"]:
					sum += 1.0
	return sum

func _get_buff_mod(subtype: StringName) -> float:
	if buff_system == null:
		return 0.0
	var sum := 0.0
	if buff_system.has_method("get_active_buffs"):
		for b in buff_system.get_active_buffs():
			if not b.has("tags"):
				continue
			var tags: Array = b["tags"]
			if "SPEECH_BOOST" in tags:
				sum += float(b.get("speech_bonus", 0.0))
			if "CHEM_NERVE" in tags and subtype == "INTIMIDATION":
				sum += float(b.get("intimidation_bonus", 0.0))
			if "CHEM_EMPATH" in tags and subtype == "EMPATHY":
				sum += float(b.get("empathy_bonus", 0.0))
	return sum
