extends Label
class_name HorrorTerminalLabel

@export var font_key := "terminal_glitch"

func _ready() -> void:
    var font_path := HorrorAssetRegistry.get_font(font_key)
    if font_path == "":
        return
    var font_res: Font = load(font_path)
    var theme := Theme.new()
    theme.set_font("font", "Label", font_res)
    theme.set_font_size("font_size", "Label", 18)
    theme.set_color("font_color", "Label", Color(0.6, 1.0, 0.6))
    self.theme = theme
