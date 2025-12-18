<#
Usage: run from project root (or pass -ProjectPath):
  .\tools\export_windows_dev_and_run_tests.ps1 -ProjectPath 'C:\Users\Hunter\Repos\Cell' -OutputDir 'C:\Users\Hunter\Games\CELL-Dev'

What the script does:
 - finds a godot CLI ('godot4' or 'godot') on PATH
 - ensures the output dir exists
 - runs `godot --path <project> --export "Windows Dev" "<output>\CELL.exe"`
 - runs the exported exe with `--run-tests`, pipes output to a log
 - prints the path to the test_results.json if found or displays console output for diagnostics
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputDir,

    [Parameter(Mandatory = $false)]
    [string]$PresetName = "Windows Dev",

    [Parameter(Mandatory = $false)]
    [string]$GodotPath = ""
)

# Default Godot CLI path for this development node if not provided
if (-not $GodotPath -or [string]::IsNullOrWhiteSpace($GodotPath)) {
    $GodotPath = "C:\Users\Hunter\Godot\Godot_v4.5.1-stable_win64.exe"
}

# Verify Godot exists
if (-not (Test-Path $GodotPath)) {
    Write-Error "Godot executable not found at '$GodotPath'. Pass -GodotPath explicitly or update the default in this script."
    exit 1
}

$ExportExe = Join-Path -Path $OutputDir -ChildPath "CELL.exe"
$RunLog = Join-Path -Path $OutputDir -ChildPath "CELL-run-tests.log"

Write-Output "Project: $ProjectPath"
Write-Output "Output Dir: $OutputDir"

if (-not (Test-Path $ProjectPath)) {
    Write-Error "Project path not found: $ProjectPath"
    exit 2
}

# Ensure output dir exists
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null }

# Find godot: allow override via parameter, fallback to a sensible default (edit if needed)
if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    $GodotPath = "C:\Program Files\Godot\Godot_v4.5.1-stable_win64.exe"  # <- EDIT THIS PATH to match your machine if not passing -GodotPath
}

if (-not (Test-Path $GodotPath)) {
    Write-Error "Godot executable not found at '$GodotPath'. Either pass -GodotPath, add Godot to PATH, or edit this script to point to your install." 
    Write-Error "Alternatively, open the Godot editor and use Project -> Export... to run the 'Windows Dev' preset manually."
    exit 3
}

# Validate that Godot is runnable
try {
    $ver = & $GodotPath --version 2>&1
    Write-Output "Godot version info: $ver"
} catch {
    Write-Warning ("Could not execute '{0} --version'. The executable may be missing dependencies or be an incompatible build." -f $GodotPath)
}

Write-Output "Using Godot executable: $GodotPath"

# Validate that the export preset exists in project export_presets.cfg
$exportCfgPath = Join-Path -Path $ProjectPath -ChildPath "export_presets.cfg"
if (-not (Test-Path $exportCfgPath)) {
    Write-Warning "No export_presets.cfg found at $exportCfgPath. Ensure the 'Windows Dev' preset exists in Project -> Export..."
} else {
    $cfgText = Get-Content -Path $exportCfgPath -Raw -ErrorAction SilentlyContinue
    $pattern = 'name\s*=\s*"' + [regex]::Escape($PresetName) + '"'
    if ($cfgText -match $pattern) {
        Write-Output "Export preset '$PresetName' found in export_presets.cfg"
    } else {
        Write-Warning "Export preset '$PresetName' was not found in export_presets.cfg. Please create it in Project -> Export..."
    }
}

# Check for export templates in AppData (common place on Windows)
$appDataGodot = Join-Path -Path $env:APPDATA -ChildPath "Godot"
$templatesFound = $false
if (Test-Path $appDataGodot) {
    $templateDirs = @(
        Join-Path $appDataGodot "templates",
        Join-Path $appDataGodot "export_templates",
        Join-Path $appDataGodot "templates\4"
    )
    foreach ($td in $templateDirs) {
        if (Test-Path $td) {
            $files = Get-ChildItem -Path $td -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($files) { 
                Write-Output "Found export templates under: $td"
                $templatesFound = $true
                break
            }
        }
    }
}
if (-not $templatesFound) {
    Write-Warning "Did not detect Godot export templates in $appDataGodot. Exports may fail if templates are missing."
    Write-Warning "Install export templates via the Godot editor (Editor -> Manage Export Templates) or via the Godot website."

    function Test-InstallTemplates {
        param(
            [string]$versionString,
            [string]$destDir
        )

        Write-Output "Attempting automatic download of export templates for Godot version: $versionString"

            # Parse the numeric version (e.g., 4.2.1) if present
        $v = $null
        $rx = [regex]"(\d+\.\d+\.\d+)"
        $m = $rx.Match($versionString)
        if ($m.Success) { $v = $m.Groups[1].Value }
        else {
            $rx2 = [regex]"(\d+\.\d+)"
            $m2 = $rx2.Match($versionString)
            if ($m2.Success) { $v = $m2.Groups[1].Value } else { $v = $versionString }
        }

        # Candidate filenames and base URLs
        $filenames = @(
            "Godot_v${v}_export_templates.tpz",
            "Godot_v${v}_export_templates.zip",
            "Godot_v${v}-stable_export_templates.tpz",
            "Godot_v${v}-stable_export_templates.zip"
        )
        $baseUrls = @(
            "https://downloads.tuxfamily.org/godotengine/$v/",
            "https://github.com/godotengine/godot/releases/download/v$v/",
            "https://github.com/godotengine/godot/releases/download/$v/"
        )

        $tmp = [System.IO.Path]::GetTempPath()
        foreach ($b in $baseUrls) {
            foreach ($f in $filenames) {
                $url = "$b$f"
                Write-Output "Trying: $url"
                $tmpFile = Join-Path -Path $tmp -ChildPath $f
                try {
                    Invoke-WebRequest -Uri $url -OutFile $tmpFile -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
                    if ((Test-Path $tmpFile) -and ((Get-Item $tmpFile).Length -gt 1024)) {
                        Write-Output "Downloaded candidate: $tmpFile"
                        # Ensure dest dir exists
                        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }

                        # Attempt extraction based on extension
                        $ext = [System.IO.Path]::GetExtension($tmpFile).ToLowerInvariant()
                        if ($ext -eq '.zip') {
                            try { Expand-Archive -Path $tmpFile -DestinationPath $destDir -Force; Write-Output "Extracted templates to $destDir"; return $true } catch { Write-Warning ("Expand-Archive failed for {0}: {1}" -f $tmpFile, $_) }
                        } elseif ($ext -eq '.tpz') {
                            # Some .tpz files are actually zip archives; try unzip via Expand-Archive
                            try { Expand-Archive -Path $tmpFile -DestinationPath $destDir -Force; Write-Output "Extracted .tpz (via Expand-Archive) to $destDir"; return $true } catch {
                                # If Expand-Archive didn't work, attempt to rename to .zip and try again
                                $alt = [System.IO.Path]::ChangeExtension($tmpFile, '.zip')
                                try { Rename-Item -Path $tmpFile -NewName $alt -ErrorAction Stop; Expand-Archive -Path $alt -DestinationPath $destDir -Force; Write-Output "Renamed/Extracted .tpz->.zip to $destDir"; return $true } catch { Write-Warning ("Failed to extract .tpz file: {0}" -f $_) }
                            }
                        } else {
                            Write-Warning "Unknown archive extension '$ext' for $tmpFile - manual installation may be required."
                        }
                    }
                } catch {
                    # ignore and try next candidate
                }
            }
        }

        return $false
    }

    $shouldAttempt = $AutoInstallTemplates
    if (-not $shouldAttempt) {
        $ans = Read-Host "Attempt to download and install templates automatically now? (Y/n)"
        if ($ans -eq '' -or $ans.ToLower().StartsWith('y')) { $shouldAttempt = $true }
    }

    if ($shouldAttempt) {
        $installed = Test-InstallTemplates -versionString $ver -destDir (Join-Path $appDataGodot 'templates')
        if ($installed) {
            Write-Output "Automatic template install appears successful. Re-checking templates..."
            # Quick verification
            $templateFiles = Get-ChildItem -Path (Join-Path $appDataGodot 'templates') -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($templateFiles) { Write-Output "Templates now present under: $(Join-Path $appDataGodot 'templates')"; $templatesFound = $true }
            else { Write-Warning "Templates installed but not detected; please verify manually in $appDataGodot" }
        } else {
            Write-Warning "Automatic template installation failed (no candidate downloads succeeded). Please install export templates via the Godot Editor -> Manage Export Templates or download them manually from the Godot website."
        }
    }
}

# Export
if ($PresetName -eq "Windows Dev") {
    Write-Output ("Using preset '{0}' for export." -f $PresetName)
} else {
    Write-Warning ("Using preset '{0}' for export. Ensure it matches export_presets.cfg." -f $PresetName)
}

Write-Output ("Exporting preset '{0}' to {1}" -f $PresetName, $ExportExe)
$exportArgs = @("--path", $ProjectPath, "--export", $PresetName, $ExportExe)
Write-Output ("Running: {0} {1}" -f $godot, ($exportArgs -join ' '))
$exportProc = Start-Process -FilePath $GodotPath -ArgumentList $exportArgs -NoNewWindow -Wait -PassThru
if ($exportProc.ExitCode -ne 0) {
    Write-Error "Export failed (exit code $($exportProc.ExitCode)). Check Godot editor/export templates and that the preset exists."
    exit 4
}

if (-not (Test-Path $ExportExe)) {
    Write-Error "Export reported success but $ExportExe was not found."
    exit 5
}

Write-Output "Export succeeded. Running exported exe with --run-tests (output -> $RunLog)"
& "$ExportExe" --run-tests 2>&1 | Tee-Object -FilePath $RunLog

Write-Output "Exe finished. Saved console output to $RunLog"

# Try to locate the test results JSON via the console log
$logText = Get-Content -Path $RunLog -Raw -ErrorAction SilentlyContinue
$rx = [regex]"TestRunner: wrote log to (.+)"
$mm = $rx.Match($logText)
if ($mm.Success) {
    $jsonPath = $mm.Groups[1].Value.Trim()
    Write-Output "Detected TestRunner log path printed by game: $jsonPath"
    # If the path is user://, try mapped location in $env:APPDATA\Godot\app_userdata\<appname>\ ...
    if ($jsonPath -like "user://*") {
        $attempt = Join-Path -Path $env:APPDATA -ChildPath "Godot\app_userdata\CELL\logs\test_results.json"
        if (Test-Path $attempt) { Write-Output "Found test_results.json at $attempt"; exit 0 }
        else { Write-Output "Could not find the file at $attempt; please check the game console for the exact user:// path."; exit 0 }
    } else {
        # If it's a res:// path, the file lives inside the PCK; that's less likely, but we already capture console output.
        Write-Output "TestRunner wrote: $jsonPath"; exit 0
    }
} else {
    Write-Output "No explicit TestRunner log path found in console; inspect $RunLog for details."
    exit 0
}