# PR commit steps (suggested)

Run these locally (git must be available on your machine). They produce the commit sequence recommended in the PR plan.

# 1. Create feature branch
git checkout -b feat/loreway-dialogue-integration

# 2. Commit 1: schema + example + loader stub
git add res/narrative/_schema/dialogue_schema.json res/narrative/loreway/dialogue/ashveil_scavenger_intro.json res/scripts/narrative/loreway_bridge.gd
git commit -m "feat(loreway): add dialogue schema, example graph, and LorewayBridge loader"

# 3. Commit 2: core runtime
git add res/scripts/narrative/dialogue_graph.gd res/scripts/narrative/dialogue_condition_evaluator.gd res/scripts/narrative/dialogue_session.gd res/scripts/narrative/speech_check_evaluator.gd
git commit -m "feat(loreway): add DialogueGraph, condition evaluator, session, and speech checks"

# 4. Commit 3: interaction + debug
git add res/scripts/narrative/interaction_router.gd res/scripts/narrative/encounter_manager.gd res/scripts/debug/dialogue_debug_snapshot.gd
git commit -m "feat(loreway): add interaction router, encounter manager, and debug snapshot"

# 5. Commit 4: tests and scene
git add tests/scenes/DialogueTestScene.tscn tests/scene_scripts/npc_dialogue_test_controller.gd tests/unit/*.gd
git commit -m "test(loreway): add dialogue test scene and unit tests"

# 6. Commit 5: speech-check flow + snapshots
# (assumes changes to DialogueSession and SpeechCheckEvaluator)
git add res/scripts/narrative/dialogue_session.gd res/scripts/narrative/speech_check_evaluator.gd
git commit -m "feat(loreway): integrate speech-check flow and snapshot reporting"

# 7. Commit 6: CI JSON validation
git add .github/workflows/dialogue-json-validate.yml tools/validate_dialogue_json.py PR_DESCRIPTION.md PR_COMMIT_STEPS.md
git commit -m "ci(loreway): add JSON schema validation job for dialogue files"

# 8. Push branch and open PR
git push -u origin feat/loreway-dialogue-integration
# Open a PR using your normal GitHub workflow UI or hub/gh CLI
