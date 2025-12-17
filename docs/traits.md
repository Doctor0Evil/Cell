For Cell, traits should talk to V.I.T.A.L.I.T.Y., oxygen, water, suit integrity, sanity, and faction systems instead of Fallout’s SPECIAL and AP. Below is a refactored, Cell‑themed trait set plus a respect model that slots into your existing systems.[1]

## Cell trait schema (replacement for SPECIAL)

Use this pattern for every trait:

- `ATTR:` V/I/T/A/L/I/T/Y deltas (and secondary stats like constitution, dexterity).
- `POOL:` Blood / Oxygen / Water / Stamina / Wellness / BodyTemperature effects.
- `STATUS:` concrete rules (environment tags, thresholds, AoE).  
- `FACTION_REP:` region/faction id ±X.  
- `RESPECT:` faction id ±X (competence/fear).

Example notation inside design docs:

- `ATTR: Vitality +1, Tenacity +2`  
- `POOL: OxygenMax +15%, StaminaMax −10%`  
- `STATUS: In COLD_VERGE hull zones, temp drop −20%, stamina decay −10%`  
- `RESPECT: "HULL_TECHS" +10, "TRANSIT_CIVILIANS" +5`

## 1–10 Core survival / body traits (Cell)

1. **Cold Verge Runner**  
   - ATTR: Tenacity +1, Agility +1.  
   - POOL: StaminaMax +10%.  
   - STATUS: In regions tagged `COLD_VERGE`, body temperature drop rate −20%, stamina decay −10%.  
   - RESPECT: `HULL_TECHS` +10 (seen as reliable in exterior runs).

2. **Ashveil Scavenger**  
   - ATTR: Instinct +1, Yield +1.  
   - POOL: WellnessMax −5% (solvent exposure, chronic micro‑damage).  
   - STATUS: In `ASHVEIL_DRIFT` salvage zones, container loot quantity +15%, encounter chance +10%.  
   - RESPECT: `SCAVENGER_RINGS` +10; `FORMAL_SECURITY` −5.

3. **Heavy Frame**  
   - ATTR: Strength +2, Agility −1.  
   - POOL: StaminaMax −5%. Carry capacity +40%.  
   - STATUS: Movement speed −5%, climbing/vent access checks −20%.  
   - RESPECT: `BULK_LOGISTICS` +5 (airlocks, cargo crews).

4. **Ambidextrous Grip**  
   - ATTR: Dexterity +2.  
   - STATUS: Off‑hand weapon penalties removed; dual‑weapon recoil penalty −10%.  
   - POOL: Stamina decay +5% while firing two weapons (extra strain).  
   - RESPECT: `SECURITY_ARMS` +5.

5. **Hull Bruiser**  
   - ATTR: Strength +3, Agility −2.  
   - STATUS: Melee damage +20%, ranged weapon stability −10%.  
   - POOL: Oxygen decay +5% under exertion (big frame burns mix faster).  
   - RESPECT: `PIT_COMBAT` +10; `TACTICAL_COMMAND` −5.

6. **Trigger Drift**  
   - ATTR: Instinct +1, Temper −1.  
   - STATUS: All ranged attacks oxygen spike +5% per burst, hit chance +5%, misfire +3% with jury‑rigged weapons.  
   - REPUTATION: `ORDERLY_FACTIONS` −5, `CHAOTIC_MILITIAS` +5.

7. **Containment-Cautious**  
   - ATTR: Instinct +1, Agility −1.  
   - STATUS: Stealth vs ambient sensors +10%; sprint start delay +0.2s (you check corners).  
   - RESPECT: `TACTICAL_COMMAND` +5; `IMPULSIVE_GANGS` −5.

8. **Pack Spine**  
   - POOL: Carry capacity +60%; Oxygen decay +5% when over 80% capacity.  
   - STATUS: Loot highlight radius +1 tile; movement speed −10% above 75% load.  
   - DISPOSITION: `DECK_TRADERS` +5; minimalism‑oriented companions −5.

9. **Red Silence Optics**  
   - ATTR: Logic +1, Perception analogue via Instinct +1 at >20m; Instinct −1 at <4m (HUD bias to distant signals).  
   - STATUS: Scoped weapon accuracy +15% in `RED_SILENCE` regions; close‑quarters detection −5%.  
   - RESPECT: `LONG_SPINE_MARKSMEN` +5.

10. **Tunnel Focus**  
    - ATTR: Instinct +1.  
    - STATUS: To‑hit +10% on targets inside 35° frontal cone in `MAINT_TUNNEL`‑tagged corridors; flank and rear hit −15%.  
    - RESPECT: Used situationally by `SECTION_COMMAND` (bunker breach assignments).

## 11–20 Social / psychological traits (Cell)

11. **Containment Face**  
    - ATTR: Influence +2.  
    - SKILL: Negotiation/command checks +15% in `CONTAINMENT_ZONES`; bartering +10% at ration consoles.  
    - REPUTATION: neutral factions +5 initial reaction.  
    - RESPECT: `ADMINISTRATIVE_CORE` +5.

12. **Hard Edge**  
    - ATTR: Temper −1.  
    - SKILL: Intimidation +10%, conciliatory dialog −10%.  
    - REPUTATION: medical/aid factions −5 on first contact.  
    - RESPECT: `BLACK_SECTION_OPERATIVES` +5.

13. **Signal Empath**  
    - ATTR: Instinct +1, Temper −1.  
    - STATUS: Social/empathy checks +20%, lie detection +15%; sanity loss +25% from witnessing suffering or signal‑borne horror.  
    - DISPOSITION: positive shifts +20%, negative shifts +20% (you react strongly).

14. **Compartmentalized**  
    - ATTR: Temper +2, Influence −1.  
    - STATUS: Stress from atrocities −50%; positive disposition gains −20%, negative −20%.  

15. **Orbital Luck**  
    - ATTR: Luck +2.  
    - STATUS: Rare event “saves” +50% chance (avoiding critical system failures, finding extra O2 capsule, etc.).  
    - RESPECT: `SUPERSTITION_CELLS` +5.

16. **Jinxed Orbit**  
    - ATTR: Luck −2.  
    - STATUS: Mishap chance +50% for everyone within 5m (slips, jams, panel shorts).  
    - RESPECT: `SUPERSTITION_CELLS` −5.

17. **Night Shift Mind**  
    - ATTR: Logic +1, Instinct +1 at station night; −1 Logic, −1 Instinct during artificial “day”.  
    - STATUS: Stealth +10% in low‑light interior blocks.  
    - REPUTATION: `NOCTURNAL_CREWS` +5.

18. **Day Cycle Anchor**  
    - ATTR: Logic +1, Tenacity +1 during scheduled “day”; −1 Logic, −1 Instinct at night.  
    - STATUS: Maintenance/repair speed +10% in daylight cycles.  

19. **Hull Claustrophobia**  
    - STATUS: In cells tagged `INTERIOR_TIGHT`: StaminaMax −10%, stealth −10%, sanity loss +25%.  
    - DISPOSITION: `BUNKER_FACTIONS` −5.

20. **Void Vertigo**  
    - STATUS: On exposed hull or high gantries: Agility checks −20%, ranged accuracy −15%.  
    - RESPECT: `EVA_CREWS` −5.

## 21–30 Survival / environment traits (Cell)

21. **Iron Lungs (Cell)**  
    - POOL: Oxygen decay rate −20% in `LOW_OXYGEN` or `TOXIC` states.  
    - STATUS: Breath‑hold time in flooded/smoke cells ×2.  
    - RESPECT: `HULL_TECHS` +5.

22. **Cold Glass Nerves**  
    - ATTR: Tenacity +1.  
    - STATUS: Freezing thresholds lowered: body temperature warning at 30°C instead of 32°C; stamina decay in cold −10%.  

23. **Thin Suit Skin**  
    - STATUS: Suit integrity damage +20%; knockdown and stun chance +15%.  
    - POOL: BloodMax −10%.  

24. **Composite Frame**  
    - STATUS: Knockdown and stun chance −25%; suit integrity loss −10%.  
    - POOL: Movement speed −5%.

25. **Chemical Drift**  
    - STATUS: Tagged toxins (chem leak, spore cloud) damage −25%; drug withdrawal −25%.  
    - RESPECT: `BIOHAZARD_TEAMS` +5.

26. **Weak Filter**  
    - STATUS: Disease/contaminant chance ×2, duration +30%.  

27. **Heat Friction**  
    - STATUS: In high‑heat cells: Strength −1, Tenacity −1, stamina drain +25%.  

28. **Cold Aversion**  
    - STATUS: In cold cells: Agility −1, Tenacity −1, stamina drain +25%.  

29. **Rad Absorber**  
    - STATUS: Radiation gain +50%; while irradiated, stamina regen +10%, blood regen +10%.  

30. **Rad Fragile**  
    - STATUS: Radiation thresholds harsher; penalties start earlier and scale 1.5×.

These can be extended in the same pattern up to 150+ Cell‑specific traits; many of your Fractures already cover the more exotic/one‑off effects.

## Cell respect / reputation model (replacement for config)

Refactor `respect_system.cfg` into a Cell‑themed, engine‑driven config.

**File:** `res://design/systems/cell_respect_system.cfg`

```ini
[RESPECT_MODEL]
range_min = 0
range_max = 100
base_neutral = 50

[standing_model]
; final_standing = clamp( rep_weight * reputation + disp_weight * disposition + resp_weight * (respect - base_neutral) )
rep_weight   = 0.5
disp_weight  = 0.3
resp_weight  = 0.2

[ui_thresholds]
hostile_max  = -25
neutral_min  = -10
friendly_min =  20
admire_min   =  40
```

**File:** `res://scripts/factions/cell_respect_system.gd`

```gdscript
extends Resource
class_name CellRespectSystem

@export var range_min := 0.0
@export var range_max := 100.0
@export var base_neutral := 50.0

@export var rep_weight := 0.5
@export var disp_weight := 0.3
@export var resp_weight := 0.2

@export var hostile_max := -25.0
@export var neutral_min := -10.0
@export var friendly_min := 20.0
@export var admire_min := 40.0

func compute_standing(rep: float, disp: float, resp: float) -> float:
    var standing := rep_weight * rep + disp_weight * disp + resp_weight * (resp - base_neutral)
    return clamp(standing, -100.0, 100.0)

func classify(standing: float) -> StringName:
    if standing <= hostile_max:
        return &"hostile"
    if standing < neutral_min:
        return &"wary"
    if standing < friendly_min:
        return &"neutral"
    if standing < admire_min:
        return &"friendly"
    return &"admire"
```

Traits then apply `FACTION_REP` and `RESPECT` modifiers by faction id, and the `CellRespectSystem` converts those into concrete behavior and UI states, fully aligned with Cell’s survival, faction, and fracture systems.
