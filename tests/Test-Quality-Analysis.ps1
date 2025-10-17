#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Analyze PoshGuard test suite quality and generate improvement recommendations

.DESCRIPTION
    This script analyzes the PoshGuard test suite to:
    - Identify modules with low coverage
    - Find tests that might be missing edge cases
    - Detect performance issues (slow tests)
    - Verify test patterns (mocking, isolation, etc.)
    - Generate actionable improvement recommendations

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester Architect principles
#>

[CmdletBinding()]
param(
  [Parameter()]
  [switch]$IncludeCoverage,
  
  [Parameter()]
  [switch]$ShowSlowTests,
  
  [Parameter()]
  [string]$OutputPath = './test-quality-report.md'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host '🔍 PoshGuard Test Quality Analysis' -ForegroundColor Cyan
Write-Host '=================================' -ForegroundColor Cyan
Write-Host ''

# Initialize results
$results = @{
  TotalTestFiles = 0
  TotalTests     = 0
  PassedTests    = 0
  FailedTests    = 0
  SkippedTests   = 0
  SlowTests      = @()
  Issues         = @()
  Recommendations = @()
  ModuleCoverage = @()
}

#region Test Discovery
Write-Host '📋 Discovering test files...' -ForegroundColor Yellow

$testFiles = Get-ChildItem -Path './tests/Unit' -Filter '*.Tests.ps1' -Recurse
$results.TotalTestFiles = $testFiles.Count

Write-Host "   Found $($testFiles.Count) test files" -ForegroundColor Green
Write-Host ''

#endregion

#region Test Execution Analysis
Write-Host '🧪 Analyzing test execution...' -ForegroundColor Yellow

$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit'
$config.Run.PassThru = $true
$config.Run.Exit = $false
$config.Output.Verbosity = 'Minimal'

if ($IncludeCoverage) {
  Write-Host '   Enabling code coverage (this may take a while)...' -ForegroundColor Cyan
  $config.CodeCoverage.Enabled = $true
  $config.CodeCoverage.Path = './tools/lib/*.psm1'
  $config.CodeCoverage.RecursePaths = $true
}

try {
  $pesterResult = Invoke-Pester -Configuration $config
  
  $results.TotalTests = $pesterResult.TotalCount
  $results.PassedTests = $pesterResult.PassedCount
  $results.FailedTests = $pesterResult.FailedCount
  $results.SkippedTests = $pesterResult.SkippedCount
  
  Write-Host "   Total:   $($results.TotalTests)" -ForegroundColor White
  Write-Host "   Passed:  $($results.PassedTests)" -ForegroundColor Green
  Write-Host "   Failed:  $($results.FailedTests)" -ForegroundColor $(if ($results.FailedTests -gt 0) { 'Red' } else { 'Green' })
  Write-Host "   Skipped: $($results.SkippedTests)" -ForegroundColor Yellow
  
  if ($IncludeCoverage -and $pesterResult.CodeCoverage) {
    $coveragePercent = [math]::Round($pesterResult.CodeCoverage.CoveragePercent, 2)
    Write-Host "   Coverage: $coveragePercent%" -ForegroundColor $(if ($coveragePercent -ge 85) { 'Green' } else { 'Yellow' })
    
    $results.ModuleCoverage = $pesterResult.CodeCoverage.AnalyzedFiles | ForEach-Object {
      @{
        File = $_ -replace '.*[\\/]tools[\\/]lib[\\/]', ''
        Coverage = 'N/A' # Detailed per-file coverage requires more parsing
      }
    }
  }
}
catch {
  Write-Warning "Test execution failed: $_"
  $results.Issues += "Test execution failed: $_"
}

Write-Host ''

#endregion

#region Slow Test Detection
if ($ShowSlowTests) {
  Write-Host '⏱️  Analyzing test performance...' -ForegroundColor Yellow
  
  # Run tests individually to identify slow ones
  $slowThreshold = 500 # milliseconds
  
  foreach ($testFile in ($testFiles | Select-Object -First 10)) { # Sample first 10
    $config = New-PesterConfiguration
    $config.Run.Path = $testFile.FullName
    $config.Run.PassThru = $true
    $config.Output.Verbosity = 'None'
    
    $duration = Measure-Command {
      $fileResult = Invoke-Pester -Configuration $config
    }
    
    if ($duration.TotalMilliseconds -gt $slowThreshold) {
      $results.SlowTests += @{
        File     = $testFile.Name
        Duration = [math]::Round($duration.TotalMilliseconds, 0)
      }
    }
  }
  
  if ($results.SlowTests.Count -gt 0) {
    Write-Host "   Found $($results.SlowTests.Count) slow test files (>500ms):" -ForegroundColor Yellow
    $results.SlowTests | ForEach-Object {
      Write-Host "   - $($_.File): $($_.Duration)ms" -ForegroundColor Red
    }
  }
  else {
    Write-Host '   No slow tests detected (sampled)' -ForegroundColor Green
  }
  
  Write-Host ''
}

#endregion

#region Pattern Analysis
Write-Host '🔬 Analyzing test patterns...' -ForegroundColor Yellow

$patternStats = @{
  UsingInModuleScope = 0
  UsingMock          = 0
  UsingTestDrive     = 0
  UsingTestCases     = 0
  HasEdgeCases       = 0
  HasErrorTests      = 0
}

foreach ($testFile in $testFiles) {
  $content = Get-Content -Path $testFile.FullName -Raw
  
  if ($content -match 'InModuleScope') { $patternStats.UsingInModuleScope++ }
  if ($content -match '\bMock\b') { $patternStats.UsingMock++ }
  if ($content -match 'TestDrive:') { $patternStats.UsingTestDrive++ }
  if ($content -match '-TestCases') { $patternStats.UsingTestCases++ }
  if ($content -match '(null|empty|unicode|boundary|edge)') { $patternStats.HasEdgeCases++ }
  if ($content -match 'Should -Throw') { $patternStats.HasErrorTests++ }
}

Write-Host "   InModuleScope:  $($patternStats.UsingInModuleScope)/$($testFiles.Count) files" -ForegroundColor Cyan
Write-Host "   Mock:           $($patternStats.UsingMock)/$($testFiles.Count) files" -ForegroundColor Cyan
Write-Host "   TestDrive:      $($patternStats.UsingTestDrive)/$($testFiles.Count) files" -ForegroundColor Cyan
Write-Host "   TestCases:      $($patternStats.UsingTestCases)/$($testFiles.Count) files" -ForegroundColor Cyan
Write-Host "   Edge Cases:     $($patternStats.HasEdgeCases)/$($testFiles.Count) files" -ForegroundColor Cyan
Write-Host "   Error Tests:    $($patternStats.HasErrorTests)/$($testFiles.Count) files" -ForegroundColor Cyan

Write-Host ''

#endregion

#region Recommendations
Write-Host '💡 Generating recommendations...' -ForegroundColor Yellow

# Failed tests
if ($results.FailedTests -gt 0) {
  $results.Recommendations += "🔴 Fix $($results.FailedTests) failing test(s) immediately"
}

# Skipped tests
if ($results.SkippedTests -gt 0) {
  $results.Recommendations += "⚠️  Review $($results.SkippedTests) skipped test(s) - are they still needed?"
}

# Missing patterns
if ($patternStats.UsingInModuleScope -lt ($testFiles.Count * 0.5)) {
  $results.Recommendations += "📝 Consider using InModuleScope more consistently for internal function testing"
}

if ($patternStats.UsingTestCases -lt ($testFiles.Count * 0.3)) {
  $results.Recommendations += "📊 Add table-driven tests with -TestCases to reduce duplication"
}

if ($patternStats.HasEdgeCases -lt ($testFiles.Count * 0.5)) {
  $results.Recommendations += "🎯 Add more edge case tests (null, empty, large, unicode, boundary values)"
}

if ($patternStats.HasErrorTests -lt ($testFiles.Count * 0.7)) {
  $results.Recommendations += "⚡ Add more error path testing (Should -Throw for invalid inputs)"
}

# Slow tests
if ($results.SlowTests.Count -gt 0) {
  $results.Recommendations += "⏱️  Optimize $($results.SlowTests.Count) slow test file(s) - consider mocking expensive operations"
}

# Coverage
if ($IncludeCoverage -and $coveragePercent -lt 85) {
  $results.Recommendations += "📈 Increase code coverage from $coveragePercent% to 85%+ target"
}

# Always good practices
$results.Recommendations += "✅ Continue using AAA pattern (Arrange-Act-Assert)"
$results.Recommendations += "✅ Keep mocking all external dependencies (time, filesystem, network)"
$results.Recommendations += "✅ Maintain test isolation with TestDrive and BeforeEach"

Write-Host ''

#endregion

#region Report Generation
Write-Host '📄 Generating report...' -ForegroundColor Yellow

$report = @"
# PoshGuard Test Quality Analysis Report

**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Summary

### Test Coverage
- **Test Files:** $($results.TotalTestFiles)
- **Total Tests:** $($results.TotalTests)
- **Passed:** $($results.PassedTests) ✅
- **Failed:** $($results.FailedTests) $(if ($results.FailedTests -gt 0) { '❌' } else { '✅' })
- **Skipped:** $($results.SkippedTests) $(if ($results.SkippedTests -gt 0) { '⚠️' } else { '✅' })

$(if ($IncludeCoverage) {
"### Code Coverage
- **Overall:** $coveragePercent%
- **Target:** 90% (lines), 85% (branches)
- **Status:** $(if ($coveragePercent -ge 85) { '✅ Meets threshold' } else { '⚠️ Below threshold' })"
})

## Test Pattern Usage

| Pattern | Usage | Status |
|---------|-------|--------|
| InModuleScope | $($patternStats.UsingInModuleScope)/$($testFiles.Count) | $(if ($patternStats.UsingInModuleScope -gt ($testFiles.Count * 0.5)) { '✅ Good' } else { '⚠️ Could improve' }) |
| Mock | $($patternStats.UsingMock)/$($testFiles.Count) | $(if ($patternStats.UsingMock -gt ($testFiles.Count * 0.5)) { '✅ Good' } else { '⚠️ Could improve' }) |
| TestDrive | $($patternStats.UsingTestDrive)/$($testFiles.Count) | $(if ($patternStats.UsingTestDrive -gt ($testFiles.Count * 0.3)) { '✅ Good' } else { 'ℹ️ Optional' }) |
| TestCases | $($patternStats.UsingTestCases)/$($testFiles.Count) | $(if ($patternStats.UsingTestCases -gt ($testFiles.Count * 0.3)) { '✅ Good' } else { '⚠️ Could improve' }) |
| Edge Cases | $($patternStats.HasEdgeCases)/$($testFiles.Count) | $(if ($patternStats.HasEdgeCases -gt ($testFiles.Count * 0.5)) { '✅ Good' } else { '⚠️ Could improve' }) |
| Error Tests | $($patternStats.HasErrorTests)/$($testFiles.Count) | $(if ($patternStats.HasErrorTests -gt ($testFiles.Count * 0.7)) { '✅ Good' } else { '⚠️ Could improve' }) |

$(if ($results.SlowTests.Count -gt 0) {
"## Slow Tests (>500ms)

| Test File | Duration |
|-----------|----------|
$($results.SlowTests | ForEach-Object { "| $($_.File) | $($_.Duration)ms |" } | Out-String)"
})

## Recommendations

$($results.Recommendations | ForEach-Object { "- $_" } | Out-String)

## Next Steps

1. **Immediate:** Fix failing tests
2. **High Priority:** Improve coverage to 90%+
3. **Medium Priority:** Add edge cases and error path tests
4. **Low Priority:** Optimize slow tests, add table-driven tests

---

*Report generated by Test-Quality-Analysis.ps1*
"@

$report | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "   Report saved to: $OutputPath" -ForegroundColor Green

#endregion

Write-Host ''
Write-Host '✅ Analysis complete!' -ForegroundColor Green
Write-Host ''

# Display summary
Write-Host '📊 Quick Summary:' -ForegroundColor Cyan
Write-Host "   Tests: $($results.PassedTests)/$($results.TotalTests) passing" -ForegroundColor White
if ($IncludeCoverage) {
  Write-Host "   Coverage: $coveragePercent%" -ForegroundColor White
}
Write-Host "   Top Priority: $(if ($results.FailedTests -gt 0) { 'Fix failing tests' } elseif ($IncludeCoverage -and $coveragePercent -lt 85) { 'Improve coverage' } else { 'Maintain quality' })" -ForegroundColor White
Write-Host ''
