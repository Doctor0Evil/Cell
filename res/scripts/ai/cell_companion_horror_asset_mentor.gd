extends Node
class_name CellCompanionHorrorAssetMentor

# Central “teacher” brain that explains to an IDE / agent how to build CELL horror assets
# with Godot 4+ and CC0 / CC-BY compatible pipelines.

const LICENSE_CC0 := "CC0"
const LICENSE_CC_BY := "CC-BY"

# Minimal knowledge base the IDE can query.
var kb_categories := {
	"tilesets_godot_4": {
		"doc_urls": [
			"https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html",
			"https://docs.godotengine.org/en/latest/tutorials/2d/using_tilemaps.html"
		],
		"notes": "Use TileSet + TileMapLayer in Godot 4 for 2.5D layouts. Import atlases, configure collisions, navigation, and scene tiles for dynamic objects."
	},
	"licensing_safe_sources": {
		"cc0_horror_assets": [
			"https://itch.io/game-assets/assets-cc0/store/tag-horror"
		],
		"cc0_ambience_examples": [
			"https://www.free-stock-music.com/sound-effects-library-spooky-ambience.html"
		],
		"cc_by_ambience_examples": [
			"https://freesound.org/people/klankbeeld/packs/9250/"
		],
		"notes": "Prefer CC0. When CC-BY is used, enforce explicit attribution in res/META/CREDITS.md and in asset metadata."
	}
}

# Personality vector for this mentor (for dialogue weighting / behavior trees).
var personality := {
	"Calm": 0.74,
	"Methodical": 0.91,
	"Supportive": 0.67,
	"Cunning": 0.34,
	"Cruel": 0.02,
	"Nihilistic": 0.08
}

func get_personality_vector() -> Dictionary:
	return personality.duplicate(true)

func suggest_asset_pipeline(concept: String) -> Dictionary:
	# Returns a high-level, IDE-friendly horror-asset pipeline for CELL.
	# Mirrors the user’s flowchart but sanitized and generalized.
	var steps: Array = []

	steps.append({
		"id": "concept",
		"label": "Concept & Mood",
		"detail": "Anchor the asset in a CELL region (Forgotten Moon, Ashveil, Cold Verge, Red Silence). Define mood, faction presence, and survival affordances.",
		"actions": [
			"Gather CC0/CC-BY-safe mood references (architecture, industrial decay, harsh lighting).",
			"List V.I.T.A.L.I.T.Y. hooks: cover, oxygen access, freezing risk, fracture triggers."
		]
	})

	steps.append({
		"id": "blockout",
		"label": "Blockout",
		"detail": "Create low-resolution silhouettes or 64x64–128x128 tiles / sprites for the core shapes.",
		"actions": [
			"Keep silhouettes readable from top-down / 2.5D camera.",
			"Design modular tiles for doors, vents, escape pods, bioglass panels."
		]
	})

	steps.append({
		"id": "detail",
		"label": "Detail & Wear",
		"detail": "Add industrial decay and cold damage, not gore.",
		"actions": [
			"Indicate condensation, frost creep, worn cables, corroded metal.",
			"Ensure details survive downsampling to pixel scale."
		]
	})

	steps.append({
		"id": "prep_for_godot",
		"label": "Tile & Import Prep",
		"detail": "Retopology (if 3D), UVs, or sprite sheet packing for Godot 4 TileSet / TileMap.",
		"actions": [
			"Pack tiles in a single atlas where possible for TileSet efficiency.",
			"Reserve metadata slots for collisions, nav, and interaction areas."
		]
	})

	steps.append({
		"id": "textures",
		"label": "Textures & Palette",
		"detail": "Bake or paint textures in a limited, oppressive palette.",
		"actions": [
			"Use cyan/amber/ashen palettes with toxic haze overlays where appropriate.",
			"Export PBR or pseudo-PBR maps compatible with Godot shaders."
		]
	})

	steps.append({
		"id": "godot_integration",
		"label": "Godot 4 Integration",
		"detail": "Create TileSet, TileMap, and scene-prefabs for interactive props.",
		"actions": [
			"Follow Godot 4 TileSet + TileMap workflows; set collisions, terrain, and scene tiles for dynamic objects.",
			"Wire shaders for frost, fog, and static flicker; expose parameters for region-based modulation."
		]
	})

	steps.append({
		"id": "interaction",
		"label": "Interactive Hooks",
		"detail": "Attach scripts for keypads, neurochip glitches, distress radios, hallucination overlays.",
		"actions": [
			"Emit signals into GameState and RegionManager when players interact.",
			"Bind FractureSystem triggers to prolonged exposure, low oxygen, or strange audio loops."
		]
	})

	steps.append({
		"id": "test_and_export",
		"label": "Testing & Export",
		"detail": "Test performance, readability, and horror tone; then package as asset packs.",
		"actions": [
			"Validate TileMap performance on target platforms; profile shaders and animated tiles.",
			"Export as PNG spritesheets, normal maps, and Godot scenes with a README describing integration."
		]
	})

	return {
		"concept": concept,
		"steps": steps
	}

func suggest_safe_sources() -> Dictionary:
	# For IDE: where to look for example CC0/CC-BY horror-compatible resources.
	return kb_categories["licensing_safe_sources"].duplicate(true)

func build_horror_prompt(region: String, asset_focus: String) -> String:
	# Returns a single high-quality prompt to feed into external image/audio generation tools.
	var base := "Top-down 2.5D survival-horror asset for the CELL universe, "
	base += "set in " + region + ", focused on " + asset_focus + ". "
	base += "Industrial sci-fi decay, no gore, harsh contrast lighting, limited cyan and amber palette, "
	base += "frosted glass, exposed cabling, heavy atmospheric fog, subtle diegetic UI hints, "
	base += "optimized for 64x64 or 128x128 pixel tiles, Godot 4 TileSet-ready."
	return base

func get_godot_tileset_guidance() -> Dictionary:
	return {
		"summary": "Use Godot 4 TileMapLayer and TileSet: import spritesheets or atlases, auto-create tiles, then assign collisions, navigation, and scenes to tiles for interactive objects.",
		"docs": kb_categories["tilesets_godot_4"]["doc_urls"]
	}

func get_attribution_instructions(license_type: String) -> String:
	match license_type:
		LICENSE_CC0:
			return "CC0: note the source in res/META/CREDITS.md for provenance, but no attribution is legally required."
		LICENSE_CC_BY:
			return "CC-BY: add creator name, work title, URL, and license text into res/META/CREDITS.md and any distribution README. Ensure in-game credits surface the attribution."
		_:
			return "Unknown license type. Do not import; keep the asset outside the repo until licensing is clarified."