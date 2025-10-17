#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Comprehensive test runner for PoshGuard test suite

.DESCRIPTION
    Provides various test execution modes:
    - Fast: Quick unit tests without coverage (default)
    - Coverage: Full coverage analysis
    - CI: Simulate CI/CD pipeline
    - Single: Run single test file
    - Module: Run specific module tests
    - Debug: Detailed output for debugging
    
    Follows Pester Architect Agent best practices.

.PARAMETER Mode
    Test execution mode (Fast, Coverage, CI, Debug)

.PARAMETER Path
    Path to test file or directory (default: ./tests/Unit)

.PARAMETER Module
    Specific module to test (e.g., Core, Security, Advanced)

.PARAMETER ShowSummary
    Display detailed test summary

.PARAMETER StopOnFailure
    Stop on first test failure (debug mode only)

.EXAMPLE
    ./Run-Tests.ps1
    Run all unit tests quickly (no coverage)

.EXAMPLE
    ./Run-Tests.ps1 -Mode Coverage
    Run all unit tests with code coverage

.EXAMPLE
    ./Run-Tests.ps1 -Mode CI
    Simulate CI/CD pipeline execution

.EXAMPLE
    ./Run-Tests.ps1 -Module Core
    Run only Core module tests

.EXAMPLE
    ./Run-Tests.ps1 -Mode Debug -Module Security -StopOnFailure
    Debug Security module tests with stop on failure

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Version: 1.0.0
#>

[CmdletBinding()]
param(
  [Parameter()]
  [ValidateSet('Fast', 'Coverage', 'CI', 'Debug')]
  [string]$Mode = 'Fast',
  
  [Parameter()]
  [string]$Path,
  
  [Parameter()]
  [string]$Module,
  
  [Parameter()]
  [switch]$ShowSummary,
  
  [Parameter()]
  [switch]$StopOnFailure
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Import helpers
$helpersPath = Join-Path $PSScriptRoot 'Helpers/PesterConfigurations.psm1'
if (-not (Test-Path $helpersPath)) {
  Write-Error "Cannot find helper module at: $helpersPath"
  exit 1
}
Import-Module $helpersPath -Force

# Display banner
Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   PoshGuard Test Suite Runner v1.0    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Determine test path
if ($Module) {
  # Check if it's a main module
  $modulePath = Join-Path $PSScriptRoot "Unit/$Module.Tests.ps1"
  if (-not (Test-Path $modulePath)) {
    # Check submodules
    $subPaths = @(
      "Unit/Advanced/$Module.Tests.ps1",
      "Unit/BestPractices/$Module.Tests.ps1",
      "Unit/Formatting/$Module.Tests.ps1"
    )
    
    $found = $false
    foreach ($subPath in $subPaths) {
      $fullPath = Join-Path $PSScriptRoot $subPath
      if (Test-Path $fullPath) {
        $Path = $fullPath
        $found = $true
        break
      }
    }
    
    if (-not $found) {
      Write-Error "Module tests not found: $Module"
      exit 1
    }
  } else {
    $Path = $modulePath
  }
  
  Write-Host "Testing Module: " -NoNewline -ForegroundColor Yellow
  Write-Host $Module -ForegroundColor White
} elseif (-not $Path) {
  $Path = Join-Path $PSScriptRoot 'Unit'
  Write-Host "Testing All Modules" -ForegroundColor Yellow
} else {
  Write-Host "Testing Path: " -NoNewline -ForegroundColor Yellow
  Write-Host $Path -ForegroundColor White
}

Write-Host "Mode: " -NoNewline -ForegroundColor Yellow
Write-Host $Mode -ForegroundColor White
Write-Host ""

# Create configuration based on mode
$config = switch ($Mode) {
  'Fast' {
    Write-Host "Creating fast test configuration (no coverage)..." -ForegroundColor Cyan
    New-FastTestConfiguration -Path $Path -PassThru
  }
  'Coverage' {
    Write-Host "Creating coverage test configuration..." -ForegroundColor Cyan
    $repoRoot = Split-Path $PSScriptRoot -Parent
    $covPath = if ($Module) {
      # Try to match module file
      $modFile = Join-Path $repoRoot "tools/lib/$Module.psm1"
      if (Test-Path $modFile) {
        @($modFile)
      } else {
        @("$repoRoot/tools/lib/*.psm1")
      }
    } else {
      @("$repoRoot/tools/lib/*.psm1")
    }
    New-CoverageTestConfiguration -Path $Path -CoveragePath $covPath
  }
  'CI' {
    Write-Host "Creating CI test configuration..." -ForegroundColor Cyan
    New-CITestConfiguration -Path $Path -EnableCoverage:$IsLinux
  }
  'Debug' {
    Write-Host "Creating debug test configuration..." -ForegroundColor Cyan
    New-DebugTestConfiguration -Path $Path -StopOnFailure:$StopOnFailure
  }
}

# Run tests
Write-Host ""
Write-Host "Running tests..." -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

$startTime = Get-Date
$result = Invoke-Pester -Configuration $config
$duration = (Get-Date) - $startTime

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

# Display summary
if ($ShowSummary -or $Mode -in @('Coverage', 'CI')) {
  Get-TestSummary -Result $result -ShowCoverage:($Mode -in @('Coverage', 'CI'))
} else {
  # Quick summary
  Write-Host "Summary: " -NoNewline -ForegroundColor Cyan
  Write-Host "$($result.PassedCount)/$($result.TotalCount) passed" -NoNewline
  
  if ($result.FailedCount -eq 0) {
    Write-Host " ✅" -ForegroundColor Green
  } else {
    Write-Host " ❌ ($($result.FailedCount) failed)" -ForegroundColor Red
  }
  
  Write-Host "Duration: " -NoNewline -ForegroundColor Cyan
  Write-Host "$($duration.TotalSeconds.ToString('F2'))s" -ForegroundColor White
}

# Coverage report location
if ($Mode -in @('Coverage', 'CI') -and $result.CodeCoverage) {
  Write-Host ""
  Write-Host "Coverage report: " -NoNewline -ForegroundColor Cyan
  Write-Host "./coverage.xml" -ForegroundColor White
  
  if ($IsLinux) {
    Write-Host ""
    Write-Host "To view coverage HTML report, install ReportGenerator:" -ForegroundColor Yellow
    Write-Host "  dotnet tool install --global dotnet-reportgenerator-globaltool" -ForegroundColor Gray
    Write-Host "  reportgenerator -reports:coverage.xml -targetdir:coverage-html -reporttypes:Html" -ForegroundColor Gray
  }
}

# Test results file location
if ($Mode -in @('Coverage', 'CI')) {
  Write-Host "Test results: " -NoNewline -ForegroundColor Cyan
  Write-Host "./test-results.xml" -ForegroundColor White
}

Write-Host ""

# Exit with appropriate code
if ($result.FailedCount -gt 0) {
  Write-Host "❌ Tests failed" -ForegroundColor Red
  exit 1
} else {
  Write-Host "✅ All tests passed" -ForegroundColor Green
  exit 0
}
