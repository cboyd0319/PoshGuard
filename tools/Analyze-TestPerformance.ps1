#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Analyze test file performance to identify slow or problematic tests

.DESCRIPTION
    Runs each test file individually to measure performance and identify issues.
    Helps find tests that should be tagged as 'Slow' or have other performance problems.

.PARAMETER Path
    Path to test files (default: ./tests/Unit)

.PARAMETER TimeoutSeconds
    Timeout for each test file (default: 30)

.PARAMETER ExcludeSlow
    Exclude tests tagged as 'Slow' (default: true)

.EXAMPLE
    ./tools/Analyze-TestPerformance.ps1

.EXAMPLE
    ./tools/Analyze-TestPerformance.ps1 -TimeoutSeconds 60 -ExcludeSlow:$false
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$Path = './tests/Unit',
    
    [Parameter()]
    [int]$TimeoutSeconds = 30,
    
    [Parameter()]
    [bool]$ExcludeSlow = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     PoshGuard Test Performance Analyzer                  ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Get all test files
$testFiles = Get-ChildItem -Path $Path -Filter '*.Tests.ps1' -File | Sort-Object Name

if (-not $testFiles) {
    Write-Warning "No test files found in $Path"
    exit 1
}

Write-Host "Found $($testFiles.Count) test files" -ForegroundColor White
Write-Host "Timeout: ${TimeoutSeconds}s per file" -ForegroundColor Gray
Write-Host "Exclude Slow: $ExcludeSlow`n" -ForegroundColor Gray

$results = @()
$totalFiles = $testFiles.Count
$currentFile = 0

foreach ($file in $testFiles) {
    $currentFile++
    Write-Host "[$currentFile/$totalFiles] Testing: " -NoNewline -ForegroundColor Cyan
    Write-Host "$($file.Name)" -ForegroundColor White
    
    # Run test in background job
    $job = Start-Job -ScriptBlock {
        param($FilePath, $ExcludeSlowTag)
        
        $config = New-PesterConfiguration
        $config.Run.Path = $FilePath
        $config.Run.PassThru = $true
        $config.Output.Verbosity = 'None'
        
        if ($ExcludeSlowTag) {
            $config.Filter.ExcludeTag = @('Slow')
        }
        
        Invoke-Pester -Configuration $config
    } -ArgumentList $file.FullName, $ExcludeSlow
    
    $completed = Wait-Job -Job $job -Timeout $TimeoutSeconds
    
    if ($completed) {
        $result = Receive-Job -Job $job -ErrorAction SilentlyContinue
        
        if ($result) {
            $status = if ($result.FailedCount -eq 0) { 'PASS' } else { 'FAIL' }
            $statusColor = if ($status -eq 'PASS') { 'Green' } else { 'Red' }
            $duration = $result.Duration.TotalSeconds
            $durationColor = if ($duration -lt 5) { 'Green' } elseif ($duration -lt 10) { 'Yellow' } else { 'Red' }
            
            Write-Host "  [$status] " -NoNewline -ForegroundColor $statusColor
            Write-Host "$($result.PassedCount)/$($result.TotalCount) tests in " -NoNewline
            Write-Host "$($duration.ToString('0.00'))s" -ForegroundColor $durationColor
            
            $results += [PSCustomObject]@{
                File = $file.Name
                Duration = [double]$duration
                Tests = $result.TotalCount
                Passed = $result.PassedCount
                Failed = $result.FailedCount
                Skipped = $result.NotRunCount
                Status = $status
                Issue = $null
            }
        } else {
            Write-Host "  [ERROR] No output from Pester" -ForegroundColor Red
            
            $results += [PSCustomObject]@{
                File = $file.Name
                Duration = $TimeoutSeconds
                Tests = 0
                Passed = 0
                Failed = 0
                Skipped = 0
                Status = 'ERROR'
                Issue = 'No output'
            }
        }
    } else {
        Write-Host "  [TIMEOUT] > ${TimeoutSeconds}s" -ForegroundColor Yellow
        Stop-Job -Job $job
        
        $results += [PSCustomObject]@{
            File = $file.Name
            Duration = $TimeoutSeconds
            Tests = 0
            Passed = 0
            Failed = 0
            Skipped = 0
            Status = 'TIMEOUT'
            Issue = "Exceeded ${TimeoutSeconds}s"
        }
    }
    
    Remove-Job -Job $job -Force
}

# Generate summary
Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Performance Summary                                   ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$totalTests = ($results | Measure-Object -Property Tests -Sum).Sum
$totalPassed = ($results | Measure-Object -Property Passed -Sum).Sum
$totalFailed = ($results | Measure-Object -Property Failed -Sum).Sum
$totalDuration = ($results | Measure-Object -Property Duration -Sum).Sum

Write-Host "Total Files:    $($results.Count)" -ForegroundColor White
Write-Host "Total Tests:    $totalTests" -ForegroundColor White
Write-Host "Total Passed:   $totalPassed" -ForegroundColor Green
Write-Host "Total Failed:   $totalFailed" -ForegroundColor $(if ($totalFailed -gt 0) { 'Red' } else { 'Green' })
Write-Host "Total Duration: $($totalDuration.ToString('0.00'))s`n" -ForegroundColor White

# Show problematic files
$problematic = $results | Where-Object { $_.Status -in @('TIMEOUT', 'ERROR', 'FAIL') -or $_.Duration -gt 10 }

if ($problematic) {
    Write-Host "⚠️  Problematic Files (needs attention):" -ForegroundColor Yellow
    $problematic | 
        Sort-Object -Property Duration -Descending |
        Format-Table -Property @{
            Label = 'File'
            Expression = { $_.File }
            Width = 40
        }, @{
            Label = 'Status'
            Expression = { $_.Status }
            Width = 10
        }, @{
            Label = 'Duration'
            Expression = { "$($_.Duration.ToString('0.00'))s" }
            Width = 12
        }, @{
            Label = 'Tests'
            Expression = { "$($_.Passed)/$($_.Tests)" }
            Width = 12
        }, @{
            Label = 'Issue'
            Expression = { $_.Issue }
        } -AutoSize
} else {
    Write-Host "✅ No problematic files found!" -ForegroundColor Green
}

# Show slow files (but passing)
Write-Host "`n📊 Performance Breakdown:" -ForegroundColor Cyan
$results | 
    Sort-Object -Property Duration -Descending |
    Format-Table -Property @{
        Label = 'File'
        Expression = { $_.File }
        Width = 40
    }, @{
        Label = 'Status'
        Expression = { 
            switch ($_.Status) {
                'PASS' { '✅' }
                'FAIL' { '❌' }
                'TIMEOUT' { '⏱️' }
                'ERROR' { '⚠️' }
            }
        }
        Width = 8
    }, @{
        Label = 'Duration'
        Expression = { "$($_.Duration.ToString('0.00'))s" }
        Width = 12
    }, @{
        Label = 'Tests'
        Expression = { "$($_.Passed)/$($_.Tests)" }
        Width = 12
    }, @{
        Label = 'Speed'
        Expression = {
            if ($_.Duration -eq 0) { 'N/A' }
            elseif ($_.Duration -lt 1) { 'Fast ⚡' }
            elseif ($_.Duration -lt 5) { 'Good ✓' }
            elseif ($_.Duration -lt 10) { 'Slow ⏱️' }
            else { 'Very Slow 🐌' }
        }
        Width = 15
    }

# Recommendations
Write-Host "`n💡 Recommendations:" -ForegroundColor Cyan

$slow = $results | Where-Object { $_.Status -eq 'PASS' -and $_.Duration -gt 5 }
if ($slow) {
    Write-Host "  • Consider tagging these files/tests as 'Slow':" -ForegroundColor Yellow
    $slow | ForEach-Object { Write-Host "    - $($_.File)" -ForegroundColor Gray }
}

$timeouts = $results | Where-Object { $_.Status -eq 'TIMEOUT' }
if ($timeouts) {
    Write-Host "  • Fix hanging/timeout issues in:" -ForegroundColor Red
    $timeouts | ForEach-Object { Write-Host "    - $($_.File) (likely interactive prompt or infinite loop)" -ForegroundColor Gray }
}

$failures = $results | Where-Object { $_.Status -eq 'FAIL' }
if ($failures) {
    Write-Host "  • Fix failing tests in:" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "    - $($_.File)" -ForegroundColor Gray }
}

if (-not $slow -and -not $timeouts -and -not $failures) {
    Write-Host "  ✅ All tests are fast and passing!" -ForegroundColor Green
}

Write-Host "`n✅ Analysis complete!`n" -ForegroundColor Green

# Exit with error if there are failures or timeouts
if ($totalFailed -gt 0 -or $timeouts) {
    exit 1
}
