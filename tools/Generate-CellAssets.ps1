<#
.SYNOPSIS
    Bulk-generate survival-horror tilesets & sprites for Cell using PixelLab API,
    organized into a Godot-ready folder structure.

.DESCRIPTION
    - Creates /assets subfolders compatible with Godot’s scene-based project organization.
    - Calls PixelLab's API (via HTTP) for tilesets and sprite sheets and writes PNGs + JSON manifests.
    - Does NOT store API keys in the repo; pass via -ApiKey or set PIXELLAB_API_KEY environment variable.

    REQUIREMENTS:
    - PowerShell 7+
    - Invoke-RestMethod available
    - PIXELLAB_API_KEY environment variable (recommended)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,

    [ValidateSet("Ashveil","ColdVerge","RedSilence","Custom")]
    [string]$Region = "Ashveil",

    [string]$CustomBaseStylePrompt,

    [string]$ApiKey,

    [int]$TileSize = 32,

    [int]$TilesetCount = 3,

    [int]$SpriteSheetCount = 4,

    [switch]$VerboseLogging
)

#region Helpers
function Write-Log {
    param([string]$Message, [ValidateSet('INFO','WARN','ERROR','DEBUG')][string]$Level = 'INFO')
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = "[$timestamp][$Level]"
    if ($Level -eq 'ERROR') {
        Write-Error "$prefix $Message"
    } elseif ($Level -eq 'WARN') {
        Write-Warning "$prefix $Message"
    } elseif ($Level -eq 'DEBUG') {
        if ($VerboseLogging) { Write-Host "$prefix $Message" -ForegroundColor DarkGray }
    } else {
        Write-Host "$prefix $Message"
    }
}
function New-DirectoryIfMissing {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
} 
function Get-PixelLabApiKey {
    param([string]$ExplicitKey)
    if ($ExplicitKey) { return $ExplicitKey }
    $envKey = $env:PIXELLAB_API_KEY
    if (-not $envKey) { throw "PixelLab API key not provided. Set PIXELLAB_API_KEY or pass -ApiKey." }
    return $envKey
}
function Invoke-PixelLabApi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Endpoint,
        [Parameter(Mandatory=$true)][hashtable]$Body,
        [Parameter(Mandatory=$true)][string]$ApiKey
    )
    $baseUrl = "https://api.pixellab.ai"
    $url = "$baseUrl$Endpoint"
    $jsonBody = $Body | ConvertTo-Json -Depth 8
    Write-Log "POST $url" 'DEBUG'
    Write-Log "Body: $jsonBody" 'DEBUG'
    try {
        $response = Invoke-RestMethod -Method Post -Uri $url -Headers @{ "Authorization" = "Bearer $ApiKey"; "Content-Type" = "application/json" } -Body $jsonBody
        return $response
    } catch {
        Write-Log "PixelLab API call failed: $($_.Exception.Message)" 'ERROR'
        throw
    }
}
function Save-Base64Image {
    param([string]$Base64Data, [string]$OutputPath)
    $bytes = [Convert]::FromBase64String($Base64Data)
    [System.IO.File]::WriteAllBytes($OutputPath, $bytes)
}
function Resolve-RegionBasePrompt { param([string]$Region, [string]$CustomBaseStylePrompt)
    $common = "grim, survival-horror, late-90s isometric RPG, muted palette, harsh contrast, claustrophobic, VHS grime, low light, readable silhouettes"
    switch ($Region) {
        "Ashveil" {
            $s = @"
$common, Ashveil: burnt decks, corpse economies, ration lockers, scorched bulkheads, smoldering vents, ash-choked corridors, improvised shrines and charnel heaps
"@
            return $s.Trim()
        } 
        "ColdVerge" {
            $s = @"
$common, Cold Verge: frozen hull plating, ice-fog vents, cryo frost, rime-coated gantries, burst coolant lines, blue-white speculars, breath clouds in the dark
"@
            return $s.Trim()
        } 
        "RedSilence" {
            $s = @"
$common, Red Silence: signal glyphs, corrupted terminals, glitch bleed, warning strobes, cable tangles, occult radio interference, red-black palettes, hostile UI overlays
"@
            return $s.Trim()
        } 
        "Custom" {
            if (-not $CustomBaseStylePrompt) { throw "Region 'Custom' selected but -CustomBaseStylePrompt is empty." }
            $s = @"
$common, $CustomBaseStylePrompt
"@
            return $s.Trim()
        }
        default { throw "Unknown region: $Region" }
    }
}
#endregion Helpers

$ErrorActionPreference = 'Stop'
$ProjectRoot = (Resolve-Path $ProjectRoot).Path
Write-Log "Project root: $ProjectRoot"
$projectFile = Join-Path $ProjectRoot "project.godot"
if (-not (Test-Path $projectFile)) { Write-Log "project.godot not found at $ProjectRoot. Ensure this is the Cell Godot project root." 'WARN' }
$assetsRoot = Join-Path $ProjectRoot "assets"; $tilesetRoot = Join-Path $assetsRoot "tilesets"; $spriteRoot = Join-Path $assetsRoot "sprites"; $conceptRoot = Join-Path $assetsRoot "concepts"; $manifestRoot = Join-Path $ProjectRoot "tools\generated-manifests"
New-DirectoryIfMissing $assetsRoot; New-DirectoryIfMissing $tilesetRoot; New-DirectoryIfMissing $spriteRoot; New-DirectoryIfMissing $conceptRoot; New-DirectoryIfMissing $manifestRoot
Write-Log "Ensured asset directories under $assetsRoot"
$resolvedApiKey = Get-PixelLabApiKey -ExplicitKey $ApiKey; Write-Log "PixelLab API key resolved." 'DEBUG'
Write-Log "Using region prompt for $Region" 'INFO'

# Tileset generation loop
$tilesetManifest = @(); $regionSlug = $Region.ToLowerInvariant()
for ($i=1; $i -le $TilesetCount; $i++) {
    Write-Log "[$Region] Generating tileset $i of $TilesetCount..."
    $tilesetPrompt = @"
$(Resolve-RegionBasePrompt -Region $Region -CustomBaseStylePrompt $CustomBaseStylePrompt),
top-down exploration, industrial biotech corridors, clear walkable vs blocked tiles,
strong grid readability for navigation, environmental storytelling specific to $Region
"@
$tilesetPrompt = $tilesetPrompt.Trim() 
    $body = @{ prompt=$tilesetPrompt; tile_size=$TileSize; layout="wang"; palette="horror_muted"; variations=1; seed=(Get-Random -Minimum 1 -Maximum 2147483647); output_format="base64" }
    $response = Invoke-PixelLabApi -Endpoint "/v1/tilesets/create" -Body $body -ApiKey $resolvedApiKey
    if (-not $response.image_base64) { throw "PixelLab tileset response missing image_base64. Inspect response schema and adjust script." }
    $tilesetId = if ($response.id) { $response.id } else { "tileset_${regionSlug}_$i" }
    $fileNamePng = "cell_${regionSlug}_tileset_{0:D2}_{1}.png" -f $i, $TileSize; $outPathPng = Join-Path $tilesetRoot $fileNamePng
    Save-Base64Image -Base64Data $response.image_base64 -OutputPath $outPathPng
    Write-Log "Saved $Region tileset to $outPathPng"
    $relPath = (Resolve-Path $outPathPng).Path.Replace($ProjectRoot, "res:").Replace("\","/")
    $tilesetManifest += [pscustomobject]@{ id=$tilesetId; region=$Region; file=$relPath; tile_size=$TileSize; layout=$body.layout; seed=$body.seed; prompt=$tilesetPrompt; created_utc=(Get-Date).ToUniversalTime().ToString("o") }
}

# Sprite sheet generation
$spriteManifest = @()
for ($i=1; $i -le $SpriteSheetCount; $i++) {
    Write-Log "[$Region] Generating sprite sheet $i of $SpriteSheetCount..."
    $spritePrompt = @"
$(Resolve-RegionBasePrompt -Region $Region -CustomBaseStylePrompt $CustomBaseStylePrompt),
biomechanical abomination, readable silhouette at player scale, 4-direction walk cycle, idle + walk poses,
sprite sheet grid layout, designed to match $Region environment lighting and palette
"@
$spritePrompt = $spritePrompt.Trim()
    $body = @{ prompt=$spritePrompt; sprite_width=32; sprite_height=48; frames_x=4; frames_y=4; seed=(Get-Random -Minimum 1 -Maximum 2147483647); output_format="base64" }
    $response = Invoke-PixelLabApi -Endpoint "/v1/spritesheets/create" -Body $body -ApiKey $resolvedApiKey
    if (-not $response.image_base64) { throw "PixelLab spritesheet response missing image_base64. Inspect response schema and adjust script." }
    $spriteId = if ($response.id) { $response.id } else { "sprite_${regionSlug}_$i" }
    $fileNamePng = "cell_${regionSlug}_sprite_{0:D2}.png" -f $i; $outPathPng = Join-Path $spriteRoot $fileNamePng
    Save-Base64Image -Base64Data $response.image_base64 -OutputPath $outPathPng
    Write-Log "Saved $Region spritesheet to $outPathPng"
    $relPath = (Resolve-Path $outPathPng).Path.Replace($ProjectRoot, "res:").Replace("\","/")
    $spriteManifest += [pscustomobject]@{ id=$spriteId; region=$Region; file=$relPath; frame_width=$body.sprite_width; frame_height=$body.sprite_height; frames_x=$body.frames_x; frames_y=$body.frames_y; seed=$body.seed; prompt=$spritePrompt; created_utc=(Get-Date).ToUniversalTime().ToString("o") }
}

# Write manifests
$tilesetManifestPath = Join-Path $manifestRoot "cell_tilesets.json"; $spriteManifestPath = Join-Path $manifestRoot "cell_sprites.json"
$tilesetManifest | ConvertTo-Json -Depth 5 | Out-File -Encoding UTF8 $tilesetManifestPath
$spriteManifest | ConvertTo-Json -Depth 5 | Out-File -Encoding UTF8 $spriteManifestPath
Write-Log "Wrote tileset manifest: $tilesetManifestPath"; Write-Log "Wrote sprite manifest:  $spriteManifestPath"
Write-Log "PixelLab region asset generation for Cell completed successfully."