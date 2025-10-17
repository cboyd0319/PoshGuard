#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Local test runner script for PoshGuard test suite

.DESCRIPTION
    Runs PoshGuard tests locally with various options:
    - Quick test run (core modules only)
    - Full test suite
    - With code coverage
    - With PSScriptAnalyzer
    
    Use this before committing to catch issues early.

.PARAMETER Quick
    Run only core module tests (fast feedback)

.PARAMETER Coverage
    Enable code coverage analysis

.PARAMETER SkipAnalyzer
    Skip PSScriptAnalyzer checks

.PARAMETER Module
    Run tests for specific module

.EXAMPLE
    ./run-local-tests.ps1 -Quick
    Run core tests only (fast)

.EXAMPLE
    ./run-local-tests.ps1 -Coverage
    Run all tests with coverage

.EXAMPLE
    ./run-local-tests.ps1 -Module Core
    Run Core module tests only

.NOTES
    Part of PoshGuard Test Suite
#>

[CmdletBinding()]
param(
  [Parameter()]
  [switch]$Quick,

  [Parameter()]
  [switch]$Coverage,

  [Parameter()]
  [switch]$SkipAnalyzer,

  [Parameter()]
  [string]$Module,

  [Parameter()]
  [string[]]$Tag
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Colors for output
$cyan = 'Cyan'
$green = 'Green'
$yellow = 'Yellow'
$red = 'Red'

function Write-Section {
  param([string]$Message)
  Write-Host "`n$('=' * 80)" -ForegroundColor $cyan
  Write-Host "  $Message" -ForegroundColor $cyan
  Write-Host "$('=' * 80)`n" -ForegroundColor $cyan
}

# Verify Pester is installed
Write-Section "Checking Prerequisites"
$pesterModule = Get-Module Pester -ListAvailable | Where-Object { $_.Version -ge '5.5.0' } | Select-Object -First 1
if (-not $pesterModule) {
  Write-Host "❌ Pester v5.5.0+ not found" -ForegroundColor $red
  Write-Host "Installing Pester..." -ForegroundColor $yellow
  Install-Module Pester -Force -SkipPublisherCheck -MinimumVersion 5.5.0 -Scope CurrentUser
  $pesterModule = Get-Module Pester -ListAvailable | Select-Object -First 1
}
Write-Host "✅ Pester $($pesterModule.Version) installed" -ForegroundColor $green

# Verify PSScriptAnalyzer is installed (unless skipped)
if (-not $SkipAnalyzer) {
  $psaModule = Get-Module PSScriptAnalyzer -ListAvailable | Select-Object -First 1
  if (-not $psaModule) {
    Write-Host "❌ PSScriptAnalyzer not found" -ForegroundColor $red
    Write-Host "Installing PSScriptAnalyzer..." -ForegroundColor $yellow
    Install-Module PSScriptAnalyzer -Force -SkipPublisherCheck -Scope CurrentUser
    $psaModule = Get-Module PSScriptAnalyzer -ListAvailable | Select-Object -First 1
  }
  Write-Host "✅ PSScriptAnalyzer $($psaModule.Version) installed" -ForegroundColor $green
}

# Run PSScriptAnalyzer
if (-not $SkipAnalyzer) {
  Write-Section "Running PSScriptAnalyzer"
  
  Write-Host "Analyzing source code..." -ForegroundColor $cyan
  $sourceResults = Invoke-ScriptAnalyzer -Path ./tools/lib -Settings ./.psscriptanalyzer.psd1 -Recurse -ErrorAction Continue
  
  if ($sourceResults) {
    Write-Host "⚠️  Found $($sourceResults.Count) issue(s) in source code:" -ForegroundColor $yellow
    $sourceResults | Format-Table -Property Severity, RuleName, ScriptName, Line, Message -AutoSize
    
    $errors = $sourceResults | Where-Object { $_.Severity -eq 'Error' }
    if ($errors) {
      Write-Host "❌ Found $($errors.Count) error(s)" -ForegroundColor $red
      exit 1
    }
  }
  else {
    Write-Host "✅ No issues found in source code" -ForegroundColor $green
  }
  
  Write-Host "`nAnalyzing test code..." -ForegroundColor $cyan
  $testResults = Invoke-ScriptAnalyzer -Path ./tests -Settings ./tests/.psscriptanalyzer.tests.psd1 -Recurse -ErrorAction Continue
  
  if ($testResults) {
    Write-Host "⚠️  Found $($testResults.Count) issue(s) in test code:" -ForegroundColor $yellow
    $testResults | Format-Table -Property Severity, RuleName, ScriptName, Line, Message -AutoSize
    
    $errors = $testResults | Where-Object { $_.Severity -eq 'Error' }
    if ($errors) {
      Write-Host "❌ Found $($errors.Count) error(s)" -ForegroundColor $red
      exit 1
    }
  }
  else {
    Write-Host "✅ No issues found in test code" -ForegroundColor $green
  }
}

# Configure Pester
Write-Section "Configuring Test Run"
$config = New-PesterConfiguration

# Determine test path
if ($Module) {
  $config.Run.Path = "./tests/Unit/$Module.Tests.ps1"
  Write-Host "Running tests for module: $Module" -ForegroundColor $cyan
}
elseif ($Quick) {
  $config.Run.Path = @(
    './tests/Unit/PoshGuard.Tests.ps1',
    './tests/Unit/Core.Tests.ps1',
    './tests/Unit/Security.Tests.ps1'
  )
  Write-Host "Running quick test suite (core modules only)" -ForegroundColor $cyan
}
else {
  $config.Run.Path = './tests/Unit'
  Write-Host "Running full test suite" -ForegroundColor $cyan
}

# Apply tags if specified
if ($Tag) {
  $config.Filter.Tag = $Tag
  Write-Host "Filtering by tags: $($Tag -join ', ')" -ForegroundColor $cyan
}

# Configure output
$config.Run.PassThru = $true
$config.Output.Verbosity = 'Detailed'

# Configure test results
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.TestResult.OutputPath = './test-results.xml'

# Configure code coverage
if ($Coverage) {
  Write-Host "Enabling code coverage analysis" -ForegroundColor $cyan
  $config.CodeCoverage.Enabled = $true
  $config.CodeCoverage.Path = './tools/lib/*.psm1'
  $config.CodeCoverage.OutputFormat = 'JaCoCo'
  $config.CodeCoverage.OutputPath = './coverage.xml'
  $config.CodeCoverage.CoveragePercentTarget = 85
}

# Run tests
Write-Section "Running Tests"
$result = Invoke-Pester -Configuration $config

# Display results
Write-Section "Test Results"
Write-Host "Total Tests:    $($result.TotalCount)" -ForegroundColor White
Write-Host "Passed:         $($result.PassedCount)" -ForegroundColor $green
if ($result.FailedCount -gt 0) {
  Write-Host "Failed:         $($result.FailedCount)" -ForegroundColor $red
}
else {
  Write-Host "Failed:         $($result.FailedCount)" -ForegroundColor $green
}
Write-Host "Skipped:        $($result.SkippedCount)" -ForegroundColor $yellow
Write-Host "Duration:       $($result.Duration.TotalSeconds)s" -ForegroundColor White

# Display coverage results
if ($Coverage -and $result.CodeCoverage) {
  Write-Section "Code Coverage"
  $coverage = $result.CodeCoverage
  $coveragePercent = [math]::Round($coverage.CoveragePercent, 2)
  
  Write-Host "Lines Covered:  $($coverage.CommandsExecutedCount) / $($coverage.CommandsAnalyzedCount)" -ForegroundColor White
  Write-Host "Coverage:       $coveragePercent%" -ForegroundColor $(if ($coveragePercent -ge 85) { $green } else { $yellow })
  Write-Host "Target:         85%" -ForegroundColor White
  
  if ($coveragePercent -lt 85) {
    Write-Host "`n⚠️  Coverage is below 85% target" -ForegroundColor $yellow
    
    # Show top 10 least covered files
    $missedByFile = $coverage.MissedCommands | Group-Object -Property File | 
      Select-Object Name, Count | 
      Sort-Object Count -Descending | 
      Select-Object -First 10
    
    if ($missedByFile) {
      Write-Host "`nTop 10 files with missed coverage:" -ForegroundColor $yellow
      $missedByFile | Format-Table -AutoSize
    }
  }
  else {
    Write-Host "`n✅ Coverage meets 85% threshold" -ForegroundColor $green
  }
}

# Final status
Write-Section "Summary"
if ($result.FailedCount -eq 0) {
  Write-Host "✅ All tests passed!" -ForegroundColor $green
  exit 0
}
else {
  Write-Host "❌ $($result.FailedCount) test(s) failed" -ForegroundColor $red
  
  # Show failed tests
  Write-Host "`nFailed tests:" -ForegroundColor $yellow
  $result.Failed | ForEach-Object {
    Write-Host "  - $($_.ExpandedName)" -ForegroundColor $red
    if ($_.ErrorRecord) {
      Write-Host "    $($_.ErrorRecord.Exception.Message)" -ForegroundColor $red
    }
  }
  
  exit 1
}
