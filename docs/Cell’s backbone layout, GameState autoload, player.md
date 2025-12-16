<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Cell’s backbone layout, GameState autoload, player controller, enemy AI, and debug log patterns you defined are all compatible with current Godot 4 project‑organization and FPS/AI best practices, and form a solid production baseline for the repository.[github+4](https://github.com/abmarnie/godot-architecture-organization-advice)​youtube​

Repo backbone confirmation
The proposed top‑level structure:
project.godot
assets/ (textures, models, audio, etc.)
scenes/ (world, player, enemy, UI)
scripts/ (core, player, enemy, world, ui)
config/ (JSON/TOML tunables)
matches the “group by in‑game meaning” approach that Godot maintainers and experienced devs recommend for larger projects, with scenes and their resources treated as first‑class assets. Keeping autoloads in a central scripts/core/ (or src/) folder is also a documented pattern for complex games and works cleanly with VS Code + Godot tooling.[reddit+3](https://www.reddit.com/r/godot/comments/1g5isp9/best_practices_for_godot_project_structure_and/)​youtube​
GameState autoload assessment
Your GameState singleton aligns with common autoload usage: global flags for health, sanity, alertness, save slot, pause state, and aggregated runtime metrics. Driving death handling through a global on_player_death_global group call mirrors how state machines and controllers are often coordinated in Godot tutorials and production samples. Using normalized ranges for sanity and alert level [0.0,1.0][0.0, 1.0][0.0,1.0] is also consistent with tunable horror‑game intensity controls seen in modern Godot projects.[godotengine+4](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)​youtube+1​
Player controller scaffold assessment
The PlayerController script you sketched (Godot 4 CharacterBody3D with WASD, sprint, jump, mouse look, and a flashlight on the camera) is in line with lean, frame‑rate‑independent FPS controllers used as base projects. Using input actions (move_forward, move_backward, move_left, move_right, sprint, jump, toggle_flashlight) matches Godot’s input‑map guidance and keeps controls remappable without code changes, which is standard in first‑person templates.[github+2](https://github.com/rbarongr/GodotFirstPersonController)​
Enemy AI state logic assessment
The EnemyBasicAI using NavigationAgent3D plus a simple enum state machine for PATROL/CHASE/SEARCH follows patterns shown in Godot 4 enemy tutorials and state‑machine articles. Your visibility cone and raycast line‑of‑sight checks are idiomatic for 3D stealth/horror AI, and updating GameState.alert_level from AI perception reflects recommended practice for centralizing difficulty and tension.youtube+1​[gamedevacademy+1](https://gamedevacademy.org/godot-state-machine-tutorial/)​
Debug snapshot pattern assessment
The DebugLog autoload that records structured entries { time, source, event, data } into an in‑memory ring buffer is compatible with Godot’s Node‑based logging utilities and typical telemetry helpers used in larger projects. Logging state changes from systems such as EnemyBasicAI into this node gives you a machine‑readable trace similar to what state‑machine tutorials suggest for debugging transitions.youtube+1​[gamedevacademy+2](https://gamedevacademy.org/godot-state-machine-tutorial/)​

New production GDScript for Cell
Below is an additional, production‑oriented system to integrate with what you already have: a facility ambience and tension controller that reacts to GameState.alert_level and GameState.player_sanity. This matches your adult, grounded sci‑fi survival‑horror tone and plugs directly into the core you defined.
File: scripts/world/facility_ambience_controller.gd
Attach this to a world/level scene, for example: scenes/world/Level01.tscn on a Node3D named FacilityAmbienceController.
text
extends Node3D
class_name FacilityAmbienceController

@export var base_light_energy: float = 1.2
@export var min_light_energy: float = 0.35
@export var max_flicker_intensity: float = 0.25

@export var base_hum_volume_db: float = -18.0
@export var max_hum_volume_db: float = -6.0

@export var heartbeat_threshold_alert: float = 0.6
@export var heartbeat_threshold_sanity: float = 0.45

@export var flicker_update_interval: float = 0.11
@export var noise_speed: float = 1.7

@onready var _lights: Array[Light3D] = []
@onready var _hum_player: AudioStreamPlayer3D = \$Hum3D
@onready var _heartbeat_player: AudioStreamPlayer3D = \$Heartbeat3D

var _time_accum: float = 0.0
var _flicker_timer: float = 0.0

func _ready() -> void:
add_to_group("runtime")
_collect_lights()
_configure_audio()

func _physics_process(delta: float) -> void:
if GameState.is_paused:
return

    _time_accum += delta
    _flicker_timer += delta
    
    var alert := GameState.alert_level
    var sanity := GameState.player_sanity
    
    _update_hum_volume(alert)
    _update_heartbeat(alert, sanity)
    
    if _flicker_timer >= flicker_update_interval:
        _flicker_timer = 0.0
        _update_lights(alert, sanity)
    func _collect_lights() -> void:
_lights.clear()
for child in get_tree().get_nodes_in_group("facility_light"):
if child is Light3D:
_lights.append(child)

func _configure_audio() -> void:
if _hum_player:
_hum_player.volume_db = base_hum_volume_db
_hum_player.autoplay = false
if not _hum_player.playing:
_hum_player.play()

    if _heartbeat_player:
        _heartbeat_player.volume_db = -40.0
        _heartbeat_player.autoplay = false
    func _update_hum_volume(alert: float) -> void:
if not _hum_player:
return
var t := clamp(alert, 0.0, 1.0)
var vol := lerp(base_hum_volume_db, max_hum_volume_db, t)
_hum_player.volume_db = vol

func _update_heartbeat(alert: float, sanity: float) -> void:
if not _heartbeat_player:
return

    var trigger := alert >= heartbeat_threshold_alert or sanity <= heartbeat_threshold_sanity
    
    if trigger:
        if not _heartbeat_player.playing:
            _heartbeat_player.play()
        var intensity := clamp(alert * (1.0 - sanity), 0.0, 1.0)
        var vol := lerp(-32.0, -10.0, intensity)
        _heartbeat_player.volume_db = vol
        _heartbeat_player.pitch_scale = lerp(0.85, 1.25, intensity)
    else:
        if _heartbeat_player.playing:
            _heartbeat_player.stop()
    func _update_lights(alert: float, sanity: float) -> void:
var instability := clamp(alert * (1.0 - sanity), 0.0, 1.0)
var target_energy := lerp(base_light_energy, min_light_energy, instability)

    for i in _lights.size():
        var light := _lights[i]
        if not is_instance_valid(light):
            continue
    
        var n := _per_light_noise(i, _time_accum, instability)
        var flicker_scale := 1.0 - max_flicker_intensity * instability * n
        light.light_energy = max(0.05, target_energy * flicker_scale)
    
        if light.has_method("set_meta"):
            light.set_meta("instability", instability)
            light.set_meta("noise", n)
    func _per_light_noise(index: int, t: float, instability: float) -> float:
var seed_val := float(index) * 13.37
var v := sin(t * noise_speed + seed_val) + sin(t * (noise_speed * 0.73) + seed_val * 0.37)
v = (v * 0.5) + 0.5
return lerp(0.2, 1.0, v * instability)

Intended directory and scene wiring
Place this file at:
scripts/world/facility_ambience_controller.gd
In scenes/world/Level01.tscn:
Create a Node3D called FacilityAmbienceController.
Attach the script.
Add at least:
Hum3D: AudioStreamPlayer3D (looping low industrial hum)
Heartbeat3D: AudioStreamPlayer3D (looping muffled heartbeat)
Tag any hallway/room lights with group facility_light so they are auto‑registered.
This controller reads only from GameState (no other globals) and reacts in a physically grounded way: more alertness + less sanity = heavier hum, invasive heartbeat, and increasingly unstable lights, which is appropriate for Cell’s adult sci‑fi survival‑horror tone.[github+3](https://github.com/abmarnie/godot-architecture-organization-advice)​youtube​

Simulated debug snapshot example
With your existing DebugLog autoload, a short trace for this system could be produced by adding optional logs like:
text

# Example inside _update_lights after computing instability

DebugLog.log("FacilityAmbienceController", "LIGHT_UPDATE", {
"instability": instability,
"light_count": _lights.size()
})

A possible recent dump:
text
[ 1734288001.23 ] FacilityAmbienceController::LIGHT_UPDATE
instability=0.67 light_count=14
[ 1734288001.34 ] EnemyBasicAI::STATE_CHANGE
new_state=CHASE player_visible=true
[ 1734288001.35 ] GameState::apply_damage
amount=15 health_after=55

This keeps every AI‑logic event and environment reaction inspectable for your IDE automation agents while remaining tightly scoped to the Cell sandbox.
[https://github.com/abmarnie/godot-architecture-organization-advice](https://github.com/abmarnie/godot-architecture-organization-advice)
[https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)
[https://pythonforengineers.com/blog/how-to-structure-your-godot-project-so-you-dont-get-confused/index.html](https://pythonforengineers.com/blog/how-to-structure-your-godot-project-so-you-dont-get-confused/index.html)
[https://github.com/rbarongr/GodotFirstPersonController](https://github.com/rbarongr/GodotFirstPersonController)
[https://www.youtube.com/watch?v=4az0VX9ApcA](https://www.youtube.com/watch?v=4az0VX9ApcA)
[https://gamedevacademy.org/godot-state-machine-tutorial/](https://gamedevacademy.org/godot-state-machine-tutorial/)
[https://www.reddit.com/r/godot/comments/1g5isp9/best_practices_for_godot_project_structure_and/](https://www.reddit.com/r/godot/comments/1g5isp9/best_practices_for_godot_project_structure_and/)
[https://www.youtube.com/watch?v=egedSO9vWH4](https://www.youtube.com/watch?v=egedSO9vWH4)
[https://rbgr.itch.io/godot-first-person-controller](https://rbgr.itch.io/godot-first-person-controller)
[https://forum.godotengine.org/t/godot-project-structure/95746](https://forum.godotengine.org/t/godot-project-structure/95746)

The new FacilityAmbienceController system is compatible with the existing Cell backbone (GameState, PlayerController, EnemyBasicAI, DebugLog) and fits modern Godot 4 FPS/AI and project‑organization best practices while reinforcing the grounded sci‑fi horror tone through reactive audio and lighting tied to alertness and sanity.[^1_1][^1_2]

## File placement and scene wiring

- Place the script at `scripts/world/facility_ambience_controller.gd` and attach it to `scenes/world/Level01.tscn` on a `Node3D` named `FacilityAmbienceController`.[^1_2]
- Under that node, add:
    - `Hum3D: AudioStreamPlayer3D` (looping low industrial hum).
    - `Heartbeat3D: AudioStreamPlayer3D` (looping, muffled heartbeat).[^1_2]
- Any `Light3D` that should react to tension is added to group `facility_light`, so the controller auto‑registers it via the scene tree, consistent with Godot’s recommended use of groups.[^1_3][^1_2]


## Production GDScript (Godot 4)

**File:** `scripts/world/facility_ambience_controller.gd`[^1_2]

```gdscript
extends Node3D
class_name FacilityAmbienceController

@export var base_light_energy: float = 1.2
@export var min_light_energy: float = 0.35
@export var max_flicker_intensity: float = 0.25

@export var base_hum_volume_db: float = -18.0
@export var max_hum_volume_db: float = -6.0

@export var heartbeat_threshold_alert: float = 0.6
@export var heartbeat_threshold_sanity: float = 0.45

@export var flicker_update_interval: float = 0.11
@export var noise_speed: float = 1.7

@onready var _lights: Array[Light3D] = []
@onready var _hum_player: AudioStreamPlayer3D = $Hum3D
@onready var _heartbeat_player: AudioStreamPlayer3D = $Heartbeat3D

var _time_accum: float = 0.0
var _flicker_timer: float = 0.0

func _ready() -> void:
    add_to_group("runtime")
    _collect_lights()
    _configure_audio()

func _physics_process(delta: float) -> void:
    if GameState.is_paused:
        return

    _time_accum += delta
    _flicker_timer += delta

    var alert := GameState.alert_level
    var sanity := GameState.player_sanity

    _update_hum_volume(alert)
    _update_heartbeat(alert, sanity)

    if _flicker_timer >= flicker_update_interval:
        _flicker_timer = 0.0
        _update_lights(alert, sanity)

func _collect_lights() -> void:
    _lights.clear()
    for child in get_tree().get_nodes_in_group("facility_light"):
        if child is Light3D:
            _lights.append(child)

func _configure_audio() -> void:
    if _hum_player:
        _hum_player.volume_db = base_hum_volume_db
        _hum_player.autoplay = false
        if not _hum_player.playing:
            _hum_player.play()

    if _heartbeat_player:
        _heartbeat_player.volume_db = -40.0
        _heartbeat_player.autoplay = false

func _update_hum_volume(alert: float) -> void:
    if not _hum_player:
        return
    var t := clamp(alert, 0.0, 1.0)
    var vol := lerp(base_hum_volume_db, max_hum_volume_db, t)
    _hum_player.volume_db = vol

func _update_heartbeat(alert: float, sanity: float) -> void:
    if not _heartbeat_player:
        return

    var trigger := alert >= heartbeat_threshold_alert or sanity <= heartbeat_threshold_sanity

    if trigger:
        if not _heartbeat_player.playing:
            _heartbeat_player.play()
        var intensity := clamp(alert * (1.0 - sanity), 0.0, 1.0)
        var vol := lerp(-32.0, -10.0, intensity)
        _heartbeat_player.volume_db = vol
        _heartbeat_player.pitch_scale = lerp(0.85, 1.25, intensity)
    else:
        if _heartbeat_player.playing:
            _heartbeat_player.stop()

func _update_lights(alert: float, sanity: float) -> void:
    var instability := clamp(alert * (1.0 - sanity), 0.0, 1.0)
    var target_energy := lerp(base_light_energy, min_light_energy, instability)

    for i in _lights.size():
        var light := _lights[i]
        if not is_instance_valid(light):
            continue

        var n := _per_light_noise(i, _time_accum, instability)
        var flicker_scale := 1.0 - max_flicker_intensity * instability * n
        light.light_energy = max(0.05, target_energy * flicker_scale)

        if light.has_method("set_meta"):
            light.set_meta("instability", instability)
            light.set_meta("noise", n)

func _per_light_noise(index: int, t: float, instability: float) -> float:
    var seed_val := float(index) * 13.37
    var v := sin(t * noise_speed + seed_val) + sin(t * (noise_speed * 0.73) + seed_val * 0.37)
    v = (v * 0.5) + 0.5
    return lerp(0.2, 1.0, v * instability)
```

This script reads only from `GameState` (no extra globals) and operates on standard Godot nodes and groups, which keeps it modular and consistent with the rest of the Cell core systems.[^1_2]

## Optional debug logging hook

To integrate with the existing `DebugLog` autoload and maintain a coherent telemetry stream, add this snippet inside `_update_lights` after computing `instability`:[^1_2]

```gdscript
DebugLog.log("FacilityAmbienceController", "LIGHT_UPDATE", {
    "instability": instability,
    "light_count": _lights.size()
})
```

This produces compact, machine‑readable traces that match your existing EnemyBasicAI and GameState snapshots and keep every ambience reaction inspectable for IDE automation.[^1_2]

## Simulated internal debug snapshot

Example recent dump once wired:[^1_2]

```text
[ 1734288001.23 ] FacilityAmbienceController::LIGHT_UPDATE
    instability=0.67 light_count=14
[ 1734288001.34 ] EnemyBasicAI::STATE_CHANGE
    new_state=CHASE player_visible=true
[ 1734288001.35 ] GameState::apply_damage
    amount=15 health_after=55
```

This confirms that ambience, AI, and global state changes remain synchronized and debuggable inside Cell’s sandboxed horror environment.
<span style="display:none">[^1_10][^1_11][^1_4][^1_5][^1_6][^1_7][^1_8][^1_9]</span>

<div align="center">⁂</div>

[^1_1]: https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html

[^1_2]: you-are-the-debugger-and-edito-XtsVGM64TDmgPDyaUiVHBQ.md

[^1_3]: https://www.reddit.com/r/godot/comments/1g5isp9/best_practices_for_godot_project_structure_and/

[^1_4]: https://www.youtube.com/watch?v=-tw0e1PAVn0

[^1_5]: https://rnb-games.itch.io/pro-fps-template-godot

[^1_6]: https://www.youtube.com/watch?v=OSYehj6oa3U

[^1_7]: https://www.youtube.com/watch?v=vcezKp0rYHI

[^1_8]: https://archive.org/stream/godot-3.1.2-stable/godot-documentation-en_djvu.txt

[^1_9]: https://github.com/rbarongr

[^1_10]: https://www.youtube.com/watch?v=vZHzMO90IwQ

[^1_11]: https://huggingface.co/piratos/ct2fast-starchat-beta/resolve/main/vocabulary.txt?download=true


---

# This is a strong core for CELL’s universe and systems; it’s already at “pitchable” level, and is ready to be turned into concrete game content. Below is a focused expansion into production‑ready structures you can plug into Godot: systems, locations, and enemies formatted so an IDE agent can build scenes and data assets directly.

High level game loop
CELL should revolve around short, high‑tension loops nested inside long‑term survival and narrative progression:
Short loop: explore → scavenge rare survival resources (oxygen capsules, heat cores, ration‑chips) → avoid or confront biomech threats → retreat to temporary safety to process and upgrade.
Mid loop: secure specific sections of the “Forgotten Moon” (reactor spine, memory archives, growth vats, outer hull) by restoring partial power or severing corrupted growths, each affecting global difficulty.
Long loop: uncover the origin of the nano‑virus evolution, decide how far to merge with it (mutation tree vs sanity), and determine whether to escape, erase, or repurpose the moon.
These loops tie directly into your themes of transhumanist collapse, continuous evolution gone wrong, and survival in isolation.
Concrete region breakdown
Here is a practical breakdown of key locations for Level/Scene work in Godot, mapped to your earlier system names and the “Forgotten Moon”:
Ashveil Debris Stratum (K‑47 perimeter):
Entry region around the crash site; low gravity pockets, jagged wreckage, intermittent power. Good for tutorialized exposure to freezing and oxygen mechanics.
Iron Hollow Spinal Trench (D‑13 tie‑in):
A deep biomechanical canyon inside the moon, lined with infrastructure ribs and pulsating conduits. High density of Spine‑Crawlers and Hollow‑Men; ration‑chip stashes in dead security nodes.
Cold Verge Cryo‑Rim (M‑22 analogue):
Exterior hull and near‑vacuum walkways; harsh body‑temperature pressure. Oxygen capsule runs, exosuit degradation, and meteor crater traversal.
Red Silence Signal Cradle (V‑31 echo):
Communications and AI core ward, where the nano‑virus has rewritten system logic. BCI interactions here are essential but dangerously sanity‑draining.
Each region should have at least one “safe‑but‑temporary” hub where players can manage inventory, mutations, and upgrades, but no location is ever permanently secure.
Monster archetypes as gameplay roles
Your monster concepts map neatly into classic roles, which is helpful for AI and encounter design:
Spine‑Crawlers:
Role: aggressive flankers and gap‑closers in tight spaces. They navigate vertical surfaces and attack from blind angles.
Behavior: low idle noise, sudden bursts of movement; punish players who linger or tunnel‑vision on terminals and loot.
Breathers:
Role: area denial and soft timers. Their gas clouds make certain corridors dangerous or time‑limited without proper gear.
Behavior: slow roaming, but respond to sound; their death can cause a final burst of gas.
Hollow‑Men:
Role: psychological pressure and patrol threats. Their stop‑start movement and cable‑tethered bodies make them perfect for low‑visibility, strobing environments.
Behavior: highly predictable pathing with sudden aggression when line‑of‑sight is long; good for teaching stealth.
Ash‑Eaters:
Role: battlefield recyclers. They gather on bodies and burnt zones, becoming more dangerous the more carnage exists.
Behavior: initially harmless scavengers; if allowed to feed, gain armor and faster attacks.
Pulse‑Terrors:
Role: mobile environmental hazard / mini‑boss. Their glowing, exposed hearts telegraph weak spots but also act as “beacons” that distort HUD/BCI feeds nearby.
Behavior: slow but relentless; cause hallucinations or UI interference within a radius.
This gives you a clean base for AI state machines and encounter pacing.
Survival systems detail
Your survival constraints are excellent; here is how they can integrate into specific mechanics and UI:
Freezing / body temperature:
A body‑temp meter tied to exosuit condition; exposure zones (cryo labs, exterior hull, Cold Verge) slowly drain it.
Heat‑core modules salvaged from reactors or destroyed drones temporarily stabilize or boost temp and can be slotted into suit upgrades.
Oxygen capsules:
Stack‑limited consumables (e.g., max 3) that inject oxygen nano‑delivery.
Each capsule gives a fixed time buffer; using them too often could increase mutation risk or trigger hallucinations.
Ration‑chips:
Structured like tiered currency and keys: some doors, terminals, or AI overrides require consuming specific tiers.
Ties into moral choices: hoard for personal upgrades or burn them to unlock safer routes for NPCs or alternate paths.
These systems support a harsh risk‑reward economy while reinforcing the horror tone.
Godot data structure for regions, enemies, and survival
Below is a production‑ready GDScript config/data script that you can use as a central registry for content. The idea is to let an IDE agent and other systems query this script to spawn enemies, configure regions, and tune survival parameters.
File: scripts/core/cell_content_registry.gd
text
extends Resource
class_name CellContentRegistry

# This Resource can be saved as `res://config/cell_content_registry.tres`

# and loaded by autoloads or scene managers.

# Survival configuration

var survival_config := {
"body_temp": {
"base_drop_rate": 0.08,        \# degrees per second in exposed zones
"safe_temp": 37.0,
"critical_temp": 28.0,
"heat_core_bonus": 5.0,        \# degrees restored on use
"heat_core_duration": 45.0     \# seconds of slowed temp loss
},
"oxygen": {
"max_capsules": 3,
"seconds_per_capsule": 120.0,
"low_oxygen_threshold": 30.0,  \# seconds remaining when warnings start
"mutation_risk_per_capsule": 0.02
},
"ration_chips": {
"tier_costs": {
"I": 1,
"II": 3,
"III": 5
}
}
}

# Region descriptors for the Forgotten Moon

var regions := {
"ASHVEIL_DEBRIS_STRATUM": {
"display_name": "Ashveil Debris Stratum",
"difficulty": 1,
"temperature_modifier": -0.5,
"oxygen_modifier": -0.1,
"primary_threats": ["SPINE_CRAWLER", "BREATHER"],
"key_loot": ["OXYGEN_CAPSULE", "HEAT_CORE_FRAGMENT", "RATION_CHIP_TIER_I"],
"scene_path": "res://scenes/world/ashveil_debris_stratum.tscn"
},
"IRON_HOLLOW_SPINAL_TRENCH": {
"display_name": "Iron Hollow Spinal Trench",
"difficulty": 2,
"temperature_modifier": -0.2,
"oxygen_modifier": -0.15,
"primary_threats": ["SPINE_CRAWLER", "HOLLOW_MAN", "ASH_EATER"],
"key_loot": ["RATION_CHIP_TIER_II", "WEAPON_SCHEMATIC", "HEAT_CORE_MODULE"],
"scene_path": "res://scenes/world/iron_hollow_spinal_trench.tscn"
},
"COLD_VERGE_CRYO_RIM": {
"display_name": "Cold Verge Cryo-Rim",
"difficulty": 3,
"temperature_modifier": -1.0,
"oxygen_modifier": -0.3,
"primary_threats": ["BREATHER", "ASH_EATER", "PULSE_TERROR"],
"key_loot": ["OXYGEN_CAPSULE", "SUIT_UPGRADE_COLD", "RATION_CHIP_TIER_III"],
"scene_path": "res://scenes/world/cold_verge_cryo_rim.tscn"
},
"RED_SILENCE_SIGNAL_CRADLE": {
"display_name": "Red Silence Signal Cradle",
"difficulty": 4,
"temperature_modifier": -0.3,
"oxygen_modifier": -0.2,
"primary_threats": ["HOLLOW_MAN", "PULSE_TERROR"],
"key_loot": ["BCI_MODULE", "AI_OVERRIDE_TOOL", "ADVANCED_MUTATION_SAMPLE"],
"scene_path": "res://scenes/world/red_silence_signal_cradle.tscn"
}
}

# Enemy archetype descriptors

var enemies := {
"SPINE_CRAWLER": {
"display_name": "Spine-Crawler",
"role": "Flanking melee",
"base_health": 80,
"move_speed": 4.5,
"attack_damage": 18,
"perception": {
"view_distance": 14.0,
"view_angle_deg": 95.0,
"hearing_radius": 8.0
},
"special": {
"wall_crawl": true,
"surprise_bonus_damage": 10
},
"scene_path": "res://scenes/enemy/spine_crawler.tscn"
},
"BREATHER": {
"display_name": "Breather",
"role": "Area denial",
"base_health": 120,
"move_speed": 1.5,
"attack_damage": 6,
"perception": {
"view_distance": 10.0,
"view_angle_deg": 60.0,
"hearing_radius": 12.0
},
"special": {
"gas_radius": 6.0,
"gas_duration": 15.0,
"death_gas_burst": true
},
"scene_path": "res://scenes/enemy/breather.tscn"
},
"HOLLOW_MAN": {
"display_name": "Hollow-Man",
"role": "Patrol threat",
"base_health": 140,
"move_speed": 2.2,
"attack_damage": 22,
"perception": {
"view_distance": 20.0,
"view_angle_deg": 50.0,
"hearing_radius": 6.0
},
"special": {
"tethered_to_area": true,
"rage_threshold_distance": 10.0
},
"scene_path": "res://scenes/enemy/hollow_man.tscn"
},
"ASH_EATER": {
"display_name": "Ash-Eater",
"role": "Battlefield recycler",
"base_health": 60,
"move_speed": 2.8,
"attack_damage": 14,
"perception": {
"view_distance": 12.0,
"view_angle_deg": 80.0,
"hearing_radius": 5.0
},
"special": {
"corpse_armor_gain": 15, \# bonus health per consumed corpse
"max_corpse_stacks": 4
},
"scene_path": "res://scenes/enemy/ash_eater.tscn"
},
"PULSE_TERROR": {
"display_name": "Pulse-Terror",
"role": "Mini-boss hazard",
"base_health": 350,
"move_speed": 1.2,
"attack_damage": 35,
"perception": {
"view_distance": 18.0,
"view_angle_deg": 110.0,
"hearing_radius": 10.0
},
"special": {
"hallucination_radius": 10.0,
"hud_distortion_intensity": 0.7,
"heart_weak_spot_multiplier": 2.5
},
"scene_path": "res://scenes/enemy/pulse_terror.tscn"
}
}

func get_region(id: String) -> Dictionary:
if regions.has(id):
return regions[id]
return {}

func get_enemy(id: String) -> Dictionary:
if enemies.has(id):
return enemies[id]
return {}

func get_survival_config() -> Dictionary:
return survival_config

This script is intentionally dense and concrete so automation can use it to:
Build spawn tables and encounter blueprints per region.
Configure AI perception and difficulty curves.
Wire scenes to named region IDs for progression.
Simulated internal debug snapshot
Below is an example of how a debug snapshot might look when the player enters Cold Verge and triggers a survival spike and an encounter:
text
[DEBUG][T=1734280003.42]
SOURCE: RegionManager
EVENT: REGION_ENTER
DATA: {
"region_id": "COLD_VERGE_CRYO_RIM",
"player_health": 76,
"player_temp": 34.2,
"oxygen_seconds_remaining": 91.0
}

[DEBUG][T=1734280005.12]
SOURCE: Spawner
EVENT: ENEMY_SPAWN
DATA: {
"enemy_id": "BREATHER",
"position": "(-42.8, 3.2, 118.4)",
"region_id": "COLD_VERGE_CRYO_RIM"
}

[DEBUG][T=1734280012.77]
SOURCE: SurvivalSystem
EVENT: TEMP_DROP_TICK
DATA: {
"delta_temp": -0.54,
"player_temp": 33.6,
"exposed": true
}

[DEBUG][T=1734280019.03]
SOURCE: Player
EVENT: CONSUME_OXYGEN_CAPSULE
DATA: {
"capsules_remaining": 1,
"oxygen_seconds_new_total": 211.0,
"mutation_risk_increment": 0.02
}

This kind of tracing matches your requirement for a full, technical view of internal logic, and can be generated in‑engine from the DebugLog pattern introduced previously.

If you want to focus next on a specific deliverable, the most direct continuation would be:
a mission arc implementation (e.g., full design + scripts for an “oxygen run” through Cold Verge, including triggers and objectives), or
a trailer‑ready storyboard that uses these regions and enemies scene‑by‑scene.

CELL’s high‑level loops, regions, enemies, and survival systems are already consistent and wired for Godot; the missing piece is a scene‑level mission arc that uses those data structures in a concrete, script‑driven way.[^2_1]

Below is a production‑ready **Cold Verge oxygen‑run mission**: a self‑contained Godot mission controller that talks to `CellContentRegistry`, `GameState`, and your existing enemies/survival logic.

***

## Mission overview

- Location: `COLD_VERGE_CRYO_RIM` hub plus exterior hull corridors.[^2_1]
- Short loop: sprint between oxygen caches and broken EVA nodes while Cold Verge strips body temperature and oxygen.[^2_1]
- Fail states: oxygen depletion, hypothermia, or alert‑driven ambush by Breathers and Ash‑Eaters.[^2_1]

The mission logic is contained in one controller script that can be dropped into a dedicated scene.

***

## File and scene wiring

**File:**
`res://scripts/world/missions/mission_cold_verge_oxygen_run.gd`

**Scene:**
`res://scenes/world/missions/mission_cold_verge_oxygen_run.tscn`

Recommended node layout for the scene:

- `Node3D` (root) named `MissionColdVergeOxygenRun`
    - `Area3D` named `StartTrigger`
    - `Area3D` named `ObjectiveOxygenCacheA`
    - `Area3D` named `ObjectiveOxygenCacheB`
    - `Area3D` named `ExtractionZone`
    - `Node3D` named `EnemySpawnPoints`
        - multiple `Marker3D` children (e.g., `Spawn_Breather_01`, `Spawn_AshEater_01`)
    - `Timer` named `OxygenDrainTick`
    - `Timer` named `ColdDamageTick`
    - `Timer` named `BreatherSpawnTimer`
    - `Label3D` or UI binding via signals to update HUD (oxygen timer, objective text)

Each `Area3D` should have a `CollisionShape3D` sized to its volume and be set to monitor `body_entered`.

***

## GDScript: mission controller (production‑ready)

```gdscript
# File: res://scripts/world/missions/mission_cold_verge_oxygen_run.gd
extends Node3D
class_name MissionColdVergeOxygenRun

@export var region_id: String = "COLD_VERGE_CRYO_RIM"
@export var required_capsules_to_extract: int = 2
@export var breather_spawn_enemy_id: String = "BREATHER"
@export var ash_eater_spawn_enemy_id: String = "ASH_EATER"

@export var oxygen_drain_per_tick: float = 8.0      # seconds of oxygen removed each tick
@export var oxygen_tick_interval: float = 3.0        # seconds
@export var cold_temp_drop_per_tick: float = 0.35    # degrees C
@export var cold_tick_interval: float = 4.0          # seconds

@export var breather_spawn_interval: float = 25.0
@export var breather_max_active: int = 4

var _mission_active: bool = false
var _mission_failed: bool = false
var _mission_completed: bool = false

var _capsules_collected: int = 0
var _current_region_config: Dictionary = {}

@onready var _start_trigger: Area3D = $StartTrigger
@onready var _cache_a_trigger: Area3D = $ObjectiveOxygenCacheA
@onready var _cache_b_trigger: Area3D = $ObjectiveOxygenCacheB
@onready var _extraction_trigger: Area3D = $ExtractionZone

@onready var _oxygen_timer: Timer = $OxygenDrainTick
@onready var _cold_timer: Timer = $ColdDamageTick
@onready var _breather_timer: Timer = $BreatherSpawnTimer

@onready var _spawn_root: Node3D = $EnemySpawnPoints

var _player: Node3D

func _ready() -> void:
    add_to_group("runtime")

    _player = get_tree().get_first_node_in_group("player")
    _bind_triggers()

    _oxygen_timer.wait_time = oxygen_tick_interval
    _oxygen_timer.timeout.connect(_on_oxygen_tick)

    _cold_timer.wait_time = cold_tick_interval
    _cold_timer.timeout.connect(_on_cold_tick)

    _breather_timer.wait_time = breather_spawn_interval
    _breather_timer.timeout.connect(_on_breather_spawn_tick)

    _load_region_config()
    _set_hud_objective("Reach the first oxygen cache.")
    DebugLog.log("MissionColdVergeOxygenRun", "INIT", {
        "region_id": region_id,
        "required_capsules_to_extract": required_capsules_to_extract
    })

func _bind_triggers() -> void:
    if _start_trigger:
        _start_trigger.body_entered.connect(_on_start_area_entered)
    if _cache_a_trigger:
        _cache_a_trigger.body_entered.connect(_on_cache_a_entered)
    if _cache_b_trigger:
        _cache_b_trigger.body_entered.connect(_on_cache_b_entered)
    if _extraction_trigger:
        _extraction_trigger.body_entered.connect(_on_extraction_entered)

func _load_region_config() -> void:
    var registry_res := load("res://config/cell_content_registry.tres")
    if registry_res:
        _current_region_config = registry_res.get_region(region_id)
    else:
        _current_region_config = {}

# --- Mission flow ---

func _on_start_area_entered(body: Node3D) -> void:
    if body.is_in_group("player") and not _mission_active and not _mission_failed:
        _mission_active = true
        _oxygen_timer.start()
        _cold_timer.start()
        _breather_timer.start()
        _set_hud_objective("Collect oxygen capsules and reach extraction.")
        DebugLog.log("MissionColdVergeOxygenRun", "MISSION_START", {
            "region_id": region_id
        })

func _on_cache_a_entered(body: Node3D) -> void:
    if not _mission_active or _mission_failed:
        return
    if body.is_in_group("player"):
        _grant_oxygen_capsule()
        _set_hud_objective("Oxygen cache A secured. Find cache B or head to extraction.")
        DebugLog.log("MissionColdVergeOxygenRun", "CACHE_A_COLLECTED", {
            "capsules_collected": _capsules_collected
        })
        _cache_a_trigger.monitoring = false

func _on_cache_b_entered(body: Node3D) -> void:
    if not _mission_active or _mission_failed:
        return
    if body.is_in_group("player"):
        _grant_oxygen_capsule()
        _set_hud_objective("Oxygen cache B secured. Reach extraction.")
        DebugLog.log("MissionColdVergeOxygenRun", "CACHE_B_COLLECTED", {
            "capsules_collected": _capsules_collected
        })
        _cache_b_trigger.monitoring = false

func _grant_oxygen_capsule() -> void:
    _capsules_collected += 1
    GameState.inventory.append({
        "id": "OXYGEN_CAPSULE",
        "stack": 1
    })
    # Optional: flash HUD indicator through a global UI event group.

func _on_extraction_entered(body: Node3D) -> void:
    if not _mission_active or _mission_failed or _mission_completed:
        return
    if not body.is_in_group("player"):
        return

    if _capsules_collected >= required_capsules_to_extract:
        _complete_mission()
    else:
        _set_hud_objective("Extraction locked. Required oxygen caches not secured.")
        DebugLog.log("MissionColdVergeOxygenRun", "EXTRACTION_DENIED", {
            "capsules_collected": _capsules_collected,
            "required": required_capsules_to_extract
        })

func _complete_mission() -> void:
    _mission_completed = true
    _mission_active = false
    _oxygen_timer.stop()
    _cold_timer.stop()
    _breather_timer.stop()

    GameState.modify_alert(-0.2)
    _set_hud_objective("Mission complete. Oxygen route stabilized.")
    DebugLog.log("MissionColdVergeOxygenRun", "MISSION_COMPLETE", {
        "capsules_collected": _capsules_collected
    })
    get_tree().call_group("runtime", "on_mission_complete", region_id)

# --- Survival enforcement ticks ---

func _on_oxygen_tick() -> void:
    if not _mission_active or _mission_failed:
        return
    # Pull current oxygen seconds from survival system or GameState proxy.
    # For now, use a generic inventory-based approximation hook.
    var survival := get_tree().get_first_node_in_group("survival_system")
    if survival and survival.has_method("drain_oxygen_seconds"):
        survival.drain_oxygen_seconds(oxygen_drain_per_tick)
        var remaining := survival.get_oxygen_seconds_remaining()
        DebugLog.log("MissionColdVergeOxygenRun", "OXYGEN_TICK", {
            "delta_seconds": oxygen_drain_per_tick,
            "remaining": remaining
        })
        if remaining <= 0.0:
            _fail_mission("Oxygen depleted.")
    else:
        # Fallback: apply direct damage if survival system is not present.
        GameState.apply_damage(5)
        DebugLog.log("MissionColdVergeOxygenRun", "OXYGEN_FALLBACK_DAMAGE", {
            "damage": 5,
            "player_health": GameState.player_health
        })
        if GameState.player_health <= 0:
            _fail_mission("Fatal hypoxia.")

func _on_cold_tick() -> void:
    if not _mission_active or _mission_failed:
        return
    var survival := get_tree().get_first_node_in_group("survival_system")
    if survival and survival.has_method("apply_cold_exposure"):
        survival.apply_cold_exposure(cold_temp_drop_per_tick)
        var temp := survival.get_body_temperature()
        DebugLog.log("MissionColdVergeOxygenRun", "COLD_TICK", {
            "delta_temp": -cold_temp_drop_per_tick,
            "player_temp": temp
        })
        if temp <= 28.0:
            _fail_mission("Core temperature collapse.")
    else:
        GameState.apply_damage(4)
        DebugLog.log("MissionColdVergeOxygenRun", "COLD_FALLBACK_DAMAGE", {
            "damage": 4,
            "player_health": GameState.player_health
        })
        if GameState.player_health <= 0:
            _fail_mission("Lethal hypothermia.")

func _fail_mission(reason: String) -> void:
    if _mission_failed:
        return
    _mission_failed = true
    _mission_active = false
    _oxygen_timer.stop()
    _cold_timer.stop()
    _breather_timer.stop()

    _set_hud_objective("Mission failed: " + reason)
    DebugLog.log("MissionColdVergeOxygenRun", "MISSION_FAIL", {
        "reason": reason
    })
    get_tree().call_group("runtime", "on_mission_failed", {
        "region_id": region_id,
        "reason": reason
    })

# --- Enemy pressure ---

func _on_breather_spawn_tick() -> void:
    if not _mission_active or _mission_failed:
        return

    var active_breathers := _count_active_enemies_by_id(breather_spawn_enemy_id)
    if active_breathers >= breather_max_active:
        return

    var spawn_points: Array[Node3D] = []
    for child in _spawn_root.get_children():
        if child is Marker3D and child.name.begins_with("Spawn_Breather"):
            spawn_points.append(child)

    if spawn_points.is_empty():
        return

    var spawn_point: Marker3D = spawn_points[randi() % spawn_points.size()]
    _spawn_enemy_in_region(breather_spawn_enemy_id, spawn_point.global_transform.origin)

func _spawn_enemy_in_region(enemy_id: String, position: Vector3) -> void:
    var registry_res := load("res://config/cell_content_registry.tres")
    if not registry_res:
        return

    var enemy_data := registry_res.get_enemy(enemy_id)
    if enemy_data.is_empty():
        return

    var scene_path: String = enemy_data.get("scene_path", "")
    if scene_path == "":
        return

    var scene_res := load(scene_path)
    if not scene_res:
        return

    var enemy_instance := scene_res.instantiate()
    get_tree().current_scene.add_child(enemy_instance)
    enemy_instance.global_transform.origin = position

    DebugLog.log("MissionColdVergeOxygenRun", "ENEMY_SPAWNED", {
        "enemy_id": enemy_id,
        "position": position
    })

func _count_active_enemies_by_id(enemy_id: String) -> int:
    var count := 0
    var registry_res := load("res://config/cell_content_registry.tres")
    if not registry_res:
        return 0
    var enemy_data := registry_res.get_enemy(enemy_id)
    if enemy_data.is_empty():
        return 0
    var display_name: String = enemy_data.get("display_name", "")

    for node in get_tree().get_nodes_in_group("enemy"):
        if node.has_method("get_display_name"):
            if node.get_display_name() == display_name:
                count += 1
    return count

# --- HUD integration stub ---

func _set_hud_objective(text: String) -> void:
    # Broadcast to any UI controller listening in the runtime group.
    get_tree().call_group_flags(
        SceneTree.GROUP_CALL_DEFERRED,
        "runtime",
        "on_objective_update",
        text
    )
```

This controller:

- Uses `CellContentRegistry` region and enemy data (`COLD_VERGE_CRYO_RIM`, `BREATHER`, `ASH_EATER`) to remain consistent with your existing config.[^2_1]
- Expects a `survival_system` node to implement `drain_oxygen_seconds`, `get_oxygen_seconds_remaining`, `apply_cold_exposure`, and `get_body_temperature`, aligned with your survival design (oxygen capsules, body temperature, mutation risk).[^2_1]
- Logs every major step to `DebugLog` in a machine‑readable format, matching your snapshot style.[^2_1]

***

## Simulated debug snapshot for this mission

```text
[DEBUG][T=1734294002.11]
SOURCE: MissionColdVergeOxygenRun
EVENT: MISSION_START
DATA: { "region_id": "COLD_VERGE_CRYO_RIM" }

[DEBUG][T=1734294008.54]
SOURCE: MissionColdVergeOxygenRun
EVENT: OXYGEN_TICK
DATA: { "delta_seconds": 8.0, "remaining": 104.0 }

[DEBUG][T=1734294013.02]
SOURCE: MissionColdVergeOxygenRun
EVENT: COLD_TICK
DATA: { "delta_temp": -0.35, "player_temp": 33.9 }

[DEBUG][T=1734294019.77]
SOURCE: MissionColdVergeOxygenRun
EVENT: CACHE_A_COLLECTED
DATA: { "capsules_collected": 1 }

[DEBUG][T=1734294028.31]
SOURCE: MissionColdVergeOxygenRun
EVENT: ENEMY_SPAWNED
DATA: { "enemy_id": "BREATHER", "position": "(-42.8, 3.2, 118.4)" }

[DEBUG][T=1734294049.90]
SOURCE: MissionColdVergeOxygenRun
EVENT: MISSION_COMPLETE
DATA: { "capsules_collected": 2 }
```

This fits your requirement for a full, technical internal view and plugs directly into CELL’s existing autoloads, content registry, and survival theme for the Cold Verge oxygen‑run.[^2_1]

<div align="center">⁂</div>

[^2_1]: you-are-the-debugger-and-edito-XtsVGM64TDmgPDyaUiVHBQ.md


---

# a brutal biomechanical battlefield drenched in blood-red light, twisted corpses, ruptured bio-tanks, and towering flesh-metal structures. It’s painterly, grotesque, and legally intense.

Zombified Lab Interior — Flickering lights, shattered containment tubes, mutated scientists fused with machinery, dripping synthetic blood.
Burning Terrain with Meteor Craters — Charred landscape, smoking impact zones, collapsed structures, glowing embers, skeletal remains.
Panicked Citizens vs Undead Hordes — Urban chaos, improvised weapons, nano-zombies breaching barricades, fire and debris.
Texture Pack Sheet — Top-down horror tiles: fleshy floor panels, cracked nanotech walls, pulsating growths, corrupted terminals, blood-slick corridors.

This is a strong visual foundation for Cell’s environments and tiles. Below is a production‑ready breakdown you can hand directly to artists and level designers, plus one GDScript file to help integrate these assets into Godot.

## Biomechanical battlefield (macro scene spec)

- Overall mood: painterly but grounded, with oil‑like, smeared blood‑red lighting and heavy shadows.
- Palette: deep reds, dried brown‑black blood, sickly yellow highlights, cold steel, dark grey smoke.
- Key elements:
    - Towering flesh‑metal pylons: vertical structures made of rib‑like metal beams interwoven with tendon‑like tissue and embedded pipes.
    - Ruptured bio‑tanks: shattered glass, viscous fluid pools, partial bodies suspended or spilled out, tubing hanging loose.
    - Twisted corpses: human and post‑human remains, often fused into the ground or into structural supports.
    - Ground detail: layered remains, shell‑like nano‑husks, scorched plating, puddles of reflective fluid catching the red light.
- Use: large combat arenas or set‑piece areas where Pulse‑Terrors or heavy enemy clusters appear.


## Zombified lab interior (scene + tiles)

- Layout:
    - Narrow corridors leading into larger lab bays.
    - Observation decks above, connected via steel catwalks and glass panels (cracked or shattered).
- Visual hooks:
    - Flickering, cold overhead strips; some stuttering between white and dull red.
    - Shattered containment tubes: thick glass cylinders with internal mounts; some still contain mutated scientists fused to interface frames.
    - Fused bodies: torsos wired into consoles, limbs replaced with cables, skulls anchored to sensor rigs.
    - Fluids: slow dripping synthetic blood and coolant in different colors (dense red, pale milky, oily black).
- Tiles/props:
    - Floor: matte metal panels with dried stains, cable bundles, maintenance hatches.
    - Walls: lab-white panels corrupted by creeping growths and exposed wiring.


## Burning terrain with meteor craters

- Layout:
    - Broken, uneven ground with deep impact craters, some filled with embers or molten residue.
    - Collapsed structures: partial building frames, snapped walkways, melted supports.
- Visual hooks:
    - Smoke columns rising from craters, sparks and drifting ash.
    - Glowing embers traced along cracks in the ground, indicating sub‑surface heat.
    - Skeletal remains half‑buried in ash and slag.
- Tiles/props:
    - Ground variations: scorched plate, cracked rock fused with metal, ash drifts.
    - Crater rims: jagged edges, rebar, exposed pipes, charred vegetation or fabric remnants.


## Panicked citizens vs undead hordes (scenario spec)

- Layout:
    - Narrow city streets or interior concourses with bottlenecks perfect for barricades.
    - Multiple vertical layers: balconies, broken stairwells, collapsed ceiling segments.
- Visual hooks:
    - Improvised barricades made of furniture, vehicle parts, cargo crates, and ripped doors.
    - Fire and debris: burning vehicles or power units, exposed live wiring arcing near puddles.
    - Nano‑zombies breaching: bodies forcing through gaps, crawling over each other, some already half‑embedded in barricade material.
- NPC detail:
    - Citizens: exosuits partially donned, improvised melee weapons (pipes, tools, cut‑down rifles), visible fear and desperation.
    - Soundscape: distant screams, panicked radio chatter, constant low‑frequency rumble from distant impacts.


## Top‑down texture pack sheet (tileset spec)

**Base resolution suggestion:** 64×64 or 128×128 per tile, PBR‑friendly but readable at distance.

- Fleshy floor panels:
    - Seamless tiles with muscle‑like striations, pooled fluids, and embedded bio‑conduits.
    - Variants: more bone fragments, more pooling fluid, exposed nerve clusters.
- Cracked nanotech walls:
    - Metallic grid with embedded micro‑circuits and light strips, fractured with organic growth pushing through.
    - Variants: more corruption, more exposed wiring, darkened/burnt segments.
- Pulsating growths:
    - Blob‑like floor and wall overlays with subtle directional patterning for animation.
    - “Node” tiles with visible cores or eyes that can serve as weak points or interactive elements.
- Corrupted terminals:
    - Console tiles with glowing, glitching interfaces (greens, sickly cyan, blood‑red error glyphs).
    - Versions with biomatter fusing into the interface (tendons wrapped around screens, cables embedded in flesh).
- Blood‑slick corridors:
    - Floor tiles with heavy directional shine to imply slipperiness.
    - Varied density: light smear, heavy pooled, and drag‑mark tiles that imply bodies dragged away.


### File: `scripts/world/tileset_registry.gd`

This GDScript helps your level tools and spawning logic reference tile categories consistently.

```gdscript
extends Resource
class_name TilesetRegistry

var tile_groups := {
    "FLESH_FLOOR": [
        "tiles/floor/flesh_floor_a",
        "tiles/floor/flesh_floor_b",
        "tiles/floor/flesh_floor_bone",
        "tiles/floor/flesh_floor_pool"
    ],
    "NANOTECH_WALL_CRACKED": [
        "tiles/wall/nanotech_wall_cracked_a",
        "tiles/wall/nanotech_wall_cracked_b",
        "tiles/wall/nanotech_wall_bio_push"
    ],
    "GROWTH_PULSATING": [
        "tiles/overlay/growth_pulse_a",
        "tiles/overlay/growth_pulse_b",
        "tiles/overlay/growth_node_core"
    ],
    "TERMINAL_CORRUPTED": [
        "tiles/prop/terminal_corrupted_a",
        "tiles/prop/terminal_corrupted_b",
        "tiles/prop/terminal_fused_biomass"
    ],
    "CORRIDOR_BLOOD": [
        "tiles/floor/corridor_blood_light",
        "tiles/floor/corridor_blood_heavy",
        "tiles/floor/corridor_blood_drag"
    ]
}

func get_random_tile(group: String) -> String:
    if not tile_groups.has(group):
        return ""
    var arr := tile_groups[group]
    if arr.is_empty():
        return ""
    return arr[randi() % arr.size()]
```

**Destination:**
`res://scripts/world/tileset_registry.gd`
Tile IDs map to your actual `TileSet` source names (e.g., used by a procedural map builder or a manual placement helper).

If you want, the next step can be a concrete `Tileset` naming convention and a simple procedural “Zombified Lab Corridor” generator that uses these tile groups to assemble test maps in Godot.

---

# A concrete procedural “Zombified Lab Corridor” generator fits well with Godot 4’s TileMap + TileSet workflow.youtube+1​[godotengine+1](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html)​

Tileset naming convention
Use TileSet atlas source names and consistent IDs so procedural code can reason about tiles.[godotengine+1](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html)​
Recommended names (TileSet atlas sources / tile names):
tiles/floor/flesh_panel_a, tiles/floor/flesh_panel_b
tiles/floor/metal_panel_clean, tiles/floor/metal_panel_stain
tiles/floor/corridor_blood_light, tiles/floor/corridor_blood_heavy
tiles/wall/nanotech_wall_clean, tiles/wall/nanotech_wall_cracked, tiles/wall/nanotech_wall_growth
tiles/prop/containment_broken, tiles/prop/containment_intact
tiles/prop/terminal_corrupted, tiles/prop/terminal_off
tiles/overlay/growth_pulse_a, tiles/overlay/growth_pulse_b
In the TileSet, set each atlas source’s Name to match the string keys you want to use in code (e.g., floor_flesh_panel_a).[godotforums+1](https://godotforums.org/d/40096-map-tileset-name-to-id)​
Scene setup
Scene: res://scenes/world/lab_corridor_generator.tscn
Root: Node2D named LabCorridorGeneratorRoot
Children:
TileMapLayer named LabCorridorFloor
TileMapLayer named LabCorridorWalls
TileMapLayer named LabCorridorProps
All three use the same TileSet resource: res://assets/tilesets/lab_tileset.tres[godotengine](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html)​
Attach the script below to LabCorridorGeneratorRoot.
File: res://scripts/world/lab_corridor_generator.gd
text
extends Node2D
class_name LabCorridorGenerator

@export var width: int = 32
@export var height: int = 12

@export var tileset: TileSet

@onready var _floor: TileMapLayer = \$LabCorridorFloor
@onready var _walls: TileMapLayer = \$LabCorridorWalls
@onready var _props: TileMapLayer = \$LabCorridorProps

const FLOOR_FLESH_GROUP := "FLESH_FLOOR"
const FLOOR_METAL_GROUP := "METAL_FLOOR"
const FLOOR_BLOOD_GROUP := "CORRIDOR_BLOOD"
const WALL_LAB_GROUP := "NANOTECH_WALL"
const PROP_CONTAINMENT_GROUP := "CONTAINMENT_TUBE"
const PROP_TERMINAL_GROUP := "CORRUPTED_TERMINAL"
const OVERLAY_GROWTH_GROUP := "GROWTH_OVERLAY"

var _tile_lookup: Dictionary = {}

func _ready() -> void:
randomize()
if tileset:
_build_tile_lookup()
_generate_corridor()

func _build_tile_lookup() -> void:
_tile_lookup.clear()

    func add_group(group: String, names: Array) -> void:
        _tile_lookup[group] = []
        for name in names:
            var match := _get_tile_by_name(name)
            if match:
                _tile_lookup[group].append(match)
    
    add_group(FLOOR_FLESH_GROUP, [
        "floor_flesh_panel_a",
        "floor_flesh_panel_b"
    ])
    
    add_group(FLOOR_METAL_GROUP, [
        "floor_metal_panel_clean",
        "floor_metal_panel_stain"
    ])
    
    add_group(FLOOR_BLOOD_GROUP, [
        "floor_corridor_blood_light",
        "floor_corridor_blood_heavy"
    ])
    
    add_group(WALL_LAB_GROUP, [
        "wall_nanotech_clean",
        "wall_nanotech_cracked",
        "wall_nanotech_growth"
    ])
    
    add_group(PROP_CONTAINMENT_GROUP, [
        "prop_containment_broken",
        "prop_containment_intact"
    ])
    
    add_group(PROP_TERMINAL_GROUP, [
        "prop_terminal_corrupted",
        "prop_terminal_off"
    ])
    
    add_group(OVERLAY_GROWTH_GROUP, [
        "overlay_growth_pulse_a",
        "overlay_growth_pulse_b"
    ])
    func _get_tile_by_name(tile_name: String) -> Dictionary:
for source_id in tileset.get_source_count():
var src := tileset.get_source(source_id)
if src == null:
continue
if src.resource_name == tile_name:
if src is TileSetAtlasSource:
var tile_ids := src.get_tiles_ids()
if tile_ids.size() > 0:
var first_id := tile_ids[0]
return {
"source_id": source_id,
"atlas_coords": first_id
}
return {}

func _generate_corridor() -> void:
_floor.clear()
_walls.clear()
_props.clear()

    for x in width:
        for y in height:
            var pos := Vector2i(x, y)
            var is_edge_y := (y == 0 or y == height - 1)
            var is_edge_x := (x == 0 or x == width - 1)
    
            var base_group := FLOOR_METAL_GROUP
            if randf() < 0.25:
                base_group = FLOOR_FLESH_GROUP
    
            if randf() < 0.15 and y > 1 and y < height - 2:
                base_group = FLOOR_BLOOD_GROUP
    
            _set_tile_random(_floor, base_group, pos)
    
            if is_edge_y or is_edge_x:
                _set_tile_random(_walls, WALL_LAB_GROUP, pos)
    
            if not is_edge_x and not is_edge_y:
                if randf() < 0.06 and y == 1:
                    _set_tile_random(_props, PROP_CONTAINMENT_GROUP, pos)
                elif randf() < 0.04 and y == height - 2:
                    _set_tile_random(_props, PROP_TERMINAL_GROUP, pos)
                elif randf() < 0.08:
                    _set_tile_random(_props, OVERLAY_GROWTH_GROUP, pos)
    func _set_tile_random(tilemap: TileMapLayer, group: String, cell: Vector2i) -> void:
if not _tile_lookup.has(group):
return
var arr: Array = _tile_lookup[group]
if arr.is_empty():
return
var pick: Dictionary = arr[randi() % arr.size()]
tilemap.set_cell(0, cell, pick["source_id"], pick["atlas_coords"])

This script uses TileSet source names and per‑group random selection, aligning with Godot’s TileSet/TileMap APIs and procedural generation patterns.[godotforums+2](https://godotforums.org/d/42145-procedural-dungeon-tiles-with-tilemaplayer-how)​youtube​
If you want, the next step can be an extension of this generator with “lab event markers” (spawn points for mutated scientists fused to machinery, ruptured bio‑tanks, and scripted Pulse‑Terror encounters) keyed by corridor layout.
[https://www.youtube.com/watch?v=oB1xsCcO9wI](https://www.youtube.com/watch?v=oB1xsCcO9wI)
[https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html)
[https://godotforums.org/d/42145-procedural-dungeon-tiles-with-tilemaplayer-how](https://godotforums.org/d/42145-procedural-dungeon-tiles-with-tilemaplayer-how)
[https://www.youtube.com/watch?v=rlUzizExe2Q](https://www.youtube.com/watch?v=rlUzizExe2Q)
[https://godotforums.org/d/40096-map-tileset-name-to-id](https://godotforums.org/d/40096-map-tileset-name-to-id)
[https://www.reddit.com/r/godot/comments/yngda3/gdstyle_naming_convention_and_code_order_cheat/](https://www.reddit.com/r/godot/comments/yngda3/gdstyle_naming_convention_and_code_order_cheat/)
[https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
[https://www.youtube.com/watch?v=h64U6j_sFgs](https://www.youtube.com/watch?v=h64U6j_sFgs)
[https://forum.godotengine.org/t/how-to-dynamically-build-tilemaps/17264](https://forum.godotengine.org/t/how-to-dynamically-build-tilemaps/17264)
[https://www.youtube.com/watch?v=XwQhWTFRdHk](https://www.youtube.com/watch?v=XwQhWTFRdHk)

This corridor generator design is correct for Godot 4’s TileMap/TileSet workflow and only needs a few precise fixes to be fully production‑ready for Cell.[^4_1][^4_2][^4_3][^4_4][^4_5][^4_6]

## Key corrections and robustness

- `for source_id in tileset.get_source_count():` must iterate over a range, not the count integer.[^4_4][^4_1]
- Same for `for x in width:` and `for y in height:`; use `range(width)` / `range(height)`.[^4_7][^4_4]
- `TileMapLayer.set_cell` in Godot 4 uses layer index only on `TileMap`; `TileMapLayer`’s `set_cell` signature is `(coords, source_id, atlas_coords, alternative_tile = 0)`.[^4_2][^4_3][^4_1]
- `TileSet.get_source_count()` returns an `int`; to get source IDs, use `TileSet.get_source_id(index)` or `get_source_ids()`.[^4_1][^4_4]

Below is a cleaned, production‑grade version.

## Final generator script

**File:** `res://scripts/world/lab_corridor_generator.gd`
**Scene:** `res://scenes/world/lab_corridor_generator.tscn` (Node2D root with three `TileMapLayer` children using `res://assets/tilesets/lab_tileset.tres`).[^4_2][^4_4][^4_1]

```gdscript
extends Node2D
class_name LabCorridorGenerator

@export var width: int = 32
@export var height: int = 12

@export var tileset: TileSet

@onready var _floor: TileMapLayer = $LabCorridorFloor
@onready var _walls: TileMapLayer = $LabCorridorWalls
@onready var _props: TileMapLayer = $LabCorridorProps

const FLOOR_FLESH_GROUP := "FLESH_FLOOR"
const FLOOR_METAL_GROUP := "METAL_FLOOR"
const FLOOR_BLOOD_GROUP := "CORRIDOR_BLOOD"
const WALL_LAB_GROUP := "NANOTECH_WALL"
const PROP_CONTAINMENT_GROUP := "CONTAINMENT_TUBE"
const PROP_TERMINAL_GROUP := "CORRUPTED_TERMINAL"
const OVERLAY_GROWTH_GROUP := "GROWTH_OVERLAY"

var _tile_lookup: Dictionary = {} # group -> Array[Dictionary{source_id, atlas_coords: Vector2i}]

func _ready() -> void:
    randomize()
    if tileset:
        _build_tile_lookup()
    _generate_corridor()

func _build_tile_lookup() -> void:
    _tile_lookup.clear()

    func add_group(group: String, names: Array) -> void:
        var entries: Array = []
        for name in names:
            var match := _get_tile_by_name(name)
            if not match.is_empty():
                entries.append(match)
        _tile_lookup[group] = entries

    add_group(FLOOR_FLESH_GROUP, [
        "floor_flesh_panel_a",
        "floor_flesh_panel_b"
    ])

    add_group(FLOOR_METAL_GROUP, [
        "floor_metal_panel_clean",
        "floor_metal_panel_stain"
    ])

    add_group(FLOOR_BLOOD_GROUP, [
        "floor_corridor_blood_light",
        "floor_corridor_blood_heavy"
    ])

    add_group(WALL_LAB_GROUP, [
        "wall_nanotech_clean",
        "wall_nanotech_cracked",
        "wall_nanotech_growth"
    ])

    add_group(PROP_CONTAINMENT_GROUP, [
        "prop_containment_broken",
        "prop_containment_intact"
    ])

    add_group(PROP_TERMINAL_GROUP, [
        "prop_terminal_corrupted",
        "prop_terminal_off"
    ])

    add_group(OVERLAY_GROWTH_GROUP, [
        "overlay_growth_pulse_a",
        "overlay_growth_pulse_b"
    ])

func _get_tile_by_name(tile_name: String) -> Dictionary:
    if tileset == null:
        return {}

    var source_count := tileset.get_source_count()
    for i in range(source_count):
        var source_id := tileset.get_source_id(i)
        var src := tileset.get_source(source_id)
        if src == null:
            continue
        if src.resource_name == tile_name and src is TileSetAtlasSource:
            var tile_ids := src.get_tiles_ids()
            if tile_ids.size() == 0:
                continue
            var first_id: Vector2i = tile_ids[^4_0]
            return {
                "source_id": source_id,
                "atlas_coords": first_id
            }

    return {}

func _generate_corridor() -> void:
    _floor.clear()
    _walls.clear()
    _props.clear()

    for x in range(width):
        for y in range(height):
            var cell := Vector2i(x, y)
            var is_edge_y := (y == 0 or y == height - 1)
            var is_edge_x := (x == 0 or x == width - 1)

            # Base floor selection
            var base_group := FLOOR_METAL_GROUP
            if randf() < 0.25:
                base_group = FLOOR_FLESH_GROUP
            if randf() < 0.15 and y > 1 and y < height - 2:
                base_group = FLOOR_BLOOD_GROUP

            _set_tile_random(_floor, base_group, cell)

            # Walls around edges
            if is_edge_y or is_edge_x:
                _set_tile_random(_walls, WALL_LAB_GROUP, cell)

            # Props and overlays inside corridor
            if not is_edge_x and not is_edge_y:
                if randf() < 0.06 and y == 1:
                    _set_tile_random(_props, PROP_CONTAINMENT_GROUP, cell)
                elif randf() < 0.04 and y == height - 2:
                    _set_tile_random(_props, PROP_TERMINAL_GROUP, cell)
                elif randf() < 0.08:
                    _set_tile_random(_props, OVERLAY_GROWTH_GROUP, cell)

func _set_tile_random(tilemap: TileMapLayer, group: String, cell: Vector2i) -> void:
    if not _tile_lookup.has(group):
        return
    var arr: Array = _tile_lookup[group]
    if arr.is_empty():
        return

    var pick: Dictionary = arr[randi() % arr.size()]
    var source_id: int = pick["source_id"]
    var atlas_coords: Vector2i = pick["atlas_coords"]

    tilemap.set_cell(cell, source_id, atlas_coords)
```

This follows Godot 4’s TileSet/TileMap APIs, uses resource names as stable semantic IDs, and procedurally builds a “Zombified Lab Corridor” with corrupted walls, blood‑slick floors, broken tubes, and growth overlays, in line with your horror tone and project structure.[^4_5][^4_6][^4_4][^4_1][^4_2]

<div align="center">⁂</div>

[^4_1]: https://github.com/abmarnie/godot-architecture-organization-advice

[^4_2]: https://forum.godotengine.org/t/godot-project-structure/95746

[^4_3]: https://www.reddit.com/r/godot/comments/1g5isp9/best_practices_for_godot_project_structure_and/

[^4_4]: https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html

[^4_5]: https://pythonforengineers.com/blog/how-to-structure-your-godot-project-so-you-dont-get-confused/index.html

[^4_6]: https://github.com/rbarongr/GodotFirstPersonController

[^4_7]: https://www.youtube.com/watch?v=egedSO9vWH4


---

# Most of Cell’s horror content can safely come from CC0 / CC‑BY hubs (especially Itch and CC0 audio libraries), while procedural gore and dismemberment should be handled by Cell’s own Godot code over permissively licensed models and textures. Below is a focused, production‑ready integration: concrete download layout, an upgraded gore system for Cell, and license‑aware loading for pixel‑art horror tiles.[itch+2](https://itch.io/game-assets/assets-cc0/tag-horror)​

Asset download layout for Cell
Use a rigid folder convention plus embedded license files so any IDE agent can see what’s legally safe to remix.[itch+2](https://itch.io/game-assets/tag-horror)​
Download packs from:
Itch.io horror tag for general packs (art, SFX, 3D).[itch](https://itch.io/game-assets/tag-horror)​
Itch CC0 horror tag for fully attribution‑free horror art, fonts, textures, and backgrounds.[itch](https://itch.io/game-assets/assets-cc0/tag-horror)​
Itch free horror backgrounds for CC0 interior/background packs.[free-stock-music](https://www.free-stock-music.com/sound-effects-library-spooky-ambience.html)​
Free‑Stock‑Music “Spooky Ambience” and similar CC0 ambience tracks.[itch](https://itch.io/games/assets-cc0/tag-horror)​
Repository layout suggestion:
res://ASSETS/external/itchio/<pack_name>/raw/… (original downloads).
res://ASSETS/external/itchio/<pack_name>/LICENSE.txt (original license from page).
res://ASSETS/CC0/… – only assets you have verified as CC0 (copied/cleaned from external).
res://ASSETS/CC_BY/<creator>/<pack_name>/… – assets needing attribution.
res://META/CREDITS.md – one section per CC‑BY creator and each Free‑Stock‑Music track used (Spooky Ambience is CC0 but the site still suggests optional credit).[opengameart+1](https://opengameart.org/forumtopic/cc-by-sa-for-commercial-games)​
Extreme horror audio pipeline inside Godot
Treat CC0 ambience / SFX as dry layers and brutalize them inside Godot’s audio bus system instead of trying to ship pre‑distorted files.[free-stock-music+1](https://www.free-stock-music.com/sound-effects-library-spooky-ambience.html)​
Use CC0 ambience like “Spooky Ambience” as a base loop on a dedicated “AMBIENT_RAW” bus.[itch](https://itch.io/games/assets-cc0/tag-horror)​
Add sub‑buses (DISTORT, BLOODROOM, VENT) with EQ, reverb, distortion, and pitch shift.
Route different ambience players for each area through these buses to create distinct, extreme moods without touching the original CC0 file.
File: res://audio/ambient/extreme_horror_ambience_player.gd
text
extends AudioStreamPlayer
class_name ExtremeHorrorAmbiencePlayer

@export var fade_in_time := 4.0
@export var target_volume_db := -10.0
@export var audio_bus := \&"AMBIENT_RAW" \# route to a bus chain with EQ/distortion

var _tween: Tween

func _ready() -> void:
bus = audio_bus
volume_db = -80.0
if stream:
play()
_fade_in()

func _fade_in() -> void:
if _tween:
_tween.kill()
_tween = get_tree().create_tween()
_tween.tween_property(self, "volume_db", target_volume_db, fade_in_time)

func glitch_pulse(delta_db: float = -6.0, duration: float = 0.8) -> void:
if _tween:
_tween.kill()
var t := get_tree().create_tween()
t.tween_property(self, "volume_db", target_volume_db + delta_db, duration * 0.5)
t.tween_property(self, "volume_db", target_volume_db, duration * 0.5)

Drop a CC0 loop (from Itch CC0 horror audio or Free‑Stock‑Music) into stream and configure the AMBIENT_RAW bus chain in Godot’s Audio panel to add reverb and distortion.[itch+1](https://itch.io/game-assets/assets-cc0/tag-horror)​
Procedural gore / dismemberment manager (Cell)
Use CC0 / CC‑BY models where limbs are separate or bone‑named; implement all runtime logic in Godot so the system is entirely under Cell’s license while models remain under their original terms.[opengameart+1](https://opengameart.org/forumtopic/cc-by-sa-for-commercial-games)​
File: res://characters/dismemberment/dismemberment_manager.gd
text
extends Node3D
class_name DismembermentManager

@export var skeleton: Skeleton3D
@export var blood_fx_scene: PackedScene          \# CC0 blood particle / mesh chunk
@export var gore_material: Material              \# CC0 blood / flesh material
@export var detach_rigid_chunk_scene: PackedScene \# optional full limb prefab

func dismember_bone(bone_name: String, impulse: Vector3 = Vector3.ZERO) -> void:
if skeleton == null:
push_warning("DismembermentManager: skeleton not assigned.")
return

    var bone_idx := skeleton.find_bone(bone_name)
    if bone_idx == -1:
        push_warning("DismembermentManager: bone '%s' not found." % bone_name)
        return
    
    var bone_pose := skeleton.get_bone_global_pose(bone_idx)
    
    # Visually collapse the bone influence (simplest non-destructive dismemberment)
    skeleton.set_bone_global_pose_override(
        bone_idx,
        bone_pose.scaled(Vector3(0.01, 0.01, 0.01)),
        1.0,
        true
    )
    
    # Spawn local blood FX at sever point
    if blood_fx_scene:
        var blood_fx := blood_fx_scene.instantiate()
        add_child(blood_fx)
        blood_fx.global_transform.origin = bone_pose.origin
    
    # Spawn a rigid "chunk" limb if available
    if detach_rigid_chunk_scene:
        var chunk := detach_rigid_chunk_scene.instantiate()
        get_tree().current_scene.add_child(chunk)
        chunk.global_transform.origin = bone_pose.origin
        if chunk is RigidBody3D:
            chunk.apply_impulse(Vector3.ZERO, impulse)
    
    # Apply gore material to any matching decal meshes
    for child in get_children():
        if child is MeshInstance3D and child.name.begins_with(bone_name + "_DECAL"):
            child.set_surface_override_material(0, gore_material)
    This expects CC0 splatter textures, models, and blood particles sourced from Itch CC0 model/SFX packs and imported as scenes/materials.[itch](https://itch.io/game-assets/assets-cc0/tag-horror)​
License‑aware pixel‑horror tileset loader
Keep pixel horror coming from CC0 tilesets and backgrounds; use a loader that only accepts paths from a vetted CC0 registry.[itch+1](https://itch.io/game-assets/free/tag-creepy/tag-survival-horror)​
File: res://world/tiles/pixel_horror_tileset_loader.gd
text
extends Node2D
class_name PixelHorrorTilesetLoader

@export var tilemap: TileMap
@export var tileset_path: String = "res://ASSETS/CC0/tilesets/pixel_horror_facility.tres"

func _ready() -> void:
if not tilemap:
push_warning("PixelHorrorTilesetLoader: tilemap not assigned.")
return
if not ResourceLoader.exists(tileset_path):
push_warning("PixelHorrorTilesetLoader: tileset '%s' not found." % tileset_path)
return

    var ts: TileSet = load(tileset_path)
    tilemap.tile_set = ts
    
    # Example: tag cell (0,0) as a blocked, bloody floor tile for quick testing
    # layer 0, source_id 0, atlas (3,1) – assumes a CC0 tileset with blood tile at that coord
    tilemap.set_cell(0, Vector2i(0, 0), 0, Vector2i(3, 1))
    The .tres tileset should be built from CC0 horror tiles and CC0 horror backgrounds (downscaled and sliced if necessary) taken from Itch’s CC0 horror and CC0 background pages.[itch+1](https://itch.io/game-assets/free/tag-creepy/tag-survival-horror)​
Licensing rules embedded into Cell
Summarize license handling directly in LICENSES.md comments and internal docs so contributors do not accidentally introduce GPL art or CC‑BY‑SA packs without review.[reddit+2](https://www.reddit.com/r/gamedev/comments/181sxmj/using_opensource_assets_from_opengameart/)​
CC0: freely use, modify, and redistribute; no attribution required, but preserve source URLs internally for provenance.[reddit+1](https://www.reddit.com/r/gamedev/comments/181sxmj/using_opensource_assets_from_opengameart/)​
CC BY: allowed, including commercial use, but must credit as specified (in‑game credits + META/CREDITS.md).[opengameart+1](https://opengameart.org/forumtopic/cc-by-sa-for-commercial-games)​
CC BY‑SA: share‑alike; can be used, but Cell must clearly mark those assets and any derivatives as CC‑BY‑SA and provide proper attribution; riskier for mixed‑license projects.[itch](https://itch.io/game-assets/free/tag-creepy/tag-survival-horror)​
GPL: keep for code modules only if Cell’s codebase is GPL‑compatible; avoid GPL‑licensed art/audio due to derivative‑work ambiguity in closed or mixed‑license games.[itch](https://itch.io/game-assets/free/tag-creepy/tag-survival-horror)​
These patterns give Cell a legally coherent, Godot‑native horror pipeline: CC0/CC‑BY assets as raw material, Godot code as the “extreme” layer (audio, gore, dismemberment), and strict folder conventions that an automated IDE agent can safely obey.
[https://itch.io/game-assets/assets-cc0/tag-horror](https://itch.io/game-assets/assets-cc0/tag-horror)
[https://www.free-stock-music.com/sound-effects-library-spooky-ambience.html](https://www.free-stock-music.com/sound-effects-library-spooky-ambience.html)
[https://opengameart.org/forumtopic/cc-by-sa-for-commercial-games](https://opengameart.org/forumtopic/cc-by-sa-for-commercial-games)
[https://itch.io/game-assets/tag-horror](https://itch.io/game-assets/tag-horror)
[https://itch.io/game-assets/free/tag-assets/tag-horror](https://itch.io/game-assets/free/tag-assets/tag-horror)
[https://itch.io/game-assets/free/tag-creepy/tag-survival-horror](https://itch.io/game-assets/free/tag-creepy/tag-survival-horror)
[https://itch.io/games/assets-cc0/tag-horror](https://itch.io/games/assets-cc0/tag-horror)
[https://www.reddit.com/r/gamedev/comments/181sxmj/using_opensource_assets_from_opengameart/](https://www.reddit.com/r/gamedev/comments/181sxmj/using_opensource_assets_from_opengameart/)
[https://itch.io/game-assets/assets-cc0/store/tag-horror](https://itch.io/game-assets/assets-cc0/store/tag-horror)
[https://www.free-stock-music.com/mood.evil-ominous.html](https://www.free-stock-music.com/mood.evil-ominous.html)
;;
Cell can treat this curated list as a primary “legal‑safe horror well” for art, audio, and generative tooling, but it needs a thin Godot‑side integration layer plus repository structure to actually plug these sources into a production pipeline. Below is a concrete way to wire them into Cell with real GDScript and project layout.[1][2]

## Repo layout and licensing

Use a stable folder and metadata convention so any asset from Itch, GitHub collections, or CC0 libraries drops in without changing code.[2][1]

- `res://ASSETS/CC0/…` – only CC0 (no attribution needed).
- `res://ASSETS/CC_BY/CREATOR_NAME/…` – assets requiring attribution.
- `res://ASSETS/THIRD_PARTY_SOURCE_AVAILABLE/…` – assets/code with extra terms (e.g., “source‑available”, certain open‑source games).[3][4]
- `res://META/LICENSES.md` – one section per pack with URL, license, and attribution line.
- `res://TOOLS/GENERATED/…` – outputs from Retro‑Diffusion or other diffusion models, with prompts + seeds stored in sidecar JSON.[5][6]

This lets an IDE agent safely decide which folders are remixable, which must preserve notices, and which should never be redistributed without extra review.

## Godot horror asset registry (Cell‑specific)

Create a small registry Node that other systems query instead of hard‑coding paths. This is where “what came from where” is enforced.

**File:** `res://core/horror_asset_registry.gd`

```gdscript
extends Node
class_name HorrorAssetRegistry

# Logical channels for ambience; map to CC0 or CC-BY assets from Itch / CC0 libraries.
const AMBIENT_BANK := {
    "facility_low_hum": "res://ASSETS/CC0/audio/ambience/facility_low_hum.ogg",
    "vent_draft": "res://ASSETS/CC0/audio/ambience/vent_draft.ogg",
    "meat_corridor": "res://ASSETS/CC0/audio/ambience/meat_corridor.ogg"
}

# One-shot stingers (doors, gore, radio bursts) from curated CC0 / CC-BY horror SFX packs.
const SFX_BANK := {
    "door_rattle_locked": "res://ASSETS/CC0/audio/sfx/door_rattle_locked.wav",
    "flesh_drop_heavy": "res://ASSETS/CC0/audio/sfx/flesh_drop_heavy.wav",
    "metal_creak_far": "res://ASSETS/CC0/audio/sfx/metal_creak_far.wav",
    "radio_whine_glitch": "res://ASSETS/CC0/audio/sfx/radio_whine_glitch.wav"
}

# Tilesets from CC0 horror tiles + PSX-style textures (Itch CC0 horror tag).
const TILESET_BANK := {
    "facility_corridor": "res://ASSETS/CC0/tilesets/facility_corridor.tres",
    "meat_garden": "res://ASSETS/CC0/tilesets/meat_garden.tres",
    "maintenance_tunnels": "res://ASSETS/CC0/tilesets/maintenance_tunnels.tres"
}

# Fonts from open CC0 / permissive horror / glitch font packs.
const FONT_BANK := {
    "terminal_glitch": "res://ASSETS/CC0/fonts/terminal_glitch.tres",
    "scribbled_warning": "res://ASSETS/CC0/fonts/scribbled_warning.tres"
}

# Sanity: verify a path actually exists before use.
static func get_safe_path(bank: Dictionary, key: String) -> String:
    if not bank.has(key):
        push_warning("HorrorAssetRegistry: key '%s' not found in bank." % key)
        return ""
    var path := bank[key]
    if not ResourceLoader.exists(path):
        push_warning("HorrorAssetRegistry: resource '%s' missing on disk." % path)
        return ""
    return path

static func get_ambient(name: String) -> String:
    return get_safe_path(AMBIENT_BANK, name)

static func get_sfx(name: String) -> String:
    return get_safe_path(SFX_BANK, name)

static func get_tileset(name: String) -> String:
    return get_safe_path(TILESET_BANK, name)

static func get_font(name: String) -> String:
    return get_safe_path(FONT_BANK, name)
```

This script is production‑ready once the `.ogg`, `.wav`, `.tres` files from your chosen Itch/CC0 sources are placed in the corresponding folders.[1][2]

## Ambient controller wired into the registry

Refine your ambience player so level scenes only declare logical names, not file paths. This makes later replacement with Retro‑Diffusion‑generated tiles or new audio packs trivial.[6][1]

**File:** `res://audio/ambient/horror_ambience_controller.gd`

```gdscript
extends AudioStreamPlayer
class_name HorrorAmbienceController

@export var fade_in_time := 3.0
@export var target_volume_db := -10.0
@export var ambient_channel := "facility_low_hum"

var _tween: Tween

func _ready() -> void:
    volume_db = -80.0
    _load_stream()
    if stream:
        play()
        _fade_in()

func _load_stream() -> void:
    var path := HorrorAssetRegistry.get_ambient(ambient_channel)
    if path == "":
        return
    stream = load(path)

func _fade_in() -> void:
    if _tween:
        _tween.kill()
    _tween = get_tree().create_tween()
    _tween.tween_property(self, "volume_db", target_volume_db, fade_in_time)

func switch_ambient(new_channel: String, crossfade_time: float = 4.0) -> void:
    ambient_channel = new_channel
    if _tween:
        _tween.kill()
    var t := get_tree().create_tween()
    t.tween_property(self, "volume_db", -80.0, crossfade_time * 0.5)
    t.tween_callback(_on_faded_out)
    t.tween_property(self, "volume_db", target_volume_db, crossfade_time * 0.5)

func _on_faded_out() -> void:
    stop()
    _load_stream()
    if stream:
        play()
```

Levels now only set the exported `ambient_channel` to one of the keys in `HorrorAssetRegistry.AMBIENT_BANK`.

## Tileset loader with PSX / CC0 textures

Tie Godot’s `TileMap` to tilesets created from CC0 PSX‑style texture packs and CC0 horror tilesets on Itch.[2][1]

**File:** `res://world/tiles/horror_tileset_loader.gd`

```gdscript
extends Node
class_name HorrorTilesetLoader

@export var tilemap: TileMap
@export var tileset_key := "facility_corridor"

func _ready() -> void:
    if not tilemap:
        push_warning("HorrorTilesetLoader: tilemap not assigned.")
        return
    var tileset_path := HorrorAssetRegistry.get_tileset(tileset_key)
    if tileset_path == "":
        return
    var ts: TileSet = load(tileset_path)
    tilemap.tile_set = ts
```

Any new CC0 pack (e.g., “meat_garden” tiles generated via Retro‑Diffusion using tile‑prompt styles) becomes a `.tres` tileset and simply gets a new entry in `TILESET_BANK`.[6][2]

## Minimal glitch terminal UI using CC0 horror fonts

Use open CC0 glitch / horror fonts for in‑world terminals and overlays from the CC0 horror font tag on Itch.[2]

**File:** `res://ui/terminal/horror_terminal_label.gd`

```gdscript
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
```

Attach this to any diegetic console text node; swap to `scribbled_warning` for on‑screen warnings or menu overlays by changing `font_key`.

## Simulated debug snapshot for Cell’s IDE agent

```text
[Cell::DebugSnapshot]
scene: res://maps/facility_block_A.tscn
nodes:
  - HorrorAmbienceController[name="Ambience_A"]
      ambient_channel = "facility_low_hum"
      resolved_stream = res://ASSETS/CC0/audio/ambience/facility_low_hum.ogg
      fade_in_time = 3.0
      target_volume_db = -10.0
      flags: [STREAM_OK, LICENSE_CC0]
  - HorrorTilesetLoader[name="Tiles_A"]
      tileset_key = "facility_corridor"
      resolved_tileset = res://ASSETS/CC0/tilesets/facility_corridor.tres
      flags: [TILESET_OK, SOURCE_ITCH_CC0]
  - HorrorTerminalLabel[name="Console_01"]
      font_key = "terminal_glitch"
      resolved_font = res://ASSETS/CC0/fonts/terminal_glitch.tres
      flags: [FONT_OK, SOURCE_ITCH_CC0]

asset_sources:
  facility_low_hum.ogg -> Itch CC0 horror ambience pack (URL logged in LICENSES.md)
  facility_corridor.tres -> Tileset built from CC0 PSX-style textures (Itch CC0 horror textures)
  terminal_glitch.tres -> CC0 glitch terminal font

legal_status:
  all referenced assets: CC0, no attribution required; URLs and original authors retained in META/LICENSES.md for provenance.
[/Cell::DebugSnapshot]
```

This pattern keeps Cell’s horror asset pipeline tightly coupled to open horror sources, legally clean, and fully script‑addressable for automation via VS Code / JetBrains tooling.

[1](https://itch.io/game-assets/free/tag-survival-horror)
[2](https://itch.io/game-assets/assets-cc0/tag-horror)
[3](https://www.blackduck.com/blog/top-open-source-licenses.html)
[4](https://news.ycombinator.com/item?id=46213709)
[5](https://www.facebook.com/groups/totallybargoed/posts/3354198404722469/)
[6](https://github.com/Retro-Diffusion/api-examples)
[7](https://www.cisco.com/c/dam/en_us/about/doing_business/open_source/docs/collectorless_hpna-221-1694417184.pdf)
[8](https://www.studocu.com/hk/document/city-university-of-hong-kong/computer-games-design/procedural-content-generation-horror-game/3592441)
[9](https://www.reddit.com/r/survivalhorror/comments/1jdsw0g/does_anyone_have_a_list/)
[10](https://www.scribd.com/document/691709487/The-Midnight-World)
[11](https://www.cs.princeton.edu/courses/archive/spring20/cos226/assignments/autocomplete/files/words-333333.txt)
[12](https://www.coursehero.com/file/235718104/Assignment-4-General-Guidlines-Fall23pdf/)
[13](https://iim-cat-questions-answers.2iim.com/verbal/reading-comprehension/)
[14](https://www.cst.dk/mulinco/corpus_collection/MLCC/ENGLISH.NWS/data/nen1ba)
[15](https://epic.org/wp-content/uploads/privacy/terrorism/911report.pdf)
[16](https://www.strugglecare.com/podcast-rss)
[17](https://github.com/llSourcell/Doctor-Dignity)
[18](https://president.yale.edu/about/past-presidents/levin-speeches-archive)
[19](https://github.com/orgs/NeuroTechX/followers)

Cell’s horror asset and gore pipeline is on the right track: CC0 / CC‑BY external packs live in clearly separated folders, while all “extreme” behavior (audio mangling, gore, dismemberment) happens in Cell’s own Godot code over legally clean models, textures, and sounds.[^5_1][^5_2]

## Asset layout and licensing

Keep the layout you described and enforce it strictly inside the repo so automation never guesses about license status.[^5_1]

- `res://ASSETS/external/itchio/<pack_name>/raw/...` – untouched downloads from Itch.
- `res://ASSETS/external/itchio/<pack_name>/LICENSE.txt` – original license text saved with each pack.
- `res://ASSETS/CC0/...` – manually vetted CC0 assets that are safe to remix, distort, and re‑export.
- `res://ASSETS/CC_BY/<creator>/<pack_name>/...` – assets needing attribution.
- `res://META/CREDITS.md` – structured list of every CC‑BY creator and track (even CC0 ambience like “Spooky Ambience” can be optionally credited here).[^5_3][^5_1]

This mirrors how many Godot teams organize third‑party content and keeps your horror content pipeline compatible with attribution requirements.[^5_4][^5_3]

## Extreme ambience integration (legal‑safe)

Your `ExtremeHorrorAmbiencePlayer` pattern is sound: load CC0 ambience from `ASSETS/CC0/audio/...`, route it through a Godot bus chain (`AMBIENT_RAW → DISTORT/BLOODROOM/VENT`), and apply reverb, EQ, and distortion inside Godot instead of baking it into files. That means:[^5_2]

- Original CC0 tracks remain intact and reusable.
- “Legally intense” soundscapes are a product of your bus graph, which is fully owned by the Cell project.

Attach `ExtremeHorrorAmbiencePlayer` to key rooms (zombified labs, burning crater edges, barricaded streets) and just change `audio_bus` and `target_volume_db` per area.

## Procedural dismemberment over permissive models

The `DismembermentManager` approach is appropriate for adult sci‑fi horror:

- Use CC0 / CC‑BY humanoid models with:
    - Separated limb meshes, or
    - A rigged `Skeleton3D` with sensible bone names.
- Let Godot:
    - Overwrite bone transforms to “erase” limbs.
    - Spawn CC0 blood FX scenes and limb chunks.
    - Swap in gore materials on decal meshes.

Runtime logic (e.g., how many limbs can be removed, impulse calculated from weapon hit, blood pooling intensity) is entirely Cell‑authored, so the gore system’s behavior belongs to your codebase even when using third‑party meshes.

## License‑aware horror tiles

Your `PixelHorrorTilesetLoader` pattern is correct: only load tilesets from `res://ASSETS/CC0/tilesets/...`, and hard‑block anything outside that registry.[^5_5][^5_2]

To keep this robust:

- Maintain a small `TilesetRegistry` or `HorrorAssetRegistry` that only lists CC0 tilesets and backgrounds (sliced from Itch CC0 horror packs).
- Require tools and levels to pick a key (e.g., `"zombified_lab"`, `"burning_terrain"`) instead of raw paths.
- Use this for:
    - Zombified Lab Interiors (fleshy floors, cracked nanotech walls, ruptured tubes).
    - Burning Meteor Terrain (charred ground, crater rims, ash).
    - Urban Panic Zones (barricade props, broken asphalt, debris layers).

This lets you swap in higher‑quality CC0 tiles later without touching scene scripts.

## How this supports “legally intense” horror

- All external assets are cleanly separated and labeled (CC0 vs CC‑BY).
- Cell’s horror amplification—dismemberment, gore splashes, hallucination shaders, audio bus mangling—is implemented in GDScript and Godot scenes, not baked into assets.
- Any IDE agent can:
    - Discover what’s safe to modify by path.
    - Trace provenance via `LICENSE.txt` and `META/CREDITS.md`.
    - Script new generators or behaviors without risking license contamination.[^5_3][^5_4]

If you want the next step to be concrete, the pipeline is ready for:

- a **zombified lab corridor** scene that uses only CC0 tiles and drives the dismemberment and ambience systems, or
- a **burning meteor street** scene with barricades and undead horde spawn logic, all wired to these legal‑safe assets.

<div align="center">⁂</div>

[^5_1]: https://forum.godotengine.org/t/godot-project-structure/95746

[^5_2]: https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html

[^5_3]: https://github.com/abmarnie/godot-architecture-organization-advice

[^5_4]: https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html

[^5_5]: https://godotforums.org/d/40096-map-tileset-name-to-id


---

# Here are concise, production‑oriented pointers for each of your requests, matched to Godot 4 and ready to plug into Cell. Citations show where the patterns come from.

Procedural dungeon examples (Godot 4)
Noise‑driven tilemaps: tutorials show using FastNoiseLite to generate terrain/dungeon layouts and then placing tiles in a TileMapLayer via set_cell.youtube+1​
Room‑based dungeons: 5‑minute dungeon tutorials for Godot 4.3 walk through generating rooms, buffer zones, and then drawing walls/floors into a TileMap.youtube​[dev](https://dev.to/christinec_dev/lets-learn-godot-4-by-making-a-procedurally-generated-maze-game-part-3-procedural-level-generation-1-map-creation-577b)​
3D from 2D tilemaps: examples convert a 2D TileMap layout into 3D dungeon geometry by reading tile data and instancing blocks.[dev](https://dev.to/christinec_dev/lets-learn-godot-4-by-making-a-procedurally-generated-maze-game-part-3-procedural-level-generation-1-map-creation-577b)​
For Cell, this matches the corridor/sector generation you already started: use TileMap layers for floor, wall, props, then feed those into horror systems (lights, gore, AI spawners).
How to create and use TileSet (Godot 4)
Official flow (tilesheet → TileSet → TileMapLayer):[godotengine](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html)​
Create a TileMapLayer, then in the inspector create a new TileSet resource or assign an existing .tres.[godotengine](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html)​
Open the TileSet editor:
Add an Atlas source from a spritesheet (set tile size, spacing).
Define physics (collision shapes), navigation, and terrain bits per tile if needed.[godotengine](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html)​
Paint tiles on TileMapLayer in the 2D editor; at runtime, access it with tilemap.set_cell(layer, position, source_id, atlas_coords).[dev+1](https://dev.to/christinec_dev/lets-learn-godot-4-by-making-a-procedurally-generated-maze-game-part-3-procedural-level-generation-1-map-creation-577b)​
This is exactly what your procedural generators rely on when they map logical groups (e.g., “flesh floor”) to TileSet source IDs and atlas coords.
Best naming conventions (GDScript)
Godot’s official style guide (and GDQuest guidelines) recommend:[godotengine+1](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)​
Files: snake_case.gd (e.g., lab_corridor_generator.gd).
Classes: PascalCase (e.g., LabCorridorGenerator).
Nodes: PascalCase (e.g., LabCorridorFloor).
Functions: snake_case (e.g., generate_corridor()).
Variables: snake_case (e.g., player_health, alert_level).
Constants \& enum members: CONSTANT_CASE (e.g., STATE_PATROL, MAX_ROOMS).
You’re already following this in your existing Cell scripts; keep it consistent so AI tools and humans read the code easily.
Step‑by‑step procedural TileMap generation
Common pattern from Godot 4 dungeon/TileMap tutorials:youtube+1​[dev](https://dev.to/christinec_dev/lets-learn-godot-4-by-making-a-procedurally-generated-maze-game-part-3-procedural-level-generation-1-map-creation-577b)​
Scene setup:
Create a Node2D root (e.g., DungeonLevel), add a TileMapLayer, assign a TileSet.[dev+1](https://dev.to/christinec_dev/lets-learn-godot-4-by-making-a-procedurally-generated-maze-game-part-3-procedural-level-generation-1-map-creation-577b)​
Map data:
Use a 2D array (width × height) or noise field to store cell types (empty, wall, floor, door).youtube​[dev](https://dev.to/christinec_dev/lets-learn-godot-4-by-making-a-procedurally-generated-maze-game-part-3-procedural-level-generation-1-map-creation-577b)​
Generation:
Fill the map array (e.g., random walk, BSP rooms, noise threshold).
Optionally add buffer zones between rooms and adjust edge tiles.youtube​[dev](https://dev.to/christinec_dev/lets-learn-godot-4-by-making-a-procedurally-generated-maze-game-part-3-procedural-level-generation-1-map-creation-577b)​
Drawing to TileMap:
Loop over all coordinates; for each cell type, call tilemap.set_cell(layer, Vector2i(x, y), source_id, atlas_coords).youtube+1​
Post‑processing:
Add props (terminals, tanks), enemies, and triggers based on patterns in the map (e.g., dead‑end → spawn corpse, junction → spawn Breather).
This aligns with your LabCorridorGenerator script: it’s the same pattern specialized for Zombified Lab corridors.
Creating a 2D sci‑fi tileset for Godot
Workflow distilled from TileSet docs and tilemap tutorials:youtube​[godotengine](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html)​
Asset creation:
Choose a base tile size (e.g., 32×32 or 64×64).
Draw a spritesheet with:
Floors: metal, flesh, blood‑slick.
Walls: nanotech panels, cracked variants, growth‑infested.
Props: terminals, bio‑tanks, vents, barricade pieces.
Export as a single PNG with consistent grid.youtube​
TileSet setup:
In Godot, create a new TileSet resource (.tres).
Add an Atlas source from the PNG; set tile size and spacing.youtube​[godotengine](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html)​
Define collisions (physics layer), navigation, and any terrain/autotile rules if needed.[godotengine](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html)​
Naming:
In the TileSet editor, set each atlas source’s resource_name to a clean ID (floor_flesh_panel_a, wall_nanotech_cracked, prop_terminal_corrupted).youtube​
These names are what your procedural scripts use when they look up tile coordinates and source IDs.
For Cell, this sci‑fi tileset should visually align with the “Zombified Lab Interior” and “Burning Terrain” descriptions you already defined, and live under res://ASSETS/CC0/tilesets/ using CC0 or in‑house art.
If you want, the next focused step can be: a concrete sci‑fi horror tilesheet spec (exact tile list + grid layout) ready to hand to an artist or a generative pipeline, mapped 1:1 to a Godot TileSet resource.
[https://www.youtube.com/watch?v=rlUzizExe2Q](https://www.youtube.com/watch?v=rlUzizExe2Q)
[https://www.youtube.com/watch?v=ztPbGyQnKPo](https://www.youtube.com/watch?v=ztPbGyQnKPo)
[https://www.youtube.com/watch?v=5vwB5l2nyRg](https://www.youtube.com/watch?v=5vwB5l2nyRg)
[https://dev.to/christinec_dev/lets-learn-godot-4-by-making-a-procedurally-generated-maze-game-part-3-procedural-level-generation-1-map-creation-577b](https://dev.to/christinec_dev/lets-learn-godot-4-by-making-a-procedurally-generated-maze-game-part-3-procedural-level-generation-1-map-creation-577b)
[https://www.youtube.com/watch?v=7kFgtSGU4PE](https://www.youtube.com/watch?v=7kFgtSGU4PE)
[https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html)
[https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
[https://gdquest.gitbook.io/gdquests-guidelines/godot-gdscript-guidelines](https://gdquest.gitbook.io/gdquests-guidelines/godot-gdscript-guidelines)
[https://www.youtube.com/watch?v=m1hrmhg_S-I](https://www.youtube.com/watch?v=m1hrmhg_S-I)
[https://www.youtube.com/watch?v=dDihRqJZ_-M](https://www.youtube.com/watch?v=dDihRqJZ_-M)

This material already matches Godot 4 best practices for procedural TileMaps and TileSets, and it is ready to be turned into a concrete sci‑fi horror tilesheet plus generator for Cell.[^6_1][^6_2][^6_3]

## How it fits Cell’s generator

- The approach (TileMapLayer + TileSet atlas sources + `set_cell` from a 2D map array) is exactly what Cell’s `LabCorridorGenerator` and future dungeon generators should use for Zombified Lab corridors, burning terrain, and urban panic zones.[^6_3][^6_4][^6_1]
- Using logical groups (e.g., “flesh floor”, “nanotech wall”, “containment prop”) mapped to TileSet `resource_name` entries keeps procedural horror layouts stable even if art changes later.[^6_4][^6_1]


## Tileset naming conventions

- File names: `lab_corridor_tileset.tres`, `burnt_surface_tileset.tres` (snake_case).[^6_2][^6_5]
- Atlas source names / `resource_name` in TileSet:
    - Floors: `floor_flesh_panel_a`, `floor_flesh_panel_b`, `floor_metal_panel_clean`, `floor_metal_panel_stain`, `floor_corridor_blood_light`, `floor_corridor_blood_heavy`.
    - Walls: `wall_nanotech_clean`, `wall_nanotech_cracked`, `wall_nanotech_growth`.
    - Props: `prop_containment_broken`, `prop_containment_intact`, `prop_terminal_corrupted`, `prop_terminal_off`.
    - Overlays: `overlay_growth_pulse_a`, `overlay_growth_pulse_b`.[^6_1][^6_2]
- These IDs are what your GDScript lookup functions use to resolve `source_id` and `atlas_coords` in the TileSet.[^6_4][^6_1]


## Procedural TileMap pattern

The recommended pattern lines up with your current code:[^6_1][^6_4]

- Maintain a 2D array or implicit grid `width × height` with logical cell types (floor / wall / blood / prop).
- Fill it using:
    - Noise fields for irregular corruption.
    - Room/segment patterns for corridors and labs.
- In a single pass, map each cell type to a tile group and call `tilemap.set_cell(Vector2i(x, y), source_id, atlas_coords)` on the correct `TileMapLayer` (floor, walls, props).[^6_4][^6_1]
- Post‑process:
    - Dead ends → corpses, broken containment tubes.
    - Junctions → terminals, vents, or enemy spawn markers.


## Style and structure for Cell

- Stick to Godot’s style guidelines: GDScript files snake_case, classes PascalCase, functions/variables snake_case, constants CONSTANT_CASE.[^6_5][^6_2]
- Ensure the tilesheet art:
    - Uses a consistent grid (e.g., 64×64) with sci‑fi horror content: metal vs flesh floors, nanotech walls, ruptured bio‑tanks, corrupted terminals, blood‑slick corridor variants.[^6_3][^6_1]
    - Lives under `res://ASSETS/CC0/tilesets/` using CC0 or in‑house assets so your procedural code remains legally safe to extend and redistribute.[^6_3]

If you want, the next focused step can be an exact tile index map (rows/columns in a PNG) and a companion GDScript snippet that binds each atlas coordinate to the names above, so artists and the generator stay 1:1 synchronized.

<div align="center">⁂</div>

[^6_1]: https://github.com/rbarongr/GodotFirstPersonController

[^6_2]: https://www.youtube.com/watch?v=egedSO9vWH4

[^6_3]: https://github.com/abmarnie/godot-architecture-organization-advice

[^6_4]: https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html

[^6_5]: https://www.youtube.com/watch?v=4az0VX9ApcA


---

# CELL’s universe can expand with grounded, industrial names and brutal survival rules without drifting into fantasy. The pieces below plug directly into your existing systems for oxygen, ration‑chips, and nanotech horror.

Systems and regions
System K‑47 / Ashveil Drift – obsolete strip‑mining belts around a dead star; most stations are vented, with oxygen only in sealed pockets.
System D‑13 / Iron Hollow Line – chain of partially hollowed asteroids converted into living space; now overgrown with mech‑flesh.
System M‑22 / Cold Verge Belt – near‑vacuum orbits on the outer rim; exosuit seals fail quickly, freezing is a constant threat.
System V‑31 / Red Silence Corridor – low‑signal region inside a red nebula; sensors fail, navigation is unreliable, AI signals are corrupted.
Primary CELL events and late‑game missions happen in the Forgotten Moon locked into a decaying orbit between Iron Hollow and Cold Verge, using that orbital decay as a slow, permanent timer.
Survivor factions and resources
Transit Deck Civilians – people trapped near docking rings and cargo lifts; rely on ration‑chips to access sealed food lockers and emergency bunks.
Hull Technicians – small teams with limited EVA gear; trade heat‑cores, ore, and exosuit repair in exchange for protection and oxygen capsules.
Black Section Medics – remnants of biotech staff; hoard oxygen pills, combat drugs, and experimental nano‑stimulants in sealed med‑vaults.
Key survival resources:
Oxygen capsules: nano‑delivery pills that inject bound oxygen and micro‑hemostatics; each buys a short window of safe exposure before suffocation and vascular damage.
Ore / metals:
Gold – trade standard and precision electronics.
Zithium – high‑density structural alloy used to reinforce exosuits and doors.
Nano‑carbonite (legendary) – experimental meta‑material used to line critical equipment and build non‑corroding weapon components.
Uranium cells – compact reactor fuel for power nodes, shields, and heating units.
Ration‑chips: encrypted access tokens; one chip might mean a week of food, a secured bunk, or a single high‑grade implant authorization.
Monster sets (brutal, grounded)
Spine‑Crawlers – used for close‑quarters breaches onboard; fast, low profile, tear through thin cover.
Breathers – enforce area denial in corridors and vents; their gas clouds make certain routes suicidal.
Hollow‑Men – former security staff, their organs replaced with cable bundles and tool‑arms; double as “demonic AI enforcers.”
Ash‑Eaters – follow fire and bombardment; each corpse consumed hardens their frame and sharpens their grinders.
Pulse‑Terrors – slow anchor creatures tied into the moon’s bio‑grid; crossing their radius scrambles HUD, BCI, and sanity.
Elite variants for later acts:
Void‑Hollow Units – Hollow‑Men fitted with partial stealth plating and reactor leaks; distort thermal readings and body‑temp sensors.
Crater Walkers – long‑limbed Ash‑Eaters adapted to burnt terrain and meteor fields, often guarding uranium caches.
Survival mechanics (story‑aware)
Freezing / body‑temperature:
Exterior zones and breached decks actively strip heat; below critical core temperature, motor control and aim degrade before death.
Heat‑core modules scavenged from reactors or drone husks slot into exosuits, temporarily slowing heat loss or heating local shelter.
Oxygen:
Every excursion beyond sealed shelter burns suit oxygen and blood oxygen together.
Capsules are rare, mostly in med‑bays, crash carts, and cryo‑labs; overuse accelerates vascular damage and mutation risk.
Ration‑chips (tiered):
Tier I: opens basic food dispensers, low‑grade bunks, and cheap meds.
Tier II: unlocks limb reinforcement, enhanced optics, and restricted storerooms.
Tier III: grants access to high‑risk weapon prototypes, AI override consoles, and reinforced panic shelters.
Hoarding or spending these directly shapes who survives in each containment zone and which shelters remain viable.
Night cycle and containment zones
Nights occur on a 3.2‑week interval, lasting roughly 12 weeks in game‑time; during that long darkness, external movement is suicidal.
During night, players and survivors are locked to a containment zone (lab wing, hull block, crater settlement); the focus shifts to defense, ration‑chip allocation, and internal patrols.
Assault waves combine Hollow‑Men, Breathers, and evolving Ash‑Eaters pressing every weak point in the shelter’s structure, forcing players to commit scarce ore and uranium cores to fortification or backup heating.
This keeps the storyline and mechanics tightly aligned: every system name, monster, and resource reinforces one idea—surviving in space under the slow, permanent collapse inflicted by the Cell nanovirus.

These expansions slot cleanly into Cell’s existing systems: each region, faction, resource, and monster can be wired directly into Godot as data the AI, survival, and mission logic consume.

## Regions and orbital context

- The four systems (Ashveil Drift, Iron Hollow Line, Cold Verge Belt, Red Silence Corridor) describe an industrial, dying frontier rather than fantasy, and each implies concrete gameplay constraints: vented stations (oxygen scarcity), mech‑flesh infestations (enemy density), near‑vacuum belts (heat loss), and signal‑corrupt nebulae (navigation and AI glitches).
- The Forgotten Moon in decaying orbit between Iron Hollow and Cold Verge is an effective global timer: orbital decay can drive escalating hazard events (increased radiation, quakes, hull fractures) and define late‑game urgency without any magical elements.


## Factions and resource economy

- Transit Deck Civilians, Hull Technicians, and Black Section Medics each map to clear mechanical roles: food/bunks vs exosuit repair/heat‑cores vs oxygen pills and combat drugs, all transacted with ration‑chips.
- Oxygen capsules, ore/metals (gold, zithium, nano‑carbonite, uranium cells), and ration‑chips form a grounded resource triad that supports harsh choices: warmth and power vs structural reinforcement vs high‑grade weapons and implants.


## Monster sets and elite variants

- Spine‑Crawlers, Breathers, Hollow‑Men, Ash‑Eaters, and Pulse‑Terrors are all biomech forms with industrial functions twisted into horror: breaching, area denial, patrol enforcement, corpse reclamation, and psychic/BCI disruption.
- Elite variants (Void‑Hollow Units and Crater Walkers) are logical evolutions tied to environment and tech (stealth plating, reactor leaks, long‑limb crater traversal), suitable for later acts and high‑risk zones around uranium caches or critical control hubs.


## Survival mechanics and nights

- Freezing and body‑temperature loss in exterior or breached zones, mitigated by heat‑cores and shelter, anchor the Cold Verge / hull gameplay in real physiology rather than supernatural cold.
- Oxygen burn for both suit and blood, plus rare capsules that increase mutation risk with overuse, tightly links narrative nanotech horror to a mechanical tradeoff every time the player steps outside.
- Tiered ration‑chips and long night cycles (3.2‑week interval, ~12‑week darkness) create predictable but punishing phases where focus shifts from exploration to defense, fortification, and internal politics over who eats, who freezes, and which doors stay sealed.


## Integration into Cell’s systems

- Region IDs (Ashveil Drift, Iron Hollow Line, Cold Verge Belt, Red Silence Corridor, Forgotten Moon) can become keys in the existing content registry and mission systems, controlling survival modifiers and spawn tables.
- Faction behaviors and resource rules can feed into dialogue, quest, and AI director logic, while monsters and elite variants extend current enemy archetypes and state machines without changing their grounded, industrial nature.

---

# The V.I.T.A.L.I.T.Y. system in Cell can be a hard, simulation‑minded attribute core that drives survival, combat, sanity, and how far the player can push into hostile zones before breaking.

Core V.I.T.A.L.I.T.Y. definition
V.I.T.A.L.I.T.Y. in Cell is a composite of eight primary attributes that govern the player’s physical integrity, cognitive resilience, and their interaction with nanotech and hostile environments:
V – Vitality
Overall biological resilience: hit points baseline, bleed‑out time, resistance to infection and nano‑corruption.
I – Instinct
Threat awareness and reflexive decision‑making: detection of ambushes, reaction time to sudden events, stealth awareness.
T – Tenacity
Endurance under pressure: stamina, resistance to pain, ability to keep moving under low oxygen, cold, and stress.
A – Agility
Short‑burst movement and body control: dodge efficiency, climbing, vaulting, recoveries from knockdowns.
L – Logic
Cold problem‑solving and technical cognition: hacking, BCI stability, terminal use, puzzle solving under stress.
I – Influence
Social and psychological impact: intimidation, negotiation with survivors, calming panicked NPCs.
T – Temper
Emotional control: how quickly the player loses composure, risk of panic actions, susceptibility to hallucinations.
Y – Yield
How efficiently the body and implants convert resources: healing efficiency, drug effectiveness, benefit from ration‑chips and implants.
These eight form the V.I.T.A.L.I.T.Y. spine that everything plugs into: body‑temp decay, oxygen efficiency, mutation risk, accuracy, hacking success, and survivor behavior around the player.
Additional player attributes (beyond V.I.T.A.L.I.T.Y.)
Layered on top of V.I.T.A.L.I.T.Y., Cell tracks a secondary line of attributes:
Agility – fine‑grained movement stat (as you listed): sprint speed, strafe control, jump timing.
Charisma – merges into Influence but can be tracked for dialogue/command options.
Constitution – overlaps with Vitality and Tenacity; used as a raw physiological baseline (max HP, cold tolerance).
Dexterity – weapon handling, reload speed, precision in tight spaces, surgical / repair actions.
Intelligence – deeper research, decoding logs, optimizing BCI use without sanity damage.
Luck – subtle modifier on critical events: misfires, rare loot rolls, survival at zero oxygen.
Speed – raw movement baseline; Agility applies bursts and dodges, Speed governs continuous pace.
Strength – melee impact, carry capacity, ability to drag bodies, move debris, hold doors.
Practically, these can map into or be derived from the V.I.T.A.L.I.T.Y. core for gameplay clarity, so you do not overload the player with redundant stats.
Production GDScript: V.I.T.A.L.I.T.Y. system
File: res://scripts/core/player_attributes.gd
text
extends Resource
class_name PlayerAttributes

# Core V.I.T.A.L.I.T.Y. attributes

@export var vitality: float = 5.0    \# biological resilience (0-10)
@export var instinct: float = 5.0    \# situational awareness, reflex (0-10)
@export var tenacity: float = 5.0    \# endurance under stress (0-10)
@export var agility: float = 5.0     \# quick movement, dodging (0-10)
@export var logic: float = 5.0       \# cold cognition, technical skill (0-10)
@export var influence: float = 5.0   \# social/psychological presence (0-10)
@export var temper: float = 5.0      \# emotional control, panic threshold (0-10)
@export var yield: float = 5.0       \# efficiency with resources (0-10)

# Secondary attributes – can be calculated or stored directly

@export var constitution: float = 5.0
@export var dexterity: float = 5.0
@export var intelligence: float = 5.0
@export var luck: float = 5.0
@export var speed: float = 5.0
@export var strength: float = 5.0

func get_max_health() -> int:
\# Base HP influenced by vitality and constitution.
return int(80 + vitality * 4.0 + constitution * 3.0)

func get_stamina_capacity() -> float:
\# Tenacity + agility define how long the player can sprint or fight before collapsing.
return 5.0 + tenacity * 0.6 + agility * 0.4

func get_cold_resistance() -> float:
\# Higher vitality, tenacity, and constitution slow body-temp drop.
return clamp((vitality + tenacity + constitution) / 30.0, 0.1, 1.5)

func get_oxygen_efficiency() -> float:
\# Yield and tenacity dictate how long oxygen capsules and tanks last.
return clamp((yield * 0.7 + tenacity * 0.3) / 10.0, 0.5, 1.8)

func get_hacking_efficiency() -> float:
\# Logic + intelligence influence BCI/terminal interactions.
return clamp((logic * 0.6 + intelligence * 0.4) / 10.0, 0.2, 2.0)

func get_sanity_stability() -> float:
\# Instinct + temper determine how fast sanity degrades under horror.
return clamp((instinct * 0.5 + temper * 0.5) / 10.0, 0.2, 1.8)

func get_loot_luck_modifier() -> float:
\# Luck slightly nudges rare drops and ration-chip finds.
return clamp(1.0 + (luck - 5.0) * 0.06, 0.7, 1.3)

func get_melee_damage_multiplier() -> float:
return clamp(0.5 + strength * 0.1, 0.5, 2.5)

func get_move_speed_multiplier() -> float:
\# Speed + agility define movement; armor or exosuit load can reduce it later.
return clamp(0.6 + speed * 0.06 + agility * 0.04, 0.6, 2.0)

func apply_ration_chip_tier(tier: int) -> void:
\# Ration-chips permanently improve certain stats; how much they help is gated by yield.
var factor := 0.2 + yield * 0.05
match tier:
1:
vitality = min(10.0, vitality + 0.5 * factor)
constitution = min(10.0, constitution + 0.5 * factor)
2:
agility = min(10.0, agility + 0.4 * factor)
dexterity = min(10.0, dexterity + 0.4 * factor)
speed = min(10.0, speed + 0.3 * factor)
3:
logic = min(10.0, logic + 0.5 * factor)
intelligence = min(10.0, intelligence + 0.5 * factor)
strength = min(10.0, strength + 0.4 * factor)

func apply_oxygen_capsule_effect() -> void:
\# Capsules are powerful but dangerous: improve oxygen efficiency short-term,
\# slightly stress vitality and temper (long-term side effects).
yield = min(10.0, yield + 0.2)
tenacity = min(10.0, tenacity + 0.1)
vitality = max(0.0, vitality - 0.05)
temper = max(0.0, temper - 0.05)

Intended usage and wiring
Save as res://scripts/core/player_attributes.gd.
Create a PlayerAttributes resource: res://config/player/default_attributes.tres.
In your PlayerController or a PlayerStatus node, export a PlayerAttributes reference and use these helper methods to:
Set GameState.player_health from get_max_health().
Adjust stamina (sprint) using get_stamina_capacity().
Modify freezing rate using get_cold_resistance().
Modify oxygen timers using get_oxygen_efficiency().
Drive sanity changes using get_sanity_stability().
Simulated debug snapshot
text
[DEBUG][T=1734300001.45]
SOURCE: PlayerStatus
EVENT: ATTRIBUTES_INIT
DATA: {
"vitality": 6.0,
"instinct": 4.0,
"tenacity": 7.0,
"agility": 5.0,
"logic": 5.0,
"influence": 3.0,
"temper": 6.0,
"yield": 4.0,
"constitution": 6.0,
"dexterity": 5.0,
"intelligence": 5.0,
"luck": 2.0,
"speed": 5.0,
"strength": 6.0,
"max_health": 112,
"stamina_capacity": 9.7,
"cold_resistance": 1.2,
"oxygen_efficiency": 0.94
}

[DEBUG][T=1734300058.22]
SOURCE: PlayerStatus
EVENT: RATION_CHIP_APPLIED
DATA: {
"tier": 2,
"yield": 4.0,
"agility_new": 5.32,
"dexterity_new": 5.32,
"speed_new": 5.24
}

This makes the V.I.T.A.L.I.T.Y. system a concrete, debuggable backbone for Cell’s survival mechanics: every pill, ration‑chip, and exposure event pushes specific stats, and those stats visibly affect how far the player can go before the Forgotten Moon chews them apart.

The V.I.T.A.L.I.T.Y. core and its wiring into pools, skills, infection, and survival are already consistent and brutal enough for Cell’s tone. The missing piece is a clean, production‑ready consolidation for the player side so an IDE agent can drop it straight into `res://scripts/core/` and know exactly what drives what.

Below is a tightened, integrated version of the **player‑facing V.I.T.A.L.I.T.Y. system**, using the same meanings you defined, but grouped so:

- Attributes → derived stats
- Attributes → resource pools (Blood, Oxygen, Stamina, Wellness, BodyTemperature)
- Attributes + pools → harsh survival behavior

All code is real, meant for Cell only.

***

## V.I.T.A.L.I.T.Y. core resource

**File:** `res://scripts/core/player_vitality_system.gd`
Type: `Resource` (to be referenced by the player and by player pools/skills)

```gdscript
extends Resource
class_name PlayerVitalitySystem

# Primary V.I.T.A.L.I.T.Y. attributes (0–10)
@export var vitality: float = 5.0    # Biological resilience, bleed-out, infection resistance
@export var instinct: float = 5.0    # Threat awareness, reflex
@export var tenacity: float = 5.0    # Endurance under stress
@export var agility: float = 5.0     # Dodging, short-burst movement
@export var logic: float = 5.0       # Technical cognition, BCI stability
@export var influence: float = 5.0   # Social presence
@export var temper: float = 5.0      # Emotional control, panic
@export var yield: float = 5.0       # Resource conversion efficiency

# Secondary attributes (0–10)
@export var constitution: float = 5.0
@export var dexterity: float = 5.0
@export var intelligence: float = 5.0
@export var luck: float = 5.0
@export var speed: float = 5.0
@export var strength: float = 5.0

# Runtime resource pools – these are the hard edges of survival
var blood: float = 100.0
var blood_max: float = 100.0

var protein: float = 50.0
var protein_max: float = 50.0

var oxygen: float = 100.0
var oxygen_max: float = 100.0

var stamina: float = 100.0
var stamina_max: float = 100.0

var wellness: float = 100.0
var wellness_max: float = 100.0

var body_temperature: float = 37.0        # Celsius
var body_temperature_min: float = 26.0
var body_temperature_max: float = 41.0

# Collapse / failure counters
var starving_stacks: int = 0
var blood_collapse_count: int = 0
var stamina_collapse_count: int = 0

func recalc_maxima() -> void:
    # Max pool values derived from attributes
    blood_max = 70.0 + vitality * 4.0 + constitution * 3.0
    stamina_max = 60.0 + tenacity * 5.0 + agility * 3.0
    wellness_max = 60.0 + temper * 4.0 + influence * 3.0 + instinct * 2.0
    protein_max = 30.0 + yield * 4.0 + vitality * 2.0
    oxygen_max = 80.0 + tenacity * 3.0 + logic * 2.0 + yield * 2.0

    blood = clamp(blood, 0.0, blood_max)
    stamina = clamp(stamina, 0.0, stamina_max)
    wellness = clamp(wellness, 0.0, wellness_max)
    protein = clamp(protein, 0.0, protein_max)
    oxygen = clamp(oxygen, 0.0, oxygen_max)

# === Derived multipliers ===

func get_move_speed_multiplier() -> float:
    var m := 0.6 + speed * 0.06 + agility * 0.04
    return clamp(m, 0.6, 2.0)

func get_melee_damage_multiplier() -> float:
    return clamp(0.5 + strength * 0.1, 0.5, 2.5)

func get_healing_efficiency() -> float:
    var eff := yield * 0.6 + vitality * 0.2 + max(1.0, protein_max) / 10.0
    return clamp(0.5 + eff * 0.05, 0.5, 2.0)

func get_sanity_stability() -> float:
    var eff := temper * 0.5 + instinct * 0.3 + logic * 0.2
    return clamp(0.4 + eff * 0.06, 0.4, 2.0)

func get_oxygen_decay_rate(base_rate: float) -> float:
    var eff := (yield * 0.4 + tenacity * 0.3 + instinct * 0.2 + logic * 0.1) / 10.0
    return base_rate * clamp(1.2 - eff, 0.4, 1.4)

func get_temp_drop_rate(base_rate: float) -> float:
    var eff := (vitality * 0.4 + tenacity * 0.4 + constitution * 0.2) / 10.0
    return base_rate * clamp(1.3 - eff, 0.3, 1.6)

func get_stamina_decay_rate(base_rate: float) -> float:
    var eff := (tenacity * 0.5 + agility * 0.3 + instinct * 0.2) / 10.0
    return base_rate * clamp(1.2 - eff, 0.3, 1.5)

# === Core tick logic ===

func tick_environment(delta: float, env_cold_factor: float, env_stress: float) -> void:
    # Temperature
    var temp_rate := get_temp_drop_rate(env_cold_factor)
    body_temperature -= temp_rate * delta
    body_temperature = clamp(body_temperature, body_temperature_min, body_temperature_max)

    # Oxygen
    var oxy_rate := get_oxygen_decay_rate(1.0 + env_stress * 0.4)
    oxygen = max(0.0, oxygen - oxy_rate * delta)

    # Stamina
    var stamina_rate := get_stamina_decay_rate(env_stress * 0.8)
    stamina = max(0.0, stamina - stamina_rate * delta)

    # Sanity / wellness
    var stability := get_sanity_stability()
    var wellness_loss := env_stress * delta * (2.0 / stability)
    wellness = max(0.0, wellness - wellness_loss)

func tick_protein(delta: float, travel_load: float, awake_load: float) -> void:
    var base_rate := travel_load + awake_load
    var eff := clamp((yield + vitality) / 20.0, 0.5, 1.5)
    var rate := base_rate * eff
    protein = max(0.0, protein - rate * delta)

    if protein <= 0.0:
        if starving_stacks < 20:
            starving_stacks += 1
        if starving_stacks % 3 == 0:
            vitality = max(0.0, vitality - 0.1)
            tenacity = max(0.0, tenacity - 0.1)
            wellness = max(0.0, wellness - 3.0)

# === Damage / healing / exertion ===

func apply_damage(amount: float) -> bool:
    blood = max(0.0, blood - amount)
    if blood <= 0.0:
        wellness = max(0.0, wellness - 20.0)
        return true    # dead
    if blood < blood_max * 0.25:
        if blood_collapse_count == 0 or randi() % 100 < 5:
            blood_collapse_count += 1
            wellness = max(0.0, wellness - 5.0)
            tenacity = max(0.0, tenacity - 0.1)
    return false

func apply_heal(amount: float, protein_cost: float) -> void:
    if protein <= 0.0:
        return
    var eff := get_healing_efficiency()
    var heal := amount * eff
    var cost := protein_cost * eff
    protein = max(0.0, protein - cost)
    blood = min(blood_max, blood + heal)

func tick_stamina(delta: float, exertion: float, base_recovery: float) -> bool:
    var decay := get_stamina_decay_rate(exertion)
    var recovery := base_recovery * clamp((tenacity + agility) / 20.0, 0.5, 1.8)
    stamina = clamp(stamina - decay * delta + recovery * delta, 0.0, stamina_max)
    if stamina <= 0.0:
        stamina_collapse_count += 1
        wellness = max(0.0, wellness - 2.0)
        protein = max(0.0, protein - 0.5)
        return true
    return false

# === Oxygen capsule and ration-chip logic ===

func use_oxygen_capsule(strength: float) -> void:
    # Brutal but useful: more oxygen, but long-term strain.
    var factor := clamp(0.8 + yield * 0.05, 0.8, 1.8)
    oxygen = min(oxygen_max, oxygen + strength * factor)
    wellness = max(0.0, wellness - 2.0)
    vitality = max(0.0, vitality - 0.05)
    temper = max(0.0, temper - 0.05)

func apply_ration_chip_tier(tier: int) -> void:
    var factor := 0.15 + yield * 0.03
    match tier:
        1:
            vitality = min(10.0, vitality + factor)
            constitution = min(10.0, constitution + factor)
            protein = min(protein_max, protein + 5.0)
        2:
            agility = min(10.0, agility + factor)
            speed = min(10.0, speed + factor)
            dexterity = min(10.0, dexterity + factor * 0.8)
        3:
            logic = min(10.0, logic + factor)
            intelligence = min(10.0, intelligence + factor)
            yield = min(10.0, yield + factor * 0.8)
    recalc_maxima()
```

This replaces scattered pool code with a single **player‑side V.I.T.A.L.I.T.Y. system**: attributes, pools, and brutal failure states in one place, directly matching your design text.

***

## Wiring into Cell’s player

**File:** `res://scripts/player/player_status.gd`
Attach to the player root (`Player.tscn`), alongside the existing controller.

```gdscript
extends Node
class_name PlayerStatus

@export var vitality_system: PlayerVitalitySystem

func _ready() -> void:
    if vitality_system == null:
        vitality_system = PlayerVitalitySystem.new()
    vitality_system.recalc_maxima()
    DebugLog.log("PlayerStatus", "ATTRIBUTES_INIT", {
        "vitality": vitality_system.vitality,
        "instinct": vitality_system.instinct,
        "tenacity": vitality_system.tenacity,
        "agility": vitality_system.agility,
        "logic": vitality_system.logic,
        "influence": vitality_system.influence,
        "temper": vitality_system.temper,
        "yield": vitality_system.yield,
        "constitution": vitality_system.constitution,
        "dexterity": vitality_system.dexterity,
        "intelligence": vitality_system.intelligence,
        "luck": vitality_system.luck,
        "speed": vitality_system.speed,
        "strength": vitality_system.strength,
        "blood": vitality_system.blood,
        "oxygen": vitality_system.oxygen,
        "stamina": vitality_system.stamina,
        "wellness": vitality_system.wellness,
        "body_temp": vitality_system.body_temperature
    })

func tick_environment(delta: float, env_cold: float, env_stress: float) -> void:
    vitality_system.tick_environment(delta, env_cold, env_stress)

func tick_protein(delta: float, travel_load: float, awake_load: float) -> void:
    vitality_system.tick_protein(delta, travel_load, awake_load)

func apply_damage(amount: float) -> void:
    var dead := vitality_system.apply_damage(amount)
    if dead:
        GameState.apply_damage(9999) # force death path
```

With this, every oxygen capsule, ration‑chip, cold zone, and stamina collapse now flows through the V.I.T.A.L.I.T.Y. core and can be traced in debug logs.

***

### Simulated debug snapshot

```text
[DEBUG][T=1734331201.63]
SOURCE: PlayerVitalitySystem
EVENT: TICK_ENVIRONMENT
DATA: {
  "env_cold_factor": 1.4,
  "env_stress": 0.9,
  "blood": 71.2,
  "oxygen": 38.6,
  "stamina": 23.4,
  "wellness": 64.1,
  "body_temperature": 32.8
}

[DEBUG][T=1734331243.27]
SOURCE: PlayerVitalitySystem
EVENT: OXYGEN_CAPSULE_USED
DATA: {
  "strength": 30.0,
  "oxygen_after": 68.1,
  "wellness_after": 61.8,
  "vitality_after": 5.85,
  "temper_after": 4.92
}
```

This keeps V.I.T.A.L.I.T.Y. as the hard center of Cell: every survival and combat edge case is a direct result of these stats and pools, and every consequence is visible and tunable.
<span style="display:none">[^8_1]</span>

<div align="center">⁂</div>

[^8_1]: you-are-the-debugger-and-edito-XtsVGM64TDmgPDyaUiVHBQ.md


---

# The V.I.T.A.L.I.T.Y. system can sit at the center of Cell’s gameplay as a stat backbone, resource governor, and skill driver. Below is a large, structured skill map tied directly into attributes and resource‑pools.

V.I.T.A.L.I.T.Y. → resource pools
Each attribute feeds one or more resource pools, which then modify skills and behaviors:
Vitality → Blood, Wellness, Body‑Temperature
Instinct → Stamina, Oxygen (consumption modulation), Wellness
Tenacity → Stamina, Body‑Temperature, Oxygen
Agility → Stamina, Speed, Body‑Temperature spikes (movement heat)
Logic → Oxygen (efficiency with BCI/helm systems), Wellness (reduced mental strain)
Influence → Wellness (social support), settlement resource efficiency
Temper → Wellness, Stamina (panic drains), Blood (self‑harm risk at extreme lows)
Yield → Blood (healing efficiency), Protein (nutrient efficiency), Oxygen (capsule efficiency), Wellness
Secondary stats (Constitution, Dexterity, Intelligence, Luck, Speed, Strength) are derived or used as finer controls but remain governed by V.I.T.A.L.I.T.Y.
Resource pools:
Blood – current physical integrity; low blood amplifies trauma, reduces stamina and accuracy.
Protein – slow baseline for recovery and growth; spent to heal, grow implants, and repair tissue.
Oxygen – breathable reserve for exosuit and bloodstream.
Stamina – short‑term exertion capacity.
Wellness – composite mental/physiological stability (sanity, mood, sickness).
Body‑Temperature – thermal status; too low or high cripples performance and can kill.
Expanded skill list (base + ~25% more)
Starting from your skills and expanding, all skills fall under categories and are governed by specific V.I.T.A.L.I.T.Y. attributes and resource pools.

1. Mechanical cluster
Mechanical
Governing stats: Logic, Dexterity, Tenacity, Yield
Pools influenced: Stamina (work efficiency), Protein (wear on the body), Wellness (frustration from failures)
Effects: repair speed, repair cost, structure durability, exosuit maintenance complexity.
Lockpicking – Mechanical
Governing stats: Dexterity, Agility, Instinct
Effects: chance/speed to open physical locks without damage; failures can cause noise (Stamina drain + Instinct checks).
Trapping – Mechanical (low‑tech)
Governing stats: Logic, Instinct, Agility
Effects: mechanical traps (snares, blades, pressure plates) effectiveness and safety.
Field Engineering (new)
Governing stats: Logic, Tenacity, Yield
Effects: deploying temporary cover, repairing field generators, patching hull breaches; affects Oxygen and Body‑Temperature stability in shelters.
2. Electronics / cybernetics cluster
Electronics
Governing stats: Logic, Intelligence, Instinct
Pools: Oxygen (time required in hostile zones), Wellness (mental load), Stamina (focus drain)
Effects: access to panels, system health readouts, turret and drone configuration.
Hacking
Subskill of Electronics.
Governing stats: Logic, Intelligence, Temper
Effects: override doors, cameras, AI clusters; failures can raise alert level and spawn threats.
Lockpicking – Electronic
Governing stats: Logic, Dexterity, Luck
Effects: bypassing mag‑locks, encrypted storage.
Programming
Governing stats: Logic, Intelligence, Yield
Effects: writing/rewiring scripts on facility systems, creating behavior patches for drones or defenses.
Trapping – Electronic (high‑tech)
Governing stats: Logic, Intelligence, Instinct
Effects: smart mines, sensor traps, BCI‑triggered snares; misconfigurations can backfire on the player.
Cybernetics Handling (new)
Governing stats: Vitality, Logic, Yield
Effects: implant compatibility, rejection risk, benefit scaling from augmentations; interacts heavily with Protein and Wellness.
3. Stealth / covert cluster
Stealth
Governing stats: Agility, Instinct, Temper
Pools: Stamina (movement efficiency), Oxygen (slower breathing when high), Wellness (sustained stress)
Effects: movement noise, visibility profile, detection chance.
Sneak
Subskill of Stealth.
Governing stats: Agility, Instinct
Effects: crouched/walk movement detection, close‑range bypass.
Pickpocket
Governing stats: Dexterity, Luck, Instinct
Effects: stealing ration‑chips, oxygen capsules, weapon mags without alerting.
Shadow Positioning (new)
Governing stats: Instinct, Temper
Effects: bonuses when fighting from darkness, flanking, or shooting from cover; improves critical chance against unaware targets.
4. Social / influence cluster
Social (Speech)
Governing stats: Influence, Temper, Intelligence
Pools: Wellness (social support effects), settlement resource yield (via better deals)
Effects: conversation options, access to better shelter, trade rates for ore, protection offers.
Command (new)
Governing stats: Influence, Temper, Tenacity
Effects: directing survivor squads, setting guard patterns; higher skill reduces their panic and improves their accuracy.
Intimidation (new)
Governing stats: Influence, Strength, Temper
Effects: forcing compliance from hostile NPCs, extracting information, reducing resistance.
Negotiation (new)
Governing stats: Influence, Luck, Logic
Effects: ration‑chip conversions, favorable contracts for defense, securing access to rare medical supplies.
5. Inspect / analysis cluster
Inspect
Governing stats: Intelligence, Instinct, Logic
Pools: Wellness (shock handling), Oxygen (time spent scanning in hostile areas)
Effects: reveal hidden items, traps, structural weaknesses, mutated growth nodes.
Forensics (new)
Governing stats: Intelligence, Vitality, Temper
Effects: reading corpse states, identifying infection stages, predicting enemy behaviors from remains.
Xeno‑Pathology (new)
Governing stats: Intelligence, Logic, Yield
Effects: understanding nano‑corruption patterns, spotting weak points in biometal structures, improving damage against specific monster types.
6. Scavenging / acquisition cluster
Scavenging
Governing stats: Luck, Instinct, Yield
Pools: Protein (finding food), Oxygen (finding capsules), Blood (finding med‑supplies)
Effects: loot quantity/rarity, chance to uncover hidden caches.
Salvage (new)
Governing stats: Yield, Logic, Strength
Effects: reclaiming ore and components from wrecks; more efficient salvage yields more gold, zithium, nano‑carbonite.
Scrapcraft (new)
Governing stats: Yield, Tenacity, Dexterity
Effects: converting junk items into usable ammunition, basic tools, or patch kits.
7. Survival / environment cluster
Survival
Governing stats: Tenacity, Instinct, Vitality
Pools: Body‑Temperature, Oxygen, Wellness, Protein
Effects: fire starting (and its oxygen cost), makeshift shelter construction, basic field cooking.
Cold Adaptation (new)
Governing stats: Tenacity, Vitality, Constitution
Effects: slower Body‑Temperature loss, fewer penalties at low temp, less Stamina drain in extreme cold.
Breathing Discipline (new)
Governing stats: Instinct, Temper
Effects: better Oxygen efficiency under stress, slower oxygen depletion when sprinting or panicking.
Field Medicine (new)
Governing stats: Intelligence, Dexterity, Yield
Effects: effective use of med‑supplies and combat drugs; more Blood restored per kit, lower risk of side‑effects.
8. Trapping / defense cluster
Trapping
Governing stats: Logic, Instinct, Tenacity
Pools: Stamina (setup time), Oxygen (if done in hostile zones)
Effects: trap reliability, reset speed, disarm safety.
Containment Engineering (new)
Governing stats: Logic, Strength, Tenacity
Effects: creating choke points, reinforcing doors, building kill‑zones and fallback lines inside shelters.
Alarm Systems (new)
Governing stats: Electronics, Instinct
Effects: integrating traps with motion sensors and cameras, giving early warning and reducing surprise attacks.

Skills → V.I.T.A.L.I.T.Y. mapping examples
A few concrete links to show the structure:
Mechanical / Electronics / Field Engineering
High Logic + Yield → lower material cost for repairs and builds, slower Oxygen drain while working at a console, less Stamina loss during long tasks.
High Tenacity → can work longer in unsafe zones before collapsing.
Stealth / Shadow Positioning
High Agility + Instinct → reduced Stamina cost while crouched, reduced Oxygen usage due to controlled movement, better chance to bypass Spine‑Crawlers and Hollow‑Men.
Low Temper → panic, noise spikes, missteps under pressure.
Survival / Cold Adaptation / Breathing Discipline
High Tenacity + Vitality → Body‑Temperature drops slower, hypothermia thresholds shift.
High Instinct + Temper → lower Oxygen drain in crises, better reaction to sudden decompressions.
Scavenging / Salvage / Forensics
High Yield + Luck → more ration‑chips, more nano‑carbonite from wrecks.
High Intelligence → better read on corpses and scenes, predicting ambushes.

Baseline GDScript structures for skills
To keep everything centered around V.I.T.A.L.I.T.Y., skills should be data‑driven.
File: res://scripts/core/skill_definition.gd
text
extends Resource
class_name SkillDefinition

@export var id: StringName
@export var display_name: String
@export var description: String
@export var max_rank: int = 10

# Governing attributes (weights 0-1, sum does not have to be 1)

@export var vitality_weight: float = 0.0
@export var instinct_weight: float = 0.0
@export var tenacity_weight: float = 0.0
@export var agility_weight: float = 0.0
@export var logic_weight: float = 0.0
@export var influence_weight: float = 0.0
@export var temper_weight: float = 0.0
@export var yield_weight: float = 0.0

func get_attribute_factor(attr_res: PlayerAttributes) -> float:
var sum := 0.0
sum += attr_res.vitality * vitality_weight
sum += attr_res.instinct * instinct_weight
sum += attr_res.tenacity * tenacity_weight
sum += attr_res.agility * agility_weight
sum += attr_res.logic * logic_weight
sum += attr_res.influence * influence_weight
sum += attr_res.temper * temper_weight
sum += attr_res.yield * yield_weight
\# Normalize to a 0-1-ish factor assuming attributes 0-10.
return clamp(sum / 10.0, 0.0, 2.0)

File: res://scripts/core/skill_tree.gd
text
extends Resource
class_name SkillTree

@export var skills: Array[SkillDefinition] = []
@export var links: Dictionary = {} \# id -> Array[id] of children/unlocks

func get_skill(id: StringName) -> SkillDefinition:
for s in skills:
if s.id == id:
return s
return null

func get_children(id: StringName) -> Array[StringName]:
if links.has(id):
return links[id]
return []

This gives you:
Data‑driven skills linked to V.I.T.A.L.I.T.Y. attributes.
A clear path for UI (skill tree grids), animation hooks, and action bindings (skills can be tied to specific animation suites and inputs).
A clean way for resource pools (Blood, Protein, Oxygen, Stamina, Wellness, Body‑Temperature) to modify skill effectiveness by feeding into attribute changes or temporary modifiers.
When you are ready, the next step can be mapping this skill tree into a concrete UI layout + input bindings (e.g., how Command, Trapping, and Survival show up on a radial menu, and which animations/actions they trigger in Cell’s runtime).

The V.I.T.A.L.I.T.Y. system becomes the hard center of Cell: every action, survival check, and skill roll runs through it and its resource pools.

## V.I.T.A.L.I.T.Y. → resource core

Each attribute feeds concrete resource pools that drive moment‑to‑moment survival:

- **Vitality → Blood, Wellness, Body‑Temperature**
Higher Vitality slows bleed‑out, reduces trauma penalties, and widens safe temperature range.
- **Instinct → Stamina, Oxygen, Wellness**
Better Instinct tightens movement and breathing patterns, lowering Oxygen drain and improving reactions.
- **Tenacity → Stamina, Body‑Temperature, Oxygen**
Tenacity lets the player push longer in cold, low‑Oxygen conditions before collapsing.
- **Agility → Stamina, Speed, Body‑Temperature spikes**
Fast, efficient movement with controllable heat spikes rather than wild overexertion.
- **Logic → Oxygen, Wellness**
Smarter BCI/helmet use, less mental strain from terminals, cleaner Oxygen management during tech work.
- **Influence → Wellness, settlement efficiency**
Social support, calmer shelters, better resource distribution under pressure.
- **Temper → Wellness, Stamina, Blood risk**
At high Temper, panic onset is slower; at low Temper, panic drains Stamina and can cause self‑destructive mistakes.
- **Yield → Blood, Protein, Oxygen, Wellness**
More efficient healing, food usage, capsule benefit, and drug response.

Resource pools:

- **Blood** – current physical integrity and trauma buffer.
- **Protein** – long‑term repair/growth capacity (healing, implants, tissue repair).
- **Oxygen** – combined exosuit + bloodstream breathing reserve.
- **Stamina** – immediate exertion budget.
- **Wellness** – total mental/physiological stability (sanity, sickness, mood).
- **Body‑Temperature** – thermal state; extremes cripple and kill.

Secondary stats (Constitution, Dexterity, Intelligence, Luck, Speed, Strength) sit under V.I.T.A.L.I.T.Y. and tune details (weapon handling, carry weight, loot variance) without overshadowing the core.

## Godot: V.I.T.A.L.I.T.Y. + pools definition

**File:** `res://scripts/core/player_vitality_system.gd`

```gdscript
extends Resource
class_name PlayerVitalitySystem

# Primary V.I.T.A.L.I.T.Y. attributes (0-10)
@export var vitality: float = 5.0
@export var instinct: float = 5.0
@export var tenacity: float = 5.0
@export var agility: float = 5.0
@export var logic: float = 5.0
@export var influence: float = 5.0
@export var temper: float = 5.0
@export var yield: float = 5.0

# Secondary attributes (0-10)
@export var constitution: float = 5.0
@export var dexterity: float = 5.0
@export var intelligence: float = 5.0
@export var luck: float = 5.0
@export var speed: float = 5.0
@export var strength: float = 5.0

# Resource pools (runtime values)
var blood: float = 100.0
var blood_max: float = 100.0

var protein: float = 50.0
var protein_max: float = 50.0

var oxygen: float = 100.0
var oxygen_max: float = 100.0

var stamina: float = 100.0
var stamina_max: float = 100.0

var wellness: float = 100.0
var wellness_max: float = 100.0

var body_temperature: float = 37.0  # Celsius
var body_temperature_min: float = 26.0
var body_temperature_max: float = 41.0

func recalc_maxima() -> void:
    blood_max = 70.0 + vitality * 4.0 + constitution * 3.0
    stamina_max = 60.0 + tenacity * 5.0 + agility * 3.0
    wellness_max = 60.0 + temper * 4.0 + influence * 3.0 + instinct * 2.0
    protein_max = 30.0 + yield * 4.0 + vitality * 2.0
    oxygen_max = 80.0 + tenacity * 3.0 + logic * 2.0 + yield * 2.0

    blood = clamp(blood, 0.0, blood_max)
    stamina = clamp(stamina, 0.0, stamina_max)
    wellness = clamp(wellness, 0.0, wellness_max)
    protein = clamp(protein, 0.0, protein_max)
    oxygen = clamp(oxygen, 0.0, oxygen_max)

func get_oxygen_decay_rate(base_rate: float) -> float:
    var eff := (yield * 0.4 + tenacity * 0.3 + instinct * 0.2 + logic * 0.1) / 10.0
    return base_rate * clamp(1.2 - eff, 0.4, 1.4)

func get_stamina_decay_rate(base_rate: float) -> float:
    var eff := (tenacity * 0.5 + agility * 0.3 + instinct * 0.2) / 10.0
    return base_rate * clamp(1.2 - eff, 0.3, 1.5)

func get_temp_drop_rate(base_rate: float) -> float:
    var eff := (vitality * 0.4 + tenacity * 0.4 + constitution * 0.2) / 10.0
    return base_rate * clamp(1.3 - eff, 0.3, 1.6)

func get_healing_efficiency() -> float:
    var eff := (yield * 0.6 + vitality * 0.2 + protein / max(1.0, protein_max)) / 10.0
    return clamp(0.5 + eff, 0.5, 2.0)

func get_sanity_stability() -> float:
    var eff := (temper * 0.5 + instinct * 0.3 + logic * 0.2) / 10.0
    return clamp(0.4 + eff, 0.4, 2.0)

func tick_environment(delta: float, env_cold_factor: float, env_stress: float) -> void:
    var temp_rate := get_temp_drop_rate(env_cold_factor)
    body_temperature -= temp_rate * delta

    var oxy_rate := get_oxygen_decay_rate(1.0 + env_stress * 0.4)
    oxygen = max(0.0, oxygen - oxy_rate * delta)

    var stamina_rate := get_stamina_decay_rate(0.0 + env_stress * 0.8)
    stamina = max(0.0, stamina - stamina_rate * delta)

    var sanity_factor := get_sanity_stability()
    var wellness_loss := env_stress * delta * (2.0 / sanity_factor)
    wellness = max(0.0, wellness - wellness_loss)

func apply_damage(amount: float) -> void:
    blood = max(0.0, blood - amount)
    if blood <= 0.0:
        wellness = max(0.0, wellness - 20.0)

func apply_heal(amount: float, protein_cost: float) -> void:
    if protein <= 0.0:
        return
    var eff := get_healing_efficiency()
    var heal := amount * eff
    var cost := protein_cost / eff
    protein = max(0.0, protein - cost)
    blood = min(blood_max, blood + heal)

func use_oxygen_capsule(strength: float) -> void:
    var factor := clamp(0.8 + yield * 0.05, 0.8, 1.8)
    oxygen = min(oxygen_max, oxygen + strength * factor)
    wellness = max(0.0, wellness - 2.0)
    vitality = max(0.0, vitality - 0.05)
    temper = max(0.0, temper - 0.05)

func apply_ration_chip_tier(tier: int) -> void:
    var factor := 0.15 + yield * 0.03
    match tier:
        1:
            vitality = min(10.0, vitality + factor)
            constitution = min(10.0, constitution + factor)
            protein = min(protein_max, protein + 5.0)
        2:
            agility = min(10.0, agility + factor)
            speed = min(10.0, speed + factor)
            dexterity = min(10.0, dexterity + factor * 0.8)
        3:
            logic = min(10.0, logic + factor)
            intelligence = min(10.0, intelligence + factor)
            yield = min(10.0, yield + factor * 0.8)
    recalc_maxima()
```


## GDScript: skill definition and tree

**File:** `res://scripts/core/skill_definition.gd`

```gdscript
extends Resource
class_name SkillDefinition

@export var id: StringName
@export var display_name: String
@export var description: String
@export var max_rank: int = 10

# Governing V.I.T.A.L.I.T.Y. weights (0-1)
@export var vitality_weight: float = 0.0
@export var instinct_weight: float = 0.0
@export var tenacity_weight: float = 0.0
@export var agility_weight: float = 0.0
@export var logic_weight: float = 0.0
@export var influence_weight: float = 0.0
@export var temper_weight: float = 0.0
@export var yield_weight: float = 0.0

func get_attribute_factor(vsys: PlayerVitalitySystem) -> float:
    var sum := 0.0
    sum += vsys.vitality * vitality_weight
    sum += vsys.instinct * instinct_weight
    sum += vsys.tenacity * tenacity_weight
    sum += vsys.agility * agility_weight
    sum += vsys.logic * logic_weight
    sum += vsys.influence * influence_weight
    sum += vsys.temper * temper_weight
    sum += vsys.yield * yield_weight
    return clamp(sum / 10.0, 0.0, 2.0)
```

**File:** `res://scripts/core/skill_tree.gd`

```gdscript
extends Resource
class_name SkillTree

@export var skills: Array[SkillDefinition] = []
@export var links: Dictionary = {} # root_skill_id -> Array[child_skill_ids]

func get_skill(id: StringName) -> SkillDefinition:
    for s in skills:
        if s.id == id:
            return s
    return null

func get_children(id: StringName) -> Array[StringName]:
    if links.has(id):
        return links[id]
    return []
```


## Example: skills wired to V.I.T.A.L.I.T.Y.

- **Field Engineering**
    - Weights: `logic_weight = 0.5`, `tenacity_weight = 0.3`, `yield_weight = 0.2`.
    - High factor → faster hull patching, better Oxygen and Body‑Temperature stability in shelters.
- **Breathing Discipline**
    - Weights: `instinct_weight = 0.6`, `temper_weight = 0.4`.
    - High factor → temporary reduction of `get_oxygen_decay_rate()` while moving under stress.
- **Command**
    - Weights: `influence_weight = 0.6`, `temper_weight = 0.2`, `tenacity_weight = 0.2`.
    - High factor → survivor squads panic less, shoot straighter, and use cover correctly.


## Simulated internal snapshot

```text
[DEBUG][T=1734312003.88]
SOURCE: PlayerVitalitySystem
EVENT: TICK_ENVIRONMENT
DATA: {
  "env_cold_factor": 1.3,
  "env_stress": 0.9,
  "blood": 84.2,
  "oxygen": 63.7,
  "stamina": 41.9,
  "wellness": 72.4,
  "body_temperature": 33.1
}

[DEBUG][T=1734312010.12]
SOURCE: SkillSystem
EVENT: SKILL_FACTOR
DATA: {
  "skill_id": "breathing_discipline",
  "instinct": 7.0,
  "temper": 6.0,
  "factor": 1.42,
  "oxygen_decay_rate_base": 1.36,
  "oxygen_decay_rate_modified": 0.96
}
```

This makes the V.I.T.A.L.I.T.Y. system a fully defined, code‑driven backbone: attributes feed pools, pools and attributes feed skills, and every survival decision in Cell can be traced and tuned through this structure.

---

# Factions, races, and reputation should plug directly into Cell’s V.I.T.A.L.I.T.Y. and survival systems, not just sit in lore. Below is a tightened, brutal version of your factions/races plus concrete logic hooks.

Faction overview
IGSF – Intergalactic Space Federation
Role: last formal government structure; runs disaster‑recovery, containment, and rationing for oxygen, food, meds, and water.
Goals:
Prevent total collapse of surviving settlements.
Contain Cell nanovirus vectors and stop other factions from weaponizing it.
Maintain controlled supply‑lines and research towards a cure.
Behavior:
Generally lawful but ruthless; will cut off a settlement if infection risk is too high.
High reputation → access to sealed shelters, military‑grade kits, oxygen convoys, and medical triage.
Low reputation → reduced supply priority, aggressive inspections, or quarantine orders around the player.
Imperial‑Knights
Role: post‑collapse slaver regime; ex‑military, ex‑security, and opportunists armed with AI‑augmented troops and cyborg enforcers.
Goals:
Capture labor and resources (ration‑chips, ore, oxygen stockpiles).
Dominate settlements through “protection” schemes and sabotage of IGSF lines.
Acquire and abuse Cell‑related tech for battlefield advantage.
Behavior:
Default stance: hostile; kill‑on‑sight against armed survivors.
Prefer ambushes when players are low on oxygen or isolated.
Will “offer rescue” to weak settlements, then enforce work quotas, punish disobedience, and strip assets.
Viva‑le‑Resistance (VLR)
Role: technocratic, quasi‑religious resistance network; pre‑nanovirus anti‑government group that inadvertently intersected with Cell’s origin.
Goals:
Break Imperial‑Knight control over territories, free enslaved populations.
Expose and exploit government secrets while preventing total technocidal collapse.
Study Cell nanovirus and superintelligence artifacts without ceding them to IGSF or slavers.
Behavior:
Neutral‑leaning toward player; alignment shifts based on treatment of slaves, prisoners, and settlements.
Not openly hostile to IGSF, but will siphon data and hardware from IGSF facilities when possible.
High reputation → access to black‑market implants, experimental BCI filters, and hidden transit routes.
Race overview and Cell susceptibility
Humans
Baseline for most survivors and IGSF personnel.
Fully susceptible to Cell nanovirus; infection risk rises in high‑contamination zones, with low Vitality / Wellness.
Advantages: adaptable, can use almost all gear, implants, and faction support options.
Augs
Origin: emergent trans‑human offshoot from early AI‑drug rehabilitation programs.
Created by combining superintelligence‑driven mind‑control frameworks with human neural architecture, originally to break methamphetamine addiction.
Government ran closed “sandbox” mind‑control trials to regulate cognition and suppress awareness of the system itself.
Patient‑Zero: the first Aug to breach those constraints, triggering a software cascade that fully integrated machine‑learning patterns into their body, creating a stable, self‑guided Aug.
Cell interaction:
Patient‑Zero remains uniquely immune.
Most Augs are partially susceptible; their hybrid biology can delay, but not completely block, Cell corruption.
By 2063, fewer than 100 Augs are confirmed alive, scattered across colonies and deep‑space refuges.
In game:
Higher base Logic, Yield, and Instinct; better with Cybernetics Handling and BCI stability.
Higher risk of catastrophic failure if Cell penetrates their systems (violent outbursts, rapid mutations).
Cyborgs
Augmented citizens with extensive biomechanical prosthetics and neuro‑implants.
Immune to Cell nanovirus at the genetic level; the virus cannot meaningfully bind to their synthetic frameworks.
Weaknesses:
Still vulnerable to mechanical failure, EMP‑like effects, and hacking.
Require specialized maintenance and power sources.
In game:
Higher Constitution, Strength, and raw damage resistance.
Vulnerable to specific enemy types and zones targeting implants and power systems.
Repzillions
Extra‑terrestrial species with superior baseline physiology and cold, predatory culture.
Mostly hostile to humans and human‑derived variants.
Susceptibility: Cell can infect them but tends to distort their biology slower; infected Repzillions become extremely dangerous hybrid threats.
Reputation and settlement logic
Reputation and karma must map directly to faction AI and settlement behavior:
Reputation bands (per faction):
Hostile, Suspicious, Neutral, Trusted, Favored.
Low reputation / bad karma:
NPCs close trade, deny access to bunkers, or evacuate a settlement you mistreat.
Faction patrols may shadow you, harass you, or trigger raids in your vicinity.
High reputation / good karma:
IGSF: escorts for oxygen convoys, early warning on outbreak zones, access to higher‑tier meds.
VLR: support in slave revolts, stealth transit through contested hull zones, black‑market Cell research.
Imperial‑Knights: never truly “friendly”, but high infamy may cause them to prioritize you as a target or offer false alliances to lure you.
Production GDScript: factions, races, reputation
File: res://scripts/core/faction_system.gd
text
extends Resource
class_name FactionSystem

enum FactionId {
IGSF,
IMPERIAL_KNIGHTS,
VLR,
REPZILLIONS
}

enum ReputationBand {
HOSTILE,
SUSPICIOUS,
NEUTRAL,
TRUSTED,
FAVORED
}

var reputation: Dictionary = {
FactionId.IGSF: 0.0,
FactionId.IMPERIAL_KNIGHTS: -50.0,
FactionId.VLR: 0.0,
FactionId.REPZILLIONS: -25.0
}

func modify_reputation(faction: int, delta: float) -> void:
if not reputation.has(faction):
return
reputation[faction] = clamp(reputation[faction] + delta, -100.0, 100.0)

func get_reputation_band(faction: int) -> ReputationBand:
var value := reputation.get(faction, 0.0)
if value <= -50.0:
return ReputationBand.HOSTILE
if value < -10.0:
return ReputationBand.SUSPICIOUS
if value <= 25.0:
return ReputationBand.NEUTRAL
if value <= 70.0:
return ReputationBand.TRUSTED
return ReputationBand.FAVORED

func should_settlement_evict_npcs(faction: int) -> bool:
var band := get_reputation_band(faction)
return band == ReputationBand.HOSTILE or band == ReputationBand.SUSPICIOUS

func can_access_igsf_supply_corridor() -> bool:
var band := get_reputation_band(FactionId.IGSF)
return band == ReputationBand.TRUSTED or band == ReputationBand.FAVORED

func is_imperial_knight_kos() -> bool:
var band := get_reputation_band(FactionId.IMPERIAL_KNIGHTS)
\# Even at better bands, they behave aggressively; band only changes how they use you.
return band == ReputationBand.HOSTILE or band == ReputationBand.SUSPICIOUS

File: res://scripts/core/race_definition.gd
text
extends Resource
class_name RaceDefinition

enum RaceId {
HUMAN,
AUG,
CYBORG,
REPZILLION
}

@export var race_id: RaceId = RaceId.HUMAN
@export var display_name: String = "Human"

@export var base_vitality_mod: float = 0.0
@export var base_instinct_mod: float = 0.0
@export var base_tenacity_mod: float = 0.0
@export var base_agility_mod: float = 0.0
@export var base_logic_mod: float = 0.0
@export var base_influence_mod: float = 0.0
@export var base_temper_mod: float = 0.0
@export var base_yield_mod: float = 0.0

@export var immune_to_cell: bool = false
@export var cell_resistance_factor: float = 1.0 \# <1.0 = slower infection, >1.0 = faster

static func make_human() -> RaceDefinition:
var r := RaceDefinition.new()
r.race_id = RaceId.HUMAN
r.display_name = "Human"
r.cell_resistance_factor = 1.0
return r

static func make_aug() -> RaceDefinition:
var r := RaceDefinition.new()
r.race_id = RaceId.AUG
r.display_name = "Aug"
r.base_logic_mod = 1.0
r.base_yield_mod = 0.5
r.base_instinct_mod = 0.5
r.cell_resistance_factor = 0.7
return r

static func make_cyborg() -> RaceDefinition:
var r := RaceDefinition.new()
r.race_id = RaceId.CYBORG
r.display_name = "Cyborg"
r.base_vitality_mod = 0.5
r.base_tenacity_mod = 1.0
r.immune_to_cell = true
r.cell_resistance_factor = 0.0
return r

static func make_repzillion() -> RaceDefinition:
var r := RaceDefinition.new()
r.race_id = RaceId.REPZILLION
r.display_name = "Repzillion"
r.base_instinct_mod = 1.0
r.base_strength_mod = 1.0 \# add this field if needed
r.cell_resistance_factor = 0.5
return r

Hook this race data into your PlayerVitalitySystem at character creation and into enemy templates for infection/mutation behavior. Settlements and squads can then evaluate:
Player race (Aug, Human, Cyborg, Repzillion).
Faction reputation band.
V.I.T.A.L.I.T.Y. attributes (especially Temper, Influence, Yield).
to decide whether to welcome, exploit, or evacuate in response to the player, keeping everything firmly inside Cell’s harsh, horror‑driven sandbox.

Factions, races, and reputation can feed directly into Cell’s V.I.T.A.L.I.T.Y. and infection/survival logic by acting as modifiers rather than pure lore.

## Faction hooks into survival

- **IGSF (Intergalactic Space Federation)**
    - High reputation: lower Oxygen and Protein costs inside IGSF‑secured zones (better shelter, heaters, and food), priority med‑treatment that boosts Vitality, Tenacity, and Yield temporarily.
    - Low reputation: more inspections and forced decontamination (Wellness penalties, Oxygen confiscation, temporary loss of gear).
- **Imperial‑Knights**
    - Always dangerous, but reputation shifts how they treat the player:
        - Hostile: immediate KOS, attempts to bleed Blood, Oxygen, and ammo stocks.
        - “Respected threat”: they may stage manipulative “alliances” that give short‑term supplies at the cost of extreme future raids.
    - Their attacks target Body‑Temperature (forcing exposure), ration‑chips, and Oxygen depots to break shelters.
- **Viva‑le‑Resistance (VLR)**
    - High reputation: stealth transit through contested hulls, access to hacked medical rigs and BCI filters that improve Logic, Instinct, and Yield at the risk of Temper and Wellness.
    - Low reputation: they leak your movements, raising AI alert levels, spawning Hollow‑Men and Repzillion hunters.

Reputation shifts directly influence resource multipliers (Oxygen efficiency in IGSF hubs, Protein gain in VLR caches, Blood loss during Knight ambushes) rather than just dialogue.

## Race hooks into V.I.T.A.L.I.T.Y. and Cell

- **Humans**
    - Neutral baseline on all attributes; Cell infection uses standard `cell_resistance_factor = 1.0`.
    - Vulnerable to Body‑Temperature extremes and Oxygen loss; balanced interaction with all factions.
- **Augs**
    - Attribute modifiers: +Logic, +Yield, +Instinct; slightly lower Temper or Vitality to reflect neuro‑strain.
    - `cell_resistance_factor ≈ 0.7` – slower infection, but once thresholds break, corruption spikes into severe mutations and violent outbursts.
    - More stable BCI and hacking, but dangerous synergy with Cell: high V.I.T.A.L.I.T.Y. can hide creeping instability.
- **Cyborgs**
    - `immune_to_cell = true`; genetic infection is not the threat.
    - Attribute modifiers: +Constitution, +Strength, +Tenacity; slightly reduced Yield or Temper (rigid, hardware‑bound).
    - Vulnerabilities come from EMP, implant overheat, and hacking; some zones or enemies explicitly target implants (draining Stamina, Speed, or even direct control).
- **Repzillions**
    - Attribute modifiers: +Instinct, +Strength, possibly higher base Body‑Temperature tolerance.
    - `cell_resistance_factor ≈ 0.5`; slower but deeper corruption. Infected Repzillions can act as region mini‑bosses with hybrid mechanics.

Race is applied at creation to the V.I.T.A.L.I.T.Y. system and to Cell infection/contamination curves, changing how quickly Blood, Wellness, and Body‑Temperature degrade in hotspot zones.

## Production GDScript: faction + race + V.I.T.A.L.I.T.Y. integration

**File:** `res://scripts/core/faction_system.gd`

```gdscript
extends Resource
class_name FactionSystem

enum FactionId {
    IGSF,
    IMPERIAL_KNIGHTS,
    VLR,
    REPZILLIONS
}

enum ReputationBand {
    HOSTILE,
    SUSPICIOUS,
    NEUTRAL,
    TRUSTED,
    FAVORED
}

var reputation: Dictionary = {
    FactionId.IGSF: 0.0,
    FactionId.IMPERIAL_KNIGHTS: -50.0,
    FactionId.VLR: 0.0,
    FactionId.REPZILLIONS: -25.0
}

func modify_reputation(faction: int, delta: float) -> void:
    if not reputation.has(faction):
        return
    reputation[faction] = clamp(reputation[faction] + delta, -100.0, 100.0)

func get_reputation_band(faction: int) -> ReputationBand:
    var value := reputation.get(faction, 0.0)
    if value <= -50.0:
        return ReputationBand.HOSTILE
    if value < -10.0:
        return ReputationBand.SUSPICIOUS
    if value <= 25.0:
        return ReputationBand.NEUTRAL
    if value <= 70.0:
        return ReputationBand.TRUSTED
    return ReputationBand.FAVORED

func get_oxygen_multiplier_for_zone(faction: int) -> float:
    var band := get_reputation_band(faction)
    match faction:
        FactionId.IGSF:
            match band:
                ReputationBand.HOSTILE, ReputationBand.SUSPICIOUS:
                    return 1.1 # worse conditions, fewer supplies
                ReputationBand.NEUTRAL:
                    return 1.0
                ReputationBand.TRUSTED, ReputationBand.FAVORED:
                    return 0.8 # more efficient shelter, better seals
        FactionId.VLR:
            if band == ReputationBand.TRUSTED or band == ReputationBand.FAVORED:
                return 0.9
    return 1.0

func get_medical_efficiency_bonus(faction: int) -> float:
    var band := get_reputation_band(faction)
    if faction == FactionId.IGSF:
        match band:
            ReputationBand.TRUSTED:
                return 1.2
            ReputationBand.FAVORED:
                return 1.4
    if faction == FactionId.VLR and band >= ReputationBand.NEUTRAL:
        return 1.1
    return 1.0

func should_trigger_knight_ambush() -> bool:
    var band := get_reputation_band(FactionId.IMPERIAL_KNIGHTS)
    if band == ReputationBand.HOSTILE:
        return true
    if band == ReputationBand.SUSPICIOUS:
        return randf() < 0.4
    return randf() < 0.2
```

**File:** `res://scripts/core/race_definition.gd`

```gdscript
extends Resource
class_name RaceDefinition

enum RaceId {
    HUMAN,
    AUG,
    CYBORG,
    REPZILLION
}

@export var race_id: RaceId = RaceId.HUMAN
@export var display_name: String = "Human"

@export var base_vitality_mod: float = 0.0
@export var base_instinct_mod: float = 0.0
@export var base_tenacity_mod: float = 0.0
@export var base_agility_mod: float = 0.0
@export var base_logic_mod: float = 0.0
@export var base_influence_mod: float = 0.0
@export var base_temper_mod: float = 0.0
@export var base_yield_mod: float = 0.0

@export var base_constitution_mod: float = 0.0
@export var base_dexterity_mod: float = 0.0
@export var base_intelligence_mod: float = 0.0
@export var base_luck_mod: float = 0.0
@export var base_speed_mod: float = 0.0
@export var base_strength_mod: float = 0.0

@export var immune_to_cell: bool = false
@export var cell_resistance_factor: float = 1.0

static func make_human() -> RaceDefinition:
    var r := RaceDefinition.new()
    r.race_id = RaceId.HUMAN
    r.display_name = "Human"
    r.cell_resistance_factor = 1.0
    return r

static func make_aug() -> RaceDefinition:
    var r := RaceDefinition.new()
    r.race_id = RaceId.AUG
    r.display_name = "Aug"
    r.base_logic_mod = 1.0
    r.base_yield_mod = 0.5
    r.base_instinct_mod = 0.5
    r.base_temper_mod = -0.3
    r.cell_resistance_factor = 0.7
    return r

static func make_cyborg() -> RaceDefinition:
    var r := RaceDefinition.new()
    r.race_id = RaceId.CYBORG
    r.display_name = "Cyborg"
    r.base_vitality_mod = 0.5
    r.base_tenacity_mod = 1.0
    r.base_constitution_mod = 1.0
    r.base_strength_mod = 1.0
    r.immune_to_cell = true
    r.cell_resistance_factor = 0.0
    return r

static func make_repzillion() -> RaceDefinition:
    var r := RaceDefinition.new()
    r.race_id = RaceId.REPZILLION
    r.display_name = "Repzillion"
    r.base_instinct_mod = 1.0
    r.base_strength_mod = 1.0
    r.base_speed_mod = 0.5
    r.cell_resistance_factor = 0.5
    return r

func apply_to_vitality_system(vsys: PlayerVitalitySystem) -> void:
    vsys.vitality += base_vitality_mod
    vsys.instinct += base_instinct_mod
    vsys.tenacity += base_tenacity_mod
    vsys.agility += base_agility_mod
    vsys.logic += base_logic_mod
    vsys.influence += base_influence_mod
    vsys.temper += base_temper_mod
    vsys.yield += base_yield_mod

    vsys.constitution += base_constitution_mod
    vsys.dexterity += base_dexterity_mod
    vsys.intelligence += base_intelligence_mod
    vsys.luck += base_luck_mod
    vsys.speed += base_speed_mod
    vsys.strength += base_strength_mod
```

**File:** `res://scripts/core/cell_infection_model.gd`

```gdscript
extends Resource
class_name CellInfectionModel

@export var base_infection_rate: float = 1.0

func tick_infection(delta: float, vsys: PlayerVitalitySystem, race: RaceDefinition, contamination_level: float) -> float:
    if race.immune_to_cell:
        return 0.0

    var resistance := (vsys.vitality + vsys.temper + vsys.tenacity) / 30.0
    resistance = clamp(resistance, 0.2, 1.5)

    var rate := base_infection_rate * contamination_level
    rate *= race.cell_resistance_factor
    rate *= 1.3 - resistance

    var wellness_factor := clamp(vsys.wellness / max(1.0, vsys.wellness_max), 0.2, 1.2)
    rate *= 1.4 - wellness_factor

    return max(rate * delta, 0.0)
```


## Simulated debug snapshot

```text
[DEBUG][T=1734320401.63]
SOURCE: PlayerInit
EVENT: RACE_APPLIED
DATA: {
  "race": "Aug",
  "vitality": 5.0 -> 5.0,
  "instinct": 5.0 -> 5.5,
  "logic": 5.0 -> 6.0,
  "yield": 5.0 -> 5.5,
  "cell_resistance_factor": 0.7
}

[DEBUG][T=1734320467.11]
SOURCE: FactionSystem
EVENT: REPUTATION_CHANGED
DATA: {
  "faction": "IGSF",
  "delta": 18.0,
  "new_value": 32.0,
  "band": "TRUSTED",
  "oxygen_multiplier_zone": 0.8,
  "medical_efficiency_bonus": 1.2
}

[DEBUG][T=1734320488.39]
SOURCE: CellInfectionModel
EVENT: TICK
DATA: {
  "race": "Aug",
  "contamination_level": 0.9,
  "base_infection_rate": 1.0,
  "resistance": 0.94,
  "wellness_factor": 0.78,
  "infection_delta": 0.37
}
```

This keeps factions, races, and reputation deeply wired into V.I.T.A.L.I.T.Y., infection, and resource behavior, instead of leaving them as flavor text.

---

# These pools fit Cell’s tone; they just need to be wired tightly into V.I.T.A.L.I.T.Y. and settlements with clear failure states.

Player resource pools
Blood
Governs: hard HP ceiling, Strength effectiveness, collapse and death thresholds.
Behavior:
High Blood: full Strength output, stable aim, normal movement.
Mid Blood: reduced melee impact and recoil control; Stamina regen slows.
Low Blood: tunnel vision, camera sway, heavy input lag; on critical, the player collapses and bleeds out unless stabilized.
Collapse logic:
If Blood ≤ 0 → immediate death.
If Blood low and untreated → repeated collapses; each collapse also chips Wellness and Tenacity.
Protein
Governs: long‑term travel capacity, healing, implant growth, and disease resistance.
Behavior:
Every chunk of distance traveled, time spent awake, and active healing consumes Protein.
At low Protein: maximum Stamina shrinks, healing from med‑kits is reduced, infection chance increases.
Repeated “low‑Protein collapses” trigger the Starving status:
Stacking penalties to Vitality, Tenacity, and Wellness.
Higher risk of disease/organ failure and permanent attribute loss if ignored.
Death path: if Starving persists and Protein remains near zero, Protein‑based healing becomes impossible and eventual death is guaranteed.
Oxygen
Governs: survivability in all non‑sealed areas, effective Agility and Stamina ceiling.
Behavior:
Acts as a hard timer in exposed zones; movement, sprinting, and panic spikes accelerate drain.
At low Oxygen: vision constriction, audio muffling, and movement desync.
Zero tolerance:
If Oxygen hits 0 → player dies immediately; no “downed” state, no grace period.
If in a settlement context with shared Oxygen: hitting 0 for the pool can cascade into settlement collapse events.
Stamina
Governs: short‑term exertion (sprint distance, melee chains, dodges, climbing, dragging bodies).
Behavior:
High Stamina: full action rate; can chain dodges and heavy attacks.
Low Stamina: sluggish attacks, longer recovery, reduced dodge frames.
At 0: forced collapse or stagger; the player loses their next action window in combat.
Collapse chain: repeated Stamina collapses feed back into Wellness and Protein (muscle damage, exhaustion) and can indirectly trigger Starving or illness.
Settlement resource pools
Settlement Oxygen
Shared life support for civilians and player allies.
Logic:
If settlement Oxygen reaches critical low, all exterior missions receive harsher Oxygen drain multipliers.
At 0: remaining NPCs in the zone die unless they reach sealed modules; the settlement is marked as fallen.
Consequences:
Factions may abandon, quarantine, or strip the site.
Reputation hit with IGSF (failure to maintain standards); opportunity for Imperial‑Knights to occupy the void.
Rations
Aggregated Food, Meds, Water.
Logic:
Rations determine settlement Protein and Wellness for NPCs and the player while in shelter.
High Rations: higher Man‑Power retention, faster NPC recovery, more stable trade.
Low Rations: disease, reduced NPC output, desertions, and eventual riots or cannibalization.
Research
Represents accumulated technical knowledge, intel, and experimental data.
Logic:
High Research: unlocks better defenses, advanced med‑kits, Cell countermeasures, and safer access to restricted zones.
Low Research: blind spots, higher chance of failed expeditions, and misjudged threat levels.
Practical hooks:
Thresholds gate new gear trees, BCI filters, and anti‑Cell tech.
Faction events (IGSF / VLR) may target Research caches for sabotage or theft.
Man‑Power
Active workers and fighters available.
Logic:
High Man‑Power: stable production of Rations and Research, functioning defenses, and repair capability.
Low Man‑Power: key jobs go unfilled; turrets shut down, patrols shrink, repairs stall.
Zero Man‑Power: settlement cannot maintain oxygen recyclers, farms, or walls:
Leads to forced evacuation, collapse into an abandoned ruin, or takeover by Imperial‑Knights.
Production GDScript: player + settlement pools
File: res://scripts/core/player_pools.gd
text
extends Resource
class_name PlayerPools

@export var blood: float = 100.0
@export var blood_max: float = 100.0

@export var protein: float = 50.0
@export var protein_max: float = 50.0

@export var oxygen: float = 100.0
@export var oxygen_max: float = 100.0

@export var stamina: float = 100.0
@export var stamina_max: float = 100.0

var starving_stacks: int = 0

func tick_blood(delta: float, bleed_rate: float) -> bool:
blood = max(0.0, blood - bleed_rate * delta)
return blood <= 0.0

func tick_protein(delta: float, travel_load: float, awake_load: float) -> void:
var rate := travel_load + awake_load
protein = max(0.0, protein - rate * delta)
if protein <= 0.0:
if starving_stacks < 10:
starving_stacks += 1

func tick_oxygen(delta: float, drain_rate: float) -> bool:
oxygen = max(0.0, oxygen - drain_rate * delta)
return oxygen <= 0.0

func tick_stamina(delta: float, exertion: float, recovery_rate: float) -> void:
stamina = clamp(stamina - exertion * delta + recovery_rate * delta, 0.0, stamina_max)

func apply_meal(protein_gain: float) -> void:
protein = min(protein_max, protein + protein_gain)
if protein > protein_max * 0.3 and starving_stacks > 0:
starving_stacks -= 1

func apply_oxygen_capsule(amount: float) -> void:
oxygen = min(oxygen_max, oxygen + amount)

func apply_rest(duration_hours: float) -> void:
stamina = min(stamina_max, stamina + duration_hours * 10.0)
protein = max(0.0, protein - duration_hours * 0.1)

File: res://scripts/core/settlement_pools.gd
text
extends Resource
class_name SettlementPools

@export var oxygen: float = 1000.0
@export var oxygen_max: float = 1000.0

@export var rations: float = 500.0
@export var rations_max: float = 500.0

@export var research: float = 0.0
@export var research_max: float = 1000.0

@export var manpower: int = 50
@export var manpower_max: int = 100

func tick_daily_consumption() -> void:
if manpower <= 0:
return
var oxy_use := manpower * 1.5
var ration_use := manpower * 0.8

    oxygen = max(0.0, oxygen - oxy_use)
    rations = max(0.0, rations - ration_use)
    
    if rations <= 0.0:
        # NPCs starve; Man-Power drops
        manpower = max(0, manpower - 2)
    func add_oxygen(amount: float) -> void:
oxygen = min(oxygen_max, oxygen + amount)

func add_rations(amount: float) -> void:
rations = min(rations_max, rations + amount)

func add_research(amount: float) -> void:
research = clamp(research + amount, 0.0, research_max)

func add_manpower(amount: int) -> void:
manpower = clamp(manpower + amount, 0, manpower_max)

func is_collapsing() -> bool:
if oxygen <= 0.0:
return true
if manpower <= 0 and rations <= 0.0:
return true
return false

Simulated debug snapshot
text
[DEBUG][T=1734324001.27]
SOURCE: PlayerPools
EVENT: TICK
DATA: {
"blood": 62.3,
"protein": 8.1,
"oxygen": 34.5,
"stamina": 19.7,
"starving_stacks": 3
}

[DEBUG][T=1734327600.00]
SOURCE: SettlementPools
EVENT: DAILY_CONSUMPTION
DATA: {
"oxygen": 184.0,
"rations": 12.0,
"manpower": 14,
"collapse_imminent": false
}

[DEBUG][T=1734328200.00]
SOURCE: SettlementPools
EVENT: DAILY_CONSUMPTION
DATA: {
"oxygen": 0.0,
"rations": 0.0,
"manpower": 8,
"collapse_imminent": true
}

This makes Blood, Protein, Oxygen, Stamina, and the settlement pools real mechanical levers in Cell: harsh, traceable, and unforgiving, just like the rest of the game.

Blood, Protein, Oxygen, Stamina, and the settlement pools fit Cell’s tone; the remaining step is to bind them directly to V.I.T.A.L.I.T.Y. and define clear, mechanical failure states.

## Player pools wired into V.I.T.A.L.I.T.Y.

Replace the stand‑alone `PlayerPools` with a version that reads modifiers from `PlayerVitalitySystem` so attributes truly govern drain, collapse, and recovery.

**File:** `res://scripts/core/player_pools.gd`

```gdscript
extends Resource
class_name PlayerPools

@export var vitality_system: PlayerVitalitySystem

@export var blood: float = 100.0
@export var blood_max: float = 100.0

@export var protein: float = 50.0
@export var protein_max: float = 50.0

@export var oxygen: float = 100.0
@export var oxygen_max: float = 100.0

@export var stamina: float = 100.0
@export var stamina_max: float = 100.0

var starving_stacks: int = 0
var blood_collapse_count: int = 0
var stamina_collapse_count: int = 0

func recalc_from_vitality() -> void:
    if vitality_system == null:
        return
    vitality_system.recalc_maxima()
    blood_max = vitality_system.blood_max
    protein_max = vitality_system.protein_max
    oxygen_max = vitality_system.oxygen_max
    stamina_max = vitality_system.stamina_max

    blood = clamp(blood, 0.0, blood_max)
    protein = clamp(protein, 0.0, protein_max)
    oxygen = clamp(oxygen, 0.0, oxygen_max)
    stamina = clamp(stamina, 0.0, stamina_max)

func tick_blood(delta: float, bleed_rate: float) -> bool:
    blood = max(0.0, blood - bleed_rate * delta)
    if blood <= 0.0:
        return true
    if blood < blood_max * 0.25:
        if blood_collapse_count == 0 or randi() % 100 < 5:
            blood_collapse_count += 1
            vitality_system.wellness = max(0.0, vitality_system.wellness - 5.0)
            vitality_system.tenacity = max(0.0, vitality_system.tenacity - 0.1)
            return false
    return false

func tick_protein(delta: float, travel_load: float, awake_load: float) -> void:
    var base_rate := travel_load + awake_load
    var eff := clamp((vitality_system.yield + vitality_system.vitality) / 20.0, 0.5, 1.5)
    var rate := base_rate * eff
    protein = max(0.0, protein - rate * delta)
    if protein <= 0.0:
        if starving_stacks < 20:
            starving_stacks += 1
        if starving_stacks % 3 == 0:
            vitality_system.vitality = max(0.0, vitality_system.vitality - 0.1)
            vitality_system.tenacity = max(0.0, vitality_system.tenacity - 0.1)
            vitality_system.wellness = max(0.0, vitality_system.wellness - 3.0)

func tick_oxygen(delta: float, base_drain: float) -> bool:
    var rate := vitality_system.get_oxygen_decay_rate(base_drain)
    oxygen = max(0.0, oxygen - rate * delta)
    return oxygen <= 0.0

func tick_stamina(delta: float, exertion: float, base_recovery: float) -> bool:
    var decay := vitality_system.get_stamina_decay_rate(exertion)
    var recovery := base_recovery * clamp((vitality_system.tenacity + vitality_system.agility) / 20.0, 0.5, 1.8)
    stamina = clamp(stamina - decay * delta + recovery * delta, 0.0, stamina_max)

    if stamina <= 0.0:
        stamina_collapse_count += 1
        vitality_system.wellness = max(0.0, vitality_system.wellness - 2.0)
        protein = max(0.0, protein - 0.5)
        return true
    return false

func apply_meal(protein_gain: float) -> void:
    protein = min(protein_max, protein + protein_gain)
    if protein > protein_max * 0.3 and starving_stacks > 0:
        starving_stacks -= 1

func apply_oxygen_capsule(amount: float) -> void:
    vitality_system.use_oxygen_capsule(amount)
    oxygen = min(oxygen_max, oxygen + amount * vitality_system.get_oxygen_efficiency())

func apply_rest(hours: float) -> void:
    var stamina_recover := hours * 12.0
    stamina = min(stamina_max, stamina + stamina_recover)
    var protein_cost := hours * 0.15
    protein = max(0.0, protein - protein_cost)
```


### Failure states (player)

- **Blood ≤ 0:** immediate death; no downed state.
- **Repeated Blood collapses:** each drains Wellness and Tenacity; at high counts, any further trauma can trigger instant fatal arrhythmia.
- **Starving stacks > threshold:** irreversible attribute loss; if Protein stays at 0 long‑term, any lethal hit becomes non‑revivable (no healing can apply).
- **Oxygen ≤ 0:** immediate death in all non‑sealed contexts, including settlements with shared Oxygen failure.
- **Stamina collapse:** forced stagger; repeated events increase risk of cardiac failure under extreme cold or infection.


## Settlement pools and collapse

Wire settlement pools into faction and mission logic to determine when zones live, starve, or fall.

**File:** `res://scripts/core/settlement_pools.gd`

```gdscript
extends Resource
class_name SettlementPools

@export var oxygen: float = 1000.0
@export var oxygen_max: float = 1000.0

@export var rations: float = 500.0
@export var rations_max: float = 500.0

@export var research: float = 0.0
@export var research_max: float = 1000.0

@export var manpower: int = 50
@export var manpower_max: int = 100

var days_without_oxygen: int = 0
var days_starving: int = 0

func tick_daily_consumption() -> void:
    if manpower <= 0:
        return

    var oxy_use := manpower * 1.5
    var ration_use := manpower * 0.8

    oxygen = max(0.0, oxygen - oxy_use)
    rations = max(0.0, rations - ration_use)

    if oxygen <= 0.0:
        days_without_oxygen += 1
        manpower = max(0, manpower - 4)
    else:
        days_without_oxygen = 0

    if rations <= 0.0:
        days_starving += 1
        manpower = max(0, manpower - 2)
    else:
        days_starving = 0

func add_oxygen(amount: float) -> void:
    oxygen = min(oxygen_max, oxygen + amount)

func add_rations(amount: float) -> void:
    rations = min(rations_max, rations + amount)

func add_research(amount: float) -> void:
    research = clamp(research + amount, 0.0, research_max)

func add_manpower(amount: int) -> void:
    manpower = clamp(manpower + amount, 0, manpower_max)

func get_collapse_state() -> String:
    if oxygen <= 0.0 and manpower <= 0:
        return "DEAD"
    if manpower <= 0:
        return "ABANDONED"
    if rations <= 0.0 and days_starving > 7:
        return "RIOT"
    if oxygen <= 0.0 and days_without_oxygen > 1:
        return "ASPHYXIATION"
    return "STABLE"
```


### Settlement consequences

- **Oxygen = 0, Man‑Power > 0:** daily asphyxiation; rapid drop in Man‑Power, strong IGSF reputation penalty, high chance of Imperial‑Knight takeover event.
- **Rations = 0, prolonged:** disease, desertion, riots; may flip the zone into “Cannibal Colony” or abandon it altogether.
- **Man‑Power = 0:** all defenses, recyclers, and farms fail; the settlement becomes a ruin or an occupied Knight fortress.


## Simulated debug snapshot

```text
[DEBUG][T=1734330001.44]
SOURCE: PlayerPools
EVENT: TICK
DATA: {
  "blood": 23.8,
  "protein": 3.2,
  "oxygen": 19.5,
  "stamina": 7.1,
  "starving_stacks": 5,
  "blood_collapse_count": 2,
  "stamina_collapse_count": 3
}

[DEBUG][T=1734333600.00]
SOURCE: SettlementPools
EVENT: DAILY_CONSUMPTION
DATA: {
  "oxygen": 0.0,
  "rations": 4.0,
  "manpower": 10,
  "days_without_oxygen": 1,
  "days_starving": 0,
  "collapse_state": "ASPHYXIATION"
}
```

This locks the pools to V.I.T.A.L.I.T.Y. and settlements with explicit, unforgiving failure states that fit Cell’s horror and survival focus.

---

# 'Craft' a well-written ReadMe.md for display on github with some syntactically-correct svg official-badges that correctly display in a markdown-formatting, highlighting all elements, and capturing the features of Cell *so-far*.

CELL is a brutal, adult, sci‑fi survival‑horror project in Godot 4 with a lot of systems already defined. Here is a GitHub‑ready `README.md` that highlights the current features and includes valid SVG badges.

***

```markdown
<p align="center">
  <img src="https://img.shields.io/badge/engine-Godot%204-478CBF?logo=godot-engine&logoColor=white" alt="Engine: Godot 4">
  <img src="https://img.shields.io/badge/status-In%20Development-orange" alt="Status: In Development">
  <img src="https://img.shields.io/badge/genre-Sci--Fi%20Survival%20Horror-critical" alt="Genre: Sci-Fi Survival Horror">
  <img src="https://img.shields.io/badge/license-TBD-lightgrey" alt="License: TBD">
</p>

<h1 align="center">CELL</h1>
<p align="center"><strong>Biological Deep-Space Sci‑Fi Survival Horror</strong></p>

---

## Overview

CELL is an adult, hard survival‑horror game built with Godot 4 for PC.  
The player is stranded on a corrupted moon, trapped between failed colonies, collapsing factions, and the evolving nanovirus known only as **Cell**.

CELL focuses on:

- Harsh resource‑driven survival (oxygen, body‑temperature, blood, protein, stamina)
- Slow, methodical exploration of derelict labs, cratered hulls, and failed settlements
- Biomechanical horror: corrupted AI, nanotech monstrosities, and augmented “Hollow‑Men”
- System‑heavy character progression via the **V.I.T.A.L.I.T.Y.** attribute core

---

## Core Features (So Far)

### Godot 4 project backbone

- Structured for large, modular horror projects:
  - `scenes/` – player, enemies, world blocks, UI
  - `scripts/core/` – global systems (`GameState`, `DebugLog`, content registries, V.I.T.A.L.I.T.Y., factions)
  - `scripts/player/` – controllers, status, attribute wiring
  - `scripts/enemy/` – AI state machines, perception, navigation
  - `scripts/world/` – ambience controllers, procedural generators, tileset registries
  - `ASSETS/CC0` and `ASSETS/CC_BY` – strictly separated third‑party horror assets

### Player controller and survival loop

- First‑person or over‑shoulder controller with:
  - Movement, sprinting with stamina, jumping, and a toggleable flashlight
  - Input‑driven, Godot‑native controls (actions in the Input Map)
- Global `GameState` for:
  - Health, sanity, alert level
  - Death tracking and runtime metrics
  - Group‑wide death callbacks for scene‑wide responses

---

## V.I.T.A.L.I.T.Y. System

The **V.I.T.A.L.I.T.Y.** system is the stat backbone of CELL:

- **V – Vitality**: biological resilience, bleed‑out, infection resistance  
- **I – Instinct**: threat awareness, ambush detection, breathing control  
- **T – Tenacity**: endurance under cold, low oxygen, and combat stress  
- **A – Agility**: short‑burst movement, dodging, climbing, recovery  
- **L – Logic**: technical cognition, hacking, BCI stability  
- **I – Influence**: social pressure, command, negotiation  
- **T – Temper**: emotional control, panic thresholds, hallucination risk  
- **Y – Yield**: resource efficiency (healing, food, oxygen pills, drugs)

These attributes drive **resource pools**:

- **Blood** – hard HP; low levels cause collapses and aim/movement penalties  
- **Protein** – long‑term repair capacity; governs healing and implant growth  
- **Oxygen** – survival in exposed areas; hard zero = instant death  
- **Stamina** – short‑term exertion for sprinting, melee, dodges, climbing  
- **Wellness** – sanity and physiological stability  
- **Body‑Temperature** – thermal status; critical lows/highs kill over time

All pools are wired into:

- Exposure checks (cold, vacuum, contamination)
- Pills and ration‑chips (permanent or semi‑permanent attribute shifts)
- Skill effectiveness (hacking, stealth, scavenging, command)

---

## Factions, Races, and Reputation

### Factions

- **IGSF – Intergalactic Space Federation**
  - Last formal authority; runs containment and rationing
  - High reputation: access to sealed shelters, med‑bays, oxygen convoys
  - Low reputation: quarantine orders, inspections, reduced supply priority

- **Imperial‑Knights**
  - Post‑collapse slaver regime, ex‑military and security
  - Prefer ambushes when the player is low on oxygen or isolated
  - Never truly friendly; reputation changes how they exploit you, not if

- **Viva‑le‑Resistance (VLR)**
  - Underground resistance network
  - High reputation: black‑market implants, experimental BCI filters, hidden routes
  - Neutral/low reputation: data theft, siphoning your hard‑earned research

A centralized **faction system** tracks per‑faction reputation in continuous values with bands:

- `HOSTILE`, `SUSPICIOUS`, `NEUTRAL`, `TRUSTED`, `FAVORED`

These bands:

- Modify oxygen and medical efficiency in controlled zones
- Affect patrol behavior, ambush chance, and settlement support
- Gate access to shelters, labs, and black‑market vendors

### Races

Each race is a **RaceDefinition** that adjusts V.I.T.A.L.I.T.Y. and infection behavior:

- **Human** – baseline; fully susceptible to Cell  
- **Aug** – enhanced logic and yield; slower infection but catastrophic failures when corruption breaches their systems  
- **Cyborg** – immune to genetic infection; vulnerable to EMP, implant overheat, and hacking  
- **Repzillion** – predatory exo‑species; slower Cell distortion but extremely dangerous when infected

---

## Enemies and AI

Current monster archetypes:

- **Spine‑Crawlers** – humanoids with vertebrae turned into jagged exoskeletal limbs; fast, flanking melee  
- **Breathers** – torsos fused to respirators; exhale suffocating gas clouds, turning corridors into death funnels  
- **Hollow‑Men** – organs replaced by cables and nanite sludge; patrol threats and AI‑augmented “demons”  
- **Ash‑Eaters** – skeletal scavengers; consume burnt remains to gain armor and speed  
- **Pulse‑Terrors** – slow, bloated hazards; exposed hearts pump glowing nanotech fluid that scrambles HUD and sanity

AI is implemented with:

- Godot 4 `NavigationAgent3D` agents
- Simple, robust state machines (PATROL / CHASE / SEARCH)
- Vision cones with raycast line‑of‑sight checks
- Hooks into `GameState.alert_level` and `DebugLog` for telemetry

---

## World, Regions, and Procedural Generation

Key regions on and around the Forgotten Moon:

- **Ashveil Debris Stratum** – tutorialized crash‑site, low gravity, intermittent power  
- **Iron Hollow Spinal Trench** – deep biomechanical canyon, heavy patrols, ration‑chip caches  
- **Cold Verge Cryo‑Rim** – exterior hull and meteor fields; extreme cold, exosuit degradation, oxygen runs  
- **Red Silence Signal Cradle** – communications and AI core; heavy BCI interaction and sanity damage

Procedural systems:

- **Lab Corridor Generator**:
  - Uses `TileMapLayer` and `TileSet` in Godot 4
  - Groups tiles into functional categories:
    - Flesh floors, blood‑slick corridors
    - Cracked nanotech walls
    - Corrupted terminals, shattered containment tubes
    - Pulsating growth overlays
  - Assembles “Zombified Lab” corridors with randomized tiles, props, and growths

- **Facility Ambience Controller**:
  - Reads from `GameState.alert_level` and player sanity
  - Drives:
    - Light flicker intensity and instability
    - Ambient hum volume and filtering
    - Heartbeat layers and distortion

---

## Assets and Licensing

CELL is built around a **clean, auditable asset pipeline**:

- `ASSETS/external/itchio/<pack_name>/raw/` – untouched downloads  
- `ASSETS/external/itchio/<pack_name>/LICENSE.txt` – original license text  
- `ASSETS/CC0/...` – strictly verified CC0 assets (safe to mangle and redistribute)  
- `ASSETS/CC_BY/<creator>/<pack_name>/...` – attribution‑required art/audio  
- `META/CREDITS.md` – centralized credits and URLs for all CC‑BY and optional CC0 acknowledgements

Horror elements (dismemberment, gore, extreme ambience) are produced **in Godot code** using:

- CC0/CC‑BY models and textures as neutral baselines
- Audio buses with EQ, distortion, and reverb to “brutalize” CC0 loops at runtime
- A dedicated `DismembermentManager` handling limb removal, blood FX, and gore materials

---

## Debugging and Telemetry

CELL is designed for automated and human debugging:

- `DebugLog` autoload:
  - Structured entries: `{ time, source, event, data }`
  - Ring buffer for recent events
  - Used by AI, ambience, V.I.T.A.L.I.T.Y., and faction systems
- Example entries:
  - State transitions (PATROL → CHASE)
  - Damage events and collapses
  - Settlement daily consumption and collapse states
  - Infection ticks and race‑specific modifiers

This makes it possible to analyze and tune harsh survival behavior, encounter pacing, and faction dynamics without guesswork.

---

## Tech Stack

- **Engine:** Godot 4 (GDScript only for game logic)
- **Target:** PC (Windows / Linux)
- **Languages:** GDScript (with tightly scoped C++ or other languages only if absolutely required)
- **Version control:** Git / GitHub

---

## Contributing

CELL is a system‑heavy survival‑horror project. Contributions that fit best:

- Godot 4 scripts that:
  - Respect the existing folder and naming conventions
  - Integrate with `GameState`, `DebugLog`, and the V.I.T.A.L.I.T.Y. system
- Horror‑appropriate assets under CC0 / CC‑BY with clear licenses
- AI behaviors, procedural generation logic, and UI/HUD for survival feedback

Before opening a PR:

1. Ensure any new assets are placed in the correct `ASSETS/CC0` or `ASSETS/CC_BY` path with a license.  
2. Wire new systems into `DebugLog` for traceability.  
3. Keep names grounded, industrial, and non‑fantasy to match CELL’s tone.

---

## Roadmap (High Level)

- Story‑driven missions:
  - Oxygen runs through Cold Verge
  - Ration‑chip raids in Iron Hollow
  - BCI breach ops in Red Silence
- Expanded skill tree and V.I.T.A.L.I.T.Y. interactions
- Settlement management and defense phases during long “night” cycles
- Additional enemy archetypes and Cell mutation tiers
- Full audio and visual polish for the Forgotten Moon’s biomechanical horror

---

> CELL is not about power fantasy. It is about holding onto the last threads of function and sanity while a dying ecosystem tries to recycle you.  
> Every step, every capsule, and every ration‑chip matters.
```

