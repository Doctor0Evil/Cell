Dev export and test runner

This project includes a Windows "Windows Dev" export preset for local development. The preset is a simple, non-installer export that produces an EXE + PCK for running locally without admin privileges.

How to export

1. In Godot: Project -> Export...
2. Choose the "Windows Dev" preset and click "Export Project..."
3. Select a folder under your user profile (e.g., C:\Users\<you>\Games\CELL-Dev) and export as `CELL.exe`.

Dev runtime flags

- `CELL.exe --run-tests` — runs `res://scenes/tests/TestRunner.tscn`. The runner will attempt to write `res://logs/test_results.json` when run from source; when run from an exported build it will write `user://logs/test_results.json` instead (user:// maps to a writable directory on the host; on Windows this will be under AppData or the Godot user folder).

- `CELL.exe --dev-harness` — starts the `res://scenes/debug/DevHarness.tscn` scene. The Dev Harness provides a small UI panel to inspect oxygen/water/V.I.T.A.L.I.T.Y. for a spawned player and a button to run tests.

Helper script

- A helper PowerShell script is provided at `tools/export_windows_dev_and_run_tests.ps1` to automate exporting and running the tests locally. Example usage from project root:

  - `.	ools\export_windows_dev_and_run_tests.ps1` (uses defaults)
  - `.	ools\export_windows_dev_and_run_tests.ps1 -ProjectPath 'C:\Users\Hunter\Repos\Cell' -OutputDir 'C:\Users\Hunter\Games\CELL-Dev'`

Diagnostics

- The helper script now performs additional diagnostics before exporting:
  - Detects `godot4`/`godot` on PATH and, if missing, searches common install locations (Program Files, Local AppData, Downloads).
  - Validates that `export_presets.cfg` contains a preset named `Windows Dev` and warns if it's missing.
  - Checks for installed export templates under `%APPDATA%\Godot` and warns if templates are not found (missing templates will cause export to fail).

Automatic template installation

- When export templates are missing, the helper script can attempt a best-effort automatic download and install of export templates.
  - Use the `-AutoInstallTemplates` switch to run the installer automatically and non-interactively: `.	ools\export_windows_dev_and_run_tests.ps1 -AutoInstallTemplates`.
  - If you run without the flag, the script will prompt to ask whether you want it to attempt the download.
  - The installer tries several common download locations derived from your Godot version; if it cannot find a matching package, it will tell you how to install templates manually.

If the script reports missing Godot or missing templates, follow the printed guidance to install or configure the editor and templates, then re-run the helper script.
Notes

- The export preset intentionally does not exclude test scenes/scripts so dev builds include the test runner.
- No admin privileges are required when exporting into a user-writable directory.
