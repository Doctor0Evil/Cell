extends Resource
class_name MedsRegistry

# Centralized, data-driven medical consumables for CELL.
# These are ConsumableDefinition instances that will be added
# into the shared AssetDatabase (res://data/assets/asset_database.tres).

const ANGER_DM_ID: StringName        = &"med_anger_dm"
const STILLWATER_ID: StringName      = &"med_stillwater_t"
const REVIVE9_ID: StringName         = &"med_revive_9"
const OXYPULSE_ID: StringName        = &"med_oxy_pulse_gel"
const SPORECLEANSE_ID: StringName    = &"med_sporecleanse"
const BLACKRUSH_ID: StringName       = &"med_black_rush_iv"
const SYNTHSKIN_ID: StringName       = &"med_synth_skin_patch"
const COOLANTBLOOD_ID: StringName    = &"med_coolant_blood"
const VITALHEXIN_ID: StringName      = &"med_vital_hexin"
const RECALLINE_ID: StringName       = &"med_recalline_amp"

# Utility: build all meds as an Array[ConsumableDefinition]
static func build_all() -> Array:
	var out: Array = []
	out.append(_make_anger_dm())
	out.append(_make_stillwater())
	out.append(_make_revive9())
	out.append(_make_oxy_pulse())
	out.append(_make_sporecleanse())
	out.append(_make_black_rush())
	out.append(_make_synth_skin())
	out.append(_make_coolant_blood())
	out.append(_make_vital_hexin())
	out.append(_make_recalline())
	return out


# --- Anger‑dm -------------------------------------------------------
# Super‑drug: 3x strength/tenacity/agility, loss of control, ally‑aggro risk,
# dialogue lockout, heavy withdrawal and habit‑forming.[file:1][file:2]
static func _make_anger_dm() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = ANGER_DM_ID
	c.display_name = "Anger‑dm"
	c.description = (
		"Combat extremal stimulant. Floods the body with synthetic rage, " +
		"tripling strength, tenacity and agility for a short window while " +
		"shredding peripheral vision, impulse control and post‑dose sanity. " +
		"Often used as a last resort against clustered threats; almost always " +
		"leaves scars on whoever survives the crash."
	)
	c.category = &"consumable"
	c.rarity = &"experimental"
	c.max_stack = 3
	c.weight_kg = 0.05
	c.volume_l = 0.02
	c.base_value_chips = 420
	c.icon_path = "res://assets/icons/meds/anger_dm.png"
	c.world_scene_path = "res://scenes/items/meds/anger_dm.tscn"
	c.tags = [&"med", &"combat_stim", &"addictive", &"rage_state"]

	# Instant pools (small physical jolt, big sanity hit handled via effect).[file:2]
	c.blood_delta = 5.0
	c.oxygen_delta = 0.0
	c.stamina_delta = 30.0
	c.wellness_delta = -10.0
	c.body_temp_delta = 0.8
	c.protein_delta = 0.0

	# Attribute spikes: approx “3x” via flat + multipliers in the active effect.[file:2]
	c.vitality_delta = 0.0
	c.instinct_delta = 2.0
	c.tenacity_delta = 3.0
	c.agility_delta = 3.0
	c.logic_delta = -3.0
	c.influence_delta = -2.0
	c.temper_delta = 3.0
	c.yield_delta = 0.0

	# Applied timed effects (status system must resolve these IDs).[file:2]
	c.applied_effect_ids = [
		&"eff_anger_dm_rage_active",      # +melee damage, +move speed, tunnel vision, no dialog
		&"eff_anger_dm_allied_friendly_fire", # periodic ally‑aggro checks during combat only
		&"eff_anger_dm_addiction_risk"    # long‑term habit + withdrawal template
	]
	c.min_yield_required = 3.0
	c.safe_stack_limit = 1

	c.pickup_sfx_id = &"sfx_pick_med_vial"
	c.use_sfx_id = &"sfx_injector_heavy"

	return c


# --- Stillwater‑T ---------------------------------------------------
static func _make_stillwater() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = STILLWATER_ID
	c.display_name = "Stillwater‑T"
	c.description = (
		"Slow‑release neurodepressant threaded with station‑grade nanofilters. " +
		"Flattens panic spikes and quiets intrusive signals long enough to " +
		"talk, patch wounds, or reset from a spiral."
	)
	c.category = &"consumable"
	c.rarity = &"rare"
	c.max_stack = 5
	c.weight_kg = 0.04
	c.volume_l = 0.015
	c.base_value_chips = 160
	c.icon_path = "res://assets/icons/meds/stillwater_t.png"
	c.world_scene_path = "res://scenes/items/meds/stillwater_t.tscn"
	c.tags = [&"med", &"sedative", &"sanity_up"]

	c.blood_delta = 0.0
	c.oxygen_delta = 0.0
	c.stamina_delta = -5.0
	c.wellness_delta = 8.0
	c.body_temp_delta = -0.2
	c.protein_delta = 0.0

	c.vitality_delta = 0.0
	c.instinct_delta = -1.0
	c.tenacity_delta = 0.0
	c.agility_delta = -1.0
	c.logic_delta = 1.0
	c.influence_delta = 0.0
	c.temper_delta = -1.0
	c.yield_delta = 0.0

	c.applied_effect_ids = [
		&"eff_stillwater_sanity_regen",
		&"eff_stillwater_reaction_penalty"
	]
	c.min_yield_required = 0.0
	c.safe_stack_limit = 2
	c.pickup_sfx_id = &"sfx_pick_med_ampule"
	c.use_sfx_id = &"sfx_pill_dry"
	return c


# --- Revive‑9 Injector ---------------------------------------------
static func _make_revive9() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = REVIVE9_ID
	c.display_name = "Revive‑9 Injector"
	c.description = (
	"Field‑issue auto‑hemo injector that slams reoxygenated plasma and " +
	"coagulants into any port it can find. Designed to drag a body back " +
	"from the edge once, maybe twice, before the vessels give up."
	)
	c.category = &"consumable"
	c.rarity = &"experimental"
	c.max_stack = 2
	c.weight_kg = 0.08
	c.volume_l = 0.03
	c.base_value_chips = 520
	c.icon_path = "res://assets/icons/meds/revive9.png"
	c.world_scene_path = "res://scenes/items/meds/revive9.tscn"
	c.tags = [&"med", &"revive", &"coagulant"]

	c.blood_delta = 60.0
	c.oxygen_delta = 10.0
	c.stamina_delta = 20.0
	c.wellness_delta = -5.0
	c.body_temp_delta = 0.3
	c.protein_delta = -5.0

	c.vitality_delta = 0.0
	c.instinct_delta = 0.0
	c.tenacity_delta = 1.0
	c.agility_delta = -1.0
	c.logic_delta = 0.0
	c.influence_delta = 0.0
	c.temper_delta = 0.0
	c.yield_delta = 0.0

	c.applied_effect_ids = [
		&"eff_revive9_cardiac_shock_risk",
		&"eff_revive9_suit_autoseal_pulse"
	]
	c.min_yield_required = 2.0
	c.safe_stack_limit = 1
	c.pickup_sfx_id = &"sfx_pick_med_injector"
	c.use_sfx_id = &"sfx_injector_fast"
	return c


# --- Oxy‑Pulse Gel -------------------------------------------------
static func _make_oxy_pulse() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = OXYPULSE_ID
	c.display_name = "Oxy‑Pulse Gel"
	c.description = (
		"Thick, metallic gel that blooms into micro‑oxygen bubbles once it hits " +
		"lung tissue. Meant for short, ugly walks through airless corridors."
	)
	c.category = &"consumable"
	c.rarity = &"common"
	c.max_stack = 6
	c.weight_kg = 0.06
	c.volume_l = 0.03
	c.base_value_chips = 90
	c.icon_path = "res://assets/icons/meds/oxy_pulse_gel.png"
	c.world_scene_path = "res://scenes/items/meds/oxy_pulse_gel.tscn"
	c.tags = [&"med", &"oxygen", &"emergency"]

	c.blood_delta = 0.0
	c.oxygen_delta = 80.0
	c.stamina_delta = 0.0
	c.wellness_delta = -2.0
	c.body_temp_delta = -0.1
	c.protein_delta = -2.0

	c.vitality_delta = 0.0
	c.instinct_delta = 0.0
	c.tenacity_delta = 0.0
	c.agility_delta = 0.0
	c.logic_delta = 0.0
	c.influence_delta = 0.0
	c.temper_delta = 0.0
	c.yield_delta = 0.0

	c.applied_effect_ids = [
		&"eff_oxy_pulse_throat_inflammation"
	]
	c.min_yield_required = 0.0
	c.safe_stack_limit = 3
	c.pickup_sfx_id = &"sfx_pick_med_canister"
	c.use_sfx_id = &"sfx_gel_squeeze"
	return c


# --- Sporecleanse Ampule -------------------------------------------
static func _make_sporecleanse() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = SPORECLEANSE_ID
	c.display_name = "Sporecleanse Ampule"
	c.description = (
		"Corrosive antifungal cocktail tuned to the station's rot strains. " +
		"Strips infections out of blood and suit filters, taking a layer of " +
		"strength with it."
	)
	c.category = &"consumable"
	c.rarity = &"rare"
	c.max_stack = 4
	c.weight_kg = 0.05
	c.volume_l = 0.02
	c.base_value_chips = 230
	c.icon_path = "res://assets/icons/meds/sporecleanse.png"
	c.world_scene_path = "res://scenes/items/meds/sporecleanse.tscn"
	c.tags = [&"med", &"antifungal", &"detox"]

	c.blood_delta = -5.0
	c.oxygen_delta = 0.0
	c.stamina_delta = -10.0
	c.wellness_delta = 15.0
	c.body_temp_delta = 0.0
	c.protein_delta = -4.0

	c.vitality_delta = 0.0
	c.instinct_delta = 0.0
	c.tenacity_delta = -1.0
	c.agility_delta = 0.0
	c.logic_delta = 0.0
	c.influence_delta = 0.0
	c.temper_delta = 0.0
	c.yield_delta = 0.0

	c.applied_effect_ids = [
		&"eff_sporecleanse_purge_infection"
	]
	c.min_yield_required = 2.0
	c.safe_stack_limit = 2
	c.pickup_sfx_id = &"sfx_pick_med_ampule"
	c.use_sfx_id = &"sfx_injector_slow"
	return c


# --- Black‑Rush IV -------------------------------------------------
static func _make_black_rush() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = BLACKRUSH_ID
	c.display_name = "Black‑Rush IV"
	c.description = (
		"Back‑deck nanoboost brewed from discarded lab routines. Sharpens " +
		"reflexes and limb tracking while punching small holes in reality " +
		"around the user."
	)
	c.category = &"consumable"
	c.rarity = &"experimental"
	c.max_stack = 3
	c.weight_kg = 0.07
	c.volume_l = 0.025
	c.base_value_chips = 310
	c.icon_path = "res://assets/icons/meds/black_rush_iv.png"
	c.world_scene_path = "res://scenes/items/meds/black_rush_iv.tscn"
	c.tags = [&"med", &"stimulant", &"hallucinogenic"]

	c.blood_delta = 0.0
	c.oxygen_delta = 0.0
	c.stamina_delta = 25.0
	c.wellness_delta = -6.0
	c.body_temp_delta = 0.5
	c.protein_delta = 0.0

	c.vitality_delta = 0.0
	c.instinct_delta = 2.0
	c.tenacity_delta = 1.0
	c.agility_delta = 2.0
	c.logic_delta = -1.0
	c.influence_delta = 0.0
	c.temper_delta = 1.0
	c.yield_delta = 0.0

	c.applied_effect_ids = [
		&"eff_black_rush_reflex_boost",
		&"eff_black_rush_visual_hallucinations",
		&"eff_black_rush_sanity_bleed"
	]
	c.min_yield_required = 3.0
	c.safe_stack_limit = 2
	c.pickup_sfx_id = &"sfx_pick_med_injector"
	c.use_sfx_id = &"sfx_injector_click"
	return c


# --- SynthSkin Patch -----------------------------------------------
static func _make_synth_skin() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = SYNTHSKIN_ID
	c.display_name = "SynthSkin Patch"
	c.description = (
		"Peel‑back dermal mesh that clots, knits and seals open tissue. " +
		"Favored in hullside clinics where sutures are too slow and " +
		"infection waits in every draft."
	)
	c.category = &"consumable"
	c.rarity = &"common"
	c.max_stack = 8
	c.weight_kg = 0.02
	c.volume_l = 0.01
	c.base_value_chips = 70
	c.icon_path = "res://assets/icons/meds/synth_skin_patch.png"
	c.world_scene_path = "res://scenes/items/meds/synth_skin_patch.tscn"
	c.tags = [&"med", &"bandage", &"fracture_care"]

	c.blood_delta = 30.0
	c.oxygen_delta = 0.0
	c.stamina_delta = -5.0
	c.wellness_delta = 5.0
	c.body_temp_delta = 0.0
	c.protein_delta = -5.0

	c.vitality_delta = 0.0
	c.instinct_delta = 0.0
	c.tenacity_delta = 0.0
	c.agility_delta = 0.0
	c.logic_delta = 0.0
	c.influence_delta = 0.0
	c.temper_delta = 0.0
	c.yield_delta = 0.0

	c.applied_effect_ids = [
		&"eff_synth_skin_stop_bleeding",
		&"eff_synth_skin_minor_fracture_fix"
	]
	c.min_yield_required = 0.0
	c.safe_stack_limit = 4
	c.pickup_sfx_id = &"sfx_pick_med_patch"
	c.use_sfx_id = &"sfx_bandage_wrap"
	return c


# --- Coolant‑Blood -------------------------------------------------
static func _make_coolant_blood() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = COOLANTBLOOD_ID
	c.display_name = "Coolant‑Blood"
	c.description = (
		"Hybrid hemocoolant circulated through augmented rigs to keep cores " +
		"from cooking. Flesh can drink it too, but it is meant for steel."
	)
	c.category = &"consumable"
	c.rarity = &"rare"
	c.max_stack = 4
	c.weight_kg = 0.09
	c.volume_l = 0.04
	c.base_value_chips = 260
	c.icon_path = "res://assets/icons/meds/coolant_blood.png"
	c.world_scene_path = "res://scenes/items/meds/coolant_blood.tscn"
	c.tags = [&"med", &"coolant", &"cybernetic"]

	c.blood_delta = 10.0
	c.oxygen_delta = 0.0
	c.stamina_delta = 15.0
	c.wellness_delta = 0.0
	c.body_temp_delta = -1.2
	c.protein_delta = -3.0

	c.vitality_delta = 0.0
	c.instinct_delta = 0.0
	c.tenacity_delta = 1.0
	c.agility_delta = 0.0
	c.logic_delta = 0.0
	c.influence_delta = 0.0
	c.temper_delta = 0.0
	c.yield_delta = 0.0

	c.applied_effect_ids = [
		&"eff_coolant_blood_thermal_resist",
		&"eff_coolant_blood_cyborg_malfunction_risk"
	]
	c.min_yield_required = 1.0
	c.safe_stack_limit = 2
	c.pickup_sfx_id = &"sfx_pick_med_canister"
	c.use_sfx_id = &"sfx_liquid_pour"
	return c


# --- Vital‑Hexin Serum ---------------------------------------------
static func _make_vital_hexin() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = VITALHEXIN_ID
	c.display_name = "Vital‑Hexin Serum"
	c.description = (
		"Six‑channel nanomed dose that nudges every failing gauge just above " +
		"catastrophe. Favored by crews who cannot afford a proper medbay."
	)
	c.category = &"consumable"
	c.rarity = &"rare"
	c.max_stack = 3
	c.weight_kg = 0.06
	c.volume_l = 0.025
	c.base_value_chips = 340
	c.icon_path = "res://assets/icons/meds/vital_hexin.png"
	c.world_scene_path = "res://scenes/items/meds/vital_hexin.tscn"
	c.tags = [&"med", &"stabilizer", &"addictive"]

	c.blood_delta = 10.0
	c.oxygen_delta = 10.0
	c.stamina_delta = 10.0
	c.wellness_delta = 10.0
	c.body_temp_delta = 0.0
	c.protein_delta = -4.0

	c.vitality_delta = 1.0
	c.instinct_delta = 0.0
	c.tenacity_delta = 1.0
	c.agility_delta = 0.0
	c.logic_delta = 0.0
	c.influence_delta = 0.0
	c.temper_delta = 0.0
	c.yield_delta = 0.0

	c.applied_effect_ids = [
		&"eff_vital_hexin_brief_overclock",
		&"eff_vital_hexin_addiction_risk"
	]
	c.min_yield_required = 2.0
	c.safe_stack_limit = 2
	c.pickup_sfx_id = &"sfx_pick_med_vial"
	c.use_sfx_id = &"sfx_injector_soft"
	return c


# --- Recalline Ampule ----------------------------------------------
static func _make_recalline() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = RECALLINE_ID
	c.display_name = "Recalline Ampule"
	c.description = (
		"Sharp, bitter ampule used to cut through chem fog and shock. " +
		"Snaps the mind back to serviceable focus at the cost of a small, " +
		"permanent scrape off the edges."
	)
	c.category = &"consumable"
	c.rarity = &"rare"
	c.max_stack = 5
	c.weight_kg = 0.03
	c.volume_l = 0.015
	c.base_value_chips = 190
	c.icon_path = "res://assets/icons/meds/recalline.png"
	c.world_scene_path = "res://scenes/items/meds/recalline.tscn"
	c.tags = [&"med", &"neuro", &"antidote"]

	c.blood_delta = 0.0
	c.oxygen_delta = 0.0
	c.stamina_delta = 5.0
	c.wellness_delta = 4.0
	c.body_temp_delta = 0.1
	c.protein_delta = 0.0

	c.vitality_delta = 0.0
	c.instinct_delta = 0.0
	c.tenacity_delta = 0.0
	c.agility_delta = 0.0
	c.logic_delta = 1.0
	c.influence_delta = 1.0
	c.temper_delta = 0.0
	c.yield_delta = 0.0

	c.applied_effect_ids = [
		&"eff_recalline_clear_confusion",
		&"eff_recalline_dialogue_stabilizer",
		&"eff_recalline_sanity_chip"
	]
	c.min_yield_required = 0.0
	c.safe_stack_limit = 2
	c.pickup_sfx_id = &"sfx_pick_med_ampule"
	c.use_sfx_id = &"sfx_glass_snap"
	return c