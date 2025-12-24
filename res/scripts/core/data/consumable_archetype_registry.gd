extends Resource
class_name ConsumableArchetypeRegistry

# Minimal archetype registry used to spawn ConsumableDefinition resources from
# small archetype identifiers and lightweight override dictionaries.
# Author: GitHub Copilot (Raptor mini (Preview))

const ARCHETYPES = {
	"OXY_CAPSULE": {
		"base_deltas": {"oxygen_delta": 35.0, "wellness_delta": -2.0, "vitality_delta": -0.05},
		"addiction_channel": "OXYGEN",
		"withdrawal_template": "oxygen_chem_loop",
		"safe_stack": 3,
		"tags": ["oxygen", "chem", "survival"]
	},
	"STIM_INJECT": {
		"base_deltas": {"stamina_delta": 40.0, "agility_delta": 0.5, "blood_delta": -8.0},
		"addiction_channel": "STIM",
		"withdrawal_template": "stim_crash",
		"safe_stack": 1,
		"tags": ["chem_stim", "speed_boost"]
	},
	"RATION_HEAVY": {
		"base_deltas": {"protein_delta": 15.0, "water_delta": 20.0, "temper_delta": -0.1},
		"addiction_channel": "RATION",
		"withdrawal_template": "ration_dependence",
		"safe_stack": 5,
		"tags": ["food", "ration"]
	},
	"SED_PILL": {
		"base_deltas": {"wellness_delta": 25.0, "logic_delta": 0.4, "agility_delta": -0.2},
		"addiction_channel": "SEDATIVE",
		"withdrawal_template": "sed_withdrawal",
		"safe_stack": 4,
		"tags": ["chem_sedative", "pain_suppress"]
	}
}

static func resolve_archetype(id: StringName) -> Dictionary:
	return ARCHETYPES.get(id, {})

# Create a ConsumableDefinition from an archetype id and optional overrides.
# Overrides accepts any AssetDefinition/ConsumableDefinition fields keyed as strings.
static func make_consumable_from_archetype(archetype_id: StringName, overrides: Dictionary = {}) -> ConsumableDefinition:
	var arch := resolve_archetype(archetype_id)
	if arch.empty():
		push_warning("ConsumableArchetypeRegistry: unknown archetype '%s'." % archetype_id)
		return null

	var c := ConsumableDefinition.new()
	# Basic wiring
	c.category = &"consumable"
	c.rarity = &"common"
	c.max_stack = int(arch.get("safe_stack", 1))
	c.tags = []

	# Apply base deltas
	var base := arch.get("base_deltas", {})
	for k in base.keys():
		if c.has_property(k):
			c.set(k, base[k])

	# Attach archetype tags
	if arch.has("tags"):
		for t in arch["tags"]:
			c.tags.append(StringName(t))

	# Add addiction / withdrawal as tags for systems to pick up
	if arch.has("addiction_channel"):
		c.tags.append(StringName("addiction:" + str(arch["addiction_channel"])))
	if arch.has("withdrawal_template"):
		c.tags.append(StringName("withdrawal:" + str(arch["withdrawal_template"])))

	# Override fields provided by caller
	for k in overrides.keys():
		var v := overrides[k]
		if c.has_property(k):
			c.set(k, v)
		elif k == "tags" and typeof(v) == TYPE_ARRAY:
			for t in v:
				c.tags.append(StringName(t))
		else:
			# store unknowns as tags to avoid losing data
			c.tags.append(StringName("meta:" + str(k) + "=" + str(v)))

	return c
