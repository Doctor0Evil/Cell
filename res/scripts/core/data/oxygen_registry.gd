extends Resource
class_name OxygenRegistry

# Hardware-style oxygen consumables (LOX bottles / cryo cores)
# These are ConsumableDefinition instances intended to be loaded into the AssetDatabase.

const LOX_STD_ID: StringName = &"CON_LOX_CRYO_CORE_STD"
const LOX_EMERGENCY_ID: StringName = &"CON_LOX_CRYO_CORE_EMERGENCY"

static func build_all() -> Array:
	var out: Array = []
	out.append(_make_lox_cryo_core_standard())
	out.append(_make_lox_cryo_core_emergency())
	return out

# Standard Cryo-Core LOX Bottle -- ~160 SL refill (≈25% of a 600 SL suit tank)
static func _make_lox_cryo_core_standard() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = LOX_STD_ID
	c.display_name = "Cryo‑Core LOX Bottle"
	c.description = (
		"Compact, vacuum‑jacketed bottle of liquid oxygen tied into suit feeds. " +
		"Slow boil‑off and regulated feed mean partial refills are possible; " +
		"careful crews top off before long treks into the Cold Verge."
	)
	c.category = &"consumable"
	c.rarity = &"rare"
	c.max_stack = 3
	c.weight_kg = 1.2
	c.volume_l = 3.0
	c.base_value_chips = 240
	c.icon_path = "res://assets/icons/consumables/lox_cryo_core.png"
	c.world_scene_path = "res://scenes/items/consumables/lox_cryo_core.tscn"
	c.tags = [&"oxygen", &"lox", &"life_support", &"LOX_BOTTLE"]

	# This oxygen_delta is expressed in Standard Liters (SL) and will be
	# converted to player oxygen units by the vitality system.
	c.oxygen_delta = 160.0

	# Minimal side effects compared to old capsules.
	c.wellness_delta = -1.0
	c.vitality_delta = -0.01
	c.temper_delta = -0.01

	c.applied_effect_ids = []
	c.min_yield_required = 0.0
	c.safe_stack_limit = 2
	c.pickup_sfx_id = &"sfx_pick_med_canister"
	c.use_sfx_id = &"sfx_liquid_pour"
	return c

# Emergency LOX bottle: small, high-pressure canister for ~480 SL (quick large refill)
static func _make_lox_cryo_core_emergency() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = LOX_EMERGENCY_ID
	c.display_name = "Cryo‑Core LOX (Emergency)"
	c.description = (
		"Insulated high‑pressure cryo bottle. Large refill in an emergency, but risk of boil‑off and suit stress."
	)
	c.category = &"consumable"
	c.rarity = &"experimental"
	c.max_stack = 1
	c.weight_kg = 2.8
	c.volume_l = 4.5
	c.base_value_chips = 560
	c.icon_path = "res://assets/icons/consumables/lox_cryo_core_emerg.png"
	c.world_scene_path = "res://scenes/items/consumables/lox_cryo_core_emerg.tscn"
	c.tags = [&"oxygen", &"lox", &"life_support", &"LOX_BOTTLE", &"emergency"]

	c.oxygen_delta = 480.0

	c.wellness_delta = -2.0
	c.vitality_delta = -0.05
	c.temper_delta = -0.02

	c.applied_effect_ids = [&"eff_lox_large_refill_stress"]
	c.min_yield_required = 0.0
	c.safe_stack_limit = 1
	c.pickup_sfx_id = &"sfx_pick_med_canister"
	c.use_sfx_id = &"sfx_liquid_pour"
	return c