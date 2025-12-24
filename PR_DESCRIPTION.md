# feat(loreway): add Godot dialogue runtime and Loreway bridge

Summary
-------
Adds a Godot-native dialogue runtime and a Loreway bridge so Loreway JSON exports can drive in-game NPC conversations. Provides: graph loader/schema, runtime (graph, evaluator, session), speech-checks, interaction routing, encounter manager, debug snapshotting, basic tests, and a CI job to validate dialogue JSON files.

Implementation details
----------------------
- Dialogue schema: `res/narrative/_schema/dialogue_schema.json`
- Example graph: `res/narrative/loreway/dialogue/ashveil_scavenger_intro.json`
- Runtime: `res/scripts/narrative/` (DialogueGraph, LorewayBridge, DialogueConditionEvaluator, DialogueSession, SpeechCheckEvaluator, InteractionRouter, EncounterManager)
- Debugging: `res/scripts/debug/dialogue_debug_snapshot.gd`
- Tests: `tests/unit/*` and `tests/scenes/DialogueTestScene.tscn` and `tests/scene_scripts/npc_dialogue_test_controller.gd`
- CI: `.github/workflows/dialogue-json-validate.yml` and `tools/validate_dialogue_json.py` (validates all dialogue JSON files against schema)

How to test locally
-------------------
1. Open the project in Godot editor.
2. Run the scene `res://tests/scenes/DialogueTestScene.tscn` to manually step through the Ashveil scavenger intro.
3. Run unit smoke tests by executing the provided small test scripts in the Godot editor (or a test harness).
4. From the repo root, run:
   ```sh
   python tools/validate_dialogue_json.py --schema res/narrative/_schema/dialogue_schema.json --dir res/narrative/loreway/dialogue
   ```
   This will validate all JSON files and fail if any do not conform to schema.

Risks & limitations
-------------------
- The speech-check JSON shape supports both `speech_skill` and simple `stat` checks; shape normalization is done in the session. If you prefer a single canonical shape, we can tighten schema and evaluator in follow-ups.
- The existing Lua Loreway generator is not modified; compatibility was preserved via schema and loader but deeper integration can be added later.
- The CI job will run JSON validation only; further unit & integration tests (Godot test harness) are recommended before merging.

Suggested commit sequence for small, reviewable commits
------------------------------------------------------
Refer to `PR_COMMIT_STEPS.md` for commands to create the commits locally.
