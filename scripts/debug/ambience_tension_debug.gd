extends Control
class_name AmbienceTensionDebug

@export var ambience_player_path: NodePath

@onready var slider: HSlider = %TensionSlider
@onready var value_label: Label = %ValueLabel
@onready var ambience_player: ExtremeHorrorAmbiencePlayer = null

func _ready() -> void:
    ambience_player = (
        ambience_player_path.is_empty() ? GameState.extreme_ambience_player : get_node_or_null(ambience_player_path)
    )
    slider.value_changed.connect(_on_value_changed)
    _on_value_changed(slider.value)

func _on_value_changed(value: float) -> void:
    value_label.text = "%.2f" % value
    if ambience_player:
        ambience_player.set_debug_tension_override(value)
