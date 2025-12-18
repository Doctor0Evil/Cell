extends Control
class_name DevHarness

@onready var oxygen_label: Label = $VBox/OxygenLabel
@onready var suit_label: Label = $VBox/SuitLabel
@onready var water_label: Label = $VBox/WaterLabel
@onready var flags_label: Label = $VBox/FlagsLabel
@onready var loreway_profile_label: Label = $VBox/LorewayProfileLabel

@onready var global_slider: HSlider = $VBox/LorewayControlsScroll/LorewayControls/BrutalityGlobal/GlobalSlider
@onready var physical_slider: HSlider = $VBox/LorewayControlsScroll/LorewayControls/BrutalityPhysical/PhysicalSlider
@onready var psych_slider: HSlider = $VBox/LorewayControlsScroll/LorewayControls/BrutalityPsych/PsychSlider
@onready var social_slider: HSlider = $VBox/LorewayControlsScroll/LorewayControls/BrutalitySocial/SocialSlider

@onready var dread_slider: HSlider = $VBox/LorewayControlsScroll/LorewayControls/HorrorDread/DreadSlider
@onready var shock_slider: HSlider = $VBox/LorewayControlsScroll/LorewayControls/HorrorShock/ShockSlider
@onready var disgust_slider: HSlider = $VBox/LorewayControlsScroll/LorewayControls/HorrorDisgust/DisgustSlider
@onready var uncanny_slider: HSlider = $VBox/LorewayControlsScroll/LorewayControls/HorrorUncanny/UncannySlider
@onready var moral_slider: HSlider = $VBox/LorewayControlsScroll/LorewayControls/HorrorMoral/MoralSlider

@onready var rural_slider: HSlider = $VBox/LorewayControlsScroll/LorewayControls/SlavicRural/RuralSlider
@onready var bureau_slider: HSlider = $VBox/LorewayControlsScroll/LorewayControls/SlavicBureau/BureauSlider

@onready var surreal_slider: HSlider = $VBox/LorewayControlsScroll/LorewayControls/TempSurreal/SurrealSlider
@onready var narrative_slider: HSlider = $VBox/LorewayControlsScroll/LorewayControls/TempNarrative/NarrativeSlider
@onready var horror_temp_slider: HSlider = $VBox/LorewayControlsScroll/LorewayControls/TempHorror/HorrorTempSlider

@onready var reset_button: Button = $VBox/LorewayControlsScroll/LorewayControls/LorewayControlsReset/ResetButton

@onready var candidates_label: Label = $VBox/CandidatesLabel
@onready var candidate_selector: OptionButton = $VBox/CandidateSetSelector
@onready var apply_candidates_button: Button = $VBox/ApplyCandidatesButton

@onready var mood_label: Label = $VBox/MoodLabel
@onready var mood_selector: OptionButton = $VBox/MoodSelector
@onready var apply_mood_button: Button = $VBox/ApplyMoodButton
@onready var custom_mood_input: LineEdit = $VBox/CustomMoodRow/CustomMoodName
@onready var save_custom_button: Button = $VBox/CustomMoodRow/SaveCustomButton

@onready var run_tests_button: Button = $VBox/RunTestsButton
@onready var spawn_player_button: Button = $VBox/SpawnPlayerButton

var _player_status: Node = null
var _storyteller: Storyteller = null
var _tuning_candidates: Array = []
var _candidate_sets: Dictionary = {}
var _mood_presets: Dictionary = {}
var _custom_moods: Dictionary = {}

# Path to persist selected mood + candidate set between runs
var _state_save_path: String = "user://loreway_state.cfg"
# Path to persist custom mood presets
var _custom_moods_save_path: String = "user://loreway_custom_moods.cfg"


func _ready() -> void:
	add_to_group("runtime")
	run_tests_button.pressed.connect(_on_run_tests_pressed)
	spawn_player_button.pressed.connect(_on_spawn_player_pressed)
	_refresh_player_handle()

	# Wire up a Storyteller instance for smoke testing brutality scoring
	var st := Storyteller.new()
	_storyteller = st
	add_child(st)
	# Example candidates to validate scoring (and demonstrate brutality effects in the logs)
	_tuning_candidates = [
		{"type":"local_catastrophe", "narrativetags":["plague"], "consequences":["mass_casualty"], "external_reference_allowed": false},
		{"type":"disappearance", "narrativetags":["betrayal"], "consequences":[], "external_reference_allowed": false},
		{"type":"minor", "narrativetags":[], "consequences":[], "external_reference_allowed": false}
	]
	var chosen := _storyteller.pick_next_event(_tuning_candidates)
	DebugLog.log("DevHarness", "STORYTELLER_TEST", {"chosen_type": str(chosen.get("type", "unknown"))})

	# Connect sliders for live tuning
	global_slider.connect("value_changed", Callable(self, "_on_slider_changed"), ["brutality", "global"])
	physical_slider.connect("value_changed", Callable(self, "_on_slider_changed"), ["brutality", "physical"])
	psych_slider.connect("value_changed", Callable(self, "_on_slider_changed"), ["brutality", "psychological"])
	social_slider.connect("value_changed", Callable(self, "_on_slider_changed"), ["brutality", "social"])

	dread_slider.connect("value_changed", Callable(self, "_on_slider_changed"), ["horror", "dread"])
	shock_slider.connect("value_changed", Callable(self, "_on_slider_changed"), ["horror", "shock"])
	disgust_slider.connect("value_changed", Callable(self, "_on_slider_changed"), ["horror", "disgust"])
	uncanny_slider.connect("value_changed", Callable(self, "_on_slider_changed"), ["horror", "uncanny"])
	moral_slider.connect("value_changed", Callable(self, "_on_slider_changed"), ["horror", "moral_anxiety"])

	rural_slider.connect("value_changed", Callable(self, "_on_slider_changed"), ["slavic", "rural_decay"])
	bureau_slider.connect("value_changed", Callable(self, "_on_slider_changed"), ["slavic", "bureaucratic_horror"])

	surreal_slider.connect("value_changed", Callable(self, "_on_slider_changed"), ["temperature", "surreal_temperature"])
	narrative_slider.connect("value_changed", Callable(self, "_on_slider_changed"), ["temperature", "narrative_temperature"])
	horror_temp_slider.connect("value_changed", Callable(self, "_on_slider_changed"), ["temperature", "horror_temperature"])

	reset_button.pressed.connect(Callable(self, "_on_reset_pressed"))

	# Sync sliders to current profile so UI reflects the initial state
	_sync_sliders_with_profile()
	# Initialize candidate set selector UI and handlers
	_init_candidate_sets()
	apply_candidates_button.pressed.connect(Callable(self, "_on_apply_candidates_pressed"))
	# Apply defaults immediately
	_on_apply_candidates_pressed()

	# Initialize mood presets UI and handlers
	_init_mood_presets()
	mood_selector.connect("item_selected", Callable(self, "_on_mood_selected"))
	apply_mood_button.pressed.connect(Callable(self, "_on_apply_mood_pressed"))
	# Wire up custom mood saving
	save_custom_button.pressed.connect(Callable(self, "_on_save_custom_pressed"))
	# Load and apply the last-saved state (mood + candidate set) if present, otherwise apply default
	_load_saved_state()

func _process(delta: float) -> void:
	if not _player_status:
		_refresh_player_handle()
	_update_display()
	# Keep profile label up to date
	loreway_profile_label.text = _format_profile_string(LorewayPersona.profile)

func _refresh_player_handle() -> void:
	_player_status = get_tree().get_first_node_in_group("player_status")

func _update_display() -> void:
	if not _player_status:
		oxygen_label.text = "Player: (none)"
		suit_label.text = "Suit SL Cap: N/A"
		water_label.text = "Water: N/A"
		flags_label.text = "Flags: N/A"
		var p := LorewayPersona.profile
		loreway_profile_label.text = "Profile: global=%.2f physical=%.2f psych=%.2f social=%.2f\nDread=%.2f shock=%.2f disgust=%.2f uncanny=%.2f moral=%.2f\nSlavic: rural=%.2f bureau=%.2f domestic=%.2f cosmic=%.2f" % [p.brutality.global, p.brutality.physical, p.brutality.psychological, p.brutality.social, p.horror.dread, p.horror.shock, p.horror.disgust, p.horror.uncanny, p.horror.moral_anxiety, p.slavic.rural_decay, p.slavic.bureaucratic_horror, p.slavic.domestic_haunting, p.slavic.cosmic_rot]
		return


	var vit := _player_status.vitalitysystem
	oxygen_label.text = "Oxygen: %s / %s" % [str(vit.oxygen), str(vit.oxygen_max)]
	suit_label.text = "Suit SL Cap: %s" % [str(vit.suit_oxygen_capacity_sl)]
	water_label.text = "Water: %s / %s" % [str(vit.water), str(vit.water_max)]
	flags_label.text = "Flags: Player OK"
		var p := LorewayPersona.profile
		loreway_profile_label.text = "Profile: global=%.2f physical=%.2f psych=%.2f social=%.2f\nDread=%.2f shock=%.2f disgust=%.2f uncanny=%.2f moral=%.2f\nSlavic: rural=%.2f bureau=%.2f domestic=%.2f cosmic=%.2f" % [p.brutality.global, p.brutality.physical, p.brutality.psychological, p.brutality.social, p.horror.dread, p.horror.shock, p.horror.disgust, p.horror.uncanny, p.horror.moral_anxiety, p.slavic.rural_decay, p.slavic.bureaucratic_horror, p.slavic.domestic_haunting, p.slavic.cosmic_rot]

func _on_slider_changed(value: float, group: String, key: String) -> void:
	var p := LorewayPersona.profile
	if group == "brutality":
		if key == "global":
			p.brutality.global = value
		elif key == "physical":
			p.brutality.physical = value
		elif key == "psychological":
			p.brutality.psychological = value
		elif key == "social":
			p.brutality.social = value
	elif group == "horror":
		if key == "dread":
			p.horror.dread = value
		elif key == "shock":
			p.horror.shock = value
		elif key == "disgust":
			p.horror.disgust = value
		elif key == "uncanny":
			p.horror.uncanny = value
		elif key == "moral_anxiety":
			p.horror.moral_anxiety = value
	elif group == "slavic":
		if key == "rural_decay":
			p.slavic.rural_decay = value
		elif key == "bureaucratic_horror":
			p.slavic.bureaucratic_horror = value
	elif group == "temperature":
		if key == "surreal_temperature":
			p.surreal_temperature = value
		elif key == "narrative_temperature":
			p.narrative_temperature = value
		elif key == "horror_temperature":
			p.horror_temperature = value
	# Update the label to reflect live changes
	loreway_profile_label.text = _format_profile_string(p)
	# Re-evaluate tuning candidates and log the chosen asset so changes are visible
	if _storyteller != null and _tuning_candidates.size() > 0:
		var chosen := _storyteller.pick_next_event(_tuning_candidates)
		DebugLog.log("DevHarness", "STORYTELLER_TUNE", {"chosen_type": str(chosen.get("type", "unknown"))})

func _format_profile_string(p) -> String:
	return "Profile: global=%.2f physical=%.2f psych=%.2f social=%.2f\nDread=%.2f shock=%.2f disgust=%.2f uncanny=%.2f moral=%.2f\nSlavic: rural=%.2f bureau=%.2f domestic=%.2f cosmic=%.2f\nTemps: surreal=%.2f narrative=%.2f horror=%.2f" % [p.brutality.global, p.brutality.physical, p.brutality.psychological, p.brutality.social, p.horror.dread, p.horror.shock, p.horror.disgust, p.horror.uncanny, p.horror.moral_anxiety, p.slavic.rural_decay, p.slavic.bureaucratic_horror, p.slavic.domestic_haunting, p.slavic.cosmic_rot, p.surreal_temperature, p.narrative_temperature, p.horror_temperature]

func _sync_sliders_with_profile() -> void:
	var p := LorewayPersona.profile
	global_slider.value = p.brutality.global
	physical_slider.value = p.brutality.physical
	psych_slider.value = p.brutality.psychological
	social_slider.value = p.brutality.social
	dread_slider.value = p.horror.dread
	shock_slider.value = p.horror.shock
	disgust_slider.value = p.horror.disgust
	uncanny_slider.value = p.horror.uncanny
	moral_slider.value = p.horror.moral_anxiety
	rural_slider.value = p.slavic.rural_decay
	bureau_slider.value = p.slavic.bureaucratic_horror
	surreal_slider.value = p.surreal_temperature
	narrative_slider.value = p.narrative_temperature
	horror_temp_slider.value = p.horror_temperature
	loreway_profile_label.text = _format_profile_string(p)

func _on_reset_pressed() -> void:
	LorewayPersona.profile = LorewayPersonality.default_profile()
	_sync_sliders_with_profile()

func _init_candidate_sets() -> void:
	# Preset candidate sets mapped to easily identifiable KG slices
	_candidate_sets = {
		"Default": [
			{"type":"local_catastrophe", "narrativetags":["plague"], "consequences":["mass_casualty"], "external_reference_allowed": false},
			{"type":"disappearance", "narrativetags":["betrayal"], "consequences":[], "external_reference_allowed": false},
			{"type":"minor", "narrativetags":[], "consequences":[], "external_reference_allowed": false}
		],
		"Ashditch Wells": [
			{"type":"local_catastrophe", "narrativetags":["well","plague"], "consequences":["contaminated_water"], "external_reference_allowed": false},
			{"type":"ritual_failure", "narrativetags":["well_ritual","origin_legend"], "consequences":["disfigurement"], "external_reference_allowed": false},
			{"type":"disappearance", "narrativetags":["well_suspect"], "consequences":[], "external_reference_allowed": false}
		],
		"Witch Trials": [
			{"type":"ritual_failure", "narrativetags":["betrayal","public_trial"], "consequences":["execution"], "external_reference_allowed": false},
			{"type":"disappearance", "narrativetags":["witch_trial","origin_legend"], "consequences":[], "external_reference_allowed": false},
			{"type":"local_catastrophe", "narrativetags":["mob_violence"], "consequences":["mass_casualty"], "external_reference_allowed": false}
		]
	}
	candidate_selector.clear()
	for name in _candidate_sets.keys():
		candidate_selector.add_item(name)
	candidate_selector.select(0)
	candidates_label.text = "Candidates: %s" % candidate_selector.get_item_text(candidate_selector.get_selected_id())

func _on_apply_candidates_pressed() -> void:
	var idx := candidate_selector.get_selected_id()
	var name := candidate_selector.get_item_text(idx)
	_tuning_candidates = _candidate_sets.get(name, _candidate_sets["Default"])
	candidates_label.text = "Candidates: %s" % name
	DebugLog.log("DevHarness", "STORYTELLER_CANDIDATES_SET", {"set": name})
	# Persist this candidate choice together with mood
	_save_state()
	_evaluate_candidates_and_log()

func _evaluate_candidates_and_log() -> void:
	if _storyteller != null and _tuning_candidates.size() > 0:
		var chosen := _storyteller.pick_next_event(_tuning_candidates)
		DebugLog.log("DevHarness", "STORYTELLER_TUNE", {"chosen_type": str(chosen.get("type", "unknown")), "set": candidate_selector.get_item_text(candidate_selector.get_selected_id())})

func _init_mood_presets() -> void:
	# Define three useful mood presets that set brutality, horror vectors and temperatures
	_mood_presets = {
		"SlowBurn": {
			"brutality": {"global": 0.5, "physical": 0.3, "psychological": 0.6, "social": 0.5},
			"horror": {"dread": 0.8, "shock": 0.4, "disgust": 0.4, "uncanny": 0.9, "moral_anxiety": 0.8},
			"slavic": {"rural_decay": 0.9, "bureaucratic_horror": 0.7, "domestic_haunting": 0.8, "cosmic_rot": 0.6},
			"surreal_temperature": 0.4, "narrative_temperature": 0.95, "horror_temperature": 0.45
		},
		"Panic": {
			"brutality": {"global": 0.98, "physical": 0.95, "psychological": 1.0, "social": 0.95},
			"horror": {"dread": 1.0, "shock": 1.0, "disgust": 0.95, "uncanny": 0.75, "moral_anxiety": 1.0},
			"slavic": {"rural_decay": 0.6, "bureaucratic_horror": 0.95, "domestic_haunting": 0.7, "cosmic_rot": 0.5},
			"surreal_temperature": 0.2, "narrative_temperature": 0.6, "horror_temperature": 1.0
		},
		"DreamLogic": {
			"brutality": {"global": 0.7, "physical": 0.4, "psychological": 0.85, "social": 0.6},
			"horror": {"dread": 0.7, "shock": 0.4, "disgust": 0.5, "uncanny": 1.0, "moral_anxiety": 0.9},
			"slavic": {"rural_decay": 0.8, "bureaucratic_horror": 0.6, "domestic_haunting": 0.9, "cosmic_rot": 0.85},
			"surreal_temperature": 1.0, "narrative_temperature": 0.5, "horror_temperature": 0.65
		}
	}
	# Load any saved custom moods and merge them into presets
	_load_custom_moods()
	for name in _custom_moods.keys():
		_mood_presets[name] = _custom_moods[name]

	mood_selector.clear()
	for name in _mood_presets.keys():
		mood_selector.add_item(name)
	mood_selector.select(0)
	mood_label.text = "Mood Preset: %s" % mood_selector.get_item_text(mood_selector.get_selected_id())

func _on_mood_selected(index: int) -> void:
	mood_label.text = "Mood Preset: %s" % mood_selector.get_item_text(index)

func _on_apply_mood_pressed() -> void:
	var idx := mood_selector.get_selected_id()
	var name := mood_selector.get_item_text(idx)
	var preset := _mood_presets.get(name, null)
	if preset != null:
		LorewayPersona.profile = LorewayPersonality.new_profile("MOOD_" + name, name, preset)
		_sync_sliders_with_profile()
		DebugLog.log("DevHarness", "MOOD_APPLIED", {"mood": name})
		# Persist this choice for next runs (including candidate set)
		_save_state()
		# Re-evaluate candidate picks to show the effect immediately
		_evaluate_candidates_and_log()

func _save_state() -> void:
	# Persist both the selected mood and selected candidate set as JSON
	var state := {}
	state["mood"] = mood_selector.get_item_text(mood_selector.get_selected_id())
	state["candidates"] = candidate_selector.get_item_text(candidate_selector.get_selected_id())

	var json := JSON.print(state)
	var f := FileAccess.open(_state_save_path, FileAccess.WRITE)
	if f:
		f.store_string(json)
		f.close()
		DebugLog.log("DevHarness", "STATE_SAVED", {"ok": true, "path": _state_save_path})
	else:
		DebugLog.log("DevHarness", "STATE_SAVE_FAILED", {})

func _load_saved_state() -> void:
	if not FileAccess.file_exists(_state_save_path):
		# Nothing saved, apply defaults
		_on_apply_mood_pressed()
		return
	var f := FileAccess.open(_state_save_path, FileAccess.READ)
	if not f:
		_on_apply_mood_pressed()
		return
	var s := f.get_as_text()
	f.close()
	var parsed := JSON.parse_string(s)
	if parsed.error != OK:
		_on_apply_mood_pressed()
		return
	var data := parsed.result
	if typeof(data) != TYPE_DICTIONARY:
		_on_apply_mood_pressed()
		return

	# Apply mood if present
	var moodName := data.get("mood", "")
	if moodName != "":
		for i in range(mood_selector.get_item_count()):
			if mood_selector.get_item_text(i) == moodName:
				mood_selector.select(i)
				mood_label.text = "Mood Preset: %s" % moodName
				_on_apply_mood_pressed()
				DebugLog.log("DevHarness", "STATE_LOADED_MOOD", {"mood": moodName})
				break

	# Apply candidate set if present
	var candName := data.get("candidates", "")
	if candName != "":
		for i in range(candidate_selector.get_item_count()):
			if candidate_selector.get_item_text(i) == candName:
				candidate_selector.select(i)
				_on_apply_candidates_pressed()
				DebugLog.log("DevHarness", "STATE_LOADED_CANDIDATES", {"candidates": candName})
				break

func _on_run_tests_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/tests/TestRunner.tscn")

func _on_spawn_player_pressed() -> void:
	# Instantiate the configured player scene into current scene for testing.
	var p := load(GameState.player_scene_path) as PackedScene
	if p:
		var inst := p.instantiate()
		get_tree().current_scene.add_child(inst)
		DebugLog.log("DevHarness", "SPAWN_PLAYER", {"path": GameState.player_scene_path})
		_refresh_player_handle()
	else:
		DebugLog.log("DevHarness", "SPAWN_PLAYER_FAILED", {"path": GameState.player_scene_path})
