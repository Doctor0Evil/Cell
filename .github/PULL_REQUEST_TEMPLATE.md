<!-- Pull Request Template -->

## Summary

Region scaffolding: missing scenes, runtimes, and registry fields.

This PR:
- Adds placeholder region scenes for Iron Hollow, Cold Verge, and Red Silence.
- Adds minimal runtime scripts for each region.
- Expands `CellContentRegistry` with tags, tileset/ambience keys, spawn/loot tables, contamination risk, and `runtime_script_path`.
- Adds placeholder enemy and loot scenes to make the scenes loadable in CI.
- Adds `scripts/tests/test_region_registry.gd` smoke test and `scripts/tools/region_registry_verifier.gd`.

CI: the GitHub Actions workflow runs the Godot TestRunner via:
`godot4 --headless --quiet --path . --quit --run res://scenes/tests/TestRunner.tscn`

Please review; this PR is intended to be a safe scaffolding pass — future PRs will replace placeholders with real content and tune spawn tables / ambience.
