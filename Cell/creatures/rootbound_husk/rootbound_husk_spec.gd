# File: res://cell/creatures/rootbound_husk/rootbound_husk_spec.gd

extends Node
const CellCreatureSpec := preload("res://cell/creatures/cell_creature_spec.gd")


func create_rootbound_husk_spec() -> CellCreatureSpec:
	var spec := CellCreatureSpec.new()

	spec.core = {
		"creature_id": "cell_rootbound_husk_001",
		"name": "Rootbound Husk",
		"classification": "aberrant",
		"origin_zone": "subroot_corridor",
		"threat_level": 4,
		"rarity": "uncommon"
	}

	spec.visual = {
		"style_tags": ["survival_horror", "biopunk", "low_key_lighting"],
		"color_palette": ["#2A1E1E", "#6C0000", "#3B3B3B", "#1A0F0F"],
		"dominant_shapes": ["skeletal_torso", "exposed_muscle", "root_tendrils_head", "elongated_clawed_hands"],
		"lighting": "backlit_bioluminescent",
		"pose_archetypes": ["idle_brood", "lunge_attack", "hanging_in_corridor"],
		"environment_hint": "narrow_blood_slick_corridor_choked_with_roots"
	}

	spec.model3d = {
		"rig_type": "biped_mutated",
		"scale_category": "human_plus",
		"animation_states": ["idle", "stalk", "attack_heavy", "attack_grab", "wall_emerge", "death_collapse"],
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
		"sound_profile": ["wet_clicking", "root_tear", "distant_heartbeat_drum"],
		"interaction_flags": ["can_immobilize", "bleeds_on_hit", "lingering_blood_hazard"],
		"death_trigger": "collapse_into_blood_pool_and_roots"
	}

	spec.lore = {
		"short_hook": "It is what happens when the station remembers having a spine.",
		"origin_brief": "The Rootbound Husk formed where ruptured life-support lines bled into the subroot corridors, fusing corpses with the invasive root-structure. Its anatomy is half remembered human, half invasive infrastructure.",
		"scientific_note": "Designated Aberrant-Root IV. Tissue samples display hybridized vascular systems, with circulatory channels diverted into non-human root matrices. Movement appears driven by pressure waves propagating through the surrounding root network.",
		"myth_fragment": "Technicians insist that when it drags itself past, the corridor lights dim in time with its heartbeat."
	}

	spec.gameplay = {
		"damage_type": ["laceration", "corrosive_blood"],
		"special_mechanics": ["immobilize_on_grab", "hazardous_corpse_blood_pool"],
		"counterplay_hint": "Keep distance and avoid standing in blood; its reach spikes when anchored in pooled fluid.",
		"loot_table_id": "loot_root_aberrant_tier2",
		"spawn_tier": 2
	}

	spec.compliance = {
		"attribution_hash": "<SHA256_ROOTBOUND_HUSK>",
		"contributor_did": "did:web:perplexity.cell/artist_rootbound",
		"pipeline_stamp": "git:rootbound_husk@<commit_hash>",
		"license_anchor": "CELL-COMMONS-1.0",
		"invisible_tags": ["CELL_UNIVERSE", "ASSET_CLASS_CREATURE", "ROOTBOUND_SERIES"],
		"rollback_enabled": true,
		"audit_trail_ref": "tx:fetch:rootbound_husk_initial_gen"
	}

	return spec
