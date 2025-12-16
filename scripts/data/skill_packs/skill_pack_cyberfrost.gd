extends Resource
class_name SkillPackCyberfrost

# This resource instantiates SkillDefinition objects for Cell's cyberfrost / wastepunk layer.
# It expects SkillDefinition and PlayerVitalitySystem from the core skill system.

const PACK_ID := "CYBERFROST"

func build_skills() -> Array[SkillDefinition]:
	var skills: Array[SkillDefinition] = []

	# Cold Systems & Wastecraft ---------------------------------------

	skills.append(_make_skill(
		"CRYO_SYSTEMS",
		"Cryo Systems",
		"Operating frozen reactors, plasma lines, and coolant veins in breached hulls without boiling your blood.",
		{
			"logic_weight": 0.5,
			"intelligence_weight": 0.3,
			"yield_weight": 0.2
		}
	))

	skills.append(_make_skill(
		"SCRAP_ALCHEMY",
		"Scrap Alchemy",
		"Cooking chems, coagulants, and corrosives from rust, biometal scrap, and station sludge.",
		{
			"logic_weight": 0.35,
			"yield_weight": 0.45,
			"tenacity_weight": 0.2
		}
	))

	skills.append(_make_skill(
		"NANOFORGE_HANDLING",
		"Nanoforge Handling",
		"Running reclaim rigs and nanoforges to print ammo, plates, and BCI nodes without waking the infection.",
		{
			"logic_weight": 0.45,
			"vitality_weight": 0.25,
			"yield_weight": 0.3
		}
	))

	skills.append(_make_skill(
		"SIGNAL_CARTOGRAPHY",
		"Signal Cartography",
		"Mapping safe corridors through static, howl, and broken telemetry across Ashveil and Red Silence.",
		{
			"logic_weight": 0.4,
			"instinct_weight": 0.35,
			"intelligence_weight": 0.25
		}
	))

	# Social & Faction Mesh -------------------------------------------

	skills.append(_make_skill(
		"DECK_DIPLOMACY",
		"Deck Diplomacy",
		"Cutting deals for oxygen, water, and shelter between IGSF, Knights, and resistance crews.",
		{
			"influence_weight": 0.5,
			"logic_weight": 0.25,
			"temper_weight": 0.25
		}
	))

	skills.append(_make_skill(
		"KNOTWORK_CULTURE",
		"Knotwork Culture",
		"Reading cults, dead religions, and deck myths well enough not to get spaced for a wrong greeting.",
		{
			"influence_weight": 0.4,
			"intelligence_weight": 0.4,
			"instinct_weight": 0.2
		}
	))

	skills.append(_make_skill(
		"INTERROGATION_PROTOCOLS",
		"Interrogation Protocols",
		"Extracting routes, caches, and outbreak data from people who would rather die than talk.",
		{
			"temper_weight": 0.4,
			"influence_weight": 0.35,
			"intelligence_weight": 0.25
		}
	))

	skills.append(_make_skill(
		"BEAST_DRONE_HANDLING",
		"Beast & Drone Handling",
		"Taming scavenger drones and semi-feral biometal hulks long enough to use them.",
		{
			"instinct_weight": 0.45,
			"logic_weight": 0.3,
			"temper_weight": 0.25
		}
	))

	# Survival & Conditioning -----------------------------------------

	skills.append(_make_skill(
		"DEEP_HULL_NAVIGATION",
		"Deep Hull Navigation",
		"Moving through broken gravity shafts, coolant canals, and frostbitten trusses without getting lost or killed.",
		{
			"instinct_weight": 0.35,
			"agility_weight": 0.4,
			"tenacity_weight": 0.25
		}
	))

	skills.append(_make_skill(
		"CRYO_ADAPTATION",
		"Cryo Adaptation",
		"Training nerves and blood to keep working in Cold Verge winds and forgotten decks.",
		{
			"vitality_weight": 0.4,
			"tenacity_weight": 0.4,
			"constitution_weight": 0.2 # requires extended SkillDefinition if you want this
		}
	))

	skills.append(_make_skill(
		"TOXIN_BUFFERING",
		"Toxin Buffering",
		"Keeping poisons, spores, and nanosludge from turning your organs into slurry.",
		{
			"vitality_weight": 0.35,
			"yield_weight": 0.4,
			"temper_weight": 0.25
		}
	))

	skills.append(_make_skill(
		"ANCHOR_MIND",
		"Anchor Mind",
		"Holding focus through signal howl, whisper loops, and the sound of your own suit screaming.",
		{
			"temper_weight": 0.45,
			"instinct_weight": 0.3,
			"logic_weight": 0.25
		}
	))

	return skills


func _make_skill(id: StringName, name: String, desc: String, weights: Dictionary) -> SkillDefinition:
	var s := SkillDefinition.new()
	s.id = id
	s.display_name = name
	s.description = desc
	s.max_rank = 10

	# Map provided weight keys into SkillDefinition's fields if present
	if weights.has("vitality_weight"):
		s.vitality_weight = weights["vitality_weight"]
	if weights.has("instinct_weight"):
		s.instinct_weight = weights["instinct_weight"]
	if weights.has("tenacity_weight"):
		s.tenacity_weight = weights["tenacity_weight"]
	if weights.has("agility_weight"):
		s.agility_weight = weights["agility_weight"]
	if weights.has("logic_weight"):
		s.logic_weight = weights["logic_weight"]
	if weights.has("influence_weight"):
		s.influence_weight = weights["influence_weight"]
	if weights.has("temper_weight"):
		s.temper_weight = weights["temper_weight"]
	if weights.has("yield_weight"):
		s.yield_weight = weights["yield_weight"]

	# Optional: extended weights for secondary stats, if you extend SkillDefinition later
	if weights.has("constitution_weight") and s.has_meta("constitution_weight"):
		s.set("constitution_weight", weights["constitution_weight"])

	return s
