Title: Region scaffolding: missing scenes, runtimes, and registry fields

Summary:
- Adds placeholder region scenes and minimal runtime scripts for three missing regions.
- Expands `CellContentRegistry` with tags, ambience/tileset keys, spawn/loot tables, contamination risk, and `runtime_script_path`.
- Adds placeholder enemy/loot scenes to avoid scene-load failures in CI.
- Adds smoke tests and a registry verifier utility.

CI: The repository's GitHub Actions will run the headless Godot TestRunner (`godot4 --headless --quiet --path . --quit --run res://scenes/tests/TestRunner.tscn`) and attach `res/logs/test_results.json`.

Notes for reviewers:
- This PR is intentionally scaffold-only; follow-ups will replace placeholders and tune spawn tables and ambience.
