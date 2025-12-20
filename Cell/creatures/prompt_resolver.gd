# File: res://cell/creatures/prompt_resolver.gd
# Hydrates {variables} from a CellCreatureSpec into concrete prompts.

extends Node

const CellCreatureSpec := preload("res://cell/creatures/cell_creature_spec.gd")


func _fmt_list(list: Array) -> String:
	return ", ".join(list)


func resolve_2d_prompt(spec: CellCreatureSpec, template: String) -> String:
	var v := spec.visual
	var m := spec.model3d
	var c := spec.core

	var map := {
		"{classification}": c.classification,
		"{name}": c.name,
		"{dominant_shapes}": _fmt_list(v.dominant_shapes),
		"{texture_style}": m.texture_style,
		"{color_palette}": _fmt_list(v.color_palette),
		"{lighting}": v.lighting,
		"{environment_hint}": v.environment_hint
	}

	var result := template
	for k in map.keys():
		result = result.replace(k, str(map[k]))
	return result


func resolve_3d_prompt(spec: CellCreatureSpec, template: String) -> String:
	var c := spec.core
	var v := spec.visual
	var m := spec.model3d
	var b := spec.behavior

	var map := {
		"{name}": c.name,
		"{classification}": c.classification,
		"{rig_type}": m.rig_type,
		"{scale_category}": m.scale_category,
		"{dominant_shapes}": _fmt_list(v.dominant_shapes),
		"{movement_style}": b.movement_style,
		"{archetype}": b.archetype,
		"{animation_states}": _fmt_list(m.animation_states),
		"{texture_style}": m.texture_style,
		"{color_palette}": _fmt_list(v.color_palette)
	}

	var result := template
	for k in map.keys():
		result = result.replace(k, str(map[k]))
	return result


func resolve_lore_prompt(spec: CellCreatureSpec, template: String) -> String:
	var c := spec.core
	var b := spec.behavior

	var map := {
		"{creature_id}": c.creature_id,
		"{name}": c.name,
		"{classification}": c.classification,
		"{origin_zone}": c.origin_zone,
		"{threat_level}": str(c.threat_level),
		"{archetype}": b.archetype
	}

	var result := template
	for k in map.keys():
		result = result.replace(k, str(map[k]))
	return result
