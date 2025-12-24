# Post-FX Profiles — README / Spec

**Purpose:** Quick reference for designers and engineers on creating, tuning, and integrating Post-FX panic profiles used by Rachnoform, PsychicEcho, and post-processing (`cell_horror_post.gdshader`).

---

## 🔧 Overview

- **Location:** `res/config/post_fx_profiles/` (JSON files)
- **Tool:** `tools/post_fx_profile_tool.js` — create/list/show/delete profiles
- **Runtime loader:** `res://scripts/fx/cell_post_profile_loader.gd` (loads JSON → shader params)
- **Driver node:** `res://scripts/fx/cell_post_fx.gd` (attached to ColorRect shader material)

---

## 📁 Profile format (example)

```json
{
  "vignette_strength": 1.25,
  "vignette_softness": 0.55,
  "warp_strength": 0.038,
  "warp_noise_scale": 1.7,
  "warp_speed": 1.6,
  "grain_strength": 0.14,
  "flicker_strength": 0.30
}
```

- All values are floats. Reasonable ranges:
  - `vignette_strength`: 0.0–2.0
  - `vignette_softness`: 0.0–1.0
  - `warp_strength`: 0.0–0.1
  - `warp_noise_scale`: 0.5–4.0
  - `warp_speed`: 0.0–5.0
  - `grain_strength`: 0.0–0.3
  - `flicker_strength`: 0.0–0.5

---

## 🚀 Designer workflow (VS Code / Terminal)

- List profiles:
  - `node tools/post_fx_profile_tool.js list`
- Create preset (quick):
  - `node tools/post_fx_profile_tool.js create breakdown --intensity 0.7`
- Create preset (with overrides):
  - `node tools/post_fx_profile_tool.js create near_death --intensity 1.0 --grain 0.22 --flicker 0.4`
- Inspect profile:
  - `node tools/post_fx_profile_tool.js show near_death`

---

## 🔁 Integration notes

- Add profiles to `res/config/post_fx_profiles/`.
- `cell_post_profile_loader.gd` should be run on scene start or when switching levels to push parameters to `cell_post_fx.gd` (the ColorRect shader material).
- Rachnoform / PsychicEcho should call `post_fx.set_panic_intensity(panic / 100.0)` or `post_fx.pulse_panic(delta_amount)` to animate intensity.
- Use profile presets to set base shader params for environmental contexts (e.g., `low_panic`, `breakdown`, `near_death`); then modulate `panic_intensity` at runtime for dynamic spikes.

---

## 🧩 Best practices & design tips

- Use subtle base profiles; reserve high warp/grain for short, dramatic beats (player comfort).
- Combine with audio cues (whispers/chitter) at the same time you pulse panic for stronger effect.
- Keep profile files small and validated — engine loader should clamp values to safe ranges.
- Track profile changes with a simple changelog or comment header (authors/date).

> ⚠️ Note: Always test profiles in-context (same scene lighting and camera FOV) — perceived intensity varies with scene brightness and camera motion.

---

If you'd like, I can also add a couple of example presets (`low_panic.json`, `breakdown.json`, `near_death.json`) and a short CONTRIBUTING note to this folder.
