extends Resource
class_name SkillPackAshveil

const PACK_ID := "ASHVEIL"

func build_skills() -> Array[SkillDefinition]:
	var skills: Array[SkillDefinition] = []

	# RATION_SCAVENGER – Yield + Instinct: more ration-chips / food salvage
	var ration := SkillDefinition.new()
	ration.id = "RATION_SCAVENGER"
	ration.display_name = "Ration Scavenger"
	ration.description = "You know where the bodies and lockers are that nobody claimed. Increases chance to find ration-chips in ruined barracks and command posts."
	ration.max_rank = 5
	ration.instinct_weight = 0.3
	ration.yield_weight = 0.5
	ration.luck_weight = 0.2 if ration.has_meta("luck_weight") else 0.0
	skills.append(ration)

	# CORPSE_RECLAIMER – Yield + Temper: corpse-looting oxygen / food
	var corpse := SkillDefinition.new()
	corpse.id = "CORPSE_RECLAIMER"
	corpse.display_name = "Corpse Reclaimer"
	corpse.description = "Harvest oxygen capsules and ration fragments from the dead before the station eats them."
	corpse.max_rank = 5
	corpse.yield_weight = 0.5
	corpse.instinct_weight = 0.25
	corpse.temper_weight = 0.25
	skills.append(corpse)

	# ADAPTIVE_MUTATION – Vitality + Tenacity + Temper (risk)
	var mut := SkillDefinition.new()
	mut.id = "ADAPTIVE_MUTATION"
	mut.display_name = "Adaptive Mutation"
	mut.description = "Nanothermal scars and cell shifts turn trauma into raw power. Survival at the cost of what you used to be."
	mut.max_rank = 3
	mut.vitality_weight = 0.35
	mut.tenacity_weight = 0.35
	mut.temper_weight = 0.3
	skills.append(mut)

	# OXYGEN_EFFICIENCY – Logic + Yield + Tenacity: exosuit O2
	var oxy := SkillDefinition.new()
	oxy.id = "OXYGEN_EFFICIENCY_AV"
	oxy.display_name = "Oxygen Efficiency"
	oxy.description = "You squeeze every usable breath from cracked tanks and cheap capsules."
	oxy.max_rank = 5
	oxy.logic_weight = 0.35
	oxy.yield_weight = 0.4
	oxy.tenacity_weight = 0.25
	skills.append(oxy)

	# FEAR_RESISTANCE – Temper + Instinct: slows Wellness loss under hordes
	var fear := SkillDefinition.new()
	fear.id = "FEAR_RESISTANCE"
	fear.display_name = "Fear Resistance"
	fear.description = "You've seen enough mass graves that one more doesn't move the needle much."
	fear.max_rank = 5
	fear.temper_weight = 0.5
	fear.instinct_weight = 0.3
	fear.influence_weight = 0.2
	skills.append(fear)

	return skills
