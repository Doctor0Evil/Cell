# File: res://tools/pipeline/cell_headless_generate_prompts.gd
# Purpose: Iterate all creature folders, load specs, resolve prompts, and dump .txt payloads.
# Run via: godot4 --headless --path . --script res://tools/pipeline/cell_headless_generate_prompts.gd

extends SceneTree

const CellCreatureGenerationConfig := preload("res://cell/creatures/creature_generation_config.gd")
const CellCreatureSpec := preload("res://cell/creatures/cell_creature_spec.gd")
const PromptResolver := preload("res://cell/creatures/prompt_resolver.gd")
const JsonLoader := preload("res://tools/pipeline/cell_creature_json_loader.gd")

var CREATURES_DIR := "res://assets/creatures"
var SPEC_JSON_NAME := "creature.json"

func _initialize() -> void:
	print("CELL: Headless prompt generation started.")
	_generate_for_all_creatures()
	print("CELL: Headless prompt generation finished.")
	quit()


func _generate_for_all_creatures() -> void:
	var dir := DirAccess.open(CREATURES_DIR)
	if dir == null:
		push_error("CELL: Cannot open creatures dir: %s" % CREATURES_DIR)
		return

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with("."):
			_generate_for_creature(entry)
		entry = dir.get_next()
	dir.list_dir_end()


func _generate_for_creature(creature_id: String) -> void:
	var loader := JsonLoader.new()
	var spec := loader.load_creature_spec(creature_id)
	if spec == null:
		push_warning("CELL: Skipping creature '%s' (no valid spec)." % creature_id)
		return

	var cfg := _build_default_generation_config(creature_id, spec)
	var prompt_resolver := PromptResolver.new()

	var base_dir := "%s/%s" % [CREATURES_DIR, creature_id]
	var two_d_out := "%s/creature_2d_prompt.txt" % base_dir
	var three_d_out := "%s/creature_3d_prompt.txt" % base_dir
	var lore_out := "%s/creature_lore_prompt.txt" % base_dir

	# Initialize to allow bundling later
	var p2d := ""
	var p3d := ""
	var p_lore := ""

	if cfg.targets.generate_2d_concepts:
		var two_d := cfg.generator.two_d
		var p2d := prompt_resolver.resolve_2d_prompt(spec, two_d.prompt_template)
		_store_text(two_d_out, p2d)
		print("CELL: 2D prompt written for %s → %s" % [creature_id, two_d_out])

	if cfg.targets.generate_3d_prompt:
		var three_d := cfg.generator.three_d
		var p3d := prompt_resolver.resolve_3d_prompt(spec, three_d.prompt_template)
		_store_text(three_d_out, p3d)
		print("CELL: 3D prompt written for %s → %s" % [creature_id, three_d_out])

	if cfg.targets.generate_lore:
		var lore_cfg := cfg.generator.lore
		p_lore = prompt_resolver.resolve_lore_prompt(spec, lore_cfg.prompt_template)
		_store_text(lore_out, p_lore)
		print("CELL: Lore prompt written for %s → %s" % [creature_id, lore_out])

	# Create a JSON bundle containing all generated prompts for programmatic consumers
	var json_out := "%s/creature_prompts.json" % base_dir
	var prompts_dict := {
		"two_d": p2d,
		"three_d": p3d,
		"lore": p_lore
	}
	var json_text := JSON.stringify(prompts_dict, "\t")
	_store_text(json_out, json_text)
	print("CELL: JSON prompt bundle written for %s → %s" % [creature_id, json_out])


func _store_text(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("CELL: Failed to write: %s" % path)
		return
	file.store_string(content)
	file.close()


func _build_default_generation_config(creature_id: String, spec: CellCreatureSpec) -> CellCreatureGenerationConfig:
	var cfg := CellCreatureGenerationConfig.new()

	cfg.input = {
		"source_spec_path": "%s/%s/%s" % [CREATURES_DIR, creature_id, SPEC_JSON_NAME],
		"output_namespace": "cell.creatures.%s" % creature_id
	}

	cfg.targets = {
		"generate_2d_concepts": true,
		"generate_3d_prompt": true,
		"generate_lore": true
	}

	cfg.constraints = {
		"universe": "CELL_CORE_CANON",
		"style_lock": spec.visual.get("style_tags", []),
		"prohibited_motifs": [
			"heroic_power_fantasy",
			"bright_color_fantasy",
			"cartoon_cute"
		],
		"asset_requirements": [
			"32bit_png",
			"premultiplied_alpha",
			"deterministic_draw_order"
		],
		"rights_enforcement": [
			"invisible_attribution",
			"non_derivative_guardrails"
		]
	}

	cfg.generator = {
		"two_d": {
			"views": [
				{
					"name": "front_idle",
					"pose": "idle_brood",
					"background": spec.visual.get("environment_hint", "industrial_decay_corridor")
				},
				{
					"name": "attack_lunge",
					"pose": "lunge_attack",
					"background": "tight_corridor_view"
				},
				{
					"name": "emergent",
					"pose": "emergent_from_wall",
					"background": "root_choked_tunnel"
				}
			],
			"prompt_template": """
Highly detailed survival horror concept art of a {classification} creature called {name}.
Visual traits:
- Body: {dominant_shapes}
- Texture: {texture_style}
- Palette: {color_palette}
- Lighting: {lighting}
- Environment: {environment_hint}

Camera focuses on the creature, with clear silhouette readable for production.
No text, no UI, no logos. Consistent with the CELL universe: industrial, decayed, biopunk, hostile.
"""
		},
		"three_d": {
			"prompt_template": """
3D production-ready creature model concept for a game called CELL.
Creature: {name} ({classification}), rigged as {rig_type}, scale {scale_category}.
Key traits: {dominant_shapes}. Movement style: {movement_style}. Behavior: {archetype}.

Output intent:
- Neutral T-pose or A-pose variant suited for animation
- Clear muscle, root, and bone structure readable for rigging
- Support for animation states: {animation_states}
- Texture style: {texture_style}, matching {color_palette}

The model should be practical for survival horror gameplay: optimized forms, clear joints,
readable silhouette, and region separation for gore and root growths.
"""
		},
		"lore": {
			"prompt_template": """
You are writing lore for the survival horror game CELL.

Creature ID: {creature_id}
Name: {name}
Classification: {classification}
Origin zone: {origin_zone}
Threat level: {threat_level} / 5
Behavior archetype: {archetype}

Write:
1. A 1–2 sentence in-universe field log entry.
2. A short scientific classification note (2–3 sentences).
3. A whispered rumor told by workers or survivors (1–2 sentences).
Tone: bleak, clinical yet haunted, no comedy, no meta-references.
Keep it concise and usable directly as in-game text.
"""
		}
	}

	cfg.compliance = {
		"attach_invisible_watermark": true,
		"record_generation_summary": true,
		"log_fields": [
			"creature_id", "name", "contributor_did", "pipeline_stamp",
			"attribution_hash", "license_anchor"
		]
	}

	return cfg
