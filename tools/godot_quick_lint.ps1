<# godot_quick_lint.ps1
Quick scanner for common Godot 3->4 migration and syntax patterns that often
cause parse failures (helpful when 'warnings as errors' is enabled).

Usage: run from repo root:
  .\tools\godot_quick_lint.ps1

It produces a simple report in tools/godot_quick_lint_report.txt
#>

$repo = Get-Location
$out = Join-Path -Path $repo -ChildPath "tools/godot_quick_lint_report.txt"
Remove-Item -Path $out -ErrorAction SilentlyContinue

$patterns = @{
    "EmptyCalls" = '\.empty\s*\(';
    "PoolVector" = 'PoolVector2Array|PoolVector3Array';
    "ResourceSaverSave" = 'ResourceSaver\.save\s*\(';
    "DirAccessMakeDir" = 'DirAccess\.make_dir_recursive\s*\(';
    "ExportFileComma" = '@export_file\("[^"]+,"';
    "IsEqualApproxArgs" = 'is_equal_approx\s*\([^,]+,[^)]+,[^)]+\)';
}

Add-Content -Path $out -Value "Godot Quick Lint Report - $(Get-Date)`n"
foreach ($k in $patterns.Keys) {
    Add-Content -Path $out -Value "\n== $k =="
    $pat = $patterns[$k]
    $lintMatches = Select-String -Path "**/*.gd" -Pattern $pat -SimpleMatch -CaseSensitive:$false -ErrorAction SilentlyContinue
    if ($lintMatches) {
        foreach ($m in $lintMatches) {
            Add-Content -Path $out -Value "$($m.Path):$($m.LineNumber): $($m.Line.Trim())"
        }
    } else { Add-Content -Path $out -Value "(none found)" }
}

Add-Content -Path $out -Value "`nNote: Patterns are heuristic; inspect each occurrence before applying fixes." 
Write-Output "Wrote lint report to $out"