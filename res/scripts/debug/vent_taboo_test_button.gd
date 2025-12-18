extends Button
class_name VentTabooTestButton

@export var tester_path: NodePath

func _ready() -> void:
	text = "Test Vent Taboo"
	connect("pressed", _on_pressed)

func _on_pressed() -> void:
	var tester := get_node_or_null(tester_path)
	if tester and tester.has_method("trigger_test_once"):
		tester.trigger_test_once()
