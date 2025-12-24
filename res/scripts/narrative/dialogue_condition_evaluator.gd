extends Node
class_name DialogueConditionEvaluator

@export var trait_registry: Node        # CellTraitsRegistry
@export var respect_system: Node        # CellRespectSystem or FactionSystem
@export var game_state: Node           # GameState autoload
@export var player_vitality: Node      # PlayerVitalitySystem
@export var faction_system: Node       # FactionSystem
@export var fracture_system: Node      # FractureSystem

# Optional runtime context: { "player": Node, "npc": Node, "traits_registry": Resource, "faction_system": Node, "respect_system": Node }
var context: Dictionary = {}

func set_context(ctx: Dictionary) -> void:
	context = ctx.duplicate()

func _has_trait(trait_id: StringName, subject: StringName = &"player") -> bool:
	# subject may be "player", "npc", or an entity Node passed in context
	if subject == StringName("player") and context.has("player"):
		var p := context["player"]
		if p and p.has_method("get_active_trait_ids"):
			return trait_id in p.get_active_trait_ids()
		if p and p.has_meta("traits"):
			return trait_id in p.get_meta("traits")
	if subject == StringName("npc") and context.has("npc"):
		var n := context["npc"]
		if n and n.has("trait_ids"):
			return trait_id in n.trait_ids

	# Fallback: check registry-level presence (not an entity presence check)
	if trait_registry == null:
		return false
	if trait_registry.has_method("has_trait"):
		return trait_registry.has_trait(trait_id)
	if trait_registry.has_method("get_active_trait_ids"):
		return trait_id in trait_registry.get_active_trait_ids()
	return false

func _faction_standing_min(faction: StringName, min_value: float, subject: StringName = &"player") -> bool:
	# subject-aware reservation: check player vs npc
	if subject == StringName("player"):
		if faction_system and faction_system.has_method("get_standing"):
			var standing: float = float(faction_system.get_standing(faction))
			return standing >= min_value
		if respect_system and respect_system.has_method("get_respect_for"):
			var s: float = float(respect_system.get_respect_for(faction))
			return s >= min_value
	if subject == StringName("npc") and context.has("npc"):
		var n := context["npc"]
		if n and n.has("base_faction"):
			if faction_system and faction_system.has_method("get_relation_between"):
				# hypothetical method: get_relation_between(faction_a, faction_b)
				var rel: float = float(faction_system.get_relation_between(n.base_faction, faction))
				return rel >= min_value
	# fallback
	if faction_system and faction_system.has_method("get_standing"):
		var s2 := faction_system.get_standing(faction)
		return s2 >= min_value
	return false

func _flag_check(flag: StringName, expected: bool) -> bool:
	return game_state and game_state.has_method("get_flag") and game_state.get_flag(flag) == expected

func _missing_trait(trait_id: StringName, subject: StringName = &"player") -> bool:
	return not _has_trait(trait_id, subject)

func _respect_range(faction: StringName, min_value: float, max_value: float) -> bool:
	# Check respect standing against a range
	var val := 0.0
	if faction_system and faction_system.has_method("get_standing"):
		val = faction_system.get_standing(faction)
	elif respect_system and respect_system.has_method("get_respect_for"):
		val = respect_system.get_respect_for(faction)
	return val >= min_value and val <= max_value

func _faction_relation_at_least(faction: StringName, relation_label: StringName) -> bool:
	# Map textual relation to numeric threshold
	var thresholds := {"hostile": -100.0, "neutral": 0.0, "friendly": 50.0}
	var t := thresholds.get(str(relation_label).to_lower(), 0.0)
	return _faction_standing_min(faction, t)

func _region_has_tag(tag: StringName) -> bool:
	return game_state and game_state.has_method("current_region_has_tag") and game_state.current_region_has_tag(tag)

func _vitality_threshold(pool: StringName, min_value: float) -> bool:
	if not player_vitality:
		return false
	if player_vitality.has_method("get_pool_value"):
		return player_vitality.get_pool_value(pool) >= min_value
	return false

func evaluate_condition(cond: Dictionary) -> bool:
	var ctype := StringName(cond.get("type", ""))
	# optional subject: "player" or "npc"
	var subject := StringName(cond.get("subject", "player"))
	match ctype:
		"has_trait":
			return _has_trait(StringName(cond.get("value", "")), subject)
		"missing_trait":
			return _missing_trait(StringName(cond.get("value", "")), subject)
		"faction_standing_min":
			return _faction_standing_min(
				StringName(cond.get("faction", "")),
				float(cond.get("standing", 0.0)),
				subject
			)
		"min_respect":
			return _faction_standing_min(
				StringName(cond.get("faction", "")),
				float(cond.get("value", 0.0)),
				subject
			)
		"max_respect":
			return not _faction_standing_min(StringName(cond.get("faction", "")), float(cond.get("value", 0.0)) + 0.0001, subject)
		"faction_relation_at_least":
			return _faction_relation_at_least(StringName(cond.get("faction", "")), StringName(cond.get("relation", "neutral")))
		"flag_check":
			return _flag_check(
				StringName(cond.get("flag", "")),
				bool(cond.get("value", true))
			)
		"region_has_tag":
			return _region_has_tag(StringName(cond.get("tag", "")))
		"vitality_threshold":
			return _vitality_threshold(
				StringName(cond.get("pool", "")),
				float(cond.get("min", 0.0))
			)
		_:
			push_warning("Unknown dialogue condition type: %s" % ctype)
			return false

func filter_choices(raw_choices: Array, ctx: Dictionary = {}) -> Array:
	# ctx may include local context that overrides evaluator.context for this check
	var merged_ctx := context.duplicate() if context else {} 
	for k in ctx.keys():
		merged_ctx[k] = ctx[k]
	var result: Array = []
	for c in raw_choices:
		var ok := true
		for cond in c.conditions:
			# temporarily set context for nested checks
			var prev_ctx := context
			context = merged_ctx
			var cond_ok := evaluate_condition(cond)
			context = prev_ctx
			if not cond_ok:
				ok = false
				break
		if ok:
			result.append(c)
	return result

func apply_effects(effects: Array) -> void:
	for eff in effects:
		var etype := StringName(eff.get("type", ""))
		match etype:
			"respect_delta":
				if faction_system and faction_system.has_method("add_respect_delta"):
					faction_system.add_respect_delta(StringName(eff.get("faction", "")), float(eff.get("value", 0.0)))
				elif respect_system and respect_system.has_method("adjust_respect"):
					respect_system.adjust_respect(StringName(eff.get("faction", "")), float(eff.get("value", 0.0)))
			"disposition_delta":
				if faction_system and faction_system.has_method("add_disposition_delta"):
					faction_system.add_disposition_delta(StringName(eff.get("faction", "")), float(eff.get("value", 0.0)))
			"flag_set":
				if game_state and game_state.has_method("set_flag"):
					game_state.set_flag(StringName(eff.get("flag", "")), bool(eff.get("value", true)))
			"vitality_delta":
				if player_vitality and player_vitality.has_method("apply_dialogue_delta"):
					player_vitality.apply_dialogue_delta(eff)
			"fracture_gain":
				if fracture_system and fracture_system.has_method("add_fracture"):
					fracture_system.add_fracture(StringName(eff.get("fracture_id", "")))
			_:
				push_warning("Unknown dialogue effect type: %s" % etype)
