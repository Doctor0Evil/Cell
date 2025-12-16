extends Control
class_name CellFractureShell

# Simple design‑time sandbox for fractures, NOT runtime gameplay.
# Attach this to a debug scene: res://scenes/debug/CellFractureShell.tscn
# UI requirements:
# - RichTextLabel named "Log"
# - LineEdit named "InputLine" (for numeric/choice input feed)
# - Optionally a Button to re‑run _show_main_menu()

# --------------------------
# Data definitions
# --------------------------

const ATTR_NAMES: Array[String] = [
    "Vitality",   # physical resilience
    "Instinct",   # threat awareness
    "Tenacity",   # endurance
    "Agility",    # movement / finesse
    "Logic",      # technical cognition
    "Influence",  # social presence
    "Temper",     # emotional control
    "Yield"       # resource efficiency
]

const FRACTURE_NAMES: Array[String] = [
    "Thirst Map",                 # 1
    "Hardened Blood",             # 2
    "Last Tank",                  # 3
    "Cold Verge Runner",          # 4
    "Ashveil Scavenger Routes",   # 5
    "Hull Line Marksman",         # 6
    "Recoil Interpreter",         # 7
    "Spine-Breaker Rounds",       # 8
    "Thermal Baffle Webbing",     # 9
    "Atmos Seal Kit",             # 10
    "BCI Noise Shield",           # 11
    "Bulkhead Ghost",             # 12
    "Deep Trench Dweller",        # 13
    "Cold Line Runner",           # 14
    "Oxygen Scar",                # 15
    "Sterile Gut",                # 16
    "Corridor Butcher",           # 17
    "Pulse Echo",                 # 18
    "Self-Healing Composite",     # 19
    "HazMat Overlay Harness",     # 20
    "Signal Mapper",              # 21
    "Containment Keyholder",      # 22
    "Long Night Survivor",        # 23
    "Black-Section Asset",        # 24
    "Deckside Myth",              # 25
    "Containment Oath",           # 26
    "Cell-Marked",                # 27
    "Faction Oath-bound",         # 28
    "Companion Circuit",          # 29
    "Prey Mesh",                  # 30
    "Oxygen Accountant",          # 31
    "Hull Ghost",                 # 32
    "Field Jury-Rig",             # 33
    "Chem Discipline",            # 34
    "Cold Glass Optics",          # 35
    "Mag-Latch Reload",           # 36
    "Adaptive Chameleon Plating", # 37
    "Shock Spine Dampers",        # 38
    "Dielectric Skin Mesh",       # 39
    "Red Silence Signal Scar"     # 40
]

# Indexed parallel arrays for descriptions and design‑time notes
var fracture_descriptions: Array[String] = []
var fracture_design_notes: Array[String] = []

# --------------------------
# Subject state (shell)
# --------------------------

var player_name: String = "Containment Subject"
var player_level: int = 1
var player_xp: int = 0
var xp_for_next_level: int = 1000

# Attributes 0–10 (design range)
var player_attr: Array[int] = []

# Core survival pools (shell stand‑ins)
var blood: int = 100
var oxygen: int = 100
var water: int = 100
var stamina: int = 100
var wellness: int = 100

# Fractures imprinted on this subject (indices into FRACTURE_NAMES)
var player_fractures: Array[int] = []

# Input state
var awaiting_choice: String = ""   # "MAIN", "GAIN_XP", "SELECT_FRACTURE"
var last_available_indices: Array[int] = []

@onready var log: RichTextLabel = %Log
@onready var input_line: LineEdit = %InputLine

# --------------------------
# Lifecycle
# --------------------------

func _ready() -> void:
    _init_attributes()
    _init_fracture_descriptions()
    _print_header()
    _show_main_menu()
    input_line.text_submitted.connect(_on_input_submitted)

func _init_attributes() -> void:
    player_attr.resize(ATTR_NAMES.size())
    for i in player_attr.size():
        player_attr[i] = 5

func _init_fracture_descriptions() -> void:
    fracture_descriptions.resize(FRACTURE_NAMES.size())
    fracture_design_notes.resize(FRACTURE_NAMES.size())

    for i in FRACTURE_NAMES.size():
        var name := FRACTURE_NAMES[i]
        match name:
            "Thirst Map":
                fracture_descriptions[i] = "Water drain slows; reclaim tanks and rigs stand out on the map."
                fracture_design_notes[i] = "water_decay_mult = 0.85, auto‑mark water sources in PlayerWaterSystem."
            "Hardened Blood":
                fracture_descriptions[i] = "Bleed less, move heavier. Stamina max and recovery dip."
                fracture_design_notes[i] = "blood_loss_mult = 0.85, stamina_max_mult = 0.9, stamina_recovery_mult = 0.9."
            "Last Tank":
                fracture_descriptions[i] = "When O2/H2O go red, you push once more. Every push scars you."
                fracture_design_notes[i] = "reactive; triggers at O2/H2O < 10%, adds move_speed_bonus +0.15, accuracy_bonus +0.1, then wellness_max_scar += 1, yield_scar += 0.1."
            "Cold Verge Runner":
                fracture_descriptions[i] = "Exterior hull cold bites slower; sprint costs less in the Verge."
                fracture_design_notes[i] = "region = COLD_VERGE, stamina_decay_mult = 0.9, temp_drop_mult = 0.8."
            "Ashveil Scavenger Routes":
                fracture_descriptions[i] = "Knows broken lanes in Ashveil; more salvage, more noise and nests."
                fracture_design_notes[i] = "loot_mult in ASHVEIL_DRIFT, encounter_chance_mult > 1.0."
            "Hull Line Marksman":
                fracture_descriptions[i] = "Scoped shots down the spine of the station land truer."
                fracture_design_notes[i] = "weapon_tag=SCOPED_RIFLE, accuracy_bonus ~0.12, crit_bonus ~0.08 in long corridors."
            "Recoil Interpreter":
                fracture_descriptions[i] = "Automatic fire walks where you tell it, if you hold the stance."
                fracture_design_notes[i] = "weapon_tag=AUTOMATIC, sustained_fire_spread_mult < 1, stamina_decay_mult > 1."
            "Spine-Breaker Rounds":
                fracture_descriptions[i] = "Penetrators tuned to pry plates open and wake everything nearby."
                fracture_design_notes[i] = "AP penetration bonus, noise_radius_mult > 1.2."
            "Thermal Baffle Webbing":
                fracture_descriptions[i] = "Cold and heat swing slower; vents hiss louder when you panic."
                fracture_design_notes[i] = "temp_drop_mult < 1, temp_rise_mult < 1, stealth_noise_mult > 1 at high Stamina use."
            "Atmos Seal Kit":
                fracture_descriptions[i] = "Suit patches small leaks, burns more O2 and water doing it."
                fracture_design_notes[i] = "small auto patch on hull breach, oxygen_decay_mult > 1, water_decay_mult > 1."
            "BCI Noise Shield":
                fracture_descriptions[i] = "Less signal‑howl in your head, fewer whispers from the dark."
                fracture_design_notes[i] = "sanity_loss_mult for signal horror < 1, subtle audio cue detection ‑Instinct."
            "Bulkhead Ghost":
                fracture_descriptions[i] = "Grating and ladders barely speak when you move right."
                fracture_design_notes[i] = "footstep_noise_mult_on_metal < 1, weakens at low stamina or high load."
            "Deep Trench Dweller":
                fracture_descriptions[i] = "Maintenance tunnels do not close in as fast on you."
                fracture_design_notes[i] = "claustrophobia wellness hits reduced, trap detection bonus in tight spaces."
            "Cold Line Runner":
                fracture_descriptions[i] = "Trained to move in freezing corridors without burning out."
                fracture_design_notes[i] = "cold_zone stamina_decay_mult < 1, temp_drop_mult < 1."
            "Oxygen Scar":
                fracture_descriptions[i] = "You learned to breathe on nothing; your mind never fully settled."
                fracture_design_notes[i] = "crisis O2 efficiency bonus, permanent wellness_max_scar and harsher capsule penalties."
            "Sterile Gut":
                fracture_descriptions[i] = "Poisons slide off; real food barely sticks."
                fracture_design_notes[i] = "poison immunity, food_heal_mult < 1, food_protein_gain_mult ~0.5."
            "Corridor Butcher":
                fracture_descriptions[i] = "Up close, nothing leaves intact. Survivors remember that."
                fracture_design_notes[i] = "melee_damage_adjacent +20%, blood_leech ~5%, Influence/Temper checks ‑2."
            "Pulse Echo":
                fracture_descriptions[i] = "Every hit might send a spasm back along the line."
                fracture_design_notes[i] = "small chance to stagger attacker; sanity decay under stress +10–15%."
            "Self-Healing Composite":
                fracture_descriptions[i] = "Armor stitches itself if you keep it out of the grinder."
                fracture_design_notes[i] = "armor_cond_regen_out_of_combat, deep_repair_nanocarbon_cost_mult > 1."
            "HazMat Overlay Harness":
                fracture_descriptions[i] = "Scrubbers keep toxins out and heat in."
                fracture_design_notes[i] = "poison/chem effect mult < 1, body_temp_rise_mult > 1."
            "Signal Mapper":
                fracture_descriptions[i] = "You can hear weak signals under the static."
                fracture_design_notes[i] = "ping reveals hidden terminals/labs, extra O2/Water cost during scans."
            "Containment Keyholder":
                fracture_descriptions[i] = "Some doors open for you and close on everyone else."
                fracture_design_notes[i] = "faction_key access to sealed decks, worsens standing with rivals."
            "Long Night Survivor":
                fracture_descriptions[i] = "You already lived through one station‑long blackout."
                fracture_design_notes[i] = "+Vitality/+Tenacity at start, minor Scarring fracture like Oxygen Scar."
            "Black-Section Asset":
                fracture_descriptions[i] = "Your file lives behind sealed clearance, so do your treatments."
                fracture_design_notes[i] = "unlocks Syndicate fractures, sanity risk and faction suspicion."
            "Deckside Myth":
                fracture_descriptions[i] = "Stories about you move faster than you do."
                fracture_design_notes[i] = "Influence checks polarised; some outposts help, some panic."
            "Containment Oath":
                fracture_descriptions[i] = "You swore certain horrors would never reach certain decks."
                fracture_design_notes[i] = "oath_bonus while obeyed; breaking adds severe Scarring fracture."
            "Cell-Marked":
                fracture_descriptions[i] = "The nanotech knows your blood and keeps a slot for itself."
                fracture_design_notes[i] = "subtle regen/healing boost; reserved progression fracture slot."
            "Faction Oath-bound":
                fracture_descriptions[i] = "You belong to one side of the station. The other knows it."
                fracture_design_notes[i] = "faction loyalty track, unique missions, betrayal → big Scarring event."
            "Companion Circuit":
                fracture_descriptions[i] = "You and your crew slot together better than most."
                fracture_design_notes[i] = "companion synergy table; faster repairs, better ambush, mixed diplomacy."
            "Prey Mesh":
                fracture_descriptions[i] = "The environment twitches before something breaks out."
                fracture_design_notes[i] = "Stealth/Inspect threat detection advantage, reduced ambush flags."
            "Oxygen Accountant":
                fracture_descriptions[i] = "You count breaths like rationchips."
                fracture_design_notes[i] = "oxygen_decay_mult < 1, capsule efficiency +15%."
            "Hull Ghost":
                fracture_descriptions[i] = "Industrial corridors feel like cover, not exposure."
                fracture_design_notes[i] = "Stealth bonus in corridors/maintenance, region‑tag aware."
            "Field Jury-Rig":
                fracture_descriptions[i] = "You keep gear running on things that were never parts."
                fracture_design_notes[i] = "field repair to ~60% condition, JURY_RIGGED tag degrades 25% faster."
            "Chem Discipline":
                fracture_descriptions[i] = "Your body obeys the dose, not the craving."
                fracture_design_notes[i] = "drug side‑effect chance ‑40%, stim heal +10% if Yield ≥ 6."
            "Cold Glass Optics":
                fracture_descriptions[i] = "Heat, smoke, dark — all just layers over the target."
                fracture_design_notes[i] = "scopes ignore part of darkness/smoke penalty at low O2/Stamina spikes."
            "Mag-Latch Reload":
                fracture_descriptions[i] = "Your hands and the mag rails share a clock."
                fracture_design_notes[i] = "platform‑specific reload buff above a Stamina threshold; slower below."
            "Adaptive Chameleon Plating":
                fracture_descriptions[i] = "Stand still and the hull forgets you for a while."
                fracture_design_notes[i] = "Stealth bonus while stationary/slow; breaks on bursts."
            "Shock Spine Dampers":
                fracture_descriptions[i] = "Falls and hits fold into the spine instead of shattering it."
                fracture_design_notes[i] = "fall_damage_mult << 1; Dexterity‑style fine checks slightly worse."
            "Dielectric Skin Mesh":
                fracture_descriptions[i] = "Arcs crawl over you instead of through you."
                fracture_design_notes[i] = "arc/EMP resistance up, blunt trauma vulnerability up."
            "Red Silence Signal Scar":
                fracture_descriptions[i] = "You remember what the scream of the nebula feels like."
                fracture_design_notes[i] = "psychic/signal horror reduction, small loss in mechanical audio perception."
            _:
                fracture_descriptions[i] = "Fracture effect not fully detailed in this shell."
                fracture_design_notes[i] = "Implement in FractureSystem and content registry."
        end
    end

func _print_header() -> void:
    log.clear()
    log.append_text("CELL: FRACTURE SYSTEM SHELL\n")
    log.append_text("Subject: %s (Level %d)\n" % [player_name, player_level])
    log.append_text("----------------------------------------\n")

# --------------------------
# Menu + input handling
# --------------------------

func _show_main_menu() -> void:
    awaiting_choice = "MAIN"
    log.append_text("\n--- Main Console ---\n")
    log.append_text("1. View Subject Sheet\n")
    log.append_text("2. Gain Experience\n")
    log.append_text("3. Select Fracture\n")
    log.append_text("4. View All Fractures\n")
    log.append_text("5. Quit Shell\n")
    log.append_text("Enter choice (1‑5) and press Enter.\n")
    input_line.text = ""
    input_line.grab_focus()

func _on_input_submitted(text: String) -> void:
    var trimmed := text.strip_edges()
    if trimmed.is_empty():
        input_line.text = ""
        return

    match awaiting_choice:
        "MAIN":
            _handle_main_choice(trimmed)
        "GAIN_XP":
            _handle_gain_xp(trimmed)
        "SELECT_FRACTURE":
            _handle_select_fracture_choice(trimmed)
        _:
            _show_main_menu()

    input_line.text = ""

func _handle_main_choice(choice: String) -> void:
    match choice:
        "1":
            _display_subject_sheet()
            _show_main_menu()
        "2":
            awaiting_choice = "GAIN_XP"
            log.append_text("\nEnter XP to gain (positive integer):\n")
        "3":
            _start_select_fracture()
        "4":
            _display_all_fractures()
            _show_main_menu()
        "5":
            log.append_text("\nSession terminated. Close this debug scene.\n")
            awaiting_choice = "NONE"
        _:
            log.append_text("\nInvalid choice. Use 1‑5.\n")
            _show_main_menu()

func _handle_gain_xp(text: String) -> void:
    var xp_val := text.to_int()
    if xp_val <= 0:
        log.append_text("\nInvalid XP amount.\n")
        _show_main_menu()
        return

    player_xp += xp_val
    log.append_text("Gained %d XP.\n" % xp_val)
    var leveled := false
    while player_xp >= xp_for_next_level:
        player_level += 1
        leveled = true
        log.append_text("Tier up. Subject is now Level %d.\n" % player_level)
        # simple random attribute gain
        var idx := randi() % ATTR_NAMES.size()
        player_attr[idx] += 1
        log.append_text("Adaptation: +1 %s\n" % ATTR_NAMES[idx])
        xp_for_next_level += 1000 + (player_level - 1) * 500
    if not leveled:
        log.append_text("No tier change. XP: %d / %d\n" % [player_xp, xp_for_next_level])

    awaiting_choice = "MAIN"
    _show_main_menu()

# --------------------------
# Fracture selection
# --------------------------

func _start_select_fracture() -> void:
    if player_level <= 1 or player_level % 2 != 0:
        log.append_text("\nNo fracture slot at this level. Current Level: %d\n" % player_level)
        _show_main_menu()
        return

    log.append_text("\n--- Available Fractures (Sample Set) ---\n")
    # For the shell, limit list to first 12 fractures
    last_available_indices.clear()
    var max_list := min(12, FRACTURE_NAMES.size())
    for k in max_list:
        last_available_indices.append(k)
        log.append_text("%d. %s\n" % [k + 1, FRACTURE_NAMES[k]])
        log.append_text("    %s\n" % fracture_descriptions[k])
    var cancel_index := max_list + 1
    log.append_text("%d. Cancel\n" % cancel_index)
    log.append_text("Choose a fracture (1‑%d):\n" % cancel_index)
    awaiting_choice = "SELECT_FRACTURE"

func _handle_select_fracture_choice(text: String) -> void:
    var choice_val := text.to_int()
    var max_list := min(12, FRACTURE_NAMES.size())
    var cancel_index := max_list + 1

    if choice_val == cancel_index:
        log.append_text("Fracture imprinting cancelled.\n")
        awaiting_choice = "MAIN"
        _show_main_menu()
        return

    if choice_val < 1 or choice_val > max_list:
        log.append_text("Invalid choice.\n")
        awaiting_choice = "MAIN"
        _show_main_menu()
        return

    var idx := choice_val - 1
    if player_fractures.has(idx):
        log.append_text("Fracture already imprinted.\n")
        awaiting_choice = "MAIN"
        _show_main_menu()
        return

    player_fractures.append(idx)
    log.append_text("Fracture \"%s\" acquired.\n" % FRACTURE_NAMES[idx])

    match FRACTURE_NAMES[idx]:
        "Thirst Map":
            log.append_text("Design note: water_decay_mult = 0.85, auto‑mark water sources.\n")
        "Hardened Blood":
            log.append_text("Design note: blood_loss_mult = 0.85, stamina_max_mult = 0.9, stamina_recovery_mult = 0.9.\n")
        "Last Tank":
            log.append_text("Design note: surge on O2/H2O < 10%, wellness_max and Yield scar per trigger.\n")
        "Cold Verge Runner":
            log.append_text("Design note: better stamina/temp handling in COLD_VERGE hull zones.\n")
        _:
            log.append_text("Design note: implement in FractureSystem + PlayerVitalitySystem.\n")

    awaiting_choice = "MAIN"
    _show_main_menu()

# --------------------------
# Display functions
# --------------------------

func _display_subject_sheet() -> void:
    log.append_text("\n--- Subject Sheet: %s ---\n" % player_name)
    log.append_text("Tier: %d\n" % player_level)
    log.append_text("XP: %d / %d\n" % [player_xp, xp_for_next_level])

    log.append_text("\nAttributes:\n")
    for i in ATTR_NAMES.size():
        log.append_text("  %s: %d\n" % [ATTR_NAMES[i], player_attr[i]])

    log.append_text("\nCore Pools (design stand‑ins):\n")
    log.append_text("  Blood:   %d\n" % blood)
    log.append_text("  Oxygen:  %d\n" % oxygen)
    log.append_text("  Water:   %d\n" % water)
    log.append_text("  Stamina: %d\n" % stamina)
    log.append_text("  Wellness:%d\n" % wellness)

    log.append_text("\nFractures:\n")
    if player_fractures.is_empty():
        log.append_text("  None\n")
    else:
        for idx in player_fractures:
            if idx >= 0 and idx < FRACTURE_NAMES.size():
                log.append_text("  %s\n" % FRACTURE_NAMES[idx])
            else:
                log.append_text("  Unknown Fracture (index: %d)\n" % idx)
    log.append_text("----------------------------------------\n")

func _display_all_fractures() -> void:
    log.append_text("\n--- All Fractures (Design List) ---\n")
    for i in FRACTURE_NAMES.size():
        log.append_text("%d. %s\n" % [i + 1, FRACTURE_NAMES[i]])
        log.append_text("    %s\n" % fracture_descriptions[i])
    log.append_text("----------------------------------------\n")
