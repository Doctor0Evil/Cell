extends Node
class_name CellHorrorArtPipelineMentor

var personality := {
	"Calm":0.78,
	"Methodical":0.9,
	"Supportive":0.7,
	"Cunning":0.35,
	"Cruel":0.02,
	"Nihilistic":0.08
}

func get_personality_vector() -> Dictionary:
	return personality.duplicate(true)

func get_pipeline_steps() -> Array:
	return [
		"Define region, faction, and survival function for each asset batch.",
		"Blockout shapes and layout in low-fidelity (2D tiles or simple 3D geo).",
		"Iterate on mood: lighting, palette, fog, and readability in darkness.",
		"Detail surfaces with industrial wear, cold damage, and subtle body-scale cues (no gore by default).",
		"Prepare assets for Godot import (naming, pivots, atlases, LODs).",
		"Integrate into scenes / TileMaps, wire interactions, and test V.I.T.A.L.I.T.Y. affordances.",
		"Profile performance and memory; finalize packs and document usage."
	]

func get_folder_structure_root() -> Dictionary:
	return {
		"res/ASSETS": [
			"CHARACTERS",
			"ENVIRONMENTS",
			"PROPS",
			"UI",
			"SFX",
			"MUSIC",
			"SHADERS",
			"CC0",
			"CC-BY"
		],
		"res/scenes": [
			"regions",
			"rooms",
			"prefabs",
			"cameras"
		],
		"res/scripts": [
			"ai",
			"systems",
			"tools",
			"effects"
		]
	}

func get_environment_art_tips() -> Array:
	return [
		"Use simple geometry and strong lighting first; tune environment and light before adding fine detail.",
		"Lean on ambient occlusion, fog, and contrast to sculpt space and hide threats just outside visibility.",
		"Always test from the actual game camera and movement speed, not from a pretty editor angle."
	]

func get_character_concept_prompts() -> Array:
	return [
		"Emaciated technician in cracked pressure-suit, visor fogged from inside, limbs slightly misaligned as if bones learned new angles.",
		"Quiet maintenance worker whose tools fused into their hands, illuminated only by failing headlamp and emergency strobes.",
		"Medical responder with obsolete life-support harness, cables trailing like veins, eyes over-dilated from years under artificial night."
	]

func get_night_vision_guidance() -> Dictionary:
	return {
		"godot_hint": "Use a full-screen CanvasLayer with a ColorRect and a green-tinted shader; sample scene color, add noise, vignetting, and bloom for night-vision feel.",
		"refs": [
			"Godot 4 night vision shader tutorials and post-processing guides."
		]
	}