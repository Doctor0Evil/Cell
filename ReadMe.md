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
