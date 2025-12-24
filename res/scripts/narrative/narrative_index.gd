extends Resource
class_name NarrativeIndex

@export var scenes: Dictionary = {
	"SCN-HADES-VENT-TABOO-02": {
		"file": "res://resources/narratives/SCN-HADES-VENT-TABOO-02.yaml",
		"place_id": "PLCORBITALHADES01",
		"taboos": ["TABSVENTSILENCE01"],
		"spirits": ["SPRTAZUREHOWLER01"],
		"hooks": [
			"postplayervoice:route_to_vent_bus",
			"screen_desaturate:0.15_over_2s",
			"flash_oxygen_warning_once",
			"play_sfx:VENT_HISS_LOCKON",
			"reroute_growler_paths_toward_player_deck"
		]
	}
}
