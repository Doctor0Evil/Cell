# File: res://cell/creatures/templates/cell_creature_template.gd
# Generic template equivalent to cell_creature.sai.

extends Node

const CellCreatureSpec := preload("res://cell/creatures/cell_creature_spec.gd")
const CellCreatureGenerationConfig := preload("res://cell/creatures/creature_generation_config.gd")


func create_template_spec() -> CellCreatureSpec:
	var spec := CellCreatureSpec.new()

	spec.core = {
		"creature_id": "cell_xxx_001",
		"name": "TEMP_NAME",
		"classification": "aberrant",
		"origin_zone": "subroot_corridor",
		"threat_level": 4,
		"rarity": "uncommon"
	}

	spec.visual = {
		"style_tags": ["survival_horror", "biopunk", "low_key_lighting"],
		"color_palette": ["#2A1E1E", "#6C0000", "#3B3B3B"],
		"dominant_shapes": ["elongated_limbs", "root_growths", "skeletal_torso"],
		"lighting": "backlit_bioluminescent",
		"pose_archetypes": ["idle_brood", "lunge_attack", "emergent_from_wall"],
		"environment_hint": "enclosed_organic_corridor"
	}

	spec.model3d = {
		"rig_type": "biped_mutated",
		"scale_category": "human_plus",
		"animation_states": ["idle", "patrol", "attack_heavy", "attack_grab", "death_collapse", "emerge_wall"],
		"collision_profile": "multi_limb_soft_shell",
		"texture_style": "photobashed_gore_handpainted_roots",
		"lod": ["high", "medium", "low"],
		"export_formats": ["FBX", "GLTF"]
	}

	spec.behavior = {
		"archetype": "stalker_ambush",
		"aggression_range": "short",
		"movement_style": "jerky_pulsed",
		"pack_behavior": "solitary",
		"sound_profile": ["wet_clicking", "low_root_grind", "distant_pulse"],
		"interaction_flags": ["can_immobilize", "bleeds_on_hit"],
		"death_trigger": "collapse_into_root_pile"
	}

	spec.lore = {
		"short_hook": "It grows where the station bleeds.",
		"origin_brief": "Emerged after containment failure in the lower root corridors...",
		"scientific_note": "Catalogued as Aberrant-Root Class IV. Tissue appears fused with station infrastructure.",
		"myth_fragment": "Workers say you can hear it breathing through the walls hours before it arrives."
	}

	spec.gameplay = {
		"damage_type": ["laceration", "corrosive_blood"],
		"special_mechanics": ["immobilize_on_grab", "hazardous_corpse_blood_pool"],
		"counterplay_hint": "Avoid narrow corridors; use elevation and ranged weapons.",
		"loot_table_id": "loot_root_aberrant_tier2",
		"spawn_tier": 2
	}

	spec.compliance = {
		"attribution_hash": "<SHA256_PLACEHOLDER>",
		"contributor_did": "did:web:perplexity.cell/contributor_x",
		"pipeline_stamp": "git:<commit_hash>@<timestamp>",
		"license_anchor": "CELL-COMMONS-1.0",
		"invisible_tags": ["CELL_UNIVERSE", "ASSET_CLASS_CREATURE", "NON_DERIVATIVE_ENFORCED"],
		"rollback_enabled": true,
		"audit_trail_ref": "tx:fetch:<tx_id_or_log_ref>"
	}

	return spec


func create_template_generation_config() -> CellCreatureGenerationConfig:
	var cfg := CellCreatureGenerationConfig.new()

	cfg.input = {
		"source_spec_path": "assets/creatures/cell_xxx_001/creature.sai",
		"output_namespace": "cell.creatures.cell_xxx_001"
	}

	cfg.targets = {
		"generate_2d_concepts": true,
		"generate_3d_prompt": true,
		"generate_lore": true
	}

	cfg.constraints = {
		"universe": "CELL_CORE_CANON",
		"style_lock": ["survival_horror", "biopunk", "low_key_lighting"],
		"prohibited_motifs": ["heroic_power_fantasy", "bright_color_fantasy", "cartoon_cute"],
		"asset_requirements": ["32bit_png", "premultiplied_alpha", "deterministic_draw_order"],
		"rights_enforcement": ["invisible_attribution", "non_derivative_guardrails"]
	}

	cfg.generator = {
		"two_d": {
			"views": [
				{
					"name": "front_idle",
					"pose": "idle_brood",
					"background": "enclosed_organic_corridor"
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
