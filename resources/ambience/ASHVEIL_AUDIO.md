# Ashveil Audio - Recommended Buses & Notes

This short note documents the recommended audio bus layout and basic usage for the Ashveil ambience controllers.

## Buses (recommended)
- **AshveilBase** — Always-on bed (mono/narrow stereo). Broad-band ash hiss, low wind, subsonic hum (20–80 Hz).
- **AshveilMid** — Local scene details. Creeks, signs, distant cars, subtle midrange activity.
- **AshveilEvent** — Short one-shot/loop events for memory/sting playback (radio fragments, broadcasts).
- **AshveilCollapse** — Large, pitched-down roars and collapse tails; emphasized in low end (80–200 Hz).

## Mixer routing tips
- Route each `Ashveil*` bus under your general `AMBIENT`/`MASTER` bus as appropriate for the project.
- Keep `AshveilBase` narrow/mono to create claustrophobia; `AshveilCollapse` should be fuller with low-pass and reverb sends for distance.
- Use send busses for long reverb tails and pre-delay to sell city-scale collapses.

## Test scene
- `scenes/tests/test_ashveil_ambience.tscn` contains placeholder `AudioStreamPlayer3D` nodes wired to `AmbienceController3D` for quick in-editor checks and mixing.

## Notes
- The `AshveilAmbience3DController` will assign the exported buses at runtime; you can override bus names on the controller node in the scene.
- Use the test scene to tune relative levels before assigning production audio assets to `res://audio/loops` and `res://audio/stingers`.

## Auto-binding assets by convention
- `AshveilAmbience3DController` includes an **auto-bind helper** (`auto_bind_assets`) and the `auto_bind_on_ready` export (default: `true`).
- Naming convention: files in `res://audio/loops` and `res://audio/stingers` will be matched to players by filename. For best results, include descriptive tokens in filenames that match player names or types (e.g., `Base`, `Mid`, `Collapse`, `Event`, `Petrified`, `Promenade`).
- Examples: `Ashveil_Petrified_Promenade_Loop.ogg` → a `MidPlayer` named `MidPlayer1`; `Ashveil_Collapse_01.ogg` → `CollapsePlayer1`.
- If no exact match is found, the helper uses token heuristics (e.g., matches `collapse`, `roar`, `stinger`) and falls back to the first asset found.
- To disable auto-binding in-scene, set `auto_bind_on_ready` to `false` and assign streams manually via the Inspector or call `auto_bind_assets()` from an Editor script when ready.

## Default tuning curves
- On first editor-time use, the controller will auto-create sensible default `Curve` resources and save them to `res://resources/ambience/`:
  - `ashveil_roar_volume_curve.tres`
  - `ashveil_roar_pitch_curve.tres`
  - `ashveil_creak_volume_curve.tres`
  - `ashveil_creak_pitch_curve.tres`
- These defaults implement:
  - **Roar volume:** S-curve, restrained until mid-intensity, then ramps hard near 0.7–1.0.
  - **Roar pitch:** Gentle near-linear rise (heavy at low intensity, slight sharpness at peak).
  - **Creak volume:** Mostly linear with a mild bump around mid-intensity.
  - **Creak pitch:** Very shallow uptick at high intensity.
- You can edit these curves in the Inspector (select `AmbienceController3D`) to refine behavior for production assets.


## Region runtime integration
- `AshveilDebrisStratumRuntime` will automatically detect and initialize an `AshveilAmbience3DController` if present in the region scene (wire it into `ambience_controller_3d_path` or name it `AmbienceController3D`).
- The controller exposes `apply_region_profile(hazard_profile, difficulty)` and `start_ambience()` methods; `RegionManager` will call `apply_region_profile` when the region loads so the ambience reacts to region hazard profiles and difficulty.
- Gameplay triggers in the Ashveil runtime (e.g., `trigger_pursuit`, `trigger_signal_flood`) will also attempt to notify the 3D controller to play event stingers.
