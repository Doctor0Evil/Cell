# File: res://scripts/core/skill_registry.gd
extends Resource
class_name SkillRegistry

# pack_id -> SkillTree
@export var trees: Dictionary = {}

@export var registry_version: String = "CELL_SKILL_REGISTRY_v1.0"
@export var last_built: String = ""

func build_default_trees() -> void:
	trees.clear()

	# CYBERFROST – cold nanotech, signal, wastecraft
	var frost_pack := SkillPackCyberfrost.new()
	var frost_tree := SkillTree.new()
	# Preferred: use populate_from_pack if SkillTree supports it
	if frost_tree.has_method("populate_from_pack"):
		frost_tree.populate_from_pack(SkillPackCyberfrost.PACK_ID, frost_pack.build_skills())
	else:
		frost_tree.skills = frost_pack.build_skills()
	frost_tree.links = {
		"CRYO_SYSTEMS": ["OXYGEN_EFFICIENCY_CF"],
		"OXYGEN_EFFICIENCY_CF": ["CRYOGENIC_RESILIENCE"]
	}
	trees[SkillPackCyberfrost.PACK_ID] = frost_tree

	# ASHVEIL – corpse economies, brutal survival
	var ash_pack := SkillPackAshveil.new()
	var ash_tree := SkillTree.new()
	if ash_tree.has_method("populate_from_pack"):
		ash_tree.populate_from_pack(SkillPackAshveil.PACK_ID, ash_pack.build_skills())
	else:
		ash_tree.skills = ash_pack.build_skills()
	ash_tree.links = {
		"RATION_SCAVENGER": ["CORPSE_RECLAIMER"],
		"CORPSE_RECLAIMER": ["ADAPTIVE_MUTATION"]
	}
	trees[SkillPackAshveil.PACK_ID] = ash_tree

	# IRON_HOLLOW – biomechanical weaponry
	var iron_pack := SkillPackIronHollow.new()
	var iron_tree := SkillTree.new()
	if iron_tree.has_method("populate_from_pack"):
		iron_tree.populate_from_pack(SkillPackIronHollow.PACK_ID, iron_pack.build_skills())
	else:
		iron_tree.skills = iron_pack.build_skills()
	iron_tree.links = {
		"BONEGRINDER": ["PULSE_CANNON"],
		"PULSE_CANNON": ["NANITE_OVERDRIVE"]
	}
	trees[SkillPackIronHollow.PACK_ID] = iron_tree

	# RED_SILENCE – psychological degradation, AI bleed
	var red_pack := SkillPackRedSilence.new()
	var red_tree := SkillTree.new()
	if red_tree.has_method("populate_from_pack"):
		red_tree.populate_from_pack(SkillPackRedSilence.PACK_ID, red_pack.build_skills())
	else:
		red_tree.skills = red_pack.build_skills()
	red_tree.links = {
		"HALLUCINATION_RESISTANCE": ["AI_OVERRIDE"],
		"AI_OVERRIDE": ["MINDFRACTURE"]
	}
	trees[SkillPackRedSilence.PACK_ID] = red_tree

	# COLD_VERGE – exosuit survival, void walking
	var cold_pack := SkillPackColdVerge.new()
	var cold_tree := SkillTree.new()
	if cold_tree.has_method("populate_from_pack"):
		cold_tree.populate_from_pack(SkillPackColdVerge.PACK_ID, cold_pack.build_skills())
	else:
		cold_tree.skills = cold_pack.build_skills()
	cold_tree.links = {
		"THERMAL_REGULATOR": ["LOX_BOTTLE_MASTERY"],
		"LOX_BOTTLE_MASTERY": ["VOID_ENDURANCE"]
	}
	# Note: 'LOX_BOTTLE_MASTERY' replaces the older 'OXYGEN_CAPSULE_MASTERY' skill id to reflect LOX bottle system.
	trees[SkillPackColdVerge.PACK_ID] = cold_tree

	last_built = Time.get_datetime_string_from_system()
	DebugLog.log("SkillRegistry", "BUILD_DEFAULT_TREES", {
		"trees_count": trees.size(),
		"version": registry_version,
		"timestamp": last_built
	})


func get_tree(pack_id: String) -> SkillTree:
	if trees.has(pack_id):
		return trees[pack_id]
	return null


func list_all_trees() -> Array:
	return trees.keys()


func has_tree(pack_id: String) -> bool:
	return trees.has(pack_id)
