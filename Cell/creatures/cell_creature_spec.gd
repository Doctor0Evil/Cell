# File: res://cell/creatures/cell_creature_spec.gd
# Canonical CELL creature spec model in GDScript.

class_name CellCreatureSpec
extends Resource

# Core blocks as typed dictionaries for flexibility and JSON bridging.
var core: Dictionary = {
	"creature_id": "",
	"name": "",
	"classification": "",
	"origin_zone": "",
	"threat_level": 1,
	"rarity": ""
}

var visual: Dictionary = {
	"style_tags": [],
	"color_palette": [],
	"dominant_shapes": [],
	"lighting": "",
	"pose_archetypes": [],
	"environment_hint": ""
}

var model3d: Dictionary = {
	"rig_type": "",
	"scale_category": "",
	"animation_states": [],
	"collision_profile": "",
	"texture_style": "",
	"lod": [],
	"export_formats": []
}

var behavior: Dictionary = {
	"archetype": "",
	"aggression_range": "",
	"movement_style": "",
	"pack_behavior": "",
	"sound_profile": [],
	"interaction_flags": [],
	"death_trigger": ""
}

var lore: Dictionary = {
	"short_hook": "",
	"origin_brief": "",
	"scientific_note": "",
	"myth_fragment": ""
}

var gameplay: Dictionary = {
	"damage_type": [],
	"special_mechanics": [],
	"counterplay_hint": "",
	"loot_table_id": "",
	"spawn_tier": 1
}

var compliance: Dictionary = {
	"attribution_hash": "",
	"contributor_did": "",
	"pipeline_stamp": "",
	"license_anchor": "",
	"invisible_tags": [],
	"rollback_enabled": false,
	"audit_trail_ref": ""
}


func to_dict() -> Dictionary:
	return {
		"core": core,
		"visual": visual,
		"model3d": model3d,
		"behavior": behavior,
		"lore": lore,
		"gameplay": gameplay,
		"compliance": compliance
	}


static func from_dict(data: Dictionary) -> CellCreatureSpec:
	var spec := CellCreatureSpec.new()
	if data.has("core"): spec.core = data.core
	if data.has("visual"): spec.visual = data.visual
	if data.has("model3d"): spec.model3d = data.model3d
	if data.has("behavior"): spec.behavior = data.behavior
	if data.has("lore"): spec.lore = data.lore
	if data.has("gameplay"): spec.gameplay = data.gameplay
	if data.has("compliance"): spec.compliance = data.compliance
	return spec
