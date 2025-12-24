# PixelLab Asset Generation (Cell)

This document explains how to use `tools/Generate-CellAssets.ps1` to bulk-generate region assets via PixelLab and wire them into Godot.

## Quick start
1. Ensure you have PowerShell 7+ and a PixelLab API key in `PIXELLAB_API_KEY` (or pass -ApiKey to the script).
2. From repo root run:

   ```powershell
   pwsh ./tools/Generate-CellAssets.ps1 -ProjectRoot . -Region Ashveil -TilesetCount 4 -SpriteSheetCount 6 -VerboseLogging
   ```

3. After the script finishes, generated PNGs will be under `assets/tilesets` and `assets/sprites` and manifests will be in `tools/generated-manifests`.
4. In the Godot editor run `res://tools/editor/cell_tileset_loader.gd` (Editor -> File -> Run) to create TileSet `.tres` resources from the manifest.

## Security note
- Do not commit your `PIXELLAB_API_KEY` to the repo. Use environment variables or secure secrets store.

## Troubleshooting
- If PowerShell complains about `Invoke-RestMethod` or TLS, ensure PowerShell 7+ is installed and networking is allowed.
- If Godot or ffmpeg are missing from PATH you can still run the script, but local tooling that depends on them will be unavailable.
