extends Control
class_name CellContainmentConsole

@export var vitality_system: PlayerVitalitySystem
@export var settlement_pools: SettlementPools
@export var faction_system: FactionSystem

var active_panel: StringName = &"Survival Dashboard"
var command_input: String = ""
var command_history: Array[String] = []
var history_index: int = -1

var panels := {
    "Survival Dashboard": [
        {"name": "Vitals Monitor", "icon": "♥", "description": "Blood, Oxygen, Water, Stamina, Wellness, Body Temperature."},
        {"name": "Status Flags", "icon": "⚠", "description": "Starving, Dehydrated, Hypoxic, Frostbite thresholds."},
        {"name": "Recent Events", "icon": "⌛", "description": "Last collapses, near-death logs, contamination spikes."}
    ],
    "Mission Feed": [
        {"name": "Active Route", "icon": "⛓", "description": "Current objective chain and failure conditions."},
        {"name": "Region Modifiers", "icon": "☢", "description": "Cold, stress, contamination multipliers in this sector."},
        {"name": "Encounter Density", "icon": "✖", "description": "Projected presence of Breathers, HollowMen, PulseTerrors."}
    ],
    "Suit & Implants": [
        {"name": "Exosuit Shell", "icon": "🜨", "description": "Armor, thermal shielding, oxygen bleed modifiers."},
        {"name": "Implant Stack", "icon": "⚙", "description": "BCI load, cybernetic strain, Cell infection hooks."},
        {"name": "Drug Loadout", "icon": "💉", "description": "Stims, sedatives, oxygen pills, rationchips."}
    ],
    "Settlement Link": [
        {"name": "Life Support", "icon": "🫧", "description": "Shared Oxygen, Rations, Water, Manpower stability."},
        {"name": "Alert State", "icon": "⚔", "description": "Faction incursions, raid timers, lockdown events."},
        {"name": "Reputation", "icon": "☍", "description": "IGSF, Knights, VLR standing and corridor access."}
    ],
    "Diagnostics": [
        {"name": "VITALITY Trace", "icon": "Ψ", "description": "Attribute multipliers applied to drains and recovery."},
        {"name": "Cell Exposure", "icon": "✷", "description": "Current infection rate and resistance model output."},
        {"name": "System Log", "icon": "⎇", "description": "Last 64 survival and mission events."}
    ]
}

func _ready() -> void:
    if vitality_system == null:
        var status := get_tree().get_first_node_in_group("player_status")
        if status and status.has_method("get_vitality_system"):
            vitality_system = status.get_vitality_system()
    _refresh_ui()

func _process(_delta: float) -> void:
    _refresh_status_bar()

# Called from the scene tree or directly
func _refresh_ui() -> void:
    _update_panel_list()
    _update_panel_content()
    _update_status_bar()

func _update_panel_list() -> void:
    var sidebar := %SidebarPanels as VBoxContainer
    if sidebar == null:
        return
    sidebar.queue_free_children()
    for panel_name in panels.keys():
        var button := Button.new()
        button.text = str(panel_name)
        button.toggle_mode = true
        button.pressed = (panel_name == active_panel)
        button.focus_mode = Control.FOCUS_NONE
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.connect("pressed", Callable(self, "_on_panel_button_pressed").bind(panel_name))
        sidebar.add_child(button)

func _on_panel_button_pressed(panel_name: StringName) -> void:
    active_panel = panel_name
    _update_panel_content()

func _update_panel_content() -> void:
    var content_root := %PanelContent as VBoxContainer
    if content_root == null:
        return
    content_root.queue_free_children()

    var title := Label.new()
    title.text = str(active_panel)
    title.add_theme_color_override("font_color", Color.hex(0xD0F5FFFF))
    title.add_theme_font_size_override("font_size", 18)
    content_root.add_child(title)

    var sep := HSeparator.new()
    content_root.add_child(sep)

    # Survival Dashboard can surface live V.I.T.A.L.I.T.Y. + Water
    if active_panel == "Survival Dashboard" and vitality_system:
        content_root.add_child(_build_survival_grid())
    else:
        for entry in panels[active_panel]:
            var panel_box := VBoxContainer.new()
            panel_box.add_theme_constant_override("separation", 2)

            var header := HBoxContainer.new()
            var icon_label := Label.new()
            icon_label.text = str(entry["icon"])
            icon_label.add_theme_font_size_override("font_size", 16)
            header.add_child(icon_label)

            var name_label := Label.new()
            name_label.text = str(entry["name"])
            name_label.add_theme_font_size_override("font_size", 14)
            header.add_child(name_label)

            panel_box.add_child(header)

            var desc := Label.new()
            desc.text = str(entry["description"])
            desc.add_theme_color_override("font_color", Color.hex(0x9AA7B0FF))
            desc.autowrap = true
            panel_box.add_child(desc)

            var frame := PanelContainer.new()
            frame.add_theme_stylebox_override("panel", _make_frame_style())
            frame.add_child(panel_box)
            content_root.add_child(frame)

func _build_survival_grid() -> GridContainer:
    var grid := GridContainer.new()
    grid.columns = 3
    grid.add_theme_constant_override("h_separation", 16)
    grid.add_theme_constant_override("v_separation", 8)

    func add_meter(label_text: String, value: float, max_value: float, color: Color) -> void:
        var vb := VBoxContainer.new()
        var l := Label.new()
        l.text = label_text
        l.add_theme_color_override("font_color", Color.hex(0xC2CBD5FF))
        vb.add_child(l)

        var pb := TextureProgressBar.new()
        pb.min_value = 0.0
        pb.max_value = max_value
        pb.value = value
        pb.tint_progress = color
        pb.custom_minimum_size = Vector2(120, 10)
        vb.add_child(pb)
        grid.add_child(vb)

    add_meter("Blood", vitality_system.blood, vitality_system.blood_max, Color.hex(0xD73535FF))
    add_meter("Oxygen", vitality_system.oxygen, vitality_system.oxygen_max, Color.hex(0x3BB2E8FF))
    add_meter("Water", vitality_system.water, vitality_system.water_max, Color.hex(0x4AC6B0FF))
    add_meter("Stamina", vitality_system.stamina, vitality_system.stamina_max, Color.hex(0xE3D65AFF))
    add_meter("Wellness", vitality_system.wellness, vitality_system.wellness_max, Color.hex(0xA9E85CFF))
    add_meter("Body Temp", vitality_system.body_temperature, vitality_system.body_temperature_max, Color.hex(0xF79443FF))

    return grid

func _make_frame_style() -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color.hex(0x181D24FF)
    sb.border_color = Color.hex(0x2F3B47FF)
    sb.border_width_top = 1
    sb.border_width_bottom = 1
    sb.border_width_left = 1
    sb.border_width_right = 1
    sb.corner_radius_top_left = 2
    sb.corner_radius_top_right = 2
    sb.corner_radius_bottom_left = 2
    sb.corner_radius_bottom_right = 2
    return sb

# =========================
# Status bar + command line
# =========================

func _refresh_status_bar() -> void:
    _update_status_bar()

func _update_status_bar() -> void:
    var status_label := %StatusLine as Label
    if status_label == null or vitality_system == null:
        return

    var blood_str := str(round(vitality_system.blood)) + "/" + str(round(vitality_system.blood_max))
    var oxy_str := str(round(vitality_system.oxygen)) + "/" + str(round(vitality_system.oxygen_max))
    var water_str := str(round(vitality_system.water)) + "/" + str(round(vitality_system.water_max))

    status_label.text = "BLOOD " + blood_str \
        + " | O2 " + oxy_str \
        + " | H2O " + water_str \
        + " | STAM " + str(round(vitality_system.stamina)) \
        + " | WELL " + str(round(vitality_system.wellness))

func _on_CommandLine_text_submitted(text: String) -> void:
    var trimmed := text.strip_edges()
    if trimmed.is_empty():
        return
    command_history.append(trimmed)
    history_index = command_history.size()
    command_input = ""
    _execute_console_command(trimmed)

func _execute_console_command(cmd: String) -> void:
    # Simple, Cell‑specific command set
    # e.g. "trace.vitality", "trace.water", "mission.status", "settlement.state"
    match cmd:
        "trace.vitality":
            DebugLog.log("ContainmentConsole", "TRACE_VITALITY", {
                "vitality": vitality_system.vitality,
                "instinct": vitality_system.instinct,
                "tenacity": vitality_system.tenacity,
                "yield": vitality_system.yield
            })
        "trace.water":
            DebugLog.log("ContainmentConsole", "TRACE_WATER", {
                "water": vitality_system.water,
                "water_max": vitality_system.water_max,
                "dehydration_stacks": vitality_system.dehydration_stacks
            })
        "mission.status":
            GameState.request_mission_status()
        "settlement.state":
            if settlement_pools:
                DebugLog.log("ContainmentConsole", "SETTLEMENT_STATE", {
                    "oxygen": settlement_pools.oxygen,
                    "rations": settlement_pools.rations,
                    "manpower": settlement_pools.manpower,
                    "collapse_state": settlement_pools.get_collapse_state()
                })
        _:
            DebugLog.log("ContainmentConsole", "UNKNOWN_COMMAND", {"command": cmd})

func _on_CommandLine_gui_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_UP:
            if command_history.size() == 0:
                return
            history_index = max(0, history_index - 1)
            %CommandLine.text = command_history[history_index]
            %CommandLine.caret_column = %CommandLine.text.length()
        elif event.keycode == KEY_DOWN:
            if command_history.size() == 0:
                return
            history_index = min(command_history.size(), history_index + 1)
            if history_index == command_history.size():
                %CommandLine.text = ""
            else:
                %CommandLine.text = command_history[history_index]
            %CommandLine.caret_column = %CommandLine.text.length()
