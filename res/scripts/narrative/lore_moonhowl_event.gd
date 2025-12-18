extends Resource
class_name LoreEntryMoonhowlEvent

@export var entry_id: StringName = &"LORE_GROWLERS_MOONHOWL_01"
@export var title: String = "Lycanthropy-in-Space: The Moonhowl Event"
@export var region_id: StringName = &"PLCORBITALHADES_THETA"
@export var tags: PackedStringArray = [
	"nanovirus-contagion",
	"lycanthropy",
	"transspecies-anomaly",
	"cosmic-psychosis",
	"oxygen-famine"
]

@export_multiline var incident_summary: String = """
During the thirteenth lunar night-cycle aboard orbital colony Hades-Theta, exosuit technicians and cargo-deck personnel mutated after exposure to the Cell-nanovirus under sustained radiation from the Azure Moon, a rogue satellite emitting bioluminescent mist and psionic interference. Victims underwent violent exogenic recombination as human DNA entangled with canid biomaterial carried in the nanovirus suspension medium, producing the first documented Growler packs in orbit.
"""

@export_multiline var physiology_notes: String = """
Growlers exhibit skeletal elongation of the cranial ridge into a quasi-snout with retractable jaw hinges, hyper-oxygenic muscle microfibrils capable of sprinting at kill-charge velocities in low or null gravity, and echolocation-grade sensitivity that allows them to localize bloodstream flow through bulkheads. Continuous metabolic agony keeps cortical activity in a state of weaponized distress; even after apparent death, residual motor clusters and vocal folds can remain partially sentient.
"""

@export_multiline var behavior_notes: String = """
During standard cycles they wander abandoned decks, magnetized to vibration patterns and heartbeat rhythm, communicating through guttural howls that phase-lock with the Azure Moon's dominant frequency. Under extended long-night conditions, they enter Pack Protocols and hunt any warm-blooded presence, including other Growlers, prioritizing moving oxygen signatures over static heat sources.
"""

@export_multiline var transcript_fragment: String = """
"...they're learning to open doors now. Not with their hands—with the claws. They feel for the latch, like it's a pulse under paint, and you can hear them find it. Somebody told me they used to be engineers. I keep hearing their breathing in the ducts; it's not just air, it's the ship remembering how we used to sound."
"""

@export_multiline var lore_implication: String = """
The Moonhowl Event establishes a direct correlation between the Cell-nanovirus and extraterrestrial resonance fields. Slavic myth fragments mention Psel'Grova—the Blue Echo Moon—that calls the beast in mankind when the border between life and death thins. Hades-Theta bio-theory circles now treat the Azure Moon as both transmitter and organism, shaping cross-speciation toward a predatory, corridor-native consciousness.
"""

@export var taboo_id: StringName = &"TABSVENTSILENCE01"
@export var spirit_id: StringName = &"SPRTAZUREHOWLER01"
@export var event_id: StringName = &"EVMOONHOWLDEC2063"
