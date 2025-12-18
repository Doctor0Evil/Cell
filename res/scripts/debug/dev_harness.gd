extends Control
class_name DevHarness

@onready var oxygen_label: Label = $VBox/OxygenLabel
@onready var suit_label: Label = $VBox/SuitLabel
@onready var water_label: Label = $VBox/WaterLabel
@onready var flags_label: Label = $VBox/FlagsLabel
@onready var run_tests_button: Button = $VBox/RunTestsButton
@onready var spawn_player_button: Button = $VBox/SpawnPlayerButton

var _player_status: Node = null

func _ready() -> void:
	add_to_group("runtime")
	run_tests_button.pressed.connect(_on_run_tests_pressed)
	spawn_player_button.pressed.connect(_on_spawn_player_pressed)
	_refresh_player_handle()

func _process(delta: float) -> void:
	if not _player_status:
		_refresh_player_handle()
	_update_display()

func _refresh_player_handle() -> void:
	_player_status = get_tree().get_first_node_in_group("player_status")

func _update_display() -> void:
	if not _player_status:
		oxygen_label.text = "Player: (none)"
		suit_label.text = "Suit SL Cap: N/A"
		water_label.text = "Water: N/A"
		flags_label.text = "Flags: N/A"
		return

	var vit := _player_status.vitalitysystem
	oxygen_label.text = "Oxygen: %s / %s" % [str(vit.oxygen), str(vit.oxygen_max)]
	suit_label.text = "Suit SL Cap: %s" % [str(vit.suit_oxygen_capacity_sl)]
	water_label.text = "Water: %s / %s" % [str(vit.water), str(vit.water_max)]
	flags_label.text = "Flags: Player OK"

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
