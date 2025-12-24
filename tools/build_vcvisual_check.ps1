# Tool: tools/build_vcvisual_check.ps1
# Purpose: Compile and run a minimal header-check TU for VCVisualLatentTrace.
# Usage: .\build_vcvisual_check.ps1

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path "$scriptDir\..\..").Path
$src = Join-Path $projectRoot "src\visual_code\VCVisualLatentTrace_test_compile.cpp"
$out = Join-Path $projectRoot "build\vcvisual_header_check.exe"

Write-Host "Compiling header check: $src"

# Try MSVC cl.exe first
if (Get-Command cl -ErrorAction SilentlyContinue) {
    Write-Host "Using cl.exe (MSVC) to compile"
    cl /EHsc /std:c++17 /Fe:$out $src 2>&1 | Write-Host
    if (Test-Path $out) { & $out; exit $LASTEXITCODE }
    else { Write-Error "Compilation with cl.exe failed"; exit 1 }
}

# Fallback to g++
if (Get-Command g++ -ErrorAction SilentlyContinue) {
    Write-Host "Using g++ to compile"
    $cmd = "g++ -std=c++17 -O2 -o `"$out`" `"$src`""
    iex $cmd
    if (Test-Path $out) { & $out; exit $LASTEXITCODE }
    else { Write-Error "Compilation with g++ failed"; exit 1 }
}

Write-Error "No supported C++ compiler found (cl.exe or g++). Install toolchain or invoke via your CI."; exit 2
