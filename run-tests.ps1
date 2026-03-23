#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Run all unit tests defined in .github/workflows/ci.yml
.DESCRIPTION
    Reads test paths from .github/workflows/ci.yml and executes them locally.
    Exit code: 0 = all passed, 1 = one or more failed
#>

param(
    [string]$GodotExe = "C:\apps\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64_console.exe",
    [switch]$StopOnFirstFailure
)

# Read and parse ci.yml to extract test paths
$ciYmlPath = Join-Path $PSScriptRoot ".github\workflows\ci.yml"

if (-not (Test-Path $ciYmlPath)) {
    Write-Host "ERROR: CI configuration not found at: $ciYmlPath" -ForegroundColor Red
    exit 1
}

$ciContent = Get-Content $ciYmlPath -Raw
$tests = @()

# Extract test paths from lines like: run: godot --headless --script ./tests/...
$pattern = 'run:\s+godot\s+--headless\s+--script\s+(\.\/tests\/[^\s]+\.gd)'
$matches = [regex]::Matches($ciContent, $pattern)

foreach ($match in $matches) {
    $testPath = $match.Groups[1].Value
    if ($testPath -and $tests -notcontains $testPath) {
        $tests += $testPath
    }
}

if ($tests.Count -eq 0) {
    Write-Host "ERROR: No tests found in $ciYmlPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $GodotExe)) {
    Write-Host "ERROR: Godot executable not found at: $GodotExe" -ForegroundColor Red
    exit 1
}

Write-Host "Loaded $($tests.Count) tests from ci.yml`n" -ForegroundColor Cyan

Push-Location "src"

$passed = 0
$failed = 0
$failedTests = @()

foreach ($test in $tests) {
    $testName = Split-Path $test -Leaf
    Write-Host "[$($passed + $failed + 1)/$($tests.Count)] $testName" -NoNewline
    
    & $GodotExe --headless --script $test 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ✓" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " ✗" -ForegroundColor Red
        $failed++
        $failedTests += $test
        
        if ($StopOnFirstFailure) {
            Write-Host "`nStopping on first failure." -ForegroundColor Red
            Pop-Location
            exit 1
        }
    }
}

Pop-Location

Write-Host "`n" + ("=" * 60)
Write-Host "Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })

if ($failedTests.Count -gt 0) {
    Write-Host "`nFailed tests:" -ForegroundColor Red
    $failedTests | ForEach-Object { Write-Host "  - $_" }
}

exit $(if ($failed -gt 0) { 1 } else { 0 })
