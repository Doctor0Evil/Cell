extends Control
class_name MainMenu

@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
    start_button.pressed.connect(_on_start_pressed)
    continue_button.pressed.connect(_on_continue_pressed)
    options_button.pressed.connect(_on_options_pressed)
    quit_button.pressed.connect(_on_quit_pressed)
    continue_button.disabled = not SaveSystem.has_any_profile()

func _on_start_pressed() -> void:
    SaveSystem.new_profile()
    GameState.reset_for_new_run()
    GameState.load_region(&"ASHVEIL_DEBRIS_STRATUM")

func _on_continue_pressed() -> void:
    SaveSystem.load_last_profile()

func _on_options_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/ui/OptionsMenu.tscn")

func _on_quit_pressed() -> void:
    get_tree().quit()
